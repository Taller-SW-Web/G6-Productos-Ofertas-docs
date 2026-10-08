# HU-004 — Gestión de variantes y SKU

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** SPEC [SPEC-004](../specs/SPEC-004-gestion-variantes-skus.md) | Wireframe [WF-004](..\..\ux\wireframes\flows\WF-004-gestion-variantes-skus.md)

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
| CA-04 | Crear variante solicita exclusivamente `inventory.sku.initialization.requested` e inicia en `PENDING` sin acción manual requerida. |
| CA-05 | No se crea precio base por variante ni se emite inicialización de Pricing para la variante. |
| CA-06 | Variante sin override hereda precio del producto. |
| CA-07 | Activar exige Inventario confirmado, atributos e imagen válidos y perfil físico completo. El padre debe admitir variantes, pero no necesita estar activo. |
| CA-08 | El padre con variantes no crea saldo. |
| CA-09 | Peso/dimensiones pertenecen al SKU de variante y usan kg/cm con valores >0. Pueden estar incompletos en borrador; activar/reactivar exige los cuatro valores completos. El padre no tiene perfil propio y el volumen se deriva de las dimensiones. |
| CA-10 | Reintentos no duplican la inicialización. |
| CA-11 | La edición actualiza la misma variante, conservando `variant_id`, SKU comercial publicado y atributos identificadores; permite modificar atributos no identificadores, imagen y perfil físico válido. Si una edición de una variante activa incumple condiciones de activación, se rechaza conservando datos y estado anteriores. |
| CA-12 | Desactivar conserva la identidad SKU y publica `catalog.sku.deactivated` mediante RabbitMQ. Si era la última variante activa y el padre estaba activo, se inactiva al padre; si estaba en borrador o inactivo, conserva su estado. La baja del padre conserva los estados de los hijos y bloquea su exposición comercial. |
| CA-13 | Reactivar una variante `INACTIVA` conserva `variant_id` y SKU y revalida padre con variantes, unicidad de SKU y combinación, atributos e imagen válidos, perfil físico completo en kg/cm con valores >0 e Inventario confirmado como completado. Solo entonces pasa a `ACTIVA`; si falla, conserva `INACTIVA`. |
| CA-14 | Reactivar no crea precio base ni repite inicializaciones completadas. Si Inventario está pendiente o rechazado, el reintento conserva la identidad de operación. El padre se reactiva mediante su propio flujo y sus validaciones. |
| CA-15 | Las variantes en borrador o inactivas no bloquean por sí solas la activación del padre ni se ofrecen comercialmente. Reactivar al padre no reactiva variantes inactivas. |
| CA-16 | Los errores técnicos transitorios de inventario se recuperan automáticamente mediante la infraestructura de mensajería (RabbitMQ); no hay acción manual durante un estado `PENDING` ordinario. |
| CA-17 | El estado administrativo de preparación publicado permite conocer el estado real de inventario de cada variante (`PENDING`, `COMPLETED`, `REJECTED`), la causa en `code` y si admite recuperación manual (`manual_retry_allowed`). |
| CA-18 | El rechazo de inventario (`REJECTED`) mantiene la variante no publicable y no se reintenta automáticamente; Catálogo calcula autoritativamente `manual_retry_allowed=false` hasta que el gestor corrige los atributos o perfil físico y se revalidan las precondiciones locales. |
| CA-19 | La admisión de recuperación manual es atómica: exactamente una solicitud gana y obtiene HTTP 202 Accepted (iniciando un nuevo ciclo asíncrono y pasando a `PENDING` con `manual_retry_allowed=false`); las solicitudes concurrentes competidoras obtienen HTTP 409 PREPARACION_NO_REINTENTABLE. HTTP 202 formaliza admisión de recuperación, no éxito final. |
| CA-20 | La recuperación manual conserva la `operation_id` original, genera una nueva `message_id` para transporte, correlaciona el resultado con `causation_id`, construye el comando con el estado actual validado de la variante y no duplica SKU ni inicializaciones. |
| CA-21 | Una inicialización de inventario en estado `COMPLETED` es terminal e irreversible; nunca vuelve a ejecutarse ni reintentarse. |
| CA-22 | La variante recupera ÚNICAMENTE la inicialización de inventario de su SKU; nunca inicializa ni reintenta Pricing. |
