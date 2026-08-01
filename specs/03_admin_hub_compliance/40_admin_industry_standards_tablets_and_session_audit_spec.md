# 📜 SPEC: Rediseño Layout Admin — Full-Width Fluid Layout (27" / 4K), Responsividad Tablets $\ge$ 8" & Sub-Sidebar
**ID:** SPEC-CORE-40  
**Épica Relacionada:** Admin UX & Ergonomía Visual, Full-Width Panoramic Support (27" / 4K), Responsividad Tablet ($\ge$ 8") & Sub-Sidebar Navigation  
**Issue Relacionado:** `#21` ([`[FEAT] Admin Hub: Full-Width Fluid Layout (27" / 4K / UltraWide Support), Sub-Sidebar & Tablet Responsiveness`](https://github.com/onlyone-ai-pods/aipods-docs/issues/21))  
**Estado:** APPROVED / SPEC-DRIVEN  

---

## 1. Visión y Objetivos

Esta especificación establece la arquitectura de **Full-Width Fluid Layout (Ancho Fluido Panorámico al 100%)** para el **Admin Review Hub** (`aipods-frontend-admin`), eliminando desperdicios de espacio y márgenes negros en monitores grandes de 27", monitores 4K y pantallas UltraWide.

Establece las reglas de diseño:
1. **Full-Width Fluid Layout (100% Ancho Utilitario)**: Sustitución de límites rígidos (`max-width: 1300px`) por contenedores adaptativos fluidos (`width: 100%; padding: 0 32px;`).
2. **Grids Panorámicos Auto-Adaptativos**: Las tarjetas de telemetría, métricas FinOps y aprobaciones `Dry-Run` se distribuyen dinámicamente en 4 a 6 columnas en monitores de 27".
3. **Sub-Menú Lateral Colapsable (`AdminSubSidebar.jsx`)**: Descomposición de pestañas complejas en sub-módulos laterales.
4. **Responsividad para Tablets desde 8 Pulgadas ($\ge 768\text{px}$)**: Colapsado automático a modo compacto de solo-iconos con superficies táctiles de toque $\ge 44\text{px}$ (ISO 9241-210 / WCAG 2.1 AAA).

---

## 2. Diagrama del Layout Fluido Panorámico (27" / 4K)

```mermaid
graph TD
    Device[Monitor / Display] --> ResolutionCheck{Resolución & Tamaño}
    
    ResolutionCheck -->|Desktop 27" / 4K / UltraWide (>= 1440px)| FullWidth[Full-Width Fluid Layout 100% + Grid 4 a 6 Columnas]
    ResolutionCheck -->|Desktop Standard (1024px - 1439px)| StandardFluid[Fluid Layout 100% + Grid 2 a 3 Columnas]
    ResolutionCheck -->|Tablet 8" a 10" (768px - 1023px)| TabletLayout[Sub-Sidebar Compacta 64px + Targets Táctiles >= 44px]

    FullWidth --> FullUtilization[🎯 Aprovechamiento del 100% del Ancho de Pantalla (Cero Márgenes Negros)]
```

---

## 3. Matriz de Adaptabilidad por Resolución

| Resolución / Monitor | Ancho Contenedor | Columnas Grid | Estado de Sub-Sidebar |
|---|---|---|---|
| **Monitor 27" / 4K / UltraWide** ($\ge 1440\text{px}$) | `width: 100%; padding: 0 32px;` | 4 a 6 Columnas Panorámicas | Expandido (210px) |
| **Desktop Estándar** ($1024\text{px} - 1439\text{px}$) | `width: 100%; padding: 0 24px;` | 2 a 3 Columnas | Expandido / Colapsable |
| **Tablet 8" a 10"** ($768\text{px} - 1023\text{px}$) | `width: 100%; padding: 0 16px;` | 1 a 2 Columnas | Compacto Icon-Only (64px) |

---

## 4. Escenarios BDD

```gherkin
Feature: Full-Width Fluid Layout para Monitores Grandes de 27"

  Scenario: Navegación en Monitor de 27 Pulgadas (2560x1440)
    Given un administrador operando desde un monitor de 27 pulgadas a resolución 1440p
    When abre la consola Admin Hub en `http://localhost:3001`
    Then el layout debe expandirse al 100% del ancho del viewport sin márgenes negros a los lados
    And las tarjetas de telemetría y métricas deben organizarse dinámicamente en 4 columnas
```
