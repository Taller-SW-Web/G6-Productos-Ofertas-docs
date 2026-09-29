# HU-015 — Historia de Usuario: Control de stock y disponibilidad

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** Spec [SPEC-015](./specs/SPEC-015-control-stock-disponibilidad.md) | Flow [WF-015](./wireframes/flows/WF-015-control-stock-disponibilidad.md)  
**Contrato HTTP:** [`./api/openapi.yaml`](./api/openapi.yaml)  
**Contrato asíncrono:** [`./asyncapi/asyncapi.yaml`](./asyncapi/asyncapi.yaml)  
**Catálogo de errores:** [`./api/catalogo-errores.md`](./api/catalogo-errores.md)

**Versión:** v1.1 — idempotencia armonizada

**Como** responsable de inventario,

**quiero** consultar la disponibilidad de cada SKU y que el sistema gestione de forma segura las reservas, consumos, liberaciones y ajustes de stock,

**para** mantener un inventario consistente y disponible para todos los canales sin vender las mismas unidades más de una vez.

El inventario se controla por **SKU vendible + ubicación (`location_id`)**. Un producto simple utiliza su `sku_base`; un producto con variantes utiliza el SKU comercial de cada variante. El producto padre no posee stock propio.

El flujo de compra se coordina con **Ventas y Postventa**:

```text
Pedido CREADO
    -> reservar stock

Pedido PAGADO
    -> confirmar consumo

PAGO_NO_COMPLETADO o anulación aplicable
    -> liberar reserva
```

Marketplace, Chatbot y Retail únicamente consultan disponibilidad. No reservan ni consumen inventario directamente.

---

# Criterios de aceptación

| **ID** | **Criterio** |
|---|---|
| **CA-01** | Cada unidad vendible se identifica mediante un SKU y su saldo autoritativo se controla por `(sku, location_id)`. Un producto simple usa `sku_base`; una variante utiliza su SKU comercial. |
| **CA-02** | El sistema permite consultar un SKU y devuelve como mínimo `on_hand`, `reserved`, `available` y su estado de disponibilidad. `location_id` es obligatorio cuando sea necesario distinguir ubicaciones. |
| **CA-03** | `available` se calcula como `max(on_hand - reserved, 0)`. El sistema nunca puede presentar una cantidad disponible negativa. |
| **CA-04** | El estado se calcula sobre `available`: `0 → Agotado`; `0 < available <= umbral_efectivo → Stock bajo`; `available > umbral_efectivo → Disponible`. |
| **CA-05** | El umbral efectivo utiliza el override configurado para el SKU cuando exista y, en caso contrario, el umbral global configurable. |
| **CA-06** | Marketplace, Chatbot y Retail pueden consultar disponibilidad, pero no pueden crear reservas, confirmar consumos ni liberar stock directamente. |
| **CA-07** | Cuando un pedido entra en estado `CREADO`, Ventas/Postventa puede solicitar idempotentemente una reserva indicando pedido, operación, SKU, cantidad y ubicación. |
| **CA-08** | Una reserva exitosa aumenta `reserved` y reduce `available` sin modificar `on_hand`. Si cualquiera de las líneas del pedido no puede reservarse, la operación no debe quedar parcialmente confirmada como exitosa. |
| **CA-09** | Una reserva tiene los estados `ACTIVA`, `CONSUMIDA`, `LIBERADA` o `EXPIRADA`. Desde un estado terminal no puede regresar a `ACTIVA`. |
| **CA-10** | Cuando el pedido pasa a `PAGADO`, Ventas/Postventa confirma la reserva. El sistema reduce `on_hand` y `reserved` por las cantidades consumidas, recalcula `available`, registra Kardex y marca la reserva como `CONSUMIDA`. |
| **CA-11** | Ante `PAGO_NO_COMPLETADO` o una anulación aplicable antes del consumo definitivo, Ventas/Postventa puede liberar la reserva. La liberación reduce `reserved`, recupera `available`, no incrementa `on_hand` y marca la reserva como `LIBERADA`. |
| **CA-12** | Toda reserva activa tiene un vencimiento configurable. Si alcanza su TTL sin haber sido confirmada o liberada, el sistema libera sus unidades y la marca `EXPIRADA`. |
| **CA-13** | Confirmar, liberar o expirar una misma reserva de forma concurrente no puede aplicar más de una transición terminal ni modificar el saldo dos veces. |
| **CA-14** | Reserva, consumo y liberación son idempotentes: repetir la misma identidad con el mismo payload semántico reutiliza el resultado sin ejecutar efectos nuevamente; reutilizar esa identidad para una intención distinta se rechaza con `IDEMPOTENCY_CONFLICT`. |
| **CA-15** | Ante operaciones concurrentes sobre el mismo `(sku, location_id)`, el sistema garantiza `on_hand >= 0`, `reserved >= 0`, `available >= 0` y evita que dos operaciones comprometan las mismas unidades. |
| **CA-16** | Toda mutación autoritativa del inventario registra un movimiento trazable de Kardex con SKU, ubicación, operación, cantidades y saldos anterior/posterior. |
| **CA-17** | Un ajuste absoluto procedente de carga masiva debe incluir `stock_version`; si el saldo cambió desde la versión esperada, el sistema rechaza el ajuste con `VERSION_CONFLICT`. |
| **CA-18** | Un SKU nuevo se inicializa idempotentemente con `on_hand=0`, `reserved=0`, `available=0` y `stock_version=0` en la ubicación inicial acordada. |
| **CA-19** | Después de una mutación persistida, Inventario publica `inventory.stock.changed`; un evento nunca se utiliza como sustituto del comando que provocó el cambio. |
| **CA-20** | Una devolución posterior al consumo solo repone los SKU, cantidades y ubicación comunicados como físicamente aceptados por Ventas/Postventa. Inventario no decide la política comercial de devolución. |
| **CA-21** | Inventario no cambia el estado del pedido, no procesa pagos, no ejecuta reembolsos y no genera un segundo consumo por acciones de Despacho. |

---

# Escenarios dado-cuando-entonces

## Escenario 1 — Consultar disponibilidad

- **DADO** un SKU `NK-AM-BLK-40` con `on_hand=10`, `reserved=2` en `location_id=DEFAULT`,
- **CUANDO** un canal consulta su disponibilidad,
- **ENTONCES** Inventario devuelve `available=8` y el estado correspondiente según el umbral efectivo.

## Escenario 2 — SKU agotado

- **DADO** un SKU con `available=0`,
- **CUANDO** un canal consulta su disponibilidad,
- **ENTONCES** el sistema devuelve estado **Agotado**.

## Escenario 3 — Stock bajo

- **DADO** un SKU con `available=3` y `umbral_efectivo=5`,
- **CUANDO** se consulta su disponibilidad,
- **ENTONCES** el sistema devuelve estado **Stock bajo**.

## Escenario 4 — Crear reserva al entrar el pedido en CREADO

- **DADO** un pedido `PED-001` en estado `CREADO` y un SKU con `on_hand=10`, `reserved=0`, `available=10`,
- **CUANDO** Ventas/Postventa solicita reservar 3 unidades,
- **ENTONCES** Inventario deja `on_hand=10`, actualiza `reserved=3`, `available=7` y registra una reserva `ACTIVA`.

## Escenario 5 — Reserva multilínea exitosa

- **DADO** un pedido con `SKU-A x2` y `SKU-B x1`, ambos con disponibilidad suficiente,
- **CUANDO** Ventas solicita la reserva,
- **ENTONCES** Inventario reserva todas las líneas dentro de una operación consistente y devuelve una única reserva asociada al pedido.

## Escenario 6 — Reserva multilínea rechazada

- **DADO** un pedido con `SKU-A x2` disponible y `SKU-B x4` sin disponibilidad suficiente,
- **CUANDO** Ventas solicita reservar ambas líneas,
- **ENTONCES** la operación se rechaza y no queda confirmada parcialmente como una reserva válida del pedido.

## Escenario 7 — Dos reservas compiten por las últimas unidades

- **DADO** un SKU con `on_hand=5`, `reserved=0`, `available=5`,
- **CUANDO** dos operaciones intentan reservar simultáneamente 3 unidades cada una,
- **ENTONCES** solo una puede ser aceptada y el saldo final válido es `on_hand=5`, `reserved=3`, `available=2`.

## Escenario 8 — Confirmar reserva al pasar el pedido a PAGADO

- **DADO** un SKU con `on_hand=10`, `reserved=3`, `available=7` y una reserva `ACTIVA` por 3 unidades,
- **CUANDO** Ventas/Postventa confirma que el pedido pasó a `PAGADO`,
- **ENTONCES** Inventario deja `on_hand=7`, `reserved=0`, `available=7`, registra Kardex y marca la reserva `CONSUMIDA`.

## Escenario 9 — Liberar reserva por pago no completado

- **DADO** un SKU con `on_hand=10`, `reserved=3`, `available=7`,
- **CUANDO** Ventas informa `PAGO_NO_COMPLETADO` y solicita liberar la reserva,
- **ENTONCES** Inventario deja `on_hand=10`, `reserved=0`, `available=10` y marca la reserva `LIBERADA`.

## Escenario 10 — Expirar reserva

- **DADO** una reserva `ACTIVA` cuyo `expires_at` ya fue alcanzado,
- **CUANDO** se ejecuta el proceso de expiración,
- **ENTONCES** Inventario libera las unidades, recalcula disponibilidad y marca la reserva `EXPIRADA`.

## Escenario 11 — Confirmación y expiración concurrentes

- **DADO** una reserva `ACTIVA` que está alcanzando su vencimiento,
- **CUANDO** Ventas confirma la reserva al mismo tiempo que el proceso de expiración intenta liberarla,
- **ENTONCES** solo una transición terminal puede aplicarse y el saldo no se modifica dos veces.

## Escenario 12 — Confirmación repetida idempotente

- **DADO** una reserva que ya fue confirmada correctamente,
- **CUANDO** llega nuevamente la misma solicitud con la misma identidad idempotente y el mismo payload semántico,
- **ENTONCES** Inventario no vuelve a descontar stock y reutiliza el resultado lógico de la confirmación original.

## Escenario 13 — Liberación repetida idempotente

- **DADO** una reserva que ya fue liberada,
- **CUANDO** llega nuevamente la misma operación con la misma identidad idempotente y el mismo payload semántico,
- **ENTONCES** Inventario no incrementa nuevamente la disponibilidad y reutiliza el resultado lógico original.

## Escenario 14 — Conflicto de idempotencia

- **DADO** una identidad idempotente utilizada para una solicitud válida,
- **CUANDO** se reutiliza esa misma identidad con una intención de negocio distinta,
- **ENTONCES** Inventario rechaza la segunda solicitud con `IDEMPOTENCY_CONFLICT` y no modifica el saldo ni la reserva.

## Escenario 15 — SKU inexistente

- **DADO** que no existe el SKU `NK-AM-XXX-99`,
- **CUANDO** se consulta o intenta reservar,
- **ENTONCES** el sistema rechaza la operación con un código estable de recurso inexistente.

## Escenario 16 — Cantidad inválida

- **DADO** un SKU existente,
- **CUANDO** una solicitud intenta reservar una cantidad igual o menor que cero,
- **ENTONCES** Inventario rechaza la operación sin modificar el saldo.

## Escenario 17 — Ajuste absoluto obsoleto

- **DADO** una exportación realizada con `stock_version=12`,
- **Y** posteriormente una reserva modifica el saldo a versión 13,
- **CUANDO** Bulk intenta establecer un conteo absoluto usando la versión 12,
- **ENTONCES** Inventario rechaza el ajuste con `VERSION_CONFLICT`.

## Escenario 18 — Inicialización de SKU

- **DADO** que Catálogo confirma un nuevo SKU vendible,
- **CUANDO** Inventario recibe la inicialización por primera vez,
- **ENTONCES** crea el saldo con `on_hand=0`, `reserved=0`, `available=0` y `stock_version=0`.
- **Y CUANDO** se repite la misma inicialización,
- **ENTONCES** no crea un saldo duplicado.

## Escenario 19 — Devolución aceptada

- **DADO** que un pedido ya fue consumido y Postventa acepta físicamente la devolución de 1 unidad de un SKU,
- **CUANDO** Ventas/Postventa comunica la cantidad y ubicación de reintegro,
- **ENTONCES** Inventario repone únicamente esa unidad y registra el movimiento correspondiente.

---

# Interacción con otros módulos

| **Módulo** | **Necesidad de interacción** | **Información que recibe Inventario** | **Información que entrega Inventario** |
|---|---|---|---|
| **Marketplace** | Consultar disponibilidad antes de ofrecer o comprar un SKU. | SKU y contexto de ubicación cuando aplique. | `on_hand`, `reserved`, `available` y estado según contrato. |
| **Chatbot** | Responder consultas de disponibilidad. | SKU consultado. | Disponibilidad y estado. |
| **Retail** | Consultar disponibilidad de tienda/ubicación durante la venta asistida. | SKU y `location_id` cuando corresponda. | Saldo y estado de la ubicación. |
| **Ventas y Postventa** | Orquestar reserva, consumo, liberación y reintegro autorizado. | `order_id`, `operation_id`, reserva, líneas SKU/cantidad/ubicación y motivo cuando aplique. | Resultado idempotente de la operación y eventos posteriores al commit. |
| **Despacho y Entrega** | No muta Inventario. La venta ya fue reservada/consumida por el flujo de Ventas. | Ninguna orden de consumo de stock. | Ningún segundo consumo. La integración de datos físicos de SKU pertenece a Catálogo/SPEC correspondiente. |
| **Seguridad y Usuarios** | Autorizar consumidores y operaciones. | JWT/identidad técnica y scopes. | No recibe datos de inventario como owner. |

---

# Dependencias dentro de Productos y Ofertas

| **Funcionalidad interna** | **Dependencia** |
|---|---|
| **Catálogo / Variantes** | Define los SKU vendibles y su estado comercial. |
| **Bulk** | Solicita ajustes absolutos condicionados por `stock_version`. |
| **Combos** | Consume proyecciones de disponibilidad, sin ser owner del saldo. |
| **Promociones** | Puede consumir proyecciones de stock para evaluación comercial. |
| **Dashboard de Inventario** | Se actualiza mediante `inventory.stock.changed`. |

---

# Contratos y autoridad documental

Las reglas de negocio de esta historia se detallan en:

```text
SPEC-015-control-stock-disponibilidad.md
```

Las rutas HTTP, parámetros, request bodies, responses y códigos se definen en:

```text
api/openapi.yaml
```

Los contratos asíncronos se definen en:

```text
asyncapi/asyncapi.yaml
```

Cuando exista contradicción entre la historia y la SPEC sobre una regla funcional, debe corregirse la historia para mantener trazabilidad; no se deben mantener dos reglas distintas.

---

# Reglas consolidadas

- La unidad autoritativa es `(sku, location_id)`.
- `available = max(on_hand - reserved, 0)`.
- Los canales solo consultan stock.
- Ventas/Postventa orquesta las mutaciones.
- `CREADO` solicita reserva.
- `PAGADO` confirma consumo.
- `PAGO_NO_COMPLETADO` o anulación aplicable libera.
- Toda reserva posee TTL configurable.
- Despacho no genera un segundo consumo.
- Una devolución solo repone unidades físicamente aceptadas.
- Las operaciones externas son idempotentes.
- Mismo identificador idempotente + misma intención reutiliza el resultado.
- Mismo identificador idempotente + intención distinta produce `IDEMPOTENCY_CONFLICT`.
- `OPERACION_DUPLICADA` no se utiliza para retries legítimos.
- Los ajustes absolutos respetan `stock_version`.
- Inventario registra Kardex.
- Los cambios persistidos publican eventos posteriores al commit.
- Inventario no procesa pedido, pago ni reembolso.

---

# Criterio de completitud de la HU

La historia se considera cubierta cuando existe evidencia de que:

- [ ] los canales consultan disponibilidad por SKU;
- [ ] el estado se calcula sobre `available`;
- [ ] Ventas puede crear una reserva al entrar el pedido en `CREADO`;
- [ ] Ventas puede confirmar la reserva al pasar a `PAGADO`;
- [ ] Ventas puede liberar la reserva ante pago no completado/anulación;
- [ ] existe expiración por TTL;
- [ ] las operaciones son idempotentes;
- [ ] un retry legítimo no duplica efectos;
- [ ] una reutilización conflictiva de identidad devuelve `IDEMPOTENCY_CONFLICT`;
- [ ] la concurrencia no permite doble compromiso de unidades;
- [ ] existe Kardex;
- [ ] `stock_version` protege ajustes masivos;
- [ ] existe `inventory.stock.changed`;
- [ ] Despacho no descuenta inventario;
- [ ] las rutas implementadas coinciden con OpenAPI;
- [ ] las pruebas cubren los escenarios críticos de SPEC-015.
