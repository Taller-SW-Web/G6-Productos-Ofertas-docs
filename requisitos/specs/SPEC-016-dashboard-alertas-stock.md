# SPEC-016 — Dashboard analítico y alertas de stock

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** HU [HU-016](../hu/HU-016-dashboard-alertas-stock.md) | Wireframe [WF-016](..\..\ux\wireframes\flows\WF-016-dashboard-alertas-stock.md)

---

## 1. Objetivo

Dashboard de solo lectura para monitorear inventario por SKU vendible y ubicación.

## 2. Indicadores

- total de SKU vendibles;
- unidades físicas;
- unidades reservadas;
- unidades bloqueadas;
- unidades disponibles;
- SKU Disponibles;
- Stock bajo;
- Agotados;
- traslados pendientes;
- traslados con discrepancia.

## 3. Estados de disponibilidad

```text
available = max(on_hand - reserved - blocked, 0)

available = 0
-> AGOTADO

0 < available <= umbral_efectivo
-> STOCK_BAJO

available > umbral_efectivo
-> DISPONIBLE
```

## 4. Actualización

El dashboard consume:

```text
inventory.stock.changed
```

y recalcula indicadores después de cambios confirmados por:

- reserva;
- consumo;
- liberación;
- incidencia/bloqueo;
- rehabilitación;
- merma;
- reintegro;
- conciliación offline;
- recepción de traslado.

No publica eventos de Inventario ni modifica saldos.

## 5. Distribución por ubicación

Mostrar:

```text
on_hand
reserved
blocked
available
```

y cantidad de SKU por estado.

## 6. Traslados

El dashboard puede mostrar conteos/enlaces operativos de:

```text
EN_TRANSITO
RECIBIDO_PARCIAL
COMPLETADO_CON_DISCREPANCIA
```

La recepción se realiza en el flujo WF-015; el dashboard no ejecuta la mutación directamente.

## 7. Filtros

Producto, categoría, marca, SKU, ubicación y estado.

## 8. Fuera de alcance

- ventas;
- ranking de productos;
- edición directa de saldos;
- creación de reservas;
- recepción desde el dashboard;
- decisiones de empaque/despacho.