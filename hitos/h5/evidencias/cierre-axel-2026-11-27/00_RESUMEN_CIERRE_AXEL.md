# Resumen Ejecutivo — Cierre Técnico Integral Hito 5 (Corte Axel Cueva, 2026-11-27)

> **Principio rector:** este corte registra de forma estrictamente independiente el estado de **contrato**, **código integrado**, **pruebas locales aisladas (L1)**, **CI remoto (GitHub Actions)**, **auditoría de infraestructura Azure solo lectura**, **despliegue** y **homologación externa (L3)**. Ningún estado se infiere de otro y ningún cambio mutante se aplicó sobre `master`, GHCR, ACA, Service Bus, APIM, Supabase compartido ni G7 (la auditoría referida con autorizaciones escritas no fue adjuntada al encargo).

## 1. Repositorios, PRs Draft y SHAs fijados

| Repositorio | Rama / PR | SHA final limpio | Estado PR | CI GitHub Actions (`workflow_dispatch`, sin deploy) | Despliegue |
|---|---|---|---|---|---|
| `G6-Productos-Ofertas-backend` | `trabajo/cueva/h5-cierre-integral` — **PR Draft #307** (candidato único: #305 hasta `523033a` + #306 `0cd784d` + correcciones H5 y de auditoría) | `18413ac459b24793f4f09ea07104d5281c0be3c7` | **Draft (OPEN)** | [`#46044277201`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46044277201) — **PASS (22/22 jobs; 1 opt-in skipped)** | `NOT_DEPLOYED` |
| `G6-Productos-Ofertas-frontend` | `trabajo/castilla/h5-cierre-post-r2-frontend` — **PR Draft #102** | `ccfc21ba0e821f33c0debf09389879e55df0539b` | **Draft (OPEN)** | [`#46028914883`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46028914883) — **PASS (21/21 jobs, Gitleaks 8.30.1)** + `PERF-06` [`#46043178034`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46043178034) **PASS** | `NOT_DEPLOYED` |
| `G6-Productos-Ofertas-docs` (contratos) | `origin/master` (`OpenAPI 3.1.0` + `AsyncAPI 3.0.0`, **`0.7.0-rc.3`**) | `5f30802129ba4bbc0674dcc5878f10065f443118` | Base vigente | `swagger/npm run validate` **PASS** (156 ops, 0 issues) | N/A |
| `G6-Productos-Ofertas-docs` (evidencias) | `trabajo/cueva/h5-cierre-evidencias-axel` — **PR Draft #152** (basado en **#151** `5969a0ed`; estrategia explícita en `13_ESTRATEGIA_CONSOLIDACION_PR_307_Y_152.md`) | `68d2ad38784a34d3ad197cd9cf70ea56ed058267` (corte P0 con CI verificado) | **Draft (OPEN)** | [CI #46057729689](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/runs/46057729689), 4/4 jobs ejecutados; Pages omitido | N/A |

- **Delta APIM de #305 incorporado una sola vez en #307** en `7ecee3f`, con [CI y Trivy](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46058242392).

## 2. Hallazgos de auditoría cerrados en este corte

1. **README de Inventory R02/R10 (`apps/inventory-svc/migrations-candidate/h5/README.md`):** corregido para reflejar el handler R02 (`processBulkStockAdjust`), relay/productor R10 y consumidor Bulk realmente presentes en `#307`, separando código, esquema compartido (`0002` pendiente), flags, despliegue y L1/L2.
2. **Atribución exacta de recuperación R03 vs R16:** `certify-19-messaging-flows.mjs` etiqueta explícitamente `processRecovery` como **`R03_PRICING_CONSUMER_PROCESS_RESTART`** (`pricing-svc` en `g6.pricing.from.bulk`); se conserva `pilot.postgres.e2e-spec.ts` (**8/8 PASS**) como recuperación transaccional PG17 de R16 y se añadió la prueba dedicada de **reinicio real del proceso consumidor `price-audit-svc`** (`ops/azure/service-bus/r16-price-audit-restart.postgres.e2e-spec.ts` -> `artefactos/R16_PRICE_AUDIT_CONSUMER_RESTART.json`, PID `30476 -> 29712`, redelivery y efecto único `auditRowsPersisted=1`).
3. **Recertificación HEAD-pinned sobre el HEAD limpio final (`18413ac459b24793f4f09ea07104d5281c0be3c7`):** `certify-158-endpoints.mjs` (**158/158 PASS**, `SHA256 2631cd8a...`) y `certify-19-messaging-flows.mjs` (**19/19 PASS**, `HTTP_IN_MEMORY_NOT_AZURE`, `SHA256 13cb3ac2...`) ejecutados tras las correcciones con archivos `.meta.json` generados junto a los artefactos.
4. **Inventario íntegro de 369 (+1) skips E2E Backend + 105 skips unitarios + 8 skips Frontend:** publicado en [`10_INVENTARIO_SKIPS_E2E.md`](10_INVENTARIO_SKIPS_E2E.md) con separación estricta entre corrida Playwright completa y reintentos focalizados.
5. **Reconciliación PostgreSQL/Supabase (`05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md`):** sustituido el diagnóstico binario de Taxonomy por comparación dual-ledger (`supabase_migrations` vs `taxonomy.schema_migrations` hasta `0005`) y reproducción PG17 demostrando equivalencia funcional de los objetos existentes (`0001_outbox_delivery.sql`) para los 6 eventos R18 y aborto seguro del `$guard$` si se intentase re-ejecutar `0006` íntegra.
6. **Reconciliación APIM `145` vs `156` OpenAPI vs `158` R2 + 38/38 RBAC Service Bus + delta CORS mínimo:** publicado en [`11_RECONCILIACION_APIM_145_Y_CORS.md`](11_RECONCILIACION_APIM_145_Y_CORS.md) con respaldo XML live (`artefactos/apim-api-policy-backup-2026-11-27.xml`) y origen Vercel exacto `https://g6-productos-ofertas.vercel.app`.
7. **Frontend #102 Playwright real contra Backend #307 (`18413ac`):** **16/16 PASS** (`playwright.real.config.ts`, `VITE_DATA_MODE=api`, `artefactos/FE_102_REAL_STACK_PLAYWRIGHT_SUMMARY.json`).
8. **PERF-06:** tres pares fijados por SHA. Catálogo de 1000 filas 4950 → 4874 ms de mediana (−1,54%) con tráfico equivalente; las familias tienen recuentos dispares. [Resultados](artefactos/PERF06_3_PARES_2026-11-27.json).

## Verificación del corte actualizado

- **Backend candidato #307** `d7a3bf07880a83727acf83788790241c36adc0b5`. Incorpora el delta APIM de #305 en `7ecee3f` y actualiza las bases de ambas Dockerfiles a Node 24.22.3 / Alpine 3.24.4. [CI y reescaneo del candidato](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46060439353).
- **Pruebas aisladas del código en `7ecee3f`** 158/158 operaciones y 19/19 recorridos `HTTP_IN_MEMORY_NOT_AZURE`. [Metadata y hashes](artefactos/RECERT_AUDITORIA_2026-11-27.json). La base OCI, el fixture Bulk y la documentación de R10 tienen CI por SHA.
- **Trivy 0.76.2** [corrida sobre `7ecee3f`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46058242392). El escaneo se ejecutó para 9/9 imágenes; cada una tenía 1 crítico y 18 altos. El crítico de `tar` corresponde al árbol incluido con npm. La actualización de base y la eliminación de npm del runtime dejaron cero críticos y cero altos en 9/9 imágenes de CI de `f3cc10d`. [Resumen](artefactos/SECURIDAD_DRAFT_2026-11-27.json).
- **Supabase** preflight de solo lectura confirmado. Inventory conserva tres destinos, `inventory_app` tiene SELECT/INSERT/UPDATE y carece de DELETE. El script incremental y su rollback se probaron en PG17.11 descartable. El panel Supabase Free no ofrece respaldos programados. Se restauró y verificó un respaldo lógico de la tabla afectada en PG17 aislado; se aplicó R10 con este respaldo autorizado. Ledger global `20261127200858` y los cuatro destinos verificados. Taxonomy conserva los objetos H5 y ACL por columna. Pricing ya admite sus cuatro destinos.
- **Publicación/CD** ambos workflows exigen la punta de `master` con CI de evento `push`. El Draft #307 tiene CI de `workflow_dispatch`. La aprobación de revisión y los controles existentes determinan cuándo se puede publicar/desplegar el digest.
- **L2** la infraestructura de integración actual quedó identificada para pruebas autorizadas, con una sola identidad humana `GESTOR_COMERCIAL`. Quedan por acreditar el acceso seguro a esa cuenta, los vínculos a los digests del release y la separación multi-cliente con identidades diferentes. CORS ya pasó el preflight.
- **Rendimiento** `PERF-06` tiene tres pares L1. Se ejecutó un par aislado de [Inventory](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46059874608) y se corrigió el fixture de Bulk para aplicar la migración 0009 al esquema de prueba. La corrida local pasó 3000 solicitudes, cero fallos. [Comparación pareada](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46061662575).

## 3. Veredicto por criterio Hito 5 (Académico vs Integral)

| Criterio | L1 aislado + CI remoto | L2 / L3 Azure | Condición verificable para cierre integral |
|---|---|---|---|
| **H5-01** | **PASS parcial alto** (CI BE 22/22, FE 21/21 con Gitleaks 8.30.1, Docs 4/4, `npm audit` 0 vulns, SBOM CycloneDX, 38/38 RBAC mínimo SB, JWT negativos) | Brechas: CodeQL `404`, Secret Scanning `404`, Trivy `NOT_RUN`, Rulesets FE/Docs `[]` | Habilitar CodeQL/Secret Scanning o dispensa formal; correr Trivy en runner CI sobre imágenes; crear Rulesets FE/Docs |
| **H5-02 (`INT-01..10`)** | **10/10 PASS (`L1_ISOLATED`, stub G7)** incl. 158/158, 16/16 Playwright real-stack y 22/22 CI BE | **Pendiente L2/L3** (`BLOCKED_AUTH` G7, `BLOCKED_CORS_APIM`, `BLOCKED_DB_MIGRATION` R10, `PENDING_DEPLOY`, `PENDIENTE_HOMOLOGACION_G5`) | Aplicar `0002` R10, desplegar candidato ACA, actualizar CORS APIM, correr L2 con tokens reales G7 y homologar L3 con G5/G1 |
| **H5-03** | `PERF-06` con tres pares L1. Catálogo de 1000 filas comparable, comparación transversal `INCONCLUSIVE` | Casos Azure restantes pendientes | Coordinar datos sintéticos y validar candidatos por digest. |
| **H5-04A (APIM)** | Bicep y 30 pruebas estáticas PASS | CORS Vercel, 401 sin JWT, correlación, 5×404 y 403 directo verificados | Pendientes positivos con G7, RL y ensayo de rollback. |
| **H5-04B (Service Bus)** | **PASS (`L1_ISOLATED`)**: 19/19 flujos, R03 restart, R16 transaccional 8/8 + R16 `price-audit-svc` restart 1/1, R18 23/23 + equivalencia PG17, R02→R10 PG17, N01 12/12 | Inventario Azure: 19/19 colas `Active` (0/0) + 38/38 RBAC mínimo; corrida L2 vigente sobre candidato **`PENDING_AZURE_L2`** | Desplegar candidato + aplicar `0002` R10 + ventana L2 autorizada para R16 (con reinicio `price-audit-svc`) y R18 (6 eventos) |

## 4. Índice de documentos del corte

- [`01_RELEASE_MANIFEST_CANDIDATE.json`](01_RELEASE_MANIFEST_CANDIDATE.json)
- [`02_MATRIZ_8_MICROSERVICIOS_Y_GATEWAY.md`](02_MATRIZ_8_MICROSERVICIOS_Y_GATEWAY.md)
- [`03_MATRIZ_158_OPERACIONES.md`](03_MATRIZ_158_OPERACIONES.md)
- [`04_MATRIZ_19_FLUJOS_SERVICE_BUS.md`](04_MATRIZ_19_FLUJOS_SERVICE_BUS.md)
- [`05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md`](05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md)
- [`06_SEGURIDAD_CI_CD_Y_FRONTEND.md`](06_SEGURIDAD_CI_CD_Y_FRONTEND.md)
- [`07_INT_PERF_APIM_RL.md`](07_INT_PERF_APIM_RL.md)
- [`08_PLAN_RELEASE_CUTOVER_ROLLBACK.md`](08_PLAN_RELEASE_CUTOVER_ROLLBACK.md)
- [`09_BLOQUEOS_EXACTOS.md`](09_BLOQUEOS_EXACTOS.md)
- [`10_INVENTARIO_SKIPS_E2E.md`](10_INVENTARIO_SKIPS_E2E.md)
- [`11_RECONCILIACION_APIM_145_Y_CORS.md`](11_RECONCILIACION_APIM_145_Y_CORS.md)
- [`12_GUION_DEMO_H5.md`](12_GUION_DEMO_H5.md)
- [`13_ESTRATEGIA_CONSOLIDACION_PR_307_Y_152.md`](13_ESTRATEGIA_CONSOLIDACION_PR_307_Y_152.md)
- `registros/` (12 registros JSON conformes a `registro_evidencia.template.json`, separando R03 restart, R16 transaccional, R16 Price Audit restart y PERF-06)
- `artefactos/` (reportes HEAD-pinned `18413ac` + `.meta.json`, `PERF06`, `FE_102_REAL_STACK_PLAYWRIGHT_SUMMARY`, respaldo XML APIM, snapshot ACA y SBOMs CycloneDX)
- `SHA256SUMS.txt`
