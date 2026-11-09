# SPEC-CORE-71: Conexión de Caché Semántico al Router con Reutilización Global

**Estado:** DRAFT (IN_PROGRESS)  
**Épica:** 01 Core Architecture & Engine / 02 Security & Compliance  
**Issue:** [#39](https://github.com/onlyone-ai-pods/aipods-docs/issues/39)  
**Repos afectados:** `aipods-core-engine`, `aipods-frontend-customer`, `aipods-frontend-admin`, `aipods-docs`

---

## 1. Motivación y Contexto

Actualmente, `SemanticCacheManager` está desconectado del flujo principal de consultas en `RouteAndExecute`:
1. El Core Engine no consulta el caché antes de procesar una pregunta, gastando llamadas a Claude y al Vector Store en cada request.
2. Las respuestas positivas no se indexan ni se comparten entre clientes, perdiendo la oportunidad de acelerar consultas recurrentes sobre normativas públicas de ARCA.
3. El almacenamiento actual es un mapa volátil en memoria y no persiste entre reinicios.

---

## 2. Requisitos de la Especificación

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-71.R1` | **Conexión en el Router**: `RouteAndExecute` consulta primero el caché (`GetCachedResponse`). Si hay acierto, retorna la respuesta en < 10ms marcando `cached: true`. | Test de router verificando 0 llamadas a LLM ante una consulta repetida. |
| `SPEC-CORE-71.R2` | **Nivel de Caché GLOBAL (Público)**: Las respuestas a consultas generales sobre manuales y normativas tributarias se almacenan bajo el tenant `GLOBAL` y están disponibles para todos los clientes de la plataforma. | Test multi-tenant: Tenant A genera la respuesta, Tenant B la obtiene del caché. |
| `SPEC-CORE-71.R3` | **Nivel de Caché TENANT (Privado)**: Consultas que involucran datos contables propios, facturas, clientes en Odoo o secretos se aíslan estrictamente con su `tenant_id` y nunca se comparten. | Test de aislamiento: Tenant B no puede acceder a las respuestas en caché de Tenant A. |
| `SPEC-CORE-71.R4` | **Ciclo de Vida y Purga Reactiva**: Las respuestas se guardan como `PROVISIONAL`. Al recibir 👍 se promueven a `VERIFIED`. Al recibir 👎 (`POST /api/v1/feedback`), se purgan de inmediato del caché (`PurgeKey`). | Test de purga: tras 👎, la siguiente consulta ejecuta búsqueda primaria. |
| `SPEC-CORE-71.R5` | **Persistencia en Redis**: `SemanticCacheManager` utiliza Redis (`REDIS_URL`) con TTL configurable (por defecto 24 horas a 7 días). | Test de integración con Redis en contenedor. |

---

## 3. Plan de Implementación

1. Modificar `internal/router/dynamic_router.go` para inyectar `SemanticCacheManager` y envolver el ciclo de ejecución.
2. Incorporar lógica de partición de claves (`GLOBAL` para RAG tributario, `TENANT_ID` para consultas de pods privados).
3. Conectar el handler de feedback (`POST /api/v1/feedback`) para purga reactiva.
4. Conectar Redis backend para persistencia duradera.
