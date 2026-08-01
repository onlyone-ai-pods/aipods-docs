# 📜 SPEC MAESTRA 03: Admin Review Hub, Gobernanza UX & Ergonomía
**ID Épica:** EPIC-ADMIN-HUB-GOVERNANCE  
**Estándar de Interfaz:** ISO 9241-210, WCAG 2.1 AAA, SOC 2 & Full-Width Fluid  
**Estado:** CONSOLIDATED MASTER SPECIFICATION  

---

## 🏛️ Índice de Especificaciones Consolidadas en esta Épica

- [`SPEC-CORE-30`: Panel Multi-Tenant, Odoo Billing & Exportación PDF/CSV](#1-spec-core-30-panel-multi-tenant-odoo-billing--exportación-pdfcsv)
- [`SPEC-CORE-37`: Onboarding Checklist Wizard de Administrador](#2-spec-core-37-onboarding-checklist-wizard-de-administrador)
- [`SPEC-CORE-38`: Autenticación e Inicio de Sesión de Administrador con 2FA TOTP](#3-spec-core-38-autenticación-e-inicio-de-sesión-de-administrador-con-2fa-totp)
- [`SPEC-CORE-39`: Rediseño Admin Hub — Navegación por 5 Pestañas & Alertas](#4-spec-core-39-rediseño-admin-hub--navegación-por-5-pestañas--alertas)
- [`SPEC-CORE-40`: Full-Width Fluid Layout 100% & Responsividad Tablets 8"+](#5-spec-core-40-full-width-fluid-layout-100--responsividad-tablets-8)

---

## 1. SPEC-CORE-30: Panel Multi-Tenant, Odoo Billing & Exportación PDF/CSV

Gestión centralizada de empresas clientes, control de cuotas de tokens, cambio de estados (`PROD_ACTIVE`, `SUSPENDED`) y exportador modal de reportes normativos en PDF/CSV firmados con SHA-256 (`AuditExportModal.jsx`).

---

## 2. SPEC-CORE-37: Onboarding Checklist Wizard de Administrador

Wizard interactivo de 4 pasos (`AdminOnboardingWizard.jsx`) con barra de progreso para guiado y certificación de configuración de administradores.

---

## 3. SPEC-CORE-38: Autenticación e Inicio de Sesión de Administrador con 2FA TOTP

Pantalla de Login segura (`AdminLoginView.jsx`) con desafío 2FA TOTP obligatorio de 6 dígitos para el rol Senior Consultant, gestión de token de sesión JWT en `sessionStorage` y botón de Logout en cabecera.

---

## 4. SPEC-CORE-39: Rediseño Admin Hub — Navegación por 5 Pestañas & Alertas

Sistema de navegación por 5 pestañas modulares segregadas (`AdminTabNavigation.jsx`) con indicadores visuales de severidad (🔴 Crítico, 🟡 Advertencia, 🟢 Normal):
1. `🧑‍⚖️ Review Hub (Dry-Run)` (Pestaña principal por defecto).
2. `📜 Trazabilidad & Auditoría` (Log inmutable SHA-256).
3. `🏢 Gestión Multi-Tenant` (Odoo Billing).
4. `📊 Observabilidad & Telemetría` (Prometheus & Redis).
5. `🧙 Checklist de Setup` (Onboarding Wizard).

---

## 5. SPEC-CORE-40: Full-Width Fluid Layout 100% & Responsividad Tablets 8"+

- **Full-Width Fluid Layout 100%**: Eliminación de márgenes encajonados de `1300px` para aprovechar al máximo monitores de 27", 4K y UltraWide con `padding: 0 32px;`.
- **Sub-Sidebar Colapsable (`AdminSubSidebar.jsx`)**: Descomposición de pestañas complejas en sub-módulos laterales.
- **Responsividad Tablets $\ge 8"$**: Colapsado automático a modo compacto Icon-Only (64px) con superficies de contacto de al menos $44\text{px}$ (ISO 9241-210 / WCAG 2.1 AAA).
