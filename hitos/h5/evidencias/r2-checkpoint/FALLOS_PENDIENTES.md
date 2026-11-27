# Fallos Pendientes — Checkpoint G6 H5 R2

Ordenados por prioridad (P0 bloqueantes primero).

---

## P0-1. `[106]` `crearImportacionGeneralProductos` — Paso `INVENTARIO` queda en `PENDING` (`bulkTerminal = "PROCESSING"`)
- **Servicio afectado:** `inventory-svc` / `bulk-svc`
- **Estado observado en reporte:** `HTTP 202`, `functional = FUNCTIONAL_PASS`, `asyncTerminal = FAIL`, `persistence = FAIL`. En `bulkSnap`: `CATALOGO = COMPLETED`, `PRICING = COMPLETED`, `INVENTARIO = PENDING`.
- **Error exacto en `certify-stack.log`:**
  `[inventory-svc stderr] [inventory-sb-consumer] InventoryMessageError: FEATURE_DISABLED` en `InventoryCommandService.process` (`dist/apps/inventory-svc/inbox/inventory-command.service.js:57`).
- **Causa conocida / hipótesis:** En `backend/apps/inventory-svc/src/inbox/inventory-command.service.ts` (líneas 74-80 y `processBulkStockAdjust` / configuración de feature flags), `inventory-svc` rechaza o deshabilita el mensaje por feature flag (`FEATURE_DISABLED`) o código desfasado en `dist/`. Requiere revisar qué flag controla `BULK_STOCK_ADJUST` / `SKU_DEACTIVATED` en `inventory.config.ts` y `startRealStackAndVite.mjs`.
- **Archivos y líneas relevantes:**
  - `backend/apps/inventory-svc/src/inbox/inventory-command.service.ts:57-80`
  - `backend/apps/inventory-svc/src/messaging/service-bus-consumer.ts:162,287`
  - `frontend/tests/e2e-real/startRealStackAndVite.mjs:1685`

## P0-2. `[109]` `reanudarImportacionGeneral` — `HTTP 409 RETRY_NOT_ELIGIBLE`
- **Servicio afectado:** `bulk-svc`
- **Estado observado en reporte:** `POST /api/v1/carga-masiva/productos/importaciones/{batchId}/reanudar` devolvió `HTTP 409` (`functional = FAIL`, `persistence = FAIL`).
- **Causa conocida / hipótesis:** La función `evaluateCatalogRetryEligibility` en `backend/apps/bulk-svc/src/persistence/bulk.repository.ts` (líneas 2240-2440) exige que `batch.status === 'COMPLETED'`, `BULK_RETRY_CATALOG_V1_ENABLED === 'true'`, paso `CATALOGO` en `FAILED`, `row.appliedDomains.length === 0`, y consistencia estricta en `domainAttempts` (`previousAttemptId`, `commandAttemptId`, `businessOperationId`, `receiptMessageId`) y `fileManifests`/`content_documents`. Alguna de estas precondiciones no coincide con el estado sembrado por `seedBulkMarkRetryable` en `startRealStackAndVite.mjs` o el lote aún no había cerrado como `COMPLETED`.
- **Archivos y líneas relevantes:**
  - `backend/apps/bulk-svc/src/persistence/bulk.repository.ts:2240-2440`

## P0-3. `[32]` `reintentarPreparacionProducto` — `HTTP 500 ERROR_INTERNO`
- **Servicio afectado:** `catalog-svc`
- **Estado observado en reporte:** `POST /api/v1/productos/{productoId}/preparacion/reintentar` devolvió `HTTP 500` (`functional = FAIL`, `persistence = FAIL`), mientras que `[40] reintentarPreparacionVariante` sí devolvió `200/202 PASS`.
- **Causa conocida / hipótesis:** En `backend/apps/catalog-svc/src/catalog-mutation.service.ts:906-965` (`retry()`), cuando `dependency === 'PRICING'` para producto simple, el seed `seedCatalogPendingPreparation` (`frontend/tests/e2e-real/startRealStackAndVite.mjs:1632-1645`) insertó `catalog.outbox` con payload mínimo `{"sku":"..."}`, faltando posiblemente campos esperados en la reconstrucción del comando o registro asociado (p.ej. `sku_physical_profiles` o `outbox_delivery`) al ejecutar `retry()`.
- **Archivos y líneas relevantes:**
  - `backend/apps/catalog-svc/src/catalog-mutation.service.ts:906-965`
  - `frontend/tests/e2e-real/startRealStackAndVite.mjs:1632-1645`

## P0-4. `[148]` `admitirConsumoCuponH5` — Admisión `202` termina en `REJECTED` (`COUPON_NOT_ELIGIBLE`)
- **Servicio afectado:** `promotions-svc` (y fixture en `certify-158-endpoints.mjs`)
- **Estado observado en reporte:** `POST /api/v1/cupones/consumos` devolvió `HTTP 202` (`functional = FUNCTIONAL_PASS`), pero `asyncTerminal = FAIL`, `persistence = FAIL`.
- **Causa conocida / hipótesis:** En `backend/tests/h5/certify-158-endpoints.mjs:1190`, `[148]` reutiliza `ctx.customerRef`, el cual ya había consumido el cupón en la prueba seed N01 (`n01ConsumeStatus = "COMPLETED"`), violando elegibilidad/límite por cliente en `promotions-svc/src/coupons/coupon-transactions.ts:210-219` / `authoritative-coupon-evidence.ts:141-171`.
- **Archivos y líneas relevantes:**
  - `backend/tests/h5/certify-158-endpoints.mjs:1190`
  - `backend/apps/promotions-svc/src/coupons/coupon-transactions.ts:210-219`
  - `backend/apps/promotions-svc/src/coupons/authoritative-coupon-evidence.ts:141-171`

## P1-5. Suite Playwright E2E Frontend (`3 PASS / 13 FAIL` en última corrida previa)
- **Archivo:** `frontend/test-results/.last-run.json` (`2026-11-26 06:09:53`)
- **Detalle:** `13` casos fallidos en la corrida previa a los arreglos de backend (`eight-modules.real.spec.ts`, `http-contracts.real.spec.ts`, `transversal-flows.real.spec.ts`). Pendiente de re-ejecución y diagnóstico individual tras cerrar los 4 fallos P0 de backend.

## P1-6. Suite aislada 19 colas Service Bus (`service-bus-19-queues.e2e-spec.ts`)
- **Detalle:** Pendiente de ejecución para certificar cobertura R01–R18 y N01 en conjunto (DLQ, duplicados, 256KB, TTL).

## P2-7. Limpieza de trazas temporales de depuración (`console.error`)
- **Detalle:** Quedan trazas temporales `[catalog-bulk]`, `[bulk-export]`, `[bulk-result-consumer]`, `[bulk-repo]`, `[coupon-h5-ops]`, etc. en archivos de backend para remover antes de la entrega final.
