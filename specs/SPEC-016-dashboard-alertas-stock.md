# SPEC-016 — Especificación: Dashboard analítico y alertas de stock

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** HU [HU-016](./hu/HU-016-dashboard-alertas-stock.md) | Wireframe [WF-016](./wireframes/flows/WF-016-dashboard-alertas-stock.md)

## Descripción
Dashboard de consulta para monitorear inventario por SKU vendible y ubicación. El producto es únicamente agrupador comercial.

## 1. Indicadores
- total de SKUs vendibles;
- unidades disponibles;
- SKUs Disponibles;
- Stock bajo;
- Agotados.

## 2. Alertas
Por `(sku, location_id)`:

```text
0 < available <= umbral_efectivo -> STOCK_BAJO
available = 0 -> AGOTADO
```

`umbral_efectivo = override SKU ?? umbral_global`.

## 3. Actualización
El dashboard **consume** `inventory.stock.changed`. Cuando Inventario publica un cambio confirmado, la proyección del dashboard recalcula indicadores/alertas.

El dashboard:
- NO publica `inventory.stock.changed`;
- NO modifica `on_hand`, `reserved` o `available`;
- NO simula un consumo como acción de usuario;
- NO usa polling fijo como requisito.

## 4. Distribución por ubicación
Mostrar `on_hand`, `reserved`, `available`, cantidad de SKUs con stock bajo y agotados por ubicación.

Si solo existe `DEFAULT`, se muestra vista única sin inventar ubicaciones adicionales.

## 5. Filtros
Producto, categoría, marca, SKU, `location_id` y estado de inventario (`Disponible | Stock bajo | Agotado`).

## 6. Fuera de alcance
Ventas, rankings, Top productos, edición/ajuste de stock, reservas/consumo y métricas comerciales.

## 7. Resultado esperado
Vista de inventario de solo lectura, reactiva a hechos confirmados publicados por Inventario.

## Criterio de completitud
Los indicadores usan SKU/location, el filtro por estado funciona y el dashboard nunca se comporta como productor o editor de stock.
