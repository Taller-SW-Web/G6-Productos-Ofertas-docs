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
3. Mostrar “Preparando precio e inventario”.
4. Si ambas preparaciones terminan, habilitar activación cuando se cumplan las demás condiciones.
5. Si falla una preparación, mostrar un mensaje operativo y permitir reintento.

## Producto con variantes
La pantalla no afirma que el producto padre tenga stock. Dirige a Variantes para administrar SKU vendibles.

## Datos físicos
Solo producto simple. Mostrar Peso (kg), Largo/Ancho/Alto (cm).

## No mostrar
Nombres de mensajes, `operation_id`, `price_version`, nombres de tablas o endpoints.
