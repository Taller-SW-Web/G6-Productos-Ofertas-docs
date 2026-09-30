# WF-002 — Gestión de combos

## Usuario objetivo
Gestor comercial.

## Objetivo
Crear y editar combos con componentes válidos, garantizando una propuesta económica con ventaja frente a la compra individual y una lectura comercial transparente.

## Pantallas
- **Lista:** catálogo de combos creados con indicador de estado (activo, inactivo) y disponibilidad estimada informativa.
- **Crear/editar:** formulario con datos generales, selector de componentes SKU directos (mínimo 2), comparación automática contra sumas de precios regulares/vigentes y cálculo de aporte de disponibilidad.
- **Detalle:** ficha informativa completa del combo, componentes vinculados y estado comercial.
- **Estado no disponible:** vista que informa la no elegibilidad para compra cuando un componente fue desactivado o se encuentra sin existencias.

## Reglas visibles
- Mínimo dos productos/SKU componentes.
- Prohibición estricta de anidamiento (no permitir combo dentro de combo).
- Indicador visual de beneficio económico del combo: el precio promocional debe ser menor que la compra de los componentes por separado (`Suma regular` y `Suma pública vigente`).
- Alerta clara cuando un componente fue desactivado o no tiene existencias.
- Nota informativa visible: «La compra verifica y reserva existencias durante el pedido. La disponibilidad mostrada es meramente informativa».

## Integración asíncrona y checkout
- La pantalla administrativa no consume cupón ni reserva stock.
- La compra se orquesta en checkout por el módulo de Ventas:
  1. Si la reserva de existencias falla, se cancela el pedido sin tocar cupones.
  2. Si el consumo de cupón falla, se libera la reserva de stock confirmada y se cancela el pedido.
  3. Si el pago falla habiendo consumido cupón, se libera la reserva de stock y se solicita la restitución de cupón; si no tenía cupón, únicamente se libera la reserva de existencias.
