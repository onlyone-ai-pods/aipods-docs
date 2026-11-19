# SPEC-CORE-73: Despliegue Blue-Green sin Cortes (Graceful Shutdown, Readiness, Estado Compartido y Migraciones Expand/Contract)

**Estado:** DRAFT (IN_PROGRESS)  
**Épica:** 01 Core Architecture & Engine  
**Issue:** [#44](https://github.com/onlyone-ai-pods/aipods-docs/issues/44)  
**Repos afectados:** `aipods-core-engine`, `aipods-docs`, archivos de despliegue de `deploy/` (no versionados)  
**Depende de:** [SPEC-CORE-67](09_auth_tenant_persistence_spec.md), [SPEC-CORE-71](11_semantic_cache_shared_reuse_spec.md), [SPEC-CORE-72](13_afip_intent_rag_stability_spec.md) (numeración de migraciones)

---

## 1. Motivación y Contexto

Una auditoría del core (`main` @ `a9c2024`, 2026-11-19) evaluó si soporta un despliegue paralelo con dos colores detrás de Traefik (azul = versión vigente, verde = versión nueva), drenando las conexiones del color viejo antes de apagarlo. Resultado: hoy cada deploy corta las peticiones en curso.

1. **No hay apagado elegante.** `cmd/server/main.go` arranca con `r.Run(":" + port)`: no escucha `SIGINT`/`SIGTERM`, no llama a `http.Server.Shutdown` y no fija timeouts. Un `SIGTERM` termina el proceso y corta las respuestas de Claude en vuelo. El `defer st.Close()` nunca se ejecuta y el cliente Redis no se cierra.
2. **No hay readiness.** `/healthz` responde 200 aunque Postgres esté caído (solo cambia el texto a `postgres:down`), hace un `Ping` a la base en cada llamada siendo público, y reporta una versión fija (`60.0.0`). No existe un estado de drenado que avise al proxy.
3. **Hay estado en memoria del proceso.** El rate limiter (`security.RedisRateLimiter`) es un mapa en RAM aunque su nombre diga Redis, y toma la clave del header `X-Tenant-ID`. Las sagas (`resilience.SagaOrchestrator`), los pods dinámicos (`DynamicSmartRouter.RegisterDynamicPod`) y las sesiones del sandbox (`sandbox.SessionManager`) también viven en RAM: con dos colores una saga iniciada en azul no existe en verde, y un pod registrado se pierde en cada reinicio.
4. **Las migraciones no tienen política de compatibilidad.** `store.OpenPostgres` aplica las migraciones embebidas al arrancar, con `pg_advisory_lock` (correcto). Pero nada impide un `DROP` o `RENAME` que rompa al color viejo mientras sigue sirviendo, y no hay `lock_timeout`.
5. **El despliegue no permite dos versiones a la vez.** El compose de producción fija `container_name: aipods_core` y `levantar_vps.sh` ejecuta `up -d --build`, que detiene el contenedor viejo (10 s de gracia por defecto) antes de que el nuevo esté sano.

Lo que ya está bien y no cambia: JWT firmado con `AUTH_SIGNING_KEY` compartida y validado contra Postgres (SPEC-CORE-67); usuarios, aprobaciones, vault, auditoría y RAG léxico en Postgres; caché semántica en Redis con prefijo versionado (SPEC-CORE-71). No hay WebSockets, SSE ni consumidores de colas.

---

## 2. Requisitos de la Especificación

### 2.1 Apagado elegante y drenado

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-73.R1` | **Servidor con señales.** `main()` crea un contexto con `signal.NotifyContext(ctx, SIGINT, SIGTERM)` y delega en `run(ctx, getenv) error`. El servidor es un `http.Server` explícito con `ReadHeaderTimeout` 10 s, `IdleTimeout` 120 s (mayor que el `idleConnTimeout` de 90 s de Traefik), sin `WriteTimeout` global, y `BaseContext` derivado de un contexto cancelable propio. Los errores de inicialización vuelven como `error` desde `run` (no `log.Fatalf`), para que los `defer` se ejecuten. | `TestSPEC_CORE_73_R1_*`: `run` con un contexto que se cancela termina sin error y libera el puerto. |
| `SPEC-CORE-73.R2` | **Secuencia de drenado.** Al recibir la señal: (1) se restablece el manejo por defecto de señales, así una segunda señal mata el proceso; (2) el estado pasa a *draining* y `/readyz` responde 503; (3) espera `DRAIN_DELAY` (default 5 s) para que Traefik saque la instancia; (4) `srv.Shutdown` con plazo `SHUTDOWN_TIMEOUT` (default 60 s), que deja de aceptar conexiones y espera las peticiones en curso; (5) si vence el plazo, cancela el `BaseContext` (corta las llamadas al LLM) y llama a `srv.Close`; (6) espera los workers de fondo (R10); (7) cierra Redis y por último Postgres. Durante el drenado toda respuesta lleva `Connection: close`. Duraciones inválidas usan el default con aviso en el log. | Test de integración con `httptest`: una petición lenta (3 s) iniciada antes de la señal termina con 200; una petición nueva después de la señal no llega al handler; `/readyz` devuelve 503 desde el paso 2. Test de orden de cierre con fakes: Redis antes que Postgres, ambos después del último handler. |
| `SPEC-CORE-73.R3` | **Cota del LLM.** `AnthropicClient.Complete` aplica `context.WithTimeout` con `LLM_TIMEOUT` (default 45 s). Si `SHUTDOWN_TIMEOUT` no es mayor que `LLM_TIMEOUT`, el core lo avisa en el log al arrancar. | Test con cliente HTTP falso que no responde: `Complete` devuelve error de contexto vencido dentro de `LLM_TIMEOUT`. |
| `SPEC-CORE-73.R4` | **Auditoría que sobrevive al drenado.** `auditor.recordAs` escribe con `context.WithoutCancel(c.Request.Context())` y un plazo de 2 s, así un evento no se pierde si el cliente corta o el contexto de la petición se cancela. | Test: con el contexto de la petición cancelado, el evento se guarda en el store. |

### 2.2 Sondas de salud

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-73.R5` | **Liveness y readiness separados.** `GET /livez` responde 200 si el proceso atiende, sin consultar dependencias. `GET /readyz` responde 503 `{"status":"draining"}` durante el drenado, 503 `{"status":"not_ready"}` si el `Ping` a Postgres (plazo 1 s) falla, y 200 `{"status":"ready"}` en otro caso. Ambas se registran antes del middleware de autenticación y del rate limiter, e incluyen `version` y `color`. `/readyz` no se publica en Traefik: solo lo consulta la sonda del balanceador contra el contenedor. | Tests de handler para los tres estados de `/readyz` y para `/livez` con la base caída (200). |
| `SPEC-CORE-73.R6` | **`/healthz` compatible y barato.** `/healthz` mantiene sus campos actuales para no romper el healthcheck existente, pero deja de hacer `Ping` a la base en cada llamada: el campo `database` muestra el resultado de la última sonda de readiness. `version` deja de ser fija: se inyecta en la compilación (`-ldflags "-X main.buildVersion=<VERSION>-<sha corto>"`) y `color` sale de `DEPLOY_COLOR`. El core publica `aipods_build_info{version,color} 1` en `/metrics`. | Test: N llamadas a `/healthz` no generan pings al store. Test del collector: la línea `aipods_build_info` aparece con los valores configurados. |

### 2.3 Cierre de recursos

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-73.R7` | **Cierre ordenado.** `SemanticCacheManager` expone `Close() error`, que cierra el backend si implementa `io.Closer`. El cliente Redis es uno solo, compartido entre la caché semántica y el rate limiter (R8), y se cierra una vez. El pool de Postgres se cierra último. | Test con backend falso: `Close` del manager cierra el backend una vez. |

### 2.4 Estado compartido entre colores

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-73.R8` | **Rate limiter en Redis.** Ventana fija de 1 minuto con `INCR` + `EXPIRE` en una transacción, clave `aipods:ratelimit:v1:<sujeto>:<ventana>`, mismo límite que hoy (300 RPM). El sujeto es `tenant:<id>` tomado del contexto autenticado (`tenant.FromContext`), o `ip:<ClientIP>` si no hay tenant; el header `X-Tenant-ID` deja de usarse. Si Redis falla, deja pasar la petición y lo registra (fail-open). Sin `REDIS_URL` y fuera de producción usa el limitador en memoria actual. | Test con Redis en memoria (miniredis o equivalente): dos instancias del limitador comparten la cuota; la petición 301 del minuto recibe 429. Test: el header `X-Tenant-ID` no cambia la clave. Test: con Redis caído, la petición pasa. |
| `SPEC-CORE-73.R9` | **Sagas en Postgres.** Tabla `sagas` (migración expand). El ID es un UUID. `VerifyOTPAndExecute` hace la transición con un `UPDATE ... WHERE saga_id = $1 AND status = 'AWAITING_2FA_OTP' RETURNING ...`, igual que `DecideApproval`; una segunda verificación devuelve conflicto. El contrato HTTP de `/api/v1/saga/*` no cambia. | Test de store (memoria y Postgres): una saga creada por una instancia se verifica desde otra; dos verificaciones concurrentes, solo una gana. |
| `SPEC-CORE-73.R10` | **Pods dinámicos persistentes.** Tabla `dynamic_pods` (migración expand). `POST /api/v1/pods/register` escribe en la tabla. Cada instancia carga los pods al arrancar y los relee cada `DYNAMIC_PODS_SYNC_INTERVAL` (default 30 s) en un worker que termina al cancelarse el contexto de señales y que el apagado espera (R2 paso 6). | Test: un pod registrado en la instancia A aparece en la B tras una sincronización. Test: el worker sale al cancelar el contexto. |
| `SPEC-CORE-73.R11` | **Sesiones del sandbox en Redis.** Clave `aipods:sandbox:v1:<session_id>`, TTL 30 min, mismo contenido que hoy. El comportamiento visible no cambia (incluida la creación automática de una sesión desconocida), pero la sesión y su contador son los mismos en ambos colores. Sin `REDIS_URL` y fuera de producción, memoria. | Test: una sesión creada por una instancia se lee desde otra con el mismo `tenant_id` y `query_count`. |
| `SPEC-CORE-73.R12` | **Sin fallbacks silenciosos en producción.** Con `ENVIRONMENT=production`, el core no arranca si falta `DATABASE_URL` o `REDIS_URL`, en vez de caer a memoria. | Test de `buildStore` y `buildSemanticCache` con `ENVIRONMENT=production` y la variable vacía: devuelven error. |
| `SPEC-CORE-73.R13` | **Bootstrap del admin idempotente.** Si dos instancias arrancan con la tabla `users` vacía, la que pierde la carrera recibe `ErrConflict` y lo trata como éxito. | Test con store en memoria: dos llamadas concurrentes a `bootstrapAdmin` no devuelven error y queda un solo usuario. |

### 2.5 Migraciones expand/contract

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-73.R14` | **Solo expand al arrancar.** Las migraciones de `internal/store/migrations/*.sql` (las que corren al iniciar el core, con el color viejo todavía sirviendo) solo agregan: tablas, columnas nulas o con default, índices sobre tablas chicas. Un test rechaza en esos archivos `DROP TABLE/COLUMN/INDEX`, `RENAME COLUMN/TO`, `ALTER COLUMN ... TYPE` y `ALTER COLUMN ... SET NOT NULL`. Las queries siguen usando listas de columnas explícitas, nunca `SELECT *`. | `TestSPEC_CORE_73_R14_StartupMigrationsAreExpandOnly` pasa con `0001` a `0003` y falla con un archivo de prueba que contenga `DROP COLUMN`. |
| `SPEC-CORE-73.R15` | **Cotas de lock.** Cada migración corre con `SET LOCAL lock_timeout = '5s'` y `SET LOCAL statement_timeout = '120s'`. Si no consigue el lock, el arranque falla con un error claro y el color nuevo no queda listo, sin bloquear las queries del color viejo. | Test sobre Postgres de prueba: con una transacción que retiene un lock sobre la tabla, la migración falla en unos 5 s con un mensaje que nombra la migración. |
| `SPEC-CORE-73.R16` | **Contract fuera del arranque.** Los cambios que quitan o cambian estructura van en `internal/store/migrations/contract/*.sql` y se aplican solo con `aipods-cli migrate contract`, cuando el color viejo ya no existe. Se registran en `schema_migrations` con prefijo `contract/`. Los índices sobre tablas grandes (`rag_chunks`, `audit_log`) se crean con `CREATE INDEX CONCURRENTLY` por la misma vía, fuera de transacción. | Test: el arranque no aplica archivos de `contract/`; el comando sí, una sola vez. |

La numeración de las migraciones nuevas sigue a la última que haya entrado en `main` (SPEC-CORE-72 reserva `0004`).

### 2.6 Despliegue por colores en oracle-vps

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-73.R17` | **Imagen.** El `Dockerfile` declara `STOPSIGNAL SIGTERM` e inyecta la versión con `-ldflags` (R6). El binario sigue siendo PID 1 en forma exec. | `docker inspect` muestra `StopSignal: SIGTERM`; `/livez` devuelve la versión del build. |
| `SPEC-CORE-73.R18` | **Compose por color.** El core sale del compose principal a `deploy/docker-compose.core.yml`, levantado como proyecto `aipods-blue` o `aipods-green`. Postgres, Redis, Qdrant, NATS y los portales quedan en el proyecto `aipods` actual (sin mover volúmenes). El servicio del core: sin `container_name`; `stop_grace_period: 75s` (mayor que `DRAIN_DELAY` + `SHUTDOWN_TIMEOUT`); `DEPLOY_COLOR`; healthcheck a `/livez` cada 5 s, 3 reintentos, `start_period` 30 s; redes `inverseproxy_public` y `aipods_internal` (externas); los mismos labels de Traefik en ambos colores (routers `aipods-api`, `aipods-metrics`, `aipods-api-insecure` y servicio `aipods-api`), más `loadbalancer.healthcheck.path=/readyz`, `interval=2s`, `timeout=1s`. Ambos colores comparten `DATABASE_URL`, `REDIS_URL`, `AUTH_SIGNING_KEY` y `VAULT_MASTER_KEY`. | Con los dos colores arriba, Traefik muestra un servicio `aipods-api` con dos servidores; al detener uno, queda uno sin errores en el dashboard. |
| `SPEC-CORE-73.R19` | **Script de cambio.** `deploy/switch_color.sh`, corrido en el VPS: lee el color activo de `deploy/.active_color`; construye y levanta el otro con `up -d --build --wait`; verifica `/readyz` dentro del contenedor nuevo; espera 6 s (3 sondas de Traefik); detiene el color viejo con `stop -t 75` y luego `down`; guarda el color nuevo. Rollback = correr el script otra vez, válido mientras la migración aplicada haya sido solo expand (R14). `levantar_vps.sh` deja de recrear el core. | Ejecución en el VPS con el OK escrito de Martin (regla de deploys a producción). |
| `SPEC-CORE-73.R20` | **Cero cortes medidos.** Durante un cambio de color, una carga constante (al menos 5 req/s a `/api/v1/auth/me` con token válido) más una petición de chat en curso de más de 10 s no producen respuestas 5xx, resets de conexión ni errores de Traefik; la petición de chat larga termina con 200. | Script de prueba en `deploy/` que corre `hey` o `curl` en bucle durante `switch_color.sh` y reporta el conteo de códigos HTTP. Resultado adjunto al cierre del issue. |

---

## 3. Fuera de Alcance

- Streaming (SSE o WebSockets) del chat. Si se agrega, necesitará su propia spec: aviso de reconexión al entrar en drenado y cierre desde `srv.RegisterOnShutdown`.
- Blue-green de los portales `admin` y `customer`. Son estáticos; queda como seguimiento conservar en la imagen nueva los assets hasheados de la versión anterior.
- Persistencia del billing de Odoo (hoy es un mock en memoria).
- Rotación de `AUTH_SIGNING_KEY` o `VAULT_MASTER_KEY` con varias claves activas.
- Despliegue en más de un host o con orquestador (Swarm, Kubernetes).

---

## 4. Plan de Implementación

Cuatro PRs de código en `aipods-core-engine`, en este orden. Cada uno se puede desplegar solo.

1. **Apagado y sondas (R1-R7, R17).** `cmd/server/main.go` pasa a `run(ctx)`; nuevo `cmd/server/health.go` con `/livez`, `/readyz` y el middleware de drenado; `Close` en `internal/rag/semantic_cache.go`; `LLM_TIMEOUT` en `internal/llm/anthropic.go`; `WithoutCancel` en `cmd/server/platform.go`; `Dockerfile` con `STOPSIGNAL` y `ldflags`.
2. **Despliegue por colores (R18-R20).** Archivos en `deploy/` (fuera de git): `docker-compose.core.yml`, `switch_color.sh`, prueba de carga, y quitar el core de `docker-compose.oracle.yml`. Requiere el OK escrito de Martin para correrlo en producción. Antes del primer cambio se migra una vez el contenedor actual al proyecto `aipods-blue`, con un corte breve anunciado.
3. **Estado compartido y migraciones (R8, R12-R16).** `internal/security/ratelimiter.go` sobre Redis; fail-fast en `cmd/server/platform.go` y `semantic_cache.go`; `bootstrapAdmin` idempotente; test de política y cotas en `internal/store/`; subcomando `migrate contract` en `cmd/aipods-cli`.
4. **Sagas, pods dinámicos y sandbox (R9-R11).** Migración expand con `sagas` y `dynamic_pods`; métodos en `store.Store` (memoria y Postgres); `resilience`, `router` y `sandbox` pasan a usar el store y Redis.

Commits con el formato `[TAG] modulo: resumen (SPEC-CORE-73)` y tests nombrados `TestSPEC_CORE_73_RN_*`. Gates: `go vet`, `gosec` y `go test ./...` en el core.
