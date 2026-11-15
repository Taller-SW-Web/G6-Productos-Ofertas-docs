# Auditoría final de optimizaciones G6 — 2026-11-14

## Alcance y estado

Esta evidencia sigue los Draft PR existentes: Backend #230 (`perf/optimizacion-integral-g6`, corrección en `59775363fc2c5ca8499b775f9872cb794097c2be`), Frontend #82 (`codex/perf-optimizacion-integral-g6`, corrección en `46cd9f0fafcd65b821148e4625e436ad8560c7e3`) y Docs #120 (`docs/optimizaciones-integral-g6-contratos`). No crea ramas o PR sustitutos.

- Backend #230 CI completa: [run 43658275955](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43658275955), PASS. También pasaron [A1/A2](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43658275917) y las suites aisladas [Bulk/PostgreSQL/RabbitMQ](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43658275944). El job de benchmark Pricing fue omitido por ser opt-in; se conserva el benchmark aprobado anterior, no se extrapola.
- Frontend #82 CI para `46cd9f0`: [run 43658438259](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/43658438259), PASS; cuatro shards E2E, build API, suites unitarias, typecheck y lint pasaron. El run incompleto de SHA anterior fue cancelado y no se usa como evidencia.
- Docs #120 CI del commit `9c56d9c`: [run 43658916417](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/runs/43658916417), PASS. La presente actualización requiere un nuevo run documental.

La solicitud exige medidas de rendimiento con servicios reales, carga concurrente sostenida, percentiles p50/p95/p99, solicitudes/bytes, consultas/planes y conexiones. No se considera que una prueba funcional de integración equivalga a un benchmark.

## Seguridad y contratos contrastados

La revisión del provider en Backend #230 y del registry de Gateway identifica:

- La resolución administrativa usa `POST /api/v1/productos/administracion/skus/resolver`, bearer humano y rol `GESTOR_COMERCIAL` en el controller de Catálogo y en Gateway.
- El contexto SKU privado de Pricing usa `POST /api/v1/productos/skus/contexto/lote`; no aparece registrado en las rutas Gateway. La documentación contractual conserva esta frontera privada.
- `POST /api/v1/combos/administracion` exige el rol comercial y `Idempotency-Key`. La persistencia mantiene recibo por actor/clave, fingerprint y rechazo de clave reutilizada con intención distinta. La ruta legacy continúa disponible.
- Auditoría mantiene rutas administrativas separadas con autorización humana. La verificación de provider/Gateway corresponde a CI del SHA final que se indicará abajo.

El harness aislado de Gateway ejerce la ruta administrativa con JWT humano firmado y confirma: `GESTOR_COMERCIAL` reenvía la petición; un rol sin autorización recibe 403 sin invocar upstream; el batch privado recibe 404 sin upstream. Las suites locales reportadas para Backend probaron 477/477 casos de routing, 68/68 casos HTTP de Catálogo y 343/343 casos unitarios de Pricing. La prueba de composición Frontend por separado confirma que Combos construye las consultas con bearer humano y usa el adaptador administrativo, y rechaza el 403 del Gateway. No existe en estos checkouts un runner único que conecte el adapter de UI al proceso real del Gateway; el aislamiento de capas y la limitación se registran explícitamente en la sección de Frontend.

El emisor JWT de prueba acredita comportamiento de autorización en el entorno de prueba, no que G7 haya registrado o concedido grants reales. No se encontró evidencia de grants efectivos en los artefactos inspeccionados. Esa concesión y cualquier cambio de homologación externa siguen siendo dependencias de sus owners; G6 puede cerrar su wiring, guards, tests y compatibilidad interna.

## Cobertura de rendimiento por servicio

| Servicio | Evidencia de performance | Cobertura que falta para declarar medido |
|---|---|---|
| Catálogo | Benchmark Pricing previo usa fixture HTTP de Catálogo, no el provider real. | Carga del provider, SQL/EXPLAIN, buffers, pool, bytes y p50/p95/p99 bajo concurrencia sostenida. |
| Pricing | [Benchmark sintético de Pricing](RESULTADOS_BENCHMARK_PRICING_G6_2026-11-14.md): PostgreSQL 16 desechable, 100 muestras por caso, fixture de Catálogo; p50/p95/p99, consultas y dos planes EXPLAIN. | Throughput sostenido y bytes; conexiones de pool ocupadas; consultas Gateway/Catálogo reales y tamaño representativo de datos. No extrapolar. |
| Combos | Sin benchmark de carga identificado en la evidencia de este PR antes del cierre. | Percentiles, throughput/concurrencia, HTTP/bytes, SQL/buffers/EXPLAIN, pool, timeout/recuperación. |
| Inventario | Las suites aisladas prueban integración funcional con PostgreSQL/RabbitMQ, no rendimiento. | Medidas de carga con percentiles, throughput, consultas/planes, pool y recuperación. |
| Promociones | Las suites aisladas prueban persistencia/contrato, no rendimiento. | Medidas de carga con percentiles, throughput, consultas/planes, pool y recuperación. |
| Auditoría de precios | El benchmark Pricing no incluye la lectura del servicio Price Audit como endpoint de carga. | Medidas de endpoint, SQL/planes/buffers, pool, throughput y recuperación. |
| Bulk | Sin benchmark de carga identificado en la evidencia de este PR antes del cierre. | Medidas de admisión/proceso/exportación, throughput, bytes, SQL/planes, pool y recuperación. |
| Taxonomía | La E2E aislada Taxonomy/Catalog acredita integración, no rendimiento. | Medidas de endpoints taxonómicos con cardinalidades, p50/p95/p99, SQL/planes, pool y recuperación. |
| Gateway | Las pruebas de routing/identidad acreditan comportamiento y autorización, no rendimiento. | Carga end-to-end, solicitudes/bytes, latencia/errores y upstreams concurrentes. |

## Cobertura de pantallas administrativas

La matriz siguiente se trazó desde `src/app/routes/productRoutes.tsx`, hooks, composición de runtime, adapters y rutas HTTP. Los nombres de endpoint son sus prefijos/patrones; cada adapter determina query, método y parámetros. El Frontend verificó composición Combos con fetch de Gateway aislado. Es una prueba de red simulada y no una captura de Gateway activo. Para todo el tráfico por pantalla, las solicitudes/bytes/latencias no están disponibles; no se presentan como ceros.

| Pantalla / rutas | Hook(s) | Adapter / Gateway | Endpoint(s) | Servicio | Requests / bytes / tiempo |
|---|---|---|---|---|---|
| Productos, alta/edición/detalle/estado/preparación y variantes (`/productos/**`) | `useProductList`, `useProductDetail`, `useProductForm`, `useProductPreparation`, `useProductStateMutation`, `useVariantList/Detail/Form/Preparation/StateMutation` | `CatalogServicesContext` → repositorio HTTP Catálogo/Taxonomía → cliente Gateway autenticado | `/productos/administracion`, `/productos/administracion/{productId}`, `/productos/{productId}/variantes/**`, `/productos/{productId}/preparacion`, lecturas de esquema `/caracteristicas/{id}` | Catálogo; Taxonomía para esquemas | No medidos |
| Combos (lista, alta/edición/detalle) (`/combos/**`) | `useCombosRuntime` | `CatalogCombosAdapter`, repositorio HTTP Combos → cliente Gateway autenticado | `/combos`, `/combos/{id}`, `/combos/administracion`, Catálogo `/productos/administracion`, resolver admin `/productos/administracion/skus/resolver` | Combos; Catálogo | No medidos. Prueba de composición verifica rutas, bearer humano, 403 y ausencia de llamada privada a Pricing |
| Precios (vigente, edición, programación, importación, resultado, histórico) (`/precios/**`) | `usePricingContext` y hooks/contexto de página | `createHttpPricingRepository` → cliente Gateway autenticado | `/precios/productos/{id}`, `/precios/skus/{sku}`, recursos de programación/importación/reportes; lectura de objetivos de Catálogo | Pricing; Catálogo | No medidos por pantalla |
| Auditoría de precios (historial, detalle, exportación CSV/PDF) (`/precios/auditoria/**`) | `useAuditRead`, `useAuditExport` | `createHttpAuditRepository` → cliente Gateway autenticado | `/precios/auditoria/**` | Auditoría de precios | No medidos |
| Categorías (árbol, alta/confirmación slug, detalle, edición, baja/reactivación) (`/categorias/**`) | `useCategoryTree/Detail/CreateCategory/UpdateCategory/SolicitarBaja/ReactivarCategoria` | repositorio HTTP Categoría → `taxonomyGatewayRuntime` → cliente Gateway autenticado | `/categorias/**`, `/seo/categorias/slug/resolver` | Taxonomía | No medidos |
| Características y valores (`/caracteristicas/**`) | `useCharacteristicList/Detail/CreateCharacteristic/UpdateCharacteristic` y operaciones de valores/estado | repositorio HTTP Características → Gateway autenticado | `/caracteristicas/**` | Taxonomía | No medidos |
| Tipos de producto y esquemas (`/tipos-producto/**`) | `useProductTypeList/Detail/Schema` y hooks de asociación/estado | `httpProductTypeAdminAdapter` → Gateway autenticado | `/tipos-producto/**`, `/taxonomia/operaciones/{id}` | Taxonomía | No medidos |
| Marcas (`/marcas/**`) | `useBrandList/Detail/SolicitarBajaMarca` y formulario | `httpBrandRepository` → Gateway autenticado | `/marcas/**` | Taxonomía | No medidos |
| SEO (`/seo/**`) | `useSeoList/Detail/GuardarSeo/HistorialSlug` | repositorio HTTP SEO → Gateway autenticado | `/seo/**` | Taxonomía | No medidos |
| Recomendaciones (cross-sell/upsell/selector/estado) (`/recomendaciones/**`) | hooks del servicio de promociones y páginas de regla | `httpPromotionServices.recommendations` → Gateway autenticado | `/recomendaciones/**` | Promociones | No medidos |
| Campañas (`/promociones/**`) | `usePromotionServices` y páginas de campaña | `httpPromotionServices` → Gateway autenticado | `/promociones/**` | Promociones | No medidos |
| Cupones (`/cupones/**`) | `useCoupons`, `useCouponForm`, `usePromotionCommand` | `httpPromotionServices` → Gateway autenticado | `/cupones/**` | Promociones | No medidos |
| Inventario (saldos, umbrales, traslados, dashboard) (`/inventario/**`) | `useInventoryStock/FilterOptions/Thresholds/Transfers/Dashboard` | `createHttpInventoryRepository` y snapshot Catálogo → cliente Gateway autenticado | `/inventario/administracion/saldos`, `/inventario/umbrales/**`, `/inventario/traslados/**`, `/inventario/dashboard/**` | Inventario; Catálogo/Taxonomía para enriquecer selección | No medidos |
| Carga masiva (importación, revisión, progreso, resultado, descargas) (`/carga-masiva/**`) | `useBulkFlow`, `useBulkBatch`, `useBulkDownloads`, `useBulkRepository` | `createHttpBulkRepository` → transporte Gateway autenticado dedicado | `/carga-masiva/**` | Bulk | No medidos |

### Evaluación de recorridos administrativos

`POST /productos/administracion/skus/resolver` solo resuelve los SKU que recibe y publica datos de elegibilidad/identidad. No enumera Catálogo ni incluye todos los atributos que consumen Pricing e Inventario. Por eso no sustituye el recorrido de productos/variantes de `listCatalogTargets` o `listInventoryCatalogSkus`. Ambos necesitan SKU reales, relaciones y nombres; Inventario también usa IDs de categoría/marca con su catálogo de Taxonomía. El recorrido de Inventario ya usa `listVariantsByProduct` con concurrencia acotada a 4 y caché de 30 segundos por usuario. Pricing reutiliza ahora ese helper por página en vez de cargar variantes de forma secuencial. La cantidad de llamadas por producto no desaparece: el contrato vigente solo publica el listado de variantes por producto, y agregar un enumerador consolidado sería cambio contractual. No se presenta el camino como cero N+1 ni como optimización de solicitudes medida; se redujo el fan-out secuencial sin perder atributos ni alterar el contrato.

No hay mediciones de carga reales por pantalla en estos PR: p50/p95/p99, solicitudes HTTP, bytes, throughput y concurrencia sostenida están pendientes de un Gateway/servicios aislados instrumentados. El mapa anterior acredita trazabilidad de código y los casos de test especificados, no tiempos de runtime.

## Límite del entorno aislado de esta auditoría

No se usaron tráfico productivo ni `.env.local`. El daemon Docker de esta estación no responde (`Docker Desktop is unable to start`); el servicio `com.docker.service` está detenido y el usuario actual no puede abrirlo para iniciarlo (`Cannot open 'com.docker.service' service`). La distribución WSL tampoco dispone de cliente Docker ni integración de Docker Desktop. Por eso no se ejecutó aquí un nuevo benchmark de nueve servicios ni de pantallas. Esta limitación no convierte los resultados de Pricing en evidencia de los servicios restantes.

Las ejecuciones de CI en runners desechables podrán acreditar integración funcional y las mediciones existentes de Pricing. No acreditarán throughput o percentiles de los otros servicios si el workflow no los genera explícitamente.

## Resultado de cierre

- **Corregido:** wiring administrativo de Combos, replay acotado del POST lógico de lectura y compatibilidad de Pricing por modo están implementados en los SHA indicados; las suites locales reportadas pasan. CI completa queda pendiente.
- **Medido:** solo las dimensiones expresamente reportadas arriba y en el informe de Pricing; la cobertura completa solicitada permanece pendiente.
- **Bloqueado externamente:** concesión/grant real de G7 y homologaciones externas que resulten contractualmente necesarias. La ausencia de Docker local es una limitación del entorno de esta auditoría, no un bloqueo externo de G6.
