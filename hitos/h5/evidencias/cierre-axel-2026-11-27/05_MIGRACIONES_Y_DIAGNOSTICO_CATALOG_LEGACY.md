# Reconciliación PostgreSQL/Supabase, Migraciones PG17 y Diagnóstico Catalog Legacy — 2026-11-27

> **Límite estricto respetado:** **NO** se ejecutó DDL, DML, replay de Outbox heredada ni limpieza de DLQ sobre Supabase compartido (`slzglmtiyrzygpkiuthf`) porque la autorización expresa escrita de Marco Castilla referida por la auditoría no fue adjuntada al encargo. Toda verificación mutante se ejecutó exclusivamente en contenedores `postgres:17` descartables locales. Los ledgers y checksums históricos permanecen intactos.

## 1. Comparación de historiales de migraciones (`supabase_migrations` vs ledgers por servicio)

| Dominio | Ledger global (`supabase_migrations.schema_migrations`) | Ledger del servicio (`<schema>.schema_migrations`) | Artefacto versionado en candidato `#307` | Estado real reconciliado |
|---|---|---|---|---|
| **Inventory (R02/R10)** | Sin entrada R10 | `inventory.schema_migrations`: `0001_create_inventory.sql`, `0002_order_id_operaciones_disponibilidad.sql` (no alterar) | `apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.sql` (`SHA256 7ac74f99...`) + rollback (`22e6a461...`) | **`PENDIENTE_APLICACION_AUTORIZADA`**: `ck_inventory_delivery_route` en Supabase solo admite 3 destinos (R11/R12/R13); `inventory.outbox_delivery` tiene 0 filas y owner `po_inventory_owner`. Al aplicar bajo aprobación, registrar identificador explícito en `supabase_migrations` (ej. `g6_h5_inventory_allow_bulk_r10_delivery_YYYYMMDD`) sin colisionar con la numeración histórica `0002` de `inventory.schema_migrations` |
| **Taxonomy (R09/R18)** | Registra `g6_h5_taxonomy_outbox_delivery_20261125` y `g6_h5_taxonomy_outbox_restrict_runtime_acl_20261125` | `taxonomy.schema_migrations`: llega hasta `0005` | `apps/taxonomy-svc/migrations-candidate/h5/0001_outbox_delivery.sql` (`SHA256 fc838e56...`) vs `apps/taxonomy-svc/migrations/0006_service_bus_outbox_delivery.sql` (`SHA256 ab68c32c...`) | **NO es «0006 no aplicada» — ESQUEMA H5 YA EXISTE Y ES FUNCIONALMENTE EQUIVALENTE** (ver sección 2). **PROHIBIDO ejecutar `0006` íntegra** sobre los objetos existentes (su propio `$guard$` aborta con `Taxonomy H5 has an existing or alternate writer`) |
| **Pricing (R14–R17)** | Registra `g6_h5_pricing_0003_service_bus_routes_r2` | Verificar vía SELECT en preflight | `apps/pricing-svc/migrations/0003_service_bus_h5_routes_r2.sql` (`SHA256 9a059889...`) | **COMPATIBLE CON CANDIDATO**: amplía `ck_delivery_route` a los 4 destinos (`g6.price-audit.from.pricing`, `g6.promotions.from.pricing`, `g6.catalog.from.pricing`, `g6.bulk.from.pricing`, `route_version=1`, `transport='AZURE_SERVICE_BUS'`). Conservar migración aplicada sin reejecutar |

---

## 2. Reconciliación detallada de Taxonomy (`R09`/`R18`) — Objetos observados vs `0006_service_bus_outbox_delivery.sql`

### 2.1 Comparación objeto por objeto

| Objeto / Propiedad | Estado observado en Supabase (`g6_h5_taxonomy_outbox_delivery_20261125` + `...restrict_runtime_acl_20261125`, base `0001_outbox_delivery.sql`) | Candidato `0006_service_bus_outbox_delivery.sql` (`SHA256 ab68c32c...`) | Equivalencia y diferencia exacta |
|---|---|---|---|
| `taxonomy.outbox.delivery_transport` | `text NOT NULL`, default `COALESCE(NULLIF(current_setting('g6.taxonomy_messaging', true), ''), 'RABBITMQ')`, `CHECK IN ('RABBITMQ', 'AZURE_SERVICE_BUS')` | Nombra explícitamente `taxonomy_outbox_delivery_transport_valid` y añade `taxonomy_outbox_h5_valid_event` (`CHECK` a nivel tabla) | **Equivalente en efecto:** en el esquema observado, eventos inválidos con `AZURE_SERVICE_BUS` igual son rechazados con `ROLLBACK` por `fn_enqueue_catalog_h5()` |
| `taxonomy.outbox_delivery` | PK `(message_id, destination)`, FK a `taxonomy.outbox(message_id) ON DELETE RESTRICT`, `destination = 'g6.catalog.from.taxonomy'`, `route_version = 1`, `attempts >= 0`, `(lease_token IS NULL) = (lease_until IS NULL)` | **100% idéntica** | **Equivalencia total** |
| `ix_taxonomy_delivery_pending` | Índice parcial `(next_attempt_at, created_at) WHERE sent_at IS NULL` | **100% idéntico** | **Equivalencia total** |
| `taxonomy.fn_enqueue_catalog_h5()` | `RETURNS trigger LANGUAGE plpgsql SET search_path = pg_catalog`, admite exactamente los **6 eventos R18** (`taxonomy.category.updated`, `taxonomy.product-type-schema.changed`, `taxonomy.characteristic-value.updated`, `taxonomy.master.deactivation.check.requested`, `taxonomy.master.deactivated`, `taxonomy.master.deactivation.rejected`) y lanza `RAISE EXCEPTION 'Unsupported Taxonomy H5 route'` ante cualquier otro evento | Misma lógica y **exactamente los mismos 6 eventos R18**; agrega `SECURITY INVOKER` explícito (default en PG) y `GRANT EXECUTE ... TO taxonomy_app` | **Equivalencia funcional verificada en PG17 descartable** |
| `trg_taxonomy_catalog_h5` | `AFTER INSERT ON taxonomy.outbox FOR EACH ROW WHEN (NEW.delivery_transport = 'AZURE_SERVICE_BUS')` habilitado | Añade `AND NEW.event_name IN (<6 eventos R18>)` en `WHEN` | **Equivalente en efecto y convivencia H4/H5:** filas `RABBITMQ` nunca disparan el trigger; cualquier evento inválido con `AZURE_SERVICE_BUS` aborta en la función |
| Propietario y ACL `taxonomy_app` | Propietario `po_taxonomy_owner`; `REVOKE ALL FROM PUBLIC`; `SELECT, INSERT` en `taxonomy.outbox_delivery` y `UPDATE (next_attempt_at, attempts, lease_token, lease_until, sent_at, last_error)` por columna | Mismos privilegios de tabla/columna + `GRANT USAGE ON SCHEMA taxonomy` + `GRANT EXECUTE` en función | **Verificado en PG17 descartable:** bajo `0001_outbox_delivery.sql` (sin `GRANT EXECUTE`), `taxonomy_app` inserta correctamente los **6 eventos R18** (`deliveryCount=6`) porque PostgreSQL no exige privilegio `EXECUTE` directo al llamador para disparar triggers `AFTER INSERT` |

### 2.2 Prueba de reproducción en PostgreSQL 17 descartable (`verify-taxonomy-observed-ddl.mjs`)
Reproduciendo `0001_create_taxonomy.sql` + `0002`..`0005` + `0001_outbox_delivery.sql` (`SHA256 fc838e563fbd8594bbb04ad9b0afaebbe41b0e9315fc73762561968a4caf0035`) como `po_taxonomy_owner`:
- Intentar aplicar `0006_service_bus_outbox_delivery.sql` encima **aborta limpiamente en el `$guard$`** (`ERROR: Taxonomy H5 has an existing or alternate writer; reconcile before applying`), confirmando que **queda excluida la ejecución íntegra de `0006`**.
- Insertando como rol runtime `taxonomy_app` los **6 eventos R18** con `delivery_transport='AZURE_SERVICE_BUS'`: **6/6 PASS** (`taxonomy.outbox_delivery` = 6 filas).
- Insertando un evento H4 con `delivery_transport='RABBITMQ'`: **0 filas** agregadas en `taxonomy.outbox_delivery` (convivencia H4/H5 intacta).
- Insertando un evento no soportado con `delivery_transport='AZURE_SERVICE_BUS'`: **rechazado y revertido** (`Unsupported Taxonomy H5 route`, 0 cambios parciales).
- **Tratamiento aprobado del ledger:** NO registrar `0006` en `taxonomy.schema_migrations` sin haber ejecutado su SQL ni re-ejecutar `0006`; documentar la equivalencia funcional con `g6_h5_taxonomy_outbox_delivery_20261125` + `g6_h5_taxonomy_outbox_restrict_runtime_acl_20261125`. Si una introspección `SELECT` adicional en Supabase detectara alguna brecha real de constraint/ACL, emitir únicamente una migración diferencial incremental y reversible en transacción única (`SET LOCAL lock_timeout='5s'`).

---

## 3. Inventory R02/R10 (`0002_allow_bulk_r10_delivery.sql` y rollback)

- **SHA-256 up:** `7ac74f99a0d34c500f731d4769a411a1ab315440fe89336f08b840d09b718575` (`apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.sql`).
- **SHA-256 rollback:** `22e6a461b166a7fabfdee4236fb024fee8b456e166020af76ea9be630ee402b2` (`apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.rollback.sql`).
- **Verificación PG17 descartable (`PASS`):** pre-migración rechaza `g6.bulk.from.inventory`; aplicación ×2 idempotente como `po_inventory_owner`; inserción de los 4 destinos (R10/R11/R12/R13) como rol runtime `inventory_app`; 3 negativos rechazados (`g6.price-audit.from.pricing`, `route_version=2`, `transport='RABBITMQ'`); rollback aborta con exit 3 (`existen entregas Bulk`) si hay fila Bulk y revierte limpio tras limpieza descartable preservando las 3 rutas previas.
- **Prerrequisito faltante para aplicar en Supabase `slzglmtiyrzygpkiuthf`:** confirmación expresa escrita de Marco Castilla (proyecto/alcance/ventana/PITR/ejecutor `po_inventory_owner`), ya que la auditoría no fue adjuntada al prompt.

---

## 4. Diagnóstico de las 4 filas históricas pendientes en `catalog.outbox` (`RABBITMQ`)

### 4.1 Hechos verificados (solo lectura)
- Existen **4 filas** en `catalog.outbox` con `published_at IS NULL` y `delivery_transport = 'RABBITMQ'`:
  - **2 filas** `inventory.sku.initialization.requested`
  - **2 filas** `pricing.product.initialization.requested`
- **Aislamiento H5 confirmado:** `relayCatalogDelivery` lee exclusivamente `catalog.outbox_delivery` (alimentada solo bajo `AZURE_SERVICE_BUS`), por lo que las 4 filas heredadas no bloquean ni interfieren con H5.
- **Límite respetado:** sin borrado, sin replay automático y sin alterar ledgers ni registros originales.

### 4.2 Consulta `READ ONLY` para vincular mensaje, correlación y efecto downstream por fila

```sql
BEGIN READ ONLY;

SELECT
  o.id AS message_id,
  o.correlation_id,
  o.event_name,
  o.aggregate_id,
  o.delivery_transport,
  o.created_at,
  o.payload->>'sku' AS sku,
  o.payload->>'productId' AS product_id,
  ac.inventory_ready,
  ac.pricing_ready,
  (SELECT count(*) FROM inventory.sku_identity si WHERE si.sku = o.payload->>'sku') AS inv_sku_exists,
  (SELECT count(*) FROM inventory.inbox ii WHERE ii.message_id = o.id) AS inv_inbox_hits,
  (SELECT count(*) FROM pricing.prices pr WHERE pr.sku = o.payload->>'sku') AS pricing_rows,
  (SELECT count(*) FROM pricing.inbox pi WHERE pi.message_id = o.id) AS pricing_inbox_hits
FROM catalog.outbox o
LEFT JOIN catalog.activation_checks ac
  ON ac.product_id::text = coalesce(o.payload->>'productId', o.aggregate_id::text)
WHERE o.published_at IS NULL
  AND o.delivery_transport = 'RABBITMQ'
ORDER BY o.created_at ASC;

COMMIT;
```

### 4.3 Matriz de decisión propuesta (sujeta a autorización específica tras ejecutar el SELECT)
- **Efecto downstream demostrado (`inv_sku_exists > 0` / `pricing_rows > 0` o `activation_checks = true`):** residuo histórico ya cumplido; conservar original y **no reenviar**.
- **Producto/SKU inactivo o sintético obsoleto:** confirmar con Poma y mantener aislado sin replay.
- **Efecto downstream indeterminado o ausente en SKU activo:** **no** reactivar RabbitMQ; una vez desplegado H5, ejecutar `POST /api/v1/productos/{productoId}/reintentar-preparacion` (o `/variantes/{variantId}/reintentar-preparacion`) bajo autorización de Poma para emitir un nuevo `message_id` auditable en `AZURE_SERVICE_BUS`.
