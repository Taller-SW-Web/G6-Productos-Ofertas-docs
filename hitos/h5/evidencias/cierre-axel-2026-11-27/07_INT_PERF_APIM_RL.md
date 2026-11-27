# Matrices INT-01..10, PERF-01..08, APIM-T01..08 y RL-01..06 — 2026-11-27

> **Criterio estricto de clasificación:** solo se registra `PASS` cuando existe corrida real ejecutada en el nivel declarado. No se promueve L1 a L2, ni L0 estático a L2 en vivo, ni `SKIP` a `PASS`.

## 1. Matriz de Integración `INT-01` a `INT-10` (H5-02)

| ID (Owner) | Nivel L1 aislado (esta corrida) | Nivel L2 Azure real | Nivel L3 Intergrupo | Evidencia / Hallazgo y condición de desbloqueo |
|---|---|---|---|---|
| **INT-01** (Poma) | **PASS (`ISOLATED`, stub G7)** — 158-endpoints (`catalog-svc` 26/26, `pricing-svc` 15/15, `inventory-svc` 24/24) + `catalog-sku-context.http.e2e-spec.ts` (29/29) | `BLOCKED_AUTH` / `PENDING_DEPLOY` | `NOT_RUN` | Requiere despliegue candidato ACA + token G7 real autorizado (G1/Marketplace o Despacho) sobre APIM |
| **INT-02** (Taco) | **PASS (`ISOLATED`, stub G7)** — `inventory-h5.postgres.e2e-spec.ts` (26/26) + specs #297 (`inventory-int02`, 26/26) + 158-endpoints | `BLOCKED_AUTH` / `PENDING_DEPLOY` | `NOT_RUN` | R10 aplicado. Pendientes el candidato desplegado y los grants G7/G5 aplicables. |
| **INT-03** (Axel) | **PASS (`ISOLATED`, stub G7)** — `coupon-h5.postgres.e2e-spec.ts` (12/12) + #148/#149 (`202 -> COMPLETED`, `RESTORED`) + N01 19-flows | `BLOCKED_AUTH` / `PENDING_DEPLOY` | `BLOCKED_AUTH` (G5/G7) | Requiere despliegue candidato (#296) + grants reales G7/G5 para `cupones:consumir`/`restaurar` |
| **INT-04** (Castilla / Poma) | PASS L1. Bulk y flujos relacionados en el stack aislado. | `PENDING_DEPLOY` | N/A | Esquema R10 verificado. Pendiente probar el lote y estado terminal por el candidato en Azure. |
| **INT-05** (Vera) | **PASS (`ISOLATED`)** — `pilot.postgres.e2e-spec.ts` (8/8 transaccional PG17) + `r16-price-audit-restart.postgres.e2e-spec.ts` (**1/1 reinicio real proceso `price-audit-svc`**, PID `30476 -> 29712`, `auditRowsPersisted=1`) + `r03-r14-r16-r17` (3/3) + R16 19-flows | **`PENDING_AZURE_L2`** (obligatorio H5-04B) | N/A | Piloto #234 es antecedente histórico; requiere corrida Azure vigente con SHA/digest candidato y reinicio controlado de `price-audit-svc` en `g6-sb-h5-chile-261127` |
| **INT-06** (López) | **PASS (`ISOLATED`)** — `run-taxonomy-catalog-postgres.mjs` (23/23: R09 + 6 eventos R18) + `verify-taxonomy-observed-ddl` (equivalencia PG17 de objetos ya presentes en Supabase) + `int06-harness.e2e-spec.ts` (2/2) + R09/R18 19-flows | **`PENDING_AZURE_L2`** (esquema H5 equivalente ya existe en Supabase; falta deploy candidato + ensayo L2 R18) | N/A | Requiere deploy candidato + corrida L2 R18 autorizada con los 6 eventos contractuales |
| **INT-07** (Castilla) | PASS L1 con G7 local y validación estática | PARCIAL. CORS y negativas APIM comprobadas | `NOT_RUN` | Tras desplegar, capturar desde APIM la operación de Catálogo permitida a GESTOR_COMERCIAL y correlacionar su respuesta con la revisión y el digest de Gateway. |
| **INT-08** (Poma) | PASS 16/16 Chromium con Frontend `ccfc21ba`, Backend `18413ac4` y G7 local | `PENDING_DEPLOY` | N/A | CORS Vercel comprobado. Ejecutar el recorrido con la sesión GESTOR_COMERCIAL existente tras desplegar el candidato. |
| **INT-09** (Axel) | **PASS (`ISOLATED`, stub G7)** — 158-endpoints operaciones G5 (`reservar`/`confirmar`/`liberar`/`conciliar-offline`/cupones) con `g5Token` sintético y rechazo `403` con cliente ajeno | `BLOCKED_AUTH` | **`PENDIENTE_HOMOLOGACION_G5`** | Requiere ventana bilateral G5–G6, client/scopes G7 verificados y artefacto conjunto |
| **INT-10** (Vera) | **PASS (`ISOLATED`)** — **evidencia separada**: reinicio real de proceso **R03 (`pricing-svc`)** en 19-flows + reinicio real de proceso **R16 (`price-audit-svc`)** (`R16_PRICE_AUDIT_CONSUMER_RESTART.json`) + recuperación transaccional PG17 (`pilot.postgres` 8/8) + replay 19 colas sin efecto doble + DLQ | **`PENDING_AZURE_L2`** | N/A | Requiere prueba de caída/recuperación en ACA/Service Bus autorizada sobre R16 (reinicio de `price-audit-svc`) y R18 |

---

## 2. Matriz de Performance `PERF-01` a `PERF-08` (H5-03)

- Las pruebas Azure se hacen en el entorno de integración autorizado con datos sintéticos y carga gradual. Usar 1, 5 y 20 VU, tres repeticiones comparables y detención ante degradación. Los escenarios de varios clientes se ejecutan en L1 con identidades sintéticas y quedan BLOCKED_AUTH en L2.
- **Harness versionado verificado (L0/L1):** `test-performance-workflow.mjs` (**PASS**), `inventory-perf03-k6` y `inventory-fixture-generator` (#297 vía #306, **26/26 PASS**), y workflow `performance-g6.yml` listo para ejecución opt-in.

| ID (Owner) | Escenario | Estado actual | Motivo / Criterio exacto de desbloqueo |
|---|---|---|---|
| **PERF-01** (Poma) | GET catálogo paginado por canal (1/5/20 VU × 3 repeticiones) | **`NOT_RUN`** (`BLOCKED_ENV`) | Requiere entorno staging autorizado con APIM + dataset sintético versionado + runner `k6` + baseline vs candidato pareados |
| **PERF-02** (Vera) | GET detalle SKU y precio | **`NOT_RUN`** (`BLOCKED_ENV`) | Igual que PERF-01 + telemetría DB/downstream |
| **PERF-03** | GET disponibilidad comercial vía Gateway → Inventory | Un par L1 completado, 0 fallos | p95 66,138 → 39,7 ms y 549,55 → 881,66 solicitudes/s a concurrencia 32. Pendientes perfiles finales Azure. [Datos aislados](artefactos/PERF03_PERF07_L1_2026-11-27.json). |
| **PERF-04** (Axel) | POST admisión idempotente N01 (`202`, throughput y backlog) | **`NOT_RUN` (condicionado al manifest)** — si el manifest de release mantiene N01 deshabilitado en producción, clasificar `scope=OUT_OF_SCOPE` y excluir del denominador del scorecard; si N01 se habilita, requiere BD desechable + `k6` + grants G7 | Decisión de alcance en manifest de release + BD desechable + autorización de entorno |
| **PERF-05** (Axel) | Service Bus mensajes sintéticos (lag, backlog, redelivery, DLQ, ventana 5 min) | **`NOT_RUN`** (`BLOCKED_ENV`) | Requiere corrida Azure autorizada sobre colas de prueba con payloads sintéticos sin datos reales |
| **PERF-06** | Chromium, baseline `2c6ad931` y candidato `ccfc21ba` | `INCONCLUSIVE` transversal, tres pares L1 | Catálogo 1000 filas 4950 → 4874 ms de mediana (−1,54%), 13 requests y 264902 bytes en ambos. En las familias los recuentos varían y hay muestras sin solicitudes. [Resultados y hashes](artefactos/PERF06_3_PARES_2026-11-27.json). |
| **PERF-07** | Admisión HTTP Bulk con PostgreSQL aislado | Dos pares L1 pasaron tras incluir 0009 en el fixture; 0 fallos y 0 timeouts | Concurrencia 32: mediana p95 138,962 → 151,776 ms (+9,22%) y caudal −7,1%. Señal a contrastar con más repeticiones y perfiles Azure. [Datos aislados](artefactos/PERF03_PERF07_L1_2026-11-27.json). |
| **PERF-08** (Castilla) | APIM vs ruta privada equivalente autorizada | **`NOT_RUN`** (`BLOCKED_ENV` / `BLOCKED_AUTH`) | Requiere autorización para medir ambos planos sobre mismo servicio/datos/config con `k6` |

---

## 3. Matriz APIM `APIM-T01` a `APIM-T08` y Rate Limiting `RL-01` a `RL-06` (H5-04A)

### 3.1 Descubrimiento operativo crítico en Azure (auditoría solo lectura 2026-11-27 ~15:10 UTC)

A diferencia del snapshot histórico de la entrega (`apimObserved=0`, `gatewayDirectPublic=true`), la auditoría read-only detectó que **APIM ya está aprovisionado y activo en vivo**:

- **Recurso:** `apim-g6-productos-chile` (`rg-g6-aca-chile`, `Chile Central`, SKU `Developer` capacidad `1`, VNet `External` en `vm-g6-backendVNET/snet-g6-apim`, IP pública `57.156.40.55`, `provisioningState: Succeeded`).
- **API publicada:** `g6-productos-ofertas` en ruta **`/api/v1`** (no `/h5-candidate/api/v1`), `subscriptionRequired: false`, **145 operaciones** (0 rutas internas expuestas), backend `https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io/api/v1`.
- **Modalidad B ACTIVA en `api-gateway` (`api-gateway--0000003`):** `ipSecurityRestrictions` contiene regla `allow-apim-1` (`Allow 57.156.40.55/32`). Toda llamada directa al FQDN de `api-gateway` recibe **HTTP `403 RBAC: access denied`** (incluido `/health/ready`).
- **CORS:** el corte detectó un solo origen. El cambio posterior a la política de API añadió Vercel. [Registro del cambio y preflight](artefactos/APIM_CORS_POST_CAMBIO_2026-11-27.json).
- **Política de operación (`listarProductos`, `SHA256 CD17FD1A21F9B46B31BBACDA17976C5FB6C314951D9C11E1B4B1EA03E29D3EE0`):** valida JWT contra OIDC/JWKS de G7 (`200 OK`, `kid: mjorpqaOV8Yh3izXYLnfY2OnO3zBQe3DgH9dXrOXnjk`) y aplica `rate-limit-by-key` (`120 calls / 60 s`) + `quota-by-key` (`5000 calls / 3600 s`).
- **Validación estática L0 de artefactos Bicep en candidato (`523033a`):** `az bicep build` **PASS**, `29/29` pruebas Python **PASS**, `verify-arm-template.py --mode candidate` **PASS** (145 políticas, 5 rutas privadas excluidas, G5 deshabilitado por defecto).

### 3.2 Estado caso por caso (`APIM-T01..T08` y `RL-01..RL-06`)

| ID | Comprobación | Estado actual | Evidencia observada / Bloqueo exacto |
|---|---|---|---|
| **APIM-T01** | HTTPS a hostname real llega a ruta autorizada y owner | **`BLOCKED_AUTH`** | Hostname live `https://apim-g6-productos-chile.azure-api.net/api/v1` responde TLS/HTTPS; falta token JWT real G7 para acreditar `200` hasta owner |
| **APIM-T02** | Token válido alcanza Gateway; sin token / firma / iss / aud / exp inválido denegado | **PARCIAL** (negativos **`PASS` en vivo**; positivo **`BLOCKED_AUTH`**) | Vivo: sin token -> `401` + `x-correlation-id`; JWT inválido -> `401`. Positivo requiere token real G7 |
| **APIM-T03** | `scope`/`client_id` no permitido recibe `403` | **`BLOCKED_AUTH`** | Requiere token real G7 con scope insuficiente (no fabricar tokens) |
| **APIM-T04** | Origen CORS permitido y no permitido | PASS preflight en vivo | Vercel obtuvo HTTP 200 y el encabezado de origen exacto. Un origen distinto quedó sin ACAO. Falta navegador con G7 real en INT-08. |
| **APIM-T05** | Protección integral contra exceso (`429`, `Retry-After`, aislamiento, no llega a backend, anti-bypass directo) | **PARCIAL** (anti-bypass **`PASS` en vivo**; `429`/aislamiento **`BLOCKED_AUTH` + `BLOCKED_ENV`**) | Vivo: llamada directa a `api-gateway` devuelve **`403 RBAC: access denied`** (anti-bypass demostrado). Política `rate-limit-by-key` 120/60s inspeccionada; ensayo de ráfaga `429` requiere token G7 + autorización de carga |
| **APIM-T06** | Ruta desconocida e internas devuelven `404` sin proxy genérico ni fuga a backend | **`PASS` (solo lectura en vivo)** | Vivo: `/api/v1/productos/skus/TEST-SKU/contexto` -> `404`, `/api/v1/interno/productos/skus/filtrar` -> `404`, `/api/v1/interno/carga-masiva/contenidos/00000000-0000-4000-8000-000000000001` -> `404`; 0 rutas internas en API de 145 operaciones |
| **APIM-T07** | Correlación `X-Correlation-Id` validada y propagada sin fuga | **PARCIAL** (validación/eco en borde **`PASS` en vivo**; traza downstream **`BLOCKED_AUTH`**) | Vivo: `X-Correlation-Id` inválido rechazado `400 VALIDACION`; válido reflejado en respuesta `401`. Traza completa hasta microservicio requiere token G7 |
| **APIM-T08** | Comparación privada equivalente y rollback de configuración | **`NOT_RUN`** (`BLOCKED_ENV` — no se permite mutar APIM live) | Requiere ventana autorizada por Marco Castilla para snapshot pre-cambio, revisión candidata y rollback verificable |
| **RL-01..RL-06** | Ráfaga/s, ventana acumulada, `Retry-After`, aislamiento multi-cliente, 0 llegada a backend, concurrencia+idempotencia | **`NOT_RUN`** (`BLOCKED_AUTH` + `BLOCKED_ENV`) | Requiere 2 identidades/clientes sintéticos autorizados en G7 + runner `k6` + autorización explícita de carga sobre APIM/staging (no ejecutar contra entorno vivo compartido sin aprobación) |
