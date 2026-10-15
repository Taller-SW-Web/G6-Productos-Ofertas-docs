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

<a id="matriz-rabbitmq-por-aplicacion"></a>

## 3. Matrices RabbitMQ por aplicación

La matriz contractual actual `0.6.0-rc.2` está **BLOQUEADA para aprovisionamiento seguro**. La matriz candidata A es **NO aprobada, NO desplegada** y su validación reproducible es parcial: un caso de recuperación de DLQ falló. Ninguna describe una configuración actualmente operativa.

### 3.1 Estado de la matriz contractual actual `0.6.0-rc.2` — BLOQUEADA

**BLOQUEADO_ESPECÍFICO — aprovisionamiento de credenciales runtime:** el contrato vigente concede `write` en `po.retry.x` y `po.dlx.x` compartidos `direct` a los productores de la matriz. Las ACL de recurso no limitan routing keys en esos exchanges; no aprovisionar estas credenciales mientras no se demuestre el aislamiento. Responsables: coordinación técnica e Infraestructura G6. Desbloqueo: elegir una alternativa y demostrarla con prueba negativa reproducible en el broker objetivo.

La tabla contractual completa aparece en 3.3. Sus permisos describen el contrato, no ACL instaladas ni usuarios activos.

### 3.2 Matriz candidata A — NO aprobada, NO desplegada; validación parcial

A convertiría `po.retry.x` a `topic`, limitaría el topic permission de cada runtime al nombre exacto de su propia cola y retiraría `write` runtime de `po.dlx.x`, delegando el rechazo final al dead-lettering del broker. Esta propuesta no modifica AsyncAPI ni topología vigentes.

ACL runtime propuesta para verificar A (no adoptada/no aprovisionable todavía):

| Identidad | Configure | Write del recurso `po.retry.x` | Topic write en `po.retry.x` | Write `po.dlx.x` | Read | Declaraciones al arrancar |
|---|---|---|---|---|---|---|
| `g6_taxonomia` | ∅ | Sí | `^po\.taxonomy\.q$` | ∅ | `po.taxonomy.q` | No activas |
| `g6_catalogo` | ∅ | Sí | `^po\.catalog\.q$` | ∅ | `po.catalog.q` | No activas |
| `g6_precios` | ∅ | Sí | `^po\.pricing\.q$` | ∅ | `po.pricing.q` | No activas |
| `g6_auditoria_precios` | ∅ | Sí | `^po\.price-audit\.q$` | ∅ | `po.price-audit.q` | No activas |
| `g6_promociones` | ∅ | Sí | `^po\.promotions\.q$` | ∅ | `po.promotions.q` | No activas |
| `g6_combos` | ∅ | Sí | `^po\.combos\.q$` | ∅ | `po.combos.q` | No activas |
| `g6_inventario` | ∅ | Sí | `^po\.inventory\.q$` | ∅ | `po.inventory.q` | No activas |
| `g6_masivos` | ∅ | Sí | `^po\.bulk\.q$` | ∅ | `po.bulk.q` | No activas |
| `g6_pasarela` | ∅ | Sí | `^po\.gateway\.q$` | ∅ | `po.gateway.q` | No activas |
| `g5_ventas` (externo; pendiente) | ∅ | Sí | `^po\.sales\.q$` | ∅ | `po.sales.q` | No activas |

Además se negará `write` del exchange por defecto y de cualquier recurso de cola a las identidades runtime: la única ruta de publish retry permitida debe ser `po.retry.x` y su topic permission. `po.dlx.x` solo se alcanza por dead-lettering del broker. Los permisos de publicación de negocio ya existentes y sus topic permissions exactos no se amplían por esta propuesta. Las topic permissions son opt-in: en el authorization backend por defecto, si falta la regla para un usuario/exchange, la publicación topic queda autorizada; el aprovisionamiento debe verificar backend, presencia y unicidad de cada patrón estrecho y denegar patrones amplios. RabbitMQ 4.2 comprueba `read` en cola y `write` en DLX durante la declaración; el aprovisionador separado hará las declaraciones/políticas. Para declarar las colas `.retry` con DLX `''`, también debe satisfacer la autorización del exchange por defecto (`amq.default`). El runtime consumirá recursos preaprovisionados (`basic.consume` requiere `read` en su cola); si intenta declaración activa, necesita `configure` y debe fallar. Las declaraciones pasivas en 4.2.9 requieren algún permiso sobre el recurso desde 4.2.7; el `read` de su cola/`write` del exchange satisface ese mínimo según tipo.

**Resultado del arnés aislado RabbitMQ 4.2.9:** pasan publicación retry propia y topic permission exacto/anclado, denegación de rutas cruzadas, aislamiento de lectura, prohibición de declaraciones runtime, TTL de 30 s, rechazo final normal a DLQ, ACK de rechazo de negocio, tres reintentos con contador/cabeceras y restricciones sobre DLX/default exchange/colas ajenas, además de alternate exchange + `mandatory=true`. Falla la recuperación tras liberar capacidad en la DLQ: el mensaje dead-lettered no se observó en destino en 60 s. Este resultado se conserva como fallo real, no como PASS. A sigue **BLOQUEADO_ESPECÍFICO** para aprobación/provisión hasta explicar y repetir satisfactoriamente ese caso y verificarlo en la configuración objetivo. El arnés y los límites de evidencia están en [pruebas aisladas](../tests/rabbitmq-aislamiento/README.md).

**Compatibilidad de consumidor sin `configure` no acreditada:** se inspeccionó solo para lectura el backend hermano en HEAD `2c4a18105c5e379edc8476b9d315aa6be1134b80`; no se encontró código consumidor RabbitMQ de producción bajo `apps`. Inventario contiene el publisher Outbox y su prueba de integración declara exchanges/colas para el fixture. No es evidencia de cómo arrancan los consumidores runtime ni de las otras aplicaciones. Antes de otorgar permisos debe verificarse su arranque real; una declaración AMQP activa fallará con `configure=∅`, mientras que consumir una cola ya creada usa `read`. Esta inspección no modificó el backend.

Comparación para la siguiente prueba: A es la candidata de menor privilegio: solo cambia el retry a topic y evita `write` de aplicaciones a DLX. B requiere topic permissions y cambios de tipo en ambos exchanges, y conserva la publicación directa runtime a DLQ. C evita topic permissions mediante ACL por recurso pero multiplica exchanges direct por consumidor y bindings. Las tres opciones requieren prueba; no se considera viable restringir routing keys en `direct` por ACL ni asignar topic permissions a exchanges `direct`.

Para A, la prueba negativa de permisos debe demostrar que `g6_inventario` publica con éxito en `po.retry.x` usando `po.inventory.q`, pero recibe `ACCESS_REFUSED` al usar `po.catalog.q`; los patrones literales serán anclados y escaparán los puntos (`^po\.inventory\.q$`, no `.*inventory.*`). Debe verificar además que Inventario no publica en `po.dlx.x`, default exchange ni colas ajenas; Catálogo no consume `po.inventory.q`; y ninguno puede declarar, alterar o borrar recursos. La matriz no se aprobará hasta pasar esta suite en broker aislado RabbitMQ 4.2.9.

Casos de aceptación runtime del arnés (RabbitMQ 4.2.9 aislado; resultados del commit de validación):

| Caso | Escenario y resultado requerido |
|---|---|
| 1 | Inventario publica a `po.retry.x` con clave `po.inventory.q`; confirm recibido y mensaje solo en `po.inventory.q.retry`. |
| 2 | Inventario intenta `po.catalog.q` y `po.inventoryXq`; ambos reciben `ACCESS_REFUSED` por regex exacto escapado/anclado. |
| 3 | Catálogo intenta consumir `po.inventory.q`; `ACCESS_REFUSED`, sin entrega. |
| 4 | Runtime intenta declarar/modificar/eliminar exchange, cola, binding o política; operación denegada. Consumer preprovisionado inicia con solo `read` en su cola; no se confunde declaración pasiva con activa. |
| 5 | Fallo técnico republica con confirms antes de ACK original; la cola `.retry` retiene ~30 s y vuelve al principal por default exchange, sin pérdida y permitiendo duplicados idempotentes. |
| 6 | Después de exactamente 3 retries posteriores al intento inicial, el consumidor rechaza la entrega actual con `requeue=false`; aparece una sola ruta lógica a DLQ propia y no regresa al principal. Repetir con destino no disponible y reconciliar comportamiento at-least-once/duplicados. |
| 7 | Rechazo poison/definitivo llega por DLX de la cola principal a su DLQ correcta sin `write` runtime a `po.dlx.x`; validar la comprobación de permisos al declarar usando solo el aprovisionador. |
| 8 | Rechazo válido de negocio ACKea el mensaje y publica el resultado de negocio si corresponde; no llega a DLQ. |
| 9 | Reentrega/duplicado conserva y verifica `message_id`, `correlation_id`, `causation_id`, `operation_id` y `x-retry-count`; pruebas de consumidores deben comprobar Inbox/idempotencia sin segundo efecto. |
| 10 | Intentos por default exchange (`amq.default`), nombre de cola, DLX, alternate exchange u otra ruta no autorizada son denegados/no alcanzan colas ajenas; revisar bindings completos y ACL efectiva. Los destinos de publicaciones de negocio con routing keys expresamente contratadas son excepción intencional y deben coincidir exactamente con sus bindings autorizados. |

Resultados: 1 PASS, 2 PASS, 3 PASS, 4 PASS, 5 PASS, 6 **FAIL** (entrega tras recuperar la DLQ no observada en 60 s; el rechazo normal de 6 sí llegó), 7 PASS, 8 PASS, 9 PASS, 10 PASS. La prueba acredita solo la fixture aislada fijada a RabbitMQ 4.2.9; no acredita compatibilidad de los consumidores de las diez identidades reales, homologación G5, configuración productiva ni despliegue. Caso 9 acredita transporte/cabeceras, no idempotencia funcional del backend.

El caso 9 requiere además una prueba de consumidor para acreditar idempotencia; un ensayo del broker por sí solo solo acredita el transporte/cabeceras. Los casos de TTL deben medir tiempo y número de entregas, no asumir el resultado por YAML.

La comparación prioritaria A/B/C y la evaluación de seguridad, complejidad, impacto y compatibilidad constan en [Decisiones de RabbitMQ](./decisiones/rabbitmq.md). No se adoptan otras soluciones (plugin, relay o exchanges por aplicación) en esta evaluación.

### 3.3 Matriz contractual vigente `0.6.0-rc.2` — BLOQUEADA para aprovisionamiento seguro

Derivada de `operations`, `x-producer`, bindings y colas de [AsyncAPI](../contratos/eventos/asyncapi.yaml) y [topología](../contratos/eventos/rabbitmq-topologia.md). `configure=∅` en runtime; cada identidad lee únicamente su cola principal. `.retry`, DLQ, `po.unrouted.q` y otros recursos operativos no reciben permisos de lectura. Las columnas `write` de retry/DLX describen el contrato rc.2 y no se deben provisionar.

| Aplicación / identidad objetivo | Configure | Write (recursos) | Read (colas) | Permiso de tópico para publicación de negocio | Declaraciones AMQP al arranque |
|---|---|---|---|---|---|
| `taxonomy-svc` / `g6_taxonomia` | ∅ | `po.commands.x`, `po.events.x`, `po.results.x`, `po.retry.x`, `po.dlx.x` | `po.taxonomy.q` | `po.commands.x`: `taxonomy.master.deactivation.check.requested`; `po.events.x`: `taxonomy.category.updated`, `taxonomy.characteristic-value.updated`, `taxonomy.master.deactivated`, `taxonomy.product-type-schema.changed`; `po.results.x`: `taxonomy.master.deactivation.rejected` | Ninguna activa; recursos preaprovisionados |
| `catalog-svc` / `g6_catalogo` | ∅ | `po.commands.x`, `po.events.x`, `po.results.x`, `po.retry.x`, `po.dlx.x` | `po.catalog.q` | `po.commands.x`: `inventory.sku.initialization.requested`, `pricing.product.initialization.requested`; `po.events.x`: `catalog.product.deactivated`, `catalog.sku.deactivated`; `po.results.x`: `catalog.bulk.upsert.completed`, `catalog.bulk.upsert.rejected`, `catalog.master.deactivation.checked` | Ninguna activa; recursos preaprovisionados |
| `pricing-svc` / `g6_precios` | ∅ | `po.events.x`, `po.results.x`, `po.retry.x`, `po.dlx.x` | `po.pricing.q` | `po.events.x`: `pricing.price.changed`; `po.results.x`: `pricing.bulk.price.apply.completed`, `pricing.bulk.price.apply.rejected`, `pricing.product.initialization.completed`, `pricing.product.initialization.rejected` | Ninguna activa; recursos preaprovisionados |
| `price-audit-svc` / `g6_auditoria_precios` | ∅ | `po.retry.x`, `po.dlx.x` | `po.price-audit.q` | Ninguno | Ninguna activa; recursos preaprovisionados |
| `promotions-svc` / `g6_promociones` | ∅ | `po.results.x`, `po.retry.x`, `po.dlx.x` | `po.promotions.q` | `po.results.x`: `promotions.coupon.consumption.completed`, `promotions.coupon.consumption.rejected`, `promotions.coupon.restoration.completed`, `promotions.coupon.restoration.rejected` | Ninguna activa; recursos preaprovisionados |
| `combos-svc` / `g6_combos` | ∅ | `po.retry.x`, `po.dlx.x` | `po.combos.q` | Ninguno | Ninguna activa; recursos preaprovisionados |
| `inventory-svc` / `g6_inventario` | ∅ | `po.events.x`, `po.results.x`, `po.retry.x`, `po.dlx.x` | `po.inventory.q` | `po.events.x`: `inventory.reservation.consumed`, `inventory.reservation.created`, `inventory.reservation.expired`, `inventory.reservation.released`, `inventory.stock.adjusted`, `inventory.stock.changed`; `po.results.x`: `inventory.bulk.stock.adjust.completed`, `inventory.bulk.stock.adjust.rejected`, `inventory.consumption.completed`, `inventory.consumption.rejected`, `inventory.reservation.rejected`, `inventory.sku.initialization.completed`, `inventory.sku.initialization.rejected` | Ninguna activa; recursos preaprovisionados |
| `bulk-svc` / `g6_masivos` | ∅ | `po.commands.x`, `po.retry.x`, `po.dlx.x` | `po.bulk.q` | `po.commands.x`: `catalog.bulk.upsert.requested`, `inventory.bulk.stock.adjust.requested`, `pricing.bulk.price.apply.requested` | Ninguna activa; recursos preaprovisionados |
| `api-gateway/bff` / `g6_pasarela` | ∅ | `po.retry.x`, `po.dlx.x` | `po.gateway.q` | Ninguno | Ninguna activa; recursos preaprovisionados |
| `modulo-ventas` (G5) / `g5_ventas` | ∅ | `po.commands.x`, `po.retry.x`, `po.dlx.x` | `po.sales.q` | `po.commands.x`: `promotions.coupon.consumption.requested`, `promotions.coupon.restoration.requested` | Ninguna activa; recursos preaprovisionados; concesión y homologación del vhost pendientes |

Esta matriz está bloqueada: sus permisos `write` completos en exchanges compartidas `direct` no aíslan routing keys ni DLQ. No es una configuración desplegada ni una autorización para provisionar.

Las routing keys de negocio indicadas se configuran como patrones exactos anclados (`^(?:clave1|clave2)$`) por exchange `topic`; un intento de publicar otra clave debe denegarse. Los exchanges retry/DLX son `direct`: su ACL `write` autoriza el recurso entero, no solo la routing key indicada por el flujo. No se otorga permiso de publicación en `po.unrouted.x`: es destino de alternate exchange configurado por el aprovisionador. En AMQP, los bindings del topology los crea el aprovisionador: el runtime no declara exchanges, queues, argumentos, alternate exchanges, DLX ni bindings y no necesita `configure`. Si una biblioteca intenta declaración activa al iniciar, el arranque queda bloqueado hasta configurarla para consumir recursos existentes o aprobar explícitamente otro modelo; no se ampliarán ACL silenciosamente.

El aprovisionador tiene identidad separada y permisos operativos para crear vhost, exchanges, colas, bindings y políticas. Para declarar exchanges con alternate exchange y bindings puede necesitar permisos `configure`/`read`/`write` en recursos origen/destino; estos permisos no se trasladan a cuentas runtime.

**Alcance sin evidencia de ejecución:** `x-producer` y bindings fijan el permiso contractual esperado. La biblioteca y el código real de arranque no se validaron en este lote; por eso la matriz prohíbe declaraciones runtime como objetivo y requiere verificación de implementación antes de conceder credenciales.

Validaciones operativas futuras deberán incluir positivas (publicación permitida, consumo de cola propia, retry propio) y negativas (otra routing key de negocio, otra cola, declaración/cambio de topología). Una prueba de publicación retry/DLX dirigida a la cola ajena documentará que la ACL nativa la permite mientras las exchanges sigan compartidas `direct`; no se marcará como PASS de aislamiento. No conceder permisos de lectura sobre colas ajenas para facilitar pruebas. La revocación/rotación debe incluir reconexión cuando corresponda, pues las decisiones de autorización pueden quedar en caché durante la sesión.

En publicación con `mandatory=true`, RabbitMQ devuelve `basic.return` si no hay ruta ni en el alternate exchange; si el alternate captura el mensaje, se considera enrutado y no hay `basic.return` (los publisher confirms son una señal separada). El arnés aislado verificó ambos comportamientos. La alternativa A también verificó `ACCESS_REFUSED` al publicar runtime en DLX, exchange por defecto y alternate, además de lectura/declaración sobre colas fuera de ACL. El traslado normal por DLX pasó; recuperación tras destino DLQ lleno falló en 60 s y no acredita `at-least-once` operativo en esa condición.

Referencia técnica RabbitMQ 4.2: [Access Control](https://www.rabbitmq.com/docs/4.2/access-control) describe topic authorisation para exchanges `topic`, permisos AMQP y declaraciones pasivas desde 4.2.7; [Dead Letter Exchanges](https://www.rabbitmq.com/docs/4.2/dlx) especifica los permisos DLX comprobados al declarar la cola; [TTL](https://www.rabbitmq.com/docs/4.2/ttl); [Quorum Queues](https://www.rabbitmq.com/docs/4.2/quorum-queues) documenta las condiciones/costes del dead-lettering `at-least-once`; [Alternate Exchanges](https://www.rabbitmq.com/docs/4.2/ae) documenta permisos al declararlos y que un mensaje enrutado mediante alternate exchange cuenta como enrutado para `mandatory`.

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
