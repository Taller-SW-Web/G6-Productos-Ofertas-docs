# Entrega a Axel — Despliegue G6 H5 en Azure (Chile Central)

> **Estado de certificación local:** `CODE_AND_LAB_FUNCTIONAL_READY=true`, `LOCAL_G6_GO=false` (transporte real Azure Service Bus y grants externos G7 pendientes), `AZURE_G6_GO=false` (despliegue y RBAC a cargo de Axel).
> **Evidencia integral:** [`hitos/h5/evidencias/r2-certificacion-final/RESUMEN_CERTIFICACION_FINAL_R2.md`](../r2-certificacion-final/RESUMEN_CERTIFICACION_FINAL_R2.md)

## 1. HEAD certificados y condición obligatoria de `master` (Pre-requisito CD)

- **Rama de trabajo:** `trabajo/castilla/h5-integral-r2`
  - **Backend:** `d1ecf2eac77723cec5d6de8a9a999edb7306b400`
  - **Frontend:** `2f0453c1794f54a403085610d5579c4d82fecf5e`
  - **Docs:** `trabajo/castilla/h5-integral-r2` (`94ca6b063624915c9276612f62005194f48f21d0` + este cierre)

> [!IMPORTANT]
> **Requisito estricto del CD oficial (`.github/workflows/cd-services-azure.yml` + `ops/azure/container-apps/validate-source.sh`):**
> **No está autorizado desplegar directamente el SHA de la rama.** El workflow exige `sha` de 40 caracteres que coincida exactamente con el **`HEAD` vigente de `master`** y cuente con **CI exitosa**.
>
> **Advertencia de divergencia en Backend:** `trabajo/castilla/h5-integral-r2` diverge respecto a `origin/master` (`6` commits en `origin/master`, `29` commits en la rama). Antes de fusionar o integrar a `master`, se debe **conservar los cambios recientes de `origin/master`**, en particular:
> - **Catalog (`a30fdfef` / PR #298 `marketplace-auth-hotfix`):** `fix(catalog): aceptar esquema Bearer sin distincion de mayusculas`.
> - **Azure CD (`5ee5053e` / PR #299 `fix-aca-verify-running-state`):** `fix(cd): aceptar RunningAtMaxScale e ignorar runningStatus dinamico en deploy.sh`.

## 2. Separación de Resource Groups y destinos Azure (`deployment-targets.json`)

- **Resource Group Container Apps Chile (`chile-shared`):** `rg-g6-aca-chile`
  - ACA Environment: `env-g6-phase1-chile` | Región: `Chile Central` | GitHub Environment: `azure-h5-chile` (requiere `AZURE_CHILE_DEPLOY_ENABLED=true` y despliegue individual por servicio).
- **Resource Group Namespace Service Bus Basic y laboratorio aislado Brasil (`brazil-isolated`):** `rg-g6-sb-h5-int-fork`
  - Namespace Service Bus Basic: `g6-sb-h5-int-32cdqgbnlk7ow` (`g6-sb-h5-int-32cdqgbnlk7ow.servicebus.windows.net`, claves locales deshabilitadas).
  - ACA Environment aislado Brasil (cuando aplica): `env-g6-h5-int` | Región: `Brazil South` | GitHub Environment: `azure-h5`.
- **Suscripción autorizada:** `fef42188-accd-4470-ae88-78f583eb4906`.

## 3. Migraciones SQL necesarias (PostgreSQL 17 / Supabase)

Aplicar por esquema sin alterar migraciones históricas ya aplicadas:

- **taxonomy-svc:** `apps/taxonomy-svc/migrations/0002_deactivation_source_version.sql` .. `0005_configurable_list_values.sql`; `apps/taxonomy-svc/migrations-candidate/h5/0001_outbox_delivery.sql` (previo `preflight-readonly.sql`).
- **catalog-svc:** `apps/catalog-svc/migrations/0002_create_sku_barcodes.sql` .. `0005_catalog_function_search_path.sql`; `apps/catalog-svc/migrations-candidate/h5/0001_outbox_delivery.sql`, `0002_taxonomy_reply_transport.sql`, `0003_bulk_retry_receipts.sql`.
- **pricing-svc:** `apps/pricing-svc/migrations/0002_schedule_effective_events.sql`, `0003_initialization_operation_index.sql`, `0003_service_bus_h5_routes_r2.sql`, `0004_price_import_idempotency.sql`; `apps/pricing-svc/migrations-candidate/h5/0001_outbox_delivery.sql`.
- **price-audit-svc:** `apps/price-audit-svc/migrations/0002_typed_price_change.sql`.
- **promotions-svc:** `apps/promotions-svc/migrations-candidate/h5/0001_coupon_http_operations.sql`, `0002_coupon_http_runtime_role.sql`.
- **combos-svc:** `apps/combos-svc/migrations/0002_create_combo_creation_receipts.sql`.
- **inventory-svc:** `apps/inventory-svc/migrations/20261104_0001_lifecycle_offline_reconciliation.sql`; `apps/inventory-svc/migrations-candidate/h5/0001_outbox_delivery.sql`.
- **bulk-svc:** `apps/bulk-svc/migrations/0002_export_source_snapshot.sql` .. `0009_h5_outbox_delivery_all_destinations.sql`.

## 4. Variables de Azure Service Bus y flags H5 reales (8 microservicios)

Todos los parsers de los 8 microservicios leen **`SERVICE_BUS_NAMESPACE_FQDN`** (no usar `AZURE_SERVICE_BUS_FULLY_QUALIFIED_NAMESPACE`):

- **Comunes a los 8 microservicios:**
  - `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`
  - `SERVICE_BUS_NAMESPACE_FQDN=g6-sb-h5-int-32cdqgbnlk7ow.servicebus.windows.net`
  - `AZURE_CLIENT_ID=<client_id de la User-Assigned Managed Identity propia del servicio>`
  - `G6_SECURITY_MODE=G7_AUTHENTICATED` (en producción; `PUBLIC_READ_ONLY` eliminado y `SIMULATED_AUTH` prohibido fuera de `NODE_ENV=test`).
- **Específicas por servicio observadas en parsers:**
  - **pricing-svc** (`apps/pricing-svc/src/messaging/service-bus-config.ts` y `service-bus.spec.ts`):
    - `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`
    - `SERVICE_BUS_NAMESPACE_FQDN`
    - `G6_SERVICE_BUS_PRODUCTION_ENABLED=true` (en producción) / `G6_SERVICE_BUS_PILOT_ENABLED=true`
    - `PRICING_PRICE_CHANGED_PUBLISH_ENABLED=true`
    - `PRICING_AMQP_URL` debe estar **ausente**.
  - **catalog-svc** (`apps/catalog-svc/migrations-candidate/h5/README.md`):
    - `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`, `CATALOG_H5_DESTINATIONS` (lista explícita de destinos salientes autorizados).
  - **taxonomy-svc** (`apps/taxonomy-svc/migrations-candidate/h5/README.md`):
    - `TAXONOMY_SERVICE_BUS_ENABLED=true`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`; `RABBITMQ_URL` y `TAXONOMY_CATALOG_AMQP_USER` deben estar **ausentes**.
  - **promotions-svc** (`apps/promotions-svc/src/coupons/service-bus-config.ts`):
    - `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`.
- **Gateway (`api-gateway`):**
  - `G7_JWKS_URL`, `G7_JWT_ISSUER`, `G7_JWT_AUDIENCE=api-productos`, `G7_INTROSPECTION_URL`; perfil opcional `gateway_route_profile=g5-labelled` en `chile-shared` (elimina `GATEWAY_G5_H5_ENABLED` en la revisión etiquetada según `deploy.sh`). `api-gateway` no consume colas.

## 5. Identidades separadas, topología de 19 colas y RBAC mínimo

- **Identidades:** Cada uno de los 8 microservicios debe usar su propia User-Assigned Managed Identity (p. ej. `g6-h5-int-promotions`). **Prohibido** asignar permisos de negocio a la identidad compartida de pull (`g6-h5-qa-acr-pull`).
- **RBAC mínimo en `rg-g6-sb-h5-int-fork` / `g6-sb-h5-int-32cdqgbnlk7ow`:** Asignar `Azure Service Bus Data Sender` al productor y `Azure Service Bus Data Receiver` al consumidor en el scope exacto de cada cola (`/queues/<cola>`), nunca `Data Owner` global:

| Flujo | Cola | Sender (productor) | Receiver (consumidor) |
|---|---|---|---|
| R01 | `g6.catalog.from.bulk` | `bulk-svc` | `catalog-svc` |
| R02 | `g6.inventory.from.bulk` | `bulk-svc` | `inventory-svc` |
| R03 | `g6.pricing.from.bulk` | `bulk-svc` | `pricing-svc` |
| R04 | `g6.bulk.from.catalog` | `catalog-svc` | `bulk-svc` |
| R05 | `g6.combos.from.catalog` | `catalog-svc` | `combos-svc` |
| R06 | `g6.inventory.from.catalog` | `catalog-svc` | `inventory-svc` |
| R07 | `g6.pricing.from.catalog` | `catalog-svc` | `pricing-svc` |
| R08 | `g6.promotions.from.catalog` | `catalog-svc` | `promotions-svc` |
| R09 | `g6.taxonomy.from.catalog` | `catalog-svc` | `taxonomy-svc` |
| R10 | `g6.bulk.from.inventory` | `inventory-svc` | `bulk-svc` |
| R11 | `g6.catalog.from.inventory` | `inventory-svc` | `catalog-svc` |
| R12 | `g6.combos.from.inventory` | `inventory-svc` | `combos-svc` |
| R13 | `g6.promotions.from.inventory` | `inventory-svc` | `promotions-svc` |
| R14 | `g6.bulk.from.pricing` | `pricing-svc` | `bulk-svc` |
| R15 | `g6.catalog.from.pricing` | `pricing-svc` | `catalog-svc` |
| R16 | `g6.price-audit.from.pricing` | `pricing-svc` | `price-audit-svc` |
| R17 | `g6.promotions.from.pricing` | `pricing-svc` | `promotions-svc` |
| R18 | `g6.catalog.from.taxonomy` | `taxonomy-svc` | `catalog-svc` |
| N01 | `g6.promotions.commands` | `promotions-svc` | `promotions-svc` |

```powershell
# SOLO AXEL — Asignación RBAC mínima por cola en rg-g6-sb-h5-int-fork
$labRg = 'rg-g6-sb-h5-int-fork'
$labNs = 'g6-sb-h5-int-32cdqgbnlk7ow'
$nsId = az servicebus namespace show -g $labRg -n $labNs --query id -o tsv
$principalObjectId = '<OBJECT_ID_MI_SERVICIO>'
$queueName = '<COLA_EXACTA>'
$role = '<Azure Service Bus Data Sender | Azure Service Bus Data Receiver>'
$qId = az servicebus queue show -g $labRg --namespace-name $labNs -n $queueName --query id -o tsv
if (-not $qId.StartsWith($nsId + '/queues/')) { throw 'Cola invalida' }
az role assignment create --assignee-object-id $principalObjectId --assignee-principal-type ServicePrincipal --role $role --scope $qId
```

## 6. Procedimiento oficial de imágenes GHCR y CD Backend (`cd-services-azure.yml` + `Dockerfile.service` + `deploy.sh`)

1. **Integración previa:** Fusionar en `master` (conservando `a30fdfef` de Catalog y `5ee5053e` de `deploy.sh`) y esperar **CI exitosa** sobre ese `HEAD` de `master`.
2. **Construcción e imagen oficial en GHCR:** `.github/workflows/cd-services-azure.yml` construye con `Dockerfile.service` (`ARG SERVICE_NAME=<servicio>`) y publica en **`ghcr.io/taller-sw-web/g6-productos-ofertas-backend/<servicio>@sha256:<digest>`**.
3. **Despliegue en Chile Central (`rg-g6-aca-chile` / `env-g6-phase1-chile`):**
   - Disparar `workflow_dispatch` en `cd-services-azure.yml` **de forma individual por servicio** (Chile rechaza despliegue masivo `all`), con:
     - `destination=chile-shared`
     - `service=<servicio>` (p. ej. `catalog-svc`, `inventory-svc`, `pricing-svc`, `promotions-svc`, `api-gateway`, etc.)
     - `sha=<HEAD_VIGENTE_DE_MASTER>`
     - `pilot_self_review=false`
     - `gateway_route_profile=standard` (o `g5-labelled` solo para `api-gateway` en `chile-shared`)
   - Internamente el job autentica OIDC (`azure-h5-chile` con `AZURE_CHILE_DEPLOY_ENABLED=true`) y ejecuta:

```bash
# Ejecutado por el job oficial de cd-services-azure.yml en runner self-hosted (azure-h5-smoke-chile)
H5_DEPLOY_DESTINATION=chile-shared \
H5_DEPLOY_ENVIRONMENT=azure-h5-chile \
H5_PILOT_SELF_REVIEW=false \
H5_GATEWAY_ROUTE_PROFILE=standard \
AZURE_CHILE_DEPLOY_ENABLED=true \
bash ops/azure/container-apps/deploy.sh <servicio> "ghcr.io/taller-sw-web/g6-productos-ofertas-backend/<servicio>@sha256:<digest>"
```

- `deploy.sh` exige en `chile-shared` que `api-gateway` y `promotions-svc` mantengan `minReplicas=1` y `maxReplicas=1`, verifica `fqdn`, `allowInsecure=false`, `healthState=Healthy` y `Provisioned`.

## 7. Publicación oficial del Frontend (Vercel + verificación automatizada)

- **Repositorio:** `G6-Productos-Ofertas-frontend` (integrado en `master`).
- **Build oficial en Vercel (`vercel.json` + `scripts/build-vercel.mjs`):**
  - `vercel.json` configura `buildCommand: "node scripts/build-vercel.mjs"` (validado por `.github/workflows/frontend.yml` mediante `node --test scripts/build-vercel.test.mjs` y el job `Compilación - Integración con API` con `VITE_DATA_MODE=api`).
  - Al publicarse el deployment de producción en Vercel desde `master`, Vercel emite `repository_dispatch` (`vercel.deployment.ready`) hacia `.github/workflows/verificacion-despliegue-vercel.yml` (`environment: vercel-produccion`).
  - El workflow ejecuta `scripts/verificar-despliegue-vercel.mjs` (valida `VERCEL_DEPLOYMENT_ID`, `VERCEL_PROJECT_ID`, `VERCEL_TEAM_ID`, SHA y ref `master`), corre `scripts/vercel-smoke.mjs` con Chromium/Playwright sobre la URL inmutable, verifica vigencia con `scripts/verificar-vigencia-vercel.mjs` y reporta el estado final con `scripts/registrar-estado-vercel.mjs`.

## 8. Verificación de despliegue, Gateway, consumidores y Rollback

1. **Readiness y Gateway:**
   - `GET <GATEWAY_FQDN>/health` → `200`.
   - `GET <GATEWAY_FQDN>/health/ready` → `200` (o `503` si algún servicio upstream no responde `/health/ready`).
   - Validar rechazo sin token (`401 TOKEN_INVALIDO`), rechazo sin rol/scope (`403 SCOPE_INSUFICIENTE`), y lectura/importación autenticada con JWT G7 válido.
2. **Consumidores Service Bus:**
   - Verificar logs sin errores `401/403` RBAC en los 8 servicios y ejecutar `tests/h5/azure-service-bus.real.e2e-spec.ts` contra `g6-sb-h5-int-32cdqgbnlk7ow`.
3. **Rollback oficial (`deploy.sh --restore`):**

```bash
bash ops/azure/container-apps/deploy.sh --restore <servicio> \
  "ghcr.io/taller-sw-web/g6-productos-ofertas-backend/<servicio>@sha256:<digest_anterior>" \
  "ghcr.io/taller-sw-web/g6-productos-ofertas-backend/<servicio>@sha256:<digest_aplicado>" \
  "<sha256_configuracion>"
```

## 9. Bloqueos externos que Axel debe gestionar

1. Fusión ordenada a `master` conservando `a30fdfef` (Catalog) y `5ee5053e` (`deploy.sh`) + CI verde.
2. Asignación de User-Assigned Managed Identities por servicio y RBAC mínimo (`Data Sender` / `Data Receiver`) en las 19 colas de `rg-g6-sb-h5-int-fork` / `g6-sb-h5-int-32cdqgbnlk7ow`.
3. Confirmación de grants M2M reales en **G7** y homologación externa con G1–G5 en APIM/Gateway.
