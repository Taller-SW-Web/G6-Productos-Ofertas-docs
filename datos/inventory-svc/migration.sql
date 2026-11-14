-- ============================================================================
-- inventory-svc - Persistencia (schema `inventory`)
-- Hito 2 [BD] Issue #54
-- Responsable: Miguel Ángel Taco Zavala
-- Fuente normativa:
--   Arquitectura.md §7 (Persistencia / schema por servicio),
--   §8 (Migraciones: reproducible desde cero, no editar aplicadas, expand/contract),
--   §13 (Inventario: modelo autoritativo e invariantes),
--   §15 (Concurrencia de inventario y ajustes absolutos);
--   Modelo_Conceptual.md §14-15;
--   Contrato_Api.md §2.1;
--   CONVENCIONES_BD.md §3 y §18 (Ownership de Ubicación y definición de locations).
-- Compatible con PostgreSQL 14+ (probado en PostgreSQL 18; Supabase = Postgres 15).
-- ============================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS inventory;

-- --------------------------------------------------------------------------
-- Enumeraciones
-- --------------------------------------------------------------------------

CREATE TYPE inventory.reservation_status AS ENUM
    ('ACTIVA', 'CONSUMIDA', 'LIBERADA', 'EXPIRADA');

CREATE TYPE inventory.operation_type AS ENUM
    ('RESERVA', 'CONSUMO', 'LIBERACION', 'EXPIRACION',
     'AJUSTE_ABSOLUTO', 'INCIDENCIA_BLOQUEO', 'INCIDENCIA_RESOLUCION',
     'REINTEGRO', 'CONCILIACION_OFFLINE', 'RECEPCION_TRASLADO',
     'INICIALIZACION_SKU');

CREATE TYPE inventory.operation_status AS ENUM
    ('RECIBIDO', 'APLICADO', 'RECHAZADO', 'REQUIRES_REVIEW');

CREATE TYPE inventory.stock_status AS ENUM
    ('AGOTADO', 'STOCK_BAJO', 'DISPONIBLE');

CREATE TYPE inventory.outbox_status AS ENUM
    ('PENDING', 'PUBLISHED');

CREATE TYPE inventory.inbox_status AS ENUM
    ('RECEIVED', 'PROCESSED');

CREATE TYPE inventory.incidencia_estado AS ENUM
    ('ABIERTA', 'RESUELTA', 'TRASLADO_PENDIENTE');

CREATE TYPE inventory.tipo_resolucion_incidencia AS ENUM
    ('REHABILITADO', 'MERMA', 'FALTANTE_CONFIRMADO', 'TRASLADO_ALMACEN_CENTRAL');

CREATE TYPE inventory.traslado_estado AS ENUM
    ('EN_TRANSITO', 'RECIBIDO_PARCIAL', 'COMPLETADO', 'COMPLETADO_CON_DISCREPANCIA');

CREATE TYPE inventory.disposicion_recepcion_traslado AS ENUM
    ('REINGRESAR_DISPONIBLE', 'REINGRESAR_BLOQUEADO', 'CONFIRMAR_MERMA');

-- --------------------------------------------------------------------------
-- Funciones compartidas de triggers
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inventory.fn_touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- La carrera confirmar/liberar/expirar admite una sola transición terminal:
-- las reservas no pueden salir de un estado terminal.
CREATE OR REPLACE FUNCTION inventory.fn_no_double_terminal()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status <> 'ACTIVA' AND NEW.status IS DISTINCT FROM OLD.status THEN
        RAISE EXCEPTION
            'Transicion no permitida: reserva % ya esta en estado terminal %',
            OLD.reservation_id, OLD.status;
    END IF;
    RETURN NEW;
END;
$$;

-- Los estados terminales de traslado (COMPLETADO, COMPLETADO_CON_DISCREPANCIA)
-- son irreversibles: una recepción final no se revierte ni se sobrescribe.
CREATE OR REPLACE FUNCTION inventory.fn_traslado_terminal()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.estado IN ('COMPLETADO', 'COMPLETADO_CON_DISCREPANCIA')
       AND NEW.estado IS DISTINCT FROM OLD.estado THEN
        RAISE EXCEPTION
            'Transicion no permitida: traslado % ya esta en estado terminal %',
            OLD.traslado_id, OLD.estado;
    END IF;
    RETURN NEW;
END;
$$;

-- --------------------------------------------------------------------------
-- Tabla: locations (catálogo autoritativo de ubicaciones de inventario)
-- CONVENCIONES_BD.md §18
-- --------------------------------------------------------------------------

CREATE TABLE inventory.locations (
    id           uuid        NOT NULL DEFAULT gen_random_uuid(),
    code         text        NOT NULL,
    name         text        NOT NULL,
    type         text        NOT NULL,
    external_ref text,               -- extensión escalar opcional hacia Retail (sin FK)
    active       boolean     NOT NULL DEFAULT true,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_locations PRIMARY KEY (id),
    CONSTRAINT uq_locations_code UNIQUE (code)
);

CREATE TRIGGER trg_locations_updated_at
    BEFORE UPDATE ON inventory.locations
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

-- --------------------------------------------------------------------------
-- Tabla: stock_balance (saldo autoritativo por (sku_id, location_id))
-- --------------------------------------------------------------------------

CREATE TABLE inventory.stock_balance (
    sku_id        text        NOT NULL,
    location_id   uuid        NOT NULL,
    on_hand       integer     NOT NULL DEFAULT 0,
    reserved      integer     NOT NULL DEFAULT 0,
    blocked       integer     NOT NULL DEFAULT 0,
    stock_version bigint      NOT NULL DEFAULT 0,
    available     integer     GENERATED ALWAYS AS (GREATEST(0, on_hand - reserved - blocked)) STORED,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_stock_balance PRIMARY KEY (sku_id, location_id),
    CONSTRAINT fk_stock_balance_location FOREIGN KEY (location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT,
    CONSTRAINT ck_sb_no_negativo CHECK (on_hand >= 0 AND reserved >= 0 AND blocked >= 0),
    CONSTRAINT ck_sb_reserved_plus_blocked CHECK (reserved + blocked <= on_hand)
);

CREATE TRIGGER trg_stock_balance_updated_at
    BEFORE UPDATE ON inventory.stock_balance
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

-- --------------------------------------------------------------------------
-- Tabla: reservations (agregado order-level)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.reservations (
    id              uuid        NOT NULL DEFAULT gen_random_uuid(),
    reservation_id  uuid        NOT NULL,
    status          inventory.reservation_status NOT NULL DEFAULT 'ACTIVA',
    expires_at      timestamptz NOT NULL,
    idempotency_key text        NOT NULL,
    intention       text        NOT NULL DEFAULT 'reservar',
    correlation_id  uuid,
    order_id        uuid,
    operation_id    uuid,
    consumed_at     timestamptz,
    released_at     timestamptz,
    expired_at      timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_reservations PRIMARY KEY (id),
    CONSTRAINT uq_reservations_identity UNIQUE (reservation_id),
    CONSTRAINT uq_reservations_idempotency UNIQUE (idempotency_key)
);

CREATE TRIGGER trg_reservations_updated_at
    BEFORE UPDATE ON inventory.reservations
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

CREATE TRIGGER trg_no_double_terminal
    BEFORE UPDATE OF status ON inventory.reservations
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_no_double_terminal();

-- --------------------------------------------------------------------------
-- Tabla: reservation_lines (líneas de reserva; FK a reservations y locations)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.reservation_lines (
    id             uuid        NOT NULL DEFAULT gen_random_uuid(),
    reservation_id uuid        NOT NULL,
    sku_id         text        NOT NULL,
    location_id    uuid        NOT NULL,
    quantity       integer     NOT NULL CHECK (quantity > 0),
    CONSTRAINT pk_reservation_lines PRIMARY KEY (id),
    CONSTRAINT fk_reservation_lines_reservation FOREIGN KEY (reservation_id) REFERENCES inventory.reservations (id) ON DELETE CASCADE,
    CONSTRAINT fk_reservation_lines_location FOREIGN KEY (location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT,
    CONSTRAINT uq_reservation_lines UNIQUE (reservation_id, sku_id, location_id)
);

-- --------------------------------------------------------------------------
-- Tabla: inventory_operations (operaciones mutadoras, admisión e idempotencia)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.inventory_operations (
    id                 uuid        NOT NULL DEFAULT gen_random_uuid(),
    operation_type     inventory.operation_type NOT NULL,
    idempotency_key    text        NOT NULL,     -- única por comando
    intention          text        NOT NULL,
    status             inventory.operation_status NOT NULL DEFAULT 'RECIBIDO',
    sku_id             text,
    location_id        uuid,
    quantity_requested integer,
    quantity_applied   integer,
    result_code        text,       -- STOCK_INSUFICIENTE, VERSION_CONFLICT, etc.
    correlation_id     uuid,
    order_id           uuid,
    reservation_id     uuid,
    stock_version      bigint,     -- versión usada (ajustes absolutos)
    accepted_at        timestamptz, -- 202 Accepted (admisión, no resultado)
    applied_at         timestamptz,
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_inventory_operations PRIMARY KEY (id),
    CONSTRAINT fk_inventory_operations_location FOREIGN KEY (location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT,
    CONSTRAINT uk_operations_idempotency UNIQUE (idempotency_key),
    CONSTRAINT chk_op_qty CHECK (
        (quantity_requested IS NULL OR quantity_requested >= 0)
        AND (quantity_applied IS NULL OR quantity_applied >= 0)
    )
);

CREATE TRIGGER trg_inventory_operations_updated_at
    BEFORE UPDATE ON inventory.inventory_operations
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

-- --------------------------------------------------------------------------
-- Tabla: kardex (mutaciones autoritativas de saldo; append-only)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.kardex (
    id              uuid        NOT NULL DEFAULT gen_random_uuid(),
    sku_id          text        NOT NULL,
    location_id     uuid        NOT NULL,
    operation_type  inventory.operation_type NOT NULL,
    operation_id    uuid,
    reservation_id  uuid,
    quantity        integer     NOT NULL CHECK (quantity <> 0),
    on_hand_before  integer     NOT NULL,
    on_hand_after   integer     NOT NULL,
    reserved_before integer     NOT NULL,
    reserved_after  integer     NOT NULL,
    blocked_before  integer     NOT NULL,
    blocked_after   integer     NOT NULL,
    stock_version   bigint      NOT NULL,
    correlation_id  uuid,
    created_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_kardex PRIMARY KEY (id),
    CONSTRAINT fk_kardex_location FOREIGN KEY (location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT
);

-- --------------------------------------------------------------------------
-- Tabla: incidencias (cuarentenas físicas reportadas)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.incidencias (
    id                   uuid        NOT NULL DEFAULT gen_random_uuid(),
    incidencia_id        uuid        NOT NULL,
    sku_id               text        NOT NULL,
    location_id          uuid        NOT NULL,
    external_incident_id text,               -- referencia operativa externa de Retail
    act_ref              text,               -- acta de resolución
    estado               inventory.incidencia_estado NOT NULL DEFAULT 'ABIERTA',
    tipo_resolucion      inventory.tipo_resolucion_incidencia,
    cantidad_bloqueada   integer     NOT NULL CHECK (cantidad_bloqueada > 0),
    idempotency_key      text        NOT NULL, -- identidad del reporte (sincronización Retail)
    correlation_id       uuid,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),
    resolved_at          timestamptz,
    CONSTRAINT pk_incidencias PRIMARY KEY (id),
    CONSTRAINT fk_incidencias_location FOREIGN KEY (location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT,
    CONSTRAINT uk_incidencias_identity UNIQUE (incidencia_id),
    CONSTRAINT uk_incidencias_idempotency UNIQUE (idempotency_key)
);

CREATE TRIGGER trg_incidencias_updated_at
    BEFORE UPDATE ON inventory.incidencias
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

-- --------------------------------------------------------------------------
-- Tabla: traslados (origen -> destino entre ubicaciones)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.traslados (
    id                 uuid        NOT NULL DEFAULT gen_random_uuid(),
    traslado_id        uuid        NOT NULL,
    source_incident_id uuid,               -- incidencia resuelta como TRASLADO_ALMACEN_CENTRAL
    sku_id             text        NOT NULL,
    source_location_id uuid        NOT NULL,
    target_location_id uuid        NOT NULL,
    quantity_shipped   integer     NOT NULL CHECK (quantity_shipped > 0),
    quantity_received  integer     NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
    missing_quantity   integer,
    estado             inventory.traslado_estado NOT NULL DEFAULT 'EN_TRANSITO',
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_traslados PRIMARY KEY (id),
    CONSTRAINT fk_traslados_source_location FOREIGN KEY (source_location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT,
    CONSTRAINT fk_traslados_target_location FOREIGN KEY (target_location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT,
    CONSTRAINT uk_traslados_identity UNIQUE (traslado_id),
    CONSTRAINT chk_traslado_missing CHECK (
        missing_quantity IS NULL OR missing_quantity >= 0
    )
);

-- Un traslado por incidencia resuelta como traslado (evita duplicados).
CREATE UNIQUE INDEX ix_traslado_por_incidencia
    ON inventory.traslados (source_incident_id)
    WHERE source_incident_id IS NOT NULL;

CREATE TRIGGER trg_traslados_updated_at
    BEFORE UPDATE ON inventory.traslados
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

CREATE TRIGGER trg_traslado_terminal
    BEFORE UPDATE OF estado ON inventory.traslados
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_traslado_terminal();

-- --------------------------------------------------------------------------
-- Tabla: traslado_recepciones (recepción idempotente y su disposición)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.traslado_recepciones (
    id                uuid        NOT NULL DEFAULT gen_random_uuid(),
    recepcion_id      uuid        NOT NULL,
    traslado_id       uuid        NOT NULL,
    cantidad_recibida integer     NOT NULL CHECK (cantidad_recibida > 0),
    disposicion       inventory.disposicion_recepcion_traslado NOT NULL,
    es_recepcion_final boolean     NOT NULL DEFAULT false,
    sub_gestor        text        NOT NULL, -- sub del gestor autorizado (INVENTARIO_TRASLADOS_RECIBIR)
    idempotency_key   text        NOT NULL, -- identidad de la recepción (Idempotency-Key)
    received_at       timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_traslado_recepciones PRIMARY KEY (id),
    CONSTRAINT fk_recepciones_traslado FOREIGN KEY (traslado_id) REFERENCES inventory.traslados (id) ON DELETE CASCADE,
    CONSTRAINT uk_recepciones_identity UNIQUE (recepcion_id),
    CONSTRAINT uk_recepciones_idempotency UNIQUE (idempotency_key)
);

-- --------------------------------------------------------------------------
-- Tabla: stock_threshold_override (umbral efectivo global o por SKU)
-- El umbral no se define por ubicación en el alcance actual (SPEC-015 §6).
-- --------------------------------------------------------------------------

CREATE TABLE inventory.stock_threshold_override (
    id              uuid        NOT NULL DEFAULT gen_random_uuid(),
    sku_id          text,
    location_id     uuid,
    umbral_efectivo integer     NOT NULL CHECK (umbral_efectivo >= 0),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_stock_threshold_override PRIMARY KEY (id),
    CONSTRAINT fk_threshold_override_location FOREIGN KEY (location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT,
    CONSTRAINT uq_threshold_override UNIQUE (sku_id, location_id),
    CONSTRAINT chk_threshold_scope CHECK (
        location_id IS NULL
        AND (
            (sku_id IS NULL)
            OR (sku_id IS NOT NULL)
        )
    )
);

-- Solo puede existir un override global (ambos nulos).
CREATE UNIQUE INDEX ix_threshold_global
    ON inventory.stock_threshold_override ((1))
    WHERE sku_id IS NULL AND location_id IS NULL;

CREATE TRIGGER trg_threshold_override_updated_at
    BEFORE UPDATE ON inventory.stock_threshold_override
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

-- --------------------------------------------------------------------------
-- Tabla: inventory_config (configuración del contexto: TTL, política D-INV-01 ...)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.inventory_config (
    key         text        PRIMARY KEY,
    value       jsonb       NOT NULL,
    description text,
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_inventory_config_updated_at
    BEFORE UPDATE ON inventory.inventory_config
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

-- --------------------------------------------------------------------------
-- Tabla: dashboard_projection (read model de solo lectura del dashboard)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.dashboard_projection (
    sku_id          text        NOT NULL,
    location_id     uuid        NOT NULL,
    on_hand         integer     NOT NULL,
    reserved        integer     NOT NULL,
    blocked         integer     NOT NULL,
    available       integer     GENERATED ALWAYS AS
                    (GREATEST(0, on_hand - reserved - blocked)) STORED,
    status          inventory.stock_status NOT NULL,
    umbral_efectivo integer     NOT NULL,
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_dashboard_projection PRIMARY KEY (sku_id, location_id),
    CONSTRAINT fk_dashboard_projection_location FOREIGN KEY (location_id) REFERENCES inventory.locations (id) ON DELETE RESTRICT,
    CONSTRAINT chk_dp_no_negativo CHECK (on_hand >= 0 AND reserved >= 0 AND blocked >= 0),
    CONSTRAINT chk_dp_reserved_plus_blocked CHECK (reserved + blocked <= on_hand)
);

CREATE TRIGGER trg_dashboard_projection_updated_at
    BEFORE UPDATE ON inventory.dashboard_projection
    FOR EACH ROW EXECUTE FUNCTION inventory.fn_touch_updated_at();

-- --------------------------------------------------------------------------
-- Tabla: outbox (publicación de eventos posterior al commit)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.outbox (
    id             uuid        NOT NULL DEFAULT gen_random_uuid(),
    event_id       uuid        NOT NULL,
    event_type     text        NOT NULL,
    aggregate_type text        NOT NULL,
    aggregate_id   text        NOT NULL,
    correlation_id uuid,
    payload        jsonb       NOT NULL,
    status         inventory.outbox_status NOT NULL DEFAULT 'PENDING',
    published_at   timestamptz,
    created_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_outbox PRIMARY KEY (id),
    CONSTRAINT uk_outbox_event UNIQUE (event_id)
);

-- --------------------------------------------------------------------------
-- Tabla: inbox (deduplicación de mensajes entrantes)
-- --------------------------------------------------------------------------

CREATE TABLE inventory.inbox (
    id           uuid        NOT NULL DEFAULT gen_random_uuid(),
    message_id   uuid        NOT NULL UNIQUE,
    message_type text        NOT NULL,
    source       text        NOT NULL,
    payload      jsonb       NOT NULL,
    status       inventory.inbox_status NOT NULL DEFAULT 'RECEIVED',
    processed_at timestamptz,
    created_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_inbox PRIMARY KEY (id)
);

-- --------------------------------------------------------------------------
-- Índices operativos y de claves foráneas
-- --------------------------------------------------------------------------

CREATE INDEX ix_stock_balance_location_id
    ON inventory.stock_balance (location_id);

CREATE INDEX ix_reservations_ttl
    ON inventory.reservations (status, expires_at)
    WHERE status = 'ACTIVA';              -- barrido del worker de expiración TTL

CREATE INDEX ix_reservation_lines_reservation_id
    ON inventory.reservation_lines (reservation_id);

CREATE INDEX ix_reservation_lines_location_id
    ON inventory.reservation_lines (location_id);

CREATE INDEX ix_reservation_lines_sku
    ON inventory.reservation_lines (sku_id, location_id);

CREATE INDEX ix_inventory_operations_location_id
    ON inventory.inventory_operations (location_id);

CREATE INDEX ix_operations_sku
    ON inventory.inventory_operations (sku_id, location_id);

CREATE INDEX ix_operations_type_status
    ON inventory.inventory_operations (operation_type, status);

CREATE INDEX ix_kardex_location_id
    ON inventory.kardex (location_id);

CREATE INDEX ix_kardex_saldo
    ON inventory.kardex (sku_id, location_id, created_at DESC);

CREATE INDEX ix_kardex_operation
    ON inventory.kardex (operation_id);

CREATE INDEX ix_dashboard_projection_location_id
    ON inventory.dashboard_projection (location_id);

CREATE INDEX ix_dashboard_ubicacion_estado
    ON inventory.dashboard_projection (location_id, status);

CREATE INDEX ix_dashboard_estado
    ON inventory.dashboard_projection (status);

CREATE INDEX ix_outbox_dispatcher
    ON inventory.outbox (status, created_at);

CREATE INDEX ix_inbox_processing
    ON inventory.inbox (status, created_at);

CREATE INDEX ix_incidencias_location_id
    ON inventory.incidencias (location_id);

CREATE INDEX ix_incidencias_estado
    ON inventory.incidencias (estado);

CREATE INDEX ix_incidencias_sku
    ON inventory.incidencias (sku_id, location_id);

CREATE INDEX ix_traslados_source_location_id
    ON inventory.traslados (source_location_id);

CREATE INDEX ix_traslados_target_location_id
    ON inventory.traslados (target_location_id);

CREATE INDEX ix_traslados_estado
    ON inventory.traslados (estado);

CREATE INDEX ix_traslados_source
    ON inventory.traslados (source_location_id, estado);

CREATE INDEX ix_recepciones_traslado
    ON inventory.traslado_recepciones (traslado_id);

COMMIT;