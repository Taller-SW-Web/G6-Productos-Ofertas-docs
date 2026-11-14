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

Basic no permite configurar `DefaultMessageTimeToLive`; no apoyar la expiración de reservas en TTL de mensajes. Inventory debe detectar el vencimiento desde su dato durable `expires_at` y emitir cualquier evento interno mediante outbox. La expiración de mensaje y la expiración comercial son conceptos distintos. Probar la semántica de disposición/DLQ en Azure real; el emulador no sustituye autenticación ni persistencia entre reinicios.

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
