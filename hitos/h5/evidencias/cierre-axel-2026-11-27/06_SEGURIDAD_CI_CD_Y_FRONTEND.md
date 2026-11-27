# Seguridad H5-01, CI/CD Multi-Repositorio y Frontend #102 — 2026-11-27

## 1. Ejecución real de CI (GitHub Actions, `workflow_dispatch` sin deploy/publicación)

Los PRs Draft omiten automáticamente los checks de `pull_request` por política (`draft == false`). Para acreditar evidencia real de CI sin sacar los PRs de Draft ni activar CD/publicación, se ejecutaron corridas seguras (`permissions: contents: read`) vía `workflow_dispatch`:

### 1.1 Backend — PR Draft #307 (`trabajo/cueva/h5-cierre-integral`, SHA `16d373aeb63cb2386b0e174c76517d8bf3381fb5`)
- **Run principal (`ci.yml`, `mode=ci`):** [`#46030550806`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46030550806) — **`completed / success` (22/22 jobs ejecutados PASS; 1 job opt-in `Benchmark focalizado solicitado` skipped)**
  - `Comprobar tipos TypeScript`: **PASS**
  - `Comprobar formato del código`: **PASS**
  - `Revisar calidad del código`: **PASS**
  - `Ejecutar pruebas unitarias`: **PASS**
  - `Compilar microservicios`: **PASS**
  - `Ejecutar pruebas de extremo a extremo`: **PASS**
  - `Validar flujos de automatización`: **PASS**
  - `Validar contratos y datos iniciales`: **PASS**
  - `Dependency audit High/Critical`: **PASS**
  - `APIM H5 — artefactos y ARM estáticos`: **PASS**
  - `Probar el ejecutor de CD Azure H5 sin credenciales`: **PASS**
  - `Probar persistencia de Promotions con PostgreSQL TLS`: **PASS**
  - `Probar integración de Taxonomy con PostgreSQL desechable`: **PASS**
  - `Probar E2E aislado Taxonomy y Catalog`: **PASS**
  - `Probar integración de Inventory con PostgreSQL y RabbitMQ desechables`: **PASS**
  - `Probar E2E Gateway → Inventory → PostgreSQL 17 (obligatorio)`: **PASS**
  - `Probar persistencia y mensajería de Pricing y Price Audit`: **PASS**
  - `Probar integración de Combos con PostgreSQL, RabbitMQ y Catalog desechables`: **PASS**
  - `Probar integración H5 de Combos con PostgreSQL 17 TLS y contrato 0.7.0-rc.3`: **PASS**
  - `Validar imágenes y pruebas funcionales de contenedores` (9 imágenes Docker + salud + PG TLS + Marketplace): **PASS**
  - `Lint, Typecheck, Test, Build & Smoke Test`: **PASS**
  - `Validación integral de integración continua`: **PASS**
- **Workflows PR adicionales (corrida previa `d297cfc`, antes del ajuste puntual de 5 líneas en tests/CI):**
  - `MK-001 Bulk E2E Integral (Navegador Real + Recuperación + Performance)` (`#46028848508`): **PASS**
  - `Integración Bulk-Catalog Retry (PostgreSQL 17 descartable)` (`#46028848676`): **PASS**
- **Corrida intermedia que detectó 2 regresiones heredadas (`#46028851217` en `d297cfc`):** falló únicamente en `inventario` (`stock_version` BIGINT devuelto como string `'1'` en `inventory.real.integration.spec.ts:4914`) y `apim_h5_estatico` (SHAs `099ad192`/`2eb8c864` desactualizados en `.github/workflows/ci.yml` frente a `fabf2c43`). Ambos fueron corregidos en `16d373a` y verificados en verde en `#46030550806`.

### 1.2 Frontend — PR Draft #102 (`trabajo/castilla/h5-cierre-post-r2-frontend`, SHA `ccfc21ba0e821f33c0debf09389879e55df0539b`)
- **Run principal (`frontend.yml`, `performance_harness=false`):** [`#46028914883`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46028914883) — **`completed / success` (21/21 jobs ejecutados PASS; 1 job opt-in `Benchmark administrativo` skipped)**
  - `Seguridad H5 (fixtures, bundles y diff)` (**Gitleaks 8.30.1** con checksum SHA-256 verificado + negativos de seguridad + verificación bundles mock y API): **PASS**
  - `Auditoría de dependencias High/Critical` (SCA H5 fail-closed): **PASS**
  - `Compilación - Integración con API` (`VITE_DATA_MODE=api` + Playwright contra Gateway/G7 contractuales aislados + sin retorno a datos de demostración): **PASS**
  - `Compilación - Datos de demostración` + `Verificación de compilación local`: **PASS**
  - `E2E Pricing (configuración propia)`: **PASS**
  - `Pruebas rápidas de interfaz` (`@smoke`): **PASS**
  - `Pruebas de extremo a extremo` (partes 1, 2, 3 y 4 de 4): **PASS**
  - `Comprobación de tipos`, `Revisión de estilo`, `Política de release`, `Clasificar alcance de cambios`, unitarias (`Combos`, `Carga masiva`, `Inventario`, `Precios`, `Taxonomy`) y `validate`: **PASS**

### 1.3 Validaciones locales reproducidas en Frontend #102 (`ccfc21ba0e821f33c0debf09389879e55df0539b`)
- `npm run typecheck`, `npm run lint`, `npm test` (incl. 35 pruebas política release), `VITE_DATA_MODE=api npm run build`, `npm audit --audit-level=moderate` (0 vulnerabilidades): **PASS**.
- `npm run test:e2e:pricing`: **12/12 PASS**.
- `npx playwright test --config tests/h5/security-playwright.config.ts`: **7/7 PASS**.
- `npm run test:e2e`: 664 passed, 8 skipped, 2 fallos transitorios por contención de CPU durante corrida paralela de Backend (`promotions-coupon-http.spec.ts:251` y `transversal-integration.spec.ts:111`), ambos **2/2 PASS** en re-ejecución focalizada aislada (y confirmados **4/4 shards PASS** en GitHub Actions `#46028914883`).
- **Stubs de G7:** declarados explícitamente como `SIMULATED_DEPENDENCY` en pruebas L1; el recorrido real `Frontend → APIM → Gateway → servicio` permanece bloqueado en L2 por ausencia del origen Vercel en la política CORS live de `apim-g6-productos-chile` y falta de token G7 real.

---

## 2. Seguridad H5-01 — SCA, SBOM, Secretos, SAST/CodeQL, Contenedores, IaC y JWT

| Control H5-01 | Estado | Evidencia / Brecha exacta |
|---|---|---|
| **SCA (`npm audit --audit-level=moderate`)** | **PASS** | `0` vulnerabilidades moderate/high/critical en Backend (`16d373a`) y Frontend (`ccfc21ba`); jobs `Dependency audit High/Critical` y `Auditoría de dependencias High/Critical` en verde en CI |
| **SBOM CycloneDX 1.5** | **PASS** | Generados localmente y adjuntados en `artefactos/`: `sbom-backend.cdx.json` (444 componentes, SHA-256 `09f13aae61cae055be276333a8b04d5a029e598e0fcba6e83c01371a03ed8238`) y `sbom-frontend.cdx.json` (282 componentes, SHA-256 `2e68ba5fc321a130479af226073dd5f13fd49b4ac04e93a5a9c3c63f49d870ee`) |
| **Detección de secretos (Gitleaks)** | **PASS (Frontend CI + diff scan local)** | Gitleaks `8.30.1` en verde en Frontend CI `#46028914883` (`Seguridad H5`); escaneo regex sobre diffs Backend/Frontend y reportes JSON: `0` hallazgos. **Brecha GitHub:** Secret Scanning nativo devuelve `404` en los 3 repos |
| **SAST / CodeQL** | **`BLOCKED_GOVERNANCE` (`NOT_RUN` en GitHub)** | API GitHub `code-scanning/alerts` devuelve `404 no analysis found` en los 3 repos (requiere habilitación por admin de organización); oxlint/TypeScript estrictos en verde en CI |
| **Escaneo de imágenes (Trivy)** | **`NOT_RUN`** | `trivy` no instalado localmente; las 9 imágenes Docker sí fueron construidas y probadas funcionalmente en CI `#46030550806` (`Validar imágenes y pruebas funcionales de contenedores`: **PASS**) |
| **Validación IaC (APIM Bicep)** | **PASS (`L0_STATIC`)** | `az bicep build` + `29/29` pruebas Python + `verify-arm-template.py --mode candidate` (145 políticas, 5 rutas internas excluidas, G5 OFF) en local y en CI `#46030550806` |
| **Denegación JWT / Separación de identidades** | **PASS (L1 completo + L2 negativos en vivo)** | L1: 158/158 `auth401`/`auth403` PASS, 6/6 `authChecks` PASS (login inválido, bloqueado, rotación y reúso de refresh), 7/7 `security-playwright` PASS. L2 vivo en APIM: sin token `401`, JWT malformado `401`, mala correlación `400`, rutas internas `404`, directo a Gateway `403`. Positivos con token real G7: `BLOCKED_AUTH` |
| **Gobierno GitHub (Rulesets / Environments)** | **PARCIAL** | Backend `master` protege con Ruleset `24961806` (`required_review_thread_resolution=true`, required check `Lint, Typecheck, Test, Build & Smoke Test`, `required_approving_review_count=0`) y Environments `azure-h5`/`azure-h5-chile`/`azure-h5-pilot-234` con `required_reviewers`. **Brecha:** Frontend y Docs tienen `rulesets=[]` en `master` |
