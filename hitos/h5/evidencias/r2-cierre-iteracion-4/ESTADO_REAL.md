# Estado Real — G6 H5 R2 (Cierre Iteración 4 / 2 Iteraciones)

- **Fecha:** 2026-11-26
- **Entorno:** Windows, `Node v24.3.0`, `npm 11.4.2`, PostgreSQL local en contenedor, Service Bus aislado en memoria HTTP, G7 RS256/JWKS de laboratorio, simulador G5 HTTPS local.
- **Rama:** `trabajo/castilla/h5-integral-r2`
- **Playwright:** **EXCLUIDO** por instrucción expresa.
- **Azure Service Bus real / Supabase compartido:** **NO EJECUTADO / NO MODIFICADO**.
- **Estado final:** `LOCAL_G6_GO = FALSE`

## Cifras verificables

| Dimensión | Resultado real observado |
|---|---|
| Certificación 158 operaciones (`certify-158-endpoints.mjs`) | **149 PASS / 9 FAIL / 0 BLOCKED / 0 NOT_RUN** (`158/158` ejecutadas) |
| Auth G7 (`authChecks`) | **6/6 PASS** |
| Consumo cupón seed N01 (`n01ConsumeStatus`) | **COMPLETED** |
| Conciliación venta offline (`[128]`) | **HTTP 200 COMPLETED** (`on_hand: 29`, `neg: 400 PASS`; falló SQL `kardex.reference_id`) |
| Reintento preparación producto (`[32]`) | **PASS** |
| Suite topología Service Bus (`service-bus-19-queues.e2e-spec.ts`) | **3/3 PASS** (Bicep, 19 colas sin fallback RabbitMQ, 256 KB + DLQ + R10/R14 + Readiness) |
| Suite funcional 19 recorridos (`certify-19-messaging-flows.mjs`) | **FAIL** en setup de producto administrativo (`admProdId = undefined`, HTTP 500 controlado en `/__test/pg-query`) |
| Compilación / Typecheck / Lint (`backend`) | `typecheck` **PASS**, `build:all` **PASS**, `lint` **PASS** (0 errores) |
| Pruebas unitarias (`npm test`) | **2876 passed / 40 failed / 114 skipped** (252 archivos: 225 passed, 25 failed, 2 skipped; **0 errores de colección**) |
| Playwright E2E Frontend | **NO_EJECUTADO** (excluido por instrucción) |
