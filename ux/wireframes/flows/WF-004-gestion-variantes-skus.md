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
- Datos físicos bajo perfil anidado en kg/cm con valores mayores que cero.
- Permitir perfil físico incompleto en borrador, con valores informados positivos; activar/reactivar exige peso, largo, ancho y alto completos. No registrar medidas del padre ni solicitar volumen como entrada independiente.
- El padre no necesita estar activo para activar una variante. Los hijos en borrador o inactivos no bloquean por sí solos al padre ni se ofrecen comercialmente.
- La interfaz consume el estado administrativo publicado (`GET /api/v1/productos/{productoId}/preparacion`):
  - `PENDING` con `manual_retry_allowed=false`: mostrar “Preparando inventario…”. **No mostrar botón de reintento**, ya que la operación está en curso o en recuperación técnica automática.
  - `REJECTED`: mostrar la causa funcional reportada en `code`, mantener la variante no publicable y permitir corregir datos (atributos o perfil). El botón permanece inactivo hasta que se guardan los cambios y Catálogo confirma `manual_retry_allowed=true`.
  - `manual_retry_allowed=true`: ofrecer acción “Reintentar preparación de inventario”.
  - Tras solicitar reintento: exactamente una solicitud adquiere la transición (`202 Accepted`) y vuelve a `PENDING`; solicitudes concurrentes o no reintentables reciben `409 PREPARACION_NO_REINTENTABLE`. Nunca mostrar “completado” hasta recibir confirmación `COMPLETED`.

## Precio
No pedir un precio base obligatorio ni solicitar inicialización de Pricing al crear o reintentar cada variante. La variante hereda el precio del producto padre salvo que el gestor use posteriormente la gestión de Pricing para un precio específico.

## No mostrar
RabbitMQ, colas, exchanges, routing keys, nombres de colas, DLQ, contadores de retry, eventos de inicialización, `operation_id`, `message_id`, `causation_id`, ni términos técnicos de infraestructura o endpoints.

## Edición y cambios de estado
- Editar atributos no identificadores, imagen y datos físicos; conservar `variant_id`, SKU comercial publicado y atributos identificadores de la variante publicada.
- La edición actualiza la misma variante. Si está activa y el resultado incumpliría sus requisitos de activación, rechazar el guardado, informar el motivo y conservar datos y estado anteriores.
- Solicitar confirmación antes de desactivar. Si era la última variante activa y el padre estaba activo, informar que el padre también queda inactivo; si estaba en borrador o inactivo, conserva su estado.
- Desactivar al padre bloquea comercialmente sus variantes sin cambiar sus estados individuales. Reactivar al padre no reactiva variantes inactivas.
- Para una variante inactiva, ofrecer “Reactivar” y solicitar confirmación conservando su SKU.
- Antes de confirmar la reactivación, revalidar que el padre admita variantes, la unicidad del SKU y la combinación, atributos e imagen, datos físicos completos y válidos en kg/cm e inventario preparado con estado `COMPLETED`.
- Si faltan condiciones, conservar la variante inactiva y mostrar los motivos. Si la preparación de inventario admite reintento (`manual_retry_allowed=true`), permitir solicitar recuperación manual con un mensaje operativo. Una dependencia `COMPLETED` nunca se vuelve a ejecutar.
- Al completar la reactivación, mostrar “Variante activa”. No crear precio base ni mostrar que se reactiva automáticamente el padre; su reactivación se gestiona desde Productos.

La reactivación y la recuperación manual de variante corresponden a las capacidades declaradas en OpenAPI vigente; estos controles complementan el alcance del índice de prototipo actual, que ilustra principalmente alta y preparación.
