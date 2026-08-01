# 📜 SPEC MAESTRA 05: Native Campaign Engine, Page Builder & Component Library
**ID Épica:** EPIC-GROWTH-CAMPAIGNS  
**Estándar de Arquitectura:** ISO/IEC/IEEE 26514:2022 & CMMI Level 4  
**Estado:** CONSOLIDATED MASTER SPECIFICATION  
**ID Trazabilidad:** SPEC-CORE-48  

---

## 🏛️ Índice de Especificaciones Consolidadas en esta Épica

- [1. Visión y Objetivos de Negocio](#1-visión-y-objetivos-de-negocio)
- [2. Arquitectura Backend Go & Campaign Scheduler Engine](#2-arquitectura-backend-go--campaign-scheduler-engine)
- [3. Componentes Visuales & Ancho Completo (100vw Immersive Banner)](#3-componentes-visuales--ancho-completo-100vw-immersive-banner)
- [4. Micro-Componentes Promocionales (Cintas, Precios Tachados, Trust Badges)](#4-micro-componentes-promocionales-cintas-precios-tachados-trust-badges)
- [5. Dynamic Carousel & Auto-Rotating Banner Engine](#5-dynamic-carousel--auto-rotating-banner-engine)
- [6. Tracking Pixels, SEO & Open Graph Meta Tags Engine](#6-tracking-pixels-seo--open-graph-meta-tags-engine)

---

## 1. Visión y Objetivos de Negocio

Esta especificación establece la infraestructura nativa para la **creación, programación y rotación de Landing Pages y Campañas Comerciales** en el sitio principal (`aipods-frontend-customer`).

Permite al equipo de Marketing y Administración publicar páginas web estacionales (*Black Friday, Cierre Fiscal AFIP/ARCA, Lanzamientos de Pods*) totalmente dinámicas, **sin tocar código, sin licencias de terceros y con latencias sub-10ms en Redis Cache**.

---

## 2. Arquitectura Backend Go & Campaign Scheduler Engine

### 2.1 Modelo de Datos JSON Schema (`CampaignSpec`)

```go
package campaign

import "time"

type CampaignStatus string

const (
	StatusDraft     CampaignStatus = "DRAFT"
	StatusScheduled CampaignStatus = "SCHEDULED"
	StatusActive    CampaignStatus = "ACTIVE"
	StatusExpired   CampaignStatus = "EXPIRED"
)

type BlockConfig struct {
	ID         string                 `json:"id"`
	Type       string                 `json:"type"` // HERO_BANNER, POD_HIGHLIGHT, CAROUSEL_BANNER, PRICING_PROMO
	Order      int                    `json:"order"`
	Properties map[string]interface{} `json:"properties"`
}

type Campaign struct {
	ID           string         `json:"id"`
	Slug         string         `json:"slug"`
	Title        string         `json:"title"`
	TargetRegion string         `json:"target_region"` // "es_AR", "es_CL", "pt_BR", "ALL"
	StartsAt     time.Time      `json:"starts_at"`
	EndsAt       time.Time      `json:"ends_at"`
	Status       CampaignStatus `json:"status"`
	Blocks       []BlockConfig  `json:"blocks"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
}
```

---

## 3. Componentes Visuales & Ancho Completo (100vw Immersive Banner)

Inspirado en los estándares visuales de marcas globales como **Xiaomi y Apple**, permite desplegar banners inmersivos que rompen el contenedor encajonado de 1200px para ocupar el **100% del ancho del viewport (`100vw`)**.

### 3.1 Animación CSS de Llenado de Barra (6 segundos)

```css
/* Barras de Progreso Segmentadas Animadas estilo Xiaomi (SPEC-CORE-48) */
.carousel-progress-segment {
  height: 3px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 2px;
  overflow: hidden;
  position: relative;
  flex: 1;
}

.carousel-progress-fill.animating {
  height: 100%;
  background: #ff6900; /* Naranja Xiaomi / Cyan Acento */
  animation: fillProgress 6s linear forwards;
}

@keyframes fillProgress {
  from { width: 0%; }
  to { width: 100%; }
}
```

---

## 4. Micro-Componentes Promocionales (Cintas, Precios Tachados, Trust Badges)

Permite inyectar elementos de impacto psicológico de ventas sobre cualquier imagen o tarjeta:

1. **Corner Ribbons (Cintas de Esquina en Ángulo 45°)**: Textos tipo `HOT SALE`, `30% OFF` o `CIERRE FISCAL`.
2. **Precios Tachados vs Promocionales**: Muestra el precio normal censurado (`ARS $150.000 / mes`) junto al precio promocional destacado (`ARS $105.000 / mes`) con pill verde de `AHORRAS 30%`.
3. **Trust & Security Badges**: Insignias `[ 🔒 Cifrado AES-256 ]`, `[ 🛡️ Garantía 30 Días ]`, `[ ⚡ Despliegue < 60s ]`.

---

## 5. Dynamic Carousel & Auto-Rotating Banner Engine

- **Auto-Play & Timer Configurable**: Rotación suave programable (ej. cada 6 segundos) con barra de progreso.
- **Pause-on-Hover**: Congelamiento automático cuando el cursor pasa sobre el banner para evitar que se escape la diapositiva.
- **Botón de Pausa / Play**: Control interactivo `[ ⏸️ / ▶️ ]` en la barra inferior.
- **Touch Swipe**: Desplazamiento gestual táctil en teléfonos y tablets.

---

## 6. Tracking Pixels, SEO & Open Graph Meta Tags Engine

### 6.1 Sanitized Tracking Pipeline
Inyección segura solicitando únicamente los IDs de seguimiento (evitando riesgos de vulnerabilidad XSS):
- **Google Analytics 4**: ID `G-XXXXXXXXXX`
- **Meta / Facebook Pixel**: ID `123456789012345`
- **Google Tag Manager**: ID `GTM-XXXXXXX`
- **LinkedIn Insight Tag**: ID `1234567`

### 6.2 SEO & Open Graph Meta Tags
Inyección dinámica de `<title>`, `<meta name="description">`, `<meta name="keywords">`, etiquetas `og:image` para previsualizaciones en WhatsApp/LinkedIn y datos estructurados **JSON-LD Schema.org** para Google Rich Snippets.
