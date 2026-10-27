# Registro de decisiones DEC-F — G6 Productos y Ofertas

- **Corte de contraste:** `origin/master` `78a923bbc6bada31b39b3d386331f90a4f812b31` (merge de PR #86).
- **Antecedente:** `G6_REGISTRO_MAESTRO_12_DECISIONES_DEC-F_2026-10-12.md`, recibido el 12-10-2026.
- **Alcance:** DEC-F-001–DEC-F-015 son decisiones internas adoptadas por G6. DEC-F-013 a DEC-F-015 fueron aprobadas por Marco el 2026-10-13 y sus invariantes se limitan a la autoridad de Productos y Ofertas. B1–B4 son bloqueantes de integración del PR #86, no decisiones adicionales ni sustitutos. Se conserva [ADR-DEC-F-BLOQUEANTES.md](ADR-DEC-F-BLOQUEANTES.md).
- **Estado global:** DEC-F-001–DEC-F-015 adoptadas internamente. La homologación externa, implementación y verificación integral no se infieren de este documento.

## Estados y lectura

“Adoptado” describe la decisión interna reportada por el antecedente/ADR. “Homologado” requiere evidencia de aceptación externa. “Implementado” requiere evidencia de código/backend; “probado” requiere resultados reproducibles identificados. La presencia de documentación o contratos candidatos no satisface esos estados.

PR #86 está fusionado en el `master` contrastado. OpenAPI y AsyncAPI `0.6.0-rc.1` continúan descritos en el repositorio como candidatos/provisionales; su fusión no acredita integración E2E. Las migraciones Inventario 0002 y Promociones 0004 tienen evidencia de aplicación estructural en [datos/deploy/README.md](../../datos/deploy/README.md), pero eso no acredita handlers, mensajería, grants efectivos ni E2E.

## Adenda documental Catálogo — resoluciones 1–9

Esta adenda conserva las DEC-F existentes y no crea una DEC-F nueva. Las resoluciones funcionales fueron comunicadas por sus responsables conforme al encargo; no se presentan como comentarios o commits que no constan en GitHub. Cuando falta ratificación pública, el estado es «decisión comunicada; pendiente de registrar trazabilidad en repositorio».

| Punto | Estado interno documentado | Estado externo / implementación |
|---|---|---|
| D-CAT-05/06, elegibilidad común de canales | Política funcional descrita; ratificación pendiente | Pendiente de Arquitectura y conformidad de consumidores; sin tablas ni implementación inferida |
| `precioMin` / `precioMax` | Regla inclusiva sobre precio efectivo vigente de Pricing, solo PEN; exclusión de otras monedas es criterio técnico recomendado | Mapeo SKU/producto, canales y autorización Catálogo↔Pricing no homologados; runtime no acreditado |
| D-CAT-01..04, códigos de barras | Definición funcional cerrada por Catálogo | Candidatos backend `poma` (migración 0002 y componentes de servicio/repositorio); aplicación y homologación no acreditadas; ratificación formal por trazar |
| Q-06 | Regla comunicada para corrección de tipo mediante PATCH, con precondiciones verificables | Trazabilidad formal, `publicado_alguna_vez`, migración e implementación pendientes |
| Retry `REJECTED` / `PENDING` | `REJECTED` no reintentable; timeout PENDING requiere condiciones verificadas; diseño de 300000 ms comunicado | Compatibilidad de diseño confirmada por Pricing/Inventory; pruebas integradas y homologación pendientes |
| SKU de variante | Obligatorio, explícito, global e inmutable | Contrato documental actualizado; implementación no acreditada por esta adenda |
| Barreras Taxonomy | Semántica y persistencia futura descritas; timeout inicial de 60 s | Migración propia de Taxonomy requiere autorización de Marco; especialización AsyncAPI pendiente de homologación por ser cambio compartido |
| `400 VALIDACION` variantes | Regla de validación comunicada y reflejada en OpenAPI | Trazabilidad formal, pruebas y runtime pendientes |

Persistencia: `catalog.master_barriers` ya está en la migración inicial; `catalog.sku_barcodes` existe como migración candidata `0002` en backend `poma`, sin despliegue acreditado; `catalog.products.publicado_alguna_vez` y `taxonomy.master_deactivation_operations.source_version`, `product_type_characteristics.taxonomy_version` e índice parcial activo requieren futuras migraciones versionadas de sus owners. No editar migraciones históricas ni inferir aplicación.

Los mensajes de baja de maestros mantienen sus nombres, exchanges y routing keys vigentes en AsyncAPI. La propuesta de tipar `data`, exigir `operation_id` para esas cuatro operaciones y especializar sus razones requiere revisión y homologación del contrato compartido; este documento no acredita aceptación externa ni autoriza sustituir los schemas ejecutables actuales.

## DEC-F-001 — SKU vendible como identidad comercial compartida

**Acuerdo privado skuContext registrado el 2026-10-26.** Marco aprobó el diseño de Pricing → Catálogo comunicado por Poma: [acuerdo y estados](../../integraciones/ACUERDO_PRICING_CATALOGO_SKU_CONTEXT.md), reflejado en OpenAPI mediante `obtenerContextoSku`. Se reutiliza el DTO del puerto `PricingCatalogContext` y el mecanismo de servicio existente, sin nueva DEC-F. La aprobación interna de la identidad propuesta `modulo-pricing` no acredita confirmación de registro, grant, token G7 ni implementación/pruebas Backend. El acuerdo permite documentar y desarrollar la frontera propia; la llamada real autenticada depende específicamente de G7.

**Enunciado y justificación.** Precio, disponibilidad, reserva, consumo, combos y referencias comerciales convergen en el SKU vendible canónico de Catálogo. Evita que producto, variante y código de barras se traten como la misma identidad.

**Invariantes G6.** Producto simple: `sku_base` vendible. Producto con variantes: cada variante vendible tiene SKU propio. Inventario se identifica por `(sku, location_id)`; Pricing resuelve herencia/override; combos se expanden a SKU y cantidad. El código de barras es texto opaco y se resuelve a un SKU; no lo sustituye.

**Responsabilidades externas.** Retail captura y envía el código sin transformación y usa el SKU resuelto. Otros consumidores usan el identificador devuelto; no redefinen SKU ni acceden a tablas de Catálogo.

**Estados.** Interno: adoptado. Externo: alineación de Retail documentada; homologación transversal no acreditada. Implementación: contratos/modelos documentados, runtime no acreditado. Pruebas: casos definidos, cierre integral no acreditado.

**Referencias y pendientes.** SPEC-002/003/004/013/015, HU-003/004, FLOW-003/004, OpenAPI, Modelo Conceptual, ALINEACION_RETAIL y persistencias de catálogo/inventario/pricing. Auditar resolución única, ceros iniciales, SKU no vendible y cobertura de variantes.

## DEC-F-002 — Inventario como única autoridad de stock

**Enunciado y justificación.** `inventory-svc` es propietario del saldo autoritativo, reservas y movimientos; evita saldos paralelos, dobles consumos y divergencia entre módulos.

**Invariantes G6.** El stock central de Inventario es autoritativo por `(sku, location_id)`; `available=max(on_hand-reserved-blocked,0)` con componentes no negativos y `reserved+blocked<=on_hand`. Durante desconexión, un POS puede mantener estado local/provisional de ventas, pero no sustituye ni actualiza por sí solo el saldo central. La conciliación aplica solo cantidades admisibles (`applied_quantity=min(requested_quantity, available)`), conserva el remanente no conciliado para revisión y nunca crea saldo negativo. Las mutaciones centrales dejan Kardex y preservan idempotencia/atomicidad; la proyección comercial no revela saldos privados.

**Responsabilidades externas.** Ventas es dueño del pedido/pago y coordina su flujo. Retail conserva una venta POS local/provisional durante desconexión. El nuevo antecedente comunica que Retail llama directamente a G6 para conciliar la venta offline; las alineaciones G6 actuales describen el camino Retail→Ventas→G6. La ruta invocadora requiere homologación documental externa; no se infiere orden entre creación del pedido, cobro, conciliación y consumo de stock.

**Estados.** Interno: adoptado. Externo: contradicción de documentación sobre invocador, pendiente de homologación; demás permisos no se consideran concedidos por aparecer en contrato. Implementación: hay evidencia estructural de migraciones citadas, backend funcional no acreditado. Pruebas: pendientes de ejecución E2E.

**Referencias y pendientes.** SPEC-015, HU-015, FLOW-015, OpenAPI, Arquitectura, Modelo Conceptual, ALINEACION_RETAIL/VENTAS, `datos/inventory-svc/*`, pruebas de contrato. Resolver la ruta Retail↔G6↔Ventas y validar permisos, concurrencia, Kardex y conciliación sin escritura cruzada.

## DEC-F-003 — Ventas/Postventa orquesta el ciclo comercial; `202` no es éxito final

**Enunciado y justificación.** La secuencia depende del canal y del contrato aplicable. Para Marketplace y Chatbot, G5 crea el pedido `CREADO` y coordina la reserva de Inventario conforme a su contrato; `202 Accepted` de G6 admite un comando, no confirma su resultado. Retail tiene una secuencia distinta en el contrato G5 API v1.5.0 reportado: pedido `PAGADO` y `ENTREGADO` sin reserva; el nuevo antecedente de integración indica que Retail llama directamente a G6 para conciliar ventas offline. G4 v0.4 mantiene otra secuencia que aún requiere homologación. Se preservan estas diferencias sin imponer una secuencia común.

**Invariantes G6.** Reserva, consumo y liberación requieren resultado definitivo durable. Para el flujo de Marketplace/Chatbot, no afirmar reserva tras un mero `202`. No continuar un beneficio con cupón rechazado. Inventario emite `expires_at`; Promociones decide consumo/restauración dentro de su política. Pago y estado del pedido no pertenecen a G6. No inferir el orden definitivo entre pedido, cobro, conciliación y consumo de stock para Retail o G4.

**Responsabilidades externas.** G5 mantiene pedido/pago y coordina el flujo de Marketplace/Chatbot según su contrato. Para Retail rige la secuencia distinta que el contrato G5 v1.5.0 describe y el antecedente de llamada directa a G6 para conciliación; la documentación G6 existente difiere y debe homologarse. G4 v0.4 también requiere homologación. Los canales no convierten una admisión G6 en confirmación de compra. No se atribuye aquí una secuencia definitiva común.

**Estados.** Interno: adoptado con flujos por canal distinguidos. Externo: Marketplace/Chatbot, Retail y G4 tienen descripciones distintas; homologación Retail/G6 y G4 pendiente, y ratificación G5 donde la alineación la requiere. Implementación: contratos candidatos; handlers y compatibilidad de consumidores no acreditados. Pruebas: E2E por canal y resultado tras `202` pendientes.

**Referencias y pendientes.** SPEC/HU/FLOW-002/005/015, [ALINEACION_VENTAS.md](../../integraciones/ALINEACION_VENTAS.md), [ALINEACION_RETAIL.md](../../integraciones/ALINEACION_RETAIL.md), OpenAPI, AsyncAPI, catálogo de eventos y matriz de pruebas. La alineación G5 cita `specs/api/api-ventas.md` v1.5.0; el registro maestro aporta el antecedente Retail y G4 v0.4. Resolver las diferencias de secuencia con los owners sin alterar contratos ni imponer orden de pedido/cobro/conciliación/consumo.

## DEC-F-004 — Pedido opaco, operación UUID y reserva UUID

**Enunciado y justificación.** `order_id` textual opaco de Ventas, `operation_id` UUID lógico, `reservation_id` UUID de Inventario y `message_id` de transporte son identidades distintas para evitar conversiones artificiales y pérdida de correlación.

**Invariantes G6.** No convertir `order_id` a UUID ni confundir correlación/dedupe de mensaje con idempotencia de negocio. Persistir resultado durable antes de publicar; tratar datos legados sin IDs según estrategia explícita. `202` no implica `COMPLETED`.

**Responsabilidades externas.** Ventas conserva su pedido y propaga/reutiliza la identidad de operación acordada; Seguridad valida identidad del cliente. El scope candidato de consulta durable requiere registro/concesión G7 antes de uso efectivo.

**Estados.** Interno: adoptado. Externo: contrato de Ventas y scope G7 pendientes de ratificación/concesión según alineación. Implementación: B1 en contratos candidatos y migración documentada; operación en runtime no acreditada. Pruebas: correlación/legados pendientes.

**Referencias y pendientes.** ADR B1/B2, SPEC-015, HU/FLOW-015, OpenAPI, AsyncAPI, ALINEACION_VENTAS, `datos/inventory-svc/migrations/0002*`, pruebas. Verificar rollout/compatibilidad de `order_id` textual y consulta durable.

## DEC-F-005 — Disponibilidad comercial por SKU y cantidad sin revelar saldos

**Enunciado y justificación.** Canales reciben proyección comercial; suficiencia por cantidad/contexto solo se afirma si una fuente ejecutable puede cubrirla. Impide sumar ubicaciones sin capacidad multi-origen demostrada y filtrar datos internos.

**Invariantes G6.** Política D-INV-01 adoptada en ADR B3: una ubicación elegible por contexto de cumplimiento, sin sumas independientes. Mapeo ausente/ambiguo o cumplimiento no demostrable produce `INDETERMINADO`. Verificar cantidad es consulta sin efectos, no reserva; no exponer `location_id` ni saldos.

**Responsabilidades externas.** Canales proveen contexto público de cumplimiento y no interpretan `INDETERMINADO` como agotado. Ventas reserva por su flujo autorizado.

**Estados.** Interno: adoptado. Externo: regla reflejada en alineaciones de canales; conformidad de cada consumidor no acreditada. Implementación: endpoints `0.6.0-rc.1` provisionales. Pruebas: pendientes de ejecución.

**Referencias y pendientes.** SPEC/HU/FLOW-015 y SPEC-002, ADR B3, OpenAPI, AsyncAPI, Arquitectura, Modelo, alineaciones, persistencia Inventory y pruebas. Confirmar mapeos/scopes/handlers; multi-origen queda fuera de alcance y requeriría otra decisión.

## DEC-F-006 — Pricing resuelve precios por SKU, canal y vigencia

**Enunciado y justificación.** `pricing-svc` es autoridad de precio regular/oferta, moneda, alcance, canal, vigencia, versión e historial; evita autoridades monetarias paralelas.

**Invariantes G6.** Según SPEC-013, el SKU vendible simple hereda el precio del producto y una variante puede heredar o usar override propio. Precio por canal sigue precedencia específica/global y su fallback definido en SPEC-013; no se permiten vigencias superpuestas para el mismo objetivo y canal. Las escrituras condicionadas respetan `price_version`; una versión obsoleta produce `VERSION_CONFLICT`. `pricing-svc` calcula y persiste el precio vigente; `price-audit-svc` registra la bitácora/historial y no autoriza ni mantiene un precio mutable paralelo. Promociones calcula beneficios sobre una referencia, no posee precio base; Ventas conserva su snapshot sin editar precios.

**Responsabilidades externas.** Canales y Ventas consultan/respetan precio, canal y vigencia; no escriben precios definitivos en esquemas ajenos.

**Estados.** Interno: adoptado según antecedente y reglas de SPEC-013. Externo: revisión transversal pendiente. Implementación: documentación y persistencia presentes; ejecución integral y contratos runtime no acreditados. Pruebas: cierre no acreditado.

**Referencias y pendientes.** SPEC/HU/FLOW-013/014, SPEC-003/004, OpenAPI/AsyncAPI, Arquitectura/Modelo, alineaciones y `datos/pricing`, `datos/price_audit`, pruebas. Contrastar fallback/prioridad con cada contrato aplicable y ejecutar pruebas de vigencias, herencia, concurrencia, `VERSION_CONFLICT` e historial.

## DEC-F-007 — Promociones es autoridad de beneficios, campañas y cupones

**Enunciado y justificación.** `promotions-svc` gobierna campañas, elegibilidad, límites, cupones y sus consumos; evita duplicar reglas y contadores.

**Invariantes G6.** Evaluar/validar cupón no consume ni reserva cupo. Promociones no posee precio base, pedido ni pago. Consumo respeta límites atómicos y la identidad cliente permitida por contrato.

**Responsabilidades externas.** Ventas posee decisión de compra, snapshot y pago, y solicita consumo; canales usan evaluación sin mutar contadores. Seguridad controla identidad/scopes.

**Estados.** Interno: adoptado. Externo: integración de Ventas pendiente de cierre E2E. Implementación: límites/modelos documentados; consumo productivo y grants no acreditados. Pruebas: concurrencia/último cupo pendientes.

**Referencias y pendientes.** SPEC/HU/FLOW-005/006/007, OpenAPI/AsyncAPI, Modelo, ALINEACION_VENTAS, `datos/promotions/*`, pruebas. Verificar alcance producto/SKU, elegibilidad, identidad y consumo una vez.

## DEC-F-008 — Consumo y restauración de cupones atómicos e idempotentes

**Enunciado y justificación.** Consumo tiene efecto a lo sumo una vez; restaurar requiere consumo confirmado y aplica política del owner. Evita doble consumo/restauración y cupos incoherentes.

**Invariantes G6.** La precondición de consumo del flujo al que aplica es una reserva de Inventario efectivamente confirmada: HTTP `202` por sí solo no basta. La solicitud se relaciona con `reservation_id` UUID de esa reserva, `commercial_snapshot_ref` durable, `order_id` opaco y `operation_id` UUID. En esa secuencia, Promociones debe emitir el consumo y su resultado definitivo tipado antes de que Ventas intente cobrar; rechazo no permite cobrar con ese snapshot. El snapshot no reemplaza la revalidación autoritativa de cupo global, cupo por cliente, elegibilidad y coherencia con el pedido, que debe hacerse atómicamente al consumir. La unicidad de negocio `(order_id, coupon_id)` —a lo sumo un consumo por pedido y cupón— es distinta de la idempotencia técnica del comando por `operation_id`; una operación nueva no habilita segundo consumo. Restaurar exige consumo confirmado y aplica `RESTAURAR_EN_CANCELACION` o `NO_RESTAURAR`, de manera atómica/idempotente; no crea uso inexistente ni excede límites. La secuencia de consumo no se relaja para Retail: el flujo Retail sin reserva no tiene mecanismo de cupón aprobado en este registro.

**Responsabilidades externas.** En el flujo aplicable, Ventas aporta las referencias, solicita consumo/restauración y decide estado/pago del pedido. Retail concilia su venta offline bajo una secuencia aún pendiente de homologación; la llamada directa Retail→G6 no establece un mecanismo de cupón sin reserva. No se inventa reserva ficticia, mensaje ni DTO para ese caso.

**Estados.** Interno: adoptado con precondiciones preservadas. Externo: semántica G5/cupón requiere homologación donde aplique; no hay mecanismo Retail sin reserva aprobado aquí. Implementación: B4 candidato; migración 0004 cuenta con postcheck estructural documentado, backend transaccional no acreditado. Pruebas: carreras y E2E pendientes.

**Referencias y pendientes.** SPEC-005/002/006, HU/FLOW-005, ADR B4, AsyncAPI, ALINEACION_VENTAS, `datos/promotions/migrations/0004*`, matriz de pruebas. Homologar correlación/restauración sin cambiar precondiciones; no crear mecanismo de cupón para venta offline.

## DEC-F-009 — Idempotencia por identidad, intención y contenido

**Enunciado y justificación.** Retry equivalente repite resultado sin efectos; reutilizar identidad con intención/payload semántico distinto produce conflicto. Separa operación de negocio, dedupe de transporte y correlación.

**Invariantes G6.** Para mutaciones, distinguir identidad estable del comando, identidad de mensaje/reintento técnico y correlación. En ventas offline, POS puede conservar estado local/provisional mientras no hay conexión; el saldo central sigue siendo autoritativo y solo cantidades admisibles se concilian sin saldo negativo. La deduplicación por identidad estable de la venta offline, independiente del identificador técnico de reintento, está pendiente. No se fija nombre de campo, índice, fingerprint ni clave compuesta sin contrato aprobado. Para el resto de mutaciones se mantiene la regla general: retry semánticamente idéntico sin efecto repetido; identidad de comando reutilizada con intención/contenido distinto, conflicto. `message_id` deduplica entrega, `correlation_id` agrupa traza; ninguno sustituye idempotencia de negocio. No prometer “exactly once”.

**Responsabilidades externas.** Consumidores reintentan con identidad/intención estables y procesan resultados tipados; G6 valida actor, scope y propiedad.

**Estados.** Interno: adoptado como principio. Externo: ámbito transversal completo y deduplicación de venta offline pendientes de homologación. Implementación: parcial/candidata; constraint/ledger existente no prueba handlers conformes. Pruebas: carreras, retry técnico vs venta offline duplicada y fallos entre efecto/Outbox pendientes.

**Referencias y pendientes.** SPEC-003/004/005/015, OpenAPI, AsyncAPI, catálogo de errores/eventos, Arquitectura, persistencias Inventory/Promotions y pruebas. Resolver y probar ámbito de unicidad e identidad estable de venta offline; no alterar índices ni elegir nombre/clave por inferencia.

## DEC-F-010 — Inventario determina TTL y expiración de reservas

**Enunciado y justificación.** Inventario calcula y aplica expiración; consumidores respetan `expires_at`, evitando temporizadores locales contradictorios.

**Invariantes G6.** El TTL comercial es configurable por canal/entorno; Inventario calcula y emite `expires_at` para cada reserva efectivamente creada, y el consumidor respeta ese instante en vez de recalcularlo localmente. Expiración solo libera reserva aún activa; consumo/liberación/expiración se serializan y estados terminales no reviven por replay. TTL comercial de la reserva y TTL de transporte/reintento son distintos. No se fija duración ni condición adicional en este registro.

**Responsabilidades externas.** Ventas usa el vencimiento emitido para checkout y no inventa duración. No decide saldos ni extiende reserva unilateralmente.

**Estados.** Interno: adoptado. Externo: regla descrita en alineación Ventas; integración completa no certificada. Implementación: candidato contractual; cálculo, worker y transiciones no acreditados. Pruebas: concurrencia, configuración por canal/entorno y reloj pendientes.

**Referencias y pendientes.** SPEC/HU/FLOW-015, OpenAPI/AsyncAPI, Arquitectura, ALINEACION_VENTAS, persistencia Inventory e integración. Verificar TTL configurable, cálculo/emisión de `expires_at`, worker, serialización y replay sin imponer duración.

## DEC-F-011 — Catálogo posee perfil físico; Despacho decide logística

**Enunciado y justificación.** Catálogo posee peso/dimensiones intrínsecos del SKU vendible; Despacho decide embalaje, paquetes, agrupación, rutas y capacidad. Evita convertir Catálogo en planificador logístico.

**Invariantes G6.** Perfil por SKU vendible; DTO exacto es el OpenAPI (dimensiones anidadas según contrato). Compleción requerida al activar según SPEC. G6 no determina caja, volumen de embalaje ni plan de transporte.

**Responsabilidades externas.** Despacho consulta el perfil y mantiene su autoridad logística; no escribe perfil maestro de Catálogo.

**Estados.** Interno: adoptado. Externo: el contrato G2 declara acordadas por ambos equipos la ruta y autorización de consulta física por lote desde `modulo-despacho` con scope `productos:fisicos:leer`. Ese acuerdo documental no acredita la aprobación/registro/concesión administrativa del permiso por Seguridad ni la provisión efectiva de credenciales. Implementación: endpoint/modelos documentados; runtime no acreditado. Pruebas: no certificadas.

**Referencias y pendientes.** SPEC/HU/FLOW-003/004, OpenAPI, Arquitectura §1.4, Modelo, catálogo físico y pruebas; contrato externo G2 [`integraciones/api-contract.md`](https://github.com/Taller-SW-Web/G2-Despacho-Specs/blob/main/integraciones/api-contract.md) §3.4 y §5.2. La operación documentada es `POST /api/v1/productos/datos-fisicos/consulta`, `aud=api-productos`, `scope=productos:fisicos:leer`, cliente `modulo-despacho`. Verificar separadamente aprobación, grant de Seguridad, provisión de credenciales y pruebas de integración.

## DEC-F-012 — Fuentes normativas, contratos versionados y compatibilidad

**Enunciado y justificación.** Integraciones dependen de fuentes normativas explícitas, versiones y cambios trazables; evita que narrativa o implementaciones implícitas contradigan contratos y consumidores.

**Invariantes G6.** Estados de decisión, contrato, implementación y pruebas se informan por separado. Cambios incompatibles requieren versionado/transición y coordinación. Scope declarado no prueba grant. Migración aplicada/checksum no se reescribe; cambios nuevos son incrementales. B1–B4 no reemplazan DEC-F.

**Responsabilidades externas.** Cada módulo dueño acepta/versiona sus contratos; G7 concede scopes y consumidores validan compatibilidad. No afirmar homologación sin evidencia.

**Estados.** Interno: adoptado como gobernanza. Externo: pendientes de homologación concretos, incluida conciliación Retail. Implementación: OpenAPI/AsyncAPI `0.6.0-rc.1` candidatos en master tras merge #86, no evidencia de backend/E2E. Pruebas: varios casos explícitamente pendientes.

**Referencias y pendientes.** README, SPEC/HU/FLOW afectados, OpenAPI/AsyncAPI, contratos guía, Arquitectura/Modelo, alineaciones, persistencia/migraciones y matriz de pruebas. La matriz adjunta clasifica referencias sin declarar completa ninguna decisión.

## DEC-F-013 — Conciliación offline autoritativa

**Enunciado y justificación.** Inventario conserva autoridad sobre el stock central al conciliar ventas offline que ya ocurrieron físicamente. La conciliación refleja únicamente cantidades admisibles y evita reservas retroactivas y dobles descuentos.

**Invariantes G6.** Aplicar solo las cantidades admisibles conforme a SPEC-015; permitir conciliación parcial y registrar cantidades no resueltas; no producir saldos negativos ni consumir unidades reservadas o bloqueadas; registrar mutaciones efectivas mediante Kardex y el mecanismo transaccional correspondiente. Una misma venta física no puede causar un segundo descuento por reintentos o mensajes repetidos.

**Responsabilidades externas.** Retail conserva la venta física y sus datos locales; la invocación y la secuencia con pedido/pago requieren homologación. No se atribuye a Retail o Ventas una identidad o mecanismo no acordado.

**Estados.** Interno: `ADOPTADA_G6`, aprobada por Marco el 2026-10-13. Externo: invocador y secuencia pendientes de homologación. Implementación: no acreditada por OpenAPI 0.6.0-rc.1. Pruebas: autorización y pruebas integradas pendientes.

**Referencias y pendientes.** SPEC-015 §24.4–24.5 documenta conciliación parcial (`applied_quantity`, `unresolved_quantity`) y ausencia de reserva retroactiva; OpenAPI define `offline_sale_id` y `operation_id`. Pendientes: correspondencia G4 `ventaLocalUuid`/G6 `offline_sale_id`, estabilidad y ámbito de unicidad de identidad offline, idempotencia frente a múltiples `operation_id`, homologación del invocador G4/G5, secuencia con pedido/pago, autorización y pruebas integradas. No se crean campos, índices, DTO ni mecanismos.

## DEC-F-014 — Resolución segura de tienda a ubicación

**Enunciado y justificación.** Una referencia pública de tienda no identifica por sí misma una ubicación interna; Inventario debe resolver y autorizar internamente la ubicación antes de una mutación.

**Invariantes G6.** Inventario resuelve tienda a ubicación física. Una lectura comercial suficiente no autoriza escritura. El consumidor no escoge libremente una ubicación para mutar saldos. Se rechaza de forma segura la mutación cuando el mapeo es inexistente o ambiguo, o el actor no está autorizado para la operación y ubicación.

**Responsabilidades externas.** Retail aporta la referencia pública convenida y Seguridad conserva la autoridad sobre grants y credenciales. Aprobación del consumidor técnico y homologación G4/G7 siguen pendientes.

**Estados.** Interno: `ADOPTADA_G6`, aprobación de Marco 2026-10-13. Externo: pendiente. Implementación: no acreditada; el contrato actual no se modifica. Pruebas: acceso indebido y mapeos ambiguos pendientes.

**Referencias y pendientes.** OpenAPI `ConciliacionOfflineRequest.lines` referencia `LineaInventarioUbicada`, cuyo `location_id` es obligatorio. Esta incompatibilidad contractual permanece; la decisión no cambia automáticamente el contrato. Pendientes: contrato de entrada compatible con Retail, mecanismo exacto de resolución/autorización, aprobación del consumidor técnico y homologación G4/G7. No se inventa solución contractual.

## DEC-F-015 — Minimización de datos de conciliación para Retail

**Enunciado y justificación.** Retail debe conocer el resultado de su conciliación con la información necesaria, bajo mínimo privilegio.

**Invariantes G6.** No exponer saldos internos ni ubicaciones internas innecesarios para ese propósito. Aplicar mínimo privilegio según identidad, scope, allowlist y operación. Se distinguen las cantidades funcionales `requested_quantity`, `applied_quantity` y `unresolved_quantity` de los saldos internos.

**Responsabilidades externas.** Los consumidores autorizados y Seguridad deben homologar representación y acceso. No se afirma una operación GET de recuperación para Retail.

**Estados.** Interno: `ADOPTADA_G6`, aprobación de Marco 2026-10-13. Externo: pendiente de homologación G4/G7. Implementación: representación contractual definitiva no aprobada; OpenAPI 0.6.0-rc.1 no se considera implementación. Pruebas: compatibilidad y autorización pendientes.

**Referencias y pendientes.** OpenAPI `ConciliacionOfflineLineaResultado` incluye `location_id`, `on_hand`, `reserved`, `blocked`, `available` y `stock_version`, además de las cantidades funcionales. Pendientes: DTO compatible, consumidores autorizados, mecanismo eventual de consulta posterior, homologación G4/G7, compatibilidad y pruebas. No se afirma que exista un GET autorizado para Retail.

## Pendientes transversales

1. Homologar documentalmente la invocación de conciliación offline: antecedente comunica Retail→G6 directo; alineaciones describen Ventas→G6. No inferir orden entre creación de pedido y conciliación.
2. No inventar consumo/restauración de cupón para venta offline sin reserva; elevar a owners de negocio si se requiere.
3. Mantener `0.6.0-rc.1` como candidato mientras falte evidencia de implementación y conformidad E2E.
4. Resolver referencias contradichas o incompletas según [MATRIZ_TRAZABILIDAD_DEC_F.md](MATRIZ_TRAZABILIDAD_DEC_F.md); ninguna decisión se declara completa.

## Referencia de estado G1 Marketplace H4 — 2026-10-20

G6 comunicó aceptación de M-01–M-09 (`ACEPTADO_G6_COMUNICADO_G1`). Esto no altera las invariantes DEC-F ni atribuye decisiones a G1/G2/G5/G7. Para correspondencia y estado de cada operación consultar el [Acuerdo H4](../../integraciones/ACUERDO_G1_G6_H4_2026-10-20.md) y la [alineación](../../integraciones/ALINEACION_MARKETPLACE.md). Las declaraciones internas de decisiones adoptadas no equivalen a contrato implementado, grant, despliegue o E2E.
