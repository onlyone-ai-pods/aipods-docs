# 📄 Especificación SDD: Ingesta RAG Multimodal & Multi-Fuente (Multimodal Ingestion Pipeline)

**Especificación ID:** `05_multimodal_and_multisource_rag_ingestion_spec`  
**Dominio:** Arquitectura Core Backend & AI Pods  
**Versión:** `8.3.0`  
**Estado:** PROPUESTO & CLARIFICADO  

---

## 1. División Clara de Responsabilidades: Core Engine vs. AI Pods Especializados

Para mantener el motor backend en Go **100% ligero, universal y sub-milisegundo**, se establece una separación estricta entre la extracción nativa de documentos y la transcripción/sincronización externa:

### A. Lo que se implementa DIRECTAMENTE EN EL CORE ENGINE (`aipods-core-engine`)
* **Formatos de Texto Estructurado:** Archivos `.pdf`, Markdown (`.md`), reStructuredText (`.rst`), `.txt`, `.json`, `.yaml`, `.csv`.
* **Razón Arquitectónica:** Se procesan mediante librerías nativas en Go de ultra-alta velocidad sin necesidad de invocar modelos pesados de IA ni generar latencia de red. El Core parsea, fragmenta (*chunking*) e indexa los vectores en Qdrant directamente.

### B. Lo que se implementa MEDIANTE UN CONJUTO DE AI PODS ESPECIALIZADOS
* **Multimedia & Audio/Video (`.mp3`, `.wav`, `.mp4`):** Procesados por el **`AI Pod Transcriptor Multimodal`** (utilizando modelos Whisper / Gemini Multimodal para Speech-to-Text).
* **Conectores Cloud Workspace (Google Drive, Notion, Confluence):** Procesados por el **`AI Pod Conector Cloud Workspace`** (manejando flujo OAuth2, tokens de renovación y sincronización de deltas).
* **Razón Arquitectónica:** Evita sobrecargar el binario del Core Engine con binarios pesados (como `ffmpeg`), modelos pesados de procesamiento de voz o lógica de autenticación específica de proveedores SaaS.

---

## 2. Diagrama de Flujo de Decisiones de Ingesta

```text
                               ┌────────────────────────────────────────────────────────┐
                               │ Documento / Fuente de Información Entrante a la Plataforma │
                               └───────────────────────────┬────────────────────────────┘
                                                           │
                                           ¿De qué tipo de archivo se trata?
                                                           │
                     ┌─────────────────────────────────────┼─────────────────────────────────────┐
                     ▼                                     ▼                                     ▼
      [ Archivos de Texto Estructurado ]          [ Archivos Multimedia ]             [ Fuentes Cloud SaaS ]
        (.pdf, .md, .rst, .txt, .json)               (.mp3, .wav, .mp4)               (Google Drive, Notion)
                     │                                     │                                     │
                     ▼                                     ▼                                     ▼
        PROCESADO DIRECTAMENTE EN EL               ENVIADO AL AI POD ESPECIALIZADO       ENVIADO AL AI POD ESPECIALIZADO
             CORE ENGINE (GO)                         "Transcriptor Multimodal"             "Conector Cloud Workspace"
                     │                                     │                                     │
                     │ (Extracción nativa              (Transcripción Speech-to-Text         (Sincronización OAuth2
                     │  sub-milisegundo)                    con timestamps)                       y extracción de deltas)
                     │                                     │                                     │
                     └─────────────────────────────────────┼─────────────────────────────────────┘
                                                           │
                                                           ▼
                                           [ Fragmentación & Indexación Vectorial ]
                                              Qdrant Vector DB (Multi-Tenant)
```

---

## 3. Matriz Definitiva de Implementación

| Tipo de Fuente / Archivo | Dónde se Implementa | Componente / Paquete | Justificación Técnica |
| :--- | :--- | :--- | :--- |
| **PDF (`.pdf`)** | **Core Engine** | `internal/rag/pdf_ingest.go` | Parsers nativos en Go. Extracción estática sub-milisegundo. |
| **Markdown (`.md`)** | **Core Engine** | `internal/rag/md_ingest.go` | Parsing AST de encabezados nativo en Go. |
| **reST (`.rst`)** | **Core Engine** | `internal/rag/rst_ingest.go` | Parsing de secciones estructuradas nativo en Go. |
| **Texto Plano (`.txt`)** | **Core Engine** | `internal/rag/txt_ingest.go` | Lectura de caracteres en Go. |
| **Audio (`.mp3`, `.wav`)** | **AI Pod Especializado** | `POD_MULTIMEDIA_WHISPER` | Requiere modelos de IA Speech-to-Text (Whisper/Gemini). |
| **Video (`.mp4`)** | **AI Pod Especializado** | `POD_MULTIMEDIA_WHISPER` | Extracción de audio + transcripción con timestamps. |
| **Google Drive (GDocs)** | **AI Pod Especializado** | `POD_GDRIVE_SYNC` | Conector OAuth2 con la API REST de Google Workspace. |
