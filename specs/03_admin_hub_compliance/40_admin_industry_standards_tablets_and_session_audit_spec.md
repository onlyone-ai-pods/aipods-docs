# 📜 SPEC: Rediseño Layout Admin — Responsividad Tablets $\ge$ 8", Sub-Sidebar Colapsable & Badges de Alerta
**ID:** SPEC-CORE-40  
**Épica Relacionada:** Admin UX & Ergonomía Visual, Responsividad Tablet ($\ge$ 8"), Sub-Sidebar Navigation & Cascade Alert Badge System  
**Issue Relacionado:** `#21` ([`[FEAT] Admin Hub: Layout Responsivo Tablets >=8" & Sub-menú Lateral Colapsable`](https://github.com/onlyone-ai-pods/aipods-docs/issues/21))  
**Estado:** APPROVED / SPEC-DRIVEN  

---

## 1. Visión y Objetivos

Esta especificación define exclusivamente la arquitectura de interfaz responsiva y ergonomía de pantalla para el **Admin Review Hub** (`aipods-frontend-admin`), enfocada en la experiencia de uso para operadores y administradores en jornadas de 6 a 8 horas.

Establece las reglas de diseño:
1. **Sub-Menú Lateral Colapsable (`AdminSubSidebar.jsx`)**: Descomposición de pestañas complejas (ej. *Observabilidad*) en sub-módulos laterales.
2. **Responsividad para Tablets desde 8 Pulgadas ($\ge 768\text{px}$)**: Colapsado automático a modo compacto de solo-iconos con superficies táctiles de toque $\ge 44\text{px}$ (ISO 9241-210 / WCAG 2.1 AAA).
3. **Propagación de Alertas de Severidad (Cascade Alert Badges)**: Indicadores visuales en el sub-menú lateral para evitar puntos ciegos.

---

## 2. Diagrama del Layout Responsivo en Tablets ($\ge 768\text{px}$)

```mermaid
graph TD
    Device[Dispositivo de Navegación] --> BreakpointCheck{Ancho de Pantalla}
    
    BreakpointCheck -->|Desktop >= 1024px| DesktopLayout[Sub-Sidebar Expandida 210px + Icono + Texto + Badges]
    BreakpointCheck -->|Tablet 8" a 10" (768px - 1023px)| TabletLayout[Sub-Sidebar Compacta 64px (Icon-Only + Tooltip)]
    BreakpointCheck -->|Mobile < 768px| MobileLayout[Menú Desplegable Horizontal Touch]

    TabletLayout --> TouchTarget[🎯 Targets Táctiles >= 44px (ISO 9241 / WCAG 2.1 AAA)]
```

---

## 3. Descomposición de Pestañas en Sub-Módulos Laterales

| Pestaña Principal | Sub-Módulos en Sidebar Left | Icono | Componente Renderizado |
|---|---|:---:|---|
| **`📊 Observabilidad`** | 1. Telemetría OpenTelemetry<br>2. AI Pods Dinámicos<br>3. FinOps & Consumo Tokens | `📊`<br>`🤖`<br>`💰` | `TelemetryDashboard.jsx`<br>`DynamicPodsManager.jsx`<br>`FinOpsMetrics.jsx` |
| **`🏢 Gestión Multi-Tenant`** | 1. Lista de Tenants & Odoo Billing<br>2. Planes & Cuotas de Tokens | `🏢`<br>`💳` | `TenantManagementView.jsx` |

---

## 4. Escenarios BDD

```gherkin
Feature: Layout Responsivo en Tablets de 8 Pulgadas & Sub-Sidebar Colapsable

  Scenario: Operación desde una Tablet de 8 Pulgadas (768px)
    Given un administrador navegando en `http://localhost:3001` desde una Tablet (768px)
    When el viewport detecta un ancho menor o igual a 1024px
    Then la barra sub-sidebar colapsa automáticamente al modo compacto (64px Icon-Only)
    And mantiene una superficie de contacto táctil de al menos 44px por botón
```
