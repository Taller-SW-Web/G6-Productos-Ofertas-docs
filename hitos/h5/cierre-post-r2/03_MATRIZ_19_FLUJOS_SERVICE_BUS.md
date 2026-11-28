# Matriz de 19 relaciones Service Bus

Fuente normativa: `integraciones/MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md` y AsyncAPI `0.7.0-rc.3` en Docs `5f308021`. Azure CLI confirmó 19 colas activas en `g6-sb-h5-chile-261127`; **cola existente no prueba producer, consumer, role, entrega ni E2E**. La matriz normativa por flujo conserva el seguimiento detallado. Este corte no actualiza sus estados.

| Flujo | Cola | Evidencia en esta sesión |
|---|---|---|
| R01 | g6.catalog.from.bulk | Cola Active; loop/E2E NOT_RUN |
| R02 | g6.inventory.from.bulk | Cola Active; receptor y handler reales en Backend base. E2E Inventory PostgreSQL 17: recepción, stock, Inbox, Outbox, ACK/replay/recovery PASS; entrega desde Bulk no probada en esta corrida. |
| R03 | g6.pricing.from.bulk | Cola Active; implementación R2 documentada; replay actual NOT_RUN |
| R04 | g6.bulk.from.catalog | Cola Active; E2E NOT_RUN |
| R05 | g6.combos.from.catalog | Cola Active; E2E NOT_RUN |
| R06 | g6.inventory.from.catalog | Cola Active; E2E NOT_RUN |
| R07 | g6.pricing.from.catalog | Cola Active; E2E NOT_RUN |
| R08 | g6.promotions.from.catalog | Cola Active; E2E NOT_RUN |
| R09 | g6.taxonomy.from.catalog | Cola Active; PR #300 Draft; E2E NOT_RUN |
| R10 | g6.bulk.from.inventory | Cola Active; producer/relay Inventory y consumidor Bulk existen. Check físico anterior rechaza entrega; migración candidata permite registrarla en PG17. Entrega terminal al consumidor Bulk aún sin E2E conjunto. |
| R11 | g6.catalog.from.inventory | Cola Active; E2E NOT_RUN |
| R12 | g6.combos.from.inventory | Cola Active; E2E NOT_RUN |
| R13 | g6.promotions.from.inventory | Cola Active; E2E NOT_RUN |
| R14 | g6.bulk.from.pricing | Cola Active; implementación R2 documentada; replay actual NOT_RUN |
| R15 | g6.catalog.from.pricing | Cola Active; E2E NOT_RUN |
| R16 | g6.price-audit.from.pricing | Cola Active; piloto histórico no equivale a este entorno; E2E NOT_RUN |
| R17 | g6.promotions.from.pricing | Cola Active; E2E NOT_RUN |
| R18 | g6.catalog.from.taxonomy | Cola Active; PR #300 Draft; E2E NOT_RUN |
| N01 | g6.promotions.commands | Cola Active; E2E NOT_RUN |

RBAC por identidad, flags, Outbox/Inbox, lease, ledger y prueba por recorrido requieren inventario y entorno aislado antes de cambiar `NOT_RUN` a `PASS`. No se consumieron mensajes ajenos ni se alteraron colas.
