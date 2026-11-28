# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `azure-apim-edge-2026-11-27`
- **Fecha UTC:** `2026-11-28T03:53:23.148Z`
- **Entorno:** `azure-apim-chile` (`https://apim-g6-productos-chile.azure-api.net`)
- **Perfil:** `apim-edge`
- **Veredicto global:** **`FAIL`**
- **Nivel de evidencia:** `LAB_AZURE`
- **Estado de despliegue:** `APIM_LIVE_145_OPS`
- **Contrato OpenAPI:** `0.7.0-rc.3`
- **Node.js / Newman:** `24.16.0` / `6.2.3`
- **SHA Docs (local):** `940c5a26670965265c93bdb77638c69ae553b396`
- **SHA Backend (local, solo lectura):** `36f619da6c44a3c14b93917d1fddf2d09bd569db`
- **SHA Frontend (local, solo lectura):** `2c6ad931b8dd48e4a4fe883a18ac899fb48b0c81`
- **SHA-256 Coleccion:** `10f85b8b850189b4f7a9ca27798dc5b82fdf8959dfdf57d08f82139c2d94cec5`

## Resumen y reconciliacion de ejecucion

| Metrica | Valor |
|---|---:|
| Casos planificados | 12 |
| Casos ejecutados en Newman | 3 |
| PASS | 0 |
| FAIL | 3 |
| INCONCLUSIVE | 0 |
| NOT_RUN | 9 |
| Aserciones totales | 5 |
| Aserciones aprobadas | 0 |
| Aserciones fallidas | 5 |
| Duracion total (ms) | 64236 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado | Bloqueo / Nota |
|---|---|---|---|---:|---:|---:|---|---|---|
| PM-002 | INT-01 | PM-002 - Gateway -> Catalog: Listar productos autorizados | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL). |
| PM-003A | INT-01 | PM-003A - Catalog -> Pricing: Filtro por rango de precio amplio | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL). |
| PM-003B | INT-01 | PM-003B - Catalog -> Pricing: Filtro rango acotado y relacion de subconjunto | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL). |
| PM-003C | INT-01 | PM-003C - Catalog: Detalle comercial de producto (simple o con variantes) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL). |
| PM-003D | INT-01 | PM-003D - Pricing: Consultar precio efectivo para SKU encadenado | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL). |
| PM-004 | INT-07 | PM-004 - Negativo: Solicitud sin autenticacion (401) | GET | - | 0/2 | 0 | `673c4299-77a2-4479-afd3-3e3d7889be3b` | **FAIL** | ETIMEDOUT |
| PM-004B | INT-07 | PM-004B - Negativo: Token malformado o invalido (401) | GET | - | 0/2 | 0 | `97d2e90a-255a-4293-ad4e-563636359a49` | **FAIL** | ETIMEDOUT |
| PM-005 | INT-07 | PM-005 - Negativo: Autorizacion insuficiente (403 estricto) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_RESTRICTED_ACCESS_TOKEN (identidad autenticada sin permiso para validar 403). |
| PM-006 | INT-01 | PM-006 - Negativo: Recurso inexistente (404) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL). |
| PM-007A | INT-01 | PM-007A - Negativo: Rango de precios inconsistente (precioMin > precioMax) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL). |
| PM-007B | INT-01 | PM-007B - Negativo: Canal y paginacion invalidos (400) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL). |
| PM-008 | INT-07 | PM-008 - Negativo: Ruta desconocida en APIM/Gateway (404) | GET | - | 0/1 | 0 | `09926bfa-7464-4e0e-a2de-3e689122f067` | **FAIL** | ETIMEDOUT |

## Detalle de fallos

### PM-004 — PM-004 - Negativo: Solicitud sin autenticacion (401)
- Error de red/solicitud: `ETIMEDOUT`
- Asercion fallida: **PM-004: HTTP 401 sin Authorization** — `expected PostmanResponse{ …(5) } to have property 'code'`
- Asercion fallida: **PM-004: Problem Details TOKEN_INVALIDO sin fuga de items** — `"undefined" is not valid JSON`

### PM-004B — PM-004B - Negativo: Token malformado o invalido (401)
- Error de red/solicitud: `ETIMEDOUT`
- Asercion fallida: **PM-004B: HTTP 401 con JWT invalido** — `expected PostmanResponse{ …(5) } to have property 'code'`
- Asercion fallida: **PM-004B: Problem Details TOKEN_INVALIDO sin fuga de datos** — `"undefined" is not valid JSON`

### PM-008 — PM-008 - Negativo: Ruta desconocida en APIM/Gateway (404)
- Error de red/solicitud: `ETIMEDOUT`
- Asercion fallida: **PM-008: HTTP 404 para ruta fuera de contrato** — `expected PostmanResponse{ …(5) } to have property 'code'`


## Bloqueos y advertencias

- Ejecucion parcial (FAIL): 9 de 12 casos planificados quedaron NOT_RUN por credenciales ausentes.
