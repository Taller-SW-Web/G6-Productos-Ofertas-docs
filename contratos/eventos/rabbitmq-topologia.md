# Topología RabbitMQ — Productos y Ofertas

**Contrato ejecutable:** [AsyncAPI](asyncapi.yaml), candidata `0.6.0-rc.3`. **Estado:** infraestructura base observada históricamente en Oracle el 2026-10-19; homologación externa pendiente; despliegue y conectividad no acreditados.

## 1. Alcance de la reconciliación

La auditoría reportó RabbitMQ 4.2.9, vhost `g6-productos-ofertas`, cuatro exchanges base, diez colas de aplicación y una cola operativa, todas quorum y durables, y 57 bindings observados. Se conservan exactamente el vhost, el conjunto de 40 mensajes/canales, operaciones, productores, consumidores, payloads, esquemas y routing keys comerciales de `0.6.0-rc.2`. `0.6.0-rc.3` modifica referencias físicas de topología base y los metadatos documentales correspondientes.

La observación es histórica y no acredita estado actual del servidor, homologación bilateral, permisos completos, conexión AMQP, entrega, ACK, despliegue ni E2E. Las definiciones individuales de los 57 bindings no están disponibles; por ello la correspondencia binding a binding permanece `PENDIENTE_VERIFICACION`, aunque el conteo del candidato coincida. Véase la [matriz de compatibilidad](compatibilidad-rabbitmq-oracle.md).

## 2. Exchanges base

| Nombre físico | Tipo | Durabilidad | Observación |
|---|---|---|---|
| `po.comandos.x` | topic | durable | Observado |
| `po.eventos.x` | topic | durable | Observado |
| `po.resultados.x` | topic | durable | Observado |
| `po.sin-ruta.x` | fanout | durable | Observado |

Las tres exchanges de mensajes de negocio declaran `po.sin-ruta.x` como alternate exchange. `mandatory=true`, `basic.return` y publisher confirms son señales separadas: una ruta al alternate exchange cuenta como enrutada; si tampoco hay ruta alternativa, se genera `basic.return`. Un publisher confirm acredita la confirmación del broker respecto de la publicación, no la recepción ni el ACK del consumidor.

## 3. Colas base observadas

Las diez colas principales y la cola operativa observada son quorum y durables. `po.sin-ruta.q` se reserva para operación/diagnóstico y no pertenece a un contexto comercial. La lista de servicios, routing keys contractuales y permisos observados se mantiene en la [matriz de compatibilidad](compatibilidad-rabbitmq-oracle.md).

| Cola física | Uso contractual | Estado |
|---|---|---|
| `po.catalogo.q` | Catálogo | Observada |
| `po.pasarela.q` | Pasarela/BFF | Observada |
| `po.promociones.q` | Promociones | Observada |
| `po.combos.q` | Combos | Observada |
| `po.inventario.q` | Inventario | Observada |
| `po.precios.q` | Precios | Observada |
| `po.auditoria-precios.q` | Auditoría de precios | Observada |
| `po.ventas.q` | Consumidor externo Ventas G5 | Observada |
| `po.taxonomia.q` | Taxonomía | Observada |
| `po.masivos.q` | Operaciones masivas | Observada |
| `po.sin-ruta.q` | Captura operativa sin ruta | Observada; no comercial |

## 4. Retry/DLX: diseño candidato bloqueado

**NO APROBADO, NO APROVISIONADO, NO HOMOLOGADO.** `po.retry.x` y `po.dlx.x` conservan los nombres y tipos del diseño candidato; no se traducen ni se agregan recursos físicos. Las colas `<cola>.retry`, `<cola>.dlq` y sus claves técnicas acompañan el nombre reconciliado de la cola principal cuando la referencian, pero siguen sin aprobar ni desplegar. No activar políticas ni permisos runtime.

El gate de recuperación está bloqueado y se conserva el hallazgo `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`. La evaluación aislada que no verificó recuperación no constituye aprobación. Cualquier futura adopción requiere resolver ese gate y utilizar una versión candidata posterior a `0.6.0-rc.3`.

## 5. Estado G5 y permisos

La auditoría reportó históricamente para `g5_ventas`, en `g6-productos-ofertas`: `write` en `po.comandos.x`, `read` en `po.ventas.q` y `configure` denegado. La existencia de la identidad y esos permisos observados no prueba conexión, publicación, entrega, consumo ni aceptación de mensajes. La homologación de nombres, red privada/túnel, identidad y ACL, publisher confirms, ACK, idempotencia y pruebas bilaterales permanece pendiente. No se agregan credenciales ni permisos por esta documentación.

## 6. Referencias

- [Matriz de compatibilidad RabbitMQ Oracle](compatibilidad-rabbitmq-oracle.md)
- [Decisiones de RabbitMQ](../../arquitectura/decisiones/rabbitmq.md)
- [Operación de RabbitMQ](../../arquitectura/operacion-rabbitmq.md)
- [Transición de RabbitMQ](../../integraciones/transicion-rabbitmq.md)

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
