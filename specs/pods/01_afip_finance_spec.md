# 📜 SPEC: AI Pod - AFIP / ARCA & Gestión Fiscal (`POD_AFIP_FISCAL`)
**ID:** SPEC-POD-01 (`POD_AFIP_FISCAL`)  
**Épica Relacionada:** Épica 1 (HU 1.1, HU 1.2)  
**Estado:** READY FOR IMPL / SPEC-DRIVEN  

---

## 1. Visión General & Arquitectura de Memoria (Bajo Consumo)

El **AI Pod AFIP / ARCA & Gestión Fiscal (`POD_AFIP_FISCAL`)** provee capacidades avanzadas de asistencia técnica asistencial (generación de CSR OpenSSL, diagnóstico de balances en Odoo/CSV) y **automatización robótica de procesos (RPA)** sobre los portales interactivos de ARCA/AFIP mediante Playwright.

### 1.1 Desacoplamiento & Consumo de Recursos (Playwright)
> [!IMPORTANT]
> **Optimización de Memoria (Bajo Footprint):**
> * **Proceso Local (Modo Pruebas / Dev):** Se ejecuta en modo headless ligero con flags de restricción de recursos (`--disable-dev-shm-usage`, `--no-sandbox`, `--disable-gpu`, `--single-process`), manteniendo un uso medio de ~150MB a ~250MB de RAM solo durante la ejecución activa de la tarea.
> * **Proceso Remoto (Modo Producción / Multitenant - VPS RPA Dedicado):** Para evitar sobrecargar el servidor principal donde corre `aipods-core-engine` u Odoo, el AI Pod actúa como un cliente liviano (~10MB de RAM) que se conecta vía WebSocket a una VPS secundaria ejecutando un contenedor Docker de Playwright/Browserless (`playwright.chromium.connect("ws://vps-rpa.internal:3000")`).
> * **Ciclo de Vida Efímero:** Los contextos del navegador se abren y cierran inmediatamente al completar cada operación, garantizando la liberación total de memoria RAM.

---

## 1.2 Matriz de Servicios por Condición Fiscal

El AI Pod detecta o recibe la **Condición Fiscal** del contribuyente/representado para habilitar u omitir flujos de automatización según la normativa fiscal de ARCA:

| Servicio ARCA / AFIP | Monotributo (ej. CUIT `20262534538`) | Responsable Inscripto (RI) | IVA Exento | Comportamiento del AI Pod |
| :--- | :---: | :---: | :---: | :--- |
| **Domicilio Fiscal Electrónico (e-Ventanilla)** | ✅ Habilitado | ✅ Habilitado | ✅ Habilitado | Servicio común. Consulta notificaciones y requerimientos. |
| **Mis Comprobantes (Emitidos/Recibidos)** | ✅ Habilitado *(Facturas C)* | ✅ Habilitado *(Facturas A/B/M)* | ✅ Habilitado *(Facturas C/Exentas)* | Servicio común. Descarga comprobantes del período. |
| **Generación de VEP (SETI / Pagos)** | ✅ Habilitado *(Cuota Monotributo)* | ✅ Habilitado *(IVA, Autónomos, etc.)* | ✅ Habilitado | Servicio común. Generación de volantes de pago. |
| **Sistema Registral / Seguimiento de Trámites** | ✅ Habilitado | ✅ Habilitado | ✅ Habilitado | Servicio común. Consulta estado de cuenta y padrón. |
| **Portal Monotributo** | ✅ Habilitado | ❌ No aplica | ❌ No aplica | Pago de cuota, recategorización semestral, modificación. |
| **Mis Retenciones (SICORE / SIRE)** | ⚠️ Percepciones sufridas | ✅ Habilitado *(Retenciones + Percepciones)* | ⚠️ Limitado | En Monotributo se filtra por percepciones sufridas. |
| **Declaración en Línea (F.931 - SICOSS)** | ⚠️ Solo Monotributista Empleador | ✅ Habilitado *(Empleadores)* | ⚠️ Solo Empleador | El Pod verifica presencia de menú/DDJJ antes de descargar. |
| **Libro de IVA Digital / Portal IVA** | ❌ No aplica | ✅ Habilitado *(F.2002/2000)* | ❌ No aplica | Habilitado exclusivamente para Responsables Inscriptos. |
| **Convenio Multilateral (SIFERE WEB)** | ⚠️ Si tributa IIBB CM | ⚠️ Si tributa IIBB CM | ⚠️ Si tributa IIBB CM | Requiere alta en padrón federal IIBB. |

---

## 1.3 Ciclo de Vida del AI Pod (`POD_AFIP_FISCAL`)

El ciclo de vida operativo del AI Pod consta de 5 fases secuenciales:

```
[1. Provisionamiento & Secrets] ──► [2. Smart Router Intent] ──► [3. Dry-Run Protocol]
                                                                        │
[5. Dossier Audit & Telemetría] ◄── [4. Ejecución RPA (Playwright)] ◄───┘
```

1. **Phase 1: Provisionamiento & Secrets Vault Binding**
   * El tenant habilita `POD_AFIP_FISCAL`.
   * Las credenciales CUIT / Clave Fiscal / Certificados se resuelven de forma segura desde Bitwarden Vault (`SPEC-CORE-08`) o `cuits.json` local.
   * Se evalúa la Condición Fiscal (Monotributo / RI / Exento) para ajustar las capacidades activas.

2. **Phase 2: Intent Recognition & Dynamic Smart Router**
   * El `DynamicSmartRouter` captura la intención del usuario (ej: *"Descargá los comprobantes emitidos"* o *"Consultá mis puntos de venta"*) y deriva la solicitud a `POD_AFIP_FISCAL`.

3. **Phase 3: Protocolo Dry-Run (`dry_run=true`) & Human-in-the-Loop**
   * Para operaciones de consulta o mutación, el Pod evalúa parámetros y genera un `ApprovalToken` con el resumen del comando a ejecutar antes de tocar el portal oficial.

4. **Phase 4: Ejecución Desacoplada RPA (Playwright Engine)**
   * **Modo Local:** Playwright Chromium headless efímero (~150MB-250MB RAM).
   * **Modo Producción SaaS:** Conexión cliente ligera (~10MB RAM) vía WebSocket a la VPS RPA dedicada (`ws://vps-rpa.internal:3000`).
   * **Cierre Efímero:** Liberación total de recursos al finalizar la tarea (`browser.close()`).

5. **Phase 5: Dossier de Auditoría & Respuesta al Cliente**
   * Generación de la respuesta estructurada en Markdown/JSON con adjuntos (PDFs/Excels/Screenshots) y registro del hash de auditoría sin exponer claves.

---

## 2. Gestión de Credenciales & Seguridad (`cuits.json` / Vault)

Para entornos de pruebas locales, las credenciales de los contribuyentes se gestionan mediante el archivo `cuits.json` en la raíz del proyecto (excluido estrictamente mediante `.gitignore`).

### 2.1 Estructura Estándar de `cuits.json`
```json
{
  "contribuyentes": [
    {
      "cuit": "20334445559",
      "alias": "MiEmpresa_Pruebas",
      "clave_fiscal": "TuClaveFiscalSegura123",
      "nivel_clave": 3,
      "activo": true,
      "representados_frecuentes": [
        {
          "cuit": "30711234568",
          "razon_social": "Representada S.A."
        }
      ]
    }
  ]
}
```

> [!CAUTION]
> En entornos de producción multitenant, las claves fiscales nunca residen en archivos ni logs. El AI Pod resuelve las credenciales en tiempo de ejecución desde el Vault de Secretos (Bitwarden BYOV / HashiCorp Vault) de acuerdo a `SPEC-CORE-08`.

---

## 3. Historias de Usuario (User Stories)

### US-01: Descarga de Comprobantes Emitidos y Recibidos
**Como** consultor contable,  
**quiero** que el sistema navegue automáticamente al servicio "Mis Comprobantes" de ARCA, aplique un rango de fechas personalizado y descargue las facturas emitidas y/o recibidas en formato Excel o CSV,  
**para** tener los comprobantes del período en mi carpeta local sin ingresar manualmente al portal.

### US-02: Descarga de Retenciones y Percepciones (SICORE/SIRE)
**Como** contador responsable de las declaraciones juradas,  
**quiero** que el sistema itere sobre todos los impuestos del catálogo de "Mis Retenciones" (IVA, Ganancias, Bs. Personales, etc.) y descargue en Excel los que tengan movimientos en el período,  
**para** consolidar el resumen de retenciones sufridas sin riesgo de omitir ningún impuesto.

### US-03: Descarga de DDJJ Convenio Multilateral (SIFERE WEB)
**Como** contador de empresa que tributa en Convenio Multilateral,  
**quiero** que el sistema descargue como PDF cada DDJJ mensual (CM03/CM05) presentada en SIFERE WEB, incluyendo el detalle por jurisdicción provincial,  
**para** archivar digitalmente las presentaciones oficiales sin navegar manualmente por el menú de Comarb.

### US-04: Descarga de DDJJ SICOSS (Formulario 931)
**Como** responsable de Recursos Humanos / Liquidación de Sueldos,  
**quiero** que el sistema consulte los borradores/DDJJ presentadas en "Declaración en Línea", capture el popup dinámico de cada período y genere el PDF del Formulario 931,  
**para** verificar la nómina y cargas sociales de cada mes.

### US-05: Generación de VEP (Volante Electrónico de Pago)
**Como** tesorero o administrativo,  
**quiero** que el Pod complete el wizard interactivo del servicio "Pagos / SETI", seleccione el CUIT representado, el tipo de obligación, período y monto, y genere el VEP con su respectivo token y medio de pago,  
**para** automatizar la emisión de VEPs recurrentes sin errores de digitación.

### US-06: Consulta y Seguimiento de Trámites / E-Ventanilla
**Como** asesor fiscal,  
**quiero** que el Pod consulte las notificaciones no leídas en la E-Ventanilla y el estado de los trámites en curso,  
**para** recibir alertas tempranas de requerimientos o fiscalizaciones electrónicas.

### US-07: Consulta y Alta de Puntos de Venta (ABM Puntos de Venta y Domicilios)
**Como** administrador del sistema / consultor contable,  
**quiero** que el Pod consulte los Puntos de Venta vigentes y permita dar de alta nuevos Puntos de Venta (asociando el número de PV, sistema de facturación Web Services / RECE / Comprobantes en Línea y domicilio empadronado),  
**para** habilitar la facturación electrónica en Odoo o nuevos canales sin ingresar manualmente al servicio "Administración de Puntos de Venta y Domicilios".

---

## 4. Herramientas del AI Pod (Tools Schemas JSON)

### 4.1 Herramienta `generar_csr_openssl`
```json
{
  "name": "generar_csr_openssl",
  "description": "Genera los comandos OpenSSL exactos para crear la clave privada y la solicitud de certificado (CSR) de facturación electrónica AFIP/ARCA.",
  "parameters": {
    "type": "object",
    "properties": {
      "cuit": { "type": "string", "description": "CUIT de 11 dígitos sin guiones", "example": "20334445559" },
      "os": { "type": "string", "enum": ["Linux", "Windows", "macOS"], "description": "Sistema operativo del cliente" }
    },
    "required": ["cuit", "os"]
  }
}
```

### 4.2 Herramienta `analizar_balance_financiero`
```json
{
  "name": "analizar_balance_financiero",
  "description": "Extrae ingresos, egresos, EBITDA y margen operativo a partir de un balance financiero exportado de Odoo en CSV o PDF y provee un diagnóstico contable.",
  "parameters": {
    "type": "object",
    "properties": {
      "file_path": { "type": "string", "description": "Ruta absoluta al archivo CSV o PDF del balance" },
      "formato": { "type": "string", "enum": ["csv", "pdf"] }
    },
    "required": ["file_path"]
  }
}
```

### 4.3 Herramienta `descargar_comprobantes_arca`
```json
{
  "name": "descargar_comprobantes_arca",
  "description": "Navega al servicio Mis Comprobantes en ARCA y descarga archivos Excel/CSV de comprobantes emitidos o recibidos.",
  "parameters": {
    "type": "object",
    "properties": {
      "cuit_contribuyente": { "type": "string", "description": "CUIT del titular de la clave fiscal" },
      "cuit_representado": { "type": "string", "description": "CUIT de la empresa representada (opcional)" },
      "tipo": { "type": "string", "enum": ["Emitidos", "Recibidos"], "default": "Emitidos" },
      "fecha_desde": { "type": "string", "description": "Formato YYYY-MM-DD", "example": "2026-06-01" },
      "fecha_hasta": { "type": "string", "description": "Formato YYYY-MM-DD", "example": "2026-06-30" },
      "formato": { "type": "string", "enum": ["xlsx", "csv"], "default": "xlsx" },
      "dry_run": { "type": "boolean", "default": true, "description": "Si es true, valida parámetros y simula la navegación sin abrir navegador" }
    },
    "required": ["cuit_contribuyente", "fecha_desde", "fecha_hasta", "dry_run"]
  }
}
```

### 4.4 Herramienta `descargar_retenciones_arca`
```json
{
  "name": "descargar_retenciones_arca",
  "description": "Descarga desde el servicio Mis Retenciones el resumen de retenciones/percepciones sufridas por impuesto.",
  "parameters": {
    "type": "object",
    "properties": {
      "cuit_contribuyente": { "type": "string" },
      "cuit_representado": { "type": "string" },
      "impuesto_codigo": { "type": "string", "description": "Código o nombre del impuesto (ej. 217 - Ganancias, 767 - IVA)", "default": "TODOS" },
      "tipo_operacion": { "type": "string", "enum": ["Retencion", "Percepcion", "Ambos"], "default": "Ambos" },
      "fecha_desde": { "type": "string", "example": "2026-01-01" },
      "fecha_hasta": { "type": "string", "example": "2026-06-30" },
      "dry_run": { "type": "boolean", "default": true }
    },
    "required": ["cuit_contribuyente", "fecha_desde", "fecha_hasta", "dry_run"]
  }
}
```

### 4.5 Herramienta `descargar_ddjj_sifere_arca`
```json
{
  "name": "descargar_ddjj_sifere_arca",
  "description": "Descarga en PDF los formularios de declaraciones juradas mensuales de Convenio Multilateral desde SIFERE WEB.",
  "parameters": {
    "type": "object",
    "properties": {
      "cuit_contribuyente": { "type": "string" },
      "periodo_mes_desde": { "type": "string", "example": "01" },
      "periodo_anio_desde": { "type": "string", "example": "2026" },
      "periodo_mes_hasta": { "type": "string", "example": "06" },
      "periodo_anio_hasta": { "type": "string", "example": "2026" },
      "dry_run": { "type": "boolean", "default": true }
    },
    "required": ["cuit_contribuyente", "periodo_mes_desde", "periodo_anio_desde", "dry_run"]
  }
}
```

### 4.6 Herramienta `descargar_f931_arca`
```json
{
  "name": "descargar_f931_arca",
  "description": "Navega a Declaración en Línea y descarga en PDF los Formularios 931 presentados para un período determinado.",
  "parameters": {
    "type": "object",
    "properties": {
      "cuit_contribuyente": { "type": "string" },
      "periodo_yyyymm": { "type": "string", "description": "Año y mes en formato YYYYMM", "example": "202601" },
      "dry_run": { "type": "boolean", "default": true }
    },
    "required": ["cuit_contribuyente", "periodo_yyyymm", "dry_run"]
  }
}
```

### 4.7 Herramienta `generar_vep_arca`
```json
{
  "name": "generar_vep_arca",
  "description": "Ejecuta el wizard de generación de VEP en el servicio SETI/Pagos de ARCA.",
  "parameters": {
    "type": "object",
    "properties": {
      "cuit_contribuyente": { "type": "string" },
      "cuit_representado": { "type": "string" },
      "grupo_pago": { "type": "string", "example": "IVA" },
      "tipo_pago": { "type": "string", "example": "Declaración Jurada Mensual" },
      "periodo_mm": { "type": "string", "example": "06" },
      "periodo_aaaa": { "type": "string", "example": "2026" },
      "monto": { "type": "number", "example": 85000.00 },
      "dry_run": { "type": "boolean", "default": true }
    },
    "required": ["cuit_contribuyente", "grupo_pago", "monto", "dry_run"]
  }
}
```

### 4.8 Herramienta `consultar_estado_tramite_arca`
```json
{
  "name": "consultar_estado_tramite_arca",
  "description": "Consulta el resumen de notificaciones electrónicas y trámites en e-Ventanilla.",
  "parameters": {
    "type": "object",
    "properties": {
      "cuit_contribuyente": { "type": "string" },
      "solo_no_leidos": { "type": "boolean", "default": true },
      "dry_run": { "type": "boolean", "default": true }
    },
    "required": ["cuit_contribuyente", "dry_run"]
  }
}
```

### 4.9 Herramienta `gestionar_puntos_de_venta_arca`
```json
{
  "name": "gestionar_puntos_de_venta_arca",
  "description": "Consulta los puntos de venta habilitados o ejecuta el alta/baja de un punto de venta en el servicio Administración de Puntos de Venta y Domicilios de ARCA.",
  "parameters": {
    "type": "object",
    "properties": {
      "cuit_contribuyente": { "type": "string", "description": "CUIT del titular de la clave fiscal" },
      "cuit_representado": { "type": "string", "description": "CUIT de la empresa representada (opcional)" },
      "accion": { "type": "string", "enum": ["Consultar", "Alta", "Baja"], "default": "Consultar" },
      "numero_punto_venta": { "type": "integer", "description": "Número del punto de venta (ej. 7)", "example": 7 },
      "nombre_fantasia": { "type": "string", "example": "Facturación Odoo Production" },
      "sistema_emision": { "type": "string", "enum": ["Factura Electrónica - Monotributo Web Services", "RECE para aplicativo y/o web services", "Comprobantes en Línea"], "example": "RECE para aplicativo y/o web services" },
      "domicilio_asociado": { "type": "string", "description": "Domicilio empadronado asociado al punto de venta" },
      "dry_run": { "type": "boolean", "default": true }
    },
    "required": ["cuit_contribuyente", "accion", "dry_run"]
  }
}
```

---

## 5. Escenarios BDD de Aceptación (Gherkin)

```gherkin
Feature: Autenticación ARCA y Navegación Básica

  @autenticacion @navegacion
  Scenario: Autenticación exitosa y selección de representado
    Given que el portal ARCA está accesible en "https://auth.afip.gob.ar/contribuyente_/login.xhtml"
    And el CUIT del contribuyente es un CUIT válido registrado en el sistema
    And la clave fiscal es de nivel 3
    When Playwright llena el campo "#F1\:username" con el CUIT
    And hace click en "#F1\:btnSiguiente"
    And llena "#F1\:password" con la clave fiscal
    And hace click en "#F1\:btnIngresar"
    Then el portal debe redirigir al portal principal de ARCA
    And si hay un selector de representados debe aparecer la pantalla de selección
    And el script debe seleccionar el CUIT del representado indicado
    And el portal debe mostrar el panel de servicios del representado

Feature: Descarga de Comprobantes en ARCA

  @comprobantes @dry_run
  Scenario: Simulación de descarga de comprobantes emitidos con dry_run=true
    Given el parámetro "dry_run" está en true
    And el período solicitado es "2026-06-01" a "2026-06-30"
    And el tipo de comprobante es "Emitidos" en formato "xlsx"
    When se invoca la herramienta "descargar_comprobantes_arca"
    Then el sistema NO debe abrir el navegador
    And debe retornar un preview con los parámetros validados
    And el log debe incluir "[dry_run] Comprobantes Emitidos 2026-06-01 -> 2026-06-30 .xlsx"
    And ninguna credencial debe aparecer en el output

Feature: Descarga de Retenciones y Percepciones (Mis Retenciones)

  @retenciones @sin_datos
  Scenario: Consulta de período sin retenciones registradas
    Given que el contribuyente realiza la consulta para un rango de fechas sin movimientos
    When el script navega a Mis Retenciones y presiona "#btnConsultarRetenciones"
    Then el DOM debe mostrar el texto descriptivo "/no se encontraron|sin movimientos/i"
    And el script debe capturar este aviso sin arrojar excepción
    And debe retornar un resultado indicando total_registros=0 y archivo=null

Feature: Descarga de Formulario 931 (Declaración en Línea)

  @f931 @popup @pdf @cdp
  Scenario: Descarga exitosa del F.931 vía captura de popup y CDP Session
    Given que el contribuyente tiene una DDJJ presentada para el período "01/2026"
    And el sistema ya está autenticado en ARCA y en el servicio "Declaración en Línea"
    When el script extrae la llamada JavaScript "AbrirPopupBorrador('202601','001')" del HTML
    And ejecuta "page.evaluate('AbrirPopupBorrador(\"202601\",\"001\")')"
    And captura la nueva pestaña con "context.expect_page(timeout=15000)"
    And invoca CDP Session "Page.printToPDF" en la pestaña capturada
    Then se debe generar el archivo "F931_2026-01_sec001.pdf" con tamaño mayor a 0 bytes
    And el log de ejecución debe reportar "OK: F931_2026-01_sec001.pdf"

Feature: Generación de VEP (SETI Pagos)

  @vep @wizard @dry_run
  Scenario: Creación de VEP IVA mensual con dry_run=true
    Given el parámetro dry_run es true
    And los parámetros del VEP son grupo="IVA", tipo="Declaración Jurada Mensual", periodo="06/2026", monto=85000.00
    When se invoca "generar_vep_arca"
    Then el sistema retorna un JSON con los parámetros del VEP a generar
    And el campo "estimated_steps" lista los 4 pasos del wizard
    And el campo "warning" indica que no se ejecutará ninguna acción real en el portal

Feature: Administración de Puntos de Venta y Domicilios

  @puntos_de_venta @consulta
  Scenario: Consulta exitosa de Puntos de Venta empadronados
    Given que el contribuyente navega al servicio "Administración de Puntos de Venta y Domicilios"
    When el script selecciona la empresa y presiona "A/B/M de Puntos de Venta"
    Then el sistema debe extraer la lista de Puntos de Venta con su número, sistema de emisión y estado
    And retornar la estructura JSON con los PV vigentes

  @puntos_de_venta @alta @dry_run
  Scenario: Simulación de alta de nuevo Punto de Venta Web Services con dry_run=true
    Given el parámetro dry_run es true
    And los datos del nuevo PV son numero=7, sistema="RECE para aplicativo y/o web services", nombre="Odoo Prod"
    When se invoca "gestionar_puntos_de_venta_arca" con accion="Alta"
    Then el sistema debe simular los pasos del alta sin confirmar el formulario en el portal
    And retornar un aviso de pre-confirmación indicando los datos a registrar
```

---

## 6. Mapa de Selectores DOM & Estrategias Playwright

### 6.1 Tabla de Selectores CSS Primarios

| Servicio | Elemento | Selector CSS / Estrategia |
| :--- | :--- | :--- |
| **Autenticación** | Campo CUIT | `id=F1:username` *(Verificado en ARCA)* |
| **Autenticación** | Botón Siguiente | `id=F1:btnSiguiente` |
| **Autenticación** | Campo Clave Fiscal | `id=F1:password` |
| **Autenticación** | Botón Ingresar | `id=F1:btnIngresar` |
| **Portal ARCA** | Card Servicio | `#serviciosMasUtilizados div[style*='cursor: pointer']:has(h3:text-is('{nombre}'))` |
| **Portal ARCA** | Buscador de Servicios | `input[placeholder*='Buscador'], #buscadorInput` |
| **Mis Comprobantes** | Botón Recibidos | `#btnRecibidos` |
| **Mis Comprobantes** | Botón Emitidos | `#btnEmitidos` |
| **Mis Comprobantes** | Datepicker Rango | `input[name='daterangepicker_start']`, `input[name='daterangepicker_end']` |
| **Mis Comprobantes** | Botón Exportar | `a:has-text('Excel')`, `a:has-text('CSV')` |
| **Mis Retenciones** | Dropdown Impuesto | `#selectImpuestos` |
| **Mis Retenciones** | Opción Impuesto | `#selectImpuestos-multiselect-options li[role='option'][aria-label^='{codigo} -']` |
| **Mis Retenciones** | Radio Operación | `#tipoOperacion input[type='radio'][value='1']` *(Retención)* / `value='2'` *(Percepción)* |
| **Declaración en Línea**| Popup F.931 | Call JS `AbrirPopupBorrador('{yyyymm}','{sec}')` -> `context.expect_page()` |
| **Generar VEP** | Inputs Vue (Monto/Mes)| `#inp1`, `#inp2`, `#inp3` *(Requiere `press_sequentially` para reactividad Vue)* |

### 6.2 Diccionario JSON Integrado para la Configuración del Pod

```json
{
  "auth": {
    "cuit_field": "id=F1:username",
    "next_button": "id=F1:btnSiguiente",
    "password_field": "id=F1:password",
    "login_button": "id=F1:btnIngresar"
  },
  "portal": {
    "service_card": "#serviciosMasUtilizados div[style*='cursor: pointer']:has(h3:text-is('{nombre}'))",
    "search_input": "#buscadorInput",
    "search_result": "li[aria-label='{nombre}'] a.dropdown-item"
  },
  "mis_comprobantes": {
    "btn_recibidos": "#btnRecibidos",
    "btn_emitidos": "#btnEmitidos",
    "datepicker": "#fechaEmision",
    "range_custom": "li[data-range-key='Rango Personalizado']",
    "date_from": "input[name='daterangepicker_start']",
    "date_to": "input[name='daterangepicker_end']",
    "apply_range": "button.applyBtn",
    "buscar": "button:has-text('Buscar')",
    "export_excel": "a:has-text('Excel')",
    "export_csv": "a:has-text('CSV')"
  },
  "mis_retenciones": {
    "impuesto_input": "#selectImpuestos",
    "impuesto_option": "#selectImpuestos-multiselect-options li[role='option'][aria-label^='{codigo} -']",
    "radio_retencion": "#tipoOperacion input[type='radio'][value='1']",
    "radio_percepcion": "#tipoOperacion input[type='radio'][value='2']",
    "fecha_desde": "#datePickerFechasRetencionesDesde__input",
    "fecha_hasta": "#datePickerFechasRetencionesHasta__input",
    "consultar": "#btnConsultarRetenciones",
    "exportar_btn": "button:has-text('Exportar'):not(:has-text('SIAP'))",
    "exportar_excel": "li[role='menuitem']:has-text('Excel')"
  },
  "sifere": {
    "url_mensuales": "https://app1.comarb.gob.ar/siferewebconsultas/sfrDdjj.do?method=buscarMensualesIn",
    "mes_desde": "#mesDesdeStr",
    "anio_desde": "#anioDesdeStr",
    "mes_hasta": "#mesHastaStr",
    "anio_hasta": "#anioHastaStr",
    "buscar": "input[type='submit']",
    "pdf_method": "CDP:Page.printToPDF"
  },
  "declaracion_en_linea": {
    "url_consulta": "https://serviciossegsoc.afip.gob.ar/djproforma/app/consultar/dj_generadas.aspx",
    "aviso_aceptar": "input[type='image'][id*='Aviso1_btnAceptar']",
    "ddjj_js_pattern": "AbrirPopupBorrador('YYYYMM','SSS')",
    "popup_capture": "ctx.expect_page(timeout=15000)",
    "pdf_method": "CDP:Page.printToPDF"
  },
  "generar_vep": {
    "card_pagos": "div.seti-box:has(h5:has(b:text-is('Pagos')))",
    "btn_generar_vep": "button:has-text('Generar VEP')",
    "btn_nuevo_vep": "a:has-text('Nuevo VEP'):not(:has-text('Desde'))",
    "select_cuit": "#selectCuit",
    "select_grupo": "#selectGrupoTipoPago",
    "select_tipo_pago": "#selectTipoPago",
    "inp_mes": "#inp1",
    "inp_anio": "#inp2",
    "inp_monto": "#inp3",
    "btn_siguiente": "button:has-text('Siguiente'):not([disabled])",
    "btn_medio_pago": "button#medioPago",
    "dismiss_tour": "button:has-text('Saltar intro')"
  }
}
```
