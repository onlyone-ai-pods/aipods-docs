# SPEC-CORE-69: Consumo real de tokens por tenant (FinOps)

**Estado:** IN_PROGRESS
**Épica:** 01 Core Engine / 03 Admin Hub
**Repos afectados:** aipods-core-engine, aipods-frontend-admin

## 1. Motivación

El panel FinOps del admin mostraba tenants, tokens y costos inventados. El core llama a Claude en cada consulta (clasificación del pod y redacción de la respuesta, SPEC-CORE-66) pero no guardaba cuántos tokens usaba ni para qué tenant.

## 2. Decisiones

| Tema | Decisión |
|---|---|
| Qué se mide | Cada respuesta de la API de Claude: tokens de entrada, salida, lectura y escritura de caché, modelo que respondió y propósito (`classify` o `answer`). Las negativas (`refusal`) también se cuentan porque se facturan. |
| Atribución | `RouteAndExecute` marca el contexto con el tenant (`llm.WithTenant`). Una llamada sin tenant se guarda como `SIN_TENANT`. |
| Modelo | Se guarda el modelo que devolvió la API, que puede ser distinto del pedido si respondió un fallback del servidor. |
| Costo | Estimado con precios de lista de Anthropic por millón de tokens (al 2026-10-06), en `cmd/server/finops.go`. Escritura de caché a 1,25 veces la entrada. Un modelo sin precio conocido se informa aparte y no suma. La factura de Anthropic es la referencia. |
| Falla al registrar | Nunca corta la consulta del cliente: se loguea y sigue. |

## 3. Requisitos

- **R1.** Tabla `llm_usage` (migración `0003_llm_usage.sql`) con una fila por llamada.
- **R2.** `GET /api/v1/admin/finops/usage?days=N&tenant_id=X` (N entre 1 y 366, 30 por defecto) devuelve, por tenant: llamadas, tokens por tipo, costo estimado, modelos sin precio y el detalle por modelo, más el costo total del período y la fecha de los precios.
- **R3.** `platform_admin` y `auditor` ven todos los tenants; `tenant_admin` solo el suyo (otro tenant responde 403); `customer` no tiene acceso.
- **R4.** El panel FinOps del admin muestra esos datos para 7, 30 o 90 días, respeta el tenant activo y no tiene valores de ejemplo.

## 4. Fuera de alcance

- Cuotas o límites de tokens por plan y alertas de consumo alto (la pestaña Gestión Multi-Tenant todavía usa datos de ejemplo).
- Conciliación con la Usage and Cost API de Anthropic.
