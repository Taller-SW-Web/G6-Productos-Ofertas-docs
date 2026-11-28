# Traza Downstream ACA — `catalog-svc` → `pricing-svc` (`azure-apim-smoke-jws-2026-11-28`)

Este documento registra la traza redactada de Azure Container Apps (ACA) proporcionada por infraestructura (Axel) correspondiente a la corrida real `azure-apim-smoke-jws-2026-11-28` (`2026-11-28 UTC`), acreditando que las consultas filtradas por precio en `catalog-svc` invocaron efectivamente al servicio downstream `pricing-svc` en Azure Chile.

> **Nota de integridad:** Este archivo se agrega de forma complementaria sin modificar ninguno de los artefactos originales ni sus checksums SHA-256 registrados en `evidence-index.json`.

## Correlación verificada (`LAB_AZURE`)

| Caso PM | `X-Correlation-Id` | Llamadas `pricing-svc` (HTTP 200, UTC) | Finalización `catalog-svc` (UTC) | Latencia observada |
|---|---|---|---|---|
| `PM-003A` (página 1 — rango amplio) | `37340d3d-9545-435e-ae43-537f7c3421b2` | `05:03:01.473Z` y `05:03:01.497Z` | `05:03:01.845Z` | `1247–1252 ms` |
| `PM-003A` (página 2 — paginación auxiliar) | `37340d3d-9545-435e-ae43-537f7c3421b2` | `05:03:02.669Z` y `05:03:02.713Z` | `05:03:03.066Z` | `1020–1025 ms` |
| `PM-003B` (rango acotado) | `6817ef69-7ac6-4643-a6a8-3bc49fc49e41` | `05:03:03.848Z` y `05:03:03.866Z` | `05:03:04.244Z` | `977–981 ms` |

## Conclusión técnica

- Queda acreditada de extremo a extremo la cadena **APIM Chile → `api-gateway` → `catalog-svc` → `pricing-svc`** (`INT-01`) con propagación íntegra de `X-Correlation-Id`.
- La presencia de una segunda consulta paginada en `PM-003A` confirma adicionalmente el origen del conteo histórico `H11` (`12` ejecuciones HTTP para `11` casos PM ejecutados en `smoke`, y `33` para `32` en `integration`), ya corregido en el runner trasladado a Backend (`tests/h5/postman/`).
