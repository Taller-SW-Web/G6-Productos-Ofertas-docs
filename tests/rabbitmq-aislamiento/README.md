# Pruebas aisladas de aislamiento RabbitMQ

Este arnés ensaya la **alternativa A** de `arquitectura/operacion-rabbitmq.md` en un broker desechable RabbitMQ **4.2.9**. No adopta A ni cambia AsyncAPI `0.6.0-rc.2`; un PASS solo acredita el comportamiento de esta fixture en la versión etiquetada, no homologación, implementación productiva o despliegue.

## Ejecución en Windows

Desde este directorio, con Docker Desktop y un contexto Linux funcional, la ejecución predeterminada corre solo el smoke esencial:

```powershell
./run.ps1
```

Las pruebas ampliadas se ejecutan solo al solicitarlas explícitamente:

```powershell
./run.ps1 -Profile extended
```

La comprobación focalizada del gate de recuperación se ejecuta sin lanzar la suite extendida:

```powershell
./run.ps1 -Profile recovery
```

Para la investigación controlada del timeout interno del worker DLX, el runner admite dos perfiles de configuración, siempre sobre brokers desechables y con un límite explícito de observación:

```powershell
./run.ps1 -Profile recovery -RecoveryInterval reduced -ObservationSeconds 60
./run.ps1 -Profile recovery -RecoveryInterval default -ObservationSeconds 240
```

`reduced` monta `advanced.recovery-reduced.config`, que fija solo en esa fixture `dead_letter_worker_publisher_confirm_timeout=5000`. `default` no monta `advanced.config`; el runner consulta el valor efectivo en el nodo con `rabbitmqctl eval` antes del escenario. El perfil focalizado omite `queue_purge()` y exige colas vacías en el volumen nuevo. Un timeout sin evidencia de retención de origen se clasifica `INCONCLUSO`, no `FAIL`.

`./run.ps1 -Profile all` solicita explícitamente ambos perfiles. La ejecución ampliada conserva la incidencia conocida y puede finalizar con error; no se reintenta automáticamente ni se aumenta su ventana de observación.

El script exige el contexto local Docker Desktop `desktop-linux`, comprueba el endpoint de named pipe y confirma que el daemon informa `OSType=linux`; valida la configuración Compose, descarga `rabbitmq:4.2.9-management` y ejecuta solo el perfil seleccionado (smoke esencial por defecto). Siempre intenta limpiar el proyecto. Cada ejecución tiene un nombre Compose aleatorio y propio. `down --volumes --remove-orphans --rmi local` se limita a ese proyecto: contenedores, red interna, volumen de prueba e imagen del runner. La imagen cacheada de RabbitMQ no se borra porque puede ser compartida localmente. El arnés no monta el socket de Docker, no publica puertos al host y no lee `.env`, claves, variables ni credenciales del host.

## Aislamiento y datos de prueba

- El único broker es `rabbitmq:4.2.9-management`; no hay dependencia de Oracle ni del backend.
- Compose crea una red `internal`, no publica puertos y crea un volumen de prueba aislado.
- El vhost es `g6-test`; `bootstrap`, `inventory_test` y `catalog_test` y sus contraseñas son credenciales locales de prueba definidas aquí.
- Inventario y Catálogo son usuarios separados y verificados en el smoke esencial. Cada uno tiene `configure=^$`, `write=^po\.retry\.x$`, `read` exacto de su cola principal y topic `write` exacto y anclado en `po.retry.x`; ninguno tiene acceso de escritura a DLX, exchange por defecto o colas.
- La fixture crea únicamente los exchanges/colas/bindings mínimos para ambos consumidores. Policies exactas por cola configuran quorum `at-least-once`, `overflow=reject-publish`, TTL de 30 s y DLX/routing key broker-managed, sin argumentos DLX hardcoded.
- La importación de definiciones aprovisiona la fixture de forma repetible en el volumen efímero. Las pruebas limpian sus mensajes de prueba antes de cada caso. No usa el backend productivo como fixture.

## Perfiles de prueba

**Smoke esencial (predeterminado):**

1. Publicación permitida por cada identidad en su ruta retry propia.
2. Rechazo de routing keys cruzadas y near-match por topic permissions exactos/anclados.
3. Denegación de lectura cruzada entre Catálogo e Inventario.
4. Denegación de declaración, binding, borrado y administración de policies al runtime.
5. TTL de 30 s con retorno a la cola principal.
6. Rechazo normal con `requeue=false` a la DLQ propia.
7. Publicación runtime al DLX prohibida y dead-lettering del broker permitido.
8. Publicación en exchange por defecto y lectura de recursos ajenos/operativos prohibidas.

En el smoke se verifican las dos cuentas separadas sin `loopback_users.guest = false`; no se modifica la seguridad global del broker para habilitar usuarios de prueba.

**Pruebas ampliadas (`-Profile extended`):** recuperación con DLQ saturada (incidencia abierta), ACK de rechazo de negocio sin DLQ, tres ciclos de retry con mensajes sintéticos y alternate exchange/`mandatory=true`. El ensayo de tres ciclos no ejecuta handlers de `inventory-svc`, Outbox/Inbox ni idempotencia funcional. Un PASS solo acredita transporte de mensajes de prueba.

La ejecución histórica completa de 10 escenarios fue **9 PASS / 1 FAIL** en RabbitMQ 4.2.9. En 2026-10-15, `./run.ps1 -Profile recovery` volvió a ejecutar solo el escenario de recuperación con RabbitMQ 4.2.9 fijado por digest. Se verificó el tipo quorum y las políticas efectivas mediante `rabbitmqctl list_queues`; los publisher confirms mostraron ACK del relleno y del primer sondeo, y NACK del siguiente con la DLQ en `max-length=1` (dos mensajes aceptados, `messages_ready=2`). Esto confirma el exceso permitido por la cola quorum y acredita rechazo real tras los sondeos acotados.

Después, el mensaje original persistente se publicó con `message_id` único, se confirmó y se rechazó con `requeue=false`. Mientras el destino no aceptaba publicaciones, la cola fuente reportó `messages=1`, `messages_ready=0`, con política efectiva `dead-letter-strategy=at-least-once`, `overflow=reject-publish` y DLX/routing esperados. Se recuperó capacidad consumiendo y ACKeando únicamente los dos mensajes de relleno identificados; no se purgó la DLQ. El mensaje original no apareció en el destino durante los 60 s de observación ya existentes: **FAIL**, con cero duplicados observados. La incidencia **`RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`** continúa abierta; el gate de adopción no pasa. Esta ventana no constituye una garantía de recuperación.

El runner registra las políticas/counters, confirms, versión del broker y logs del contenedor sin credenciales; limpia solo el proyecto Compose aleatorio de esta prueba. No aumentar el timeout ni reintentar indefinidamente para forzar PASS.

### Investigación controlada del temporizador DLX — 2026-10-15

#### Corrección de observabilidad de retención

La revisión posterior encontró que el ensayo anterior hacía `basic.get` sobre la fuente después del `basic.reject(requeue=false)`. Esa lectura podía competir con el consumidor interno del DLX y reencolar mediante `basic.nack(requeue=true)` el mensaje identificado; por tanto, no era evidencia válida de retención por el worker. También se sondeaba solo mientras `messages` era `null`, de modo que un primer cero impedía observar una actualización asíncrona posterior. Las corridas anteriores a esta corrección no acreditan retención identificable en origen.

El ensayo corregido confirma que las tres métricas de fuente son cero al inicio; publica y confirma un único `message_id` en la fuente; recibe ese mismo ID y lo rechaza con `requeue=false`; no vuelve a consumir la fuente. Antes de liberar la DLQ consulta `messages`, `messages_ready` y `messages_unacknowledged` cada 5 s durante hasta 20 s, registrando ceros y valores posteriores. El intervalo cubre varias actualizaciones de estadísticas: RabbitMQ recomienda 5 s para observación cercana a tiempo real en desarrollo y desaconseja intervalos menores. Solo acredita retención con `messages=1`, `messages_ready=0` y `messages_unacknowledged=0`. La identidad se atribuye por la secuencia aislada (fuente inicialmente vacía, único publish confirmado, recepción del ID exacto y ningún otro productor o lector), no por un contador agregado aislado.

En RabbitMQ 4.2.9 el total de quorum incluye `rabbit_fifo_dlx:stat`, que suma descartes pendientes y mensajes checked out por el consumidor interno; el quorum overview expone `num_discarded` y `num_discard_checked_out`. Esto explica por qué el total puede ser uno mientras los mensajes listos y los unacknowledged AMQP son cero. Véanse [RabbitMQ 4.2 monitoring](https://www.rabbitmq.com/docs/4.2/monitoring), [rabbit_fifo:messages_total/1 y overview/1 en 4.2.9](https://github.com/rabbitmq/rabbitmq-server/blob/v4.2.9/deps/rabbit/src/rabbit_fifo.erl#L833-L892), [rabbit_fifo_dlx:stat/1 en 4.2.9](https://github.com/rabbitmq/rabbitmq-server/blob/v4.2.9/deps/rabbit/src/rabbit_fifo_dlx.erl#L64-L79) y el comando documentado [`rabbitmq-queues quorum_status`](https://www.rabbitmq.com/docs/4.2/man/rabbitmq-queues.8#quorum_status). Si la Management API no expone las tres métricas requeridas, el gate queda `INCONCLUSO`; no se usa `basic.get` para identificar el retenido. `rabbitmqctl list_queues` es una lectura complementaria de conteos, no una prueba de identidad.

En RabbitMQ 4.2.9, `rabbit_fifo_dlx_worker` lee `dead_letter_worker_publisher_confirm_timeout` como `settle_timeout`; el worker arma un `send_after(SettleTimeout, settle_timeout)` y al vencer intenta `redeliver_and_ack`. El valor efectivo se verifica con `rabbitmqctl eval` en cada corrida. La primera invocación de B no llegó al test porque la Management API devolvió temporalmente la definición de política y las métricas ausentes. Se añadió sondeo de esa definición cada 5 s durante hasta 20 s; B3 sí completó su ventana.

| Corrida | Timeout runtime | Ventana solicitada/completada | Resultado | Evidencia registrada |
|---|---:|---:|---|---|
| A1 — reducida | 5000 ms (`{ok,5000}`) | 60 s solicitados; terminó 2 s después de la primera llegada | **PASS del gate temprano; no cuenta como observación íntegra** | Retención identificada por el gate y llegada del original. Salida detallada truncada; no se usa para afirmar cero duplicados durante 60 s. |
| A2 — repetición previa al arreglo del corte | 5000 ms (`{ok,5000}`) | 60 s solicitados; terminó 2 s después de la primera llegada | **PASS del gate temprano; no cuenta como observación íntegra** | Fuente al inicio `0/0/0`; muestras antes de liberar: `0/0/0` a 0.003 s, `1/0/0` a 5.007 s. Retención identificada. Original llegó 5.091 s después de liberar; 0 duplicados en el corto periodo observado. Fuente seguía `1/0/0` al final de esa corrida. |
| A3 — ventana completa | 5000 ms (`{ok,5000}`) | 60 s / 60 s | **PASS** | Fuente `0/0/0` al inicio; antes de liberar, `0/0/0` a 0.005 s y `1/0/0` a 5.010 s. Inmediatamente tras liberar: `1/0/0`; al completar 60 s: `0/0/0`. El mismo `message_id` llegó en 5.101 s; 0 duplicados observados durante los 60 s. `rabbitmqctl list_queues` al cierre: fuente 0, DLQ 0. |
| B1/B2 — preparación predeterminada | 180000 ms (`{ok,180000}`) | No iniciaron la ventana | **INCONCLUSO / no ensayo** | B2 falló antes de publicar: Management API no expuso `effective_policy_definition` ni contadores. No se atribuye ese resultado al worker. |
| B3 — predeterminado | 180000 ms (`{ok,180000}`) | 240 s / 240 s | **FAIL dentro de la ventana** | Fuente `0/0/0` al inicio; antes de liberar, `0/0/0` a 0.006 s y `1/0/0` a 5.012 s. Inmediatamente tras liberar y al final: `1/0/0`. ACK del relleno, ACK del primer sondeo, NACK del siguiente, ACK de publicación original. El mismo original no llegó en 240 s; 0 duplicados vistos. `rabbitmqctl list_queues` al cierre: fuente 1, DLQ 0. |

A1/A2 terminaron antes de completar la ventana porque el bucle salía dos segundos después de la primera llegada; se corrigió y A3 observó íntegros los 60 s. La actualización tardía `1/0/0` → `0/0/0` de A3 confirma por qué se deben conservar lecturas posteriores y consultar también después de liberar capacidad. B3 mantuvo `1/0/0` durante toda la ventana y el mensaje original no apareció en el destino. A es compatible con recuperación al intervalo reducido; B no se explica solo por el timeout predeterminado, pues no recuperó dentro de 240 s aunque el runtime confirmó 180000 ms. La diferencia está observada, pero no identifica por sí sola la causa del fallo B.

Los confirms de publicaciones normales se reportan separados del comportamiento del worker: las publicaciones filler/probe acreditan saturación y NACK real; la recepción del mismo `message_id` después de liberar capacidad acredita el resultado DLX. En las corridas válidas no se purgó ninguna cola. `FAIL` significa que hubo NACK real, retención identificable previa y el mismo mensaje no llegó dentro de la ventana solicitada; `INCONCLUSO` queda para precondiciones o métricas ausentes. A continúa no adoptada, `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA` continúa abierta y el aprovisionamiento sigue `BLOQUEADO_ESPECÍFICO`. No se adopta una lección aprendida ni se cambia el estado contractual.

La saturación usa sondeos seriales confirmados con límite de ocho, y la recuperación ACKea únicamente rellenos con identidades conocidas; no se purga la DLQ en ese escenario. La fila de `messages_ready` puede exceder `max-length` en quorum, por lo que la política sola no cuenta como evidencia de saturación.

Esta fixture no verifica comportamiento en el broker real, consumidores reales, handlers ni integración G5. Un caso HTTP a Management API verifica que los usuarios sin tags no puedan crear policies.

## Comparación contractual `rc.1` → `rc.2`

La comparación estática entre `94bfec2` (`0.6.0-rc.1`) y AsyncAPI `0.6.0-rc.2` actual encuentra los mismos 40 canales y nombres de mensajes, las mismas operaciones, bindings de canal, exchanges y routing keys. No obstante, **no se deben describir todos los payload schemas como idénticos**: tres mensajes de rechazo cambiaron la referencia de schema en el commit previo `c176960` (Inventario consumo rechazado, Promociones consumo rechazado y Promociones restauración rechazada); `CouponRestorationRequestedData` también incorporó una descripción de transición. Esos cambios preceden a la revisión de vhost y a esta corrección, que no modifica `asyncapi.yaml`; requieren conservarse como antecedente contractual e inspeccionarse/homologarse aparte. Esta comparación no acredita compatibilidad G5.

## Archivos

- `compose.yaml`: servicios, red y volumen desechables, sin puertos publicados.
- `definitions.json`: vhost, identidades, ACL exactas, topic permissions, exchanges, colas, bindings y policy de prueba.
- `rabbitmq.conf`: carga determinística de las definiciones.
- `test_isolation.py`: pruebas AMQP/Management API en perfiles smoke esencial y ampliado.
- `Dockerfile`, `requirements.txt`: runner aislado y dependencias con versiones fijas.
- `run.ps1`: comprobación de daemon Linux, ejecución y limpieza con alcance de proyecto único.

Si el comando de Docker requiere elevación o intervención manual, no se intenta cambiar servicios/configuración del sistema; se registra ese bloqueo y las pruebas runtime quedan **NO EJECUTADAS**. La validación estática de YAML/Python no equivale a ejecución del broker.
