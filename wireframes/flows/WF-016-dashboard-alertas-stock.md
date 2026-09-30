# WF-016 — Dashboard analítico y alertas de stock


## Objetivo
Monitorear el inventario confirmado por SKU y ubicación sin exponer detalles técnicos.

## KPIs

```text
SKUs vendibles
Unidades disponibles
Unidades bloqueadas
Disponibles
Stock bajo
Agotados
Traslados pendientes
Traslados con discrepancia
```

## Tabla principal

Columnas:

```text
SKU
Producto
Ubicación
Físico
Reservado
Bloqueado
Disponible
Umbral
Estado
```

## Distribución por ubicación

Mostrar totales:

```text
Físico
Reservado
Bloqueado
Disponible
Stock bajo
Agotados
```

## Traslados
Panel de resumen:

- En tránsito.
- Recibidos parcialmente.
- Con discrepancia.

Puede enlazar a la pantalla de recepción de WF-015, pero no registrar recepción desde el dashboard.

## Actualización reactiva

Cuando llega un cambio confirmado, recalcular KPIs sin perder filtros.

## No mostrar

```text
on_hand
reserved
blocked
available
routing key
message_id
endpoint
operation_id
```

Los nombres técnicos anteriores no son etiquetas de interfaz.
