# Entrega a Axel — Despliegue G6 H5 en Azure (Chile Central)

> **Estado de certificación local:** `CODE_AND_LAB_FUNCTIONAL_READY=true`, `LOCAL_G6_GO=false` (transporte real Azure Service Bus y grants externos G7 pendientes), `AZURE_G6_GO=false` (despliegue y RBAC a cargo de Axel).
> **Evidencia integral:** [`hitos/h5/evidencias/r2-certificacion-final/RESUMEN_CERTIFICACION_FINAL_R2.md`](../r2-certificacion-final/RESUMEN_CERTIFICACION_FINAL_R2.md)

## 1. HEAD finales certificados (`trabajo/castilla/h5-integral-r2`)

- **Backend:** `d1ecf2eac77723cec5d6de8a9a999edb7306b400`
- **Frontend:** `2f0453c1794f54a403085610d5579c4d82fecf5e`
- **Docs:** rama `trabajo/castilla/h5-integral-r2` (matrices base `0466cfa7e0c644484d4bc28700045d915d0be456` + este cierre)

## 2. Migraciones SQL necesarias (Supabase / PostgreSQL 17)

Aplicar en orden por esquema (sin alterar migraciones históricas ya aplicadas):

- **taxonomy-svc:**
  - `apps/taxonomy-svc/migrations/0002_deactivation_source_version.sql`
  - `apps/taxonomy-svc/migrations/0003_deactivation_timeout_setting.sql`
  - `apps/taxonomy-svc/migrations/0004_product_type_pending_version.sql`
  - `apps/taxonomy-svc/migrations/0005_configurable_list_values.sql`
  - `apps/taxonomy-svc/migrations-candidate/h5/0001_outbox_delivery.sql` (previo `preflight-readonly.sql`)
- **catalog-svc:**
  - `apps/catalog-svc/migrations/0002_create_sku_barcodes.sql`
  - `apps/catalog-svc/migrations/0003_product_publication_history.sql`
  - `apps/catalog-svc/migrations/0004_historical_preparation_requests.sql`
  - `apps/catalog-svc/migrations/0005_catalog_function_search_path.sql`
  - `apps/catalog-svc/migrations-candidate/h5/0001_outbox_delivery.sql`
  - `apps/catalog-svc/migrations-candidate/h5/0002_taxonomy_reply_transport.sql`
  - `apps/catalog-svc/migrations-candidate/h5/0003_bulk_retry_receipts.sql`
- **pricing-svc:**
  - `apps/pricing-svc/migrations/0002_schedule_effective_events.sql`
  - `apps/pricing-svc/migrations/0003_initialization_operation_index.sql`
  - `apps/pricing-svc/migrations/0003_service_bus_h5_routes_r2.sql`
  - `apps/pricing-svc/migrations/0004_price_import_idempotency.sql`
  - `apps/pricing-svc/migrations-candidate/h5/0001_outbox_delivery.sql`
- **price-audit-svc:**
  - `apps/price-audit-svc/migrations/0002_typed_price_change.sql`
- **promotions-svc:**
  - `apps/promotions-svc/migrations-candidate/h5/0001_coupon_http_operations.sql`
  - `apps/promotions-svc/migrations-candidate/h5/0002_coupon_http_runtime_role.sql`
- **combos-svc:**
  - `apps/combos-svc/migrations/0002_create_combo_creation_receipts.sql`
- **inventory-svc:**
  - `apps/inventory-svc/migrations/20261104_0001_lifecycle_offline_reconciliation.sql`
  - `apps/inventory-svc/migrations-candidate/h5/0001_outbox_delivery.sql`
- **bulk-svc:**
  - `apps/bulk-svc/migrations/0002_export_source_snapshot.sql` .. `0009_h5_outbox_delivery_all_destinations.sql`

## 3. Imágenes, variables y feature flags requeridos

- **Imágenes:** construir desde Backend HEAD `d1ecf2eac77723cec5d6de8a9a999edb7306b400` para los 9 contenedores (`api-gateway`, `catalog-svc`, `taxonomy-svc`, `pricing-svc`, `price-audit-svc`, `promotions-svc`, `combos-svc`, `inventory-svc`, `bulk-svc`) y Frontend HEAD `2f0453c1794f54a403085610d5579c4d82fecf5e`.
- **Frontend build obligatorio:** `VITE_DATA_MODE=api` (producción rechaza valor implícito o `mock`).
- **Mensajería H5 (los 8 microservicios):**
  - `MESSAGING_PROVIDER=AZURE_SERVICE_BUS` (no usar RabbitMQ/AMQP en H5).
  - `AZURE_SERVICE_BUS_FULLY_QUALIFIED_NAMESPACE=g6-sb-h5-int-32cdqgbnlk7ow.servicebus.windows.net`
  - `AZURE_CLIENT_ID=<client_id de la User-Assigned Managed Identity propia del servicio>`
- **Seguridad G7 / Gateway:**
  - `PUBLIC_READ_ONLY` **eliminado** (su presencia provoca fallo en bootstrap).
  - `G7_JWKS_URL`, `G7_JWT_ISSUER`, `G7_JWT_AUDIENCE=api-productos`, `G7_INTROSPECTION_URL` (para operaciones sensibles de Pricing).
  - `SIMULATED_AUTH` prohibido fuera de `NODE_ENV=test`.
  - Feature flag de rutas G5 H5 en Gateway/Promotions/Inventory según configuración del ambiente (`G5_H5_ENABLED=true` donde aplique).

## 4. Identidades por microservicio

- **Regla obligatoria:** **NO** otorgar permisos de negocio a la identidad compartida de pull (`g6-h5-qa-acr-pull`). Cada uno de los 8 microservicios debe tener su propia User-Assigned Managed Identity (p. ej. `g6-h5-int-promotions`, etc.).
- `api-gateway` **no** consume ni publica colas Service Bus.

## 5. Topología de las 19 colas y permisos Azure RBAC mínimos

Namespace laboratorio: `rg-g6-sb-h5-int-fork` / `g6-sb-h5-int-32cdqgbnlk7ow` (Chile Central, Basic, claves locales deshabilitadas). Asignar roles únicamente en scope de cola (`/queues/<cola>`), nunca `Data Owner` global:

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

### Asignación RBAC mínima (solo Axel)

```powershell
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

## 6. Procedimiento PowerShell de despliegue en Chile Central (solo Axel)

```powershell
# 1. Validar contexto y region chilecentral
$rg = '<RESOURCE_GROUP_APPS>'
$acr = '<ACR_NAME>'
$tag = 'h5-r2-d1ecf2ea'
az acr login --name $acr

# 2. Construir y publicar imagenes por servicio (desde backend HEAD d1ecf2ea)
$services = @('api-gateway','catalog-svc','taxonomy-svc','pricing-svc','price-audit-svc','promotions-svc','combos-svc','inventory-svc','bulk-svc')
foreach ($svc in $services) {
  az acr build --registry $acr --image "g6/$svc`:$tag" --build-arg SERVICE=$svc .
}

# 3. Actualizar revisiones Container Apps con digest inmutable y variables H5
foreach ($svc in $services) {
  $digest = az acr repository show --name $acr --image "g6/$svc`:$tag" --query digest -o tsv
  az containerapp update -g $rg -n "ca-g6-$svc" --image "$acr.azurecr.io/g6/$svc@$digest"
}
```

## 7. Readiness, Smoke Tests y Verificación de Gateway/Consumidores

1. **Readiness:**
   - `GET <GATEWAY_URL>/health` → `200` (liveness).
   - `GET <GATEWAY_URL>/health/ready` → `200` cuando los 8 microservicios responden `/health/ready` (`503` si algún upstream no está listo).
2. **Smoke HTTP autenticado (con JWT G7 válido):**
   - Sin token → `401 TOKEN_INVALIDO`.
   - JWT sin rol/scope → `403 SCOPE_INSUFICIENTE`.
   - `GET /api/v1/productos?canal=MARKETPLACE` → `200`.
   - `POST /api/v1/precios/importaciones/prevalidar` y `POST /api/v1/precios/importaciones` → `200` / `202` → polling `GET /api/v1/precios/importaciones/{batchId}` hasta `COMPLETED`.
3. **Verificación de consumidores Service Bus:**
   - Confirmar ausencia de errores `401/403` RBAC en logs de los 8 microservicios.
   - Ejecutar `tests/h5/azure-service-bus.real.e2e-spec.ts` / `ops/azure/service-bus/pilot.azure.e2e-spec.ts` con credenciales autorizadas en el ambiente.

## 8. Rollback

```powershell
# Revertir revision activa en Container Apps a la revision estable previa
az containerapp revision list -g $rg -n "ca-g6-$svc" --query "[].{name:name,active:properties.active,traffic:properties.trafficWeight}" -o table
az containerapp ingress traffic set -g $rg -n "ca-g6-$svc" --revision-weight "<REVISION_PREVIA>=100"
```

## 9. Bloqueos externos que Axel debe gestionar

1. Aprovisionamiento de User-Assigned Managed Identities por servicio y asignación RBAC `Data Sender` / `Data Receiver` en las 19 colas de `g6-sb-h5-int-32cdqgbnlk7ow`.
2. Confirmación y emisión de grants M2M reales en **G7** (especialmente `combos:leer`, `catalogo:leer` para `inventory-svc` y `carga-masiva:contenidos:leer` para `catalog-svc`).
3. Homologación externa con G1–G5 en APIM/Gateway una vez desplegadas las revisiones.
