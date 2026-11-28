# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `h27-real-gateway-preflight`
- **Fecha UTC:** `2026-11-28T10:47:22.010Z`
- **Entorno:** `local` (`http://127.0.0.1:55298`)
- **Perfil:** `folder:00 - Preflight y autenticacion`
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
| Casos PM planificados | 2 |
| Casos PM ejecutados | 2 |
| Casos PM PASS | 1 |
| Casos PM FAIL | 1 |
| Casos PM no ejecutados (NOT_RUN) | 0 |
| Solicitudes HTTP principales | 2 |
| Solicitudes HTTP auxiliares (paginacion/descubrimiento) | 0 |
| Violaciones contractuales auxiliares | 0 |
| INCONCLUSIVE | 0 |
| Aserciones totales | 4 |
| Aserciones aprobadas | 3 |
| Aserciones fallidas | 1 |
| Duracion total (ms) | 156 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado | Bloqueo / Nota |
|---|---|---|---|---:|---:|---:|---|---|---|
| PM-001 | INT-07 | PM-001 - Preflight Gateway Health | GET | 200 | 2/2 | 5 | `1adaa9f3-f286-40b5-ae5e-ba64d87362ca` | **PASS** | - |
| PM-001B | INT-07 | PM-001B - Preflight Gateway Readiness (disponibilidad operativa) | GET | 503 | 1/2 | 4 | `391e2af0-6049-400f-ad80-e7b1368eaa75` | **FAIL** | - |

## Detalle de fallos

### PM-001B — PM-001B - Preflight Gateway Readiness (disponibilidad operativa)
- Asercion fallida: **PM-001B: Disponibilidad operativa acreditada (HTTP 200 y status=ready)** — `Gateway respondio 503 contractual (not_ready): no acredita disponibilidad operativa.`

