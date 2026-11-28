# Diagnóstico de Defectos, Nota Histórica H11 y Brechas H5

Este documento resume los hallazgos técnicos de las corridas reales en APIM Chile (`2026-11-28`), la nota de reconciliación histórica `H11`, la evaluación de Frontend y el estado de las brechas de Catalog (`Backend #310`).

- **Código ejecutable (fuente única de verdad):** trasladado a `G6-Productos-Ofertas-backend`, carpeta `tests/h5/postman/` — Draft PR [#313](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/313).
- **Evidencias históricas y matrices:** conservadas íntegras en este repositorio (`hitos/h5/demos-integracion-performance/postman/evidencias/` y `matrices/`).

---

## 1. Nota de reconciliación histórica `H11` (sin mutar evidencias previas)

En las corridas reales previas al traslado (`azure-apim-smoke-jws-2026-11-28` y `azure-apim-integration-jws-2026-11-28`), el reporte histórico mostró:
- `smoke`: `12` ejecuciones sobre `11` casos PM ejecutados (`1` caso `NOT_RUN`: `PM-005`).
- `integration`: `33` ejecuciones sobre `32` casos PM ejecutados (`4` casos `NOT_RUN`: `PM-005`, `PM-080`, `PM-081`, `PM-082`).

**Causa exacta:** `PM-003A` disparó **1 solicitud HTTP auxiliar de paginación** (página 2) mediante `pm.sendRequest`, confirmada en la traza ACA de Axel (`37340d3d-9545-435e-ae43-537f7c3421b2` a las `05:03:02.669Z`). Newman registra esa llamada dentro de `run.executions` reutilizando el nombre del ítem padre.

**Resolución:** Las evidencias históricas del `2026-11-28` se preservan intactas sin alterar sus SHA-256. El sanitizer trasladado a Backend (`tests/h5/postman/scripts/lib/sanitizer-core.mjs`, `manifest.json` v1.2.0) separa ahora explícitamente `plannedPmCases`, `executedPmCases`, `notRunPmCases`, `primaryHttpRequests` y `auxiliaryHttpRequests` con regresión automatizada (`PASS / ISOLATED`).

---

## 2. Diagnóstico de los 3 defectos reproducidos en APIM Chile (`FAIL / LAB_AZURE`)

| Defecto | Casos afectados | Causa raíz exacta | Estado actual |
|---|---|---|---|
| **A — APIM 401 no RFC 7807** | `PM-004`, `PM-004B` | `ops/azure/apim/policies/operation-secured.xml` (línea 4) usa `<validate-jwt>` y `api.xml` carece de `<on-error>` para formatear `401` como `application/problem+json` (`code: "TOKEN_INVALIDO"`). | `STANDBY` (parche XML propuesto en Backend PR #313 para aplicación por Axel). |
| **B — Inventory HTTP 400** | `PM-012` | Comportamiento contractual legítimo en `apps/inventory-svc/src/disponibilidad/disponibilidad.service.ts` (líneas 104–112): exige `location_id` cuando el SKU existe en `> 1` ubicación. | `PASS / ISOLATED` (`PM-012` descubre `location_id` vía `GET /inventario/ubicaciones` con `safeSendRequest`; revalidación live en `STANDBY`). |
| **C — Bulk HTTP 401 con JWS válido** | `PM-030`, `PM-031` | Defecto real en Backend `apps/bulk-svc/src/auth/bulk-user-bearer.guard.ts` (líneas 93 y 117–124): exige `aud === 'api-productos'` en JWTs humanos (`tipo: 'acceso'`), claim que G7 solo emite para tokens M2M (`tipo: 'servicio'`). | Diagnosticado con ubicación exacta; parche coordinado sin colisión con PR #310; revalidación live en `STANDBY`. |

---

## 3. Auditoría de Frontend (`G6-Productos-Ofertas-frontend`)

- Se verificó el código de Frontend en la rama `poma-hito-5-pruebas-v2`.
- El cierre de sesión al descargar la plantilla de catálogo es consecuencia directa del HTTP `401 TOKEN_INVALIDO` devuelto por `bulk-svc` (Defecto C), que Frontend maneja correctamente expirando la sesión.
- **Decisión conforme a directriz de auditoría:** No existe defecto funcional en Frontend; **no se modifica el repositorio Frontend ni se abre PR vacío**.

---

## 4. Brechas históricas de `catalog-svc` (`Backend #310`)

Sin modificar `apps/catalog-svc/test/postgres.persistence.e2e-spec.ts` ni ningún archivo de `Backend #310`, se incorporó en Backend PR #313 la suite independiente `apps/catalog-svc/test/h5/catalog-h5-equivalence.test.mjs` (`4/4 PASS / ISOLATED`) cubriendo los 6 escenarios: `TAXONOMY-UPDATES`, `BLOCK-A2`, `JOINT-01`, `JOINT-01-REGRESSION`, `BULK-JOINT` y `BULK-CONSUMER-v2`.

---

## 5. Validaciones reales en `STANDBY`

Las siguientes validaciones contra infraestructura real permanecen en `STANDBY` hasta que se cierren los PR de CI/CD (`Backend #310`, `Frontend #103`) y se apliquen las correcciones de APIM (Defecto A) y `bulk-svc` (Defecto C):
1. Re-ejecución de `smoke` e `integration` contra APIM Chile con `PM-004`/`PM-004B` (RFC 7807), `PM-012` (`location_id`) y `PM-030`/`PM-031` (`bulk-svc`).
2. Ejecución de `PM-005` (403 con identidad restringida) y `PM-080`/`PM-081`/`PM-082` (tokens M2M `modulo-marketplace` y `modulo-ventas`).
3. Pruebas con infraestructura real de Service Bus/PostgreSQL administradas por el pipeline modernizado de PR #310.
