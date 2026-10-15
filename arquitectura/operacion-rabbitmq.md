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

| Aplicación | Identidad objetivo | Cola principal objetivo |
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

**Los nombres de esta tabla son objetivo, no credenciales existentes.** Hasta homologación contractual no se reemplazarán las colas inglesas por estas. La necesidad de publicar de cada servicio se derivará del contrato y no de su nombre de usuario.

## 3. Matriz de privilegios: criterio de construcción

Para cada aplicación se generará una matriz verificable con cinco columnas: `configure`, `write`, `read`, permisos de tópico y operaciones de prueba. No se aprobarán expresiones `.*` generales para las identidades runtime.

- **Inventario:** consumir solo su cola principal (y recursos complementarios si el flujo lo requiere); publicar únicamente eventos y resultados de inventario previstos en AsyncAPI.
- **Auditoría de precios y Combos:** consumo de sus respectivas colas; sin publicación salvo decisión contractual posterior.
- **Pasarela:** consumo de proyecciones de `po.gateway.q` en el contrato actual; sin administración.
- **Ventas G5:** consumo exclusivo de la cola de Ventas y publicación exclusivamente de comandos acordados; no acceso a colas ajenas.
- **Aprovisionador:** permisos para declarar vhost/topología/políticas según el proceso; no se comparte con aplicaciones.

**Detalles técnicos a validar:**

1. RabbitMQ distingue `configure`, `write` y `read` por recurso. Publicar en un exchange compartido requiere permisos sobre ese exchange, y restringir la routing key requiere permisos de tópico adicionales en exchanges de tipo `topic`.
2. Bindings, declaraciones de recursos, exchanges alternativos y dead lettering pueden requerir permisos adicionales. La matriz exacta debe derivarse de las operaciones AMQP **reales** de la biblioteca y del método de aprovisionamiento.
3. No conceder permisos de lectura sobre la cola de otro microservicio para facilitar pruebas: usar cuentas de prueba acotadas y sin datos reales.
4. Ejecutar pruebas **positivas** (un flujo permitido funciona) y **negativas** (publicar otro dominio, consumir otra cola y modificar topología son rechazados).
5. La revocación/rotación debe incluir reconexión cuando corresponda; los permisos pueden estar almacenados en caché durante la sesión.

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
2. Provisionar la topología de la **versión contractual elegida**. Inicialmente es válido conservar nombres de exchanges/colas/keys en inglés dentro del vhost nuevo, si así se acuerda, para desacoplar migración de vhost y traducción general.
3. Declarar exchanges con su tipo y durabilidad; colas principales y complementarias con el tipo acordado; bindings; políticas y mecanismo de captura sin ruta.
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

1. Intento inicial de consumo.
2. Ante error **técnico transitorio**, reenvío controlado a cola de reintentos con retardo de `30 s`.
3. Hasta **3 reintentos**; preservar identidad de operación, nueva `message_id` solo si lo exige el contrato/semántica de publicación y metadatos de intento explícitos.
4. Tras agotar el máximo, DLQ del consumidor; alerta e incidente con causa.
5. Fallos de negocio se resuelven con resultados contractuales de rechazo, no con DLQ.

El contrato especifica actualmente el retorno desde cola de reintento mediante DLX al exchange por defecto. Debe verificarse la compatibilidad exacta de políticas, TTL y tipo de cola con RabbitMQ 4.2.9. Si se requiere dead lettering `at-least-once`, verificar parámetros y límites de recurso antes de habilitarlo.

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
