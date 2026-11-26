# Cierre MK-001 Bulk H5 sin despliegue

**Corte:** 25/11/2026 (America/Lima)
**Alcance:** Bulk B01–B08 y F01–F06, integración requerida de Catalog H5, E2E en navegador real (Chromium), recuperación P1, matriz de archivos/exportaciones, migraciones, performance reproducible y documentación.
**Estado del corte:** `CODE_COMPLETE / TESTED_DISPOSABLE_CI / BACKEND_MERGED / FRONTEND_READY_NOT_MERGED / NOT_DEPLOYED`.
- Backend PR [#274](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/274) quedó fusionado en `master` (`daf4882b7dc6895c6601a1f4af209ec92c8215b0`, HEAD `e3ae66ebebcaa6aed78340a6cc003dbaaf09b3bb`).
- Backend PR [#283](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/283) (HEAD `a2cf59de5b97682514effd512e42038fe304ca59`) quedó fusionado en `master` (`fdd0b59e6e8251cae0a5d4b4652c99af58206b2c`); posteriormente `master` avanzó hasta `20b890e5196df56a9890d42c8d85c4935b83ea08` (post-merge CI `45557503199` y `45557503313` en **PASS**).
- Backend PR [#285](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/285) (HEAD `06ef20b44dc409da4a36ad2deddd8013679b3ad9`, cierre de auditoría final) quedó fusionado en `master` (`ce57c5effc1ab63549d64ab5b25204bab4fa7b6e`) tras pasar `MK-001 Bulk E2E Integral` ([run `45560095170`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45560095170), 2m43s, **PASS**) y su CI completa (`45560095278`, `45560095370`, `45560095167`, `45560095225`).
- Backend PR [#287](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/287) (HEAD `e4db2842bc367f489ce12c60022923b8a7d0c5d1`, outage real de conectividad PostgreSQL por proxy TCP descartable) quedó fusionado en `master` (`75d5687eeb1fc18b50b7ce1d20404e822618934a`) tras pasar `MK-001 Bulk E2E Integral` ([run `45563675826`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45563675826), 2m35s, **7/7 Vitest y 2/2 Playwright PASS**) y toda su CI (`45563675882`, `45563675985`, `45563675800`, `45563675795`) contra PostgreSQL 17 descartable, Supabase Storage local (CLI 3.4.0), API Gateway real, Bulk real, Catalog real y Chromium sobre Frontend fijado al SHA inmutable `f26864bb2b20c5abd693fb415f392ed6110e317b`.
- Docs PR [#146](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/146) (HEAD `7baee4b649928012eb3b08235ffff6c8e0d61b39`) quedó fusionado en `master` (`5c23a5c8b7ed9b25c9ae85b6cd36d4a3c6f405cc`).
- Frontend PR [#97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/97) (HEAD `f26864bb2b20c5abd693fb415f392ed6110e317b`) pasó su CI aplicable, fue publicado bajo protección `vercel.json` (`deploymentEnabled: { "**": false, "master": true }`, verificado con `vercel ls`: cero despliegues Preview) y permanece Ready for Review sin fusionar a `master` para evitar despliegue automático de producción (`FRONTEND_READY_NOT_MERGED`).
**Despliegue:** NO REALIZADO.

## 1. Resumen ejecutivo

Se completó el cierre integral de **MK-001 Bulk H5** sin ejecutar despliegues ni modificar entornos compartidos:

1. **Recuperación Frontend (`494c88c` → `f26864bb`) y reproducibilidad de CI:** se recuperó el commit local no publicado en `trabajo/castilla/bulk-h5-integracion-real`, se verificó la protección de `vercel.json` y `vercel ls`, se volvió obligatoria la descarga de reporte de errores (`GET .../reporte` 200, `text/csv`, `batchId`, contenido `/CATALOG_AUTH_TEMPORARY_UNAVAILABLE|CATALOGO|FAILED/i` y `owner-b` 404) eliminando el `if` condicional en `tests/bulk-http-real.spec.ts`, y se fijó `.github/workflows/bulk-browser-e2e.yml` al SHA inmutable `f26864bb2b20c5abd693fb415f392ed6110e317b` con validación 40-hex y registro en `run-metadata.json` y `$GITHUB_STEP_SUMMARY`.
2. **Orquestador E2E en navegador real (`apps/bulk-svc/test/bulk-browser-real.e2e-spec.ts`):** ejecuta los **2 escenarios Playwright** de `tests/bulk-http-real.spec.ts` (Chromium → React Bulk `VITE_DATA_MODE=api` → API Gateway real con JWKS local y JWT RS256 → Bulk real → PostgreSQL 17 descartable / Supabase Storage local → Catalog real → resultado V2 → UI), cubriendo plantillas, doble clic, admisión ambigua, conciliación por correlación, rechazo transitorio Catalog, reanudación exclusiva, recarga, descarga obligatoria de reporte, exportaciones reales CSV/XLSX, aislamiento 401/403/404 y accesibilidad a 1440 px.
3. **Recuperación P1, archivos y migraciones (`apps/bulk-svc/test/bulk-recovery-files-migrations.e2e-spec.ts`, 5 pruebas Vitest):**
   - Recreación de módulo NestJS (`app1.close()` → `app2.init()`) con Outbox durable pendiente (no reinicio de SO), deduplicación de consumidor Catalog, claim-check malformado e inyección simulada de fallo del adaptador Storage (`vi.spyOn(storage, 'put')` → 503, escenario simulado distinto de caída real del servicio).
   - **Fallo temporal de autorización/acceso por rol/esquema PostgreSQL** (`ALTER ROLE bulk_app NOLOGIN` + `REVOKE USAGE ON SCHEMA bulk` → rechazo HTTP ≥ 500 → restauración → reintento `202` con `1` fila en `bulk.batch_jobs` sin duplicados).
   - **Outage real de conectividad PostgreSQL vía proxy TCP descartable** hacia el contenedor PostgreSQL 17 del runner: `/health/readiness/reads` `200 READY` → interrupción efectiva de sockets TCP → `/health/readiness/reads` `503 DATABASE_UNAVAILABLE` y `POST /importaciones` `503 SERVICIO_NO_DISPONIBLE` → restauración de conectividad y `/health/readiness/reads` `200 READY` → recuperación con el mismo `X-Correlation-Id` (`202`) → persistencia única de `batch_jobs`, `file_manifests` y `outbox` → consumo `APPLIED`/`DUPLICATE` sin duplicación comercial.
   - Plantillas CSV/XLSX, roundtrip real CSV y roundtrip real XLSX (`Plantilla v2` → inserción de fila `ALTA` → reempaquetado ZIP → `POST /importaciones` → `CatalogBulkService` → persistencia en `catalog.products`), exportación CSV y exportación XLSX con validación estructurada de workbook (`EXPORT_HEADERS` y `'=CMD` en fila `EXP-FORMULA-1`), aislamiento por propietario (404), upgrade `0001–0008` con datos preexistentes y rollback DDL transaccional.
4. **Performance reproducible (`apps/bulk-svc/test/bulk-performance-suite.e2e-spec.ts`, 1 prueba Vitest con 11 benchmarks):** ejecutó 11 mediciones sobre PostgreSQL 17 descartable y Supabase Storage local con 0 fallos; respecto a la regresión histórica `c=8`, se declara **`SIN BASELINE COMPARABLE`** al haber cambiado infraestructura y ambiente.

El transporte asíncrono utilizado en CI entrega mensajes en proceso al consumidor real de Catalog; no homologa Azure Service Bus, APIM real, G7 institucional ni G5/Marketplace.

## 2. Estado Git y PRs

| Repo | PR | Resultado / SHA | Estado comprobado |
|---|---|---|---|
| Frontend | [#93](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/93) | merge `e322808d868bb89e2c645a1b069eb12728296d9f`; HEAD `8665ce65086bb456573f82e8146f941bb50eb617` | MERGED normal |
| Frontend | [#97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/97) | HEAD `f26864bb2b20c5abd693fb415f392ed6110e317b` | OPEN Ready for Review (`FRONTEND_READY_NOT_MERGED` por política de no despliegue en `master`) |
| Backend Catalog H5 | [#262](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/262) | merge `c73ed61c533a21787d1dab22aa79cd83ff77da14` | MERGED normal |
| Backend Bulk V3/H5 | [#271](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/271) | merge `133a051acf187e0a75c074e38aa284a8ea226250`; HEAD `af5a6b4e0e7f4cc7a5d32fcf3694d19cb6db9660` | MERGED normal; flags apagados |
| Backend Catalog Retry V4/V2 | [#273](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/273) | merge `49bab9e2075819d922c63b06fcc6fc6ac16ce703`; HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204` | MERGED normal |
| Backend E2E/Storage/Seguridad | [#274](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/274) | merge `daf4882b7dc6895c6601a1f4af209ec92c8215b0`; HEAD `e3ae66ebebcaa6aed78340a6cc003dbaaf09b3bb` | MERGED normal; CI runs `45501578837` y `45501578656` SUCCESS |
| Backend Cierre Integral | [#283](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/283) | merge `fdd0b59e6e8251cae0a5d4b4652c99af58206b2c`; HEAD `a2cf59de5b97682514effd512e42038fe304ca59` | MERGED normal; CI `45556286013`, `45556285868` y `45556285879` PASS |
| Backend Auditoría Final | [#285](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/285) | merge `ce57c5effc1ab63549d64ab5b25204bab4fa7b6e`; HEAD `06ef20b44dc409da4a36ad2deddd8013679b3ad9` | MERGED normal; CI `45560095170`, `45560095278`, `45560095370`, `45560095167`, `45560095225` PASS |
| Backend Outage PG Real | [#287](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/287) | merge `75d5687eeb1fc18b50b7ce1d20404e822618934a`; HEAD `e4db2842bc367f489ce12c60022923b8a7d0c5d1` | MERGED normal; CI `45563675826`, `45563675882`, `45563675985`, `45563675800`, `45563675795` PASS |
| Docs | [#144](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/144) | merge `79e4e130bcf5d6db81fda058ad670ee65f8b21e1` | MERGED normal |
| Docs Auditoría Final | [#146](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/146) | merge `5c23a5c8b7ed9b25c9ae85b6cd36d4a3c6f405cc`; HEAD `7baee4b649928012eb3b08235ffff6c8e0d61b39` | MERGED normal |
| Docs Cierre Final | `trabajo/castilla/docs-bulk-h5-final-cierre` | Registro final de #146, #287 y `run-45563675826` | PR correctivo mínimo |

## 3. Matriz de guía MK-001 (BUL-B01–B08 y BUL-F01–F06)

### Bulk Backend BUL-B01–B08

| ID | Requisito exacto | Implementación | Prueba | SHA probado | Resultado | Estado de integración / Pendiente operativo |
|---|---|---|---|---|---|---|
| BUL-B01 | Plantillas CSV/XLSX contractuales, MIME/headers y roundtrip | `apps/bulk-svc/src/bulk-svc.controller.ts`, `apps/bulk-svc/src/domain/bulk-template-v2.ts` | `bulk-recovery-files-migrations.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | Final: `06ef20b44dc409da4a36ad2deddd8013679b3ad9` / `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `91dbf0a7` / `c7ddd7ed`) | PASS (CSV/XLSX/roundtrip real XLSX/400 PDF) | Implementado y probado en CI descartable; pendiente despliegue |
| BUL-B02 | Admisión durable, persistencia transaccional y rollback ante error | `apps/bulk-svc/src/bulk-import.service.ts`, `apps/bulk-svc/src/persistence/bulk.repository.ts` | `bulk-recovery-files-migrations.e2e-spec.ts` (upgrade + rollback DDL + Storage 503 + acceso PG + outage real PG) | Final: `e4db2842bc367f489ce12c60022923b8a7d0c5d1` (previo: `06ef20b44dc409da4a36ad2deddd8013679b3ad9`, histórico: `91dbf0a7`) | PASS | Implementado y probado en PostgreSQL 17; pendiente despliegue |
| BUL-B03 | Idempotencia, propietario, correlación y replay sin duplicar | `apps/bulk-svc/src/persistence/bulk.repository.ts` | `bulk-catalog-retry.e2e-spec.ts` + `bulk-postgres.gateway.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` + proxy outage PG | Final: `e4db2842bc367f489ce12c60022923b8a7d0c5d1` / `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `e3ae66eb` / `91dbf0a7`) | PASS (14/14 + 7/7 + browser + outage PG) | Implementado y probado en CI; pendiente G7/APIM real |
| BUL-B04 | Estado por fila/dominio y aplicación de resultado del owner | `apps/bulk-svc/src/persistence/bulk.repository.ts` | `bulk-catalog-retry.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | Final: `06ef20b44dc409da4a36ad2deddd8013679b3ad9` / `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `91dbf0a7` / `c7ddd7ed`) | PASS | Probado en entrega local Catalog; no homologa Service Bus real |
| BUL-B05 | Reanudación selectiva (`BULK_RETRY_V1`), concurrencia y causación | `apps/bulk-svc/src/bulk-svc.controller.ts`, `bulk.repository.ts` | `bulk-catalog-retry.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | Final: `06ef20b44dc409da4a36ad2deddd8013679b3ad9` / `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `91dbf0a7` / `c7ddd7ed`) | PASS (V4/V2 + STALE + UI) | Probado localmente para Catalog; falta Azure Service Bus real |
| BUL-B06 | Reportes y exportaciones durables CSV/XLSX, bytes, fórmula CSV y auth | `apps/bulk-svc/src/bulk-export.service.ts`, `bulk-export-format.ts`, `bulk-storage.service.ts` | `bulk-recovery-files-migrations.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | Final: `06ef20b44dc409da4a36ad2deddd8013679b3ad9` / `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `91dbf0a7` / `c7ddd7ed`) | PASS (bytes, `'=CMD`, workbook XLSX, reporte obligatorio, 404, 503) | Implementado y probado con Storage local CLI 3.4.0; pendiente Storage/despliegue |
| BUL-B07 | Claim-check V3 privado, SHA-256, tamaño y auth `catalog-svc` | `apps/bulk-svc/src/bulk-content.service.ts`, `bulk-service-bearer.guard.ts` | `bulk-catalog-retry.e2e-spec.ts` + `bulk-recovery-files-migrations.e2e-spec.ts` | Final: `06ef20b44dc409da4a36ad2deddd8013679b3ad9` (histórico: `e3ae66eb` / `91dbf0a7`) | PASS (401/403/404, corrupto, malformado) | Probado con JWT local; pendiente grants G7 e ingress privado real |
| BUL-B08 | Mantener R02/R03/R10/R14 bloqueados sin consumidores inventados | `apps/bulk-svc/src/*` (gates y flags preservados) | Verificación de contrato y flags desactivados | Final: `06ef20b44dc409da4a36ad2deddd8013679b3ad9` (histórico: `91dbf0a7`) | PASS | Bloqueado correctamente por contrato H5; no es brecha de código |

### Bulk Frontend BUL-F01–F06

| ID | Requisito exacto | Implementación | Prueba | SHA probado | Resultado | Estado de integración / Pendiente operativo |
|---|---|---|---|---|---|---|
| BUL-F01 | Adaptador HTTP real (`VITE_DATA_MODE=api`) sin fallback silencioso | `src/features/bulk/adapters/httpBulkRepository.ts` | `tests/bulk-http-real.spec.ts` vía `bulk-browser-real.e2e-spec.ts` + `test:unit:bulk` (98/98) | Final: `f26864bb2b20c5abd693fb415f392ed6110e317b` / `06ef20b44dc409da4a36ad2deddd8013679b3ad9` (histórico: `c7ddd7ed` / `91dbf0a7`) | PASS | Integrado contra Gateway+Bulk+Catalog reales en CI; pendiente merge/deploy Vercel |
| BUL-F02 | Validación UX de archivo, revisión y accesibilidad 1440 px | `src/features/bulk/pages/BulkUploadPage.tsx`, `BulkReviewPage.tsx` | `tests/bulk-http-real.spec.ts` (archivo `.txt` bloqueado, Tab/focus, overflow=false) | Final: `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `c7ddd7ed`) | PASS | Completo y probado en Chromium 1440 px |
| BUL-F03 | Una intención, bloqueo doble clic y conciliación ambigua | `src/features/bulk/context/BulkUploadContext.tsx`, `hooks/useBulkAdmissionRecovery.ts` | `tests/bulk-http-real.spec.ts` (`dblclick` -> 1 POST; socket drop -> `por-correlacion`) | Final: `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `c7ddd7ed`) | PASS | Completo y probado contra Gateway+Bulk reales |
| BUL-F04 | Polling, estados por fila/dominio, recuperación tras refresh | `src/features/bulk/pages/BulkProgressPage.tsx`, `BulkResultPage.tsx` | `tests/bulk-http-real.spec.ts` (`page.reload()` en progreso y resultado) | Final: `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `c7ddd7ed`) | PASS | Completo y probado en Chromium |
| BUL-F05 | Reanudación solo con elegibilidad backend y persistencia de intento | `src/features/bulk/pages/BulkResultPage.tsx`, `utils/bulkResumeIntent.ts` | `tests/bulk-http-real.spec.ts` (rechazo Catalog -> `Reanudar` -> recarga -> V2 `Completado`) | Final: `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `c7ddd7ed`) | PASS | Completo y probado contra Catalog V4/V2 real |
| BUL-F06 | Descargas Blob reales (plantillas/reportes/exportaciones) y auth 401/403/404 | `src/features/bulk/pages/BulkDownloadsPage.tsx`, `BulkResultPage.tsx`, `ExportJobPanel.tsx` | `tests/bulk-http-real.spec.ts` (plantillas CSV/XLSX, reporte obligatorio, exportaciones CSV/XLSX, `owner-b` 404, `forbidden` 403, `anonymous`) | Final: `f26864bb2b20c5abd693fb415f392ed6110e317b` (histórico: `c7ddd7ed`) | PASS | Completo y probado en Chromium; pendiente despliegue Vercel |

## 4. Pruebas reproducibles ejecutadas en este cierre

| Ejecución / Suite | SHA Backend / Frontend | Resultado | Evidencia |
|---|---|---|---|
| `npm run typecheck`, `npm run lint`, `npm run test:unit:bulk` (Frontend) | Frontend `5c799f7` → `f26864bb` | PASS (98/98 unitarias Bulk; `typecheck` y `lint` PASS) | PR [#97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/97) |
| `MK-001 Bulk E2E Integral` (`bulk-browser-real` + `bulk-recovery-files-migrations` + `bulk-performance-suite` + `typecheck` + `build:bulk-svc`) | Backend PR #285 `06ef20b4` (merge ref `82079eb0`, merge `master` `ce57c5ef`) + Frontend fijado `f26864bb` | **PASS** (2m43s; **6/6 tests Vitest** y **2/2 tests Playwright**, 0 fallos, 0 omitidos) | [run `45560095170`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45560095170), artefactos en `evidencias/mk001-bulk/run-45560095170/` |
| `MK-001 Bulk E2E Integral` (incluye prueba separada de outage real de conectividad PostgreSQL por proxy TCP) | Backend PR #287 `e4db2842` (merge ref `63d23eb8`, merge `master` `75d5687e`) + Frontend fijado `f26864bb` | **PASS** (2m35s; **7/7 tests Vitest** y **2/2 tests Playwright**, 0 fallos, 0 omitidos) | [run `45563675826`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45563675826), artefactos en `evidencias/mk001-bulk/run-45563675826/` |
| `Integración Bulk-Catalog Retry` (PostgreSQL 17 + Storage CLI 3.4.0) | Backend PR #285 `06ef20b4` | **PASS** (1m52s) | [run `45560095370`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45560095370) |

## 5. Performance definitiva (`run 45560095170`, `bulk-performance-suite.json`)

Medida sobre PostgreSQL 17 descartable y Supabase Storage local (CLI 3.4.0) en GitHub Actions (`82079eb0` / `06ef20b4`), con warmup previo y 0 fallos/timeouts:

| Operación | Concurrencia | Total | Fallos | Throughput (req/s) | p50 (ms) | p95 (ms) | p99 (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|
| `admission_csv_c1` | 1 | 20 | 0 | 17.01 | 53.01 | 84.21 | 112.18 |
| `admission_csv_c8` | 8 | 40 | 0 | 36.99 | 205.11 | 272.32 | 286.11 |
| `admission_csv_c32` | 32 | 64 | 0 | 46.24 | 600.93 | 876.56 | 913.08 |
| `admission_xlsx_c1` | 1 | 4 | 0 | 21.18 | 46.26 | 52.72 | 52.72 |
| `admission_xlsx_c8` | 8 | 32 | 0 | 51.73 | 145.64 | 184.34 | 202.20 |
| `admission_large_csv_500rows_c1` | 1 | 5 | 0 | 4.61 | 210.21 | 247.42 | 247.42 |
| `get_batch_c8` | 8 | 40 | 0 | 395.48 | 18.88 | 27.42 | 30.10 |
| `get_correlation_c8` | 8 | 40 | 0 | 788.82 | 9.74 | 11.46 | 12.98 |
| `replay_idempotent_c8` | 8 | 24 | 0 | 125.27 | 60.54 | 80.16 | 89.90 |
| `retry_reanudar_replay_c8` | 8 | 16 | 0 | 236.64 | 19.38 | 51.12 | 51.12 |
| `export_csv_e2e_c1` | 1 | 3 | 0 | 5.86 | 170.61 | 172.27 | 172.27 |

**Estado respecto a la regresión histórica `c=8`:** **`SIN BASELINE COMPARABLE`**. Las mediciones anteriores provenían de un entorno distinto y no existe un baseline equivalente ejecutado bajo la misma infraestructura (PostgreSQL 17 descartable + Supabase Storage local CLI 3.4.0 en GitHub Actions). En consecuencia, el crecimiento de throughput entre `c=1` (17.01 req/s), `c=8` (36.99 req/s) y `c=32` (46.24 req/s) se registra únicamente como **medición absoluta reproducible en entorno CI descartable** y no constituye demostración de resolución de la regresión histórica `c=8`.

## 6. Estado operativo y bloqueos exclusivamente operativos

| Condición | Estado |
|---|---|
| Código completo Bulk MK-001 | `CODE_COMPLETE` |
| Pruebas integrales CI descartables | `TESTED_DISPOSABLE_CI` (PASS en `45560095170` y `45563675826`) |
| Backend | `BACKEND_MERGED` (PR #285 merge `ce57c5ef`, PR #287 merge `75d5687e`) |
| Despliegue (Vercel / Azure / Supabase compartido) | `NOT_DEPLOYED` (prohibición operativa vigente) |
| Supabase compartido modificado | NO |
| Flags compartidos/productivos activados | NO |
| Homologación externa (Service Bus Azure / APIM / G7 institucional / G5) | Pendiente operativo fuera de este alcance |

- **Frontend PR #97:** permanece sin merge a `master` (`FRONTEND_READY_NOT_MERGED`) porque `vercel.json` habilita despliegues de producción en `master`.
- **Owner Azure/G7/DB:** la habilitación de Service Bus Basic, grants G7 reales, aplicación controlada de migraciones en Supabase compartido y despliegue quedan pendientes de ventana operativa autorizada.
