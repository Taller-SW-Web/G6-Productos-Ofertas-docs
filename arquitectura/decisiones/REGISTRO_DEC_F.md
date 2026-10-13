# Registro de decisiones DEC-F — G6 Productos y Ofertas

- **Corte de contraste:** `origin/master` `78a923bbc6bada31b39b3d386331f90a4f812b31` (merge de PR #86).
- **Antecedente:** `G6_REGISTRO_MAESTRO_12_DECISIONES_DEC-F_2026-10-12.md`, recibido el 12-10-2026.
- **Alcance:** formaliza únicamente DEC-F-001–DEC-F-012, aprobadas conceptualmente por G6. B1–B4 son bloqueantes de integración del PR #86, no decisiones adicionales ni sustitutos. Se conserva [ADR-DEC-F-BLOQUEANTES.md](ADR-DEC-F-BLOQUEANTES.md).
- **Estado global:** adopción interna conceptual registrada; la homologación externa, implementación y verificación integral no se infieren de este documento.

## Estados y lectura

“Adoptado” describe la decisión interna reportada por el antecedente/ADR. “Homologado” requiere evidencia de aceptación externa. “Implementado” requiere evidencia de código/backend; “probado” requiere resultados reproducibles identificados. La presencia de documentación o contratos candidatos no satisface esos estados.

PR #86 está fusionado en el `master` contrastado. OpenAPI y AsyncAPI `0.6.0-rc.1` continúan descritos en el repositorio como candidatos/provisionales; su fusión no acredita integración E2E. Las migraciones Inventario 0002 y Promociones 0004 tienen evidencia de aplicación estructural en [datos/deploy/README.md](../../datos/deploy/README.md), pero eso no acredita handlers, mensajería, grants efectivos ni E2E.

## DEC-F-001 — SKU vendible como identidad comercial compartida

**Enunciado y justificación.** Precio, disponibilidad, reserva, consumo, combos y referencias comerciales convergen en el SKU vendible canónico de Catálogo. Evita que producto, variante y código de barras se traten como la misma identidad.

**Invariantes G6.** Producto simple: `sku_base` vendible. Producto con variantes: cada variante vendible tiene SKU propio. Inventario se identifica por `(sku, location_id)`; Pricing resuelve herencia/override; combos se expanden a SKU y cantidad. El código de barras es texto opaco y se resuelve a un SKU; no lo sustituye.

**Responsabilidades externas.** Retail captura y envía el código sin transformación y usa el SKU resuelto. Otros consumidores usan el identificador devuelto; no redefinen SKU ni acceden a tablas de Catálogo.

**Estados.** Interno: adoptado. Externo: alineación de Retail documentada; homologación transversal no acreditada. Implementación: contratos/modelos documentados, runtime no acreditado. Pruebas: casos definidos, cierre integral no acreditado.

**Referencias y pendientes.** SPEC-002/003/004/013/015, HU-003/004, FLOW-003/004, OpenAPI, Modelo Conceptual, ALINEACION_RETAIL y persistencias de catálogo/inventario/pricing. Auditar resolución única, ceros iniciales, SKU no vendible y cobertura de variantes.

## DEC-F-002 — Inventario como única autoridad de stock

**Enunciado y justificación.** `inventory-svc` es propietario del saldo autoritativo, reservas y movimientos; evita saldos paralelos, dobles consumos y divergencia entre módulos.

**Invariantes G6.** Saldo por `(sku, location_id)`; `available=max(on_hand-reserved-blocked,0)` con componentes no negativos y `reserved+blocked<=on_hand`. Mutaciones dejan trazabilidad Kardex y preservan idempotencia/atomicidad. La proyección comercial no revela saldos privados. La conciliación offline es una capacidad de Inventario; este registro no define quién la invoca.

**Responsabilidades externas.** Ventas orquesta acciones de pedido; Retail informa hechos físicos autorizados. El antecedente comunica que Retail llama directamente a G6 para conciliación offline. Las alineaciones actuales también describen conciliación desde Ventas. La ruta invocadora requiere homologación documental externa; no se infiere orden entre creación del pedido y conciliación.

**Estados.** Interno: adoptado. Externo: contradicción de documentación sobre invocador, pendiente de homologación; demás permisos no se consideran concedidos por aparecer en contrato. Implementación: hay evidencia estructural de migraciones citadas, backend funcional no acreditado. Pruebas: pendientes de ejecución E2E.

**Referencias y pendientes.** SPEC-015, HU-015, FLOW-015, OpenAPI, Arquitectura, Modelo Conceptual, ALINEACION_RETAIL/VENTAS, `datos/inventory-svc/*`, pruebas de contrato. Resolver la ruta Retail↔G6↔Ventas y validar permisos, concurrencia, Kardex y conciliación sin escritura cruzada.

## DEC-F-003 — Ventas/Postventa orquesta el ciclo comercial; `202` no es éxito final

**Enunciado y justificación.** Ventas posee pedido y orquesta inventario/cupones; G6 ejecuta las mutaciones de Inventario y Promociones. `202 Accepted` admite un comando, no confirma su resultado.

**Invariantes G6.** Reserva, consumo y liberación requieren resultado definitivo durable. No afirmar reserva ni continuar un beneficio con cupón rechazado. Inventario emite `expires_at`; Promociones decide consumo/restauración dentro de su política. Pago y estado del pedido no pertenecen a G6.

**Responsabilidades externas.** Ventas integra los resultados, mantiene el pedido/pago y orquesta el flujo; los canales no convierten una admisión G6 en confirmación de compra. La secuencia exacta de checkout debe respetar SPEC/contratos y homologación.

**Estados.** Interno: adoptado. Externo: integración G5 requiere ratificación explícita según ALINEACION_VENTAS. Implementación: contratos candidatos; handlers y compatibilidad de consumidores no acreditados. Pruebas: E2E 202+resultado pendientes.

**Referencias y pendientes.** SPEC/HU/FLOW-002/005/015, ALINEACION_VENTAS, OpenAPI, AsyncAPI, catálogo de eventos y matriz de pruebas. Validar resultado tras `202`, recuperación, fallo de pago y transiciones concurrentes.

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

**Invariantes G6.** SKU simple/variante sigue reglas documentadas de herencia/override. Promociones calcula beneficios sobre referencia de precio, no posee precio base. Ventas conserva snapshot de pedido sin editar el catálogo de precios; auditoría conserva hechos de cambio.

**Responsabilidades externas.** Canales y Ventas consultan/respetan precio, canal y vigencia; no escriben precios definitivos en esquemas ajenos.

**Estados.** Interno: adoptado según antecedente. Externo: revisión transversal pendiente. Implementación: documentación y persistencia presentes; ejecución integral y contratos runtime no acreditados. Pruebas: cierre no acreditado.

**Referencias y pendientes.** SPEC/HU/FLOW-013/014, SPEC-003/004, OpenAPI/AsyncAPI, Arquitectura/Modelo, alineaciones y `datos/pricing`, `datos/price_audit`, pruebas. Auditar vigencias, herencia, concurrencia e historial.

## DEC-F-007 — Promociones es autoridad de beneficios, campañas y cupones

**Enunciado y justificación.** `promotions-svc` gobierna campañas, elegibilidad, límites, cupones y sus consumos; evita duplicar reglas y contadores.

**Invariantes G6.** Evaluar/validar cupón no consume ni reserva cupo. Promociones no posee precio base, pedido ni pago. Consumo respeta límites atómicos y la identidad cliente permitida por contrato.

**Responsabilidades externas.** Ventas posee decisión de compra, snapshot y pago, y solicita consumo; canales usan evaluación sin mutar contadores. Seguridad controla identidad/scopes.

**Estados.** Interno: adoptado. Externo: integración de Ventas pendiente de cierre E2E. Implementación: límites/modelos documentados; consumo productivo y grants no acreditados. Pruebas: concurrencia/último cupo pendientes.

**Referencias y pendientes.** SPEC/HU/FLOW-005/006/007, OpenAPI/AsyncAPI, Modelo, ALINEACION_VENTAS, `datos/promotions/*`, pruebas. Verificar alcance producto/SKU, elegibilidad, identidad y consumo una vez.

## DEC-F-008 — Consumo y restauración de cupones atómicos e idempotentes

**Enunciado y justificación.** Consumo tiene efecto a lo sumo una vez; restaurar requiere consumo confirmado y aplica política del owner. Evita doble consumo/restauración y cupos incoherentes.

**Invariantes G6.** Validación no consume. Replay semánticamente idéntico devuelve resultado sin efecto adicional; misma identidad con intención distinta se rechaza. Solo Promociones aplica política `RESTAURAR_EN_CANCELACION`/`NO_RESTAURAR`. El snapshot de Ventas no sustituye elegibilidad/cupo de Promociones.

**Responsabilidades externas.** Ventas solicita consumo/restauración y decide estado/pago del pedido. La llamada directa Retail a G6 informada para conciliación offline no establece un mecanismo de cupón sin reserva; no se infiere uno.

**Estados.** Interno: adoptado. Externo: semántica G5/cupón requiere homologación donde aplique. Implementación: B4 candidato; migración 0004 cuenta con postcheck estructural documentado, backend transaccional no acreditado. Pruebas: carreras y E2E pendientes.

**Referencias y pendientes.** SPEC-005/002/006, HU/FLOW-005, ADR B4, AsyncAPI, ALINEACION_VENTAS, `datos/promotions/migrations/0004*`, matriz de pruebas. Homologar correlación y política ante ambigüedad; no crear mecanismo de cupón para venta offline.

## DEC-F-009 — Idempotencia por identidad, intención y contenido

**Enunciado y justificación.** Retry equivalente repite resultado sin efectos; reutilizar identidad con intención/payload semántico distinto produce conflicto. Separa operación de negocio, dedupe de transporte y correlación.

**Invariantes G6.** Fingerprint semántico, ámbito definido y persistencia atómica; `message_id` deduplica entrega, `correlation_id` agrupa traza, ninguno por sí solo sustituye la clave de operación. No prometer “exactly once”.

**Responsabilidades externas.** Consumidores reintentan con identidad/intención estables y procesan resultados tipados; G6 valida actor, scope y propiedad.

**Estados.** Interno: adoptado como principio. Externo: ámbito transversal completo pendiente de homologación. Implementación: parcial/candidata; constraint/ledger existente no prueba handlers conformes. Pruebas: carreras y fallos entre efecto/Outbox pendientes.

**Referencias y pendientes.** SPEC-003/004/005/015, OpenAPI, AsyncAPI, catálogo de errores/eventos, Arquitectura, persistencias Inventory/Promotions y pruebas. Resolver y probar ámbito de unicidad; no alterar índices por inferencia.

## DEC-F-010 — Inventario determina TTL y expiración de reservas

**Enunciado y justificación.** Inventario calcula y aplica expiración; consumidores respetan `expires_at`, evitando temporizadores locales contradictorios.

**Invariantes G6.** Toda reserva confirmada publica vencimiento autoritativo. Expiración solo libera reserva aún activa; consumo/liberación/expiración se serializan y estados terminales no reviven por replay. TTL comercial no es TTL de transporte.

**Responsabilidades externas.** Ventas usa el vencimiento emitido para checkout y no inventa duración. No decide saldos ni extiende reserva unilateralmente.

**Estados.** Interno: adoptado. Externo: acuerdo descrito en alineación Ventas, integración completa no certificada. Implementación: candidato contractual; worker/transiciones no acreditados. Pruebas: concurrencia y reloj pendientes.

**Referencias y pendientes.** SPEC/HU/FLOW-015, OpenAPI/AsyncAPI, Arquitectura, ALINEACION_VENTAS, persistencia Inventory e integración. Verificar worker, serialización y replay.

## DEC-F-011 — Catálogo posee perfil físico; Despacho decide logística

**Enunciado y justificación.** Catálogo posee peso/dimensiones intrínsecos del SKU vendible; Despacho decide embalaje, paquetes, agrupación, rutas y capacidad. Evita convertir Catálogo en planificador logístico.

**Invariantes G6.** Perfil por SKU vendible; DTO exacto es el OpenAPI (dimensiones anidadas según contrato). Compleción requerida al activar según SPEC. G6 no determina caja, volumen de embalaje ni plan de transporte.

**Responsabilidades externas.** Despacho consulta el perfil y mantiene su autoridad logística; no escribe perfil maestro de Catálogo.

**Estados.** Interno: adoptado. Externo: conformidad de Despacho no acreditada en alineaciones disponibles. Implementación: endpoint/modelos documentados; runtime no acreditado. Pruebas: no certificadas.

**Referencias y pendientes.** SPEC/HU/FLOW-003/004, OpenAPI, Arquitectura §1.4, Modelo, catálogo físico y pruebas. Verificar scope, DTO, SKU variante y activación.

## DEC-F-012 — Fuentes normativas, contratos versionados y compatibilidad

**Enunciado y justificación.** Integraciones dependen de fuentes normativas explícitas, versiones y cambios trazables; evita que narrativa o implementaciones implícitas contradigan contratos y consumidores.

**Invariantes G6.** Estados de decisión, contrato, implementación y pruebas se informan por separado. Cambios incompatibles requieren versionado/transición y coordinación. Scope declarado no prueba grant. Migración aplicada/checksum no se reescribe; cambios nuevos son incrementales. B1–B4 no reemplazan DEC-F.

**Responsabilidades externas.** Cada módulo dueño acepta/versiona sus contratos; G7 concede scopes y consumidores validan compatibilidad. No afirmar homologación sin evidencia.

**Estados.** Interno: adoptado como gobernanza. Externo: pendientes de homologación concretos, incluida conciliación Retail. Implementación: OpenAPI/AsyncAPI `0.6.0-rc.1` candidatos en master tras merge #86, no evidencia de backend/E2E. Pruebas: varios casos explícitamente pendientes.

**Referencias y pendientes.** README, SPEC/HU/FLOW afectados, OpenAPI/AsyncAPI, contratos guía, Arquitectura/Modelo, alineaciones, persistencia/migraciones y matriz de pruebas. La matriz adjunta clasifica referencias sin declarar completa ninguna decisión.

## Pendientes transversales

1. Homologar documentalmente la invocación de conciliación offline: antecedente comunica Retail→G6 directo; alineaciones describen Ventas→G6. No inferir orden entre creación de pedido y conciliación.
2. No inventar consumo/restauración de cupón para venta offline sin reserva; elevar a owners de negocio si se requiere.
3. Mantener `0.6.0-rc.1` como candidato mientras falte evidencia de implementación y conformidad E2E.
4. Resolver referencias contradichas o incompletas según [MATRIZ_TRAZABILIDAD_DEC_F.md](MATRIZ_TRAZABILIDAD_DEC_F.md); ninguna decisión se declara completa.
