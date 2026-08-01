# 📜 SPEC MAESTRA 04: Customer Portal, Growth & UI Governance Skill
**ID Épica:** EPIC-CUSTOMER-PORTAL-GROWTH  
**Estándar de Interfaz:** ISO 9241-210, WCAG 2.1 AAA & Spec-Driven Development  
**Estado:** CONSOLIDATED MASTER SPECIFICATION  

---

## 🏛️ Índice de Especificaciones Consolidadas en esta Épica

- [`SPEC-CORE-31`: Customer Portal — Perfil "Mi Cuenta", Invitaciones & 2FA TOTP](#1-spec-core-31-customer-portal--perfil-mi-cuenta-invitaciones--2fa-totp)
- [`SPEC-CORE-41`: UI/UX Layout Governance Skill & Mapa Canónico del Layout](#2-spec-core-41-uiux-layout-governance-skill--mapa-canónico-del-layout)
- [`SPEC-CORE-44`: Ecosistema Multi-Idioma i18n/l10n & Sincronización de Locale Partner Odoo](#3-spec-core-44-ecosistema-multi-idioma-i18nl10n--sincronización-de-locale-partner-odoo)
- [`SPEC-CORE-45`: Formularios UI de Selección de Idioma, Región y Moneda Localizada](#4-spec-core-45-formularios-ui-de-selección-de-idioma-región-y-moneda-localizada)

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

- **Cascada de Fallback Inteligente (Fallback Resolution Cascade)**:
  - Nivel 1 (Región Específica): `es_AR`, `es_CL`, `es_PE`, `es_UY`, `es_MX`, `pt_BR`, `en_US`.
  - Nivel 2 (Familia Lingüística): `es` (Español Neutro Latinoamericano) o `pt` (Portugués General).
  - Nivel 3 (Perfil de Usuario / Partner Odoo `res.partner.lang`).
  - Nivel 4 (Fallback Global por Defecto): `en` (English Default).
- **Detección Dinámica de Locale (`res.partner.lang`)**: Integración con el modelo de Partner de Odoo ERP para sincronizar automáticamente el idioma y preferencia regional del cliente/proveedor.
- **Middleware i18n Backend Go (`internal/i18n`)**: Carga asíncrona de paquetes de traducción `.json` / `.po` utilizando `nicksnyder/go-i18n/v2`.
- **Plantillas Localizadas de Correo y PDF**: Generación dinámica de facturas, avisos de pago, invitaciones y notificaciones de AI Pods ajustadas a la moneda regional (`ARS`, `CLP`, `PEN`, `BRL`, `USD`), formato de fecha y separadores numéricos de cada país.
- **Soporte Multi-Idioma en React (`i18next`)**: Proveedor `<I18nextProvider>` en Customer Portal y Admin Hub con selector de idioma y región en el perfil de usuario.

---

## 4. SPEC-CORE-45: Protocolo de Detección Automática de Idioma & UI de Configuración de Perfil

- **Escenario 1: Visitante Anónimo (Landing Page, Sandbox Demo & Pantalla de Login / Sin Sesión)**:
  - **Auto-Detección Geográfica & Browser Locale**: No se muestran selectores manuales en la cabecera principal. El sistema detecta automáticamente la región y lenguaje mediante `navigator.language` y la geolocalización IP.
  - *Comportamiento*: Si el usuario navega desde Argentina (`es-AR`), Chile (`es-CL`) o Perú (`es-PE`), la interfaz carga en **Español** (`es`). Si navega desde Brasil (`pt-BR`), carga en **Portugués** (`pt`). En EE.UU. u otros países, carga en **Inglés** (`en`).
- **Escenario 2: Usuario Autenticado (Clientes, Administradores, Auditores / Con Sesión Iniciada)**:
  - **Prevalencia Absoluta del Perfil de Usuario**: Una vez iniciado sesión, el sistema ignora la IP geográfica (útil para ejecutivos o clientes que viajan al exterior) y aplica estrictamente el idioma y región configurados en su perfil (`res.partner.lang` de Odoo ERP o `SettingsView.jsx`).
- **Configuración de Perfil (`SettingsView.jsx`)**:
  - Unicidad de edición: La modificación de idioma, región (`es_AR`, `es_CL`, `es_PE`, `es_UY`, `es_MX`, `pt_BR`, `en_US`) y moneda (`ARS`, `CLP`, `PEN`, `UYU`, `MXN`, `BRL`, `USD`) se realiza exclusivamente dentro de las configuraciones de la cuenta del usuario.
- **Modal de Invitación Multi-Idioma (`InviteMemberModal.jsx`)**:
  - Al invitar nuevos miembros con roles RBAC (*Operator, Auditor, Senior Consultant*), el formulario incluye la selección del idioma inicial con el que el nuevo usuario recibirá su correo de bienvenida y accederá al portal.
- **Persistencia en LocalStorage y Estado Global (`LanguageContext.jsx`)**:
  - Cambio dinámico instantáneo del idioma de la interfaz sin necesidad de recargar la página.


