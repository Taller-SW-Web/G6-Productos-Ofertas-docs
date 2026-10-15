# Decisiones de RabbitMQ

**Proyecto:** G6 — Productos y Ofertas  
**Fecha:** 15 de octubre de 2026  
**Estado:** decisión interna G6 adoptada para el contrato candidato `0.6.0-rc.2`; **homologación externa del vhost pendiente y no implementado**
**Responsable:** coordinación técnica de G6  
**Alcance:** ocho microservicios de negocio, la pasarela de API y consumidores externos expresamente autorizados.

> G6 adopta internamente `g6-productos-ofertas` como vhost contractual de la candidata AsyncAPI `0.6.0-rc.2`. Esto no acredita homologación de G5, aprovisionamiento, implementación ni pruebas de broker. No se incorpora una nueva decisión DEC-F.

## 1. Motivo

RabbitMQ se utilizará como infraestructura compartida de mensajería del sistema Productos y Ofertas, tanto para los flujos internos entre sus servicios como para las integraciones externas que tengan mensajería expresamente contratada. El nombre anterior de vhost, `/marketplace`, puede confundirse con el módulo externo Marketplace, aunque incluye muchas otras responsabilidades.

La auditoría de infraestructura realizada el 14 de octubre de 2026 observó RabbitMQ 4.2.9 saludable en Docker/Oracle Cloud, un vhost real llamado `g6`, dos usuarios genéricos (`g6_admin` y `g6_backend`) con permisos amplios en ese vhost y ninguna cola ni exchange de negocio configurado. También observó un único nodo con volumen persistente; no acreditó restauración probada. Son observaciones de ese corte, no una afirmación del estado futuro.

## 2. Identidad y separación de entornos

**Vhost adoptado internamente para la candidata contractual:** `g6-productos-ofertas` (sin barra inicial). Es un nombre lógico exacto, distinto de `g6` y del vhost de la línea candidata anterior `0.6.0-rc.1` (`/marketplace`).

- Se utilizará un vhost común para las comunicaciones asíncronas autorizadas de G6. Los usuarios se separan por aplicación, no por canal comercial.
- G5 Ventas, cuando la integración sea homologada y la red esté preparada, podrá acceder mediante una identidad exclusiva con permisos limitados. No tendrá privilegios de administración.
- Marketplace G1, Chatbot G3 y Retail G4 siguen integrándose principalmente por HTTP; la topología actual no les asigna colas directas. No se crearán usuarios o colas por inferencia.
- Un vhost separa recursos y permisos **lógicamente**, pero no proporciona aislamiento de CPU, disco ni alta disponibilidad.
- Ante futuros entornos adicionales, se evaluarán vhosts independientes y, para producción crítica, infraestructura separada. No se crearán nombres de entornos hipotéticos en esta fase.

## 3. Nomenclatura en español

### 3.1 Reglas

1. Usar nombres comprensibles en español para **identificadores nuevos de infraestructura**, con minúsculas, sin tildes, sin `ñ`, sin espacios y sin datos personales.
2. Usar puntos (`.`) para segmentos técnicos o semánticos y guiones (`-`) para palabras compuestas.
3. Mantener el prefijo estable `po` para recursos de Productos y Ofertas; conservar `.x` como sufijo de exchanges y `.q` como sufijo de colas.
4. Emplear para colas el nombre del **consumidor responsable**, no el nombre del productor ni del emisor circunstancial.
5. Para mensajes nuevos de una futura versión contractual, preferir la forma `dominio.entidad.hecho`, por ejemplo `inventario.reserva.creada`. Un comando puede reflejar una solicitud (`inventario.ajuste.solicitado`).
6. El idioma no justifica por sí mismo romper consumidores: **no traducir routing keys ya publicadas sin versión, inventario de dependencias y homologación**.

### 3.2 Tabla de nombres físicos: propuesta, todavía no contractual

| Recurso | Nombre contractual actual | Nombre propuesto |
|---|---|---|
| Vhost | `/marketplace` (`0.6.0-rc.1`) | `g6-productos-ofertas` (`0.6.0-rc.2`, candidato) |
| Exchange de comandos | `po.commands.x` | `po.comandos.x` |
| Exchange de eventos | `po.events.x` | `po.eventos.x` |
| Exchange de resultados | `po.results.x` | `po.resultados.x` |
| Exchange de reintentos | `po.retry.x` | `po.reintentos.x` |
| Exchange de fallidos | `po.dlx.x` | `po.fallidos.x` |
| Exchange de mensajes sin ruta | `po.unrouted.x` | `po.sin-ruta.x` |
| Catálogo | `po.catalog.q` | `po.catalogo.q` |
| Pasarela de API | `po.gateway.q` | `po.pasarela.q` |
| Promociones | `po.promotions.q` | `po.promociones.q` |
| Combos | `po.combos.q` | `po.combos.q` |
| Inventario | `po.inventory.q` | `po.inventario.q` |
| Precios | `po.pricing.q` | `po.precios.q` |
| Auditoría de precios | `po.price-audit.q` | `po.auditoria-precios.q` |
| Ventas G5 | `po.sales.q` | `po.ventas.q` |
| Taxonomía | `po.taxonomy.q` | `po.taxonomia.q` |
| Operaciones masivas | `po.bulk.q` | `po.masivos.q` |
| Cola de mensajes sin ruta | `po.unrouted.q` | `po.sin-ruta.q` |

Para las diez colas principales, las colas complementarias siguen la pauta `<cola-principal>.reintentos` y `<cola-principal>.fallidos`; por ejemplo `po.inventario.q.reintentos` y `po.inventario.q.fallidos`.

**Regla de transición:** esta tabla es un mapa para una futura modificación coordinada. No se deben mezclar nombres nuevos de exchanges con bindings o publicaciones de la versión anterior ni crear un alias ficticio entre vhosts. El cambio del **vhost** puede tramitarse separadamente del cambio de exchanges, colas y routing keys. La traducción de routing keys existentes requiere un mapeo exhaustivo en un lote contractual posterior.

**Ejemplos ilustrativos de futuros nombres de eventos (no vigentes):** `inventario.reserva.creada`, `inventario.reserva.rechazada`, `precios.precio.actualizado`, `taxonomia.categoria.actualizada`. Las claves vigentes siguen siendo, por ejemplo, `inventory.reservation.created` y `pricing.price.changed`.

## 4. Identidades y permisos

- Se asignará **una identidad técnica por aplicación**, más identidades externas autorizadas. Convención: `g6_<dominio>` y, para G5, `g5_ventas` (sujeto a aceptación de G5).
- Los microservicios solo podrán publicar en exchanges y claves contractualmente permitidos, y consumir de sus propias colas. No se concederán permisos comodín `.*` sin justificación explícita.
- Se separarán tres roles: **administración excepcional**, **aprovisionamiento de recursos** y **ejecución de aplicaciones**. Los servicios en ejecución no administrarán el broker.
- Una cuenta de aplicación no tendrá etiquetas administrativas. El permiso `configure` se denegará por defecto; antes de aplicarlo, se verificará que su biblioteca no exige declaración activa de colas/exchanges al iniciar.
- Los permisos de recursos se complementarán con permisos de tópico sobre exchanges de tipo `topic` para reducir el alcance de las routing keys. Las ACL por recurso, sin esta capa, no limitan necesariamente qué clave puede publicarse en un exchange compartido.
- Las credenciales serán únicas, rotables y guardadas como secretos fuera del control de versiones. El usuario `guest` no deberá habilitar acceso remoto.
- La consola de gestión solo estará disponible para operadores autorizados. El acceso externo a AMQP requerirá transporte seguro y reglas de red estrictas; la existencia de un consumidor externo **no** autoriza abrir el puerto a Internet.

## 5. Fiabilidad, reintentos y fallidos

Se mantienen las invariantes contractuales: persistencia según tipo de cola, confirmaciones del publicador (*publisher confirms*), confirmación manual de consumo (*ACK*), entrega al menos una vez (*at-least-once*), eliminación de duplicados por `message_id`, idempotencia funcional por `operation_id` cuando aplique y patrones Outbox/Inbox.

- Política vigente de reintentos **técnicos**: hasta **tres reintentos posteriores al intento inicial**, con **30 segundos** de espera por reintento, mediante cola específica por consumidor.
- Evitar bucles de `requeue=true`. Mantener un contador verificable de intentos y respetar el límite.
- Antes de confirmar como procesado un mensaje que se reenvía a una cola de reintentos, asegurar la aceptación del mensaje reenviado (por ejemplo mediante confirmación del publicador). Aun así pueden producirse duplicados: la idempotencia sigue siendo obligatoria.
- Tras agotar intentos, dirigir a la cola de mensajes fallidos (DLQ), conservar contexto de error y requerir intervención controlada para reprocesarlo.
- Los rechazos válidos de negocio, como stock insuficiente, no son errores técnicos: se emite el resultado de rechazo previsto y se confirma el mensaje original.
- La existencia de colas quorum no activa automáticamente dead lettering confiable: si se exige traslado **at-least-once** a DLQ, configurar y validar su estrategia explícitamente, incluidos `overflow=reject-publish`, `dead-letter-exchange` y sus efectos operativos.
- Los mensajes sin ruta se dirigirán al mecanismo de captura contractual y generarán alerta. Probar conjuntamente el comportamiento del exchange alternativo y `mandatory`, sin suponer que ambos producen la misma señal.

## 6. Disponibilidad y recuperación

**Situación actual:** un único nodo RabbitMQ sobre una única VM. Es un punto único de fallo; ni el volumen persistente ni las colas quorum de una sola réplica toleran la pérdida del host.

- No se declarará alta disponibilidad sin al menos una arquitectura redundante y pruebas de pérdida de nodo. Un diseño futuro podrá evaluar un clúster de **tres nodos** con miembros de quorum distribuidos entre dominios de fallo.
- Se distinguirán **definiciones/topología** (exportables como JSON) y **datos de mensajes** (almacenamiento del nodo). Un JSON de definiciones no respalda el contenido de las colas.
- Se verificará cualquier respaldo anterior (incluidos artefactos JSON/GPG) sin exponer secretos y se ensayará su restauración en un entorno aislado.
- Para respaldo de mensajes se usará un procedimiento consistente que respete el estado del nodo, la identidad del nodo y las restricciones de restauración de RabbitMQ; no se copiarán archivos de mensajes arbitrariamente mientras el broker esté activo.
- Las copias deberán estar protegidas, almacenadas fuera de la VM y sujetas a retención. Los objetivos de recuperación RTO/RPO serán acordados antes de prometer garantías.

## 7. Observabilidad

Se vigilarán como mínimo: disponibilidad del broker, alarmas de memoria/disco, conexiones, consumidores, mensajes listos y sin confirmar, acumulación y edad de colas, reintentos, DLQ, mensajes sin ruta y errores de publicación.

- Preferencia por el complemento de métricas de RabbitMQ compatible con Prometheus y paneles de Grafana si existe capacidad operativa.
- Se configurarán alertas inmediatas para broker caído y alarmas de recursos; para acumulación y pérdida de consumidores se ajustarán umbrales con mediciones reales. Toda entrada nueva en DLQ o mensajes sin ruta debe investigarse.
- Los registros de las aplicaciones conservarán `message_id`, `operation_id`, `correlation_id` y `causation_id` según el contrato, sin credenciales ni datos sensibles innecesarios.
- Se distinguirá la salud del broker de la disponibilidad funcional de consumidores y de los resultados definitivos del negocio.

## 8. Operación, evolución y compatibilidad

1. La topología será **declarativa, versionada e idempotente** y se aplicará por un proceso autorizado, no por cuentas runtime con permisos de administración.
2. Los cambios con impacto contractual requieren una versión candidata de AsyncAPI, consistencia con la topología física y pruebas de productores/consumidores.
3. Para G5, la homologación del cambio debe identificar vhost, redes, credencial, permisos, nombre y comportamiento de la cola de Ventas, routing keys, correlación y compatibilidad de despliegue. La homologación previa del flujo funcional de eventos no cubre este cambio de endpoint ni concede acceso al broker.
4. Se habilitará primero la integración de Inventario, luego las demás aplicaciones, sin anunciar que la integración es funcional antes de pruebas de extremo a extremo.
5. No se eliminarán los vhosts existentes `g6` ni `/marketplace` si aparecen durante la migración sin verificar previamente dependencias, mensajes y plan de reversión.

El procedimiento y sus puntos de autorización están detallados en [Operación de RabbitMQ](../operacion-rabbitmq.md) y [Transición de RabbitMQ](../../integraciones/transicion-rabbitmq.md).

## 9. Criterios de aceptación del diseño

- [ ] Decisiones revisadas y formalizadas por G6.
- [ ] Divergencias con AsyncAPI/topología registradas y versión de cambio aprobada.
- [ ] Consumidores externos afectados homologados antes de cambios incompatibles.
- [ ] Cuentas y permisos por servicio verificados mediante pruebas positivas y negativas.
- [ ] Topología aplicada desde definiciones repetibles sin errores de equivalencia.
- [ ] Reintentos, DLQ, mensajes sin ruta e idempotencia comprobados.
- [ ] Restauración de respaldo ensayada y documentada.
- [ ] Observabilidad básica operativa con alertas accionables.
- [ ] Integración Inventory ↔ G5 demostrada con evidencia E2E.

## Referencias

**Internas:** [Arquitectura](../Arquitectura.md) · [AsyncAPI](../../contratos/eventos/asyncapi.yaml) · [Topología RabbitMQ](../../contratos/eventos/rabbitmq-topologia.md) · [Matriz intermodular](../../integraciones/MATRIZ_INTERMODULAR_BACKEND.md).

**RabbitMQ oficial:** [Vhosts](https://www.rabbitmq.com/docs/vhosts) · [Permisos](https://www.rabbitmq.com/docs/access-control) · [Colas quorum](https://www.rabbitmq.com/docs/quorum-queues) · [Respaldo y restauración](https://www.rabbitmq.com/docs/backup) · [Monitoreo](https://www.rabbitmq.com/docs/monitoring).
