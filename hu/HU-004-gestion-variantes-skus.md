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
| CA-11 | La edición conserva `variant_id`, SKU comercial publicado y atributos identificadores; permite modificar atributos no identificadores, imagen y perfil físico válido. |
| CA-12 | Desactivar conserva la identidad SKU y publica `catalog.sku.deactivated` mediante RabbitMQ. Si era la última variante activa, se inactiva el padre conforme a SPEC-003. |
| CA-13 | Reactivar una variante `INACTIVA` conserva `variant_id` y SKU y revalida padre con variantes, unicidad de SKU y combinación, atributos e imagen válidos, perfil físico completo en kg/cm con valores >0 e Inventario confirmado como completado. Solo entonces pasa a `ACTIVA`; si falla, conserva `INACTIVA`. |
| CA-14 | Reactivar no crea precio base ni repite inicializaciones completadas. Si Inventario está pendiente o rechazado, el reintento conserva la identidad de operación. El padre se reactiva mediante su propio flujo y sus validaciones. |
