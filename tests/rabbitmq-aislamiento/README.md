# Pruebas aisladas de aislamiento RabbitMQ

Este arnés ensaya la **alternativa A** de `arquitectura/operacion-rabbitmq.md` en un broker desechable RabbitMQ **4.2.9**. No adopta A ni cambia AsyncAPI `0.6.0-rc.2`; un PASS solo acredita el comportamiento de esta fixture en la versión etiquetada, no homologación, implementación productiva o despliegue.

## Ejecución en Windows

Desde este directorio, con Docker Desktop y un contexto Linux funcional:

```powershell
./run.ps1
```

El script exige el contexto local Docker Desktop `desktop-linux`, comprueba el endpoint de named pipe y confirma que el daemon informa `OSType=linux`; valida la configuración Compose, descarga `rabbitmq:4.2.9-management`, ejecuta las diez pruebas y siempre intenta limpiar el proyecto. Cada ejecución tiene un nombre Compose aleatorio y propio. `down --volumes --remove-orphans --rmi local` se limita a ese proyecto: contenedores, red interna, volumen de prueba e imagen del runner. La imagen cacheada de RabbitMQ no se borra porque puede ser compartida localmente. El arnés no monta el socket de Docker, no publica puertos al host y no lee `.env`, claves, variables ni credenciales del host.

## Aislamiento y datos de prueba

- El único broker es `rabbitmq:4.2.9-management`; no hay dependencia de Oracle ni del backend.
- Compose crea una red `internal`, no publica puertos y crea un volumen de prueba aislado.
- El vhost es `g6-test`; `bootstrap`, `inventory_test` y `catalog_test` y sus contraseñas son credenciales locales de prueba definidas aquí.
- Inventario y Catálogo son usuarios separados. Cada uno tiene `configure=^$`, `write=^po\.retry\.x$`, `read` exacto de su cola principal y topic `write` exacto y anclado en `po.retry.x`; ninguno tiene acceso de escritura a DLX, exchange por defecto o colas.
- La fixture crea únicamente los exchanges/colas/bindings mínimos para ambos consumidores. Policies exactas por cola configuran quorum `at-least-once`, `overflow=reject-publish`, TTL de 30 s y DLX/routing key broker-managed, sin argumentos DLX hardcoded.
- La importación de definiciones aprovisiona la fixture de forma repetible en el volumen efímero. Las pruebas limpian sus mensajes de prueba antes de cada caso. No usa el backend productivo como fixture.

## Casos ejecutados

Los nombres y el orden corresponden a los diez escenarios de operación: (1) publish/confirm retry propio de Inventario y Catálogo; (2) rechazo de claves cruzadas y near-match; (3) aislamiento de consumo entre Catálogo e Inventario; (4) denegación de declaraciones/cambios/bindings/eliminación y de administración de policies; (5) retorno TTL medido de 30 s; (6) rechazo final hacia DLQ propia y prueba de recuperación del destino lleno; (7) sin `write` runtime al DLX, con dead-lettering del broker; (8) ACK de un rechazo de negocio sin DLQ; (9) tres retries contados y conservación de IDs/cabeceras antes del DLQ; (10) denegación de exchange por defecto, alternate, DLX, `.retry`, DLQ y cola ajena. El caso 10 también prueba la pareja `mandatory`: un alternate con binding captura el mensaje (confirm, sin return) y si ni la ruta primaria ni alternate tienen binding se observa `basic.return`/`UnroutableError`.

La suite espera hasta 45 s por cada expiración TTL y el escenario 9 recorre tres ciclos; una ejecución completa puede tardar varios minutos. Cualquier fallo deja un estado distinto de cero y no se oculta. En RabbitMQ 4.2.9, los casos 1–5 y 7–10 pasan; el caso 6 verifica el dead-lettering normal, pero falla al no observar la entrega retenida dentro de 60 s tras vaciar la DLQ. La falla mantiene A bloqueada para credenciales runtime hasta investigarla; no representa un PASS ni un resultado de producción. Un caso HTTP a Management API verifica que los usuarios sin tags no puedan crear policies.

## Comparación contractual `rc.1` → `rc.2`

La comparación estática entre `94bfec2` (`0.6.0-rc.1`) y AsyncAPI `0.6.0-rc.2` actual encuentra los mismos 40 canales y nombres de mensajes, las mismas operaciones, bindings de canal, exchanges y routing keys. No obstante, **no se deben describir todos los payload schemas como idénticos**: tres mensajes de rechazo cambiaron la referencia de schema en el commit previo `c176960` (Inventario consumo rechazado, Promociones consumo rechazado y Promociones restauración rechazada); `CouponRestorationRequestedData` también incorporó una descripción de transición. Esos cambios preceden a la revisión de vhost y a esta corrección, que no modifica `asyncapi.yaml`; requieren conservarse como antecedente contractual e inspeccionarse/homologarse aparte. Esta comparación no acredita compatibilidad G5.

## Archivos

- `compose.yaml`: servicios, red y volumen desechables, sin puertos publicados.
- `definitions.json`: vhost, identidades, ACL exactas, topic permissions, exchanges, colas, bindings y policy de prueba.
- `rabbitmq.conf`: carga determinística de las definiciones.
- `test_isolation.py`: diez pruebas AMQP/Management API.
- `Dockerfile`, `requirements.txt`: runner aislado y dependencias con versiones fijas.
- `run.ps1`: comprobación de daemon Linux, ejecución y limpieza con alcance de proyecto único.

Si el comando de Docker requiere elevación o intervención manual, no se intenta cambiar servicios/configuración del sistema; se registra ese bloqueo y las pruebas runtime quedan **NO EJECUTADAS**. La validación estática de YAML/Python no equivale a ejecución del broker.
