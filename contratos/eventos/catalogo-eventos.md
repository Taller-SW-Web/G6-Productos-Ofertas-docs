# Catálogo de eventos y mensajes — Productos y Ofertas

**Fuente de verdad:** [`asyncapi.yaml`](asyncapi.yaml)
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

## Semántica de operation_id, message_id y causation_id en preparación de Catálogo (FLOW-003 / FLOW-004)

Aplica específicamente a los comandos y resultados de inicialización:
- `pricing.product.initialization.requested`
- `pricing.product.initialization.completed`
- `pricing.product.initialization.rejected`
- `inventory.sku.initialization.requested`
- `inventory.sku.initialization.completed`
- `inventory.sku.initialization.rejected`

### Reglas de identidad, transporte e idempotencia

1. **`operation_id` (Identidad de negocio de la preparación):**
   - Identifica la **PREPARACIÓN** lógica de larga vida entre Catálogo y el servicio dependiente (Pricing o Inventario).
   - Se genera en el alta inicial y **se conserva estrictamente** a lo largo de toda la vida de esa preparación, incluyendo cualquier recuperación manual autorizada.
2. **`message_id` (Identidad de publicación y transporte):**
   - Identifica una publicación o intento concreto a través de RabbitMQ.
   - Toda redelivery técnica del mismo mensaje en la infraestructura de transporte conserva su `message_id` original y es deduplicada de forma ordinaria por el consumidor.
   - Cuando Catálogo autoriza una recuperación manual excepcional tras un rechazo o umbral superado, **conserva la `operation_id` pero genera una nueva `message_id`** para la publicación Outbox hacia RabbitMQ.
3. **`causation_id` (Correlación por intento y descarte de resultados stale):**
   - Cada comando `*.requested` tiene su propia `message_id`.
   - El resultado asíncrono correspondiente (`*.completed` o `*.rejected`) emitido por el servicio dependiente DEBE portar `causation_id = message_id` del comando `*.requested` que originó ese resultado.
   - Catálogo conserva internamente cuál es la `message_id` del intento actualmente activo.
   - Catálogo solo puede modificar el estado actual de la preparación con un resultado cuyo `causation_id` coincida con la `message_id` del intento activo.
   - Un resultado tardío de un intento anterior se registra/ignora idempotentemente como stale y NO puede reemplazar ni degradar el estado del intento actual.
   - Ejemplo:
     ```text
     operation_id = PREP-123

     attempt 1:
     requested.message_id = MSG-A
     rejected.causation_id = MSG-A

     manual retry:
     requested.message_id = MSG-B
     completed.causation_id = MSG-B
     ```
     Si llega un mensaje tardío con `causation_id = MSG-A` mientras el intento activo es `MSG-B`, Catálogo lo registra/ignora como stale y no toca el intento `MSG-B`.
4. **Reconocimiento en el consumidor tras `REJECTED`:**
   - Después de emitir un resultado `*.rejected`, el consumidor puede recibir posteriormente un nuevo mensaje con una **nueva `message_id`** pero con la **misma `operation_id`**.
   - El consumidor debe reconocer que este mensaje representa un nuevo intento autorizado de la misma preparación lógica, y **no** una segunda entidad de negocio.
   - Las reglas de idempotencia deben seguir impidiendo la creación de precios duplicados, SKUs duplicados o inicializaciones redundantes.
5. **Terminalidad de `COMPLETED`:**
   - El estado `COMPLETED` es terminal para esa preparación.
   - Publicaciones posteriores que porten una `operation_id` ya completada se descartan idempotentemente y **nunca** vuelven a aplicar efectos ni mutaciones en el servicio dependiente.
6. **Reconstrucción del comando con el estado actual validado del borrador:**
   - Cuando la recuperación ocurre después de que el Gestor Comercial corrigió datos en el borrador de Catálogo, el nuevo comando `*.requested` se construye usando el **estado actual validado** del borrador.
   - **No se debe republicar ciegamente el payload antiguo rechazado**.
   - Si un rechazo de pricing exigiese alterar el precio base inicial, `manual_retry_allowed` permanece en `false` porque la API de Catálogo no expone una operación para modificar el precio base inicial en el borrador; el reintento manual solo puede admitirse para causas subsanables con operaciones vigentes.
   - Conservar la `operation_id` no significa congelar el payload rechazado.
