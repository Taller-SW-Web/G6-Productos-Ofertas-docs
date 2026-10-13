# HU-015 — Control de stock y disponibilidad

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** SPEC [SPEC-015](../specs/SPEC-015-control-stock-disponibilidad.md) | Wireframe [WF-015](../../ux/wireframes/flows/WF-015-control-stock-disponibilidad.md) | Decisión [ADR-DEC-F-BLOQUEANTES](../../arquitectura/decisiones/ADR-DEC-F-BLOQUEANTES.md) (B3 — D-INV-01)

---

## Historia principal

**Como** gestor comercial con capacidades de gestión de inventario,

**quiero** mantener por SKU y ubicación un saldo consistente que distinga unidades físicas, reservadas, bloqueadas y disponibles,

**para** evitar sobreventa, reflejar incidencias reales de tienda, procesar devoluciones correctamente y conciliar operaciones realizadas sin conectividad.

La unidad de inventario es:

```text
(sku, location_id)
```

y se cumple:

```text
available = max(on_hand - reserved - blocked, 0)
```

---

# Criterios de aceptación

| ID | Criterio |
|---|---|
| **CA-01** | Cada saldo autoritativo se identifica por `(sku, location_id)`. |
| **CA-02** | La **consulta detallada de saldo autoritativo** devuelve como mínimo `on_hand`, `reserved`, `blocked`, `available`, `status` y `stock_version` cuando corresponda; la proyección comercial tiene contrato diferente. |
| **CA-03** | `available = max(on_hand - reserved - blocked, 0)`. |
| **CA-04** | Siempre se cumple `on_hand >= 0`, `reserved >= 0`, `blocked >= 0`, `reserved + blocked <= on_hand` y `available >= 0`. |
| **CA-05** | El estado del saldo autoritativo `AGOTADO/STOCK_BAJO/DISPONIBLE` se calcula sobre `available` por `(sku, location_id)`; la proyección comercial aplica adicionalmente D-INV-01 y puede ser `INDETERMINADO`. |
| **CA-06** | Marketplace y Chatbot solo consultan Inventario. |
| **CA-07** | En la secuencia actualmente documentada por G6, Ventas/Postventa invoca las mutaciones comerciales, incluida la conciliación offline; una eventual invocación directa Retail→G6 permanece pendiente de homologación y este criterio no concede acceso a Retail. |
| **CA-08** | Cuando un pedido entra en `CREADO`, Ventas/Postventa puede solicitar idempotentemente una reserva. |
| **CA-09** | Reservar aumenta `reserved` y reduce `available` sin modificar `on_hand` ni `blocked`. |
| **CA-10** | Una reserva tiene estados `ACTIVA`, `CONSUMIDA`, `LIBERADA` o `EXPIRADA`; un estado terminal no vuelve a `ACTIVA`. |
| **CA-11** | Cuando el pedido pasa a `PAGADO`, Ventas confirma consumo: disminuyen `on_hand` y `reserved`; `blocked` no cambia. |
| **CA-12** | Ante `PAGO_NO_COMPLETADO` o anulación pre-consumo, Ventas libera la reserva: disminuye `reserved` y `on_hand` no aumenta. |
| **CA-13** | Confirmar, liberar y expirar concurrentemente una misma reserva solo puede producir una transición terminal. |
| **CA-14** | Reserva/consumo/liberación son idempotentes; reutilizar una identidad para otra intención produce `IDEMPOTENCY_CONFLICT`. |
| **CA-15** | Dos operaciones concurrentes nunca comprometen las mismas unidades disponibles. |
| **CA-16** | Toda mutación autoritativa registra Kardex con saldos anterior/posterior, operación, SKU y ubicación. |
| **CA-17** | Un ajuste absoluto de Bulk requiere `stock_version`; una versión obsoleta se rechaza con `VERSION_CONFLICT`. |
| **CA-18** | Un SKU nuevo se inicializa idempotentemente con `on_hand=0`, `reserved=0`, `blocked=0`, `available=0`. |
| **CA-19** | Después de una mutación confirmada se publica `inventory.stock.changed` cuando corresponda; el evento nunca sustituye al comando. |
| **CA-20** | Una devolución comercial aprobada no repone stock automáticamente. |
| **CA-21** | Ventas/Postventa puede reintegrar solo unidades físicamente recibidas y declaradas reintegrables. |
| **CA-22** | Un reintegro exitoso incrementa `on_hand`, recalcula `available`, incrementa versión y registra Kardex exactamente una vez. |
| **CA-23** | Retail puede reportar una incidencia física mediante `inventario:incidencias:reportar`; Inventario solo bloquea cantidad actualmente disponible. |
| **CA-24** | Reportar una incidencia incrementa `blocked` sin reducir `on_hand`. |
| **CA-25** | `REHABILITADO` disminuye `blocked` sin modificar `on_hand`. |
| **CA-26** | `MERMA` y `FALTANTE_CONFIRMADO` disminuyen `blocked` y `on_hand` una sola vez. |
| **CA-27** | Toda resolución de incidencia exige una referencia de acta y es idempotente. |
| **CA-28** | Un traslado a almacén central no acredita stock en el destino hasta la confirmación de recepción. |
| **CA-29** | El flujo G6 vigente documenta a Ventas/Postventa como invocador de la conciliación offline. La alternativa Retail→G6 y su secuencia con pedido/pago están pendientes de homologación; no se declara que Retail disponga actualmente del endpoint. |
| **CA-30** | La conciliación offline aplica como máximo la cantidad disponible y nunca consume `reserved` ni `blocked`. |
| **CA-31** | Si no puede aplicarse toda la venta offline, el resultado es `REQUIRES_REVIEW` con `unresolved_quantity > 0`; nunca se permite saldo negativo. |
| **CA-32** | Repetir la misma conciliación offline con la misma identidad no duplica efectos. |
| **CA-33** | `modulo-ventas` usa `inventario:reservar`, `inventario:consumir`, `inventario:liberar`, `inventario:reintegrar` e `inventario:conciliar-offline`. |
| **CA-34** | `modulo-retail` usa `inventario:incidencias:reportar` e `inventario:incidencias:resolver`, además de la **consulta de disponibilidad comercial**, no del saldo detallado. |
| **CA-35** | Una operación técnica sin token utilizable responde `401 TOKEN_INVALIDO`; una identidad sin scope responde `403 SCOPE_INSUFICIENTE`. |
| **CA-36** | Resolver una incidencia como `TRASLADO_ALMACEN_CENTRAL` descuenta origen y crea un traslado `EN_TRANSITO`, sin acreditar destino. |
| **CA-37** | La recepción del traslado la ejecuta un gestor comercial con capacidad local de inventario, no Retail ni Despacho. |
| **CA-38** | `REINGRESAR_DISPONIBLE` acredita unidades disponibles; `REINGRESAR_BLOQUEADO` conserva cuarentena; `CONFIRMAR_MERMA` no acredita stock. |
| **CA-39** | Una recepción nunca supera la cantidad pendiente del traslado. |
| **CA-40** | Una recepción parcial con `final_receipt=false` deja `RECIBIDO_PARCIAL`. |
| **CA-41** | Cerrar con unidades faltantes produce `COMPLETADO_CON_DISCREPANCIA` y `missing_quantity`; las faltantes no se acreditan. |
| **CA-42** | Repetir la misma recepción con la misma identidad no duplica saldos. |
| **CA-43** | `D-INV-01` está **adoptada**: para la primera entrega, cada referencia/contexto comercial de cumplimiento se resuelve internamente a una sola ubicación elegible y ejecutable; Inventario conserva la autoridad por `(sku, location_id)`. |
| **CA-44** | No se suman por defecto cantidades de ubicaciones independientes ni se toma como cumplimiento viable un máximo/suma arbitrarios. El abastecimiento multi-origen agregado está fuera del alcance de esta versión y requerirá otra ADR y pruebas de viabilidad. |
| **CA-45** | Si falta la correspondencia interna del contexto comercial (incluida `fulfillment_ref` cuando aplique), hay ambigüedad o no puede probarse una fuente realizable, la disponibilidad comercial responde `INDETERMINADO`; nunca infiere `AGOTADO`, `DISPONIBLE` ni `SUFICIENTE`. |
| **CA-46** | `GET /api/v1/inventario/disponibilidad/comercial` devuelve la proyección `sku + status`, con `status` en `DISPONIBLE`, `STOCK_BAJO`, `AGOTADO` o `INDETERMINADO`, sin ubicación ni saldos internos; su `AGOTADO` presupone un SKU existente con abastecimiento evaluable, no un SKU inexistente. |
| **CA-47** | `POST /api/v1/inventario/disponibilidad/comercial/verificar` evalúa `{sku, quantity}` para un `channel_id` y contexto `fulfillment`, devolviendo por línea `SUFICIENTE`, `INSUFICIENTE` o `INDETERMINADO`, con `binding=false`; es una consulta sin efectos, no reserva y no garantiza disponibilidad futura. `SUFICIENTE` exige que una fuente elegible pueda atender la cantidad completa. |
| **CA-48** | La ausencia/ambigüedad de mapeo interno produce `200` con resultado `INDETERMINADO`; un contexto de cumplimiento semánticamente inválido se rechaza con `422 CONTEXTO_ABASTECIMIENTO_INVALIDO`, y una petición malformada con `400 VALIDACION`. |
| **CA-49** | Para JWT de servicio, `GET /api/v1/inventario/disponibilidad` detallado solo admite `modulo-ventas`; las consultas comerciales `GET` y `POST /verificar` admiten `modulo-marketplace`, `modulo-chatbot` y `modulo-retail`. El scope compartido `inventario:disponibilidad:leer` no anula las allowlists por operación ni la autorización humana de la ruta detallada. |
| **CA-50** | Un `202 Accepted` en reserva, consumo o liberación acredita únicamente la aceptación del comando. Ventas determina el éxito/rechazo por resultado persistido y evento tipado; `GET /api/v1/inventario/operaciones/{operationId}` es recuperación sin reejecución, exclusiva de `modulo-ventas`. |
| **CA-51** | `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. La consulta de operaciones requiere `inventario:operaciones:leer`, scope candidato aún pendiente de registro/grant por Seguridad (G7); no se presupone su habilitación real. |
| **CA-52** | Repetir una venta física offline ya conciliada no vuelve a descontar stock, aunque cambie la identidad técnica del reintento. El resultado es un requisito adoptado; la identidad estable de la venta, su unicidad y el mecanismo técnico siguen pendientes de definición/homologación y no se consideran implementados. |
| **CA-53** | Si una venta repetida tuvo resultado parcial, se devuelve el resultado previo `REQUIRES_REVIEW` y se conservan las cantidades originales solicitadas, aplicadas y no resueltas; no se recalcula ni se crea un nuevo descuento. La identificación estable de la venta permanece pendiente. |
| **CA-54** | Una correspondencia tienda→ubicación interna inexistente o ambigua no autoriza la mutación. La resolución corresponde internamente a Inventario; la entrada contractual compatible con esta regla está pendiente de homologación porque OpenAPI aún exige `location_id`. |
| **CA-55** | Un actor sin autorización para la operación y la ubicación resuelta no puede modificar el saldo. La autorización efectiva, el consumidor técnico y su homologación con G4/G7 permanecen pendientes; la consulta comercial no concede permisos de escritura. |
| **CA-56** | La futura representación destinada a Retail comunica el resultado y solo las cantidades funcionales necesarias; no expone saldos ni ubicaciones internas innecesarias. El DTO compatible, el consumidor autorizado y la homologación G4/G7 están pendientes; este criterio no afirma que Retail disponga hoy de un endpoint de conciliación. |

---

# Escenarios principales

## Escenario 1 — Reserva normal

- **DADO** `on_hand=10`, `reserved=0`, `blocked=2`,
- **CUANDO** Ventas reserva 3,
- **ENTONCES** queda `reserved=3` y `available=5`.

## Escenario 2 — Daño reportado por Retail

- **DADO** `on_hand=10`, `reserved=3`, `blocked=0`,
- **CUANDO** Retail reporta 1 unidad dañada,
- **ENTONCES** `blocked=1`, `available=6`, `on_hand=10`.

## Escenario 3 — Merma confirmada

- **DADO** una incidencia abierta de 1 unidad bloqueada,
- **CUANDO** Retail resuelve con `MERMA` y acta válida,
- **ENTONCES** `blocked` disminuye en 1 y `on_hand` disminuye en 1 exactamente una vez.

## Escenario 4 — Devolución comercial sin recepción

- **DADO** una devolución aprobada,
- **CUANDO** aún no existe confirmación física de recepción/reintegrabilidad,
- **ENTONCES** Inventario no incrementa stock.

## Escenario 5 — Reintegro físico

- **DADO** Postventa confirma una unidad físicamente reintegrable,
- **CUANDO** `modulo-ventas` solicita el reintegro,
- **ENTONCES** `on_hand` aumenta en 1, se registra Kardex y el retry no duplica el incremento.

## Escenario 6 — Venta offline completamente conciliable

- **DADO** una venta Retail offline de 2 unidades ya registrada en Ventas y `available=4`,
- **CUANDO** Ventas solicita conciliación,
- **ENTONCES** se aplican 2 y el resultado es `COMPLETED`.

## Escenario 7 — Venta offline con discrepancia

- **DADO** una venta offline de 3 y `available=2`,
- **CUANDO** Ventas concilia,
- **ENTONCES** `applied_quantity=2`, `unresolved_quantity=1`, `status=REQUIRES_REVIEW` y ningún saldo es negativo.

## Escenario 8 — Reserva e incidencia concurrentes

- **DADO** las últimas 2 unidades disponibles,
- **CUANDO** una reserva de 2 y una incidencia física de 1 compiten,
- **ENTONCES** las transacciones se serializan/validan y solo se aplican cantidades compatibles con las invariantes.

---

## Escenario 9 — Traslado recibido completo

- **DADO** un traslado de 3 unidades `EN_TRANSITO`,
- **CUANDO** el gestor comercial autorizado recibe 3 como `REINGRESAR_DISPONIBLE` con `final_receipt=true`,
- **ENTONCES** el destino aumenta 3 unidades disponibles y el traslado queda `COMPLETADO`.

## Escenario 10 — Recepción parcial

- **DADO** un traslado de 5,
- **CUANDO** se reciben 3 con `final_receipt=false`,
- **ENTONCES** queda `RECIBIDO_PARCIAL` y 2 unidades pendientes.

## Escenario 11 — Cierre con discrepancia

- **DADO** un traslado de 5 con 3 ya recibidas,
- **CUANDO** el gestor comercial autorizado cierra la recepción sin recibir las 2 restantes,
- **ENTONCES** queda `COMPLETADO_CON_DISCREPANCIA`, `missing_quantity=2` y ninguna unidad faltante se acredita.

## Escenario 12 — Dos ubicaciones independientes no cubren una sola solicitud

- **DADO** un SKU con 2 unidades disponibles en la ubicación A y 3 en la ubicación B, sin plan de cumplimiento conjunto,
- **CUANDO** un canal verifica comercialmente una solicitud de 4 unidades bajo una referencia que resuelve a A,
- **ENTONCES** no obtiene `SUFICIENTE` sumando A+B; se evalúa únicamente la fuente A, por lo que el resultado es `INSUFICIENTE`.

## Escenario 13 — Correspondencia de cumplimiento ausente o ambigua

- **DADO** un SKU existente y un canal/contexto de cumplimiento válido, cuya correspondencia interna a una ubicación elegible no existe o es ambigua,
- **CUANDO** Marketplace, Chatbot o Retail solicita la proyección comercial o verifica una cantidad,
- **ENTONCES** la consulta devuelve `INDETERMINADO` (en el campo `status` del GET o `result` del POST); no se fabrica un `AGOTADO` ni una ubicación por defecto.

## Escenario 14 — Verificación comercial informativa

- **DADO** un contexto que resuelve inequívocamente a una ubicación con 5 unidades disponibles de un SKU,
- **CUANDO** un canal autorizado invoca `POST /api/v1/inventario/disponibilidad/comercial/verificar` con cantidad 4,
- **ENTONCES** obtiene `200`, `result=SUFICIENTE` y `binding=false`, sin incrementar reservas, modificar Kardex ni garantizar la operación de venta.

## Escenario 15 — Distinguir ambigüedad de contexto inválido

- **DADO** un contexto de abastecimiento semánticamente inválido según el schema/las reglas de la modalidad,
- **CUANDO** el canal solicita verificación comercial,
- **ENTONCES** se responde `422 CONTEXTO_ABASTECIMIENTO_INVALIDO`; si el contexto es válido pero falla únicamente su mapeo interno, corresponde `200` con `INDETERMINADO`.

## Escenario 16 — Separación de permisos por consumidor

- **DADO** un token técnico válido de `modulo-chatbot` con `inventario:disponibilidad:leer`,
- **CUANDO** solicita `GET /api/v1/inventario/disponibilidad` (detalle) y la consulta comercial,
- **ENTONCES** Inventario deniega el detalle (`403`) y admite únicamente la ruta comercial conforme a la allowlist y a las demás verificaciones de seguridad.

# Dependencias

| Módulo | Responsabilidad |
|---|---|
| Ventas/Postventa | Pedido, pago, devolución comercial, disparo de reserva/consumo/liberación/reintegro/conciliación |
| Retail | Hechos físicos de tienda y acta de resolución |
| Marketplace / Chatbot | Consulta |
| Catálogo | Identidad SKU |
| Seguridad (G7) | JWT/service tokens/scopes; registro y grant efectivo del scope candidato `inventario:operaciones:leer` para Ventas |
| Inventario | Autoridad del saldo, Kardex, idempotencia y concurrencia |

---

# Criterio de completitud

La HU se considera cubierta cuando existen pruebas unitarias y de contrato para las invariantes, las allowlists, la proyección comercial y la política D-INV-01; además, cuando exista backend real, deben aprobarse las pruebas de integración de concurrencia, idempotencia, resultados durables, reintegro, incidencias, conciliación offline y verificación comercial sin efectos. Los cambios contractuales `0.6.0-rc.1` siguen **provisionales de implementación**: documentarlos no acredita CI/E2E aprobado, grants G7 ni despliegue.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Criterios complementarios 0.5.0

Para evitar ambigüedad, los criterios de consulta se interpretan así:

- la consulta detallada devuelve la composición del saldo únicamente a consumidores autorizados;
- Marketplace, Chatbot y Retail consumen la proyección comercial;
- la proyección comercial devuelve `sku + status`;
- no expone ubicación, cantidades internas, umbral ni `stock_version`;
- es informativa y no constituye reserva/garantía futura;
- `AGOTADO` representa un SKU existente sin disponibilidad, no un SKU inexistente;
- el mismo scope `inventario:disponibilidad:leer` no elimina las allowlists por operación.

**Estado D-INV-01:** decisión **adoptada** para la entrega candidata `0.6.0-rc.1` (ADR B3). La política exige una fuente de cumplimiento elegible, única y realizable por contexto de canal/modalidad; la falta de correspondencia o ambigüedad se expresa como `INDETERMINADO`, no como ausencia de stock. La agregación entre ubicaciones independientes permanece **fuera de alcance**, no pendiente de resolver dentro de D-INV-01: exigiría otra ADR y un plan multi-origen demostrablemente ejecutable.

**Contratos candidatos, no desplegados:** los criterios CA-43 a CA-51 amplían la interpretación del baseline HTTP `0.5.0` conforme a OpenAPI/AsyncAPI `0.6.0-rc.1`; no añaden tablas ni autoridad de negocio nueva. Distinguir el `GET.status` (`DISPONIBLE/STOCK_BAJO/AGOTADO/INDETERMINADO`) del `POST.items[].result` (`SUFICIENTE/INSUFICIENTE/INDETERMINADO`). La nueva lectura de operaciones queda condicionada al registro de scope por G7 y a pruebas runtime.
<!-- HOMOLOGACION-HTTP-0.5.0:END -->
