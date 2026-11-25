# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CODE_CORRECTED_R5_PENDING_EXTERNAL_AUDIT` (correcciones R5 implementadas; **ninguna prueba ejecutada ni recurso Azure mutado**).

## 1. Procedencia y dependencias

- **Backend `master`:** `1b90543dc39a8919fd94f0e059d10e1002b3b2a9`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`.
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Coherencia OpenAPI efectivo, roles humanos y modos `candidate`/`effective`

- **Proyección OpenAPI efectivo (`filter-openapi.py`, `APIM-R4-01`):** cuando `--allow-human-only-when-m2m-pending` excluye la alternativa M2M de operaciones mixtas, se proyecta una copia independiente con `security: [{ userBearer: [] }]` y sin extensiones M2M (`x-service-audience`, `x-required-scope`, `x-allowed-client-ids`). `validate_artifact_pair()` exige correspondencia exacta entre `security` del OpenAPI filtrado y `securityAlternatives` del manifiesto.
- **Paridad de roles humanos (`APIM-R4-03`):** operaciones `userBearer` conservan su rol contractual explícito o aplican el predeterminado efectivo del Gateway (`GESTOR_COMERCIAL`) cuando no es explícito; discrepancias explícitas entre Docs y Gateway bloquean la generación.
- **Modos `candidate` / `effective` y G5 opt-in (`verify-arm-template.py`, `APIM-R4-02`, `APIM-R4-04`, `APIM-R4-07`):** separación explícita entre `--mode candidate` y `--mode effective` (incluyendo `--allow-human-only-when-m2m-pending` y `--enable-g5` + `--g5-authorized`). Sin autorización G5 ninguna ruta G5 se publica; con autorización G5 se validan scopes, clientes y `g5EnabledByDefault=false`.
- **OpenAPI fijado en Bicep (`main.bicep`, `APIM-R4-08`):** eliminado `param filteredOpenApi`; `main.bicep` carga directamente `loadTextContent('./openapi/gateway-filtered.json')` (`fixedFilteredOpenApi`) vinculado a `operation-security.json` y los SHA esperados bajo `publicationGatePassed`.

## 3. Evidencia Azure, red privada y aislamiento de 429

- **Evidencia Azure (`validate-parameters.py`, `apim-live-acceptance.mjs`, `APIM-R4-05`):** exige `expectedSubscriptionId`, `expectedResourceGroup`, `expectedEnvironment`, `expectedGatewayResourceId`, `expectedApimOriginCidrs`, `sourceCommand` (`az ...`), `capturedAtUtc` <= 24h y `directRoutesBlocked=true`. El JSON de evidencia no es prueba criptográfica por sí solo y queda vinculado a consultas Azure CLI de solo lectura en el procedimiento autorizado.
- **Aislamiento de 429 en k6 (`apim-rl-k6.js`, `APIM-R4-06`):** `rl05_concurrency_expensive` ejecuta `concurrencyVus < APIM_LAB_EXPENSIVE_BURST_CALLS` (1 iteración por VU) para aislar `limit-concurrency` de `rate-limit-by-key`, manteniendo identidades separadas y resumen causal (`burst_rate_limit_by_key_429`, `quota_by_key_403`, `limit_concurrency_429`, `authz_false_positive`).
- **Inventario Azure (solo lectura, 25/11/2026):** sin instancia APIM (`Microsoft.ApiManagement: NotRegistered`), sin Application Insights ni Private DNS zones; `env-g6-phase1-chile` con `vnetConfiguration=null`; `api-gateway` con `external=true` e `ipSecurityRestrictions=null`; los 8 microservicios con `external=false`; `AZURE_CHILE_DEPLOY_ENABLED=false`.

## 4. Estado de pruebas (NO EJECUTADAS)

- `apps/api-gateway/test/*`: `NOT_RUN`.
- `ops/azure/apim/tests/test_apim_artifacts.py`: `NOT_RUN`.
- `ops/azure/apim/tests/apim-live-acceptance.mjs` (`APIM-T01`..`APIM-T08`): `NOT_RUN` / `BLOCKED_INFRA`.
- `ops/azure/apim/tests/apim-rl-k6.js` (`RL-01`..`RL-06`): `NOT_RUN` / `BLOCKED_INFRA`.
