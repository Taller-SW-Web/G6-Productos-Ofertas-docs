# Certificación Final G6 H5 R2 — Evidencias Definitivas

- **Fecha:** 2026-11-26
- **Rama:** `trabajo/castilla/h5-integral-r2`
- **SHAs certificados:**
  - Backend: `d1ecf2eac77723cec5d6de8a9a999edb7306b400`
  - Frontend: `2f0453c1794f54a403085610d5579c4d82fecf5e`
  - Docs (matrices base): `0466cfa7e0c644484d4bc28700045d915d0be456` (actualizado con estas evidencias y handoff)

## Estados de liberación

- `CODE_AND_LAB_FUNCTIONAL_READY`: **true**
- `LOCAL_G6_GO`: **false** (transporte real Azure Service Bus en `rg-g6-sb-h5-int-fork` / `g6-sb-h5-int-32cdqgbnlk7ow` pendiente de RBAC `Data Sender`/`Data Receiver` por servicio y homologación externa G7)
- `AZURE_G6_GO`: **false** (despliegue y RBAC Azure a cargo de Axel)

## Resolución de los 2 fallos previos en `apps/api-gateway/test/routing.e2e-spec.ts`

Se verificó en worktree temporal sobre el HEAD previo (`d386a3de8994e765ac6fc4bd2a9b1b81a08f4d3a`) que ambos fallos eran preexistentes por expectativas previas a H5:
1. `keeps liveness separate from upstream readiness` (`routing.e2e-spec.ts:739`): esperaba `404` en `GET /health/ready` con upstream lento, pero Gateway H5 expone `/health/ready` (`api-gateway.controller.ts:18`) y devuelve `503`. Actualizado para validar `503` cuando el upstream excede timeout.
2. `preserves local validation/auth errors absent from operation responses (H-01)` (`routing.e2e-spec.ts:753`): esperaba `403 SCOPE_INSUFICIENTE` sin header `Authorization`, pero tras retirar `PUBLIC_READ_ONLY` Gateway exige `401 TOKEN_INVALIDO` sin token y `403 SCOPE_INSUFICIENTE` con JWT válido sin scope (`signed.token({ scope: '' })`). Actualizado para validar ambos (`401` + `403`).

Resultado posterior: **514/514 PASS** en ambas regresiones limpias.

## Comparativa de las dos regresiones integrales limpias

Cada corrida inició en entorno limpio con contenedores PostgreSQL 17 Docker desechables, G7 local RS256/TLS y bus aislado independientes.

| Componente | Regresión 1 (`run1/`) | Regresión 2 (`run2/`) |
|---|---|---|
| Backend `typecheck` | PASS | PASS |
| Backend `build:all` | PASS | PASS |
| Backend `lint` | PASS (0 errores, 24 warnings) | PASS (0 errores, 24 warnings) |
| Backend unitarias (`npm test`) | PASS (`250 passed \| 2 skipped`, `2941 passed \| 101 skipped`) | PASS (`250 passed \| 2 skipped`, `2941 passed \| 101 skipped`)* |
| Gateway paridad contractual | PASS (`2 files`, `10/10`) | PASS (`2 files`, `10/10`) |
| Gateway E2E (`routing`, `g5-h5`, `g7-transversal`, `g7-introspection`, `public-read-only`) | PASS (`5 files`, `541/541`) | PASS (`5 files`, `541/541`) |
| Regresión certificador importación de precios | PASS (`4/4`) | PASS (`4/4`) |
| Bulk PostgreSQL 17 (`run-bulk-postgres17.mjs`) | PASS (`38/38`) | PASS (`38/38`) |
| Inventory PostgreSQL 17 (`inventory-h5.postgres.e2e-spec.ts`) | PASS (`24/24`) | PASS (`24/24`) |
| Certificación HTTP (`certify-158-endpoints.mjs`) | PASS (`158/158`, `[97] PERSISTENCE_PASS` + `ASYNC_TERMINAL_PASS`) | PASS (`158/158`, `[97] PERSISTENCE_PASS` + `ASYNC_TERMINAL_PASS`) |
| Mensajería local + recuperación Pricing (`certify-19-messaging-flows.mjs`) | PASS (`19/19`) | PASS (`19/19`) |
| Frontend `typecheck` | PASS | PASS |
| Frontend `build` (`VITE_DATA_MODE=api`) | PASS | PASS |
| Frontend `lint` | PASS | PASS |
| Frontend unitarias (`npm test`) | PASS (`789/789`) | PASS (`789/789`) |
| Frontend Playwright real (`playwright.real.config.ts`) | PASS (`16/16`) | PASS (`16/16`) |

\* En el primer intento paralelo de `npm test` de Regresión 2 hubo 2 timeouts de 5000ms por contención de CPU (`historical-openapi.spec.ts` y `bulk-export.service.spec.ts`); al re-ejecutar `npm test` sobre el mismo código cerró `2941/2941` (`250 passed | 2 skipped`).

## Inventario de `SKIP` justificados en Backend (`101 skipped`)

- `apps/inventory-svc/test/inventory.real.integration.spec.ts` (`63 skipped` por `INVENTORY_REAL_INTEGRATION=1`):
  - `24` pruebas vigentes (10 Azure Service Bus H5 `outbox_delivery`/Store/Relay + 14 `DashboardService` H01/H02) fueron extraídas a `apps/inventory-svc/test/inventory-h5.postgres.e2e-spec.ts` y ejecutadas en verde (**24/24 PASS** en ambas regresiones).
  - `39` pruebas restantes corresponden a cobertura histórica H4 acoplada a RabbitMQ (`rabbitmq:3.13-management-alpine`) + TLS (`16` raíz, `2` consumer ACK/dedup, `8` motores RabbitMQ/PG, `8` BACK-02 DDL/permisos, `5` DATA-004 scripts SQL).
- Otros `38` casos omitidos en archivos unitarios corresponden a pruebas condicionales históricas documentadas fuera del flujo H5 (ninguna requerida por H5 fue omitida).

## Limitaciones externas (Azure y G7)

1. **Azure Service Bus (Chile Central):** Las 19 colas están validadas en laboratorio local aislado (`certify-19-messaging-flows.mjs` + PostgreSQL 17). Falta que Axel asigne identidades administradas propias por servicio y roles mínimos `Azure Service Bus Data Sender` / `Azure Service Bus Data Receiver` en el scope exacto de cada cola, además de ejecutar las pruebas reales contra el namespace `g6-sb-h5-int-32cdqgbnlk7ow`.
2. **G7 Seguridad:** La seguridad RS256, introspección, refresh/logout y 401/403 están certificadas contra el emisor local RS256/TLS; falta la homologación externa de grants M2M con G7 (p. ej. `combos:leer`, `catalogo:leer` para `inventory-svc`, `carga-masiva:contenidos:leer` para `catalog-svc`).

## Artefactos por corrida

- Corrida 1: `run1/be-*.log`, `run1/gw-*.log`, `run1/bulk-pg17.log`, `run1/bulk-postgres17-result.json`, `run1/inv-pg17.log`, `run1/http-158.log`, `run1/158_ENDPOINTS_CERTIFICATION_REPORT.{json,md}`, `run1/msg-19.log`, `run1/fe-*.log`.
- Corrida 2: `run2/be-*.log`, `run2/gw-*.log`, `run2/bulk-pg17.log`, `run2/bulk-postgres17-result.json`, `run2/inv-pg17.log`, `run2/http-158.log`, `run2/158_ENDPOINTS_CERTIFICATION_REPORT.{json,md}`, `run2/msg-19.log`, `run2/fe-*.log`.
