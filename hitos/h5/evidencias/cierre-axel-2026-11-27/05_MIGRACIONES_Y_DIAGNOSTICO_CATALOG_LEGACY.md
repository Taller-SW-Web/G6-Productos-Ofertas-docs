# Migraciones Candidatas (PG17 Descartable) y Diagnóstico de Catalog Legacy — 2026-11-27

> **Límite estricto respetado:** **NO** se ejecutó ningún DDL, DML, replay de Outbox heredada ni limpieza de DLQ sobre Supabase compartido (`slzglmtiyrzygpkiuthf`). Todas las pruebas mutantes se ejecutaron exclusivamente en contenedores `postgres:17` descartables locales. Los ledgers y checksums históricos aplicados permanecen intactos.

## 1. Registro de migraciones candidatas ensayadas

| Servicio | Archivo candidato | SHA-256 | Estado en PG17 descartable | Estado en Supabase compartido | Dueño y prerequisito para aplicar |
|---|---|---|---|---|---|
| `inventory-svc` | `apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.sql` | `7ac74f99a0d34c500f731d4769a411a1ab315440fe89336f08b840d09b718575` | **PASS** (pre-migración rechaza Bulk; up×2 idempotente; 4 destinos insertados como rol real `inventory_app`; 3 negativos rechazados) | **`NO_APLICADO`** (`ck_inventory_delivery_route` sigue permitiendo solo 3 destinos; `outbox_delivery` tiene 0 filas) | Taco / Owner BD + autorización expresa Marco Castilla; ejecutar `BD_PREDEPLOY_CHECKS.sql` y backup/PITR previo; conciliar registro en `inventory.schema_migrations` sin inventar versión ni alterar `0001`/`0002` previos |
| `inventory-svc` (rollback) | `apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.rollback.sql` | `22e6a461b166a7fabfdee4236fb024fee8b456e166020af76ea9be630ee402b2` | **PASS** (aborta con `existen entregas Bulk` si hay filas Bulk; tras limpieza en contenedor descartable restaura constraint de 3 destinos preservando las 3 filas restantes) | `NO_APLICADO` (contingencia validada) | Mismo owner BD; nunca ejecutar si existen entregas Bulk sin conciliar |
| `taxonomy-svc` | `apps/taxonomy-svc/migrations/0006_service_bus_outbox_delivery.sql` | `ab68c32c188ddbc6b75a07dfe7c5a6a3123d42711ed8bd344277e56b4f3f7f63` | **PASS** (`run-taxonomy-catalog-postgres.mjs` **23/23 PASS** con R09 + 6 eventos R18; SHA-256 idéntico al documentado en `INVENTARIO_R09_R18.md`) | **`NO_APLICADO`** | López / Owner BD + autorización Marco Castilla; contrastar DDL y checksum contra variantes previas (#247/fork) y ledger real de `taxonomy` antes de fijar orden |
| `pricing-svc` | `apps/pricing-svc/migrations/0003_service_bus_h5_routes_r2.sql` | `9a059889203c302e365ad154b2d4952ee75137eb6cfd397cbf9094856ed73d8c` | **PASS** (`pilot.postgres.e2e-spec.ts` **8/8 PASS** y `r03-r14-r16-r17.postgres.e2e-spec.ts` **3/3 PASS**) | Verificar presencia/checksum vía SELECT antes de habilitar R03/R14/R15/R17 | Vera / Owner BD |

## 2. Conciliación de `inventory.outbox_delivery.ck_inventory_delivery_route` (R10)

- En el entorno compartido (`slzglmtiyrzygpkiuthf`), la auditoría read-only confirmó:
  - Propietario del esquema y tabla: `po_inventory_owner`.
  - Rol runtime: `inventory_app` con `USAGE`, `SELECT`, `INSERT`, `UPDATE`.
  - Constraint física actual: `ck_inventory_delivery_route` permite solo `g6.catalog.from.inventory`, `g6.combos.from.inventory`, `g6.promotions.from.inventory` (falta `g6.bulk.from.inventory`).
  - Filas actuales en `inventory.outbox_delivery`: `0`.
  - Ledger `inventory.schema_migrations`: solo `0001_create_inventory.sql` y `0002_order_id_operaciones_disponibilidad.sql` (no alterar).
- La migración `0002_allow_bulk_r10_delivery.sql` usa `lock_timeout = '3s'`, `statement_timeout = '30s'`, verifica propietario `po_inventory_owner`, añade la nueva restricción `NOT VALID` + `VALIDATE CONSTRAINT` y realiza el intercambio sin reescribir `0001_outbox_delivery.sql`.
- El rollback condicionado (`0002_allow_bulk_r10_delivery.rollback.sql`) bloquea explícitamente la reversión si ya existen filas para `g6.bulk.from.inventory`, evitando pérdida silenciosa de ruta o corrupción del estado de lotes Bulk.

## 3. Diagnóstico y propuesta de conciliación de las 4 filas históricas pendientes en `catalog.outbox`

### 3.1 Hechos verificados (solo lectura)
- En `slzglmtiyrzygpkiuthf`, `catalog.outbox` registra **4 filas** con `published_at IS NULL` y `delivery_transport = 'RABBITMQ'`:
  - 2 eventos `inventory.sku.initialization.requested`
  - 2 eventos `pricing.product.initialization.requested`
- **Aislamiento verificado en código H5:** `relayCatalogDelivery` lee exclusivamente `catalog.outbox_delivery`, tabla que únicamente recibe inserciones cuando `catalog.messaging_provider = 'AZURE_SERVICE_BUS'`. Por tanto, **esas 4 filas históricas de RabbitMQ no bloquean, no duplican ni interfieren con el transporte Service Bus Basic de H5**.

### 3.2 Diagnóstico por evento (SQL solo lectura para ejecutar con rol autorizado)
Antes de cualquier acción correctiva, el owner de Catalog (`Poma`) junto con los owners de Inventory (`Taco`) y Pricing (`Vera`) deben ejecutar el siguiente `SELECT` en transacción `READ ONLY` para clasificar cada una de las 4 filas sin mutar el ledger ni la tabla:

```sql
BEGIN READ ONLY;

-- 1. Inspección de las 4 filas pendientes heredadas en catalog.outbox
SELECT
  o.id AS message_id,
  o.event_name,
  o.aggregate_id,
  o.delivery_transport,
  o.created_at,
  o.published_at,
  o.payload->>'sku' AS sku,
  o.payload->>'productId' AS product_id,
  o.payload->>'variantId' AS variant_id
FROM catalog.outbox o
WHERE o.published_at IS NULL
  AND o.delivery_transport = 'RABBITMQ'
ORDER BY o.created_at ASC;

-- 2. Contraste con estado actual en catalog.activation_checks
SELECT
  o.id AS message_id,
  o.event_name,
  o.aggregate_id,
  ac.inventory_ready,
  ac.pricing_ready,
  ac.updated_at
FROM catalog.outbox o
LEFT JOIN catalog.activation_checks ac
  ON ac.product_id::text = coalesce(o.payload->>'productId', o.aggregate_id::text)
WHERE o.published_at IS NULL
  AND o.delivery_transport = 'RABBITMQ';

-- 3. Contraste con estado efectivo en Inventory (para las 2 filas inventory.sku.initialization.requested)
SELECT
  o.id AS message_id,
  o.payload->>'sku' AS sku,
  si.sku_id AS inventory_sku_present,
  sb.stock_actual,
  (SELECT count(*) FROM inventory.inbox ii WHERE ii.message_id = o.id) AS inbox_hits
FROM catalog.outbox o
LEFT JOIN inventory.sku_identity si ON si.sku = o.payload->>'sku'
LEFT JOIN inventory.stock_balance sb ON sb.sku_id = si.sku_id
WHERE o.published_at IS NULL
  AND o.delivery_transport = 'RABBITMQ'
  AND o.event_name = 'inventory.sku.initialization.requested';

-- 4. Contraste con estado efectivo en Pricing (para las 2 filas pricing.product.initialization.requested)
SELECT
  o.id AS message_id,
  o.payload->>'sku' AS sku,
  count(pr.id) AS pricing_rows,
  (SELECT count(*) FROM pricing.inbox pi WHERE pi.message_id = o.id) AS inbox_hits
FROM catalog.outbox o
LEFT JOIN pricing.prices pr ON pr.sku = o.payload->>'sku'
WHERE o.published_at IS NULL
  AND o.delivery_transport = 'RABBITMQ'
  AND o.event_name = 'pricing.product.initialization.requested'
GROUP BY o.id, o.payload->>'sku';

COMMIT;
```

### 3.3 Matriz de decisión para conciliación (sin borrado ni replay ciego)
1. **Caso A — Efecto ya materializado en destino (`inventory_sku_present IS NOT NULL` / `pricing_rows > 0` o `activation_checks` ya `true`):**
   - El evento es un residuo histórico ya cumplido por vía posterior o administrativa.
   - **Acción propuesta:** documentar el `message_id` como conciliado histéricamente y **no reenviar**; solo si el owner aprueba una actualización controlada de auditoría, registrar marca explícita sin `DELETE` ni alteración de migraciones.
2. **Caso B — Producto/SKU dado de baja o prueba sintética obsoleta:**
   - **Acción propuesta:** confirmar con Poma que no corresponde a SKU activo comercial y mantener aislado sin replay.
3. **Caso C — SKU activo aún sin inicializar en Inventory o Pricing (`activation_checks` pendiente y destino ausente):**
   - **Acción propuesta:** **no** reactivar RabbitMQ ni reenviar ciegamente filas antiguas. Utilizar el endpoint contractual administrativo de reintento de preparación (`POST /api/v1/productos/{productoId}/reintentar-preparacion` o `/variantes/{variantId}/reintentar-preparacion`) una vez desplegado H5 con Service Bus Basic activo, de modo que genere un nuevo `message_id` trazable bajo `AZURE_SERVICE_BUS` con `outbox_delivery`.
