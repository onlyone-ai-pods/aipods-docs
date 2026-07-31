# 📜 SPEC: Registro de Issues Oficiales de Gobernanza y Roadmap

**ID:** SPEC-CORE-25  
**Épica Relacionada:** Gobernanza de Requerimientos, GitHub Issues & Feature Roadmap  
**Estado:** PUBLICADO & ACTIVO  
**Repositorio GitHub:** `https://github.com/onlyone-ai-pods/aipods-docs/issues`  

---

## 1. Registro Oficial de Issues Creados en GitHub

A continuación se detalla el listado de los 13 GitHub Issues registrados en el repositorio central `onlyone-ai-pods/aipods-docs`:

| ID Issue | Título de la Característica | Etiquetas (Labels) | Estado | URL GitHub |
| :---: | :--- | :--- | :---: | :--- |
| **`#1`** | `[FEAT] Cifrado At-Rest de Embeddings en Qdrant (AES-256 GCM)` | `feature`, `spec-approved`, `pod-core` | `CLOSED` | [Issue #1](https://github.com/onlyone-ai-pods/aipods-docs/issues/1) |
| **`#2`** | `[FEAT] Rate Limiting y Throttling Dinámico de Tokens por IP y Tenant` | `feature`, `pod-core`, `redis` | `CLOSED` | [Issue #2](https://github.com/onlyone-ai-pods/aipods-docs/issues/2) |
| **`#3`** | `[FEAT] Pipeline de CI/CD Automático en GitHub Actions con Docker y Helm` | `feature`, `needs-spec` | `OPEN` | [Issue #3](https://github.com/onlyone-ai-pods/aipods-docs/issues/3) |
| **`#4`** | `[FEAT] Dashboard de Telemetría OpenTelemetry & Prometheus/Grafana` | `feature`, `spec-approved`, `pod-core` | `CLOSED` | [Issue #4](https://github.com/onlyone-ai-pods/aipods-docs/issues/4) |
| **`#5`** | `[FEAT] POD_CORE_NOTIFICATIONS_TELEGRAM: Alertas Push de Cobro y Seguridad` | `feature`, `needs-spec`, `pod-essential` | `OPEN` | [Issue #5](https://github.com/onlyone-ai-pods/aipods-docs/issues/5) |
| **`#6`** | `[FEAT] POD_SOCIAL_MARKETING: Generación de Contenido & Meta Graph API` | `feature`, `needs-spec`, `pod-dynamic` | `OPEN` | [Issue #6](https://github.com/onlyone-ai-pods/aipods-docs/issues/6) |
| **`#7`** | `[FEAT] Exportación de Reportes PDF/CSV de Auditoría en Admin Review Hub` | `feature`, `spec-approved`, `frontend-admin` | `CLOSED` | [Issue #7](https://github.com/onlyone-ai-pods/aipods-docs/issues/7) |
| **`#8`** | `[FEAT] Integración JSON-RPC Odoo Billing: Confirmación de Pagos y Aprovisionamiento PROD_ACTIVE` | `feature`, `needs-spec`, `frontend-customer` | `CLOSED` | [Issue #8](https://github.com/onlyone-ai-pods/aipods-docs/issues/8) |
| **`#9`** | `[FEAT] Generación Automática del Dossier ISO 9001 & SOC 2 Type II (Global & Per-Tenant)` | `feature`, `spec-approved`, `pod-core` | `CLOSED` | [Issue #9](https://github.com/onlyone-ai-pods/aipods-docs/issues/9) |
| **`#10`** | `[FEAT] Herramienta CLI Unificada aipods-cli (Scaffold, Validate, Register & Audit)` | `feature`, `spec-approved`, `pod-core` | `CLOSED` | [Issue #10](https://github.com/onlyone-ai-pods/aipods-docs/issues/10) |
| **`#11`** | `[FEAT] Módulo Híbrido de Gestión de Secretos (Native Vault AES-256 & BYOV Bitwarden)` | `feature`, `spec-approved`, `pod-core` | `IN_PROGRESS (Fase 1 Native Vault Done)` | [Issue #11](https://github.com/onlyone-ai-pods/aipods-docs/issues/11) |
| **`#12`** | `[FEAT] Motor de Orquestación de Enjambre de Micro AI Pods (Swarm Protocol)` | `feature`, `spec-approved`, `pod-core` | `CLOSED` | [Issue #12](https://github.com/onlyone-ai-pods/aipods-docs/issues/12) |
| **`#13`** | `[FEAT] Motor de Resiliencia Enterprise (2FA OTP Interruption, NATS JobId, Saga Pattern & Policy Rulesets)` | `feature`, `needs-spec`, `pod-core` | `OPEN` | [Issue #13](https://github.com/onlyone-ai-pods/aipods-docs/issues/13) |
| **`#14`** | `[FEAT] Purga Reactiva de Caché Redis por Feedback 👎 y RPA AFIP` | `feature`, `spec-approved`, `pod-essential` | `CLOSED` | [Issue #14](https://github.com/onlyone-ai-pods/aipods-docs/issues/14) |
| **`#16`** | `[FEAT] Integración Frontend (Customer Portal & Admin Hub) para Native Vault Cifrado AES-256` | `feature`, `spec-approved`, `frontend-customer` | `CLOSED` | [Issue #16](https://github.com/onlyone-ai-pods/aipods-docs/issues/16) |
| **`#17`** | `[FEAT] Customer Portal: Modal de Invitaciones de Empleados con Asignación de Roles RBAC e IAM Audit Trail` | `feature`, `spec-approved`, `frontend-customer` | `CLOSED` | [Issue #17](https://github.com/onlyone-ai-pods/aipods-docs/issues/17) |

---

## 2. Instrucciones para la Resolución de Issues (Workflow SDD)

Para abordar cualquiera de los Issues `#1` al `#13`:

1. Crear rama `spec/issue-<ID>-<descripcion>` en `aipods-docs`.
2. Redactar o actualizar la especificación `.spec.md` en `specs/`.
3. Abrir Pull Request con `gh pr create` y solicitar review.
4. Tras el merge de la Spec, actualizar el Label del Issue a `spec-approved`.
5. Crear rama `feat/issue-<ID>-<descripcion>` en el repositorio correspondiente (`aipods-core-engine`, `aipods-frontend-customer` o `aipods-frontend-admin`).
6. Hacer commit final con el formato: `[ADD] <modulo>: <descripcion>. Closes #ID`.
