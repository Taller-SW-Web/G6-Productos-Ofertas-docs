# Plan Accionable de Release, Cutover y Rollback — G6 Hito 5 (2026-11-27)

> **Estado:** Plan preparado y listo para ejecución bajo **autorización expresa de Marco Castilla** y los owners de cada componente. **La política CORS de APIM ya fue corregida. El despliegue del candidato y la migración R10 siguen pendientes.**

## 1. Escalación operativa previa al cutover (hallazgo Azure 2026-11-27)

Antes de desplegar nuevas imágenes o abrir tráfico, **Marco Castilla** debe confirmar la decisión operativa sobre el estado actual observado en vivo (`rg-g6-aca-chile`):

1. **`api-gateway--0000003` tiene Modalidad B activa (`allow-apim-1: 57.156.40.55/32`)** y bloquea con HTTP `403` toda llamada directa a `https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io`.
   - **Propuesta de recuperación / continuidad (si algún consumidor externo G1/G3/G5 aún apunta al FQDN directo de Gateway):**
     - **Opción A (recomendada si todos los consumidores migran a APIM):** comunicar formalmente la URL canónica `https://apim-g6-productos-chile.azure-api.net/api/v1` y mantener Modalidad B activa (cumple anti-bypass `APIM-T05`).
     - **Opción B (contingencia temporal reversible):** remover temporalmente la regla `allow-apim-1` en `api-gateway` solo durante ventana de migración de clientes, preservando la URL activa del Gateway, y reactivarla una vez confirmada la migración de G1/G3/G5/Frontend.
2. **Política CORS live en `apim-g6-productos-chile`:** Vercel ya está permitido. [Evidencia](artefactos/APIM_CORS_POST_CAMBIO_2026-11-27.json).
- **Previo a Frontend L2:** revalidar CORS y usar una sesión G7 autorizada para el recorrido completo.
3. **Delta APIM de #305:** incorporado en Backend Draft #307 `7ecee3f` una sola vez.

---

## 2. Checklist de autorizaciones expresas previas

| Gate | Autoridad requerida | Criterio verificable antes de avanzar |
|---|---|---|
| Merge a `master` (Backend, Frontend, Docs) | Marco Castilla | PRs salen de Draft, CI `Lint, Typecheck, Test, Build & Smoke Test` / `validate` / `validate-docs` en verde en SHA final |
| Backup / PITR Supabase (`slzglmtiyrzygpkiuthf`) | Owner BD + Marco Castilla | Confirmación de punto de restauración PITR y ejecución previa de `BD_PREDEPLOY_CHECKS.sql` (solo SELECT) |
| Migración BD Inventory R10 (`0002`) | Taco + Owner BD + Castilla | Revisión de `po_inventory_owner`, 0 filas previas en `inventory.outbox_delivery`, checksum `7ac74f99...` y registro acordado sin alterar `0001`/`0002` históricos |
| Verificación BD Taxonomy (R09/R18) | López + Owner BD | Confirmar en solo lectura la equivalencia con los objetos instalados y los dos historiales. Una desviación funcional requiere una migración diferencial aprobada |
| Publicación GHCR + Despliegue ACA | Marco Castilla (Environment approval `azure-h5-chile`) | Workflow `publish-only-images.yml` + `cd-services-azure.yml` sobre commit de `master`, capturando digest `sha256` por servicio |
| Grants / Tokens G7 reales | Owner G7 + Castilla | Verificación de `client_id`, `audience`, `scopes` y usuarios/clientes de prueba en ambiente autorizado |
| Ventana L2 Service Bus + APIM / k6 | Marco Castilla + Owners | Autorización explícita para tráfico sintético y pruebas de fallo/recuperación en staging/lab |

---

## 3. Orden de despliegue por dependencias (Wave 0 → Wave 4)

### Wave 0 — Preflight de BD, Snapshot y Conciliación (solo lectura)
1. Ejecutar `hitos/h5/cierre-post-r2/BD_PREDEPLOY_CHECKS.sql` + las 4 consultas `READ ONLY` de diagnóstico de `catalog.outbox` (`05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md`).
2. Confirmar PITR/snapshot activo en Supabase `slzglmtiyrzygpkiuthf`.
3. Guardar snapshot JSON de revisiones ACA actuales (`artefactos/azure-aca-readonly-snapshot-2026-11-27.json`) y XML de políticas APIM actuales como línea base de rollback.
4. Confirmar que las 19 colas en `g6-sb-h5-chile-261127` están `Active` con `active=0, dlq=0` y que las Managed Identities ACA tienen RBAC mínimo (`Azure Service Bus Data Sender` / `Data Receiver` por cola según matriz).

### Wave 1 — Migración R10 y verificación de esquemas (flags H5 nuevos en `false`)
1. **Inventory R10 (`Taco` / Owner BD):** con autorización expresa, respaldo verificable y ventana confirmada, aplicar `apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.sql` (`SHA256 7ac74f99...`) como `po_inventory_owner`. Registrar el artefacto aplicado con su checksum sin modificar las entradas históricas. Verificar `ck_inventory_delivery_route` con cuatro destinos y los permisos de `inventory_app`.
2. **Taxonomy R09/R18 (`López` / Owner BD):** verificar en solo lectura la equivalencia de `outbox_delivery`, función, trigger, eventos y ACL con [la reconciliación de esquema e historiales](05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md). Conservar los dos registros H5 globales y el ledger del servicio hasta `0005`. **Queda excluida la ejecución o el registro de `0006` completa.** Ante una desviación funcional demostrada, ensayar un diferencial versionado y reversible en una transacción completa. R18 requiere el despliegue y la corrida L2.
3. **Pricing (`Vera` / Owner BD):** confirmar vía `SELECT` la entrada global `g6_h5_pricing_0003_service_bus_routes_r2` y los cuatro destinos compatibles. Si aparece una desviación, reconciliarla antes del release.
4. **Regla inmutable:** NO tocar `catalog.outbox` legacy (`RABBITMQ`) ni alterar filas de `schema_migrations` aplicadas.

### Wave 2 — Publicación de Imágenes OCI y Despliegue de Microservicios (flags nuevos OFF)
Desplegar por digest `sha256` exacto en orden de dependencias de dominio (manteniendo flags de transporte nuevos `OFF` en el arranque inicial para aislar regresiones HTTP):
1. **Nivel base (maestros y auditoría):** `taxonomy-svc`, `price-audit-svc`.
2. **Nivel núcleo comercial:** `catalog-svc`, `pricing-svc`, `inventory-svc`.
3. **Nivel agregadores y orquestación:** `combos-svc`, `promotions-svc`, `bulk-svc`.
4. **Borde interno:** `api-gateway` (verificando `/health/ready` = `200` y propagación `X-Correlation-Id`).
5. **Borde externo APIM:** conservar la política CORS verificada. Repetir preflight y las cinco exclusiones `404` al certificar el release.
6. **Frontend:** fusionar PR #102 (`ccfc21ba`) y validar despliegue Vercel con `VITE_DATA_MODE=api` apuntando a APIM (una vez corregido CORS).

### Wave 3 — Activación Progresiva de Flags Service Bus y Certificación L2 (H5-04B)
Activar flags `SEND`/`RECEIVE` de forma incremental con verificación de colas y DLQ = 0 entre cada paso:
1. **Paso 3.1 — H5-04B Flujo #1 (`R16: Pricing → Price Audit`, owner Vera):**
   - Verificar `SEND` en `pricing-svc` y `RECEIVE` en `price-audit-svc` para `g6.price-audit.from.pricing`.
   - Ejecutar smoke L2 sintético: cambio de precio SKU sintético → `price_audit.price_audit_log` persistido → reinicio controlado de `price-audit-svc` → duplicado idempotente → mensaje malformado aislado en DLQ sin bloquear la cola.
2. **Paso 3.2 — H5-04B Flujo #2 (`R18: Taxonomy → Catalog`, owner López/Poma):**
   - Habilitar `SEND` en `taxonomy-svc` y `RECEIVE` en `catalog-svc` para `g6.catalog.from.taxonomy` (y `R09` si aplica en manifest).
   - Ejecutar smoke L2 con los 6 eventos contractuales de R18 + verificación de barrera, correlación, recuperación y DLQ = 0.
   - *(Contingencia solo bajo bloqueo objetivo documentado de R18 y aprobación expresa del owner: activar `R07 Catalog → Pricing` manteniendo R18 visible en matriz.)*
3. **Paso 3.3 — Flujo Bulk (`R02 → R10`, owners Castilla/Taco):**
   - Habilitar `RECEIVE` R02 y `SEND` R10 en `inventory-svc`, y `RECEIVE` R10 en `bulk-svc`.
   - Ejecutar lote sintético Bulk → Inventory → Bulk confirmando estado terminal `COMPLETED`, stock aplicado una sola vez y DLQ = 0.
4. **Paso 3.4 — `N01 Promotions` (owner Cueva, si el manifest lo habilita):**
   - Confirmar grants G7/G5 y ejecutar admisión `202` → `COMPLETED` + restauración + idempotencia.

### Wave 4 — Smoke Post-Cutover, APIM-T / INT L2 y Performance Autorizada
1. Ejecutar `APIM-T01..T08` con tokens reales G7 verificando `200`/`401`/`403`/`404`/`429`, CORS Frontend y `X-Correlation-Id` hasta logs de microservicios.
2. Ejecutar `INT-01..INT-10` L2 (y L3 bilateral con G5/G1 cuando haya ventana).
3. Ejecutar `PERF-01..PERF-08` y `RL-01..RL-06` en staging autorizado (3 repeticiones baseline/candidato con `k6`).

---

## 4. Criterios de Aborto y Procedimiento de Rollback

### 4.1 Criterios de aborto inmediato
Abortar avance de ola si ocurre cualquiera de las siguientes condiciones:
- `/health/ready` de `api-gateway` o cualquier microservicio devuelve `503` sostenido > 60 s.
- Aumento no esperado de errores `5xx` (> 1%) o fugas de rutas internas en APIM (`!= 404`).
- Crecimiento de `deadLetterMessageCount > 0` en pruebas sintéticas válidas o evidencia de efecto comercial duplicado en Inbox/Kardex/Price Audit.
- Fallo de validación JWT contra JWKS de G7 (`500`/`401` con token válido confirmado).

### 4.2 Rollback por plano (independiente y reversible)

| Plano | Acción de rollback | Condición de seguridad |
|---|---|---|
| **1. Flags de mensajería (primer nivel, < 2 min)** | Cambiar flags `*_SERVICE_BUS_SEND_ENABLED=false` y `*_SERVICE_BUS_RECEIVE_ENABLED=false` en la Container App afectada | Detiene consumo/envío sin perder filas en `*.outbox_delivery`; no purgar colas ni DLQ |
| **2. Aplicación (ACA)** | Redirigir 100% del tráfico a la revisión previa inmutable documentada en `azure-aca-readonly-snapshot-2026-11-27.json` (ej. `catalog-svc--0000004`, `inventory-svc--0000002`, `taxonomy-svc--0000005`, `promotions-svc--0000007`, `api-gateway--0000003`) | Revisiones anteriores permanecen disponibles y pinneadas por digest `sha256` |
| **3. APIM / Modalidad B** | Restaurar política XML anterior (`SHA256 AA9B8C...` / `CD17FD...`) o revisión APIM previa; si se requiere restablecer acceso directo de emergencia al Gateway, retirar regla `allow-apim-1` en `api-gateway` bajo aprobación de Castilla | Conservar respaldo XML antes de toda modificación |
| **4. Base de datos (Inventory R10)** | Ejecutar `apps/inventory-svc/migrations-candidate/h5/0002_allow_bulk_r10_delivery.rollback.sql` (`SHA256 22e6a461...`) | **Solo procede si hay 0 filas `g6.bulk.from.inventory`**; si existen entregas Bulk, el script aborta por diseño para evitar corrupción y exige conciliación previa |
| **5. Base de datos (Taxonomy / general)** | Conservar la infraestructura H5 instalada y desactivar por flags el tramo afectado. Para un diferencial aprobado, usar su rollback ensayado. PITR queda reservado a incidentes severos aprobados por Owner BD y Castilla | Preservar ambos ledgers y los objetos existentes |
