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

## Flujo de creación
1. Completar datos mínimos.
2. Guardar borrador.
3. Para producto simple, mostrar “Preparando precio e inventario”; para padre con variantes, mostrar la preparación de precio y dirigir a Variantes para preparar las unidades vendibles.
4. Habilitar activación al cumplir las demás condiciones y terminar las preparaciones requeridas: precio e inventario del SKU simple, o precio y al menos una variante activa y preparada, con inventario confirmado en todas las variantes activas. Los hijos en borrador o inactivos no bloquean al padre ni se ofrecen comercialmente.
5. Si falla una preparación, mostrar un mensaje operativo y permitir reintento.

## Producto con variantes
La pantalla no afirma que el producto padre tenga stock. Dirige a Variantes para administrar SKU vendibles.

## Datos físicos
Solo producto simple. Mostrar Peso (kg), Largo/Ancho/Alto (cm).
Permitir borrador incompleto, con valores informados positivos; activar/reactivar exige los cuatro valores completos. El padre con variantes no registra peso ni dimensiones. El volumen se deriva de las dimensiones y no se solicita como entrada independiente.

## Edición y cambios de estado
- Editar conserva el mismo producto, su naturaleza comercial y la coherencia con sus variantes; no recodifica SKU base, cambia el modelo de venta ni crea o sustituye variantes. Otro producto comercial requiere una nueva alta.
- Si la edición de un producto activo dejaría de cumplir requisitos de activación, rechazar el guardado, informar el motivo y conservar datos y estado anteriores.
- Desactivar al padre bloquea comercialmente sus variantes conservando sus estados individuales. Reactivar revalida las condiciones del padre sin reactivar hijos inactivos; reactivar un hijo tampoco reactiva al padre.

## No mostrar
Nombres de mensajes, `operation_id`, `price_version`, nombres de tablas o endpoints.
