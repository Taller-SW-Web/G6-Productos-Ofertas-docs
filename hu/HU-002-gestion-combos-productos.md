# HU-002 — Historia de Usuario: Gestión de combos de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** Spec [SPEC-002](./specs/SPEC-002-gestion-combos-productos.md) | Flow [WF-002](./wireframes/flows/WF-002-gestion-combos-productos.md)

**Como** gestor comercial,  
**quiero** crear y gestionar combos formados por múltiples SKUs vendibles bajo un precio único promocional,  
**para** ofrecer paquetes comercialmente convenientes cuya disponibilidad pueda consultarse de forma informativa y cuyo stock sea reservado, consumido o liberado por Inventario bajo la orquestación de Ventas/Postventa.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| **CA-01** | Solo un usuario autorizado puede crear, modificar, consultar y desactivar combos. Los códigos de permiso concretos pertenecen al contrato de Seguridad. |
| **CA-02** | Un combo incluye nombre, descripción, precio y como mínimo 2 SKUs vendibles distintos —SKU de variante o `sku_base` de producto simple— con cantidad entera positiva. |
| **CA-03** | El precio del combo debe ser mayor que cero, menor que la suma de precios regulares y menor que la suma de precios públicos vigentes de los componentes multiplicados por sus cantidades. |
| **CA-04** | Se prohíbe el anidamiento: un combo no puede incluir otro combo. |
| **CA-05** | La disponibilidad informativa se calcula como `min(floor(available_i / cantidad_i))` sobre la proyección conocida de Inventario. |
| **CA-06** | Si falta o está obsoleta la proyección de un componente, se informa «No verificable»; no se inventa un cero ni se garantiza la compra. |
| **CA-07** | Cuando Ventas/Postventa crea el pedido en `CREADO`, solicita a Inventario reservar todos los SKU componentes y cantidades del combo. La reserva completa se acepta o rechaza sin dejar un combo parcialmente reservado. |
| **CA-08** | Cuando el pedido pasa a `PAGADO`, Ventas/Postventa solicita confirmar la reserva; Inventario realiza el consumo definitivo de las líneas reservadas de manera idempotente. |
| **CA-09** | Ante `PAGO_NO_COMPLETADO`, anulación aplicable antes del consumo o expiración, Ventas/Postventa solicita liberar la reserva o actúa el TTL. Liberar restaura disponibilidad y no crea stock. |
| **CA-10** | Marketplace, Chatbot y Retail solo consultan disponibilidad del combo/SKUs. Ningún canal reserva, libera o consume stock directamente. |
| **CA-11** | Si un SKU componente se desactiva, el combo deja de ser elegible para nuevas ventas, se oculta en los canales una vez propagado el cambio y se notifica al gestor para revisión. |
| **CA-12** | No se repite el mismo SKU en dos filas. Cada cantidad es un entero positivo. |
| **CA-13** | Si un cambio de Pricing hace que el combo deje de ser más barato que la compra individual vigente, el combo deja de ser elegible para nuevas ventas sin alterar pedidos históricos. |
| **CA-14** | La combinabilidad del beneficio del combo con promociones/cupones pertenece a la política de Promociones; el combo no inventa una regla global de acumulación. |
| **CA-15** | Ventas/Postventa conserva el snapshot de la composición y precio aceptados en el pedido. |
| **CA-16** | La política de devolución total/parcial pertenece a Ventas/Postventa. Inventario solo repondrá SKU físicamente aceptados cuando exista un contrato homologado; esta HU no fija un evento `order.returned`. |
| **CA-17** | Un `202 Accepted` en una mutación de Inventario indica admisión del comando; el resultado definitivo se obtiene mediante el contrato asíncrono correspondiente. |
| **CA-18** | Los reintentos de reserva, confirmación y liberación no duplican efectos; una misma identidad idempotente con intención distinta se trata como conflicto. |

## Escenarios dado-cuando-entonces

### Escenario 1: Crear un combo válido

- **DADO** que existen dos o más SKUs vendibles elegibles
- **CUANDO** el gestor define cantidades positivas y un precio válido
- **ENTONCES** se registra el combo y se muestra su disponibilidad informativa.

### Escenario 2: Rechazar precio inválido

- **DADO** un combo cuya suma pública vigente es S/ 120
- **CUANDO** se intenta guardar con precio S/ 120, superior o menor/igual a cero
- **ENTONCES** el sistema bloquea el guardado y explica que el combo debe representar un descuento real.

### Escenario 3: Rechazar un combo anidado

- **DADO** que el gestor selecciona componentes
- **CUANDO** intenta incluir otro combo
- **ENTONCES** la selección se bloquea.

### Escenario 4: Calcular disponibilidad proporcional

- **DADO** 1 camiseta con disponibilidad 10 y 2 medias con disponibilidad 15
- **CUANDO** se consulta el combo
- **ENTONCES** se muestran 7 combos como estimación.

### Escenario 5: Disponibilidad no verificable

- **DADO** que una proyección está ausente o desactualizada
- **CUANDO** se consulta el combo
- **ENTONCES** se muestra «No verificable» y la fecha/estado de actualización disponible.

### Escenario 6: Reservar componentes al crear el pedido

- **DADO** un combo de 1 raqueta y 3 pelotas con disponibilidad suficiente
- **CUANDO** Ventas/Postventa crea el pedido y solicita reserva
- **ENTONCES** Inventario reserva las cuatro unidades correspondientes como una sola intención de operación y devuelve resultado asíncrono.

### Escenario 7: Rechazar una reserva incompleta

- **DADO** que las pelotas no tienen disponibilidad suficiente
- **CUANDO** Inventario procesa la reserva
- **ENTONCES** rechaza la operación sin dejar solo la raqueta reservada.

### Escenario 8: Consumir al pagar

- **DADO** una reserva activa del combo
- **CUANDO** el pedido pasa a `PAGADO`
- **ENTONCES** Ventas/Postventa solicita confirmar la reserva e Inventario consume exactamente las líneas reservadas.

### Escenario 9: Liberar por pago no completado

- **DADO** una reserva activa
- **CUANDO** el pedido termina por `PAGO_NO_COMPLETADO`
- **ENTONCES** Ventas/Postventa solicita liberar y la disponibilidad vuelve a quedar libre sin incrementar `on_hand`.

### Escenario 10: Desactivar por componente

- **DADO** un combo activo
- **CUANDO** se desactiva uno de sus SKU componentes
- **ENTONCES** el combo deja de ser elegible para nuevas ventas y el gestor recibe una alerta de revisión.

### Escenario 11: Cambio de precio invalida el combo

- **DADO** un combo comercialmente válido
- **CUANDO** un cambio de Pricing hace que el precio del combo deje de ser menor que la compra individual vigente
- **ENTONCES** el combo deja de ser elegible para nuevas ventas sin modificar pedidos ya creados.

### Escenario 12: Devolución todavía no homologada

- **DADO** un pedido pagado que contiene un combo
- **CUANDO** se plantea una devolución
- **ENTONCES** esta funcionalidad no decide la elegibilidad ni repone stock por sí sola; espera el contrato homologado de Ventas/Postventa.

## Interacción con otros módulos

| Módulo | Necesidad | Recibe | Entrega |
|---|---|---|---|
| Marketplace | Mostrar y cotizar combos | Consulta comercial y disponibilidad | Combo, precio y disponibilidad informativa |
| Chatbot | Consultar combos | Consulta de producto/combo | Información comercial y disponibilidad |
| Retail | Venta asistida | Consulta de combo/SKU | Información comercial y disponibilidad |
| Ventas/Postventa | Orquestar ciclo del pedido | Estado del pedido y composición aceptada | Datos necesarios para identificar los SKU componentes; resultado de stock lo produce Inventario |
| Seguridad y Usuarios | Autorizar administración | Token/identidad | Resultado de autorización |
| Despacho | Preparar envío después de venta | Pedido/lineas desde su contrato propietario | Combos no define empaque |

## Dependencias internas

| Funcionalidad | Información |
|---|---|
| Catálogo | SKU vendible, producto/variante y estado |
| Pricing | Precio regular y oferta propia vigente |
| Inventario | `available`, reserva, confirmación/consumo y liberación |
| Promociones | Política de combinabilidad con otros beneficios |

## Reglas consolidadas

- **Unidad de componente:** SKU vendible.
- **Disponibilidad:** estimación, no reserva.
- **Stock:** Ventas/Postventa orquesta; Inventario ejecuta.
- **Pedido CREADO:** reserva.
- **Pedido PAGADO:** consumo definitivo.
- **PAGO_NO_COMPLETADO/cancelación aplicable:** liberación de reserva.
- **Canales:** solo lectura de disponibilidad.
- **Anidamiento:** prohibido.
- **Devolución:** pendiente de contrato homologado; no se fija `order.returned`.
