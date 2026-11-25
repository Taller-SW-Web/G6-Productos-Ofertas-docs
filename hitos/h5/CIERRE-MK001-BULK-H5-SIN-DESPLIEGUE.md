# Cierre MK-001 Bulk H5 sin despliegue

**Corte:** 25/11/2026 (America/Lima)
**Alcance:** Bulk B01–B08 y F01–F06, integración requerida de Catalog H5, E2E en navegador real (Chromium), recuperación P1, matriz de archivos/exportaciones, migraciones, performance reproducible y documentación.
**Estado del corte:** `CODE_COMPLETE / TESTED_DISPOSABLE_CI / NOT_DEPLOYED`.
- Backend PR [#274](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/274) quedó fusionado en `master` (`daf4882b7dc6895c6601a1f4af209ec92c8215b0`, HEAD `e3ae66ebebcaa6aed78340a6cc003dbaaf09b3bb`), y `master` avanzó hasta `33b206c7c7dbee9ccb5401c20b7536e40e0d43d3`.
- Backend PR [#283](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/283) (HEAD `a2cf59de5b97682514effd512e42038fe304ca59`) quedó fusionado en `master` mediante merge normal tras pasar `Integración continua (CI)` ([run `45556286013`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45556286013)), `MK-001 Bulk E2E Integral` ([run `45556285868`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45556285868), 2m34s, **PASS**, y [run `45555080185`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45555080185), 2m32s, **PASS**) e `Integración Bulk-Catalog Retry` ([run `45556285879`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45556285879), 2m8s, **PASS**) contra PostgreSQL 17 descartable, Supabase Storage local (CLI 3.4.0), API Gateway real, Bulk real, Catalog real y Chromium sobre Frontend `c7ddd7ed0f2379e25028dd8a8c5875c5f3027b84`.
- Frontend PR [#97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/97) (HEAD `c7ddd7ed0f2379e25028dd8a8c5875c5f3027b84`) pasó toda su CI incluyendo `validate` ([run `45555457872`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/45555457872)), fue publicado bajo protección `vercel.json` (`deploymentEnabled: { "**": false, "master": true }`, verificado con `vercel ls`: cero despliegues Preview) y permanece Ready for Review sin fusionar a `master` para evitar despliegue automático de producción (`FRONTEND_READY_NOT_MERGED`).
**Despliegue:** NO REALIZADO.

## 1. Resumen ejecutivo

Se completó el cierre integral de **MK-001 Bulk H5** sin ejecutar despliegues ni modificar entornos compartidos:

1. **Recuperación Frontend (`494c88c` → `c7ddd7ed`):** se recuperó el commit local no publicado en `trabajo/castilla/bulk-h5-integracion-real`, se verificó la protección de `vercel.json` y `vercel ls`, y se amplió el harness aislado (`tests/harness/bulk-http-real.tsx`) con verificación de manifiesto de capacidades (`verifyBulkHomologationManifest`) y los 21 escenarios obligatorios de navegador en `tests/bulk-http-real.spec.ts`.
2. **Orquestador E2E en navegador real (`apps/bulk-svc/test/bulk-browser-real.e2e-spec.ts`):** conecta Chromium → React Bulk (`VITE_DATA_MODE=api`) → API Gateway real (JWKS local + JWT RS256) → Bulk real → PostgreSQL 17 descartable / Supabase Storage local → Catalog real → resultado V2 → UI, incluyendo fault injection de admisión ambigua (respuesta perdida tras commit), conciliación por correlación sin segundo `POST`, rechazo transitorio de Catalog, elegibilidad calculada por Backend, reanudación exclusiva de Catalog, persistencia de retry en recarga, descarga de reporte y exportaciones reales CSV/XLSX, aislamiento 401/403/404 y accesibilidad a 1440 px.
3. **Recuperación P1, archivos y migraciones (`apps/bulk-svc/test/bulk-recovery-files-migrations.e2e-spec.ts`):** acredita reinicio real de instancia Nest (`app1.close()` → `app2.init()`) con Outbox pendiente, reinicio de consumidor Catalog sin duplicación comercial, indisponibilidad temporal y recuperación de Storage (503 → 200), claim-check malformado, identidad contradictoria, plantillas CSV/XLSX y roundtrip, protección contra inyección de fórmulas CSV (`'=CMD`, `'+SUM`), aislamiento por propietario (404), upgrade `0001–0008` con datos preexistentes y rollback DDL transaccional.
4. **Performance reproducible (`apps/bulk-svc/test/bulk-performance-suite.e2e-spec.ts`):** ejecutó 11 benchmarks (admisión CSV c=1/8/32, XLSX c=1/8, CSV 500 filas, GET lote, GET correlación, replay idempotente, retry `reanudar` y exportación CSV) con cero fallos.

El transporte asíncrono utilizado en CI entrega mensajes en proceso al consumidor real de Catalog; no homologa Azure Service Bus, APIM real, G7 institucional ni G5/Marketplace.

## 2. Estado Git y PRs

| Repo | PR | Resultado / SHA | Estado comprobado |
|---|---|---|---|
| Frontend | [#93](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/93) | merge `e322808d868bb89e2c645a1b069eb12728296d9f`; HEAD `8665ce65086bb456573f82e8146f941bb50eb617` | MERGED normal |
| Frontend | [#97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/97) | HEAD `c7ddd7ed0f2379e25028dd8a8c5875c5f3027b84` | OPEN Ready for Review (`FRONTEND_READY_NOT_MERGED` por política de no despliegue en `master`) |
| Backend Catalog H5 | [#262](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/262) | merge `c73ed61c533a21787d1dab22aa79cd83ff77da14` | MERGED normal |
| Backend Bulk V3/H5 | [#271](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/271) | merge `133a051acf187e0a75c074e38aa284a8ea226250`; HEAD `af5a6b4e0e7f4cc7a5d32fcf3694d19cb6db9660` | MERGED normal; flags apagados |
| Backend Catalog Retry V4/V2 | [#273](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/273) | merge `49bab9e2075819d922c63b06fcc6fc6ac16ce703`; HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204` | MERGED normal |
| Backend E2E/Storage/Seguridad | [#274](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/274) | merge `daf4882b7dc6895c6601a1f4af209ec92c8215b0`; HEAD `e3ae66ebebcaa6aed78340a6cc003dbaaf09b3bb` | MERGED normal; CI runs `45501578837` y `45501578656` SUCCESS |
| Backend Cierre Integral | [#283](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/283) | merge `fdd0b59e`; HEAD `a2cf59de5b97682514effd512e42038fe304ca59` (desde `master` `33b206c7c7dbee9ccb5401c20b7536e40e0d43d3`) | MERGED normal; CI `45556286013`, `45556285868` y `45556285879` PASS |
| Docs | [#144](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/144) | rama `trabajo/castilla/bulk-h5-certificacion-final` | Actualizado con evidencia integral |

## 3. Matriz de guía MK-001 (BUL-B01–B08 y BUL-F01–F06)

### Bulk Backend BUL-B01–B08

| ID | Requisito exacto | Implementación | Prueba | SHA probado | Resultado | Estado de integración / Pendiente operativo |
|---|---|---|---|---|---|---|
| BUL-B01 | Plantillas CSV/XLSX contractuales, MIME/headers y roundtrip | `apps/bulk-svc/src/bulk-svc.controller.ts`, `apps/bulk-svc/src/domain/bulk-template-v2.ts` | `bulk-recovery-files-migrations.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | `91dbf0a7` / `c7ddd7ed` | PASS (CSV/XLSX/roundtrip/400 PDF) | Implementado y probado en CI descartable; pendiente despliegue |
| BUL-B02 | Admisión durable, persistencia transaccional y rollback ante error | `apps/bulk-svc/src/bulk-import.service.ts`, `apps/bulk-svc/src/persistence/bulk.repository.ts` | `bulk-recovery-files-migrations.e2e-spec.ts` (upgrade + rollback DDL + Storage 503) | `91dbf0a7` | PASS | Implementado y probado en PostgreSQL 17; pendiente despliegue |
| BUL-B03 | Idempotencia, propietario, correlación y replay sin duplicar | `apps/bulk-svc/src/persistence/bulk.repository.ts` | `bulk-catalog-retry.e2e-spec.ts` + `bulk-postgres.gateway.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | `e3ae66eb` / `91dbf0a7` | PASS (14/14 + 7/7 + browser) | Implementado y probado en CI; pendiente G7/APIM real |
| BUL-B04 | Estado por fila/dominio y aplicación de resultado del owner | `apps/bulk-svc/src/persistence/bulk.repository.ts` | `bulk-catalog-retry.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | `91dbf0a7` / `c7ddd7ed` | PASS | Probado en entrega local Catalog; no homologa Service Bus real |
| BUL-B05 | Reanudación selectiva (`BULK_RETRY_V1`), concurrencia y causación | `apps/bulk-svc/src/bulk-svc.controller.ts`, `bulk.repository.ts` | `bulk-catalog-retry.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | `91dbf0a7` / `c7ddd7ed` | PASS (V4/V2 + STALE + UI) | Probado localmente para Catalog; falta Azure Service Bus real |
| BUL-B06 | Reportes y exportaciones durables CSV/XLSX, bytes, fórmula CSV y auth | `apps/bulk-svc/src/bulk-export.service.ts`, `bulk-export-format.ts`, `bulk-storage.service.ts` | `bulk-recovery-files-migrations.e2e-spec.ts` + `bulk-browser-real.e2e-spec.ts` | `91dbf0a7` / `c7ddd7ed` | PASS (bytes, `'=CMD`, 404 ajeno/ausente, 503) | Implementado y probado con Storage local CLI 3.4.0; pendiente Storage/despliegue |
| BUL-B07 | Claim-check V3 privado, SHA-256, tamaño y auth `catalog-svc` | `apps/bulk-svc/src/bulk-content.service.ts`, `bulk-service-bearer.guard.ts` | `bulk-catalog-retry.e2e-spec.ts` + `bulk-recovery-files-migrations.e2e-spec.ts` | `e3ae66eb` / `91dbf0a7` | PASS (401/403/404, corrupto, malformado) | Probado con JWT local; pendiente grants G7 e ingress privado real |
| BUL-B08 | Mantener R02/R03/R10/R14 bloqueados sin consumidores inventados | `apps/bulk-svc/src/*` (gates y flags preservados) | Verificación de contrato y flags desactivados | `91dbf0a7` | PASS | Bloqueado correctamente por contrato H5; no es brecha de código |

### Bulk Frontend BUL-F01–F06

| ID | Requisito exacto | Implementación | Prueba | SHA probado | Resultado | Estado de integración / Pendiente operativo |
|---|---|---|---|---|---|---|
| BUL-F01 | Adaptador HTTP real (`VITE_DATA_MODE=api`) sin fallback silencioso | `src/features/bulk/adapters/httpBulkRepository.ts` | `tests/bulk-http-real.spec.ts` vía `bulk-browser-real.e2e-spec.ts` + `test:unit:bulk` (98/98) | `c7ddd7ed` / `91dbf0a7` | PASS | Integrado contra Gateway+Bulk+Catalog reales en CI; pendiente merge/deploy Vercel |
| BUL-F02 | Validación UX de archivo, revisión y accesibilidad 1440 px | `src/features/bulk/pages/BulkUploadPage.tsx`, `BulkReviewPage.tsx` | `tests/bulk-http-real.spec.ts` (archivo `.txt` bloqueado, Tab/focus, overflow=false) | `c7ddd7ed` | PASS | Completo y probado en Chromium 1440 px |
| BUL-F03 | Una intención, bloqueo doble clic y conciliación ambigua | `src/features/bulk/context/BulkUploadContext.tsx`, `hooks/useBulkAdmissionRecovery.ts` | `tests/bulk-http-real.spec.ts` (`dblclick` -> 1 POST; socket drop -> `por-correlacion`) | `c7ddd7ed` | PASS | Completo y probado contra Gateway+Bulk reales |
| BUL-F04 | Polling, estados por fila/dominio, recuperación tras refresh | `src/features/bulk/pages/BulkProgressPage.tsx`, `BulkResultPage.tsx` | `tests/bulk-http-real.spec.ts` (`page.reload()` en progreso y resultado) | `c7ddd7ed` | PASS | Completo y probado en Chromium |
| BUL-F05 | Reanudación solo con elegibilidad backend y persistencia de intento | `src/features/bulk/pages/BulkResultPage.tsx`, `utils/bulkResumeIntent.ts` | `tests/bulk-http-real.spec.ts` (rechazo Catalog -> `Reanudar` -> recarga -> V2 `Completado`) | `c7ddd7ed` | PASS | Completo y probado contra Catalog V4/V2 real |
| BUL-F06 | Descargas Blob reales (plantillas/reportes/exportaciones) y auth 401/403/404 | `src/features/bulk/pages/BulkDownloadsPage.tsx`, `BulkResultPage.tsx`, `ExportJobPanel.tsx` | `tests/bulk-http-real.spec.ts` (plantillas CSV/XLSX, exportaciones CSV/XLSX, `owner-b` 404, `forbidden` 403, `anonymous`) | `c7ddd7ed` | PASS | Completo y probado en Chromium; pendiente despliegue Vercel |

## 4. Pruebas reproducibles ejecutadas en este cierre

| Ejecución / Suite | SHA Backend / Frontend | Resultado | Evidencia |
|---|---|---|---|
| `npm run typecheck`, `npm run lint`, `npm run test:unit:bulk` (Frontend) | Frontend `5c799f7` → `c7ddd7ed` | PASS (98/98 unitarias Bulk) | PR [#97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/97) |
| `MK-001 Bulk E2E Integral` (`bulk-browser-real` + `bulk-recovery-files-migrations` + `bulk-performance-suite` + `typecheck` + `build:bulk-svc`) | Backend `91dbf0a7` + Frontend `c7ddd7ed` | **PASS** (2m32s, 0 fallos, 0 omitidos) | [run `45555080185`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45555080185), artefactos en `evidencias/mk001-bulk/run-45555080185/` |
| `Integración Bulk-Catalog Retry` (PostgreSQL 17 + Storage CLI 3.4.0) | Backend #274 `e3ae66eb` (merge `daf4882b`) | PASS (8/8 tests, 14/14 escenarios, 0 omitidos) | `run-45497460957` y `45501578656` |

## 5. Performance definitiva (`run 45555080185`, `bulk-performance-suite.json`)

Medida sobre PostgreSQL 17 descartable y Supabase Storage local en GitHub Actions (`91dbf0a7`), con warmup previo y 0 fallos/timeouts:

| Operación | Concurrencia | Total | Fallos | Throughput (req/s) | p50 (ms) | p95 (ms) | p99 (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|
| `admission_csv_c1` | 1 | 20 | 0 | 21.32 | 35.72 | 62.30 | 195.44 |
| `admission_csv_c8` | 8 | 40 | 0 | 41.12 | 142.24 | 412.91 | 415.82 |
| `admission_csv_c32` | 32 | 64 | 0 | 66.07 | 430.00 | 640.67 | 689.13 |
| `admission_xlsx_c1` | 1 | 4 | 0 | 31.69 | 29.79 | 36.31 | 36.31 |
| `admission_xlsx_c8` | 8 | 32 | 0 | 77.01 | 97.04 | 135.28 | 145.40 |
| `admission_large_csv_500rows_c1` | 1 | 5 | 0 | 7.12 | 139.98 | 148.65 | 148.65 |
| `get_batch_c8` | 8 | 40 | 0 | 488.38 | 15.32 | 23.03 | 25.23 |
| `get_correlation_c8` | 8 | 40 | 0 | 981.89 | 8.12 | 8.68 | 10.47 |
| `replay_idempotent_c8` | 8 | 24 | 0 | 176.53 | 44.49 | 58.25 | 64.21 |
| `retry_reanudar_replay_c8` | 8 | 16 | 0 | 357.83 | 12.57 | 34.21 | 34.21 |
| `export_csv_e2e_c1` | 1 | 3 | 0 | 6.06 | 164.18 | 166.66 | 166.66 |

Observación sobre concurrencia 8: en la medición actual con PostgreSQL 17 y Storage local, el throughput de admisión CSV escala de 21.32 req/s (c=1) a 41.12 req/s (c=8) y 66.07 req/s (c=32), con 0 fallos, sin reproducirse caída de throughput en c=8.

## 6. Estado operativo y bloqueos exclusivamente operativos

| Condición | Estado |
|---|---|
| Código completo Bulk MK-001 | `CODE_COMPLETE` |
| Pruebas integrales CI descartables | `TESTED_DISPOSABLE_CI` (PASS en `45555080185`) |
| Despliegue (Vercel / Azure / Supabase compartido) | `NOT_DEPLOYED` (prohibición operativa vigente) |
| Supabase compartido modificado | NO |
| Flags compartidos/productivos activados | NO |
| Homologación externa (Service Bus Azure / APIM / G7 institucional / G5) | Pendiente operativo fuera de este alcance |

- **Frontend PR #97:** permanece sin merge a `master` (`FRONTEND_READY_NOT_MERGED`) porque `vercel.json` habilita despliegues de producción en `master`.
- **Owner Azure/G7/DB:** la habilitación de Service Bus Basic, grants G7 reales, aplicación controlada de migraciones en Supabase compartido y despliegue quedan pendientes de ventana operativa autorizada.
