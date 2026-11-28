# Pruebas de Integración HTTP — Postman / Newman (Evidencias y Trazabilidad H5)

Este directorio conserva las **evidencias históricas y actuales**, las **matrices de cobertura**, el **diagnóstico técnico de defectos**, la **evidencia reproducible de Frontend** y la **trazabilidad con los requisitos de Hito 5** para **G6 — Productos y Ofertas**.

> **Ubicación del código ejecutable (fuente única de verdad):**  
> Toda la implementación ejecutable (colección Postman v2.1.0, entornos de ejemplo, validador contractual estricto OpenAPI/Ajv `H24`/`H25`, scripts PowerShell/Node, runner, preflight, sanitizador, `package.json`/`package-lock.json` con `newman@6.2.3` y suite automatizada de **32 regresiones `H01`–`H25`**) reside en el repositorio **Backend**:
>
> - **Repositorio:** `Taller-SW-Web/G6-Productos-Ofertas-backend`
> - **Ruta ejecutable:** `tests/h5/postman/`
> - **PRs Draft asociados:**
>   - [#313](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/313) (`poma-hito-5-pruebas-v2`) — Harness Postman/Newman (`H11`–`H25`), helper seguro PG17 (`H26`), suite complementaria Catalog a `#310` e integración local real `Gateway -> Catalog -> Pricing -> Inventory` (`H27`).
>   - [#314](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/314) (`trabajo/poma/h5-apim-errores-autenticacion`) — Corrección Defecto A (APIM 401 RFC 7807, `H28`).
>   - [#315](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/315) (`trabajo/poma/h5-bulk-autenticacion`) — Corrección Defecto C (`BulkUserBearerGuard`, `H29`).

## Contenido conservado en Docs

- `evidencias/` *(intactas, con checksums SHA-256 sin alteración)*:
  - `azure-preflight-2026-11-27/`: Evidencia histórica de bloqueo esperado Modalidad B en ACA (`403`).
  - `azure-apim-edge-2026-11-27/`: Evidencia histórica previa de timeout en APIM (`ETIMEDOUT`).
  - `azure-apim-smoke-jws-2026-11-28/`: Corrida real `smoke` contra APIM Chile con JWS `GESTOR_COMERCIAL` (`9/11` PASS, `2` FAIL APIM 401, `1` NOT_RUN) + `TRAZA-DOWNSTREAM-CATALOG-PRICING.md` (traza ACA redactada de Axel acreditando `catalog-svc -> pricing-svc`).
  - `azure-apim-integration-jws-2026-11-28/`: Corrida real `integration` contra los 8 microservicios en APIM Chile (`27/32` PASS, `5` FAIL en Defectos A/B/C, `4` NOT_RUN).
- `matrices/`:
  - `cobertura-integracion.md` y `cobertura-integracion.csv`: Trazabilidad completa de los 38 casos `PM-*` contra `INT-01`..`INT-09` y OpenAPI `0.7.0-rc.3`.
- `DIAGNOSTICO-DEFECTOS-Y-BRECHAS-H5.md`: Estado diferenciado por nivel de evidencia, consolidación `#310` vs `#313`, resultados exactos `H27`, evidencia reproducible de Frontend (`2c6ad93`) y lista de validaciones reales en `STANDBY`.

## Cómo reproducir localmente (desde Backend)

```powershell
cd <ruta-repo-backend>/tests/h5/postman
npm ci
npm run validate
npm test
```

> **Nota operativa (`STANDBY`):** No ejecute corridas contra Azure APIM, ACA, Service Bus, G7 ni bases compartidas hasta que finalice la ventana de estabilización de CI/CD (`Backend #310`, `Frontend #103`) y se desplieguen las correcciones de APIM (Defecto A) y `bulk-svc` (Defecto C).
