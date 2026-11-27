# Pruebas Unitarias y Compilación (`backend`)

- **Fecha:** 2026-11-26
- **Entorno:** `Node v24.3.0`, `npm 11.4.2`

## Comandos ejecutados
- `npm run typecheck` (`tsc --build --noEmit`): **PASS** (exit code 0)
- `npm run build:all` (`tsc --build`): **PASS** (exit code 0)
- `npm run lint` (`oxlint apps/`): **PASS** (exit code 0, 23 warnings, 0 errores)
- `npx vitest run --config ./vitest.config.e2e.ts tests/h5/service-bus-19-queues.e2e-spec.ts`: **PASS** (`3/3`)
- `npm test` (`vitest run`): **FAIL** (`2876 passed | 40 failed | 114 skipped` de `3030` tests en `252` archivos: `225 passed | 25 failed | 2 skipped`).

## Clasificación de las 40 pruebas unitarias fallidas
- **0 errores de colección/carga** (resuelto mediante `resolve.alias.vitest` en `vitest.config.ts`).
- **40 fallos reales de aserción** concentrados principalmente en expectativas H4 (`PUBLIC_READ_ONLY`, `RABBITMQ_URL`) en `promotions-svc`, `pricing-svc`, `combos-svc`, `taxonomy-svc`, `bulk-svc` y `catalog-svc`, más `api-gateway/test/contract-parity.spec.ts` y `taxonomy-svc/src/database.spec.ts`.
