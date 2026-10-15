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

Hipótesis H1: la observación histórica de 60 s pudo terminar antes del siguiente reintento del worker. En RabbitMQ 4.2.9, `rabbit_fifo_dlx_worker` lee `dead_letter_worker_publisher_confirm_timeout` como `settle_timeout`; cuando mantiene publicaciones pendientes arma un `send_after(SettleTimeout, settle_timeout)`, y al vencer llama a `redeliver_and_ack`. El código fuente da 180000 ms como valor predeterminado, pero ese mecanismo por sí solo no demuestra cuándo será recuperado un mensaje concreto ni confirma el valor runtime. El runner consulta el valor efectivo con `rabbitmqctl eval` antes de iniciar cada ensayo.

| Ensayo | Valor efectivo observado | Observación | Resultado del gate | Evidencia y límite |
|---|---:|---:|---|---|
| A — reducido | 5000 ms (`rabbitmqctl eval`: `{ok,5000}`) | 60 s | **INCONCLUSO** en ambas corridas | DLQ NACK real después de ACK confirmado del relleno y del primer sondeo. El `message_id` original llegó a la DLQ en 5.186 s y 5.424 s, respectivamente; cero duplicados observados en cada corrida. La Management API no dejó verificar identidad/counters de retención en la fuente antes de liberar capacidad. No se declara PASS. |
| B — predeterminado | 180000 ms (`rabbitmqctl eval`: `{ok,180000}`) | 240 s | **INCONCLUSO** | El mensaje no llegó a la DLQ durante la ventana. Publisher confirms: ACK de relleno, ACK del primer sondeo, NACK del siguiente y ACK del original en la fuente. Cero duplicados observados; estado final: fuente `messages=1`, destino `messages=0`. La retención del original antes de liberar capacidad no fue observable, por lo que no se clasifica FAIL. |

Ambos ensayos válidos usaron RabbitMQ 4.2.9 fijado por digest, las mismas definiciones aisladas y el mismo escenario. La prueba verificó las policies coincidentes/ganadoras y sus definiciones efectivas; se confirmaron las publicaciones y el rechazo real del destino. El perfil focalizado no purgó colas. Una corrida preliminar anterior a la corrección invocó el `setUp()` histórico, que purgaba colas; se excluyó de la comparación.

La evidencia de A es compatible con una demora próxima al timeout reducido. En B no hubo entrega en una ventana de 240 s que cubrió el valor efectivo de 180 s. Sin evidencia de retención en la fuente antes de liberar capacidad, ninguno cumple el requisito de PASS ni el de FAIL. H1 queda plausible, pero no demostrada; no se adopta una lección aprendida afirmativa ni se modifica el estado contractual: Lote 4 permanece en **Caso B**, A sigue no adoptada, `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA` continúa abierta y el aprovisionamiento runtime sigue `BLOQUEADO_ESPECÍFICO`. El siguiente desbloqueo es obtener una señal observable de retención del original en la fuente antes de liberar capacidad.

**Estados del gate:** `PASS` exige NACK real del destino, retención identificable mientras está lleno y llegada posterior del mismo `message_id`; `FAIL` registra que ese mensaje no llegó dentro de la ventana existente de 60 s una vez establecidas esas señales; `INCONCLUSO` se usa si no se puede demostrar una precondición o aparece contenido inesperado; `NO EJECUTADO` se imprime cuando Docker no permite iniciar el perfil. La saturación usa sondeos seriales confirmados con límite de ocho, y la recuperación ACKea únicamente rellenos con identidades conocidas; no se purga la DLQ en ese escenario. La fila de `messages_ready` puede exceder `max-length` en quorum, por lo que la política sola no cuenta como evidencia de saturación.

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
