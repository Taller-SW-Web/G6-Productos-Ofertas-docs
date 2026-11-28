# Diagnóstico Consolidado de Defectos, Auditoría Frontend y Brechas H5

Este documento mantiene la trazabilidad consolidada de Hito 5 en `G6-Productos-Ofertas-docs`, diferenciando explícitamente los niveles de evidencia: `PASS / MOCK`, `PASS / STATIC`, `PASS / ISOLATED (código productivo)`, `PASS / ISOLATED (PostgreSQL descartable)`, `FAIL / LAB_AZURE histórico`, `NOT_RUN` y `STANDBY`.

## 1. Distribución de PRs (todos en Draft, cero colisión con `#310` y `#103`)

- **Docs [#154](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/154)** (`poma-hito-5-pruebas-v2`): Evidencias históricas intactas, traza ACA de Axel, matrices y trazabilidad consolidada.
- **Backend [#313](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/313)** (`poma-hito-5-pruebas-v2`): Harness ejecutable Postman/Newman (`tests/h5/postman/`, `H11`–`H25`), helper seguro PG17 (`H26`), suite complementaria Catalog consolidada respecto a `#310` e integración local real `Gateway -> Catalog -> Pricing -> Inventory` (`H27`).
- **Backend [#314](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/314)** (`trabajo/poma/h5-apim-errores-autenticacion`, SHA `6a5da558`): Corrección independiente de **Defecto A** (`H28`, APIM 401 RFC 7807 exclusivo para `validate-jwt`).
- **Backend [#315](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/315)** (`trabajo/poma/h5-bulk-autenticacion`, SHA `2a484ba0`): Corrección independiente de **Defecto C** (`H29`, `BulkUserBearerGuard` coherente con JWT humano G7).
- **Frontend (`G6-Productos-Ofertas-frontend`, SHA `2c6ad931b8dd48e4a4fe883a18ac899fb48b0c81`):** Sin PR (verificación funcional completa sin defectos; evidencia reproducible en §4).

---

## 2. Estado diferenciado de defectos, validaciones y brechas

| Tema | Causa raíz / Alcance | Reproducción y verificación local | Nivel de evidencia actual |
|---|---|---|---|
| **Defecto A** (`PM-004`/`004B` APIM 401, `H28`) | `<validate-jwt>` en `operation-secured.xml` sin `<on-error>` RFC 7807 en `api.xml`. | Parche en `api.xml` + prueba de políticas efectivas heredadas (`<on-error><base /></on-error>`), `correlationId` idéntico en header/body y preservación de `403`/`429` en `test_apim_artifacts.py`: **`27/27 PASS`** — **PR #314** (`6a5da558`). | `PASS / STATIC` (histórico: `FAIL / LAB_AZURE histórico`; revalidación live: `STANDBY`). |
| **Defecto B** (`PM-012` Inventory 400, `H18`/`H27`) | `disponibilidad.service.ts` exige `location_id` UUID con `>1` ubicación. | Reproducidos los 4 escenarios tanto en harness mock (`runner.test.mjs`) como contra **`inventory-svc` productivo real + PG17** (`catalog-h5-newman-real.postgres.e2e-spec.ts`) — **PR #313**. | `PASS / MOCK` + `PASS / ISOLATED (PostgreSQL descartable)` (revalidación live: `STANDBY`). |
| **Defecto C** (`PM-030`/`031` Bulk 401, `H29`) | `BulkUserBearerGuard` exigía `aud === 'api-productos'` en JWT humano `tipo === 'acceso'` (G7 no emite `aud` en perfil humano). | Corregido en `bulk-user-bearer.guard.ts` + test `nbf` futuro corregido (`13/13 PASS`) + regresiones HTTP e2e reales de `PM-030` (`200 text/csv`) y `PM-031` (`404 LOTE_NO_ENCONTRADO`) + `401`/`403` (`4/4 PASS`) — **PR #315** (`2a484ba0`). | `PASS / ISOLATED (código productivo)` (histórico: `FAIL / LAB_AZURE histórico`; revalidación live: `STANDBY`). |
| **Contrato OpenAPI/Ajv (`H24` + `H25`)** | Resolución automática por `(método, ruta, status, Content-Type)` sobre OpenAPI `0.7.0-rc.3` (156 operaciones), validación recursiva y preflight obligatorio en `run-newman.mjs`. | `npm run validate` OK (`STRICT_OFFICIAL`, OpenAPI SHA-256 `a0021cb567c9...`) + **`32/32 PASS`** (`tests/h5/postman`) — **PR #313**. | `PASS / MOCK`. |
| **Equivalencias Catalog H5 (`#310` canónica + `#313` complemento)** | **Backend #310** (`6dd66036`) es la base canónica para los 6 escenarios históricos (`BLOCK-A2`, `BULK-JOINT`, `BULK-CONSUMER-v2`, `TAXONOMY-UPDATES`). | `apps/catalog-svc/test/h5/catalog-h5-equivalence.postgres.e2e-spec.ts` conserva **solo** garantías complementarias no duplicadas (`C1` activación real `BORRADOR -> ACTIVO` tras Pricing+Inventory + fallo ambiguo relay; `C2` rechazo de correlación falsificada + `STALE`; `C3` conflicto de payload en Inbox + bloqueo de destinos deshabilitados): **`3/3 PASS`** con helper seguro `H26` — **PR #313**. | `PASS / ISOLATED (PostgreSQL descartable)`. |
| **Integración local real `Gateway -> Catalog -> Pricing -> Inventory` (`H27`)** | Servicios productivos reales (`api-gateway`, `catalog-svc`, `pricing-svc`, `inventory-svc`) sobre PostgreSQL 17 descartable + JWKS RS256 sintético (`catalog-h5-newman-real.postgres.e2e-spec.ts`). | **Vitest: `3/3 PASS`**. Resultados individuales Newman: **Carpeta 01** (`PM-002`, `PM-003A`, `PM-003B`, `PM-003C`, `PM-003D`): **`5/5 PASS`** (`exitCode=0`); **Carpeta 02** (4 escenarios reales `inventory-svc`): 1 ubicación sin `location_id` **`3/3 PASS`**, multi-ubicación sin `location_id` **`2 PASS / 1 FAIL (400 VALIDACION)`**, multi-ubicación con `location_id` UUID **`3/3 PASS`**, ubicación sin saldo **`2 PASS / 1 FAIL (200 items=[])`**; **Carpeta 00**: `PM-001` **`200 PASS`**, `PM-001B` **`503 FAIL`** preservado honestamente; **Carpeta 09**: `PM-004`, `PM-004B`, `PM-006`, `PM-007A`, `PM-007B`, `PM-008` **`6/6 PASS`**, `PM-005` **`NOT_RUN`** (`PARTIAL_NOT_COMPLETE`, `exitCode=5`). | `PASS / ISOLATED (PostgreSQL descartable)` (casos fuera de estos 4 servicios permanecen `NOT_RUN` / `STANDBY`). |

---

## 3. Consolidación de cobertura Catalog H5 (`Backend #310` vs `Backend #313`)

| Escenario | Base canónica en `Backend #310` (`6dd66036`) | Valor complementario en `Backend #313` |
|---|---|---|
| `BLOCK-A2` | `tests/h5/catalog-bulk-inventory.postgres.e2e-spec.ts` + `apps/inventory-svc/test/inventory.real.integration.spec.ts` | Sin duplicación. |
| `BULK-JOINT` / `BULK-CONSUMER-v2` | `tests/h5/catalog-bulk-inventory.postgres.e2e-spec.ts` | `C3`: Bloqueo preventivo ante destino `g6.bulk.from.catalog` deshabilitado. |
| `TAXONOMY-UPDATES` | `tests/h5/taxonomy-service-bus.postgres.e2e-spec.ts` | `C3`: Conflicto de payload en Inbox (mismo `message_id`, payload distinto) y bloqueo de destino `g6.taxonomy.from.catalog` deshabilitado. |
| `JOINT-01` / `JOINT-01-REGRESSION` | Cobertura parcial en `#310`. | `C1` + `C2`: Activación real `BORRADOR -> ACTIVO` tras Pricing + Inventory, fallo ambiguo en relay, rechazo de `correlation_id` falsificado y estado `TERMINAL` / `STALE`. |

---

## 4. Evidencia reproducible de auditoría Frontend (sin PR en Frontend)

- **Repositorio y commit exacto:** `Taller-SW-Web/G6-Productos-Ofertas-frontend`, rama `poma-hito-5-pruebas-v2`, **SHA `2c6ad931b8dd48e4a4fe883a18ac899fb48b0c81`** (árbol limpio, sin modificaciones).
- **Comando ejecutado:**
  ```powershell
  npm test -- --run
  ```
- **Totales exactos por suite (`0` fallos, `0` skipped):**
  - `test:unit:combos` (incluye autenticación y clientes HTTP): **16 archivos, 239 passed** (`auth.test.ts` 55, `readOnlyClient.test.ts` 17, `authenticatedGatewayClient.test.ts` 9, `publicReads.test.ts` 8, `g7OnlyTransport.spec.ts` 4, `catalogHttpRepository.test.ts` 5, restantes 141).
  - `test:unit:bulk`: **1 archivo, 98 passed** (`tests/bulk.unit.test.ts`).
  - `test:unit:inventory`: **5 archivos, 132 passed**.
  - `test:unit:pricing`: **4 archivos, 166 passed**.
  - `test:unit:taxonomy`: **12 archivos, 111 passed**.
  - `test:release:policy`: **35 passed**.
  - **Total verificado:** **781 pruebas ejecutadas, 781 passed, 0 failed** (`PASS / ISOLATED (código productivo)`).
- **Comportamiento verificado en `src/app/config/authenticatedGatewayClient.ts` y `src/features/catalog/adapters/authenticatedCatalogTransport.ts`:**
  - Ante `401` (`TOKEN_INVALIDO`) en lecturas `GET` (incluyendo descargas de plantilla CSV), el cliente intenta **1 refresco automático** (`refreshAccessToken`) y reintenta una sola vez antes de invalidar sesión.
  - Ante `403` (`SCOPE_INSUFICIENTE`) y `500`/`503`, **preserva la sesión activa** y propaga el error controlado a la UI sin cerrar sesión ni reintentar escrituras mutadoras.
  - **Conclusión:** No existe defecto funcional en Frontend; por ello no se abre un PR vacío en el repositorio Frontend.

---

## 5. Nota histórica `H11` y validaciones reales en `STANDBY`

- Las evidencias históricas del `2026-11-27` y `2026-11-28` en `evidencias/` se preservan **sin modificación** (sus SHA-256 permanecen intactos).
- **Validaciones reales en `STANDBY`:** Re-ejecución de `smoke`/`integration` contra APIM Chile tras despliegue de PRs `#314` y `#315`, ejecución live de `PM-005` (`403`) y `PM-080`/`PM-081`/`PM-082` (tokens M2M reales).
