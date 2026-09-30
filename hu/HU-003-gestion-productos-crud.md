# HU-003 — Gestión de productos (CRUD principal)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** SPEC [SPEC-003](../specs/SPEC-003-gestion-productos-crud.md) | Wireframe [WF-003](../wireframes/flows/WF-003-gestion-productos-crud.md)

---

**Como** gestor comercial,  
**quiero** administrar productos y su preparación técnica,  
**para** publicarlos solo cuando precio e inventario estén listos.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | El producto nace en `BORRADOR`. |
| CA-02 | `sku_base` es único. |
| CA-03 | Producto simple usa `sku_base` como SKU vendible. |
| CA-04 | Producto con variantes no posee stock físico propio. |
| CA-05 | Tras crear el borrador se solicita `pricing.product.initialization.requested`. |
| CA-06 | Producto simple solicita `inventory.sku.initialization.requested`. |
| CA-07 | Un retry no duplica precio ni identidad SKU. |
| CA-08 | Activar exige confirmación de Pricing e Inventario. |
| CA-09 | Rechazo de una dependencia mantiene `BORRADOR`. |
| CA-10 | Variantes sin override heredan el precio del producto. |
| CA-11 | El perfil físico usa kg/cm y valores >0. |
| CA-12 | Despacho obtiene físico sin stock/precio/pedido. |
| CA-13 | Desactivación es lógica y trazable. |