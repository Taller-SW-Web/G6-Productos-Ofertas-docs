# Topología RabbitMQ — Productos y Ofertas

**Fuente ejecutable:** [AsyncAPI](asyncapi.yaml), candidata `0.6.0-rc.3`. La topología base fue observada históricamente en Oracle el 2026-10-19; homologación, correspondencia de bindings, implementación y estado runtime actual no se acreditan.

## 1. Alcance y recursos base

El vhost candidato es `g6-productos-ofertas`. La observación reportó cuatro exchanges base y once colas, todas durable; las colas son quorum. AsyncAPI declara 56 bindings para las diez colas principales y uno operativo de `po.sin-ruta.x` a `po.sin-ruta.q` con `#`, total 57. La auditoría también enumeró 57 bindings físicos, pero no hay definiciones individuales para comparar cada par exchange/cola/clave: **`PENDIENTE_VERIFICACION`**. Véase la [matriz de compatibilidad](compatibilidad-rabbitmq-oracle.md), que centraliza nombres, operaciones, bindings contractuales, ACL observadas y límites.

Los exchanges base candidatos son `po.comandos.x` (topic), `po.eventos.x` (topic), `po.resultados.x` (topic) y `po.sin-ruta.x` (fanout). Las colas de servicio son `po.catalogo.q`, `po.pasarela.q`, `po.promociones.q`, `po.combos.q`, `po.inventario.q`, `po.precios.q`, `po.auditoria-precios.q`, `po.ventas.q`, `po.taxonomia.q` y `po.masivos.q`; la cola operativa es `po.sin-ruta.q`.

El estado `base-observed-not-homologated` expresa una observación histórica y un contrato candidato. No significa que el recurso siga en el broker, esté provisionado desde esta definición, sea accesible, esté homologado ni que una publicación se haya entregado. Las routing keys siguen siendo los nombres lógicos de mensajes; esta reconciliación no las traduce.

## 2. Publicación, entrega y confiabilidad

- Entrega at-least-once; los duplicados son posibles.
- Usar mensajes persistentes cuando aplique y publisher confirms. Un confirm informa aceptación por el broker, no entrega ni ACK del consumidor.
- Consumidores con ACK manual; confirmar el mensaje solo después de persistir el resultado o completar el efecto idempotente.
- Outbox transaccional vincula cambios de base de datos con publicación eventual. Inbox/deduplicación se aplica antes de efectos secundarios; `message_id` identifica transporte y `operation_id` la idempotencia funcional cuando corresponde.
- Prefetch inicial documentado: `20` por consumidor; cualquier ajuste requiere medición y prueba.
- Con `mandatory=true`, `basic.return` indica que no hubo ruta ni en el alternate exchange. Si el alternate captura el mensaje, se considera enrutado y no hay `basic.return`. Observar retornos y publisher confirms como señales distintas.

La matriz de operaciones por productor/consumidor está en [compatibilidad RabbitMQ Oracle](compatibilidad-rabbitmq-oracle.md); no se replica aquí.

## 3. Rechazos de negocio y flujo Retry/DLX candidato

Un rechazo de negocio válido se ACKea y, si el contrato define resultado, se publica ese resultado. No se convierte en error técnico ni DLQ por sí solo. Ejemplos de rechazo funcional son stock insuficiente, cupón sin cupo o reserva no activa.

El diseño previo describe para fallos técnicos transitorios hasta tres reintentos de aplicación con intervalo candidato de `30 s`, una cola `.retry` por principal y DLQ al agotar intentos. Los detalles de identificadores técnicos deben referenciar el nombre reconciliado de la cola principal. Esto es **diseño histórico/candidato**, no flujo actualmente aprobado ni configurado.

**Estado actual del diseño Retry/DLX: NO APROBADO, NO APROVISIONADO, NO HOMOLOGADO; gate BLOQUEADO.** `po.retry.x` y `po.dlx.x` conservan nombres y tipos candidatos `direct`; no se traducen, no se crean recursos, no se activan políticas ni se conceden permisos runtime. A/B/C no se adoptan. Se conserva `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`: el ensayo focalizado histórico observó retención/NACK bajo saturación, pero no la recuperación posterior dentro de la ventana y terminó **FAIL**. No afirmar que las pruebas Retry/DLX pasaron.

El gate exige explicar y repetir la recuperación bajo capacidad llena/indisponibilidad, validar TTL, límite de intentos, ausencia de ciclos y duplicados, permisos efectivos, persistencia, Outbox/Inbox e idempotencia. Las pruebas aisladas no demostrarían por sí solas comportamiento de handlers reales ni E2E. Toda futura adopción requiere una versión candidata posterior a `0.6.0-rc.3`.

## 4. Mensajes sin ruta y aceptación

Los exchanges base usan `po.sin-ruta.x` como alternate exchange. El binding operativo `po.sin-ruta.x` → `po.sin-ruta.q` usa fanout y clave `#`; la cola no es un consumidor comercial. Una publicación sin binding principal que llega a esa cola no produce `basic.return`; una prueba aislada sin binding alternate debe producir `basic.return` con `mandatory=true`. Deben observarse también los publisher confirms, por separado.

La aceptación contractual estática comprueba referencias y bindings declarados. Las pruebas runtime futuras, en entorno aislado, cubren ambos caminos (alternate captura / alternate sin ruta), permisos autorizados/denegados, publicación confirmada, consumo/ACK, duplicación/idempotencia y alertas. No alterar topología productiva para simular el caso sin alternate.

## 5. Seguridad, permisos y declaraciones

Las ACL observadas en octubre por identidad, el alcance de recurso requerido por operaciones y diferencias pendientes están en la [matriz de compatibilidad](compatibilidad-rabbitmq-oracle.md). Las ACL de recurso `configure`/`write`/`read` no sustituyen topic permissions: la auditoría no reporta topic permissions y no deben inferirse desde `write`.

La identidad de aprovisionamiento declara vhost, exchanges, colas, bindings, argumentos y políticas autorizados. La identidad runtime no obtiene `configure`; usa recursos preaprovisionados y solo consume su cola contractual. El flujo de arranque debe probarse antes de conceder credenciales: una declaración activa requiere `configure`; una declaración pasiva en RabbitMQ 4.2.7+ requiere algún permiso aplicable al recurso. `basic.consume` requiere `read` sobre la cola. En una cola declarada con DLX, RabbitMQ verifica `read` de la cola y `write` del DLX durante la declaración; el aprovisionador, no el runtime, satisface las autorizaciones de creación.

Las pruebas de autorización positivas y negativas, incluyendo topic permissions exactos, lectura cruzada, `configure`, exchanges compartidos, exchange por defecto y rutas laterales, son gates de operación descritos en [Operación de RabbitMQ](../../arquitectura/operacion-rabbitmq.md). No son permisos concedidos ni resultados de runtime de este candidato.

## 6. Cambios de infraestructura, respaldo y reversión

No se deriva una orden de modificar recursos del broker desde esta topología. Una operación futura requiere diff declarativo revisado, inventario reciente de recursos y bindings, identificación de mensajes pendientes, aprobación de owners, backup protegido y restauración ensayada en aislamiento. JSON de definiciones no contiene mensajes; restaurar definiciones no mueve mensajes entre vhosts.

No cambiar tipos in-place, purgar ni recrear colas con mensajes. Ante fallo, detener nuevos publishers del lote, estabilizar consumidores y reconciliar mensajes confirmados/no confirmados, pendientes y duplicados. Revertir solo con compatibilidad demostrada y ensayo de consistencia que evite perder o repetir efectos funcionales. Cualquier recuperación se documenta con versión del broker, SHA, entorno, tiempo y limitaciones.

## 7. Referencias

- [Matriz de compatibilidad RabbitMQ Oracle](compatibilidad-rabbitmq-oracle.md)
- [Decisiones de RabbitMQ](../../arquitectura/decisiones/rabbitmq.md)
- [Operación de RabbitMQ](../../arquitectura/operacion-rabbitmq.md)
- [Transición de RabbitMQ](../../integraciones/transicion-rabbitmq.md)

## Addendum contractual 0.6.0-rc.1 — Cuatro bloqueantes G6

**Histórico: decisión interna aprobada; objetivo `0.6.0-rc.1` (no desplegado).**

- `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- `POST /inventario/reservas`, `/confirmar` y `/liberar` responden `202` solamente cuando aceptan el comando. El éxito o rechazo se determina por resultado persistido y evento.
- Nuevos contratos provisionales: `GET /inventario/operaciones/{operationId}` (solo Ventas; scope `inventario:operaciones:leer`) y `POST /inventario/disponibilidad/comercial/verificar` (canales, consulta sin efectos).
- Nuevo evento `inventory.reservation.rejected`; resultados de reserva/consumo/liberación/expiración con datos tipados y correlación obligatoria.
- `D-INV-01`: no se suman saldos de ubicaciones independientes por defecto. Un canal obtiene `INDETERMINADO` cuando el punto único de cumplimiento no se puede resolver. `SUFICIENTE` exige una fuente de abastecimiento realizable para la cantidad completa; no supone reserva.
- Cupones: después de reserva confirmada, Ventas envía `reservation_id` y `commercial_snapshot_ref` al solicitar consumo. Los resultados de consumo se tipan y la restauración se vincula a la operación previamente consumida.
- Misma identidad/operación/payload semántico => mismo resultado y cero efectos nuevos; identidad reutilizada con payload distinto => `IDEMPOTENCY_CONFLICT`. Los eventos tienen `message_id` propio para deduplicación de transporte.
- Las transiciones pagar/expirar/liberar se serializan por reserva; se respeta `expires_at` emitido por Inventario.
- Estos contratos siguen **provisionales** hasta que la implementación, migraciones y pruebas integradas sean verificadas. No anunciar disponibilidad real antes del cierre.
