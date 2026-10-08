# Topología RabbitMQ — Productos y Ofertas

**Fuente ejecutable:** [`../asyncapi/asyncapi.yaml`](asyncapi.yaml)

## 1. Decisión

VHost:

```text
/marketplace
```

Exchanges durables:

| Exchange | Tipo | Uso |
|---|---|---|
| `po.commands.x` | topic | Comandos |
| `po.events.x` | topic | Hechos/eventos |
| `po.results.x` | topic | Resultados |
| `po.retry.x` | direct | Retries técnicos retardados |
| `po.dlx.x` | direct | Dead letters por consumidor |
| `po.unrouted.x` | fanout | Publicaciones sin binding |

La routing key de negocio es siempre el nombre lógico del mensaje, por ejemplo:

```text
inventory.stock.changed
pricing.product.initialization.requested
```

## 2. Fiabilidad

- Colas principales: quorum, durable.
- ACK de consumidor: manual.
- Publisher confirms: obligatorios.
- Prefetch inicial: `20` por consumidor.
- Entrega: at-least-once.
- Dedupe: `message_id`.
- Idempotencia de negocio: `operation_id` cuando aplique.
- Outbox transaccional para publicar después del commit.
- Inbox/dedupe antes de aplicar side effects.

RabbitMQ recomienda publisher confirms para saber cuándo el broker asumió responsabilidad por una publicación; las quorum queues combinan bien con confirms y acknowledgements manuales cuando se prioriza seguridad de datos.

## 3. Retry

Regla de retry:

```text
máximo 3 retries de aplicación
delay = 30 s por retry
```

Flujo:

```text
main queue
  -> fallo técnico transitorio
  -> publicar en po.retry.x con routing key = nombre de main queue
  -> ACK del original
  -> <main>.retry espera 30 s
  -> DLX al default exchange
  -> vuelve directamente a <main>
```

Después del tercer retry:

```text
po.dlx.x
  -> <main>.dlq
```

No usar `requeue=true` en bucle.

## 4. Qué NO va a DLQ

Un rechazo de negocio válido no es un poison message.

Ejemplos:

```text
STOCK_INSUFICIENTE
CUPON sin cupo
RESERVA_NO_ACTIVA
```

El consumidor confirma el mensaje y publica el resultado `...rejected` cuando el contrato lo define.

Van a retry/DLQ:

- timeout de base de datos;
- broker/dependencia temporalmente no disponible;
- fallo técnico repetido;
- mensaje malformado;
- schema/version no soportado.

## 5. Publicaciones sin ruta

Los exchanges de negocio usan `po.unrouted.x` como alternate exchange. Además, los publishers deben usar `mandatory=true`.

`po.unrouted.q` es operativa: detecta un mensaje que no tenía consumidor físico configurado.

## 6. Colas y bindings

### `po.catalog.q` — catalog-svc

Bindings:

- `catalog.bulk.upsert.requested`
- `inventory.sku.initialization.completed`
- `inventory.sku.initialization.rejected`
- `pricing.product.initialization.completed`
- `pricing.product.initialization.rejected`
- `taxonomy.category.updated`
- `taxonomy.characteristic-value.updated`
- `taxonomy.master.deactivated`
- `taxonomy.master.deactivation.check.requested`
- `taxonomy.master.deactivation.rejected`
- `taxonomy.product-type-schema.changed`

Retry: `po.catalog.q.retry` · DLQ: `po.catalog.q.dlq`

### `po.gateway.q` — api-gateway/bff

Bindings:

- `catalog.product.deactivated`
- `inventory.reservation.consumed`
- `inventory.reservation.created`
- `inventory.reservation.expired`
- `inventory.reservation.released`
- `inventory.stock.adjusted`
- `inventory.stock.changed`
- `pricing.price.changed`
- `taxonomy.category.updated`
- `taxonomy.master.deactivated`

Retry: `po.gateway.q.retry` · DLQ: `po.gateway.q.dlq`

### `po.promotions.q` — promotions-svc

Bindings:

- `catalog.product.deactivated`
- `catalog.sku.deactivated`
- `inventory.stock.changed`
- `pricing.price.changed`
- `promotions.coupon.consumption.requested`
- `promotions.coupon.restoration.requested`

Retry: `po.promotions.q.retry` · DLQ: `po.promotions.q.dlq`

### `po.combos.q` — combos-svc

Bindings:

- `catalog.product.deactivated`
- `catalog.sku.deactivated`
- `inventory.stock.changed`

Retry: `po.combos.q.retry` · DLQ: `po.combos.q.dlq`

### `po.inventory.q` — inventory-svc

Bindings:

- `catalog.sku.deactivated`
- `inventory.bulk.stock.adjust.requested`
- `inventory.sku.initialization.requested`

Retry: `po.inventory.q.retry` · DLQ: `po.inventory.q.dlq`

### `po.pricing.q` — pricing-svc

Bindings:

- `catalog.sku.deactivated`
- `pricing.bulk.price.apply.requested`
- `pricing.product.initialization.requested`

Retry: `po.pricing.q.retry` · DLQ: `po.pricing.q.dlq`

### `po.price-audit.q` — price-audit-svc

Bindings:

- `pricing.price.changed`

Retry: `po.price-audit.q.retry` · DLQ: `po.price-audit.q.dlq`

### `po.sales.q` — modulo-ventas

Bindings:

- `inventory.consumption.completed`
- `inventory.consumption.rejected`
- `inventory.reservation.consumed`
- `inventory.reservation.created`
- `inventory.reservation.expired`
- `inventory.reservation.released`
- `promotions.coupon.consumption.completed`
- `promotions.coupon.consumption.rejected`
- `promotions.coupon.restoration.completed`
- `promotions.coupon.restoration.rejected`

Retry: `po.sales.q.retry` · DLQ: `po.sales.q.dlq`

### `po.taxonomy.q` — taxonomy-svc

Bindings:

- `catalog.master.deactivation.checked`

Retry: `po.taxonomy.q.retry` · DLQ: `po.taxonomy.q.dlq`

### `po.bulk.q` — bulk-svc

Bindings:

- `catalog.bulk.upsert.completed`
- `catalog.bulk.upsert.rejected`
- `inventory.bulk.stock.adjust.completed`
- `inventory.bulk.stock.adjust.rejected`
- `inventory.stock.adjusted`
- `pricing.bulk.price.apply.completed`
- `pricing.bulk.price.apply.rejected`

Retry: `po.bulk.q.retry` · DLQ: `po.bulk.q.dlq`


## 7. Canales externos

Marketplace, Chatbot y Retail continúan integrándose principalmente por HTTP. No se provisionan colas directas para ellos en P2.

Cuando un dato debe proyectarse hacia canales, el consumidor físico es `api-gateway/bff`. Chatbot mantiene su decisión explícita de no consumir eventos en esta versión.

## 8. Configuración pendiente de entorno

No forma parte del contrato de negocio:

- hostname del broker;
- credenciales/secret;
- número de nodos del cluster;
- memoria/disco asignado;
- TLS/certificados del entorno.

Esos valores se resuelven en infraestructura sin cambiar exchanges, queues ni routing keys.
