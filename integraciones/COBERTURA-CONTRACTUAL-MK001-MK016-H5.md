# Cobertura contractual MK-001 a MK-016 (H5)

Propuesta contractual centralizada publicada en Docs PR #133 para revisión; OpenAPI/AsyncAPI `0.7.0-rc.2` es la base y `0.7.0-rc.3` la revisión candidata. Las extensiones BULK_RETRY_V1, Catalog request V4 y resultados V2 conservan `PROPOSED_NOT_APPROVED`: están propuestas, no aprobadas ni habilitadas. La existencia de contrato no acredita autorización de habilitación.

| MK | Servicio / owner | Cobertura contractual y consumidor | Estado y trabajo requerido |
|---|---|---|---|
| MK-001 | Bulk / Castilla | Plantilla, importación, estado, reporte, reanudación selectiva y exportación; claim-check V3 único se reutiliza desde #243. | Backend #252 `MERGED` (merge commit `9e4ac0af2a3ea882784413401bd5016ff611caa2`); extensiones BULK_RETRY_V1 siguen `PROPOSED_NOT_APPROVED`. Catalog #243/#254 y aprobación contractual pendientes; no habilitar. |
| MK-002 | Combos / Castilla | CRUD y disponibilidad existentes; canales consultan disponibilidad. | `CONTRATO_EXISTENTE`; revisar implementación según controller y pruebas vigentes, sin añadir checkout. |
| MK-003 | Catalog / Poma | Administración, ciclo de vida, filtros y contexto SKU existentes. | `CONTRATO_EXISTENTE`; batch de SKU existente no resuelve población por producto/categoría/marca. |
| MK-004 | Catalog / Poma | Variantes, preparación diferida y ciclo de SKU cubiertos. | `CONTRATO_EXISTENTE`; conservar política de SKU simple y no crear REST de mensajería. |
| MK-005 | Promotions / Cueva | CRUD/validación de cupones y operaciones H5 existentes. | `CONTRATO_EXISTENTE`; G5 sigue `PENDIENTE_HOMOLOGACION_EXTERNA`, G7 `PENDIENTE_VERIFICACION`. |
| MK-006 | Promotions / Cueva | CRUD y evaluación de promociones existentes. | `CONTRATO_EXISTENTE`; lectura/evaluación no autoriza consumo. |
| MK-007 | Promotions / Cueva | Recomendaciones existentes; evaluación separada de mutaciones. | `CONTRATO_EXISTENTE`; no se añade evento por consultas. |
| MK-008 | Taxonomy / López | Categorías y baja asíncrona con consulta de operación existente. | `CONTRATO_EXISTENTE`; 202 no significa completado. |
| MK-009 | Taxonomy / López | Características y valores existentes. | `CONTRATO_EXISTENTE`; preservar nulls y correlación. |
| MK-010 | Taxonomy / López | Tipos y asociaciones existentes. | `CONTRATO_EXISTENTE`; mantener estado de operación y errores terminales. |
| MK-011 | Taxonomy / López | Marcas y baja asíncrona existentes. | `CONTRATO_EXISTENTE`; no crear mecanismo nuevo. |
| MK-012 | Taxonomy / López | SEO/metadatos existentes. | `CONTRATO_EXISTENTE`; sin endpoint adicional identificado. |
| MK-013 | Pricing / Vera | Precio, programación, prevalidación e importación HTTP existentes. | `CONTRATO_EXISTENTE`; #233 se mantiene como única vía de importación masiva de precios. |
| MK-014 | Price Audit / Vera | Historial, detalle y exportación append-only existentes. | `CONTRATO_EXISTENTE`; no añadir asientos ni comandos. |
| MK-015 | Inventory / Taco | Disponibilidad, reservas, incidencias, reintegros, traslados y umbrales existentes; agrega saldos de administración. | `CONTRATO_EXISTENTE` + `listarSaldosFisicosAdministracion`; GET de estado de reserva conserva allowlist `modulo-ventas`. |
| MK-016 | Inventory / Taco | Dashboard solo acepta `sku` y `locationId`; agrega alertas y ubicaciones administrativas. | Alertas/ubicaciones `CONTRATO_PROPUESTO`, backend `PENDIENTE_ENDPOINT_HTTP`. Filtros Catalog ampliados pendientes de adaptador. |

### Evidencia de integración Bulk Retry

Backend PR #252 fue fusionado mediante el commit `9e4ac0af2a3ea882784413401bd5016ff611caa2`. La CI general [#45103235690](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45103235690) y la integración Bulk↔Catalog [#45103231056](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45103231056) finalizaron `SUCCESS`. La evidencia conjunta ejecutó 144/144 pruebas `PASS` sobre PostgreSQL descartable. Esto acredita esa integración de prueba; Catalog #243/#254 siguen pendientes de integración en la rama principal y el contrato rc.3 continúa sin aprobación formal.

## Anexo de compatibilidad R01–R18 / N01

| ID | Compatibilidad y estado |
|---|---|
| R01 | Se conserva el flujo Catalog → Inventory de inicialización de SKU; estado runtime debe verificarse por SHA. |
| R02 | `inventory.bulk.stock.adjust.requested` tiene contrato tipado para ajuste absoluto inicial; runtime Inventory pendiente de handler durable, ubicación real, Inbox/Outbox y pruebas. |
| R03 / R14 | `pricing.bulk.price.apply.*` queda `RESERVADO_NO_APLICA_BULK_V2`; no implementar ni activar. Precio regular solo en ALTA por inicialización Catalog → Pricing; cambios masivos siguen el importador HTTP Pricing. |
| R04–R09 | Se preservan contratos y ownership existentes; no se habilita ningún flujo por existir en YAML. |
| R10 | Resultados tipados completed/rejected; integración de emisión y recepción permanece pendiente. `inventory.stock.adjusted` conserva su semántica previa y no se duplica `inventory.stock.changed`. |
| R11–R18 | Se preservan identificadores/canales existentes sin cambiar runtime, producer/consumer o transporte. |
| N01 | Se conserva mensaje y envelope actual; `causation_id` continúa opcional donde ya es opcional. |

### Discrepancias y evidencia pendiente

* Inventory #248 describe helpers internos de alertas/ubicaciones, no endpoints HTTP; frontend #90 permanece bloqueado hasta handler, Gateway, grant G7 y prueba.
* El runtime #248 trata paginación/`soloActivas=false` y `available=NULL` con diferencias frente al contrato aquí fijado. Corregir y probar el servicio antes de activar clientes.
* Filtros `productoId`, `categoriaId` y `marcaId` del dashboard se retiran de la operación actual; el código vigente devuelve 400 a filtros no reconocidos. La etapa futura depende de `POST /interno/productos/skus/filtrar`.

Rutas en OpenAPI son relativas a `/api/v1`. Identidad de evidencia: baseline de contrato arriba; revalidar SHA exacto de Backend/Frontend y de este PR antes de declarar estados probados.

## Anexo A — inventario ejecutable por operación

Cada entrada deriva de la propuesta OpenAPI `0.7.0-rc.3`, basada en master `0.7.0-rc.2`; rutas son relativas a `/api/v1`. `-` indica que OpenAPI no declara consumidores o schema directo. Los estados de implementación no se deducen de la documentación.

### MK-001 — Bulk

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/carga-masiva/productos/plantilla` | `descargarPlantillaProductos` | — | — | 200,400,401,403,500,503 | provisional-internal |
| POST `/carga-masiva/productos/importaciones` | `crearImportacionGeneralProductos` | — | — | 202,400,401,403,413,422,500,503 | provisional-internal |
| GET `/carga-masiva/productos/importaciones/{batchId}` | `obtenerImportacionGeneralProductos` | — | EstadoImportacionGeneral | 200,401,403,404,500,503 | provisional-internal |
| GET `/carga-masiva/productos/importaciones/por-correlacion/{correlationId}` | `conciliarImportacionGeneralPorCorrelacion` | — | ImportacionGeneralConciliada | 200,400,401,403,404,503 | propuesta no aprobada; solo lectura `(owner_sub, correlation_id)` |
| GET `/carga-masiva/productos/importaciones/{batchId}/reporte` | `descargarReporteImportacionGeneral` | — | — | 200,401,403,404,500,503 | provisional-internal |
| POST `/carga-masiva/productos/importaciones/{batchId}/reanudar` | `reanudarImportacionGeneral` | — | ReanudarImportacionRequest | 202,401,403,404,409,500,503 | provisional-internal |
| POST `/carga-masiva/productos/exportaciones` | `crearExportacionGeneralProductos` | — | CrearExportacionProductosRequest | 202,400,401,403,500,503 | provisional-internal |
| GET `/carga-masiva/productos/exportaciones/{exportId}` | `obtenerExportacionGeneralProductos` | — | TrabajoExportacion | 200,401,403,404,500,503 | provisional-internal |
| GET `/carga-masiva/productos/exportaciones/{exportId}/archivo` | `descargarExportacionGeneralProductos` | — | — | 200,401,403,404,500,503 | provisional-internal |

### MK-002 — Combos

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/combos/{comboId}` | `obtenerCombo` | — | Combo | 200,400,401,403,404,500,503 | stable |
| PATCH `/combos/{comboId}` | `actualizarCombo` | — | ComboUpdateRequest, Combo | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| GET `/combos` | `listarCombosAdmin` | — | PaginaCombos | 200,400,401,403,500,503 | provisional-internal |
| POST `/combos` | `crearCombo` | — | ComboCreateRequest | 201,400,401,403,404,422,500,503 | provisional-internal |
| POST `/combos/{comboId}/desactivar` | `desactivarCombo` | — | Combo | 200,401,403,404,500,503 | provisional-internal |
| GET `/combos/{comboId}/disponibilidad` | `consultarDisponibilidadCombo` | — | DisponibilidadCombo | 200,401,403,404,500,503 | provisional-internal |

### MK-003 — Catalog

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/productos/skus/{sku}/contexto` | `obtenerContextoSku` | Pricing, Promotions | PricingCatalogContext | 200,401,403,404,503 | provisional-internal |
| GET `/productos` | `listarProductos` | Marketplace, Chatbot, Retail, Ventas/Postventa | PaginaProductosComercial | 200,400,401,403,422,429,500,503 | stable |
| POST `/productos` | `crearProducto` | — | ProductoCreateRequest | 201,400,401,403,409,422,500,503 | provisional-internal |
| GET `/productos/{productoId}` | `obtenerProducto` | Marketplace, Chatbot, Retail, Ventas/Postventa | ProductoDetalleComercial | 200,400,401,403,404,429,500,503 | stable |
| PATCH `/productos/{productoId}` | `actualizarProducto` | — | ProductoUpdateRequest, ProductoDetalle | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| POST `/productos/{productoId}/activar` | `activarProducto` | — | EstadoMutationRequest, ProductoDetalle | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| POST `/productos/{productoId}/desactivar` | `desactivarProducto` | — | EstadoMutationRequest, ProductoDetalle | 200,400,401,403,404,409,500,503 | provisional-internal |
| POST `/productos/{productoId}/reactivar` | `reactivarProducto` | — | EstadoMutationRequest, ProductoDetalle | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| GET `/productos/por-slug/{slug}` | `obtenerProductoPorSlug` | Marketplace, Chatbot, Retail | ProductoDetalleComercial | 200,401,403,404,429,500,503 | stable |
| GET `/productos/{productoId}/preparacion` | `obtenerPreparacionProducto` | — | ProductoPreparacion | 200,400,401,403,404,500,503 | provisional-internal |
| POST `/productos/{productoId}/preparacion/reintentar` | `reintentarPreparacionProducto` | — | ReintentarPreparacionProductoRequest | 202,400,401,403,404,409,500,503 | provisional-internal |
| POST `/productos/codigos-barras/resolver` | `resolverCodigoBarras` | Retail | ResolverCodigoBarrasRequest, ResolverCodigoBarrasResponse | 200,400,401,403,404,429,500,503 | stable |

### MK-004 — Catalog

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/productos/skus/{sku}/contexto` | `obtenerContextoSku` | Pricing, Promotions | PricingCatalogContext | 200,401,403,404,503 | provisional-internal |
| GET `/productos` | `listarProductos` | Marketplace, Chatbot, Retail, Ventas/Postventa | PaginaProductosComercial | 200,400,401,403,422,429,500,503 | stable |
| GET `/productos/{productoId}` | `obtenerProducto` | Marketplace, Chatbot, Retail, Ventas/Postventa | ProductoDetalleComercial | 200,400,401,403,404,429,500,503 | stable |
| GET `/productos/{productoId}/preparacion` | `obtenerPreparacionProducto` | — | ProductoPreparacion | 200,400,401,403,404,500,503 | provisional-internal |
| GET `/productos/{productoId}/variantes` | `listarVariantesProducto` | — | PaginaVariantes | 200,400,401,403,404,500,503 | provisional-internal |
| POST `/productos/{productoId}/variantes` | `crearVariante` | — | VarianteCreateRequest | 201,400,401,403,404,409,422,500,503 | provisional-internal |
| GET `/productos/{productoId}/variantes/{variantId}` | `obtenerVariante` | — | Variante | 200,400,401,403,404,500,503 | provisional-internal |
| PATCH `/productos/{productoId}/variantes/{variantId}` | `actualizarVariante` | — | VarianteUpdateRequest, Variante | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| POST `/productos/{productoId}/variantes/{variantId}/activar` | `activarVariante` | — | Variante | 200,401,403,404,409,422,500,503 | provisional-internal |
| POST `/productos/{productoId}/variantes/{variantId}/desactivar` | `desactivarVariante` | — | Variante | 200,401,403,404,409,500,503 | provisional-internal |
| POST `/productos/{productoId}/variantes/{variantId}/reactivar` | `reactivarVariante` | — | Variante | 200,401,403,404,409,422,500,503 | provisional-internal |
| POST `/productos/{productoId}/variantes/{variantId}/preparacion/reintentar` | `reintentarPreparacionVariante` | — | ReintentarPreparacionVarianteRequest | 202,400,401,403,404,409,500,503 | provisional-internal |
| POST `/productos/codigos-barras/resolver` | `resolverCodigoBarras` | Retail | ResolverCodigoBarrasRequest, ResolverCodigoBarrasResponse | 200,400,401,403,404,429,500,503 | stable |

### MK-005 — Promotions

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| POST `/cupones/validar` | `validarCupon` | — | ValidarCuponRequest, ValidarCuponResponse | 200,400,401,403,429,500,503 | stable |
| GET `/cupones` | `listarCupones` | — | PaginaCupones | 200,400,401,403,500,503 | provisional-internal |
| POST `/cupones` | `crearCupon` | — | CuponCreateRequest | 201,400,401,403,409,422,500,503 | provisional-internal |
| GET `/cupones/{cuponId}` | `obtenerCuponAdmin` | — | CuponAdmin | 200,401,403,404,500,503 | provisional-internal |
| PATCH `/cupones/{cuponId}` | `actualizarCupon` | — | CuponUpdateRequest, CuponAdmin | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| POST `/cupones/{cuponId}/activar` | `activarCupon` | — | CuponAdmin | 200,401,403,404,500,503 | provisional-internal |
| POST `/cupones/{cuponId}/desactivar` | `desactivarCupon` | — | CuponAdmin | 200,401,403,404,500,503 | provisional-internal |

### MK-006 — Promotions

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/promociones` | `listarPromociones` | — | PromocionResumen | 200,400,401,403,429,500,503 | stable |
| POST `/promociones` | `crearPromocion` | — | PromocionWriteRequest | 201,400,401,403,422,500,503 | provisional-internal |
| POST `/promociones/evaluar` | `evaluarPromociones` | — | EvaluacionPromocionesRequest, EvaluacionPromocionesResponse | 200,400,401,403,422,429,500,503 | stable |
| GET `/promociones/{promocionId}` | `obtenerPromocionAdmin` | — | PromocionAdmin | 200,401,403,404,500,503 | provisional-internal |
| PATCH `/promociones/{promocionId}` | `actualizarPromocion` | — | PromocionUpdateRequest, PromocionAdmin | 200,400,401,403,404,422,500,503 | provisional-internal |
| POST `/promociones/{promocionId}/activar` | `activarPromocion` | — | PromocionAdmin | 200,401,403,404,500,503 | provisional-internal |
| POST `/promociones/{promocionId}/desactivar` | `desactivarPromocion` | — | PromocionAdmin | 200,401,403,404,500,503 | provisional-internal |
| GET `/promociones/administracion` | `listarPromocionesAdmin` | — | PaginaPromocionesAdmin | 200,401,403,500,503 | provisional-internal |

### MK-007 — Promotions

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/recomendaciones` | `obtenerRecomendaciones` | Marketplace, Chatbot, Retail | RecomendacionesResponse | 200,400,401,403,429,500,503 | provisional |
| GET `/recomendaciones/reglas` | `listarReglasRecomendacion` | — | PaginaReglasRecomendacion | 200,400,401,403,500,503 | provisional-internal |
| POST `/recomendaciones/reglas` | `crearReglaRecomendacion` | — | ReglaRecomendacionWriteRequest | 201,400,401,403,422,500,503 | provisional-internal |
| GET `/recomendaciones/reglas/{reglaId}` | `obtenerReglaRecomendacion` | — | ReglaRecomendacionAdmin | 200,401,403,404,500,503 | provisional-internal |
| PATCH `/recomendaciones/reglas/{reglaId}` | `actualizarReglaRecomendacion` | — | ReglaRecomendacionUpdateRequest, ReglaRecomendacionAdmin | 200,400,401,403,404,422,500,503 | provisional-internal |
| POST `/recomendaciones/reglas/{reglaId}/activar` | `activarReglaRecomendacion` | — | ReglaRecomendacionAdmin | 200,401,403,404,500,503 | provisional-internal |
| POST `/recomendaciones/reglas/{reglaId}/desactivar` | `desactivarReglaRecomendacion` | — | ReglaRecomendacionAdmin | 200,401,403,404,500,503 | provisional-internal |

### MK-008 — Taxonomy

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/categorias` | `listarCategorias` | — | Categoria | 200,400,401,403,429,500,503 | stable |
| POST `/categorias` | `crearCategoria` | — | CategoriaWriteRequest | 201,400,401,403,409,422,500,503 | provisional-internal |
| POST `/seo/categorias/slug/resolver` | `resolverSlugCategoriaCreacion` | — | SlugCategoriaResolveRequest, SlugCategoriaResolveResponse | 200,400,401,403,500,503 | provisional-internal |
| GET `/categorias/arbol` | `obtenerArbolCategoriasAdmin` | — | CategoriaTreeNode | 200,401,403,500,503 | provisional-internal |
| GET `/categorias/{categoriaId}` | `obtenerCategoriaAdmin` | — | CategoriaAdmin | 200,401,403,404,500,503 | provisional-internal |
| PATCH `/categorias/{categoriaId}` | `actualizarCategoria` | — | CategoriaUpdateRequest, CategoriaAdmin | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| POST `/categorias/{categoriaId}/desactivar` | `solicitarDesactivacionCategoria` | — | — | 202,401,403,404,409,500,503 | provisional-internal |
| POST `/categorias/{categoriaId}/reactivar` | `reactivarCategoria` | — | CategoriaAdmin | 200,401,403,404,409,500,503 | provisional-internal |
| GET `/taxonomia/operaciones/{operationId}` | `obtenerOperacionMaestra` | — | OperacionMaestra | 200,401,403,404,500,503 | provisional-internal |
| GET `/categorias/administracion` | `listarCategoriasAdmin` | — | PaginaCategoriasAdmin | 200,401,403,500,503 | provisional-internal |

### MK-009 — Taxonomy

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/caracteristicas` | `listarCaracteristicas` | — | PaginaCaracteristicas | 200,400,401,403,500,503 | provisional-internal |
| POST `/caracteristicas` | `crearCaracteristica` | — | CaracteristicaCreateRequest | 201,400,401,403,422,500,503 | provisional-internal |
| GET `/caracteristicas/{caracteristicaId}` | `obtenerCaracteristica` | — | CaracteristicaAdmin | 200,401,403,404,500,503 | provisional-internal |
| PATCH `/caracteristicas/{caracteristicaId}` | `actualizarCaracteristica` | — | CaracteristicaUpdateRequest, CaracteristicaAdmin | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| GET `/caracteristicas/{caracteristicaId}/valores` | `listarValoresCaracteristica` | — | ValorCaracteristica | 200,401,403,404,500,503 | provisional-internal |
| POST `/caracteristicas/{caracteristicaId}/valores` | `crearValorCaracteristica` | — | ValorCaracteristicaWriteRequest | 201,400,401,403,404,422,500,503 | provisional-internal |
| PATCH `/caracteristicas/{caracteristicaId}/valores/{valorId}` | `actualizarValorCaracteristica` | — | ValorCaracteristicaWriteRequest, ValorCaracteristica | 200,401,403,404,409,500,503 | provisional-internal |
| POST `/caracteristicas/{caracteristicaId}/valores/{valorId}/desactivar` | `solicitarDesactivacionValorCaracteristica` | — | — | 202,401,403,404,409,500,503 | provisional-internal |
| POST `/caracteristicas/{caracteristicaId}/valores/{valorId}/reactivar` | `reactivarValorCaracteristica` | — | ValorCaracteristica | 200,401,403,404,500,503 | provisional-internal |
| POST `/caracteristicas/{caracteristicaId}/desactivar` | `desactivarCaracteristica` | — | CaracteristicaAdmin | 200,401,403,404,409,500,503 | provisional-internal |
| POST `/caracteristicas/{caracteristicaId}/reactivar` | `reactivarCaracteristica` | — | CaracteristicaAdmin | 200,401,403,404,409,500,503 | provisional-internal |
| GET `/taxonomia/operaciones/{operationId}` | `obtenerOperacionMaestra` | — | OperacionMaestra | 200,401,403,404,500,503 | provisional-internal |

### MK-010 — Taxonomy

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| POST `/caracteristicas/{caracteristicaId}/desactivar` | `desactivarCaracteristica` | — | CaracteristicaAdmin | 200,401,403,404,409,500,503 | provisional-internal |
| POST `/caracteristicas/{caracteristicaId}/reactivar` | `reactivarCaracteristica` | — | CaracteristicaAdmin | 200,401,403,404,409,500,503 | provisional-internal |
| GET `/tipos-producto` | `listarTiposProducto` | — | TipoProductoAdmin, PageMeta | 200,400,401,403,500,503 | provisional-internal |
| POST `/tipos-producto` | `crearTipoProducto` | — | TipoProductoCreateRequest | 201,400,401,403,500,503 | provisional-internal |
| GET `/tipos-producto/{tipoProductoId}` | `obtenerTipoProducto` | — | TipoProductoAdmin | 200,401,403,404,500,503 | provisional-internal |
| POST `/tipos-producto/{tipoProductoId}/desactivar` | `solicitarDesactivacionTipoProducto` | — | — | 202,401,403,404,409,500,503 | provisional-internal |
| POST `/tipos-producto/{tipoProductoId}/reactivar` | `reactivarTipoProducto` | — | TipoProductoAdmin | 200,401,403,404,409,500,503 | provisional-internal |
| GET `/tipos-producto/{tipoProductoId}/caracteristicas` | `obtenerEsquemaTipoProducto` | — | EsquemaTipoProducto | 200,401,403,404,500,503 | stable |
| POST `/tipos-producto/{tipoProductoId}/caracteristicas` | `asociarCaracteristicaTipoProducto` | — | AsociacionTipoCaracteristicaCreateRequest | 201,400,401,403,404,409,422,500,503 | provisional-internal |
| PATCH `/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}` | `actualizarAsociacionTipoCaracteristica` | — | AsociacionTipoCaracteristicaUpdateRequest, AsociacionTipoCaracteristica | 200,401,403,404,409,500,503 | provisional-internal |
| POST `/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}/desasociar` | `solicitarDesasociacionTipoCaracteristica` | — | — | 202,401,403,404,409,500,503 | provisional-internal |
| GET `/taxonomia/operaciones/{operationId}` | `obtenerOperacionMaestra` | — | OperacionMaestra | 200,401,403,404,500,503 | provisional-internal |

### MK-011 — Taxonomy

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/marcas` | `listarMarcas` | — | Marca | 200,400,401,403,429,500,503 | stable |
| POST `/marcas` | `crearMarca` | — | MarcaCreateMultipart | 201,400,401,403,409,413,422,500,503 | provisional-internal |
| GET `/marcas/{marcaId}` | `obtenerMarcaAdmin` | — | MarcaAdmin | 200,401,403,404,500,503 | provisional-internal |
| PATCH `/marcas/{marcaId}` | `actualizarMarca` | — | MarcaUpdateMultipart, MarcaAdmin | 200,400,401,403,404,409,413,422,500,503 | provisional-internal |
| POST `/marcas/{marcaId}/desactivar` | `solicitarDesactivacionMarca` | — | — | 202,401,403,404,409,500,503 | provisional-internal |
| POST `/marcas/{marcaId}/reactivar` | `reactivarMarca` | — | MarcaAdmin | 200,401,403,404,500,503 | provisional-internal |
| GET `/taxonomia/operaciones/{operationId}` | `obtenerOperacionMaestra` | — | OperacionMaestra | 200,401,403,404,500,503 | provisional-internal |
| GET `/marcas/administracion` | `listarMarcasAdmin` | — | PaginaMarcasAdmin | 200,401,403,500,503 | provisional-internal |

### MK-012 — Taxonomy

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| POST `/categorias` | `crearCategoria` | — | CategoriaWriteRequest | 201,400,401,403,409,422,500,503 | provisional-internal |
| POST `/seo/categorias/slug/resolver` | `resolverSlugCategoriaCreacion` | — | SlugCategoriaResolveRequest, SlugCategoriaResolveResponse | 200,400,401,403,500,503 | provisional-internal |
| GET `/seo/{slug}` | `obtenerSeoPorSlug` | — | SeoMetadata | 200,404,500 | stable |
| GET `/seo/resoluciones/{slugAnterior}` | `resolverSlugAnterior` | — | SlugResolution | 200,404,500 | stable |
| GET `/categorias/{categoriaId}/seo` | `obtenerSeoCategoriaAdmin` | — | SeoAdmin | 200,401,403,404,500,503 | provisional-internal |
| PATCH `/categorias/{categoriaId}/seo` | `actualizarSeoCategoria` | — | SeoUpdateRequest, SeoAdmin | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| GET `/categorias/{categoriaId}/seo/historial` | `listarHistorialSlugCategoria` | — | SlugHistoryEntry | 200,401,403,404,500,503 | provisional-internal |

### MK-013 — Pricing

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/productos/skus/{sku}/contexto` | `obtenerContextoSku` | Pricing, Promotions | PricingCatalogContext | 200,401,403,404,503 | provisional-internal |
| GET `/precios` | `consultarPrecios` | Catalog, Promotions, Combos | ConsultaPrecios | 200,400,401,403,500,503 | stable |
| GET `/precios/skus/{sku}` | `obtenerPrecioSku` | Catalog, Promotions, Combos | Precio | 200,400,401,403,404,429,500,503 | stable |
| PATCH `/precios/skus/{sku}` | `actualizarPrecioSku` | — | PrecioUpdateRequest, Precio | 200,400,401,403,404,409,422,500,503 | stable |
| GET `/precios/skus/{sku}/programaciones` | `listarProgramacionesPrecioSku` | — | PaginaProgramacionesPrecio | 200,401,403,404,500,503 | provisional-internal |
| POST `/precios/skus/{sku}/programaciones` | `programarPrecioSku` | — | ProgramacionPrecioRequest | 201,400,401,403,404,409,422,500,503 | provisional-internal |
| POST `/precios/importaciones/prevalidar` | `prevalidarImportacionPrecios` | — | PrevalidacionPrecio | 200,400,401,403,413,422,500,503 | excluded-h4 |
| POST `/precios/importaciones` | `crearImportacionPrecios` | — | — | 202,400,401,403,413,422,500,503 | excluded-h4 |
| GET `/precios/importaciones/{batchId}` | `obtenerImportacionPrecios` | — | EstadoImportacionPrecio | 200,401,403,404,500,503 | provisional-internal |
| GET `/precios/importaciones/{batchId}/reporte` | `descargarReporteImportacionPrecios` | — | — | 200,401,403,404,500,503 | provisional-internal |
| GET `/precios/productos/{productoId}` | `obtenerPrecioBaseProducto` | — | PrecioProducto | 200,401,403,404,500,503 | provisional-internal |
| PATCH `/precios/productos/{productoId}` | `actualizarPrecioBaseProducto` | — | PrecioUpdateRequest, PrecioProducto | 200,400,401,403,404,409,422,500,503 | provisional-internal |
| GET `/precios/productos/{productoId}/programaciones` | `listarProgramacionesPrecioProducto` | — | PaginaProgramacionesPrecioProducto | 200,401,403,404,500,503 | provisional-internal |
| POST `/precios/productos/{productoId}/programaciones` | `programarPrecioBaseProducto` | — | ProgramacionPrecioRequest | 201,400,401,403,404,409,422,500,503 | provisional-internal |

### MK-014 — Price Audit

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/auditoria-precios` | `listarAuditoriaPrecios` | — | PaginaAuditoriaPrecios | 200,400,401,403,500,503 | stable |
| GET `/auditoria-precios/{auditId}` | `obtenerAuditoriaPrecio` | — | RegistroAuditoriaPrecio | 200,401,403,404,500,503 | stable |
| POST `/auditoria-precios/exportaciones` | `crearExportacionAuditoriaPrecios` | — | ExportacionAuditoriaRequest | 202,400,401,403,422,500,503 | provisional-internal |
| GET `/auditoria-precios/exportaciones/{exportId}` | `obtenerExportacionAuditoriaPrecios` | — | TrabajoExportacion | 200,401,403,404,500,503 | provisional-internal |
| GET `/auditoria-precios/exportaciones/{exportId}/archivo` | `descargarExportacionAuditoriaPrecios` | — | — | 200,401,403,404,500,503 | provisional-internal |

### MK-015 — Inventory

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/inventario/disponibilidad` | `consultarDisponibilidad` | Ventas (M1), Postventa (M2) para consulta informativa de CAMBIO | ConsultaDisponibilidadResponse | 200,400,401,403,500,503 | stable |
| POST `/inventario/reservas` | `solicitarReserva` | — | CrearReservaRequest | 202,400,401,403,409,422,500,503 | provisional |
| POST `/inventario/reservas/{reservaId}/confirmar` | `confirmarReserva` | — | OperacionReservaRequest | 202,400,401,403,404,409,500,503 | provisional |
| POST `/inventario/reservas/{reservaId}/liberar` | `liberarReserva` | — | LiberarReservaRequest | 202,400,401,403,404,409,500,503 | provisional |
| GET `/inventario/umbrales` | `obtenerUmbralesInventario` | — | UmbralInventario | 200,401,403,500,503 | provisional-internal |
| PUT `/inventario/umbrales/global` | `actualizarUmbralGlobal` | — | UmbralGlobalRequest, UmbralInventario | 200,400,401,403,500,503 | provisional-internal |
| PUT `/inventario/umbrales/skus/{sku}` | `establecerUmbralSku` | — | UmbralSkuRequest, UmbralInventario | 200,400,401,403,404,500,503 | provisional-internal |
| DELETE `/inventario/umbrales/skus/{sku}` | `eliminarUmbralSku` | — | — | 204,401,403,404,500,503 | provisional-internal |
| GET `/inventario/administracion/saldos` | `listarSaldosFisicosAdministracion` | — | ListadoSaldosFisicosAdministrativos | 200,400,401,403,429,500,503 | IMPLEMENTADO_BACKEND_PENDIENTE_VERIFICACION |
| GET `/inventario/ubicaciones` | `listarUbicacionesInventario` | — | ListadoUbicacionesInventario | 200,400,401,403,429,500,503 | PENDIENTE_ENDPOINT_HTTP |
| GET `/inventario/disponibilidad/comercial` | `consultarDisponibilidadComercial` | Marketplace, Chatbot, Retail, Promotions, Combos | ConsultaDisponibilidadComercialResponse | 200,400,401,403,429,500,503 | provisional |

### MK-016 — Inventory

| Método y ruta | operationId | Consumidor | DTO/schema | HTTP | Estado documental/runtime |
|---|---|---|---|---|---|
| GET `/inventario/administracion/saldos` | `listarSaldosFisicosAdministracion` | — | ListadoSaldosFisicosAdministrativos | 200,400,401,403,429,500,503 | IMPLEMENTADO_BACKEND_PENDIENTE_VERIFICACION |
| GET `/inventario/alertas` | `listarAlertasOperativasInventario` | — | ListadoAlertasOperativas | 200,400,401,403,429,500,503 | PENDIENTE_ENDPOINT_HTTP |
| GET `/inventario/ubicaciones` | `listarUbicacionesInventario` | — | ListadoUbicacionesInventario | 200,400,401,403,429,500,503 | PENDIENTE_ENDPOINT_HTTP |
| GET `/inventario/dashboard` | `obtenerDashboardInventario` | — | DashboardInventario | 200,400,401,403,500,503 | provisional-internal |
