# HU-005 — Gestión de cupones de descuento

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** SPEC [SPEC-005](../specs/SPEC-005-gestion-cupones-descuento.md) | Wireframe [WF-005](../wireframes/flows/WF-005-gestion-cupones-descuento.md)

---

**Como** gestor comercial,  
**quiero** administrar cupones con límites seguros,  
**para** aplicar descuentos sin duplicar consumos ni perder restituciones.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | Código de cupón normalizado es único. |
| CA-02 | Validar no consume. |
| CA-03 | `customer_ref` es el UUID `sub` de Seguridad. |
| CA-04 | Cupón con límite por cliente exige `customer_ref`. |
| CA-05 | El consumo se solicita después de reserva confirmada y antes del intento de pago. |
| CA-06 | `(order_id, cupon_id)` consume como máximo una vez. |
| CA-07 | Dos pedidos compitiendo por el último uso producen un solo ganador. |
| CA-08 | Reintentar el mismo comando devuelve el mismo efecto lógico. |
| CA-09 | `RESTAURAR_EN_CANCELACION` restituye una sola vez. |
| CA-10 | `NO_RESTAURAR` conserva el consumo. |
| CA-11 | Cancelar un pedido sin consumo previo no aumenta el cupo. |
| CA-12 | Promociones no decide pago/reembolso. |