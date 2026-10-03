# Validación del procedimiento — #49

Fecha: 2026-10-02. Resultado local: PASS. Motor real: PostgreSQL 17.11 (Debian), imagen `postgres:17`, digest `sha256:d74eeac9a635390a49bc21bd49fccd973de707e2a53a76ac49b552b8712ec46f`. Supabase remoto: NO EJECUTADO, acceso no disponible.

| Comprobación | Resultado |
|---|---|
| Bootstrap desde cero y repetición | PASS; ocho schemas con sus roles NOLOGIN |
| Aplicar 0001 y repetir en cada uno de los ocho schemas | PASS; un registro por schema, sin duplicación |
| Owner de cada schema coincide con su contexto | PASS |
| Intentar lectura cruzada desde cada owner hacia los otros siete | PASS; 56 accesos rechazados |
| Editar migración aplicada | PASS; checksum distinto detiene ejecución |
| Migración con CREATE TABLE seguido de división por cero | PASS; tabla y registro de versión no persistieron |
| Dos ejecutores simultáneos sobre nueva versión | PASS; advisory lock serializa, un índice y una versión |
| Eliminar archivo de una versión aplicada del checkout de prueba | PASS; historial ausente rechazado |
| Eliminar versión inferior del ledger conservando otra superior | PASS; hueco rechazado |

Solo se usaron tablas `deployment_fixture` en una base local desechable; no constituyen modelo físico de ningún contexto. El modelo de promotions y su despliegue pertenecen al #53, aplazado por Axel.

La reproducción consiste en seguir §5 del [procedimiento](README.md) con fixtures transaccionales: una tabla por schema; segunda versión crea un índice; variante inválida crea una tabla y ejecuta `SELECT 1/0`. Ejecutar primero y repetir `migrate.py`, consultar el ledger y comprobar ownership; probar accesos cruzados con `SET ROLE po_<schema>_owner`. Los cambios de checkout/ledger para casos negativos se realizan únicamente sobre copias y base desechable. No probar manipulación del historial en un proyecto compartido.

La evidencia valida el mecanismo PostgreSQL; la conexión TLS, los permisos efectivos del proyecto Supabase y las migraciones reales de cada owner se validan al disponer del proyecto. No se modificaron workflows ni credenciales.
