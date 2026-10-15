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

La ejecución histórica completa de 10 escenarios fue **9 PASS / 1 FAIL** en RabbitMQ 4.2.9. El fallo permanece registrado como **`RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`**: el rechazo normal llegó a DLQ, pero el mensaje no se observó tras vaciarla dentro de una ventana de 60 s. Esa ventana fue un timeout de observación de la fixture, **no una garantía de recuperación de RabbitMQ**. Antes de concluir el caso se deben comprobar por separado la retención del mensaje en la fuente, el rechazo efectivo del destino y la entrega posterior al restaurar capacidad. No aumentar el timeout ni reintentar indefinidamente para forzar PASS.

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
