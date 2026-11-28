# Diagnóstico Consolidado de Defectos, Auditoría Frontend y Brechas H5

Este documento mantiene la trazabilidad consolidada de Hito 5 en `G6-Productos-Ofertas-docs` sin duplicar la documentación técnica de implementación de Backend.

## 1. Distribución de PRs (todos en Draft, cero colisión con `#310` y `#103`)

- **Docs [#154](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/154)** (`poma-hito-5-pruebas-v2`): Evidencias históricas intactas, traza ACA de Axel, matrices y trazabilidad consolidada.
- **Backend [#313](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/313)** (`poma-hito-5-pruebas-v2`): Harness ejecutable Postman/Newman (`tests/h5/postman/`), cierres `H11`–`H22`, equivalencias auténticas de Catalog (`H16`) y Newman sobre servicios reales (`H19`).
- **Backend [#314](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/314)** (`trabajo/poma/h5-apim-errores-autenticacion`): Corrección independiente de **Defecto A** (APIM 401 RFC 7807 exclusivo para `validate-jwt`).
- **Backend [#315](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/315)** (`trabajo/poma/h5-bulk-autenticacion`): Corrección independiente de **Defecto C** (`BulkUserBearerGuard` coherente con JWT humano G7).
- **Frontend (`G6-Productos-Ofertas-frontend`):** Sin PR (auditado funcionalmente sin defectos).

---

## 2. Estado diferenciado de defectos y brechas

| Tema | Hipótesis / Causa raíz | Reproducción y corrección local | Estado actual |
|---|---|---|---|
| **Defecto A** (`PM-004`/`004B` APIM 401) | `<validate-jwt>` en `operation-secured.xml` sin `<on-error>` RFC 7807 en `api.xml`. | Parche en `api.xml` filtrado por `LastError.Source == "validate-jwt"` y `StatusCode == 401` + test en `test_apim_artifacts.py` (`26/26 PASS`) — **PR #314**. | `PASS / ISOLATED` (confirmación live en `STANDBY`). |
| **Defecto B** (`PM-012` Inventory 400) | `disponibilidad.service.ts` exige `location_id` con `>1` ubicación (comportamiento contractual; causa histórica live sigue como hipótesis hasta confirmación real). | Reproducidos los 4 escenarios en `runner.test.mjs` (`1` ubicación sin `location_id`, multi-ubicación sin `location_id` → `400`, multi-ubicación con `locationId` explícito → `200`, ubicación sin saldo) — **PR #313**. | `PASS / MOCK` (confirmación live en `STANDBY`). |
| **Defecto C** (`PM-030`/`031` Bulk 401) | `BulkUserBearerGuard` exigía `aud === 'api-productos'` en JWT humano `tipo === 'acceso'` (G7 no emite `aud` en perfil humano). | Corregido en `bulk-user-bearer.guard.ts` permitiendo `aud === undefined` y preservando rechazo `401` si `aud` es inválido y `403` por rol insuficiente (`13/13 PASS` con RS256 sintético) — **PR #315**. | `PASS / ISOLATED` (confirmación live en `STANDBY`). |
| **Brechas Catalog H5 (`H16`)** | 6 escenarios históricos del `#310` (`TAXONOMY-UPDATES`, `BLOCK-A2`, `JOINT-01`, `JOINT-01-REGRESSION`, `BULK-JOINT`, `BULK-CONSUMER-v2`). | Acreditados sobre código productivo real (`CatalogMutationService`, `CatalogBulkService`, `CatalogMessageService`, `relayCatalogDelivery`) + **PostgreSQL 17 descartable** con migraciones oficiales (`5/5 PASS`) — **PR #313**. | `PASS / ISOLATED (PostgreSQL 17 descartable)`. |
| **Servicios reales locales (`H19`)** | Newman ejecutado contra `api-gateway` + `catalog-svc` reales y PG17 descartable (`catalog-h5-newman-real.postgres.e2e-spec.ts`). | `PM-001` (`200`), `PM-004`/`004B` (`401`), `PM-006` (`404`), `PM-007A`/`007B` (`400`), `PM-008` (`404`) aprobados con validación Ajv OpenAPI; `PM-001B` devolvió `503` esperado al no levantarse los otros 7 microservicios y `PM-005` quedó `NOT_RUN`. | `PASS / ISOLATED (servicios reales + PG17)`. |
| **Auditoría Frontend (Sección 10)** | Verificación del manejo de `401`, `403`, `500`, descargas y refresco de sesión en `authenticatedGatewayClient.ts` y `authenticatedCatalogTransport.ts`. | Suite completa de Frontend ejecutada: **`781+` pruebas PASS (`0` fallos)** (`auth.test.ts` 55, `readOnlyClient.test.ts` 17, `authenticatedGatewayClient.test.ts` 9, `publicReads.test.ts` 8, `g7OnlyTransport.spec.ts` 4, `bulk.unit.test.ts` 98, inventario 132, pricing 166, taxonomy 111, release-policy 35). Frontend intenta refresco en `GET 401`, preserva sesión en `403`/`500` y solo invalida tras reintento `401 TOKEN_INVALIDO`. | Sin defecto funcional; no corresponde PR en Frontend. |

---

## 3. Nota histórica `H11` y validaciones reales en `STANDBY`

- Las evidencias históricas del `2026-11-27` y `2026-11-28` en `evidencias/` se preservan **sin modificación** (sus SHA-256 permanecen intactos). El conteo histórico (`12` vs `11` en `smoke`, `33` vs `32` en `integration`) corresponde a la llamada auxiliar de paginación de `PM-003A` acreditada en `evidencias/azure-apim-smoke-jws-2026-11-28/TRAZA-DOWNSTREAM-CATALOG-PRICING.md`, y está separado en el runner de Backend PR #313.
- **Validaciones reales en `STANDBY`:** Re-ejecución de `smoke`/`integration` contra APIM Chile tras despliegue de PRs `#314` y `#315`, ejecución live de `PM-005` (`403`) y `PM-080`/`PM-081`/`PM-082` (tokens M2M reales).
