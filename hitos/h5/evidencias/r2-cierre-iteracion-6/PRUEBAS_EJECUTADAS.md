# Pruebas ejecutadas — G6 H5 R2 (Cierre Iteración 6)

- **Entorno:** Windows local, stack aislado Docker PostgreSQL + bus aislado + G7 stub + `api-gateway` + 8 microservicios NestJS compilados (`dist/`).
- **Playwright:** **NO EJECUTADO** (excluido por instrucción expresa).
- **Estado de certificación local:** `LOCAL_G6_GO=FALSE`.

| Comando | Resultado | Detalle observado |
|---|---|---|
| `npm run typecheck` | PASS | `tsc --build --noEmit` sin errores |
| `npm run build:all` | PASS | `tsc --build` sin errores |
| `npm run lint` | PASS | `oxlint apps/` — 0 errores, 24 warnings sobre 882 archivos |
| `npx vitest run --reporter=json --outputFile=tests/h5/unit-tests-iter1-pass.json` | PARTIAL (2,907 PASS / 8 FAIL / 114 SKIP) | De 40 fallos iniciales bajó a 8 (1 aserción en `promotions-config.spec.ts` + 7 timeouts por carga paralela de CPU) |
| `npx vitest run apps/promotions-svc/src/infrastructure/config/promotions-config.spec.ts apps/bulk-svc/src/bulk-export.service.spec.ts apps/catalog-svc/src/historical-openapi.spec.ts` | PASS (91/91) | Corrida focalizada post-fix de los 3 archivos restantes |
| `node tests/h5/certify-158-endpoints.mjs` (Iteración 2) | FAIL (152/158 PASS, 6 FAIL) | `n01ConsumeStatus=COMPLETED`, `bulkTerminal=COMPLETED`, `authChecksPass=true`. Fallos: `[30]`, `[45]`, `[100]`, `[109]`, `[114]`, `[158]` |
| `node tests/h5/certify-19-messaging-flows.mjs` (Iteración 2) | FAIL (seed) | Abortó en seed: `ACTIVATION_CHECKS_NOT_COMPLETED` para `admProdId` (`f621928e-338b-4f17-b293-70cbe6ca57d0`) |

## Evidencias adjuntas

- `CERTIFICACION_158.json` y `CERTIFICACION_158.csv`
- `UNIT_TESTS.json`
- `FALLOS_PENDIENTES.md`
- `../../MATRIZ_158_OPERACIONES_H5_R2.csv` (actualizada con los resultados reales de Iteración 2)
