# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `h27-real-inv-empty-loc`
- **Fecha UTC:** `2026-11-28T10:47:18.177Z`
- **Entorno:** `local` (`http://127.0.0.1:55298`)
- **Perfil:** `folder:02 - Preparacion comercial e Inventory`
- **Veredicto global:** **`FAIL`**
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
| Casos PM planificados | 3 |
| Casos PM ejecutados | 3 |
| Casos PM PASS | 2 |
| Casos PM FAIL | 1 |
| Casos PM no ejecutados (NOT_RUN) | 0 |
| Solicitudes HTTP principales | 3 |
| Solicitudes HTTP auxiliares (paginacion/descubrimiento) | 0 |
| Violaciones contractuales auxiliares | 0 |
| INCONCLUSIVE | 0 |
| Aserciones totales | 3 |
| Aserciones aprobadas | 2 |
| Aserciones fallidas | 1 |
| Duracion total (ms) | 422 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado | Bloqueo / Nota |
|---|---|---|---|---:|---:|---:|---|---|---|
| PM-010 | INT-01 | PM-010 - Catalog: Estado de preparacion del producto | GET | 200 | 1/1 | 38 | `8e00cef8-fea5-47cd-a1a3-5931b2a2d153` | **PASS** | - |
| PM-011 | INT-01 | PM-011 - Catalog: Listar variantes de producto | GET | 200 | 1/1 | 28 | `250df13f-08a7-4b1d-a38d-ad552eacc7bc` | **PASS** | - |
| PM-012 | INT-02 | PM-012 - Inventory: Disponibilidad autoritativa por SKU encadenado | GET | 200 | 0/1 | 16 | `5c544a32-3555-495e-a62b-cd54270ecbfd` | **FAIL** | - |

## Detalle de fallos

### PM-012 — PM-012 - Inventory: Disponibilidad autoritativa por SKU encadenado
- Asercion fallida: **PM-012: HTTP 200, JSON Schema DisponibilidadStock e invariante de stock** — `expected [] not to be empty`

