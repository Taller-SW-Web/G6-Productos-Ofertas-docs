# HU-002 — Gestión de combos de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** SPEC [SPEC-002](../specs/SPEC-002-gestion-combos-productos.md) | Wireframe [WF-002](../wireframes/flows/WF-002-gestion-combos-productos.md)

---

**Como** gestor comercial,  
**quiero** crear combos válidos con beneficio económico garantizado,  
**para** ofrecer conjuntos atractivos sin romper precio, inventario ni cupones.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | El combo contiene al menos dos componentes SKU vendibles directos. |
| CA-02 | No se admiten combos anidados ni componentes duplicados. |
| CA-03 | La disponibilidad mostrada se deriva de los componentes y es meramente informativa. |
| CA-04 | El combo no posee saldo propio ni reserva existencias en Inventario. |
| CA-05 | La validación de cupón previa al pedido no consume saldo ni muta estado. |
| CA-06 | El consumo de cupón lo orquesta Ventas solo tras confirmar la reserva de stock. |
| CA-07 | La reserva y consumo de existencias de componentes lo orquesta Ventas. |
| CA-08 | Si un componente no tiene existencias, el combo se muestra como agotado o no comprable. |
| CA-09 | El precio del combo debe ser mayor a cero y estrictamente menor que la compra por separado de sus componentes (suma regular y suma pública vigente). |
| CA-10 | Si un componente es desactivado en catálogo, el combo pasa a no elegible para nuevas ventas, preservando su registro administrativo. |
| CA-11 | Ante fallo de pago en checkout, solo se emite restitución de cupón si este fue consumido con anterioridad. |

## Escenario — Creación de combo con beneficio comercial

DADO dos componentes SKU con precios y existencias vigentes,  
CUANDO el gestor ingresa un precio promocional menor que la suma de sus precios por separado,  
ENTONCES el combo se registra exitosamente como activo o borrador, mostrando la disponibilidad estimada informativa.

## Escenario — Rechazo por precio sin ventaja económica

DADO un intento de crear un combo cuyo precio supera o iguala la suma de precios regulares o públicos de sus componentes,  
CUANDO se valida el formulario,  
ENTONCES el sistema rechaza la operación indicando error de precio inválido (`COMBO_PRECIO_INVALIDO`).

## Escenario — Desactivación de componente

DADO un combo activo en catálogo,  
CUANDO se desactiva uno de sus componentes mediante evento de catálogo,  
ENTONCES el combo pasa automáticamente al estado no elegible / no comprable para clientes, manteniendo intacta su definición administrativa.

## Escenario — Compensación en checkout según consumo de cupón

DADO un pedido de combo en checkout con reserva de inventario confirmada,  
CUANDO el intento de pago falla,  
ENTONCES Ventas solicita la liberación de la reserva de stock en Inventario y, solo si el pedido incluía un cupón efectivamente consumido, emite la solicitud de restitución a Promociones.