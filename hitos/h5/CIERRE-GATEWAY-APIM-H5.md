# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CODE_CORRECTED_PENDING_EXTERNAL_AUDIT` (correcciones P0/P1 implementadas; **ninguna prueba ejecutada ni recurso Azure mutado**).

## 1. Procedencia y dependencias

- **Backend `master`:** `b0c41cb41e089cffb349da9c3938f8f62e793cd6`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`. Preserva `PUBLIC_READ_ONLY` con opt-in G5 H5 únicamente con configuración G7 válida (`SIMULATED_AUTH` rechazado; `GATEWAY_G5_H5_ENABLED=false` por defecto).
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Estado de rutas Gateway y seguridad alternativa

- **Registro base (`CONTRACT_ROUTES`):** 147 entradas, incluyendo `conciliarImportacionGeneralPorCorrelacion` (Bulk), `listarAlertasOperativasInventario` y `listarUbicacionesInventario` (Inventory H01/H02).
- **Overlay G5 H5 (`G5_H5_ROUTES`):** 4 rutas protegidas (`admitirConsumoCuponH5`, `admitirRestauracionCuponH5`, `obtenerOperacionCuponH5`, `obtenerEstadoReservaH5`), apagadas por defecto (`GATEWAY_G5_H5_ENABLED=false`, requiere configuración G7 válida y gate operativo).
- **Seguridad alternativa humana/M2M (`human_or_m2m`):** `obtenerCombo` y `consultarDisponibilidadCombo` admiten `userBearer` (sin audiencia técnica) o `serviceBearer` (con audiencia técnica, scope y cliente). `operation-security.json` conserva ambas alternativas en `securityAlternatives` y las políticas APIM evalúan cada modalidad sin reducir colecciones.
- **Exclusiones internas (5 operaciones):** `obtenerContextoSku`, `obtenerContextosSkuLote`, `filtrarSkusVendiblesInterno`, `obtenerEvidenciaReservaCuponInterno`, `obtenerContenidoCargaMasivaInternoH5` devuelven `404` en Gateway y no se importan en APIM.
- **Excepciones históricas Pricing (2 operaciones):** `obtenerDefinicionPrecioProductoAdministracion` y `obtenerDefinicionPrecioSkuAdministracion` se conservan en Gateway protegidas con `userBearer`/`GESTOR_COMERCIAL` y quedan fuera de la importación contractual APIM hasta decisión de regularización documental.

## 3. Catálogo candidato vs importación efectiva fail-closed

- `ops/azure/apim/filter-openapi.py` separa cuatro niveles:
  1. `contractInventory` (154 operaciones de OpenAPI `0.7.0-rc.3`).
  2. `gatewayStaticRegistry` (registro base + overlay G5).
  3. `candidateCatalog` (145 operaciones candidatas APIM por defecto).
  4. `effectivePublication` (importación efectiva **fail-closed**: `environmentEnabled=false` por defecto hasta recibir `--enabled-providers`, `--security-profile`, `--authorized-public-allowlist` para las dos rutas SEO sin seguridad y resolución de `PENDING_G7_ALLOWLIST`).
- `--enable-g5` requiere `--g5-authorized` explícito para incluir rutas G5.
- Operaciones M2M sin `x-allowed-client-ids` (ej. `consultarDisponibilidadCombo`) se marcan `PENDING_G7_ALLOWLIST` sin inventar clientes y bloquean la publicación efectiva hasta registro G7.

## 4. Perfiles, correlación, streaming, anti-bypass y rollback

- **Perfiles obligatorios (`main.bicep` / `validate-parameters.py`):** `commercial_read`, `admin_read`, `business_write`, `multipart_import`, `expensive_export`, `g5_protected` (sin valores por defecto silenciosos en `main.bicep`; `environmentTier` distingue `lab` vs `production`).
- **Correlación y streaming (`api.xml`, `operation-secured.xml`, `operation-public.xml`):** regex UUID canónica estricta alineada con Gateway (rechazo `400 VALIDACION` ante UUID no canónico o duplicado), `buffer-request-body="false"` y `buffer-response="false"`, CORS con `Content-Disposition` y `Location` sin wildcard.
- **Red privada y anti-bypass:** `validate-parameters.py` exige `privateNetworkProof.verified=true` y `antiBypassVerified=true` en `production`; nunca infiere conectividad privada por sintaxis `https://`.
- **Inventario Azure (solo lectura, 25/11/2026):** sin instancia APIM (`Microsoft.ApiManagement: NotRegistered`), sin Application Insights ni Private DNS zones; `env-g6-phase1-chile` con `vnetConfiguration: null`; `api-gateway` con `external: true` e `ipSecurityRestrictions: null`; los 8 microservicios con `external: false`; `AZURE_CHILE_DEPLOY_ENABLED=false`.
- **Rollback:** conservación de revisión previa, `operationSetSha256` y hashes de políticas XML.

## 5. Cobertura preparada APIM-T01–T08 y RL-01–RL-06 (NO EJECUTADAS)

| ID | Cobertura preparada | Estado actual |
|---|---|---|
| APIM-T01 | `apim-live-acceptance.mjs`: operación habilitada con JWT contractual correcto (`200`, no anónimo en rutas M2M) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T02 | JWT válido, ausente, malformado, expirado, issuer incorrecto, audience incorrecta (`401`) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T03 | Scope, rol y cliente incorrectos (`403`) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T04 | CORS positivo y negativo | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T05 | Burst `429`, aislamiento y anti-bypass directo al Gateway con JWT autorizado (fallo inequívoco si responde `200`) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T06 | Ruta desconocida y las 5 internas excluidas (`404`) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T07 | Correlación entre APIM, Gateway y provider + rechazo UUID no canónico (`400`) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T08 | Comparación privada y evidencia de rollback aprobada | `NOT_RUN` / `BLOCKED_INFRA` |
| RL-01..RL-06 | `apim-rl-k6.js`: ráfaga `429` + `Retry-After`, recuperación, cuota `403`, concurrencia, aislamiento cliente B con JWT, métricas `p50/p95/p99` y metadatos | `NOT_RUN` / `BLOCKED_INFRA` |
