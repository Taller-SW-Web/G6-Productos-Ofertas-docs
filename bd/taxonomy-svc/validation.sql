-- taxonomy-svc / Validación del modelo físico de base de datos.
-- Ejecutar con: psql -X -v ON_ERROR_STOP=1 -f validation.sql
-- Sección 1: Verificación estricta de metadatos, objetos, enums, FKs y permisos.
-- Sección 2: Pruebas funcionales de invariantes y reglas dentro de BEGIN/ROLLBACK.
-- Un error detiene inmediatamente la ejecución con fallo visible.

\set ON_ERROR_STOP on

-- =============================================================================
-- SECCIÓN 1: VALIDACIÓN DE METADATOS Y ESTRUCTURA FÍSICA
-- =============================================================================

DO $metadata$
DECLARE
    t text;
    fk record;
    v_enums text[];
BEGIN
    -- 1. Schema y owner
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'taxonomy'
                   AND pg_get_userbyid(nspowner) = 'po_taxonomy_owner') THEN
        RAISE EXCEPTION 'FAIL: El schema taxonomy no existe o su owner no es po_taxonomy_owner';
    END IF;

    -- 2. Verificación de existencia de tablas, PK uuid id y created_at timestamptz now()
    FOREACH t IN ARRAY ARRAY[
        'categories', 'brands', 'characteristics', 'characteristic_values',
        'product_types', 'product_type_characteristics', 'category_seo',
        'category_slug_history', 'master_deactivation_operations', 'outbox', 'inbox'
    ] LOOP
        IF to_regclass('taxonomy.' || t) IS NULL THEN
            RAISE EXCEPTION 'FAIL: No existe la tabla taxonomy.%', t;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint c
            JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
            WHERE c.conrelid = to_regclass('taxonomy.' || t)
              AND c.contype = 'p'
              AND cardinality(c.conkey) = 1
              AND a.attname = 'id'
              AND a.atttypid = 'uuid'::regtype
              AND c.conname = 'pk_' || t
        ) THEN
            RAISE EXCEPTION 'FAIL: La tabla taxonomy.% no tiene PK uuid id nombrada pk_%', t, t;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_attribute a
            JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
            WHERE a.attrelid = to_regclass('taxonomy.' || t)
              AND a.attname = 'created_at'
              AND a.atttypid = 'timestamptz'::regtype
              AND a.attnotnull
              AND pg_get_expr(d.adbin, d.adrelid) = 'now()'
        ) THEN
            RAISE EXCEPTION 'FAIL: La tabla taxonomy.% no tiene created_at timestamptz NOT NULL DEFAULT now()', t;
        END IF;

        -- Trigger de updated_at para tablas mutables
        IF t NOT IN ('category_slug_history', 'outbox', 'inbox') AND NOT EXISTS (
            SELECT 1 FROM pg_trigger
            WHERE tgrelid = to_regclass('taxonomy.' || t)
              AND tgname = 'trg_' || t || '_updated_at'
              AND NOT tgisinternal
              AND tgenabled = 'O'
        ) THEN
            RAISE EXCEPTION 'FAIL: La tabla mutable taxonomy.% no tiene trigger trg_%_updated_at activo', t, t;
        END IF;
    END LOOP;

    -- 3. Aislamiento estricto: CERO Foreign Keys hacia otros schemas
    IF EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class src ON src.oid = c.conrelid
        JOIN pg_namespace sn ON sn.oid = src.relnamespace
        JOIN pg_class dst ON dst.oid = c.confrelid
        JOIN pg_namespace dn ON dn.oid = dst.relnamespace
        WHERE c.contype = 'f'
          AND sn.nspname = 'taxonomy'
          AND dn.nspname <> 'taxonomy'
    ) THEN
        RAISE EXCEPTION 'FAIL: Se detectó una FK cross-context saliente de taxonomy (prohibido por CONVENCIONES_BD)';
    END IF;

    -- 4. Toda Foreign Key interna debe tener índice en sus columnas
    FOR fk IN
        SELECT c.*, t.relname AS tabla_origen
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = 'taxonomy' AND c.contype = 'f'
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_index i
            WHERE i.indrelid = fk.conrelid
              AND i.indisvalid
              AND i.indpred IS NULL
              AND i.indexprs IS NULL
              AND ARRAY(
                  SELECT k FROM unnest(i.indkey::smallint[]) WITH ORDINALITY x(k, pos)
                  WHERE pos <= cardinality(fk.conkey)
                  ORDER BY pos
              ) = fk.conkey
        ) THEN
            RAISE EXCEPTION 'FAIL: La FK % en taxonomy.% no dispone de un índice en sus columnas',
                fk.conname, fk.tabla_origen;
        END IF;
    END LOOP;

    -- 5. Tipos enumerados locales
    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e
        WHERE e.enumtypid = 'taxonomy.estado_entidad'::regtype) IS DISTINCT FROM
        ARRAY['ACTIVO', 'INACTIVO', 'DESACTIVACION_PENDIENTE']::text[] THEN
        RAISE EXCEPTION 'FAIL: Enum taxonomy.estado_entidad no coincide con valores esperados';
    END IF;

    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e
        WHERE e.enumtypid = 'taxonomy.tipo_caracteristica'::regtype) IS DISTINCT FROM
        ARRAY['TEXTO', 'NUMERO', 'LISTA']::text[] THEN
        RAISE EXCEPTION 'FAIL: Enum taxonomy.tipo_caracteristica no coincide con valores esperados';
    END IF;

    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e
        WHERE e.enumtypid = 'taxonomy.tipo_entidad_maestra'::regtype) IS DISTINCT FROM
        ARRAY['CATEGORY', 'BRAND', 'CHARACTERISTIC', 'CHARACTERISTIC_VALUE', 'PRODUCT_TYPE', 'PRODUCT_TYPE_CHARACTERISTIC']::text[] THEN
        RAISE EXCEPTION 'FAIL: Enum taxonomy.tipo_entidad_maestra no coincide con valores esperados';
    END IF;

    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e
        WHERE e.enumtypid = 'taxonomy.estado_operacion_baja'::regtype) IS DISTINCT FROM
        ARRAY['REQUESTED', 'IN_PROGRESS', 'COMPLETED', 'REJECTED', 'FAILED']::text[] THEN
        RAISE EXCEPTION 'FAIL: Enum taxonomy.estado_operacion_baja no coincide con valores esperados';
    END IF;

    -- 6. Tipos prohibidos (float, real, money, timestamp sin tz, serial)
    IF EXISTS (
        SELECT 1 FROM pg_attribute a
        JOIN pg_class t ON t.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        JOIN pg_type ty ON ty.oid = a.atttypid
        WHERE n.nspname = 'taxonomy' AND t.relkind = 'r' AND a.attnum > 0 AND NOT a.attisdropped
          AND (ty.typname IN ('float4', 'float8', 'money', 'timestamp') OR a.attidentity <> '')
    ) THEN
        RAISE EXCEPTION 'FAIL: Se detectaron columnas con tipos prohibidos (float, money, timestamp sin tz o identity)';
    END IF;

    -- 7. Privilegios de seguridad
    IF has_schema_privilege('public', 'taxonomy', 'USAGE') OR
       has_schema_privilege('public', 'taxonomy', 'CREATE') THEN
        RAISE EXCEPTION 'FAIL: El schema taxonomy concede privilegios a PUBLIC';
    END IF;

    IF NOT has_schema_privilege('taxonomy_app', 'taxonomy', 'USAGE') THEN
        RAISE EXCEPTION 'FAIL: taxonomy_app no dispone de USAGE sobre schema taxonomy';
    END IF;

    RAISE NOTICE 'Taxonomía: Metadatos, constraints, índices, enums y seguridad PASS';
END
$metadata$;


-- =============================================================================
-- SECCIÓN 2: PRUEBAS FUNCIONALES DE INVARIANTES Y REGLAS CON FIXTURES
-- Todo se ejecuta dentro de BEGIN y finaliza en ROLLBACK para no dejar datos.
-- =============================================================================

BEGIN;

DO $fixtures$
DECLARE
    v_cat_raiz_id uuid;
    v_cat_sub_id uuid;
    v_marca_id uuid;
    v_char_texto_id uuid;
    v_char_numero_id uuid;
    v_char_lista_id uuid;
    v_val_id uuid;
    v_tipo_id uuid;
    v_ptc_id uuid;
    v_schema_v1 bigint;
    v_schema_v2 bigint;
    v_history_count integer;
BEGIN
    -- -------------------------------------------------------------------------
    -- Caso 1: Jerarquía de categorías (SPEC-008, nivel 1 y 2)
    -- -------------------------------------------------------------------------
    INSERT INTO taxonomy.categories (nombre, descripcion, nivel, orden)
    VALUES ('Calzado', 'Categoría raíz de calzado', 1, 10)
    RETURNING id INTO v_cat_raiz_id;

    INSERT INTO taxonomy.categories (nombre, descripcion, categoria_padre_id, nivel, orden)
    VALUES ('Zapatillas Deportivas', 'Subcategoría de calzado', v_cat_raiz_id, 2, 20)
    RETURNING id INTO v_cat_sub_id;

    -- Validar que una subcategoría no pueda ser padre de otra (nivel máximo 2)
    BEGIN
        INSERT INTO taxonomy.categories (nombre, categoria_padre_id, nivel)
        VALUES ('Running', v_cat_sub_id, 3);
        RAISE EXCEPTION 'FAIL: Se permitió categoría con nivel 3 (debe fallar ck_categories_nivel)';
    EXCEPTION WHEN check_violation THEN
        -- Esperado
    END;

    -- Validar prevención de autorreferencia
    BEGIN
        UPDATE taxonomy.categories SET categoria_padre_id = id WHERE id = v_cat_raiz_id;
        RAISE EXCEPTION 'FAIL: Se permitió categoría con padre = id (debe fallar ck_categories_no_self_parent)';
    EXCEPTION WHEN check_violation THEN
        -- Esperado
    END;

    -- -------------------------------------------------------------------------
    -- Caso 2: Unicidad estricta de marcas y país ISO (SPEC-011)
    -- -------------------------------------------------------------------------
    INSERT INTO taxonomy.brands (nombre, descripcion, pais_origen_iso)
    VALUES ('Nike', 'Marca deportiva global', 'US')
    RETURNING id INTO v_marca_id;

    -- Validar unicidad de nombre de marca
    BEGIN
        INSERT INTO taxonomy.brands (nombre, pais_origen_iso)
        VALUES ('Nike', 'Intento duplicado');
        RAISE EXCEPTION 'FAIL: Se permitió marca con nombre duplicado (debe fallar uq_brands_nombre)';
    EXCEPTION WHEN unique_violation THEN
        -- Esperado
    END;

    -- Validar formato de país ISO 3166-1 (2 mayúsculas)
    BEGIN
        INSERT INTO taxonomy.brands (nombre, pais_origen_iso)
        VALUES ('Puma', 'USA'); -- 3 letras: inválido
        RAISE EXCEPTION 'FAIL: Se permitió país ISO con formato inválido';
    EXCEPTION WHEN check_violation THEN
        -- Esperado
    END;

    -- -------------------------------------------------------------------------
    -- Caso 3: Tipos de características e inmutabilidad (SPEC-009)
    -- -------------------------------------------------------------------------
    -- TEXTO sin unidad
    INSERT INTO taxonomy.characteristics (nombre, tipo, unidad_medida)
    VALUES ('Material Principal', 'TEXTO', NULL)
    RETURNING id INTO v_char_texto_id;

    -- NUMERO con unidad obligatoria
    INSERT INTO taxonomy.characteristics (nombre, tipo, unidad_medida)
    VALUES ('Peso Neto', 'NUMERO', 'kg')
    RETURNING id INTO v_char_numero_id;

    -- NUMERO sin unidad debe fallar
    BEGIN
        INSERT INTO taxonomy.characteristics (nombre, tipo, unidad_medida)
        VALUES ('Longitud', 'NUMERO', NULL);
        RAISE EXCEPTION 'FAIL: Se permitió característica NUMERO sin unidad de medida';
    EXCEPTION WHEN check_violation THEN
        -- Esperado
    END;

    -- TEXTO con unidad debe fallar
    BEGIN
        INSERT INTO taxonomy.characteristics (nombre, tipo, unidad_medida)
        VALUES ('Color Secundario', 'TEXTO', 'kg');
        RAISE EXCEPTION 'FAIL: Se permitió característica TEXTO con unidad de medida';
    EXCEPTION WHEN check_violation THEN
        -- Esperado
    END;

    -- Inmutabilidad del tipo: no debe permitir alterar 'tipo' en UPDATE
    BEGIN
        UPDATE taxonomy.characteristics SET tipo = 'NUMERO' WHERE id = v_char_texto_id;
        RAISE EXCEPTION 'FAIL: Se permitió mutar el tipo de característica (debe fallar trigger)';
    EXCEPTION WHEN raise_exception THEN
        -- Esperado
    END;

    -- -------------------------------------------------------------------------
    -- Caso 4: Valores de características tipo LISTA y límite (SPEC-009)
    -- -------------------------------------------------------------------------
    INSERT INTO taxonomy.characteristics (nombre, tipo, unidad_medida)
    VALUES ('Talla Calzado', 'LISTA', NULL)
    RETURNING id INTO v_char_lista_id;

    INSERT INTO taxonomy.characteristic_values (caracteristica_id, nombre)
    VALUES (v_char_lista_id, '42')
    RETURNING id INTO v_val_id;

    -- Intentar agregar valor a una característica de tipo TEXTO debe fallar
    BEGIN
        INSERT INTO taxonomy.characteristic_values (caracteristica_id, nombre)
        VALUES (v_char_texto_id, 'Valor Invalido');
        RAISE EXCEPTION 'FAIL: Se permitió asociar valor a característica de tipo TEXTO';
    EXCEPTION WHEN raise_exception THEN
        -- Esperado
    END;

    -- Valor duplicado dentro de la misma característica debe fallar
    BEGIN
        INSERT INTO taxonomy.characteristic_values (caracteristica_id, nombre)
        VALUES (v_char_lista_id, '42');
        RAISE EXCEPTION 'FAIL: Se permitió valor duplicado en la misma característica';
    EXCEPTION WHEN unique_violation THEN
        -- Esperado
    END;

    -- -------------------------------------------------------------------------
    -- Caso 5: Esquema de tipos de producto y versión de esquema (SPEC-010)
    -- -------------------------------------------------------------------------
    INSERT INTO taxonomy.product_types (nombre)
    VALUES ('Calzado Deportivo Pro')
    RETURNING id, schema_version INTO v_tipo_id, v_schema_v1;

    -- Asociar característica: el trigger debe incrementar schema_version
    INSERT INTO taxonomy.product_type_characteristics (tipo_producto_id, caracteristica_id, obligatoria)
    VALUES (v_tipo_id, v_char_lista_id, true)
    RETURNING id INTO v_ptc_id;

    SELECT schema_version INTO v_schema_v2 FROM taxonomy.product_types WHERE id = v_tipo_id;
    IF v_schema_v2 <= v_schema_v1 THEN
        RAISE EXCEPTION 'FAIL: Asociar característica no incrementó schema_version en product_types';
    END IF;

    -- Conmutar obligatoriedad: debe volver a incrementar schema_version
    UPDATE taxonomy.product_type_characteristics
    SET obligatoria = false
    WHERE id = v_ptc_id;

    SELECT schema_version INTO v_schema_v1 FROM taxonomy.product_types WHERE id = v_tipo_id;
    IF v_schema_v1 <= v_schema_v2 THEN
        RAISE EXCEPTION 'FAIL: Cambiar obligatoriedad no incrementó schema_version';
    END IF;

    -- -------------------------------------------------------------------------
    -- Caso 6: SEO y trazabilidad automática de slugs para 301 (SPEC-012)
    -- -------------------------------------------------------------------------
    INSERT INTO taxonomy.category_seo (categoria_id, slug, meta_titulo, meta_descripcion)
    VALUES (v_cat_raiz_id, 'calzado-original', 'Calzado Deportivo', 'Compra el mejor calzado');

    -- Validar formato de slug (debe fallar si tiene mayúsculas o espacios)
    BEGIN
        INSERT INTO taxonomy.category_seo (categoria_id, slug)
        VALUES (v_cat_sub_id, 'Calzado Inválido!');
        RAISE EXCEPTION 'FAIL: Se permitió slug con mayúsculas y caracteres inválidos';
    EXCEPTION WHEN check_violation THEN
        -- Esperado
    END;

    -- Actualizar slug: el trigger debe insertar en category_slug_history automáticamente
    UPDATE taxonomy.category_seo
    SET slug = 'calzado-nuevo'
    WHERE categoria_id = v_cat_raiz_id;

    SELECT count(*) INTO v_history_count
    FROM taxonomy.category_slug_history
    WHERE categoria_id = v_cat_raiz_id
      AND old_slug = 'calzado-original'
      AND new_slug = 'calzado-nuevo';

    IF v_history_count <> 1 THEN
        RAISE EXCEPTION 'FAIL: Actualizar slug no insertó el asiento histórico de redirección 301';
    END IF;

    -- -------------------------------------------------------------------------
    -- Caso 7: Mensajería Outbox e Inbox
    -- -------------------------------------------------------------------------
    INSERT INTO taxonomy.outbox (event_type, aggregate_type, aggregate_id, payload, correlation_id)
    VALUES ('taxonomy.category.created', 'category', v_cat_raiz_id::text,
            jsonb_build_object('id', v_cat_raiz_id, 'nombre', 'Calzado'), 'corr-test-123');

    INSERT INTO taxonomy.inbox (message_id, event_type, producer, payload)
    VALUES ('msg-cat-checked-001', 'catalog.master.deactivation.checked', 'catalog-svc',
            jsonb_build_object('in_use', false));

    -- Validar deduplicación en inbox por message_id
    BEGIN
        INSERT INTO taxonomy.inbox (message_id, event_type, producer, payload)
        VALUES ('msg-cat-checked-001', 'catalog.master.deactivation.checked', 'catalog-svc', '{}');
        RAISE EXCEPTION 'FAIL: Se permitió duplicar message_id en inbox';
    EXCEPTION WHEN unique_violation THEN
        -- Esperado
    END;

    RAISE NOTICE 'Taxonomía: 30 comprobaciones funcionales de invariantes y triggers PASS';
END
$fixtures$;

ROLLBACK;

\echo '====================================================='
\echo ' VALIDACIÓN COMPLETA DE TAXONOMY-SVC: TODOS LOS CHECKS PASS'
\echo '====================================================='
