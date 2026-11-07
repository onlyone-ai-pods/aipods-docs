# SPEC-CORE-68: Estrategia RAG Dual Configurable por Tenant

**Estado:** DRAFT (IN_PROGRESS)  
**Épica:** 01 Core Architecture & Engine  
**Issue:** [#38](https://github.com/onlyone-ai-pods/aipods-docs/issues/38)  
**Repos afectados:** `aipods-core-engine`, `deploy`, `aipods-docs`

---

## 1. Motivación y Contexto

Actualmente, el motor RAG depende de un contenedor local de Ollama corriendo el modelo `bge-m3` en el VPS de Oracle Cloud. Esto presenta los siguientes problemas operativos:
1. **Consumo de Recursos en VPS**: Ocupa entre 2.5 GB y 3.5 GB de RAM continua y somete a la CPU a sobrecarga durante la vectorización de PDFs extensos.
2. **Inconsistencia de Privacidad**: Dado que las respuestas finales son sintetizadas por Claude (Anthropic), los fragmentos ya viajan a un servicio cloud.
3. **Brecha Semántica**: La búsqueda por palabras clave directa falla cuando el usuario usa lenguaje informal (*"cómo cobro laburo afuera"*) y la documentación utiliza terminología formal de ARCA (*"Comprobantes clase E - Exportación de servicios"*).

---

## 2. Requisitos de la Especificación

| ID | Requisito | Verificación |
|---|---|---|
| `SPEC-CORE-68.R1` | **Query Expansion con Claude (Alternativa 2 - Default)**: Previo a la búsqueda de documentos, se invoca un prompt rápido a Claude que traduce la consulta informal a términos técnicos, palabras clave y números de resolución de ARCA. | Unit test con mock de LLM verificando la expansión léxica. |
| `SPEC-CORE-68.R2` | **Embeddings Livianos vía API SaaS (Alternativa 1)**: Implementación de `VoyageEmbedder` (`voyage-3-lite`, 1024 dims) y `OpenAIEmbedder` (`text-embedding-3-small`) implementando la interfaz `embed.Embedder`. | Tests unitarios con clientes HTTP mock. |
| `SPEC-CORE-68.R3` | **Configuración RAG por Tenant**: La entidad Tenant y el router permiten seleccionar la estrategia: `query_expansion` (por defecto) o `external_embeddings`. | Test de router verificando el despacho según el `tenant_id`. |
| `SPEC-CORE-68.R4` | **Fallback de Resiliencia**: Si la API externa de embeddings falla, el router degrada automáticamente a Query Expansion + búsqueda léxica sin interrumpir la experiencia de usuario. | Test de simulación de fallo de red en `external_embeddings`. |
| `SPEC-CORE-68.R5` | **Opcionalidad de Ollama**: El contenedor `ollama` en `docker-compose.oracle.yml` se desactiva por defecto o se aisla en un perfil opcional, liberando RAM en el VPS. | Verificación de arranque sin servicio `ollama`. |

---

## 3. Plan de Implementación

1. Crear módulo `internal/llm/expander.go` con prompt especializado en taxonomía fiscal argentina (ARCA/AFIP).
2. Crear adaptadores en `internal/embed/voyage.go` y `internal/embed/openai.go`.
3. Agregar campo `RAGStrategy` en la resolución de Tenant y condicional en `smartRouter.RouteAndExecute`.
4. Tests de integración y ajuste de variables en `.env.oracle.example`.
