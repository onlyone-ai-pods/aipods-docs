# SPEC-CORE-74: Modelo de Claude Configurable por Tarea y por Tenant, con Cadena de Respaldo

**Estado:** DRAFT (IN_PROGRESS)  
**Épica:** 01 Core Architecture & Engine  
**Issue:** [#50](https://github.com/onlyone-ai-pods/aipods-docs/issues/50)  
**Repos afectados:** `aipods-core-engine`, `aipods-frontend-admin`, `aipods-docs`, variables de `deploy/` (no versionadas)  
**Depende de:** [SPEC-CORE-66](08_llm_rag_real_spec.md) (LLM real), [SPEC-CORE-70](12_rag_dual_strategy_spec.md) (configuración por tenant y expansión de consulta), SPEC-CORE-71 (caché semántica, en [`01_CORE`](../01_CORE_ENGINE_MASTER_SPEC.md)), SPEC-CORE-73 (`LLM_TIMEOUT`, migraciones expand-only)

---

## 1. Motivación y Contexto

Lectura del core en `main` @ `b74c3fa` (2026-11-20):

1. **Un solo modelo para todo.** Cada consulta sin caché hace tres llamadas a Claude en serie: clasificar el pod (`llm.Classify`), expandir la consulta (`llm.ExpandQuery`) y redactar la respuesta (`draftAnswer`). Las tres usan el modelo de `ANTHROPIC_MODEL` (por defecto `claude-opus-5-5`).
2. **Costo y latencia.** Clasificar y expandir son tareas cortas. Opus 5.5 cuesta USD 4 / 20 por millón de tokens (entrada / salida) y Haiku 5.5 USD 0,10 / 0,50 (platform.claude.com, 2026-11-20). La misma `ANTHROPIC_API_KEY` sirve para todos los modelos.
3. **Sin respaldo ante saturación.** Si el modelo devuelve 429 o 529, o no responde dentro de `LLM_TIMEOUT` (45 s), la tarea cae directo a su plan B sin LLM (palabras clave, consulta cruda o respuesta fija del pod). No se prueba otro modelo de Claude. El `server-side fallback` que el core ya envía solo cubre rechazos del modelo, no saturación.
4. **Sin configuración por tenant.** No se puede dar a un tenant un modelo más rápido o más capaz que al resto.

Decisiones de Martin (2026-11-20, issue #50): el modelo es configurable por tarea, por variables de entorno y también por tenant desde el admin; la cadena de respaldo entra en esta spec.

**Fuera de alcance:** proveedores que no sean Anthropic (Gemini u otros); cola, concurrencia máxima, circuit breaker y presupuesto de tokens del gateway del LLM (decisión D4 del roadmap, PR #47); modo degradado sin LLM; ejecutar clasificación y expansión en paralelo; autogestión del modelo por el cliente en el portal; registro de consumo de tokens por tenant (issue #36).

---

## 2. Requisitos de la Especificación

### 2.1 Modelo por tarea

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-74.R1` | **Tres tareas con modelo propio.** Las tareas son `classify`, `expand` y `answer`. Variables: `LLM_MODEL_CLASSIFY`, `LLM_MODEL_EXPAND`, `LLM_MODEL_ANSWER`. Una variable ausente, vacía o solo con espacios usa `ANTHROPIC_MODEL` (y este, `claude-opus-5-5`). Sin variables nuevas el comportamiento es idéntico al actual. | Test de configuración: sin variables, las tres tareas resuelven a `ANTHROPIC_MODEL`; con `LLM_MODEL_CLASSIFY` definida, solo cambia esa tarea. |
| `SPEC-CORE-74.R2` | **Lista de modelos permitidos.** `LLM_ALLOWED_MODELS` (lista separada por comas; por defecto `claude-opus-5-5,claude-sonnet-5-5,claude-haiku-5-5`). `ANTHROPIC_MODEL` siempre se considera permitido. Si una variable `LLM_MODEL_*` o `LLM_FALLBACK_MODELS` nombra un modelo fuera de la lista, el core no arranca y el error nombra la variable y el valor (con blue-green, el color nuevo no queda listo y el viejo sigue sirviendo). | Test: valor fuera de la lista devuelve error desde `buildAIStack`; valor dentro de la lista arranca. |
| `SPEC-CORE-74.R3` | **Modelo por llamada.** `llm.Request` gana el campo `Model`. `AnthropicClient.Complete` usa `req.Model` si viene, o el modelo del cliente si no. Hay un solo cliente y una sola API key. `Classify` y `ExpandQuery` reciben el modelo de su tarea. | Test con servidor HTTP falso: el cuerpo de cada petición lleva el modelo de la tarea. |
| `SPEC-CORE-74.R4` | **Parámetros según el modelo.** El core arma la petición según las capacidades del modelo, definidas en una tabla en `internal/llm`: `claude-haiku-5-5` no recibe el parámetro `fallbacks` ni el beta `server-side-fallback-2026-07-01` (ese modelo no tiene fallback del lado del servidor); `effort` se envía siempre de forma explícita (`low` para `classify` y `expand`, `medium` para `answer`, como hoy). Un modelo permitido que no esté en la tabla usa el perfil conservador: sin `fallbacks`. | Test por modelo: la petición a Haiku no contiene `fallbacks`; la de Opus y Sonnet sí; todas llevan `output_config.effort`. |

### 2.2 Configuración por tenant

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-74.R5` | **Persistencia.** Migración expand `0006` (o la siguiente libre en `main`): columnas nulas en `tenants`: `llm_model_classify`, `llm_model_expand`, `llm_model_answer` (`TEXT NULL`) y `llm_fallback_models` (`TEXT NULL`, lista separada por comas). `NULL` significa heredar. Sin `CHECK` sobre los nombres de modelo: la lista permitida cambia con el tiempo y se valida en Go. Cumple SPEC-CORE-73.R14. | `TestSPEC_CORE_73_R14_StartupMigrationsAreExpandOnly` sigue pasando. Test de store (memoria y Postgres): leer y escribir los cuatro campos; tenant inexistente devuelve `ErrNotFound`. |
| `SPEC-CORE-74.R6` | **Orden de prioridad.** Para cada tarea: valor del tenant, luego variable `LLM_MODEL_*`, luego `ANTHROPIC_MODEL`. Para la cadena: valor del tenant, luego `LLM_FALLBACK_MODELS`. Un tenant sin fila (tenants demo con `AUTH_MODE=off`) o un error de lectura usan la configuración del entorno y se registra en el log, igual que `storeStrategyResolver`. Si el valor guardado de un tenant ya no está en la lista permitida, se ignora, se usa el del entorno y se registra una advertencia. | Test del resolver: las cuatro combinaciones (tenant, entorno, default, valor ya no permitido). |
| `SPEC-CORE-74.R7` | **Una lectura por consulta.** La configuración del tenant se lee una vez por consulta, después del fallo de caché y antes de clasificar. Un acierto de caché no consulta la base. | Test del router con store falso que cuenta lecturas: 1 en fallo de caché, 0 en acierto. |
| `SPEC-CORE-74.R8` | **API de administración.** `GET` y `PUT /api/v1/admin/tenants/:id/llm-models`, solo `platform_admin` (mismo guard que `rag-strategy`). Cuerpo del `PUT`: `{"classify": "...", "expand": "...", "answer": "...", "fallback": ["...", "..."]}`; `null` o `""` en una tarea y `null` en `fallback` significan heredar; `fallback: []` significa sin cadena para ese tenant. Respuestas: 400 si un modelo no está permitido o la cadena excede R10 (el mensaje lista los permitidos); 404 si el tenant no existe. El `GET` devuelve `configured` (lo guardado), `effective` (lo que se usa tras R6) y `allowed` (lista permitida). Cada `PUT` se audita como `llm_models.set` con los valores y el resultado. La API key nunca es configurable por tenant ni aparece en respuestas o auditoría. | Tests de handler: 200, 400, 404, 403 para un rol que no es `platform_admin`; el evento de auditoría queda guardado también cuando falla. |

### 2.3 Cadena de respaldo

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-74.R9` | **Cuándo salta.** Si el modelo de la tarea falla con HTTP 429, 529, 500, 502, 503 o 504, con error de conexión o por vencer el plazo del intento (R11), el core reintenta la misma petición con el siguiente modelo de la cadena. No salta con 400, 401, 403 o 404, con un rechazo del modelo (`ErrRefused`), ni cuando el contexto de la petición fue cancelado (el cliente cortó o el core está drenando). Agotada la cadena, la tarea usa su plan B actual sin LLM. | Tests con servidor falso: 529 en el primero y 200 en el segundo devuelve la respuesta del segundo; 400 no salta; contexto cancelado no salta; cadena agotada devuelve el plan B de hoy. |
| `SPEC-CORE-74.R10` | **Forma de la cadena.** `LLM_FALLBACK_MODELS` es una lista ordenada separada por comas, vacía por defecto (sin cadena, comportamiento actual). Máximo 3 modelos. Al ejecutar se omiten el modelo de la tarea y los repetidos. La cadena es la misma para las tres tareas. Ejemplo recomendado: `claude-sonnet-5-5,claude-haiku-5-5`. | Test: con tarea en `claude-sonnet-5-5` y cadena `claude-sonnet-5-5,claude-haiku-5-5`, hay como mucho 2 intentos. Test: 4 modelos en la variable impide el arranque; 4 en el `PUT` devuelve 400. |
| `SPEC-CORE-74.R11` | **Plazos.** `LLM_TIMEOUT` (45 s) pasa a ser el plazo total de una tarea, cadena incluida, así el peor caso por consulta no crece respecto de hoy (3 tareas × `LLM_TIMEOUT`). Cada tarea admite un plazo propio menor: `LLM_TIMEOUT_CLASSIFY`, `LLM_TIMEOUT_EXPAND`, `LLM_TIMEOUT_ANSWER` (por defecto `LLM_TIMEOUT`). Con cadena configurada, el plazo de un intento es `LLM_ATTEMPT_TIMEOUT` (por defecto la mitad del plazo de la tarea) y nunca más que el tiempo restante de la tarea. Duraciones inválidas usan el valor por defecto con aviso en el log. El aviso de SPEC-CORE-73.R3 sobre `SHUTDOWN_TIMEOUT` no cambia. | Test con servidor que no responde: el primer intento se corta en `LLM_ATTEMPT_TIMEOUT`, el segundo recibe el tiempo restante y la tarea completa no supera su plazo. |
| `SPEC-CORE-74.R12` | **Reintentos del SDK.** Con cadena configurada para la tarea, el cliente no usa el reintento automático del SDK (`option.WithMaxRetries(0)`) salvo en el último modelo de la cadena: el siguiente intento es el siguiente modelo, no el mismo modelo saturado. Sin cadena, el comportamiento actual (2 reintentos del SDK) no cambia. | Test con servidor que cuenta peticiones por modelo: con cadena, 1 petición al primero y hasta 3 al último; sin cadena, hasta 3 al único. |

### 2.4 Caché, respuesta y observabilidad

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-74.R13` | **Modelo real en la respuesta.** `PodResponse.Model` informa el modelo que redactó la respuesta, sea el configurado o uno de la cadena. El contrato del chat no cambia. | Test del router: tras un salto en `answer`, `model` es el del modelo que respondió. |
| `SPEC-CORE-74.R14` | **Caché GLOBAL solo con el modelo de la plataforma.** Una respuesta se guarda en la partición GLOBAL solo si, además de las reglas de SPEC-CORE-71, la redactó el modelo de `answer` efectivo del entorno (R1). Si la redactó otro modelo (configuración propia del tenant o salto de cadena), se guarda en la partición del tenant. Así un tenant con un modelo distinto, o un salto por saturación, no cambia las respuestas que comparten los demás. La lectura de caché no cambia: un acierto se sirve sin importar el modelo configurado, y `model` muestra quién la redactó. | Tests del router: respuesta global redactada por el modelo del entorno va a GLOBAL; redactada por el modelo propio del tenant o por un respaldo va a la partición del tenant. |
| `SPEC-CORE-74.R15` | **Métricas.** `aipods_llm_requests_total{task,model,outcome}` con `outcome` en `ok`, `error`, `timeout`, `refused`; y `aipods_llm_fallback_total{task,from,to}` por cada salto. Las etiquetas solo toman valores de la lista permitida y de las tres tareas (cardinalidad acotada), nunca el tenant ni texto de la consulta. | Test del collector: las líneas aparecen con las etiquetas esperadas tras una llamada correcta y tras un salto. |
| `SPEC-CORE-74.R16` | **Salud y logs.** `/healthz` mantiene el campo `llm` (modelo de `answer`, formato actual) y suma `llm_models` con `classify`, `expand`, `answer` y `fallback` del entorno. Cada salto escribe una línea de log con tarea, modelo de origen, modelo de destino, motivo y tenant, sin el texto de la consulta. | Test de handler de `/healthz`. Test: la línea de log del salto no contiene la consulta. |

### 2.5 Portal de administración

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-74.R17` | **Pantalla "Modelos LLM" por tenant.** En `TenantManagementView`, cada tenant tiene una acción "Modelos LLM" que abre un panel con tres selectores (clasificar, expandir, redactar) y una lista ordenada de respaldo de hasta 3 modelos. Cada selector ofrece "Heredar de la plataforma (`<modelo efectivo>`)" más los modelos de `allowed`. El panel muestra el modelo efectivo de cada tarea y guarda con el `PUT` de R8. Los errores 400 y 404 se muestran con el mensaje de la API. Solo visible para `platform_admin`. Textos en `i18n.js` (es y en). | `npm run build` y `eslint` sin errores. Prueba manual: guardar, recargar y ver el valor; elegir "Heredar" borra el valor guardado. |
| `SPEC-CORE-74.R18` | **Gobernanza de layout.** El panel reutiliza los componentes y tokens existentes: no cambia `index.css`, la navegación ni los breakpoints. Controles de al menos $44\text{px}$ de alto y contraste $\ge 7:1$. | Matriz LIEP de la sección 4. |

---

## 3. Escenarios de Aceptación (Gherkin BDD)

```gherkin
Feature: Modelo de Claude configurable por tarea y por tenant, con cadena de respaldo

  Scenario: Sin configuración nueva no cambia nada
    Given ANTHROPIC_MODEL=claude-opus-5-5 y ninguna variable LLM_MODEL_* ni LLM_FALLBACK_MODELS
    When un cliente envía una consulta sin caché
    Then las tres llamadas usan claude-opus-5-5
    And no hay saltos de modelo

  Scenario: Haiku para clasificar y expandir
    Given LLM_MODEL_CLASSIFY=claude-haiku-5-5 y LLM_MODEL_EXPAND=claude-haiku-5-5
    And ANTHROPIC_MODEL=claude-opus-5-5
    When un cliente envía una consulta sin caché
    Then la clasificación y la expansión usan claude-haiku-5-5 sin el parámetro fallbacks
    And la respuesta la redacta claude-opus-5-5
    And la respuesta informa model=claude-opus-5-5

  Scenario: Modelo elegido para un tenant desde el admin
    Given un platform_admin autenticado
    When configura answer=claude-sonnet-5-5 para el tenant ACME
    Then las consultas de ACME se redactan con claude-sonnet-5-5
    And los demás tenants siguen con la configuración del entorno
    And el cambio queda en la auditoría como llm_models.set

  Scenario: Modelo fuera de la lista permitida
    Given un platform_admin autenticado
    When intenta configurar un modelo que no está en LLM_ALLOWED_MODELS
    Then el sistema responde HTTP 400 con la lista de modelos permitidos
    And no guarda el cambio

  Scenario: Respaldo ante saturación
    Given LLM_MODEL_ANSWER=claude-opus-5-5 y LLM_FALLBACK_MODELS=claude-sonnet-5-5,claude-haiku-5-5
    And claude-opus-5-5 responde 529
    When un cliente envía una consulta sin caché
    Then la respuesta la redacta claude-sonnet-5-5
    And la respuesta informa model=claude-sonnet-5-5
    And aipods_llm_fallback_total{task="answer",from="claude-opus-5-5",to="claude-sonnet-5-5"} aumenta en 1
    And la respuesta no se guarda en la caché GLOBAL

  Scenario: Cadena agotada
    Given una cadena de respaldo configurada
    And todos los modelos responden 529
    When un cliente envía una consulta sin caché
    Then el chat responde HTTP 200 con el plan B actual de cada tarea
    And el tiempo total de cada tarea no supera su plazo

  Scenario: Variable vacía
    Given LLM_MODEL_EXPAND con un valor vacío o solo espacios
    When arranca el core
    Then usa ANTHROPIC_MODEL para esa tarea
```

---

## 4. Matriz de Evaluación de Impacto de Layout (Protocolo LIEP)

| Código Elemento | Componente del Layout | Estándar Evaluado | Estado / Resultado | Justificación Técnica & Salvaguarda |
|:---:|---|---|:---:|---|
| `[D1]` | `MAIN_CONTENT_PANEL` | **Full-Width Fluid** | ✅ `COMPLIANT` | El panel "Modelos LLM" se abre dentro de la vista de tenants, sin `max-width` rígido. |
| `[D1]` | `MAIN_CONTENT_PANEL` | **ISO 9241-210** | ✅ `COMPLIANT` | Selectores y botones de al menos $44\text{px}$; sin scroll vertical nuevo en la tabla de tenants. |
| `[D1]` | `MAIN_CONTENT_PANEL` | **WCAG 2.1 AAA** | ✅ `COMPLIANT` | Se usan los tokens de color existentes, con contraste $\ge 7:1$. |
| `[B1]` | `MAIN_TAB_NAVIGATION_BAR` | **SOC 2 Type II** | ✅ `COMPLIANT` | Sin cambios en la navegación ni en los badges de severidad. |

---

## 5. Plan de Implementación

1. **Core, configuración:** `internal/llm` (campo `Model` en `Request`, tabla de capacidades, tipo `Task`, ejecución de la cadena con plazos); `cmd/server/ai_config.go` (lectura y validación de variables).
2. **Core, tenant:** migración `0006`, métodos `GetLLMModels` y `SetLLMModels` en `internal/store` (memoria y Postgres), resolver en `cmd/server`, rutas en un archivo nuevo `cmd/server/llm_models.go`.
3. **Core, router:** `internal/router` pasa el modelo de cada tarea a `Classify`, `ExpandQuery` y `draftAnswer`; regla de caché GLOBAL (R14); `internal/telemetry` (métricas); `/healthz`.
4. **Admin:** panel en `TenantManagementView.jsx` y textos en `i18n.js`.
5. **Deploy (no versionado):** variables nuevas en el compose y en el ejemplo de entorno. Valores sugeridos para producción: `LLM_MODEL_CLASSIFY=claude-haiku-5-5`, `LLM_MODEL_EXPAND=claude-haiku-5-5`, `LLM_FALLBACK_MODELS=claude-sonnet-5-5,claude-haiku-5-5`, `LLM_TIMEOUT_CLASSIFY=10s`, `LLM_TIMEOUT_EXPAND=10s`.
6. **Verificación antes de activar en producción:** correr las 10 preguntas de categorías de ARCA con la configuración nueva y comparar pod elegido, citas y tiempos contra la actual. Gates: `go vet`, `gosec`, `go test` en el core; `npm audit`, `eslint`, `npm run build` en el admin.

## 6. Riesgos

- **Calidad con modelos chicos.** Haiku puede clasificar o expandir peor que Opus en normativa de ARCA. Mitigación: el paso 6 del plan, y volver atrás es quitar una variable.
- **Costo de la cadena.** Un salto paga la entrada dos veces. Con 429 o 529 el primer intento no se cobra; con vencimiento de plazo sí puede cobrarse. `aipods_llm_fallback_total` permite medirlo.
- **Límites compartidos.** Los modelos de una misma cuenta tienen límites separados por modelo, pero una caída general de Anthropic deja la cadena sin efecto. Ese caso lo cubren el modo degradado y el proveedor alternativo, fuera de esta spec.
