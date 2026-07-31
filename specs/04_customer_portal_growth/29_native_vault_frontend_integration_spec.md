# 📜 SPEC: Integración Frontend (Customer Portal & Admin Hub) — Native Vault AES-256
**ID:** SPEC-CORE-29  
**Épica Relacionada:** UX Security, Zero-Trust Frontend Architecture & Vault Governance  
**Issues Relacionados:** `#11` ([`[FEAT] Native Vault AES-256 Encryption`](https://github.com/onlyone-ai-pods/aipods-docs/issues/11))  
**Estado:** APPROVED / SPEC-DRIVEN  

---

## 1. Visión y Objetivos

Esta especificación establece el comportamiento, flujo de datos y patrones de seguridad de interfaz de usuario para el **Customer Portal** y el **Admin Review Hub** al interactuar con el **Native Vault cifrado AES-256-GCM**.

El diseño sigue el principio de **Zero-Trust & Zero-Knowledge**: el frontend nunca almacena claves secretas en texto plano en almacenamiento local (`localStorage` / `sessionStorage`) ni mantiene referencias en memoria más allá del ciclo efímero de visualización de 15 segundos.

---

## 2. Flujo Criptográfico en el Customer Portal (`aipods-frontend-customer`)

```mermaid
graph TD
    User[Cliente en NativeVaultView.jsx] -->|1. Render Inicial| MaskedUI[🔒 Estado Enmascarado: '••••••••••••']
    User -->|2. Click '👁️ Revelar'| API[POST /api/v1/vault/reveal]
    API -->|3. Descifrado AES-256-GCM| Go[Engine Core Server Go]
    Go -->|4. Plaintext Efímero en RAM| State[State Local React: revealedData]
    State -->|5. Timer 15s Expirado| AutoPurge[🧹 Auto-Purga de Memoria RAM Frontend]
    AutoPurge --> MaskedUI
```

---

## 3. Especificación del Componente `NativeVaultView.jsx` (Customer Portal)

### 3.1 Estados Visuales de Credencial

| Campo | Estado Enmascarado | Estado Revelado (15s Max) | Acción |
|---|---|---|---|
| **Clave Fiscal AFIP / ARCA** | `••••••••••••••••` | `ClaveFiscalSuperSegura2026!` | Botón `👁️ Revelar` / `🙈 Ocultar` |
| **Odoo Enterprise API Key** | `••••••••••••3a9f` | `odoo_api_key_88f7a6b5c4d3e2f1` | Botón `👁️ Revelar` / `🙈 Ocultar` |
| **GitHub Access Token** | `••••••••••••9f01` | `ghp_x9K2mL4nP7qR1sT0vW3xY5zA6bC8dE9fG0hI` | Botón `👁️ Revelar` / `🙈 Ocultar` |

### 3.2 Formulario de Alta de Secreto Cifrado

```jsx
// Payload enviado hacia Go (Nunca persistido en cliente)
const handleSaveSecret = async (keyName, plainTextSecret) => {
  await fetch('http://localhost:8080/api/v1/vault/secrets', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ key_name: keyName, secret_value: plainTextSecret })
  });
  // Auto-limpieza inmediata de inputs
  setPlainTextSecret('');
};
```

---

## 4. Especificación para Admin Review Hub (`aipods-frontend-admin`)

### 4.1 Principio Zero-Trust para Administradores (ISO 27001)
Los operadores en el Admin Review Hub **NO tienen habilitada la opción de descifrar o ver en texto plano** las credenciales privadas de los clientes.

### 4.2 Métricas de Salud del Vault
- **🟢 Credenciales Válidas**: Conteo de secretos activos por Tenant.
- **⚠️ Credenciales por Vencer**: Alerta si el certificado AFIP `.crt` vence en < 30 días.
- **🔒 Registro de Consultas de Revelado**: Auditoría de cada vez que el cliente presionó `👁️ Revelar`.

---

## 5. Escenarios BDD

```gherkin
Feature: Integración Frontend Customer & Admin Hub — Native Vault AES-256

  Scenario: Revelado Efímero con Auto-Purga de Memoria RAM (15 segundos)
    Given un usuario autenticado en el Customer Portal observando el Native Vault
    When hace click en "👁️ Revelar" en la API Key de Odoo
    Then el frontend solicita el descifrado a `POST /api/v1/vault/reveal`
    And muestra la clave en pantalla activando un timer de 15 segundos
    And al finalizar los 15 segundos, la memoria RAM del estado React debe limpiarse automáticamente retornando al estado `••••••••`

  Scenario: Seguridad Zero-Trust en el Admin Hub
    Given un operador de soporte en el Admin Review Hub auditando un tenant
    When ingresa al panel de Vault
    Then el sistema debe mostrar únicamente la fecha de vencimiento y el hash del certificado
    And bloquear la opción de descifrar el texto plano de la credencial del cliente
```
