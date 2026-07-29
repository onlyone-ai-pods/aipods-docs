<p align="center">
  <img src=".github/assets/aipods_banner_docs.jpg" alt="AI Pods Docs by OnlyOne" width="100%" style="border-radius: 8px;">
</p>

# 📜 AI Pods Enterprise (SaaS) - Documentación & Especificaciones (`aipods-docs`)

Este repositorio contiene la documentación oficial, las especificaciones ejecutables SDD, el backlog del producto y los contratos OpenAPI de **AI Pods Enterprise SaaS Platform**.

## 📄 Estructura de Documentación y Módulos del Workspace

* **[`VERSION`](file:///home/martin/server/aipods-docs/VERSION):** Versión actual de la plataforma (`25.0.0`).
* **[`LICENSE`](file:///home/martin/server/aipods-docs/LICENSE):** Licencia Propietaria del Autor (Martin Llanos).
* **[`DEVELOPER_ONBOARDING_AND_GIT_WORKFLOW.md`](file:///home/martin/server/aipods-docs/DEVELOPER_ONBOARDING_AND_GIT_WORKFLOW.md):** **[NUEVO]** Guía Oficial de Onboarding, Instalación, Pruebas Locales y Flujo de Pull Requests (PRs).
* **[`scripts/`](file:///home/martin/server/aipods-docs/scripts/):** **[NUEVO]** Scripts de Automatización Local (`deploy_stack.sh`, `start_local_stack.sh`, `test_functional_e2e.sh`, `stop_local_stack.sh`).
* **[`.aipods/rules/mcp_codebase_memory.md`](file:///home/martin/server/aipods-docs/.aipods/rules/mcp_codebase_memory.md):** Regla de uso prioritario del MCP `codebase-memory-mcp`.
* **[`.aipods/skills/sdd-spec-writer/SKILL.md`](file:///home/martin/server/aipods-docs/.aipods/skills/sdd-spec-writer/SKILL.md):** Agentic Skill para redacción de especificaciones SDD y BDD.
* **[`docs/BACKLOG.md`](file:///home/martin/server/aipods-docs/docs/BACKLOG.md):** Backlog del producto con 12 Épicas e Historias de Usuario consolidadas.
* **[`docs/SDD.md`](file:///home/martin/server/aipods-docs/docs/SDD.md):** Documento Maestro de Diseño de Software (SDD v25.0.0).
* **[`specs/`](file:///home/martin/server/aipods-docs/specs/README.md):** Suite Completa de 34 Especificaciones SDD organizada en **5 Dominios Temáticos**.

---

## 🏛️ Repositorios del Ecosistema en el Servidor (`/home/martin/server/`)

1. **`aipods-docs`** (`/home/martin/server/aipods-docs`): Documentación, Specs SDD y OpenAPI.
2. **`aipods-core-engine`** (`/home/martin/server/aipods-core-engine`): Backend en Go 1.22+, Smart Router y DBs.
3. **`aipods-frontend-customer`** (`/home/martin/server/aipods-frontend-customer`): Portal de Clientes React 18 / Vite.
4. **`aipods-frontend-admin`** (`/home/martin/server/aipods-frontend-admin`): Portal de Administración React 18 / Vite.

---

## 🔒 Licencia

Este proyecto y su documentación están protegidos bajo una **Licencia Propietaria del Autor**. Todos los derechos reservados © 2026 Martin Llanos. Ver el archivo [`LICENSE`](file:///home/martin/server/aipods-docs/LICENSE) para más detalles.
