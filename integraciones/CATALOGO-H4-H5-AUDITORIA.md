# Catálogo H4 y preparación de mensajería H5

Bases inspeccionadas: Backend `055548f`, Frontend `4e4856f`, Docs `0a4c333`. OpenAPI `0.6.0-rc.5`. La ruta administrativa de detalle se registra como candidata para reconciliar el contrato con el código, con revisión normativa pendiente.

## Operaciones HTTP

Las rutas llevan el prefijo `/api/v1`. **A** indica JWT humano con `GESTOR_COMERCIAL` en el servicio. **C** indica lectura comercial según la identidad, allowlist, scope y canal del contrato de esa operación. **M** indica JWT técnico con scope y cliente específicos. Las operaciones marcadas como internas se llaman directamente entre servicios. Las demás tienen ruta de Gateway en el repositorio inspeccionado. La columna de evidencia remite a suites locales o integración pendiente, sin inferir estado del despliegue.

| Operación OpenAPI | Método y ruta | Controller → servicio/repositorio | Consumidor | Seguridad | Evidencia y estado |
| --- | --- | --- | --- | --- | --- |
| obtenerContextoSku | GET `/productos/skus/{sku}/contexto` | SKU Context → consulta SKU | Pricing | M interno; `modulo-productos`, `catalogo:leer` | Suite SKU Context; grant efectivo pendiente |
| obtenerContextosSkuLote | POST `/productos/skus/contexto/lote` | SKU Context → consulta SKU en lote | Pricing | M interno; mismo scope y cliente | Suite SKU Context; grant efectivo pendiente |
| listarProductosAdministracion | GET `/productos/administracion` | Query → Query Repository | ProductsPage | A | Filtro de tipo en Gateway antes del conteo; fixture frontend |
| resolverSkusAdministracion | POST `/productos/administracion/skus/resolver` | Query → Query Repository | Combos administrativo | A | Contrato lote vigente; conserva orden y estados |
| listarProductos | GET `/productos` | Commercial → repositorio comercial | Marketplace y otros consumidores autorizados | C | Filtros y canal explícito; ruta separada de la grilla administrativa |
| crearProducto | POST `/productos` | Mutation → Mutation Repository | ProductCreatePage | A | Alta de borrador y preparación; persistencia en suite aislada |
| obtenerProducto | GET `/productos/{productoId}` | Query → consulta comercial | Consumidores comerciales | C | Visibilidad comercial conserva reglas por canal |
| actualizarProducto | PATCH `/productos/{productoId}` | Mutation → Mutation Repository | ProductEditPage | A | Q-06 exige versión y esquema; conflicto conserva el formulario |
| consultarDatosFisicos | POST `/productos/datos-fisicos/consulta` | Query → Query Repository | Despacho | M; `modulo-despacho`, `productos:fisicos:leer` | Claims locales; grant efectivo pendiente |
| activarProducto | POST `/productos/{productoId}/activar` | Mutation → agregado | ProductDetailPage | A | Preparación y requisitos comerciales gobiernan elegibilidad |
| desactivarProducto | POST `/productos/{productoId}/desactivar` | Mutation → agregado/outbox | ProductDetailPage | A | Brecha de evento del SKU simple pendiente |
| reactivarProducto | POST `/productos/{productoId}/reactivar` | Mutation → agregado | ProductDetailPage | A | Conserva validación de versión y elegibilidad |
| obtenerProductoPorSlug | GET `/productos/por-slug/{slug}` | Commercial → repositorio comercial | Consumidores comerciales | C | Frontera comercial; aislar canal |
| obtenerPreparacionProducto | GET `/productos/{productoId}/preparacion` | Query → activation checks/outbox | ProductPreparationPage, VariantPreparationPage | A | Estados por operación; resultado bilateral pendiente |
| reintentarPreparacionProducto | POST `/productos/{productoId}/preparacion/reintentar` | Mutation → activation checks/outbox | ProductPreparationPage | A | Reintento sujeto al estado persistido |
| listarVariantesProducto | GET `/productos/{productoId}/variantes` | Query → Query Repository | VariantListPage | A | Filtro de estado y paginación. Gateway conserva el 400 VALIDACION contractual. |
| crearVariante | POST `/productos/{productoId}/variantes` | Mutation → Mutation Repository | VariantCreatePage | A | SKU explícito, identidad global y preparación de Inventory |
| obtenerVariante | GET `/productos/{productoId}/variantes/{variantId}` | Query → Query Repository | VariantDetailPage, VariantEditPage | A | Valida pertenencia a producto. Gateway conserva el 400 VALIDACION contractual. |
| actualizarVariante | PATCH `/productos/{productoId}/variantes/{variantId}` | Mutation → Mutation Repository | VariantEditPage | A | Identidad inmutable y versión |
| activarVariante | POST `/productos/{productoId}/variantes/{variantId}/activar` | Mutation → agregado | VariantDetailPage | A | Requiere elegibilidad real |
| desactivarVariante | POST `/productos/{productoId}/variantes/{variantId}/desactivar` | Mutation → agregado/outbox | VariantDetailPage | A | Emite baja de SKU con versión |
| reactivarVariante | POST `/productos/{productoId}/variantes/{variantId}/reactivar` | Mutation → agregado | VariantDetailPage | A | Conserva validación de versión y elegibilidad |
| reintentarPreparacionVariante | POST `/productos/{productoId}/variantes/{variantId}/preparacion/reintentar` | Mutation → activation checks/outbox | VariantPreparationPage | A | Reintento de Inventory sujeto al estado |
| resolverCodigoBarras | POST `/productos/codigos-barras/resolver` | Barcode → Barcode Repository | Retail | M; `modulo-retail`, `catalogo:leer` | Identidad exacta y grant efectivo pendiente |
| obtenerProductoAdministracion | GET `/productos/administracion/{productoId}` | Query → Query Repository | ProductDetailPage, ProductEditPage | A | Ruta existente; DTO candidato y señal Q-06 |

## Hallazgos y decisiones

- **Q-06.** El detalle administrativo puede confirmar elegibilidad estructural desde el mismo snapshot de PostgreSQL. Un estado histórico desconocido, un producto con hijos, un padre de variantes o un estado distinto de BORRADOR deshabilitan la corrección. PATCH mantiene el control de concurrencia y de atributos. La UI omite el tipo en la edición ordinaria y lo envía solamente ante una corrección elegible.
- **Taxonomy.** El listado resuelve categoría y tipo una vez por carga de colecciones, sin consultar por fila. El detalle resuelve además la marca. Si falta un maestro no se infiere un nombre desde el ID. El PR Backend #225 de proyección de eventos ya está en la base.
- **Pricing.** La inicialización usa operación, correlación y causalidad. Para operaciones de contexto SKU se conserva la identidad privada. La solicitud de grants y la evidencia local no acreditan autorización efectiva en G7.
- **Inventory.** El código de `origin/taco` revisado ya es ancestro de la base Backend. La baja de una variante emite `catalog.sku.deactivated`. El producto simple emite `catalog.product.deactivated` y el handler de Inventory escucha la baja de SKU. Taco, Poma y Marco deben acordar la semántica compatible de baja del SKU vendible simple y validar sus efectos en Pricing, Promotions y Combos antes de cambiar publicaciones.
- **SPEC-016.** Inventory rechaza explícitamente producto/categoría/marca en su dashboard. El resolver administrativo actual exige conocer los SKU; el listado de productos pagina productos, sin poder representar por sí solo la relación completa de SKU vendibles. Una consulta interna candidata de Catalog debería devolver, para filtros exactos, una página y cursor estables de identidades `(sku, product_id, variant_id)`, con límites, semántica de estados, aislamiento, scope y allowlist homologados. Inventory filtra y pagina sobre el universo completo antes de agregar stock por ubicación. Taco y Poma deben acordar semántica, volumen, límites y errores. G7 y Marco deben aprobar acceso. La consulta candidata carece de endpoint normativo.
- **Outbox H4.** La consulta agregada de solo lectura del 15 de noviembre de 2026 encontró dos solicitudes de Pricing y dos de Inventory pendientes, con cero confirmaciones. Tres filas tenían cero intentos registrados. Una de Pricing tenía `BROKER_PUBLISH_UNCONFIRMED`. Los checks mostraban Inventory 55 COMPLETED y 2 PENDING, y Pricing 20 COMPLETED y 2 PENDING. El relay toma primero la fila pendiente más antigua y termina el ciclo al fallar un envío. Es un mecanismo capaz de retrasar las demás filas. La consulta no identifica por qué falló la confirmación ni valida el usuario del broker. En un ambiente autorizado, correlacionar intentos y logs del relay, verificar exchange, bindings, permisos, usuario AMQP y confirmación. Reconciliar Inbox y resultado terminal antes de cualquier reenvío.

## Clasificación de pendientes

| Frontera | Estado | Responsable y evidencia necesaria |
| --- | --- | --- |
| G7 y Gateway | BLOQUEADO_G7 / IMPLEMENTADO_SIN_E2E_REAL | G7 y Marco. Validar issuer/JWKS, claims, audiencia de servicio y grants efectivos con el Gateway autorizado. |
| Taxonomy | IMPLEMENTADO_SIN_E2E_REAL | López y Poma. Probar lectura de maestros y corrección de tipo contra servicios y esquema vigentes. |
| Pricing / Inventory | IMPLEMENTADO_SIN_E2E_REAL | Vera, Taco y Poma. Confirmar flujo completo de solicitudes y resultados por IDs en un entorno autorizado. |
| Baja SKU simple / SPEC-016 | BLOQUEADO_CONTRATO | Taco, Poma y Marco. Acordar evento y resolver de stock antes de habilitar consumidores. |
| Mensajería H5 | PENDIENTE_APROBACION_H5 | Marco, infraestructura y owners de los consumidores. Validar corte, rollback, Azure y conciliación. |

Los PR Backend #186, #214, #222, #225, #228, #230 y #231, y Frontend #73, #75, #81 y #82 estaban fusionados al preparar esta revisión. Backend #206 y #218 estaban cerrados sin merge. Se revisó el código de la base sin incorporar ramas viejas.
