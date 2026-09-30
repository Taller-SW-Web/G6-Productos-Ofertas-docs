# HU-015 — Historia de Usuario: Control de stock y disponibilidad

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** Spec [SPEC-015](../specs/SPEC-015-control-stock-disponibilidad.md) | Flow [WF-015](../wireframes/flows/WF-015-control-stock-disponibilidad.md)

**Como** responsable de inventario,

**quiero** consultar la disponibilidad de las variantes de los productos y actualizar su stock cuando se registre un consumo,

**para** mantener la información de inventario actualizada y consistente para los diferentes canales y módulos del marketplace.

El inventario se controla por **SKU vendible + ubicación (`location_id`)**. Un producto simple utiliza su `sku_base`; una variante utiliza su SKU comercial, mientras `variant_id` permanece como identidad interna de Catálogo. El producto padre no tiene stock. Para el MVP puede existir una ubicación `DEFAULT`, pero el modelo no impide Retail/almacenes múltiples.

## Criterios de aceptación

| **ID** | **Criterio** |
| --- | --- |
| **CA-01** | Cada unidad vendible debe tener un SKU comercial único y el inventario se identifica por `(sku, location_id)`. Un producto simple usa `sku_base`; una variante usa su SKU suministrado o generado por Catálogo. |
| **CA-02** | El sistema debe permitir consultar inventario proporcionando SKU y, cuando aplique, `location_id`; la consulta devuelve como mínimo `on_hand`, `reserved` y `available`. Si el canal consulta disponibilidad global, Inventario agrega únicamente ubicaciones elegibles según el contrato acordado. |
| **CA-03** | El estado se calcula sobre `available`: `available=0 → Agotado`, `0 < available <= umbral_efectivo → Stock bajo`, `available > umbral_efectivo → Disponible`. El umbral efectivo usa override por SKU cuando existe y, en caso contrario, un valor global configurable; puede evolucionar a reglas por categoría/ubicación sin cambiar el contrato base. |
| **CA-04** | Inventario debe permitir las operaciones idempotentes `reserve`, `release` y `consume` sobre SKU + ubicación. El ciclo operativo alineado con Ventas/Postventa es: pedido **CREADO** → `reserve` (con TTL); pedido **PAGADO**/confirmado → `consume` (confirmación de la reserva); **PAGO_NO_COMPLETADO**/anulación aplicable → `release`; TTL vencido → expiración/liberación. Productos y Ofertas solo ejecuta el movimiento autorizado y no cambia el estado del pedido. |
| **CA-05** | Antes de actualizar el stock, el sistema debe validar que la variante exista, que la cantidad consumida sea válida y que exista stock suficiente. |
| **CA-06** | Cuando exista disponibilidad suficiente: `reserve` aumenta `reserved` y reduce `available` sin alterar `on_hand`; `release` libera `reserved` y recupera `available` sin incrementar `on_hand`; `consume` confirmado reduce `on_hand` y la reserva asociada cuando exista, manteniendo invariantes (`on_hand >= 0`, `reserved >= 0`, `available >= 0`) y Kardex. |
| **CA-07** | El sistema no debe permitir que el stock de una variante sea negativo. Si no existe stock suficiente, debe rechazar el consumo y conservar el stock actual. |
| **CA-08** | Después de cada movimiento se recalcula el estado con `available` y el umbral efectivo de la unidad/ubicación. Una reserva puede llevar temporalmente a Stock bajo o Agotado aunque `on_hand` siga siendo mayor que cero. |
| **CA-09** | El saldo confirmado se devuelve autoritativamente desde Inventario; las vistas replicadas de canales se actualizan por eventos y pueden presentar retraso temporal identificable. |
| **CA-10** | Ante reservas/consumos concurrentes sobre el mismo `(sku, location_id)`, el sistema garantiza `on_hand >= 0`, `reserved >= 0` y `available = on_hand - reserved >= 0`. Las mutaciones usan actualización condicional/versionado y bloqueos transaccionales breves por registro, nunca un bloqueo global. |
| **CA-11** | El ciclo de reserva es la lógica operativa interna: Ventas/Postventa solicita `inventory.reserve` al crear el pedido (`CREADO`, con TTL/referencia de operación), `inventory.consume` al confirmar el pago (`PAGADO`) y `inventory.release` ante `PAGO_NO_COMPLETADO`/anulación. Los nombres de los hitos externos constituyen contratos provisionales pendientes de homologación; mientras no se utilice la fase de reserva, `order.created` no afecta stock y el consumo ocurre con la confirmación acordada. Despacho no genera un segundo consumo. |
| **CA-12** | Una cancelación o `PAGO_NO_COMPLETADO` libera reservas pendientes de forma idempotente; una cancelación posterior a un consumo efectivo compensa el consumo previo no compensado (previo a despacho). Una devolución repone **solo los SKU, cantidades y ubicación de reintegro aceptados físicamente**; la política de si un combo puede devolverse total o parcialmente pertenece a Postventa. |
| **CA-13** | `order.confirmed` es un contrato externo provisional con `order_id`, `operation_id`, SKUs y cantidades (y snapshot de componentes para combo). Inventario consume todas las líneas de la operación en ACID y emite resultado idempotente aceptado o rechazado. |
| **CA-14** | Un rechazo por stock insuficiente nunca marca la venta como exitosa ni revierte pagos en Inventario; Ventas/Postventa define el tratamiento comercial y financiero. |
| **CA-15** | `order.cancelled` y `order.returned` solo compensan consumos previos efectivos, no repuestos anteriormente; los eventos duplicados no acreditan dos veces, y el retorno requiere aceptación física. |
| **CA-16** | Un ajuste absoluto masivo lleva `location_id` y `stock_version`, se rechaza ante conflicto y solo Inventario emite `inventory.stock.adjusted`/`inventory.stock.changed` después del Kardex de la ubicación. |
| **CA-17** | Un SKU nuevo se inicializa idempotentemente en la ubicación `DEFAULT` (o ubicaciones acordadas) con `on_hand=0`, `reserved=0`, `available=0` y `stock_version=0` antes de admitir movimientos. |
| **CA-18** | Las reservas tienen un estado transicional `ACTIVA` y estados terminales `CONSUMIDA`, `LIBERADA` y `EXPIRADA`; una reserva terminal no vuelve a `ACTIVA` ni puede confirmarse o liberarse dos veces. |
| **CA-19** | Las operaciones de reserva/confirmación/liberación son idempotentes por `(order_id/operation_id + tipo_operacion + sku)`; los duplicados son no-op y una segunda intención contradictoria con el estado vigente responde `IDEMPOTENCY_CONFLICT` sin alterar saldos. |

## Escenarios dado-cuando-entonces

### Escenario 1: Consultar disponibilidad de una variante

* **DADO** que existe una variante con SKU `NK-AM-BLK-40` y tiene `on_hand=10`, `reserved=0` y `available=10` en `location_id=DEFAULT`,
* **CUANDO** un canal solicita consultar su disponibilidad,
* **ENTONCES** el sistema devuelve el SKU, la cantidad disponible de 10 unidades y el estado **Disponible**.

### Escenario 2: Consultar una variante sin stock

* **DADO** que existe una variante con SKU `NK-AM-WHT-40` y tiene 0 unidades disponibles,
* **CUANDO** un canal consulta su disponibilidad,
* **ENTONCES** el sistema devuelve el stock en 0 y el estado **Agotado**.

### Escenario 3: Actualizar stock por consumo

* **DADO** que la variante con SKU `NK-AM-BLK-40` tiene 10 unidades disponibles,
* **CUANDO** se registra el consumo de 3 unidades,
* **ENTONCES** el sistema actualiza el stock de la variante a 7 unidades.

### Escenario 4: Rechazar un consumo por stock insuficiente

* **DADO** que la variante con SKU `NK-AM-BLK-40` tiene 2 unidades disponibles,
* **CUANDO** se registra el consumo de 5 unidades,
* **ENTONCES** el sistema rechaza la operación, informa que no existe stock suficiente y conserva las 2 unidades disponibles.

### Escenario 5: Consumir la última unidad

* **DADO** que la variante con SKU `NK-AM-BLK-40` tiene 1 unidad disponible,
* **CUANDO** se registra el consumo de 1 unidad,
* **ENTONCES** el sistema actualiza el stock a 0 y establece el estado **Agotado**.

### Escenario 6: SKU inexistente

* **DADO** que no existe una variante asociada al SKU `NK-AM-XXX-99`,
* **CUANDO** se solicita consultar o actualizar su stock,
* **ENTONCES** el sistema rechaza la operación e informa que la variante no existe.

### Escenario 7: Evitar stock negativo

* **DADO** que una variante tiene 3 unidades disponibles,
* **CUANDO** se intenta registrar un consumo de una cantidad que supera las 3 unidades,
* **ENTONCES** el sistema rechaza la operación y el stock permanece en 3 unidades.

### Escenario 8: Consultar el stock después de un consumo

* **DADO** que una variante tenía 10 unidades y se registró correctamente un consumo de 4 unidades,
* **CUANDO** un canal consulta nuevamente la disponibilidad,
* **ENTONCES** el sistema devuelve 6 unidades como stock disponible.

### Escenario 9: Consumos concurrentes sobre el mismo SKU

* **DADO** que la variante con SKU `NK-AM-BLK-40` tiene 5 unidades disponibles y se solicitan simultáneamente un consumo de 3 unidades (Consumo A) y un consumo de 3 unidades (Consumo B),
* **CUANDO** ambos consumos se registran de forma concurrente sobre el mismo SKU,
* **ENTONCES** el sistema acepta un solo consumo y rechaza el otro por falta de stock, aplicando el descuento mediante una **actualización condicional sobre el saldo** con el control de concurrencia optimista de las operaciones masivas; el stock final de la variante es de 2 unidades, sin quedar nunca negativo.

### Escenario 10: Estado resultante Stock bajo después de un consumo

* **DADO** que la variante con SKU `NK-AM-BLK-40` tiene 6 unidades disponibles y su `umbral_stock_bajo` está configurado en 5 unidades,
* **CUANDO** se registra el consumo de 1 unidad,
* **ENTONCES** el sistema actualiza el stock a 5 unidades y establece el estado **Stock bajo**.

### Escenario 11: Consultar una variante con stock bajo

* **DADO** que existe una variante con SKU `NK-AM-BLK-41` que tiene 3 unidades disponibles y su `umbral_stock_bajo` está configurado en 5 unidades,
* **CUANDO** un canal consulta su disponibilidad,
* **ENTONCES** el sistema devuelve la cantidad disponible de 3 unidades y el estado **Stock bajo**.

### Escenario 12: Venta confirmada sin stock
* **DADO** un pedido confirmado con cantidad superior a las existencias restantes,
* **CUANDO** Inventario recibe `order.confirmed`,
* **ENTONCES** rechaza el consumo sin stock negativo y emite resultado a Ventas, sin cambiar pagos ni afirmar que el pedido quedó resuelto.

### Escenario 13: Cancelación duplicada
* **DADO** un consumo confirmado compensado una vez,
* **CUANDO** llega nuevamente la misma cancelación,
* **ENTONCES** no se incrementa de nuevo el stock.

### Escenario 14: Ajuste absoluto con versión anterior
* **DADO** que un consumo aumentó `stock_version` desde la exportación,
* **CUANDO** se solicita restablecer el conteo anterior por carga masiva,
* **ENTONCES** el ajuste se rechaza con `VERSION_CONFLICT` sin sobrescribir la venta.

### Escenario 15: Reserva temporal homologada por Ventas
* **DADO** un SKU con `on_hand=5`, `reserved=1` y `available=4` en una ubicación,
* **CUANDO** Ventas/Postventa solicita idempotentemente reservar 2 unidades mediante el contrato homologado,
* **ENTONCES** Inventario conserva `on_hand=5`, actualiza `reserved=3` y `available=2`; si la venta expira o falla, `release` devuelve la disponibilidad sin crear unidades nuevas.

### Escenario 16: Confirmar reserva y consumir al confirmar el pago

* **DADO** una reserva `ACTIVA` del SKU `NK-AM-BLK-40` por 2 unidades con `on_hand=5`, `reserved=2` y `available=3`,
* **CUANDO** el pedido pasa a `PAGADO` y Ventas/Postventa solicita `inventory.consume`,
* **ENTONCES** Inventario reduce `on_hand` a 3 y `reserved` a 0, la reserva pasa a estado terminal `CONSUMIDA` y se publica `inventory.stock.changed` tras el commit local.

### Escenario 17: Liberar reserva por pago no completado o anulación

* **DADO** una reserva `ACTIVA` de 2 unidades con `on_hand=5`, `reserved=2` y `available=3`,
* **CUANDO** Ventas/Postventa comunica `PAGO_NO_COMPLETADO` y solicita `inventory.release`,
* **ENTONCES** Inventario libera la reserva quedando `reserved=0` y `available=5` sin modificar `on_hand`, y la reserva pasa a estado terminal `LIBERADA`.

### Escenario 18: Expirar reserva por TTL

* **DADO** una reserva `ACTIVA` del SKU `NK-AM-BLK-40` con TTL configurado,
* **CUANDO** transcurre el tiempo de vida de la reserva sin confirmación ni liberación,
* **ENTONCES** Inventario expira la reserva liberándola y la marca con estado terminal `EXPIRADA`; las unidades vuelven a `available` sin incrementar `on_hand`.

### Escenario 19: Reintento idempotente de confirmación

* **DADO** un consumo confirmado del SKU `NK-AM-BLK-40` con estado terminal `CONSUMIDA`,
* **CUANDO** llega nuevamente la misma confirmación (mismo `order_id + tipo_operacion + sku`),
* **ENTONCES** Inventario responde el resultado previo sin volver a descontar stock ni crear Kardex adicional.

### Escenario 20: Conflicto de intención por operación contradictoria

* **DADO** una reserva ya consumida (estado terminal `CONSUMIDA`) del SKU `NK-AM-BLK-40`,
* **CUANDO** Ventas/Postventa solicita liberar esa misma reserva,
* **ENTONCES** Inventario responde `IDEMPOTENCY_CONFLICT` sin alterar los saldos.

## Interacción con otros módulos

| **Módulo** | **Necesidad de interacción** | **Información que esta funcionalidad recibe** | **Información que esta funcionalidad entrega** |
| --- | --- | --- | --- |
| **Canal Marketplace** | Consultar disponibilidad antes de vender. | SKU y contexto/ubicación cuando corresponda. | `available`, estado y ubicación/proyección permitida. |
| **Canal Chatbot** | Responder consultas sobre la disponibilidad de productos y sus variantes. | SKU de la variante consultada. | Stock disponible y estado de disponibilidad. |
| **Canal Retail** | Consultar disponibilidad durante venta asistida, pudiendo requerir inventario de una tienda/ubicación concreta. | SKU y `location_id`. | `on_hand`, `reserved`, `available` y estado de la ubicación. |
| **Ventas y Postventa** | Solicitar reserva/liberación si el contrato acordado la utiliza y confirmar consumo o compensación. | `order_id`/`operation_id`, SKU, cantidad, ubicación y tipo de movimiento. | Resultado idempotente del movimiento y disponibilidad resultante; Inventario no decide estado del pedido ni pago. |
| **Despacho** | Entregar unidades correspondientes a ventas ya confirmadas; no genera consumo ni modifica el stock por sí mismo. | SKU y cantidad a despachar de ventas confirmadas. | Confirmación de la entrega (sin consumo adicional). |

La consulta de disponibilidad por parte de los canales **Marketplace, Retail y Chatbot** se realiza siempre referenciando una **Variante/SKU**; el canal no consulta el stock del producto como si el producto fuera la unidad de inventario.

## Dependencias dentro de Productos y Ofertas

| **Funcionalidad interna** | **Información necesaria** |
| --- | --- |
| **Gestión de productos** | Identificador, nombre, estado y variantes del producto para identificar qué unidades deben ser controladas mediante inventario. |
| **Gestión de variantes/SKUs** | Identificación y atributos de cada variante (SKU), base sobre la cual se controla el stock individual. |
| **Gestión de características** | Características de las variantes, como talla, color u otras que permitan diferenciar unidades de inventario. |
| **Gestión de precios** | Identificación de la variante y precio vigente cuando los canales necesiten relacionar la disponibilidad con la información comercial del producto. |

## Condición externa para la implementación
Los eventos `order.confirmed`, `order.cancelled` y `order.returned` y las respuestas de consumo son **propuestas de contrato** pendientes de homologación con Ventas y Postventa; esta HU no afirma que ya existan en el sistema externo. Inventario no confirma pedidos, no realiza cobros ni ejecuta reembolsos.

## Reglas consolidadas

* El `umbral_stock_bajo` efectivo usa override por SKU cuando existe y un valor global configurable como fallback; futuras reglas por categoría/ubicación pueden extenderlo.
* El ciclo de reserva es la lógica operativa interna: `CREADO` → `reserve` (TTL), `PAGADO` → `consume`, `PAGO_NO_COMPLETADO`/anulación → `release`, TTL → expiración. Los hitos externos son contratos provisionales; sin la fase de reserva, `order.created` no afecta stock y el consumo ocurre con la confirmación acordada.
* La reserva modifica `reserved`/`available` sin tocar `on_hand`; el consumo reduce `on_hand` y `reserved`; la liberación/expiración recupera `available` sin incrementar `on_hand`. Los estados terminales `CONSUMIDA`, `LIBERADA` y `EXPIRADA` no vuelven a `ACTIVA`.
* La generación del SKU corresponde a Gestión de Variantes/Productos según el tipo de producto.

> Nota: la identidad interna y el SKU comercial los define **Gestión de variantes/SKUs**; Inventario usa el SKU vendible y no asume que siempre sea autogenerado. El ciclo de reserva/consumo descrito y las compensaciones son la lógica interna que implementará Productos y Ofertas; su homologación final con Ventas/Postventa sigue pendiente.
