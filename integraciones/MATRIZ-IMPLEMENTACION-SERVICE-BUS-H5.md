# Matriz de implementación y seguimiento — Azure Service Bus H5

**Estado:** especificación de seguimiento; no habilita recursos, contratos, grants, despliegues ni cortes.  
**Revisión:** 2026-11-17. **Backend contrastado:** origin/master SHA 8d26885276d933171ff0b1866d6e23f02a959405. **Docs base:** origin/master SHA a1e00c1.
**Autoridad:** ADR H5 y topología H5. Esta matriz concentra estados por flujo; no duplica la arquitectura ni el plan de migración.

Fuentes normativas: [ADR-H5-SERVICE-BUS-BASIC.md](../arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md), [TOPOLOGIA-SERVICE-BUS-BASIC-H5.md](../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md), [PLAN-MIGRACION-MENSAJERIA-H5.md](PLAN-MIGRACION-MENSAJERIA-H5.md), [MATRIZ-EXTERNOS-ASYNCAPI-H5.md](MATRIZ-EXTERNOS-ASYNCAPI-H5.md), [INVENTARIO-40-MENSAJES-H5.md](../contratos/eventos/INVENTARIO-40-MENSAJES-H5.md) y [contrato AsyncAPI H4](../contratos/eventos/asyncapi.yaml), solo como origen semántico. Evidencia parcial del piloto: [cierre Backend #234](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/master/docs/hito-5/CIERRE_PILOTO_234.md) y [ejecución Azure](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/master/docs/hito-5/EJECUCION_AZURE_SERVICE_BUS.md).

## Reglas de uso y clasificación

Actualizar el estado solo con SHA de Backend, rutas de código/migración/prueba, comando, resultado y fecha. Una mención contractual, clase, migración candidata o prueba unitaria no demuestra conexión runtime. PENDIENTE_VERIFICACION significa que debe inspeccionarse la fuente indicada antes de decidir. No inventar handlers, colas, owners ni flags.

Estados: IMPLEMENTAR_AHORA (trabajo interno autónomo), IMPLEMENTAR_PARCIAL (frontera aislada), BLOQUEADO_ESPECIFICO (solo condición indicada), IMPLEMENTADO_PENDIENTE_PRUEBAS, VALIDADO_PILOTO (solo alcance Azure aislado), HABILITADO (operación demostrada en entorno nombrado).

Service Bus Basic carece de topics/subscriptions. Una cola por destinatario es una candidata, no una cola existente. AsyncAPI H4 contiene 40 mensajes que se agrupan en 18 pares internos productor→consumidor; ni los mensajes ni esos pares son automáticamente colas o handlers. Las interacciones externas G5 usan HTTP autenticado según la matriz externa. Gateway/APIM no se modela como consumidor de cola: no hay handler aprobado. g6.promotions.commands es un flujo nuevo, fuera de los 18 pares.

## Registro por relación

Cada fila comparte estas reglas de captura: fuente normativa = ADR H5, topología H5, inventario H4 solo para semántica y SPEC/DEC-F del bounded context; registrar por separado implementación, unitarias, integración local, E2E, Azure real y entorno habilitado. Outbox, Inbox, migraciones, flags, namespace, managed identity y RBAC se verifican en las rutas backend indicadas; no inferir por existencia de código. Aceptación por flujo: entrega durable, persistencia antes de complete, idempotencia/redelivery, DLQ/recovery y prueba por SHA. Desplegar apagado; cortar por destinatario solo tras observar flujo y probar rollback. Owner técnico es el equipo del bounded context según EQUIPO_Y_RESPONSABILIDADES.md; dependencias específicas se listan por fila.

| ID / mensajes AsyncAPI H4 | Productor → consumidor owner | Transporte H4 → H5; cola candidata | Handler/código Backend en SHA base; persistencia/configuración | Estado y pruebas observadas | Faltante, dependencia y aceptación |
|---|---|---|---|---|---|
| F01 taxonomy.category.updated; taxonomy.product-type-schema.changed; taxonomy.characteristic-value.updated | Taxonomy → Catalog | transporte H4 → Service Bus; g6.catalog.from.taxonomy | Catalog: catalog-taxonomy-message.ts y catalog-service-bus.ts; Inbox localizada. Wiring por mensaje, Outbox, migración y flag: PENDIENTE_VERIFICACION. | IMPLEMENTAR_PARCIAL; integración y Azure PENDIENTE_VERIFICACION. | Lopez/Poma: confirmar wiring/schema de los tres eventos y probar replay idempotente antes de aprovisionar cola. |
| F02 catalog.product.deactivated; catalog.sku.deactivated | Catalog → Promotions, Combos, Inventory, Pricing | transporte H4 → Service Bus; g6.promotions.from.catalog, g6.combos.from.catalog, g6.inventory.from.catalog, g6.pricing.from.catalog | Catalog tiene bridge/relay; Pricing contiene catalog-sku-deactivated.ts. Consumers de los cuatro destinos deben verificarse individualmente. Inbox/Outbox Catalog y migration candidate h5 existen en código. | IMPLEMENTAR_PARCIAL; SB por destinatario y flags PENDIENTE_VERIFICACION. | Poma/Cueva/Castilla/Taco/Vera: confirmar cada consumer y entrega independiente, sin fan-out implícito. Aceptar pruebas de duplicado y rollback por destinatario. |
| F03 pricing.price.changed | Pricing → Price Audit, Promotions | transporte H4 → Service Bus; g6.price-audit.from.pricing, g6.promotions.from.pricing | Pricing: service-bus-relay.ts, service-bus-deliveries.ts; Price Audit: messaging/service-bus-consumer.ts. Outbox delivery migration candidate existe en Pricing. | Price Audit: VALIDADO_PILOTO únicamente para alcance #234. Promotions: PENDIENTE_VERIFICACION. Unitarias no equivalen a E2E/producción. | Vera/Cueva: verificar flags y ejecución por destino. Consultar backend docs/hito-5/CIERRE_PILOTO_234.md; no extender su evidencia al resto. |
| F04 inventory.stock.changed | Inventory → Combos, Promotions | transporte H4 → Service Bus; g6.combos.from.inventory, g6.promotions.from.inventory | Adaptador, handlers, Outbox/Inbox H5 y migraciones PENDIENTE_VERIFICACION; runtime actual corresponde a H4. | IMPLEMENTAR_AHORA para implementación interna tras confirmar el contrato de dominio; H5 aún PENDIENTE_VERIFICACION. | Taco/Castilla/Cueva: identificar productor y consumers reales; prueba de entrega independiente, redelivery e idempotencia. |
| F05 inventory.stock.adjusted | Inventory → Bulk | transporte H4 → Service Bus; g6.bulk.from.inventory | Handler/relay, persistencia H5 y flag PENDIENTE_VERIFICACION. | IMPLEMENTAR_AHORA en alcance interno definido; pruebas Service Bus PENDIENTE_VERIFICACION. | Taco/Castilla: comprobar resultado que Bulk requiere y probar recuperación duradera. |
| F06 taxonomy.master.deactivation.check.requested; taxonomy.master.deactivation.rejected; taxonomy.master.deactivated | Taxonomy → Catalog | transporte H4 → Service Bus; g6.catalog.from.taxonomy | Catalog tiene handlers de mensajes Taxonomy e Inbox; cobertura de nombres exactos, Outbox, migración y runtime H5 PENDIENTE_VERIFICACION. | IMPLEMENTAR_PARCIAL. | Lopez/Poma: demostrar secuencia de barrera completa y correlación; replay no duplica efectos. |
| F07 catalog.master.deactivation.checked | Catalog → Taxonomy | transporte H4 → Service Bus; g6.taxonomy.from.catalog | Handler Taxonomy/Service Bus y persistencia PENDIENTE_VERIFICACION. | IMPLEMENTAR_PARCIAL; pruebas PENDIENTE_VERIFICACION. | Poma/Lopez: confirmar contrato, handler y resultado durable correlacionado antes de habilitar. |
| F08 catalog.bulk.upsert.requested | Bulk → Catalog | transporte H4 → Service Bus; g6.catalog.from.bulk | Catalog tiene procesamiento Bulk e Inbox en catalog-bulk.service.ts; wiring SB del productor/consumer PENDIENTE_VERIFICACION. Migración candidate Catalog existente. | IMPLEMENTAR_PARCIAL. | Castilla/Poma: resolver mensajes H4 de hasta 1 MiB, que superan el límite Basic de 256 KB, antes de activar; probar resultado por fila. |
| F09 catalog.bulk.upsert.completed; catalog.bulk.upsert.rejected | Catalog → Bulk | transporte H4 → Service Bus; g6.bulk.from.catalog | Emisión/consumo, Outbox/Inbox y configuración PENDIENTE_VERIFICACION. | IMPLEMENTAR_PARCIAL; pruebas no confirmadas. | Poma/Castilla: persistir estado terminal, correlacionar operación y verificar replay sin duplicados. |
| F10 pricing.bulk.price.apply.requested | Bulk → Pricing | transporte H4 → Service Bus; g6.pricing.from.bulk | Inventario H5 reporta handler bloqueado en revisión previa; revalidar en SHA actual antes de fijar estado. | BLOQUEADO_ESPECIFICO para la operación si persiste el bloqueo; sin activación parcial del comando. | Castilla/Vera: desbloqueo al verificar contrato, handler, persistencia y pruebas completas. No bloquea otros flujos Pricing. |
| F11 pricing.bulk.price.apply.completed; pricing.bulk.price.apply.rejected | Pricing → Bulk | transporte H4 → Service Bus; g6.bulk.from.pricing | Handler/Outbox/Inbox H5 PENDIENTE_VERIFICACION. | IMPLEMENTAR_PARCIAL. | Vera/Castilla: completar resultados correlacionados y probar reintentos idempotentes. |
| F12 inventory.bulk.stock.adjust.requested | Bulk → Inventory | transporte H4 → Service Bus; g6.inventory.from.bulk | Fuente H5 reporta handler Inventory BLOCKED_CONTRACT; confirmar en SHA actual. Migración, flag e identidad PENDIENTE_VERIFICACION. | BLOQUEADO_ESPECIFICO solo para este comando. | Castilla/Taco: requiere contrato aprobado, handler durable Inbox y pruebas recovery. Los demás flujos Inventory continúan independientes. |
| F13 inventory.bulk.stock.adjust.completed; inventory.bulk.stock.adjust.rejected | Inventory → Bulk | transporte H4 → Service Bus; g6.bulk.from.inventory | Emisor/consumer, Outbox/Inbox y configuración PENDIENTE_VERIFICACION. | IMPLEMENTAR_PARCIAL; depende de definición verificable del comando, no habilita F12. | Taco/Castilla: probar resultados terminales recuperables y sin estado duplicado. |
| F14 pricing.product.initialization.requested | Catalog → Pricing | transporte H4 → Service Bus; g6.pricing.from.catalog | pricing-initialization.ts implementa handler Pricing; entrega Catalog y conexión SB efectiva PENDIENTE_VERIFICACION. Inbox está en Pricing; migration candidate existe. | IMPLEMENTAR_PARCIAL; pruebas por operación PENDIENTE_VERIFICACION. | Poma/Vera: comprobar productor, flag, managed identity y replay idempotente de inicialización. |
| F15 pricing.product.initialization.completed; pricing.product.initialization.rejected | Pricing → Catalog | transporte H4 → Service Bus; g6.catalog.from.pricing | Handler Catalog y envío Pricing H5 PENDIENTE_VERIFICACION; revisar catalog-service-bus.ts y relay. | IMPLEMENTAR_PARCIAL. | Vera/Poma: resultado durable, correlation/operation ID y prueba de recuperación. |
| F16 inventory.sku.initialization.requested | Catalog → Inventory | transporte H4 → Service Bus; g6.inventory.from.catalog | Handler y wiring de ambos servicios H5 PENDIENTE_VERIFICACION; no se localizó adaptador Inventory SB en SHA base. | IMPLEMENTAR_AHORA una vez confirmado contrato/spec interno; implementación no demostrada. | Poma/Taco: definir prueba del efecto único y recuperación antes de crear cola. |
| F17 inventory.sku.initialization.completed; inventory.sku.initialization.rejected | Inventory → Catalog | transporte H4 → Service Bus; g6.catalog.from.inventory | Consumer Catalog, productor Inventory, Inbox/Outbox/config H5 PENDIENTE_VERIFICACION. | IMPLEMENTAR_PARCIAL. | Taco/Poma: confirmar payload/handler contractual y prueba de resultado durable. |
| F18 inventory.reservation.*; inventory.consumption.*; promotions.coupon.* asignados a modulo-ventas | Inventory/Promotions ↔ G5 Ventas | Transporte heredado H4 → HTTP autenticado por APIM/Gateway; no crear g6.ventas.* | Mantener runtime H4 para compatibilidad/regresión. Contrato HTTP, autorizaciones G7 y runtime compartido no se infieren. | BLOQUEADO_ESPECIFICO para corte/fachada externa hasta homologación; el desarrollo interno G6 autónomo no se bloquea. | Owner G5 + owners G6 + G7: liberar con contrato bilateral, grant verificado y E2E autenticado; corte y rollback autorizados. Detalle mensaje a mensaje en MATRIZ-EXTERNOS-ASYNCAPI-H5.md. |

## Flujo H5 nuevo Promotions

| ID / operación | Productor → consumidor | H4/H5, cola y fuentes | Código, persistencia, identidad y pruebas | Estado/dependencias/criterios |
|---|---|---|---|---|
| N01 admisión HTTP de consumo/restauración de cupón, worker y resultado consultable | Adapter HTTP Promotions → worker del mismo servicio | No corresponde a evento AsyncAPI H4. HTTPS autenticado → Service Bus interno; g6.promotions.commands candidata. ADR, topología y PROPUESTA-OPERACIONES-CUPONES-H5.md. | Handler, migraciones, Outbox/Inbox y wiring H5 al SHA base PENDIENTE_VERIFICACION. Se requiere flag cerrado, managed identity/RBAC, autorización G7 y pruebas durable/replay/DLQ. | IMPLEMENTAR_PARCIAL: preparar reglas internas aislables; BLOQUEADO_ESPECIFICO para exponer API hasta contrato aprobado, grants y recursos verificados. Aceptar 202 tras commit durable, GET autorizado, idempotencia/redelivery y E2E. |

## Estado por contexto (no inferir de otros servicios)

| Bounded context | Código observado en Backend SHA base | Lectura |
|---|---|---|
| Taxonomy | No se identificó adaptador SB en búsqueda del SHA; runtime heredado identificado como H4. | H5 PENDIENTE_VERIFICACION. |
| Catalog | catalog-service-bus.ts, relay, handlers Taxonomy/Bulk, Inbox y migration/E2E candidates. | Implementación parcial; validar wiring y pruebas por fila. |
| Pricing | relay, deliveries, Inbox consumers e initialization handlers; migration candidate. | Implementación presente; único piloto Azure reportado junto con Price Audit en alcance #234. |
| Price Audit | consumer/config/pruebas Service Bus. | Código presente; Azure solo VALIDADO_PILOTO según alcance #234. |
| Promotions | Runtime localizado pertenece a H4; g6.promotions.commands es diseño, no implementación acreditada. | H5 PENDIENTE_VERIFICACION. |
| Combos | No se identificó adaptador SB en búsqueda del SHA base. | H5 PENDIENTE_VERIFICACION. |
| Inventory | Runtime heredado H4; no se identificó adaptador SB H5 en SHA base. | H5 PENDIENTE_VERIFICACION. |
| Bulk | Runtime heredado H4; no se identificó adaptador SB H5 en SHA base. | H5 PENDIENTE_VERIFICACION. |
| Gateway/APIM | Entrada HTTP transversal; ningún handler de cola aprobado identificado. | No consumidor Service Bus. |

## Fases y gates

El detalle arquitectónico permanece en PLAN-MIGRACION-MENSAJERIA-H5.md. Orden de ejecución:

1. Inventariar handlers conectados, contrato, schema, datos, flags, owner y tamaño por fila; actualizar SHAs. No inferir colas.
2. Implementar primitives y persistencia por owner: transacción negocio+Outbox, Inbox, idempotencia, correlación, retry/DLQ y recovery. Gate: unitarias e integración local con redelivery.
3. Reproducir Pricing→Price Audit del piloto #234 en SHA actual. Gate: evidencia Azure fechada y acotada al flujo, nunca generalizada.
4. Cerrar Catalog por destinatario; resolver tamaño >256 KB antes de Bulk. Gate: E2E de cada entrega sin consumidores perdidos.
5. Migrar pares internos restantes por dependencia causal; mantener H4 activo hasta prueba/corte autorizado. Gate: observabilidad, prueba de apagado y rollback por flujo.
6. Implementar Promotions HTTP nuevo tras contrato y autorización; Gate: G7 grants, contrato homologado aplicable, persistencia durable y E2E autenticado.
7. Corte por flujo y retiro global solo cuando no haya productores/consumidores H4 activos y todos los reemplazos estén demostrados.

No ejecutar fases de implementación, Azure compartido, SQL remoto, activación o corte mediante esta matriz.

## Datos pendientes para ejecución sin especulación

- SHA y resultados actuales unitarios/integración/E2E/Azure de cada fila; confirmar wiring de todos los handlers.
- Colas aprobadas/provisionadas por ambiente, IaC, namespace, RBAC e identidad administrada verificados.
- Migraciones nuevas aprobadas y aplicadas por entorno, ownership/retención Inbox-Outbox y política de replay.
- Flags con owner, métricas/alertas, despliegue oscuro, secuencia de corte y rollback.
- Solución aprobada para payloads H4 mayores que el límite Basic.
- Contratos/handlers faltantes de Bulk e inicialización Inventory y Taxonomy.
- Homologación G5, OpenAPI HTTP publicado y scopes/grants G7 de operaciones externas.
- Inventario de consumidores H4 activos por ambiente y evidencia de ausencia de publicación duplicada.

## Contraste y discrepancias

Docs origin/master SHA a1e00c1 adopta Service Bus Basic y clasifica RabbitMQ como legado H4. Backend origin/master SHA 8d26885276d933171ff0b1866d6e23f02a959405 contiene implementación parcial en Pricing, Price Audit y Catalog, además del piloto #234; no demuestra migración global, aprovisionamiento compartido ni producción. El checkout Docs preexistente estaba en rama docs/rabbitmq-adopcion-retry-dlx con numerosos cambios locales, incluidos AsyncAPI y operación RabbitMQ; dichos cambios no se usaron como norma ni se modificaron. Discrepancias nuevas se resuelven contra ADR adoptada, master y evidencia por SHA del owner.

No se cambian AsyncAPI/OpenAPI ni fixtures H4. La matriz no afirma homologación, grant, despliegue o retiro de RabbitMQ.
