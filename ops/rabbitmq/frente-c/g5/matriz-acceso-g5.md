# Matriz de acceso G5 — RabbitMQ compartido

**Alcance:** ACL observada durante la provisión G5 del 2026-10-15, derivada entonces de una instantánea histórica AsyncAPI `0.6.0-rc.3`. El contrato canónico vigente de `master` es [`asyncapi.yaml`](../../../../contratos/eventos/asyncapi.yaml), `0.6.0-rc.2`; la instantánea histórica permanece en el historial de PR #98, commit [`184d0be`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/184d0be54cb28b8178cba920e59c544c198348e4/contratos/eventos/asyncapi-0.6.0-rc.3-g5-candidate.yaml). **Estado externo:** aceptación técnica reportada por Marco; homologación y adaptación D-02 pendientes. **Runtime:** `g5_ventas` y `g5_tunnel` aprovisionados y probados desde la PC administrativa; no probado desde una PC G5. La cuenta SSH grupal y una clave Ed25519 compartida implican baja/rotación de todo el equipo y no dan atribución criptográfica por integrante. Esta matriz es evidencia ACL histórica, no una fuente contractual vigente.

| Identidad | `configure` | `read` | `write` de recurso | Topic write permitido | Topic read | Admin | Estado |
|---|---|---|---|---|---|---|---|
| `g5_ventas` | denegado (`^$`) | solo `po.ventas.q` | solo `po.comandos.x` | `promotions.coupon.consumption.requested`; `promotions.coupon.restoration.requested` | denegado (`^$`) | sin tags | implementada; smoke central PASS |

Quedan denegados: las demás colas y exchanges, `amq.default`, `po.eventos.x`, `po.resultados.x`, `po.sin-ruta.x`, `po.reintentos.x`, `po.fallidos.x`, colas `.reintentos`/`.fallidos`, configuración de topología, purge de colas ajenas, administración y management API. No se otorga permiso de publicación por exchange sin los topic permissions exactos. No se crea una identidad Postventa: rc.3 no define un productor distinto que la justifique. No se alteraron los nueve usuarios ni ACL G6.

**Límite inherente del modelo RabbitMQ:** el permiso `read` sobre la cola propia permite también `basic.get`/consumo y `queue.purge` de esa misma cola. RabbitMQ no ofrece una ACL para permitir lectura y denegar purge por separado. No se concede lectura sobre otras colas; el smoke no ejecuta `purge` y se debe comunicar esta capacidad inherente antes de la homologación.

## Matriz de aceptación necesaria de G5

G5 debe dejar aceptación explícita y versionada que confirme:

1. RabbitMQ compartido, vhost `g6-productos-ofertas` y endpoint lógico via túnel local `127.0.0.1:5673` → Oracle `127.0.0.1:5672`.
2. Exchanges `po.comandos.x` (topic) y cola propia `po.ventas.q` (quorum), su binding y nombres físicos rc.3.
3. Usuario técnico único `g5_ventas`, sin administración y con ACL exacta de esta matriz.
4. Las dos routing keys de cupones, sus payloads/sobre rc.3, correlación, publisher confirms y comportamiento del consumidor G5.
5. Compatibilidad de despliegue: servicios de Ventas/Postventa se ejecutan en PCs G5 y usan el túnel local `127.0.0.1:5673`. Ningún servicio G5 se despliega en Oracle.
6. Aceptación del login SSH y clave Ed25519 compartidos `g5_tunnel`, los destinatarios nominales de paquetes independientes, la custodia de la clave y que una revocación requiera rotar el acceso para todo G5. La cuenta está restringida al forwarding local a `127.0.0.1:5672`.
7. Aceptación de que retry/DLX y cualquier cola derivada no forman parte de esta provisión.

La aceptación funcional previa de eventos, si se cita, no cubre por sí sola cambio de endpoint, nombres físicos, credenciales ni permisos RabbitMQ. La VM operativa del Frente C tampoco constituye aceptación de G5.
