# Decisiones de RabbitMQ

**Proyecto:** G6 — Productos y Ofertas  
**Fecha:** 15 de octubre de 2026  
**Estado:** candidata documental `0.6.0-rc.3`; infraestructura base observada en auditoría Oracle del 2026-10-19; homologación externa pendiente y runtime no acreditado
**Responsable:** coordinación técnica de G6  
**Alcance:** ocho microservicios de negocio, la pasarela de API y consumidores externos expresamente autorizados.

> `0.6.0-rc.3` reconcilia el contrato candidato con la topología base observada el 2026-10-19. La observación histórica no demuestra estado actual, bindings individuales, homologación G5, conectividad, despliegue ni pruebas de broker. No se incorpora una nueva decisión DEC-F.

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

## 3. Nombres físicos reconciliados con la observación Oracle

La candidata AsyncAPI `0.6.0-rc.3` usa los nombres observados en la auditoría histórica Oracle del 2026-10-19 (RabbitMQ 4.2.9, vhost `g6-productos-ofertas`). Los nombres y tipos de la infraestructura base son referencia documental; no se renombrarán ni recrearán recursos en el broker por este cambio. La incompatibilidad afecta identidades físicas, no claves lógicas.

Los identificadores nuevos usan minúsculas, sin tildes, `ñ`, espacios ni datos personales; puntos separan segmentos y guiones separan palabras compuestas. `po` identifica Productos y Ofertas; `.x` y `.q` distinguen exchanges y colas. La cola representa a su consumidor. Esta convención no autoriza traducir routing keys comerciales publicadas: solo cambian referencias de recursos físicos expresamente versionadas.

| Recurso | Candidato anterior | Nombre físico observado y candidato rc.3 | Tipo/estado |
|---|---|---|---|
| Exchange comandos | `po.commands.x` | `po.comandos.x` | topic, durable; base observada |
| Exchange eventos | `po.events.x` | `po.eventos.x` | topic, durable; base observada |
| Exchange resultados | `po.results.x` | `po.resultados.x` | topic, durable; base observada |
| Exchange sin ruta | `po.unrouted.x` | `po.sin-ruta.x` | fanout, durable; base observada |
| Catálogo | `po.catalog.q` | `po.catalogo.q` | quorum, durable; base observada |
| Pasarela | `po.gateway.q` | `po.pasarela.q` | quorum, durable; base observada |
| Promociones | `po.promotions.q` | `po.promociones.q` | quorum, durable; base observada |
| Combos | `po.combos.q` | `po.combos.q` | quorum, durable; base observada |
| Inventario | `po.inventory.q` | `po.inventario.q` | quorum, durable; base observada |
| Precios | `po.pricing.q` | `po.precios.q` | quorum, durable; base observada |
| Auditoría de precios | `po.price-audit.q` | `po.auditoria-precios.q` | quorum, durable; base observada |
| Ventas G5 | `po.sales.q` | `po.ventas.q` | quorum, durable; base observada |
| Taxonomía | `po.taxonomy.q` | `po.taxonomia.q` | quorum, durable; base observada |
| Operaciones masivas | `po.bulk.q` | `po.masivos.q` | quorum, durable; base observada |
| Captura operativa sin ruta | `po.unrouted.q` | `po.sin-ruta.q` | quorum, durable; observada; no es contexto comercial |

`po.retry.x` y `po.dlx.x` conservan sus nombres y tipos solo como diseño candidato no aprobado. Las colas `.retry` y `.dlq` y sus routing keys técnicas siguen siendo candidatos no aprovisionados; si refieren el nombre de una cola principal, usan el identificador reconciliado. No se traducen exchanges retry/DLX.

Se mantienen las routing keys comerciales existentes, por ejemplo `inventory.stock.changed`, `inventory.reservation.created`, `inventory.reservation.rejected`, `pricing.price.changed` y `promotions.coupon.consumption.requested`. La reconciliación no cambia mensajes, canales, operaciones, productores, consumidores, payloads ni esquemas.

El reporte de auditoría registra 57 bindings, pero las definiciones físicas individuales no están disponibles en las fuentes de este repositorio. Por tanto la correspondencia uno-a-uno entre bindings observados y los declarados en AsyncAPI sigue `PENDIENTE_VERIFICACION`; coincidir en cantidad no constituye evidencia de equivalencia. Véase la [matriz de compatibilidad RabbitMQ Oracle](../../contratos/eventos/compatibilidad-rabbitmq-oracle.md).

## 4. Identidades y permisos

**Observación histórica de auditoría (2026-10-19):** la matriz [RabbitMQ Oracle](../../contratos/eventos/compatibilidad-rabbitmq-oracle.md) transcribe `configure`/`write`/`read` para las diez identidades consultadas. Esto no prueba conexión, publicación, entrega, consumo ni aceptación de mensajes y no representa ACL runtime actual. La auditoría no registra topic permissions. Los permisos observados no amplían permisos contractuales ni constituyen una autorización nueva.


- Se asignará **una identidad técnica por aplicación**, más identidades externas autorizadas. Convención: `g6_<dominio>` y, para G5, `g5_ventas` (sujeto a aceptación de G5).
- Los microservicios solo podrán publicar en exchanges y claves contractualmente permitidos, y consumir de sus propias colas. No se concederán permisos comodín `.*` sin justificación explícita.
- Se separarán tres roles: **administración excepcional**, **aprovisionamiento de recursos** y **ejecución de aplicaciones**. Los servicios en ejecución no administrarán el broker.
- Una cuenta de aplicación no tendrá etiquetas administrativas. El permiso `configure` se denegará por defecto; antes de aplicarlo, se verificará que su biblioteca no exige declaración activa de colas/exchanges al iniciar.
- Los permisos de recursos se complementarán con permisos de tópico sobre exchanges de tipo `topic` para reducir el alcance de las routing keys. Las ACL por recurso, sin esta capa, no limitan necesariamente qué clave puede publicarse en un exchange compartido.
- Las credenciales serán únicas, rotables y guardadas como secretos fuera del control de versiones. El usuario `guest` no deberá habilitar acceso remoto.
- La consola de gestión solo estará disponible para operadores autorizados. El acceso externo a AMQP requerirá transporte seguro y reglas de red estrictas; la existencia de un consumidor externo **no** autoriza abrir el puerto a Internet.

### 4.1 Evaluación del aislamiento retry/DLX (no adoptada)

El bloqueo de publicación runtime en las exchanges compartidas `direct` `po.retry.x` y `po.dlx.x` sigue vigente. El perfil focalizado de RabbitMQ 4.2.9 del 2026-10-15 verificó las políticas efectivas de origen y destino con `rabbitmqctl list_queues`. La DLQ quorum confirmó dos publicaciones con `max-length=1` antes de NACKear una tercera; esa aceptación por encima del límite confirma el exceso posible documentado para quorum. El mensaje original, persistente y confirmado, fue rechazado con `requeue=false`; mientras el destino no aceptaba publicaciones, el origen reportó `messages=1` y `messages_ready=0` con la política efectiva `at-least-once`/`reject-publish`. Al consumir y ACKear solo los dos mensajes de relleno identificados, el original no llegó a la DLQ dentro de los 60 s existentes: el escenario focalizado terminó **FAIL**. A no pasa el gate de recuperación y no se adopta. Se mantiene `BLOQUEADO_ESPECÍFICO` para aprovisionar credenciales runtime. Esta fixture no acredita recuperación ante reinicio, caída de Oracle, consumidores reales, Outbox/Inbox, integración G5 ni operación productiva.

**A/B/C permanecen sin adoptar.** La descripción de alternativas que sigue es antecedente de análisis, no aprobación, provisión ni autorización para ejecutarlas. No se elige una alternativa en esta revisión. Cambiar `po.retry.x` a tipo `topic`, mantener `po.dlx.x` `direct` con escritura solo del aprovisionador y configurar cada cola principal para dead-lettering broker-managed hacia su DLQ al rechazar con `requeue=false`. El runtime publicaría únicamente sus reintentos en `po.retry.x` usando un topic permission con patrón exacto, escapado y anclado (por ejemplo, `^po\.inventory\.q$` para Inventario), y leería solo su cola principal. RabbitMQ no limita publicaciones topic por clave si para ese usuario/exchange no se instala una topic permission; el aprovisionamiento debe verificar explícitamente que cada identidad tiene la regla y que no existen reglas más amplias. El flujo técnico publicaría el retry en la cola `.retry` correspondiente; su TTL existente lo retornaría a la cola principal. Tras tres retries el consumidor rechazaría la entrega final con `requeue=false`; el dead-lettering acabaría en DLQ sin volver a la principal. Los rechazos de negocio deben continuar ACKeándose y no disparar dead-lettering.

La configuración candidata debe demostrar dead-lettering **at-least-once** para las colas quorum fuente que deban garantizar el traslado a la principal o a DLQ: en RabbitMQ 4.2 requiere estrategia `at-least-once`, `overflow=reject-publish`, DLX/routing configuradas y la feature flag `stream_queue` habilitada. Tiene coste adicional de recursos; mensajes retenidos durante indisponibilidad y duplicados son posibles, pueden acumularse en la cola fuente y generar backpressure, por lo que capacidad/alertas deben planificarse sin inventar límites. El destino debe ser durable y el reproceso conservar idempotencia por `message_id`/`operation_id`. En el arnés 4.2.9, la ruta normal funciona pero el ensayo de full-capacity/recuperación no entregó el mensaje al liberar la DLQ; la expectativa documentada por la feature no quedó demostrada y A permanece bloqueada hasta investigar y repetir ese caso.

Las alternativas comparadas son:

| Alternativa | Seguridad esperada | Complejidad/cambio | Estado y compatibilidad |
|---|---|---|---|
| A. Retry `topic` con topic permissions; DLX `direct` broker-managed | Puede restringir cada publish de retry a la routing key propia. Sin escritura runtime a DLX. | Una conversión incompatible de `po.retry.x`, patrones exactos por identidad y DLX/políticas por cola principal. Menos privilegios y cambios que B. | **Candidata, no adoptada.** El perfil focalizado confirmó rechazo efectivo de destino y retención observable en la fuente, pero falló la entrega posterior del mensaje original dentro de 60 s. `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA` sigue abierta. |
| B. Retry y DLX `topic` con topic permissions | Puede limitar ambos publishes a una routing key propia si se verifica la autorización AMQP para ambos exchanges. | Dos cambios incompatibles de tipo y dos permisos topic por identidad; mantiene la capacidad runtime de publicar directamente en DLQ, privilegio que A evita. | No adoptada ni probada; más configuración y privilegio runtime. |
| C. Exchanges direct separados por aplicación | ACL de recurso limita cada identidad a nombres de exchange propios sin topic permissions. | Hasta dos exchanges por consumidor, más bindings y aprovisionamiento; conservar exchanges comunes ya no representa el flujo aislado. | No adoptada ni probada; aislamiento simple por recurso, pero más recursos y cambios físicos que A. |

No se acepta una ACL de recurso sobre exchanges `direct` como restricción de routing key; las topic permissions tampoco se aplican a esos exchanges. La hipótesis de A requiere confirmar que el broker usa un authorization backend que aplique topic permissions a publishers AMQP. A y B requieren recursos nuevos o una migración coordinada: cambiar `direct` a `topic` in-place falla por tipo incompatible. Antes de cualquier provisión se debe inventariar dependencias, preparar un destino compatible aislado y un corte/drain/reversión no destructivo; no borrar ni recrear colas con mensajes.

RabbitMQ verifica `read` sobre la cola y `write` sobre el DLX cuando se declara una cola con DLX. La topología candidata debe declararse por la identidad de aprovisionamiento, que conserva esos permisos; al declarar las colas `.retry` con el exchange por defecto como DLX, el aprovisionador también deberá satisfacer la autorización sobre `amq.default` (el nombre interno que RabbitMQ usa para el exchange AMQP por defecto). Runtime sin `configure` debe usar recursos ya aprovisionados y su ACL no incluirá `amq.default`. Una declaración pasiva en RabbitMQ 4.2.9 requiere al menos un permiso en el recurso desde 4.2.7; una declaración activa requiere `configure`. En una inspección solo de lectura del backend hermano (`2c4a18105c5e379edc8476b9d315aa6be1134b80`), no se encontró consumidor RabbitMQ de producción bajo `apps`; Inventario sí tiene un publisher Outbox y el test de integración crea exchanges/colas con `assertExchange`/`assertQueue`. Esa fixture no acredita el arranque runtime ni permite verificar que los nueve servicios y G5 consuman recursos preaprovisionados sin `configure`; la compatibilidad de consumidores sigue pendiente.

**Criterio de desbloqueo:** completar en broker 4.2.9 aislado las pruebas positivas y negativas del plan operativo (clave propia frente a ajena con regex literal `\.` y anclas `^$`, lectura cruzada, declaraciones, retry/TTL, tres reintentos, DLQ broker-managed, rechazo de negocio, correlación/idempotencia, default exchange y rutas laterales), y resolver/repetir satisfactoriamente la recuperación tras indisponibilidad/capacidad llena; conservar logs/comandos y versión del broker ligados al commit. Hasta entonces se mantiene `BLOQUEADO_ESPECÍFICO`. No se crea DEC-F nuevo. La versión `0.6.0-rc.3` se asigna a la reconciliación de nombres físicos base. Cualquier adopción posterior de retry/DLX deberá evaluarse con sus gates y tramitarse en una versión candidata posterior; esta revisión no fija su número.

## 5. Fiabilidad, reintentos y fallidos

La semántica contractual de publicación/consumo conserva publisher confirms, ACK manual, entrega at-least-once, deduplicación por `message_id`, idempotencia de negocio por `operation_id` cuando aplique y patrones Outbox/Inbox. Estas reglas documentales no prueban que las aplicaciones estén conectadas o implementen el flujo.

El flujo retry/DLX, incluidas las cifras candidatas de tres reintentos y 30 segundos, permanece **NO APROBADO, NO APROVISIONADO y BLOQUEADO**. `po.retry.x` y `po.dlx.x` conservan nombres y tipos candidatos; no se activan políticas ni permisos runtime. Se conserva `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`; la evidencia aislada disponible registró fallo de recuperación bajo saturación. No se afirma que las pruebas retry/DLX hayan pasado ni que el diseño candidato opere.

Los rechazos válidos de negocio se representan mediante el resultado previsto y no se convierten en fallos técnicos por esta reconciliación. Los mensajes sin ruta usan el alternate exchange `po.sin-ruta.x`; `mandatory`, `basic.return` y publisher confirms mantienen señales diferentes. Un confirm del publicador no demuestra recepción o ACK del consumidor.

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

**RabbitMQ oficial 4.2:** [Permisos y topic authorisation](https://www.rabbitmq.com/docs/4.2/access-control) · [Dead lettering](https://www.rabbitmq.com/docs/4.2/dlx) · [TTL](https://www.rabbitmq.com/docs/4.2/ttl) · [Colas quorum y dead-lettering at-least-once](https://www.rabbitmq.com/docs/4.2/quorum-queues). Otros: [Vhosts](https://www.rabbitmq.com/docs/vhosts) · [Respaldo y restauración](https://www.rabbitmq.com/docs/backup) · [Monitoreo](https://www.rabbitmq.com/docs/monitoring).
