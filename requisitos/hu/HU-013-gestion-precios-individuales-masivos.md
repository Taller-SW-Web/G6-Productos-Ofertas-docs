# HU-013 — Gestión de precios individuales y masivos

**Responsable:** Cristian Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** SPEC [SPEC-013](../specs/SPEC-013-gestion-precios-individuales-masivos.md) | Wireframe [WF-013](..\..\ux\wireframes\flows\WF-013-gestion-precios-individuales-masivos.md)

---

**Como** gestor comercial,  
**quiero** administrar precios y vigencias,  
**para** mantener una única fuente de verdad comercial.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | Pricing es owner del precio. |
| CA-02 | El primer precio usa `pricing.product.initialization.requested`. |
| CA-03 | `completed` confirma la preparación de Pricing para activación del producto. |
| CA-04 | El primer precio se registra como `CREACION`. |
| CA-05 | `pricing.price.changed` se publica después del commit. |
| CA-06 | Variante sin override hereda precio del producto. |
| CA-07 | Crear variante no crea precio artificial. |
| CA-08 | Una escritura obsoleta se rechaza por versión. |
| CA-09 | No existen vigencias superpuestas para el mismo alcance. |
| CA-10 | La carga masiva exclusiva de Pricing no promete atomicidad con Catálogo/Inventario. |