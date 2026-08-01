# 📜 SPEC MAESTRA 04: Customer Portal, Growth & UI Governance Skill
**ID Épica:** EPIC-CUSTOMER-PORTAL-GROWTH  
**Estándar de Interfaz:** ISO 9241-210, WCAG 2.1 AAA & Spec-Driven Development  
**Estado:** CONSOLIDATED MASTER SPECIFICATION  

---

## 🏛️ Índice de Especificaciones Consolidadas en esta Épica

- [`SPEC-CORE-31`: Customer Portal — Perfil "Mi Cuenta", Invitaciones & 2FA TOTP](#1-spec-core-31-customer-portal--perfil-mi-cuenta-invitaciones--2fa-totp)
- [`SPEC-CORE-41`: UI/UX Layout Governance Skill & Mapa Canónico del Layout](#2-spec-core-41-uiux-layout-governance-skill--mapa-canónico-del-layout)
- [`SPEC-CORE-44`: Ecosistema Multi-Idioma i18n/l10n & Sincronización de Locale Partner Odoo](#3-spec-core-44-ecosistema-multi-idioma-i18nl10n--sincronización-de-locale-partner-odoo)

---

## 1. SPEC-CORE-31: Customer Portal — Perfil "Mi Cuenta", Invitaciones & 2FA TOTP

- **Edición Completa de Perfil (`SettingsView.jsx`)**: Modificación interactiva de nombre, email corporativo, CUIT, razón social, selector de tema gráfico (*Dark / Light*) y contraseña.
- **Invitaciones de Empleados (`InviteMemberModal.jsx`)**: Modal con asignación de roles RBAC (*Admin, Senior Consultant, Operator, Auditor*) e inyección automática en el IAM Audit Trail firmado con SHA-256.
- **Configuración 2FA TOTP**: Setup de autenticación de dos factores para cuentas de cliente.

---

## 2. SPEC-CORE-41: UI/UX Layout Governance Skill & Mapa Canónico del Layout

- **Skill `ui-layout-governance`**: Reglas de gobernanza mandatorias antes de mutar cualquier CSS, Theme o estructura visual.
- **Mapa Canónico del Layout (`layout_mockup_map.md`)**: Nomenclatura oficial etiquetada (`[A1]` a `[F1]`) para desarrolladores, arquitectos y auditores.
- **Protocolo LIEP (Layout Impact Evaluation Protocol)**: Matriz de evaluación de impacto para preservar estándares ISO 9241-210, WCAG 2.1 AAA, SOC 2 e ISO 27001.

---

## 3. SPEC-CORE-44: Ecosistema Multi-Idioma i18n/l10n & Sincronización de Locale Partner Odoo

- **Detección Dinámica de Locale (`res.partner.lang`)**: Integración con el modelo de Partner de Odoo ERP para sincronizar automáticamente el idioma y preferencia regional del cliente/proveedor (`es_AR`, `pt_BR`, `en_US`).
- **Middleware i18n Backend Go (`internal/i18n`)**: Carga asíncrona de paquetes de traducción `.json` / `.po` utilizando `nicksnyder/go-i18n/v2`.
- **Plantillas Localizadas de Correo y PDF**: Generación dinámica de facturas, avisos de pago, invitaciones y notificaciones de AI Pods ajustadas a la moneda (`ARS`, `BRL`, `USD`), formato de fecha ISO/US y separadores numéricos regionales.
- **Soporte Multi-Idioma en React (`i18next`)**: Proveedor `<I18nextProvider>` en Customer Portal y Admin Hub con selector de idioma en el perfil de usuario.

