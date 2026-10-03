-- taxonomy-svc / Persistencia de Taxonomía y Atributos (FLOW-008 a FLOW-012). PostgreSQL >= 15.
-- Fuentes y decisiones: ../physical-model.md y ../logical-model.md.
-- Ejecutar como po_taxonomy_owner, aprovisionado por bd/deploy/bootstrap.sql.
-- taxonomy_app: login runtime aprovisionado por bd/deploy/bootstrap.sql, SIN membresía owner.
-- Sin BEGIN/COMMIT: bd/deploy/migrate.py administra la transacción y el cálculo de checksum.

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
    'PENDING_DEACTIVATION'
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

CREATE OR REPLACE FUNCTION taxonomy.fn_enforce_category_parent_rules()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_parent record;
    v_cycle_found boolean;
    v_active_children integer;
BEGIN
    IF NEW.categoria_padre_id IS NULL THEN
        IF NEW.nivel <> 1 THEN
            RAISE EXCEPTION 'Una categoria raiz debe tener nivel 1';
        END IF;
    ELSE
        IF NEW.categoria_padre_id = NEW.id THEN
            RAISE EXCEPTION 'Una categoria no puede ser padre de si misma';
        END IF;

        SELECT * INTO v_parent
        FROM taxonomy.categories
        WHERE id = NEW.categoria_padre_id
        FOR KEY SHARE;

        IF NOT FOUND THEN
            RETURN NEW;
        END IF;
        IF v_parent.estado <> 'ACTIVO' THEN
            RAISE EXCEPTION 'La categoria padre % debe estar ACTIVA', NEW.categoria_padre_id;
        END IF;
        IF v_parent.nivel <> 1 THEN
            RAISE EXCEPTION 'La categoria padre % debe ser de nivel 1', NEW.categoria_padre_id;
        END IF;
        IF NEW.nivel <> 2 THEN
            RAISE EXCEPTION 'Una subcategoria con padre debe tener nivel 2';
        END IF;

        WITH RECURSIVE ancestors(id, categoria_padre_id) AS (
            SELECT id, categoria_padre_id
            FROM taxonomy.categories
            WHERE id = NEW.categoria_padre_id
            UNION ALL
            SELECT c.id, c.categoria_padre_id
            FROM taxonomy.categories c
            JOIN ancestors a ON c.id = a.categoria_padre_id
        )
        SELECT EXISTS (SELECT 1 FROM ancestors WHERE id = NEW.id)
        INTO v_cycle_found;

        IF v_cycle_found THEN
            RAISE EXCEPTION 'La jerarquia de categorias no puede formar ciclos';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF OLD.estado = 'ACTIVO' AND NEW.estado <> 'ACTIVO' THEN
            SELECT count(*) INTO v_active_children
            FROM taxonomy.categories
            WHERE categoria_padre_id = NEW.id
              AND estado = 'ACTIVO';
            IF v_active_children > 0 THEN
                RAISE EXCEPTION 'No se puede desactivar una categoria padre con subcategorias activas';
            END IF;
        END IF;
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
    SELECT tipo INTO v_tipo
    FROM taxonomy.characteristics
    WHERE id = NEW.caracteristica_id
    FOR UPDATE;
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
        INSERT INTO taxonomy.slug_history (categoria_id, old_slug, new_slug, changed_at)
        VALUES (NEW.categoria_id, OLD.slug, NEW.slug, now());
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION taxonomy.fn_prevent_slug_history_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'taxonomy.slug_history es append-only; no admite UPDATE ni DELETE';
END;
$$;

CREATE OR REPLACE FUNCTION taxonomy.fn_bump_product_type_schema_version()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_tipo_producto_id uuid;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_tipo_producto_id := OLD.tipo_producto_id;
    ELSE
        v_tipo_producto_id := NEW.tipo_producto_id;
    END IF;

    UPDATE taxonomy.product_types
    SET schema_version = schema_version + 1,
        updated_at = now()
    WHERE id = v_tipo_producto_id;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION taxonomy.fn_enforce_product_type_attribute_limit()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_limit integer;
    v_active integer;
BEGIN
    IF NEW.estado <> 'ACTIVO' THEN
        RETURN NEW;
    END IF;

    SELECT valor_integer INTO v_limit
    FROM taxonomy.runtime_settings
    WHERE clave = 'MAX_PRODUCT_TYPE_ATTRIBUTES'
    FOR UPDATE;

    IF v_limit IS NULL OR v_limit < 1 THEN
        RAISE EXCEPTION 'Configuracion MAX_PRODUCT_TYPE_ATTRIBUTES invalida';
    END IF;

    SELECT count(*) INTO v_active
    FROM taxonomy.product_type_characteristics
    WHERE tipo_producto_id = NEW.tipo_producto_id
      AND estado = 'ACTIVO'
      AND id <> coalesce(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);

    IF v_active >= v_limit THEN
        RAISE EXCEPTION 'Limite alcanzado: un tipo de producto no puede tener mas de % caracteristicas activas', v_limit;
    END IF;

    RETURN NEW;
END;
$$;

-- 3. Tablas de dominio
CREATE TABLE taxonomy.runtime_settings (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    clave text NOT NULL,
    valor_integer integer NOT NULL,
    descripcion text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_runtime_settings PRIMARY KEY (id),
    CONSTRAINT uq_runtime_settings_clave UNIQUE (clave),
    CONSTRAINT ck_runtime_settings_clave_not_empty CHECK (length(trim(clave)) > 0),
    CONSTRAINT ck_runtime_settings_valor_positivo CHECK (valor_integer > 0)
);

INSERT INTO taxonomy.runtime_settings (clave, valor_integer, descripcion)
VALUES (
    'MAX_PRODUCT_TYPE_ATTRIBUTES',
    20,
    'Limite configurable inicial de atributos activos por tipo de producto definido por SPEC-010'
);

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
    nombre_normalizado text GENERATED ALWAYS AS (lower(regexp_replace(btrim(nombre), '[[:space:]]+', ' ', 'g'))) STORED,
    descripcion text NULL,
    logo_url text NULL,
    pais_origen_iso char(2) NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_brands PRIMARY KEY (id),
    CONSTRAINT uq_brands_nombre_normalizado UNIQUE (nombre_normalizado),
    CONSTRAINT ck_brands_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_brands_nombre_normalizado_not_empty CHECK (length(trim(nombre_normalizado)) > 0),
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

CREATE TABLE taxonomy.slug_history (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    categoria_id uuid NOT NULL,
    old_slug text NOT NULL,
    new_slug text NOT NULL,
    changed_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_slug_history PRIMARY KEY (id),
    CONSTRAINT fk_slug_history_categoria FOREIGN KEY (categoria_id)
        REFERENCES taxonomy.categories(id) ON DELETE RESTRICT,
    CONSTRAINT ck_slug_history_distinct CHECK (old_slug <> new_slug)
);

CREATE TABLE taxonomy.master_deactivation_operations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    operation_id uuid NOT NULL,
    entity_type taxonomy.tipo_entidad_maestra NOT NULL,
    entity_id uuid NOT NULL,
    status taxonomy.estado_operacion_baja NOT NULL DEFAULT 'REQUESTED',
    reason text NULL,
    correlation_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_master_deactivation_operations PRIMARY KEY (id),
    CONSTRAINT uq_mdo_operation_id UNIQUE (operation_id),
    CONSTRAINT ck_mdo_operation_id_not_nil CHECK (operation_id <> '00000000-0000-0000-0000-000000000000'::uuid),
    CONSTRAINT ck_mdo_correlation_id_not_nil CHECK (correlation_id <> '00000000-0000-0000-0000-000000000000'::uuid)
);

CREATE TABLE taxonomy.outbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    message_id uuid NOT NULL DEFAULT gen_random_uuid(),
    event_name text NOT NULL,
    kind text NOT NULL,
    schema_version integer NOT NULL DEFAULT 1,
    correlation_id uuid NOT NULL,
    causation_id uuid NULL,
    operation_id uuid NULL,
    occurred_at timestamptz NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    published_at timestamptz NULL,
    attempts integer NOT NULL DEFAULT 0,
    last_error text NULL,
    CONSTRAINT pk_outbox PRIMARY KEY (id),
    CONSTRAINT uq_outbox_message_id UNIQUE (message_id),
    CONSTRAINT ck_outbox_kind CHECK (kind IN ('command', 'event', 'result')),
    CONSTRAINT ck_outbox_schema_version CHECK (schema_version >= 1),
    CONSTRAINT ck_outbox_attempts CHECK (attempts >= 0)
);

CREATE TABLE taxonomy.inbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    message_id uuid NOT NULL,
    handler text NOT NULL,
    event_name text NOT NULL,
    correlation_id uuid NULL,
    payload jsonb NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    result text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_inbox PRIMARY KEY (id),
    CONSTRAINT uq_inbox_message_handler UNIQUE (message_id, handler),
    CONSTRAINT ck_inbox_handler_not_empty CHECK (length(trim(handler)) > 0),
    CONSTRAINT ck_inbox_result CHECK (result IN ('PROCESSED', 'IGNORED', 'FAILED'))
);

-- 4. Disparadores (Triggers)
CREATE TRIGGER trg_runtime_settings_updated_at
    BEFORE UPDATE ON taxonomy.runtime_settings
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_categories_updated_at
    BEFORE UPDATE ON taxonomy.categories
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_categories_parent_rules
    BEFORE INSERT OR UPDATE OF categoria_padre_id, nivel, estado ON taxonomy.categories
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_enforce_category_parent_rules();

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

CREATE TRIGGER trg_ptc_attribute_limit
    BEFORE INSERT OR UPDATE OF tipo_producto_id, caracteristica_id, estado ON taxonomy.product_type_characteristics
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_enforce_product_type_attribute_limit();

CREATE TRIGGER trg_ptc_bump_schema_version
    AFTER INSERT OR UPDATE OF obligatoria, estado OR DELETE ON taxonomy.product_type_characteristics
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_bump_product_type_schema_version();

CREATE TRIGGER trg_category_seo_updated_at
    BEFORE UPDATE ON taxonomy.category_seo
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

CREATE TRIGGER trg_category_seo_track_slug
    AFTER UPDATE OF slug ON taxonomy.category_seo
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_track_slug_history();

CREATE TRIGGER trg_slug_history_append_only
    BEFORE UPDATE OR DELETE ON taxonomy.slug_history
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_prevent_slug_history_mutation();

CREATE TRIGGER trg_mdo_updated_at
    BEFORE UPDATE ON taxonomy.master_deactivation_operations
    FOR EACH ROW EXECUTE FUNCTION taxonomy.fn_set_updated_at();

-- 5. Índices de optimización y claves foráneas
CREATE INDEX ix_categories_padre_id ON taxonomy.categories(categoria_padre_id);
CREATE INDEX ix_characteristic_values_caracteristica_id ON taxonomy.characteristic_values(caracteristica_id);
CREATE INDEX ix_ptc_tipo_producto_id ON taxonomy.product_type_characteristics(tipo_producto_id);
CREATE INDEX ix_ptc_caracteristica_id ON taxonomy.product_type_characteristics(caracteristica_id);
CREATE INDEX ix_category_seo_categoria_id ON taxonomy.category_seo(categoria_id);
CREATE INDEX ix_slug_history_categoria_id ON taxonomy.slug_history(categoria_id);

CREATE INDEX ix_slug_history_old_slug ON taxonomy.slug_history(old_slug);
CREATE INDEX ix_outbox_pending ON taxonomy.outbox(published_at, occurred_at) WHERE published_at IS NULL;
CREATE INDEX ix_inbox_message_handler ON taxonomy.inbox(message_id, handler);
CREATE INDEX ix_mdo_entity ON taxonomy.master_deactivation_operations(entity_type, entity_id);

-- 6. Permisos para runtime
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA taxonomy TO taxonomy_app;
REVOKE UPDATE, DELETE ON taxonomy.slug_history FROM taxonomy_app;
ALTER DEFAULT PRIVILEGES FOR ROLE po_taxonomy_owner IN SCHEMA taxonomy
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO taxonomy_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA taxonomy TO taxonomy_app;
