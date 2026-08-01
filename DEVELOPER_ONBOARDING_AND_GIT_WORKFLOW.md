# 🚀 Guía de Onboarding & Flujo de Trabajo Git PR (Pull Requests)

**AI Pods Enterprise SaaS Platform**  
*Documentación Oficial para Desarrolladores y Socios de Proyecto — Release v77.0.0*

---

## 📋 1. Requisitos Previos del Entorno

Antes de comenzar a programar, asegúrate de tener instaladas las siguientes herramientas en tu entorno Linux / macOS / WSL:

| Herramienta | Versión Mínima | Propósito |
| :--- | :--- | :--- |
| **Go** | `1.22+` | Compilación y ejecución del Engine Core (`aipods-core-engine`) |
| **Node.js & npm** | `18+` / `9+` | Ejecución de los Frontends React/Vite y automatización RPA |
| **Git** | `2.34+` | Control de versiones distribuido |
| **GitHub CLI (`gh`)** | `2.20+` | Gestión de Issues y Pull Requests desde la consola |
| **gosec AST Scanner** | `v2+` | Scanner de vulnerabilidades en Go (`gosec ./...`) |

---

### 💻 1.1 Compatibilidad Multiplataforma (Linux, macOS & Windows 11)

Los scripts automatizados en `aipods-docs/scripts/` son **100% compatibles de forma nativa** con los sistemas operativos de todos los socios del equipo:

* **🐧 Linux (Ubuntu / Debian / RHEL / Fedora):**
  - Compatibilidad nativa en bash/zsh sin configuración especial.

* **🍏 macOS (Apple Silicon M1, M2, M3, M4 & Intel):**
  - **Soporte Nativo ARM64:** Go 1.22+ y Node.js corren en modo nativo en el chip M4 con máximo rendimiento.
  - **Ejecución:** Puedes ejecutar los scripts directamente desde la aplicación **Terminal** o **iTerm2** (`bash scripts/deploy_stack.sh`).

* **🪟 Windows 11:**
  - **Opción 1 (Recomendada): WSL 2 (Ubuntu 24.04)**  
    Proporciona un entorno Linux real dentro de Windows. Simplemente abre la terminal de WSL 2 y ejecuta los scripts (`bash scripts/deploy_stack.sh`).
  - **Opción 2: Git Bash (Git for Windows)**  
    Si prefieres usar la consola nativa de Windows sin WSL, abre **Git Bash** y ejecuta los scripts directamente (`bash scripts/deploy_stack.sh`).

---

## 📂 2. Onboarding & Clonado de Repositorios

Para que los scripts de automatización funcionen correctamente, los 4 repositorios de la organización deben clonarse dentro de una **misma carpeta contenedora** (ej. `~/server/` o `~/projects/aipods/`):

```bash
# Crear directorio raíz de trabajo
mkdir -p ~/server && cd ~/server

# Clonar los 4 repositorios oficiales de la organización
git clone https://github.com/onlyone-ai-pods/aipods-docs.git
git clone https://github.com/onlyone-ai-pods/aipods-core-engine.git
git clone https://github.com/onlyone-ai-pods/aipods-frontend-customer.git
git clone https://github.com/onlyone-ai-pods/aipods-frontend-admin.git
```

---

## 🛠️ 3. Scripts de Automatización Local (`aipods-docs/scripts/`)

Dentro del repositorio `aipods-docs/scripts/` dispones de los scripts automatizados que ejecutan análisis de calidad y sincronización de skills:

1. **`deploy_stack.sh`**: Ejecuta la suite de Quality & Security Gates en los 4 repositorios (auditoría de skills, `go vet`, `gosec`, `go test 100%`, `npm audit`, `ESLint` y compilación).
2. **`sync_skills.sh`**: Audita 0 rutas hardcoded y distribuye las Agentic Skills segregadas a los repositorios de Backend Go y Frontend React.
3. **`start_local_stack.sh`**: Arranca los 3 servicios locales en segundo plano (Go Core en `8080`, Customer Portal en `3000`, Admin Hub en `3001`).
4. **`stop_local_stack.sh`**: Detiene los procesos locales limpios.

---

## 📚 4. Arquitectura Documental Consolidada (3-Tier SDD)

Las especificaciones del sistema están organizadas bajo la metodología **Spec-Driven Development (SDD)** en los 4 Documentos Maestros por Épica:

- 📄 **[`specs/SPEC_MASTER_INDEX.md`](specs/SPEC_MASTER_INDEX.md):** Índice Maestro Dinámico de Especificaciones SDD.
- 📂 **[`specs/01_CORE_ENGINE_MASTER_SPEC.md`](specs/01_CORE_ENGINE_MASTER_SPEC.md):** Backend Engine, Swarm Protocol, Saga Pattern & CMMI Level 4.
- 📂 **[`specs/02_SECURITY_AND_COMPLIANCE_MASTER_SPEC.md`](specs/02_SECURITY_AND_COMPLIANCE_MASTER_SPEC.md):** Seguridad ISO 27001, SOC 2, Vault AES-256 e IP Audit.
- 📂 **[`specs/03_ADMIN_HUB_GOVERNANCE_MASTER_SPEC.md`](specs/03_ADMIN_HUB_GOVERNANCE_MASTER_SPEC.md):** Admin Hub Governance, Autenticación 2FA TOTP & Ergonomía Multi-Pantalla ISO 9241.
- 📂 **[`specs/04_CUSTOMER_PORTAL_MASTER_SPEC.md`](specs/04_CUSTOMER_PORTAL_MASTER_SPEC.md):** Customer Portal, IAM RBAC & UI Layout Governance Skill.

---

## 🔄 5. Flujo de Trabajo Git & Pull Requests (PRs)

1. **Creación de Rama:**  
   `git checkout -b feat/nombre-caracteristica` o `git checkout -b fix/descripcion-bug`

2. **Commit con Referencia SDD:**  
   `git commit -m "[FEAT] modulo: descripción breve (#Issue / SPEC-CORE-XX)"`

3. **Publicación y PR en GitHub CLI:**  
   `git push origin feat/nombre-caracteristica`  
   `gh pr create --title "[FEAT] modulo: título" --body "Resuelve #Issue / SPEC-CORE-XX"`
