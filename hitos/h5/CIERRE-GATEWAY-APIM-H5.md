# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CODE_CORRECTED_R4_PENDING_EXTERNAL_AUDIT` (correcciones R4 implementadas; **ninguna prueba ejecutada ni recurso Azure mutado**).

## 1. Procedencia y dependencias

- **Backend `master`:** `1b90543dc39a8919fd94f0e059d10e1002b3b2a9`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`. Preserva `PUBLIC_READ_ONLY` con opt-in G5 H5 únicamente con configuración G7 válida (`SIMULATED_AUTH` rechazado; `GATEWAY_G5_H5_ENABLED=false` por defecto).
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Estado exacto del fixture Bulk y observabilidad Gateway

- **Fixture Bulk/PostgreSQL (`bulk-postgres.gateway.e2e-spec.ts`):** contenedor `postgres:17-alpine` descartable dedicado con las 8 migraciones reales de `bulk-svc` bajo `po_bulk_owner`/`bulk_fixture_app`, limpieza idempotente centralizada (`cleanupDisposableResources`) y verificación SQL real sobre **`bulk.batch_jobs`** (filtrando `batch_id`, `owner_sub`, `correlation_id`, `count=1`), plantilla CSV Bulk V2 de 16 columnas, `Cache-Control: no-store` y `404` uniforme para actor ajeno. Estado de ejecución: `NOT_RUN`.
- **Observabilidad y Vitest (`observability-and-resilience.e2e-spec.ts`, `gateway-proxy.ts`):** `vi`/`MockInstance` y `signed.token(...)` RS256 real; logging sin sobrescribir `200` ya transmitido con `503`. Estado de ejecución: `NOT_RUN`.

## 3. Publicación candidata vs efectiva, seguridad mixta y pendientes G7

- **Rutas mixtas `human_or_m2m` (`obtenerCombo`, `consultarDisponibilidadCombo`):** la condición `PENDING_G7_ALLOWLIST` bloquea la publicación efectiva tanto en `m2m` como en `human_or_m2m` por defecto. Solo con `--allow-human-only-when-m2m-pending` explícito se emite una representación efectiva humana (`userBearer`) excluyendo explícitamente la alternativa M2M (`m2mAlternativeExcludedReason: "PENDING_G7_ALLOWLIST"`).
- **Validación de perfil y provider en públicas:** `filter-openapi.py` valida `securityProfile` contra `KNOWN_SECURITY_PROFILES` (`UNSPECIFIED`, `G7_AUTHENTICATED`, `PUBLIC_READ_ONLY`) y bloquea operaciones públicas cuyo provider esté deshabilitado salvo excepción explícita (`--public-provider-exceptions`).
- **Barrera Bicep sin bypass (`main.bicep`):** eliminado `requireEffectivePublication`; `publicationGatePassed` exige `publicationMode == 'effective'`, `effectivePublication.authorized == true`, `expectedOperationSetSha256` y `expectedFilteredOpenApiSha256`, condicionando también el recurso `apim`, `namedValues`, `api`, `operationPolicies` y `applicationInsightsLogger`.
- **Reproducibilidad y preflight (`verify-arm-template.py`, `validate-parameters.py`):** separación de `--mode effective` vs `--mode candidate`; `validate-parameters.py` exige `--expected-docs-sha`, `--expected-gateway-sha` y evidencia Azure CLI vigente (`capturedAtUtc` <= 24h, `sourceCommand` `az ...`, `vnetConfiguration != null`, `ipSecurityRestrictions` + `directRoutesBlocked=true`).

## 4. Trazas posteriores, cuota/concurrencia y anti-bypass

- **Trazas posteriores (`apim-live-acceptance.mjs`):** `APIM-T01` y `APIM-T03` esperan propagación acotada y consultan la fuente de telemetría **después** de enviar las solicitudes HTTP, validando ventana temporal, `operationId`, `owner`, `environment`, traza explícita `403` en APIM y `0` hits en provider.
- **Cuota y concurrencia sin falsos positivos (`apim-rl-k6.js`):** credenciales separadas (`APIM_JWT_M2M_A`, `APIM_JWT_M2M_B`, `APIM_JWT_HUMAN_QUOTA`, `APIM_JWT_HUMAN_CONCURRENCY`); `403` de cuota exige ausencia de `SCOPE_INSUFICIENTE`/`TOKEN_INVALIDO` (`apim_rl_authz_false_positive == 0`).
- **Inventario Azure (solo lectura, 25/11/2026):** sin instancia APIM (`Microsoft.ApiManagement: NotRegistered`), sin Application Insights ni Private DNS zones; `env-g6-phase1-chile` con `vnetConfiguration=null`; `api-gateway` con `external=true` e `ipSecurityRestrictions=null`; los 8 microservicios con `external=false`; `AZURE_CHILE_DEPLOY_ENABLED=false`.

## 5. Estado de pruebas (NO EJECUTADAS)

- `APIM-T01`..`APIM-T08` (`ops/azure/apim/tests/apim-live-acceptance.mjs`): `NOT_RUN` / `BLOCKED_INFRA`.
- `RL-01`..`RL-06` (`ops/azure/apim/tests/apim-rl-k6.js`): `NOT_RUN` / `BLOCKED_INFRA`.
- `apps/api-gateway/test/*` y `ops/azure/apim/tests/test_apim_artifacts.py`: `NOT_RUN`.
