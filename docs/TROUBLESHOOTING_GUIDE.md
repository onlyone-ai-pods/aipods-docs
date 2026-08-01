# 🛠️ Guía Oficial de Solución de Problemas & Diagnóstico (Troubleshooting)

**Plataforma:** AI Pods Enterprise SaaS Platform  
**Estándar de Documentación:** GitHub/Kubernetes-Grade Operations Guide  
**Versión:** `v81.0.0` (Conforme a ISO 27001 & CMMI Level 4)  

---

## 🔍 Matriz de Diagnóstico y Resolución Rápida (Top 10 Fallas Conocidas)

| ID / Dominio | Síntoma / Mensaje de Error | Causa Raíz Probable | Comando o Acción de Resolución |
|---|---|---|---|
| **ERR-01 (LaTeX)** | `'_' allowed only in math mode` o `'&' can not be used here` | Sintaxis KaTeX/Math con caracteres reservados en `.md`. | Reemplazar `_` por `-` en subíndices de `\text{}` y `&` por la conjunción `y`. |
| **ERR-02 (Go)** | `go vet: error loading packages` | Dependencias de módulos Go no sincronizadas. | Ejecutar `cd aipods-core-engine && go mod tidy`. |
| **ERR-03 (AST)** | `gosec AST scanner flaw detected` | Variable de entorno o clave dura en código Go. | Utilizar `internal/vault/vault.go` en lugar de strings duros. |
| **ERR-04 (Vite)** | `[vite] Internal server error: Failed to resolve import` | Importación relativa rota en React 18. | Verificar la ruta relativa del componente JSX en `src/components/`. |
| **ERR-05 (Skills)** | `Error: Se detectaron rutas locales absolutas hardcoded` | Alguna Skill contiene una ruta local (ej. `/home/martin/...`). | Ejecutar `bash scripts/sync_skills.sh` para auditar y limpiar rutas locales. |
| **ERR-06 (Redis)** | `dial tcp 127.0.0.1:6379: connect: connection refused` | Instancia local de Redis no iniciada. | Arrancar Redis local o ejecutar `bash scripts/start_local_stack.sh`. |
| **ERR-07 (Ports)** | `listen tcp :8080: bind: address already in use` | Servidor Go anterior en ejecución background. | Ejecutar `bash scripts/stop_local_stack.sh`. |
| **ERR-08 (Links)** | `file:/// protocol broken link in GitHub view` | Enlace escrito con esquema `file:///` local. | Reemplazar por enlace relativo Markdown dinámico `specs/SPEC_MASTER_INDEX.md`. |
| **ERR-09 (2FA)** | `Saga interrumpe con AWAITING_2FA_OTP` | Acción de alto riesgo requiere código de 6 dígitos. | Ingresar el código TOTP simulado `123456` en el Admin Login Hub. |
| **ERR-10 (Docs)** | `Falta el archivo DEVELOPER_ONBOARDING_AND_GIT_WORKFLOW.md` | El archivo de onboarding se movió o renombró. | Verificar presencia en la raíz de `aipods-docs/`. |

---

## 🛠️ Procedimiento de Recuperación y Limpieza del Entorno

Si tu entorno local queda en estado inconsistente, ejecuta la secuencia de recuperación de 1 línea:

```bash
bash scripts/stop_local_stack.sh && bash scripts/deploy_stack.sh
```
