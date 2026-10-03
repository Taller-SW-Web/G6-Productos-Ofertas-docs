# WF-003 — Gestión de productos


## Usuario objetivo
Gestor comercial.

## Pantallas
- Lista.
- Crear producto.
- Editar producto.
- Detalle.
- Confirmación de activación.
- Estado de preparación.

## Flujo de creación y estado de preparación

La interfaz consume el estado administrativo publicado (`GET /api/v1/productos/{productoId}/preparacion`) y **nunca infiere que false = rejected** a partir de booleanos antiguos:

1. Completar datos mínimos.
2. Guardar borrador.
3. Si el estado es `PENDING` con `manual_retry_allowed=false`: mostrar indicador “Preparando precio e inventario…” (o la dependencia correspondiente; para producto con variantes solo precio, dirigiendo a Variantes para las unidades vendibles). **No mostrar botón de reintento**, ya que la operación está en curso o en recuperación técnica automática.
4. Si una dependencia resulta `REJECTED`: mostrar la causa funcional reportada en `code` y conservar el producto en `BORRADOR`. Si la causa dispone de una operación publicada para su corrección, permitir realizarla; en caso contrario mostrar la causa y mantener la recuperación manual deshabilitada (`manual_retry_allowed=false`). El botón de reintento permanece inactivo hasta que el gestor guarda una corrección válida y Catálogo revalida y confirma autoritativamente `manual_retry_allowed=true`.
5. Si `manual_retry_allowed=true` (Catálogo autoriza el reintento tras revalidar precondiciones de un borrador corregido mediante operaciones publicadas, o en estado `PENDING` tras superar el umbral operativo configurable): mostrar y habilitar la acción “Reintentar preparación”.
6. Tras pulsar la acción: el cliente solicita el reintento vía HTTP. Exactamente una solicitud adquiere la transición (`202 Accepted`) y pasa a `PENDING`; solicitudes concurrentes o repetidas que compitan reciben `409 PREPARACION_NO_REINTENTABLE`, manteniendo la UI sincronizada sin duplicar acciones ni estados. La UI nunca muestra “completado” hasta recibir confirmación con estado `COMPLETED`.
7. Cuando las preparaciones requeridas concluyen con `COMPLETED` (precio e inventario del SKU simple, o precio y al menos una variante activa y preparada, con inventario confirmado en todas las variantes activas; los hijos en borrador o inactivos no bloquean ni se ofrecen comercialmente), habilitar la acción de activación si se cumplen las demás condiciones de negocio.

## Producto con variantes
La pantalla no afirma que el producto padre tenga stock (`inventario=null`). Dirige a Variantes (WF-004) para administrar y consultar la preparación de los SKU vendibles.

## Datos físicos
Solo producto simple. Mostrar campos de entrada bajo perfil físico: Peso (kg), Largo (cm), Ancho (cm), Alto (cm).
Permitir borrador incompleto, con valores informados positivos; activar/reactivar exige los cuatro valores completos. El padre con variantes no registra peso ni dimensiones. El volumen se deriva de las dimensiones y no se solicita como entrada independiente.

## Edición y cambios de estado
- Editar conserva el mismo producto, su naturaleza comercial y la coherencia con sus variantes; no recodifica SKU base, cambia el modelo de venta ni crea o sustituye variantes. Otro producto comercial requiere una nueva alta.
- Si la edición de un producto activo dejaría de cumplir requisitos de activación, rechazar el guardado, informar el motivo y conservar datos y estado anteriores.
- Desactivar al padre bloquea comercialmente sus variantes conservando sus estados individuales. Reactivar revalida las condiciones del padre sin reactivar hijos inactivos; reactivar un hijo tampoco reactiva al padre.

## No mostrar
RabbitMQ, colas, exchanges, routing keys, nombres físicos de colas, DLQ, contadores de retry, nombres de mensajes de eventos, `operation_id`, `message_id`, `causation_id`, `price_version`, nombres de tablas o endpoints.
