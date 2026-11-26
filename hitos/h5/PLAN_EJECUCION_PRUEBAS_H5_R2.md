# Plan de Ejecución de Pruebas — G6 H5 R2

> **Estado actual:** `PRUEBAS_ESCRITAS_NO_EJECUTADAS` (**NO GO** hasta nueva auditoría independiente). La ejecución requiere autorización expresa de Marco tras la auditoría estática. Ningún emisor ni transporte aislado de laboratorio acredita homologación G7 real, homologación G5 real ni ejecución funcional de las 19 colas.

## 1. Requisitos previos y aislamiento

- **PostgreSQL descartable local / CI:** contenedores Docker PostgreSQL 16 efímeros creados por cada suite (`IsolatedPostgres` en Pricing, `IsolatedBulkPostgres` en Bulk) en `127.0.0.1`. **Prohibido** apuntar `DATABASE_URL` o `G6_REAL_PG_URL` al proyecto Supabase compartido `slzglmtiyrzygpkiuthf`.
- **Identidad G7:** las suites locales usan emisores RS256 criptográficos con servidor HTTP JWKS local (`startLocalG7Server` / `createSignedIdentity`, `tipo: 'acceso'`, `sub` UUID v4); nunca equivalen a emisión real de G7 ni a homologación G1/G3/G5.
- **Azure Service Bus real:** desactivado por defecto (`G6_AZURE_SERVICE_BUS_REAL_TESTS` ausente). `tests/h5/azure-service-bus.real.e2e-spec.ts` envía `g6.lab.probe` como sonda genérica de transporte SDK (no acredita 19 recorridos de negocio).
- **Frontend real (`playwright.real.config.ts`):** ejecuta `node tests/e2e-real/startRealStackAndVite.mjs` (sin dependencias externas como `tsx`), el cual crea un contenedor Docker PostgreSQL 16 arrancado directamente con `-c ssl=on` (`SHOW ssl` verificado) y certificado TLS `SAN=IP:127.0.0.1`, provisiona roles `po_<svc>_owner` (`NOLOGIN`) y roles runtime separados (`taxonomy_app`, `catalog_app`, `pricing_app`, `price_audit_app`, `price_audit_archiver`, `po_promotions_runtime`/`promotions_app`, `combos_app`, `inventory_app`, `bulk_app`), aplica por `spawn` (`stdin` directo a `psql` con `ON_ERROR_STOP=1`) los SQL oficiales de `docs/datos` y migraciones de cada microservicio bajo `SET LOCAL ROLE`, siembra la ubicación `CENTRAL` en `inventory.locations`, inicia el emisor RS256 G7/JWKS único (`startSingleLocalG7Server` con `POST /api/v1/auth/token` en `camelCase` y matriz explícita de scopes por cliente) y el simulador HTTPS verificable de contrato G5 (`startLocalG5EvidenceServer` con certificado TLS dedicado vía `NODE_EXTRA_CA_CERTS` exclusivo para `promotions-svc`, validación criptográfica RS256 del bearer técnico `api-ventas` y servidor HTTP seed separado en loopback), levanta los 8 microservicios con sus variables `PG*`/`DATABASE_URL` específicas (incluyendo `G7_JWT_ISSUER` y `G7_JWT_JWKS_URL` en `inventory-svc`, `G6_DATABASE_SCHEMA=promotions`, `G6_CONNECTION_MODE=session`, `PROMOTIONS_H5_ISOLATED_BUS=1` en `NODE_ENV=test` sin `RABBITMQ_URL`, `GATEWAY_CATALOG_SVC_URL`, `GATEWAY_INVENTORY_SVC_URL`, `PROMOTIONS_G5_COUPON_EVIDENCE_ORIGIN` y credenciales técnicas H5) y Gateway con `GATEWAY_CORS_ALLOWED_ORIGINS=http://127.0.0.1:<port>`, y arranca Vite con `VITE_DATA_MODE=api`, `VITE_G6_ADMIN_API_ENABLED=true`, `VITE_GATEWAY_ORIGIN` y `VITE_G7_API_BASE`. Las pruebas usan navegación SPA real, polling acotado de exportaciones CSV, lotes Bulk (exigiendo `COMPLETED` con conteo íntegro de filas en el caso positivo y validando `FAILED_GENERAL` por separado) y recorrido transversal causal completo (maestros Taxonomy, producto simple `skuBase` en Catalog, promoción `CUPON` + cupón, stock y reserva Inventory hasta `COMPLETED` verificando `ACTIVA`/`VIGENTE`, snapshot G5 HTTPS, consumo/restauración N01 y rechazos aislados `COUPON_NOT_ELIGIBLE`).

## 2. Orden obligatorio de ejecución futura (PowerShell)

### Fase 1 — Pruebas unitarias y contratos (sin BD ni red)
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\backend
npm test -- apps/api-gateway/src/routing/gateway-g7-only.spec.ts apps/api-gateway/src/routing/gateway-public-reads.spec.ts apps/api-gateway/src/routing/gateway-identity.spec.ts
npm test -- apps/*/src/phase1-public-reads.spec.ts apps/catalog-svc/src/catalog-public-reads.spec.ts apps/taxonomy-svc/src/taxonomy-public-reads.spec.ts apps/taxonomy-svc/src/category-seo-auth.spec.ts apps/combos-svc/test/combos-readiness.spec.ts
npm test -- apps/inventory-svc/src/inbox/inventory-command.spec.ts apps/pricing-svc/src/messaging/r03-r14-r15-r17-r07.spec.ts
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\frontend
npx vitest run src/features/auth/g7OnlyTransport.spec.ts src/features/combos/adapters/httpCombosRepositoryH4.test.ts
```

### Fase 2 — Integraciones PostgreSQL por microservicio
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\backend
$env:PRICING_TEST_POSTGRES='1'; npm run test:e2e -- apps/pricing-svc/test/import-prices.postgres.e2e-spec.ts apps/pricing-svc/test/r03-r14-r16-r17.postgres.e2e-spec.ts
$env:BULK_TEST_POSTGRES='1'; npm run test:e2e -- apps/bulk-svc/test/r03-pricing-r14-bulk.postgres.e2e-spec.ts
$env:G6_TAXONOMY_H5_POSTGRES_TESTS='1'; npm run test:e2e -- tests/h5/taxonomy-service-bus.postgres.e2e-spec.ts
```

### Fase 3 — Integraciones Service Bus con handlers reales y topología 19/19
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\backend
npm test -- tests/h5/service-bus-19-queues.e2e-spec.ts
```

### Fase 4 — Autenticación y autorización G7 simuladas (JWKS local RS256)
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\backend
npm run test:e2e -- apps/api-gateway/test/public-read-only.e2e-spec.ts apps/api-gateway/test/g7-transversal-r2.e2e-spec.ts apps/api-gateway/test/g5-h5-routes.e2e-spec.ts apps/api-gateway/test/routing.e2e-spec.ts
```

### Fase 5 — Integración HTTP Frontend ↔ Gateway ↔ Backend
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\frontend
$env:VITE_DATA_MODE='api'
npx playwright test --config=playwright.real.config.ts tests/e2e-real/http-contracts.real.spec.ts
```

### Fase 6 — E2E navegador React real, ocho módulos y flujos transversales
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\frontend
$env:VITE_DATA_MODE='api'
npx playwright test --config=playwright.real.config.ts tests/e2e-real/eight-modules.real.spec.ts tests/e2e-real/transversal-flows.real.spec.ts
```

### Fase 7 — Pruebas Azure Service Bus SDK real aisladas (laboratorio 19 colas)
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\backend
$env:G6_AZURE_SERVICE_BUS_REAL_TESTS='1'
$env:G6_AZURE_SERVICE_BUS_LAB_NAMESPACE='<lab-namespace>.servicebus.windows.net'
$env:AZURE_CLIENT_ID='<managed-identity-client-id>'
npm run test:e2e -- tests/h5/azure-service-bus.real.e2e-spec.ts
```

### Fase 8 — Homologación externa G7/G1/G3/G5 (cuando se autorice)
- Validación de tokens emitidos por G7 real y tráfico homologado G1 Marketplace, G3 Chatbot y G5 Ventas sin alterar el tráfico productivo por defecto hasta autorización expresa.
