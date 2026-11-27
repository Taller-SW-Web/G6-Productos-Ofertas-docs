# Resumen Ejecutivo — Cierre Técnico Integral Hito 5 (Corte Axel Cueva, 2026-11-27)

> El corte acredita código, pruebas aisladas L1, CI remoto, cambios verificados en APIM y Supabase, y el inventario de ACA y Service Bus. La certificación L2 del candidato y la homologación intergrupo L3 siguen pendientes.

## 1. Repositorios, PRs Draft y SHAs fijados

| Repositorio | Rama / PR | SHA final limpio | Estado PR | CI GitHub Actions (`workflow_dispatch`, sin deploy) | Despliegue |
|---|---|---|---|---|---|
| Backend | [Draft #307](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/307). Candidato único con #305, #306 y el delta APIM | d7a3bf07880a83727acf83788790241c36adc0b5 | Draft (OPEN) | [CI #46061782995](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46061782995). 22 jobs PASS, uno opt-in omitido | NOT_DEPLOYED |
| `G6-Productos-Ofertas-frontend` | `trabajo/castilla/h5-cierre-post-r2-frontend` — **PR Draft #102** | `ccfc21ba0e821f33c0debf09389879e55df0539b` | **Draft (OPEN)** | [`#46028914883`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46028914883) — **PASS (21/21 jobs, Gitleaks 8.30.1)** + `PERF-06` [`#46043178034`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46043178034) **PASS** | `NOT_DEPLOYED` |
| `G6-Productos-Ofertas-docs` (contratos) | `origin/master` (`OpenAPI 3.1.0` + `AsyncAPI 3.0.0`, **`0.7.0-rc.3`**) | `5f30802129ba4bbc0674dcc5878f10065f443118` | Base vigente | `swagger/npm run validate` **PASS** (156 ops, 0 issues) | N/A |
| Docs (evidencias) | [Draft #152](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/152). Incluye #151 con su historial | Ver HEAD del Draft | Draft (OPEN) | [Corridas Docs](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/workflows/swagger-docs.yml) | N/A |

- **Delta APIM de #305 incorporado una sola vez en #307** en `7ecee3f`, con [CI y Trivy](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46058242392).

## 2. Hallazgos de auditoría cerrados en este corte

1. **README de Inventory R02/R10 (`apps/inventory-svc/migrations-candidate/h5/README.md`):** corregido para reflejar el handler R02 (`processBulkStockAdjust`), relay/productor R10 y consumidor Bulk realmente presentes en `#307`, separando código, esquema compartido con R10 verificado, flags, despliegue y L1/L2.
2. **Atribución exacta de recuperación R03 vs R16:** `certify-19-messaging-flows.mjs` etiqueta explícitamente `processRecovery` como **`R03_PRICING_CONSUMER_PROCESS_RESTART`** (`pricing-svc` en `g6.pricing.from.bulk`); se conserva `pilot.postgres.e2e-spec.ts` (**8/8 PASS**) como recuperación transaccional PG17 de R16 y se añadió la prueba dedicada de **reinicio real del proceso consumidor `price-audit-svc`** (`ops/azure/service-bus/r16-price-audit-restart.postgres.e2e-spec.ts` -> `artefactos/R16_PRICE_AUDIT_CONSUMER_RESTART.json`, PID `30476 -> 29712`, redelivery y efecto único `auditRowsPersisted=1`).
3. **Recertificación aislada** de 158 operaciones y 19 recorridos HTTP en memoria en 7ecee3f. [Comandos, sujetos y hashes](artefactos/RECERT_AUDITORIA_2026-11-27.json).
4. **Inventario íntegro de 369 (+1) skips E2E Backend + 105 skips unitarios + 8 skips Frontend:** publicado en [`10_INVENTARIO_SKIPS_E2E.md`](10_INVENTARIO_SKIPS_E2E.md) con separación estricta entre corrida Playwright completa y reintentos focalizados.
5. **Reconciliación PostgreSQL/Supabase (`05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md`):** sustituido el diagnóstico binario de Taxonomy por comparación dual-ledger (`supabase_migrations` vs `taxonomy.schema_migrations` hasta `0005`) y reproducción PG17 demostrando equivalencia funcional de los objetos existentes (`0001_outbox_delivery.sql`) para los 6 eventos R18 y aborto seguro del `$guard$` si se intentase re-ejecutar `0006` íntegra.
6. **Reconciliación APIM `145` vs `156` OpenAPI vs `158` R2 + 38/38 RBAC Service Bus + delta CORS mínimo:** publicado en [`11_RECONCILIACION_APIM_145_Y_CORS.md`](11_RECONCILIACION_APIM_145_Y_CORS.md) con respaldo XML live (`artefactos/apim-api-policy-backup-2026-11-27.xml`) y origen Vercel exacto `https://g6-productos-ofertas.vercel.app`.
7. **Frontend #102 Playwright real contra Backend #307 (`18413ac`):** **16/16 PASS** (`playwright.real.config.ts`, `VITE_DATA_MODE=api`, `artefactos/FE_102_REAL_STACK_PLAYWRIGHT_SUMMARY.json`).
8. **PERF-06:** tres pares fijados por SHA. Catálogo de 1000 filas 4950 → 4874 ms de mediana (−1,54%) con tráfico equivalente; las familias tienen recuentos dispares. [Resultados](artefactos/PERF06_3_PARES_2026-11-27.json).

## Verificación del corte actualizado

- **Backend candidato #307** `d7a3bf07880a83727acf83788790241c36adc0b5`. Incorpora el delta APIM de #305 en `7ecee3f` y actualiza las bases de ambas Dockerfiles a Node 24.22.3 / Alpine 3.24.4. [CI y reescaneo del candidato](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46060439353).
- **Pruebas aisladas del código en `7ecee3f`** 158/158 operaciones y 19/19 recorridos `HTTP_IN_MEMORY_NOT_AZURE`. [Metadata y hashes](artefactos/RECERT_AUDITORIA_2026-11-27.json). La base OCI, el fixture Bulk y la documentación de R10 tienen CI por SHA.
- **Trivy 0.76.2** [corrida sobre `7ecee3f`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46058242392). El escaneo se ejecutó para 9/9 imágenes; cada una tenía 1 crítico y 18 altos. El crítico de `tar` corresponde al árbol incluido con npm. La actualización de base y la eliminación de npm del runtime dejaron cero críticos y cero altos en 9/9 imágenes de CI de `f3cc10d`. [Resumen](artefactos/SECURIDAD_DRAFT_2026-11-27.json).
- **Supabase** preflight de solo lectura confirmado. Antes de aplicar R10, Inventory admitía tres destinos, `inventory_app` tiene SELECT/INSERT/UPDATE y carece de DELETE. El script incremental y su rollback se probaron en PG17.11 descartable. El panel Supabase Free no ofrece respaldos programados. Se restauró y verificó un respaldo lógico de la tabla afectada en PG17 aislado; se aplicó R10 con este respaldo autorizado. Ledger global `20261127200858` y los cuatro destinos verificados. Taxonomy conserva los objetos H5 y ACL por columna. Pricing ya admite sus cuatro destinos.
- **Publicación/CD** ambos workflows exigen la punta de `master` con CI de evento `push`. El Draft #307 tiene CI de `workflow_dispatch`. La aprobación de revisión y los controles existentes determinan cuándo se puede publicar/desplegar el digest.
- **L2** la infraestructura de integración actual quedó identificada para pruebas autorizadas, con una sola identidad humana `GESTOR_COMERCIAL`. Quedan por acreditar el acceso seguro a esa cuenta, los vínculos a los digests del release y la separación multi-cliente con identidades diferentes. CORS ya pasó el preflight.
- **Rendimiento** `PERF-06` tiene tres pares L1. Se ejecutó un par aislado de [Inventory](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46059874608) y se corrigió el fixture de Bulk para aplicar la migración 0009 al esquema de prueba. La corrida local pasó 3000 solicitudes, cero fallos. [Comparación pareada](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46061662575).

## 3. Veredicto por criterio Hito 5 (Académico vs Integral)

| Criterio | L1 aislado + CI remoto | L2 / L3 Azure | Condición verificable para cierre integral |
|---|---|---|---|
| **H5-01** | CI Backend 22/22, Frontend 21/21, Docs 4/4. Trivy 9/9 imágenes de CI sin altos ni críticos. | CodeQL sin configurar. Secret Scanning deshabilitado en Backend. Reglas efectivas sin entradas para Frontend/Docs. | Formalizar el control alternativo o habilitar controles nativos y verificar protecciones. |
| **H5-02 (INT-01 a INT-10)** | 10/10 PASS L1, 158/158 operaciones, 16/16 Playwright integrado con G7 local. | R10 y CORS verificados. Pendientes despliegue, acceso G7 real y homologación de G5/G1 según caso. | Publicar y desplegar por el gate oficial, ejecutar L2 con G7 y coordinar L3 por dominio. |
| **H5-03** | `PERF-06` con tres pares L1. Catálogo de 1000 filas comparable, comparación transversal `INCONCLUSIVE` | Casos Azure restantes pendientes | Coordinar datos sintéticos y validar candidatos por digest. |
| **H5-04A (APIM)** | Bicep y 30 pruebas estáticas PASS | CORS Vercel, 401 sin JWT, correlación, 5×404 y 403 directo verificados | Pendientes positivos con G7, RL y ensayo de rollback. |
| **H5-04B (Service Bus)** | **PASS (`L1_ISOLATED`)**: 19/19 flujos, R03 restart, R16 transaccional 8/8 + R16 `price-audit-svc` restart 1/1, R18 23/23 + equivalencia PG17, R02→R10 PG17, N01 12/12 | Inventario Azure: 19/19 colas `Active` (0/0) + 38/38 RBAC mínimo; corrida L2 vigente sobre candidato **`PENDING_AZURE_L2`** | Desplegar candidato y ejecutar L2 para R02→R10, R16 con reinicio del consumidor y los seis eventos de R18. |

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
- `registros/` (13 registros JSON conformes a `registro_evidencia.template.json`, separando R03 restart, R16 transaccional, R16 Price Audit restart y PERF-06)
- `artefactos/` (reportes HEAD-pinned `18413ac` + `.meta.json`, `PERF06`, `FE_102_REAL_STACK_PLAYWRIGHT_SUMMARY`, respaldo XML APIM, snapshot ACA y SBOMs CycloneDX)
- `SHA256SUMS.txt`
