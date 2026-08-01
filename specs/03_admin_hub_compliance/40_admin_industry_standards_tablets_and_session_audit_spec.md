# 📜 SPEC: Estándares de la Industria, Responsividad Tablets $\ge$ 8", Sub-Sidebar & Trazabilidad IP/User-Agent
**ID:** SPEC-CORE-40  
**Épica Relacionada:** Admin Governance, Industry Compliance Standards, Tablet UX ($\ge$ 8") & Admin Session Security  
**Issue Relacionado:** `#21` ([`[FEAT] Admin Hub: Layout Responsivo Tablets >=8", Sub-menú Lateral & Trazabilidad de IP/User-Agent`](https://github.com/onlyone-ai-pods/aipods-docs/issues/21))  
**Estado:** APPROVED / SPEC-DRIVEN  

---

## 1. Cumplimiento de Estándares de la Industria

| Estándar Internacional | Requisito / Control de Industria | Implementación en AI Pods Admin Hub |
|---|---|---|
| **SOC 2 Type II (CC6.1, CC6.8)** | Monitoreo continuo sin puntos ciegos e identificación inmutable de usuarios administradores. | Sub-menú lateral con **Cascade Alert Badges** y registro inmutable con firma SHA-256. |
| **ISO/IEC 27001:2022 (A.12.4.1)** | Registro inalterable de actividades de administración, fecha, hora, dirección IP y navegador. | Registro automático de `IP Client` y `User-Agent` en backend Go al hacer login o mutación. |
| **NIST SP 800-53 Rev. 5 (AU-2, AU-3)** | Contenido detallado de registros de auditoría de eventos de gestión del sistema. | Inyección de `RemoteAddr` y firma Hash digest en el IAM Audit Trail. |
| **ISO 9241-210 / Ergonomía** | Diseño centrado en el usuario para prevención de fatiga en turnos de 6 a 8 horas. | Encapsulamiento por sub-paneles sin scroll vertical continuo y paleta de baja luminancia. |
| **WCAG 2.1 AAA / Accesibilidad** | Contraste de texto mínimo 7:1 y blancos táctiles $\ge 44\text{px}$ para operación touch. | Botones de sub-sidebar optimizados para toque en pantallas táctiles y tablets. |

---

## 2. Layout Responsivo para Tablets desde 8 Pulgadas ($\ge 768\text{px}$)

```mermaid
graph TD
    Device[Dispositivo / Pantalla] --> BreakpointCheck{Resolución / Ancho}
    
    BreakpointCheck -->|Desktop >= 1024px| DesktopLayout[Sidebar Lateral 200px + Texto + Badges]
    BreakpointCheck -->|Tablet 8" a 10" (768px - 1023px)| TabletLayout[Sidebar Compacta 60px (Icon-Only + Tooltip)]
    BreakpointCheck -->|Mobile < 768px| MobileLayout[Menú Desplegable Off-Canvas Touch]

    TabletLayout --> TouchTarget[🎯 Botones Táctiles Target >= 44px (ISO 9241)]
```

---

## 3. Especificación Backend Go: Trazabilidad IP & User-Agent (`internal/audit`)

```go
type AdminSessionLog struct {
    LogID       string    `json:"log_id"`
    Timestamp   time.Time `json:"timestamp"`
    AdminEmail  string    `json:"admin_email"`
    Action      string    `json:"action"`
    ClientIP    string    `json:"client_ip"`
    UserAgent   string    `json:"user_agent"`
    SHA256Hash  string    `json:"sha256_hash"`
}
```

---

## 4. Escenarios BDD

```gherkin
Feature: Estándares de la Industria, Responsividad Tablet & Trazabilidad de Sesión

  Scenario: Navegación en Tablet de 8 Pulgadas (768px)
    Given un administrador operando desde una Tablet iPad Mini o Samsung Tab 8"
    When la pantalla se ajusta a una resolución de 768px
    Then la sub-sidebar lateral debe colapsar automáticamente al modo compacto (Icon-Only 60px)
    And los botones deben mantener una superficie táctil mínima de 44px

  Scenario: Auditoría de IP y User-Agent en Inicio de Sesión
    Given un administrador iniciando sesión en `http://localhost:3001`
    When el backend Go procesa las credenciales
    Then debe extraer la dirección `ClientIP` y el `User-Agent` del request HTTP
    And generar un registro firmado con SHA-256 en el IAM Audit Trail
```
