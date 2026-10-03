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
| CA-08 | Activar/reactivar exige Pricing preparado e Inventario confirmado para el SKU simple o todas las variantes activas. El padre con variantes necesita al menos una variante activa y preparada; los hijos en borrador o inactivos no bloquean ni se ofrecen comercialmente. |
| CA-09 | Durante el alta, el rechazo de una dependencia requerida mantiene `BORRADOR`; una variante no activa rechazada no bloquea por sí sola al padre ni lo inactiva. |
| CA-10 | Variantes sin override heredan el precio del producto. |
| CA-11 | El perfil físico simple usa kg/cm y valores >0. Puede estar incompleto en borrador; activar/reactivar exige peso, largo, ancho y alto completos. El padre con variantes no tiene perfil propio; el volumen es derivado, no una entrada independiente. |
| CA-12 | Despacho obtiene físico sin stock/precio/pedido. |
| CA-13 | Desactivación es lógica y trazable. |
| CA-14 | Editar conserva el producto, su naturaleza comercial y la coherencia con sus variantes, sin recodificar SKU base, cambiar el modelo de venta ni crear variantes. Cambiar la identidad comercial requiere otro producto. Si una edición de un producto activo incumple condiciones de activación, se rechaza conservando datos y estado anteriores. |
| CA-15 | Desactivar al padre bloquea comercialmente a sus variantes conservando sus estados. Reactivar al padre revalida sus condiciones y no reactiva hijos inactivos; reactivar una variante no reactiva al padre. |
| CA-16 | Los errores técnicos transitorios se recuperan automáticamente mediante la infraestructura de mensajería (RabbitMQ); no hay intervención manual durante un estado `PENDING` ordinario. |
| CA-17 | El estado administrativo de preparación permite a la interfaz consultar el estado real (`PENDING`, `COMPLETED`, `REJECTED`), el código funcional de causa en `code` y la bandera autoritativa `manual_retry_allowed`. |
| CA-18 | El rechazo de negocio de una dependencia (`REJECTED`) mantiene el producto en `BORRADOR` y no se reintenta automáticamente; la recuperación manual excepcional solo se habilita cuando el backend expone autoritativamente `manual_retry_allowed=true` tras validar que la causa es recuperable con operaciones publicadas. |
| CA-19 | La admisión de recuperación manual es atómica: exactamente una solicitud gana y obtiene HTTP 202 Accepted (iniciando un nuevo ciclo asíncrono y pasando a `PENDING` con `manual_retry_allowed=false`); las solicitudes concurrentes competidoras obtienen HTTP 409 PREPARACION_NO_REINTENTABLE. HTTP 202 formaliza admisión de recuperación, no éxito final. |
| CA-20 | La recuperación manual conserva la `operation_id` original de la preparación, genera una nueva `message_id` para la republicación, correlaciona el resultado mediante `causation_id` y no duplica producto, precio, SKU ni inicializaciones. |
| CA-21 | Una dependencia en estado `COMPLETED` es terminal e irreversible; nunca vuelve a ejecutarse ni reintentarse. |
| CA-22 | El producto simple permite recuperar Pricing e Inventario del `sku_base`; el producto con variantes recupera Inventario a nivel de cada variante específica (según HU-004) y nunca a nivel del producto padre. |
