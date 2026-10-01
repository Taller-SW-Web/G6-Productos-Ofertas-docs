# HU-015 — Control de stock y disponibilidad

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** SPEC [SPEC-015](../specs/SPEC-015-control-stock-disponibilidad.md) | Wireframe [WF-015](../wireframes/flows/WF-015-control-stock-disponibilidad.md)

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
| **CA-02** | La consulta devuelve como mínimo `on_hand`, `reserved`, `blocked`, `available`, `status` y `stock_version` cuando corresponda. |
| **CA-03** | `available = max(on_hand - reserved - blocked, 0)`. |
| **CA-04** | Siempre se cumple `on_hand >= 0`, `reserved >= 0`, `blocked >= 0`, `reserved + blocked <= on_hand` y `available >= 0`. |
| **CA-05** | El estado `AGOTADO/STOCK_BAJO/DISPONIBLE` se calcula sobre `available`. |
| **CA-06** | Marketplace y Chatbot solo consultan Inventario. |
| **CA-07** | Retail no reserva, consume, libera, reintegra ni concilia stock por una venta directamente. |
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
| **CA-29** | Una venta Retail offline se registra primero en Ventas/Postventa; Retail no invoca directamente la conciliación. |
| **CA-30** | La conciliación offline aplica como máximo la cantidad disponible y nunca consume `reserved` ni `blocked`. |
| **CA-31** | Si no puede aplicarse toda la venta offline, el resultado es `REQUIRES_REVIEW` con `unresolved_quantity > 0`; nunca se permite saldo negativo. |
| **CA-32** | Repetir la misma conciliación offline con la misma identidad no duplica efectos. |
| **CA-33** | `modulo-ventas` usa `inventario:reservar`, `inventario:consumir`, `inventario:liberar`, `inventario:reintegrar` e `inventario:conciliar-offline`. |
| **CA-34** | `modulo-retail` usa `inventario:incidencias:reportar` e `inventario:incidencias:resolver`, además de la consulta de disponibilidad. |
| **CA-35** | Una operación técnica sin token utilizable responde `401 TOKEN_INVALIDO`; una identidad sin scope responde `403 SCOPE_INSUFICIENTE`. |
| **CA-36** | Resolver una incidencia como `TRASLADO_ALMACEN_CENTRAL` descuenta origen y crea un traslado `EN_TRANSITO`, sin acreditar destino. |
| **CA-37** | La recepción del traslado la ejecuta un gestor comercial con capacidad local de inventario, no Retail ni Despacho. |
| **CA-38** | `REINGRESAR_DISPONIBLE` acredita unidades disponibles; `REINGRESAR_BLOQUEADO` conserva cuarentena; `CONFIRMAR_MERMA` no acredita stock. |
| **CA-39** | Una recepción nunca supera la cantidad pendiente del traslado. |
| **CA-40** | Una recepción parcial con `final_receipt=false` deja `RECIBIDO_PARCIAL`. |
| **CA-41** | Cerrar con unidades faltantes produce `COMPLETADO_CON_DISCREPANCIA` y `missing_quantity`; las faltantes no se acreditan. |
| **CA-42** | Repetir la misma recepción con la misma identidad no duplica saldos. |

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

# Dependencias

| Módulo | Responsabilidad |
|---|---|
| Ventas/Postventa | Pedido, pago, devolución comercial, disparo de reserva/consumo/liberación/reintegro/conciliación |
| Retail | Hechos físicos de tienda y acta de resolución |
| Marketplace / Chatbot | Consulta |
| Catálogo | Identidad SKU |
| Seguridad | JWT/service tokens/scopes |
| Inventario | Autoridad del saldo, Kardex, idempotencia y concurrencia |

---

# Criterio de completitud

La HU se considera cubierta cuando existen pruebas unitarias/contrato para las invariantes y, cuando exista backend real, pruebas de integración de concurrencia, idempotencia, reintegro, incidencias y conciliación offline.
