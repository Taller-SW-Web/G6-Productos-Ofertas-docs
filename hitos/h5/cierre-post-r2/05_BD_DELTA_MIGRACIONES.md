# Delta y plan de migración BD

## Inventory R10 — `NO_APLICADO`

El archivo candidato Backend `apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.sql` reemplaza solo `ck_inventory_delivery_route` dentro de una transacción con `lock_timeout=3s`, `statement_timeout=30s`, guard de `po_inventory_owner`, validación de la constraint previa y `NOT VALID` + `VALIDATE` antes del intercambio. Preserva tabla, PK/FK, índice, grants, columnas y los tres destinos anteriores. Su rollback aborta si hay entregas Bulk, para impedir pérdida silenciosa de la ruta. No modifica `0001` histórico.

Preflight: ejecutar los SELECT de `BD_PREDEPLOY_CHECKS.sql` y confirmar propietario, definición exacta, filas existentes y ledger. En PostgreSQL 17 descartable, verificar inserción de los cuatro destinos aprobados y rechazo de `g6.price-audit.from.pricing`, transporte distinto o `route_version` distinto; probar segunda aplicación y rollback con/sin fila Bulk. Esta prueba quedó `NOT_RUN` porque Docker Desktop no pudo iniciar (`Docker Desktop is unable to start`).

La reconciliación del ledger `schema_migrations` queda `BLOCKED_DB_ACCESS`: no se deben marcar versiones arbitrariamente ni reejecutar `CREATE` sobre objetos físicos existentes. Por cada servicio, comparar versión, checksum y definición física antes de proponer un asiento compensatorio aprobado por su owner. No se ejecutó DDL/DML en Supabase compartido.
