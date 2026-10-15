# Compatibilidad Ventas/Postventa — RabbitMQ rc.3

**Corte:** 2026-10-15 (America/Lima). **Estado interno:** G6 preparó y usó la candidata AsyncAPI `0.6.0-rc.3` para aprovisionar las dos identidades y probar sus límites. **Estado oficial en `master`:** `asyncapi.yaml` sigue en `0.6.0-rc.2`; esta rama adjunta la candidata rc.3 para revisión. **Homologación G5:** aceptación técnica reportada por Marco, sin evidencia documental formal registrada. **Consumidor G5:** no desplegado ni probado como microservicio.

## Fuentes y versión

- Contrato ejecutable de `master`: [`asyncapi.yaml`](../../../../contratos/eventos/asyncapi.yaml), `0.6.0-rc.2`.
- Candidata revisada/usada para el acceso G5 en esta rama: [`asyncapi-0.6.0-rc.3-g5-candidate.yaml`](../../../../contratos/eventos/asyncapi-0.6.0-rc.3-g5-candidate.yaml). Cambia los nombres físicos en español; conserva routing keys, mensajes, payloads y semántica.
- Topología de `master`: [`rabbitmq-topologia.md`](../../../../contratos/eventos/rabbitmq-topologia.md), basada en rc.2. El aprovisionamiento G5 se limitó a los recursos base ya presentes que se corresponden con la candidata rc.3; no cambió la topología ni Compose.
- [`ALINEACION_VENTAS.md`](../../../../integraciones/ALINEACION_VENTAS.md) y [`transicion-rabbitmq.md`](../../../../integraciones/transicion-rabbitmq.md) contienen el contexto funcional/transicional; no se usan como prueba de aceptación externa.
- Procedimiento reutilizado: [`README.md`](README.md) y [`ops/rabbitmq/frente-c/README.md`](../README.md).

## Aceptación y alcance

Marco comunicó el 2026-10-15 que G5 acepta técnicamente rc.3 y autorizó el login RabbitMQ compartido `g5_ventas` y la cuenta SSH grupal `g5_tunnel` con una única clave Ed25519. Se registra como **aceptación reportada por el owner**, no como homologación formal: no se adjuntó acta, correo o referencia externa verificable. La provisión operativa fue ejecutada bajo autorización explícita del owner y no cambia ese estado formal.

No hay consumidor G5 ejecutándose en Oracle. Los microservicios permanecen en las PCs G5 y, cuando se entregue el paquete, usarán el túnel local `127.0.0.1:5673` hacia el listener Oracle `127.0.0.1:5672`. La cuenta SSH compartida reduce la atribución por persona; baja o sospecha de compromiso requiere rotar la clave de todo G5 y reemitir los paquetes.

## Acceso derivado de rc.3

| Operación | Exchange | Routing key | Recurso | ACL aplicada |
|---|---|---|---|---|
| Pedir consumo de cupón | `po.comandos.x` | `promotions.coupon.consumption.requested` | `po.promociones.q` | write/topic permitido |
| Pedir restitución de cupón | `po.comandos.x` | `promotions.coupon.restoration.requested` | `po.promociones.q` | write/topic permitido |
| Leer resultados | `po.resultados.x` | completado/rechazado | `po.ventas.q` | read solo cola propia; no write sobre exchange |

RabbitMQ resource permissions: `configure=^$`, `write=^po\.comandos\.x$`, `read=^po\.ventas\.q$`. Topic permission única sobre `po.comandos.x` con las dos routing keys anteriores y `read=^$`. El usuario no tiene tags, permisos sobre el exchange por defecto, otros exchanges/colas, management API ni recursos retry/DLX.

La autorización `read` sobre `po.ventas.q` incluye `basic.get`, consumo y `queue.purge` sobre esa cola propia. RabbitMQ no separa la capacidad de purge de la lectura; G5 debe confirmar conocimiento de ese límite. El smoke no ejecuta purge. No se creó identidad adicional de Postventa, ya que rc.3 no define otra identidad/productor.

## Evidencia de runtime

El informe reproducible, el ID del smoke y los estados de implementación están en [`evidencia-aprovisionamiento-2026-10-15.md`](evidencia-aprovisionamiento-2026-10-15.md). Resumen: `g5_ventas`/ACL y `g5_tunnel`/política SSH verificados; autenticación, lectura propia, denegaciones, los dos publisher confirms, TTL/estado de colas y reconexión AMQP/SSH pasaron desde la PC administrativa. Pruebas desde PC G5, consumidor funcional, entrega y homologación documental siguen pendientes. Retry/DLX no fue probado ni se declara implementado.

## Confirmación pendiente de G5

G5 debe dejar una respuesta versionada que confirme: (1) rc.3 y los nombres físicos en español, (2) vhost y acceso local por túnel a 5673, (3) `g5_ventas` y permisos de la matriz, (4) los dos comandos y payloads/correlación de rc.3, (5) el límite de purge de su cola, (6) login/clave SSH compartidos y revocación grupal, (7) entrega de copias cifradas a integrantes autorizados, y (8) exclusión actual de retry/DLX. Después habrá que probar conexión e integración del microservicio en una PC G5. Aceptación técnica comunicada no equivale a esa constancia formal.
