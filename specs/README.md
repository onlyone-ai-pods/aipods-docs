# 📚 Matriz de Especificaciones Ejecutables (SDD Specs)

**Proyecto:** AI Pods Enterprise SaaS Platform  
**Organización GitHub:** [`https://github.com/onlyone-ai-pods/aipods-docs`](https://github.com/onlyone-ai-pods/aipods-docs)  
**Estándar de Arquitectura:** ISO/IEC/IEEE 26514:2022 & Consolidación 3-Tier SDD  
**Guía de Onboarding:** [`../DEVELOPER_ONBOARDING_AND_GIT_WORKFLOW.md`](../DEVELOPER_ONBOARDING_AND_GIT_WORKFLOW.md)  
**Índice Maestro:** [`SPEC_MASTER_INDEX.md`](SPEC_MASTER_INDEX.md)  

---

## 🏛️ Estructura Consolidada de Especificaciones por Documento Maestro

Toda la documentación técnica del proyecto se encuentra organizada en **4 Especificaciones Maestras**, eliminando archivos fragmentados y garantizando la navegabilidad directa en GitHub:

| Documento Maestro Consolidado | Specs ID Incluidas | Descripción de Arquitectura | Estado |
|---|---|---|:---:|
| 📂 [`01_CORE_ENGINE_MASTER_SPEC.md`](01_CORE_ENGINE_MASTER_SPEC.md) | `SPEC-CORE-01` a `15`, `33`, `35`, `36`, `42`, `46`, `47` | DynamicSmartRouter, RAG Vectorial Qdrant, Multi-Tenant Isolation, Telemetría CMMI Nivel 4 y Backend Go i18n. | ✅ `CONSOLIDATED` |
| 📂 [`02_SECURITY_AND_COMPLIANCE_MASTER_SPEC.md`](02_SECURITY_AND_COMPLIANCE_MASTER_SPEC.md) | `SPEC-CORE-16` a `27`, `32`, `34`, `38`, `59` | SGSI ISO 27001, ISO 9001:2015, SOC 2 Type II, Tenant Secrets Vault (AES-256 GCM) y BYOV Bitwarden Secrets Manager. | ✅ `CONSOLIDATED` |
| 📂 [`03_ADMIN_HUB_GOVERNANCE_MASTER_SPEC.md`](03_ADMIN_HUB_GOVERNANCE_MASTER_SPEC.md) | `SPEC-CORE-28` a `30`, `37`, `38`, `39`, `40` | Admin Review Hub, Human-in-the-Loop Approval, IAM Audit Trail firmado SHA-256 y Senior Consultant Governance. | ✅ `CONSOLIDATED` |
| 📂 [`04_CUSTOMER_PORTAL_MASTER_SPEC.md`](04_CUSTOMER_PORTAL_MASTER_SPEC.md) | `SPEC-CORE-31`, `41`, `44`, `45` | Customer Portal React 18, Perfil Mi Cuenta, 2FA TOTP, Protocolo LIEP UI Governance, i18n/l10n & Odoo Partner Locale Sync. | ✅ `CONSOLIDATED` |
| 📂 [`05_NATIVE_CAMPAIGN_ENGINE_MASTER_SPEC.md`](05_NATIVE_CAMPAIGN_ENGINE_MASTER_SPEC.md) | `SPEC-CORE-48` | Native Campaign Engine, Scheduler por Fechas, Componentes 100vw Xiaomi Style, Micro-Componentes Promocionales & SEO. | ✅ `CONSOLIDATED` |
| 📂 [`06_POD_WEB_DESIGNER_MASTER_SPEC.md`](06_POD_WEB_DESIGNER_MASTER_SPEC.md) | `SPEC-CORE-49` | AI Pod POD_WEB_DESIGNER en VPS Aislada, Multimodal Vision Feedback, Visual Inspector Mode (Odoo Debug Style) & A/B Testing. | ✅ `CONSOLIDATED` |

---

## 📁 Especificaciones Activas Temporales (`specs/active/`)

Las especificaciones en desarrollo se crean temporalmente en [`specs/active/`](active/README.md). Al ser aprobadas e implementadas, se consolidan automáticamente en su Documento Maestro correspondiente.
