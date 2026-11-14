# ADR-H5 — Azure Service Bus Basic como mensajería interna de G6

**Estado:** `PROPUESTA_G6_PENDIENTE_REVISION` — no es una decisión externa homologada ni una implementación.
**Alcance:** Hito 5, ocho microservicios G6, API Gateway y fronteras con G1–G7.
**Fecha del borrador:** 2026-11-14.
**Reemplaza operativamente, tras corte aprobado:** RabbitMQ en la infraestructura G6; **no** elimina los acuerdos ni evidencias H4.

## Contexto y decisión propuesta

G6 migra backend a Azure y necesita mensajería asíncrona operable con bajo costo sin trasladar la administración del broker a otros grupos. Se propone:

1. **Azure Service Bus Basic** como intermediario exclusivamente interno de G6. Un namespace por ambiente con colas duraderas preaprovisionadas.
2. **G1–G5 y G7** acceden a G6 por endpoints HTTP autenticados en API Management/Gateway G6. No se entregan cadenas de conexión, secretos SAS ni permisos directos de Service Bus a módulos externos.
3. **G5 Ventas/Postventa** reemplaza su publicación/consumo directo RabbitMQ por llamadas HTTP de admisión de operación y lectura del resultado durable. Esto requiere acuerdo bilateral antes del corte.
4. Se conserva el dominio de contratos de negocio (`message_id`, `operation_id`, `correlation_id`, tipo, versión, datos), pero el enrutamiento físico RabbitMQ deja de ser norma del transporte futuro.
5. Se garantiza **at-least-once** e **idempotencia de efectos**, no exactly-once del broker.

Esta ADR **no autoriza** por sí sola despliegues, merges, eliminación de RabbitMQ, activación de cupones, cambios unilaterales en API externas ni declaraciones de homologación G5/G7.

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

Basic tampoco permite configurar `DefaultMessageTimeToLive` en la cola. La expiración de reservas es una regla de negocio de Inventory basada en `expires_at` persistido y un mecanismo interno durable; no debe delegarse al TTL del mensaje.

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
- Restauración de cupón vinculada al consumo confirmado original mediante `consumption_operation_id`; `cancelled_at` original no cambia al reintentar.
- Proteger los datos sensibles, logs y DLQ; accesos solo para identidades autorizadas.
- No cambiar el contrato de Retail offline, Despacho, Marketplace o Chatbot por el mero reemplazo de broker.

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

- `contratos/eventos/asyncapi.yaml` — candidata 0.6.0-rc.4 H4.
- `contratos/eventos/rabbitmq-topologia.md` — topología observada H4.
- `integraciones/ACUERDO_G5_G6_H4_2026-10-21.md` — decisiones D-01–D-04, homologación parcial de acceso AMQP.
- `arquitectura/decisiones/ACUERDOS-INTEGRACION-INTERNA-G6-H4.md` — INT-01–13.

## Referencias del proveedor

- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-premium-messaging
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-managed-service-identity
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/overview-emulator
