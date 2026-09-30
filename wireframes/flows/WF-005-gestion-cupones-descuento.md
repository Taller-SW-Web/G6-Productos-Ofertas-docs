# WF-005 — Gestión de cupones de descuento


## Usuario objetivo
Gestor comercial.

## Pantallas
- Lista de cupones.
- Crear/editar.
- Detalle.
- Estado de límites/uso.

## Campos
- Código.
- Promoción asociada.
- Estado.
- Límite global opcional.
- Límite por cliente opcional.
- Monto mínimo opcional.
- Política de restitución:
  - Restaurar uso al cancelar.
  - No restaurar.

## Reglas
- Código normalizado único.
- Vacío en límite = Sin límite.
- No ofrecer botones administrativos “Consumir” o “Restituir”.
- La validación de compra no consume.
- El consumo/restitución sucede automáticamente desde el pedido.

## Microcopy
Usar “Uso global”, “Límite por cliente” y “Restaurar uso”; no mostrar `customer_ref`, `order_id`, nombres de eventos o códigos técnicos.
