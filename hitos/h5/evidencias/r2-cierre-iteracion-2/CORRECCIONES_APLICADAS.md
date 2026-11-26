# Correcciones Aplicadas — G6 H5 R2 (Iteraciones 1 y 2)

## Backend
- `apps/combos-svc/src/http/combos-auth.ts`: `COMBOS_ALLOWED_CLIENTS_COMBOS_READ` restringido a intersección (subconjunto) de `['modulo-marketplace', 'modulo-chatbot', 'modulo-retail']`, impidiendo ampliar la allowlist por variable de entorno.
- `apps/inventory-svc/src/conciliacion/offline-reconciliation.service.ts`: exigido el claim `store_ref` del JWT de `modulo-ventas`; eliminada la autorización por `bodyStoreRef` o `location_id` sin claim.
- `apps/inventory-svc/src/messaging/service-bus-consumer.ts`: validado `INVENTORY_SB_MAX_TRANSIENT_DELIVERIES` como entero positivo seguro (default `15`), enviando a DLQ (`TRANSIENT_RETRY_EXHAUSTED`) al agotar reintentos y añadiendo logs JSON estructurados (`message_id`, `event`, `queue`, `sku`, `location_id`, `correlation_id`, `delivery_count`).
- `apps/bulk-svc/src/messaging/bulk-service-bus.ts`: dead-letter explícito ante `BulkDomainError` con `code === 'INVALID_TRANSITION'` para evitar bucles infinitos cuando llegan resultados tardíos tras el cierre terminal de un lote.
- `apps/catalog-svc/src/catalog-query.service.spec.ts`, `catalog-price-filter.spec.ts`, `catalog-read-demo.spec.ts` y `apps/inventory-svc/src/auth/g7-jwks.spec.ts`: alineadas 6 aserciones obsoletas H4 (`PUBLIC_READ_ONLY` y firma de `listVariants`) con H5.
- `tests/h5/certify-158-endpoints.mjs`:
  - Corregido `FormData` en `httpCall` eliminando `content-type: application/json` heredado (`priceImportRes` multipart).
  - Eliminado `inventario:conciliar-offline` del token `modulo-retail`.
  - Seed real de `[109]` mediante fallo transitorio G7 `503` sobre `modulo-productos` (`catalogo:leer`) antes de poblar `CatalogBulkIdentity.cached` (sin editar estados en SQL).
  - `verifyPgPersistence()` con aserciones SQL específicas y `NOT_VERIFIED` con `ok: false`.
  - Reporte `SETUP_FAILED` en fallos de arranque/seed y guardado de `certify-stack.log` en `catch`.
- `tests/h5/certify-19-messaging-flows.mjs`: creado runner de integración para R01–R18 y N01 sobre stack real + PostgreSQL + Service Bus aislado (pendiente de corrección `https` en `httpCall`).

## Frontend (laboratorio)
- `tests/e2e-real/startRealStackAndVite.mjs`:
  - Agregado `CATALOG_BULK_RESULT_V2_ENABLED: "true"` y `CATALOG_DEFAULT_LOCATION_ID` a `catalog-svc`.
  - Agregado `store_ref: "TIENDA-CERT-01"` al token de `modulo-ventas` y removido `inventario:conciliar-offline` de `modulo-retail`.
  - Agregado hook `/__test/g7-fail-next-catalog-token` en G7 y `/__test/pg-query` con `pgQuery` inyectado desde `main()`.
