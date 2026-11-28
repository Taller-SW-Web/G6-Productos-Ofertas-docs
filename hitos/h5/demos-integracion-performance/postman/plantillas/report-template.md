# Reporte de Pruebas de Integracion HTTP — G6 Hito 5

- **Run ID:** `<run-id>`
- **Fecha UTC:** `<timestamp-utc>`
- **Entorno:** `<environment>` (`<target-origin>`)
- **Perfil:** `<profile>`
- **Nivel de evidencia:** `<STATIC|ISOLATED|LAB_AZURE|STAGING_REAL|INTERGROUP>`
- **Estado de despliegue:** `<deployment-state>`
- **Contrato OpenAPI:** `0.7.0-rc.3`
- **Node.js / Newman:** `<node-version>` / `<newman-version>`
- **SHA Docs (local):** `<docs-sha>`
- **SHA Backend (local, solo lectura):** `<backend-sha>`
- **SHA Frontend (local, solo lectura):** `<frontend-sha>`
- **SHA-256 Coleccion:** `<collection-sha256>`

## Resumen de ejecucion

| Metrica | Valor |
|---|---:|
| Solicitudes ejecutadas | 0 |
| PASS | 0 |
| FAIL | 0 |
| INCONCLUSIVE | 0 |
| NOT_RUN | 0 |
| Aserciones totales | 0 |
| Aserciones aprobadas | 0 |
| Aserciones fallidas | 0 |
| Duracion total (ms) | 0 |

## Resultados por caso

| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado |
|---|---|---|---|---:|---:|---:|---|---|
| PM-001 | INT-07 | Preflight Gateway Health | GET | 200 | 3/3 | 0 | `<uuid>` | **PASS** |

## Bloqueos y advertencias

- Registrar cualquier bloqueo externo (credenciales G7, APIM no desplegado, ausencia de traza downstream).
