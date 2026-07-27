---
name: 🐛 2. Bug Report / Reporte de Error
about: Reportar un error, fallo de API o problema de seguridad en la plataforma.
title: '[BUG] <Descripción corta del error>'
labels: 'bug'
assignees: ''
---

### 🐛 1. Descripción del Comportamiento Inesperado
Explica qué está fallando y cómo se diferencia del comportamiento esperado según las especificaciones SDD.

### 🔄 2. Pasos para Reproducir el Error
1. Iniciar el stack local con `/home/martin/server/start_local_stack.sh`
2. Enviar petición HTTP POST a `http://localhost:8080/api/v1/...` con payload:
   ```json
   { "example": "data" }
   ```
3. Observar el error devuelto o el pánico en los logs.

### 📋 3. Logs y Mensaje de Error Exacto
```text
[GIN-debug] 500 Internal Server Error: ...
```

### 🎯 4. Criterios de Aceptación para la Corrección (Gherkin BDD)
```gherkin
Scenario: Corrección del Error
  Given la condición previa que desencadenaba el error
  When se ejecuta la petición corregida
  Then el sistema debe responder HTTP 200 OK
  And no lanzar ninguna excepción en los logs
```
