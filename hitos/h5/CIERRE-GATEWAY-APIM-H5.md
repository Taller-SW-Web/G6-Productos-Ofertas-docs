# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CODE_CORRECTED_R6_PENDING_EXTERNAL_AUDIT` (correcciones R6 implementadas; **ninguna prueba ejecutada ni recurso Azure mutado**).

## 1. Procedencia y dependencias

- **Backend `master`:** `1b90543dc39a8919fd94f0e059d10e1002b3b2a9`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`.
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Importación OpenAPI compatible con límites Bicep (R5-01, R5-06)

- El artefacto legible `ops/azure/apim/openapi/gateway-filtered.json` tiene `1 373 231` caracteres (supera el límite de `131 072` de `loadTextContent()` y `1 048 576` de `loadJsonContent()`).
- `filter-openapi.py` genera en paralelo el artefacto compacto reproducible `ops/azure/apim/openapi/gateway-filtered.compact.json` (`531 461` caracteres, dentro de `1 048 576` caracteres de `loadJsonContent()`), con SHA256 canónico idéntico: `2393ebc7625a84300d23f556cb31eeccfd19ee5b39d5ee3fb8ab2e72abd07101`.
- `main.bicep` carga `loadJsonContent('./openapi/gateway-filtered.compact.json')` (`fixedFilteredOpenApiObject`) y serializa `string(fixedFilteredOpenApiObject)` hacia APIM bajo `publicationGatePassed`.
- `verify-arm-template.py` verifica el contenido real embebido en `variables('fixedFilteredOpenApiObject')` del ARM compilado contra `filteredOpenApiCanonicalSha256` y `gateway-filtered.json`, y `validate-parameters.py` verifica también `gateway-filtered.compact.json`.

## 3. Parser, verificador G5 y tests estáticos (R5-02, R5-03, R5-04)

- **Parser de registros (`filter-openapi.py`):** `_scan_route_blocks()` escanea objetos `{ ... }` con balanceo de llaves y cadenas después de `= [` (o `[` raíz en fixtures inline), evitando falsos cortes en anotaciones `ContractRoute[]` o capturas cruzadas entre rutas.
- **Verificador G5 (`verify-arm-template.py`):** `main()` propaga `g5_authorized=args.g5_authorized` hacia `validate()`, exigiendo `g5EnabledByDefault=false`, rechazando `g5OptIn` sin autorización y validando scopes/clientes cuando G5 está autorizado.
- **Suite estática (`test_apim_artifacts.py`):** `test_generated_policy_ids_match_exact_imported_operation_set` verifica `var publicationGatePassed` y `[for operation in authorizedOperations` en `main.bicep`.

## 4. Criterios RL-04 / RL-05 en k6 (R5-05)

- `ops/azure/apim/tests/apim-rl-k6.js` separa cuota y ráfaga en `rl04_quota_exhaustion` mediante `constant-arrival-rate` con `rate = max(1, APIM_LAB_QUOTA_BURST_CALLS - 1)` por `APIM_LAB_QUOTA_BURST_WINDOW_SEC`, con contador de colisión `apim_rl_quota_burst_collision == 0`.
- `rl05_concurrency_expensive` ejecuta `concurrencyVus < APIM_LAB_EXPENSIVE_BURST_CALLS` (1 iteración por VU) para aislar `limit-concurrency` de `rate-limit-by-key`, reportando `verificationStatus` (`VERIFIED` vs `NOT_VERIFIED`).

## 5. Estado de pruebas (NO EJECUTADAS)

- `apps/api-gateway/test/*`: `NOT_RUN`.
- `ops/azure/apim/tests/test_apim_artifacts.py`: `NOT_RUN`.
- `ops/azure/apim/tests/apim-live-acceptance.mjs` (`APIM-T01`..`APIM-T08`): `NOT_RUN` / `BLOCKED_INFRA`.
- `ops/azure/apim/tests/apim-rl-k6.js` (`RL-01`..`RL-06`): `NOT_RUN` / `BLOCKED_INFRA`.
