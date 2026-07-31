# 📜 SPEC: Cifrado At-Rest de Embeddings en Qdrant (AES-256-GCM)
**ID:** SPEC-CORE-34  
**Épica Relacionada:** Security & Compliance, Vector Store Security & Encryption At-Rest  
**Issue Relacionado:** `#1` ([`[FEAT] Cifrado At-Rest de Embeddings en Qdrant (AES-256 GCM)`](https://github.com/onlyone-ai-pods/aipods-docs/issues/1))  
**Estado:** APPROVED / SPEC-DRIVEN  

---

## 1. Visión y Objetivos

Esta especificación establece el mecanismo de **Cifrado At-Rest de Embeddings Vectoriales** utilizando el algoritmo **AES-256-GCM** para la capa de almacenamiento RAG en Qdrant dentro de la plataforma **Be OnlyOne / AI Pods**.

Protege los vectores numéricos flotantes (`[]float32`) generados por los modelos de IA antes de que sean persistidos en disco o memoria en la base de datos Qdrant, garantizando que un volcado no autorizado del almacenamiento impida la reconstrucción del espacio semántico o la inferencia del texto original.

---

## 2. Arquitectura de Cifrado At-Rest

```mermaid
graph TD
    TextQuery[Texto / Documento RAG] --> Embedder[Model Embeddings Float32]
    Embedder -->|Vector float32[]| Middleware[🔐 EncryptedVectorStore internal/rag]
    
    subgraph Capa de Cifrado Simétrico AES-256-GCM
        Middleware -->|1. Float32ToBytes| RawBytes[Buffer Binario 1536d]
        RawBytes -->|2. AES-256-GCM Encrypt| CipherPayload[Ciphertext + Nonce 12B]
    end

    CipherPayload -->|Persistencia Cifrada| QdrantDB[(🗄️ Qdrant Vector DB)]
    
    QdrantDB -->|Retrieval Cifrado| DecryptMiddleware[🔓 DecryptVectorFloat32]
    DecryptMiddleware -->|Vector Restaurado| RAGContext[Consolidador Contextual RAG]
```

---

## 3. Especificación Criptográfica en Go

- **Algoritmo**: `AES-256-GCM` (`crypto/cipher`).
- **Largo de Clave**: 32 bytes (256 bits) provista via `NativeVaultManager`.
- **Largo de Nonce**: 12 bytes aleatorios por vector (`crypto/rand`).
- **Conversión de Punto Flotante**: `IEEE 754 BigEndian uint32` -> `[]byte`.

---

## 4. Escenarios BDD

```gherkin
Feature: Cifrado At-Rest de Embeddings en Qdrant (AES-256-GCM)

  Scenario: Cifrado y Descifrado Transparente de un Vector de 1536 Dimensiones
    Given un vector de embeddings `[]float32` de 1536 dimensiones generado por el pipeline RAG
    When el middleware `EncryptedVectorStore` cifra el vector utilizando la clave AES-256 de 32 bytes
    Then se obtiene un payload binario cifrado que no revela los valores originales
    And al descifrar el payload se obtiene exactamente el mismo vector `[]float32` sin pérdida de precisión
```
