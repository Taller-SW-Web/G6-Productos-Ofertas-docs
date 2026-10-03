-- catalog-svc / FLOW-003 y FLOW-004. PostgreSQL >= 15.
-- Fuentes y decisiones: ../physical-model.md. No es un bootstrap global.
-- Ejecutar como po_catalog_owner, provisionado por database/bootstrap.sql.
-- catalog_app: login runtime provisionado por infraestructura, SIN membresia owner.
-- Sin BEGIN/COMMIT: database/migrate.py administra la transaccion y checksum.

DO $guard$
BEGIN
    IF current_user <> 'po_catalog_owner' OR
       NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'catalog'
                   AND pg_get_userbyid(nspowner) = current_user) THEN
        RAISE EXCEPTION 'Ejecutar con po_catalog_owner sobre su schema catalog';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'catalog_app') THEN
        RAISE EXCEPTION 'Infraestructura debe provisionar catalog_app antes de migrar';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'catalog_app'
               AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolbypassrls)) OR
       pg_has_role('catalog_app', 'po_catalog_owner', 'MEMBER') THEN
        RAISE EXCEPTION 'catalog_app no debe tener privilegios owner/administrador';
    END IF;
END
$guard$;

REVOKE ALL ON SCHEMA catalog FROM PUBLIC;
GRANT USAGE ON SCHEMA catalog TO catalog_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA catalog REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

CREATE TYPE catalog.estado_producto AS ENUM ('BORRADOR', 'ACTIVO', 'INACTIVO');
CREATE TYPE catalog.estado_variante AS ENUM ('BORRADOR', 'ACTIVA', 'INACTIVA');

CREATE FUNCTION catalog.fn_set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TABLE catalog.products (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    descripcion text NOT NULL,
    categoria_id text NOT NULL,
    tipo_producto_id text NOT NULL,
    marca_id text NOT NULL,
    sku_base text NOT NULL,
    slug text NOT NULL,
    tiene_variantes boolean NOT NULL,
    estado catalog.estado_producto NOT NULL DEFAULT 'BORRADOR',
    catalog_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_products PRIMARY KEY (id),
    CONSTRAINT uq_products_sku_base UNIQUE (sku_base),
    CONSTRAINT uq_products_slug UNIQUE (slug),
    CONSTRAINT ck_products_minimos CHECK (length(nombre) > 0 AND length(descripcion) > 0
        AND length(categoria_id) > 0 AND length(tipo_producto_id) > 0
        AND length(marca_id) > 0 AND length(sku_base) > 0 AND length(slug) > 0),
    CONSTRAINT ck_products_version CHECK (catalog_version >= 0)
);

CREATE TABLE catalog.variants (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL,
    sku text NOT NULL,
    identifying_key jsonb NOT NULL,
    estado catalog.estado_variante NOT NULL DEFAULT 'BORRADOR',
    catalog_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_variants PRIMARY KEY (id),
    CONSTRAINT fk_variants_product_id FOREIGN KEY (product_id)
        REFERENCES catalog.products (id) ON DELETE CASCADE,
    CONSTRAINT uq_variants_sku UNIQUE (sku),
    CONSTRAINT uq_variants_product_combination UNIQUE (product_id, identifying_key),
    CONSTRAINT uq_variants_id_product UNIQUE (id, product_id),
    CONSTRAINT ck_variants_sku CHECK (length(sku) > 0),
    CONSTRAINT ck_variants_identifying_key CHECK (jsonb_typeof(identifying_key) = 'object'
        AND identifying_key <> '{}'::jsonb),
    CONSTRAINT ck_variants_version CHECK (catalog_version >= 0)
);

-- Registro tecnico de TODAS las identidades SKU, incluida la base no vendible.
-- Un UNIQUE comun evita colisiones entre products.sku_base y variants.sku.
CREATE TABLE catalog.sku_identity (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    sku text NOT NULL,
    product_id uuid,
    variant_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_sku_identity PRIMARY KEY (id),
    CONSTRAINT uq_sku_identity_sku UNIQUE (sku),
    CONSTRAINT uq_sku_identity_product UNIQUE (product_id),
    CONSTRAINT uq_sku_identity_variant UNIQUE (variant_id),
    CONSTRAINT fk_sku_identity_product_id FOREIGN KEY (product_id)
        REFERENCES catalog.products (id) ON DELETE RESTRICT,
    CONSTRAINT fk_sku_identity_variant_id FOREIGN KEY (variant_id)
        REFERENCES catalog.variants (id) ON DELETE RESTRICT,
    CONSTRAINT ck_sku_identity_owner CHECK (num_nonnulls(product_id, variant_id) = 1)
);

CREATE TABLE catalog.product_images (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL,
    url text NOT NULL,
    principal boolean NOT NULL DEFAULT false,
    posicion integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_product_images PRIMARY KEY (id),
    CONSTRAINT fk_product_images_product_id FOREIGN KEY (product_id)
        REFERENCES catalog.products (id) ON DELETE CASCADE,
    CONSTRAINT ck_product_images_url CHECK (length(url) > 0),
    CONSTRAINT ck_product_images_posicion CHECK (posicion >= 0)
);

CREATE TABLE catalog.variant_images (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    variant_id uuid NOT NULL,
    url text NOT NULL,
    posicion integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_variant_images PRIMARY KEY (id),
    CONSTRAINT fk_variant_images_variant_id FOREIGN KEY (variant_id)
        REFERENCES catalog.variants (id) ON DELETE CASCADE,
    CONSTRAINT ck_variant_images_url CHECK (length(url) > 0),
    CONSTRAINT ck_variant_images_posicion CHECK (posicion >= 0)
);

CREATE TABLE catalog.product_attribute_values (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL,
    caracteristica_id text NOT NULL,
    nombre_snapshot text NOT NULL,
    valor_id text,
    valor jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_product_attribute_values PRIMARY KEY (id),
    CONSTRAINT fk_product_attribute_values_product_id FOREIGN KEY (product_id)
        REFERENCES catalog.products (id) ON DELETE CASCADE,
    CONSTRAINT uq_product_attribute_values_characteristic UNIQUE (product_id, caracteristica_id)
);

CREATE TABLE catalog.variant_attribute_values (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    variant_id uuid NOT NULL,
    caracteristica_id text NOT NULL,
    nombre_snapshot text NOT NULL,
    valor_id text,
    valor jsonb NOT NULL,
    es_identificador boolean NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_variant_attribute_values PRIMARY KEY (id),
    CONSTRAINT fk_variant_attribute_values_variant_id FOREIGN KEY (variant_id)
        REFERENCES catalog.variants (id) ON DELETE CASCADE,
    CONSTRAINT uq_variant_attribute_values_characteristic UNIQUE (variant_id, caracteristica_id)
);

CREATE TABLE catalog.product_identifying_characteristics (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL,
    caracteristica_id text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_product_identifying_characteristics PRIMARY KEY (id),
    CONSTRAINT fk_product_identifying_characteristics_product_id FOREIGN KEY (product_id)
        REFERENCES catalog.products (id) ON DELETE CASCADE,
    CONSTRAINT uq_product_identifying_characteristics_ref UNIQUE (product_id, caracteristica_id)
);

CREATE TABLE catalog.sku_physical_profiles (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    sku_identity_id uuid NOT NULL,
    peso_kg numeric,
    largo_cm numeric,
    ancho_cm numeric,
    alto_cm numeric,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_sku_physical_profiles PRIMARY KEY (id),
    CONSTRAINT uq_sku_physical_profiles_identity UNIQUE (sku_identity_id),
    CONSTRAINT fk_sku_physical_profiles_sku_identity_id FOREIGN KEY (sku_identity_id)
        REFERENCES catalog.sku_identity (id) ON DELETE RESTRICT,
    CONSTRAINT ck_sku_physical_profiles_positive CHECK (
        (peso_kg IS NULL OR (peso_kg > 0 AND peso_kg NOT IN ('NaN'::numeric,'Infinity'::numeric))) AND
        (largo_cm IS NULL OR (largo_cm > 0 AND largo_cm NOT IN ('NaN'::numeric,'Infinity'::numeric))) AND
        (ancho_cm IS NULL OR (ancho_cm > 0 AND ancho_cm NOT IN ('NaN'::numeric,'Infinity'::numeric))) AND
        (alto_cm IS NULL OR (alto_cm > 0 AND alto_cm NOT IN ('NaN'::numeric,'Infinity'::numeric))))
);

-- Estado local de dependencias: no contiene precio/saldo autoritativos.
CREATE TABLE catalog.activation_checks (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL,
    variant_id uuid,
    sku text NOT NULL,
    dependency text NOT NULL,
    operation_id uuid NOT NULL,
    correlation_id uuid NOT NULL,
    request_payload jsonb NOT NULL,
    state text NOT NULL DEFAULT 'PENDING',
    result_payload jsonb,
    result_message_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_activation_checks PRIMARY KEY (id),
    CONSTRAINT fk_activation_checks_product_id FOREIGN KEY (product_id)
        REFERENCES catalog.products (id) ON DELETE RESTRICT,
    CONSTRAINT fk_activation_checks_variant_product FOREIGN KEY (variant_id, product_id)
        REFERENCES catalog.variants (id, product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_activation_checks_sku FOREIGN KEY (sku)
        REFERENCES catalog.sku_identity (sku) ON DELETE RESTRICT,
    CONSTRAINT uq_activation_checks_operation UNIQUE (operation_id),
    CONSTRAINT uq_activation_checks_dependency_sku UNIQUE (dependency, sku),
    CONSTRAINT ck_activation_checks_dependency CHECK (dependency IN ('PRICING', 'INVENTORY')),
    CONSTRAINT ck_activation_checks_state CHECK (state IN ('PENDING', 'COMPLETED', 'REJECTED')),
    CONSTRAINT ck_activation_checks_request CHECK (jsonb_typeof(request_payload) = 'object'),
    CONSTRAINT ck_activation_checks_result CHECK (state = 'PENDING' OR
        (result_message_id IS NOT NULL AND result_payload IS NOT NULL))
);

CREATE TABLE catalog.master_barriers (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    master_type text NOT NULL,
    master_id text NOT NULL,
    operation_id uuid NOT NULL,
    is_blocking boolean NOT NULL DEFAULT true,
    source_version bigint,
    payload jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_master_barriers PRIMARY KEY (id),
    CONSTRAINT uq_master_barriers_operation UNIQUE (operation_id),
    CONSTRAINT ck_master_barriers_version CHECK (source_version IS NULL OR source_version >= 0)
);

CREATE TABLE catalog.outbox (
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
    CONSTRAINT ck_outbox_kind CHECK (kind IN ('command', 'event', 'result')),
    CONSTRAINT ck_outbox_attempts CHECK (attempts >= 0)
);

CREATE TABLE catalog.inbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    message_id uuid NOT NULL,
    handler text NOT NULL,
    event_name text NOT NULL,
    correlation_id uuid,
    operation_id uuid,
    payload jsonb NOT NULL,
    result text NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_inbox PRIMARY KEY (id),
    CONSTRAINT uq_inbox_message_handler UNIQUE (message_id, handler)
);

-- Indices de FK cubiertos por UNIQUE no se duplican. Los restantes:
CREATE INDEX ix_variants_product_id ON catalog.variants (product_id, estado);
CREATE INDEX ix_activation_checks_product_id ON catalog.activation_checks (product_id);
CREATE INDEX ix_activation_checks_variant_product ON catalog.activation_checks (variant_id, product_id);
CREATE INDEX ix_activation_checks_sku ON catalog.activation_checks (sku);
CREATE INDEX ix_variant_images_variant_id ON catalog.variant_images (variant_id);
CREATE INDEX ix_product_images_product_id ON catalog.product_images (product_id);
CREATE INDEX ix_products_estado_created_at ON catalog.products (estado, created_at, id);
CREATE INDEX ix_products_categoria_id ON catalog.products (categoria_id);
CREATE INDEX ix_products_marca_id ON catalog.products (marca_id);
CREATE INDEX ix_products_tipo_producto_id ON catalog.products (tipo_producto_id);
CREATE INDEX ix_master_barriers_blocking ON catalog.master_barriers (master_type, master_id)
    WHERE is_blocking;
CREATE INDEX ix_outbox_pending ON catalog.outbox (occurred_at, id) WHERE published_at IS NULL;

-- La reserva global se inserta junto al propietario en la misma transaccion.
CREATE FUNCTION catalog.fn_register_sku() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_TABLE_NAME = 'products' THEN
        INSERT INTO catalog.sku_identity (sku, product_id) VALUES (NEW.sku_base, NEW.id);
    ELSE
        INSERT INTO catalog.sku_identity (sku, variant_id) VALUES (NEW.sku, NEW.id);
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION catalog.fn_guard_identity() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'La identidad se conserva; usar desactivacion logica' USING ERRCODE = '23514';
    END IF;
    IF TG_TABLE_NAME = 'sku_identity' THEN
        IF TG_OP = 'UPDATE' THEN
            RAISE EXCEPTION 'Registro SKU inmutable' USING ERRCODE = '23514';
        END IF;
        IF NEW.product_id IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM catalog.products WHERE id = NEW.product_id AND sku_base = NEW.sku) OR
           NEW.variant_id IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM catalog.variants WHERE id = NEW.variant_id AND sku = NEW.sku) THEN
            RAISE EXCEPTION 'Registro SKU no corresponde al propietario' USING ERRCODE = '23514';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.id IS DISTINCT FROM OLD.id THEN
            RAISE EXCEPTION 'ID inmutable' USING ERRCODE = '23514';
        END IF;
        IF TG_TABLE_NAME = 'products' THEN
            IF (NEW.sku_base, NEW.tiene_variantes, NEW.tipo_producto_id)
                IS DISTINCT FROM (OLD.sku_base, OLD.tiene_variantes, OLD.tipo_producto_id) THEN
                RAISE EXCEPTION 'Edicion no admite migracion estructural' USING ERRCODE = '23514';
            END IF;
        ELSE
            IF (NEW.product_id, NEW.sku, NEW.identifying_key)
                IS DISTINCT FROM (OLD.product_id, OLD.sku, OLD.identifying_key) THEN
                RAISE EXCEPTION 'Identidad de variante inmutable' USING ERRCODE = '23514';
            END IF;
        END IF;
        NEW.catalog_version = OLD.catalog_version + 1;
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION catalog.fn_guard_dependency() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE p catalog.products; v catalog.variants;
BEGIN
    SELECT * INTO STRICT p FROM catalog.products WHERE id = NEW.product_id FOR UPDATE;
    IF NEW.variant_id IS NOT NULL THEN
        SELECT * INTO STRICT v FROM catalog.variants WHERE id = NEW.variant_id;
    END IF;
    IF (NEW.dependency = 'PRICING' AND (NEW.variant_id IS NOT NULL OR NEW.sku <> p.sku_base)) OR
       (NEW.dependency = 'INVENTORY' AND NOT (
            (NOT p.tiene_variantes AND NEW.variant_id IS NULL AND NEW.sku = p.sku_base) OR
            (p.tiene_variantes AND NEW.variant_id IS NOT NULL AND v.product_id = p.id AND NEW.sku = v.sku))) THEN
        RAISE EXCEPTION 'Dependencia fuera de su unidad producto/SKU' USING ERRCODE = '23514';
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF (NEW.id, NEW.product_id, NEW.variant_id, NEW.sku, NEW.dependency,
            NEW.operation_id, NEW.request_payload) IS DISTINCT FROM
           (OLD.id, OLD.product_id, OLD.variant_id, OLD.sku, OLD.dependency,
            OLD.operation_id, OLD.request_payload) THEN
            RAISE EXCEPTION 'Retry debe conservar identidad e intencion' USING ERRCODE = '23514';
        END IF;
        IF OLD.state = 'COMPLETED' AND NEW.state <> 'COMPLETED' THEN
            RAISE EXCEPTION 'No reinicializar dependencia completada' USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Validacion del agregado al final de la transaccion: permite reemplazar imagenes
-- o perfil en varios statements sin aceptar un estado final ACTIVO incompleto.
CREATE FUNCTION catalog.fn_assert_product(p_id uuid) RETURNS void LANGUAGE plpgsql AS $$
DECLARE p catalog.products; v catalog.variants; key_from_values jsonb;
BEGIN
    SELECT * INTO p FROM catalog.products WHERE id = p_id FOR UPDATE;
    IF NOT FOUND THEN RETURN; END IF;
    IF NOT p.tiene_variantes AND EXISTS (SELECT 1 FROM catalog.variants WHERE product_id = p.id) THEN
        RAISE EXCEPTION 'Producto simple no admite variantes' USING ERRCODE = '23514';
    END IF;
    IF p.tiene_variantes AND EXISTS (
        SELECT 1 FROM catalog.sku_physical_profiles f JOIN catalog.sku_identity s ON s.id = f.sku_identity_id
        WHERE s.product_id = p.id) THEN
        RAISE EXCEPTION 'Padre con variantes no tiene perfil fisico' USING ERRCODE = '23514';
    END IF;
    FOR v IN SELECT * FROM catalog.variants WHERE product_id = p.id LOOP
        SELECT jsonb_object_agg(caracteristica_id,
            CASE WHEN valor_id IS NOT NULL THEN jsonb_build_object('valor_id', valor_id)
                 ELSE jsonb_build_object('valor', valor) END)
        INTO key_from_values FROM catalog.variant_attribute_values
        WHERE variant_id = v.id AND es_identificador;
        IF key_from_values IS DISTINCT FROM v.identifying_key THEN
            RAISE EXCEPTION 'Combinacion no corresponde a atributos identificadores' USING ERRCODE = '23514';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM catalog.variant_images WHERE variant_id = v.id) THEN
            RAISE EXCEPTION 'Variante requiere imagen' USING ERRCODE = '23514';
        END IF;
        IF v.estado = 'ACTIVA' AND (
            NOT EXISTS (SELECT 1 FROM catalog.sku_physical_profiles f
                JOIN catalog.sku_identity s ON s.id = f.sku_identity_id
                WHERE s.variant_id = v.id AND num_nonnulls(f.peso_kg, f.largo_cm, f.ancho_cm, f.alto_cm) = 4) OR
            NOT EXISTS (SELECT 1 FROM catalog.activation_checks
                WHERE variant_id = v.id AND dependency = 'INVENTORY' AND state = 'COMPLETED')) THEN
            RAISE EXCEPTION 'Variante ACTIVA requiere perfil completo e Inventario COMPLETED' USING ERRCODE = '23514';
        END IF;
    END LOOP;
    IF p.estado = 'ACTIVO' THEN
        IF NOT EXISTS (SELECT 1 FROM catalog.product_images WHERE product_id = p.id) OR
           NOT EXISTS (SELECT 1 FROM catalog.activation_checks WHERE product_id = p.id
                       AND dependency = 'PRICING' AND state = 'COMPLETED') THEN
            RAISE EXCEPTION 'Producto ACTIVO requiere imagen y Pricing COMPLETED' USING ERRCODE = '23514';
        END IF;
        IF p.tiene_variantes THEN
            IF NOT EXISTS (SELECT 1 FROM catalog.variants WHERE product_id = p.id AND estado = 'ACTIVA') THEN
                RAISE EXCEPTION 'Padre ACTIVO requiere una variante ACTIVA' USING ERRCODE = '23514';
            END IF;
        ELSE
            IF NOT EXISTS (SELECT 1 FROM catalog.sku_physical_profiles f
                JOIN catalog.sku_identity s ON s.id = f.sku_identity_id
                WHERE s.product_id = p.id AND num_nonnulls(f.peso_kg, f.largo_cm, f.ancho_cm, f.alto_cm) = 4) OR
               NOT EXISTS (SELECT 1 FROM catalog.activation_checks WHERE product_id = p.id
                    AND dependency = 'INVENTORY' AND state = 'COMPLETED') THEN
                RAISE EXCEPTION 'Simple ACTIVO requiere perfil completo e Inventario COMPLETED' USING ERRCODE = '23514';
            END IF;
        END IF;
    END IF;
END;
$$;

-- Obtiene el agregado de filas dependientes para locking y validacion diferida.
CREATE FUNCTION catalog.fn_row_product(row_data jsonb, table_name text) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE p_id uuid;
BEGIN
    IF table_name = 'products' THEN RETURN (row_data ->> 'id')::uuid; END IF;
    IF table_name = 'sku_physical_profiles' THEN
        SELECT coalesce(s.product_id, v.product_id) INTO p_id
        FROM catalog.sku_identity s LEFT JOIN catalog.variants v ON v.id = s.variant_id
        WHERE s.id = (row_data ->> 'sku_identity_id')::uuid;
    ELSIF row_data ->> 'product_id' IS NOT NULL THEN
        p_id = (row_data ->> 'product_id')::uuid;
    ELSE
        SELECT product_id INTO p_id FROM catalog.variants WHERE id = (row_data ->> 'variant_id')::uuid;
    END IF;
    RETURN p_id;
END;
$$;

CREATE FUNCTION catalog.fn_lock_aggregate() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE p_id uuid;
BEGIN
    IF TG_OP <> 'INSERT' THEN
        p_id = catalog.fn_row_product(to_jsonb(OLD), TG_TABLE_NAME);
        PERFORM 1 FROM catalog.products WHERE id = p_id FOR UPDATE;
    END IF;
    IF TG_OP <> 'DELETE' THEN
        p_id = catalog.fn_row_product(to_jsonb(NEW), TG_TABLE_NAME);
        PERFORM 1 FROM catalog.products WHERE id = p_id FOR UPDATE;
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION catalog.fn_check_aggregate() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP <> 'INSERT' THEN
        PERFORM catalog.fn_assert_product(catalog.fn_row_product(to_jsonb(OLD), TG_TABLE_NAME));
    END IF;
    IF TG_OP <> 'DELETE' THEN
        PERFORM catalog.fn_assert_product(catalog.fn_row_product(to_jsonb(NEW), TG_TABLE_NAME));
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_products_identity BEFORE UPDATE OR DELETE ON catalog.products
    FOR EACH ROW EXECUTE FUNCTION catalog.fn_guard_identity();
CREATE TRIGGER trg_variants_identity BEFORE UPDATE OR DELETE ON catalog.variants
    FOR EACH ROW EXECUTE FUNCTION catalog.fn_guard_identity();
CREATE TRIGGER trg_sku_identity_guard BEFORE INSERT OR UPDATE OR DELETE ON catalog.sku_identity
    FOR EACH ROW EXECUTE FUNCTION catalog.fn_guard_identity();
CREATE TRIGGER trg_products_register_sku AFTER INSERT ON catalog.products
    FOR EACH ROW EXECUTE FUNCTION catalog.fn_register_sku();
CREATE TRIGGER trg_variants_register_sku AFTER INSERT ON catalog.variants
    FOR EACH ROW EXECUTE FUNCTION catalog.fn_register_sku();
CREATE TRIGGER trg_activation_checks_guard BEFORE INSERT OR UPDATE ON catalog.activation_checks
    FOR EACH ROW EXECUTE FUNCTION catalog.fn_guard_dependency();

DO $triggers$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['products','variants','product_images','variant_images',
        'product_attribute_values','variant_attribute_values','product_identifying_characteristics',
        'sku_physical_profiles','activation_checks','master_barriers'] LOOP
        EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON catalog.%I FOR EACH ROW EXECUTE FUNCTION catalog.fn_set_updated_at()',
            'trg_' || t || '_updated_at', t);
    END LOOP;
    FOREACH t IN ARRAY ARRAY['products','variants','product_images','variant_images',
        'product_attribute_values','variant_attribute_values','product_identifying_characteristics',
        'sku_physical_profiles','activation_checks'] LOOP
        IF t <> 'products' THEN
            EXECUTE format('CREATE TRIGGER %I BEFORE INSERT OR UPDATE OR DELETE ON catalog.%I FOR EACH ROW EXECUTE FUNCTION catalog.fn_lock_aggregate()',
                'trg_' || t || '_lock', t);
        END IF;
        EXECUTE format('CREATE CONSTRAINT TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON catalog.%I DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION catalog.fn_check_aggregate()',
            'trg_' || t || '_aggregate', t);
    END LOOP;
END
$triggers$;

REVOKE ALL ON ALL TABLES IN SCHEMA catalog FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA catalog FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE ON catalog.products, catalog.variants,
    catalog.product_images, catalog.variant_images, catalog.product_attribute_values,
    catalog.variant_attribute_values, catalog.product_identifying_characteristics,
    catalog.sku_physical_profiles, catalog.activation_checks, catalog.master_barriers TO catalog_app;
GRANT DELETE ON catalog.product_images, catalog.variant_images,
    catalog.product_attribute_values, catalog.variant_attribute_values,
    catalog.product_identifying_characteristics, catalog.sku_physical_profiles TO catalog_app;
GRANT SELECT, INSERT ON catalog.sku_identity, catalog.inbox, catalog.outbox TO catalog_app;
GRANT UPDATE (published_at, attempts, last_error) ON catalog.outbox TO catalog_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA catalog TO catalog_app;

COMMENT ON TABLE catalog.sku_identity IS 'Registro tecnico de unicidad global; base con variantes no es SKU vendible.';
COMMENT ON COLUMN catalog.variants.identifying_key IS 'Objeto JSONB canonico caracteristica_id -> valor_id o valor; sin nombres mutables.';
COMMENT ON TABLE catalog.activation_checks IS 'Preparacion local, misma operation_id e intencion en retry; no autoritativo sobre precio/stock.';
COMMENT ON TABLE catalog.master_barriers IS 'Barrera local del protocolo Taxonomia; identificadores externos sin FK ni enum nuevo.';
COMMENT ON TABLE catalog.sku_physical_profiles IS 'kg/cm; nullable en borrador, completo antes de activar. Volumen calculado, no almacenado.';
COMMENT ON COLUMN catalog.products.catalog_version IS 'Version del agregado; el servicio actualiza la raiz al editar sus dependientes.';
COMMENT ON TABLE catalog.outbox IS 'Cambio de negocio y sobre AsyncAPI en la misma transaccion; publicar despues de commit.';
COMMENT ON TABLE catalog.inbox IS 'Deduplicacion por message_id y handler; insertar junto al efecto local.';
