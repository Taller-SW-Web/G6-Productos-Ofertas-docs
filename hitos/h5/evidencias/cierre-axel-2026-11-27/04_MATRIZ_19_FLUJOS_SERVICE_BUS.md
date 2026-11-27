# Matriz Integral de 19 Recorridos Service Bus Basic (R01–R18 y N01) — 2026-11-27

> **Nivel acreditado en este corte:** `ISOLATED` (PostgreSQL 17 descartable + transporte aislado Service Bus H5 sobre el stack integrado `trabajo/cueva/h5-cierre-integral`). **No sustituye** la corrida L2 Azure real sobre `g6-sb-h5-chile-261127`, que requiere autorización expresa de entorno/despliegue.

## 1. Resumen de verificación L1 e inventario Azure solo lectura

- **Certificador integral `tests/h5/certify-19-messaging-flows.mjs`:** **19/19 PASS, 0 FAIL** (`exit 0`, artefactos `artefactos/MENSAJERIA_19_RECORRIDOS.json` SHA256 `9ece99015560e536cd8a503e8826c8599df0eff3a7b804fb3a855068ee4bfdc8` y `artefactos/MENSAJERIA_19_RECORRIDOS.csv` SHA256 `7247219c122835993e86b7061b14861c48203985d9f6f0a223de4f217ca5c5d9`).
- **Idempotencia por redelivery/duplicado:** 19/19 colas reproducidas con mismo `message_id`, `allSettled=true`, `unchanged=true` en las 12 tablas de negocio auditadas (`catalog.products`, `catalog.variants`, `catalog.activation_checks`, `inventory.stock_balance`, `inventory.kardex`, `inventory.reservations`, `pricing.prices`, `pricing.price_validities`, `combos.component_projection`, `price_audit.price_audit_log`, `promotions.coupon_uses`, `promotions.catalog_projection`).
- **Recuperación tras caída real de proceso (`processRecovery`):** `ACTUAL_LOCAL_PROCESS_KILL_AND_RESTART` sobre `pricing-svc` (PID `33476` detenido y reiniciado como PID `28596`; mensaje `d2e522b7-669b-5f96-9a71-c522e4bf4d95` encolado durante caída, drenado al reinicio, `settled=true`, `businessUnchanged=true`). Limitación explícita preservada: broker HTTP en memoria en L1, no prueba persistencia física ni expiración de lock de Azure Service Bus.
- **Rechazo / DLQ por productor no confiable (`negativeEvidence`):** mensaje `7f24ce93-725b-43d4-a2db-820b6f67f3d3` rechazado (`rejected=true`, `unchanged=true`).
- **Topología Azure real (solo lectura 2026-11-27):** namespace `g6-sb-h5-chile-261127` (`rg-g6-aca-chile`, SKU `Basic`), **19/19 colas `Active`**, `activeMessageCount=0`, `deadLetterMessageCount=0`, `lockDuration=PT1M`, `maxDeliveryCount=10`, límite de mensaje `256 KB` respetado (claim-check privado para Bulk).
- **Coexistencia con legado RabbitMQ:** los relays H5 leen exclusivamente tablas `*.outbox_delivery` (alimentadas bajo `AZURE_SERVICE_BUS`); no se introduce un segundo relay ni se reenvían filas heredadas `delivery_transport='RABBITMQ'`. La interfaz externa hacia G1–G5 conserva exclusivamente contratos HTTP.

## 2. Detalle por recorrido (R01–R18 y N01)

| ID | Cola Service Bus Basic | Productor | Consumidor | Pruebas enfocadas PG17 adicionales (L1) | Certificador 19 flujos (L1) | Topología Azure (read-only) | Corrida Azure L2 vigente |
|---|---|---|---|---|---|---|---|
| **R01** | `g6.catalog.from.bulk` | `bulk-svc` | `catalog-svc` | `run-bulk-postgres17.mjs` (38/38 PASS) | **PASS** | Active (0/0) | `NOT_RUN` (requiere autorización L2) |
| **R02** | `g6.inventory.from.bulk` | `bulk-svc` | `inventory-svc` | `inventory-h5.postgres.e2e-spec.ts` (26/26 PASS, rollback ante fallo técnico) | **PASS** | Active (0/0) | `BLOCKED_DB_MIGRATION` (espera `0002` R10 + autorización L2) |
| **R03** | `g6.pricing.from.bulk` | `bulk-svc` | `pricing-svc` | `r03-pricing-r14-bulk.postgres.e2e-spec.ts` (3/3 PASS) + `r03-r14-r16-r17` (3/3 PASS) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R04** | `g6.bulk.from.catalog` | `catalog-svc` | `bulk-svc` | `run-bulk-postgres17.mjs` (38/38 PASS) + #106/#109 158-cert | **PASS** | Active (0/0) | `NOT_RUN` |
| **R05** | `g6.combos.from.catalog` | `catalog-svc` | `combos-svc` | Suite E2E Combos + `service-bus-19-queues` (3/3 PASS) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R06** | `g6.inventory.from.catalog` | `catalog-svc` | `inventory-svc` | `inventory-h5.postgres.e2e-spec.ts` (26/26 PASS) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R07** | `g6.pricing.from.catalog` | `catalog-svc` | `pricing-svc` | `r03-r14-r16-r17.postgres.e2e-spec.ts` (3/3 PASS) (fallback predefinido si R18 se bloquea) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R08** | `g6.promotions.from.catalog` | `catalog-svc` | `promotions-svc` | Suite E2E Promotions | **PASS** | Active (0/0) | `NOT_RUN` |
| **R09** | `g6.taxonomy.from.catalog` | `catalog-svc` | `taxonomy-svc` | `run-taxonomy-catalog-postgres.mjs` (23/23 PASS) | **PASS** | Active (0/0) | `BLOCKED_DB_MIGRATION` (espera `0006` Taxonomy + autorización L2) |
| **R10** | `g6.bulk.from.inventory` | `inventory-svc` | `bulk-svc` | `inventory-h5.postgres.e2e-spec.ts` (26/26 PASS) + PG17 `0002_allow_bulk_r10_delivery.sql` up×2/rol/rollback PASS + #106/#109 terminal `COMPLETED` | **PASS** | Active (0/0) | `BLOCKED_DB_MIGRATION` (`ck_inventory_delivery_route` en Supabase compartido solo admite 3 destinos) |
| **R11** | `g6.catalog.from.inventory` | `inventory-svc` | `catalog-svc` | `inventory-h5.postgres.e2e-spec.ts` (26/26 PASS) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R12** | `g6.combos.from.inventory` | `inventory-svc` | `combos-svc` | `inventory-h5.postgres.e2e-spec.ts` (26/26 PASS) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R13** | `g6.promotions.from.inventory` | `inventory-svc` | `promotions-svc` | `inventory-h5.postgres.e2e-spec.ts` (26/26 PASS) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R14** | `g6.bulk.from.pricing` | `pricing-svc` | `bulk-svc` | `r03-pricing-r14-bulk.postgres.e2e-spec.ts` (3/3 PASS) + #106/#109 terminal `COMPLETED` | **PASS** | Active (0/0) | `NOT_RUN` |
| **R15** | `g6.catalog.from.pricing` | `pricing-svc` | `catalog-svc` | `r03-r14-r16-r17.postgres.e2e-spec.ts` (3/3 PASS) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R16** *(H5-04B #1)* | `g6.price-audit.from.pricing` | `pricing-svc` | `price-audit-svc` | `pilot.postgres.e2e-spec.ts` (**8/8 PASS**: persistencia, reinicio, duplicado, DLQ) + `r03-r14-r16-r17` (3/3 PASS) | **PASS** | Active (0/0) | `PENDING_AZURE_L2` (piloto #234 es antecedente histórico; falta corrida vigente con SHA/digest candidato) |
| **R17** | `g6.promotions.from.pricing` | `pricing-svc` | `promotions-svc` | `r03-r14-r16-r17.postgres.e2e-spec.ts` (3/3 PASS) | **PASS** | Active (0/0) | `NOT_RUN` |
| **R18** *(H5-04B #2 preferente)* | `g6.catalog.from.taxonomy` | `taxonomy-svc` | `catalog-svc` | `run-taxonomy-catalog-postgres.mjs` (**23/23 PASS**: 6 eventos contractuales, correlación, barreras, DLQ, idempotencia) + `int06-harness` (2/2 PASS) | **PASS** | Active (0/0) | `BLOCKED_DB_MIGRATION` (espera `0006` Taxonomy + deploy candidato + corrida L2 autorizada) |
| **N01** | `g6.promotions.commands` | `promotions-svc` (HTTP) | `promotions-svc` (worker) | `coupon-h5.postgres.e2e-spec.ts` (**12/12 PASS**: admisión durable antes de `202`, GET terminal `COMPLETED`/`REJECTED`, permisos, recuperación, idempotencia) + #148/#149 PASS | **PASS** | Active (0/0) | `PENDING_AZURE_L2` (evidencia histórica previa no sustituye SHA candidato; grants G7/G5 requeridos para L2/L3) |

## 3. Regla de contingencia H5-04B (R16 + R18 vs R07)

- Selección primaria para **H5-04B**: **R16** (`Pricing → Price Audit`) y **R18** (`Taxonomy → Catalog`, 6 eventos contractuales). Ambos pasaron al 100% en PostgreSQL 17 descartable y en el certificador de 19 flujos.
- **R07** (`Catalog → Pricing`) **no** se ha invocado como sustituto: permanece reservado únicamente como contingencia condicionada a bloqueo objetivo de R18 en Azure y decisión previa documentada del owner antes del ensayo. R18 permanece visible en la matriz integral en todo caso.
