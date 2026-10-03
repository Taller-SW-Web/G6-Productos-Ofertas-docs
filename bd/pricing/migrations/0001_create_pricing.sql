-- #55 / pricing-svc. PostgreSQL >= 15. Modelo: ../physical-model.md.
-- Sin BEGIN/COMMIT: database/migrate.py administra transaccion y checksum.
-- Infraestructura: po_pricing_owner, schema pricing, pricing_app y btree_gist
-- instalado en extensions. No crea roles ni modifica otros bounded contexts.
DO $guard$
BEGIN
    IF current_user <> 'po_pricing_owner' OR NOT EXISTS (
        SELECT 1 FROM pg_namespace WHERE nspname = 'pricing'
        AND pg_get_userbyid(nspowner) = current_user
    ) THEN RAISE EXCEPTION 'Ejecutar con po_pricing_owner sobre pricing'; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pricing_app') THEN
        RAISE EXCEPTION 'Infraestructura debe provisionar pricing_app';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pricing_app'
        AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls))
        OR pg_has_role('pricing_app', 'po_pricing_owner', 'MEMBER') THEN
        RAISE EXCEPTION 'pricing_app debe ser runtime sin privilegios owner';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_extension e JOIN pg_namespace n
        ON n.oid = e.extnamespace WHERE e.extname = 'btree_gist' AND n.nspname = 'extensions') THEN
        RAISE EXCEPTION 'Infraestructura debe instalar btree_gist en extensions';
    END IF;
    IF NOT has_schema_privilege(current_user,'extensions','USAGE') THEN
        RAISE EXCEPTION 'Infraestructura debe dar USAGE en extensions a po_pricing_owner';
    END IF;
END
$guard$;

REVOKE ALL ON SCHEMA pricing FROM PUBLIC;
GRANT USAGE ON SCHEMA pricing TO pricing_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA pricing REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

CREATE TYPE pricing.scheduled_price_status AS ENUM ('SCHEDULED','ACTIVE','HISTORICAL','CANCELLED');
CREATE TYPE pricing.bulk_price_job_status AS ENUM ('QUEUED','PROCESSING','COMPLETED','PARTIAL','FAILED');
CREATE TYPE pricing.bulk_price_row_status AS ENUM ('PENDING','PROCESSING','COMPLETED','FAILED');

CREATE FUNCTION pricing.fn_set_updated_at() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog, pricing AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END;
$$;

-- Definicion: un objetivo externo y un canal; no contiene dinero historico.
CREATE TABLE pricing.prices (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id text,
    sku text,
    channel_id text,
    price_version bigint NOT NULL DEFAULT 1,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_prices PRIMARY KEY (id),
    CONSTRAINT uq_prices_target_channel UNIQUE NULLS NOT DISTINCT (product_id, sku, channel_id),
    CONSTRAINT ck_prices_target CHECK ((product_id IS NOT NULL) <> (sku IS NOT NULL)),
    CONSTRAINT ck_prices_version CHECK (price_version >= 1)
);

-- Snapshots completos con intervalos [inicio, fin); NULL equivale a fin abierto.
-- Moneda pertenece al snapshot, no se pierde cuando cambia la tarifa.
CREATE TABLE pricing.price_validities (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    price_id uuid NOT NULL,
    precio_regular numeric(12,2) NOT NULL,
    precio_oferta numeric(12,2),
    currency char(3) NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz,
    price_version bigint NOT NULL,
    motivo_cambio text NOT NULL,
    usuario_id text,
    is_cancelled boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_price_validities PRIMARY KEY (id),
    CONSTRAINT uq_price_validities_id_price UNIQUE (id, price_id),
    CONSTRAINT uq_price_validities_price_version UNIQUE (price_id, price_version),
    CONSTRAINT fk_price_validities_price_id FOREIGN KEY (price_id)
        REFERENCES pricing.prices (id) ON DELETE RESTRICT,
    CONSTRAINT ck_price_validities_regular CHECK (precio_regular > 0 AND precio_regular <> 'NaN'::numeric),
    CONSTRAINT ck_price_validities_oferta CHECK (precio_oferta IS NULL OR
        (precio_oferta > 0 AND precio_oferta < precio_regular)),
    CONSTRAINT ck_price_validities_currency CHECK (length(btrim(currency)) = 3),
    CONSTRAINT ck_price_validities_order CHECK (valid_until IS NULL OR valid_until > valid_from),
    CONSTRAINT ck_price_validities_version CHECK (price_version >= 1),
    CONSTRAINT ck_price_validities_motivo CHECK (length(btrim(motivo_cambio)) > 0),
    CONSTRAINT ck_price_validities_no_overlap EXCLUDE USING gist (
        price_id extensions.gist_uuid_ops WITH =,
        tstzrange(valid_from, valid_until, '[)') WITH &&
    ) WHERE (NOT is_cancelled) DEFERRABLE INITIALLY IMMEDIATE
);
CREATE INDEX ix_price_validities_price_id ON pricing.price_validities (price_id, valid_from DESC);

-- Una programacion referencia el snapshot futuro: no es una segunda linea
-- temporal que pueda solaparse silenciosamente con precios confirmados.
CREATE TABLE pricing.scheduled_prices (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    price_id uuid NOT NULL,
    validity_id uuid NOT NULL,
    tipo_precio text NOT NULL,
    importe numeric(12,2) NOT NULL,
    status pricing.scheduled_price_status NOT NULL DEFAULT 'SCHEDULED',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_scheduled_prices PRIMARY KEY (id),
    CONSTRAINT uq_scheduled_prices_validity UNIQUE (validity_id, price_id),
    CONSTRAINT fk_scheduled_prices_validity_price FOREIGN KEY (validity_id, price_id)
        REFERENCES pricing.price_validities (id, price_id) ON DELETE RESTRICT,
    CONSTRAINT ck_scheduled_prices_type CHECK (tipo_precio IN ('REGULAR','OFERTA')),
    CONSTRAINT ck_scheduled_prices_importe CHECK (importe > 0 AND importe <> 'NaN'::numeric)
);
CREATE INDEX ix_scheduled_prices_price_id ON pricing.scheduled_prices (price_id);
CREATE INDEX ix_scheduled_prices_worker ON pricing.scheduled_prices (status, created_at)
    WHERE status IN ('SCHEDULED','ACTIVE');

CREATE TABLE pricing.bulk_price_jobs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    status pricing.bulk_price_job_status NOT NULL DEFAULT 'QUEUED',
    allow_partial boolean NOT NULL,
    total_rows integer NOT NULL,
    completed_rows integer NOT NULL DEFAULT 0,
    failed_rows integer NOT NULL DEFAULT 0,
    correlation_id uuid NOT NULL,
    usuario_id text,
    report_uri text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_bulk_price_jobs PRIMARY KEY (id),
    CONSTRAINT ck_bulk_price_jobs_counts CHECK (total_rows >= 0 AND completed_rows >= 0
        AND failed_rows >= 0 AND completed_rows + failed_rows <= total_rows),
    CONSTRAINT ck_bulk_price_jobs_completed CHECK (status <> 'COMPLETED' OR
        (completed_rows = total_rows AND failed_rows = 0)),
    CONSTRAINT ck_bulk_price_jobs_partial CHECK (status <> 'PARTIAL' OR
        (allow_partial AND completed_rows > 0 AND failed_rows > 0
        AND completed_rows + failed_rows = total_rows))
);
CREATE INDEX ix_bulk_price_jobs_worker ON pricing.bulk_price_jobs (created_at)
    WHERE status IN ('QUEUED','PROCESSING');

CREATE TABLE pricing.bulk_price_rows (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    batch_id uuid NOT NULL,
    row_id text NOT NULL,
    sku text,
    status pricing.bulk_price_row_status NOT NULL DEFAULT 'PENDING',
    code text,
    detail text,
    row_input jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_bulk_price_rows PRIMARY KEY (id),
    CONSTRAINT uq_bulk_price_rows_batch_row UNIQUE (batch_id, row_id),
    CONSTRAINT fk_bulk_price_rows_batch_id FOREIGN KEY (batch_id)
        REFERENCES pricing.bulk_price_jobs (id) ON DELETE RESTRICT,
    CONSTRAINT ck_bulk_price_rows_input CHECK (jsonb_typeof(row_input) = 'object')
);
-- La unicidad comienza por batch_id y cubre el indice de la FK.

CREATE TABLE pricing.outbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    message_id uuid NOT NULL,
    event_name text NOT NULL,
    kind text NOT NULL,
    schema_version integer NOT NULL DEFAULT 1,
    correlation_id uuid NOT NULL,
    causation_id uuid,
    operation_id uuid,
    occurred_at timestamptz NOT NULL,
    payload jsonb NOT NULL,
    published_at timestamptz,
    attempts integer NOT NULL DEFAULT 0,
    last_error text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_outbox PRIMARY KEY (id),
    CONSTRAINT uq_outbox_message_id UNIQUE (message_id),
    CONSTRAINT ck_outbox_kind CHECK (kind IN ('command','event','result')),
    CONSTRAINT ck_outbox_attempts CHECK (attempts >= 0),
    CONSTRAINT ck_outbox_schema_version CHECK (schema_version >= 1)
);
CREATE INDEX ix_outbox_pending ON pricing.outbox (occurred_at) WHERE published_at IS NULL;

CREATE TABLE pricing.inbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    message_id uuid NOT NULL,
    handler text NOT NULL,
    event_name text NOT NULL,
    correlation_id uuid,
    payload jsonb NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    result text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_inbox PRIMARY KEY (id),
    CONSTRAINT uq_inbox_message_handler UNIQUE (message_id, handler)
);

CREATE FUNCTION pricing.fn_guard_price_identity_version() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, pricing AS $$
BEGIN
    IF ROW(NEW.product_id,NEW.sku,NEW.channel_id) IS DISTINCT FROM
       ROW(OLD.product_id,OLD.sku,OLD.channel_id) THEN
        RAISE EXCEPTION 'Objetivo y canal de una definicion son inmutables' USING ERRCODE = '23514';
    END IF;
    IF NEW.price_version <> OLD.price_version + 1 THEN
        RAISE EXCEPTION 'La version debe avanzar una unidad' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_prices_identity_version BEFORE UPDATE ON pricing.prices
FOR EACH ROW EXECUTE FUNCTION pricing.fn_guard_price_identity_version();

-- Se comprueba al final de la transaccion: permite cerrar un intervalo y
-- construir/reajustar sus programaciones sin prohibir cambios atomicos validos.
CREATE FUNCTION pricing.fn_check_price_timeline() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, pricing AS $$
DECLARE target uuid;
BEGIN
    IF TG_TABLE_NAME = 'prices' THEN target := NEW.id;
    ELSE target := NEW.price_id; END IF;
    IF NOT EXISTS (SELECT 1 FROM pricing.price_validities WHERE price_id = target) THEN
        RAISE EXCEPTION 'Una definicion requiere al menos una vigencia' USING ERRCODE = '23514';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pricing.prices p
                   JOIN pricing.price_validities v
                     ON v.price_id = p.id AND v.price_version = p.price_version
                   WHERE p.id = target) THEN
        RAISE EXCEPTION 'La version del agregado requiere su snapshot correspondiente' USING ERRCODE = '23514';
    END IF;
    IF EXISTS (SELECT 1 FROM pricing.price_validities v JOIN pricing.prices p ON p.id = v.price_id
               WHERE v.price_id = target AND v.price_version > p.price_version) THEN
        RAISE EXCEPTION 'Vigencia con version superior a su definicion' USING ERRCODE = '23514';
    END IF;
    IF EXISTS (SELECT 1 FROM pricing.scheduled_prices s
               JOIN pricing.price_validities v ON v.id = s.validity_id AND v.price_id = s.price_id
               WHERE s.price_id = target AND (
                   (s.tipo_precio = 'REGULAR' AND s.importe <> v.precio_regular) OR
                   (s.tipo_precio = 'OFERTA' AND (v.precio_oferta IS NULL OR s.importe <> v.precio_oferta)) OR
                   ((s.status = 'CANCELLED') <> v.is_cancelled)
               )) THEN
        RAISE EXCEPTION 'Programacion y snapshot de vigencia incoherentes' USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER trg_prices_timeline AFTER INSERT OR UPDATE ON pricing.prices
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION pricing.fn_check_price_timeline();
CREATE CONSTRAINT TRIGGER trg_price_validities_timeline AFTER INSERT OR UPDATE ON pricing.price_validities
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION pricing.fn_check_price_timeline();
CREATE CONSTRAINT TRIGGER trg_scheduled_prices_timeline AFTER INSERT OR UPDATE ON pricing.scheduled_prices
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION pricing.fn_check_price_timeline();

DO $triggers$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['prices','price_validities','scheduled_prices','bulk_price_jobs','bulk_price_rows'] LOOP
        EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON pricing.%I FOR EACH ROW EXECUTE FUNCTION pricing.fn_set_updated_at()',
            'trg_' || t || '_updated_at', t);
    END LOOP;
END
$triggers$;

REVOKE ALL ON ALL TABLES IN SCHEMA pricing FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA pricing FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE ON pricing.prices, pricing.price_validities,
    pricing.scheduled_prices, pricing.bulk_price_jobs, pricing.bulk_price_rows, pricing.outbox TO pricing_app;
GRANT SELECT, INSERT ON pricing.inbox TO pricing_app;
-- Sin DELETE/TRUNCATE/CREATE ni membresia owner para runtime. No RLS en escritura.
COMMENT ON TABLE pricing.prices IS 'Definicion de precio por producto O SKU y canal, con version optimista; referencias externas sin FK.';
COMMENT ON TABLE pricing.price_validities IS 'Snapshots monetarios historicos/futuros, intervalos semiabiertos sin solapamiento por definicion.';
COMMENT ON TABLE pricing.scheduled_prices IS 'Intencion de programacion vinculada a la misma linea temporal; Clock y worker determinan aplicacion.';
COMMENT ON TABLE pricing.bulk_price_rows IS 'Filas durables de la carga local Pricing; row_input no define el formato externo del archivo.';
COMMENT ON TABLE pricing.outbox IS 'Insertar junto a la mutacion de negocio; relay publica solo despues del commit.';
