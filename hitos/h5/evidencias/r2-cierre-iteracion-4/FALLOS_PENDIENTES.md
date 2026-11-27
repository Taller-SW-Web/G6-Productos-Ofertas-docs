# Fallos Pendientes — G6 H5 R2 (Al cierre de Iteración 2)

1. **P0 — `[106]` y `[109]` Bulk V2 (`bulkTerminal = "PROCESSING"`, `INVENTARIO = "PROCESSING"` y `retryBatchId` en `qCat`)**
   - **Archivo:** `backend/tests/h5/certify-158-endpoints.mjs:734` y flujo `bulk-svc` -> `inventory-svc` / `catalog-svc`
   - **Observado:** `crearImportacionGeneralProductos` (`[106]`) y `reanudarImportacionGeneral` (`[109]`) recibieron `202 QUEUED`, pero `INVENTARIO` no cerró a `COMPLETED` dentro del polling de `certify-158-endpoints.mjs`, y `qCat` mostró un mensaje de retry pendiente al final de la corrida.

2. **P0 — `[114]` `actualizarUmbralGlobal` (`pers=FAIL`)**
   - **Archivo:** `backend/tests/h5/certify-158-endpoints.mjs:1100` y `frontend/tests/e2e-real/startRealStackAndVite.mjs:1265`
   - **Observado:** `/__test/pg-query` reportó `Unexpected non-whitespace character after JSON at position 77` al parsear `value` (`jsonb`) de `inventory.inventory_config` en `psql`.

3. **P0 — `[128]` `conciliarVentaOffline` (`HTTP 200 COMPLETED`, `pers=FAIL`)**
   - **Archivo:** `backend/tests/h5/certify-158-endpoints.mjs:1095`
   - **Observado:** La operación HTTP y el stock (`on_hand: 29`) funcionaron correctamente, pero `verifyPgPersistence()` consultó `inventory.kardex WHERE reference_id = ...`, columna inexistente (`column "reference_id" does not exist`).

4. **P0 — `[148]` y `[149]` Cupones H5 (`COUPON_NOT_ELIGIBLE` y `pers=FAIL`)**
   - **Archivo:** `backend/tests/h5/certify-158-endpoints.mjs:508,1138`
   - **Observado:** `[148]` devolvió `REJECTED` (`COUPON_NOT_ELIGIBLE`) tras haber consumido previamente en el mismo flujo/promoción; `[149]` falló `pers=FAIL` por comprobar sobre `ctx.orderId` cuyo estado en `coupon_command_receipts` o consulta requiere ajuste.

5. **P0 — `[152]`, `[153]` y `[158]` Contexto SKU y Readiness de `catalog-svc`**
   - **Archivo:** `backend/tests/h5/certify-158-endpoints.mjs` / `apps/catalog-svc`
   - **Observado:** `[152]` y `[153]` devolvieron `404 PRODUCTO_NO_ENCONTRADO` para `SKU-CERT1-...` (producto sembrado directamente en SQL sin proyección comercial completa o sin variante); `[158] gatewayReadiness` devolvió `503` con `catalog-svc: "not_ready"` al final de la corrida (mientras `qCat` tenía mensaje pendiente).

6. **P0 — Suite funcional `certify-19-messaging-flows.mjs`**
   - **Archivo:** `backend/tests/h5/certify-19-messaging-flows.mjs:165-173`
   - **Observado:** `POST /api/v1/productos` no devolvió `product_id` (`admProdId = undefined`), provocando HTTP 500 controlado en `/__test/pg-query` (`invalid input syntax for type uuid: "undefined"`).

7. **P1 — 40 pruebas unitarias fallidas en `npm test`**
   - **Observado:** Expectativas H4 obsoletas (`PUBLIC_READ_ONLY`, `RABBITMQ_URL`, `contract-parity.spec.ts`, `database.spec.ts`) en servicios fuera de `promotions-config.spec.ts` / `inventory-svc`.

8. **P1 — Playwright E2E Frontend (`16` pruebas)**
   - **Observado:** Excluido por instrucción expresa en este ciclo (`LOCAL_G6_GO = FALSE`).
