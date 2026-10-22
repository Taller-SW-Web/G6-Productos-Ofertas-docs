# Operación de RabbitMQ

**G6 — Productos y Ofertas**  
**Estado:** guía objetivo de operación, aún no ejecutada  
**Vhost objetivo:** `g6-productos-ofertas`  
**Vigencia contractual:** hasta una actualización homologada rigen los nombres de [AsyncAPI](../contratos/eventos/asyncapi.yaml) y de [la topología actual](../contratos/eventos/rabbitmq-topologia.md).

Esta guía concreta las [decisiones de RabbitMQ](./decisiones/rabbitmq.md). Es un procedimiento operativo: **no es evidencia de que las tareas estén realizadas**.

## 1. Inventario de partida y límites

El diagnóstico de solo lectura del 14 de octubre de 2026 registró:

| Elemento | Evidencia en ese corte |
|---|---|
| Plataforma | Ubuntu/Oracle Cloud, contenedor `g6-po-rabbitmq-1`, RabbitMQ 4.2.9 |
| Estado | Broker saludable, un nodo, sin alarmas observadas |
| Vhost disponible | `g6` (el `/` no existía en el corte) |
| Usuarios | `g6_admin` y `g6_backend`, ambos con permisos amplios sobre `g6` |
| Exchanges de negocio | Ninguno |
| Colas / bindings | Ninguno |
| Red interna | `g6-po_g6_backend`; únicamente RabbitMQ conectado |
| AMQP | Puerto del contenedor sin publicación observada en el host |
| Panel de gestión | Asociado a `127.0.0.1:15672` del host |
| Persistencia | Volumen Docker `g6-po_rabbitmq_data` |
| Copias de seguridad | No demostradas en los directorios revisados; existen antecedentes de JSON/GPG cuya ubicación y restaurabilidad se deben verificar |

Los datos anteriores **no** prueban estado actual, conectividad desde OCI, preparación de usuarios externos, copias completas ni recuperación.

La auditoría histórica del 2026-10-19 reportó después RabbitMQ 4.2.9, vhost `g6-productos-ofertas`, cuatro exchanges base, diez colas de aplicación y una operativa, todas las colas quorum/durables, y 57 bindings observados. El candidato declara 56 bindings en colas principales más uno operativo (57 total). Es otro corte temporal; no sustituye la lectura de solo lectura del 14-10 ni demuestra estado actual. Las definiciones individuales no se pueden comparar, por lo que la correspondencia por exchange/cola/clave sigue `PENDIENTE_VERIFICACION`.

Las ACL completas por identidad están transcritas desde la auditoría en la [matriz de compatibilidad RabbitMQ Oracle](../contratos/eventos/compatibilidad-rabbitmq-oracle.md). Son observaciones de octubre, no ACL runtime verificadas hoy.

## 2. Responsabilidades de operación

| Función | Alcance permitido |
|---|---|
| Administración del broker | Gestión excepcional de usuarios, vhosts, configuración y diagnóstico privilegiado |
| Aprovisionamiento | Aplicar topología y políticas autorizadas desde artefactos versionados; no ejecutar lógica de negocio |
| Aplicación G6 | Conectarse, publicar mensajes propios y consumir únicamente su cola asignada |
| Consumidor G5 | Acceder solo al conjunto de recursos acordados con G5; sin administración |
| Operador de monitoreo | Consultar métricas e incidentes mediante acceso de solo lectura cuando sea posible |

Una cuenta runtime no debería poder cambiar topología. Antes de retirar el permiso `configure` se comprobará cómo arranca cada cliente: debe consumir recursos **preaprovisionados**, sin hacer declaraciones activas que requieran permisos elevados.

### Cuentas propuestas

| Aplicación | Identidad observada históricamente (runtime actual no verificado) | Cola principal objetivo |
|---|---|---|
| Taxonomía | `g6_taxonomia` | `po.taxonomia.q` |
| Catálogo | `g6_catalogo` | `po.catalogo.q` |
| Precios | `g6_precios` | `po.precios.q` |
| Auditoría de precios | `g6_auditoria_precios` | `po.auditoria-precios.q` |
| Promociones | `g6_promociones` | `po.promociones.q` |
| Inventario | `g6_inventario` | `po.inventario.q` |
| Combos | `g6_combos` | `po.combos.q` |
| Masivos | `g6_masivos` | `po.masivos.q` |
| Pasarela de API | `g6_pasarela` | `po.pasarela.q` |
| Ventas G5 (externo) | `g5_ventas` | `po.ventas.q` |

Las identidades figuran en la auditoría Oracle del 19/10, pero esta evidencia histórica no acredita que su ACL actual, sus credenciales vigentes o la conexión runtime hayan sido verificadas nuevamente. AsyncAPI `0.6.0-rc.3` refleja nombres base observados, pero no acredita adaptación del código, provisión actual ni homologación G5.

<a id="matriz-rabbitmq-por-aplicacion"></a>

## 3. Matriz física observada y gates

La candidata AsyncAPI `0.6.0-rc.3` reconcilia nombres físicos base. Separa cuatro estados: topología observada históricamente; contrato documental candidato; adaptación de código pendiente; ejecución real no comprobada. La [matriz de compatibilidad](../contratos/eventos/compatibilidad-rabbitmq-oracle.md) relaciona servicios, identidades, colas, operaciones, routing keys, ACL observadas y homologación.

### 3.0 Piloto G5–G6 Hito 4

La decisión G6 para el piloto fija la topología física existente: vhost `g6-productos-ofertas`; exchanges `po.comandos.x`, `po.eventos.x`, `po.resultados.x`; colas `po.ventas.q`, `po.inventario.q`, `po.promociones.q`. G5 accede por túnel SSH local `127.0.0.1:5673`. No se crean aliases ni exchanges paralelos, no se cambia la VM y no se modela coexistencia de recursos ingleses. La candidata de AsyncAPI `0.6.0-rc.3` está en `master` por PR #101.

D-01 (piloto local SSH) tiene aceptación documental G5; Render queda pendiente como conexión independiente. D-02 (nombres físicos españoles rc.3) está adoptada internamente por G6; adaptación y homologación operativa G5 siguen pendientes porque la respuesta de G5 pidió conservar nombres ingleses y no consta ratificación posterior de la lista final. Los nombres documentados y las observaciones históricas no prueban conectividad, grants, bindings actuales, productor/consumidor ni ejecución. El PR #98 requiere reconciliación contra `master` y queda fuera de este encargo. Retry/DLX conserva su gate separado, bloqueado y no aprobado.

### 3.1 ACL observada, ACL contractual y permisos de tópico

La [matriz de compatibilidad](../contratos/eventos/compatibilidad-rabbitmq-oracle.md) contiene `configure`/`write`/`read` observados para las diez identidades, el alcance de recurso derivado de `send`/`receive` de AsyncAPI y las diferencias. Los permisos de recurso y los topic permissions son controles distintos. La auditoría no lista topic permissions; no se infieren de `write`. Estado actual de ACL runtime: no verificado.

Las cuentas runtime no reciben `configure`, `write` sobre `po.retry.x`/`po.dlx.x` ni `read` de colas retry/DLQ o `po.sin-ruta.q`. La identidad separada de aprovisionamiento declara exchanges, colas, bindings y políticas. No se despliega ni concede ACL por esta guía.

### 3.2 Declaraciones y pruebas positivas/negativas de autorización

La topología objetivo se aprovisiona antes del arranque de consumidores. El arranque esperado consume recursos existentes y no declara o modifica recursos con identidad runtime.

| Operación | Declaración pasiva | Declaración activa | Criterio para runtime |
|---|---|---|---|
| Exchange/cola/binding/policy | En RabbitMQ 4.2.7+ requiere al menos algún permiso aplicable al recurso; no equivale a consumo | Requiere `configure`; puede crear recursos o fallar por atributos incompatibles | Runtime no la ejecuta. Verificar el comportamiento real de cada cliente antes de credenciarlo. |
| Consumir cola propia | `basic.consume` requiere `read` sobre la cola | N/A | Positiva solo sobre la cola asignada y preaprovisionada. |
| Publicar mensaje de negocio | N/A | `write` de recurso permite publicar al exchange; en exchanges `topic`, topic authorisation puede limitar routing keys | Positiva para operaciones permitidas; negativa para routing key no autorizada según política topic aprobada. La auditoría no aporta esas ACL topic. |

Pruebas de aceptación futuras, aisladas y con versión de broker/commit registrados:

| Tipo | Intento | Resultado requerido |
|---|---|---|
| Positiva | Publicar por `po.comandos.x`, `po.eventos.x` o `po.resultados.x` solo cuando una operación del productor lo contempla | Permiso de recurso y, si está configurado, topic permission exacto; confirm y routing verificados separadamente. |
| Positiva | Consumir la propia cola preaprovisionada | `basic.consume` permitido con `read`; sin declaración activa runtime. |
| Negativa | Publicar una routing key comercial no autorizada en exchange `topic` | `ACCESS_REFUSED` cuando la topic permission correspondiente esté configurada; comprobar la regla instalada, no inferirla de `write`. |
| Negativa | Consumir cola de otro servicio, `po.sin-ruta.q`, retry o DLQ | Denegado; sin otorgar `read` cruzado para facilitar la prueba. |
| Negativa | Declarar/modificar/borrar exchange, cola, binding o policy desde runtime | Denegado por ausencia de `configure`. |
| Negativa | Publicar directamente a `po.retry.x`, `po.dlx.x`, alternate o exchange por defecto | Mantener bloqueado/no autorizado mientras Retry/DLX no se apruebe. |

Las decisiones de autorización pueden permanecer en caché durante la sesión; revocación/rotación debe probarse con reconexión cuando corresponda. La prueba negativa no se da por aprobada si no se registra la ACL efectiva y el resultado observable.

### 3.3 Retry/DLX — BLOQUEADO, NO APROBADO Y NO APROVISIONADO

`po.retry.x` y `po.dlx.x` se conservan como nombres y tipos candidatos. Las colas derivadas y claves técnicas son diseño no aprobado. A/B/C no se adoptan ni se implementan en esta revisión. No se activan políticas ni permisos runtime.

Se conserva el hallazgo `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`: en el perfil aislado RabbitMQ 4.2.9 del 2026-10-15, una DLQ con `max-length=1` rechazó publicación adicional y la cola fuente retuvo el mensaje original (`messages=1`, `messages_ready=0`). Tras liberar la capacidad ACKeando dos mensajes de relleno identificados, el original no llegó a DLQ dentro de 60 s; ese caso terminó **FAIL**. Esto no prueba la recuperación posterior ni la integración de consumidores reales. No se declara que pruebas retry/DLX hayan pasado. Cualquier futura adopción requiere resolver el gate, repetir la recuperación y tramitar una versión candidata posterior a `0.6.0-rc.3`.

## 4. Aprovisionamiento reproducible

### 4.1 Antes de cualquier modificación

- [ ] Confirmar versión de contrato y revisión de Git.
- [ ] Registrar estado y recursos del broker sin revelar contraseñas.
- [ ] Verificar los respaldos JSON/GPG existentes; conservarlos intactos.
- [ ] Exportar definiciones actuales a ubicación protegida con acceso restringido.
- [ ] Verificar una restauración en ambiente aislado, especialmente si habrá cambios irreversibles.
- [ ] Revisar rutas y versiones de Docker Compose, volúmenes y persistencia.
- [ ] Confirmar conectividad privada y la estrategia TLS para G5, si aplica.
- [ ] Aprobar un diff declarativo de los recursos a crear o modificar.

### 4.2 Aplicación gradual

1. Crear el vhost `g6-productos-ofertas` **sin eliminar `g6`**.
2. Revisar y aprobar por separado el diff de la versión contractual elegida. La candidata `0.6.0-rc.3` usa los nombres base observados en Oracle; su inclusión documental no autoriza aplicar cambios ni acredita homologación. No renombrar ni recrear recursos físicos existentes.
3. Solo tras autorización específica, verificar la topología observada y la correspondencia exacta de cada binding; el conteo contractual es 56 + 1 operativo = 57, pero el reporte Oracle no aporta aquí definiciones individuales. No aprovisionar retry/DLX mientras siga bloqueado.
4. Cargar o generar identidades técnicas mediante un mecanismo protegido de secretos, sin versionar contraseñas ni archivos con hashes reutilizables.
5. Aplicar ACL y permisos de tópico; comprobar accesos autorizados y denegados.
6. Conectar solo una aplicación piloto (`inventory-svc`) y validar observabilidad antes de incorporar consumidores restantes.
7. Preparar acceso G5 únicamente tras coordinación, red segura, permisos y contrato versionado.
8. Registrar identificadores de despliegue, pruebas y estado de cada servicio sin marcar como operativos los aún no desplegados.

**Idempotencia:** reejecutar una configuración no deberá duplicar recursos ni cambiar características inmutables sin aprobación. Una incompatibilidad debe detener el procedimiento y producir un diff verificable, nunca borrar colas con mensajes.

## 5. Política de mensajería confiable

### Publicación y consumo

- Confirmaciones del publicador obligatorias, mensajes persistentes cuando aplique y manejo explícito de retornos o falta de ruta.
- ACK manual tras persistir el resultado o completar el efecto idempotente.
- Outbox transaccional para vincular cambios PostgreSQL con publicación eventual; Inbox/deduplicación antes de efectos secundarios.
- Prefetch inicial contractual: `20` por consumidor; ajustar solo tras medición y prueba.

### Reintentos y DLQ

Retry/DLX permanece **NO APROBADO, NO APROVISIONADO y BLOQUEADO**. `po.retry.x`, `po.dlx.x`, las colas `.retry`/`.dlq`, los tres intentos y el intervalo de `30 s` son parámetros del diseño candidato; no activarlos ni conceder permisos runtime. Se conserva `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`; no afirmar éxito de recuperación. Cualquier adopción futura requiere resolver el gate y versionarse después de `0.6.0-rc.3`.

Los rechazos válidos de negocio siguen el resultado contractual y no deben tratarse como fallo técnico. Publisher confirm, `basic.return` y ACK de consumidor son señales diferentes; un confirm no acredita recepción ni ACK.

### Reprocesamiento de DLQ

Solamente después de corregir causa y autorizar recuperación. Mantener trazabilidad del mensaje original, contar los intentos, preservar idempotencia y dejar evidencia de resultado. No purgar ni reenviar masivamente en forma automática.

## 6. Respaldos y restauración

| Elemento | Estrategia | Límite |
|---|---|---|
| Definiciones | Exportación JSON protegida y versionado saneado de topología | No incluye mensajes |
| Secretos/credenciales | Gestor de secretos o archivos restringidos, con procedimiento de reconstrucción/rotación | No incluir secretos en Git ni en reportes |
| Datos de mensajes | Copia consistente del directorio de datos según procedimiento oficial | Exige detener el nodo para un respaldo de mensajes basado en archivos; restauración sujeta a identidad del nodo |
| Recuperación funcional | Ensayo aislado de topología, permisos, colas y mensajes de prueba | No inferir éxito por existencia de archivos |

La restauración de datos de un nodo RabbitMQ moderno puede requerir conservar exactamente su nombre de nodo. No se afirmará que una copia arbitraria del volumen funcionará en otra VM sin ensayar el escenario.

**Política pendiente de cuantificación:** responsables, periodicidad, almacenamiento externo, retención, RTO y RPO. Se establecerán en función de requisitos acordados, no por suposición.

### Validación mínima de recuperación

- [ ] Se identifican versión, nombre del nodo, datos y origen del respaldo.
- [ ] Se recuperan definiciones y permisos en entorno aislado.
- [ ] Se recuperan mensajes de prueba si estaban incluidos en el alcance.
- [ ] Se prueba publicación, consumo, reintento, DLQ y reconexión.
- [ ] Se documentan tiempo real, limitaciones y acciones de cierre.

## 7. Monitoreo y respuesta a incidentes

| Señal | Interpretación | Acción inicial |
|---|---|---|
| Broker no disponible | Caída o pérdida de conectividad | Verificar host, contenedor, recursos, logs y rutas privadas |
| Alarma de memoria/disco | Riesgo de bloqueo de publicaciones | Examinar capacidad y crecimiento, sin purgas improvisadas |
| Cola sin consumidor | Servicio caído, credencial o red defectuosa | Verificar aplicación, credenciales, permisos y despliegue |
| Crecimiento sostenido de mensajes | Consumidor lento o caído | Contrastar ritmo de entrada/salida, ACK y dependencias |
| Incremento de mensajes sin confirmar | Procesamiento bloqueado o prefetch excesivo | Verificar consumidores y latencias |
| DLQ con nuevos mensajes | Fallos persistentes o mensajes inválidos | Aislar causa, correlacionar IDs, evitar reproceso automático |
| Mensaje sin ruta | Binding ausente o clave incompatible | Verificar contrato, exchange y routing key |
| Reintentos reiterados | Dependencia inestable | Inspeccionar errores técnicos y ventanas de recuperación |

**Instrumentación objetivo:** `rabbitmq_prometheus` + recolector compatible con Prometheus; Grafana si está disponible. El puerto de métricas por defecto de ese complemento es `15692`, que debe permanecer en una red de monitoreo autorizada, no exponerse indiscriminadamente.

**Alertas:** indisponibilidad y alarmas críticas de recursos sin demora; DLQ o sin ruta cuando aparece un mensaje; otros umbrales definidos tras línea base de tráfico y tolerancias del equipo. Para eventos de negocio, observabilidad también en logs de consumidores con `message_id`, `operation_id`, `correlation_id`, `causation_id`.

## 8. Seguridad de red y variables

- Para aplicaciones G6 en Docker, preferir una red Docker dedicada compartida, resolución del nombre interno del servicio broker y acceso de contenedores autorizados. No presumir que `localhost` del contenedor apunta al host.
- Para G5 fuera de la VM, acordar transporte privado o TLS, autenticación individual, controles de firewall/OCI y prueba desde su ubicación real. No publicar AMQP en Internet como solución rápida.
- Guardar `RABBITMQ_URL` en el archivo privado de runtime de cada aplicación, por ejemplo la ruta operacional existente `/etc/g6-inventory/runtime.env` para Inventario, según el despliegue real.
- Una URL AMQP a vhost `g6-productos-ofertas` tendrá como ruta `/g6-productos-ofertas`; si el vhost tiene una barra como parte de su nombre, deberá codificarse correctamente en la URL. No incluir contraseñas en documentación ni logs.
- Restringir panel de gestión, acceso SSH y métricas; no otorgar `sudo` ni acceso Docker general a los desarrolladores por simple necesidad de consumir mensajes.

## 9. Puertas de salida del lote de infraestructura

- [ ] Contrato a desplegar identificado; divergencias resueltas o confinadas.
- [ ] Respaldos y rollback verificados.
- [ ] Vhost nuevo, recursos y permisos creados desde definición repetible.
- [ ] Cuentas separadas, sin permisos administrativos runtime.
- [ ] Flujo de prueba publica, confirma, consume, confirma recepción y mantiene idempotencia.
- [ ] Retries, DLQ y casos sin ruta ensayados.
- [ ] Métricas y alertas de prueba comprobadas.
- [ ] Conectividad G5 probada en red segura cuando se habilite su integración.
- [ ] Evidencia de despliegue, SHA, fecha y responsables registrada.

## Referencias

[Decisiones de RabbitMQ](./decisiones/rabbitmq.md) · [Transición de RabbitMQ](../integraciones/transicion-rabbitmq.md) · [AsyncAPI](../contratos/eventos/asyncapi.yaml) · [Topología](../contratos/eventos/rabbitmq-topologia.md).

[RabbitMQ: control de acceso](https://www.rabbitmq.com/docs/access-control) · [Definiciones](https://www.rabbitmq.com/docs/definitions) · [Respaldos](https://www.rabbitmq.com/docs/backup) · [Colas quorum](https://www.rabbitmq.com/docs/quorum-queues) · [Monitoreo](https://www.rabbitmq.com/docs/monitoring).
