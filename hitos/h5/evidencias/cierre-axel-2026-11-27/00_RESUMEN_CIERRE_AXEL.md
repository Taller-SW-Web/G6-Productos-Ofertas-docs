# Resumen Ejecutivo — Cierre Técnico Integral Hito 5 (Corte Axel Cueva, 2026-11-27)

> **Principio rector:** este corte registra de forma estrictamente independiente el estado de **contrato**, **código integrado**, **pruebas locales aisladas (L1)**, **CI remoto (GitHub Actions)**, **auditoría de infraestructura Azure solo lectura**, **despliegue** y **homologación externa (L3)**. Ningún estado se infiere de otro y ningún cambio mutante se aplicó sobre `master`, GHCR, ACA, Service Bus, APIM, Supabase compartido ni G7.

## 1. Repositorios, PRs Draft y SHAs fijados

| Repositorio | Rama / PR | SHA exacto | Estado PR | CI GitHub Actions (`workflow_dispatch` seguro) | Despliegue |
|---|---|---|---|---|---|
| `G6-Productos-Ofertas-backend` | `trabajo/cueva/h5-cierre-integral` — **PR Draft #307** (integra #305 hasta `523033a` + #306 `0cd784d` + correcciones H5) | `16d373aeb63cb2386b0e174c76517d8bf3381fb5` | **Draft (OPEN)** | [`#46030550806`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46030550806) — **PASS (22/22 jobs)** | **`NOT_DEPLOYED`** |
| `G6-Productos-Ofertas-frontend` | `trabajo/castilla/h5-cierre-post-r2-frontend` — **PR Draft #102** | `ccfc21ba0e821f33c0debf09389879e55df0539b` | **Draft (OPEN)** | [`#46028914883`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46028914883) — **PASS (21/21 jobs, incl. Gitleaks 8.30.1)** | **`NOT_DEPLOYED`** |
| `G6-Productos-Ofertas-docs` (contratos normativos) | `origin/master` (`OpenAPI 3.1.0` + `AsyncAPI 3.0.0`, `0.7.0-rc.3`) | `5f30802129ba4bbc0674dcc5878f10065f443118` | Base vigente | `swagger/npm run validate` **PASS** (156 ops, 0 issues) | N/A |
| `G6-Productos-Ofertas-docs` (evidencias) | `trabajo/cueva/h5-cierre-evidencias-axel` (complementario a **PR Draft #151** `5969a0ed`) | *(SHA del commit de este PR Draft)* | **Draft (OPEN)** | `swagger-docs.yml` (verificación sin publicación Pages) | N/A |

- **Delta APIM de PR #305 mantenido separado pendiente de coordinación con Marco Castilla:** commits `a26965a0f7aff96eaf1919d2159e90d0ef6d2c67` y `8af53c24bab652dae7edbfb096e2553262897bfe` (16 archivos de scripts operativos, evidencia Chile y ajustes APIM).

## 2. Veredicto por criterio Hito 5 (Académico vs Integral)

| Criterio | Estado en laboratorio aislado (L1) + CI | Estado en Azure / Producción (L2 / L3) | Condición verificable para cierre integral |
|---|---|---|---|
| **H5-01 (CI/CD y Seguridad)** | **PASS parcial alto:** Backend CI 22/22 PASS, Frontend CI 21/21 PASS (Gitleaks 8.30.1 + SCA), SBOM CycloneDX BE/FE, 0 vulns `npm audit`, JWT negativos 158/158 + 6/6 + 7/7 + APIM live `401`/`400`/`404`/`403` | Brechas de gobierno: CodeQL (`404`), Secret Scanning nativo (`404`), Trivy (`NOT_RUN`), Rulesets en Frontend/Docs (`[]`) | Habilitar CodeQL/Secret Scanning o registrar dispensa académica formal; ejecutar Trivy sobre digests OCI publicados; crear Rulesets en Frontend y Docs |
| **H5-02 (Integración INT-01..10)** | **PASS (`ISOLATED`):** Backend E2E **50/50 archivos PASS (1105 pruebas, 0 FAIL)**, unitarias **2972 PASS**, certificador **158/158 PASS** (los 9 fallos históricos R2 corregidos), Bulk PG17 **38/38**, Inventory PG17 **26/26**, Promotions N01 **12/12**, Taxonomy/Catalog R09+R18 **23/23**, Pricing/Price-Audit **8/8 + 3/3**, Frontend Playwright **100% PASS** | **L2/L3 pendientes** (`BLOCKED_AUTH` G7, `BLOCKED_DB_MIGRATION` R10/0006, `PENDING_DEPLOY`, `PENDIENTE_HOMOLOGACION_G5`) | Aprobar migraciones `0002` y `0006`, desplegar candidato en ACA, corregir CORS APIM, ejecutar smoke L2 con tokens reales G7 y coordinar L3 con G5/G1 |
| **H5-03 (Performance PERF-01..08 & RL-01..06)** | **`NOT_RUN`** (harness k6/workflow validados en unitarias; 0 métricas fabricadas) | **`BLOCKED_ENV`** (prohibido cargar ACA/APIM/Supabase compartidos) | Autorizar staging aislado + dataset sintético SHA-256 + 2 identidades G7 + correr `k6` 1/5/20 VU × 3 repeticiones |
| **H5-04A (API Management)** | **PASS (`L0_STATIC`):** Bicep + 29 pruebas Python + ARM 145 políticas (5 internas excluidas, G5 OFF) | **PARCIAL en vivo (`INCONCLUSIVE`):** `apim-g6-productos-chile` vivo en `api/v1` (145 ops), negativos `401`/`400`/`404` y anti-bypass directo `403` **PASS**; positivos `BLOCKED_AUTH` y **defecto CORS live** (omite origen Vercel) | Aprobación de Castilla para añadir origen Vercel a política CORS APIM, tokens reales G7 para `APIM-T01..T07`, y ventana para `429`/rollback `APIM-T08` |
| **H5-04B (Service Bus Basic — R16 + R18 y 19 flujos)** | **PASS (`ISOLATED`):** **19/19 flujos PASS** (R01–R18 + N01), duplicados 19/19 sin efecto doble, kill/restart real de proceso, DLQ productor no confiable, R16 **8/8**, R18 **23/23**, R02→R10 PG17 **PASS** | Topología Azure read-only: **19/19 colas `Active` (0/0)**; corrida L2 vigente sobre SHA/digest candidato **`PENDING_AZURE_L2`** | Desplegar candidato + aplicar `0006` (Taxonomy) y `0002` (Inventory R10) + ejecutar ensayo L2 autorizado de R16 y R18 en `g6-sb-h5-chile-261127` |

## 3. Escalación operativa inmediata para Marco Castilla

Durante la auditoría solo lectura en Azure (`rg-g6-aca-chile`, 2026-11-27 ~15:10 UTC) se confirmó un cambio operativo relevante respecto al snapshot previo:
1. **`apim-g6-productos-chile` ya está aprovisionado y sirviendo `/api/v1` (145 operaciones)** y **`api-gateway--0000003` tiene Modalidad B activa (`allow-apim-1: 57.156.40.55/32`)**, por lo que cualquier llamada directa al FQDN del Gateway devuelve **HTTP `403 RBAC: access denied`**.
2. **La política CORS live de APIM solo permite `https://apim-g6-productos-chile.azure-api.net`**, omitiendo el origen del Frontend en Vercel (impedirá llamadas desde navegador hasta actualizar la política vía Bicep + `what-if`).
3. Ver opciones de continuidad/recuperación y plan completo Wave 0–Wave 4 en [`08_PLAN_RELEASE_CUTOVER_ROLLBACK.md`](08_PLAN_RELEASE_CUTOVER_ROLLBACK.md).

## 4. Índice de artefactos del corte

- [`01_RELEASE_MANIFEST_CANDIDATE.json`](01_RELEASE_MANIFEST_CANDIDATE.json)
- [`02_MATRIZ_8_MICROSERVICIOS_Y_GATEWAY.md`](02_MATRIZ_8_MICROSERVICIOS_Y_GATEWAY.md)
- [`03_MATRIZ_158_OPERACIONES.md`](03_MATRIZ_158_OPERACIONES.md)
- [`04_MATRIZ_19_FLUJOS_SERVICE_BUS.md`](04_MATRIZ_19_FLUJOS_SERVICE_BUS.md)
- [`05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md`](05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md)
- [`06_SEGURIDAD_CI_CD_Y_FRONTEND.md`](06_SEGURIDAD_CI_CD_Y_FRONTEND.md)
- [`07_INT_PERF_APIM_RL.md`](07_INT_PERF_APIM_RL.md)
- [`08_PLAN_RELEASE_CUTOVER_ROLLBACK.md`](08_PLAN_RELEASE_CUTOVER_ROLLBACK.md)
- [`09_BLOQUEOS_EXACTOS.md`](09_BLOQUEOS_EXACTOS.md)
- `registros/` (10 registros estructurados conforme a `registro_evidencia.template.json`)
- `artefactos/` (reportes sanitizados JSON/CSV de 158 endpoints, 19 flujos, snapshot ACA read-only y SBOMs CycloneDX)
- `SHA256SUMS.txt` (hashes verificables de todos los archivos del corte)
