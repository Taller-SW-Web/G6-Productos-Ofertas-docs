# HU-016 — Dashboard analítico y alertas de stock

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** SPEC [SPEC-016](../specs/SPEC-016-dashboard-alertas-stock.md) | Wireframe [WF-016](../wireframes/flows/WF-016-dashboard-alertas-stock.md)

---

**Como** gestor comercial con capacidades de consulta de inventario,  
**quiero** visualizar indicadores y alertas por ubicación,  
**para** detectar disponibilidad baja, unidades bloqueadas y traslados con problemas.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | Muestra SKU por Disponible/Stock bajo/Agotado. |
| CA-02 | Muestra unidades físicas, reservadas, bloqueadas y disponibles. |
| CA-03 | Disponible usa `max(on_hand - reserved - blocked, 0)`. |
| CA-04 | Stock bajo usa `available` y umbral efectivo. |
| CA-05 | Distribución por ubicación incluye `blocked`. |
| CA-06 | Se actualiza al recibir `inventory.stock.changed`. |
| CA-07 | Refleja consumo, bloqueo, merma, reintegro y recepción confirmados. |
| CA-08 | Muestra cantidad de traslados pendientes y con discrepancia. |
| CA-09 | Permite filtrar por ubicación y estado. |
| CA-10 | No emite eventos de stock ni modifica saldos. |
| CA-11 | Un traslado con discrepancia no altera por sí mismo las unidades disponibles. |

## Escenarios

1. Una incidencia bloquea 2 unidades → baja Disponible y sube Bloqueado.
2. Una rehabilitación → baja Bloqueado y sube Disponible.
3. Una recepción como Disponible → aumenta Físico y Disponible del destino.
4. Una recepción como Bloqueado → aumenta Físico y Bloqueado, Disponible no cambia.
5. Un cierre parcial → aumenta el KPI “Traslados con discrepancia”.
