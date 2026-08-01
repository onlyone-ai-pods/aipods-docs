# 📁 Directorio de Especificaciones Activas Temporales (`specs/active/`)

Este directorio alberga las **Especificaciones Activas Temporales (`IN_PROGRESS`)** que están en desarrollo para un Issue o Release específico.

---

## 🔄 Reglas del Ciclo de Vida (Protocolo SDD 3-Tier):

1. **Creación**: Cuando se inicia una nueva funcionalidad, la spec se redacta en esta carpeta:
   `specs/active/XX_nombre_feature_spec.md` (Estado: `IN_PROGRESS`).

2. **Desarrollo & Tests**: El equipo desarrolla el código en Go / React y ejecuta la suite de auditoría `deploy_stack.sh`.

3. **Consolidación & Cierre (`CLOSED`)**: Una vez que el Issue se cierra y se publica el Release Tag en GitHub:
   - El contenido de la spec se **appendea como sub-capítulo en el Documento Maestro por Épica** correspondiente (`01_CORE`, `02_SECURITY`, `03_ADMIN_HUB` o `04_CUSTOMER_PORTAL`).
   - Se actualiza el [SPEC_MASTER_INDEX.md](../SPEC_MASTER_INDEX.md).
   - Se elimina el archivo borrador temporal de `specs/active/`.
