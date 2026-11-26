# Fallos pendientes — G6 H5 R2 (Cierre Iteración 6)

> Detenidos tras completar el máximo de **2 iteraciones autónomas** permitidas.

## 1. Certificador 158 endpoints (`152/158 PASS`, 6 `FAIL`)

1. **`[109/158] reanudarImportacionGeneral` (`async=false`, `pers=FAIL`) y `[158/158] gatewayReadiness` (`503 catalog-svc: not_ready`):**
   - **Error exacto en `certify-stack.log` (líneas 1811–1855):**
     `[catalog-service-bus] consume error on g6.catalog.from.bulk: ServiceUnavailableException: Service Unavailable at CatalogBulkService.consumeRetryV4 (catalog-bulk.service.ts:650-668)`
   - **Causa:** `CatalogBulkService.consumeRetryV4` llama `this.identity.authorizationForBulkRetry(...)` y ante un error no clasificado como `TRANSIENT` (o ausencia de credencial/token válido en esa ruta) lanza `ServiceUnavailableException`, lo que provoca `reportError()` (`catalog-svc: not_ready`) y `abandonMessage` dejando el mensaje `schema=4` en `g6.catalog.from.bulk`.
   - **Archivos:** `backend/apps/catalog-svc/src/catalog-bulk.service.ts:649-669`, `backend/apps/catalog-svc/src/catalog-pricing-identity.ts:193-215`.

2. **`[114/158] actualizarUmbralGlobal` (`http=200`, `pers=FAIL`):**
   - **Causa:** La verificación SQL en `backend/tests/h5/certify-158-endpoints.mjs:1120` consulta `SELECT key, value FROM inventory.inventory_config LIMIT 1` esperando que `JSON.stringify(rows[0]?.value)` contenga `"5"`, lo cual falla si el primer registro devuelto no es la clave de umbral global o su estructura difiere.
   - **Archivo:** `backend/tests/h5/certify-158-endpoints.mjs:1120`.

3. **`[30/158] obtenerProductoPorSlug` (`neg=FAIL(503)`), `[100/158] listarAuditoriaPrecios` (`neg=FAIL(503)`), `[45/158] listarCupones` (`neg=FAIL(200)`):**
   - **Causa:** Al habilitar pruebas negativas para todos los `GET` con query/parámetros en Iteración 2:
     - `[30]` (`/api/v1/productos/por-slug/slug-inexistente-...` sin `?canal=MARKETPLACE`) y `[100]` (`/api/v1/auditoria-precios` sin `?sku=...`) devolvieron `503` (el certificador esperaba `[400, 404]`). En `[30]`, la ruta requiere `?canal=MARKETPLACE` para evaluar `404` por slug; `[100]` sin `sku` falló con `503`.
     - `[45]` (`/api/v1/cupones` sin `?codigo=...`) devolvió `200` (listado completo válido), porque `codigo` es filtro opcional en `listarCupones`.
   - **Archivo:** `backend/tests/h5/certify-158-endpoints.mjs:1235-1255`.

## 2. Certificador 19 recorridos Service Bus (`certify-19-messaging-flows.mjs`)

- **Error exacto:** `Error: ACTIVATION_CHECKS_NOT_COMPLETED for f621928e-338b-4f17-b293-70cbe6ca57d0` (`certify-19-messaging-flows.mjs:194`).
- **Causa probable:** El producto administrativo `admProdId` no alcanzó `2` filas en `catalog.activation_checks` con `state = 'COMPLETED'` dentro de la ventana de polling (`40 x 300ms = 12s`), o bien R11 (`inventory-svc -> catalog-svc`) / R15 (`pricing-svc -> catalog-svc`) quedó pendiente tras la creación administrativa en esa ejecución.
- **Archivo:** `backend/tests/h5/certify-19-messaging-flows.mjs:188-194`.
