# Delta y plan de migración BD

## Inventory R10 — `NO_APLICADO`

El archivo candidato Backend `apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.sql` reemplaza solo `ck_inventory_delivery_route` dentro de una transacción con `lock_timeout=3s`, `statement_timeout=30s`, guard de `po_inventory_owner`, validación de la constraint previa y `NOT VALID` + `VALIDATE` antes del intercambio. Preserva tabla, PK/FK, índice, grants, columnas y los tres destinos anteriores. Su rollback aborta si hay entregas Bulk, para impedir pérdida silenciosa de la ruta. No modifica `0001` histórico.

Preflight para Supabase futura: ejecutar los SELECT de `BD_PREDEPLOY_CHECKS.sql` y confirmar propietario, definición exacta, filas existentes y ledger. **PG17 descartable PASS**: se levantó `postgres:17-alpine` sin puerto público, se aplicó 0001 y 0002 dos veces, se insertaron los cuatro destinos aprobados (4 filas), se rechazaron `g6.price-audit.from.pricing`, `route_version=2` y `transport=RABBITMQ`. El rollback con fila Bulk abortó con exit 3 y texto `existen entregas Bulk`; tras eliminar esa fila solo en el contenedor descartable, el rollback pasó y conservó tres filas/rutas. Se detuvo el contenedor. Docker Desktop falló al primer intento de inventario pero arrancó después; no afecta esta prueba final.

La reconciliación del ledger `schema_migrations` queda `BLOCKED_DB_ACCESS`: no se deben marcar versiones arbitrariamente ni reejecutar `CREATE` sobre objetos físicos existentes. Por cada servicio, comparar versión, checksum y definición física antes de proponer un asiento compensatorio aprobado por su owner. No se ejecutó DDL/DML en Supabase compartido.
