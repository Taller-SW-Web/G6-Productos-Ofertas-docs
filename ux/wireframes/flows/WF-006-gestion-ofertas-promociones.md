# WF-006 — Gestión de ofertas y promociones


## Objetivo
Administrar promociones, alcance, vigencia y combinabilidad.

## Integración asíncrona
Una promoción de modalidad Cupón referencia cupones válidos, pero la UI administrativa no simula ni ejecuta el consumo de un pedido.

La evaluación comercial pertenece a API/checkout y no añade controles técnicos al backoffice.

## Restricciones administrativas verificables

- Alcance por producto completo se guarda como ID de producto; alcance específico se guarda como SKU. No convertir el primero en sus SKU actuales. Deduplicar las coincidencias.
- Seleccionar explícitamente al menos un canal; no comunicar que selección vacía significa todos.
- El cambio de modalidad usa la capacidad de solo lectura `puedeCambiarModalidad`, calculada y revalidada por el servicio conforme a HU-006 CA-13. Con antecedentes desconocidos no se presupone permiso. El prototipo incluye fixtures con cambio permitido y con activación previa/cupones/usos que lo impiden.
- Reconstruir el formulario conserva las acciones Guardar/Cancelar y permite corregir un error y volver a guardar. Un fallo conserva los valores.
- El prototipo actualiza fixtures en memoria y los reinicia al recargar; no evalúa cestas ni acredita la persistencia o el servicio real.
