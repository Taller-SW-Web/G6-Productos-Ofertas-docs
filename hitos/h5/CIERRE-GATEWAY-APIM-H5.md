# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CIERRE_CODIGO_GATEWAY_APIM_H5_INTEGRADO` (PRs `#294`, `#291`, `#292` y `#98` integrados en `master`; compatibilidad Chile `Multiple`/`Single`/escala `1/1` y E2E Bulk navegador real verificados; `APIM-T08` en `NOT_VERIFIED`; pruebas en vivo Azure/APIM `APIM-T01`..`T08` y `RL-01`..`RL-06` en `NOT_RUN_BLOCKED_INFRA`).

## 1. Procedencia y dependencias

- **Backend `master`:** `352bfef5167363b11c8bc52bc61c0faa5ab0611f` (merge commit de `#292`; procedencia contractual histórica previa de Gateway/APIM: `1b90543dc39a8919fd94f0e059d10e1002b3b2a9`).
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8` como procedencia contractual histórica).
- **Frontend `master` (solo lectura):** `9a784366497408c934d20f95fff30ab2952c6468` (merge commit de `#98`; histórico previo: `5cf7b0f506833436e3e97bb0804513349099519e`).
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`.
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Correcciones R9 aplicadas

- **Preflight ACA Modalidad B (`validate-parameters.py`):** eliminada la validación incondicional `vnetConfiguration != null` previa a `validate_aca_network_evidence()`, habilitando Modalidad A (`external=false` + `vnetConfiguration`) y Modalidad B (`external=true` + reglas `Allow` exclusivas dentro de `expectedApimOriginCidrs` sin wildcard) con prueba integral en `test_apim_artifacts.py`.
- **XML de política segura (`operation-secured.xml`):** escapadas las comillas internas (`&quot;`) dentro de `condition="@{ ... }"` para validez estricta XML.
- **Separación de adquisición real en `APIM-T08` (`apim-live-acceptance.mjs`):** `validateRollbackEvidence` distingue `EVIDENCE_PREPARED` (integridad local válida sin adquisición Azure) y ningún JSON suministrado por el operador puede activar `PASS`.
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
  - `ops/azure/apim/tests/apim-live-acceptance.mjs`: `validateRollbackEvidence()` valida únicamente la integridad documental local y devuelve siempre `EVIDENCE_PREPARED` (`verified: false`), ignorando `azAcquisitionVerified` o `independentQueryDigest` del JSON. Las consultas `az rest --method get` sobre Azure son necesarias pero no suficientes para acreditar `APIM-T08`: en el Backend integrado en `master` (`352bfef5167363b11c8bc52bc61c0faa5ab0611f`), `main()` invoca `verifyLiveRollback()` con `liveCapture: null` porque falta implementar y acreditar la captura independiente real de la secuencia `antes -> cambio -> restauración`; en consecuencia, `APIM-T08` permanece en `NOT_VERIFIED` y la ejecución en vivo en `NOT_RUN_BLOCKED_INFRA`.
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

## 5. Corrección final focalizada APIM-T08 (`4509249b4bb27853fa53d3586691cc653343589d`)

- **Sin interpolación shell (`apim-live-acceptance.mjs`):** reemplazado `execSync()` por `execFileSync('az', args)` en consultas de solo lectura (`rest --method get -o json`).
- **Validación estricta de identificadores:** `assertSafeApimApiId`, `assertSafeApimRevision` y `assertSafeApimResourceId` rechazan cualquier identificador peligroso antes de invocar `az`.
- **Revisión exacta y XML sin alterar:** consulta `/apis/{apiName};rev={revision}/policies/policy?...` e interpreta `properties.value` desde JSON sin `trim()` ni conversiones de salida.
- **Bloqueo explícito contra JSON de operador (`NOT_VERIFIED`):** ningún JSON suministrado por el operador (ni siquiera con tres estados `before -> during -> after` coherentes y hash final coincidente) puede activar `PASS` de `APIM-T08` por sí solo; sin procedencia verificable de captura real en vivo durante la operación autorizada, `verifyLiveRollback()` devuelve `NOT_VERIFIED`.
- **Pruebas unitarias negativas añadidas (`apim-live-acceptance.test.mjs`):** identificadores peligrosos, revisión incorrecta, hash distinto (incluyendo diferencia de fin de línea), ausencia de evidencia de transición y JSON coherente de operador sin procedencia independiente (`NOT_VERIFIED`).

| Validación final APIM | Comando / Alcance | Resultado real |
|---|---|---|
| Pruebas unitarias Node APIM | `node --test ops/azure/apim/tests/apim-live-acceptance.test.mjs` | **PASS local** (`3/3` pruebas OK) |
| Pruebas unitarias Python APIM | `python -m unittest discover -s ops/azure/apim/tests -p test_apim_artifacts.py -v` (`APIM_ARM_TEMPLATE=$env:TEMP\apim-h5-final.json`) | **PASS local** (`28/28` pruebas OK) |
| Compilación Bicep | `az bicep build --file ops/azure/apim/main.bicep --outfile $env:TEMP\apim-h5-final.json` | **PASS local** (exit 0; 6 warnings de linter) |
| Verificación ARM candidate | `python ops/azure/apim/verify-arm-template.py --template $env:TEMP\apim-h5-final.json ... --mode candidate` | **PASS local** (`145` políticas; `5` rutas privadas excluidas; G5 deshabilitado por defecto) |
| Ejecución en vivo contra Azure APIM | Sin instancia APIM en suscripción Azure (`NotRegistered`) | `NOT_RUN_BLOCKED_INFRA` |

## 6. Compatibilidad con PR #294 (Azure Chile CD — `7a25fc88fa04627332032f60841b65fa17eb45d9`)

- **Gateway #291 (`03e29fb371c10e8f568c6e20c2cb81ae1bd94959`):** fusionó `origin/master` (`#294`, `0da1f8cf6454908787e3c35f75de900b9b92dca0`) sin conflictos.
  - `ops/azure/container-apps/render-deployment.mjs` emite `activeRevisionsMode: 'Multiple'` para `api-gateway`, conserva `Single` para `promotions-svc` y los demás microservicios, y mantiene `minReplicas=1, maxReplicas=1` obligatorios para `api-gateway` y `promotions-svc` (y `[0, 1]` para los demás servicios sin identidad gestionada).
  - **Restricción del renderer de bootstrap (`render-deployment.mjs`):**
    - El renderer se utiliza **únicamente para bootstrap inicial** (`gatewayDeploymentMode: 'bootstrap-only'`), donde genera `latestRevision=true` sin comprobar en Azure que el Gateway no exista; por ello, una reaplicación declarativa arbitraria **no** es segura.
    - **Está prohibido** aplicar una plantilla de bootstrap sobre un Gateway ya existente.
    - Las actualizaciones de Gateway existente en Chile deben realizarse exclusivamente con el CD oficial `ops/azure/container-apps/deploy.sh` (corte controlado por revisión explícita, salud/escala `1/1`, control de concurrencia y rollback).
    - Cualquier futura ruta de aplicación declarativa necesitará un **preflight real de solo lectura** en Azure que compruebe la inexistencia del Gateway antes del bootstrap.
- **APIM #292 (histórico R10/T08 `4509249b4bb27853fa53d3586691cc653343589d`, integrado finalmente en `352bfef5167363b11c8bc52bc61c0faa5ab0611f`):** compatible sin cambios con `#294` (`contract-routes.ts`, rutas `/api/v1`, OpenAPI filtrado, manifiesto y modalidades de ingress ACA sin afectación). `APIM-T08` permanece en `NOT_VERIFIED` sin captura en vivo, `APIM-T01`..`APIM-T08` y `RL-01`..`RL-06` permanecen en `NOT_RUN_BLOCKED_INFRA`, y APIM no se declara desplegado ni aceptado en vivo.

| Validación local post-merge #294 (`03e29fb3`, evidencia histórica) | Resultado real |
|---|---|
| `node --test ops/azure/container-apps/render-deployment.test.mjs` | **PASS local** (`7/7` OK) |
| `bash -n ops/azure/container-apps/deploy.sh` | **PASS local** (exit `0`) |
| `bash ops/azure/container-apps/tests/deploy.test.sh` | **PASS local** (`16/16` OK) |
| `npm run typecheck` | **PASS local** (exit `0`) |
| `npm test -- apps/api-gateway --maxWorkers=1` | **PASS local** (`12` archivos, `131/131` OK) |

## 7. Cierre definitivo e integración en `master`

| Componente | PR | HEAD final del PR | Merge commit en `master` | Estado |
|---|---|---|---|---|
| Azure Chile | Backend `#294` | `0da1f8cf6454908787e3c35f75de900b9b92dca0` | `7a25fc88fa04627332032f60841b65fa17eb45d9` | `MERGED` |
| Gateway H5 | Backend `#291` | `f7f0e9322e3fcadd3a93ccaf23acfb8a6ad3e2b6` | `1b655237c144b93dd4ab5adb506630d002403f7a` | `MERGED` |
| APIM H5 | Backend `#292` | `6d1f5aa9edd9e18e4f39e99e9c8e061209c47fc0` | `352bfef5167363b11c8bc52bc61c0faa5ab0611f` | `MERGED` |
| E2E Bulk | Frontend `#98` | `4624a1800d84611107785b8b3aa793ed44285f50` | `9a784366497408c934d20f95fff30ab2952c6468` | `MERGED` |

- **CI de APIM #292 (`6d1f5aa9edd9e18e4f39e99e9c8e061209c47fc0`):** workflow `Integración continua (CI)` run `45726372221` con resultado `SUCCESS`; el verificador ARM de CI (`verify-arm-template.py`) ejecuta `--mode candidate` conservando el bloqueo fail-closed de publicación efectiva (`--mode effective` sigue rechazando sin autorización).
- **E2E Bulk en navegador real (`MK-001 Bulk E2E Integral`):** pasó tras incorporar la corrección de sincronización de identidades en Frontend `#98` (`4624a1800d84611107785b8b3aa793ed44285f50`).
- **Compatibilidad Chile y regla bootstrap:** se conserva Gateway en `Multiple`, Promotions en `Single`, escala `1/1`, tráfico controlado por revisión explícita mediante `deploy.sh`, y la prohibición estricta de reaplicar bootstrap declarativo sobre un Gateway existente.
- **Estado APIM en vivo:** artefactos y código listos e integrados en `master`, pero sin instancia APIM desplegada; `APIM-T01`..`APIM-T08` y `RL-01`..`RL-06` en vivo permanecen en `NOT_RUN_BLOCKED_INFRA` y `APIM-T08` en `NOT_VERIFIED`.
