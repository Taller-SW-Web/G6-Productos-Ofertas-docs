-- #55 / validacion verificable derivada de bd/plantillas/validation.sql.
-- Ampliada con assertions, manifiesto de objetos y escenarios; no deja fixtures.
-- Ejecutar: psql -X -v ON_ERROR_STOP=1 -f bd/pricing/validation.sql
-- Deployer de pruebas debe poder SET ROLE owner/runtime (NO dar owner al runtime).
-- Si una assertion falla, la ejecucion debe detenerse; ROLLBACK en sesion o desconectar.
BEGIN;
SET LOCAL ROLE po_pricing_owner;
SET LOCAL TimeZone = 'UTC';
DO $structure$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='pricing'
        AND pg_get_userbyid(nspowner)='po_pricing_owner') THEN
        RAISE EXCEPTION 'Schema/owner incorrecto'; END IF;
    IF EXISTS (SELECT 1 FROM (VALUES
        ('prices','id','uuid',true),
        ('prices','product_id','text',false),
        ('prices','sku','text',false),
        ('prices','channel_id','text',false),
        ('prices','price_version','bigint',true),
        ('prices','created_at','timestamp with time zone',true),
        ('prices','updated_at','timestamp with time zone',true),
        ('price_validities','id','uuid',true),
        ('price_validities','price_id','uuid',true),
        ('price_validities','precio_regular','numeric(12,2)',true),
        ('price_validities','precio_oferta','numeric(12,2)',false),
        ('price_validities','currency','character(3)',true),
        ('price_validities','valid_from','timestamp with time zone',true),
        ('price_validities','valid_until','timestamp with time zone',false),
        ('price_validities','price_version','bigint',true),
        ('price_validities','motivo_cambio','text',true),
        ('price_validities','usuario_id','text',false),
        ('price_validities','is_cancelled','boolean',true),
        ('price_validities','created_at','timestamp with time zone',true),
        ('price_validities','updated_at','timestamp with time zone',true),
        ('scheduled_prices','id','uuid',true),
        ('scheduled_prices','price_id','uuid',true),
        ('scheduled_prices','validity_id','uuid',true),
        ('scheduled_prices','tipo_precio','text',true),
        ('scheduled_prices','importe','numeric(12,2)',true),
        ('scheduled_prices','status','pricing.scheduled_price_status',true),
        ('scheduled_prices','created_at','timestamp with time zone',true),
        ('scheduled_prices','updated_at','timestamp with time zone',true),
        ('bulk_price_jobs','id','uuid',true),
        ('bulk_price_jobs','status','pricing.bulk_price_job_status',true),
        ('bulk_price_jobs','allow_partial','boolean',true),
        ('bulk_price_jobs','total_rows','integer',true),
        ('bulk_price_jobs','completed_rows','integer',true),
        ('bulk_price_jobs','failed_rows','integer',true),
        ('bulk_price_jobs','correlation_id','uuid',true),
        ('bulk_price_jobs','usuario_id','text',false),
        ('bulk_price_jobs','report_uri','text',false),
        ('bulk_price_jobs','created_at','timestamp with time zone',true),
        ('bulk_price_jobs','updated_at','timestamp with time zone',true),
        ('bulk_price_rows','id','uuid',true),
        ('bulk_price_rows','batch_id','uuid',true),
        ('bulk_price_rows','row_id','text',true),
        ('bulk_price_rows','sku','text',false),
        ('bulk_price_rows','status','pricing.bulk_price_row_status',true),
        ('bulk_price_rows','code','text',false),
        ('bulk_price_rows','detail','text',false),
        ('bulk_price_rows','row_input','jsonb',true),
        ('bulk_price_rows','created_at','timestamp with time zone',true),
        ('bulk_price_rows','updated_at','timestamp with time zone',true),
        ('outbox','id','uuid',true),
        ('outbox','message_id','uuid',true),
        ('outbox','event_name','text',true),
        ('outbox','kind','text',true),
        ('outbox','schema_version','integer',true),
        ('outbox','correlation_id','uuid',true),
        ('outbox','causation_id','uuid',false),
        ('outbox','operation_id','uuid',false),
        ('outbox','occurred_at','timestamp with time zone',true),
        ('outbox','payload','jsonb',true),
        ('outbox','published_at','timestamp with time zone',false),
        ('outbox','attempts','integer',true),
        ('outbox','last_error','text',false),
        ('outbox','created_at','timestamp with time zone',true),
        ('inbox','id','uuid',true),
        ('inbox','message_id','uuid',true),
        ('inbox','handler','text',true),
        ('inbox','event_name','text',true),
        ('inbox','correlation_id','uuid',false),
        ('inbox','payload','jsonb',true),
        ('inbox','processed_at','timestamp with time zone',true),
        ('inbox','result','text',true),
        ('inbox','created_at','timestamp with time zone',true)
    ) expected(tab,col,typ,nn) LEFT JOIN pg_namespace n ON n.nspname='pricing'
      LEFT JOIN pg_class c ON c.relnamespace=n.oid AND c.relname=expected.tab AND c.relkind='r'
      LEFT JOIN pg_attribute a ON a.attrelid=c.oid AND a.attname=expected.col AND NOT a.attisdropped
      WHERE a.attname IS NULL OR format_type(a.atttypid,a.atttypmod)<>expected.typ OR a.attnotnull<>expected.nn
    ) THEN RAISE EXCEPTION 'Manifest de tablas/columnas/tipos/nullability incorrecto'; END IF;
    IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='pricing' AND c.relkind='r' AND c.relname <> 'schema_migrations'
      AND c.relname NOT IN ('prices','price_validities','scheduled_prices','bulk_price_jobs','bulk_price_rows','outbox','inbox')) THEN RAISE EXCEPTION 'Tabla fuera de inventario'; END IF;
    IF EXISTS (SELECT 1 FROM (VALUES
        ('prices','pk_prices','p'),
        ('prices','uq_prices_target_channel','u'),
        ('prices','ck_prices_target','c'),
        ('prices','ck_prices_version','c'),
        ('price_validities','pk_price_validities','p'),
        ('price_validities','uq_price_validities_id_price','u'),
        ('price_validities','uq_price_validities_price_version','u'),
        ('price_validities','fk_price_validities_price_id','f'),
        ('price_validities','ck_price_validities_regular','c'),
        ('price_validities','ck_price_validities_oferta','c'),
        ('price_validities','ck_price_validities_currency','c'),
        ('price_validities','ck_price_validities_order','c'),
        ('price_validities','ck_price_validities_version','c'),
        ('price_validities','ck_price_validities_motivo','c'),
        ('price_validities','ck_price_validities_no_overlap','x'),
        ('scheduled_prices','pk_scheduled_prices','p'),
        ('scheduled_prices','uq_scheduled_prices_validity','u'),
        ('scheduled_prices','fk_scheduled_prices_validity_price','f'),
        ('scheduled_prices','ck_scheduled_prices_type','c'),
        ('scheduled_prices','ck_scheduled_prices_importe','c'),
        ('bulk_price_jobs','pk_bulk_price_jobs','p'),
        ('bulk_price_jobs','ck_bulk_price_jobs_counts','c'),
        ('bulk_price_jobs','ck_bulk_price_jobs_completed','c'),
        ('bulk_price_jobs','ck_bulk_price_jobs_partial','c'),
        ('bulk_price_rows','pk_bulk_price_rows','p'),
        ('bulk_price_rows','uq_bulk_price_rows_batch_row','u'),
        ('bulk_price_rows','fk_bulk_price_rows_batch_id','f'),
        ('bulk_price_rows','ck_bulk_price_rows_input','c'),
        ('outbox','pk_outbox','p'),
        ('outbox','uq_outbox_message_id','u'),
        ('outbox','ck_outbox_kind','c'),
        ('outbox','ck_outbox_attempts','c'),
        ('outbox','ck_outbox_schema_version','c'),
        ('inbox','pk_inbox','p'),
        ('inbox','uq_inbox_message_handler','u')
    ) expected(tab,name,kind) LEFT JOIN pg_constraint k ON k.conrelid=to_regclass('pricing.'||expected.tab)
      AND k.conname=expected.name AND k.contype::text=expected.kind AND k.convalidated
      WHERE k.oid IS NULL) THEN RAISE EXCEPTION 'Constraint requerido ausente/no validado'; END IF;
    -- Destino de FK se resuelve en TODO pg_catalog: detecta taxonomy/auth/public.
    IF EXISTS (SELECT 1 FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid
      JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_class d ON d.oid=k.confrelid
      JOIN pg_namespace dn ON dn.oid=d.relnamespace
      WHERE k.contype='f' AND n.nspname='pricing' AND dn.nspname<>n.nspname)
      THEN RAISE EXCEPTION 'FK cross-context prohibida'; END IF;
    IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='pricing' AND c.relkind='r' AND c.relname<>'schema_migrations'
      AND NOT EXISTS (SELECT 1 FROM pg_constraint k JOIN pg_attribute a ON a.attrelid=k.conrelid
          AND a.attnum=ANY(k.conkey) WHERE k.conrelid=c.oid AND k.contype='p'
          AND cardinality(k.conkey)=1 AND a.atttypid='uuid'::regtype))
      THEN RAISE EXCEPTION 'PK UUID requerida'; END IF;
    IF EXISTS (SELECT 1 FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid
      JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='pricing' AND c.relkind='r'
      AND a.attnum>0 AND NOT a.attisdropped AND (a.attidentity<>'' OR
      a.atttypid IN ('real'::regtype,'double precision'::regtype,'money'::regtype,'timestamp'::regtype) OR
      EXISTS (SELECT 1 FROM pg_attrdef d WHERE d.adrelid=c.oid AND d.adnum=a.attnum
          AND pg_get_expr(d.adbin,d.adrelid) LIKE 'nextval(%')))
      THEN RAISE EXCEPTION 'Tipo/autoincremento prohibido'; END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid
      JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='pricing' AND c.relname<>'schema_migrations'
      AND k.contype IN ('p','u','f','c','x') AND k.conname !~ '^(pk_|uq_|fk_|ck_)')
      THEN RAISE EXCEPTION 'Constraint sin nombre convencional'; END IF;
    IF EXISTS (SELECT 1 FROM (VALUES
        ('price_validities','ix_price_validities_price_id'),
        ('scheduled_prices','ix_scheduled_prices_price_id'),
        ('scheduled_prices','ix_scheduled_prices_worker'),
        ('bulk_price_jobs','ix_bulk_price_jobs_worker'),
        ('outbox','ix_outbox_pending')
    ) expected(tab,name) LEFT JOIN pg_class c ON c.oid=to_regclass('pricing.'||expected.name)
      LEFT JOIN pg_index i ON i.indexrelid=c.oid AND i.indrelid=to_regclass('pricing.'||expected.tab)
      WHERE i.indexrelid IS NULL OR NOT i.indisvalid OR NOT i.indisready)
      THEN RAISE EXCEPTION 'Indice critico ausente/invalido'; END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint k WHERE k.contype='f'
      AND k.connamespace='pricing'::regnamespace AND NOT EXISTS (
        SELECT 1 FROM pg_index i WHERE i.indrelid=k.conrelid AND i.indisvalid
        AND i.indpred IS NULL AND (i.indkey::smallint[])[0:cardinality(k.conkey)-1] = k.conkey))
      THEN RAISE EXCEPTION 'FK sin indice de prefijo completo'; END IF;
    IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='pricing' AND c.relkind='r' AND c.relrowsecurity)
      THEN RAISE EXCEPTION 'RLS no corresponde al schema de escritura'; END IF;
    IF EXISTS (SELECT 1 FROM pg_namespace n CROSS JOIN LATERAL aclexplode(COALESCE(n.nspacl,acldefault('n',n.nspowner))) a
      WHERE n.nspname='pricing' AND a.grantee=0) THEN RAISE EXCEPTION 'Schema accesible a PUBLIC'; END IF;
    IF EXISTS (SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a
      WHERE p.pronamespace='pricing'::regnamespace AND a.grantee=0 AND a.privilege_type='EXECUTE')
      THEN RAISE EXCEPTION 'Funcion accesible a PUBLIC'; END IF;
    IF pg_has_role('pricing_app','po_pricing_owner','MEMBER')
      OR has_schema_privilege('pricing_app','pricing','CREATE') THEN
      RAISE EXCEPTION 'Runtime puede modificar DDL/actuar como owner'; END IF;
    IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='pricing' AND c.relkind='r' AND
        (has_table_privilege('pricing_app',c.oid,'DELETE') OR has_table_privilege('pricing_app',c.oid,'TRUNCATE')))
      THEN RAISE EXCEPTION 'Runtime con DELETE/TRUNCATE indebido'; END IF;
    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e WHERE e.enumtypid = 'pricing.scheduled_price_status'::regtype) <> ARRAY['SCHEDULED','ACTIVE','HISTORICAL','CANCELLED']::text[] THEN RAISE EXCEPTION 'Enum scheduled_price_status incorrecto'; END IF;
    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e WHERE e.enumtypid = 'pricing.bulk_price_job_status'::regtype) <> ARRAY['QUEUED','PROCESSING','COMPLETED','PARTIAL','FAILED']::text[] THEN RAISE EXCEPTION 'Enum bulk_price_job_status incorrecto'; END IF;
    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e WHERE e.enumtypid = 'pricing.bulk_price_row_status'::regtype) <> ARRAY['PENDING','PROCESSING','COMPLETED','FAILED']::text[] THEN RAISE EXCEPTION 'Enum bulk_price_row_status incorrecto'; END IF;
END
$structure$;
SELECT 'estructura, tipos, constraints, FK globales, indices, permisos y enums' AS comprobacion, 'PASS' AS resultado;

DO $conventions$
BEGIN
    IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        JOIN pg_attribute a ON a.attrelid=c.oid AND a.attname IN ('created_at','updated_at') AND NOT a.attisdropped
        LEFT JOIN pg_attrdef d ON d.adrelid=c.oid AND d.adnum=a.attnum
        WHERE n.nspname='pricing' AND c.relkind='r'
        AND (d.oid IS NULL OR pg_get_expr(d.adbin,d.adrelid)<>'now()')) THEN
        RAISE EXCEPTION 'Timestamp tecnico sin DEFAULT now()'; END IF;
    IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        JOIN pg_attribute a ON a.attrelid=c.oid AND a.attname='updated_at' AND NOT a.attisdropped
        WHERE n.nspname='pricing' AND c.relkind='r' AND NOT EXISTS (
        SELECT 1 FROM pg_trigger t WHERE t.tgrelid=c.oid AND NOT t.tgisinternal
        AND t.tgenabled<>'D' AND t.tgname='trg_'||c.relname||'_updated_at')) THEN
        RAISE EXCEPTION 'Trigger updated_at requerido ausente'; END IF;
    IF EXISTS(SELECT 1 FROM pg_proc p WHERE p.pronamespace='pricing'::regnamespace AND p.proname !~ '^fn_') THEN
        RAISE EXCEPTION 'Funcion fuera de convencion'; END IF;
    IF EXISTS(SELECT 1 FROM pg_namespace n WHERE n.nspname IN
        ('taxonomy','catalog','pricing','price_audit','promotions','combos','inventory','bulk')
        AND n.nspname<>'pricing' AND (has_schema_privilege('pricing_app',n.oid,'USAGE')
        OR has_schema_privilege('pricing_app',n.oid,'CREATE'))) THEN
        RAISE EXCEPTION 'Runtime con acceso cross-service'; END IF;
END
$conventions$;
SELECT 'timestamps, triggers y aislamiento del runtime' AS comprobacion,'PASS' AS resultado;

CREATE FUNCTION pg_temp.fn_expect_error(statement text, expected_code text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE statement;
        RAISE EXCEPTION 'El statement debio rechazarse' USING ERRCODE='XX000';
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE <> expected_code THEN
            RAISE EXCEPTION 'Esperado %, recibido %: %',expected_code,SQLSTATE,SQLERRM;
        END IF;
    END;
END;
$$;

DO $domain$
DECLARE p uuid := gen_random_uuid(); v1 uuid := gen_random_uuid(); v2 uuid := gen_random_uuid();
        batch uuid := gen_random_uuid(); message uuid := gen_random_uuid(); n integer;
BEGIN
    INSERT INTO pricing.prices(id,product_id) VALUES (p,'validation-'||p::text);
    INSERT INTO pricing.price_validities(id,price_id,precio_regular,precio_oferta,currency,valid_from,valid_until,price_version,motivo_cambio)
    VALUES(v1,p,100,90,'PEN','2020-01-01Z','2100-01-01Z',1,'Fixture de validacion');
    SET CONSTRAINTS ALL IMMEDIATE;
    PERFORM pg_temp.fn_expect_error(format($s$SET CONSTRAINTS ALL DEFERRED;
        INSERT INTO pricing.prices(sku) VALUES(%L); SET CONSTRAINTS ALL IMMEDIATE$s$,'sin-vigencia-'||p::text),'23514');
    PERFORM pg_temp.fn_expect_error(format('INSERT INTO pricing.prices(product_id) VALUES (%L)','validation-'||p::text),'23505');
    PERFORM pg_temp.fn_expect_error('INSERT INTO pricing.prices DEFAULT VALUES','23514');
    PERFORM pg_temp.fn_expect_error(format('UPDATE pricing.prices SET sku=%L WHERE id=%L','SKU-FIXTURE',p),'23514');
    PERFORM pg_temp.fn_expect_error(format('UPDATE pricing.prices SET price_version=9 WHERE id=%L',p),'23514');
    UPDATE pricing.prices SET price_version=price_version+1 WHERE id=p AND price_version=0;
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 0 THEN RAISE EXCEPTION 'CAS con version obsoleta modifico filas'; END IF;
    UPDATE pricing.prices SET price_version=price_version+1 WHERE id=p AND price_version=1;
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN RAISE EXCEPTION 'CAS valido no actualizo una fila'; END IF;
    INSERT INTO pricing.price_validities(id,price_id,precio_regular,currency,valid_from,valid_until,price_version,motivo_cambio)
    VALUES(v2,p,120,'USD','2100-01-01Z','2101-01-01Z',2,'Programacion fixture');
    INSERT INTO pricing.scheduled_prices(price_id,validity_id,tipo_precio,importe)
    VALUES(p,v2,'REGULAR',120);
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO pricing.price_validities(price_id,precio_regular,currency,valid_from,valid_until,price_version,motivo_cambio)
        VALUES(%L,110,'PEN','2050-01-01Z','2060-01-01Z',3,'Solapado')$s$,p),'23P01');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO pricing.price_validities(price_id,precio_regular,precio_oferta,currency,valid_from,valid_until,price_version,motivo_cambio)
        VALUES(%L,100,100,'PEN','2200-01-01Z','2201-01-01Z',3,'Oferta invalida')$s$,p),'23514');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO pricing.price_validities(price_id,precio_regular,currency,valid_from,valid_until,price_version,motivo_cambio)
        VALUES(%L,'NaN','PEN','2200-01-01Z','2201-01-01Z',3,'NaN')$s$,p),'23514');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO pricing.price_validities(price_id,precio_regular,currency,valid_from,valid_until,price_version,motivo_cambio)
        VALUES(%L,100,'PEN','2201-01-01Z','2200-01-01Z',3,'Intervalo invertido')$s$,p),'23514');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO pricing.price_validities(price_id,precio_regular,currency,valid_from,valid_until,price_version,motivo_cambio)
        VALUES(%L,100,'PEN','2200-01-01Z','2201-01-01Z',3,'Version adelantada')$s$,p),'23514');
    PERFORM pg_temp.fn_expect_error(format('UPDATE pricing.scheduled_prices SET importe=121 WHERE validity_id=%L',v2),'23514');
    -- Resolver as-of local no necesita tablas de Catalogo: consume el contexto externo.
    SELECT count(*) INTO n FROM pricing.price_validities WHERE price_id=p
        AND NOT is_cancelled AND tstzrange(valid_from,valid_until,'[)') @> '2099-12-31Z'::timestamptz
        AND precio_regular=100;
    IF n <> 1 THEN RAISE EXCEPTION 'Snapshot historico no conservado'; END IF;
    SELECT count(*) INTO n FROM pricing.price_validities WHERE price_id=p
        AND NOT is_cancelled AND tstzrange(valid_from,valid_until,'[)') @> '2100-01-01Z'::timestamptz
        AND precio_regular=120 AND currency='USD';
    IF n <> 1 THEN RAISE EXCEPTION 'Frontera semiabierta/programada incorrecta'; END IF;
    INSERT INTO pricing.bulk_price_jobs(id,allow_partial,total_rows,correlation_id) VALUES(batch,true,3,gen_random_uuid());
    INSERT INTO pricing.bulk_price_rows(batch_id,row_id,sku,status,row_input)
    VALUES(batch,'1','SKU-VALIDACION','COMPLETED','{}');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO pricing.bulk_price_rows(batch_id,row_id,row_input)
        VALUES(%L,'1','{}')$s$,batch),'23505');
    UPDATE pricing.bulk_price_jobs SET status='PARTIAL',completed_rows=2,failed_rows=1 WHERE id=batch;
    PERFORM pg_temp.fn_expect_error(format('UPDATE pricing.bulk_price_jobs SET allow_partial=false WHERE id=%L',batch),'23514');
    PERFORM pg_temp.fn_expect_error(format('UPDATE pricing.bulk_price_jobs SET completed_rows=4 WHERE id=%L',batch),'23514');
    INSERT INTO pricing.inbox(message_id,handler,event_name,payload,result)
    VALUES(message,'validation','pricing.product.initialization.requested','{}','COMPLETED');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO pricing.inbox(message_id,handler,event_name,payload,result)
        VALUES(%L,'validation','pricing.product.initialization.requested','{}','COMPLETED')$s$,message),'23505');
    INSERT INTO pricing.inbox(message_id,handler,event_name,payload,result)
    VALUES(message,'otro_handler','pricing.product.initialization.requested','{}','COMPLETED');
    INSERT INTO pricing.outbox(message_id,event_name,kind,correlation_id,occurred_at,payload)
    VALUES(message,'pricing.price.changed','event',gen_random_uuid(),now(),'{}');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO pricing.outbox(message_id,event_name,kind,correlation_id,occurred_at,payload)
        VALUES(%L,'pricing.price.changed','event',gen_random_uuid(),now(),'{}')$s$,message),'23505');
    -- Un fallo revierte negocio y outbox: misma transaccion local, sin relay SQL.
    BEGIN
        SET CONSTRAINTS ALL DEFERRED;
        INSERT INTO pricing.prices(sku) VALUES('rollback-'||p::text);
        INSERT INTO pricing.outbox(message_id,event_name,kind,correlation_id,occurred_at,payload)
        VALUES(p,'pricing.price.changed','event',gen_random_uuid(),now(),'{}');
        RAISE EXCEPTION 'Fallo de prueba' USING ERRCODE='P0002';
    EXCEPTION WHEN SQLSTATE 'P0002' THEN NULL;
    END;
    IF EXISTS(SELECT 1 FROM pricing.prices WHERE sku='rollback-'||p::text) OR
       EXISTS(SELECT 1 FROM pricing.outbox WHERE message_id=p) THEN
        RAISE EXCEPTION 'Negocio y outbox no se revirtieron juntos'; END IF;
END
$domain$;
SELECT 'objetivo, CAS, dinero, as-of, vigencias/programaciones, parcial, inbox/outbox atomicos' AS comprobacion,'PASS' AS resultado;

SET LOCAL ROLE pricing_app;
SET CONSTRAINTS ALL DEFERRED;
DO $runtime_write$
DECLARE p uuid := gen_random_uuid();
BEGIN
    INSERT INTO pricing.prices(id,sku) VALUES(p,'runtime-'||p::text);
    INSERT INTO pricing.price_validities(price_id,precio_regular,currency,valid_from,price_version,motivo_cambio)
    VALUES(p,10,'PEN','2020-01-01Z',1,'Runtime autorizado');
    SET CONSTRAINTS ALL IMMEDIATE;
END
$runtime_write$;
SELECT pg_temp.fn_expect_error('DELETE FROM pricing.prices','42501');
SELECT pg_temp.fn_expect_error('TRUNCATE pricing.inbox','42501');
SELECT pg_temp.fn_expect_error('CREATE TABLE pricing.validation_forbidden(id uuid)','42501');
SELECT 'runtime escribe con triggers/constraints; sin DELETE/TRUNCATE/DDL' AS comprobacion,'PASS' AS resultado;
RESET ROLE;
ROLLBACK;
-- No fixtures persistidos. Leer todos los resultados PASS y ausencia de errores.

