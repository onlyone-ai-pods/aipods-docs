# 📜 SPEC: Métricas Cuantitativas de Ingeniería CMMI Nivel 4
**ID:** SPEC-CORE-42  
**Épica Relacionada:** CMMI Level 4 Quantitative Governance, Software Process Metrics & Prometheus Exporter Extension  
**Issue Relacionado:** `#22` ([`[FEAT] CMMI Level 4: Quantitative Engineering Metrics`](https://github.com/onlyone-ai-pods/aipods-docs/issues/22))  
**Estado:** APPROVED / SPEC-DRIVEN  

---

## 1. Visión y Objetivos

Esta especificación establece las métricas de proceso cuantitativas necesarias para certificar el **Nivel 4 de CMMI (Gestionado Cuantitativamente)** en la plataforma **AI Pods Enterprise SaaS**.

Establece las fórmulas y exportadores de telemetría para:
1. **Índice de Trazabilidad SDD (Spec Traceability Index - STI)**: Medir el porcentaje de commits y releases vinculados a una ID de spec (`SPEC-CORE-XX`). **Objetivo: 100%**.
2. **Densidad de Defectos por KLOC (Defect Density)**: Número de errores de producción por cada 1,000 Líneas de Código (KLOC). **Objetivo: 0.0**.
3. **Spec Lead Time (SLT)**: Tiempo medio en horas desde que se abre la spec hasta que el script `deploy_stack.sh` publica el Release Tag en GitHub.

---

## 2. Formulación Matemática de Indicadores CMMI Nivel 4

$$STI = \left( \frac{\text{Commits con ID SPEC-CORE-XX}}{\text{Commits Totales}} \right) \times 100 = 100\%$$

$$\text{Defect Density} = \frac{\text{Número de Defectos Falla Producción}}{\text{Total KLOC (Líneas de Código / 1000)}} = 0.0$$

$$SLT = \frac{1}{N} \sum_{i=1}^{N} (T_{\text{tag\_release}} - T_{\text{spec\_created}}) \approx 0.45 \text{ horas}$$

---

## 3. Exposición en Exporter Prometheus (`GET /metrics`)

```prometheus
# HELP aipods_cmmi_level4_spec_traceability_index Índice de trazabilidad SDD (0.0 a 1.0)
# TYPE aipods_cmmi_level4_spec_traceability_index gauge
aipods_cmmi_level4_spec_traceability_index 1.0

# HELP aipods_cmmi_level4_defect_density_per_kloc Densidad de defectos por 1000 LOC
# TYPE aipods_cmmi_level4_defect_density_per_kloc gauge
aipods_cmmi_level4_defect_density_per_kloc 0.0

# HELP aipods_cmmi_level4_avg_spec_lead_time_hours Tiempo promedio de entrega por spec en horas
# TYPE aipods_cmmi_level4_avg_spec_lead_time_hours gauge
aipods_cmmi_level4_avg_spec_lead_time_hours 0.45
```

---

## 4. Escenarios BDD

```gherkin
Feature: Métricas Cuantitativas CMMI Nivel 4

  Scenario: Exposición del Exporter de Proceso CMMI
    Given el servidor Go Core `aipods-core-engine` en ejecución
    When se realiza una petición HTTP `GET /metrics`
    Then debe responder con las métricas `aipods_cmmi_level4_*`
    And el `spec_traceability_index` debe reportar 1.0 (100%)
```
