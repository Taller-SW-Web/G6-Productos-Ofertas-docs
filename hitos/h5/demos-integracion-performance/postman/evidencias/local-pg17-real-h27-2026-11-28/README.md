# Evidencia Sanitizada H35 — Integración Local Real `Gateway -> Catalog -> Pricing -> Inventory` (PostgreSQL 17)

- **Fecha UTC:** `2026-11-28`
- **Nivel de evidencia:** `PASS / ISOLATED (PostgreSQL descartable)`
- **SHAs auditados:**
  - **Backend (`#313`, rama `poma-hito-5-pruebas-v2`):** `6dbbf1ce5b10cdf903a3ea6f659a121f0da6ff4b`
  - **Docs (`#154`, base contractual verificada):** `2ccefce93d7c10f2e9eb39ae0ee77b10ee00324c`
  - **Frontend (`master` tras merge de `#103`):** `02ada63217bfd448c7be621fbadfa6e48a325f64`

## Entorno de prueba y fronteras

- **Base de datos descartable:** Contenedor efímero `postgres@sha256:b0f9560a2de083e2cc7382e75f808c7381a32852a7ec49117deedb300e552b24` (PostgreSQL 17) en loopback `127.0.0.1` con base dedicada `h5_catalog_*_isolated`, eliminado automáticamente al finalizar (`tests/h5/run-catalog-h5-newman-postgres.mjs`).
- **Roles runtime no propietarios (mínimos privilegios, `H33`):** `catalog_app`, `pricing_app` e `inventory_app` (sin uso de `postgres` en runtime de servicios).
- **Servicios productivos reales ejecutados:** `api-gateway`, `catalog-svc`, `pricing-svc`, `inventory-svc`.
- **Fronteras simuladas y fixtures:** JWKS RS256 sintético en loopback (`127.0.0.1`), respuestas de Taxonomy (`/api/v1/marcas`, `/api/v1/categorias`) en loopback local, y fixtures deterministas sembrados en PostgreSQL 17 descartable (producto simple, producto multi-variante con 2 variantes, precios base y overrides, 3 ubicaciones de inventario). Sin conexión a Azure APIM, ACA, Service Bus, G7 ni bases compartidas (`STANDBY`).

## Resultados diferenciados (Vitest vs corridas individuales Newman)

- **Vitest (`vitest-h5-real-report.json`):** **`6/6 PASS` (`0` failed, `0` skipped)** (`3/3` complemento Catalog H5 + `3/3` bloques `H27`/`H34`).
- **Newman (7 corridas sanitizadas, NO sumadas como casos únicos de la colección — 22 casos PASS, 3 FAIL controlados, 1 NOT_RUN a través de las corridas):**

| Carpeta de evidencia | Perfil / Escenario Newman | PASS | FAIL (controlado) | NOT_RUN | Veredicto Newman |
|---|---|---:|---:|---:|---|
| `h27-real-catalog-pricing/` | Carpeta `01 - Catalog y Pricing` (`PM-002`, `PM-003A`, `PM-003B`, `PM-003C`, `PM-003D`) | 5 | 0 | 0 | `PASS` (`exitCode=0`) |
| `h27-real-inv-single-loc/` | Carpeta `02` Esc. 1: 1 ubicación sin `location_id` (`PM-010`, `PM-011`, `PM-012` HTTP 200) | 3 | 0 | 0 | `PASS` (`exitCode=0`) |
| `h27-real-inv-multi-noloc/` | Carpeta `02` Esc. 2: multi-ubicación sin `location_id` (`PM-010`/`011` PASS; `PM-012` HTTP 400 `VALIDACION`) | 2 | 1 | 0 | `FAIL` (controlado) |
| `h27-real-inv-multi-valid-loc/` | Carpeta `02` Esc. 3: multi-ubicación con `location_id` UUID (`PM-010`, `PM-011`, `PM-012` HTTP 200) | 3 | 0 | 0 | `PASS` (`exitCode=0`) |
| `h27-real-inv-empty-loc/` | Carpeta `02` Esc. 4: ubicación sin saldo (`PM-010`/`011` PASS; `PM-012` HTTP 200 `items=[]`) | 2 | 1 | 0 | `FAIL` (controlado) |
| `h27-real-gateway-preflight/` | Carpeta `00 - Preflight` (`PM-001` HTTP 200 PASS; `PM-001B` HTTP 503 FAIL honesto) | 1 | 1 | 0 | `FAIL` (esperado sin los otros 4 servicios) |
| `h27-real-gateway-negatives/` | Carpeta `09 - APIM, Gateway y G7` (`PM-004`, `004B`, `006`, `007A`, `007B`, `008` PASS; `PM-005` `NOT_RUN`) | 6 | 0 | 1 | `PARTIAL_NOT_COMPLETE` (`exitCode=5`) |

Cada subcarpeta contiene: `manifest.json`, `integration-results.json`, `newman-summary.json`, `newman.junit.xml`, `report.md` y `evidence-index.json` (índice SHA-256 sin respuestas crudas, tokens ni secretos).
