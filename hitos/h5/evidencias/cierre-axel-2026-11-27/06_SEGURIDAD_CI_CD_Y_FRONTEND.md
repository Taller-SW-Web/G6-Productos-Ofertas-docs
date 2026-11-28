# Seguridad H5-01, CI/CD Multi-Repositorio y Frontend #102 — 2026-11-27

## 1. Corridas de CI en GitHub Actions, sin despliegue ni publicación

| Repositorio | PR / SHA | Run ID | Veredicto | Jobs clave verificados |
|---|---|---|---|---|
| **Backend** | Ready for Review `#307`, `db49a5b7a5e2cfa1e4b8033a65c9d2075ef57d4a` | [CI del candidato](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46086802435) | Ver estado de la corrida enlazada | Candidato G5. Corte anterior de4a54ba con 22/22. |
| **Frontend** | `#102` (`ccfc21ba0e821f33c0debf09389879e55df0539b`) | [`#46028914883`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46028914883) | **PASS (21/21 ejecutados; 1 opt-in skipped)** | `validate`, **`Seguridad H5 (fixtures, bundles y diff)` (Gitleaks 8.30.1 por checksum SHA-256)**, `Auditoría de dependencias High/Critical` (SCA H5), `Compilación - Integración con API`, `E2E Pricing`, `@smoke`, 4/4 shards Playwright, unitarias y política de release |
| **Frontend PERF-06** | `#102` (`ccfc21ba...`) vs `master` (`2c6ad931...`) | [`#46043178034`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/actions/runs/46043178034) | **PASS (benchmark pareado en mismo runner)** | `Benchmark administrativo base y optimizado (opt-in)`: 81 rutas / 14 familias SPA + datasets 20/100/1000 filas (`artefactos/PERF06_admin-performance-comparison.json`) |
| **Docs** | `#152` (validación previa `#46031816661` + re-validación tras corte actualizado) | [`#46031816661`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/runs/46031816661) | **PASS (4/4; Pages publish skipped)** | `Validar contrato y ambas alternativas Swagger`, `Verificar y empaquetar candidato Pages`, `validate-docs` |

- El check requerido de Backend está acreditado en el corte anterior de4a54ba. El nuevo candidato de G5 tiene una corrida por SHA en el mismo PR. La publicación y el CD oficiales exigirán el CI exitoso de push sobre el SHA posterior al merge en master. Frontend #102 y Docs #152 conservan su estado Draft.

## 2. Frontend #102 — Playwright contra Backend candidato real (`18413ac`) y separación de runs

1. **Suite Playwright real contra stack Backend #307 (`playwright.real.config.ts`, `VITE_DATA_MODE=api`, `VITE_G6_ADMIN_API_ENABLED=true`):**
   - **Sujetos fijados:** Backend `18413ac459b24793f4f09ea07104d5281c0be3c7`, Frontend `ccfc21ba0e821f33c0debf09389879e55df0539b`, Docs `5f30802129ba4bbc0674dcc5878f10065f443118` (`0.7.0-rc.3`), PG17 descartable + bus aislado `HTTP_IN_MEMORY_NOT_AZURE` + G7 local RS256 (`SIMULATED_DEPENDENCY`).
   - **Resultado:** **16/16 PASS, 0 FAIL, 0 SKIP (`exit 0`, 156.2 s)** — artefacto `artefactos/FE_102_REAL_STACK_PLAYWRIGHT_SUMMARY.json`.
   - **Cobertura demostrada en navegador real Chromium:** Catalog, Taxonomy, Pricing (`PriceEditForm` + `ConfirmDialog`), Price Audit (causal R16 + exportación CSV `COMPLETED`), Promotions (promoción + cupón), Inventory (`/inventario` + `/inventario/umbrales`), Combos, Bulk (8a `202 QUEUED`, 8b `COMPLETED` en `8275 ms`, 8c CSV inválido), sesión G7 RS256 con `Authorization Bearer` y `X-Correlation-Id`, `AccessDenied` + Gateway `401`/`403`, credenciales inválidas/bloqueadas/refresh rotate/logout revoke, manejo de `429 Retry-After` y no-reintento en mutaciones ambiguas `503`, matriz `P0-AUTH-09` en 8 proveedores y flujo transversal encadenado + N01 técnico.
2. **Corrida Playwright completa en CI (`#46028914883`, 4/4 shards + Pricing + smoke):** **PASS 100%** (0 fallos).
3. **Corrida Playwright completa local (separada de reintentos):** 664 passed, 8 skipped, 2 fallos transitorios por contención CPU (`promotions-coupon-http.spec.ts:251`, `transversal-integration.spec.ts:111`); **reintento focalizado aislado separado:** **2/2 PASS** (30.6 s).
4. **Navegador → APIM → Gateway → servicio (L2).** El origen Vercel pasó el preflight CORS en vivo. Falta acceso G7 real y el candidato desplegado.

## 3. Controles de Seguridad H5-01 y diagnóstico de brechas GitHub

| Control H5-01 | Estado | Evidencia real / Diagnóstico |
|---|---|---|
| **SCA (`npm audit --audit-level=moderate`)** | **PASS** | `0` vulnerabilidades en Backend (`18413ac`) y Frontend (`ccfc21ba`); jobs SCA en verde en `#46044277201` y `#46028914883` |
| **SBOM CycloneDX 1.5** | **PASS** | `artefactos/sbom-backend.cdx.json` (444 comp., `SHA256 09f13aae...`) y `artefactos/sbom-frontend.cdx.json` (282 comp., `SHA256 2e68ba5f...`) |
| **Secretos (Gitleaks + escaneo diffs)** | **PASS (CI FE + local)** | Gitleaks `8.30.1` en verde en Frontend CI `#46028914883`; `0` hallazgos en diffs y reportes Backend/Docs. **Diagnóstico GitHub `404`:** Secret Scanning nativo deshabilitado en los 3 repos (requiere plan/configuración de org admin) |
| **SAST / CodeQL** | **Pendiente de resolución de gobernanza** | CodeQL sin configurar. Semgrep ejecutó 74 reglas en Backend y Frontend con cero hallazgos. Gitleaks de Frontend pasó en CI. [Detalles y alcance](artefactos/SECURIDAD_DRAFT_2026-11-27.json) |
| **Trivy (imágenes de CI)** | **PASS** | Trivy 0.76.2 sobre nueve imágenes de f3cc10d. Cero hallazgos críticos o altos. [Corrida y reportes](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46060439353) |
| **IaC (APIM Bicep)** | **PASS (L0 local)** | 30 pruebas Python, 3 pruebas Node del verificador y ARM con 149 políticas de operación. Incluye las cuatro G5 M2M y excluye cinco internas y dos Pricing. [CI del candidato](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46086802435) |
| **JWT negativos y separación de identidades** | **PASS (L1 completo + L2 negativos live)** | L1: 158/158 `auth401`/`auth403` + 6/6 authChecks + 16/16 Playwright real-stack (`P0-AUTH-09`). L2 live APIM: `401` sin token/mal JWT, `400` mala correlación, `404` 5/5 rutas internas, `403` anti-bypass directo Gateway |
| **Protecciones de rama / permisos** | **PARCIAL** | Backend `master` tiene Ruleset `24961806` + Environments `azure-h5*` con `required_reviewers`; 38/38 RBAC mínimo por cola en Service Bus. **Brecha:** Frontend y Docs tienen `rulesets=[]` en `master` |

## Seguridad verificada en el candidato de la auditoría

Trivy 0.76.2 escaneó las nueve imágenes de CI de `f3cc10d` con **0 críticos y 0 altos** después de actualizar Node LTS y retirar el npm global de ejecución. Semgrep 1.187.0 ejecutó 74 reglas sobre 446 archivos Backend y 463 Frontend, con 0 hallazgos y dos advertencias por repositorio. Se registra como alternativa SAST de alcance acotado, pendiente de aceptación formal. La API de GitHub informó CodeQL `not-configured` y Secret Scanning deshabilitado en Backend. El required check de Backend existe; la API de reglas efectivas no devolvió reglas para `master` de Frontend/Docs. El [artefacto de auditoría](artefactos/SECURIDAD_DRAFT_2026-11-27.json) incluye IDs de imágenes y hashes de reportes.
