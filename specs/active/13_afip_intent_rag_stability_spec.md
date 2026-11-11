# SPEC-CORE-72: Pod AFIP Informativo vs Operativo, Sanitización UTF-8 en Ingesta y Estabilidad del RAG Léxico

**Estado:** DRAFT (IN_PROGRESS)  
**Épica:** 01 Core Architecture & Engine  
**Issue:** [#42](https://github.com/onlyone-ai-pods/aipods-docs/issues/42)  
**Repos afectados:** `aipods-core-engine`, `aipods-docs`  
**Depende de:** [SPEC-CORE-70](12_rag_dual_strategy_spec.md), [SPEC-CORE-71](11_semantic_cache_shared_reuse_spec.md)

---

## 1. Motivación y Contexto

El despliegue en producción de SPEC-CORE-70 y SPEC-CORE-71 (2026-11-11) mostró tres defectos en el core:

1. **El pod AFIP convierte cualquier pregunta en una acción.** `POD_AFIP_FISCAL` decide con `strings.Contains` sobre palabras sueltas ("monotributo", "categoría", "período", "clave", "certificado", e incluso la subcadena "pv"). Una pregunta normativa como "¿Cuáles son las categorías del Monotributo vigentes?" devuelve `consultar_monotributo_estado_cuenta` con `DryRunResult` y token de aprobación. Efectos medidos en producción:
   - La caché semántica nunca guarda respuestas de este pod, porque `cacheable()` exige `DryRunResult == nil` (SPEC-CORE-71.R3). Redis quedó con 0 claves.
   - Cada pregunta crea una aprobación pendiente falsa en el Admin Hub.
   - La respuesta base de la rama por defecto inyecta el `tenantID`, lo que puede bloquear el nivel GLOBAL (SPEC-CORE-71.R2).
2. **La ingesta falla con bytes nulos.** `ARCA_Manual_ServiciosClaveFiscal_Generalidades.pdf` devuelve `invalid byte sequence for encoding "UTF8": 0x00 (SQLSTATE 22021)` al indexarse en `rag_chunks`. El extractor PDF deja `0x00` en el texto y Postgres no los acepta en columnas `TEXT`.
3. **La recuperación léxica es inestable.** Con `ragTopK = 5` y términos de expansión que cambian en cada llamada (SPEC-CORE-70.R1), la misma pregunta trajo la página 1 de `ARCA_Monotributo_Categorias_Feb-Jul2026.pdf` (la tabla) en un intento y solo la página 2 (notas al pie) en el siguiente. En el segundo caso el modelo respondió que no tenía la tabla.

---

## 2. Requisitos de la Especificación

### 2.1 Pod AFIP: intención informativa vs operativa

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-72.R1` | **Clasificación de intención.** `POD_AFIP_FISCAL` clasifica cada consulta como `operational` o `informational` antes de elegir la acción. Es `operational` solo si (a) aparece un verbo de acción (consultar, ver, mostrar, revisar, descargar, bajar, traer, exportar, crear, dar de alta, agregar, habilitar, dar de baja, generar, emitir, en infinitivo, imperativo o primera persona) junto con un objeto operativo (estado de cuenta, retenciones/percepciones, comprobantes/facturas, punto(s) de venta, CSR/certificado), o (b) el objeto operativo viene con posesivo del cliente (mi, mis, nuestro, nuestra, nuestros, nuestras), o (c) la consulta nombra "estado de cuenta", que siempre es dato propio. Antes de esas reglas, una consulta interrogativa o de tutorial es `informational` aunque traiga verbo y objeto: empieza con o contiene "cómo", "qué es", "qué son", "cuál", "cuáles", "cuándo", "dónde", "por qué", "para qué", "requisitos", "pasos para", "se puede", "hace falta", "necesito saber", o lleva signos de pregunta sin posesivo del cliente. Excepción: si la pregunta pide un dato propio con posesivo o nombra "estado de cuenta" ("¿cuál es mi estado de cuenta?", "¿qué retenciones tengo en mis comprobantes?"), es `operational`. En cualquier otro caso es `informational`. La comparación es por palabras normalizadas sin acentos, no por subcadenas: "pv" no coincide dentro de "previo". | Tabla de casos en `afip_test.go` (`TestSPEC_CORE_72_R1_*`): "¿Cuáles son las categorías del Monotributo vigentes?", "¿Qué es la clave fiscal?", "¿Cómo doy de alta un punto de venta?", "Pasos para generar el CSR", "¿Qué requisitos hay para crear un punto de venta?" → `informational`; "¿Cuál es mi estado de cuenta?" → `operational`; "Consultá mi estado de cuenta del monotributo", "Descargá mis comprobantes recibidos de octubre", "Creá un punto de venta RECE", "Generá el CSR para el certificado" → `operational`. |
| `SPEC-CORE-72.R2` | **Respuesta informativa sin acción.** Para `informational` el pod devuelve `DryRunResult == nil`, sin token de aprobación, y una respuesta base genérica que no contiene el `tenantID`, el CUIT ni otro dato del cliente. Así el router la puede cachear (SPEC-CORE-71.R3) y, si todas las fuentes son GLOBAL, guardarla en el nivel GLOBAL (SPEC-CORE-71.R2). La redacción final sigue a cargo del LLM con los documentos (SPEC-CORE-66). | Test de pod: respuesta `informational` sin `DryRunResult` y sin el `tenantID`. Test de router con caché en memoria: la consulta informativa del tenant A se guarda en GLOBAL y el tenant B recibe `cached: true` y `cache_scope: GLOBAL`. Test de API: `POST /api/v1/chat/completions` informativo no crea filas en aprobaciones. |
| `SPEC-CORE-72.R3` | **Respuesta operativa sin cambios.** Para `operational` el comportamiento actual se mantiene: `DryRunResult` con `requires_human_approval: true`, token de aprobación y registro en el Admin Hub, y la respuesta no se cachea. | Test de pod y de router: la consulta operativa trae `DryRunResult`, crea la aprobación y Redis/memoria no recibe la clave. |
| `SPEC-CORE-72.R4` | **Métrica de intención.** El core cuenta las consultas del pod AFIP por intención y las publica en `/metrics` como `aipods_afip_queries_total{intent="informational"\|"operational"}`, y en el snapshot de `GET /api/v1/admin/telemetry`. | Test del collector: tras una consulta de cada tipo, la salida Prometheus contiene ambos contadores en 1. |

### 2.2 Ingesta RAG: sanitización UTF-8

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-72.R5` | **Texto válido antes de indexar.** `RAGIngestionService.IngestDocument` limpia cada chunk, para todos los formatos, antes del índice léxico y del vector store: elimina los bytes `0x00`, reemplaza secuencias UTF-8 inválidas (`strings.ToValidUTF8`) y descarta los chunks que quedan vacíos. Si no queda ningún chunk, la ingesta responde error claro en vez de un error de Postgres. | `TestSPEC_CORE_72_R5_*`: un PDF de prueba en `internal/rag/testdata` cuyo texto extraído trae `0x00` se ingesta sin error y ningún chunk contiene `0x00` ni UTF-8 inválido. Verificación en producción: `ARCA_Manual_ServiciosClaveFiscal_Generalidades.pdf` responde 200 con `chunks_count > 0`. |

### 2.3 RAG léxico: estabilidad de la recuperación

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-72.R6` | **Más contexto por consulta.** El número de chunks recuperados pasa de la constante `ragTopK = 5` a un valor configurable por `RAG_TOP_K`, con default 10 y rango 1 a 20 (fuera de rango o inválido → 10, con aviso en el log). Aplica a la búsqueda léxica y a la vectorial. | Test de configuración: sin variable → 10; `RAG_TOP_K=8` → 8; `RAG_TOP_K=50` → 10. Test de router: la búsqueda recibe el `topK` configurado. |
| `SPEC-CORE-72.R7` | **Nombre del archivo en el índice.** `search_text` incluye, además del contenido normalizado, las palabras del nombre del archivo sin extensión (separando por `_`, `-`, `.` y espacios, normalizadas con `Normalize`). Así todas las páginas de `ARCA_Monotributo_Categorias_Feb-Jul2026.pdf` coinciden con "monotributo" y "categorías" aunque la página no repita esas palabras. Una migración `0004` actualiza `search_text` de las filas existentes con la misma regla, de modo que no hace falta reingestar (el `tsv` es columna generada y se recalcula). | Test de `IndexChunks` en memoria: una página sin las palabras del título aparece al buscar "categorías monotributo". Test de la migración sobre Postgres de prueba: la fila existente queda con las palabras del nombre en `search_text`. |
| `SPEC-CORE-72.R8` | **Tabla completa de forma estable.** Con R6 y R7, la pregunta "¿Cuáles son las categorías del Monotributo vigentes de febrero a julio 2026?" trae la página 1 de `ARCA_Monotributo_Categorias_Feb-Jul2026.pdf` en 5 de 5 repeticiones. | Test con índice léxico en memoria cargado con fragmentos de los PDFs de ARCA y tres variantes de términos de expansión: la página 1 está entre los resultados en todas. Verificación en producción: 5 repeticiones con caché desactivada (`dry_run` + tenant de prueba nuevo o purga por 👎). |

---

## 3. Fuera de Alcance

- El CUIT hardcodeado en los comandos simulados del pod AFIP (`--cuit=20262534538`) y en `scripts/*_arca.js`: se trata aparte (pendiente de rotación y limpieza de historial).
- Cambios en el contrato de la API o en los frontends: los campos `cached`, `cache_scope` y `dry_run_result` ya existen y no cambian.
- Búsqueda híbrida con embeddings o re-ranking.

---

## 4. Plan de Implementación

1. **Pod AFIP (R1-R3)** en `internal/pod/afip/afip.go`: función `classifyIntent(query) Intent` con listas de verbos, objetos y posesivos sobre palabras normalizadas (`rag.Normalize`). Las ramas actuales de acción solo corren si la intención es `operational`; la rama informativa devuelve una respuesta base sin `tenantID`. Tests en `afip_test.go` y en `internal/router` con la caché en memoria.
2. **Métrica (R4)** en `internal/telemetry/metrics.go`: `RecordAFIPIntent(intent)` y su línea Prometheus; el pod la reporta a través del router.
3. **Sanitización (R5)** en `internal/rag/rag_router.go`: `sanitizeChunks` antes de indexar. PDF de prueba con `0x00` en `internal/rag/testdata`.
4. **TopK (R6)** en `internal/router/answer.go` y `retrieval.go`: `ragTopK` pasa a campo del router, cargado de `RAG_TOP_K` en `cmd/server/main.go`. Documentar la variable en `deploy/.env.oracle.example`.
5. **Nombre de archivo (R7)** en `internal/rag/lexical.go` (`searchText(fileName, content)`) y migración `internal/store/migrations/0004_rag_search_text_file_name.sql`.
6. **Verificación (R8)** con test de estabilidad y, tras el despliegue, recarga del PDF que faltaba (`ONLY=ARCA_Manual_ServiciosClaveFiscal_Generalidades.pdf`), 5 repeticiones de la pregunta de categorías y prueba de caché GLOBAL entre `tenant_afip` y `martin`.

Commits en `aipods-core-engine` con el formato `[TAG] modulo: resumen (SPEC-CORE-72)` y tests nombrados `TestSPEC_CORE_72_RN_*`.
