# Certificación Integral de las 158 Operaciones G6 H5 — 2026-11-27

El [inventario de seguimiento L2](artefactos/INVENTARIO_158_OPERACIONES_L2_2026-11-28.json) conserva las 158 filas y los resultados L1. APIM rev. 2 publica 149 operaciones. Dos lecturas de Pricing quedan pendientes de publicación. Las cinco rutas técnicas y dos sondas conservan su vía interna. Los rechazos públicos acreditan el control indicado en cada fila. El [corte original previo al CD](artefactos/INVENTARIO_158_OPERACIONES_PRE_CD.json) se conserva como referencia.

> **Nivel de evidencia:** `ISOLATED` (stack completo G6 + API Gateway + 8 microservicios + PostgreSQL 17 descartable + transporte aislado Service Bus H5 + emisor G7 de prueba). No equivale a corrida L2 sobre Azure/G7 real.

- **Fecha de ejecución UTC:** `2026-11-27T18:00:31.394Z`
- **Sujetos fijados (metadata):** Backend `18413ac459b24793f4f09ea07104d5281c0be3c7` | Frontend `ccfc21ba0e821f33c0debf09389879e55df0539b` | Docs `5f30802129ba4bbc0674dcc5878f10065f443118`
- **Contrato normativo:** OpenAPI `0.7.0-rc.3` (Docs `5f30802129ba4bbc0674dcc5878f10065f443118`)
- **Artefacto JSON fuente:** `artefactos/158_ENDPOINTS_CERTIFICATION_REPORT.json` (SHA-256: `2631cd8adb7c7d4195fbc182571e2a5e76e53e15dbc1c83346a88510e23f1933`) + `artefactos/158_ENDPOINTS_CERTIFICATION_REPORT.meta.json`
- **Resultado global:** **158/158 PASS, 0 FAIL, 0 BLOCKED** (histórico R2: 149 PASS / 9 FAIL)
- **Persistencia real en PostgreSQL 17:** `PERSISTENCE_PASS=73`, `NOT_APPLICABLE=85`, `NOT_VERIFIED=0`, `FAIL=0`
- **Contratos negativos (400/404/409/422):** `NEGATIVE_CONTRACT_PASS=151`, `NOT_APPLICABLE=7`, `FAIL=0`
- **Auth checks de ciclo de sesión (login/401/bloqueo/refresh rotate/reuse):** **6/6 PASS**
- **Estados terminales asíncronos:** `n01ConsumeStatus=COMPLETED`, `bulkTerminal=COMPLETED` (dominios aplicados: `CATALOGO, PRICING, INVENTARIO`)

## 1. Resumen por superficie / vigencia

| Superficie / Vigencia | Total | PASS | FAIL |
|---|---:|---:|---:|
| `VIGENTE` | 145 | 145 | 0 |
| `REGISTRADA_GATEWAY_PENDIENTE_CONCILIACION_OPENAPI` | 2 | 2 | 0 |
| `ENDPOINT_PRIVADO` | 11 | 11 | 0 |

## 2. Resumen por servicio

| Servicio | Total | PASS | FAIL |
|---|---:|---:|---:|
| `catalog-svc` | 26 | 26 | 0 |
| `taxonomy-svc` | 42 | 42 | 0 |
| `pricing-svc` | 15 | 15 | 0 |
| `promotions-svc` | 25 | 25 | 0 |
| `combos-svc` | 7 | 7 | 0 |
| `inventory-svc` | 24 | 24 | 0 |
| `price-audit-svc` | 7 | 7 | 0 |
| `bulk-svc` | 10 | 10 | 0 |
| `api-gateway` | 2 | 2 | 0 |

## 3. Verificación explícita de los 9 fallos históricos de R2

| # | Servicio | `operationId` | Vigencia | HTTP | Seguridad (401/403) | Persistencia PG17 | Async Terminal | Estado |
|---:|---|---|---|---:|---|---|---|---|
| 106 | `bulk-svc` | `crearImportacionGeneralProductos` | `VIGENTE` | 202 | ROUTE_SECURITY_PASS (true/true) | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 109 | `bulk-svc` | `reanudarImportacionGeneral` | `VIGENTE` | 202 | ROUTE_SECURITY_PASS (true/true) | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 114 | `inventory-svc` | `actualizarUmbralGlobal` | `VIGENTE` | 200 | ROUTE_SECURITY_PASS (true/true) | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 128 | `inventory-svc` | `conciliarVentaOffline` | `VIGENTE` | 200 | ROUTE_SECURITY_PASS (true/true) | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 148 | `promotions-svc` | `admitirConsumoCuponH5` | `ENDPOINT_PRIVADO` | 202 | ROUTE_SECURITY_PASS (true/true) | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 149 | `promotions-svc` | `admitirRestauracionCuponH5` | `ENDPOINT_PRIVADO` | 202 | ROUTE_SECURITY_PASS (true/true) | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 152 | `catalog-svc` | `obtenerContextoSku` | `ENDPOINT_PRIVADO` | 200 | ROUTE_SECURITY_PASS (true/true) | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 153 | `catalog-svc` | `obtenerContextosSkuLote` | `ENDPOINT_PRIVADO` | 200 | ROUTE_SECURITY_PASS (true/true) | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 158 | `api-gateway` | `gatewayReadiness` | `ENDPOINT_PRIVADO` | 200 | ROUTE_SECURITY_PASS (true/true) | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |

- **Rutas internas de Catalog (`#152 obtenerContextoSku` y `#153 obtenerContextosSkuLote`):** validadas en la superficie interna de `catalog-svc` con identidad de servicio autorizada (`200 OK`, `401` sin token, `403` con cliente no autorizado) **sin exponerlas públicamente**; adicionalmente, la sonda read-only sobre APIM live (`https://apim-g6-productos-chile.azure-api.net/api/v1/productos/skus/TEST-SKU/contexto`) confirmó rechazo **`404`** en la superficie pública.
- **Gateway readiness (`#158 /health/ready`):** respondió **`200 OK`** en el candidato integrado (el 503 histórico de R2 correspondía a dependencias caídas/no listas durante la corrida previa).

## 4. Detalle completo de las 158 operaciones

| # | Servicio | Vigencia | `operationId` | Método | Ruta | HTTP | Seguridad | Negativo | Funcional | Persistencia | Async | Estado |
|---:|---|---|---|---|---|---:|---|---|---|---|---|---|
| 1 | `catalog-svc` | `VIGENTE` | `listarProductos` | GET | `/api/v1/productos` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 2 | `catalog-svc` | `VIGENTE` | `crearProducto` | POST | `/api/v1/productos` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 3 | `catalog-svc` | `VIGENTE` | `obtenerProducto` | GET | `/api/v1/productos/{productoId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 4 | `catalog-svc` | `VIGENTE` | `actualizarProducto` | PATCH | `/api/v1/productos/{productoId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 5 | `taxonomy-svc` | `VIGENTE` | `listarCategorias` | GET | `/api/v1/categorias` | 200 | ROUTE_SECURITY_PASS | NOT_APPLICABLE | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 6 | `taxonomy-svc` | `VIGENTE` | `crearCategoria` | POST | `/api/v1/categorias` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 7 | `taxonomy-svc` | `VIGENTE` | `listarMarcas` | GET | `/api/v1/marcas` | 200 | ROUTE_SECURITY_PASS | NOT_APPLICABLE | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 8 | `taxonomy-svc` | `VIGENTE` | `crearMarca` | POST | `/api/v1/marcas` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 9 | `pricing-svc` | `VIGENTE` | `consultarPrecios` | GET | `/api/v1/precios` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 10 | `pricing-svc` | `VIGENTE` | `obtenerPrecioSku` | GET | `/api/v1/precios/skus/{sku}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 11 | `pricing-svc` | `VIGENTE` | `actualizarPrecioSku` | PATCH | `/api/v1/precios/skus/{sku}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 12 | `promotions-svc` | `VIGENTE` | `listarPromociones` | GET | `/api/v1/promociones` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 13 | `promotions-svc` | `VIGENTE` | `crearPromocion` | POST | `/api/v1/promociones` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 14 | `promotions-svc` | `VIGENTE` | `evaluarPromociones` | POST | `/api/v1/promociones/evaluar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 15 | `promotions-svc` | `VIGENTE` | `validarCupon` | POST | `/api/v1/cupones/validar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 16 | `promotions-svc` | `VIGENTE` | `obtenerRecomendaciones` | GET | `/api/v1/recomendaciones` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 17 | `combos-svc` | `VIGENTE` | `obtenerCombo` | GET | `/api/v1/combos/{comboId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 18 | `combos-svc` | `VIGENTE` | `actualizarCombo` | PATCH | `/api/v1/combos/{comboId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 19 | `inventory-svc` | `VIGENTE` | `consultarDisponibilidad` | GET | `/api/v1/inventario/disponibilidad` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 20 | `inventory-svc` | `VIGENTE` | `solicitarReserva` | POST | `/api/v1/inventario/reservas` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 21 | `inventory-svc` | `VIGENTE` | `confirmarReserva` | POST | `/api/v1/inventario/reservas/{reservaId}/confirmar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 22 | `inventory-svc` | `VIGENTE` | `liberarReserva` | POST | `/api/v1/inventario/reservas/{reservaId}/liberar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 23 | `catalog-svc` | `VIGENTE` | `consultarDatosFisicos` | POST | `/api/v1/productos/datos-fisicos/consulta` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 24 | `taxonomy-svc` | `VIGENTE` | `resolverSlugCategoriaCreacion` | POST | `/api/v1/seo/categorias/slug/resolver` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 25 | `taxonomy-svc` | `VIGENTE` | `obtenerSeoPorSlug` | GET | `/api/v1/seo/{slug}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 26 | `taxonomy-svc` | `VIGENTE` | `resolverSlugAnterior` | GET | `/api/v1/seo/resoluciones/{slugAnterior}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 27 | `catalog-svc` | `VIGENTE` | `activarProducto` | POST | `/api/v1/productos/{productoId}/activar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 28 | `catalog-svc` | `VIGENTE` | `desactivarProducto` | POST | `/api/v1/productos/{productoId}/desactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 29 | `catalog-svc` | `VIGENTE` | `reactivarProducto` | POST | `/api/v1/productos/{productoId}/reactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 30 | `catalog-svc` | `VIGENTE` | `obtenerProductoPorSlug` | GET | `/api/v1/productos/por-slug/{slug}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 31 | `catalog-svc` | `VIGENTE` | `obtenerPreparacionProducto` | GET | `/api/v1/productos/{productoId}/preparacion` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 32 | `catalog-svc` | `VIGENTE` | `reintentarPreparacionProducto` | POST | `/api/v1/productos/{productoId}/preparacion/reintentar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 33 | `catalog-svc` | `VIGENTE` | `listarVariantesProducto` | GET | `/api/v1/productos/{productoId}/variantes` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 34 | `catalog-svc` | `VIGENTE` | `crearVariante` | POST | `/api/v1/productos/{productoId}/variantes` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 35 | `catalog-svc` | `VIGENTE` | `obtenerVariante` | GET | `/api/v1/productos/{productoId}/variantes/{variantId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 36 | `catalog-svc` | `VIGENTE` | `actualizarVariante` | PATCH | `/api/v1/productos/{productoId}/variantes/{variantId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 37 | `catalog-svc` | `VIGENTE` | `activarVariante` | POST | `/api/v1/productos/{productoId}/variantes/{variantId}/activar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 38 | `catalog-svc` | `VIGENTE` | `desactivarVariante` | POST | `/api/v1/productos/{productoId}/variantes/{variantId}/desactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 39 | `catalog-svc` | `VIGENTE` | `reactivarVariante` | POST | `/api/v1/productos/{productoId}/variantes/{variantId}/reactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 40 | `catalog-svc` | `VIGENTE` | `reintentarPreparacionVariante` | POST | `/api/v1/productos/{productoId}/variantes/{variantId}/preparacion/reintentar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 41 | `combos-svc` | `VIGENTE` | `listarCombosAdmin` | GET | `/api/v1/combos` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 42 | `combos-svc` | `VIGENTE` | `crearCombo` | POST | `/api/v1/combos` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 43 | `combos-svc` | `VIGENTE` | `desactivarCombo` | POST | `/api/v1/combos/{comboId}/desactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 44 | `combos-svc` | `VIGENTE` | `consultarDisponibilidadCombo` | GET | `/api/v1/combos/{comboId}/disponibilidad` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 45 | `promotions-svc` | `VIGENTE` | `listarCupones` | GET | `/api/v1/cupones` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 46 | `promotions-svc` | `VIGENTE` | `crearCupon` | POST | `/api/v1/cupones` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 47 | `promotions-svc` | `VIGENTE` | `obtenerCuponAdmin` | GET | `/api/v1/cupones/{cuponId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 48 | `promotions-svc` | `VIGENTE` | `actualizarCupon` | PATCH | `/api/v1/cupones/{cuponId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 49 | `promotions-svc` | `VIGENTE` | `activarCupon` | POST | `/api/v1/cupones/{cuponId}/activar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 50 | `promotions-svc` | `VIGENTE` | `desactivarCupon` | POST | `/api/v1/cupones/{cuponId}/desactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 51 | `promotions-svc` | `VIGENTE` | `obtenerPromocionAdmin` | GET | `/api/v1/promociones/{promocionId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 52 | `promotions-svc` | `VIGENTE` | `actualizarPromocion` | PATCH | `/api/v1/promociones/{promocionId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 53 | `promotions-svc` | `VIGENTE` | `activarPromocion` | POST | `/api/v1/promociones/{promocionId}/activar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 54 | `promotions-svc` | `VIGENTE` | `desactivarPromocion` | POST | `/api/v1/promociones/{promocionId}/desactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 55 | `promotions-svc` | `VIGENTE` | `listarReglasRecomendacion` | GET | `/api/v1/recomendaciones/reglas` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 56 | `promotions-svc` | `VIGENTE` | `crearReglaRecomendacion` | POST | `/api/v1/recomendaciones/reglas` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 57 | `promotions-svc` | `VIGENTE` | `obtenerReglaRecomendacion` | GET | `/api/v1/recomendaciones/reglas/{reglaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 58 | `promotions-svc` | `VIGENTE` | `actualizarReglaRecomendacion` | PATCH | `/api/v1/recomendaciones/reglas/{reglaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 59 | `promotions-svc` | `VIGENTE` | `activarReglaRecomendacion` | POST | `/api/v1/recomendaciones/reglas/{reglaId}/activar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 60 | `promotions-svc` | `VIGENTE` | `desactivarReglaRecomendacion` | POST | `/api/v1/recomendaciones/reglas/{reglaId}/desactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 61 | `taxonomy-svc` | `VIGENTE` | `obtenerArbolCategoriasAdmin` | GET | `/api/v1/categorias/arbol` | 200 | ROUTE_SECURITY_PASS | NOT_APPLICABLE | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 62 | `taxonomy-svc` | `VIGENTE` | `obtenerCategoriaAdmin` | GET | `/api/v1/categorias/{categoriaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 63 | `taxonomy-svc` | `VIGENTE` | `actualizarCategoria` | PATCH | `/api/v1/categorias/{categoriaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 64 | `taxonomy-svc` | `VIGENTE` | `solicitarDesactivacionCategoria` | POST | `/api/v1/categorias/{categoriaId}/desactivar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 65 | `taxonomy-svc` | `VIGENTE` | `reactivarCategoria` | POST | `/api/v1/categorias/{categoriaId}/reactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 66 | `taxonomy-svc` | `VIGENTE` | `listarCaracteristicas` | GET | `/api/v1/caracteristicas` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 67 | `taxonomy-svc` | `VIGENTE` | `crearCaracteristica` | POST | `/api/v1/caracteristicas` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 68 | `taxonomy-svc` | `VIGENTE` | `obtenerCaracteristica` | GET | `/api/v1/caracteristicas/{caracteristicaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 69 | `taxonomy-svc` | `VIGENTE` | `actualizarCaracteristica` | PATCH | `/api/v1/caracteristicas/{caracteristicaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 70 | `taxonomy-svc` | `VIGENTE` | `listarValoresCaracteristica` | GET | `/api/v1/caracteristicas/{caracteristicaId}/valores` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 71 | `taxonomy-svc` | `VIGENTE` | `crearValorCaracteristica` | POST | `/api/v1/caracteristicas/{caracteristicaId}/valores` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 72 | `taxonomy-svc` | `VIGENTE` | `actualizarValorCaracteristica` | PATCH | `/api/v1/caracteristicas/{caracteristicaId}/valores/{valorId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 73 | `taxonomy-svc` | `VIGENTE` | `solicitarDesactivacionValorCaracteristica` | POST | `/api/v1/caracteristicas/{caracteristicaId}/valores/{valorId}/desactivar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 74 | `taxonomy-svc` | `VIGENTE` | `reactivarValorCaracteristica` | POST | `/api/v1/caracteristicas/{caracteristicaId}/valores/{valorId}/reactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 75 | `taxonomy-svc` | `VIGENTE` | `desactivarCaracteristica` | POST | `/api/v1/caracteristicas/{caracteristicaId}/desactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 76 | `taxonomy-svc` | `VIGENTE` | `reactivarCaracteristica` | POST | `/api/v1/caracteristicas/{caracteristicaId}/reactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 77 | `taxonomy-svc` | `VIGENTE` | `listarTiposProducto` | GET | `/api/v1/tipos-producto` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 78 | `taxonomy-svc` | `VIGENTE` | `crearTipoProducto` | POST | `/api/v1/tipos-producto` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 79 | `taxonomy-svc` | `VIGENTE` | `obtenerTipoProducto` | GET | `/api/v1/tipos-producto/{tipoProductoId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 80 | `taxonomy-svc` | `VIGENTE` | `solicitarDesactivacionTipoProducto` | POST | `/api/v1/tipos-producto/{tipoProductoId}/desactivar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 81 | `taxonomy-svc` | `VIGENTE` | `reactivarTipoProducto` | POST | `/api/v1/tipos-producto/{tipoProductoId}/reactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 82 | `taxonomy-svc` | `VIGENTE` | `obtenerEsquemaTipoProducto` | GET | `/api/v1/tipos-producto/{tipoProductoId}/caracteristicas` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 83 | `taxonomy-svc` | `VIGENTE` | `asociarCaracteristicaTipoProducto` | POST | `/api/v1/tipos-producto/{tipoProductoId}/caracteristicas` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 84 | `taxonomy-svc` | `VIGENTE` | `actualizarAsociacionTipoCaracteristica` | PATCH | `/api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 85 | `taxonomy-svc` | `VIGENTE` | `solicitarDesasociacionTipoCaracteristica` | POST | `/api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}/desasociar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 86 | `taxonomy-svc` | `VIGENTE` | `obtenerMarcaAdmin` | GET | `/api/v1/marcas/{marcaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 87 | `taxonomy-svc` | `VIGENTE` | `actualizarMarca` | PATCH | `/api/v1/marcas/{marcaId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 88 | `taxonomy-svc` | `VIGENTE` | `solicitarDesactivacionMarca` | POST | `/api/v1/marcas/{marcaId}/desactivar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 89 | `taxonomy-svc` | `VIGENTE` | `reactivarMarca` | POST | `/api/v1/marcas/{marcaId}/reactivar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 90 | `taxonomy-svc` | `VIGENTE` | `obtenerOperacionMaestra` | GET | `/api/v1/taxonomia/operaciones/{operationId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 91 | `taxonomy-svc` | `VIGENTE` | `obtenerSeoCategoriaAdmin` | GET | `/api/v1/categorias/{categoriaId}/seo` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 92 | `taxonomy-svc` | `VIGENTE` | `actualizarSeoCategoria` | PATCH | `/api/v1/categorias/{categoriaId}/seo` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 93 | `taxonomy-svc` | `VIGENTE` | `listarHistorialSlugCategoria` | GET | `/api/v1/categorias/{categoriaId}/seo/historial` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 94 | `pricing-svc` | `VIGENTE` | `listarProgramacionesPrecioSku` | GET | `/api/v1/precios/skus/{sku}/programaciones` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 95 | `pricing-svc` | `VIGENTE` | `programarPrecioSku` | POST | `/api/v1/precios/skus/{sku}/programaciones` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 96 | `pricing-svc` | `VIGENTE` | `prevalidarImportacionPrecios` | POST | `/api/v1/precios/importaciones/prevalidar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 97 | `pricing-svc` | `VIGENTE` | `crearImportacionPrecios` | POST | `/api/v1/precios/importaciones` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 98 | `pricing-svc` | `VIGENTE` | `obtenerImportacionPrecios` | GET | `/api/v1/precios/importaciones/{batchId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 99 | `pricing-svc` | `VIGENTE` | `descargarReporteImportacionPrecios` | GET | `/api/v1/precios/importaciones/{batchId}/reporte` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 100 | `price-audit-svc` | `VIGENTE` | `listarAuditoriaPrecios` | GET | `/api/v1/auditoria-precios` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 101 | `price-audit-svc` | `VIGENTE` | `obtenerAuditoriaPrecio` | GET | `/api/v1/auditoria-precios/{auditId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 102 | `price-audit-svc` | `VIGENTE` | `crearExportacionAuditoriaPrecios` | POST | `/api/v1/auditoria-precios/exportaciones` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 103 | `price-audit-svc` | `VIGENTE` | `obtenerExportacionAuditoriaPrecios` | GET | `/api/v1/auditoria-precios/exportaciones/{exportId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 104 | `price-audit-svc` | `VIGENTE` | `descargarExportacionAuditoriaPrecios` | GET | `/api/v1/auditoria-precios/exportaciones/{exportId}/archivo` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 105 | `bulk-svc` | `VIGENTE` | `descargarPlantillaProductos` | GET | `/api/v1/carga-masiva/productos/plantilla` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 106 | `bulk-svc` | `VIGENTE` | `crearImportacionGeneralProductos` | POST | `/api/v1/carga-masiva/productos/importaciones` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 107 | `bulk-svc` | `VIGENTE` | `obtenerImportacionGeneralProductos` | GET | `/api/v1/carga-masiva/productos/importaciones/{batchId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 108 | `bulk-svc` | `VIGENTE` | `descargarReporteImportacionGeneral` | GET | `/api/v1/carga-masiva/productos/importaciones/{batchId}/reporte` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 109 | `bulk-svc` | `VIGENTE` | `reanudarImportacionGeneral` | POST | `/api/v1/carga-masiva/productos/importaciones/{batchId}/reanudar` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 110 | `bulk-svc` | `VIGENTE` | `crearExportacionGeneralProductos` | POST | `/api/v1/carga-masiva/productos/exportaciones` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 111 | `bulk-svc` | `VIGENTE` | `obtenerExportacionGeneralProductos` | GET | `/api/v1/carga-masiva/productos/exportaciones/{exportId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 112 | `bulk-svc` | `VIGENTE` | `descargarExportacionGeneralProductos` | GET | `/api/v1/carga-masiva/productos/exportaciones/{exportId}/archivo` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 113 | `inventory-svc` | `VIGENTE` | `obtenerUmbralesInventario` | GET | `/api/v1/inventario/umbrales` | 200 | ROUTE_SECURITY_PASS | NOT_APPLICABLE | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 114 | `inventory-svc` | `VIGENTE` | `actualizarUmbralGlobal` | PUT | `/api/v1/inventario/umbrales/global` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 115 | `inventory-svc` | `VIGENTE` | `establecerUmbralSku` | PUT | `/api/v1/inventario/umbrales/skus/{sku}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 116 | `inventory-svc` | `VIGENTE` | `eliminarUmbralSku` | DELETE | `/api/v1/inventario/umbrales/skus/{sku}` | 204 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 117 | `inventory-svc` | `VIGENTE` | `obtenerDashboardInventario` | GET | `/api/v1/inventario/dashboard` | 200 | ROUTE_SECURITY_PASS | NOT_APPLICABLE | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 118 | `taxonomy-svc` | `VIGENTE` | `listarCategoriasAdmin` | GET | `/api/v1/categorias/administracion` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 119 | `taxonomy-svc` | `VIGENTE` | `listarMarcasAdmin` | GET | `/api/v1/marcas/administracion` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 120 | `promotions-svc` | `VIGENTE` | `listarPromocionesAdmin` | GET | `/api/v1/promociones/administracion` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 121 | `pricing-svc` | `VIGENTE` | `obtenerPrecioBaseProducto` | GET | `/api/v1/precios/productos/{productoId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 122 | `pricing-svc` | `VIGENTE` | `actualizarPrecioBaseProducto` | PATCH | `/api/v1/precios/productos/{productoId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 123 | `pricing-svc` | `VIGENTE` | `listarProgramacionesPrecioProducto` | GET | `/api/v1/precios/productos/{productoId}/programaciones` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 124 | `pricing-svc` | `VIGENTE` | `programarPrecioBaseProducto` | POST | `/api/v1/precios/productos/{productoId}/programaciones` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 125 | `inventory-svc` | `VIGENTE` | `reportarIncidenciaInventario` | POST | `/api/v1/inventario/incidencias` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 126 | `inventory-svc` | `VIGENTE` | `resolverIncidenciaInventario` | POST | `/api/v1/inventario/incidencias/{incidenciaId}/resolver` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 127 | `inventory-svc` | `VIGENTE` | `reintegrarInventario` | POST | `/api/v1/inventario/reintegros` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 128 | `inventory-svc` | `VIGENTE` | `conciliarVentaOffline` | POST | `/api/v1/inventario/conciliaciones-offline` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 129 | `inventory-svc` | `VIGENTE` | `listarTrasladosInventario` | GET | `/api/v1/inventario/traslados` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 130 | `inventory-svc` | `VIGENTE` | `obtenerTrasladoInventario` | GET | `/api/v1/inventario/traslados/{trasladoId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 131 | `inventory-svc` | `VIGENTE` | `registrarRecepcionTrasladoInventario` | POST | `/api/v1/inventario/traslados/{trasladoId}/recepciones` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 132 | `catalog-svc` | `VIGENTE` | `resolverCodigoBarras` | POST | `/api/v1/productos/codigos-barras/resolver` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 133 | `inventory-svc` | `VIGENTE` | `consultarDisponibilidadComercial` | GET | `/api/v1/inventario/disponibilidad/comercial` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 134 | `inventory-svc` | `VIGENTE` | `consultarOperacionInventario` | GET | `/api/v1/inventario/operaciones/{operationId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 135 | `inventory-svc` | `VIGENTE` | `verificarCantidadComercial` | POST | `/api/v1/inventario/disponibilidad/comercial/verificar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 136 | `catalog-svc` | `VIGENTE` | `listarProductosAdministracion` | GET | `/api/v1/productos/administracion` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 137 | `catalog-svc` | `VIGENTE` | `obtenerProductoAdministracion` | GET | `/api/v1/productos/administracion/{productoId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 138 | `pricing-svc` | `REGISTRADA_GATEWAY_PENDIENTE_CONCILIACION_OPENAPI` | `obtenerDefinicionPrecioProductoAdministracion` | GET | `/api/v1/precios/administracion/productos/{productoId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 139 | `pricing-svc` | `REGISTRADA_GATEWAY_PENDIENTE_CONCILIACION_OPENAPI` | `obtenerDefinicionPrecioSkuAdministracion` | GET | `/api/v1/precios/administracion/skus/{sku}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 140 | `inventory-svc` | `VIGENTE` | `listarSaldosFisicosAdministracion` | GET | `/api/v1/inventario/administracion/saldos` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 141 | `price-audit-svc` | `VIGENTE` | `listarAuditoriaPreciosAdministracion` | GET | `/api/v1/auditoria-precios/administracion` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 142 | `price-audit-svc` | `VIGENTE` | `obtenerAuditoriaPrecioAdministracion` | GET | `/api/v1/auditoria-precios/administracion/{auditId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 143 | `combos-svc` | `VIGENTE` | `crearComboAdministracion` | POST | `/api/v1/combos/administracion` | 201 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | NOT_APPLICABLE | **PASS** |
| 144 | `catalog-svc` | `VIGENTE` | `resolverSkusAdministracion` | POST | `/api/v1/productos/administracion/skus/resolver` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 145 | `bulk-svc` | `VIGENTE` | `conciliarImportacionGeneralPorCorrelacion` | GET | `/api/v1/carga-masiva/productos/importaciones/por-correlacion/{correlationId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 146 | `inventory-svc` | `VIGENTE` | `listarAlertasOperativasInventario` | GET | `/api/v1/inventario/alertas` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 147 | `inventory-svc` | `VIGENTE` | `listarUbicacionesInventario` | GET | `/api/v1/inventario/ubicaciones` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 148 | `promotions-svc` | `ENDPOINT_PRIVADO` | `admitirConsumoCuponH5` | POST | `/api/v1/cupones/consumos` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 149 | `promotions-svc` | `ENDPOINT_PRIVADO` | `admitirRestauracionCuponH5` | POST | `/api/v1/cupones/restauraciones` | 202 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | PERSISTENCE_PASS | ASYNC_TERMINAL_PASS | **PASS** |
| 150 | `promotions-svc` | `ENDPOINT_PRIVADO` | `obtenerOperacionCuponH5` | GET | `/api/v1/cupones/operaciones/{operationId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 151 | `inventory-svc` | `ENDPOINT_PRIVADO` | `obtenerEstadoReservaH5` | GET | `/api/v1/inventario/reservas/{reservaId}/estado` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 152 | `catalog-svc` | `ENDPOINT_PRIVADO` | `obtenerContextoSku` | GET | `/productos/skus/{sku}/contexto` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 153 | `catalog-svc` | `ENDPOINT_PRIVADO` | `obtenerContextosSkuLote` | POST | `/productos/skus/contexto/lote` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 154 | `catalog-svc` | `ENDPOINT_PRIVADO` | `filtrarSkusVendiblesInterno` | POST | `/interno/productos/skus/filtrar` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 155 | `inventory-svc` | `ENDPOINT_PRIVADO` | `obtenerEvidenciaReservaCuponInterno` | GET | `/interno/inventario/reservas/{reservaId}/evidencia-cupon` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 156 | `bulk-svc` | `ENDPOINT_PRIVADO` | `obtenerContenidoCargaMasivaInternoH5` | GET | `/interno/carga-masiva/contenidos/{contentId}` | 200 | ROUTE_SECURITY_PASS | NEGATIVE_CONTRACT_PASS | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 157 | `api-gateway` | `ENDPOINT_PRIVADO` | `gatewayHealth` | GET | `/health` | 200 | ROUTE_SECURITY_PASS | NOT_APPLICABLE | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |
| 158 | `api-gateway` | `ENDPOINT_PRIVADO` | `gatewayReadiness` | GET | `/health/ready` | 200 | ROUTE_SECURITY_PASS | NOT_APPLICABLE | FUNCTIONAL_PASS | NOT_APPLICABLE | NOT_APPLICABLE | **PASS** |

## Registro de acceso y evidencia L2

El [inventario pre-CD de 158 operaciones](artefactos/INVENTARIO_158_OPERACIONES_PRE_CD.json) conserva la cobertura L1 por ruta y reserva una entrada para revisión, digest, HTTP real, nivel y evidencia de cada operación. La vía prevista es APIM para 145 vigentes, 4 G5 y 2 Pricing condicionadas al contrato conciliado. Otras 5 operaciones usan la red interna G6 y 2 son sondas privadas de Gateway. Las 158 entradas L2 permanecen NOT_RUN hasta una ejecución real en su vía autorizada.
