# H5-04B — Mensajería asíncrona Azure Service Bus Basic

**Estado:** arquitectura interna G6 adoptada; implementación y habilitación global no certificadas. El piloto Pricing→Price Audit PR #235 (merged 17/11/2026, SHA `0a7797b…` en su PR) es evidencia parcial de R16 en laboratorio. No demuestra despliegue global, infraestructura compartida, homologación G5, grants G7 ni vigencia actual de recursos.

## Exigencia docente, ADR y límites Basic

H5-04 exige un mecanismo asíncrono entre microservicios. El criterio G6 es Azure Service Bus Basic solo entre bounded contexts G6. Integraciones G1–G5 son HTTP autenticado por APIM/Gateway; G7 conserva identidad y grants. Basic tiene colas durables, Peek-Lock y DLQ; no topics/subscriptions, sesiones, duplicate detection del broker ni exactly-once. Tamaño máximo de mensaje 256 KB y TTL no configurable, máximo/default 14 días según ADR/topología. Para varios destinatarios, Outbox independiente por destinatario y clave `(event_id,destination)`. Inbox SQL y deduplicación durable protegen el efecto; entrega es `at-least-once`.

## Matriz R01–R18 y N01

Los R IDs corresponden a relaciones del inventario heredado y la matriz vigente; la lista no significa handlers activos ni obliga a aprovisionar colas sin release. Axel es el owner único del transporte Service Bus. Castilla conserva dominio Bulk/Combos; los coowners mantienen la lógica de su bounded context.

| ID | Ruta interna y cola candidata | Owner(s) de verificación; condición concreta |
|---|---|---|
| R01 | Bulk→Catalog `g6.catalog.from.bulk` | Axel transporte; Castilla/Poma dominio. Resuelve contrato, 256 KB, Outbox/Inbox y replay |
| R02 | Bulk→Inventory `g6.inventory.from.bulk` | Axel; Castilla/Taco. Solo habilitar con contrato y handler durable |
| R03 | Bulk→Pricing `g6.pricing.from.bulk` | Axel; Castilla/Vera. Verificar contrato, flags e idempotencia |
| R04 | Catalog→Bulk `g6.bulk.from.catalog` | Axel; Poma/Castilla. Resultado terminal y replay único |
| R05 | Catalog→Combos `g6.combos.from.catalog` | Axel; Poma/Castilla. Handler, deactivación e idempotencia |
| R06 | Catalog→Inventory `g6.inventory.from.catalog` | Axel; Poma/Taco. Dos mensajes y settlement después de persistir |
| R07 | Catalog→Pricing `g6.pricing.from.catalog` | Axel; Poma/Vera. Fallback segundo flujo si R18 bloqueado; baja e inicialización verificadas separadas |
| R08 | Catalog→Promotions `g6.promotions.from.catalog` | Axel; Poma/Axel. Handler de Promotions distinto de runtime H4 y rollback probado |
| R09 | Catalog→Taxonomy `g6.taxonomy.from.catalog` | Axel; Poma/López. Resultado correlacionado y durable |
| R10 | Inventory→Bulk `g6.bulk.from.inventory` | Axel; Taco/Castilla. Ajuste y resultados sin doble efecto |
| R11 | Inventory→Catalog `g6.catalog.from.inventory` | Axel; Taco/Poma. Resultado de inicialización y rechazo |
| R12 | Inventory→Combos `g6.combos.from.inventory` | Axel; Taco/Castilla. Cambio de stock idempotente |
| R13 | Inventory→Promotions `g6.promotions.from.inventory` | Axel; Taco/Axel. Semántica comercial/efecto terminal |
| R14 | Pricing→Bulk `g6.bulk.from.pricing` | Axel; Vera/Castilla. Resultado masivo y causalidad |
| R15 | Pricing→Catalog `g6.catalog.from.pricing` | Axel; Vera/Poma. Resultado de inicialización por destino |
| R16 | Pricing→Price Audit `g6.price-audit.from.pricing` | Axel transporte; Vera dominio. Piloto #234 parcial; revalidar SHA/infra/identidad antes de release |
| R17 | Pricing→Promotions `g6.promotions.from.pricing` | Axel; Vera/Axel. Handler y no doble efecto H4/H5 |
| R18 | Taxonomy→Catalog `g6.catalog.from.taxonomy` | Axel transporte; López/Poma dominio. Preferido como segundo flujo; reconciliar #247/fork y probar eventos, baja, replay y DLQ |
| N01 | Promotions HTTP→worker Promotions; `g6.promotions.commands` candidata | Axel transporte; Axel dominio Promotions. Admitir durable, operación consultable y roles efectivos verificados |

La matriz [MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md](../../integraciones/MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md) es fuente única de seguimiento por flujo. Docs #131 sigue abierto Draft y trabaja esa matriz; Docs #133 está fusionado en el SHA base `4404b7c7d3cd9254ddc6932532ab3a9ba1a52f78`. Este documento no reemplaza el seguimiento por flujo ni declara implementación por la aprobación G6.

## Outbox, Inbox y recuperación

En una sola transacción local, el servicio persiste cambio de negocio, evento y fila Outbox por destino. Relay envía la misma identidad; confirma entrega solo tras acuse positivo; timeout ambiguo deja estado pendiente. Consumidor usa Peek-Lock, inserta/consulta Inbox con unique key, aplica el efecto y persiste resultado antes de `completeMessage`. Redelivery tras caída no repite efecto; reintentos acotados y DLQ con clasificación/revisión. Replay autorizado registra actor, motivo, correlation y resultado. No existe transacción distribuida SQL+broker. Al fan-out, cada destinatario tiene reintentos independientes. Para payload >256 KB, claim-check o fragmentación semántica aprobada; no truncar silenciosamente.

Managed Identity y RBAC mínimo por cola, identidades separadas de emisor/consumidor. No entregar connection strings/SAS a G1–G5. N01 exige además rol de DB de runtime real: corte P0 observó permisos de `po_promotions_dev_runtime`, pero no de `po_promotions_runtime`; la identidad productiva debe verificarse y permisos mínimos aplicarse por propietario BD en migración revisada, no en este PR.

## R16/R18, fallback R07 y colisiones

R16 reusa el piloto como antecedente, no como evidencia de run actual; repetir con revisión/SHA, recursos, RBAC y recovery verificables. R18 requiere que un solo transporte Axel lleve Taxonomy→Catalog. Backend #247 (abierto, SHA `fb0225b…` al corte) y fork Axel (`2266799…`) tienen DDL/runtime incompatibles; no fusionar #247 como segundo relay ni aplicar ambos SQL. Axel mantiene transporte; López dominio/pruebas. #243 sigue abierto Draft (`bbe22cc…`) y contiene material Bulk V3/relay único que no debe perderse; #251 para Catalog ya está merged (`f1e33a3…` cabeza). #250 para frontera HTTP G5/Promotions/CD está merged (`09f2f58…` cabeza); eso no habilita grants ni deployment. Si R18 no puede superar reconciliación, se elige R07 antes de correr y se registra su owner/contrato.

## Gates y evidencias de cierre

No declarar flujo activo sin handler, Outbox/Inbox, migración candidata revisada, flag, identidad y RBAC por destino, prueba positiva/negativa, redelivery, caída, DLQ/replay y SHA del servicio. Evidencia: bundle de configuración/IaC y hash, identidad/RBAC, queue, message/operation/correlation IDs, SQL antes/después, logs redactados, DLQ, commit/imagen digest, run, entorno y rollback. Owner Axel (transporte); coowners según R table. H5-04B no se cierra por docs o piloto aislado. Referencias: [ADR](../../arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md), [topología](../../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md), [AsyncAPI](../../contratos/eventos/asyncapi.yaml), [plan de migración](../../integraciones/PLAN-MIGRACION-MENSAJERIA-H5.md), [matriz externos](../../integraciones/MATRIZ-EXTERNOS-ASYNCAPI-H5.md).
