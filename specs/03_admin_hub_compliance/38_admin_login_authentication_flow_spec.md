# 📜 SPEC: Autenticación e Inicio de Sesión del Administrador (Login & 2FA TOTP)
**ID:** SPEC-CORE-38  
**Épica Relacionada:** Security & Authentication, Admin Access Control & 2FA Step-up Challenge  
**Issue Relacionado:** `#19` ([`[FEAT] Admin Hub Authentication & Login Flow (SSO / OIDC, Magic Link, 2FA TOTP)`](https://github.com/onlyone-ai-pods/aipods-docs/issues/19))  
**Estado:** APPROVED / SPEC-DRIVEN  

---

## 1. Visión y Objetivos

Esta especificación define la **Pantalla de Inicio de Sesión y Autenticación de Administradores / Senior Consultants** en el **Admin Review Hub** (`aipods-frontend-admin`).

Establece las políticas de acceso de nivel empresarial (SOC 2 Type II / ISO 27001):
1. **Credenciales Corporativas / SSO**: Autenticación por Email/Password o Single Sign-On (OIDC).
2. **Desafío 2FA TOTP Obligatorio**: Todo usuario con privilegios de aprobación debe validar un token OTP de 6 dígitos antes de acceder a la cola `dry_run`.
3. **Control de Sesión**: Generación de token JWT en `sessionStorage` y mecanismo de **Cerrar Sesión (Logout)**.

---

## 2. Diagrama del Flujo de Autenticación de Administrador

```mermaid
graph TD
    Ingreso[Administrador en http://localhost:3001] --> CheckAuth{¿Sesión Activa?}
    CheckAuth -->|No| LoginView[🔐 AdminLoginView.jsx]
    CheckAuth -->|Sí| MainHub[🛡️ SeniorReviewHub + Onboarding]

    LoginView -->|1. Email & Password| ValidateCreds[Verificación de Credenciales]
    ValidateCreds -->|2. Credenciales Válidas| Step2FA[📲 Desafío 2FA TOTP (6 dígitos)]
    Step2FA -->|3. OTP Válido| TokenGen[🔑 Generación de JWT Session Token]
    TokenGen --> MainHub

    MainHub -->|Click 'Cerrar Sesión'| Logout[Purga de SessionStorage & Redirect to Login]
```

---

## 3. Credenciales de Prueba por Defecto (Dev Mode)

- **Email Administrador**: `admin.consultant@acmecorp.com`
- **Contraseña**: `AdminPods2026!`
- **Código 2FA OTP**: `123456` (o cualquier token de 6 dígitos)

---

## 4. Escenarios BDD

```gherkin
Feature: Autenticación e Inicio de Sesión del Administrador

  Scenario: Inicio de Sesión Exitoso con Desafío 2FA TOTP
    Given un administrador en la pantalla de inicio de sesión de `aipods-frontend-admin`
    When ingresa `admin.consultant@acmecorp.com` y su contraseña
    Then el sistema solicita el código 2FA TOTP de 6 dígitos
    And al ingresar `123456`, el sistema concede el acceso al Admin Review Hub

  Scenario: Cierre de Sesión (Logout) Seguro
    Given un administrador autenticado en el Admin Hub
    When presiona el botón "🚪 Cerrar Sesión" en la cabecera
    Then el sistema purga el token de sesión y redirige inmediatamente a la pantalla de Login
```
