# HU-002 — Gestión de combos de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** SPEC [SPEC-002](../specs/SPEC-002-gestion-combos-productos.md) | Wireframe [WF-002](../wireframes/flows/WF-002-gestion-combos-productos.md)

---

**Como** gestor comercial,  
**quiero** crear combos válidos,  
**para** ofrecer conjuntos sin romper precio, inventario ni cupones.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | El combo contiene al menos dos componentes. |
| CA-02 | No se admiten combos anidados. |
| CA-03 | La disponibilidad se deriva de los SKU componentes. |
| CA-04 | El combo no posee saldo propio. |
| CA-05 | Validar un cupón no consume. |
| CA-06 | El consumo de cupón lo orquesta Ventas mediante el contrato asíncrono publicado. |
| CA-07 | La reserva/consumo de stock lo orquesta Ventas. |
| CA-08 | Si un componente no está disponible, el combo no se ofrece como comprable. |