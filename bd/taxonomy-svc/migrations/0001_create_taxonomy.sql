-- taxonomy-svc / Persistencia de Taxonomía y Atributos (FLOW-008 a FLOW-012). PostgreSQL >= 15.
-- Fuentes y decisiones: ../physical-model.md y ../logical-model.md.
-- Ejecutar como po_taxonomy_owner, aprovisionado por database/bootstrap.sql.
-- taxonomy_app: login runtime aprovisionado por infraestructura, SIN membresía owner.
-- Sin BEGIN/COMMIT: database/migrate.py administra la transacción y el cálculo de checksum.

DO $guard$
BEGIN
    IF current_user <> 'po_taxonomy_owner' OR
       NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'taxonomy'
                   AND pg_get_userbyid(nspowner) = current_user) THEN
        RAISE EXCEPTION 'Ejecutar con po_taxonomy_owner sobre su schema taxonomy';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'taxonomy_app') THEN
        RAISE EXCEPTION 'Infraestructura debe provisionar taxonomy_app antes de migrar';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'taxonomy_app'
               AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolbypassrls)) OR
       pg_has_role('taxonomy_app', 'po_taxonomy_owner', 'MEMBER') THEN
        RAISE EXCEPTION 'taxonomy_app no debe tener privilegios owner/administrador';
    END IF;
END
$guard$;

REVOKE ALL ON SCHEMA taxonomy FROM PUBLIC;
GRANT USAGE ON SCHEMA taxonomy TO taxonomy_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA taxonomy REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- 1. Tipos enumerados locales al schema
CREATE TYPE taxonomy.estado_entidad AS ENUM (
    'ACTIVO',
    'INACTIVO',
    'DESACTIVACION_PENDIENTE'
);

CREATE TYPE taxonomy.tipo_caracteristica AS ENUM (
    'TEXTO',
    'NUMERO',
    'LISTA'
);

CREATE TYPE taxonomy.tipo_entidad_maestra AS ENUM (
    'CATEGORY',
    'BRAND',
    'CHARACTERISTIC',
    'CHARACTERISTIC_VALUE',
    'PRODUCT_TYPE',
    'PRODUCT_TYPE_CHARACTERISTIC'
);

CREATE TYPE taxonomy.estado_operacion_baja AS ENUM (
    'REQUESTED',
    'IN_PROGRESS',
    'COMPLETED',
    'REJECTED',
    'FAILED'
);

-- 2. Funciones de triggers
CREATE OR REPLACE FUNCTION taxonomy.fn_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION taxonomy.fn_prevent_characteristic_type_change()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.tipo <> NEW.tipo THEN
        RAISE EXCEPTION 'El tipo de característica (%) es inmutable y no puede modificarse a %',
            OLD.tipo, NEW.tipo;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION taxonomy.fn_enforce_characteristic_value_rules()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_tipo taxonomy.tipo_caracteristica;
    v_activos integer;
BEGIN
    SELECT tipo INTO v_tipo FROM taxonomy.characteristics WHERE id = NEW.caracteristica_id;
    IF v_tipo <> 'LISTA' THEN
        RAISE EXCEPTION 'Solo las características de tipo LISTA pueden tener valores predefinidos. Tipo actual: %', v_tipo;
    END IF;

    IF NEW.estado = 'ACTIVO' THEN
        SELECT count(*) INTO v_activos
        FROM taxonomy.characteristic_values
        WHERE caracteristica_id = NEW.caracteristica_id
          AND estado = 'ACTIVO'
          AND id <> coalesce(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);
        IF v_activos >= 50 THEN
            RAISE EXCEPTION 'Límite alcanzado: una característica no puede tener más de 50 valores activos';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION taxonomy.fn_track_slug_history()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.slug <> NEW.slug THEN
        INSERT INTO taxonomy.category_slug_history (categoria_id, old_slug, new_slug, changed_at)
        VALUES (NEW.categoria_id, OLD.slug, NEW.slug, now());
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION taxonomy.fn_bump_product_type_schema_version()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    UPDATE taxonomy.product_types
    SET schema_version = schema_version + 1,
        updated_at = now()
    WHERE id = coalesce(NEW.tipo_producto_id, OLD.tipo_producto_id);
    RETURN NEW;
END;
$$;

-- 3. Tablas de dominio
CREATE TABLE taxonomy.categories (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    descripcion text NULL,
    categoria_padre_id uuid NULL,
    nivel smallint NOT NULL DEFAULT 1,
    orden integer NOT NULL DEFAULT 0,
    imagen_url text NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_categories PRIMARY KEY (id),
    CONSTRAINT fk_categories_categoria_padre FOREIGN KEY (categoria_padre_id)
        REFERENCES taxonomy.categories(id) ON DELETE RESTRICT,
    CONSTRAINT ck_categories_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_categories_nivel CHECK (nivel IN (1, 2)),
    CONSTRAINT ck_categories_orden CHECK (orden >= 0),
    CONSTRAINT ck_categories_version CHECK (taxonomy_version >= 0),
    CONSTRAINT ck_categories_no_self_parent CHECK (categoria_padre_id <> id),
    CONSTRAINT ck_categories_padre_nivel CHECK (
        (categoria_padre_id IS NULL AND nivel = 1) OR
        (categoria_padre_id IS NOT NULL AND nivel = 2)
    )
);

CREATE TABLE taxonomy.brands (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    descripcion text NULL,
    logo_url text NULL,
    pais_origen_iso char(2) NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_brands PRIMARY KEY (id),
    CONSTRAINT uq_brands_nombre UNIQUE (nombre),
    CONSTRAINT ck_brands_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_brands_pais_iso CHECK (pais_origen_iso IS NULL OR pais_origen_iso ~ '^[A-Z]{2}$'),
    CONSTRAINT ck_brands_version CHECK (taxonomy_version >= 0)
);

CREATE TABLE taxonomy.characteristics (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    tipo taxonomy.tipo_caracteristica NOT NULL,
    unidad_medida text NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_characteristics PRIMARY KEY (id),
    CONSTRAINT uq_characteristics_nombre UNIQUE (nombre),
    CONSTRAINT ck_characteristics_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_characteristics_unidad_medida CHECK (
        (tipo = 'NUMERO' AND unidad_medida IS NOT NULL AND length(trim(unidad_medida)) > 0) OR
        (tipo <> 'NUMERO' AND unidad_medida IS NULL)
    ),
    CONSTRAINT ck_characteristics_version CHECK (taxonomy_version >= 0)
);

CREATE TABLE taxonomy.characteristic_values (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    caracteristica_id uuid NOT NULL,
    nombre text NOT NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_characteristic_values PRIMARY KEY (id),
    CONSTRAINT fk_characteristic_values_caracteristica FOREIGN KEY (caracteristica_id)
        REFERENCES taxonomy.characteristics(id) ON DELETE RESTRICT,
    CONSTRAINT uq_characteristic_values_nombre UNIQUE (caracteristica_id, nombre),
    CONSTRAINT ck_characteristic_values_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_characteristic_values_version CHECK (taxonomy_version >= 0)
);

CREATE TABLE taxonomy.product_types (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    schema_version bigint NOT NULL DEFAULT 1,
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_product_types PRIMARY KEY (id),
    CONSTRAINT uq_product_types_nombre UNIQUE (nombre),
    CONSTRAINT ck_product_types_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_product_types_schema_version CHECK (schema_version >= 1),
    CONSTRAINT ck_product_types_version CHECK (taxonomy_version >= 0)
);

CREATE TABLE taxonomy.product_type_characteristics (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    tipo_producto_id uuid NOT NULL,
    caracteristica_id uuid NOT NULL,
    obligatoria boolean NOT NULL DEFAULT false,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_product_type_characteristics PRIMARY KEY (id),
    CONSTRAINT fk_ptc_tipo_producto FOREIGN KEY (tipo_producto_id)
        REFERENCES taxonomy.product_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ptc_caracteristica FOREIGN KEY (caracteristica_id)
        REFERENCES taxonomy.characteristics(id) ON DELETE RESTRICT,
    CONSTRAINT uq_ptc_tipo_caracteristica UNIQUE (tipo_producto_id, caracteristica_id)
);

CREATE TABLE taxonomy.category_seo (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    categoria_id uuid NOT NULL,
    slug text NOT NULL,
    meta_titulo text NULL,
    meta_descripcion text NULL,
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_category_seo PRIMARY KEY (id),
    CONSTRAINT fk_category_seo_categoria FOREIGN KEY (categoria_id)
        REFERENCES taxonomy.categories(id) ON DELETE RESTRICT,
    CONSTRAINT uq_category_seo_categoria UNIQUE (categoria_id),
    CONSTRAINT uq_category_seo_slug UNIQUE (slug),
    CONSTRAINT ck_category_seo_slug_format CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    CONSTRAINT ck_category_seo_version CHECK (taxonomy_version >= 0)
);

CREATE TABLE taxonomy.category_slug_history (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    categoria_id uuid NOT NULL,
    old_slug text NOT NULL,
    new_slug text NOT NULL,
    changed_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_category_slug_history PRIMARY KEY (id),
    CONSTRAINT fk_category_slug_history_categoria FOREIGN KEY (categoria_id)
        REFERENCES taxonomy.categories(id) ON DELETE RESTRICT,
    CONSTRAINT ck_category_slug_history_distinct CHECK (old_slug <> new_slug)
);

CREATE TABLE taxonomy.master_deactivation_operations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    operation_id text NOT NULL,
    entity_type taxonomy.tipo_entidad_maestra NOT NULL,
    entity_id uuid NOT NULL,
    status taxonomy.estado_operacion_baja NOT NULL DEFAULT 'REQUESTED',
    reason text NULL,
    correlation_id text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_master_deactivation_operations PRIMARY KEY (id),
    CONSTRAINT uq_mdo_operation_id UNIQUE (operation_id),
    CONSTRAINT ck_mdo_operation_id_not_empty CHECK (length(trim(operation_id)) > 0),
    CONSTRAINT ck_mdo_correlation_id_not_empty CHECK (length(trim(correlation_id)) > 0)
);

CREATE TABLE taxonomy.outbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    event_id uuid NOT NULL DEFAULT gen_random_uuid(),
    event_type text NOT NULL,
    aggregate_type text NOT NULL,
    aggregate_id text NOT NULL,
    payload jsonb NOT NULL,
    correlation_id text NOT NULL,
    status text NOT NULL DEFAULT 'PENDING',
    retry_count integer NOT NULL DEFAULT 0,
    error_message text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    published_at timestamptz NULL,
    CONSTRAINT pk_outbox PRIMARY KEY (id),
    CONSTRAINT uq_outbox_event_id UNIQUE (event_id),
    CONSTRAINT ck_outbox_status CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED')),
    CONSTRAINT ck_outbox_retry_count CHECK (retry_count >= 0)
);

CREATE TABLE taxonomy.inbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    message_id text NOT NULL,
    event_type text NOT NULL,
    producer text NOT NULL,
    payload jsonb NOT NULL,
    status text NOT NULL DEFAULT 'PROCESSED',
    received_at timestamptz NOT NULL DEFAULT now(),
    processed_at timestamptz NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_inbox PRIMARY KEY (id),
    CONSTRAINT uq_inbox_message_id UNIQUE (message_id),
    CONSTRAINT ck_inbox_status CHECK (status IN ('RECEIVED', 'PROCESSED', 'FAILED'))
);

-- 4. Disparadores (Triggers)
CREATE TRIGGER trg_categories_updated_at
    BEFORE UPDATE ON taxonomy.categories
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_brands_updated_at
    BEFORE UPDATE ON taxonomy.brands
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_characteristics_updated_at
    BEFORE UPDATE ON taxonomy.characteristics
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_characteristics_prevent_type_change
    BEFORE UPDATE OF tipo ON taxonomy.characteristics
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_prevent_characteristic_type_change();

CREATE TRIGGER trg_characteristic_values_updated_at
    BEFORE UPDATE ON taxonomy.characteristic_values
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_characteristic_values_rules
    BEFORE INSERT OR UPDATE ON taxonomy.characteristic_values
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_enforce_characteristic_value_rules();

CREATE TRIGGER trg_product_types_updated_at
    BEFORE UPDATE ON taxonomy.product_types
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_ptc_updated_at
    BEFORE UPDATE ON taxonomy.product_type_characteristics
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_ptc_bump_schema_version
    AFTER INSERT OR UPDATE OR DELETE ON taxonomy.product_type_characteristics
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_bump_product_type_schema_version();

CREATE TRIGGER trg_category_seo_updated_at
    BEFORE UPDATE ON taxonomy.category_seo
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_category_seo_track_slug
    AFTER UPDATE OF slug ON taxonomy.category_seo
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_track_slug_history();

CREATE TRIGGER trg_mdo_updated_at
    BEFORE UPDATE ON taxonomy.master_deactivation_operations
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

-- 5. Índices de optimización y claves foráneas
CREATE INDEX ix_categories_padre_id ON taxonomy.categories(categoria_padre_id);
CREATE INDEX ix_characteristic_values_caracteristica_id ON taxonomy.characteristic_values(caracteristica_id);
CREATE INDEX ix_ptc_tipo_producto_id ON taxonomy.product_type_characteristics(tipo_producto_id);
CREATE INDEX ix_ptc_caracteristica_id ON taxonomy.product_type_characteristics(caracteristica_id);
CREATE INDEX ix_category_seo_categoria_id ON taxonomy.category_seo(categoria_id);
CREATE INDEX ix_category_slug_history_categoria_id ON taxonomy.category_slug_history(categoria_id);

CREATE INDEX ix_category_slug_history_old_slug ON taxonomy.category_slug_history(old_slug);
CREATE INDEX ix_outbox_status_created ON taxonomy.outbox(status, created_at) WHERE status = 'PENDING';
CREATE INDEX ix_inbox_message_id ON taxonomy.inbox(message_id);
CREATE INDEX ix_mdo_entity ON taxonomy.master_deactivation_operations(entity_type, entity_id);

-- 6. Permisos para runtime
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA taxonomy TO taxonomy_app;
ALTER DEFAULT PRIVILEGES FOR ROLE po_taxonomy_owner IN SCHEMA taxonomy
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO taxonomy_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA taxonomy TO taxonomy_app;
