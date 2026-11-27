# Matriz Integral de 19 Recorridos Service Bus Basic (R01–R18 y N01) — 2026-11-27

> **Nivel acreditado en este corte:** `L1_ISOLATED` (`HTTP_IN_MEMORY_NOT_AZURE` + PostgreSQL 17 descartable) ejecutado sobre el HEAD limpio final de Backend #307 (`18413ac459b24793f4f09ea07104d5281c0be3c7`). **No sustituye** la corrida L2 Azure real sobre `g6-sb-h5-chile-261127`, que requiere autorización expresa de ventana y despliegue.

## 1. Resumen de verificación L1 (atribuciones separadas) e inventario Azure solo lectura

- **Certificador integral `tests/h5/certify-19-messaging-flows.mjs` (HEAD `18413ac459b24793f4f09ea07104d5281c0be3c7`):** **19/19 PASS, 0 FAIL** (`exit 0`, transporte `HTTP_IN_MEMORY_NOT_AZURE`). Artefactos:
  - `artefactos/MENSAJERIA_19_RECORRIDOS.json` (SHA-256 `13cb3ac2ae7e2900604c2263beb13744b50e8f310547940f1fc6650ad985067d`)
  - `artefactos/MENSAJERIA_19_RECORRIDOS.csv` (SHA-256 `7247219c122835993e86b7061b14861c48203985d9f6f0a223de4f217ca5c5d9`)
  - `artefactos/MENSAJERIA_19_RECORRIDOS.meta.json` (metadata generada con SHAs BE/FE/Docs, comando, exitCode, transporte y hashes).
- **Idempotencia por redelivery/duplicado (19/19 colas):** `allSettled=true`, `unchanged=true` en las 12 tablas de negocio auditadas.
- **Atribución exacta y separada de recuperación por reinicio (corrección de auditoría):**
  1. **Reinicio de proceso consumidor R03 (`pricing-svc` en `g6.pricing.from.bulk`):** evidenciado en `MENSAJERIA_19_RECORRIDOS.json -> processRecovery` (`evidenceType: "R03_PRICING_CONSUMER_PROCESS_RESTART"`, `flow: "R03"`, `service: "pricing-svc"`, `queue: "g6.pricing.from.bulk"`, `queuedWhileStopped=true`, `settled=true`, `businessUnchanged=true`). **NO se atribuye a R16.**
  2. **Recuperación transaccional PG17 de R16 (`pricing-svc -> price-audit-svc`):** evidenciado separadamente en `ops/azure/service-bus/pilot.postgres.e2e-spec.ts` (**8/8 PASS** en `18413ac`: commit atómico, rollback sin permisos, envío ambiguo reintentado sin duplicar auditoría, caída post-commit antes de ACK, DLQ ante cambio de payload, concurrencia de claim, lease vencido y cero lock SQL durante IO).
  3. **Reinicio real de proceso consumidor R16 (`price-audit-svc` en `g6.price-audit.from.pricing`):** evidenciado separadamente en `ops/azure/service-bus/r16-price-audit-restart.postgres.e2e-spec.ts` (**1/1 PASS** en `18413ac`, artefacto `artefactos/R16_PRICE_AUDIT_CONSUMER_RESTART.json` + `.meta.json`): proceso real `price-audit-svc` detenido (`PID 30476`), encolamiento durante caída de entrega identificable M2 (`563af74f...`) + redelivery de M1 (`d0998719...`) (`queuedWhileStopped=2`), arranque de nuevo proceso (`PID 29712`), drenaje + redelivery post-reinicio con **efecto único (`auditRowsPersisted=1` para M1 y M2)** y `deadLetterCount=0`.
- **Rechazo / DLQ por productor no confiable (`negativeEvidence`):** mensaje con `producer='untrusted-producer'` rechazado a DLQ (`rejected=true`, `unchanged=true`).
- **Inventario Azure solo lectura (`g6-sb-h5-chile-261127`, `Basic`, 2026-11-27):** **19/19 colas `Active` (`active=0`, `dlq=0`)**, **8 User-Assigned Managed Identities** y **38/38 asignaciones RBAC mínimo por cola** (19 `Data Sender` + 19 `Data Receiver`, 0 `Data Owner`). *Clasificado estrictamente como inventario de infraestructura, no prueba funcional L2.*

## 2. Detalle por recorrido (R01–R18 y N01)

| ID | Cola Service Bus Basic | Productor | Consumidor | Evidencia L1 (HEAD `18413ac`, PG17 / `HTTP_IN_MEMORY_NOT_AZURE`) | Inventario Azure (read-only) | Corrida Azure L2 vigente |
|---|---|---|---|---|---|---|
| **R01** | `g6.catalog.from.bulk` | `bulk-svc` | `catalog-svc` | **PASS** (19-flows + `run-bulk-postgres17` 38/38 + FE real-stack 8b `COMPLETED`) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R02** | `g6.inventory.from.bulk` | `bulk-svc` | `inventory-svc` | **PASS** (19-flows + `inventory-h5.postgres` 26/26 rollback técnico + FE real-stack 8b) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` (el recorrido R02→R10 requiere el candidato desplegado) |
| **R03** | `g6.pricing.from.bulk` | `bulk-svc` | `pricing-svc` | **PASS** (19-flows incl. **reinicio proceso real `pricing-svc`** + `r03-pricing-r14-bulk` 3/3 + `r03-r14-r16-r17` 3/3) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R04** | `g6.bulk.from.catalog` | `catalog-svc` | `bulk-svc` | **PASS** (19-flows + #106/#109 158-cert + FE real-stack 8b) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R05** | `g6.combos.from.catalog` | `catalog-svc` | `combos-svc` | **PASS** (19-flows + CI `combos_postgres_h5` `#46044277201`) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R06** | `g6.inventory.from.catalog` | `catalog-svc` | `inventory-svc` | **PASS** (19-flows + `inventory-h5.postgres` 26/26 + CI `inventario`) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R07** | `g6.pricing.from.catalog` | `catalog-svc` | `pricing-svc` | **PASS** (19-flows + `r03-r14-r16-r17` 3/3; reservado solo como fallback condicionado de R18) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R08** | `g6.promotions.from.catalog` | `catalog-svc` | `promotions-svc` | **PASS** (19-flows + CI `promotions`) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R09** | `g6.taxonomy.from.catalog` | `catalog-svc` | `taxonomy-svc` | **PASS** (19-flows + `run-taxonomy-catalog-postgres` 23/23 + CI `taxonomy_catalog`) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` (esquema Taxonomy equivalente ya existe en Supabase; falta deploy candidato + ensayo L2) |
| **R10** | `g6.bulk.from.inventory` | `inventory-svc` | `bulk-svc` | **PASS** (19-flows + `0002` PG17 up×2/`inventory_app`/rollback + #106/#109 + FE real-stack 8b) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` (cuatro destinos verificados en Supabase tras 20261127200858) |
| **R11** | `g6.catalog.from.inventory` | `inventory-svc` | `catalog-svc` | **PASS** (19-flows + `inventory-h5.postgres` 26/26) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R12** | `g6.combos.from.inventory` | `inventory-svc` | `combos-svc` | **PASS** (19-flows + CI `combos_postgres_h5`) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R13** | `g6.promotions.from.inventory` | `inventory-svc` | `promotions-svc` | **PASS** (19-flows + `inventory-h5.postgres` 26/26) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R14** | `g6.bulk.from.pricing` | `pricing-svc` | `bulk-svc` | **PASS** (19-flows + `r03-pricing-r14-bulk` 3/3 + #106/#109 + FE real-stack 8b) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R15** | `g6.catalog.from.pricing` | `pricing-svc` | `catalog-svc` | **PASS** (19-flows + `r03-r14-r16-r17` 3/3) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R16** *(H5-04B #1)* | `g6.price-audit.from.pricing` | `pricing-svc` | `price-audit-svc` | **PASS** (19-flows + `pilot.postgres` **8/8 transaccional** + `r16-price-audit-restart` **1/1 reinicio real `price-audit-svc`** + FE real-stack #4) | Active (0/0), RBAC 2/2 | **`PENDING_AZURE_L2`** (requiere acreditar RBAC de revisiones, desplegar el candidato y probar el solapamiento, el efecto único y el rollback en Azure) |
| **R17** | `g6.promotions.from.pricing` | `pricing-svc` | `promotions-svc` | **PASS** (19-flows + `r03-r14-r16-r17` 3/3) | Active (0/0), RBAC 2/2 | `PENDING_AZURE_L2` |
| **R18** *(H5-04B #2)* | `g6.catalog.from.taxonomy` | `taxonomy-svc` | `catalog-svc` | **PASS** (19-flows + `run-taxonomy-catalog-postgres` **23/23 con 6 eventos R18** + `verify-taxonomy-observed-ddl` equivalencia PG17 + `int06-harness` 2/2) | Active (0/0), RBAC 2/2 | **`PENDING_AZURE_L2`** (esquema H5 ya existente y equivalente en Supabase; requiere deploy candidato + ensayo L2 autorizado de los 6 eventos) |
| **N01** | `g6.promotions.commands` | `promotions-svc` (HTTP) | `promotions-svc` (worker) | **PASS** (19-flows + `coupon-h5.postgres` 12/12 + #148/#149 158-cert + FE real-stack #16) | Active (0/0), RBAC 2/2; ACA live flag `PROMOTIONS_H5_COUPON_COMMANDS_ENABLED=false` | **`PENDING_AZURE_L2`** (requiere deploy candidato #296, habilitación de flag y grants G7/G5) |
