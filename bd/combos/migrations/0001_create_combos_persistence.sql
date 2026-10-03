-- =============================================================================
-- 0001_create_combos_persistence.sql
-- Issue #58 - combos-svc
--
-- Ejecutada por database/migrate.py:
--   - SET ROLE po_combos_owner
--   - BEGIN/COMMIT por versión
--   - ledger combos.schema_migrations
--
-- NO incluir BEGIN/COMMIT en este archivo.
-- Prerrequisito: database/bootstrap.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. PRECONDICIONES DEL BOOTSTRAP
-- -----------------------------------------------------------------------------

DO $guard$
DECLARE
    v_owner text;
BEGIN
    IF to_regnamespace('combos') IS NULL THEN
        RAISE EXCEPTION
            'Schema combos inexistente. Ejecute database/bootstrap.sql antes de migrar.';
    END IF;

    SELECT pg_get_userbyid(nspowner)
      INTO v_owner
      FROM pg_namespace
     WHERE nspname = 'combos';

    IF v_owner IS DISTINCT FROM 'po_combos_owner' THEN
        RAISE EXCEPTION
            'Owner inesperado para schema combos: %. Esperado po_combos_owner.',
            v_owner;
    END IF;
END
$guard$;

-- -----------------------------------------------------------------------------
-- 2. ENUM LOCAL
-- -----------------------------------------------------------------------------

CREATE TYPE combos.combo_status AS ENUM (
    'ACTIVO',
    'INACTIVO'
);

-- -----------------------------------------------------------------------------
-- 3. FUNCIÓN LOCAL DE updated_at
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION combos.fn_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, combos
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. TABLA combos
-- -----------------------------------------------------------------------------

CREATE TABLE combos.combos (
    id           uuid                NOT NULL DEFAULT gen_random_uuid(),
    name         text                NOT NULL,
    description  text                NULL,
    combo_price  numeric(12,2)       NOT NULL,
    currency     char(3)             NOT NULL,
    status       combos.combo_status NOT NULL DEFAULT 'ACTIVO',
    version      bigint              NOT NULL DEFAULT 0,
    created_at   timestamptz         NOT NULL DEFAULT now(),
    updated_at   timestamptz         NOT NULL DEFAULT now(),

    CONSTRAINT pk_combos
        PRIMARY KEY (id),

    CONSTRAINT ck_combos_name_not_blank
        CHECK (btrim(name) <> ''),

    CONSTRAINT ck_combos_combo_price_positive
        CHECK (
            combo_price > 0
            AND combo_price <> 'NaN'::numeric
        ),

    CONSTRAINT ck_combos_currency_not_blank
        CHECK (btrim(currency::text) <> ''),

    CONSTRAINT ck_combos_version_non_negative
        CHECK (version >= 0)
);

-- -----------------------------------------------------------------------------
-- 5. TABLA combo_items
-- -----------------------------------------------------------------------------

CREATE TABLE combos.combo_items (
    id          uuid        NOT NULL DEFAULT gen_random_uuid(),
    combo_id    uuid        NOT NULL,
    sku         text        NOT NULL,
    quantity    integer     NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_combo_items
        PRIMARY KEY (id),

    CONSTRAINT uq_combo_items_combo_sku
        UNIQUE (combo_id, sku),

    CONSTRAINT fk_combo_items_combo_id
        FOREIGN KEY (combo_id)
        REFERENCES combos.combos (id)
        ON DELETE CASCADE,

    CONSTRAINT ck_combo_items_sku_not_blank
        CHECK (btrim(sku) <> ''),

    CONSTRAINT ck_combo_items_quantity_positive
        CHECK (quantity > 0)
);

-- -----------------------------------------------------------------------------
-- 6. TABLA component_projection
-- -----------------------------------------------------------------------------

CREATE TABLE combos.component_projection (
    id                     uuid        NOT NULL DEFAULT gen_random_uuid(),
    combo_item_id          uuid        NOT NULL,
    catalog_deactivated    boolean     NOT NULL,
    catalog_observed_at    timestamptz NULL,
    projected_available    integer     NULL,
    inventory_observed_at  timestamptz NULL,
    created_at             timestamptz NOT NULL DEFAULT now(),
    updated_at             timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_component_projection
        PRIMARY KEY (id),

    CONSTRAINT uq_component_projection_combo_item_id
        UNIQUE (combo_item_id),

    CONSTRAINT fk_component_projection_combo_item_id
        FOREIGN KEY (combo_item_id)
        REFERENCES combos.combo_items (id)
        ON DELETE CASCADE,

    CONSTRAINT ck_component_projection_available_non_negative
        CHECK (
            projected_available IS NULL
            OR projected_available >= 0
        )
);

-- -----------------------------------------------------------------------------
-- 7. OUTBOX
--
-- Excepción deliberada:
-- message_id/correlation_id/causation_id son text porque AsyncAPI MessageEnvelope
-- los publica como string sin format: uuid. operation_id sí es uuid nullable.
-- -----------------------------------------------------------------------------

CREATE TABLE combos.outbox (
    id              uuid        NOT NULL DEFAULT gen_random_uuid(),
    message_id      text        NOT NULL,
    event_name      text        NOT NULL,
    kind            text        NOT NULL,
    schema_version  integer     NOT NULL DEFAULT 1,
    correlation_id  text        NOT NULL,
    causation_id    text        NULL,
    operation_id    uuid        NULL,
    occurred_at     timestamptz NOT NULL,
    payload         jsonb       NOT NULL,
    published_at    timestamptz NULL,
    attempts        integer     NOT NULL DEFAULT 0,
    last_error      text        NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_outbox
        PRIMARY KEY (id),

    CONSTRAINT uq_outbox_message_id
        UNIQUE (message_id),

    CONSTRAINT ck_outbox_message_id_not_blank
        CHECK (btrim(message_id) <> ''),

    CONSTRAINT ck_outbox_event_name_not_blank
        CHECK (btrim(event_name) <> ''),

    CONSTRAINT ck_outbox_kind
        CHECK (kind IN ('command', 'event', 'result')),

    CONSTRAINT ck_outbox_schema_version
        CHECK (schema_version >= 1),

    CONSTRAINT ck_outbox_correlation_id_not_blank
        CHECK (btrim(correlation_id) <> ''),

    CONSTRAINT ck_outbox_payload_object
        CHECK (jsonb_typeof(payload) = 'object'),

    CONSTRAINT ck_outbox_attempts
        CHECK (attempts >= 0)
);

-- -----------------------------------------------------------------------------
-- 8. INBOX
--
-- Dedupe por (message_id, handler), no por message_id global.
-- -----------------------------------------------------------------------------

CREATE TABLE combos.inbox (
    id              uuid        NOT NULL DEFAULT gen_random_uuid(),
    message_id      text        NOT NULL,
    handler         text        NOT NULL,
    event_name      text        NOT NULL,
    correlation_id  text        NOT NULL,
    operation_id    uuid        NULL,
    payload         jsonb       NOT NULL,
    processed_at    timestamptz NOT NULL DEFAULT now(),
    result           text        NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_inbox
        PRIMARY KEY (id),

    CONSTRAINT uq_inbox_message_handler
        UNIQUE (message_id, handler),

    CONSTRAINT ck_inbox_message_id_not_blank
        CHECK (btrim(message_id) <> ''),

    CONSTRAINT ck_inbox_handler_not_blank
        CHECK (btrim(handler) <> ''),

    CONSTRAINT ck_inbox_event_name_not_blank
        CHECK (btrim(event_name) <> ''),

    CONSTRAINT ck_inbox_correlation_id_not_blank
        CHECK (btrim(correlation_id) <> ''),

    CONSTRAINT ck_inbox_payload_object
        CHECK (jsonb_typeof(payload) = 'object'),

    CONSTRAINT ck_inbox_result_not_blank
        CHECK (btrim(result) <> '')
);

-- -----------------------------------------------------------------------------
-- 9. INVARIANTE TRANSACCIONAL: mínimo 2 componentes
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION combos.fn_assert_combo_min_components(
    p_combo_id uuid
)
RETURNS void
LANGUAGE plpgsql
SET search_path = pg_catalog, combos
AS $$
DECLARE
    v_component_count bigint;
BEGIN
    -- Serializa cambios concurrentes sobre la composición del mismo combo.
    PERFORM 1
      FROM combos.combos c
     WHERE c.id = p_combo_id
     FOR UPDATE;

    -- Borrado físico controlado del padre: no queda agregado que validar.
    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT count(*)
      INTO v_component_count
      FROM combos.combo_items ci
     WHERE ci.combo_id = p_combo_id;

    IF v_component_count < 2 THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23514',
                CONSTRAINT = 'ck_combos_min_two_components',
                MESSAGE = format(
                    'El combo %s debe contener al menos 2 componentes; contiene %s.',
                    p_combo_id,
                    v_component_count
                );
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION combos.fn_trg_combo_min_components()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, combos
AS $$
BEGIN
    IF TG_TABLE_NAME = 'combos' THEN
        PERFORM combos.fn_assert_combo_min_components(NEW.id);
        RETURN NULL;
    END IF;

    IF TG_OP = 'INSERT' THEN
        PERFORM combos.fn_assert_combo_min_components(NEW.combo_id);

    ELSIF TG_OP = 'DELETE' THEN
        PERFORM combos.fn_assert_combo_min_components(OLD.combo_id);

    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM combos.fn_assert_combo_min_components(OLD.combo_id);

        IF NEW.combo_id IS DISTINCT FROM OLD.combo_id THEN
            PERFORM combos.fn_assert_combo_min_components(NEW.combo_id);
        END IF;
    END IF;

    RETURN NULL;
END;
$$;

-- -----------------------------------------------------------------------------
-- 10. TRIGGERS DE updated_at
-- -----------------------------------------------------------------------------

CREATE TRIGGER trg_combos_updated_at
BEFORE UPDATE ON combos.combos
FOR EACH ROW
EXECUTE FUNCTION combos.fn_set_updated_at();

CREATE TRIGGER trg_combo_items_updated_at
BEFORE UPDATE ON combos.combo_items
FOR EACH ROW
EXECUTE FUNCTION combos.fn_set_updated_at();

CREATE TRIGGER trg_component_projection_updated_at
BEFORE UPDATE ON combos.component_projection
FOR EACH ROW
EXECUTE FUNCTION combos.fn_set_updated_at();

-- -----------------------------------------------------------------------------
-- 11. CONSTRAINT TRIGGERS DIFERIBLES
-- -----------------------------------------------------------------------------

CREATE CONSTRAINT TRIGGER trg_combos_min_components
AFTER INSERT ON combos.combos
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION combos.fn_trg_combo_min_components();

CREATE CONSTRAINT TRIGGER trg_combo_items_min_components
AFTER INSERT OR DELETE OR UPDATE OF combo_id
ON combos.combo_items
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION combos.fn_trg_combo_min_components();

-- -----------------------------------------------------------------------------
-- 12. ÍNDICES
-- -----------------------------------------------------------------------------

CREATE INDEX ix_combos_status
    ON combos.combos (status);

CREATE INDEX ix_combo_items_sku
    ON combos.combo_items (sku);

CREATE INDEX ix_outbox_pending
    ON combos.outbox (published_at, occurred_at);

-- uq_combo_items_combo_sku cubre el acceso por combo_id de su FK.
-- uq_component_projection_combo_item_id cubre combo_item_id de su FK.

-- -----------------------------------------------------------------------------
-- 13. COMENTARIOS
-- -----------------------------------------------------------------------------

COMMENT ON TABLE combos.combos IS
'Definición comercial y administrativa autoritativa de combos-svc.';

COMMENT ON COLUMN combos.combos.id IS
'PK surrogate UUID; se serializa como combo_id en el contrato HTTP.';

COMMENT ON COLUMN combos.combos.currency IS
'Moneda explícita del precio del combo. No se restringe a PEN.';

COMMENT ON TABLE combos.combo_items IS
'Componentes del combo. sku es referencia externa a Catálogo sin FK cross-context.';

COMMENT ON TABLE combos.component_projection IS
'Proyección reconstruible por componente; no es fuente autoritativa de Catálogo ni Inventario.';

COMMENT ON TABLE combos.outbox IS
'Outbox transaccional de combos-svc. published_at NULL significa pendiente.';

COMMENT ON TABLE combos.inbox IS
'Inbox de deduplicación por message_id + handler para consumo at-least-once.';

-- Reglas deliberadamente fuera de constraints locales:
-- - existencia/actividad del SKU: catalog-svc
-- - no anidamiento: validación de aplicación/contrato
-- - ventaja económica: pricing-svc
-- - reserva/consumo real: inventory-svc orquestado por Ventas
-- - payload específico de catalog.product.deactivated e inventory.stock.changed:
--   AsyncAPI aún usa GenericData.
