# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `azure-apim-smoke-jws-2026-11-28`
- **Fecha UTC:** `2026-11-28T05:03:07.334Z`
- **Entorno:** `azure-apim-chile` (`https://apim-g6-productos-chile.azure-api.net`)
- **Perfil:** `apim-edge`
- **Veredicto global:** **`FAIL`**
- **Nivel de evidencia:** `LAB_AZURE`
- **Estado de despliegue:** `APIM_LIVE_145_OPS`
- **Contrato OpenAPI:** `0.7.0-rc.3`
- **Node.js / Newman:** `24.16.0` / `6.2.3`
- **SHA Docs (local):** `769fac059c1ca2543fd57b639bbd5a18d2a7dc5c`
- **SHA Backend (local, solo lectura):** `36f619da6c44a3c14b93917d1fddf2d09bd569db`
- **SHA Frontend (local, solo lectura):** `2c6ad931b8dd48e4a4fe883a18ac899fb48b0c81`
- **SHA-256 Coleccion:** `de0f6d6345168f46256b89ee77d680b96f19971e0789c5379139d9a43a37d961`

## Resumen y reconciliacion de ejecucion

| Metrica | Valor |
|---|---:|
| Casos planificados | 12 |
| Casos ejecutados en Newman | 12 |
| PASS | 9 |
| FAIL | 2 |
| INCONCLUSIVE | 0 |
| NOT_RUN | 1 |
| Aserciones totales | 12 |
| Aserciones aprobadas | 10 |
| Aserciones fallidas | 2 |
| Duracion total (ms) | 8052 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado | Bloqueo / Nota |
|---|---|---|---|---:|---:|---:|---|---|---|
| PM-002 | INT-01 | PM-002 - Gateway -> Catalog: Listar productos autorizados | GET | 200 | 1/1 | 1158 | `c3b735fa-1dd0-4564-a96c-c8d1e7f8dbfa` | **PASS** | - |
| PM-003A | INT-01 | PM-003A - Catalog -> Pricing: Filtro por rango de precio amplio (con paginacion completa) | GET | 200 | 1/1 | 1132 | `37340d3d-9545-435e-ae43-537f7c3421b2` | **PASS** | - |
| PM-003B | INT-01 | PM-003B - Catalog -> Pricing: Filtro rango acotado y relacion de subconjunto estricta | GET | 200 | 2/2 | 1111 | `6817ef69-7ac6-4643-a6a8-3bc49fc49e41` | **PASS** | - |
| PM-003C | INT-01 | PM-003C - Catalog: Detalle comercial y extraccion de todos los SKUs elegibles | GET | 200 | 1/1 | 976 | `5fa9f27f-148f-4e41-a707-7feca9dbb9c7` | **PASS** | - |
| PM-003D | INT-01 | PM-003D - Pricing: Consultar precios efectivos de todos los SKUs elegibles del producto | GET | 200 | 1/1 | 531 | `427e894c-af44-4fad-a560-ca11db885faf` | **PASS** | - |
| PM-004 | INT-07 | PM-004 - Negativo: Solicitud sin autenticacion (401) | GET | 401 | 0/1 | 44 | `bbc155e8-724e-4ae6-a2ed-d64c7353ab59` | **FAIL** | - |
| PM-004B | INT-07 | PM-004B - Negativo: Token malformado o invalido (401) | GET | 401 | 0/1 | 40 | `d9c99d9e-9696-443d-ad50-621438a03c21` | **FAIL** | - |
| PM-005 | INT-07 | PM-005 - Negativo: Autorizacion insuficiente (403 estricto) | GET | - | 0/0 | 0 | `-` | **NOT_RUN** | BLOCKED_AUTH: Requiere G6_RESTRICTED_ACCESS_TOKEN (identidad autenticada sin permiso para validar 403). |
| PM-006 | INT-01 | PM-006 - Negativo: Recurso inexistente (404) | GET | 404 | 1/1 | 297 | `7d9084af-049b-41b4-aa75-70f2985923e7` | **PASS** | - |
| PM-007A | INT-01 | PM-007A - Negativo: Rango de precios inconsistente (precioMin > precioMax) | GET | 400 | 1/1 | 52 | `1b271ad9-a8be-4279-ae2f-9ecb3a0fd5ad` | **PASS** | - |
| PM-007B | INT-01 | PM-007B - Negativo: Canal y paginacion invalidos (400) | GET | 400 | 1/1 | 309 | `17312648-7417-4153-a4a7-b73c38b7e282` | **PASS** | - |
| PM-008 | INT-07 | PM-008 - Negativo: Ruta desconocida en APIM/Gateway (404) | GET | 404 | 1/1 | 37 | `ad1de12d-ec08-4aa3-89a1-899109b59fcc` | **PASS** | - |

## Detalle de fallos

### PM-004 — PM-004 - Negativo: Solicitud sin autenticacion (401)
- Asercion fallida: **PM-004: HTTP 401 Problem Details TOKEN_INVALIDO sin fuga** — `PM-004 requiere title: expected {[BODY_REDACTED]} to have property 'title'`

### PM-004B — PM-004B - Negativo: Token malformado o invalido (401)
- Asercion fallida: **PM-004B: HTTP 401 Problem Details TOKEN_INVALIDO sin fuga** — `PM-004B requiere title: expected {[BODY_REDACTED]} to have property 'title'`


## Bloqueos y advertencias

- Ejecucion parcial (FAIL): 1 de 12 casos planificados quedaron NOT_RUN.
