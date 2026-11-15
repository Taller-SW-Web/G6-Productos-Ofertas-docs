# Auditoría final de optimizaciones G6 — 2026-11-14

## Alcance y estado

Esta evidencia sigue los Draft PR existentes: Backend #230 (`perf/optimizacion-integral-g6`, SHA medido `c05154e3167a22bf46b64da8f7f28658e67f0b44`), Frontend #82 (`codex/perf-optimizacion-integral-g6`, SHA `46cd9f0fafcd65b821148e4625e436ad8560c7e3`) y Docs #120 (`docs/optimizaciones-integral-g6-contratos`). No crea ramas o PR sustitutos.

- Backend #230 CI completa en SHA `c05154e`: [run 43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), PASS. Incluyó los jobs manuales/opcionales de benchmark y publicó el artifact retenido 7 días `pricing-component-benchmarks-c05154e3167a22bf46b64da8f7f28658e67f0b44` (JSON/CSV del token y logs de Pricing). También pasaron [A1/A2](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43658275917) y las suites aisladas [Bulk/PostgreSQL/RabbitMQ](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43658275944).
- Frontend #82 CI para `46cd9f0`: [run 43658438259](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/43658438259), PASS; cuatro shards E2E, build API, suites unitarias, typecheck y lint pasaron. El run incompleto de SHA anterior fue cancelado y no se usa como evidencia.
- Docs #120 CI del commit `9c56d9c`: [run 43658916417](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/runs/43658916417), PASS. La revisión documental posterior `9a1a9fa` también pasó [CI run 43659877852](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/runs/43659877852).

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

| Servicio | Evidencia de rendimiento obtenida | Runner y pruebas reales intentadas; brecha verificable |
|---|---|---|
| Catálogo | Ninguna medida de endpoint Catalog aislada del cliente Pricing. | En run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), `Probar E2E aislado Taxonomy y Catalog` pasó funcionalmente con procesos/dependencias aisladas, pero no ejecuta un generador de carga ni exporta HTTP/SQL/pool/EXPLAIN; el benchmark Pricing usa solo fixture HTTP loopback. |
| Pricing | Batch 1/20/100 SKU con PostgreSQL 16 desechable y fixture HTTP de Catálogo; y microbenchmark de token firmado local (detalles abajo). | Run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), job `Medir lotes de Pricing con PostgreSQL desechable`: no levanta HTTP Pricing/Catálogo juntos y no captura pool ocupado ni Gateway; sin carga sostenida del servicio. |
| Combos | Sin percentiles ni throughput. | Run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), job `Probar integración de Combos con PostgreSQL, RabbitMQ y Catalog desechables`: proceso y dependencias reales, pruebas funcionales; el runner no instrumenta tasas/bytes/SQL/pool/EXPLAIN ni sostiene carga. |
| Inventario | Sin percentiles ni throughput. | Run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), job `Probar integración de Inventory con PostgreSQL y RabbitMQ desechables`: E2E funcional; no existe en ese job una ventana de carga o export de SQL/pool/planes. |
| Promociones | Sin percentiles ni throughput. | Run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), job `Probar persistencia de Promotions con PostgreSQL TLS`: E2E funcional aislado; sin generador de carga sostenida ni captura de métricas HTTP/SQL/pool. |
| Auditoría de precios | Sin carga a endpoint Price Audit. | Run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), job `Probar persistencia y mensajería de Pricing y Price Audit`: comprueba integración funcional, pero no emite series de latencia/throughput/bytes, SQL dominante o pool. |
| Bulk | Sin percentiles ni throughput. | Run [43658275944](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43658275944), suite PostgreSQL/RabbitMQ desechables: prueba integración y proceso; no recoge series de carga HTTP, métricas SQL/EXPLAIN ni pool. |
| Taxonomía | Sin métricas de endpoint Taxonomy. | Run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), jobs `Probar integración de Taxonomy con PostgreSQL desechable` y `Probar E2E aislado Taxonomy y Catalog`: E2E funcional; no hay capturador de concurrencia, percentiles, bytes, SQL/buffers o pool. |
| Gateway | Sin throughput ni latencias sostenidas. | Run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495), job `Probar E2E Gateway → Inventory → PostgreSQL 17`: upstream real y ruta integrada, pero no inyecta carga sostenida ni mide solicitudes/bytes/timeout/recovery concurrente. |

Los runners de Actions sí disponen de Docker y levantaron estas dependencias; por tanto Docker Desktop local no es un impedimento. La brecha concreta de las filas indicadas es que los jobs de integración funcional citados no tienen generador de carga ni exportadores de las métricas señaladas. Esa carencia es alcance pendiente del harness de rendimiento, no un bloqueo de G7 ni de infraestructura externa.

### Pricing: evidencia de componente de token y benchmark batch previo

El run [43665450495](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43665450495) se ejecutó en `ubuntu-latest`, Linux x64, Node `v24.15.0`; el runner informó 4 vCPU y 16.8 GB. El artifact `pricing-component-benchmarks-c05154e3167a22bf46b64da8f7f28658e67f0b44` contiene `pricing-token-benchmark.json`, CSV y los logs de batch. No contiene credenciales reales ni datos productivos.

El microbenchmark de token ejecutó 5 waves de warm-up y 100 waves medidas por nivel. Cada wave crea un servicio frío y lanza solicitudes simultáneas al mismo scope contra un emisor JWT firmado loopback con demora controlada de 4 ms. Observó una sola emisión por wave, sin fallos; mide únicamente `CatalogServiceToken → emisor local`, sin proceso HTTP de Pricing, PostgreSQL, RabbitMQ ni pool SQL.

| Concurrencia de llamadas lógicas | Solicitudes lógicas | Emisiones al issuer | p50 | p95 | p99 | Solicitudes lógicas/s | Fallos |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 100 | 100 (1 por wave) | 5.180 ms | 5.653 ms | 6.661 ms | 190.86 | 0 |
| 4 | 400 | 100 (1 por wave) | 5.094 ms | 5.466 ms | 5.623 ms | 783.89 | 0 |
| 16 | 1,600 | 100 (1 por wave) | 5.147 ms | 5.409 ms | 5.640 ms | 3,121.85 | 0 |

Estos resultados verifican que el singleflight colapsa emisiones simultáneas del mismo scope en cold start bajo esta demora sintética; no demuestran rendimiento de red G7 ni cambios de capacidad productiva. No se midió saturación o variabilidad entre runners.

El benchmark batch de Pricing del mismo run se conserva como evidencia independiente y comparable con su propio flujo legacy: PostgreSQL 16 desechable, pool máximo 2, timeout SQL 2 s, fixture HTTP de Catálogo con 4 ms artificiales y 100 muestras por caso. En 100 SKU, por ejemplo, el flujo batch observó p50/p95/p99 de 8.17/9.78/12.35 ms y 2 SELECT + 1 llamada a Catálogo; el equivalente legacy observó 544.27/559.99/598.06 ms, 194 SELECT y 100 llamadas al fixture. En 20 SKU, batch hizo 2 SELECT y una llamada versus 38 SELECT y 20 llamadas del flujo legacy. Estos datos del log no son medición contra el provider real de Catálogo, Gateway ni una comparación de ramas `master` vs optimizada; el informe específico [Pricing 100 SKU](RESULTADOS_BENCHMARK_PRICING_G6_2026-11-14.md) conserva el antecedente aprobado.

## Cobertura de pantallas administrativas

La matriz siguiente se trazó desde `src/app/routes/productRoutes.tsx`, hooks, composición de runtime, adapters y rutas HTTP. Los nombres de endpoint son sus prefijos/patrones; cada adapter determina query, método y parámetros. El Frontend verificó composición Combos con fetch de Gateway aislado. Es una prueba de red simulada y no una captura de Gateway activo. Para todo el tráfico por pantalla, las solicitudes/bytes/latencias no están disponibles; no se presentan como ceros.

Intento reproducible revisado: el [run Frontend 43658438259](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/43658438259) ejecutó cuatro shards E2E de navegador, pero su workflow no contiene request/response byte recorder ni export de muestras/percentiles. Por ello ese run verifica comportamiento, no rendimiento. El harness opt-in de esta ronda está en implementación y no tiene todavía un artifact enlazable en este corte; las celdas de abajo conservan esa limitación concreta y temporal, no un impedimento de infraestructura.

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

## Ejecución aislada y límites de evidencia

No se usaron tráfico productivo ni `.env.local`. Docker Desktop/WSL local no forma parte de las precondiciones para completar esta auditoría: la ejecución autorizada usa runners desechables de GitHub Actions, donde el job existente `pricing_batch_benchmark` ya verificó Docker y levantó PostgreSQL sintético. Esa ejecución acredita únicamente el alcance del benchmark que realmente ejecuta; no acredita por sí sola carga de los nueve procesos, RabbitMQ, métricas SQL/pool ni mediciones de pantallas.

Los runs de CI funcional previos no son evidencia de throughput o percentiles. La cobertura de rendimiento solo se actualizará al descargar y vincular los artifacts JSON/CSV de los nuevos workflows opt-in, con su SHA, run, configuración y alcance. Hasta entonces, las tablas anteriores conservan el estado documentado antes de esos runs y no deben interpretarse como mediciones nuevas.

## Resultado de cierre

- **Corregido:** wiring administrativo de Combos, replay acotado del POST lógico de lectura, compatibilidad de Pricing por modo y singleflight de emisión técnica por scope están implementados. Backend SHA `c05154e` CI completa PASS en run `43665450495`; el reporte de token verifica una sola emisión por wave del mismo scope y cobertura de pruebas de fallo/aislamiento.
- **Medido:** microbenchmark del cliente token y benchmark Pricing batch con PostgreSQL + fixture HTTP, según sus alcances separados; el resto de los servicios aún carece de un harness que produzca las métricas indicadas. Las pantallas administrativas siguen en fase de instrumentación browser/API controlada y no se atribuye latencia de provider.
- **Bloqueado externamente:** solo grants reales de G7 y homologaciones de consumidores externos que requieran aceptación. Docker local no bloquea G6: los jobs de Actions citados corrieron con Docker y dependencias descartables. La cobertura integral sigue pendiente de trabajo interno de harness, no se clasifica como bloqueo externo.
