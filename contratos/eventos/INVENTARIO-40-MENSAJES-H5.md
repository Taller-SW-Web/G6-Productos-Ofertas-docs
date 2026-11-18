# Inventario contractual completo de 40 mensajes — AsyncAPI G6 H4 y destino H5

**Estado:** matriz de análisis, no runtime probado ni contrato H5 homologado. Origen: `contratos/eventos/asyncapi.yaml` 0.6.0-rc.4. Actualizar si cambia el contrato.

**Clasificación:** `INTERNO` se mantiene en el catálogo G6 y se traslada a colas internas cuando exista handler; `HTTP_G5` exige homologación HTTP externa, con mensajería solo detrás del Gateway. Las referencias a `api-gateway/bff` son internas en este inventario, **no** prueba de suscripción G1 a broker.

Conteo reproducido desde AsyncAPI `0.6.0-rc.4`: 40 canales/mensajes. Trece mensajes involucran `modulo-ventas` (11 G6→G5 y 2 G5→G6). El destino interno se concilia por 18 pares únicos productor/consumidor G6, excluyendo `api-gateway/bff` del modelo de colas; incluyen relaciones cuyo handler o activación requiere verificación, por lo que no equivalen a colas actuales ni a implementación.

| # | Mensaje H4 | Productor H4 | Consumidores H4 | Destino contractual H5 |
|---:|---|---|---|---|
| 1 | `taxonomy.category.updated` | `taxonomy-svc` | `catalog-svc`, `api-gateway/bff` | INTERNO — handler por verificar |
| 2 | `taxonomy.product-type-schema.changed` | `taxonomy-svc` | `catalog-svc` | INTERNO — handler por verificar |
| 3 | `taxonomy.characteristic-value.updated` | `taxonomy-svc` | `catalog-svc` | INTERNO — handler por verificar |
| 4 | `catalog.product.deactivated` | `catalog-svc` | `promotions-svc`, `combos-svc`, `api-gateway/bff` | INTERNO — handler por verificar |
| 5 | `catalog.sku.deactivated` | `catalog-svc` | `inventory-svc`, `pricing-svc`, `promotions-svc`, `combos-svc` | INTERNO — handler por verificar |
| 6 | `pricing.price.changed` | `pricing-svc` | `price-audit-svc`, `promotions-svc`, `api-gateway/bff` | INTERNO — handler por verificar |
| 7 | `inventory.stock.changed` | `inventory-svc` | `combos-svc`, `promotions-svc`, `api-gateway/bff` | INTERNO — handler por verificar |
| 8 | `inventory.stock.adjusted` | `inventory-svc` | `bulk-svc`, `api-gateway/bff` | INTERNO — handler por verificar |
| 9 | `inventory.reservation.created` | `inventory-svc` | `modulo-ventas`, `api-gateway/bff` | HTTP_G5 — pendiente bilateral |
| 10 | `inventory.reservation.rejected` | `inventory-svc` | `modulo-ventas` | HTTP_G5 — pendiente bilateral |
| 11 | `inventory.reservation.consumed` | `inventory-svc` | `modulo-ventas`, `api-gateway/bff` | HTTP_G5 — pendiente bilateral |
| 12 | `inventory.reservation.released` | `inventory-svc` | `modulo-ventas`, `api-gateway/bff` | HTTP_G5 — pendiente bilateral |
| 13 | `inventory.reservation.expired` | `inventory-svc` | `modulo-ventas`, `api-gateway/bff` | HTTP_G5 — pendiente bilateral |
| 14 | `inventory.consumption.completed` | `inventory-svc` | `modulo-ventas` | HTTP_G5 — pendiente bilateral |
| 15 | `inventory.consumption.rejected` | `inventory-svc` | `modulo-ventas` | HTTP_G5 — pendiente bilateral |
| 16 | `taxonomy.master.deactivation.check.requested` | `taxonomy-svc` | `catalog-svc` | INTERNO — handler por verificar |
| 17 | `catalog.master.deactivation.checked` | `catalog-svc` | `taxonomy-svc` | INTERNO — handler por verificar |
| 18 | `taxonomy.master.deactivated` | `taxonomy-svc` | `catalog-svc`, `api-gateway/bff` | INTERNO — handler por verificar |
| 19 | `taxonomy.master.deactivation.rejected` | `taxonomy-svc` | `catalog-svc` | INTERNO — handler por verificar |
| 20 | `catalog.bulk.upsert.requested` | `bulk-svc` | `catalog-svc` | INTERNO — handler por verificar |
| 21 | `catalog.bulk.upsert.completed` | `catalog-svc` | `bulk-svc` | INTERNO — handler por verificar |
| 22 | `catalog.bulk.upsert.rejected` | `catalog-svc` | `bulk-svc` | INTERNO — handler por verificar |
| 23 | `pricing.bulk.price.apply.requested` | `bulk-svc` | `pricing-svc` | INTERNO — handler por verificar |
| 24 | `pricing.bulk.price.apply.completed` | `pricing-svc` | `bulk-svc` | INTERNO — handler por verificar |
| 25 | `pricing.bulk.price.apply.rejected` | `pricing-svc` | `bulk-svc` | INTERNO — handler por verificar |
| 26 | `inventory.bulk.stock.adjust.requested` | `bulk-svc` | `inventory-svc` | INTERNO — handler por verificar |
| 27 | `inventory.bulk.stock.adjust.completed` | `inventory-svc` | `bulk-svc` | INTERNO — handler por verificar |
| 28 | `inventory.bulk.stock.adjust.rejected` | `inventory-svc` | `bulk-svc` | INTERNO — handler por verificar |
| 29 | `promotions.coupon.consumption.completed` | `promotions-svc` | `modulo-ventas` | HTTP_G5 — pendiente bilateral |
| 30 | `promotions.coupon.consumption.rejected` | `promotions-svc` | `modulo-ventas` | HTTP_G5 — pendiente bilateral |
| 31 | `promotions.coupon.consumption.requested` | `modulo-ventas` | `promotions-svc` | HTTP_G5 — pendiente bilateral |
| 32 | `promotions.coupon.restoration.requested` | `modulo-ventas` | `promotions-svc` | HTTP_G5 — pendiente bilateral |
| 33 | `promotions.coupon.restoration.completed` | `promotions-svc` | `modulo-ventas` | HTTP_G5 — pendiente bilateral |
| 34 | `promotions.coupon.restoration.rejected` | `promotions-svc` | `modulo-ventas` | HTTP_G5 — pendiente bilateral |
| 35 | `pricing.product.initialization.requested` | `catalog-svc` | `pricing-svc` | INTERNO — handler por verificar |
| 36 | `pricing.product.initialization.completed` | `pricing-svc` | `catalog-svc` | INTERNO — handler por verificar |
| 37 | `pricing.product.initialization.rejected` | `pricing-svc` | `catalog-svc` | INTERNO — handler por verificar |
| 38 | `inventory.sku.initialization.requested` | `catalog-svc` | `inventory-svc` | INTERNO — handler por verificar |
| 39 | `inventory.sku.initialization.completed` | `inventory-svc` | `catalog-svc` | INTERNO — handler por verificar |
| 40 | `inventory.sku.initialization.rejected` | `inventory-svc` | `catalog-svc` | INTERNO — handler por verificar |

## Brechas a resolver antes de trasladar 13 mensajes externos a HTTP

- Los 11 mensajes G6→G5 tienen diferentes momentos de negocio; no todos se reemplazan automáticamente por «consultar resultado de la misma operación». En particular `inventory.reservation.expired` puede llegar después de terminar la operación inicial, y necesita consulta **del estado actual de reserva** o notificación autorizada equivalente.
- Los 2 comandos G5→Promotions requieren esquema v2 completo y autenticación HTTP, sin que G5 reciba credenciales Service Bus.
- Preservar `message_id`, `correlation_id`, `operation_id`, `order_id` y causalidad. La implementación de entrega HTTP/SQL no certifica business handler.
- No declarar `PROMOTIONS` runtime habilitado ni Retail offline homologado por esta matriz.

## Hallazgos de implementación que requieren pruebas

| Mensaje o familia | Riesgo identificado en código auditado |
|---|---|
| `pricing.bulk.price.apply.requested` | El consumidor de Pricing aún registra flujo de Bulk bloqueado en el corte revisado. |
| `inventory.bulk.stock.adjust.requested` | Handler Inventory devuelve `BLOCKED_CONTRACT`. |
| `catalog.bulk.upsert.requested` | Fragmentos hasta 1 MiB en H4; Basic solo admite 256 KB incluidas propiedades. |
| `pricing.price.changed` | Publicación controlada por flag; revisar modo activo antes de probar. |
| `inventory.sku.deactivated` (evento real: `catalog.sku.deactivated`) | Consumo Inventory condicionado por flag; no habilitar por mera presencia en topología. |
| `promotions.coupon.*` | Runtime con dependencias de identidad/elegibilidad bloqueadas. |

## Regla sobre versiones

La futura candidata AsyncAPI H5 debe derivarse del contrato de negocio H4, reflejar que `modulo-ventas` ya no es un cliente AMQP tras el corte, y mantener los mensajes internos aplicables. **No actualizar el contrato canónico ni las pruebas históricas Oracle hasta aprobar compatibilidad, aceptación de G5 y gates de seguridad.**
