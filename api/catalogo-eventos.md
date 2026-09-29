# Catálogo de eventos — Productos y Ofertas

**Versión del catálogo:** `0.2.1-p0`  
**Contrato canónico:** `asyncapi/asyncapi.yaml` — AsyncAPI `3.0.0`, contrato `0.2.1-p0`  
**Fecha:** 2026-09-28  
**Fuente funcional:** SPEC-001 a SPEC-016.

> Este documento complementa el contrato asíncrono de eventos y mensajería. En caso de discrepancia de schemas o versiones, prevalece `asyncapi/asyncapi.yaml`.

---

## 1. Convenciones

- Entrega: **at-least-once**; los consumidores deben deduplicar por `message_id`.
- Publicación: patrón **transactional outbox** en el productor.
- Consumo: **inbox/deduplicación** antes de efectos de negocio no idempotentes.
- `correlation_id` enlaza un flujo extremo a extremo; no sustituye la identidad idempotente de la operación.
- `202 Accepted` en HTTP representa admisión; el resultado final llega por los contratos asíncronos cuando corresponda.
- Un `event` describe un hecho ya confirmado; no se interpreta como comando.

### Envelope canónico

```text
message_id
kind
name
schema_version
operation_id
correlation_id
causation_id
occurred_at
producer
actor
data
```

`schema_version` del envelope versiona el **payload contractual del mensaje**. En `taxonomy.product-type-schema.changed`, `data.schema_version` es una versión distinta: representa la **versión de negocio del esquema de características del tipo de producto**.

---

## 2. Inventario canónico de mensajes

| Mensaje | Tipo | Productor | Consumidores | Estado |
|---|---|---|---|---|
| `taxonomy.category.updated` | event | `taxonomy-svc` | catalog-svc, api-gateway/bff, canales autorizados | `stable` |
| `taxonomy.product-type-schema.changed` | event | `taxonomy-svc` | catalog-svc | `internal-provisional` |
| `taxonomy.characteristic-value.updated` | event | `taxonomy-svc` | catalog-svc | `internal-provisional` |
| `catalog.product.deactivated` | event | `catalog-svc` | promotions-svc, combos-svc, api-gateway/bff | `stable` |
| `catalog.sku.deactivated` | event | `catalog-svc` | inventory-svc, pricing-svc, promotions-svc, combos-svc | `stable` |
| `pricing.price.changed` | event | `pricing-svc` | price-audit-svc, promotions-svc, api-gateway/bff | `stable` |
| `inventory.stock.changed` | event | `inventory-svc` | combos-svc, promotions-svc, api-gateway/bff | `stable` |
| `inventory.stock.adjusted` | event | `inventory-svc` | bulk-svc, api-gateway/bff | `stable` |
| `inventory.reservation.created` | event | `inventory-svc` | modulo-ventas, api-gateway/bff | `provisional` |
| `inventory.reservation.consumed` | event | `inventory-svc` | modulo-ventas, api-gateway/bff | `provisional` |
| `inventory.reservation.released` | event | `inventory-svc` | modulo-ventas, api-gateway/bff | `provisional` |
| `inventory.reservation.expired` | event | `inventory-svc` | modulo-ventas, api-gateway/bff | `provisional` |
| `inventory.consumption.completed` | result | `inventory-svc` | modulo-ventas | `provisional` |
| `inventory.consumption.rejected` | result | `inventory-svc` | modulo-ventas | `provisional` |
| `taxonomy.master.deactivation.check.requested` | command | `taxonomy-svc` | catalog-svc | `internal-provisional` |
| `catalog.master.deactivation.checked` | result | `catalog-svc` | taxonomy-svc | `internal-provisional` |
| `taxonomy.master.deactivated` | event | `taxonomy-svc` | catalog-svc, api-gateway/bff | `internal-provisional` |
| `taxonomy.master.deactivation.rejected` | result | `taxonomy-svc` | catalog-svc | `internal-provisional` |
| `catalog.bulk.upsert.requested` | command | `bulk-svc` | catalog-svc | `internal-provisional` |
| `catalog.bulk.upsert.completed` | result | `catalog-svc` | bulk-svc | `internal-provisional` |
| `catalog.bulk.upsert.rejected` | result | `catalog-svc` | bulk-svc | `internal-provisional` |
| `pricing.bulk.price.apply.requested` | command | `bulk-svc` | pricing-svc | `internal-provisional` |
| `pricing.bulk.price.apply.completed` | result | `pricing-svc` | bulk-svc | `internal-provisional` |
| `pricing.bulk.price.apply.rejected` | result | `pricing-svc` | bulk-svc | `internal-provisional` |
| `inventory.bulk.stock.adjust.requested` | command | `bulk-svc` | inventory-svc | `internal-provisional` |
| `inventory.bulk.stock.adjust.completed` | result | `inventory-svc` | bulk-svc | `internal-provisional` |
| `inventory.bulk.stock.adjust.rejected` | result | `inventory-svc` | bulk-svc | `internal-provisional` |
| `promotions.coupon.consumption.completed` | result | `promotions-svc` | modulo-ventas | `provisional-external` |
| `promotions.coupon.consumption.rejected` | result | `promotions-svc` | modulo-ventas | `provisional-external` |

**Total:** 29 mensajes, 29 canales lógicos y 58 operaciones AsyncAPI.

---

## 3. Contratos cerrados para SPEC-009 y SPEC-010

### 3.1. `taxonomy.characteristic-value.updated` — SPEC-009

**Propósito:** propagar a Catálogo un cambio confirmado de etiqueta de un valor `LISTA` sin cambiar su identidad.

Payload de negocio:

```text
caracteristica_id  ID estable de la característica LISTA
valor_id           ID estable del valor
change_type        RENAMED
nombre             etiqueta vigente después del cambio
updated_at         timestamp UTC del cambio confirmado
```

Reglas:

- se publica **después** de persistir el renombrado;
- `valor_id` no cambia;
- Catálogo actualiza o invalida su proyección por ID, nunca por la etiqueta anterior;
- no reescribe snapshots históricos ni SKU existentes;
- la deduplicación usa `message_id`.

### 3.2. `taxonomy.product-type-schema.changed` — SPEC-010

**Propósito:** informar a Catálogo que el esquema efectivo de un `tipo_producto_id` cambió de forma confirmada.

Payload de negocio:

```text
tipo_producto_id   tipo cuyo esquema cambió
schema_version     versión de negocio vigente del esquema
change_type        ASSOCIATION_ADDED | OBLIGATION_CHANGED | ASSOCIATION_REMOVED | ASSOCIATION_REACTIVATED
caracteristica_id  característica afectada, cuando aplique
updated_at         timestamp UTC del cambio confirmado
```

Catálogo puede invalidar/refrescar su proyección y volver a consultar el esquema efectivo. El evento no transporta una copia completa del formulario ni convierte el mensaje en una segunda fuente de verdad.

### 3.3. Baja segura transversal ampliada

Los cuatro payloads `MasterDeactivation*` aceptan ahora:

```text
CATEGORY
BRAND
CHARACTERISTIC_VALUE
PRODUCT_TYPE
PRODUCT_TYPE_CHARACTERISTIC
```

Flujo:

```text
taxonomy.master.deactivation.check.requested
        |
        v
catalog.master.deactivation.checked
        |
        +--> CLEAR -----------------> taxonomy.master.deactivated
        |
        +--> HAS_ACTIVE_PRODUCTS ---> taxonomy.master.deactivation.rejected
```

Esto cubre la baja segura de valores LISTA, tipos de producto y asociaciones tipo–característica. Timeout, error o ausencia de confirmación nunca equivalen a autorización.

---

## 4. Catálogo detallado por mensaje

### 4.1. Taxonomía

#### `taxonomy.category.updated`

- **Tipo:** `event`
- **Productor:** `taxonomy-svc`
- **Consumidores:** catalog-svc, api-gateway/bff, canales autorizados
- **Estado:** `stable`
- **Propósito:** Categoría actualizada.
- **Schema `data`:** `CategoryUpdatedData`
- **Campos:** `category_id`*, `category_version`*, `changed_fields`, `updated_at`*
- `*` = requerido por el schema de `data`.

#### `taxonomy.product-type-schema.changed`

- **Tipo:** `event`
- **Productor:** `taxonomy-svc`
- **Consumidores:** catalog-svc
- **Estado:** `internal-provisional`
- **Propósito:** Esquema de características de un tipo de producto modificado de forma confirmada.
- **Schema `data`:** `ProductTypeSchemaChangedData`
- **Campos:** `tipo_producto_id`*, `schema_version`*, `change_type`*, `caracteristica_id`, `updated_at`*
- `*` = requerido por el schema de `data`.

#### `taxonomy.characteristic-value.updated`

- **Tipo:** `event`
- **Productor:** `taxonomy-svc`
- **Consumidores:** catalog-svc
- **Estado:** `internal-provisional`
- **Propósito:** Valor de característica actualizado conservando sus identificadores estables.
- **Schema `data`:** `CharacteristicValueUpdatedData`
- **Campos:** `caracteristica_id`*, `valor_id`*, `change_type`*, `nombre`*, `updated_at`*
- `*` = requerido por el schema de `data`.

#### `taxonomy.master.deactivation.check.requested`

- **Tipo:** `command`
- **Productor:** `taxonomy-svc`
- **Consumidores:** catalog-svc
- **Estado:** `internal-provisional`
- **Propósito:** Solicita comprobación y barrera para baja segura.
- **Schema `data`:** `MasterDeactivationCheckRequestedData`
- **Campos:** `entity_type`*, `entity_id`*, `version`*
- `*` = requerido por el schema de `data`.

#### `taxonomy.master.deactivated`

- **Tipo:** `event`
- **Productor:** `taxonomy-svc`
- **Consumidores:** catalog-svc, api-gateway/bff
- **Estado:** `internal-provisional`
- **Propósito:** Baja lógica de entidad maestra confirmada.
- **Schema `data`:** `MasterDeactivatedData`
- **Campos:** `entity_type`*, `entity_id`*, `deactivated_at`*, `version`*
- `*` = requerido por el schema de `data`.

#### `taxonomy.master.deactivation.rejected`

- **Tipo:** `result`
- **Productor:** `taxonomy-svc`
- **Consumidores:** catalog-svc
- **Estado:** `internal-provisional`
- **Propósito:** Baja de entidad maestra rechazada.
- **Schema `data`:** `MasterDeactivationRejectedData`
- **Campos:** `entity_type`*, `entity_id`*, `reason_code`*, `detail`, `rejected_at`*, `version`*
- `*` = requerido por el schema de `data`.

### 4.2. Catálogo

#### `catalog.product.deactivated`

- **Tipo:** `event`
- **Productor:** `catalog-svc`
- **Consumidores:** promotions-svc, combos-svc, api-gateway/bff
- **Estado:** `stable`
- **Propósito:** Producto desactivado lógicamente.
- **Schema `data`:** `ProductDeactivatedData`
- **Campos:** `product_id`*, `sku_base`*, `catalog_version`*, `reason`, `deactivated_at`*
- `*` = requerido por el schema de `data`.

#### `catalog.sku.deactivated`

- **Tipo:** `event`
- **Productor:** `catalog-svc`
- **Consumidores:** inventory-svc, pricing-svc, promotions-svc, combos-svc
- **Estado:** `stable`
- **Propósito:** SKU desactivado lógicamente.
- **Schema `data`:** `SkuDeactivatedData`
- **Campos:** `sku`*, `product_id`*, `variant_id`, `catalog_version`*, `reason`, `deactivated_at`*
- `*` = requerido por el schema de `data`.

#### `catalog.master.deactivation.checked`

- **Tipo:** `result`
- **Productor:** `catalog-svc`
- **Consumidores:** taxonomy-svc
- **Estado:** `internal-provisional`
- **Propósito:** Resultado de comprobación de dependencias de entidad maestra.
- **Schema `data`:** `MasterDeactivationCheckedData`
- **Campos:** `entity_type`*, `entity_id`*, `result`*, `active_references_count`, `version`*
- `*` = requerido por el schema de `data`.

### 4.3. Pricing

#### `pricing.price.changed`

- **Tipo:** `event`
- **Productor:** `pricing-svc`
- **Consumidores:** price-audit-svc, promotions-svc, api-gateway/bff
- **Estado:** `stable`
- **Propósito:** Cambio de precio persistido.
- **Schema `data`:** `PriceChangedData`
- **Campos:** `sku`*, `product_id`*, `channel_id`, `valid_from`, `valid_until`, `price_version`*, `batch_id`, `timestamp`*, `tipo_precio`*, `precio_anterior`*, `precio_nuevo`*, `variacion_porcentual`*, `tipo_operacion`*, `moneda`*, `canal_origen`*, `motivo_cambio`*, `usuario_id`, `usuario_email`, `ip_origen`
- `*` = requerido por el schema de `data`.

### 4.4. Inventario

#### `inventory.stock.changed`

- **Tipo:** `event`
- **Productor:** `inventory-svc`
- **Consumidores:** combos-svc, promotions-svc, api-gateway/bff
- **Estado:** `stable`
- **Propósito:** Snapshot autoritativo de saldo después de un cambio.
- **Schema `data`:** `InventoryStockChangedData`

#### `inventory.stock.adjusted`

- **Tipo:** `event`
- **Productor:** `inventory-svc`
- **Consumidores:** bulk-svc, api-gateway/bff
- **Estado:** `stable`
- **Propósito:** Ajuste de stock confirmado y registrado en Kardex.
- **Schema `data`:** `InventoryStockAdjustedData`
- **Campos:** `sku`*, `location_id`*, `previous_on_hand`*, `new_on_hand`*, `delta`*, `previous_stock_version`*, `stock_version`*, `batch_id`, `row_id`, `adjusted_at`*, `motivo`*
- `*` = requerido por el schema de `data`.

#### `inventory.reservation.created`

- **Tipo:** `event`
- **Productor:** `inventory-svc`
- **Consumidores:** modulo-ventas, api-gateway/bff
- **Estado:** `provisional`
- **Propósito:** Reserva creada para un pedido CREADO.
- **Schema `data`:** `ReservationCreatedData`
- **Campos:** `reservation_id`*, `order_id`*, `channel_id`*, `expires_at`*, `lines`*, `estado`*
- `*` = requerido por el schema de `data`.

#### `inventory.reservation.consumed`

- **Tipo:** `event`
- **Productor:** `inventory-svc`
- **Consumidores:** modulo-ventas, api-gateway/bff
- **Estado:** `provisional`
- **Propósito:** Reserva consumida definitivamente.
- **Schema `data`:** `ReservationTerminalData`
- **Campos:** `reservation_id`*, `order_id`*, `lines`*, `resolved_at`*, `estado`*, `motivo`
- `*` = requerido por el schema de `data`.

#### `inventory.reservation.released`

- **Tipo:** `event`
- **Productor:** `inventory-svc`
- **Consumidores:** modulo-ventas, api-gateway/bff
- **Estado:** `provisional`
- **Propósito:** Reserva liberada.
- **Schema `data`:** `ReservationTerminalData`
- **Campos:** `reservation_id`*, `order_id`*, `lines`*, `resolved_at`*, `estado`*, `motivo`
- `*` = requerido por el schema de `data`.

#### `inventory.reservation.expired`

- **Tipo:** `event`
- **Productor:** `inventory-svc`
- **Consumidores:** modulo-ventas, api-gateway/bff
- **Estado:** `provisional`
- **Propósito:** Reserva expirada automáticamente.
- **Schema `data`:** `ReservationTerminalData`
- **Campos:** `reservation_id`*, `order_id`*, `lines`*, `resolved_at`*, `estado`*, `motivo`
- `*` = requerido por el schema de `data`.

#### `inventory.consumption.completed`

- **Tipo:** `result`
- **Productor:** `inventory-svc`
- **Consumidores:** modulo-ventas
- **Estado:** `provisional`
- **Propósito:** Resultado exitoso de confirmación de consumo.
- **Schema `data`:** `InventoryConsumptionCompletedData`
- **Campos:** `order_id`*, `reservation_id`*, `operation_type`*, `lines`*, `completed_at`*
- `*` = requerido por el schema de `data`.

#### `inventory.consumption.rejected`

- **Tipo:** `result`
- **Productor:** `inventory-svc`
- **Consumidores:** modulo-ventas
- **Estado:** `provisional`
- **Propósito:** Resultado rechazado para reserva/confirmación según operation_type.
- **Schema `data`:** `InventoryConsumptionRejectedData`
- **Campos:** `order_id`*, `reservation_id`, `operation_type`*, `detail`, `rejected_at`*, `code`*
- `*` = requerido por el schema de `data`.

### 4.5. Bulk

#### `catalog.bulk.upsert.requested`

- **Tipo:** `command`
- **Productor:** `bulk-svc`
- **Consumidores:** catalog-svc
- **Estado:** `internal-provisional`
- **Propósito:** Solicita alta/actualización de Catálogo por fila.
- **Schema `data`:** `CatalogBulkUpsertRequestedData`
- **Campos:** `batch_id`*, `row_id`*, `catalog_version`, `row`*, `operacion`*
- `*` = requerido por el schema de `data`.

#### `catalog.bulk.upsert.completed`

- **Tipo:** `result`
- **Productor:** `catalog-svc`
- **Consumidores:** bulk-svc
- **Estado:** `internal-provisional`
- **Propósito:** Aplicación de Catálogo completada para una fila.
- **Schema `data`:** `CatalogBulkUpsertCompletedData`
- **Campos:** `batch_id`*, `row_id`*, `product_id`*, `variant_id`, `sku`*, `catalog_version`*, `status`*
- `*` = requerido por el schema de `data`.

#### `catalog.bulk.upsert.rejected`

- **Tipo:** `result`
- **Productor:** `catalog-svc`
- **Consumidores:** bulk-svc
- **Estado:** `internal-provisional`
- **Propósito:** Aplicación de Catálogo rechazada para una fila.
- **Schema `data`:** `BulkRejectedData`
- **Campos:** `batch_id`*, `row_id`*, `status`*, `reason_code`*, `detail`
- `*` = requerido por el schema de `data`.

#### `pricing.bulk.price.apply.requested`

- **Tipo:** `command`
- **Productor:** `bulk-svc`
- **Consumidores:** pricing-svc
- **Estado:** `internal-provisional`
- **Propósito:** Solicita aplicar un cambio de precio de la importación general.
- **Schema `data`:** `PricingBulkPriceApplyRequestedData`
- **Campos:** `batch_id`*, `row_id`*, `sku`*, `channel_id`, `precio_regular`, `precio_oferta`, `accion_precio_oferta`*, `moneda`*, `motivo_cambio`*, `price_version`
- `*` = requerido por el schema de `data`.

#### `pricing.bulk.price.apply.completed`

- **Tipo:** `result`
- **Productor:** `pricing-svc`
- **Consumidores:** bulk-svc
- **Estado:** `internal-provisional`
- **Propósito:** Aplicación de Pricing completada para una fila.
- **Schema `data`:** `PricingBulkPriceApplyCompletedData`
- **Campos:** `batch_id`*, `row_id`*, `sku`*, `price_version`*, `status`*
- `*` = requerido por el schema de `data`.

#### `pricing.bulk.price.apply.rejected`

- **Tipo:** `result`
- **Productor:** `pricing-svc`
- **Consumidores:** bulk-svc
- **Estado:** `internal-provisional`
- **Propósito:** Aplicación de Pricing rechazada para una fila.
- **Schema `data`:** `BulkRejectedData`
- **Campos:** `batch_id`*, `row_id`*, `status`*, `reason_code`*, `detail`
- `*` = requerido por el schema de `data`.

#### `inventory.bulk.stock.adjust.requested`

- **Tipo:** `command`
- **Productor:** `bulk-svc`
- **Consumidores:** inventory-svc
- **Estado:** `internal-provisional`
- **Propósito:** Solicita un ajuste absoluto de stock condicionado por versión.
- **Schema `data`:** `InventoryBulkStockAdjustRequestedData`
- **Campos:** `batch_id`*, `row_id`*, `sku`*, `location_id`*, `stock`*, `stock_version`*, `motivo`*
- `*` = requerido por el schema de `data`.

#### `inventory.bulk.stock.adjust.completed`

- **Tipo:** `result`
- **Productor:** `inventory-svc`
- **Consumidores:** bulk-svc
- **Estado:** `internal-provisional`
- **Propósito:** Ajuste de Inventario completado para una fila.
- **Schema `data`:** `InventoryBulkStockAdjustCompletedData`
- **Campos:** `batch_id`*, `row_id`*, `sku`*, `location_id`*, `previous_on_hand`*, `new_on_hand`*, `delta`*, `stock_version`*, `status`*
- `*` = requerido por el schema de `data`.

#### `inventory.bulk.stock.adjust.rejected`

- **Tipo:** `result`
- **Productor:** `inventory-svc`
- **Consumidores:** bulk-svc
- **Estado:** `internal-provisional`
- **Propósito:** Ajuste de Inventario rechazado para una fila.
- **Schema `data`:** `BulkRejectedData`
- **Campos:** `batch_id`*, `row_id`*, `status`*, `reason_code`*, `detail`
- `*` = requerido por el schema de `data`.

### 4.6. Promociones

#### `promotions.coupon.consumption.completed`

- **Tipo:** `result`
- **Productor:** `promotions-svc`
- **Consumidores:** modulo-ventas
- **Estado:** `provisional-external`
- **Propósito:** Consumo idempotente de cupón completado.
- **Schema `data`:** `CouponConsumptionCompletedData`
- **Campos:** `order_id`*, `customer_ref`, `consumed_at`*, `cupon_id`*
- `*` = requerido por el schema de `data`.

#### `promotions.coupon.consumption.rejected`

- **Tipo:** `result`
- **Productor:** `promotions-svc`
- **Consumidores:** modulo-ventas
- **Estado:** `provisional-external`
- **Propósito:** Consumo de cupón rechazado.
- **Schema `data`:** `CouponConsumptionRejectedData`
- **Campos:** `order_id`*, `customer_ref`, `detail`, `rejected_at`*, `cupon_id`*, `code`*
- `*` = requerido por el schema de `data`.

---

## 5. Versionado y compatibilidad

Se considera compatible añadir un campo opcional sin alterar la semántica existente. Requiere una nueva versión cuando se elimina un campo requerido, cambia su tipo/significado, se endurece una enumeración de forma incompatible o se reutiliza un nombre para otro hecho.

No se retira una versión anterior hasta que sus consumidores hayan migrado.

---

## 6. Contratos deliberadamente diferidos

Permanecen fuera de este incremento y siguen declarados en AsyncAPI:

- Nombres/payloads de la preparación inicial de precio desde Catálogo hacia Pricing.
- Nombres/payloads de inicialización de SKU desde Catálogo hacia Inventario.
- Comando externo homologado de consumo de cupón desde Ventas/Postventa.
- Contrato asíncrono de reintegro de stock por devolución aceptada.
- Exchanges, queues, binding keys físicos, retry queues y DLQ.
- Permisos/scopes definitivos de los contratos externos aún marcados como provisionales.


