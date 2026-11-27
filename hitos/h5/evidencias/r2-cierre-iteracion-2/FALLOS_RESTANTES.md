# Fallos Restantes — G6 H5 R2 (Priorizados)

1. **P0 — `inventory.reservations.order_id` casteo `text = uuid` en `certify-158-endpoints.mjs` + manejo de error en `/__test/pg-query`**
   - **Archivo y línea:** `backend/tests/h5/certify-158-endpoints.mjs:1058` y `frontend/tests/e2e-real/startRealStackAndVite.mjs:1263`
   - **Causa confirmada:** `inventory.reservations.order_id` es tipo `text`, pero `verifyPgPersistence()` consultó `WHERE order_id = '${targetOrder}'::uuid`, lanzando `PSQL_FAILED: operator does not exist: text = uuid` y derribando `startRealStackAndVite.mjs` al no tener `try/catch` en `/__test/pg-query`.
   - **Corrección propuesta:** Quitar `::uuid` en `WHERE order_id = '${targetOrder}'` en `certify-158-endpoints.mjs` y envolver `/__test/pg-query` en `try/catch` devolviendo HTTP `400/500` sin matar el proceso del stack.

2. **P0 — `evaluarPromociones` clasificada como mutadora en `verifyPgPersistence()`**
   - **Archivo y línea:** `backend/tests/h5/certify-158-endpoints.mjs:965-973`
   - **Causa confirmada:** `evaluarPromociones` (`POST /api/v1/promociones/evaluar`) es consulta de solo lectura sin mutación, pero no está en `READ_ONLY_POST_OPS`, marcándose `NOT_VERIFIED` (y por ende `FAIL`).
   - **Corrección propuesta:** Agregar `"evaluarPromociones"` a `READ_ONLY_POST_OPS`.

3. **P0 — Suite `certify-19-messaging-flows.mjs` usa `http.request` contra `g5SeedOrigin` HTTPS**
   - **Archivo y línea:** `backend/tests/h5/certify-19-messaging-flows.mjs:39-67`
   - **Causa confirmada:** `g5SeedOrigin` corre sobre `https://127.0.0.1:...`, por lo que `http.request` falló con `ECONNRESET`.
   - **Corrección propuesta:** Soportar `https` con `rejectUnauthorized: false` en `httpCall` de `certify-19-messaging-flows.mjs` y re-ejecutar.

4. **P0 — Carga de `tests/h5/service-bus-19-queues.e2e-spec.ts` en Vitest**
   - **Archivo y línea:** `backend/tests/h5/service-bus-19-queues.e2e-spec.ts:64`
   - **Causa observada:** `TypeError: Cannot read properties of undefined (reading 'config')` al ejecutar con `vitest.config.e2e.ts`.
   - **Corrección propuesta:** Revisar el import/configuración de Nest/Vitest en `service-bus-19-queues.e2e-spec.ts` para aislar qué módulo importado accede a `.config` en carga.

5. **P1 — 39 pruebas unitarias fallidas en `npm test` (principalmente `promotions-svc` y suites `PUBLIC_READ_ONLY`)**
   - **Archivo:** `backend/apps/promotions-svc/src/infrastructure/config/promotions-config.spec.ts` y specs asociados.
   - **Causa observada:** Expectativas históricas de `PUBLIC_READ_ONLY` / `RABBITMQ_URL` en servicios fuera de `catalog-svc` e `inventory-svc`.
   - **Corrección propuesta:** Alinear esas specs con H5 igual que se hizo en `catalog-svc` e `inventory-svc`.

6. **P1 — Playwright E2E Frontend (`16` pruebas)**
   - **Causa:** Excluido por instrucción expresa en este ciclo (`LOCAL_G6_GO = FALSE`).
