# SPEC-CORE-66: LLM real (Claude) y RAG real (embeddings + Qdrant)

**Estado:** IN_PROGRESS
**Épica:** 01 Core Engine (ÉPICA 5 Smart Router, ÉPICA 6 RAG Engine)
**Repos afectados:** aipods-core-engine, deploy (compose del VPS)

## 1. Motivación

El core responde con datos simulados:

- El router (`internal/router/dynamic_router.go`) elige el pod con `strings.Contains` sobre palabras clave.
- Cada pod devuelve un texto fijo; ninguno consulta un modelo de lenguaje.
- `internal/rag/vector_store.go` guarda los chunks en memoria y genera "embeddings" sumando códigos de caracteres. Qdrant está en el compose pero nadie lo usa.

Esta spec conecta un LLM real para clasificar y redactar, y un RAG real con embeddings y Qdrant, aislado por tenant.

## 2. Decisiones

| Tema | Decisión |
|---|---|
| LLM | Claude vía SDK oficial `github.com/anthropics/anthropic-sdk-go/v2`. Modelo por defecto `claude-opus-5-5`, configurable con `ANTHROPIC_MODEL`. |
| Credencial | `ANTHROPIC_API_KEY` por env (o vault). Sin clave, el core sigue funcionando en modo prototipo (router por palabras clave, respuestas de los pods). |
| Embeddings | Interfaz `embed.Embedder`. Implementación por defecto: Ollama local en el VPS (`bge-m3`, 1024 dim, multilingüe), para que los documentos no salgan del servidor. Alternativa a evaluar: Voyage AI. |
| Vector store | Qdrant vía API REST (sin dependencia nueva). Colección `aipods_chunks`, distancia coseno. |
| Acciones | El LLM **nunca** decide ejecutar. El `DryRunResult` y la aprobación humana los sigue generando cada pod; el LLM solo redacta la respuesta. |

## 3. Requisitos

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-66.R1` | Paquete `internal/llm` con cliente Claude: `Complete` (respuesta) y `Classify` (elige un pod de una lista cerrada). | Tests con cliente falso. |
| `SPEC-CORE-66.R2` | Con LLM configurado, el router clasifica la consulta entre los pods estáticos y los dinámicos del tenant. Si el LLM falla o devuelve un ID que no está en la lista, cae al router por palabras clave. | Test: ID válido, ID inválido, error. |
| `SPEC-CORE-66.R3` | Con LLM configurado, la respuesta final se redacta con Claude a partir de: la consulta, el resultado del pod y los fragmentos recuperados del RAG del tenant. Las citas devueltas son las de los fragmentos usados y las del pod. | Test con LLM y store falsos. |
| `SPEC-CORE-66.R4` | Paquete `internal/embed` con `Embedder` (`Embed(ctx, textos) → vectores`, `Dimension()`), implementación Ollama (`OLLAMA_URL`, `EMBED_MODEL`) y una implementación determinística solo para tests. | Tests con servidor HTTP falso. |
| `SPEC-CORE-66.R5` | `rag.Store` es una interfaz; `QdrantStore` crea la colección si falta, hace upsert con payload `tenant_id`, `file_name`, `page_number`, `content`, y busca filtrando `tenant_id ∈ {tenant, GLOBAL}` del lado de Qdrant. | Tests con servidor HTTP falso que verifican el filtro. |
| `SPEC-CORE-66.R6` | Aislamiento: una búsqueda sin tenant en el contexto devuelve error, nunca resultados de otro tenant. | Test. |
| `SPEC-CORE-66.R7` | Configuración por env: `QDRANT_URL` (si falta, store en memoria), `OLLAMA_URL`, `EMBED_MODEL`, `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL`. `/healthz` informa qué modo está activo (`llm`, `vector_store`). | Revisión + `curl /healthz`. |
| `SPEC-CORE-66.R8` | Los errores del proveedor (429, 5xx, timeout) no tiran el endpoint: se responde con el resultado del pod y se registra el error. | Test con cliente falso que falla. |
| `SPEC-CORE-66.R9` | El compose del VPS agrega el servicio `ollama` (volumen persistente, sin puertos públicos) y pasa las variables al core. | Deploy con `levantar_vps.sh`. |

## 4. Fuera de alcance

- Autenticación por JWT y persistencia en Postgres (spec aparte, SPEC-CORE-67). Mientras tanto, el `tenant_id` sigue llegando en el body y el stack sigue detrás del basic auth de Traefik.
- Cifrado del payload en Qdrant (SPEC-CORE-34): los vectores tienen que quedar en claro para poder buscar; cifrar `content` queda para una spec posterior.
- Caché semántica en Redis y uso de herramientas (tool use) por parte de los pods.

## 5. Riesgos

- Costo por consulta: se usa esfuerzo `low` para clasificar y `medium` para redactar.
- Datos fiscales de clientes viajan a la API de Anthropic al redactar. Hay que reflejarlo en los términos con los clientes.
