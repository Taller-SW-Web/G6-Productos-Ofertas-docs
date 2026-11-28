# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `h27-real-catalog-pricing`
- **Fecha UTC:** `2026-11-28T10:47:02.067Z`
- **Entorno:** `local` (`http://127.0.0.1:55298`)
- **Perfil:** `folder:01 - Catalog y Pricing`
- **Veredicto global:** **`PASS`**
- **Nivel de evidencia:** `ISOLATED`
- **Estado de despliegue:** `LOCAL_HARNESS`
- **Contrato OpenAPI:** `0.7.0-rc.3` (`STRICT_OFFICIAL`)
- **SHA-256 OpenAPI:** `a0021cb567c93b6f38389ce44f6bf487cd83b0067110e098aa73b8611382c9bd`
- **SHA-256 Matriz CSV:** `90fcfd89300b8e8547f58db64597d0bdb4dc617a73086a11a270d8e263edb32b`
- **Node.js / Newman:** `24.16.0` / `6.2.3`
- **SHA Backend (local):** `6dbbf1ce5b10cdf903a3ea6f659a121f0da6ff4b`
- **SHA Frontend (local):** `02ada63217bfd448c7be621fbadfa6e48a325f64`
- **SHA Docs (local):** `2ccefce93d7c10f2e9eb39ae0ee77b10ee00324c`
- **SHA-256 Coleccion:** `dc0d2356964ffdd981c77535d40dd208fc32d4b3b11825152fc8f3c9878f7a0a`

## Resumen y reconciliacion de ejecucion (H11 + H31)

| Metrica | Valor |
|---|---:|
| Casos PM planificados | 5 |
| Casos PM ejecutados | 5 |
| Casos PM PASS | 5 |
| Casos PM FAIL | 0 |
| Casos PM no ejecutados (NOT_RUN) | 0 |
| Solicitudes HTTP principales | 5 |
| Solicitudes HTTP auxiliares (paginacion/descubrimiento) | 0 |
| Violaciones contractuales auxiliares | 0 |
| INCONCLUSIVE | 0 |
| Aserciones totales | 7 |
| Aserciones aprobadas | 7 |
| Aserciones fallidas | 0 |
| Duracion total (ms) | 1216 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado | Bloqueo / Nota |
|---|---|---|---|---:|---:|---:|---|---|---|
| PM-002 | INT-01 | PM-002 - Gateway -> Catalog: Listar productos autorizados | GET | 200 | 1/1 | 287 | `0b4329dd-195f-47be-a6b6-a9731f989030` | **PASS** | - |
| PM-003A | INT-01 | PM-003A - Catalog -> Pricing: Filtro por rango de precio amplio (con paginacion completa) | GET | 200 | 2/2 | 163 | `c1a62800-ee6f-4e97-a6c3-e34beb45e2c3` | **PASS** | - |
| PM-003B | INT-01 | PM-003B - Catalog -> Pricing: Filtro rango acotado y relacion de subconjunto estricta | GET | 200 | 2/2 | 67 | `b76834cd-0f12-4c25-ad14-bc778fb91525` | **PASS** | - |
| PM-003C | INT-01 | PM-003C - Catalog: Detalle comercial y extraccion de todos los SKUs elegibles | GET | 200 | 1/1 | 27 | `f062c03b-5f30-497a-ae5c-0f1b0417f630` | **PASS** | - |
| PM-003D | INT-01 | PM-003D - Pricing: Consultar precios efectivos de todos los SKUs elegibles del producto | GET | 200 | 1/1 | 37 | `1ec7cf3c-ec51-403d-a7d4-812e9db1977c` | **PASS** | - |
