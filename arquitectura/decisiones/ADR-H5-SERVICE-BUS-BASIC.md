# ADR-H5 — Azure Service Bus Basic como mensajería interna de G6

**Estado de arquitectura:** `ADOPTADA_G6` (propuesta PR #119, fusionada en master el 2026-11-14; SHA de merge `a53ed842db1b05a12f5e30bc8987df1a137ff49b`). No es homologación externa ni evidencia de implementación.

**Estados pendientes independientes:** `PENDIENTE_APROVISIONAMIENTO_AZURE`; `PENDIENTE_IMPLEMENTACION`; `PENDIENTE_HOMOLOGACION_G5`; `PENDIENTE_AUTORIZACION_G7`. Un integrante del equipo asumió la configuración de los recursos en su cuenta Azure. No hay evidencia aquí de recursos creados, suscripción/identidad/grants, pruebas runtime o despliegue; no inferirlos de esa asignación.
**Alcance:** Hito 5, ocho microservicios G6, API Gateway y fronteras con G1–G7.
**Fecha del borrador:** 2026-11-14.
**Reemplaza operativamente, tras corte aprobado:** RabbitMQ en la infraestructura G6; **no** elimina los acuerdos ni evidencias H4.

## Contexto y decisión adoptada por G6

G6 migra backend a Azure y necesita mensajería asíncrona operable con bajo costo sin trasladar la administración del broker a otros grupos. La arquitectura objetivo adoptada es:

1. **Azure Service Bus Basic** como intermediario exclusivamente interno de G6. Un namespace por ambiente con colas duraderas preaprovisionadas.
2. **Consumidores externos G1–G5** acceden a G6 por endpoints HTTP autenticados en API Management/Gateway G6. G7 conserva identidad y grants; no se entregan cadenas de conexión, secretos SAS ni permisos directos de Service Bus a módulos externos.
3. **G5 Ventas/Postventa** reemplaza su publicación/consumo directo RabbitMQ por llamadas HTTP de admisión de operación y lectura del resultado durable. Esto requiere acuerdo bilateral antes del corte.
4. Se conserva el dominio de contratos de negocio (`message_id`, `operation_id`, `correlation_id`, tipo, versión, datos), pero el enrutamiento físico RabbitMQ deja de ser norma del transporte futuro.
5. Se garantiza **at-least-once** e **idempotencia de efectos**, no exactly-once del broker.

Esta ADR **no acredita ni autoriza** por sí sola despliegues, merges, eliminación de RabbitMQ, activación de cupones, cambios unilaterales en API externas ni declaraciones de homologación G5/G7.

## Por qué Basic es aceptable

| Capacidad | Basic | Tratamiento G6 |
|---|---|---|
| Colas duraderas y recepción Peek-Lock | Sí | `completeMessage` tras persistir efecto; redelivery ante caída |
| DLQ integrada | Sí | Operación y recuperación supervisadas |
| Topics, subscriptions y fan-out administrado | No | Outbox por destinatario; no compartir una sola cola entre interesados |
| Duplicate detection del broker | No | Inbox e idempotencia persistentes |
| Sesiones/FIFO estricto por grupo | No | Serialización/versiones por agregado en dominio cuando haga falta |
| Transacciones de mensajería | No | Transacción local SQL para negocio/outbox; entrega eventual con conciliación |
| Mensaje de 1 MiB | No | Límite completo de mensaje de 256 KB; fragmentación semántica o claim-check |

Basic tampoco permite configurar `DefaultMessageTimeToLive`; su TTL máximo/default de mensajes es 14 días. Una caída prolongada puede dejar mensajes expirados, por lo que la recuperación se apoya en las operaciones y Outbox durables de SQL, compara Inbox/resultado persistido, concilia estados ambiguos y solo reenvía sin efecto terminal confirmado mediante replay autorizado e idempotente. Nunca se reemite ciegamente un efecto comercial. La expiración de reservas es una regla de negocio de Inventory basada en `expires_at`, separada del TTL del mensaje.

## Colas heredadas y colas nuevas de H5

Las 18 relaciones productor→consumidor internos deducidas del AsyncAPI H4 son un inventario de relaciones de origen, no el límite ni el inventario completo de colas de H5. No son una equivalencia uno-a-uno ni restringen las colas adicionales que requieran nuevos flujos HTTP asíncronos.

Para consumos y restauraciones de cupón admitidos por HTTP se propone la cola interna `g6.promotions.commands`: el adaptador HTTP de Promotions la alimenta mediante su Outbox durable y la consume exclusivamente el worker de operaciones de Promotions. El worker registra Inbox, aplica idempotencia, persiste el resultado antes de completar el mensaje y lo expone al GET autenticado de operaciones. El flujo se detalla en la [topología H5](../../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md) y la [propuesta HTTP](../../contratos/http/PROPUESTA-OPERACIONES-CUPONES-H5.md).

**Criterio de reconsideración:** migrar a Service Bus Standard si la cantidad de destinatarios, el fan-out, el orden estricto o el costo operativo de la distribución propia convierten a Basic en una mala elección. Esta revisión requiere mediciones y aprobación, no supone cambio automático.

## Fronteras

```text
G1/G2/G3/G4/G5 ──HTTPS+JWT(G7)──> Azure API Management ──> Gateway G6
                                                             │
                                                         HTTP owners
                                                             │
                                                  SQL + Outbox transaccional
                                                             │
                                                    Azure Service Bus Basic
                                                             │
                                                    consumidor interno G6
                                                             │
                                                    Inbox + resultado durable
                                                             │
G5 ──HTTPS GET /operaciones/{operationId}───────────────────┘
```

- APIM no sustituye la validación de JWT/audiencia, scopes/allowlist por operación ni el control de actor/propiedad del resultado en backend.
- `202 Accepted` significa solicitud admitida **y durablemente registrada**, no procesada ni publicada en Service Bus.
- Ningún consumidor HTTP requiere recibir eventos por WebSocket o webhook para completar el flujo propuesto.
- La consulta debe distinguir `ACCEPTED`, `COMPLETED`, `REJECTED` y otros estados contractualmente aprobados.

## Invariantes que no cambian

- Ownership: Inventory gobierna stock; Promotions cupones; G5 gobierna pedido y pago; G7 emite identidades y grants.
- UUID `operation_id` estable y clave de idempotencia reutilizada en reintentos; `message_id` identifica la entrega individual.
- `order_id` de G5 es texto opaco, nunca un UUID inferido.
- No consumir cupón antes de una reserva **confirmada efectivamente**. No confundir reserva con su admisión HTTP.
- Distinguir creación efectiva de reserva (`inventory.reservation.created` o resultado durable `COMPLETED`) de consumo definitivo del stock (`POST /api/v1/inventario/reservas/{reservaId}/confirmar`). Para Marketplace con cupón: reserva creada → verificar vigencia actual → consumir cupón y esperar `COMPLETED` → procesar pago → confirmar consumo definitivo de stock y esperar su resultado. No confirmar stock antes del cupón ni del pago.
- Como la expiración puede ocurrir sin notificación posterior a la creación, se propone que G5 mantenga una conciliación periódica y durable de pedidos y órdenes de reemplazo con reserva asociada y activa. El GET de estado es la observación autoritativa; G5 conserva el ownership de sus estados de pedido y aplica sus transiciones existentes. G6 no administra estados de pedido. El mecanismo de conciliación no está implementado ni aceptado por G5.
- Restauración de cupón vinculada al consumo confirmado original mediante `consumption_operation_id`; `cancelled_at` original no cambia al reintentar.
- Proteger los datos sensibles, logs y DLQ; accesos solo para identidades autorizadas.
- No cambiar el contrato de Retail offline, Despacho, Marketplace o Chatbot por el mero reemplazo de broker.

### Reconciliación durable G5 ante expiración tardía — propuesta pendiente

G5 debe registrar durablemente cada pareja `order_id` + `reservation_id` al recuperar por HTTP el resultado durable `COMPLETED` de la operación que creó la reserva. En H5 este GET de resultado es el disparador de seguimiento; **no dependerá** de recibir después el evento RabbitMQ H4 `inventory.reservation.created`. El evento H4 permanece histórico/compatibilidad y no es prerrequisito de la propuesta HTTP. El seguimiento también se reconcilia al recuperar el proceso y mediante barrido periódico para pedidos y órdenes de reemplazo M1 aún elegibles. Se vuelven a consultar tras timeout, pérdida de respuesta, resultado terminal inesperado y antes de cada acción irreversible. El GET no entrega notificación espontánea ni despierta automáticamente a G5.

Cada barrido usa lease/claim durable con vencimiento, checkpoint por reserva, backoff y reanudación tras caída; un error o `5xx` no se interpreta como reserva vigente ni como expirada. El worker persiste `next_check_at`, último estado observado y motivo de reintento; aplica cuotas/backoff para no martillar Inventory. La clave idempotente de conciliación deriva de la reserva, estado observado y transición G5 pretendida; una restricción/lock por pedido-reserva evita dos workers concurrentes. Releer el mismo estado no vuelve a emitir la misma transición.

Elegibles: reserva asociada al pedido/orden que G5 aún deba conciliar con el estado comercial existente. Ambos estados son casos de expiración: (a) `ACTIVA` con vigencia efectiva `VENCIDA` (`expires_at <= observed_at`), y (b) `EXPIRADA` persistida, que puede haber sido materializada entre dos barridos por el `ReservationExpirationService` real de Inventory. `EXPIRADA` solo se excluye cuando G5 ya registró durablemente la decisión/transición correspondiente o cuando el estado comercial vigente determina que esa transición no corresponde; no se excluye por el mero estado de Inventory ni por un barrido/GET exitoso. `CONSUMIDA` y `LIBERADA` se procesan de acuerdo con el estado final y las reglas existentes, no como expiración. Pedidos pagados/anulados/cancelados solo se cierran si la transición existente de G5 así lo dispone. Para Marketplace, expiración antes del pago impide cupón/pago y activa la transición G5 existente de anulación; si el cupón ya se consumió, se usa la restauración existente solo cuando la regla de cancelación G5 lo determine, con identificadores y `cancelled_at` estables. Si el pago compite, serializar la decisión en G5, volver a consultar vigencia justo antes del pago y no iniciar cobro con reserva vencida; si ya hubo pago/consumo, no retroceder el estado ni inventar compensación, aplicar el procedimiento comercial existente y escalar incongruencias.

Una lectura HTTP exitosa de Inventory solo aporta observación. El seguimiento permanece abierto hasta que G5 persiste durablemente la decisión/transición aplicable (incluida la decisión explícita de no transición según estado comercial) y su clave idempotente/resultado de conciliación. Fallos antes de ese commit mantienen la reserva elegible para otro barrido; no se marca conciliada anticipadamente.

La orden de reemplazo es una orden propia de G5, sin cobro: se concilia de forma independiente; si su reserva vence o se rechaza antes del consumo, M1 ejecuta su transición existente de anulación y, cuando corresponda, crea una nueva orden con otra reserva. Al sellar el paquete, solicita `/confirmar`, espera el resultado definitivo y solo entonces solicita despacho. Chatbot conserva su acuerdo vigente de consultas comerciales bajo demanda y no adquiere reserva, pago, ni confirmación de stock por esta propuesta; cualquier checkout que delegue a Ventas sigue el flujo/ownership contractual de G5.

Homologación bilateral mínima: G5 y G6 acuerdan propietario y persistencia de la relación pedido-reserva, eventos/resultado que inician seguimiento, estados elegibles y exclusiones, período/backoff/SLO de barrido, scopes y allowlist G7 del GET, respuesta ante expiración y carreras, claves idempotentes, reglas de restauración de cupón, observabilidad/replay, pruebas de caída y de concurrencia, y criterios para reconciliar sin duplicar anulación/pago. Hasta registrar la aceptación, es una propuesta; no afirma implementación ni aprobación G5.

## Requisitos de aceptación

1. Mapeo completo de 40 mensajes del AsyncAPI H4 a: interno activo, interno por habilitar, externo reemplazado por HTTP, histórico/no aplicable.
2. Topología Basic y autorizaciones sin privilegios amplios; prueba negativa de emisores/consumidores cruzados.
3. Al menos un flujo real G6→G6 y uno G5→G6→resultado HTTP sin simulaciones, con SHA, versión de contratos, entorno y credenciales de prueba.
4. Prueba de caída broker con outbox persistente; duplicación, retraso, orden de agregados, reintento y recuperación de DLQ.
5. Carga Bulk de hasta 1 MiB del contrato previo: diseño compatible 256 KB o transporte de referencias, sin truncamiento silencioso.
6. Costos y cuotas verificadas en región/suscripción reales antes de aprovisionar.
7. Firma documental de propietarios G5/G6 y cambios de scopes aprobados por G7 antes de retirar el acceso AMQP anterior.

## Decisiones alternativas descartadas por ahora

- Exponer Service Bus directamente a G5: obliga a administrar credenciales, red, SDK, acoplamiento y despliegues cruzados.
- Reescribir todos los eventos como HTTP síncrono: pierde desacoplamiento interno y recuperación.
- Standard inmediatamente: más sencillo para pub/sub, pero cargo base; revaluar con carga real.
- Usar solo Storage Queue: simplifica precios, pero no resuelve por sí solo fan-out ni la semántica de integración existente.

## Referencias normativas históricas (no modificar destructivamente)

- `contratos/historico/h4/eventos/asyncapi.yaml` — AsyncAPI H4 histórico 0.6.0-rc.4. El canónico H5 es `contratos/eventos/asyncapi.yaml` 0.7.0-rc.1, `SEMIFINAL_G6`, sin homologación externa presumida.
- `contratos/eventos/rabbitmq-topologia.md` — topología observada H4.
- `integraciones/ACUERDO_G5_G6_H4_2026-10-21.md` — decisiones D-01–D-04, homologación parcial de acceso AMQP.
- `arquitectura/decisiones/ACUERDOS-INTEGRACION-INTERNA-G6-H4.md` — INT-01–13.

## Referencias del proveedor

- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-premium-messaging
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-managed-service-identity
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/overview-emulator
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-resource-manager-exceptions
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/message-expiration
