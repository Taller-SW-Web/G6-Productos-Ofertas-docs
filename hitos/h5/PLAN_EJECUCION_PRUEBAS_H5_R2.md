# Plan de Ejecución de Pruebas — G6 H5 R2

> **Estado actual:** `PRUEBAS_ESCRITAS_NO_EJECUTADAS`. La ejecución requiere autorización expresa de Marco tras la auditoría estática.

## 1. Requisitos previos y aislamiento

- **PostgreSQL descartable local / CI:** Docker PostgreSQL 17 aislado por suite (`Phase1Postgres` / contenedores efímeros). **Prohibido** apuntar `DATABASE_URL` al proyecto Supabase compartido `slzglmtiyrzygpkiuthf`.
- **Identidad G7:** las suites locales usan emisores RS256 criptográficos de prueba (`createSignedIdentity`, `createCryptographicJwt`); nunca equivalen a emisión real de G7 ni a homologación G1/G3/G5.
- **Azure Service Bus real:** desactivado por defecto (`G6_AZURE_SERVICE_BUS_REAL_TESTS` ausente). Solo ejecutar contra namespace de laboratorio con Managed Identity autorizada.

## 2. Orden de ejecución recomendado (PowerShell)

### Fase A — Unitarias y contratos sin BD ni red
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\backend
npm test -- apps/api-gateway/src/routing/gateway-g7-only.spec.ts apps/api-gateway/src/routing/gateway-public-reads.spec.ts apps/api-gateway/src/routing/gateway-identity.spec.ts
npm test -- apps/*/src/phase1-public-reads.spec.ts apps/catalog-svc/src/catalog-public-reads.spec.ts apps/taxonomy-svc/src/taxonomy-public-reads.spec.ts apps/taxonomy-svc/src/category-seo-auth.spec.ts apps/combos-svc/test/combos-readiness.spec.ts
npm test -- tests/h5/service-bus-19-queues.e2e-spec.ts apps/pricing-svc/src/messaging/r03-r14-r15-r17-r07.spec.ts
```

### Fase B — Frontend unitario/contratos
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\frontend
npx vitest run src/features/auth/g7OnlyTransport.spec.ts src/features/combos/adapters/httpCombosRepositoryH4.test.ts
```

### Fase C — E2E con PostgreSQL descartable y HTTP real local
```powershell
cd c:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\backend
npm run test:e2e -- apps/api-gateway/test/public-read-only.e2e-spec.ts apps/api-gateway/test/g7-transversal-r2.e2e-spec.ts apps/api-gateway/test/routing.e2e-spec.ts
$env:PRICING_TEST_POSTGRES='1'; npm run test:e2e -- apps/pricing-svc/test/import-prices.postgres.e2e-spec.ts
$env:G6_TAXONOMY_H5_POSTGRES_TESTS='1'; npm run test:e2e -- tests/h5/taxonomy-service-bus.postgres.e2e-spec.ts
```

### Fase D — Azure Service Bus SDK real (laboratorio 19 colas, opcional bajo autorización)
```powershell
$env:G6_AZURE_SERVICE_BUS_REAL_TESTS='1'
$env:G6_AZURE_SERVICE_BUS_LAB_NAMESPACE='<lab-namespace>.servicebus.windows.net'
$env:AZURE_CLIENT_ID='<managed-identity-client-id>'
npm run test:e2e -- tests/h5/azure-service-bus.real.e2e-spec.ts
```
