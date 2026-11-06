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

## 4. Fases

1. **Core (este PR):** migraciones, stores en Postgres con alternativa en memoria, login, middleware y roles detrás de `AUTH_MODE`.
2. **Frontends:** login en customer y admin (R10).
3. **Deploy:** `AUTH_SIGNING_KEY` y usuario inicial en el VPS, `AUTH_MODE=enforce`; después, decidir si se quita el basic auth.

## 5. Fuera de alcance

- SSO/OAuth2 externo (Google, Azure AD) y MFA.
- Mover a Postgres los pods dinámicos y las sesiones del sandbox.
