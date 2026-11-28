# Diagnóstico Consolidado de Defectos, Verificación Frontend y Brechas H5

Este documento consolida la trazabilidad de Hito 5 en `G6-Productos-Ofertas-docs`, diferenciando explícitamente los niveles de evidencia (`PASS / MOCK`, `PASS / STATIC`, `PASS / ISOLATED (código productivo)`, `PASS / ISOLATED (PostgreSQL descartable)`, `FAIL / LAB_AZURE histórico`, `NOT_RUN` y `STANDBY`) y manteniendo separados los resultados Vitest de los casos individuales de Newman.

## 1. Estado definitivo de PRs y ramas

| PR / Repo | Rama | SHA | Estado | Alcance y checks CI |
|---|---|---|---|---|
| **[Backend #310](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/310)** | `trabajo/castilla/h5-modernizacion-integral-ci` | Merge `bed0511` (técnico `6dd6603` / `a5329ff`) | **MERGED** | Base canónica del CI modernizado y de las 6 equivalencias históricas H5. |
| **[Frontend #103](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/103)** | `trabajo/castilla/h5-modernizacion-integral-ci` | Merge `02ada63` | **MERGED** | Modernización de CI y E2E Frontend. |
| **[Backend #314](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/314)** | `trabajo/poma/h5-apim-errores-autenticacion` | `b2f53cc` | **Ready for Review** | **Defecto A (`H28`):** APIM 401 RFC 7807 exclusivo `validate-jwt`. **100% CI verde** (`apim_h5_estatico`, `validate`, `Lint, Typecheck, Test, Build & Smoke Test`, `Gitleaks`, `CodeQL` — runs `46134971759` / `46135899842`). |
| **[Backend #315](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/315)** | `trabajo/poma/h5-bulk-autenticacion` | `e7547f3` | **Ready for Review** | **Defecto C (`H29`):** `BulkUserBearerGuard` admite JWT humano `tipo === 'acceso'` sin `aud` + regresiones HTTP `200`/`404`/`401`/`403`. **100% CI verde** (`Ejecutar pruebas unitarias`, `Comprobar formato del código`, `Probar Bulk R03 y R14`, `bulk_integral_e2e`, `validate`, `Gitleaks`, `CodeQL` — run `46135245432`). |
| **[Backend #313](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/313)** | `poma-hito-5-pruebas-v2` | `6dbbf1ce` | **Draft** | Harness Postman/Newman (`H11`–`H35`), resolución Gitleaks `H30`, conciliación auxiliar `H31`, procedencia/precompilación `H32`, runner PG17 automatizado con roles runtime `H33`, aserciones específicas Inventory `H34`, integración al CI (`newman_h5_integracion`) y conservación de evidencias `H35`. |
| **[Docs #154](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/154)** | `poma-hito-5-pruebas-v2` | HEAD de esta rama | **Draft** | Evidencias históricas intactas, evidencias sanitizadas `H35` (`evidencias/local-pg17-real-h27-2026-11-28/`), matrices y diagnóstico consolidado. |
| **Frontend** (sin PR) | `poma-hito-5-pruebas-v2` | `02ada63` | Sin cambios | Verificación acotada de descarga CSV con Bulk `#315` y suites unitarias/Playwright sin defectos (§4). |

---

## 2. Estado diferenciado de defectos y cierres (`H24`–`H35`)

| Tema | Implementación y verificación | Nivel de evidencia actual |
|---|---|---|
| **H30 (Gitleaks `#313`)** | Artefacto `gitleaks-84dfdda04e9c99b287086223b3b8a35c83b53e24` (run `46128359846`) identificado como JWT sintético de prueba en `tests/h5/postman/tests/sanitizer.test.mjs:10` (regla `jwt`, fingerprint `:jwt:15656`, sin credencial real); sustituido por generación dinámica en runtime sin desactivar Gitleaks ni añadir allowlists. | `PASS / ISOLATED (código productivo)` |
| **Defecto A (`H28`, `#314`)** | Parche en `ops/azure/apim/policies/api.xml` + `27/27` estáticas + job CI `apim_h5_estatico` (compilación Bicep → ARM + verificación ARM completa) en verde. | `PASS / STATIC` (live: `STANDBY`) |
| **Defecto B (`H18`/`H27`/`H34`, `#313`)** | 4 escenarios reales contra `inventory-svc` con rol runtime `inventory_app` sobre PG17 descartable, verificando `PM-010`, `PM-011` y `PM-012` individualmente (HTTP 200 single-loc, HTTP 400 `VALIDACION` multi-loc sin `location_id`, HTTP 200 con UUID explícito, HTTP 200 `items=[]` sin saldo). | `PASS / MOCK` + `PASS / ISOLATED (PostgreSQL descartable)` (live: `STANDBY`) |
| **Defecto C (`H29`, `#315`)** | `BulkUserBearerGuard` corregido + `bulk-svc.http.spec.ts` alineado + `13/13` unit + `4/4` HTTP e2e + CI completo verde. | `PASS / ISOLATED (código productivo)` (live: `STANDBY`) |
| **H24 + H25 + H31 + H32 (`#313`)** | Resolución automática OpenAPI `0.7.0-rc.3` (Ajv), contadores separados para violaciones contractuales auxiliares (`auxiliaryContractViolations`, `pmPass`, `pmFail`) conciliados en JSON/JUnit/MD/manifest, procedencia Git HEAD estricta en `STRICT_OFFICIAL` y compilación previa de esquemas antes de enviar solicitudes HTTP: **`34/34 PASS`** y `[VALIDATE] OK [STRICT_OFFICIAL]`. | `PASS / MOCK` |
| **H33 + H27 + H35 (`#313` + `#154`)** | Runner automatizado `tests/h5/run-catalog-h5-newman-postgres.mjs` (imagen PG17 fijada de master, roles runtime `catalog_app`/`pricing_app`/`inventory_app`, 5 regresiones negativas del helper en `disposable-pg17.helper.spec.ts`, verificación anti-omisión `6/6 PASS / 0 skipped`, limpieza en `finally`). Evidencias sanitizadas conservadas en [`evidencias/local-pg17-real-h27-2026-11-28/`](./evidencias/local-pg17-real-h27-2026-11-28/README.md). | `PASS / ISOLATED (PostgreSQL descartable)` |

### Resultados exactos `H27` (Vitest vs Newman — sin sumar corridas como casos únicos)

- **Vitest:** **`6/6 PASS`** (`3/3` complemento Catalog H5 + `3/3` bloques `H27`/`H34`).
- **Newman (7 corridas locales sobre `Gateway -> Catalog -> Pricing -> Inventory`):** **22 casos `PASS`**, **3 `FAIL` controlados** (`PM-012` multi-ubicación sin `location_id`, `PM-012` ubicación sin saldo, `PM-001B` readiness `503` por servicios fuera de alcance) y **1 `NOT_RUN`** (`PM-005`). Los perfiles completos `smoke` e `integration` sobre los 8 microservicios permanecen pendientes hasta contar con entorno autorizado (`STANDBY`).

---

## 3. Consolidación Catalog H5 (`Backend #310` MERGED vs `Backend #313`)

| Escenario | Base canónica en `Backend #310` (MERGED `bed0511`) | Valor complementario conservado en `Backend #313` |
|---|---|---|
| `BLOCK-A2` | `tests/h5/catalog-bulk-inventory.postgres.e2e-spec.ts` + `apps/inventory-svc/test/inventory.real.integration.spec.ts` | Sin duplicación. |
| `BULK-JOINT` / `BULK-CONSUMER-v2` | `tests/h5/catalog-bulk-inventory.postgres.e2e-spec.ts` | `C3`: Bloqueo preventivo ante destino `g6.bulk.from.catalog` deshabilitado. |
| `TAXONOMY-UPDATES` | `tests/h5/taxonomy-service-bus.postgres.e2e-spec.ts` | `C3`: Conflicto de payload en Inbox (mismo `message_id`, payload distinto) y bloqueo de destino deshabilitado. |
| `JOINT-01` / `JOINT-01-REGRESSION` | Cobertura parcial en `#310`. | `C1` + `C2`: Activación real `BORRADOR -> ACTIVO` tras Pricing + Inventory, fallo ambiguo en relay, rechazo de `correlation_id` falsificado y estados `TERMINAL` / `STALE`. |

---

## 4. Verificación acotada de Frontend (`master` `02ada63`, sin PR en Frontend)

Se actualizó el checkout local de `G6-Productos-Ofertas-frontend` al `master` actualizado (`02ada63217bfd448c7be621fbadfa6e48a325f64`, `#103` fusionado) y se verificó específicamente:

- **Navegador real (Playwright Chromium) contra `BulkSvcModule` real de `#315` (`e7547f3`):**
  - Descarga de plantilla CSV (`GET /api/v1/carga-masiva/productos/plantilla?formato=CSV`) con JWT humano RS256 **sin `aud`** → HTTP `200 text/csv`, archivo descargado con cabecera `sku_base`, sesión permanece `ACTIVE`.
  - Respuesta `403` por rol insuficiente (`CONSULTA`) → sesión permanece `ACTIVE`.
  - Fallo de servidor `500` → gestionado sin expulsar al usuario (`ACTIVE`).
  - Expiración legítima (`401 TOKEN_INVALIDO` por JWT expirado) → sesión marcada `EXPIRED`.
- **Suites de Frontend ejecutadas en `02ada63`:**
  - `npx playwright test tests/bulk-http.spec.ts`: **`7/7 PASS`** (`45.1s`).
  - `npm run test:unit:bulk -- --run`: **`98/98 PASS`**.
  - `npm run test:unit:combos -- --run` (incluye `auth.test.ts` 55, `authenticatedGatewayClient.test.ts` 9, `readOnlyClient.test.ts` 17, `publicReads.test.ts` 8, `g7OnlyTransport.spec.ts` 4): **`239/239 PASS`** (`16` archivos).
- **Alcance declarado:** Esta verificación acredita específicamente el flujo de descarga de plantilla CSV, el manejo de sesión en `401`/`403`/`500` y las suites indicadas; no se afirma que todo el repositorio Frontend esté libre de defectos fuera de este alcance. Al no detectarse defectos funcionales en este flujo, no se abre PR en Frontend.

---

## 5. `STANDBY` de infraestructura real y Caché APIM

- **Standby vigente:** Cero ejecuciones contra Azure APIM, ACA, Service Bus, G7 real, Supabase compartido o Marketplace/Ventas reales. Evidencias históricas en `evidencias/azure-*` preservadas sin alteración.
- **Caché APIM:** Permanece desacoplado de `#314` (sin política desplegada ni pruebas MISS/HIT reales).
