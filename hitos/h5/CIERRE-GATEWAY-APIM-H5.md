# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `LOCAL_VALIDATION_R9_COMPLETE` (validaciones locales APIM ejecutadas y en `PASS`; pruebas Gateway locales y pruebas reales contra Azure/APIM pendientes por bloqueo de infraestructura).

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
