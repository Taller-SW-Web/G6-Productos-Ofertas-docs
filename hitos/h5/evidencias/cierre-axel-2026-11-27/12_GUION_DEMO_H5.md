# Guion de Demostración Técnica — G6 Productos y Ofertas (Hito 5)

> **Duración sugerida:** 10–12 minutos. **Regla de transparencia:** distinguir explícitamente en cada bloque lo acreditado en **CI / Laboratorio Aislado (L1)** de lo auditado en **Azure solo lectura (L2 parcial)** y lo pendiente de autorización externa (**L2 mutante / L3 intergrupo**).

## Bloque 1 — Gobernanza, Contratos y CI/CD Multi-Repositorio (`H5-01`, 2 min)
1. Mostrar contratos normativos `0.7.0-rc.3` en `G6-Productos-Ofertas-docs` (`5f308021`, 156 operaciones OpenAPI, 19 canales AsyncAPI) y corrida verde Docs CI (`#46031816661`).
2. Mostrar los tres PRs Draft consolidados y sus corridas CI en verde sin despliegue prematuro:
   - Backend Draft `#307` (`18413ac4...`) — CI [`#46044277201`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46044277201): **22/22 jobs PASS** (incl. 9 imágenes Docker + PG TLS + Marketplace + APIM ARM estático + Inventory/Taxonomy/Combos/Promotions/Pricing).
   - Frontend Draft `#102` (`ccfc21ba...`) — CI [`#46028914883`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46028914883): **21/21 jobs PASS** (incl. **Gitleaks 8.30.1** + SCA H5 + build `VITE_DATA_MODE=api` + 4 shards Playwright + Pricing E2E).
   - Evidencias SBOM CycloneDX 1.5 (`artefactos/sbom-backend.cdx.json` y `artefactos/sbom-frontend.cdx.json`) y brechas documentadas de GitHub Advanced Security (CodeQL/Secret Scanning `404`).

## Bloque 2 — Integración de 8 Microservicios + Gateway y 158 Operaciones (`H5-02`, 3 min)
1. Mostrar el reporte HEAD-pinned `158_ENDPOINTS_CERTIFICATION_REPORT.json` + `.meta.json` (**158/158 PASS, 0 FAIL**, 73 `PERSISTENCE_PASS`, 151 `NEGATIVE_CONTRACT_PASS`, 6/6 authChecks).
2. Destacar los 9 fallos históricos de R2 ya resueltos: Bulk `#106`/`#109` (`202 -> COMPLETED` con `CATALOGO, PRICING, INVENTARIO`), Inventory `#114`/`#128`, Promotions `#148`/`#149` (`COMPLETED`/`RESTORED`), Catalog internas `#152`/`#153` (superficie privada con identidad de servicio, `404` en APIM público) y Gateway `#158` (`/health/ready` `200`).
3. Mostrar el inventario transparente de 369 (+1) skips E2E (`10_INVENTARIO_SKIPS_E2E.md`) demostrando cobertura en jobs CI independientes y opt-in locales.

## Bloque 3 — Mensajería Service Bus Basic: 19 Flujos + R16/R18 + R02→R10 (`H5-04B`, 3 min)
1. Mostrar en Azure (solo lectura) `g6-sb-h5-chile-261127`: **19/19 colas `Active` (`0/0`)**, **8 User-Assigned Managed Identities** y **38/38 asignaciones RBAC mínimo** a nivel de cola individual (19 Sender + 19 Receiver, 0 Data Owner).
2. Mostrar en laboratorio aislado L1 (`HTTP_IN_MEMORY_NOT_AZURE`, PG17 descartable):
   - **19/19 flujos PASS** (`MENSAJERIA_19_RECORRIDOS.json` + `.meta.json`) con duplicados en las 19 colas sin alterar las 12 tablas de negocio, DLQ por productor no confiable y reinicio real de proceso **R03 (`pricing-svc`)**.
   - **Evidencia separada para R16 (`price-audit-svc`):**
     - Recuperación transaccional PG17 (`pilot.postgres.e2e-spec.ts`, **8/8 PASS**).
     - Reinicio real de proceso consumidor `price-audit-svc` (`r16-price-audit-restart.postgres.e2e-spec.ts`, `R16_PRICE_AUDIT_CONSUMER_RESTART.json`, PID detenido vs PID reiniciado, redelivery y efecto único `count=1`).
   - **R18 (`taxonomy -> catalog`):** 23/23 PASS en PG17 con los 6 eventos contractuales + reconciliación dual-ledger de `taxonomy.outbox_delivery` (evitando re-ejecutar `0006` sobre objetos existentes).
   - **R02→R10 (`bulk -> inventory -> bulk`):** `0002_allow_bulk_r10_delivery.sql` y rollback condicionado probados en PG17 descartable (pendiente de aplicación autorizada en Supabase).

## Bloque 4 — Azure API Management (`H5-04A`) y Performance (`H5-03`, 2–3 min)
1. Mostrar reconciliación exacta `156 OpenAPI` → `145 APIM live` (11 exclusiones documentadas: 5 internas `404` probadas en vivo, 4 G5 `enableG5=false`, 2 admin pricing).
2. Demostrar controles en vivo sobre `apim-g6-productos-chile`: `401` sin token/JWT inválido, `400 VALIDACION` por mala correlación, `404` en las 5 rutas internas y **`403` anti-bypass** al llamar directo a `api-gateway--0000003` (Modalidad B).
3. Mostrar el hallazgo operativo CORS live (`OPTIONS` desde `https://g6-productos-ofertas.vercel.app` bloqueado) y el delta mínimo reversible listo para aprobación de Marco Castilla.
4. Mostrar **`PERF-06`** ejecutado en runner pareado de GitHub Actions ([`#46043178034`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46043178034), 81 rutas / 14 familias `master` vs `#102`) y explicar honestamente que `PERF-01..05/07/08` y `RL-01..06` requieren ventana staging `k6` + tokens G7 reales (0 métricas fabricadas).

## Bloque 5 — Plan de Release, Cutover y Rollback (1 min)
1. Mostrar Wave 0 → Wave 4 (`08_PLAN_RELEASE_CUTOVER_ROLLBACK.md`), criterios de aborto y rollback por plano (flags < 2 min, revisión ACA inmutable por digest, XML APIM `SHA256 aa9b8c12...`, rollback condicionado R10 y PITR).
