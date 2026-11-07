# SPEC-CORE-68: Telemetría medida y métricas CMMI calculadas del git

**Estado:** IN_PROGRESS
**Épica:** 01 Core Engine / 03 Admin Hub
**Repos afectados:** aipods-core-engine, aipods-frontend-admin

## 1. Motivación

`/metrics` y `/api/v1/admin/telemetry` mostraban números inventados:

- El collector de telemetría nunca recibía datos: ninguna ruta llamaba a `RecordRequest` ni a `RecordRateLimitExceeded`.
- El endpoint del admin devolvía valores fijos (latencia 12.4 ms, 3 pods, 0 bloqueos).
- Las métricas CMMI nivel 4 de `/metrics` eran constantes (trazabilidad 100%, densidad 0.00, lead time 2.18 h).
- El panel de telemetría del admin arrancaba con valores de ejemplo y un ratio de caché por defecto de 82.4%.

## 2. Decisiones

| Tema | Decisión |
|---|---|
| Telemetría de runtime | Se mide en el core desde el arranque: consultas a pods por pod y status, latencia promedio, bloqueos del rate limiter, pods registrados y caché semántica. Se reinicia con cada deploy. |
| CMMI | Se calcula del historial git del core al construir la imagen Docker (`cmd/cmmi-report`) y se guarda en `cmmi.json` junto al binario. El core lo lee al arrancar (`CMMI_REPORT_FILE`, default `cmmi.json`). |
| Sin datos | Si no hay historial git o falta el reporte, `/metrics` omite las métricas CMMI y el admin muestra "sin reporte". Nunca se muestran valores de ejemplo. |

## 3. Requisitos

- **R1.** `POST /api/v1/chat/completions` y la consulta del sandbox registran cada llamada con su pod, duración y status (500 si falla el ruteo).
- **R2.** El rate limiter registra cada request bloqueado (HTTP 429).
- **R3.** `GET /api/v1/admin/telemetry` devuelve `{status, telemetry}` con `pod_requests`, `avg_latency_ms`, `cache_hits`, `cache_misses`, `cache_purged`, `rate_limit_blocked`, `active_pods_count`, `requests_by_pod_status` y `cmmi` (o `null`).
- **R4.** `/metrics` expone en formato Prometheus los mismos valores medidos y, si hay reporte, `aipods_cmmi_report_info{commit,generated_at,shallow}`, `aipods_cmmi_commits_total`, `aipods_cmmi_level4_spec_traceability_index`, `aipods_cmmi_level4_defect_density_per_kloc` y `aipods_cmmi_level4_avg_spec_lead_time_hours`.
- **R5.** Definición de las métricas CMMI (commits sin merges):
  - **Trazabilidad:** fracción de commits cuyo asunto cita `RFC-NNNN`, `SPEC-NNNN`, `SPEC-XXX-NN` o `#NN`. El sufijo `(#N)` que agrega el squash merge de GitHub no cuenta.
  - **Densidad de defectos:** commits de fix (`[FIX]` o `fix:`) por cada 1000 líneas de Go sin tests ni vendor.
  - **Lead time por spec:** horas entre el primer y el último commit de cada spec con 2 o más commits; se informa el promedio.
- **R6.** El panel de telemetría del admin muestra solo datos del core, indica "sin datos" cuando no hay tráfico y muestra el commit y el tamaño del historial usado para CMMI, avisando si es parcial.

## 4. Limitaciones

- Con squash merge cada PR es un solo commit, así que el lead time por spec mide el tiempo entre PRs de la misma spec, no el tiempo de trabajo dentro de un PR.
- Si la imagen se construye desde un clon parcial (`shallow`), las métricas cubren solo ese historial y el reporte lo indica.
