# Estado Actual — Checkpoint G6 H5 R2

- **Fecha del checkpoint:** 2026-11-26T13:23:10-05:00
- **Rama activa (los 3 repositorios):** `trabajo/castilla/h5-integral-r2`
- **Estado general:** `LOCAL_G6_GO = FALSE` (`154/158` endpoints aprobados en certificación local aislada; `4` fallos reales pendientes; Playwright pendiente de re-ejecución tras los últimos arreglos de backend; suite aislada de 19 colas Service Bus pendiente de ejecución).

## 1. Qué se implementó / reparó

### Backend
- **Catalog (`apps/catalog-svc`):**
  - Montado `POST /interno/productos/skus/filtrar` (`catalog-internal-sku.controller.ts`, `catalog-query.controller.ts`, `catalog-query.service.ts`, `catalog-query.repository.ts`, `app.module.ts`) con paginación por cursor, filtros y autenticación interna RS256/scope.
  - Agregado `'bulk-svc'` a `allowedClients` en `listarProductos` (`commercial.controller.ts`) para exportación masiva vía HTTP.
  - Ajustes en `catalog-bulk.service.ts`, `catalog-bulk-content.ts`, `catalog-master.client.ts`, `catalog-pricing-identity.ts` y `catalog-service-bus.ts` para flujo claim-check v3 y preparación de SKUs.
- **Inventory (`apps/inventory-svc`):**
  - Montado `POST /api/v1/inventario/conciliaciones-offline` en `inventory.controller.ts` delegando a `offline-reconciliation.service.ts` y `types/inventory.dto.ts`.
  - Agregada ruta `'g6.bulk.from.inventory'` en `migrations-candidate/h5/0001_outbox_delivery.sql`.
  - Reintento ante `SKU_LOCATION_NOT_FOUND` (`SKU_LOCATION_NOT_INITIALIZED_YET`) en `inbox/inventory-command.service.ts` y backoff de `300 ms` en `messaging/service-bus-consumer.ts` bajo `G6_ISOLATED_SERVICE_BUS_URL`.
- **API Gateway (`apps/api-gateway`):**
  - Expuesto `GET /health/ready` en `api-gateway.controller.ts` + pruebas en `api-gateway.controller.spec.ts` y ajustes en `routing/contract-routes.ts`. Reporta estado real de los 8 microservicios (`158` `gatewayReadiness` PASS).
- **Bulk (`apps/bulk-svc`):**
  - Corregida inyección opcional `@Optional() @Inject(BulkStorageService)` en `bulk-export.service.ts` e incorporada fuente HTTP `export/http-bulk-export-source.ts` (`110` y `112` PASS).
  - Expuesto `GET /health/ready` en `bulk-svc.controller.ts`.
  - Evitado teardown de suscripción ante `DEPENDENCY_PENDING` en `messaging/bulk-service-bus.ts`.
  - Soportado claim-check `schema_version === 3` en `recordCatalogBulkResult`, lectura de precio en `PRICE_BULK_APPLY` y ajuste de stock en `persistence/bulk.repository.ts`.
  - Agregada migración `migrations/0009_h5_outbox_delivery_all_destinations.sql` y configuración `defaultLocationId` (`BULK_DEFAULT_LOCATION_ID`) en `bulk-import.service.ts`.
- **Taxonomy (`apps/taxonomy-svc`):**
  - Implementado cliente aislado de Service Bus para laboratorio (`NODE_ENV === 'test' && G6_ISOLATED_SERVICE_BUS_URL`) en `domain/taxonomy-service-bus.runtime.ts` y ajustes en `database.ts` (`[73]`, `[74]`, `[80]–[84]`, `[87]`, `[90]` PASS).
- **Combos (`apps/combos-svc`), Pricing (`apps/pricing-svc`), Promotions (`apps/promotions-svc`):**
  - Ajustes en `combos-svc.controller.ts`, `combos-svc.service.ts`, `http/combos-auth.ts`.
  - Ajustes en `pricing-svc/src/messaging/outbox-relay.ts` y `service-bus-relay.ts`.
  - Ajustes en `promotions-svc/src/coupons/authoritative-coupon-evidence.ts`, `coupon-h5-delivery.ts`, `coupon-h5-operations.ts`, `coupon-h5-runtime.ts`, `g5-coupon-snapshot.ts` (flujo N01 consume completado en seed).
- **Certificador (`tests/h5/certify-158-endpoints.mjs`):**
  - Separación de dimensiones (`ROUTE_SECURITY_PASS`, `NEGATIVE_CONTRACT_PASS`, `FUNCTIONAL_PASS`, `PERSISTENCE_PASS`, `ASYNC_TERMINAL_PASS`), verificación de estado terminal en `202`, exit code distinto de cero ante fallos y corrección de fixtures.

### Frontend (`tests/e2e-real/startRealStackAndVite.mjs`)
- Conectadas variables de Service Bus aislado para `taxonomy-svc` (`TAXONOMY_SERVICE_BUS_*`), `BULK_DEFAULT_LOCATION_ID` para `bulk-svc`, y `seedCatalogPendingPreparation` en el stack real de laboratorio.

### Docs (`contratos/http/openapi.yaml`)
- Actualización contractual alineada con R2 en `contratos/http/openapi.yaml`.

## 2. Qué funciona actualmente (evidencia observada)
- **154 de 158 operaciones HTTP** pasaron todas las dimensiones en `158_ENDPOINTS_CERTIFICATION_REPORT.json` (`2026-11-26T18:12:26.464Z`).
- **Auth checks (G7 simulado):** `6/6` PASS (`login_gestor`, `login_sinrol`, `login_bad_password_401`, `login_blocked_401`, `refresh_rotate_200`, `refresh_reuse_401`).
- **Gateway readiness (`/health/ready`):** `200` con los 8 servicios en `"ready"`.
- **N01 cupón consumo (caso seed):** `n01ConsumeStatus = "COMPLETED"`.
- **Bulk exportación general (`[110]`, `[112]`):** `PASS`.
- **Bulk pasos `CATALOGO` y `PRICING` en V2 CSV (`[106]`):** alcanzan estado `COMPLETED`.
- **Taxonomy flujos asíncronos de desactivación (`[73]`, `[74]`, `[80]–[84]`, `[87]`, `[90]`):** `PASS`.
- **Catalog reintento de variante (`[40]` `reintentarPreparacionVariante`):** `PASS`.

## 3. Qué falta para completar R2
1. Resolver los **4 fallos reales** en `certify-158-endpoints.mjs`: `[32]`, `[106]`, `[109]`, `[148]`.
2. Limpiar logs temporales de diagnóstico (`console.error`) agregados durante la depuración en servicios backend antes de la certificación final.
3. Ejecutar y certificar la suite de **19 colas Service Bus** (`tests/h5/service-bus-19-queues.e2e-spec.ts` / R01–R18, N01).
4. Re-ejecutar y corregir los **13 fallos previos de Playwright** en `frontend` hasta obtener `16/16 PASS`.
5. Actualizar las matrices en `docs/hitos/h5/MATRIZ_*.csv` y `asyncapi.yaml` tras pasar las suites finales, y ejecutar `typecheck`, `build:all`, `lint` y `test` en limpio.
