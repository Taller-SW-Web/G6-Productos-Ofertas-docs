# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `azure-preflight-2026-11-27`
- **Fecha UTC:** `2026-11-28T03:17:11.271Z`
- **Entorno:** `azure-aca-chile` (`https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io`)
- **Perfil:** `folder:00 - Preflight y autenticacion`
- **Nivel de evidencia:** `LAB_AZURE`
- **Estado de despliegue:** `DESPLEGADO_VERIFICADO_HISTORICO`
- **Contrato OpenAPI:** `0.7.0-rc.3`
- **Node.js / Newman:** `24.16.0` / `6.2.3`
- **SHA Docs (local):** `5f30802129ba4bbc0674dcc5878f10065f443118`
- **SHA Backend (local, solo lectura):** `36f619da6c44a3c14b93917d1fddf2d09bd569db`
- **SHA Frontend (local, solo lectura):** `2c6ad931b8dd48e4a4fe883a18ac899fb48b0c81`
- **SHA-256 Coleccion:** `4c481d1c998d091e52ef4674260a6a659d8580376cf7942a767d0a35b37859bb`

## Resumen de ejecucion

| Metrica | Valor |
|---|---:|
| Solicitudes ejecutadas | 2 |
| PASS | 0 |
| FAIL | 2 |
| INCONCLUSIVE | 0 |
| NOT_RUN | 0 |
| Aserciones totales | 5 |
| Aserciones aprobadas | 0 |
| Aserciones fallidas | 5 |
| Duracion total (ms) | 557 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado |
|---|---|---|---|---:|---:|---:|---|---|
| PM-001 | INT-07 | PM-001 - Preflight Gateway Health | GET | 403 | 0/3 | 258 | `ec6ff3fa-bbe5-4d78-a244-2db69818be07` | **FAIL** |
| PM-001B | INT-07 | PM-001B - Preflight Gateway Readiness | GET | 403 | 0/2 | 47 | `3385be1d-19b6-40d8-a0eb-5e66919d7558` | **FAIL** |

## Detalle de fallos

### PM-001 — PM-001 - Preflight Gateway Health
- Asercion fallida: **PM-001: HTTP 200 en /health** — `expected response to have status code 200 but got 403`
- Asercion fallida: **PM-001: Content-Type application/json** — `expected 'text/plain' to include 'application/json'`
- Asercion fallida: **PM-001: Estructura JSON valida sin exposicion de secretos** — `Unexpected token 'R' at 1:1
RBAC: access denied
^`

### PM-001B — PM-001B - Preflight Gateway Readiness
- Asercion fallida: **PM-001B: HTTP 200 o 503 contractual en /health/ready** — `expected [ 200, 503 ] to include 403`
- Asercion fallida: **PM-001B: Respuesta declara servicio api-gateway y estado** — `Unexpected token 'R' at 1:1
RBAC: access denied
^`


## Bloqueos y advertencias

- APIM aun no cuenta con instancia operativa desplegada (NOT_RUN_BLOCKED_INFRA); la ejecucion apunta al Gateway ACA autorizado.
- PM-005: No se proporciono G6_RESTRICTED_ACCESS_TOKEN; la validacion 403 requiere una identidad autenticada sin permisos.
