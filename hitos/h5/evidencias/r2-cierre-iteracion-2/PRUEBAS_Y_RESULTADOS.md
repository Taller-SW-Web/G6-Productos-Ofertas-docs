# Pruebas y Resultados — G6 H5 R2 (Cierre Iteración 2)

## 1. Compilación, Typecheck, Lint y Unitarias (`backend`)
- `npm run typecheck` (`tsc --build --noEmit`): **PASS** (exit code 0)
- `npm run build:all` (`tsc --build`): **PASS** (exit code 0)
- `npm run lint` (`oxlint apps/`): **PASS** (exit code 0)
- `npx nest build bulk-svc`: **PASS** (exit code 0)
- `npm test` (`vitest run`, ejecutado antes del ajuste de `bulk-service-bus.ts` pero con los fixes de `catalog-svc` y `inventory-svc` ya aplicados): **2028 passed | 39 failed | 13 skipped** en 252 archivos (`151 passed | 101 failed` archivos; incluye archivos de tests vacíos/e2e filtrados o suites obsoletas `PUBLIC_READ_ONLY` en otros servicios como `promotions-svc`).

## 2. Certificación de 158 Operaciones (`tests/h5/certify-158-endpoints.mjs`)
- **Iteración 1:** falló en seed `[109]` (`CATALOG_BULK_RESULT_V2_ENABLED` / `CatalogBulkIdentity` cache compartido con `CatalogMasterClient`), corregido luego moviendo el seed antes de `crearProducto`.
- **Iteración 2 (última ejecución):** **FAIL** (exit code 1)
  - `executed`: `158` (`18 PASS`, `140 FAIL`)
  - `[1..13]` y `[15..19]`: **PASS** (incluyendo seguridad, funcional, negativo y persistencia SQL real).
  - `[14] evaluarPromociones`: `http=200`, `functional=PASS`, `negative=PASS(400)`, `persistence=NOT_VERIFIED` (faltó incluir en `READ_ONLY_POST_OPS`).
  - `[20] solicitarReserva`: `http=202`, `functional=PASS`, `persistence=FAIL` — `/__test/pg-query` ejecutó `WHERE order_id = '...'::uuid` sobre `inventory.reservations.order_id` (`text`), provocando `PSQL_FAILED: operator does not exist: text = uuid` no capturado en `startRealStackAndVite.mjs` y derribando el stack.
  - `[21..158]`: **FAIL** por `ECONNREFUSED` tras la caída del stack en `[20]`.
  - `authChecks`: `6/6 PASS`.
  - `n01ConsumeStatus`: `"COMPLETED"`.

## 3. Mensajería 19 recorridos y topología
- `npx vitest run --config ./vitest.config.e2e.ts tests/h5/service-bus-19-queues.e2e-spec.ts`: **FAIL** al cargar (`TypeError: Cannot read properties of undefined (reading 'config')` en línea 64).
- `node tests/h5/certify-19-messaging-flows.mjs`: **FAIL** en polling inicial (`PG_QUERY_FAILED status=0 body=read ECONNRESET` por llamar con `http` a `g5SeedOrigin` `https`).

## 4. Exclusiones
- **Playwright:** No ejecutado por instrucción expresa.
- **Azure Service Bus real:** No ejecutado.
