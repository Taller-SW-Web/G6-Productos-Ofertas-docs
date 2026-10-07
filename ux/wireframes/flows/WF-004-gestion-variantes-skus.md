# WF-004 — Gestión de variantes y SKU


## Pantallas
- Lista de variantes.
- Crear/editar variante.
- Detalle de variante.
- Estado de preparación de inventario.
- Confirmación de desactivación y reactivación desde lista o detalle.

## Reglas visibles
- SKU único.
- Combinación de atributos no duplicada.
- Datos físicos en kg/cm.
- Permitir perfil incompleto en borrador, con valores informados positivos; activar/reactivar exige peso, largo, ancho y alto completos. No registrar medidas del padre ni solicitar volumen como entrada independiente.
- Una nueva variante puede mostrarse como “Preparando inventario” hasta completar su inicialización.
- El padre no necesita estar activo para activar una variante. Los hijos en borrador o inactivos no bloquean por sí solos al padre ni se ofrecen comercialmente.

## Precio
No pedir un precio base obligatorio al crear cada variante. La variante hereda el precio del producto salvo que el gestor use posteriormente la gestión de Pricing para un precio específico.

## No mostrar
Eventos de inicialización ni términos técnicos de integración.

## Edición y cambios de estado
- Editar atributos no identificadores, imagen y datos físicos; conservar SKU y atributos identificadores de la variante publicada.
- La edición actualiza la misma variante. Si está activa y el resultado incumpliría sus requisitos de activación, rechazar el guardado, informar el motivo y conservar datos y estado anteriores.
- Solicitar confirmación antes de desactivar. Si era la última variante activa y el padre estaba activo, informar que el padre también queda inactivo; si estaba en borrador o inactivo, conserva su estado.
- Desactivar al padre bloquea comercialmente sus variantes sin cambiar sus estados individuales. Reactivar al padre no reactiva variantes inactivas.
- Para una variante inactiva, ofrecer “Reactivar” y solicitar confirmación conservando su SKU.
- Antes de confirmar la reactivación, revalidar que el padre admita variantes, la unicidad del SKU y la combinación, atributos e imagen, datos físicos completos y válidos en kg/cm e inventario preparado.
- Si faltan condiciones, conservar la variante inactiva y mostrar los motivos. Para una preparación pendiente o rechazada, permitir reintento con un mensaje operativo.
- Al completar la reactivación, mostrar “Variante activa”. No crear precio base ni mostrar que se reactiva automáticamente el padre; su reactivación se gestiona desde Productos.

La reactivación corresponde a la capacidad declarada en OpenAPI vigente; estos controles complementan el alcance del índice de prototipo actual, que ilustra principalmente alta y preparación.
