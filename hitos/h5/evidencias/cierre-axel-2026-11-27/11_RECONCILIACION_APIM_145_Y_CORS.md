# Reconciliación APIM 145 vs OpenAPI 156 vs Matriz 158, RBAC Service Bus y Plan CORS — 2026-11-27

**Estado vigente del 28/11.** Rev. 2 activa con 149 operaciones, cuatro incorporaciones G5 y cero eliminaciones. Rev. 1 permanece online para recuperación. Las cinco rutas internas y las dos lecturas de Pricing siguen excluidas. Los cuatro rechazos anónimos están acreditados y los positivos requieren modulo-ventas. [Comparación, respaldo y resultados](artefactos/APIM_G5_145_A_149_2026-11-28.json).

> **Fuente:** corte inicial de solo lectura. Actualización del 27/11/2026 en la [evidencia del cambio](artefactos/APIM_CORS_POST_CAMBIO_2026-11-27.json).

## 1. Reconciliación matemática exacta de universos HTTP (`145` vs `156` vs `158`)

- **OpenAPI `0.7.0-rc.3` (`docs-master` `5f30802129ba4bbc0674dcc5878f10065f443118`):** **156** operaciones contractuales.
- **APIM live (`apim-g6-productos-chile`, API `g6-productos-ofertas`, path `/api/v1`):** **145** operaciones — **paridad del corte anterior** respecto a su manifiesto APIM de 145. El candidato actualizado de #307 añade las cuatro operaciones indicadas más abajo.
- **Matriz certificadora R2 (`hitos/h5/MATRIZ_158_OPERACIONES_H5_R2.csv`):** **158** operaciones = `156 OpenAPI` + `2 probes privados de Gateway` (`gatewayLiveness GET /health/live`, `gatewayReadiness GET /health/ready`).

### 1.1 Exclusiones observadas en la revisión live 1, antes del release G5

| # | `operationId` | Método y Ruta OpenAPI | Clasificación de exclusión | Evidencia verificada |
|---:|---|---|---|---|
| 1 | `obtenerContextoSku` | `GET /productos/skus/{sku}/contexto` | **Ruta interna G6→G6 (privada)** | Sonda live APIM: **`404`**; L1 superficie interna `catalog-svc`: `200`/`401`/`403` PASS |
| 2 | `obtenerContextosSkuLote` | `POST /productos/skus/contexto/lote` | **Ruta interna G6→G6 (privada)** | Sonda live APIM: **`404`**; L1 superficie interna `catalog-svc`: `200`/`401`/`403` PASS |
| 3 | `filtrarSkusVendiblesInterno` | `POST /interno/productos/skus/filtrar` | **Ruta interna G6→G6 (privada)** | Sonda live APIM: **`404`**; L1 superficie interna `catalog-svc`: `200`/`401`/`403` PASS |
| 4 | `obtenerEvidenciaReservaCuponInterno` | `GET /interno/inventario/reservas/{reservaId}/evidencia-cupon` | **Ruta interna G6→G6 (privada)** | Sonda live APIM: **`404`**; L1 superficie interna `inventory-svc`: `200`/`401`/`403` PASS |
| 5 | `obtenerContenidoCargaMasivaInternoH5` | `GET /interno/carga-masiva/contenidos/{contentId}` | **Ruta interna G6→G6 (privada)** | Sonda live APIM: **`404`**; L1 superficie interna `bulk-svc`: `200`/`401`/`403` PASS |
| 6 | `admitirConsumoCuponH5` | `POST /cupones/consumos` | **Ruta G5 H5** | Ausente en la revisión live 1. Autorizada e incluida en el candidato de 149 operaciones. |
| 7 | `admitirRestauracionCuponH5` | `POST /cupones/restauraciones` | **Ruta G5 H5** | Ausente en la revisión live 1. Autorizada e incluida en el candidato de 149 operaciones. |
| 8 | `obtenerOperacionCuponH5` | `GET /cupones/operaciones/{operationId}` | **Ruta G5 H5** | Ausente en la revisión live 1. Autorizada e incluida en el candidato de 149 operaciones. |
| 9 | `obtenerEstadoReservaH5` | `GET /inventario/reservas/{reservaId}/estado` | **Ruta G5 H5** | Ausente en la revisión live 1. Autorizada e incluida en el candidato de 149 operaciones. |
| 10 | `obtenerDefinicionPrecioProductoAdministracion` | `GET /precios/administracion/productos/{productoId}` | **Registrada en Gateway y excluida expresamente por el filtro APIM** | Validada en L1 158-endpoints; pendiente de conciliación si se requiere exponer por APIM |
| 11 | `obtenerDefinicionPrecioSkuAdministracion` | `GET /precios/administracion/skus/{sku}` | **Registrada en Gateway y excluida expresamente por el filtro APIM** | Validada en L1 158-endpoints; pendiente de conciliación si se requiere exponer por APIM |

---

## 2. Estado efectivo de políticas APIM y plan mínimo reversible de CORS (Prioridad operativa)

### 2.1 Snapshot solo lectura de políticas vigentes (`2026-11-27`)
- **Nivel servicio (global):** `<policies><inbound /><backend><forward-request /></backend><outbound /></policies>` (paso neutro).
- **Productos existentes:** `starter` (`subscriptionRequired=true`), `unlimited` (`subscriptionRequired=true`); la API `g6-productos-ofertas` opera con `subscriptionRequired=false` (autenticación JWT G7 en operación).
- **Nivel API (`g6-productos-ofertas`, `/api/v1`):** SHA-256 `aa9b8c125af0c7d29bd514133cefd9fe9f17b71c254a2c8add32d52b3bd99bc3`. Valida/genera `x-correlation-id` UUID (`400 VALIDACION` si malformado o duplicado), elimina `Server`/`X-Powered-By`, y fija `<cors allow-credentials="false" terminate-unmatched-request="true">` con **un solo origen**:
  ```xml
  <allowed-origins>
    <origin>https://apim-g6-productos-chile.azure-api.net</origin>
  </allowed-origins>
  ```
- **Evidencia live de bloqueo CORS al Frontend Vercel:**
  - `OPTIONS https://apim-g6-productos-chile.azure-api.net/api/v1/productos?canal=MARKETPLACE` con `Origin: https://g6-productos-ofertas.vercel.app` devolvió **`access-control-allow-origin: null`** (bloqueado en navegador).
- **Origen HTTPS exacto confirmado del despliegue Vercel (sin wildcard):**
  - **`https://g6-productos-ofertas.vercel.app`** (deployment `vercel-produccion` ID `8101258936`, alias promovido `g6-productos-ofertas.vercel.app`).

### 2.2 Propuesta y procedimiento previos al cambio

Cambio único en parámetro `corsAllowedOrigins` de `ops/azure/apim/main.bicep` (que renderiza `{{cors-origin-elements}}` en `ops/azure/apim/policies/api.xml`):

```diff
       <allowed-origins>
         <origin>https://apim-g6-productos-chile.azure-api.net</origin>
+        <origin>https://g6-productos-ofertas.vercel.app</origin>
       </allowed-origins>
```

- **Regla de seguridad:** sin wildcards `*`, `allow-credentials="false"`, `terminate-unmatched-request="true"`, preservando intactas las validaciones JWT G7, `rate-limit-by-key` (120/60s), `quota-by-key` (5000/3600s), `x-correlation-id` y la exclusión `404` de las 5 rutas internas.
- **Procedimiento al recibir aprobación escrita de Castilla:**
  1. Guardar respaldo firmado del XML vigente (`SHA256 aa9b8c125af0c7d29bd514133cefd9fe9f17b71c254a2c8add32d52b3bd99bc3`).
  2. Ejecutar `az deployment group what-if` verificando que el único delta efectivo es `Microsoft.ApiManagement/service/apis/policies` (`g6-productos-ofertas/policy`). Si `what-if` muestra otros cambios, aislar el recurso policy antes de aplicar.
  3. Aplicar únicamente la política aprobada.
  4. Validar post-cambio: `OPTIONS` desde `https://g6-productos-ofertas.vercel.app` -> `200` + `Access-Control-Allow-Origin: https://g6-productos-ofertas.vercel.app`; `OPTIONS` desde `https://evil.example` -> sin ACAO; 5 rutas internas -> `404`; sin token -> `401`; llamada real de navegador con sesión G7.
  5. **Rollback inmediato:** reaplicar el XML de respaldo `SHA256 aa9b8c12...` vía ARM/Bicep y confirmar `acao=null`.
- **Requisito del plan previo:** autorización expresa de **Marco Castilla** que identifique explícitamente `apim-g6-productos-chile` / API `g6-productos-ofertas` (`/api/v1`) y el origen `https://g6-productos-ofertas.vercel.app` (la auditoría no fue adjuntada al prompt).

---

### 2.3 Cambio CORS y decisiones de publicación

El `what-if` confirmó un único cambio a `properties.value` en la política de API. Se conservó respaldo y se aplicó mediante escritura condicional con ETag. El preflight Vercel pasó y el origen alternativo quedó sin ACAO. Se verificaron JWT ausente 401, correlación, cinco internas 404 y Gateway directo 403. El rollback queda preparado, con ensayo pendiente.

Marco comunicó la aceptación de G5 para incorporar las cuatro operaciones. Su publicación está autorizada. Las dos consultas Pricing siguen excluidas por su alcance administrativo provisional.

## 3. Auditoría read-only de Identidades Administradas, Flags ACA y RBAC Service Bus (`38/38`)

### 3.1 Identidades User-Assigned (`rg-g6-sb-h5-int-fork`) y flags activos en las 9 Container Apps

| Container App | Revisión live (previa a `#307`) | Identidad administrada | Flags clave observados en vivo (solo lectura) |
|---|---|---|---|
| `bulk-svc` | `bulk-svc--0000002` | `g6-h5-int-bulk` (`92f518ea...`) | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`, `BULK_AMQP_ENABLED=false` |
| `catalog-svc` | `catalog-svc--0000004` | `g6-h5-int-catalog` (`1384ecb4...`) | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`, `CATALOG_AMQP_ENABLED=false` |
| `combos-svc` | `combos-svc--0000003` | `g6-h5-int-combos` (`37e6a807...`) | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`, `COMBOS_SERVICE_BUS_EVENTS_ENABLED=true`, `COMBOS_AMQP_ENABLED=false` |
| `inventory-svc` | `inventory-svc--0000002` | `g6-h5-int-inventory` (`a1038065...`) | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `G6_SERVICE_BUS_PILOT_ENABLED=true`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`, `INVENTORY_SERVICE_BUS_PUBLISH_ENABLED=true`, `INVENTORY_SERVICE_BUS_CONSUME_ENABLED=true`, `INVENTORY_CATALOG_SKU_DEACTIVATION_ENABLED=false` |
| `price-audit-svc` | `price-audit-svc--0000001` | `g6-h5-int-price-audit` (`6d85a3a1...`) | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `G6_SERVICE_BUS_PILOT_ENABLED=true`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true` |
| `pricing-svc` | `pricing-svc--0000007` | `g6-h5-int-pricing` (`5ec993fb...`) | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `G6_SERVICE_BUS_PILOT_ENABLED=true`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`, `PRICING_PRICE_CHANGED_PUBLISH_ENABLED=true` |
| `promotions-svc` | `promotions-svc--0000007` | `g6-h5-int-promotions` (`b547f461...`) | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`, `PROMOTIONS_SERVICE_BUS_EVENTS_ENABLED=true`, `PROMOTIONS_COUPON_RUNTIME_ENABLED=false`, `PROMOTIONS_H5_COUPON_COMMANDS_ENABLED=false` |
| `taxonomy-svc` | `taxonomy-svc--0000005` | `g6-h5-int-taxonomy` (`1671e1ce...`) | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `G6_SERVICE_BUS_PRODUCTION_ENABLED=true`, `TAXONOMY_SERVICE_BUS_ENABLED=true`, `TAXONOMY_SERVICE_BUS_SEND_ENABLED=true`, `TAXONOMY_SERVICE_BUS_RECEIVE_ENABLED=true` |
| `api-gateway` | `api-gateway--0000003` | `None` | `G6_SECURITY_MODE=G7_AUTHENTICATED`, `GATEWAY_G5_H5_ENABLED=true`, Modalidad B `allow-apim-1: 57.156.40.55/32` |

### 3.2 Verificación RBAC mínimo en `g6-sb-h5-chile-261127`
- **Total de asignaciones sobre colas:** **38/38** exactas (`19` `Azure Service Bus Data Sender` + `19` `Azure Service Bus Data Receiver`), **0** `Data Owner` en microservicios, **0** asignaciones globales de namespace para workloads.
- Cada una de las 19 colas (`R01`–`R18` + `N01`) tiene exactamente un productor con rol `Data Sender` y un consumidor con rol `Data Receiver` a nivel de cola individual (`/namespaces/g6-sb-h5-chile-261127/queues/<cola>`).

## Actualización del release G5

Backend [`db49a5b7`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/commit/db49a5b7a5e2cfa1e4b8033a65c9d2075ef57d4a) genera 149 operaciones. Se comprobó que no hay cambios semánticos en las 145 anteriores. La consulta paginada de ARM devolvió 145 operaciones, cero G5 y cero rutas privadas en la revisión live 1. Gateway `api-gateway--0000003` está sano con `GATEWAY_G5_H5_ENABLED=true` en la ruta general. Antes de publicar, comprobar el flag en la revisión del nuevo digest y preservar Modalidad B.

| Método | Ruta relativa a /api/v1 | Scope requerido | Autorización | Resultado actual |
|---|---|---|---|---|
| POST | `/cupones/consumos` | `cupones:consumir` | JWT de servicio, audiencia `api-productos`, cliente `modulo-ventas` | Validación estática PASS. Publicación y positivo G5 pendientes. |
| POST | `/cupones/restauraciones` | `cupones:restaurar` | JWT de servicio, audiencia `api-productos`, cliente `modulo-ventas` | Validación estática PASS. Publicación y positivo G5 pendientes. |
| GET | `/cupones/operaciones/{operationId}` | `cupones:operaciones:leer` | JWT de servicio, audiencia `api-productos`, cliente `modulo-ventas` | Validación estática PASS. Publicación y positivo G5 pendientes. |
| GET | `/inventario/reservas/{reservaId}/estado` | `inventario:reservas:estado:leer` | JWT de servicio, audiencia `api-productos`, cliente `modulo-ventas` | Validación estática PASS. Publicación y positivo G5 pendientes. |

[Manifiesto de seguridad candidato](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/db49a5b7a5e2cfa1e4b8033a65c9d2075ef57d4a/ops/azure/apim/openapi/operation-security.json) · [Plan de cutover](08_PLAN_RELEASE_CUTOVER_ROLLBACK.md)
