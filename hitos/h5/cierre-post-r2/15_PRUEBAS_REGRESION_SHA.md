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
| PostgreSQL 17 descartable | NOT_RUN: Docker Desktop no pudo iniciar |
| Backend typecheck/build:all/lint/unitarias/E2E/19 loops | NOT_RUN; no se adjudican cifras R2 históricas |
| Frontend typecheck/build/lint/unitarias/Playwright API | NOT_RUN; no hubo delta runtime frontend |
| APIM-T01..T08, RL-01..RL-06 | NOT_RUN: sin instancia/candidato APIM |

Una primera corrida de unittest falló por fixture sin los nuevos parámetros y resolución `az` de Python en Windows; se corrigió el fixture y se pasó la plantilla compilada mediante `APIM_ARM_TEMPLATE`. Otra corrida encontró constantes de procedencia antiguas; se actualizaron a los HEAD vigentes y la tercera corrida pasó 28/28. No se ocultaron esos fallos de desarrollo.
