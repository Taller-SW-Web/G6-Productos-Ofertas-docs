# HU-016 — Historia de Usuario: Dashboard analítico y alertas de stock

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** Spec [SPEC-016](./specs/SPEC-016-dashboard-alertas-stock.md) | Flow [WF-016](./wireframes/flows/WF-016-dashboard-alertas-stock.md)

**Como** responsable de inventario, **quiero** visualizar indicadores, niveles y alertas, **para** detectar baja disponibilidad o agotamiento por ubicación.

## Criterios de aceptación
| ID | Criterio |
|---|---|
| CA-01 | Cantidad de SKU en Disponible/Stock bajo/Agotado. |
| CA-02 | Indicadores generales. |
| CA-03 | Stock bajo usa `available` y umbral efectivo. |
| CA-04 | Alertas para Stock bajo/Agotado. |
| CA-05 | Distribución por ubicación con `on_hand`, `reserved`, `available`. |
| CA-06 | Refleja estado confirmado actual. |
| CA-07 | Se actualiza al **recibir** `inventory.stock.changed`. |
| CA-08 | Tras consumo confirmado en Inventario, refleja transición de estado. |
| CA-09 | Filtro por ubicación; DEFAULT único si aplica. |
| CA-10 | Filtro por estado funciona sobre Disponible/Stock bajo/Agotado. |
| CA-11 | El dashboard no emite eventos de stock ni modifica saldos. |

## Escenarios
1. Entrada al dashboard → indicadores por estado.
2. `available<=umbral` y >0 → Stock bajo.
3. `available=0` → Agotado.
4. Dos ubicaciones → resumen independiente.
5. Inventario confirma consumo y publica cambio → dashboard recibe el hecho y recalcula.
6. Filtro `Stock bajo` → solo filas bajas.
7. Solo DEFAULT → no inventar selector de sedes adicionales.

## Dependencias
Productos/SKU para identificación; Inventario como fuente única de saldos y del evento `inventory.stock.changed`.
