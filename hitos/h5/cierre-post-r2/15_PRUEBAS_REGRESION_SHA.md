# Pruebas ejecutadas y límites

Base de código Backend `097dac1b`, Docs `5f30802`, Frontend `2c6ad93`. Los resultados siguientes pertenecen al candidato local antes de commit; no al backend desplegado. Duraciones solo cuando hubo medición de CLI.

| Comando / prueba | Resultado |
|---|---|
| `az bicep build --file ops/azure/apim/main.bicep` | PASS, 8.46 s; advertencias lint no bloqueantes |
| `python -m unittest discover ops/azure/apim/tests -q` con `APIM_ARM_TEMPLATE` | PASS, 29 tests, 1.65 s (última corrida) |
| `verify-arm-template.py --mode candidate` con Docs/Gateway HEAD | PASS, 145 políticas candidatas y cinco rutas privadas excluidas |
| `verify-arm-template.py` en modo efectivo predeterminado | BLOCKED esperado: `NO_SECURITY_PROFILE`, `NO_ENABLED_PROVIDERS_OR_ALLOWLIST`, `NO_AUTHORIZED_OPERATIONS` |
| `git diff --check` Backend | PASS |
| `GET /health` Gateway desplegado | HTTP 200, solo smoke de bajo impacto |
| `GET /api/v1/productos?pagina=1&tamanio=1` anónimo | HTTP 401, `X-Correlation-Id` registrado en baseline |
| PostgreSQL 17 descartable, SQL R10 up/rollback | PASS; 0002 aplicado dos veces, 4 destinos positivos, 3 rechazos negativos, rollback bloqueado con Bulk y exitoso tras retirar solo la fila descartable |
| `npm test -- apps/inventory-svc/src/messaging/service-bus.spec.ts` | PASS, 41/41 |
| `npm run typecheck` | PASS |
| `npm run build:all` | PASS |
| `npm run lint` | PASS con advertencias existentes, sin errores |
| `npm test` | PASS, 2943 aprobadas y 101 SKIP; 250 archivos PASS y 2 SKIP; duración 58.02 s |
| `npm run test:e2e` inicial | FAIL, 47 archivos PASS, 1 FAIL y 38 SKIP; 1068 pruebas PASS y 402 SKIP, duración 268.33 s. Único fallo `ENOENT` por ruta relativa Docs no montada en worktree |
| `G6_DOCS_ROOT=<checkout Docs> npm run test:e2e -- apps/inventory-svc/test/inventory-h5.postgres.e2e-spec.ts` | PASS, 24/24 en PG17 descartable, duración 19.88 s |
| `G6_DOCS_ROOT=<checkout Docs> npm run test:e2e` | FAIL, 43 archivos PASS, 4 FAIL y 39 SKIP; 981 pruebas PASS, 3 FAIL y 486 SKIP, duración 207.91 s. Fallaron suites Catalog PostgreSQL y Gateway por subprocess/timeout/respuestas 503 en ejecución paralela. |
| Rerun focalizado de las cuatro suites fallidas | PASS individual: Gateway observability 6/6, Gateway public read only 7/7, Catalog runtime PostgreSQL 5 PASS y 1 SKIP, Catalog data002 1/1. La suite completa sigue FAIL. |
| Frontend `npm run typecheck` | PASS sobre master sin delta runtime |
| Frontend `npm run lint` | PASS sobre master sin delta runtime |
| Frontend `VITE_DATA_MODE=api npm run build` | PASS, advertencia de importación dinámica inefectiva; `npm run build` sin variable falla por el control explícito del repositorio |
| Frontend `npm test` | PASS, 35/35 sobre master sin delta runtime |
| Frontend Playwright API | NOT_RUN; no hubo delta runtime frontend |
| APIM-T01..T08, RL-01..RL-06 | NOT_RUN: sin instancia/candidato APIM |

Una primera corrida de unittest falló por fixture sin los nuevos parámetros y resolución `az` de Python en Windows; se corrigió el fixture y se pasó la plantilla compilada mediante `APIM_ARM_TEMPLATE`. Otra corrida encontró constantes de procedencia antiguas; se actualizaron a los HEAD vigentes y la tercera corrida pasó 28/28. No se ocultaron esos fallos de desarrollo.
