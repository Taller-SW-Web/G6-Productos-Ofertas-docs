# Cierre técnico Gateway y Azure API Management — Hito 5

> **Estado:** `CODE_COMPLETE_PENDING_EXTERNAL_AUDIT` (código, políticas, IaC y pruebas escritos; **ninguna prueba ejecutada ni recurso Azure mutado**).

## 1. Procedencia y dependencias

- **Backend `master`:** `34058f0e5d25e89dcb4cb9d8c1ceb9db38cdfba4`
- **Docs `master`:** `18c3502f539ffc9b24947f87968223f086eea0ac` (OpenAPI `0.7.0-rc.3` fijado en `490172c11cb4b83ddd1996f8d5834d0402184cf8`)
- **Frontend `master` (solo lectura):** `5cf7b0f506833436e3e97bb0804513349099519e`
- **PR #286 (`trabajo/castilla/h5-g5-prueba-conjunta`):** fusionado en `24b0586c2a14787e5d6039ffe497dcdc9cc62d59`. Preserva `PUBLIC_READ_ONLY` con opt-in G5 H5 únicamente con configuración G7 válida (`SIMULATED_AUTH` rechazado; `GATEWAY_G5_H5_ENABLED=false` por defecto).
- **PR #255 (`vera`, Pricing CSV):** abierto en Draft (`1215c4df4b6c1595b550d24f7ef599ffbbb14795`), conservado como dependencia externa pendiente sin modificar ni simular.

## 2. Estado de rutas Gateway y contrato

- **Registro base (`CONTRACT_ROUTES`):** 147 entradas, incluyendo `conciliarImportacionGeneralPorCorrelacion` (Bulk), `listarAlertasOperativasInventario` y `listarUbicacionesInventario` (Inventory H01/H02).
- **Overlay G5 H5 (`G5_H5_ROUTES`):** 4 rutas protegidas (`admitirConsumoCuponH5`, `admitirRestauracionCuponH5`, `obtenerOperacionCuponH5`, `obtenerEstadoReservaH5`), apagadas por defecto.
- **Exclusiones internas (5 operaciones):** `obtenerContextoSku`, `obtenerContextosSkuLote`, `filtrarSkusVendiblesInterno`, `obtenerEvidenciaReservaCuponInterno`, `obtenerContenidoCargaMasivaInternoH5` devuelven `404` en Gateway y no se importan en APIM.
- **Excepciones históricas Pricing (2 operaciones):** `obtenerDefinicionPrecioProductoAdministracion` y `obtenerDefinicionPrecioSkuAdministracion` se conservan en Gateway protegidas con `userBearer`/`GESTOR_COMERCIAL` y quedan fuera de la importación contractual APIM hasta decisión de regularización documental.

## 3. Publicación APIM, manifiesto enriquecido y perfiles

- `ops/azure/apim/filter-openapi.py` separa `contractInventory`, `gatewayStaticRegistry` y `operations` publicables (145 operaciones por defecto).
- El manifiesto `operation-security.json` registra `authSchemes`, `identityType` (`public` | `human` | `m2m`), `issuerRequired`, `audienceRequired`, `audience`, `scopes`, `roles`, `allowedClients`, `introspectionRequired`, `exposureProfile`, `rateProfile` y `environmentEnabled`.
- Los tokens humanos (`userBearer`) no exigen audiencia técnica salvo declaración contractual; los tokens M2M (`serviceBearer`) exigen `x-service-audience` y `x-required-scope`.
- `--enable-g5` requiere `--g5-authorized` explícito para incluir rutas G5 en el artefacto APIM.
- Perfiles parametrizados en `main.bicep` (`rateProfiles`): `commercial_read`, `admin_read`, `business_write`, `multipart_import`, `expensive_export`, `g5_protected` (con `rate-limit-by-key`, `quota-by-key` y `limit-concurrency`).

## 4. Correlación, CORS, red privada, anti-bypass y rollback

- `api.xml` valida `X-Correlation-Id` como UUID (genera si falta; rechaza `400 VALIDACION` si es inválido o duplicado), lo propaga en `<inbound>`, `<outbound>` y `<on-error>`, expone `Content-Disposition`, `Location`, `Retry-After` y `X-Correlation-Id` en CORS sin wildcard, y desactiva buffering de cuerpo (`buffer-request-body="false"`).
- `main.bicep` soporta aprovisionamiento `Developer` de laboratorio o reutilización de instancia compatible (`reuseExistingApim`), y configura Application Insights con `bytes: 0` para request/response bodies.
- Inventario Azure (solo lectura, 25/11/2026): sin instancia APIM (`Microsoft.ApiManagement: NotRegistered`), sin Application Insights ni Private DNS zones; `env-g6-phase1-chile` con `vnetConfiguration: null`; `api-gateway` con `external: true` e `ipSecurityRestrictions: null`; los 8 microservicios con `external: false`; `AZURE_CHILE_DEPLOY_ENABLED=false`.
- Rollback reversible mediante conservación de revisión previa, `operationSetSha256` y hashes de políticas XML.

## 5. Matriz de evidencia H5 (APIM-T01–T08 y RL-01–RL-06)

| ID | Criterio canónico | Estado actual |
|---|---|---|
| APIM-T01 | HTTPS hacia operación autorizada y owner esperado | `NOT_RUN` / `BLOCKED_INFRA` (sin instancia APIM) |
| APIM-T02 | JWT válido e inválido (`401`) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T03 | Scope y cliente incorrectos (`403`) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T04 | CORS orígenes explícitos y cabeceras expuestas | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T05 | Antiabuso integral, burst, cuota, aislamiento, concurrencia y anti-bypass | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T06 | Ruta desconocida o privada (`404`) | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T07 | Correlación `X-Correlation-Id` | `NOT_RUN` / `BLOCKED_INFRA` |
| APIM-T08 | Comparación privada y rollback | `NOT_RUN` / `BLOCKED_INFRA` |
| RL-01..RL-06 | Escenarios k6 de tasa, cuota, concurrencia, aislamiento y anti-bypass | `NOT_RUN` / `BLOCKED_INFRA` |
