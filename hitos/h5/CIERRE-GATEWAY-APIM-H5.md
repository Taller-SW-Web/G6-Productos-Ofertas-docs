# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CODE_CORRECTED_R3_PENDING_EXTERNAL_AUDIT` (correcciones de ronda 3 implementadas; **ninguna prueba ejecutada ni recurso Azure mutado**).

## 1. Procedencia y dependencias

- **Backend `master`:** `b0c41cb41e089cffb349da9c3938f8f62e793cd6`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`. Preserva `PUBLIC_READ_ONLY` con opt-in G5 H5 únicamente con configuración G7 válida (`SIMULATED_AUTH` rechazado; `GATEWAY_G5_H5_ENABLED=false` por defecto).
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Fixtures Bulk, observabilidad Gateway y seguridad alternativa

- **Fixture Bulk/PostgreSQL (`bulk-postgres.gateway.e2e-spec.ts`):** utiliza un contenedor `postgres:17-alpine` descartable dedicado (sin tocar Supabase ni ampliar `Phase1Postgres`), aplica las 8 migraciones reales de `bulk-svc` bajo `po_bulk_owner`/`bulk_fixture_app`, levanta `bulk-svc` compilado con `G7_JWT_ISSUER`, `G7_JWT_JWKS_URL` y `BULK_CORRELATION_RECONCILIATION_ENABLED=true`, envía plantilla CSV Bulk V2 real por Gateway, exige `202` con `batch_id`, `200` + `Cache-Control: no-store` para el propietario, `404` uniforme para actor ajeno y lectura pura (`count=1` en `bulk.import_batches`). Estado de ejecución: `NOT_RUN`.
- **Observabilidad y Vitest (`observability-and-resilience.e2e-spec.ts`, `gateway-proxy.ts`):** usa `vi`/`MockInstance` de Vitest y `signed.token(...)` con firma RS256 real; distingue `status`, `transportState`, `failureOrigin` y `upstreamReached` sin sobrescribir `200` ya transmitido con `503`. Estado de ejecución: `NOT_RUN`.
- **Seguridad alternativa humana/M2M (`human_or_m2m`):** `obtenerCombo` y `consultarDisponibilidadCombo` conservan ambas modalidades (`userBearer` sin audiencia técnica y `serviceBearer` con audiencia/scope) en `securityAlternatives` y políticas APIM sin colapsar colecciones.

## 3. Catálogo candidato vs publicación efectiva fail-closed

- `ops/azure/apim/filter-openapi.py` separa:
  1. `contractInventory` (154 operaciones de OpenAPI `0.7.0-rc.3`).
  2. `gatewayStaticRegistry` (registro base + overlay G5).
  3. `candidateCatalog` (145 operaciones candidatas por defecto; `effectivePublication.authorized=false`).
  4. `effectivePublication` (`--effective-publish`): filtra el OpenAPI y `manifest.operations` **exclusivamente** al subconjunto autorizado (por provider habilitado, allowlist pública SEO, G5 con `--enable-g5` + `--g5-authorized` y exclusión de `PENDING_G7_ALLOWLIST`), registrando `excludedOperations` con motivo explícito.
- `main.bicep` incorpora la guarda `publicationGatePassed` (`effectivePublication.authorized == true`, `expectedOperationSetSha256` y `expectedFilteredOpenApiSha256`) sobre `api`, `apiPolicy`, `operationPolicies` (`authorizedOperations`) y `apiDiagnostics`.
- `validate-parameters.py` bloquea despliegues si `effectivePublication.authorized != true`, si faltan perfiles completos o si falta evidencia real de Azure CLI (`azureCliEvidencePath` con `vnetConfiguration != null` y `ipSecurityRestrictions`/`external=false`) y `operationalApprovalRef`.

## 4. Perfiles, anti-bypass, k6 y rollback

- **Anti-bypass (`APIM-T05`):** no basta recibir `401`/`403` JWT o `404` de ruta en Gateway directo; `apim-live-acceptance.mjs` exige evidencia de ingress (`external=false` o `ipSecurityRestrictions` hacia APIM), resultados reales de `apim-rl-k6.js` y bloqueo efectivo de acceso directo autorizado.
- **Cobertura k6 (`apim-rl-k6.js`):** carga derivada dinámicamente de `APIM_LAB_BURST_CALLS`, `APIM_LAB_BURST_WINDOW_SEC`, `APIM_LAB_QUOTA_CALLS` y `APIM_LAB_CONCURRENCY_MAX`, con thresholds separados para burst `429` + `Retry-After`, recuperación `200`, cuota `403`, concurrencia `429`, aislamiento de cliente B con JWT y resumen `p50/p95/p99`.
- **Rollback (`APIM-T08`):** exige esquema estructurado (`resourceId`, `revisionBefore`, `revisionAfterRollback`, hashes de política previo/aplicado/restaurado, `restorationResult=RESTORED`, `operationalApproval`, `privateConnectivityCheck=PASS`, `postRollbackSmokeResult=PASS`).
- **Inventario Azure (solo lectura, 25/11/2026):** sin instancia APIM (`Microsoft.ApiManagement: NotRegistered`), sin Application Insights ni Private DNS zones; `env-g6-phase1-chile` con `vnetConfiguration=null`; `api-gateway` con `external=true` e `ipSecurityRestrictions=null`; los 8 microservicios con `external=false`; `AZURE_CHILE_DEPLOY_ENABLED=false`.

## 5. Estado de pruebas APIM-T01–T08 y RL-01–RL-06

Todas las pruebas permanecen **`NOT_RUN`** (y bloqueadas por infraestructura Azure hasta aprovisionamiento/aprobación):
- `APIM-T01`..`APIM-T08` en `ops/azure/apim/tests/apim-live-acceptance.mjs`: `NOT_RUN` / `BLOCKED_INFRA`.
- `RL-01`..`RL-06` en `ops/azure/apim/tests/apim-rl-k6.js`: `NOT_RUN` / `BLOCKED_INFRA`.
