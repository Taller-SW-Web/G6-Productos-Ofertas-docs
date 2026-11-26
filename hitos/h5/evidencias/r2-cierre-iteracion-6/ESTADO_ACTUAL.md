# Estado actual — G6 H5 R2 (Cierre Iteración 6)

- **Rama:** `trabajo/castilla/h5-integral-r2`
- **Dictamen local:** `LOCAL_G6_GO=FALSE` (Playwright excluido por instrucción expresa; quedan 6/158 operaciones fallidas en `certify-158-endpoints.mjs` y fallo de seed en `certify-19-messaging-flows.mjs`).
- **HEAD de partida:**
  - `backend`: `fcf88765ef7ead5ab5c75dcde6c50173e6f35dfd`
  - `frontend`: `b278c5f851d09743d4f8e708c5e83359f6a16ac4`
  - `docs`: `ef3335b47ee55d92a3fcde91da4952b0eb1214d4`

## Qué se implementó y reparó

1. **Bulk `[106]` (`crearImportacionGeneralProductos`) y `[109]` (`reanudarImportacionGeneral`) / `catalog-sku-context` (`[152]`, `[153]`):**
   - `backend/apps/bulk-svc/src/persistence/bulk.repository.ts`: en `INVENTARIO`, cuando `earlierSkuReceipts.length === 0` (H5 no emite R11 de Catalog hacia Bulk) y `adjustmentComplete === true`, `stepStatus` transiciona a `'COMPLETED'`. Verificado en runtime: `[106]` pasó (`CATALOGO=COMPLETED`, `INVENTARIO=COMPLETED`, `PRICING=COMPLETED`).
   - `backend/apps/catalog-svc/src/catalog-bulk.service.ts`: normalizado `(priorResult.payload.command_attempt_id ?? null) !== previous.commandAttemptId`.
   - `backend/apps/catalog-svc/src/catalog-sku-context.controller.ts`: `@Controller(['api/v1/productos/skus', 'productos/skus'])` para compatibilidad con rutas internas y OpenAPI; `[152]` y `[153]` pasaron en runtime.
   - `backend/apps/pricing-svc/src/messaging/bulk-price-apply.service.ts`: agregado helper `safePositiveCents()` para rechazar por fila montos `'0.00'` sin lanzar `PriceRuleError` no capturado sobre todo el lote.
2. **Seguridad y sanitización (`taxonomy-svc`, tests unitarios H5):**
   - `backend/apps/taxonomy-svc/src/database.ts`: eliminado `error` crudo del log `taxonomy.database.query_failed` para preservar sanitización de credenciales/SQL.
   - `backend/vitest.config.ts`: `process.env.NODE_ENV ??= 'test'` para ejecución consistente en Windows.
   - Alineados los 25 archivos de pruebas unitarias que fallaban (de 40 fallos iniciales a **2,907 passed** en corrida completa + **91/91 passed** en la re-ejecución focalizada de `promotions-config.spec.ts`, `bulk-export.service.spec.ts` e `historical-openapi.spec.ts`).
3. **Certificadores y laboratorio aislado:**
   - `frontend/tests/e2e-real/startRealStackAndVite.mjs`: `/__test/pg-query` ahora usa `psql -X -t -A` mediante `pgQuery(wrapped, ["-t", "-A"])`, resolviendo el error `pg is not defined` / formato `psql`, y reenvía errores de `catalog-svc` al log del stack.
   - `backend/tests/h5/certify-158-endpoints.mjs`: separados `promoIdDeact` y `couponIdDeact` para no desactivar el cupón compartido con `[148]`; corregidas aserciones SQL de `[128]` (`inventory.kardex.operation_id`), `[149]` (`promotions.coupon_command_receipts` por `operation_id` y `intention = 'RESTAURAR'`) y `[114]`; agregadas pruebas negativas reales para `GET` parametrizados y prohibido `NOT_RUN` en `overallPass`. Resultado: **152/158 PASS**.
   - `backend/tests/h5/certify-19-messaging-flows.mjs`: agregada validación estricta de seed (`requireSeedResult`), PNG válido 1x1, `activation_checks.state = 'COMPLETED'`, DTO válido de `crearPromocion` sobre producto activo en `N01` y consultas SQL ligadas a IDs de operación/producto/SKU.
