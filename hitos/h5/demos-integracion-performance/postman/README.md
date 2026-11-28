# Pruebas de Integración HTTP — Postman / Newman (Evidencias y Trazabilidad H5)

Este directorio conserva las **evidencias históricas intactas**, las **evidencias sanitizadas locales definitivas (`H35`)**, las **matrices de cobertura**, el **diagnóstico consolidado de defectos** y la **trazabilidad con los requisitos de Hito 5** para **G6 — Productos y Ofertas**.

> **Ubicación del código ejecutable (fuente única de verdad):**  
> Toda la implementación ejecutable (colección Postman v2.1.0, entornos de ejemplo, validador contractual estricto OpenAPI/Ajv con procedencia verificada y compilación previa `H24`/`H25`/`H31`/`H32`, scripts PowerShell/Node, runner PG17 automatizado `H33`, `package.json`/`package-lock.json` con `newman@6.2.3`, **34 regresiones `H01`–`H32`** y job CI `newman_h5_integracion`) reside en el repositorio **Backend**:
>
> - **Repositorio:** `Taller-SW-Web/G6-Productos-Ofertas-backend`
> - **Ruta ejecutable:** `tests/h5/postman/` y `tests/h5/run-catalog-h5-newman-postgres.mjs`
> - **Estado de PRs asociados:**
>   - **[Backend #310](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/310)** — **MERGED** (`bed0511`, commit técnico `6dd6603` / `a5329ff`, base canónica CI y equivalencias H5).
>   - **[Frontend #103](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/103)** — **MERGED** (`02ada63`).
>   - **[Backend #314](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/314)** (`trabajo/poma/h5-apim-errores-autenticacion`, `b2f53cc`) — **Ready for Review** (Defecto A, 100% CI verde incluyendo `apim_h5_estatico`, `Gitleaks` y `CodeQL`).
>   - **[Backend #315](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/315)** (`trabajo/poma/h5-bulk-autenticacion`, `e7547f3`) — **Ready for Review** (Defecto C, 100% CI verde incluyendo `Bulk R03/R14`, `bulk_integral_e2e`, `Gitleaks` y `CodeQL`).
>   - **[Backend #313](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/313)** (`poma-hito-5-pruebas-v2`, `6dbbf1ce`) — **Draft** (H30–H35 + integración de Newman al CI).

## Contenido conservado en Docs

- `evidencias/` *(evidencias históricas intactas con checksums SHA-256 sin alteración)*:
  - `azure-preflight-2026-11-27/`: Bloqueo esperado Modalidad B en ACA (`403`).
  - `azure-apim-edge-2026-11-27/`: Evidencia histórica previa de timeout en APIM (`ETIMEDOUT`).
  - `azure-apim-smoke-jws-2026-11-28/`: Corrida real `smoke` contra APIM Chile (`9/11` PASS, `2` FAIL APIM 401, `1` NOT_RUN) + `TRAZA-DOWNSTREAM-CATALOG-PRICING.md`.
  - `azure-apim-integration-jws-2026-11-28/`: Corrida real `integration` contra los 8 microservicios en APIM Chile (`27/32` PASS, `5` FAIL en Defectos A/B/C, `4` NOT_RUN).
  - **`local-pg17-real-h27-2026-11-28/` (`H35`):** Evidencias sanitizadas definitivas (`manifest.json`, `integration-results.json`, `newman.junit.xml`, `report.md`, `evidence-index.json`, `vitest-h5-real-report.json`) sobre servicios productivos reales (`api-gateway`, `catalog-svc`, `pricing-svc`, `inventory-svc`) y PostgreSQL 17 descartable con roles runtime no propietarios (`6dbbf1ce`).
- `matrices/`:
  - `cobertura-integracion.md` y `cobertura-integracion.csv`: Trazabilidad completa de los 38 casos `PM-*` contra `INT-01`..`INT-09` y OpenAPI `0.7.0-rc.3`.
- `DIAGNOSTICO-DEFECTOS-Y-BRECHAS-H5.md`: Estado consolidado, consolidación `#310` vs `#313`, resultados `H27`/`H35`, verificación acotada de Frontend (`02ada63`) y `STANDBY`.

## Cómo reproducir localmente (desde Backend)

```powershell
# 1) Validación contractual estricta y 34 regresiones del harness (H01-H32)
cd <ruta-repo-backend>/tests/h5/postman
npm ci
npm run validate
npm test

# 2) Suites productivas reales con PostgreSQL 17 descartable y roles runtime (H33-H35)
cd <ruta-repo-backend>
node tests/h5/run-catalog-h5-newman-postgres.mjs "<ruta-repo-docs>"
```

> **Nota operativa (`STANDBY`):** No ejecute corridas contra Azure APIM, ACA, Service Bus, G7 ni bases compartidas hasta autorización expresa.
