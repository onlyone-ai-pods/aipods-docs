---
name: 🚀 1. Feature Request / Nueva Característica
about: Sugerir una nueva funcionalidad o AI Pod para la plataforma AI Pods Enterprise.
title: '[FEAT] <Nombre corto de la característica>'
labels: 'feature, needs-spec'
assignees: ''
---

### 💡 1. Descripción de la Necesidad / Justificación de Negocio
Describe claramente qué problema resuelve esta nueva característica y por qué es valiosa para la plataforma o para un cliente.

### 🎯 2. Criterios de Aceptación Obligatorios (Gherkin BDD)

```gherkin
Feature: <Nombre de la Característica>

  Scenario: <Escenario Exitoso Principal>
    Given un usuario o cliente autenticado en la plataforma
    When ejecuta la acción <nombre_accion>
    Then el sistema debe responder con <resultado>
    And cumplir con el tiempo de respuesta <latencia>

  Scenario: <Escenario de Simulación Dry-Run>
    Given una llamada con `dry_run = true`
    When se procesa la solicitud
    Then debe retornar `IsDryRun: true` y `ApprovalToken` inmutable
```

### 🧩 3. AI Pods y Componentes Impactados
Marque los módulos que se verán afectados:
- [ ] Backend Core Engine Go (`aipods-core-engine`)
- [ ] Customer Portal Frontend (`aipods-frontend-customer`)
- [ ] Admin Review Hub Frontend (`aipods-frontend-admin`)
- [ ] Nuevo AI Pod (Especificar nombre: `POD_...`)

### 📜 4. Trazabilidad SDD (Spec Relacionada)
- Especificación propuesta: `specs/0X_category/XX_feature_spec.md` (A llenar en Fase A)
