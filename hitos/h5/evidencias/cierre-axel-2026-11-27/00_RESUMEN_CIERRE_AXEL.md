# Resumen Ejecutivo — Cierre Técnico Integral Hito 5 (Corte Axel Cueva, 2026-11-27)

> El corte acredita código, pruebas aisladas L1, CI remoto, cambios verificados en APIM y Supabase, y el inventario de ACA y Service Bus. La certificación L2 del candidato y la homologación intergrupo L3 siguen pendientes.

## 1. Repositorios, PRs y SHAs fijados

| Repositorio | Rama / PR | SHA final limpio | Estado PR | CI GitHub Actions, sin despliegue | Publicación / Despliegue |
|---|---|---|---|---|---|
| Backend (`master` vigente) | [#307](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/307) (`892e96bc`) + [#308](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/308) (`36f619da`) | `36f619da6c44a3c14b93917d1fddf2d09bd569db` | **MERGED** en `master` | CI `push` [`#46091856477`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46091856477) — **PASS (22/22 ejecutados, 1 opt-in skipped)** | **9/9 digests GHCR publicados** (`46093183232`..`46093204616`) · **NOT_DEPLOYED** (Oleada 1 `taxonomy-svc` [`#46093835743`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46093835743) en `waiting` en `azure-h5-chile` con `AZURE_CHILE_DEPLOY_ENABLED=false`) |
| Backend (conciliación Pricing) | [Draft #309](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/309) (`trabajo/cueva/h5-apim-pricing-administrativo`) | `a4545acfa15957ce38e467f40554ee82492e836a` | **Draft (OPEN)** — pendiente decisión de merge con Docs #153 | Local: `30/30` APIM/ARM + `360/360` `pricing-svc` PASS (`verify-arm-template.py` `151` políticas) | `NOT_PUBLISHED` / `NOT_DEPLOYED` |
| `G6-Productos-Ofertas-frontend` | `trabajo/castilla/h5-cierre-post-r2-frontend` — **PR Draft #102** | `ccfc21ba0e821f33c0debf09389879e55df0539b` | **Draft (OPEN)** | [`#46028914883`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46028914883) — **PASS (21/21 jobs, Gitleaks 8.30.1)** + `PERF-06` [`#46043178034`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46043178034) **PASS** | `NOT_DEPLOYED` |
| `G6-Productos-Ofertas-docs` (contratos) | `origin/master` (`OpenAPI 3.1.0` + `AsyncAPI 3.0.0`, **`0.7.0-rc.3`**) + [Draft #153](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/153) (`7e143538`) | `5f30802129ba4bbc0674dcc5878f10065f443118` | Base vigente (#153 en **Draft**) | `swagger/npm run validate` **PASS** (156 ops, 0 issues; #153 CI [`#46090465419`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/runs/46090465419) **PASS**) | N/A |
| Docs (evidencias) | [Draft #152](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/152). Incluye #151 con su historial | Ver HEAD del Draft | **Draft (OPEN)** | [Corridas Docs](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/workflows/swagger-docs.yml) | N/A |

- **Manifiesto de 9 digests GHCR y estado de Oleada 1 (`36f619da`):** [`artefactos/RELEASE_36F619DA_DIGESTS_Y_PREFLIGHT_2026-11-27.json`](artefactos/RELEASE_36F619DA_DIGESTS_Y_PREFLIGHT_2026-11-27.json) · Probes L2 sin G7 (APIM/Gateway anti-bypass): [`artefactos/APIM_GATEWAY_L2_NO_G7_PROBES_2026-11-27.json`](artefactos/APIM_GATEWAY_L2_NO_G7_PROBES_2026-11-27.json).

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

- **Backend #307.** El SHA `de4a54ba` conserva la evidencia de 22/22 para CD, smoke Modalidad B y recuperación de R16 en fixtures. El nuevo candidato integra las cuatro operaciones G5 autorizadas. [CI nuevo](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46086802435) · [Alcance G5](11_RECONCILIACION_APIM_145_Y_CORS.md).
- **Pruebas aisladas del código en `7ecee3f`** 158/158 operaciones y 19/19 recorridos `HTTP_IN_MEMORY_NOT_AZURE`. [Metadata y hashes](artefactos/RECERT_AUDITORIA_2026-11-27.json). La base OCI, el fixture Bulk y la documentación de R10 tienen CI por SHA.
- **Trivy 0.76.2** [corrida sobre `7ecee3f`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46058242392). El escaneo se ejecutó para 9/9 imágenes; cada una tenía 1 crítico y 18 altos. El crítico de `tar` corresponde al árbol incluido con npm. La actualización de base y la eliminación de npm del runtime dejaron cero críticos y cero altos en 9/9 imágenes de CI de `f3cc10d`. [Resumen](artefactos/SECURIDAD_DRAFT_2026-11-27.json).
- **Supabase** preflight de solo lectura confirmado. Antes de aplicar R10, Inventory admitía tres destinos, `inventory_app` tiene SELECT/INSERT/UPDATE y carece de DELETE. El script incremental y su rollback se probaron en PG17.11 descartable. El panel Supabase Free no ofrece respaldos programados. Se restauró y verificó un respaldo lógico de la tabla afectada en PG17 aislado; se aplicó R10 con este respaldo autorizado. Ledger global `20261127200858` y los cuatro destinos verificados. Taxonomy conserva los objetos H5 y ACL por columna. Pricing ya admite sus cuatro destinos.
- **Publicación y CD.** Se requiere nueva aprobación de merge y el CI de push en master para publicar los nueve digests. El principal OIDC tiene las dos acciones de revisión asignadas exclusivamente en Price Audit y se comprobó la asignación individual para los nueve servicios. Sigue pendiente el corte supervisado. [Gates](09_BLOQUEOS_EXACTOS.md).
- **L2** la infraestructura de integración actual quedó identificada para pruebas autorizadas, con una sola identidad humana `GESTOR_COMERCIAL`. Los positivos usan esa sesión exclusivamente en operaciones autorizadas. Los casos multi-cliente se acreditan en L1 y quedan BLOCKED_AUTH en L2. CORS ya pasó el preflight.
- **Rendimiento** `PERF-06` tiene tres pares L1. Se ejecutó un par aislado de [Inventory](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46059874608) y se corrigió el fixture de Bulk para aplicar la migración 0009 al esquema de prueba. La corrida local pasó 3000 solicitudes, cero fallos. [Comparación pareada](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46061662575).

## 3. Veredicto por criterio Hito 5 (Académico vs Integral)

| Criterio | L1 aislado + CI remoto | L2 / L3 Azure | Condición verificable para cierre integral |
|---|---|---|---|
| **H5-01** | CI Backend 22/22, Frontend 21/21, Docs 4/4. Trivy 9/9 imágenes de CI sin altos ni críticos. | CodeQL sin configurar. Secret Scanning deshabilitado en Backend. Reglas efectivas sin entradas para Frontend/Docs. | Formalizar el control alternativo o habilitar controles nativos y verificar protecciones. |
| **H5-02 (INT-01 a INT-10)** | 10/10 PASS L1, 158/158 operaciones, 16/16 Playwright integrado con G7 local. | R10 y CORS verificados. Pendientes despliegue, acceso G7 real y homologación de G5/G1 según caso. | Publicar y desplegar por el gate oficial, ejecutar L2 con G7 y coordinar L3 por dominio. |
| **H5-03** | `PERF-06` con tres pares L1. Catálogo de 1000 filas comparable, comparación transversal `INCONCLUSIVE` | Casos Azure restantes pendientes | Coordinar datos sintéticos y validar candidatos por digest. |
| **H5-04A (APIM)** | Bicep y 30 pruebas estáticas PASS | CORS Vercel, 401 sin JWT, correlación, 5×404 y 403 directo verificados | Pendientes positivos con G7, RL y ensayo de rollback. |
| **H5-04B (Service Bus)** | 19/19 en L1. R16 transaccional 8/8 y reinicio aislado 1/1. R18 23/23 y R02→R10 en PG17. | 19 colas activas y RBAC de mensajería observado. Azure L2 del candidato pendiente. | Verificar R16 durante corte y recuperación, los seis eventos R18 y el ciclo R02→R10 sobre los digests desplegados. |

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
