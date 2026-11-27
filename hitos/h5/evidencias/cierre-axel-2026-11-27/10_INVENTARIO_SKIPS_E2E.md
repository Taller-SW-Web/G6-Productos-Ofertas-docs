# Inventario Completo de SKIPs (Backend 369 E2E + 105 Unitarias + Frontend 8 Playwright) — 2026-11-27

> **Política aplicada:** ningún `SKIP` se oculta ni se contabiliza como `PASS`. Cada caso omitido en la corrida por defecto se inventaría por archivo, conteo exacto, guard/flag, cobertura en job CI independiente (con SHA y URL) o corrida opt-in local ejecutada, y brecha pendiente real.

## 1. Backend — Pruebas Unitarias (`npm test`: 255 passed | 2 skipped, 2972 passed | 105 skipped)

| Archivo | Skips | Flag / Razón | Cobertura independiente verificada (SHA `18413ac` / CI `#46044277201`) | Estado real |
|---|---:|---|---|---|
| `apps/bulk-svc/src/persistence/bulk.repository.integration.spec.ts` | 38/38 | Requiere PG17 desechable (`BULK_TEST_DATABASE_URL`) | Ejecutado localmente vía `node tests/h5/run-bulk-postgres17.mjs` (**38/38 PASS**) + cubierto por `MK-001 Bulk E2E Integral` | **CUBIERTO L1 (PG17)** |
| `apps/inventory-svc/test/inventory.real.integration.spec.ts` | 67/67 | Requiere PG17 + RabbitMQ desechables (`INVENTORY_REAL_INTEGRATION=1`) | Cubierto por job CI obligatorio `Probar integración de Inventory con PostgreSQL y RabbitMQ desechables` en [`#46044277201`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46044277201) (**PASS 67/67**) | **CUBIERTO CI (PG17+RMQ)** |

---

## 2. Backend — Pruebas E2E (`npm run test:e2e`: 50 passed | 36 skipped, 1105 passed | 369 skipped; +1 nuevo opt-in R16 restart = 370)

### 2.1 Resumen de cobertura de los 369 (+1) casos omitidos en corrida base

| Categoría | Archivos | Casos | Estado |
|---|---:|---:|---|
| Cubiertos por jobs obligatorios en CI [`#46044277201`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46044277201) (PG17 / RMQ / TLS / contenedores) | 19 | 238 | **PASS en CI remoto (`18413ac`)** |
| Ejecutados explícitamente en opt-in L1 local (PG17 descartable) | 7 | 50 (+1 nuevo R16) | **PASS en L1 local** |
| Suites `readonly` contra Supabase compartido (`G6_READONLY_INTEGRATION`) | 3 | 9 | `NOT_RUN` (requiere URL read-only Supabase aprobada) |
| Suites Azure Service Bus real (`G6_SERVICE_BUS_AZURE_TESTS`, `REAL_SB_ENABLED`, `realAzureEnabled`) | 3 | 25 | **`PENDING_AZURE_L2`** (requiere autorización de envío/consumo en `g6-sb-h5-chile-261127`) |
| Suites opt-in de navegador/performance/demo local (`G6_PERFORMANCE_HTTP`, `CATALOG_H4_NATIVE_POSTGRES`, `inventory-commercial-demo` demo cases, `int01-local-catalog`) | 6 | 47 | Parcial: cubiertas parcialmente por `MK-001 Bulk E2E Integral` (`#46044279656`), `certify-158-endpoints.mjs` y `PERF-06`; benchmarks HTTP k6 pendientes de staging |
| **Total inventario E2E** | **38 (+1)** | **369 (+1)** | **100% contabilizado (0 ocultos)** |

### 2.2 Detalle archivo por archivo (los 36 archivos completos + 2 parciales = 369 skips exactos)

| # | Archivo E2E | Skips | Guard / Flag exacto | Cobertura CI / L1 / Estado |
|---:|---|---:|---|---|
| 1 | `ops/azure/service-bus/pilot.postgres.e2e-spec.ts` | 8/8 | `G6_SERVICE_BUS_POSTGRES_TESTS !== '1'` | **Ejecutado L1 PG17 (`18413ac`): 8/8 PASS** (recuperación transaccional R16) |
| 1b | `ops/azure/service-bus/r16-price-audit-restart.postgres.e2e-spec.ts` *(nuevo)* | 1/1 | `G6_SERVICE_BUS_POSTGRES_TESTS !== '1'` | **Ejecutado L1 PG17 (`18413ac`): 1/1 PASS** (reinicio real proceso `price-audit-svc`) |
| 2 | `apps/promotions-svc/test/coupon-h5.postgres.e2e-spec.ts` | 12/12 | `PROMOTIONS_H5_POSTGRES_TESTS !== '1'` | **Ejecutado L1 PG17: 12/12 PASS** + job CI `Probar persistencia de Promotions con PostgreSQL TLS` (`#46044277201` PASS) |
| 3 | `tests/h5/taxonomy-service-bus.postgres.e2e-spec.ts` | 23/23 | `G6_TAXONOMY_H5_POSTGRES_TESTS !== '1'` | **Ejecutado L1 PG17 (`run-taxonomy-catalog-postgres.mjs`): 23/23 PASS** + job CI `Probar E2E aislado Taxonomy y Catalog` (`#46044277201` PASS) |
| 4 | `apps/bulk-svc/test/r03-pricing-r14-bulk.postgres.e2e-spec.ts` | 3/3 | `BULK_TEST_POSTGRES !== '1'` | **Ejecutado L1 PG17: 3/3 PASS** |
| 5 | `apps/pricing-svc/test/r03-r14-r16-r17.postgres.e2e-spec.ts` | 3/3 | `PRICING_TEST_POSTGRES !== '1'` | **Ejecutado L1 PG17: 3/3 PASS** + job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 6 | `tests/h5/azure-service-bus.real.e2e-spec.ts` | 19/19 | `!REAL_SB_ENABLED` | **`PENDING_AZURE_L2`** — requiere autorización de envío/consumo en `g6-sb-h5-chile-261127` |
| 7 | `apps/api-gateway/test/bulk-postgres.gateway.e2e-spec.ts` | 7/7 | `G6_BULK_GATEWAY_POSTGRES_E2E` | Cubierto por workflow `Integración Bulk-Catalog Retry (PostgreSQL 17 descartable)` |
| 8 | `apps/api-gateway/test/inventory-postgres.gateway.e2e-spec.ts` | 9/9 | `INVENTORY_GATEWAY_POSTGRES` / `performanceEnabled` | Cubierto por job CI `Probar E2E Gateway → Inventory → PostgreSQL 17 (obligatorio)` (`#46044277201` PASS) |
| 9 | `apps/api-gateway/test/marketplace.postgres.e2e-spec.ts` | 5/5 | `G6_HTTP_POSTGRES_INTEGRATION !== '1'` | Cubierto por job CI `Validar imágenes y pruebas funcionales de contenedores` (paso Marketplace PG TLS, `#46044277201` PASS) |
| 10 | `apps/bulk-svc/test/bulk-browser-real.e2e-spec.ts` | 1/1 | `!enabled` (opt-in navegador) | Cubierto por workflow `MK-001 Bulk E2E Integral (Navegador Real + Recuperación + Performance)` (`#46028848508` PASS) |
| 11 | `apps/bulk-svc/test/bulk-catalog-retry.e2e-spec.ts` | 1/1 | `BULK_RETRY_INTEGRATION_*` | Cubierto por workflow `Integración Bulk-Catalog Retry (PostgreSQL 17 descartable)` (`#46028848676` PASS) |
| 12 | `apps/bulk-svc/test/bulk-http-benchmark.e2e-spec.ts` | 1/1 | `G6_PERFORMANCE_HTTP !== '1'` | Benchmark opt-in (PERF-07 pendiente de staging autorizado) |
| 13 | `apps/bulk-svc/test/bulk-messaging.e2e-spec.ts` | 18/18 | `BULK_TEST_DATABASE_URL` | Workflow `Bulk PostgreSQL y RabbitMQ desechables` (diferido en Draft) + cubierto vía `certify-19-messaging-flows.mjs` |
| 14 | `apps/bulk-svc/test/bulk-performance-suite.e2e-spec.ts` | 1/1 | `!enabled` (opt-in perf) | Cubierto en modo laboratorio por `MK-001 Bulk E2E Integral` |
| 15 | `apps/bulk-svc/test/bulk-recovery-files-migrations.e2e-spec.ts` | 5/5 | `BULK_RETRY_INTEGRATION_*` | Cubierto por workflow `Integración Bulk-Catalog Retry (PostgreSQL 17 descartable)` (`#46028848676` PASS) |
| 16 | `apps/catalog-svc/test/catalog-admin-native-postgres.e2e-spec.ts` | 1/1 | `CATALOG_H4_NATIVE_POSTGRES === '1'` | Opt-in nativo PG17; funcionalidad cubierta en `postgres.persistence.e2e-spec.ts` (104/104) y 158-endpoints |
| 17 | `apps/catalog-svc/test/catalog-browser-real.e2e-spec.ts` | 1/1 | `!enabled` (opt-in navegador) | Cubierto por corrida Frontend `e2e-real` contra Backend candidato |
| 18 | `apps/catalog-svc/test/catalog-service-bus-relay.postgres.e2e-spec.ts` | 1/1 | `CATALOG_H4_NATIVE_POSTGRES === '1'` | Cubierto en `certify-19-messaging-flows.mjs` (R04–R09 PASS) y `run-taxonomy-catalog-postgres.mjs` (23/23 PASS) |
| 19 | `apps/catalog-svc/test/commercial-eligibility.postgres.e2e-spec.ts` | 1/1 | `G6_READONLY_INTEGRATION !== 'catalog'` | `NOT_RUN` — prueba readonly contra BD compartida (requiere credencial readonly) |
| 20 | `apps/catalog-svc/test/postgres.readonly.e2e-spec.ts` | 5/5 | `G6_READONLY_INTEGRATION !== 'catalog'` | `NOT_RUN` — prueba readonly contra BD compartida |
| 21 | `apps/combos-svc/test/combos-service-bus-postgres.e2e-spec.ts` | 4/4 | `!isolatedHarnessEnabled` | Cubierto por job CI `Probar integración H5 de Combos con PostgreSQL 17 TLS y contrato 0.7.0-rc.3` (`#46044277201` PASS) |
| 22 | `apps/combos-svc/test/combos-service-bus.azure.e2e-spec.ts` | 3/3 | `!realAzureEnabled` | **`PENDING_AZURE_L2`** — requiere corrida autorizada en Azure Service Bus |
| 23 | `apps/price-audit-svc/test/consumer.amqp.e2e-spec.ts` | 8/8 | `PRICE_AUDIT_TEST_AMQP !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 24 | `apps/price-audit-svc/test/exports.postgres.e2e-spec.ts` | 10/10 | `PRICE_AUDIT_TEST_POSTGRES !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 25 | `apps/price-audit-svc/test/provider.postgres.e2e-spec.ts` | 14/14 | `PRICE_AUDIT_TEST_POSTGRES !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 26 | `apps/taxonomy-svc/test/persistencia-drizzle.e2e-spec.ts` | 71/71 | `TAXONOMY_TEST_DATABASE_URL` | Cubierto por job CI `Probar integración de Taxonomy con PostgreSQL desechable` (`#46044277201` PASS) |
| 27 | `apps/taxonomy-svc/test/postgres.readonly.e2e-spec.ts` | 3/3 | `G6_READONLY_INTEGRATION !== 'taxonomy'` | `NOT_RUN` — prueba readonly contra BD compartida |
| 28 | `apps/pricing-svc/test/catalog-pricing.integration.e2e-spec.ts` | 1/1 | `!enabled` (opt-in Pricing+Catalog) | Workflow `Integración histórica Pricing y Catalog` (diferido en Draft) + cubierto por `certify-19-messaging-flows.mjs` (R07/R15) |
| 29 | `apps/pricing-svc/test/historical-initialization.e2e-spec.ts` | 40/40 | `PRICING_TEST_AMQP !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 30 | `apps/pricing-svc/test/import-prices.postgres.e2e-spec.ts` | 8/8 | `PRICING_TEST_POSTGRES !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 31 | `apps/pricing-svc/test/inbox-consumer.amqp.e2e-spec.ts` | 8/8 | `PRICING_TEST_AMQP !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 32 | `apps/pricing-svc/test/outbox.amqp.e2e-spec.ts` | 6/6 | `PRICING_TEST_AMQP !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 33 | `apps/pricing-svc/test/persistence.e2e-spec.ts` | 46/46 | `PRICING_TEST_POSTGRES !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) |
| 34 | `apps/pricing-svc/test/price-audit.integration.e2e-spec.ts` | 1/1 | `PRICING_TEST_AUDIT !== '1'` | Cubierto por job CI `Probar persistencia y mensajería de Pricing y Price Audit` (`#46044277201` PASS) + `pilot.postgres.e2e-spec.ts` (8/8) |
| 35 | `ops/azure/service-bus/pilot.azure.e2e-spec.ts` | 3/3 | `G6_SERVICE_BUS_AZURE_TESTS !== '1'` | **`PENDING_AZURE_L2`** — requiere corrida autorizada de R16 en `g6-sb-h5-chile-261127` |
| 36 | `apps/catalog-svc/test/h5/int01-local-catalog.e2e-spec.ts` | 7/7 | `!enabled \|\| !dockerAvailable` (`G6_H5_INT01_CATALOG_L1`) | Funcionalidad INT-01 L1 cubierta por `certify-158-endpoints.mjs` + `catalog-sku-context.http.e2e-spec.ts` (29/29) |
| 37 | `apps/catalog-svc/test/runtime-postgres.e2e-spec.ts` *(parcial)* | 1/6 | Caso opt-in dentro de suite (5/6 PASS) | 5/6 casos activos pasaron en corrida secuencial |
| 38 | `apps/inventory-svc/test/inventory-commercial-demo.e2e-spec.ts` *(parcial)* | 10/22 | Casos opt-in PG/demo dentro de suite (12/22 PASS) | 12/22 casos activos pasaron; persistencia real cubierta por `inventory-h5.postgres.e2e-spec.ts` (26/26) y job `inventario` (`#46044277201` PASS) |

---

## 3. Frontend #102 (`ccfc21ba0e821f33c0debf09389879e55df0539b`) — Separación estricta de runs y 8 SKIPs

- **Run Playwright completo en GitHub Actions (`#46028914883`, 4/4 shards + Pricing + smoke + API build):** **PASS 100%** (0 fallos, sin reintentos).
- **Run Playwright completo local (`npm run test:e2e`, durante contención CPU con Backend E2E):** 664 passed, 8 skipped, 2 fallos transitorios (`promotions-coupon-http.spec.ts:251`, `transversal-integration.spec.ts:111`).
- **Reintento focalizado local aislado (separado del run completo):** **2/2 PASS** (30.6 s).
- **Inventario exacto de los 8 SKIPs en `npm run test:e2e` de Frontend:**

| Archivo Frontend | Casos skip | Flag / Motivo | Cobertura independiente |
|---|---:|---|---|
| `tests/admin-performance.spec.ts` | 1 | `!process.env.G6_PERF_HARNESS` (opt-in benchmark PERF-06) | **EJECUTADO en CI [`#46043178034`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46043178034)** (`Benchmark administrativo base y optimizado`: **PASS**, 81 rutas / 14 familias) |
| `tests/catalog-http-real-l1-independent.h5.pw.ts` | 4 | Opt-in harness Catalog HTTP real L1 | Cubierto en `certify-158-endpoints.mjs` + `tests/e2e-real/` |
| `tests/catalog-http-real.spec.ts` | 1 | `!process.env.CATALOG_REAL_JWT` (requiere runner E2E real con JWT local firmado) | Cubierto por `tests/e2e-real/` + `Compilación - Integración con API` (`#46028914883` PASS) |
| `tests/promotions-gateway.spec.ts` | 1 | Opt-in Gateway vivo Promotions | Cubierto en L1 por `certify-158-endpoints.mjs` (25/25 `promotions-svc` PASS) |
| `tests/promotions-session-gateway.spec.ts` | 1 | Opt-in sesión Gateway vivo Promotions | Cubierto en L1 por `security-playwright.config.ts` (7/7 PASS) + `Compilación - Integración con API` (`#46028914883` PASS) |
