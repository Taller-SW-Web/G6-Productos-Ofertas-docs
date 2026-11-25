# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CODE_CORRECTED_R8_PENDING_EXTERNAL_AUDIT` (correcciones R8 implementadas; **ninguna prueba ejecutada ni recurso Azure mutado**).

## 1. Procedencia y dependencias

- **Backend `master`:** `1b90543dc39a8919fd94f0e059d10e1002b3b2a9`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`.
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Modalidades de red ACA Allow-only (R7-01)

`validate-parameters.py` y `apim-live-acceptance.mjs` rechazan reglas mixtas `Allow`/`Deny` en `ipSecurityRestrictions` de Azure Container Apps y admiten únicamente:
- **Modalidad A (Gateway interno):** `external=false`, `vnetConfiguration != null`, DNS/subred/conectividad privada y `directRoutesBlocked=true`.
- **Modalidad B (Gateway externo con allowlist):** `external=true`, reglas **exclusivamente `Allow`** (sin `0.0.0.0/0`, `*` ni `::/0`), restringidas a `expectedApimOriginCidrs`, denegación implícita del resto y `directRoutesBlocked=true`.

## 3. Evidencia real de rollback APIM-T08 (R7-02)

`apim-live-acceptance.mjs` (`validateRollbackEvidence`) exige snapshots independientes (`azSnapshots.before`, `during`, `after`) obtenidos con `az apim ...` o `az rest --method get` contra `management.azure.com`, vinculados a `resourceId`, `subscriptionId`, `resourceGroup`, `apiName` y revisión, calculando el SHA256 real sobre `policyXml` en lugar de confiar en hashes autodeclarados.

## 4. Manifiesto efectivo en k6 RL-05 (R7-03)

`ops/azure/apim/tests/apim-rl-k6.js` rechaza manifiestos `candidate` y exige `APIM_EFFECTIVE_MANIFEST_PATH` con `publicationMode="effective"`, `effectivePublication.authorized=true`, coincidencia de `APIM_OPERATION_SET_SHA256` / `APIM_FILTERED_OPENAPI_SHA256`, operación `GET /auditoria-precios/exportaciones/{exportId}/archivo` en `publishedOperationIds` con `environmentEnabled=true` y `APIM_RL_EXPORT_ID` autorizado.

## 5. Estado de pruebas (NO EJECUTADAS)

- `apps/api-gateway/test/*`: `NOT_RUN`.
- `ops/azure/apim/tests/test_apim_artifacts.py`: `NOT_RUN`.
- `ops/azure/apim/tests/apim-live-acceptance.test.mjs`: `NOT_RUN`.
- `ops/azure/apim/tests/apim-live-acceptance.mjs` (`APIM-T01`..`APIM-T08`): `NOT_RUN` / `BLOCKED_INFRA`.
- `ops/azure/apim/tests/apim-rl-k6.js` (`RL-01`..`RL-06`): `NOT_RUN` / `BLOCKED_INFRA`.
