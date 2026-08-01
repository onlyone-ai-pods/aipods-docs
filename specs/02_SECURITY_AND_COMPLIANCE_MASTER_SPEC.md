# 📜 SPEC MAESTRA 02: Seguridad, Criptografía SGSI & Cumplimiento Normativo
**ID Épica:** EPIC-SECURITY-COMPLIANCE  
**Estándar de Seguridad:** ISO 27001, SOC 2 Type II, ISO 9001 & NIST SP 800-53  
**Estado:** CONSOLIDATED MASTER SPECIFICATION  

---

## 🏛️ Índice de Especificaciones Consolidadas en esta Épica

- [`SPEC-CORE-16`: Marco de Cumplimiento ISO 9001, SOC 2 y ISO 27001](#1-spec-core-16-marco-de-cumplimiento-iso-9001-soc-2-y-iso-27001)
- [`SPEC-CORE-27`: Native Vault — Cifrado AES-256-GCM y Purga RAM 15s](#2-spec-core-27-native-vault--cifrado-aes-256-gcm-y-purga-ram-15s)
- [`SPEC-CORE-32`: Generador de Expedientes Auditoría ISO 9001 & SOC 2 SHA-256](#3-spec-core-32-generador-de-expedientes-auditoría-iso-9001--soc-2-sha-256)
- [`SPEC-CORE-34`: Qdrant Vector Store — Cifrado At-Rest AES-256](#4-spec-core-34-qdrant-vector-store--cifrado-at-rest-aes-256)
- [`SPEC-CORE-38`: Trazabilidad de IP Origen y User-Agent de Administrador](#5-spec-core-38-trazabilidad-de-ip-origen-y-user-agent-de-administrador)

---

## 1. SPEC-CORE-16: Marco de Cumplimiento ISO 9001, SOC 2 y ISO 27001

Salaguardas técnicas SGSI: Autenticación OAuth2 RS256, separación Zero-Trust de dominios y almacenamiento WORM de auditoría inmutable durante 365 días.

---

## 2. SPEC-CORE-27: Native Vault — Cifrado AES-256-GCM y Purga RAM 15s

Bóveda de claves criptográficas nativa en Go (`internal/vault/vault.go`). Utiliza cifrado simétrico AES-256-GCM con sal y nonce aleatorios de 12 bytes. Implementa purga de RAM a los 15 segundos para evitar ataques de volcado de memoria.

---

## 3. SPEC-CORE-32: Generador de Expedientes Auditoría ISO 9001 & SOC 2 SHA-256

Generador del dossier oficial de auditoría externa en Go (`internal/audit/dossier_generator.go`). Recopila escaneos AST `gosec`, logs IAM y métricas de Prometheus, estampando la firma criptográfica SHA-256 Digest del documento.

---

## 4. SPEC-CORE-34: Qdrant Vector Store — Cifrado At-Rest AES-256

Middleware de cifrado en reposo para vectores y embeddings (`internal/rag/encrypted_vector_store.go`). Convierte arreglos `[]float32` a IEEE 754 y los cifra con AES-256-GCM antes de persistir en Qdrant.

---

## 5. SPEC-CORE-38: Trazabilidad de IP Origen y User-Agent de Administrador

Módulo de auditoría de sesión de administradores (`internal/audit/admin_session_logger.go`). Captura la `ClientIP` real, el `User-Agent` del dispositivo/navegador y genera la firma SHA-256 Digest en el IAM Audit Trail (ISO 27001 A.12.4.1).
