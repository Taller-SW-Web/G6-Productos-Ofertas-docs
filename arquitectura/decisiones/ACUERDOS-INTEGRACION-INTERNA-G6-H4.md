# Acuerdos de integración interna G6 — Hito 4

**Estado interno:** `APROBADA_INTERNA_G6` para DEC-G6-INT-01 a DEC-G6-INT-13, por autorización del liderazgo G6 fechada 2026-11-01.
**Alcance:** `catalog-svc`, `taxonomy-svc`, `pricing-svc`, `price-audit-svc`, `inventory-svc`, `promotions-svc`, `bulk-svc`, `combos-svc` y `api-gateway` de G6.
**Estado externo:** ninguna cláusula de este documento declara homologación de G1–G7.
**Estado de implementación y pruebas:** pendiente de evidencia identificada por SHA; la documentación no acredita runtime, grant, despliegue ni E2E.

## Interpretación y transición

Las DEC-F-001–015, sus adendas y los acuerdos ya aprobados conservan sus invariantes. INT-05 ratifica, entre otras, la frontera de Taxonomy `CLEAR | IN_USE`, los cinco tipos de entidad, la identidad de SKU y el protocolo de baja; INT-13 ratifica los canales comerciales, `skuContext`, precio efectivo y la decisión de composición de promociones del 2026-10-26. Las decisiones INT restantes complementan dichas fuentes. Las incompatibilidades de esquemas se publican mediante la versión candidata OpenAPI/AsyncAPI de este cambio antes de activar productores o consumidores; los cortes incompatibles requieren despliegue coordinado.

Cada operación debe registrar proveedor, consumidor, contrato y versión, actor, resultado nominal, ausencia, inelegibilidad, fallo técnico, `correlation_id`, pruebas con SHA, código pendiente y evidencia E2E separada. Timeout, 401/403, error de red o DTO inválido nunca se convierten en inexistencia, precio cero o `AGOTADO`. Un permiso interno aprobado no representa un grant de G7.

El bypass demo sin JWT solo puede aplicarse de forma reversible a método/ruta y origen privado previamente verificados, sin upstream público ni confianza en `X-Forwarded-For` o cabeceras arbitrarias. Para operación autenticada se requiere JWT real. Las mutaciones administrativas humanas conservan `userBearer`/`GESTOR_COMERCIAL`; no se fabrican actores ni tokens. No se modifica base compartida, broker ni Oracle sin autorización operativa propia.

La planificación adjunta fija el modo demo sin JWT hasta el 2026-11-01, el retorno de JWT para el 2026-11-06 y la exposición prevista para el 2026-11-07. Son fechas objetivo: no prueban disponibilidad, grant de Seguridad, aprobación externa ni despliegue. Antes de cada transición se requiere la evidencia y autorización operativa aplicable.

## Decisiones aprobadas

### DEC-G6-INT-01 — Identidad y permisos intra-G6

- **Problema:** llamadas internas de lectura no tienen identidad uniforme ni allowlists puntuales suficientes.
- **Regla normativa:** llamadas servicio-a-servicio usan identidad compartida existente `client_id=modulo-productos`, `tipo=servicio`, `aud=api-productos` y scopes existentes por operación (`catalogo:leer`, `precios:leer`, `inventario:disponibilidad:leer`, u otro scope de lectura ya definido). El owner habilita solo la operación concreta; no se crean scopes globales ni se hereda permiso a escrituras, administración o stock detallado. No reenviar bearer entrante ni suplantar `modulo-retail`/`modulo-marketplace`.
- **Proveedor → consumidor / operación:** Catalog `obtenerProducto` → Promotions; Pricing `obtenerPrecioSku` → Promotions; Inventory `consultarDisponibilidadComercial` → Promotions; más lecturas internas expresamente enumeradas en INT-04. El modo demo y el JWT real se rigen por Interpretación y transición.
- **Datos, errores y timeout:** DTO y errores de cada operación OpenAPI; 404 solo tiene su significado de recurso/visibilidad publicado. Timeout, 401/403, 503, red o DTO inválido son fallos técnicos, nunca ausencia.
- **Responsables:** Marco política; Poma, Vera, Taco, López y Axel adaptadores/allowlists de su dominio.
- **Evidencia:** prueba de autorización positiva y negativa por operación, verificación de JWT y allowlist, no reenvío del token, SHA/CI y prueba E2E separada.
- **Pendientes:** contrato OpenAPI candidata actualizado; implementación de allowlists/adaptadores y pruebas; grant y credenciales de G7 para JWT real; comprobación de red privada para demo. Sin homologación externa atribuida.
- **Adenda 2026-11-03 — Promotions → Inventory:** Marco aprueba que la identidad técnica compartida `client_id=modulo-productos`, `tipo=servicio`, `aud=api-productos`, con `inventario:disponibilidad:leer`, consulte únicamente `consultarDisponibilidadComercial` por GET y con `canal=MARKETPLACE`. `client_id` identifica al servicio G6 y `canal` el contexto comercial; no se suplanta `modulo-marketplace`. La autorización se restringe conjuntamente por operación, cliente y canal. No habilita CHATBOT/RETAIL para esa identidad, el POST verificador, disponibilidad detallada, reserva, consumo, liberación ni otros permisos. No se crean scopes ni bypass demo. Taco responde como proveedor; Axel como consumidor; Marco como aprobador. Implementación en Inventory, regresión, SHA/CI, grant/credenciales G7 y E2E autenticado siguen pendientes; la aprobación interna no acredita esos estados ni homologación externa.

### DEC-G6-INT-02 — D-REC-01, disponibilidad de recomendaciones con variantes

- **Problema:** el contrato product-level no selecciona SKU y la disponibilidad puede variar por variante.
- **Regla normativa:** recomendaciones permanecen a nivel `product_id`, sin selección ni reserva de SKU. Catalog aporta SKU vendibles/elegibles por canal; Inventory consulta cada uno sin sumar ubicaciones. Cualquier SKU `DISPONIBLE` ⇒ producto `DISPONIBLE`; si no, algún `STOCK_BAJO` ⇒ `STOCK_BAJO`; todos `AGOTADO` ⇒ se excluye. Sin positividad demostrada y con cualquier `INDETERMINADO`, datos ausentes o inconsistentes ⇒ excluir candidato. No convertir `INDETERMINADO` en `AGOTADO`.
- **Proveedor → consumidor / operación:** Catalog y Inventory → Promotions / recomendación existente.
- **Datos, errores y timeout:** `Recomendacion.availability` conserva `EstadoStock`; nunca confirma checkout. Estado negativo legítimo puede excluir un candidato individual; caída, timeout, respuesta corrupta o 401/403 de Inventory falla la operación completa con error técnico existente, no lista vacía.
- **Responsables:** Axel consumidor, Poma composición SKU, Taco disponibilidad.
- **Evidencia:** simple, variantes mixtas, agotadas, indeterminadas, una disponible y fallo total de dependencia.
- **Pendientes:** semántica incorporada a contrato/SPEC; implementación, pruebas de consumidor/proveedor y E2E pendientes. No requiere homologación externa para lógica interna; permisos reales siguen sujetos a G7.

### DEC-G6-INT-03 — D-REC-02, precio con variantes

- **Problema:** falta definición para `current_price` cuando un producto tiene varios SKU/precios.
- **Regla normativa:** `current_price` es el mínimo efectivo («desde») entre SKU elegibles con disponibilidad positiva demostrada, para canal e instante común `at` UTC de la respuesta. Pricing resuelve herencia producto, override SKU, vigencia y oferta: oferta vigente o precio regular. No se agrega SKU a la respuesta. SKU sin precio válido no participa; sin ningún SKU con precio y disponibilidad positiva se excluye. Moneda homogénea requerida. Empate por SKU textual ascendente solo como desempate interno determinista.
- **Proveedor → consumidor / operación:** Pricing `obtenerPrecioSku` y Catalog/Inventory elegibilidad/disponibilidad → Promotions.
- **Errores y timeout:** fallo técnico/DTO inválido/moneda inconsistente hace fallar la operación; no cero ni precio histórico. Se usa el error técnico existente.
- **Responsables:** Axel y Vera; Poma suministra composición SKU.
- **Evidencia:** override/herencia, dos variantes con precios distintos, canal, vigencias, empate, fallo y moneda no homogénea.
- **Pendientes:** contrato/SPEC actualizados; adaptadores y pruebas por SHA; grants de G7 para tráfico autenticado, sin homologación externa atribuida.

### DEC-G6-INT-04 — Fuentes internas de Promotions y resolución canónica de cesta

- **Problema:** evaluación comercial y validación administrativa necesitan hechos autoritativos sin acceso cruzado a datos.
- **Regla normativa:** Promotions consume los operationIds existentes `obtenerProducto`, `obtenerPrecioSku` y `consultarDisponibilidadComercial`, con identidad `modulo-productos`, permiso por operación y el mismo canal validado; sin SQL cross-schema, fallback ficticio ni reenvío del JWT. Si falta `product_id` en cesta, resolver con `obtenerContextoSku` (`GET /api/v1/productos/skus/{sku}/contexto`); si viene, verificar que coincide con `productId`; divergencia es entrada inválida. Crear, reemplazar referencias o activar requiere productos/SKU/categorías existentes y activos/elegibles. Desactivación o retiro de referencia antigua no se bloquea por ausencia. Validar mediante lectura de Catalog y GET existentes de Taxonomy que correspondan al tipo de regla. GET Taxonomy pertinentes admiten alternativa `serviceBearer` de lectura precisa para `modulo-productos`, sin escrituras. No se crea endpoint de mutación ni consulta SQL cruzada.
- **Errores y ausencias:** 404 comercial significa no visible/elegible para regla, no prueba inexistencia administrativa; rechazar referencia de alta/activación sin inferir estado. 401/403/503/timeout son fallo técnico, no referencia inválida. Propagar errores existentes.
- **Responsables:** Axel integra; Poma Catalog/contexto; López maestros; Vera Pricing; Taco Inventory.
- **Evidencia:** resolución SKU→productId, coincidencia/divergencia, referencias activas/inactivas/ausentes, errores técnicos y controles de allowlist.
- **Pendientes:** OpenAPI y kit actualizados; implementar y probar llamadas/allowlists antes de activar; grants reales G7 pendientes. Ninguna homologación externa se presume.
- **Precisión aprobada 2026-11-03 — Inventory:** para `consultarDisponibilidadComercial`, Promotions usa `modulo-productos` con el scope y audiencia existentes, exclusivamente para `MARKETPLACE`. La identidad del servicio y el canal son atributos distintos y se validan conjuntamente; el mapa existente de clientes comerciales no se reemplaza. La allowlist de `POST /inventario/disponibilidad/comercial/verificar` y la de disponibilidad detallada permanecen sin cambios. Taco implementa y verifica la política en Inventory; Axel consume sin suplantación; Marco aprobó el alcance. Pendientes: cambio backend de Inventory, pruebas positivas/negativas con modo demo desactivado, SHA de merge, CI, grant y credenciales G7, y repetición E2E autenticada.

### DEC-G6-INT-05 — Barrera Taxonomy ↔ Catalog (ratificación)

- **Problema:** impedir divergencias en comprobación y baja de maestros/asociaciones.
- **Regla normativa ratificada, no nueva:** `entity_type` permitido: `CATEGORY`, `BRAND`, `PRODUCT_TYPE`, `CHARACTERISTIC_VALUE`, `PRODUCT_TYPE_CHARACTERISTIC`; resultado exclusivamente `CLEAR | IN_USE`, sin `HAS_ACTIVE_PRODUCTS`. Taxonomy es autoridad de `version`; para asociación se refiere a versión de esquema del tipo de producto. Catalog conserva `operation_id`, `correlation_id`, identidad y versión, sin sustituirlas por `schema_version` del envelope. Timeout del check inicial 60 s; retry de preparación Catalog independiente, 300000 ms más condiciones ya aprobadas. `CLEAR` no libera por sí solo baja: se requiere resultado terminal y cierre correlacionado según protocolo.
- **Proveedor → consumidor / evento:** Taxonomy → Catalog, mensajes existentes de solicitud/check/resultado de baja.
- **Errores/timeout:** respuesta vieja, duplicada o no correlacionada no libera barrera; timeout sigue el protocolo durable existente.
- **Responsables:** López proveedor; Poma consumidor.
- **Evidencia:** cinco tipos, duplicado, versión obsoleta, `IN_USE`, timeout, `CLEAR` sin terminal y recuperación.
- **Estado:** reglas internas aprobadas; corrección de correlación en Catalog fusionada en Backend PR #168 y trabajo de Taxonomy para `CATEGORY`/`BRAND` fusionado en Backend PR #160. Cobertura de los tres tipos restantes, validación conjunta y garantías operativas siguen pendientes donde no exista evidencia. La aprobación interna no constituye homologación externa.

### DEC-G6-INT-06 — `pricing.price.changed` tipado y Pricing → Price Audit/Promotions

- **Problema:** evento genérico no permite auditoría fiable de cambios efectivos.
- **Regla normativa:** emitir durablemente tras commit de transición efectiva, nunca en prevalidación ni al programar futuro. Cambio base producto = un objetivo PRODUCTO; override = SKU. `data`: `target_type` (`PRODUCTO|SKU`), `product_id`, `sku` (null para producto), `channel_id` (`MARKETPLACE|CHATBOT|RETAIL|VENTAS|null`), `currency`, `price_type` (`REGULAR|OFERTA`), `previous_price`, `new_price` como decimal-string o null según semántica, `operation` (`CREACION|MODIFICACION|RETIRO_OFERTA`), `reason`, `price_version` entero >0, `valid_from` date-time, `batch_id` UUID/null y `actor` con `user_id/email/ip` nullable. Creación: anterior null y nuevo positivo; retiro oferta: nuevo null; modificación: ambos presentes. No emitir cambio inexistente. Se conserva `MessageEnvelope` y `schema_version=1` para corte coordinado, pero GenericData pasa a schema dedicado; no dirigir este payload a consumidores antiguos antes de despliegue coordinado. La evolución del contrato lleva versión candidata nueva, sin cambiar exchange/routing key.
- **Semántica consumidora:** auditor calcula `(new-previous)/previous*100` con decimal exacto, escala 2, HALF_UP; null en creación/retiro/divisor indefinido. `price_version` es versión de definición, no del envelope ni orden global. Price Audit permite `sku=null` solo para PRODUCTO y persiste/consulta `target_type`; migración aditiva autorizada pendiente. Promotions invalida objetivo/canal y vuelve a consultar Pricing; no reconstruye precio incompleto.
- **Responsables:** Vera productora y auditor; Axel invalidación.
- **Evidencia:** eventos producto/SKU, global/canal, programación futura, idempotencia por `message_id`, nulos/actor y auditoría.
- **Pendientes:** schema AsyncAPI candidato añadido; implementación, cambio aditivo de persistencia autorizado, consumer/provider tests y rollout coordinado pendientes. La persistencia requiere proceso operativo; no hay homologación externa atribuida.

### DEC-G6-INT-07 — Eventos tipados de desactivación y stock

- **Problema:** payloads genéricos no expresan identidad/versiones de invalidación.
- **Regla normativa:** conservar nombres y topología. `catalog.product.deactivated.data={product_id,product_version>=1,changed_at}`; `catalog.sku.deactivated.data={sku,product_id,sku_version>=1,changed_at}`. Para Inventory, el productor vigente emite envelope `schema_version=2` y un snapshot `data={sku,location_id,on_hand,reserved,blocked,available,estado,stock_version,updated_at}`; `stock_version` pertenece al par `(sku,location_id)` y no existe versión global por SKU. Esta reconciliación concreta el payload sin cambiar la regla aprobada: consumidores comerciales solo invalidan la proyección y consultan disponibilidad comercial autoritativa antes de decidir; no agregan ubicaciones ni toman el snapshot como estado vigente. Catalog invalida elegibilidad de producto/SKU en Promotions/Combos; SKU no cambia de padre y una versión vieja nunca reactiva.
- **Errores y entrega:** duplicados/obsoletos deduplicados con Inbox y versión; durante invalidación sin consulta fiable se falla cerrado. Versiones de dominio no son `schema_version` del envelope.
- **Responsables:** Poma/Taco productores; Axel, Marco y Vera consumidores según uso.
- **Evidencia:** payload tipado, Inbox, evento repetido/obsoleto, consulta de refresco y disponibilidad fallida.
- **Pendientes:** el decoder/writer actual de Promotions que espera una disponibilidad normalizada debe adaptarse a invalidar la proyección al recibir el snapshot y consultar luego Inventory; no conectar ese decoder a `available`/`estado` como decisión comercial. Aún faltan publicadores Catalog y adaptadores de consumidores, pruebas coordinadas y transición antes de activar. No cambiar nombres físicos ni declarar homologación externa.

### DEC-G6-INT-08 — Bulk ↔ Catalog: comando y resultados por fila

- **Problema:** Bulk necesita carga multidominio sin escrituras ajenas y con resultados parciales trazables.
- **Regla normativa:** Bulk v2 es fuente de entrada H4; no escribe esquemas Catalog/Pricing/Inventory. `catalog.bulk.upsert.requested.data`: `batch_id:uuid`, `batch_operation_id:uuid`, `template_version:2`, `mode:ALTA|ACTUALIZACION`, `rows[]` con `row_number>=2`, `row_operation_id:uuid` estable en retry, `producto_id` nullable (obligatorio en ACTUALIZACION), `sku_base`, `product` ref a DTO OpenAPI Catalog, `variant_id` nullable, `variant` ref DTO o null. Con `schema_version=1`, la actualización de variante exige `variant_id` y no admite `sku_variante`; con `schema_version=2` admite `variant_id` y/o `sku_variante`, con al menos un selector. Catalog resuelve `sku_variante` a `variant_id` y valida selector, pertenencia al padre e identidad/versiones dentro de la transacción; si se proveen ambos deben identificar la misma variante. No requiere consulta HTTP previa. Cada fila es SKU vendible; producto simple lleva variant null; variantes comparten sku_base. Catalog crea/actualiza padre una vez por grupo y rechaza atributos contradictorios. Alta/actualización selecciona DTO y operación correctos; jamás convierte actualización de variante en creación. Precio/stock van a pasos autorizados separados.
- **Resultados:** `completed.data={batch_id,batch_operation_id,results:[{row_number,row_operation_id,product_id,sku_base,status:COMPLETED|REJECTED,code:string|null}]}`; completed significa comando procesado aunque tenga filas rechazadas. `rejected.data={batch_id,batch_operation_id,code,detail}` solo rechazo del lote antes de resultados por fila; detail sin SQL/secretos/trazas. Misma row_operation_id + mismo payload semántico repite resultado sin efectos; distinto payload da `IDEMPOTENCY_CONFLICT`; distinta message_id para comando igual no duplica. Bulk consolida `{applied_domains,failed_domain,needs_reconciliation}` conforme SPEC-001, sin rollback destructivo ni éxito ficticio de Pricing/Inventory.
- **Responsables:** Marco Bulk; Poma Catalog; Vera/Taco resultados de sus dominios.
- **Evidencia:** Docs PR #107 y #109 publicaron y aprobaron el contrato/plantilla v2 de 16 cabeceras; Backend PR #162 fusionó el consumidor Catalog v1/v2. CI #41717588245 pasó 18/18 jobs; BULK-CONSUMER-v2 usó productor explícito de fixture y PostgreSQL/RabbitMQ desechables. Esto acredita el alcance probado del consumidor, no al productor Bulk v2 real ni E2E entre despliegues.
- **Pendientes:** verificar el productor Bulk v2 real y la integración completa; no hay homologación externa implícita. La plantilla ya está publicada y no queda pendiente de publicación.

### DEC-G6-INT-09 — P-PRI-01, importación y límites de plantilla H4

- **Problema:** evitar importadores paralelos o respuestas ficticias para flujo no preparado.
- **Regla normativa:** carga multidominio H4 usa Bulk v2; no crear importador paralelo de archivos en Pricing. `prevalidarImportacionPrecios` y `crearImportacionPrecios` no se declaran implementados ni responden 202 sin formato y worker específicos; quedan fuera del gate funcional H4. Escrituras individuales/programadas Pricing y eventos oficiales de inicialización/precio masivo sí avanzan independientemente. Bulk v2: CSV/XLSX, plantilla aprobada de 16 columnas, archivo máximo 10,485,760 bytes, 5,000 filas de datos y XLSX descomprimido 50 MiB; CSV UTF-8; XLSX una hoja declarada, sin macros; encabezados exactos, fila por SKU vendible y SKU únicos. Rechazar excesos/incoherencias antes de efectos.
- **Responsables:** Marco archivo/worker/contrato; Vera Pricing; Poma Catalog; Taco Inventory.
- **Evidencia:** límites y negativos, plantilla exacta, no-202 ficticio y pruebas de escrituras individuales/programadas.
- **Estado:** plantilla de 16 cabeceras publicada en SPEC-001 y contrato Bulk v2 aprobado en Docs PR #107/#109. Las rutas de importación Pricing quedan explícitamente excluidas de H4, sin promesa de implementación. La implementación del productor Bulk v2 real sigue pendiente de verificación; homologación externa no aplicable/no atribuida.

### DEC-G6-INT-10 — Snapshot de exportación Bulk

- **Problema:** no hay transacción ACID distribuida entre Catalog, Pricing e Inventory.
- **Regla normativa:** fijar un único `requested_at` UTC y usarlo en consultas con parámetro `at` (Pricing). Catalog aporta identidad/atributos observados durante ejecución; Inventory el stock realmente observado por su respuesta. Manifiesto interno Bulk registra solicitud, observaciones por dominio y versiones disponibles. Describir exportación como consolidado observado, nunca snapshot atómico. Fuente requerida fallida ⇒ `FAILED_GENERAL` con razón verificable, sin publicar parcial como completa. Reintento conserva identidad; reejecución explícita debe tener nuevo intento/versión y no sobreescribir artefacto publicado.
- **Formato/contrato:** no añadir campos públicos que OpenAPI no admita; metadatos en manifiesto interno o DTO versionado posterior.
- **Responsables:** Marco Bulk; Poma/Vera/Taco proveedores.
- **Evidencia:** instante único Pricing, tiempos/versiones observados, error de cada proveedor, retry y artefacto publicado inmutable.
- **Pendientes:** implementación/manifiesto y pruebas; no requiere homologación externa salvo que se proponga luego exponer DTO nuevo.

### DEC-G6-INT-11 — Combos: precio y disponibilidad

- **Problema:** API comercial de Inventory no expone cantidades por contexto y no permite derivar unidades de combo.
- **Regla normativa:** Combos valida SKU en Catalog y precios regulares/públicos vigentes de Pricing bajo mismo canal/instante; exigir `0 < precio_combo < suma_regular` y `< suma_publica`. Referencia inexistente/inactiva usa rechazo contractual; desigualdad incumplida `COMBO_PRECIO_INVALIDO`; precio no autoritativo por fallo técnico usa `SERVICIO_NO_DISPONIBLE`. Combos no registra stock ni reserva; compra se expande a líneas `(sku,quantity)` por orquestador autorizado.
- **Disponibilidad:** con API comercial actual, sin saldos, no derivar conteo. Responder `verificable=false`, `cantidadInformativa=null`, `estadoActualizacion=INCOMPLETA` cuando no haya fuente autoritativa de cumplimiento común/cantidad; `calculated_at` registra comprobación. No inferir 0 ni positivo por sumas multi-ubicación. Cantidad H4 requiere contrato versionado/autorizado/probado de cesta completa en único contexto realizable; no exponer `on_hand`, `reserved` o `location_id` a canal comercial. Promotions es autoridad única de combinabilidad; sin respuesta contractual permisiva no aplicar cupón automáticamente.
- **Responsables:** Marco Combos; Poma/Vera/Taco proveedores; Axel combinabilidad.
- **Evidencia:** precios iguales/distintos, referencias, error técnico, `null` no verificable, no reserva y cupón no asumido.
- **Pendientes:** contrato/SPEC y pruebas internas; fuente cuantitativa solo se implementa si se aprueba contrato aparte. Grants externos siguen independientes.

### DEC-G6-INT-12 — Política AMQP H4

- **Problema:** retry/DLX físico no está configurado y no debe confundirse con recuperación lógica.
- **Regla normativa:** conservar vhost `g6-productos-ofertas`, exchanges `po.comandos.x`, `po.eventos.x`, `po.resultados.x`, `po.sin-ruta.x`, colas observadas y routing keys/nombres aprobados. Consumidor hace ACK tras efecto o disposición durable (Inbox incluido); duplicado devuelve resultado confirmado. Payload permanentemente inválido: persistir rechazo con `message_id`, causa canónica y correlación en almacenamiento propio antes de ACK. Fallo transitorio de DB/proveedor/broker: hasta 3 intentos locales con backoff acotado; luego pausar consumidor y alertar, conservar sin ACK hasta recuperación/cierre ordenado. Evitar NACK/requeue en loop; no afirmar DLQ. Outbox publica tras commit con confirmación y message_id estable; deduplicar por operation_id/identidad, no correlation_id.
- **Responsables:** Marco topología/prueba; cada owner en su consumidor.
- **Evidencia:** pruebas aisladas inválido, duplicado, DB caída, reconexión, pausa sin pérdida, último confirmado y reinicio; evidencia de infraestructura separada.
- **Pendientes:** lógica, Inbox/Outbox y pruebas pueden implementarse con broker aislado; retry/DLX, ACL, bindings y homologación física siguen pendientes bajo seguimiento externo/operativo. AsyncAPI no certifica operación.

### DEC-G6-INT-13 — Readiness y cierre selectivo de bloqueos

- **Problema:** liveness y contratos documentados pueden confundirse con capacidad funcional disponible.
- **Regla normativa:** health liveness solo acredita proceso. Readiness técnico verifica PostgreSQL propio y broker solo si se utiliza. Readiness funcional requiere smoke contractual por operación real usando endpoint de salud existente, sin inventar rutas públicas. Proveedor deshabilitado no reporta capacidad disponible; operación bloqueada devuelve error técnico explícito, nunca dato ficticio. Composición Promotions aprobada el 2026-10-26 (acumulación, reparto fijo, redondeo, promotion_id singular) permanece aprobada y no reabre. `channel_id` textual, `CLEAR|IN_USE`, `skuContext`, precio efectivo y SKU inmutable son adaptaciones aprobadas, no nuevas decisiones.
- **Responsables:** cada owner de servicio; Marco coordinación.
- **Evidencia:** health/readiness separados, smoke por operación con SHA/correlation_id, evidencia E2E diferenciada y negativos de proveedor deshabilitado.
- **Pendientes:** adaptación de código, migraciones aditivas autorizadas cuando correspondan, pruebas. Grant G7, E2E y despliegue se acreditan separadamente; ninguna homologación externa se presume.

## Matriz operativa de bloqueos

| Prioridad | Frontera | Proveedor / responsable | Consumidor | Criterio de desbloqueo |
|---|---|---|---|---|
| P0 | Catalog ↔ Pricing `skuContext` | Poma / Vera | Vera / Poma | Adaptadores y pruebas provider/consumer; 404 vs 503; canal/instante; grant separado |
| P0 | Lecturas comerciales Promotions | Poma / Vera / Taco | Axel | Allowlist interna, DTO/errores, cesta SKU→productId y prueba contractual |
| P0 | Maestros Catalog/Promotions | López | Poma / Axel | GET internos autorizados, ausencia/estado/versiones y pruebas |
| P0 | D-REC-01/02 | Poma / Vera / Taco | Axel | Casos variantes y estados inconclusos sin DTO ficticio |
| P0 | `pricing.price.changed` | Vera | Vera / Axel | Schema, emisión post-commit, auditoría producto/SKU, idempotencia y pruebas |
| P0 | `catalog.bulk.upsert.*` | Marco | Poma / Marco | Schemas, IDs de fila, resultados parciales, plantilla v2 y pruebas |
| P1 | eventos desactivación/stock | Poma / Taco | Axel / Marco / Vera | schemas, invalidación, Inbox y versiones |
| P1 | Combos precio/disponibilidad | Poma / Vera / Taco | Marco | precio determinista; null mientras cantidad no verificable |
| P1 | Snapshot exportación | Poma / Vera / Taco | Marco | manifiesto temporal, fallo cerrado, reporte no atómico |
| P1 | AMQP recuperación | Marco y owners consumidores | todos | pruebas aisladas; evidencia de red/ACL aparte |

## Estados de incorporación documental

| Estado | Resultado en este cambio |
|---|---|
| DECISIÓN APROBADA | Las 13 decisiones internas están registradas aquí; INT-05/13 incluyen ratificaciones explícitas. |
| CONTRATO DOCUMENTADO | OpenAPI/AsyncAPI y referencias derivadas se actualizan en esta rama candidata. La fusión/publicación aún no ocurre. |
| IMPLEMENTACIÓN PENDIENTE | Todos los adaptadores, productores, consumidores, allowlists, persistencia y readiness requieren evidencia backend por SHA. |
| PRUEBA PENDIENTE | No se atribuye ejecución de pruebas runtime/provider/consumer/E2E salvo resultado concreto informado al cerrar la tarea. |
| HOMOLOGACIÓN EXTERNA PENDIENTE | Grants/provisión G7; transición de payload incompatible con consumidores; topología física; cualquier acuerdo de grupo externo concernido. Sin aceptación por silencio. |

## Auditoría de fuentes

El adjunto se incorpora como decisión interna complementaria. DEC-F-001–015, `ADR-DEC-F-BLOQUEANTES.md`, matriz DEC-F y acuerdo privado `skuContext` siguen siendo normativos donde corresponda. Los SPEC/FLOW y contratos OpenAPI/AsyncAPI prevalecen para reglas funcionales e interfaz ejecutable; los cambios de este PR forman nuevas candidatas y no demuestran publicación. Una respuesta 404 comercial no se convierte en inexistencia administrativa; `INDETERMINADO` no se convierte en agotado; disponibilidad de combo no expone saldo; Bulk no escribe en otros dominios; `completed` no significa que cada fila o dominio tuvo éxito. Se conservan los eventos físicos existentes y la separación de `schema_version` envelope frente a versiones de dominio.
