# [FEAT] pod-afip-fiscal-rpa-playwright-automation

### 💡 1. Descripción de la Necesidad / Justificación de Negocio

El AI Pod **`POD_AFIP_FISCAL`** (AI Pod AFIP / ARCA & Gestión Fiscal) requiere proveer capacidades de automatización robótica (RPA) sobre los portales interactivos de ARCA/AFIP que carecen de API pública abierta (*Mis Comprobantes*, *Mis Retenciones*, *SIFERE WEB*, *Declaración en Línea F.931*, *SETI Pagos VEP*, *E-Ventanilla* y *Administración de Puntos de Venta y Domicilios*).

#### Pilares de Arquitectura e Infraestructura Evaluados:
1. **RPA con Playwright & Desacoplamiento de Memoria:**
   - **Dev / Testing Local:** Ejecución de Playwright Chromium headless en contenedor Docker local (`docker-compose.playwright.yml`).
   - **Producción SaaS Multitenant:** Conexión de `aipods-core-engine` (Go, ~10MB RAM) vía WebSocket a un cluster dedicado de navegadores (`ws://vps-rpa.internal:3000`), evitando sobrecargar la RAM del servidor de aplicación.

2. **Telemetría y Cobro por Uso (Metered Billing):**
   - Registro automático de métricas por tarea (`duration_ms`, `memory_peak_mb`, `downloads_count`) enviadas en el evento `POD_USAGE_METERED` para computar los créditos/tarifa SaaS cobrados al cliente.

3. **Reutilización y Auto-Aprendizaje de Selectores (`config/selectors.json`):**
   - Catálogo desacoplado de selectores con estrategia de Multi-Selector Fallback. Si ARCA modifica la estructura DOM de un servicio, el script activa automáticamente el selector secundario y emite la métrica `SELECTOR_DRIFT_DETECTED`, permitiendo corregir `selectors.json` en tiempo real para todos los contribuyentes sin recompilar Go.

4. **Gobernanza de Seguridad del Contenedor:**
   - Uso exclusivo de la imagen oficial auditada por Microsoft: `mcr.microsoft.com/playwright:v1.40.0-jammy` fijada por hash SHA256.
   - Ejecución sin privilegios root (`user: 1001:1001`), `read_only: true`, `tmpfs` efímero y remoción de capacidades de kernel (`cap_drop: ALL`).
   - Restricción de red salida (Egress) permitida exclusivamente a dominios fiscales oficiales (`*.afip.gob.ar`, `*.arca.gob.ar`, `*.comarb.gob.ar`).
   - Sanitización estricta de textos extraídos del DOM antes de ser procesados por los modelos LLM (Anti-DOM Poisoning / Anti-Prompt Injection).

---

### 🚀 2. Optimización del Desarrollo & Excelencia Operativa (Nuevas Adiciones)

1. **Mock Server & HAR Fixtures para CI/CD Offline:**
   - Creación de mocks HTML y grabaciones HAR (`test_fixtures/`) para permitir que la suite de pruebas automatizadas en CI/CD corra sin depender de la disponibilidad del portal de ARCA ni consumir credenciales de producción.

2. **Cache Semántico Integrado (`SPEC-CORE-04`):**
   - Caché de respuestas de consulta en Redis (TTL 15 min) para evitar aperturas repetidas del navegador si un usuario consulta múltiples veces el mismo período sin cambios.

3. **Comando de Test y Auditoría en CLI (`aipods-cli pod afip`):**
   - Comando directo en la herramienta de CLI para diagnosticar, probar y simular la ejecución de `POD_AFIP_FISCAL` desde la terminal de desarrollador.

4. **Políticas de Reintento Exponencial y Recuperación de Sesión:**
   - Reintentos automáticos (hasta 3 intentos con *Exponential Backoff*) ante caídas temporales de sesión o errores 503 del servidor de ARCA.

---

### 📋 3. Matriz de Cobertura de Servicios ARCA (Roadmap)

- [x] **US-01:** Descarga de Comprobantes Emitidos y Recibidos (*Mis Comprobantes*) - **COMPLETADO & PROBADO EN VIVO**
- [x] **US-02:** Descarga de Retenciones y Percepciones (*Mis Retenciones / Mirequa ARCA*) - **COMPLETADO & PROBADO EN VIVO**
- [ ] **US-03:** Descarga de DDJJ Convenio Multilateral (*SIFERE WEB*)
- [ ] **US-04:** Descarga de DDJJ SICOSS Formulario 931 (*Declaración en Línea*)
- [ ] **US-05:** Generación de VEP (*SETI Pagos*)
- [ ] **US-06:** Consulta de Notificaciones (*E-Ventanilla*)
- [x] **US-07:** Consulta y Alta de Puntos de Venta (*Administración de Puntos de Venta y Domicilios*) - **COMPLETADO & PROBADO EN VIVO**

---

### 🎯 4. Criterios de Aceptación Obligatorios (Gherkin BDD)

```gherkin
Feature: POD_AFIP_FISCAL - Automatización RPA & Gobernanza

  Scenario: Autenticación y Consulta Exitosa de Comprobantes y Puntos de Venta
    Given un contribuyente autenticado con CUIT y Clave Fiscal en cuits.json / Vault
    When el AI Pod ejecuta "descargar_comprobantes_arca" o "gestionar_puntos_de_venta_arca"
    Then Playwright debe conectarse al contenedor Docker de navegadores
    And extraer los datos en vivo del portal de ARCA/AFIP
    And retornar la respuesta estructurada en Markdown/JSON

  Scenario: Registro de Telemetría para Cobro por Uso (Metered Billing)
    Given la finalización de una tarea de automatización RPA
    When el Pod `POD_AFIP_FISCAL` completa el procesamiento
    Then debe emitir el evento `POD_USAGE_METERED` con `duration_ms`, `memory_peak_mb` y `downloads_count`
    And computar el consumo de créditos correspondiente al tenant

  Scenario: Resilience & Auto-Healing ante Cambios de DOM (Selector Drift)
    Given un cambio en la estructura HTML/CSS de un servicio en el portal de ARCA
    When el script intenta el selector primario de `config/selectors.json` y no lo encuentra
    Then el script debe probar automáticamente los selectores alternativos empadronados
    And emitir la métrica de advertencia `SELECTOR_DRIFT_DETECTED` sin interrumpir la tarea

  Scenario: Protocolo de Simulación Segura (Dry-Run)
    Given una llamada con `dry_run = true`
    When se solicita una acción de consulta o mutación en ARCA
    Then el Pod debe retornar `IsDryRun: true`, el resumen de la acción y un `ApprovalToken`
    And NO debe abrir ninguna sesión de navegador real
```

---

### 📋 5. Definition of Done (DoD) Checklist

- [x] Especificación SDD integrada en `aipods-docs/specs/pods/01_afip_finance_spec.md`.
- [x] Script Playwright funcional y probado en vivo contra ARCA.
- [x] Registro desacoplado `config/selectors.json` creado.
- [x] Contenedor Docker seguro `docker-compose.playwright.yml` definido.
- [x] Suite de tests unitarios en Go ejecutada y aprobada.
- [ ] Mocks offline para CI/CD integrados.
- [ ] Evento de telemetría `POD_USAGE_METERED` integrado en backend engine.

---

### 🧩 6. AI Pods y Componentes Impactados
- [x] Backend Core Engine Go (`aipods-core-engine`)
- [x] Especificaciones y Documentación SDD (`aipods-docs/specs/pods/01_afip_finance_spec.md`)
- [x] Scripts RPA (`scripts/mis_comprobantes_arca.js`, `scripts/puntos_de_venta_arca.js`)
- [x] Catálogo de Selectores (`config/selectors.json`)
- [x] Infraestructura Docker (`docker-compose.playwright.yml`)

---

### 📜 7. Trazabilidad SDD (Spec Relacionada)
- Especificación integrada: [specs/pods/01_afip_finance_spec.md](file:///home/martin/server/aipods-docs/specs/pods/01_afip_finance_spec.md) (`POD_AFIP_FISCAL`)
