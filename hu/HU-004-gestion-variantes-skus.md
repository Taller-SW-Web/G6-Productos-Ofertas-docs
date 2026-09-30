# HU-004 — Gestión de variantes y SKU

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** SPEC [SPEC-004](../specs/SPEC-004-gestion-variantes-skus.md) | Wireframe [WF-004](../wireframes/flows/WF-004-gestion-variantes-skus.md)

---

**Como** gestor comercial,  
**quiero** administrar variantes vendibles,  
**para** diferenciar atributos y stock sin duplicar el precio base del producto.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | Solo productos con variantes permiten crearlas. |
| CA-02 | Cada variante posee SKU único. |
| CA-03 | La combinación identificadora no se duplica. |
| CA-04 | Crear variante solicita `inventory.sku.initialization.requested`. |
| CA-05 | No se crea precio base por variante. |
| CA-06 | Variante sin override hereda precio del producto. |
| CA-07 | Activar requiere inicialización de Inventario. |
| CA-08 | El padre con variantes no crea saldo. |
| CA-09 | Peso/dimensiones pertenecen al SKU de variante. |
| CA-10 | Reintentos no duplican la inicialización. |