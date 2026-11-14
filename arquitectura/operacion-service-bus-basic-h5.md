# Operación y seguridad Service Bus Basic — H5 (propuesta)

**Estado:** guía candidata; no se han creado recursos Azure ni se acreditan grants o E2E.

## Provisionamiento y configuración

- Elegir región Azure que albergue backend G6; medir egress por tráfico cross-region. Presupuestar namespace Basic, operaciones, salida de datos, logs/monitorización, almacenamiento y API Management por separado.
- Aprovisionamiento declarativo (Bicep/Terraform) en identidad CI de infraestructura; runtime sin permisos para crear/eliminar colas.
- Nombre de namespace, region, SKU, colas, límites, delivery count y roles parametrizados por ambiente; proteger secretos y estados IaC.
- Configuración de backend: `MESSAGING_PROVIDER=AZURE_SERVICE_BUS` y `SERVICE_BUS_NAMESPACE_FQDN=<namespace>.servicebus.windows.net` son nombres **propuestos**, no variables existentes.
- SDK Node: `@azure/service-bus` y `@azure/identity`. Reutilizar instancias de cliente. No pasar URL `amqps://` a `amqplib`.
- La identidad runtime preferente es Managed Identity o workload identity aislada por servicio; RBAC al nivel de cola (`Data Sender`, `Data Receiver`). Si los ocho servicios comparten identidad, no prometer aislamiento de procedencia por servicio.

## Modos de falla y disposición

| Caso | Resultado obligatorio |
|---|---|
| Service Bus indisponible al publicar | Outbox permanece pendiente, sin pérdida de operación aceptada |
| Confirmación de envío ambigua | Reenviar mismo `MessageId` y procesar idempotentemente |
| Caída del consumidor antes de commit | Mensaje se entrega de nuevo; no hay efecto parcial irreversible |
| Commit realizado pero `completeMessage` falló | Inbox evita repetir el efecto |
| Payload inválido / contrato desconocido | Rechazo controlado con evidencia y DLQ o disposición duradera; sin bucle infinito |
| Dependencia SQL caída | Reintento acotado, recuperación y alerta |
| `MaxDeliveryCount` alcanzado | Mensaje movido a subcola DLQ de esa cola; intervención/replay autorizado |
| Evento tardío/orden invertido | Control de versionado/invariantes por agregado en el dominio |
| Indisponibilidad superior al TTL máximo Basic (14 días) | Outbox/operación SQL siguen siendo fuente durable; no depender de que el mensaje siga en cola. Reconciliar operación e Inbox, y reenviar solo operaciones sin efecto terminal confirmado mediante replay autorizado con la misma identidad funcional e idempotencia |

Basic no permite configurar `DefaultMessageTimeToLive`; su TTL máximo/default de mensaje es 14 días. La expiración de mensajes y la expiración comercial de reservas son conceptos distintos. Inventory conserva la transición comercial mediante su `ReservationExpirationService` existente, que opera sobre `expires_at`; no se crea otro worker de expiración. Si una reserva venció comercialmente, no se reenvía un comando de pago/consumo aunque el registro todavía muestre `ACTIVA`. Probar la semántica de expiración y disposición/DLQ en Azure real; el emulador no sustituye autenticación ni persistencia entre reinicios.

### Cola y flujo HTTP de Promotions

La cola candidata `g6.promotions.commands` recibe solo envíos del relay Outbox del adaptador HTTP interno de `promotions-svc` y solo la consume su worker de operaciones. No se otorga acceso al broker a G5. La admisión HTTP escribe operación e intención Outbox de forma atómica; el relay envía y confirma por entrega; el worker aplica Inbox e idempotencia dentro de su transacción SQL, persiste resultado terminal y luego completa el mensaje. El GET HTTP lee ese resultado durable.

En caída prolongada o TTL vencido: retener operación y Outbox en SQL; comparar cada entrega con Inbox y estado/resultado de operación; marcar solo efectos terminales verificables como completos; clasificar casos ambiguos para conciliación del owner; reenviar operaciones elegibles solo mediante proceso autorizado, con la misma clave funcional e idempotencia. No reemitir ciegamente pagos, consumos o restauraciones ni crear un nuevo `operation_id` para averiguar el resultado.

## Observabilidad

Etiquetas: `operation_id`, `message_id`, `correlation_id`, productor lógico, destinatario, nombre del mensaje, `schema_version`, estado outbox/inbox, intento, duración. No registrar payload completo de comprador o credenciales.

Métricas y alertas: edad y tamaño del outbox, mensajes activos/consumidos/reintentados/DLQ, latencia HTTP 202→resultado terminal, caídas de consumidor, throttling/errores del broker, rechazos de JWT/allowlist. Fijar umbrales después de baseline de carga, no inventarlos.

## Manual seguro DLQ

1. Identificar cola, mensaje, razón, operación, evidencia y dueño del dominio.
2. Determinar si ya hubo efecto de negocio (inbox/operación); nunca reejecutar ciegamente.
3. Corregir causa, versionar migración de esquema si corresponde y aprobar replay.
4. Reinyectar conservando identidad funcional/correlación; registrar operador y cambio.
5. Confirmar resultado e idempotencia; eliminar DLQ original solo mediante proceso auditado.

## CI/CD y pruebas

- Unitarias con transport adapter mock y persistencia de repositorio probada; pruebas negativas de estados.
- Emulador Docker para integración local limitada: no usarlo como evidencia de Entra/RBAC, redes privadas, métricas Azure, WebSockets, DR ni durabilidad en reinicios del propio emulador.
- Suite con Azure real para SDK + identidad + permisos + colas + DLQ, segregada de CI rápida, con cleanup controlado y costos presupuestados.
- E2E G5/G6: backend Java real HTTP → APIM/Gateway → Promotions/Inventory → Service Bus → Inbox → GET; sin simulación.
- Performance separada: throughput, tasa 429, p95 de admisión y p95 de finalización, crecimiento de outbox, consumidores concurrentes; límites de aceptación definidos por equipo.

## Reversión

No hacer dual-write en ambos brokers por defecto, pues puede duplicar efectos. Antes de corte: snapshot de despliegue, inventario de productores, outbox/inbox, colas pendientes y capacidad de recuperar operaciones. Corte por integración, drenar o reconciliar mensajes, comprobar duplicados y mantener rollback del código solo si preserva el contrato; nunca borrar colas con mensajes ni RabbitMQ previo sin aprobación/backup y prueba.

## Fuentes

- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-managed-service-identity
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/overview-emulator
- https://learn.microsoft.com/en-us/azure/well-architected/service-guides/azure-service-bus
