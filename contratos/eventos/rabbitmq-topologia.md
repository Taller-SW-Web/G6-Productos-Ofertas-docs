# Topología RabbitMQ — Productos y Ofertas

**Fuente ejecutable:** [`asyncapi.yaml`](asyncapi.yaml), candidata `0.6.0-rc.2`; no homologada externamente ni desplegada.

## 1. Decisión

VHost contractual candidato (decisión interna G6 adoptada; homologación externa pendiente):

```text
g6-productos-ofertas
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

Si el exchange principal no encuentra binding, RabbitMQ intenta enrutar el mensaje al alternate exchange. Como `po.unrouted.x` enruta a `po.unrouted.q`, el mensaje se considera enrutado: con `mandatory=true` no se genera `basic.return` en ese caso. La cola operativa es la señal esperada para alerta y diagnóstico.

Si tampoco existe ruta por el alternate exchange (por ejemplo, en una prueba aislada sin el binding de captura), `mandatory=true` exige el retorno `basic.return`; el publisher debe observarlo además de usar publisher confirms. `basic.return` y publisher confirm informan condiciones distintas. Una prueba de aceptación estática debe contrastar los bindings esperados; una prueba runtime aislada debe cubrir (a) publicación sin ruta principal capturada en `po.unrouted.q` sin `basic.return`, y (b) publicación sin ruta ni siquiera en el alternate exchange que produce `basic.return`. La segunda prueba no debe alterar la topología productiva.

## 6. Colas y bindings

### Routing keys de DLQ (aplican a la alternativa A, no adoptada)

En la alternativa A, cada cola principal configura `dead-letter-exchange: po.dlx.x` y `dead-letter-routing-key` igual al nombre de la **cola principal**. El destino se selecciona por el binding `po.dlx.x` → cola DLQ con esa misma clave. La clave no es el nombre de la cola DLQ. La tabla fija el valor exacto para las diez colas; no cambia los bindings ni la topología ejecutable `0.6.0-rc.2` vigente.

| Cola principal | Exchange DLX | `dead-letter-routing-key` | Cola destino | Binding del destino |
|---|---|---|---|---|
| `po.catalog.q` | `po.dlx.x` | `po.catalog.q` | `po.catalog.q.dlq` | `po.catalog.q` |
| `po.gateway.q` | `po.dlx.x` | `po.gateway.q` | `po.gateway.q.dlq` | `po.gateway.q` |
| `po.promotions.q` | `po.dlx.x` | `po.promotions.q` | `po.promotions.q.dlq` | `po.promotions.q` |
| `po.combos.q` | `po.dlx.x` | `po.combos.q` | `po.combos.q.dlq` | `po.combos.q` |
| `po.inventory.q` | `po.dlx.x` | `po.inventory.q` | `po.inventory.q.dlq` | `po.inventory.q` |
| `po.pricing.q` | `po.dlx.x` | `po.pricing.q` | `po.pricing.q.dlq` | `po.pricing.q` |
| `po.price-audit.q` | `po.dlx.x` | `po.price-audit.q` | `po.price-audit.q.dlq` | `po.price-audit.q` |
| `po.sales.q` | `po.dlx.x` | `po.sales.q` | `po.sales.q.dlq` | `po.sales.q` |
| `po.taxonomy.q` | `po.dlx.x` | `po.taxonomy.q` | `po.taxonomy.q.dlq` | `po.taxonomy.q` |
| `po.bulk.q` | `po.dlx.x` | `po.bulk.q` | `po.bulk.q.dlq` | `po.bulk.q` |

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
- `inventory.reservation.rejected`
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

## 9. Permisos runtime y declaraciones

La matriz operativa de `configure`, `write`, `read`, permisos de tópico y declaraciones al arranque está en [Operación de RabbitMQ](../../arquitectura/operacion-rabbitmq.md#matriz-rabbitmq-por-aplicacion). Se deriva de estos bindings/operaciones y no concede acceso de lectura a `po.unrouted.q`, las colas `.retry` ni las DLQ a las identidades de aplicación.

## 10. Evaluación de aislamiento retry/DLX (sin cambio contractual)

El AsyncAPI `0.6.0-rc.2` anterior continúa describiendo `po.retry.x` y `po.dlx.x` como exchanges `direct` y el flujo actual de retry/DLQ. La alternativa A está documentada como candidata para validación, **no como topología adoptada**: convertir `po.retry.x` a `topic` y limitar su routing key mediante topic permissions exactos; mantener `po.dlx.x` `direct` sin permiso runtime `write`; configurar la DLX de cada cola principal para que un rechazo final con `requeue=false` llegue a su `<main>.dlq`. Los consumidores de negocio deben ACKear rechazos válidos.

Para evitar ciclos en esa futura configuración, la única salida DLX de cada cola `.retry` seguiría apuntando al exchange por defecto con routing key de su cola principal. La cola principal configuraría `dead-letter-routing-key` con su propio nombre (`po.inventory.q` para Inventario), que selecciona la DLQ por el binding declarado en la tabla anterior; no se usa como clave el nombre `<main>.dlq`. Una DLQ no tendría DLX de retorno. Reintentos publicados por aplicación deben conservar el envelope, `message_id`, `correlation_id`, `causation_id`, `operation_id` y contador verificable, con publisher confirm antes de ACK del original. Dead lettering at-least-once de fuentes quorum exige validar en 4.2.9 `dead-letter-strategy=at-least-once`, `overflow=reject-publish`, políticas/argumentos correctos y `stream_queue`; puede retener mensajes si el destino no acepta y puede duplicar, por lo que Outbox/Inbox/idempotencia no se omiten.

**Estado de prueba:** se ejecutó el arnés aislado RabbitMQ 4.2.9. Las pruebas de permisos, TTL, DLQ normal, rechazo de negocio, tres reintentos y rutas alternas pasan; el caso de DLQ llena no observó el reenvío del dead letter retenido dentro de 60 s. A/B/C permanecen no adoptadas, el bloqueo de credenciales runtime continúa y AsyncAPI conserva `0.6.0-rc.2`. No se deben cambiar los tipos de exchange en un broker que ya los tenga declarados: un tipo distinto en el mismo nombre es incompatible. Cualquier eventual migración requiere inventario, destino aislado, corte/drenaje y reversión no destructivos; no purgar ni recrear colas con mensajes. Si la alternativa A se adopta luego de sus pruebas, requiere AsyncAPI `0.6.0-rc.3` para versionar el cambio físico de `po.retry.x` y la ruta de rechazo final; esta evaluación sin adopción no altera la versión.

## Addendum contractual 0.6.0-rc.1 — Cuatro bloqueantes G6

**Decisión interna aprobada; objetivo 0.6.0-rc.1 (no desplegado).**

- `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- `POST /inventario/reservas`, `/confirmar` y `/liberar` responden `202` solamente cuando aceptan el comando. El éxito o rechazo se determina por resultado persistido y evento.
- Nuevos contratos provisionales: `GET /inventario/operaciones/{operationId}` (solo Ventas; scope `inventario:operaciones:leer`) y `POST /inventario/disponibilidad/comercial/verificar` (canales, consulta sin efectos).
- Nuevo evento `inventory.reservation.rejected`; resultados de reserva/consumo/liberación/expiración con datos tipados y correlación obligatoria.
- `D-INV-01`: no se suman saldos de ubicaciones independientes por defecto. Un canal obtiene `INDETERMINADO` cuando el punto único de cumplimiento no se puede resolver. `SUFICIENTE` exige una fuente de abastecimiento realizable para la cantidad completa; no supone reserva.
- Cupones: después de reserva confirmada, Ventas envía `reservation_id` y `commercial_snapshot_ref` al solicitar consumo. Los resultados de consumo se tipan y la restauración se vincula a la operación previamente consumida.
- Misma identidad/operación/payload semántico => mismo resultado y cero efectos nuevos; identidad reutilizada con payload distinto => `IDEMPOTENCY_CONFLICT`. Los eventos tienen `message_id` propio para deduplicación de transporte.
- Las transiciones pagar/expirar/liberar se serializan por reserva; se respeta `expires_at` emitido por Inventario.
- Estos contratos siguen **provisionales** hasta que la implementación, migraciones y pruebas integradas sean verificadas. No anunciar disponibilidad real antes del cierre.
