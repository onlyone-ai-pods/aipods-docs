# 📚 Matriz de Especificaciones Ejecutables (SDD Specs)

**Proyecto:** AI Pods Enterprise SaaS Platform  
**Organización GitHub:** `https://github.com/onlyone-ai-pods/aipods-docs`  
**Versión:** `8.2.0`  

---

## 🏛️ Suite Completa de 25 Especificaciones Organizada por Dominios

### Dominio 1: Arquitectura Core & Engine (`specs/01_architecture_core/`)
* **[`01_smart_router_spec.md`](file:///home/martin/server/aipods-docs/specs/01_architecture_core/01_smart_router_spec.md):** DynamicSmartRouter Go v7.1.0, HTTPSidecarAdapter, CircuitBreaker Pattern.
* **[`02_rag_pipeline_spec.md`](file:///home/martin/server/aipods-docs/specs/02_rag_pipeline_spec.md):** Pipeline RAG Vectorial, Embeddings 1536-dim, Invariante Multi-Tenant Qdrant.
* **[`03_multi_tenant_spec.md`](file:///home/martin/server/aipods-docs/specs/01_architecture_core/03_multi_tenant_spec.md):** Aislamiento Multi-Tenant estricto `WHERE (tenant_id == X OR tenant_id == 'GLOBAL')`.
* **[`04_semantic_cache_spec.md`](file:///home/martin/server/aipods-docs/specs/01_architecture_core/04_semantic_cache_spec.md):** Caché Semántico Redis Active-Active, latencia sub-10ms.
* **[`05_multimodal_and_multisource_rag_ingestion_spec.md`](file:///home/martin/server/aipods-docs/specs/01_architecture_core/05_multimodal_and_multisource_rag_ingestion_spec.md):** **[NUEVO v8.2.0]** Ingesta Multimodal (Markdown `.md`, reST `.rst`, Audio `.mp3`, Video `.mp4`, Google Drive) vía AI Pods Especializados.

### Dominio 2: Seguridad, Cumplimiento & DRP (`specs/02_security_and_compliance/`)
* **`07_enterprise_architecture_parameters_spec.md`:** Parámetros de arquitectura enterprise y Auth RS256.
* **`08_clean_code_and_security_linting_spec.md`:** Gate de linters `go vet`, `gosec`, `ESLint`, `npm audit`.
* **`14_dry_run_execution_protocol_spec.md`:** Protocolo `dry_run = true` y Human-in-the-Loop.
* **`15_pod_standards_and_policy_governance_spec.md`:** Estándares de Pods y políticas de gobernanza.
* **`16_iso9001_soc2_iso27001_compliance_spec.md`:** Marcos de cumplimiento normativo ISO 9001, SOC 2 Type II e ISO 27001.
* **`19_github_cli_and_spec_pr_governance_spec.md`:** Gobernanza de PRs y convención de ramas.

### Dominio 3: Plugins, Skills & Testing (`specs/03_plugin_and_skills/`)
* **`05_plugin_architecture_spec.md`:** Arquitectura de Plugins WASM y Pod-as-a-Service.
* **`06_lifecycle_and_governance_spec.md`:** Ciclo de vida y gobernanza de plugins.
* **`09_plugin_scaffold_and_agentic_skills_spec.md`:** Agentic Skills Kit (`.aipods/skills/`).
* **`10_internal_core_agentic_skills_spec.md`:** Skills internos del núcleo.
* **`11_product_roadmap_and_marketplace_spec.md`:** Roadmap de producto y Marketplace.
* **`18_incremental_execution_roadmap_and_vertical_slicing_spec.md`:** Ejecución incremental y slicing vertical.
* **`20_bdd_test_automation_and_tiered_evals_spec.md`:** Automatización de pruebas BDD `godog` y Evals.

### Dominio 4: Growth, Onboarding & Posicionamiento (`specs/04_customer_portal_growth/`)
* **`12_customer_portal_marketing_and_sandbox_spec.md`:** Landing Page "Servicio como Software" y Sandbox Interactivo.
* **`13_business_justifications_capabilities_and_limitations_spec.md`:** Justificación de negocio y capacidades.
* **`17_continuous_improvement_and_user_feedback_spec.md`:** Mejora continua y retroalimentación de usuarios.
* **`21_customer_onboarding_and_provisioning_spec.md`:** Onboarding auto-servicio en 3 pasos y AHA Moment.
* **`22_self_consuming_dogfooding_crm_and_billing_spec.md`:** Arquitectura de Autoconsumo Odoo CRM y Billing via NATS.

### Dominio 5: Catálogo Oficial de AI Pods (`specs/pods/`)
* **`01_afip_finance_spec.md`:** AI Pod AFIP / ARCA & Balances Financieros.
* **`02_evocrm_helpdesk_spec.md`:** AI Pod EvoCRM & Helpdesk Omnicanal.
* **`03_social_marketing_spec.md`:** AI Pod Social Marketing & Meta API.
* **`04_scm_logistics_spec.md`:** AI Pod Cadena de Suministros (SCM/WMS/MRP).
* **`05_github_devops_odoo_sh_spec.md`:** AI Pod GitHub API & Odoo.sh DevOps Integrator.
* **`06_sap_enterprise_and_b1_spec.md`:** AI Pod SAP Enterprise (S/4HANA/ECC) & Business One.
