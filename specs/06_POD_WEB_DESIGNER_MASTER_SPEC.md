# 🤖 SPEC MAESTRA 06: POD_WEB_DESIGNER — AI Agent & Multimodal Suite
**ID Épica:** EPIC-AI-POD-WEB-DESIGNER  
**Estándar de Arquitectura:** ISO/IEC/IEEE 26514:2022 & CMMI Level 4  
**Estado:** CONSOLIDATED MASTER SPECIFICATION  
**ID Trazabilidad:** SPEC-CORE-49  

---

## 🏛️ Índice de Especificaciones Consolidadas en esta Épica

- [1. Visión del Agente Autónomo POD_WEB_DESIGNER](#1-visión-del-agente-autónomo-pod_web_designer)
- [2. Arquitectura de Despliegue en VPS Segregada (Offloading Strategy)](#2-arquitectura-de-despliegue-en-vps-segregada-offloading-strategy)
- [3. Pipeline Multimodal & Visual Feedback Loop (Análisis de Capturas)](#3-pipeline-multimodal--visual-feedback-loop-análisis-de-capturas)
- [4. Visual Inspector Mode (Odoo Debug Style Overlays)](#4-visual-inspector-mode-odoo-debug-style-overlays)
- [5. Biblioteca de Plantillas & Descubribilidad (Feature Discovery)](#5-biblioteca-de-plantillas--descubribilidad-feature-discovery)
- [6. Innovaciones Avanzadas (A/B Testing, Heatmaps & Geo-Personalización)](#6-innovaciones-avanzadas-ab-testing-heatmaps--geo-personalización)

---

## 1. Visión del Agente Autónomo POD_WEB_DESIGNER

El **`POD_WEB_DESIGNER`** es un AI Pod especializado de consumo interno (*Agente Autónomo Diseñador Web & Marketing Strategist*).

Permite al equipo comercial crear, personalizar y publicar campañas completas mediante lenguaje natural y feedback visual, redactando el copy persuasivo (AIDA/PAS), respetando los Design Tokens (`SPEC-CORE-22`) y programando la vigencia sin intervención técnica.

---

## 2. Arquitectura de Despliegue en VPS Segregada (Offloading Strategy)

Para **preservar la latencia sub-15ms y la memoria del Core Engine**, el `POD_WEB_DESIGNER` opera en una **VPS / Microservicio Aislado**, comunicándose asincrónicamente mediante mTLS / gRPC con la base de datos principal y Redis Cache.

---

## 3. Pipeline Multimodal & Visual Feedback Loop (Análisis de Capturas)

Permite al usuario adjuntar **capturas de pantalla, bocetos o mockups** al chat. Mediante un modelo de visión por computadora (*Vision LLM*), el Pod analiza la imagen comparándola con la maquetación actual y aplica los deltas de ajuste al JSON Schema con precisión absoluta.

---

## 4. Visual Inspector Mode (Odoo Debug Style Overlays)

Inspirado en el **Developer Mode de Odoo ERP**, al activar `🛠️ Modo Inspector` en el Admin Hub:
- Cada elemento despliega un badge traslúcido con su nombre amigable e ID técnico (`[ 🏷️ #hero.cta_primary_button ]`).
- Hacer clic en cualquier objeto inyecta automáticamente su ID en el prompt del chat (`[ 🎯 Editando: #hero.cta_primary_button ]`).

---

## 5. Biblioteca de Plantillas & Descubribilidad (Feature Discovery)

- **Starter Template Library**: Fichas técnicas con presets (`tpl_cierre_fiscal`, `tpl_hot_sale`, `tpl_product_launch`, `tpl_enterprise_b2b`).
- **Smart Proactive Prompts**: El Pod sugiere proactivamente comandos avanzados al iniciar la conversación.
- **Marketing Toolbox Drawer**: Panel lateral de 1-clic para inyectar banners 100vw, cintas o precios tachados.

---

## 6. Innovaciones Avanzadas (A/B Testing, Heatmaps & Geo-Personalización)

1. **Auto A/B Testing**: Generación de 2 variantes de portada con selección automática del ganador tras 500 visitas.
2. **Synthetic Heatmaps**: Predicción de atención visual (*Eye-Tracking AI*) antes de publicar.
3. **Geo-Personalización**: Detección nativa de país (`es_AR`, `pt_BR`, `en_US`), adaptando automáticamente idioma, precios y moneda (`SPEC-CORE-45`).
