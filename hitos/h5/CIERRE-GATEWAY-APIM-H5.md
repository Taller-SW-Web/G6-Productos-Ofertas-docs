# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `APIM_T08_FINAL_CORRECTED` (CI oficial Gateway Bulk-Catalog Retry en `PASS` con 7/7 pruebas Gateway y 14/14 escenarios Bulk; APIM-T08 blindado sin shell, con revisión exacta, JSON sin `trim()` y verificación de transiciones; pruebas reales contra Azure/APIM pendientes por bloqueo de infraestructura).

## 1. Procedencia y dependencias

- **Backend `master`:** `1b90543dc39a8919fd94f0e059d10e1002b3b2a9`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`.
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Correcciones R9 aplicadas

- **Preflight ACA Modalidad B (`validate-parameters.py`):** eliminada la validación incondicional `vnetConfiguration != null` previa a `validate_aca_network_evidence()`, habilitando Modalidad A (`external=false` + `vnetConfiguration`) y Modalidad B (`external=true` + reglas `Allow` exclusivas dentro de `expectedApimOriginCidrs` sin wildcard) con prueba integral en `test_apim_artifacts.py`.
- **XML de política segura (`operation-secured.xml`):** escapadas las comillas internas (`&quot;`) dentro de `condition="@{ ... }"` para validez estricta XML.
- **Separación de adquisición real en `APIM-T08` (`apim-live-acceptance.mjs`):** `validateRollbackEvidence` distingue `EVIDENCE_PREPARED` (integridad local válida sin adquisición Azure) de `PASS` (`azAcquisitionVerified=true` + `independentQueryDigest`).
- **Parámetros efectivos en `RL-05` (`apim-rl-k6.js`):** exige `APIM_EFFECTIVE_PARAMETERS_PATH` y valida `rateProfiles[rateProfile].maxConcurrency > 0` y coincidencia exacta de `maxConcurrency`, `burstCalls` y SHA256.

## 3. Resultados reales de validación local (R9)

| Validación | Comando | Resultado real |
|---|---|---|
| Compilación Bicep | `az bicep build --file ops/azure/apim/main.bicep --outfile $env:TEMP\apim-h5-r9.json` | **PASS** (exit 0; sin errores) |
| Pruebas unitarias Python APIM | `python -m unittest discover -s ops/azure/apim/tests -p test_apim_artifacts.py -v` | **PASS** (28/28 pruebas OK) |
| Pruebas unitarias Node APIM | `node --test ops/azure/apim/tests/apim-live-acceptance.test.mjs` | **PASS** (2/2 pruebas OK) |
| Verificación ARM + OpenAPI + Manifiesto | `python ops/azure/apim/verify-arm-template.py ... --mode candidate` | **PASS** (145 políticas, 5 internas excluidas, G5 deshabilitado por defecto) |
| Pruebas Gateway (`apps/api-gateway`) | No ejecutadas en esta ronda focalizada | `NOT_RUN` |
| `APIM-T01`..`APIM-T08` / `RL-01`..`RL-06` en vivo | Sin instancia APIM en suscripción Azure (`NotRegistered`) | `NOT_RUN_BLOCKED_INFRA` |

## 4. Correcciones y resultados verificados (R10)

- **CI Gateway #291 (`48028433dfd2a3c051e85d65dcafef18ce7b06f2`):**
  - `.github/workflows/bulk-catalog-retry-integration.yml`: declara `G6_BULK_GATEWAY_POSTGRES_E2E: '1'` en el job E2E y compila `bulk-svc` (`npm run build:bulk-svc`) antes de ejecutar la suite.
  - `apps/api-gateway/test/bulk-postgres.gateway.e2e-spec.ts`: implementa las 7 pruebas exactas de `requiredGatewayTests` (`scripts/ci/bulk-h5-required-scenarios.json`) sin omisiones en CI, usando PostgreSQL 17 y Storage local aislado en CI (o Docker descartable en ejecución local), cabeceras CSV v2 alineadas con `BULK_TEMPLATE_HEADERS` y `template_version=2`.
  - `apps/api-gateway/test/observability-and-resilience.e2e-spec.ts`: actualizada la ruta de exportación CSV a `/api/v1/auditoria-precios/exportaciones/{exportId}/archivo` (`descargarExportacionAuditoriaPrecios`).
- **APIM #292 (`ae32f0c0e4eace2bc6a75ff304c1756c7a6666fc`):**
  - `ops/azure/apim/tests/apim-live-acceptance.mjs`: `validateRollbackEvidence()` valida únicamente la integridad documental local y devuelve siempre `EVIDENCE_PREPARED` (`verified: false`), ignorando `azAcquisitionVerified` o `independentQueryDigest` del JSON; `APIM-T08` solo puede obtener `PASS` cuando `main()` ejecuta directamente `az rest --method get` en una corrida en vivo autorizada.
  - `ops/azure/apim/tests/apim-live-acceptance.test.mjs`: prueba negativa que verifica `EVIDENCE_PREPARED` (`verified: false`) aun cuando el JSON declare `azAcquisitionVerified: true`.

| Validación | Alcance / Referencia | Resultado real |
|---|---|---|
| Gateway unit (`npm test -- apps/api-gateway --maxWorkers=1`) | Local (`48028433` equivalente en suite Gateway) | **PASS local** (12 archivos, 131/131 pruebas) |
| Gateway E2E (`observability-and-resilience`, `routing`, `contract-parity`) | Local | **PASS local** (2 archivos, 516/516 pruebas) |
| Gateway `typecheck` (`npm run typecheck`) | Local (`48028433`) | **PASS local** (exit 0) |
| Verificador escenarios (`node --test scripts/ci/verify-bulk-h5-e2e.test.mjs`) | Local | **PASS local** (1/1 prueba) |
| Workflow CI `Integración Bulk-Catalog Retry (PostgreSQL 17 descartable)` | GitHub Actions run `45701252836` (`48028433`) | **PASS CI** (`verify-bulk-h5-e2e.mjs`: `PASS`, 8/8 pruebas Vitest, 0 fallidas, 0 omitidas; `7/7` Gateway + `14/14` Bulk) |
| Compilación Bicep (`az bicep build`) | Local (`ae32f0c0`) | **PASS local** (exit 0; 6 warnings de linter) |
| Pruebas unitarias Python APIM (`test_apim_artifacts.py`) | Local (`ae32f0c0`) | **PASS local** (28/28 pruebas OK) |
| Pruebas unitarias Node APIM (`apim-live-acceptance.test.mjs`) | Local (`ae32f0c0`) | **PASS local** (2/2 pruebas OK) |
| Verificación ARM (`verify-arm-template.py --mode candidate`) | Local (`ae32f0c0`) | **PASS local** (`145` políticas; `5` rutas privadas excluidas; G5 deshabilitado por defecto) |
| `APIM-T01`..`APIM-T08` / `RL-01`..`RL-06` en vivo | Sin instancia APIM en suscripción Azure (`NotRegistered`) | `NOT_RUN_BLOCKED_INFRA` |

## 5. Corrección final focalizada APIM-T08 (`64179efba52bcf1f6f3da27cd73cbf237348c677`)

- **Sin interpolación shell (`apim-live-acceptance.mjs`):** reemplazado `execSync()` por `execFileSync('az', args)` en consultas de solo lectura (`rest --method get -o json`).
- **Validación estricta de identificadores:** `assertSafeApimApiId`, `assertSafeApimRevision` y `assertSafeApimResourceId` rechazan cualquier identificador peligroso antes de invocar `az`.
- **Revisión exacta y XML sin alterar:** consulta `/apis/{apiName};rev={revision}/policies/policy?...` e interpreta `properties.value` desde JSON sin `trim()` ni conversiones de salida.
- **Evidencia independiente de transiciones:** `verifyLiveRollback()` exige corroboración de revisiones y secuencia `before -> during -> after`; si falta, devuelve `NOT_VERIFIED` sin emitir `PASS`.
- **Pruebas unitarias negativas añadidas (`apim-live-acceptance.test.mjs`):** identificadores peligrosos, revisión incorrecta, hash distinto (incluyendo diferencia de fin de línea) y ausencia de evidencia de transición (`NOT_VERIFIED`).

| Validación final APIM | Comando / Alcance | Resultado real |
|---|---|---|
| Pruebas unitarias Node APIM | `node --test ops/azure/apim/tests/apim-live-acceptance.test.mjs` | **PASS local** (`3/3` pruebas OK) |
| Pruebas unitarias Python APIM | `python -m unittest discover -s ops/azure/apim/tests -p test_apim_artifacts.py -v` (`APIM_ARM_TEMPLATE=$env:TEMP\apim-h5-final.json`) | **PASS local** (`28/28` pruebas OK) |
| Compilación Bicep | `az bicep build --file ops/azure/apim/main.bicep --outfile $env:TEMP\apim-h5-final.json` | **PASS local** (exit 0; 6 warnings de linter) |
| Verificación ARM candidate | `python ops/azure/apim/verify-arm-template.py --template $env:TEMP\apim-h5-final.json ... --mode candidate` | **PASS local** (`145` políticas; `5` rutas privadas excluidas; G5 deshabilitado por defecto) |
| Ejecución en vivo contra Azure APIM | Sin instancia APIM en suscripción Azure (`NotRegistered`) | `NOT_RUN_BLOCKED_INFRA` |
