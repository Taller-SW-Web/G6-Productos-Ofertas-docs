# HU-001 — Carga y exportación masiva de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** SPEC [SPEC-001](../specs/SPEC-001-carga-exportacion-masiva-productos.md) | Wireframe [WF-001](../wireframes/flows/WF-001-carga-exportacion-masiva-productos.md)

---

**Como** gestor comercial,  
**quiero** cargar productos masivamente,  
**para** preparar catálogo, precio e inventario sin duplicar datos entre dominios.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | El archivo se valida antes de persistir. |
| CA-02 | Los productos se crean/actualizan en Catálogo. |
| CA-03 | El precio inicial se prepara con `pricing.product.initialization.requested`. |
| CA-04 | Cada SKU vendible nuevo se inicializa con `inventory.sku.initialization.requested`. |
| CA-05 | Una variante sin override hereda el precio del producto. |
| CA-06 | El padre con variantes no crea saldo de Inventario. |
| CA-07 | Un retry no duplica efectos. |
| CA-08 | Un error de Pricing/Inventario se reporta sin fingir rollback distribuido. |
| CA-09 | La activación solo ocurre cuando las dependencias requeridas estén preparadas. |
| CA-10 | El reporte final identifica filas exitosas y fallidas. |

## Escenario — Alta masiva nueva

DADO un archivo válido, CUANDO se procesa, ENTONCES Catálogo persiste los borradores y coordina Pricing/Inventario mediante los contratos asíncronos publicados.

## Escenario — Reintento

DADO un lote ya procesado parcialmente, CUANDO se reintenta con la misma identidad, ENTONCES no se duplican productos, precios ni saldos.