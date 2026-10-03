-- catalog-svc. Ejecutar con psql -X -v ON_ERROR_STOP=1 -f validation.sql.
-- Seccion 1 solo lee metadatos. Seccion 2 usa fixtures dentro de BEGIN/ROLLBACK.
-- Un error detiene la validacion; no dejar fixtures ni corregir datos comerciales.

DO $metadata$
DECLARE t text; fk record;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'catalog'
                    AND pg_get_userbyid(nspowner) = 'po_catalog_owner') THEN
        RAISE EXCEPTION 'FAIL schema/owner catalog';
    END IF;
    FOREACH t IN ARRAY ARRAY['products','variants','sku_identity','product_images','variant_images',
        'product_attribute_values','variant_attribute_values','product_identifying_characteristics',
        'sku_physical_profiles','activation_checks','master_barriers','outbox','inbox'] LOOP
        IF to_regclass('catalog.' || t) IS NULL THEN RAISE EXCEPTION 'FAIL tabla %', t; END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_attribute a
            ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
            WHERE c.conrelid = to_regclass('catalog.' || t) AND c.contype = 'p'
            AND cardinality(c.conkey) = 1 AND a.attname = 'id' AND a.atttypid = 'uuid'::regtype
            AND c.conname = 'pk_' || t) THEN RAISE EXCEPTION 'FAIL PK %', t; END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_attribute a JOIN pg_attrdef d
            ON d.adrelid = a.attrelid AND d.adnum = a.attnum
            WHERE a.attrelid = to_regclass('catalog.' || t) AND a.attname = 'created_at'
            AND a.atttypid = 'timestamptz'::regtype AND a.attnotnull
            AND pg_get_expr(d.adbin,d.adrelid) = 'now()') THEN
            RAISE EXCEPTION 'FAIL created_at %', t;
        END IF;
        IF t NOT IN ('sku_identity','outbox','inbox') AND NOT EXISTS (
            SELECT 1 FROM pg_trigger WHERE tgrelid = to_regclass('catalog.' || t)
            AND tgname = 'trg_' || t || '_updated_at' AND NOT tgisinternal AND tgenabled = 'O') THEN
            RAISE EXCEPTION 'FAIL updated_at trigger %', t;
        END IF;
    END LOOP;
    IF EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class src ON src.oid = c.conrelid
        JOIN pg_namespace sn ON sn.oid = src.relnamespace
        JOIN pg_class dst ON dst.oid = c.confrelid JOIN pg_namespace dn ON dn.oid = dst.relnamespace
        WHERE c.contype = 'f' AND sn.nspname = 'catalog' AND dn.nspname <> 'catalog') THEN
        RAISE EXCEPTION 'FAIL FK cross-context (incluye auth/public)';
    END IF;
    FOR fk IN SELECT c.* FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace WHERE n.nspname = 'catalog' AND c.contype = 'f' LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_index i WHERE i.indrelid = fk.conrelid AND i.indisvalid
            AND i.indpred IS NULL AND i.indexprs IS NULL AND
            ARRAY(SELECT k FROM unnest(i.indkey::smallint[]) WITH ORDINALITY x(k,pos)
                  WHERE pos <= cardinality(fk.conkey) ORDER BY pos) = fk.conkey) THEN
            RAISE EXCEPTION 'FAIL indice FK %', fk.conname;
        END IF;
    END LOOP;
    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e
        WHERE e.enumtypid = 'catalog.estado_producto'::regtype) IS DISTINCT FROM
        ARRAY['BORRADOR','ACTIVO','INACTIVO']::text[] OR
       (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e
        WHERE e.enumtypid = 'catalog.estado_variante'::regtype) IS DISTINCT FROM
        ARRAY['BORRADOR','ACTIVA','INACTIVA']::text[] THEN RAISE EXCEPTION 'FAIL enums'; END IF;
    IF EXISTS (SELECT 1 FROM pg_attribute a JOIN pg_class t ON t.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace JOIN pg_type ty ON ty.oid = a.atttypid
        JOIN pg_namespace tn ON tn.oid = ty.typnamespace
        WHERE n.nspname = 'catalog' AND t.relkind = 'r' AND a.attnum > 0 AND NOT a.attisdropped
        AND (ty.typname IN ('float4','float8','money','timestamp') OR a.attidentity <> ''
             OR tn.nspname NOT IN ('pg_catalog','catalog'))) THEN
        RAISE EXCEPTION 'FAIL tipos/identidad/dependencia de tipos externa';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_class t JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = 'catalog' AND t.relkind = 'r' AND t.relrowsecurity) THEN
        RAISE EXCEPTION 'FAIL RLS en schema interno de escritura';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_namespace n CROSS JOIN LATERAL aclexplode(
        coalesce(n.nspacl, acldefault('n',n.nspowner))) a
        WHERE n.nspname = 'catalog' AND a.grantee = 0) OR
       EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
        WHERE n.nspname = 'catalog' AND a.grantee = 0) THEN
        RAISE EXCEPTION 'FAIL acceso PUBLIC a schema/funciones';
    END IF;
    IF has_schema_privilege('catalog_app','catalog','CREATE') OR
       NOT has_schema_privilege('catalog_app','catalog','USAGE') OR
       pg_has_role('catalog_app','po_catalog_owner','MEMBER') OR
       has_table_privilege('catalog_app','catalog.products','DELETE') OR
       has_table_privilege('catalog_app','catalog.variants','TRUNCATE') THEN
        RAISE EXCEPTION 'FAIL privilegios runtime';
    END IF;
    FOREACH t IN ARRAY ARRAY['taxonomy','pricing','price_audit','promotions','combos','inventory','bulk'] LOOP
        IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = t) AND
           has_schema_privilege('catalog_app',t,'USAGE') THEN
            RAISE EXCEPTION 'FAIL runtime tiene USAGE externo %', t;
        END IF;
    END LOOP;
    IF EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace WHERE n.nspname = 'catalog'
        AND t.relname <> 'schema_migrations' AND c.contype IN ('p','u','f','c')
        AND c.conname !~ '^(pk_|uq_|fk_|ck_)') THEN
        RAISE EXCEPTION 'FAIL nombres constraints';
    END IF;
    FOREACH t IN ARRAY ARRAY['ix_variants_product_id','ix_activation_checks_product_id',
        'ix_activation_checks_variant_product','ix_activation_checks_sku','ix_outbox_pending',
        'ix_master_barriers_blocking'] LOOP
        IF to_regclass('catalog.' || t) IS NULL THEN RAISE EXCEPTION 'FAIL indice %', t; END IF;
    END LOOP;
END
$metadata$;
SELECT 'PASS' AS resultado, 'schema, ownership, PK, FK, indices, enums, tipos y permisos' AS comprobacion;

-- Manifest completo de columnas/tipos/nullability y constraints en seccion 3.

BEGIN;
SET LOCAL ROLE catalog_app;
DO $domain$
DECLARE simple uuid = gen_random_uuid(); parent uuid = gen_random_uuid();
    variant uuid = gen_random_uuid(); sid uuid; vid uuid; op uuid = gen_random_uuid();
    msg uuid = gen_random_uuid(); token text = gen_random_uuid()::text;
    base text; child text; version_before bigint;
BEGIN
    base = 'validation-simple-' || token; child = 'validation-variant-' || token;
    INSERT INTO catalog.products(id,nombre,descripcion,categoria_id,tipo_producto_id,marca_id,sku_base,slug,tiene_variantes)
        VALUES(simple,'Simple','Descripcion','cat-external','type-external','brand-external',base,base,false),
        (parent,'Padre','Descripcion','cat-external','type-external','brand-external','parent-'||token,'parent-'||token,true);
    -- Regresion de persistencia: el guard no fija tipo_producto_id como inmutable.
    -- Este UPDATE SQL de fixture no acredita elegibilidad funcional ni habilita
    -- PATCH tipoProductoId: Q-06 y la evidencia de identidad publicada siguen abiertas.
    UPDATE catalog.products SET tipo_producto_id='type-correction-fixture' WHERE id=simple;
    IF NOT EXISTS (SELECT 1 FROM catalog.products WHERE id=simple
        AND tipo_producto_id='type-correction-fixture' AND sku_base=base AND NOT tiene_variantes) THEN
        RAISE EXCEPTION 'FAIL persistencia del tipo conserva bloqueo absoluto o altera identidad';
    END IF;
    UPDATE catalog.products SET tipo_producto_id='type-external' WHERE id=simple;
    SELECT id INTO sid FROM catalog.sku_identity WHERE product_id = simple;
    INSERT INTO catalog.sku_physical_profiles(sku_identity_id,peso_kg) VALUES(sid,0.001);
    SET CONSTRAINTS ALL IMMEDIATE; -- borrador simple con perfil parcial permitido
    SET CONSTRAINTS ALL DEFERRED;
    BEGIN
        UPDATE catalog.sku_physical_profiles SET peso_kg = 0 WHERE sku_identity_id = sid;
        RAISE EXCEPTION 'FAIL peso cero aceptado';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN
        INSERT INTO catalog.sku_physical_profiles(sku_identity_id,peso_kg)
            SELECT id,1 FROM catalog.sku_identity WHERE product_id = parent;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL perfil padre aceptado';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN
        UPDATE catalog.products SET estado='ACTIVO' WHERE id=simple;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL simple incompleto activado';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN
        INSERT INTO catalog.variants(product_id,sku,identifying_key)
            VALUES(parent,base,'{"talla":{"valor_id":"M"}}');
        RAISE EXCEPTION 'FAIL colision variante/base aceptada';
    EXCEPTION WHEN unique_violation THEN NULL; END;
    INSERT INTO catalog.variants(id,product_id,sku,identifying_key)
        VALUES(variant,parent,child,'{"talla":{"valor_id":"M"}}');
    INSERT INTO catalog.variant_attribute_values(variant_id,caracteristica_id,nombre_snapshot,valor_id,valor,es_identificador)
        VALUES(variant,'talla','Talla','M','"M"',true);
    INSERT INTO catalog.variant_images(variant_id,url) VALUES(variant,'https://example.invalid/variant.png');
    SELECT id INTO vid FROM catalog.sku_identity WHERE variant_id=variant;
    INSERT INTO catalog.sku_physical_profiles(sku_identity_id,peso_kg,largo_cm,ancho_cm,alto_cm)
        VALUES(vid,0.5,20,10,5);
    INSERT INTO catalog.activation_checks(product_id,variant_id,sku,dependency,operation_id,correlation_id,request_payload)
        VALUES(parent,variant,child,'INVENTORY',op,gen_random_uuid(),jsonb_build_object('sku',child));
    SET CONSTRAINTS ALL IMMEDIATE;
    SET CONSTRAINTS ALL DEFERRED;
    BEGIN
        UPDATE catalog.variants SET estado='ACTIVA' WHERE id=variant;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL requested tratado como completed';
    EXCEPTION WHEN check_violation THEN NULL; END;
    UPDATE catalog.activation_checks SET state='REJECTED',result_message_id=msg,result_payload='{}' WHERE operation_id=op;
    UPDATE catalog.activation_checks SET state='PENDING' WHERE operation_id=op;
    IF (SELECT count(*) FROM catalog.activation_checks WHERE operation_id=op) <> 1 THEN
        RAISE EXCEPTION 'FAIL retry duplicado';
    END IF;
    BEGIN
        UPDATE catalog.activation_checks SET request_payload='{"sku":"otro"}' WHERE operation_id=op;
        RAISE EXCEPTION 'FAIL cambio intencion aceptado';
    EXCEPTION WHEN check_violation THEN NULL; END;
    UPDATE catalog.activation_checks SET state='COMPLETED',result_message_id=msg,result_payload='{}' WHERE operation_id=op;
    UPDATE catalog.variants SET estado='ACTIVA' WHERE id=variant;
    SET CONSTRAINTS ALL IMMEDIATE; -- hijo ACTIVA con padre BORRADOR permitido
    SET CONSTRAINTS ALL DEFERRED;
    IF (SELECT estado FROM catalog.products WHERE id=parent) <> 'BORRADOR' THEN
        RAISE EXCEPTION 'FAIL hijo activo activa padre';
    END IF;
    BEGIN
        UPDATE catalog.activation_checks SET state='PENDING' WHERE operation_id=op;
        RAISE EXCEPTION 'FAIL reinicializacion completed';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN
        INSERT INTO catalog.variants(product_id,sku,identifying_key)
            VALUES(parent,'duplicate-'||token,'{"talla":{"valor_id":"M"}}');
        RAISE EXCEPTION 'FAIL combinacion duplicada';
    EXCEPTION WHEN unique_violation THEN NULL; END;
    BEGIN
        INSERT INTO catalog.variants(product_id,sku,identifying_key)
            VALUES(simple,'invalid-simple-'||token,'{"talla":{"valor_id":"L"}}');
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL simple admite variantes';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN
        UPDATE catalog.variants SET sku='recoded-'||token WHERE id=variant;
        RAISE EXCEPTION 'FAIL SKU recodificado';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN
        UPDATE catalog.variant_attribute_values SET valor_id='L' WHERE variant_id=variant;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL identificadores editados';
    EXCEPTION WHEN check_violation THEN NULL; END;
    INSERT INTO catalog.product_images(product_id,url)
        VALUES(simple,'https://example.invalid/simple.png'),(parent,'https://example.invalid/parent.png');
    UPDATE catalog.sku_physical_profiles SET largo_cm=30,ancho_cm=20,alto_cm=1 WHERE sku_identity_id=sid;
    INSERT INTO catalog.activation_checks(product_id,sku,dependency,operation_id,correlation_id,request_payload,state,result_message_id,result_payload)
        VALUES(simple,base,'PRICING',gen_random_uuid(),gen_random_uuid(),'{}','COMPLETED',gen_random_uuid(),'{}'),
              (simple,base,'INVENTORY',gen_random_uuid(),gen_random_uuid(),'{}','COMPLETED',gen_random_uuid(),'{}'),
              (parent,'parent-'||token,'PRICING',gen_random_uuid(),gen_random_uuid(),'{}','COMPLETED',gen_random_uuid(),'{}');
    UPDATE catalog.products SET estado='ACTIVO' WHERE id IN (simple,parent);
    SET CONSTRAINTS ALL IMMEDIATE;
    SET CONSTRAINTS ALL DEFERRED;
    SELECT catalog_version INTO version_before FROM catalog.products WHERE id=simple;
    BEGIN
        UPDATE catalog.products SET nombre='Cambio rechazado' WHERE id=simple;
        DELETE FROM catalog.product_images WHERE product_id=simple;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL edicion activa invalida aceptada';
    EXCEPTION WHEN check_violation THEN NULL; END;
    IF (SELECT nombre FROM catalog.products WHERE id=simple) <> 'Simple' OR
       (SELECT catalog_version FROM catalog.products WHERE id=simple) <> version_before THEN
        RAISE EXCEPTION 'FAIL edicion rechazada no atomica';
    END IF;
    BEGIN
        UPDATE catalog.sku_physical_profiles SET peso_kg=NULL WHERE sku_identity_id=vid;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL variante activa pierde perfil';
    EXCEPTION WHEN check_violation THEN NULL; END;
    -- Reemplazo completo en una transaccion permitido.
    DELETE FROM catalog.product_images WHERE product_id=simple;
    INSERT INTO catalog.product_images(product_id,url) VALUES(simple,'https://example.invalid/new.png');
    SET CONSTRAINTS ALL IMMEDIATE;
    SET CONSTRAINTS ALL DEFERRED;
    BEGIN
        UPDATE catalog.variants SET estado='INACTIVA' WHERE id=variant;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL padre activo sin variante activa';
    EXCEPTION WHEN check_violation THEN NULL; END;
    UPDATE catalog.products SET estado='INACTIVO' WHERE id=parent;
    SET CONSTRAINTS ALL IMMEDIATE;
    SET CONSTRAINTS ALL DEFERRED;
    IF (SELECT estado FROM catalog.variants WHERE id=variant) <> 'ACTIVA' THEN
        RAISE EXCEPTION 'FAIL baja padre cambia estado hijo';
    END IF;
    UPDATE catalog.products SET estado='ACTIVO' WHERE id=parent;
    UPDATE catalog.variants SET estado='INACTIVA' WHERE id=variant;
    UPDATE catalog.products SET estado='INACTIVO' WHERE id=parent;
    INSERT INTO catalog.outbox(message_id,event_name,kind,correlation_id,occurred_at,payload)
        VALUES(gen_random_uuid(),'catalog.sku.deactivated','event',gen_random_uuid(),now(),jsonb_build_object('sku',child)),
              (gen_random_uuid(),'catalog.product.deactivated','event',gen_random_uuid(),now(),jsonb_build_object('product_id',parent));
    SET CONSTRAINTS ALL IMMEDIATE;
    SET CONSTRAINTS ALL DEFERRED;
    BEGIN
        INSERT INTO catalog.variants(product_id,sku,identifying_key)
            VALUES(parent,'inactive-duplicate-'||token,'{"talla":{"valor_id":"M"}}');
        RAISE EXCEPTION 'FAIL combinacion inactiva reutilizada';
    EXCEPTION WHEN unique_violation THEN NULL; END;
    BEGIN
        UPDATE catalog.products SET estado='ACTIVO' WHERE id=parent;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'FAIL padre reactiva automaticamente hijo inactivo';
    EXCEPTION WHEN check_violation THEN NULL; END;
    UPDATE catalog.variants SET estado='ACTIVA' WHERE id=variant;
    SET CONSTRAINTS ALL IMMEDIATE;
    SET CONSTRAINTS ALL DEFERRED;
    IF (SELECT estado FROM catalog.products WHERE id=parent) <> 'INACTIVO' THEN
        RAISE EXCEPTION 'FAIL reactivar hijo reactiva padre';
    END IF;
    UPDATE catalog.products SET estado='ACTIVO' WHERE id=parent;
    INSERT INTO catalog.inbox(message_id,handler,event_name,payload,result)
        VALUES(msg,'inventory-init','inventory.sku.initialization.completed','{}','COMPLETED');
    INSERT INTO catalog.inbox(message_id,handler,event_name,payload,result)
        VALUES(msg,'inventory-init','inventory.sku.initialization.completed','{}','COMPLETED')
        ON CONFLICT (message_id,handler) DO NOTHING;
    IF (SELECT count(*) FROM catalog.inbox WHERE message_id=msg AND handler='inventory-init') <> 1 THEN
        RAISE EXCEPTION 'FAIL deduplicacion inbox';
    END IF;
    INSERT INTO catalog.inbox(message_id,handler,event_name,payload,result)
        VALUES(msg,'other-handler','inventory.sku.initialization.completed','{}','COMPLETED');
    BEGIN
        INSERT INTO catalog.outbox(message_id,event_name,kind,correlation_id,occurred_at,payload)
            VALUES(msg,'catalog.sku.deactivated','event',gen_random_uuid(),now(),'{}');
        INSERT INTO catalog.outbox(message_id,event_name,kind,correlation_id,occurred_at,payload)
            VALUES(msg,'catalog.sku.deactivated','event',gen_random_uuid(),now(),'{}');
        RAISE EXCEPTION 'FAIL message_id outbox duplicado';
    EXCEPTION WHEN unique_violation THEN NULL; END;
    BEGIN
        INSERT INTO catalog.activation_checks(product_id,sku,dependency,operation_id,correlation_id,request_payload)
            VALUES(parent,'parent-'||token,'INVENTORY',gen_random_uuid(),gen_random_uuid(),'{}');
        RAISE EXCEPTION 'FAIL padre con saldo inicializado';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN
        UPDATE catalog.products SET sku_base='recoded-base-'||token WHERE id=simple;
        RAISE EXCEPTION 'FAIL sku_base recodificado';
    EXCEPTION WHEN check_violation THEN NULL; END;
    BEGIN
        DELETE FROM catalog.products WHERE id=simple;
        RAISE EXCEPTION 'FAIL runtime borra producto';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    SET CONSTRAINTS ALL IMMEDIATE;
END
$domain$;
SELECT 'PASS' AS resultado, 'borrador, perfil, unicidad, activacion, edicion atomica, bajas, retry y mensajeria (fixtures temporales)' AS comprobacion;
ROLLBACK;

-- SECCION 3: manifest completo de columnas/tipos/nullability y constraints.
DO $manifest$
DECLARE failures bigint;
BEGIN
 SELECT count(*) INTO failures FROM (VALUES
 ('products','id','uuid',true),
 ('products','nombre','text',true),
 ('products','descripcion','text',true),
 ('products','categoria_id','text',true),
 ('products','tipo_producto_id','text',true),
 ('products','marca_id','text',true),
 ('products','sku_base','text',true),
 ('products','slug','text',true),
 ('products','tiene_variantes','boolean',true),
 ('products','estado','catalog.estado_producto',true),
 ('products','catalog_version','bigint',true),
 ('products','created_at','timestamptz',true),
 ('products','updated_at','timestamptz',true),
 ('variants','id','uuid',true),
 ('variants','product_id','uuid',true),
 ('variants','sku','text',true),
 ('variants','identifying_key','jsonb',true),
 ('variants','estado','catalog.estado_variante',true),
 ('variants','catalog_version','bigint',true),
 ('variants','created_at','timestamptz',true),
 ('variants','updated_at','timestamptz',true),
 ('sku_identity','id','uuid',true),
 ('sku_identity','sku','text',true),
 ('sku_identity','product_id','uuid',false),
 ('sku_identity','variant_id','uuid',false),
 ('sku_identity','created_at','timestamptz',true),
 ('product_images','id','uuid',true),
 ('product_images','product_id','uuid',true),
 ('product_images','url','text',true),
 ('product_images','principal','boolean',true),
 ('product_images','posicion','integer',true),
 ('product_images','created_at','timestamptz',true),
 ('product_images','updated_at','timestamptz',true),
 ('variant_images','id','uuid',true),
 ('variant_images','variant_id','uuid',true),
 ('variant_images','url','text',true),
 ('variant_images','posicion','integer',true),
 ('variant_images','created_at','timestamptz',true),
 ('variant_images','updated_at','timestamptz',true),
 ('product_attribute_values','id','uuid',true),
 ('product_attribute_values','product_id','uuid',true),
 ('product_attribute_values','caracteristica_id','text',true),
 ('product_attribute_values','nombre_snapshot','text',true),
 ('product_attribute_values','valor_id','text',false),
 ('product_attribute_values','valor','jsonb',true),
 ('product_attribute_values','created_at','timestamptz',true),
 ('product_attribute_values','updated_at','timestamptz',true),
 ('variant_attribute_values','id','uuid',true),
 ('variant_attribute_values','variant_id','uuid',true),
 ('variant_attribute_values','caracteristica_id','text',true),
 ('variant_attribute_values','nombre_snapshot','text',true),
 ('variant_attribute_values','valor_id','text',false),
 ('variant_attribute_values','valor','jsonb',true),
 ('variant_attribute_values','es_identificador','boolean',true),
 ('variant_attribute_values','created_at','timestamptz',true),
 ('variant_attribute_values','updated_at','timestamptz',true),
 ('product_identifying_characteristics','id','uuid',true),
 ('product_identifying_characteristics','product_id','uuid',true),
 ('product_identifying_characteristics','caracteristica_id','text',true),
 ('product_identifying_characteristics','created_at','timestamptz',true),
 ('product_identifying_characteristics','updated_at','timestamptz',true),
 ('sku_physical_profiles','id','uuid',true),
 ('sku_physical_profiles','sku_identity_id','uuid',true),
 ('sku_physical_profiles','peso_kg','numeric',false),
 ('sku_physical_profiles','largo_cm','numeric',false),
 ('sku_physical_profiles','ancho_cm','numeric',false),
 ('sku_physical_profiles','alto_cm','numeric',false),
 ('sku_physical_profiles','created_at','timestamptz',true),
 ('sku_physical_profiles','updated_at','timestamptz',true),
 ('activation_checks','id','uuid',true),
 ('activation_checks','product_id','uuid',true),
 ('activation_checks','variant_id','uuid',false),
 ('activation_checks','sku','text',true),
 ('activation_checks','dependency','text',true),
 ('activation_checks','operation_id','uuid',true),
 ('activation_checks','correlation_id','uuid',true),
 ('activation_checks','request_payload','jsonb',true),
 ('activation_checks','state','text',true),
 ('activation_checks','result_payload','jsonb',false),
 ('activation_checks','result_message_id','uuid',false),
 ('activation_checks','created_at','timestamptz',true),
 ('activation_checks','updated_at','timestamptz',true),
 ('master_barriers','id','uuid',true),
 ('master_barriers','master_type','text',true),
 ('master_barriers','master_id','text',true),
 ('master_barriers','operation_id','uuid',true),
 ('master_barriers','is_blocking','boolean',true),
 ('master_barriers','source_version','bigint',false),
 ('master_barriers','payload','jsonb',true),
 ('master_barriers','created_at','timestamptz',true),
 ('master_barriers','updated_at','timestamptz',true),
 ('outbox','id','uuid',true),
 ('outbox','message_id','uuid',true),
 ('outbox','event_name','text',true),
 ('outbox','kind','text',true),
 ('outbox','schema_version','integer',true),
 ('outbox','correlation_id','uuid',true),
 ('outbox','causation_id','uuid',false),
 ('outbox','operation_id','uuid',false),
 ('outbox','occurred_at','timestamptz',true),
 ('outbox','payload','jsonb',true),
 ('outbox','published_at','timestamptz',false),
 ('outbox','attempts','integer',true),
 ('outbox','last_error','text',false),
 ('outbox','created_at','timestamptz',true),
 ('inbox','id','uuid',true),
 ('inbox','message_id','uuid',true),
 ('inbox','handler','text',true),
 ('inbox','event_name','text',true),
 ('inbox','correlation_id','uuid',false),
 ('inbox','operation_id','uuid',false),
 ('inbox','payload','jsonb',true),
 ('inbox','result','text',true),
 ('inbox','processed_at','timestamptz',true),
 ('inbox','created_at','timestamptz',true)
 ) expected(table_name,column_name,type_name,not_null)
 LEFT JOIN pg_namespace n ON n.nspname='catalog'
 LEFT JOIN pg_class t ON t.relnamespace=n.oid AND t.relname=expected.table_name
 LEFT JOIN pg_attribute a ON a.attrelid=t.oid AND a.attname=expected.column_name AND NOT a.attisdropped
 WHERE a.attnum IS NULL OR format_type(a.atttypid,a.atttypmod) <>
       CASE WHEN expected.type_name = 'timestamptz' THEN 'timestamp with time zone' ELSE expected.type_name END
       OR a.attnotnull IS DISTINCT FROM expected.not_null;
 IF failures > 0 THEN RAISE EXCEPTION 'FAIL manifest columnas: %', failures; END IF;
 SELECT count(*) INTO failures FROM (VALUES
 ('products','pk_products','p'),
 ('products','uq_products_sku_base','u'),
 ('products','uq_products_slug','u'),
 ('products','ck_products_minimos','c'),
 ('products','ck_products_version','c'),
 ('variants','pk_variants','p'),
 ('variants','fk_variants_product_id','f'),
 ('variants','uq_variants_sku','u'),
 ('variants','uq_variants_product_combination','u'),
 ('variants','uq_variants_id_product','u'),
 ('variants','ck_variants_sku','c'),
 ('variants','ck_variants_identifying_key','c'),
 ('variants','ck_variants_version','c'),
 ('sku_identity','pk_sku_identity','p'),
 ('sku_identity','uq_sku_identity_sku','u'),
 ('sku_identity','uq_sku_identity_product','u'),
 ('sku_identity','uq_sku_identity_variant','u'),
 ('sku_identity','fk_sku_identity_product_id','f'),
 ('sku_identity','fk_sku_identity_variant_id','f'),
 ('sku_identity','ck_sku_identity_owner','c'),
 ('product_images','pk_product_images','p'),
 ('product_images','fk_product_images_product_id','f'),
 ('product_images','ck_product_images_url','c'),
 ('product_images','ck_product_images_posicion','c'),
 ('variant_images','pk_variant_images','p'),
 ('variant_images','fk_variant_images_variant_id','f'),
 ('variant_images','ck_variant_images_url','c'),
 ('variant_images','ck_variant_images_posicion','c'),
 ('product_attribute_values','pk_product_attribute_values','p'),
 ('product_attribute_values','fk_product_attribute_values_product_id','f'),
 ('product_attribute_values','uq_product_attribute_values_characteristic','u'),
 ('variant_attribute_values','pk_variant_attribute_values','p'),
 ('variant_attribute_values','fk_variant_attribute_values_variant_id','f'),
 ('variant_attribute_values','uq_variant_attribute_values_characteristic','u'),
 ('product_identifying_characteristics','pk_product_identifying_characteristics','p'),
 ('product_identifying_characteristics','fk_product_identifying_characteristics_product_id','f'),
 ('product_identifying_characteristics','uq_product_identifying_characteristics_ref','u'),
 ('sku_physical_profiles','pk_sku_physical_profiles','p'),
 ('sku_physical_profiles','uq_sku_physical_profiles_identity','u'),
 ('sku_physical_profiles','fk_sku_physical_profiles_sku_identity_id','f'),
 ('sku_physical_profiles','ck_sku_physical_profiles_positive','c'),
 ('activation_checks','pk_activation_checks','p'),
 ('activation_checks','fk_activation_checks_product_id','f'),
 ('activation_checks','fk_activation_checks_variant_product','f'),
 ('activation_checks','fk_activation_checks_sku','f'),
 ('activation_checks','uq_activation_checks_operation','u'),
 ('activation_checks','uq_activation_checks_dependency_sku','u'),
 ('activation_checks','ck_activation_checks_dependency','c'),
 ('activation_checks','ck_activation_checks_state','c'),
 ('activation_checks','ck_activation_checks_request','c'),
 ('activation_checks','ck_activation_checks_result','c'),
 ('master_barriers','pk_master_barriers','p'),
 ('master_barriers','uq_master_barriers_operation','u'),
 ('master_barriers','ck_master_barriers_version','c'),
 ('outbox','pk_outbox','p'),
 ('outbox','uq_outbox_message_id','u'),
 ('outbox','ck_outbox_kind','c'),
 ('outbox','ck_outbox_attempts','c'),
 ('inbox','pk_inbox','p'),
 ('inbox','uq_inbox_message_handler','u')
 ) expected(table_name,constraint_name,constraint_type)
 LEFT JOIN pg_namespace n ON n.nspname='catalog'
 LEFT JOIN pg_class t ON t.relnamespace=n.oid AND t.relname=expected.table_name
 LEFT JOIN pg_constraint c ON c.conrelid=t.oid AND c.conname=expected.constraint_name
 WHERE c.oid IS NULL OR c.contype::text <> expected.constraint_type;
 IF failures > 0 THEN RAISE EXCEPTION 'FAIL manifest constraints: %', failures; END IF;
END
$manifest$;
SELECT 'PASS' AS resultado, 'manifest completo de columnas/tipos/nullability y constraints' AS comprobacion;
