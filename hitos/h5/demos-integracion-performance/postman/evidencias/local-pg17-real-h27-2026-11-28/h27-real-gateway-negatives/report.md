# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `h27-real-gateway-negatives`
- **Fecha UTC:** `2026-11-28T10:47:26.805Z`
- **Entorno:** `local` (`http://127.0.0.1:55298`)
- **Perfil:** `folder:09 - APIM, Gateway y G7`
- **Veredicto global:** **`PARTIAL_NOT_COMPLETE`**
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
| Casos PM planificados | 7 |
| Casos PM ejecutados | 6 |
| Casos PM PASS | 6 |
| Casos PM FAIL | 0 |
| Casos PM no ejecutados (NOT_RUN) | 1 |
| Solicitudes HTTP principales | 6 |
| Solicitudes HTTP auxiliares (paginacion/descubrimiento) | 0 |
| Violaciones contractuales auxiliares | 0 |
| INCONCLUSIVE | 0 |
| Aserciones totales | 6 |
| Aserciones aprobadas | 6 |
| Aserciones fallidas | 0 |
| Duracion total (ms) | 722 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado | Bloqueo / Nota |
|---|---|---|---|---:|---:|---:|---|---|---|
| PM-004 | INT-07 | PM-004 - Negativo: Solicitud sin autenticacion (401) | GET | 401 | 1/1 | 5 | `e5bde4cf-bb60-4806-a252-8cee69d67284` | **PASS** | - |
| PM-004B | INT-07 | PM-004B - Negativo: Token malformado o invalido (401) | GET | 401 | 1/1 | 4 | `335e86d5-2a66-4bd3-a77a-c9a0ee60aad6` | **PASS** | - |
| PM-005 | INT-07 | PM-005 - Negativo: Autorizacion insuficiente (403 estricto) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_RESTRICTED_ACCESS_TOKEN (identidad autenticada sin permiso para validar 403). |
| PM-006 | INT-01 | PM-006 - Negativo: Recurso inexistente (404) | GET | 404 | 1/1 | 23 | `2e458367-c786-4c25-ae6b-533b6d6accf2` | **PASS** | - |
| PM-007A | INT-01 | PM-007A - Negativo: Rango de precios inconsistente (precioMin > precioMax) | GET | 400 | 1/1 | 9 | `3298b691-4019-4c89-a555-1ee557cea4c3` | **PASS** | - |
| PM-007B | INT-01 | PM-007B - Negativo: Canal y paginacion invalidos (400) | GET | 400 | 1/1 | 7 | `27f64ba0-32fc-475f-a96f-174fc358f5af` | **PASS** | - |
| PM-008 | INT-07 | PM-008 - Negativo: Ruta desconocida en APIM/Gateway (404) | GET | 404 | 1/1 | 4 | `5e1a2c7f-5551-4c32-a8a4-3372382a40d7` | **PASS** | - |

## Bloqueos y advertencias

- Ejecucion parcial (PARTIAL_NOT_COMPLETE): 1 de 7 casos PM planificados quedaron NOT_RUN.
