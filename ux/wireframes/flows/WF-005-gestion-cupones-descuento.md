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
- Normalizar con trim y mayúsculas ASCII; rechazar código vacío o caracteres distintos de letras ASCII, números, guion y guion bajo. Al editar, excluir el propio cupón de la comprobación de duplicados.
- Vacío en límite = Sin límite.
- Límite informado = entero positivo; monto mínimo informado = mayor que cero. Conservar entradas y errores si no se guarda.
- El detalle y la edición usan el registro seleccionado; muestran promoción, estado, límites, uso global y política propios.
- Activar/desactivar requiere confirmación y conserva los usos registrados.
- No ofrecer botones administrativos “Consumir” o “Restituir”.
- La validación de compra no consume.
- El consumo/restitución sucede automáticamente desde el pedido.

## Microcopy
Usar “Uso global”, “Límite por cliente” y “Restaurar uso”; no mostrar `customer_ref`, `order_id`, nombres de eventos o códigos técnicos.

## Prototipo y límites de la evidencia

El HTML y `app.js` mantienen fixtures en memoria para comprobar navegación y validaciones administrativas. Crear/editar actualiza esos fixtures; recargar los reinicia. No implementan consumo, restitución ni persistencia de cupones.
