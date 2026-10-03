-- taxonomy-svc / Validacion del modelo fisico de base de datos.
-- Ejecutar con: psql -X -v ON_ERROR_STOP=1 -f validation.sql

\set ON_ERROR_STOP on

DO $metadata$
DECLARE
    t text;
    fk record;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_namespace
        WHERE nspname = 'taxonomy'
          AND pg_get_userbyid(nspowner) = 'po_taxonomy_owner'
    ) THEN
        RAISE EXCEPTION 'FAIL: schema taxonomy inexistente o con owner incorrecto';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'taxonomy_app') THEN
        RAISE EXCEPTION 'FAIL: rol runtime taxonomy_app no existe';
    END IF;

    FOREACH t IN ARRAY ARRAY[
        'runtime_settings',
        'categories',
        'brands',
        'characteristics',
        'characteristic_values',
        'product_types',
        'product_type_characteristics',
        'category_seo',
        'slug_history',
        'master_deactivation_operations',
        'outbox',
        'inbox'
    ] LOOP
        IF to_regclass('taxonomy.' || t) IS NULL THEN
            RAISE EXCEPTION 'FAIL: no existe taxonomy.%', t;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
            WHERE c.conrelid = to_regclass('taxonomy.' || t)
              AND c.contype = 'p'
              AND cardinality(c.conkey) = 1
              AND a.attname = 'id'
              AND a.atttypid = 'uuid'::regtype
              AND c.conname = 'pk_' || t
        ) THEN
            RAISE EXCEPTION 'FAIL: taxonomy.% no tiene PK uuid id nombrada pk_%', t, t;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM pg_attribute a
            JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
            WHERE a.attrelid = to_regclass('taxonomy.' || t)
              AND a.attname = 'created_at'
              AND a.atttypid = 'timestamptz'::regtype
              AND a.attnotnull
              AND pg_get_expr(d.adbin, d.adrelid) = 'now()'
        ) THEN
            RAISE EXCEPTION 'FAIL: taxonomy.% no tiene created_at timestamptz NOT NULL DEFAULT now()', t;
        END IF;

        IF t NOT IN ('slug_history', 'outbox', 'inbox') AND NOT EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgrelid = to_regclass('taxonomy.' || t)
              AND tgname = 'trg_' || t || '_updated_at'
              AND NOT tgisinternal
              AND tgenabled = 'O'
        ) THEN
            RAISE EXCEPTION 'FAIL: taxonomy.% no tiene trigger updated_at activo', t;
        END IF;
    END LOOP;

    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder)
        FROM pg_enum e
        WHERE e.enumtypid = 'taxonomy.estado_entidad'::regtype) IS DISTINCT FROM
       ARRAY['ACTIVO', 'INACTIVO', 'PENDING_DEACTIVATION']::text[] THEN
        RAISE EXCEPTION 'FAIL: enum taxonomy.estado_entidad no coincide con SPEC-008';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'taxonomy'
          AND table_name = 'brands'
          AND column_name = 'nombre_normalizado'
          AND data_type = 'text'
          AND is_generated = 'ALWAYS'
    ) THEN
        RAISE EXCEPTION 'FAIL: brands.nombre_normalizado generado no existe';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'taxonomy.brands'::regclass
          AND conname = 'uq_brands_nombre_normalizado'
          AND contype = 'u'
    ) THEN
        RAISE EXCEPTION 'FAIL: falta uq_brands_nombre_normalizado';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'taxonomy.brands'::regclass
          AND conname = 'uq_brands_nombre'
    ) THEN
        RAISE EXCEPTION 'FAIL: persiste UNIQUE(nombre) obsoleto en brands';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = 'taxonomy.outbox'::regclass
          AND attname IN ('message_id', 'correlation_id', 'operation_id')
          AND atttypid = 'uuid'::regtype
        GROUP BY attrelid
        HAVING count(*) = 3
    ) THEN
        RAISE EXCEPTION 'FAIL: outbox no usa UUID en message_id/correlation_id/operation_id';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'taxonomy.inbox'::regclass
          AND conname = 'uq_inbox_message_handler'
          AND contype = 'u'
    ) THEN
        RAISE EXCEPTION 'FAIL: inbox no deduplica por (message_id, handler)';
    END IF;

    IF has_table_privilege('taxonomy_app', 'taxonomy.slug_history', 'UPDATE')
       OR has_table_privilege('taxonomy_app', 'taxonomy.slug_history', 'DELETE') THEN
        RAISE EXCEPTION 'FAIL: taxonomy_app puede modificar slug_history append-only';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class src ON src.oid = c.conrelid
        JOIN pg_namespace sn ON sn.oid = src.relnamespace
        JOIN pg_class dst ON dst.oid = c.confrelid
        JOIN pg_namespace dn ON dn.oid = dst.relnamespace
        WHERE c.contype = 'f'
          AND sn.nspname = 'taxonomy'
          AND dn.nspname <> 'taxonomy'
    ) THEN
        RAISE EXCEPTION 'FAIL: existe FK cross-context saliente de taxonomy';
    END IF;

    FOR fk IN
        SELECT c.*, t.relname AS tabla_origen
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = 'taxonomy'
          AND c.contype = 'f'
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM pg_index i
            WHERE i.indrelid = fk.conrelid
              AND i.indisvalid
              AND i.indpred IS NULL
              AND i.indexprs IS NULL
              AND ARRAY(
                  SELECT k
                  FROM unnest(i.indkey::smallint[]) WITH ORDINALITY x(k, pos)
                  WHERE pos <= cardinality(fk.conkey)
                  ORDER BY pos
              ) = fk.conkey
        ) THEN
            RAISE EXCEPTION 'FAIL: FK % en taxonomy.% no tiene indice', fk.conname, fk.tabla_origen;
        END IF;
    END LOOP;

    RAISE NOTICE 'Taxonomy metadata PASS';
END
$metadata$;

BEGIN;

DO $fixtures$
DECLARE
    v_cat_root uuid;
    v_cat_child uuid;
    v_cat_inactive uuid;
    v_char_text uuid;
    v_char_list uuid;
    v_char uuid;
    v_type uuid;
    v_ptc uuid;
    v_schema_before bigint;
    v_schema_after bigint;
    v_message_id uuid := gen_random_uuid();
    i integer;
BEGIN
    INSERT INTO taxonomy.categories (nombre, nivel, orden)
    VALUES ('Calzado', 1, 10)
    RETURNING id INTO v_cat_root;

    INSERT INTO taxonomy.categories (nombre, categoria_padre_id, nivel, orden)
    VALUES ('Zapatillas', v_cat_root, 2, 20)
    RETURNING id INTO v_cat_child;

    BEGIN
        INSERT INTO taxonomy.categories (nombre, categoria_padre_id, nivel)
        VALUES ('Running', v_cat_child, 2);
        RAISE EXCEPTION 'FAIL: se permitio padre de nivel 2';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'FAIL:%' THEN RAISE; END IF;
    END;

    INSERT INTO taxonomy.categories (nombre, nivel, estado)
    VALUES ('Archivada', 1, 'INACTIVO')
    RETURNING id INTO v_cat_inactive;

    BEGIN
        INSERT INTO taxonomy.categories (nombre, categoria_padre_id, nivel)
        VALUES ('Hija invalida', v_cat_inactive, 2);
        RAISE EXCEPTION 'FAIL: se permitio padre inactivo';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'FAIL:%' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE taxonomy.categories SET categoria_padre_id = v_cat_child, nivel = 2 WHERE id = v_cat_root;
        RAISE EXCEPTION 'FAIL: se permitio ciclo real de categorias';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'FAIL:%' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE taxonomy.categories SET estado = 'INACTIVO' WHERE id = v_cat_root;
        RAISE EXCEPTION 'FAIL: se permitio desactivar padre con hijos activos';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'FAIL:%' THEN RAISE; END IF;
    END;

    INSERT INTO taxonomy.brands (nombre, pais_origen_iso)
    VALUES ('Nike', 'US');

    BEGIN
        INSERT INTO taxonomy.brands (nombre, pais_origen_iso)
        VALUES ('  NIKE  ', 'PE');
        RAISE EXCEPTION 'FAIL: se permitio marca duplicada por nombre normalizado';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    BEGIN
        INSERT INTO taxonomy.brands (nombre, pais_origen_iso)
        VALUES ('Puma', 'USA');
        RAISE EXCEPTION 'FAIL: se permitio pais ISO alpha-3';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    INSERT INTO taxonomy.characteristics (nombre, tipo)
    VALUES ('Material principal', 'TEXTO')
    RETURNING id INTO v_char_text;

    INSERT INTO taxonomy.characteristics (nombre, tipo)
    VALUES ('Talla', 'LISTA')
    RETURNING id INTO v_char_list;

    BEGIN
        INSERT INTO taxonomy.characteristic_values (caracteristica_id, nombre)
        VALUES (v_char_text, 'Cuero');
        RAISE EXCEPTION 'FAIL: se permitio valor sobre caracteristica TEXTO';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'FAIL:%' THEN RAISE; END IF;
    END;

    FOR i IN 1..50 LOOP
        INSERT INTO taxonomy.characteristic_values (caracteristica_id, nombre)
        VALUES (v_char_list, 'Valor ' || i);
    END LOOP;

    BEGIN
        INSERT INTO taxonomy.characteristic_values (caracteristica_id, nombre)
        VALUES (v_char_list, 'Valor 51');
        RAISE EXCEPTION 'FAIL: se permitio valor LISTA numero 51';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'FAIL:%' THEN RAISE; END IF;
    END;

    INSERT INTO taxonomy.product_types (nombre)
    VALUES ('Calzado deportivo')
    RETURNING id, schema_version INTO v_type, v_schema_before;

    FOR i IN 1..20 LOOP
        INSERT INTO taxonomy.characteristics (nombre, tipo)
        VALUES ('Atributo configurable ' || i, 'TEXTO')
        RETURNING id INTO v_char;

        INSERT INTO taxonomy.product_type_characteristics (tipo_producto_id, caracteristica_id, obligatoria)
        VALUES (v_type, v_char, false);
    END LOOP;

    SELECT schema_version INTO v_schema_after
    FROM taxonomy.product_types
    WHERE id = v_type;

    IF v_schema_after <> v_schema_before + 20 THEN
        RAISE EXCEPTION 'FAIL: schema_version no incremento por cambios confirmados de esquema';
    END IF;

    INSERT INTO taxonomy.characteristics (nombre, tipo)
    VALUES ('Atributo configurable 21', 'TEXTO')
    RETURNING id INTO v_char;

    BEGIN
        INSERT INTO taxonomy.product_type_characteristics (tipo_producto_id, caracteristica_id, obligatoria)
        VALUES (v_type, v_char, false);
        RAISE EXCEPTION 'FAIL: se permitio atributo 21 contra limite configurable 20';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'FAIL:%' THEN RAISE; END IF;
    END;

    SELECT id INTO v_ptc
    FROM taxonomy.product_type_characteristics
    WHERE tipo_producto_id = v_type
    ORDER BY id
    LIMIT 1;

    SELECT schema_version INTO v_schema_before
    FROM taxonomy.product_types
    WHERE id = v_type;

    UPDATE taxonomy.product_type_characteristics
    SET updated_at = updated_at
    WHERE id = v_ptc;

    SELECT schema_version INTO v_schema_after
    FROM taxonomy.product_types
    WHERE id = v_type;

    IF v_schema_after <> v_schema_before THEN
        RAISE EXCEPTION 'FAIL: schema_version incremento con UPDATE que no cambia esquema';
    END IF;

    UPDATE taxonomy.product_type_characteristics
    SET obligatoria = true
    WHERE id = v_ptc;

    SELECT schema_version INTO v_schema_after
    FROM taxonomy.product_types
    WHERE id = v_type;

    IF v_schema_after <> v_schema_before + 1 THEN
        RAISE EXCEPTION 'FAIL: schema_version no incremento al confirmar cambio de obligatoriedad';
    END IF;

    INSERT INTO taxonomy.category_seo (categoria_id, slug, meta_titulo)
    VALUES (v_cat_root, 'calzado-original', 'Calzado');

    UPDATE taxonomy.category_seo
    SET slug = 'calzado-nuevo'
    WHERE categoria_id = v_cat_root;

    IF NOT EXISTS (
        SELECT 1
        FROM taxonomy.slug_history
        WHERE categoria_id = v_cat_root
          AND old_slug = 'calzado-original'
          AND new_slug = 'calzado-nuevo'
    ) THEN
        RAISE EXCEPTION 'FAIL: no se registro slug_history';
    END IF;

    BEGIN
        UPDATE taxonomy.slug_history SET new_slug = 'otro-slug' WHERE categoria_id = v_cat_root;
        RAISE EXCEPTION 'FAIL: slug_history permitio UPDATE';
    EXCEPTION WHEN raise_exception THEN
        IF SQLERRM LIKE 'FAIL:%' THEN RAISE; END IF;
    END;

    INSERT INTO taxonomy.master_deactivation_operations (
        operation_id,
        entity_type,
        entity_id,
        correlation_id
    )
    VALUES (gen_random_uuid(), 'CATEGORY', v_cat_root, gen_random_uuid());

    INSERT INTO taxonomy.outbox (
        message_id,
        event_name,
        kind,
        schema_version,
        correlation_id,
        operation_id,
        occurred_at,
        payload
    )
    VALUES (
        v_message_id,
        'taxonomy.category.updated',
        'event',
        1,
        gen_random_uuid(),
        gen_random_uuid(),
        now(),
        jsonb_build_object('id', v_cat_root, 'nombre', 'Calzado')
    );

    INSERT INTO taxonomy.inbox (
        message_id,
        handler,
        event_name,
        correlation_id,
        payload,
        result
    )
    VALUES (
        v_message_id,
        'taxonomy.master-deactivation-handler',
        'catalog.master.deactivation.checked',
        gen_random_uuid(),
        jsonb_build_object('in_use', false),
        'PROCESSED'
    );

    INSERT INTO taxonomy.inbox (
        message_id,
        handler,
        event_name,
        payload,
        result
    )
    VALUES (
        v_message_id,
        'taxonomy.audit-handler',
        'catalog.master.deactivation.checked',
        '{}',
        'PROCESSED'
    );

    BEGIN
        INSERT INTO taxonomy.inbox (
            message_id,
            handler,
            event_name,
            payload,
            result
        )
        VALUES (
            v_message_id,
            'taxonomy.master-deactivation-handler',
            'catalog.master.deactivation.checked',
            '{}',
            'PROCESSED'
        );
        RAISE EXCEPTION 'FAIL: inbox permitio duplicar (message_id, handler)';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    RAISE NOTICE 'Taxonomy functional validation PASS';
END
$fixtures$;

ROLLBACK;

\echo '====================================================='
\echo ' VALIDACION COMPLETA DE TAXONOMY-SVC: TODOS LOS CHECKS PASS'
\echo '====================================================='
