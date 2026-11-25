# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CODE_CORRECTED_R7_PENDING_EXTERNAL_AUDIT` (correcciones R7 implementadas; **ninguna prueba ejecutada ni recurso Azure mutado**).

## 1. Procedencia y dependencias

- **Backend `master`:** `1b90543dc39a8919fd94f0e059d10e1002b3b2a9`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`.
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Importación OpenAPI, alias ARM y verificación (R5-01..06, R6-03)

- `gateway-filtered.json` (`1 373 231` chars) y `gateway-filtered.compact.json` (`531 461` chars <= `1 048 576` límite de `loadJsonContent()`) comparten SHA256 canónico `2393ebc7625a84300d23f556cb31eeccfd19ee5b39d5ee3fb8ab2e72abd07101`.
- `verify-arm-template.py` implementa `resolve_arm_variable()` para resolver de forma segura objetos literales y cadenas de alias `[variables('...')]` (como `$fxv#0`) tanto en `operationsManifest` como en `fixedFilteredOpenApiObject`, detectando ciclos, variables inexistentes y expresiones no permitidas (`parameters(...)`).

## 3. Cierre focalizado RL-05, k6 VERIFIED, APIM-T05 y rollback (R6-01, R6-02, R6-04, R6-05)

- **RL-05 (`apim-rl-k6.js`):** reemplazada la ruta inexistente `/auditoria-precios/exportar` por la operación real `descargarExportacionAuditoriaPrecios` (`GET /auditoria-precios/exportaciones/{exportId}/archivo`, perfil `expensive_export`), validando al inicio contra `operation-security.json` que la ruta resuelta exista sin placeholders y tenga concurrencia habilitada, y rechazando `404/401/403` mediante `apim_rl_concurrency_unexpected_status == 0`.
- **Dictamen `VERIFIED` (`apim-rl-k6.js` + `apim-live-acceptance.mjs`):** `handleSummary()` exige `burst429 > 0`, `burstRetryAfter > 0`, `recovery200 > 0`, `quota403 > 0`, `quotaBurstCollision == 0`, `concurrency429 > 0`, `concurrencyUnexpectedStatus == 0`, `clientB200 > 0`, `clientBFailRate == 0`, `authzFalsePositive == 0` y `checksRate == 1`. `APIM-T05` exige `k6Summary.verificationStatus === 'VERIFIED'` y coincidencia de `region`, `revision` y `policyHash`.
- **Rollback `APIM-T08` (`apim-live-acceptance.mjs`):** exige `azSnapshots` independientes (`before`, `during`, `after`) con comandos `az apim ...`, orden temporal estricto y coincidencia de revisión y hashes de política.

## 4. Estado de pruebas (NO EJECUTADAS)

- `apps/api-gateway/test/*`: `NOT_RUN`.
- `ops/azure/apim/tests/test_apim_artifacts.py`: `NOT_RUN`.
- `ops/azure/apim/tests/apim-live-acceptance.mjs` (`APIM-T01`..`APIM-T08`): `NOT_RUN` / `BLOCKED_INFRA`.
- `ops/azure/apim/tests/apim-rl-k6.js` (`RL-01`..`RL-06`): `NOT_RUN` / `BLOCKED_INFRA`.
