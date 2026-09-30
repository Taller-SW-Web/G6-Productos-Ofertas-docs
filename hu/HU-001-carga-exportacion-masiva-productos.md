# HU-001 — Carga y exportación masiva de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** SPEC [SPEC-001](../specs/SPEC-001-carga-exportacion-masiva-productos.md) | Wireframe [WF-001](../wireframes/flows/WF-001-carga-exportacion-masiva-productos.md)

---

**Como** gestor comercial,  
**quiero** cargar y exportar productos masivamente,  
**para** preparar catálogo, precio e inventario sin duplicar datos entre dominios y disponer de archivos consolidados de la totalidad de la información vigente.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | El archivo se valida en formato, tamaño y estructura antes de persistir borradores. |
| CA-02 | Los productos y variantes se crean/actualizan en Catálogo en estado borrador. |
| CA-03 | El precio inicial se prepara con `pricing.product.initialization.requested`. |
| CA-04 | Cada SKU vendible nuevo se inicializa con `inventory.sku.initialization.requested`: crea saldo cero si existe `default_location_id` o registra la identidad del SKU sin saldo si es nulo. |
| CA-05 | Una variante sin override hereda el precio del producto. |
| CA-06 | El producto padre con variantes no crea saldo en Inventario. |
| CA-07 | Un retry con el mismo `batch_id` no duplica productos, precios ni saldos. |
| CA-08 | Un error de Pricing o Inventario se reporta individualmente sin ejecutar rollback distribuido destructivo. |
| CA-09 | La consolidación exitosa de una fila requiere que todas sus dependencias hayan completado. |
| CA-10 | El reporte final descargable identifica filas exitosas, fallidas y el dominio específico del error. |
| CA-11 | El gestor puede solicitar la exportación completa de la totalidad del catálogo activo indicando formato CSV o XLSX. |
| CA-12 | El trabajo de exportación se procesa de forma asíncrona reportando su estado (`QUEUED`, `PROCESSING`, `COMPLETED`, `FAILED_GENERAL`). |
| CA-13 | Una vez completada la exportación, el archivo consolidado queda disponible para descarga. |
| CA-14 | Si una fila incluye stock inicial mayor a cero y existe ubicación predeterminada, se procesa mediante `inventory.bulk.stock.adjust.requested`; si no existe ubicación, no se inventa una ubicación y se reporta la observación. |
| CA-15 | La reanudación (`POST .../reanudar`) solo reintenta operaciones pendientes o marcadas con `needs_reconciliation`. |

## Escenario — Alta masiva nueva

DADO un archivo válido con productos, precios base y stock inicial,  
CUANDO se procesa el lote,  
ENTONCES Catálogo persiste los borradores, Pricing registra los precios base, Inventario inicializa los SKUs (creando saldo cero si hay ubicación predeterminada o registrando la identidad sin saldo si es nula) y aplica el stock inicial mediante el contrato Bulk si existe ubicación, consolidando la fila solo tras completar todas las dependencias.

## Escenario — Fallo parcial multidominio sin rollback

DADO un archivo donde la inicialización de Pricing tiene éxito pero la de Inventario es rechazada,  
CUANDO se consolida el lote,  
ENTONCES la fila queda en estado de error con `needs_reconciliation: true` y dominio fallido `INVENTARIO`, sin eliminar el precio ni el borrador creados.

## Escenario — Reintento idempotente

DADO un lote con filas observadas o pendientes de reconciliación,  
CUANDO se reintenta mediante el endpoint de reanudación con la misma identidad,  
ENTONCES el sistema procesa únicamente las dependencias pendientes sin duplicar datos en los dominios ya completados.

## Escenario — Exportación masiva de catálogo

DADO un catálogo activo con productos, variantes, precios y existencias vigentes,  
CUANDO el gestor solicita una exportación en formato CSV o XLSX,  
ENTONCES el sistema registra un trabajo asíncrono, genera el archivo consolidado de la totalidad del catálogo en segundo plano y notifica su disponibilidad para descarga directa.