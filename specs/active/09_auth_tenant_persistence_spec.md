# SPEC-CORE-67: Autenticación por tenant y persistencia en PostgreSQL

**Estado:** IN_PROGRESS
**Épica:** 02 Security & Compliance / 01 Core Engine
**Repos afectados:** aipods-core-engine, aipods-frontend-customer, aipods-frontend-admin, deploy

## 1. Motivación

Con SPEC-CORE-66 el core ya usa Claude y un RAG real, pero sigue siendo inseguro y volátil:

- `internal/auth` valida JWT RS256, pero ninguna ruta usa el middleware.
- El `tenant_id` llega en el body o en la query, así que cualquier cliente puede operar sobre otro tenant, incluido su RAG.
- `/api/v1/vault/reveal`, `/api/v1/admin/*`, `/api/v1/pods/register` y `/api/v1/rag/ingest` no exigen identidad ni rol.
- Aprobaciones, secretos del vault y auditoría viven en memoria y se pierden en cada reinicio. El vault además guarda una copia en claro en RAM y arranca con secretos de ejemplo.
- `tenant.BuildMultiTenantFilter` arma SQL concatenando strings, lo que permitiría inyección SQL si se usara.

Hoy el único control es el basic auth de Traefik en el VPS.

## 2. Decisiones

| Tema | Decisión |
|---|---|
| Driver | `github.com/jackc/pgx/v5` (pool `pgxpool`), migraciones SQL embebidas con `embed` y aplicadas al arrancar. |
| Tokens | JWT RS256 emitidos por el propio core. Clave privada PEM en `AUTH_SIGNING_KEY` (env o vault). Vida de 8 h. |
| Contraseñas | argon2id (`golang.org/x/crypto/argon2`). |
| Despliegue gradual | `AUTH_MODE=off` (default, comportamiento actual) o `enforce`. Se pasa a `enforce` cuando los frontends tengan login; recién después se evalúa quitar el basic auth de Traefik. |
| Primer usuario | Si no hay usuarios y están `AUTH_BOOTSTRAP_EMAIL` y `AUTH_BOOTSTRAP_PASSWORD`, se crea un `platform_admin` en el tenant `GLOBAL`. |

## 3. Requisitos

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-67.R1` | Con `AUTH_MODE=enforce`, todas las rutas `/api/v1/*` exigen `Authorization: Bearer <JWT>`, salvo `/api/v1/auth/login`, `/api/v1/sandbox/*` y los webhooks firmados. Sin token o con token inválido: 401. `/healthz` queda público. | Tests de middleware. |
| `SPEC-CORE-67.R2` | Con `AUTH_MODE=enforce`, el tenant sale solo de los claims. Si el body o la query traen otro `tenant_id`, se responde 403. Solo `platform_admin` puede operar sobre otro tenant. | Test: token de A con body de B → 403. |
| `SPEC-CORE-67.R3` | Roles `customer`, `tenant_admin`, `auditor`, `platform_admin`. `/admin/*` exige `auditor` o `platform_admin`; `/pods/register` y `/vault/reveal`, `tenant_admin` o `platform_admin`. | Tabla de rutas × roles cubierta por tests. |
| `SPEC-CORE-67.R4` | `POST /api/v1/auth/login` con email y contraseña devuelve un JWT y el perfil (tenant, roles). Error genérico ante credenciales inválidas. En production, `AUTH_SIGNING_KEY` es obligatoria si `AUTH_MODE=enforce`. | Tests de login y de arranque. |
| `SPEC-CORE-67.R5` | Si `DATABASE_URL` está definida, el core se conecta a Postgres y aplica las migraciones versionadas al arrancar; si falla, no arranca. Sin `DATABASE_URL` usa almacenamiento en memoria (desarrollo). `/healthz` informa `database`. | Test de integración con Postgres. |
| `SPEC-CORE-67.R6` | Tablas: `schema_migrations`, `tenants`, `users`, `approvals`, `vault_secrets` (solo texto cifrado AES-256-GCM, clave única `tenant_id + key_name`), `audit_log` (append-only). Toda tabla de negocio tiene `tenant_id NOT NULL`. | Revisión de migraciones. |
| `SPEC-CORE-67.R7` | Todas las consultas usan parámetros (`$1`). Se elimina `BuildMultiTenantFilter`. | grep + revisión. |
| `SPEC-CORE-67.R8` | Aprobaciones, secretos del vault y auditoría sobreviven a un reinicio del core. El vault no guarda copias en claro ni carga secretos de ejemplo. | Test de integración: crear → nueva instancia → leer. |
| `SPEC-CORE-67.R9` | Login, aprobación/rechazo y revelado de secretos quedan en `audit_log` con usuario, tenant, IP y hora. | Test. |
| `SPEC-CORE-67.R10` | Los frontends tienen pantalla de login, guardan el token en memoria (no localStorage) y lo envían en cada llamada a `/api/v1`. | PR de frontends. |
| `SPEC-CORE-67.R11` | `POST /api/v1/auth/password` cambia la contraseña del usuario de la sesión. Exige la contraseña actual. Si la actual es incorrecta responde 400, no 401, para no cerrar la sesión. Exige una contraseña nueva distinta de 12 caracteres o más. Los dos portales tienen pantalla para usarlo. | Tests de handler + navegador. |
| `SPEC-CORE-67.R12` | `GET /api/v1/admin/users` lista usuarios sin el hash. `platform_admin` y `auditor` ven todos los tenants (opcional `?tenant_id=`); `tenant_admin` solo el suyo (otro tenant → 403); `customer` → 403. El portal admin tiene la pestaña Usuarios, que lista y da de alta. | Tests de handler. |
| `SPEC-CORE-67.R13` | `PATCH /api/v1/admin/users/:id` (`{"active": bool}`) y `POST /api/v1/admin/users/:id/password` los usan `platform_admin` (todos) o `tenant_admin` (solo su tenant, sin tocar cuentas `platform_admin` o `auditor`). Un usuario de otro tenant se ve como 404. Nadie se desactiva ni se resetea a sí mismo. Un usuario desactivado no puede entrar y su token deja de valer en la siguiente llamada, porque el middleware consulta `active`. Todo queda en `audit_log`. | Tests de handler + middleware. |
| `SPEC-CORE-67.R14` | `GET /api/v1/approvals/:token` es público y devuelve solo `{token, status, execution_result, decided_at}` (sin comando, tenant ni resumen), con `Cache-Control: no-store`. El token funciona como capacidad: `dryrun_` + UUID v4 (122 bits aleatorios); los tokens viejos de 8 caracteres responden 404. El portal de clientes consulta así el estado de sus acciones pendientes y muestra aprobado o rechazado, sin llamar a `/admin/approvals`. | Tests de handler + navegador. |
| `SPEC-CORE-67.R15` | Cambiar la propia contraseña (R11) o que un admin la resetee (R13) cierra todas las sesiones abiertas de ese usuario. `users.token_version` sube en cada cambio, el JWT lleva `tv` y el middleware rechaza con 401 un token cuyo `tv` no coincide. En el cambio propio, `POST /auth/password` devuelve un token nuevo para que esa sesión siga abierta. Los tokens anteriores a esta versión llevan `tv` 0, igual que los usuarios que nunca cambiaron la contraseña. | Tests de handler, middleware y store (memoria y Postgres). |

## 4. Fases

1. **Core (este PR):** migraciones, stores en Postgres con alternativa en memoria, login, middleware y roles detrás de `AUTH_MODE`.
2. **Frontends:** login en customer y admin (R10).
3. **Deploy:** `AUTH_SIGNING_KEY` y usuario inicial en el VPS, `AUTH_MODE=enforce`; después, decidir si se quita el basic auth. Hecho el 2026-11-06: `/api` quedó sin basic auth (el header `Authorization` no puede llevar a la vez Basic y Bearer); los portales y `/metrics` lo mantienen.
4. **Gestión de usuarios (R11–R13):** cambio de contraseña propia, listado, activar/desactivar y reseteo de contraseña desde los portales.
5. **Estado de aprobaciones para el cliente (R14):** el cliente ve si su acción fue aprobada o rechazada. En el mismo PR del core: Gin en modo release cuando `ENVIRONMENT=production` (salvo que `GIN_MODE` diga otra cosa), `gin.New()` con Logger y Recovery, y proxies de confianza limitados a loopback y redes privadas (configurable con `TRUSTED_PROXIES`), para que `X-Forwarded-For` no se pueda falsificar desde afuera.

## 5. Fuera de alcance

- SSO/OAuth2 externo (Google, Azure AD) y MFA.
- La vista "Equipo & Roles" del portal de clientes sigue con datos de ejemplo; conectarla a R12–R13 para `tenant_admin` queda para otra iteración.
- Mover a Postgres los pods dinámicos y las sesiones del sandbox.
