# Modelo físico — `inventory` (inventory-svc)

- **Issue:** #54 — [Hito 2][BD] Implementar persistencia de inventory-svc
- **Responsable:** Miguel Ángel Taco Zavala
- **Schema:** `inventory` (único propietario: `inventory-svc`, según `Arquitectura.md` §7, `Modelo_Conceptual.md` §14–15 y `CONVENCIONES_BD.md` §3 y §18)
- **Última actualización:** 2026-10-03
- **Fuentes normativas:** `Arquitectura.md` §7 (Persistencia), §8 (Migraciones), §13 (Inventario), §15 (Concurrencia); `Modelo_Conceptual.md` §14-15; `Contrato_Api.md` §2.1; `CONVENCIONES_BD.md` §3 y §18; `logical-model.md`; trazable contra `FLOW-015` y `FLOW-016`.
- **Implementación:** `migration.sql`. **Validación:** `validation.sql` + evidencia local.

---

## 1. Principios de diseño

1. **Aislamiento de bounded context y ownership:** todo el contexto vive en el schema `inventory`. **No existen FK hacia Catálogo, Ventas ni otros bounded contexts**. Los identificadores externos (`sku_id` de Catálogo, `order_id` de Ventas, `correlation_id`, `sub_gestor`) se almacenan como `text`/`uuid` escalares sin referencias cruzadas de BD. La referencia a tiendas comerciales de Retail (`external_ref`) en las ubicaciones es una extensión escalar opcional sin FK.
2. **Autoridad sobre Ubicaciones:** `inventory-svc` es la autoridad única sobre las ubicaciones físicas (`inventory.locations`), según `Contrato_Api.md` §2.1 y `CONVENCIONES_BD.md` §3 y §18. Todas las columnas `location_id`, `source_location_id` y `target_location_id` son de tipo `uuid` y mantienen integridad referencial interna (FK) hacia `inventory.locations(id)`.
3. **Modelo autoritativo de saldo:** `stock_balance` es la única fuente de verdad del saldo por `(sku_id, location_id)`. La proyección de dashboard (`dashboard_projection`) es un *read model* de solo lectura que **no** contiene reglas de negocio.
4. **Invariantes en BD:** no-negatividad (`on_hand >= 0`, `reserved >= 0`, `blocked >= 0`), restricción de capacidad (`reserved + blocked <= on_hand`) y la fórmula contractual `available = max(on_hand - reserved - blocked, 0)` (columna generada `available`).
5. **Idempotencia:** la clave de comando (`idempotency_key`) es `UNIQUE`; la clave de reserva (`reservation_id`) es `UNIQUE`. Repetir con distinta intención produce conflicto detectable para `409 IDEMPOTENCY_CONFLICT`.
6. **Concurrencia:** `stock_version` para conflicto optimista (`VERSION_CONFLICT` en ajustes absolutos); la carrera confirmar/liberar/expirar se protege con un trigger de única transición terminal.
7. **Outbox/Inbox:** los eventos se persisten en `outbox` en la misma transacción local y se publican después del commit; los mensajes entrantes se deduplican en `inbox`.
8. **TTL de reservas:** `expires_at` en `reservations` + índice parcial `(status='ACTIVA', expires_at)` para el worker de expiración.
9. **Reserva por líneas y split fulfillment:** la reserva se modela como agregado order-level (`reservations`) y las líneas (`reservation_lines`) conservan `location_id` por línea (SPEC-015 §8.1). No existe restricción que fuerce una única ubicación por reserva.

---

## 2. Enumeraciones

| Tipo | Valores |
|---|---|
| `reservation_status` | `ACTIVA`, `CONSUMIDA`, `LIBERADA`, `EXPIRADA` |
| `operation_type` | `RESERVA`, `CONSUMO`, `LIBERACION`, `EXPIRACION`, `AJUSTE_ABSOLUTO`, `INCIDENCIA_BLOQUEO`, `INCIDENCIA_RESOLUCION`, `REINTEGRO`, `CONCILIACION_OFFLINE`, `RECEPCION_TRASLADO`, `INICIALIZACION_SKU` |
| `operation_status` | `RECIBIDO`, `APLICADO`, `RECHAZADO`, `REQUIRES_REVIEW` |
| `stock_status` | `AGOTADO`, `STOCK_BAJO`, `DISPONIBLE` |
| `outbox_status` | `PENDING`, `PUBLISHED` |
| `inbox_status` | `RECEIVED`, `PROCESSED` |
| `incidencia_estado` | `ABIERTA`, `RESUELTA`, `TRASLADO_PENDIENTE` |
| `tipo_resolucion_incidencia` | `REHABILITADO`, `MERMA`, `FALTANTE_CONFIRMADO`, `TRASLADO_ALMACEN_CENTRAL` |
| `traslado_estado` | `EN_TRANSITO`, `RECIBIDO_PARCIAL`, `COMPLETADO`, `COMPLETADO_CON_DISCREPANCIA` |
| `disposicion_recepcion_traslado` | `REINGRESAR_DISPONIBLE`, `REINGRESAR_BLOQUEADO`, `CONFIRMAR_MERMA` |

---

## 3. Tablas

### 3.1 `locations` — catálogo de ubicaciones de inventario

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_locations` (PK) |
| `code` | `text` | No | — | `uq_locations_code` (UNIQUE) |
| `name` | `text` | No | — | — |
| `type` | `text` | No | — | — |
| `external_ref` | `text` | Sí | — | Extensión escalar opcional hacia Retail (sin FK, sin UNIQUE) |
| `active` | `boolean` | No | `true` | — |
| `created_at` | `timestamptz` | No | `now()` | — |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_locations_updated_at` |

---

### 3.2 `stock_balance` — saldo autoritativo por (sku_id, location_id)

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `sku_id` | `text` | No | — | PK compuesto · Ref externa (Catálogo), sin FK |
| `location_id` | `uuid` | No | — | PK compuesto · `fk_stock_balance_location` → `locations(id)` ON DELETE RESTRICT |
| `on_hand` | `integer` | No | `0` | `ck_stock_balance_no_negativo` (>= 0) |
| `reserved` | `integer` | No | `0` | `ck_stock_balance_no_negativo` (>= 0) |
| `blocked` | `integer` | No | `0` | `ck_stock_balance_no_negativo` (>= 0) |
| `stock_version` | `bigint` | No | `0` | Control de concurrencia optimista |
| `available` | `integer` | No | *generada* | `STORED: GREATEST(0, on_hand - reserved - blocked)` |
| `created_at` | `timestamptz` | No | `now()` | — |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_stock_balance_updated_at` |

- Constraints: `pk_stock_balance (sku_id, location_id)`, `fk_stock_balance_location`, `ck_stock_balance_no_negativo`, `ck_stock_balance_capacidad (reserved + blocked <= on_hand)`.
- Índices: `ix_stock_balance_location_id (location_id)`.

---

### 3.3 `reservations` — agregado order-level de la reserva

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_reservations` (PK) |
| `reservation_id` | `uuid` | No | — | `uq_reservations_identity` (UNIQUE de negocio) |
| `status` | `inventory.reservation_status` | No | `'ACTIVA'` | Estado del ciclo de vida |
| `expires_at` | `timestamptz` | No | — | TTL de expiración |
| `idempotency_key` | `text` | No | — | `uq_reservations_idempotency` (UNIQUE) |
| `intention` | `text` | No | `'reservar'` | Intención del comando |
| `correlation_id` | `uuid` | Sí | — | Trazabilidad asíncrona |
| `order_id` | `uuid` | Sí | — | Referencia externa a Ventas (sin FK) |
| `operation_id` | `uuid` | Sí | — | Operación asociada |
| `consumed_at` | `timestamptz` | Sí | — | Marca de consumo definitivo |
| `released_at` | `timestamptz` | Sí | — | Marca de liberación |
| `expired_at` | `timestamptz` | Sí | — | Marca de expiración |
| `created_at` | `timestamptz` | No | `now()` | — |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_reservations_updated_at` |

- Transición terminal única: trigger `trg_no_double_terminal` impide salir de un estado terminal (`CONSUMIDA`, `LIBERADA`, `EXPIRADA`).
- Índices: `ix_reservations_ttl (status, expires_at) WHERE status = 'ACTIVA'`.

---

### 3.4 `reservation_lines` — líneas de reserva

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_reservation_lines` (PK) |
| `reservation_id` | `uuid` | No | — | `fk_reservation_lines_reservation` → `reservations(id)` ON DELETE CASCADE |
| `sku_id` | `text` | No | — | Ref externa (Catálogo), sin FK |
| `location_id` | `uuid` | No | — | `fk_reservation_lines_location` → `locations(id)` ON DELETE RESTRICT |
| `quantity` | `integer` | No | — | `ck_reservation_lines_qty (quantity > 0)` |

- Constraints: `pk_reservation_lines`, `fk_reservation_lines_reservation`, `fk_reservation_lines_location`, `uq_reservation_lines (reservation_id, sku_id, location_id)`.
- Índices: `ix_reservation_lines_reservation_id`, `ix_reservation_lines_location_id`, `ix_reservation_lines_sku (sku_id, location_id)`.

---

### 3.5 `inventory_operations` — operaciones mutadoras e idempotencia

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_inventory_operations` (PK) |
| `operation_type` | `inventory.operation_type` | No | — | Tipo de acción mutadora |
| `idempotency_key` | `text` | No | — | `uq_inventory_operations_idempotency` (UNIQUE) |
| `intention` | `text` | No | — | Intención original |
| `status` | `inventory.operation_status` | No | `'RECIBIDO'` | Estado del comando |
| `sku_id` | `text` | Sí | — | Ref externa (Catálogo) |
| `location_id` | `uuid` | Sí | — | `fk_inventory_operations_location` → `locations(id)` ON DELETE RESTRICT |
| `quantity_requested` | `integer` | Sí | — | `CHECK (quantity_requested >= 0)` |
| `quantity_applied` | `integer` | Sí | — | `CHECK (quantity_applied >= 0)` |
| `result_code` | `text` | Sí | — | Código funcional de resultado |
| `correlation_id` | `uuid` | Sí | — | Trazabilidad |
| `order_id` | `uuid` | Sí | — | Ref externa a Ventas |
| `reservation_id` | `uuid` | Sí | — | Reserva asociada |
| `stock_version` | `bigint` | Sí | — | Versión usada en ajustes absolutos |
| `accepted_at` | `timestamptz` | Sí | — | Timestamp 202 Accepted |
| `applied_at` | `timestamptz` | Sí | — | Timestamp de aplicación efectiva |
| `created_at` | `timestamptz` | No | `now()` | — |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_inventory_operations_updated_at` |

- Índices: `ix_inventory_operations_location_id`, `ix_operations_sku (sku_id, location_id)`, `ix_operations_type_status (operation_type, status)`.

---

### 3.6 `kardex` — movimientos autoritativos de stock

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_kardex` (PK) |
| `sku_id` | `text` | No | — | Ref externa (Catálogo) |
| `location_id` | `uuid` | No | — | `fk_kardex_location` → `locations(id)` ON DELETE RESTRICT |
| `operation_type` | `inventory.operation_type` | No | — | Tipo de movimiento |
| `operation_id` | `uuid` | Sí | — | Operación que originó el cambio |
| `reservation_id` | `uuid` | Sí | — | Reserva vinculada |
| `quantity` | `integer` | No | — | `ck_kardex_qty (quantity <> 0)` |
| `on_hand_before` | `integer` | No | — | Saldo físico previo |
| `on_hand_after` | `integer` | No | — | Saldo físico resultante |
| `reserved_before` | `integer` | No | — | Saldo reservado previo |
| `reserved_after` | `integer` | No | — | Saldo reservado resultante |
| `blocked_before` | `integer` | No | — | Saldo bloqueado previo |
| `blocked_after` | `integer` | No | — | Saldo bloqueado resultante |
| `stock_version` | `bigint` | No | — | Versión de saldo generada |
| `correlation_id` | `uuid` | Sí | — | Trazabilidad |
| `created_at` | `timestamptz` | No | `now()` | Timestamp inmutable |

- Append-only estricto: exenta de `updated_at` y `deleted_at` según `CONVENCIONES_BD.md` §7.3.
- Índices: `ix_kardex_location_id`, `ix_kardex_saldo (sku_id, location_id, created_at DESC)`, `ix_kardex_operation (operation_id)`.

---

### 3.7 `incidencias` — bloqueos y cuarentenas físicas

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_incidencias` (PK) |
| `incidencia_id` | `uuid` | No | — | `uq_incidencias_identity` (UNIQUE) |
| `sku_id` | `text` | No | — | Ref externa (Catálogo) |
| `location_id` | `uuid` | No | — | `fk_incidencias_location` → `locations(id)` ON DELETE RESTRICT |
| `external_incident_id` | `text` | Sí | — | Referencia operativa de Retail |
| `act_ref` | `text` | Sí | — | Acta de resolución |
| `estado` | `inventory.incidencia_estado` | No | `'ABIERTA'` | Estado del bloqueo |
| `tipo_resolucion` | `inventory.tipo_resolucion_incidencia` | Sí | — | Tipo de disposición final |
| `cantidad_bloqueada` | `integer` | No | — | `ck_incidencias_qty (cantidad_bloqueada > 0)` |
| `idempotency_key` | `text` | No | — | `uq_incidencias_idempotency` (UNIQUE) |
| `correlation_id` | `uuid` | Sí | — | Correlación |
| `created_at` | `timestamptz` | No | `now()` | — |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_incidencias_updated_at` |
| `resolved_at` | `timestamptz` | Sí | — | Momento de resolución |

- Índices: `ix_incidencias_location_id`, `ix_incidencias_estado (estado)`, `ix_incidencias_sku (sku_id, location_id)`.

---

### 3.8 `traslados` — envíos en tránsito entre ubicaciones

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_traslados` (PK) |
| `traslado_id` | `uuid` | No | — | `uq_traslados_identity` (UNIQUE) |
| `source_incident_id` | `uuid` | Sí | — | Incidencia de origen |
| `sku_id` | `text` | No | — | Ref externa (Catálogo) |
| `source_location_id` | `uuid` | No | — | `fk_traslados_source_location` → `locations(id)` ON DELETE RESTRICT |
| `target_location_id` | `uuid` | No | — | `fk_traslados_target_location` → `locations(id)` ON DELETE RESTRICT |
| `quantity_shipped` | `integer` | No | — | `ck_traslados_qty_shipped (quantity_shipped > 0)` |
| `quantity_received` | `integer` | No | `0` | `ck_traslados_qty_received (quantity_received >= 0)` |
| `missing_quantity` | `integer` | Sí | — | `ck_traslados_missing (missing_quantity >= 0)` |
| `estado` | `inventory.traslado_estado` | No | `'EN_TRANSITO'` | Estado del traslado |
| `created_at` | `timestamptz` | No | `now()` | — |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_traslados_updated_at` |

- Trigger `trg_traslado_terminal` protege estados terminales irreversibles.
- Índices: `ix_traslados_source_location_id`, `ix_traslados_target_location_id`, `ix_traslados_estado`, `ix_traslados_source (source_location_id, estado)`, `ix_traslado_por_incidencia UNIQUE (source_incident_id) WHERE source_incident_id IS NOT NULL`.

---

### 3.9 `traslado_recepciones` — recepciones parciales y finales

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_traslado_recepciones` (PK) |
| `recepcion_id` | `uuid` | No | — | `uq_traslado_recepciones_identity` (UNIQUE) |
| `traslado_id` | `uuid` | No | — | `fk_traslado_recepciones_traslado` → `traslados(id)` ON DELETE CASCADE |
| `cantidad_recibida` | `integer` | No | — | `ck_recepciones_qty (cantidad_recibida > 0)` |
| `disposicion` | `inventory.disposicion_recepcion_traslado` | No | — | Disposición del stock recibido |
| `es_recepcion_final` | `boolean` | No | `false` | Cierre del traslado |
| `sub_gestor` | `text` | No | — | Operador que recibe |
| `idempotency_key` | `text` | No | — | `uq_traslado_recepciones_idempotency` (UNIQUE) |
| `received_at` | `timestamptz` | No | `now()` | Timestamp de recepción |

- Índices: `ix_traslado_recepciones_traslado_id (traslado_id)`.

---

### 3.10 `stock_threshold_override` — umbrales de stock

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_stock_threshold_override` (PK) |
| `sku_id` | `text` | Sí | — | Ref SKU o nulo para global |
| `location_id` | `uuid` | Sí | — | `fk_stock_threshold_override_location` → `locations(id)` ON DELETE RESTRICT |
| `umbral_efectivo` | `integer` | No | — | `ck_stock_threshold_override_umbral (umbral_efectivo >= 0)` |
| `created_at` | `timestamptz` | No | `now()` | — |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_threshold_override_updated_at` |

- Constraints: `uq_stock_threshold_override (sku_id, location_id)`, `ck_stock_threshold_override_scope (location_id IS NULL AND ((sku_id IS NULL) OR (sku_id IS NOT NULL)))`.
- Índices: `ix_threshold_global UNIQUE ((1)) WHERE sku_id IS NULL AND location_id IS NULL`.

---

### 3.11 `inventory_config` — configuración operativa

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `key` | `text` | No | — | `pk_inventory_config` (PK) |
| `value` | `jsonb` | No | — | — |
| `description` | `text` | Sí | — | — |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_inventory_config_updated_at` |

---

### 3.12 `dashboard_projection` — read model consolidado

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `sku_id` | `text` | No | — | PK compuesto · Ref externa |
| `location_id` | `uuid` | No | — | PK compuesto · `fk_dashboard_projection_location` → `locations(id)` ON DELETE RESTRICT |
| `on_hand` | `integer` | No | — | `ck_dp_no_negativo` (>= 0) |
| `reserved` | `integer` | No | — | `ck_dp_no_negativo` (>= 0) |
| `blocked` | `integer` | No | — | `ck_dp_no_negativo` (>= 0) |
| `available` | `integer` | No | *generada* | `STORED: GREATEST(0, on_hand - reserved - blocked)` |
| `status` | `inventory.stock_status` | No | — | Estado consolidado |
| `umbral_efectivo` | `integer` | No | — | Umbral aplicado |
| `updated_at` | `timestamptz` | No | `now()` | Trigger `trg_dashboard_projection_updated_at` |

- Índices: `ix_dashboard_projection_location_id (location_id)`, `ix_dashboard_ubicacion_estado (location_id, status)`, `ix_dashboard_estado (status)`.

---

### 3.13 `outbox` — publicación transaccional de eventos

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_outbox` (PK) |
| `event_id` | `uuid` | No | — | `uq_outbox_event` (UNIQUE) |
| `event_type` | `text` | No | — | Nombre del evento |
| `aggregate_type` | `text` | No | — | Tipo de agregado |
| `aggregate_id` | `text` | No | — | Identificador del agregado |
| `correlation_id` | `uuid` | Sí | — | Correlación |
| `payload` | `jsonb` | No | — | Cuerpo del evento |
| `status` | `inventory.outbox_status` | No | `'PENDING'` | Estado de publicación |
| `published_at` | `timestamptz` | Sí | — | Momento de publicación |
| `created_at` | `timestamptz` | No | `now()` | — |

- Índices: `ix_outbox_dispatcher (status, created_at)`.

---

### 3.14 `inbox` — deduplicación de consumo asíncrono

| Columna | Tipo | Nulo | Default | Restricciones |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | `pk_inbox` (PK) |
| `message_id` | `uuid` | No | — | `uq_inbox_message_id` (UNIQUE) |
| `message_type` | `text` | No | — | Tipo de mensaje |
| `source` | `text` | No | — | Origen |
| `payload` | `jsonb` | No | — | Cuerpo del mensaje |
| `status` | `inventory.inbox_status` | No | `'RECEIVED'` | Estado de procesamiento |
| `processed_at` | `timestamptz` | Sí | — | Momento de procesamiento |
| `created_at` | `timestamptz` | No | `now()` | — |

- Append-only/deduplicación: exenta de `updated_at`.
- Índices: `ix_inbox_processing (status, created_at)`.

---

## 4. Diagrama entidad-relación físico

```mermaid
erDiagram
    locations ||--o{ stock_balance : "alberga"
    locations ||--o{ reservation_lines : "compromete"
    locations ||--o{ inventory_operations : "aplica"
    locations ||--o{ kardex : "registra"
    locations ||--o{ incidencias : "bloquea"
    locations ||--o{ traslados : "source_location"
    locations ||--o{ traslados : "target_location"
    locations ||--o{ dashboard_projection : "proyecta"
    stock_balance ||--o{ kardex : "genera"
    reservations ||--o{ reservation_lines : "contiene"
    reservations ||--o{ kardex : "registra"
    inventory_operations ||--o{ kardex : "origina"
    stock_balance ||--o{ dashboard_projection : "proyecta"
    stock_threshold_override }o--|| stock_balance : "umbral"
    inventory_config ||--o{ stock_balance : "configura"
    stock_balance ||--o{ incidencias : "bloquea"
    incidencias |o--|| traslados : "origina"
    traslados ||--o{ traslado_recepciones : "recibe"

    locations {
        uuid id PK
        text code UK
        text name
        text type
        text external_ref
        boolean active
    }
    stock_balance {
        text sku_id PK
        uuid location_id PK_FK
        int on_hand
        int reserved
        int blocked
        bigint stock_version
        int available "generated"
    }
    reservations {
        uuid id PK
        uuid reservation_id UK
        reservation_status status
        timestamptz expires_at
        text idempotency_key UK
    }
    reservation_lines {
        uuid id PK
        uuid reservation_id FK
        text sku_id
        uuid location_id FK
        int quantity
    }
    inventory_operations {
        uuid id PK
        operation_type operation_type
        text idempotency_key UK
        operation_status status
        uuid location_id FK
        text result_code
        timestamptz accepted_at
    }
    kardex {
        uuid id PK
        text sku_id
        uuid location_id FK
        operation_type operation_type
        int quantity
        int on_hand_before
        int on_hand_after
    }
    incidencias {
        uuid id PK
        uuid incidencia_id UK
        text sku_id
        uuid location_id FK
        incidencia_estado estado
        int cantidad_bloqueada
        text idempotency_key UK
    }
    traslados {
        uuid id PK
        uuid traslado_id UK
        uuid source_location_id FK
        uuid target_location_id FK
        traslado_estado estado
        int quantity_shipped
    }
    traslado_recepciones {
        uuid id PK
        uuid recepcion_id UK
        uuid traslado_id FK
        int cantidad_recibida
        text idempotency_key UK
    }
```

---

## 5. Checklist de validación física

- [x] La tabla `inventory.locations` está materializada con PK UUID surrogate y `code` único.
- [x] No existe FK hacia `auth.users` ni hacia otros schemas/bounded contexts.
- [x] Las referencias a ubicaciones dentro del schema `inventory` son de tipo `uuid` con FK interna e índice.
- [x] Toda FK interna (`locations`, `reservations`, `traslados`) posee índice en la columna referenciante.
- [x] `created_at timestamptz NOT NULL DEFAULT now()` existe en todas las tablas.
- [x] `updated_at` existe en todas las tablas mutables y está ausente en las tablas append-only (`kardex`, `inbox`).
- [x] No hay `float`, `real`, `money` ni `serial`/`bigserial`.
- [x] Todas las restricciones e índices tienen nombres con prefijo conforme a `CONVENCIONES_BD.md`.