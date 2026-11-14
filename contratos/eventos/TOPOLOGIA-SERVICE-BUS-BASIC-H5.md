# Topología candidata Service Bus Basic — G6 Hito 5

**Estado:** propuesta; no hay colas creadas, bindings migrados ni entrega probada. El AsyncAPI H4 sigue siendo el inventario lógico de origen.

## Regla de diseño

Service Bus Basic no tiene topics/subscriptions; una cola representa una entrega para un consumidor, **nunca** una distribución automática de un evento a varios grupos. Una nueva copia del mismo evento dirigida a otro destinatario debe aparecer como `outbox_delivery` propia, con estado y reintentos independientes.

Nombre candidato: `g6.<consumidor>.from.<productor>`; punto a punto, ASCII, sin nombres reservados del proveedor. Validar convenciones finales con IaC y Azure. `g6` alude al bounded context y no equivale a un namespace por servicio.

## Relaciones internas heredadas de H4

Conteo auditado contra AsyncAPI `0.6.0-rc.4`: 18 pares únicos productor→consumidor G6, excluyendo `modulo-ventas` (frontera externa propuesta HTTP) y `api-gateway/bff` (no tratado como consumidor de cola en este diseño). Son relaciones heredadas del inventario H4; **no son el inventario ni el límite máximo de colas de H5**. No equivalen a 18 handlers implementados ni obligan a aprovisionar exactamente una cola por relación. Hay 40 mensajes/canales y 13 asignaciones a G5 (11 G6→G5 y 2 G5→G6).

| Destino | Productor | Cola candidata | Mensajes/propósito principales |
|---|---|---|---|
| Catalog | Taxonomy | `g6.catalog.from.taxonomy` | Actualizaciones de maestro, bajas y solicitudes |
| Catalog | Bulk | `g6.catalog.from.bulk` | Upsert masivo |
| Catalog | Pricing | `g6.catalog.from.pricing` | Resultados de inicialización |
| Catalog | Inventory | `g6.catalog.from.inventory` | Resultados inicialización SKU |
| Bulk | Catalog | `g6.bulk.from.catalog` | Resultado importación |
| Bulk | Inventory | `g6.bulk.from.inventory` | Ajuste stock y resultados masivos candidatos |
| Bulk | Pricing | `g6.bulk.from.pricing` | Resultados masivos candidatos |
| Pricing | Catalog | `g6.pricing.from.catalog` | Inicialización y baja SKU |
| Pricing | Bulk | `g6.pricing.from.bulk` | Aplicación precios masivos candidata |
| Inventory | Catalog | `g6.inventory.from.catalog` | Inicialización y baja SKU |
| Inventory | Bulk | `g6.inventory.from.bulk` | Ajuste masivo de stock candidato |
| Promotions | Catalog | `g6.promotions.from.catalog` | Baja de producto/SKU |
| Promotions | Pricing | `g6.promotions.from.pricing` | Cambio de precios |
| Promotions | Inventory | `g6.promotions.from.inventory` | Cambio de stock |
| Combos | Catalog | `g6.combos.from.catalog` | Baja de producto/SKU |
| Combos | Inventory | `g6.combos.from.inventory` | Cambios de stock |
| Taxonomy | Catalog | `g6.taxonomy.from.catalog` | Resultado de verificación de baja |
| Price Audit | Pricing | `g6.price-audit.from.pricing` | `pricing.price.changed` |

## Cola nueva para operaciones HTTP de Promotions

Esta cola responde a un flujo H5 HTTP asíncrono y no pertenece a los 18 pares productor→consumidor heredados de H4. Su existencia, como todo H5, es propuesta y no acredita aprovisionamiento ni implementación.

| Cola candidata | Productor interno | Consumidor exclusivo | Mensajes y propósito |
|---|---|---|---|
| `g6.promotions.commands` | Adaptador HTTP de `promotions-svc` vía Outbox durable | Worker de operaciones de `promotions-svc` | Comandos de consumo/restauración de cupón; persistir Inbox, aplicar idempotencia, guardar resultado terminal y servirlo por GET HTTP |

### Secuencia durable propuesta

1. El adaptador HTTP valida token, allowlist, esquema, `operation_id`/`Idempotency-Key`, pedido y precondiciones que puede verificar.
2. En una transacción local de Promotions escribe la operación `ACCEPTED`, fingerprint idempotente y registro Outbox; devuelve HTTP 202 solo tras el commit.
3. El relay Outbox envía a `g6.promotions.commands`; conserva la entrega pendiente ante error o resultado ambiguo y reintenta la misma identidad de mensaje. No marca envío confirmado antes del acuse positivo del SDK.
4. El único worker de operaciones de Promotions recibe con Peek-Lock. En una transacción local registra/consulta Inbox por `message_id`, verifica idempotencia funcional por `operation_id`, aplica una sola vez el efecto y persiste el resultado de operación.
5. Tras commit de Inbox, efecto y resultado, completa el mensaje. Si el settle falla, la redelivery no repite el efecto y recupera el resultado persistido.
6. El endpoint GET de operación devuelve la proyección persistida autorizada por identidad/pedido; consultar o reintentar nunca vuelve a ejecutar el comando.

La transacción SQL no abarca el broker. Caídas del relay/worker se recuperan desde Outbox, redelivery y reconciliación durable; no se declara exactamente una vez en el transporte.

**Regla de aprovisionamiento:** solo crear colas de flujos con handlers aprobados, implementados y probados. No conectar automáticamente los mensajes que el código registra como `BLOCKED_CONTRACT` o runtime condicionado. Las relaciones con `api-gateway/bff` no se equiparan a grupos externos sin contrato específico.

## Frontera G5 en Basic

Los 13 mensajes que AsyncAPI asigna a `modulo-ventas` como productor/consumidor serán **representados externamente por HTTP** tras homologación. No crear `g6.ventas.*` por inercia ni permitir al módulo de Ventas obtener credenciales del namespace. Si una solicitud HTTP debe activar un worker asíncrono G6, se crea una cola **interna**, propiedad del servicio de negocio, no de G5.

## Envelope y trazabilidad

| Campo | Regla |
|---|---|
| `message_id` / `MessageId` | Id estable del mensaje de outbox para reintento; un destinatario puede recibir copia con mismo identificador lógico |
| `operation_id` | Identidad funcional idempotente; no sustituirlo por ID de transporte |
| `correlation_id` | Propagar entre HTTP, outbox, cola, inbox y estado consultable |
| `name` y `schema_version` | Contratos de negocio versionados; ruteo por catálogo interno, no por exchange |
| `producer` | Dato contractual validado contra identidad de ejecución/autorización, nunca autenticación suficiente por sí solo |
| `destination` | Identificador de cola previsto por configuración validada y autorizada |

## Outbox para fan-out

- Registros inmutables de evento e intención de entrega por destino; clave única `(event_id, destination)`.
- Transacción local: cambio de negocio + evento + entregas comprometidas; **ninguna** transacción distribuida con Azure.
- Una entrega se marca confirmada **solo** después del resultado positivo de `sendMessages` para ese destino. En timeout ambiguo permanece pendiente: reintentar con mismo `MessageId`, soportar duplicados en inbox.
- Si se aprueba un nuevo consumidor de evento antiguo, definir si hay replay histórico y límites de retención, no generar envíos retrospectivos por defecto.
- No marcar publicación global exitosa mientras existan entregas obligatorias pendientes.

## Consumo y fallos

- `PeekLock`: procesar y persistir inbox/resultado antes de `completeMessage`.
- Manejar redelivery, pérdida de lock, reintento por dependencia temporal y mensaje inválido. Clasificar inválidos o maliciosos con disposición duradera; DLQ supervisada.
- Una misma cola puede tener múltiples instancias de **un mismo consumidor lógico** para escalar, pero no servicios independientes que necesiten cada uno su copia.
- No se garantiza FIFO estricto; usar versión de agregado y control de concurrencia en base de datos.
- Probar corte del worker, caída del broker, reinicio y reconciliación del outbox.

## Restricciones verificadas

- Basic: colas sin topics, sesiones, duplicate detection administrada ni configuración `DefaultMessageTimeToLive`. El TTL máximo/default de mensaje para Basic es 14 días; el TTL individual no convierte al broker en fuente de expiración comercial.
- Máximo por mensaje/lote: **256 KB incluyendo propiedades**. No adoptar solo un máximo de payload de 256 KB; reservar margen para metadatos y encoding.
- `catalog.bulk.upsert.requested` H4 permitía hasta 1 MiB: dividir por unidades semánticamente atómicas, y si una unidad supera el límite usar Blob Storage + referencia con checksum, TTL/retención y permisos; los resultados deben conservar identidades por fila y correlación.
- No asumir que funciones de Standard/Premium están disponibles en Basic (por ejemplo auto-forwarding, sesiones o detección de duplicados).
- La entidad Basic no permite ajustar `DefaultMessageTimeToLive` y su máximo/default es 14 días. Si una indisponibilidad excede ese período, la operación/Outbox SQL permanece durable: reconciliar Inbox y resultado persistido, identificar comandos sin efecto terminal confirmado y reenviar solo con autorización y la misma idempotencia. La expiración del mensaje no altera `expires_at` ni vence una reserva comercial.

Fuentes del proveedor: [propiedades no admitidas en Basic](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-resource-manager-exceptions) y [expiración/TTL](https://learn.microsoft.com/en-us/azure/service-bus-messaging/message-expiration).

## IaC y autorización

- Provisionar namespace, colas, límites, `maxDeliveryCount` y permisos desde Bicep/Terraform (diseño aprobado antes de aplicar).
- Identidades de ejecución independientes por servicio cuando el host lo permita; roles `Data Sender`/`Data Receiver` de alcance cola, no `Data Owner` runtime.
- Si todos los servicios comparten identidad de una VM, dejar el riesgo de aislamiento explícito y proponer identidades separadas para el runtime; no declarar aislamiento por servicio inexistente.
