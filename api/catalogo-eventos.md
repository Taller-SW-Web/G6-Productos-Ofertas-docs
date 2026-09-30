# Catálogo de eventos y mensajes — Productos y Ofertas

**Fuente de verdad:** [`../asyncapi/asyncapi.yaml`](../asyncapi/asyncapi.yaml)  
**Topología física:** [`rabbitmq-topologia.md`](./rabbitmq-topologia.md)

## Reglas comunes

```text
delivery = at-least-once
publisher confirms = obligatorio
consumer ack = manual
deduplicación = message_id
idempotencia de negocio = operation_id cuando aplique
routing key = nombre lógico del mensaje
```

## Mensajes

| Nombre | Tipo | Productor | Consumidores | Estado |
|---|---|---|---|---|
| `catalog.bulk.upsert.completed` | `result` | `catalog-svc` | bulk-svc | `internal-provisional` |
| `catalog.bulk.upsert.rejected` | `result` | `catalog-svc` | bulk-svc | `internal-provisional` |
| `catalog.bulk.upsert.requested` | `command` | `bulk-svc` | catalog-svc | `internal-provisional` |
| `catalog.master.deactivation.checked` | `result` | `catalog-svc` | taxonomy-svc | `internal-provisional` |
| `catalog.product.deactivated` | `event` | `catalog-svc` | promotions-svc, combos-svc, api-gateway/bff | `stable` |
| `catalog.sku.deactivated` | `event` | `catalog-svc` | inventory-svc, pricing-svc, promotions-svc, combos-svc | `stable` |
| `inventory.bulk.stock.adjust.completed` | `result` | `inventory-svc` | bulk-svc | `internal-provisional` |
| `inventory.bulk.stock.adjust.rejected` | `result` | `inventory-svc` | bulk-svc | `internal-provisional` |
| `inventory.bulk.stock.adjust.requested` | `command` | `bulk-svc` | inventory-svc | `internal-provisional` |
| `inventory.consumption.completed` | `result` | `inventory-svc` | modulo-ventas | `provisional` |
| `inventory.consumption.rejected` | `result` | `inventory-svc` | modulo-ventas | `provisional` |
| `inventory.reservation.consumed` | `event` | `inventory-svc` | modulo-ventas, api-gateway/bff | `provisional` |
| `inventory.reservation.created` | `event` | `inventory-svc` | modulo-ventas, api-gateway/bff | `provisional` |
| `inventory.reservation.expired` | `event` | `inventory-svc` | modulo-ventas, api-gateway/bff | `provisional` |
| `inventory.reservation.released` | `event` | `inventory-svc` | modulo-ventas, api-gateway/bff | `provisional` |
| `inventory.sku.initialization.completed` | `result` | `inventory-svc` | catalog-svc | `closed` |
| `inventory.sku.initialization.rejected` | `result` | `inventory-svc` | catalog-svc | `closed` |
| `inventory.sku.initialization.requested` | `command` | `catalog-svc` | inventory-svc | `closed` |
| `inventory.stock.adjusted` | `event` | `inventory-svc` | bulk-svc, api-gateway/bff | `stable` |
| `inventory.stock.changed` | `event` | `inventory-svc` | combos-svc, promotions-svc, api-gateway/bff | `stable` |
| `pricing.bulk.price.apply.completed` | `result` | `pricing-svc` | bulk-svc | `internal-provisional` |
| `pricing.bulk.price.apply.rejected` | `result` | `pricing-svc` | bulk-svc | `internal-provisional` |
| `pricing.bulk.price.apply.requested` | `command` | `bulk-svc` | pricing-svc | `internal-provisional` |
| `pricing.price.changed` | `event` | `pricing-svc` | price-audit-svc, promotions-svc, api-gateway/bff | `stable` |
| `pricing.product.initialization.completed` | `result` | `pricing-svc` | catalog-svc | `closed` |
| `pricing.product.initialization.rejected` | `result` | `pricing-svc` | catalog-svc | `closed` |
| `pricing.product.initialization.requested` | `command` | `catalog-svc` | pricing-svc | `closed` |
| `promotions.coupon.consumption.completed` | `result` | `promotions-svc` | modulo-ventas | `provisional-external` |
| `promotions.coupon.consumption.rejected` | `result` | `promotions-svc` | modulo-ventas | `provisional-external` |
| `promotions.coupon.consumption.requested` | `command` | `modulo-ventas` | promotions-svc | `closed` |
| `promotions.coupon.restoration.completed` | `result` | `promotions-svc` | modulo-ventas | `closed` |
| `promotions.coupon.restoration.rejected` | `result` | `promotions-svc` | modulo-ventas | `closed` |
| `promotions.coupon.restoration.requested` | `command` | `modulo-ventas` | promotions-svc | `closed` |
| `taxonomy.category.updated` | `event` | `taxonomy-svc` | catalog-svc, api-gateway/bff | `stable` |
| `taxonomy.characteristic-value.updated` | `event` | `taxonomy-svc` | catalog-svc | `internal-provisional` |
| `taxonomy.master.deactivated` | `event` | `taxonomy-svc` | catalog-svc, api-gateway/bff | `internal-provisional` |
| `taxonomy.master.deactivation.check.requested` | `command` | `taxonomy-svc` | catalog-svc | `internal-provisional` |
| `taxonomy.master.deactivation.rejected` | `result` | `taxonomy-svc` | catalog-svc | `internal-provisional` |
| `taxonomy.product-type-schema.changed` | `event` | `taxonomy-svc` | catalog-svc | `internal-provisional` |

## Retry y DLQ

Los rechazos de negocio válidos se ACKean y generan su resultado de dominio cuando corresponda.

Retry/DLQ se reserva para fallos técnicos o mensajes no procesables:

```text
hasta 3 retries
30 s entre intentos
<main>.retry
<main>.dlq
```

La tabla exacta de exchanges, queues y bindings está en `api/rabbitmq-topologia.md`.
