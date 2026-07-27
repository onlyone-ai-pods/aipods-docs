# 📜 SPEC: Arquitectura del Ecosistema AI Pods, Herramienta CLI (`aipods-cli`) y Pipeline de Validación

**ID:** SPEC-CORE-28  
**Épica Relacionada:** Arquitectura de Plataforma, Ecosystem Tooling & AI Pod Standards  
**Issue Relacionado:** `#10` ([`[FEAT] Herramienta CLI Unificada aipods-cli (Scaffold, Register & Audit)`](https://github.com/onlyone-ai-pods/aipods-docs/issues/10))  
**Estado:** PROPOSED / SPEC-DRIVEN  

---

## 1. Visión General del Ecosistema AI Pods

Para garantizar escalabilidad, seguridad multi-tenant y tolerancia a fallos, la plataforma **AI Pods Enterprise SaaS** estructura el ecosistema de AI Pods en **3 modalidades de ejecución** desacopladas:

```mermaid
graph TD
    CLI[🛠️ aipods-cli: CLI para Desarrolladores & Consultores] -->|1. Scaffold & Boilerplate| LocalDev[Entorno de Desarrollo Local del Pod]
    CLI -->|2. Hot-Registration API| Engine[🌐 Backend Core Engine Go: DynamicSmartRouter]
    CLI -->|3. Audit Dossier Generation| Specs[📜 Suite de Specs SDD & Logs Audit Trail]

    subgraph Motor Core Engine Go
        Engine -->|Static In-Process <1ms| StaticPods[🟢 Core Essential Pods: AFIP, Billing, Security]
        Engine -->|Dynamic Out-of-Process Sidecar| DynamicPods[🔵 Domain Sidecar Pods: SAP, SCM, Custom ERP]
    end

    DynamicPods -->|HTTPSidecarAdapter + CircuitBreaker| External[Microservicios HTTP / Python / Node.js / Go]
```

---

## 2. Modalidades de Ejecución de AI Pods

| Modalidad de AI Pod | Tipo de Ejecución | Latencia | Tolerancia a Fallos | Ejemplos de Pods |
| :--- | :--- | :---: | :--- | :--- |
| **🟢 1. Pods Nativos del Core** | Compilados en el binario Go (*In-Process*) | **$< 1\text{ ms}$** | Directa en memoria | `POD_CORE_BILLING_ODOO`, `POD_CORE_SECURITY_AUDIT`, `POD_AFIP_FINANCE` |
| **🔵 2. Pods Dinámicos Sidecar** | Microservicios externos HTTP (*Out-of-Process*) | **$10 - 30\text{ ms}$** | Protegido por **`CircuitBreaker`** (`CLOSED`, `OPEN`, `HALF_OPEN`) | `POD_SAP_ENTERPRISE`, `POD_SCM_LOGISTICS`, Pods de Clientes |
| **🟡 3. Pods Efímeros Sandbox** | Espacios aislados temporales (*Playground*) | **$< 5\text{ ms}$** | Límite 3 consultas / Expira en 30 min | Sesiones de prueba desde el Customer Portal |

---

## 3. Pipeline de Validación del Cliente (`aipods-cli validate`)

Cuando un cliente o desarrollador ejecuta `aipods-cli validate --path=./my_pod --strict`, la herramienta ejecuta **4 Filtros de Validación Rigurosos**:

```mermaid
sequenceDiagram
    autonumber
    actor Dev as 👨‍💻 Cliente / Desarrollador
    participant CLI as 🛠️ aipods-cli validate
    participant SpecEngine as 📜 1. Validador de Esqueletos (pod.json / workflow.yml)
    participant Linter as 🔍 2. Auditoría Anti-Poisoning (FileSanitizer / gosec)
    participant Runner as 🧪 3. Pruebas BDD (Contrato PodResponse <15ms)
    participant DryRun as 🛡️ 4. Verificación Human-in-the-Loop (ApprovalToken)

    Dev->>CLI: aipods-cli validate --path=./my_custom_pod --strict
    
    Note over CLI, SpecEngine: Filtro 1: Estructura y Sintaxis
    CLI->>SpecEngine: Valida esquemas JSON de pod.json y sintaxis de workflow.yml
    SpecEngine-->>CLI: ✅ Sintaxis y esquemas válidos

    Note over CLI, Linter: Filtro 2: Seguridad de Código
    CLI->>Linter: Verifica FileSanitizer Magic Bytes + AST gosec (0 vulnerabilidades)
    Linter-->>CLI: ✅ Código limpio y seguro

    Note over CLI, Runner: Filtro 3: Contrato BDD & Latencia
    CLI->>Runner: Ejecuta llamadas a /healthz y /process (Verifica latencia <15ms)
    Runner-->>CLI: ✅ Contrato cumplido

    Note over CLI, DryRun: Filtro 4: Protocolo Dry-Run
    CLI->>DryRun: Invoca petición con dry_run = true
    DryRun-->>CLI: ✅ Retorna ApprovalToken inmutable

    CLI-->>Dev: 🟢 "SUCCESS: Pod verificado y listo para aipods-cli register"
```

### Detalle de los 4 Filtros de Validación:
1. **Filtro 1 (Sintaxis y Esquema):** Valida la presencia de `pod.json` y la coherencia del esquema de macros `workflow.yml`.
2. **Filtro 2 (Seguridad & Anti-Poisoning):** Ejecuta `gosec` (0 vulnerabilidades) y confirma que los entrypoints invoquen `FileSanitizer.ValidatePDFMagicBytes()`.
3. **Filtro 3 (Contrato BDD & Latencia <15ms):** Realiza pings a `/healthz` y valida que `/process` responda exactamente con la estructura `PodResponse` en menos de 15ms.
4. **Filtro 4 (Human-in-the-Loop):** Ejecuta la llamada simulada con `dry_run = true` asegurando la presencia del token `ApprovalToken`.

---

## 4. Rol y Módulos Funcionales de `aipods-cli`

### Módulo 1: Desarrollo y Scaffold (`aipods-cli pod ...`)
* **`aipods-cli pod init --name=POD_CUSTOM`**: Genera el proyecto estandarizado cumpliendo la interfaz `pod.BaseAIPod`, esquemas JSON de entrada/salida y suite de pruebas BDD `pod_test.go`.
* **`aipods-cli pod validate --path=./POD_CUSTOM`**: Ejecuta los 4 filtros de validación del flujo del cliente.

### Módulo 2: Registro Operacional en Caliente (`aipods-cli register ...`)
* **`aipods-cli register --id=POD_CUSTOM --endpoint=http://sidecar:9095 --keywords=kw1,kw2`**: Invoca el endpoint `/api/v1/pods/register` registrando el Pod dinámico en el `DynamicSmartRouter` en caliente sin reiniciar el motor Go.

### Módulo 3: Auditoría y Cumplimiento Normativo (`aipods-cli audit ...`)
* **`aipods-cli audit dossier --scope=global`**: Compila el expediente normativo ISO 9001 / SOC 2 Type II firmándolo con OpenSSL SHA-256.
* **`aipods-cli audit verify --dossier=file.pdf`**: Verifica la validez criptográfica del expediente.

---

## 5. Matriz de Patrones de Diseño Cumplidos

1. **Ports & Adapters (Hexagonal Architecture):** Interfaz agnóstica `pod.BaseAIPod` desacoplada del medio de transporte.
2. **Dynamic Sidecar Pattern:** Registro de microservicios dinámicos en tiempo de ejecución.
3. **Circuit Breaker Pattern:** Aislamiento de fallas de microservicios dinámicos (`CLOSED`, `OPEN`, `HALF_OPEN`).
4. **Human-in-the-Loop Pattern:** Protocolo `dry_run = true` devolviendo `ApprovalToken` criptográfico.
5. **Spec-Driven Development (SDD):** Trazabilidad completa respaldada por especificaciones ejecutables `.spec.md`.

---

## 6. Criterios de Aceptación (Gherkin BDD)

```gherkin
Feature: Arquitectura del Ecosistema AI Pods y Herramienta aipods-cli

  Scenario: Inicialización de un Nuevo AI Pod con aipods-cli (Scaffold Path)
    Given un desarrollador ejecutando `aipods-cli pod init --name=POD_TEST_SCRIBER`
    When el comando genera la estructura de carpetas
    Then debe crear la implementación cumpliendo la interfaz `pod.BaseAIPod`
    And incluir el archivo de pruebas BDD `pod_test.go` listo para ejecución

  Scenario: Validación Rigurosa del Flujo de Trabajo del Cliente (Validate Pipeline Path)
    Given un desarrollador ejecutando `aipods-cli validate --path=./my_custom_pod --strict`
    When la herramienta evalúa los 4 filtros (Esquemas, Seguridad, Contrato BDD <15ms y Dry-Run)
    Then debe validar la presencia de `FileSanitizer` y 0 vulnerabilidades `gosec`
    And confirmar el retorno de `ApprovalToken` en modo simulación

  Scenario: Registro de un Pod Dinámico en Caliente (Hot-Registration Path)
    Given un microservicio sidecar ejecutándose en `http://localhost:9095`
    When el operador ejecuta `aipods-cli register --id=POD_TEST_SCRIBER --endpoint=http://localhost:9095 --keywords=test`
    Then el `DynamicSmartRouter` debe registrar el Pod dinámico en memoria en caliente
    And enrutar las consultas coincidentes al nuevo sidecar sin reiniciar el motor Go

  Scenario: Aislamiento de Fallas con CircuitBreaker ante Caída de Sidecar (Failure Isolation)
    Given un AI Pod dinámico cuyo microservicio HTTP responde con errores HTTP 500 consecutivos
    When el número de fallas supera el umbral configurado (ej: 3 fallas)
    Then el `CircuitBreaker` debe cambiar su estado a `OPEN`
    And retornar un mensaje de fallback amigable sin bloquear las peticiones de otros tenants
```
