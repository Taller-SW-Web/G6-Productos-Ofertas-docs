-- #56 / validacion verificable derivada de bd/plantillas/validation.sql.
-- Ampliada con assertions, manifiesto de objetos y escenarios; no deja fixtures.
-- Ejecutar: psql -X -v ON_ERROR_STOP=1 -f bd/price_audit/validation.sql
-- Deployer de pruebas debe poder SET ROLE owner/runtime (NO dar owner al runtime).
-- Si una assertion falla, la ejecucion debe detenerse; ROLLBACK en sesion o desconectar.
BEGIN;
SET LOCAL ROLE po_price_audit_owner;
SET LOCAL TimeZone = 'UTC';
DO $structure$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='price_audit'
        AND pg_get_userbyid(nspowner)='po_price_audit_owner') THEN
        RAISE EXCEPTION 'Schema/owner incorrecto'; END IF;
    IF EXISTS (SELECT 1 FROM (VALUES
        ('inbox','id','uuid',true),
        ('inbox','message_id','uuid',true),
        ('inbox','handler','text',true),
        ('inbox','event_name','text',true),
        ('inbox','correlation_id','uuid',false),
        ('inbox','payload','jsonb',true),
        ('inbox','processed_at','timestamp with time zone',true),
        ('inbox','result','text',true),
        ('inbox','created_at','timestamp with time zone',true),
        ('price_audit_log','id_auditoria','uuid',true),
        ('price_audit_log','inbox_id','uuid',true),
        ('price_audit_log','sku','text',true),
        ('price_audit_log','product_id','text',true),
        ('price_audit_log','tipo_precio','text',true),
        ('price_audit_log','precio_anterior','numeric(12,2)',false),
        ('price_audit_log','precio_nuevo','numeric(12,2)',false),
        ('price_audit_log','variacion_porcentual','numeric',false),
        ('price_audit_log','tipo_operacion','text',true),
        ('price_audit_log','canal_origen','text',true),
        ('price_audit_log','motivo_cambio','text',true),
        ('price_audit_log','batch_id','uuid',false),
        ('price_audit_log','usuario_id','text',false),
        ('price_audit_log','usuario_email','text',false),
        ('price_audit_log','ip_origen','text',false),
        ('price_audit_log','timestamp','timestamp with time zone',true),
        ('price_audit_log','created_at','timestamp with time zone',true),
        ('export_jobs','id','uuid',true),
        ('export_jobs','status','price_audit.export_job_status',true),
        ('export_jobs','formato','text',true),
        ('export_jobs','filters','jsonb',true),
        ('export_jobs','record_count','integer',true),
        ('export_jobs','usuario_id','text',false),
        ('export_jobs','download_url','text',false),
        ('export_jobs','completed_at','timestamp with time zone',false),
        ('export_jobs','created_at','timestamp with time zone',true),
        ('export_jobs','updated_at','timestamp with time zone',true),
        ('archive_manifests','id','uuid',true),
        ('archive_manifests','range_start','timestamp with time zone',true),
        ('archive_manifests','range_end','timestamp with time zone',true),
        ('archive_manifests','object_uri','text',true),
        ('archive_manifests','record_count','integer',true),
        ('archive_manifests','checksum','text',true),
        ('archive_manifests','verified_count','integer',false),
        ('archive_manifests','verified_checksum','text',false),
        ('archive_manifests','verified_at','timestamp with time zone',false),
        ('archive_manifests','recoverable','boolean',true),
        ('archive_manifests','purged_at','timestamp with time zone',false),
        ('archive_manifests','created_at','timestamp with time zone',true),
        ('archive_manifests','updated_at','timestamp with time zone',true)
    ) expected(tab,col,typ,nn) LEFT JOIN pg_namespace n ON n.nspname='price_audit'
      LEFT JOIN pg_class c ON c.relnamespace=n.oid AND c.relname=expected.tab AND c.relkind='r'
      LEFT JOIN pg_attribute a ON a.attrelid=c.oid AND a.attname=expected.col AND NOT a.attisdropped
      WHERE a.attname IS NULL OR format_type(a.atttypid,a.atttypmod)<>expected.typ OR a.attnotnull<>expected.nn
    ) THEN RAISE EXCEPTION 'Manifest de tablas/columnas/tipos/nullability incorrecto'; END IF;
    IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='price_audit' AND c.relkind='r' AND c.relname <> 'schema_migrations'
      AND c.relname NOT IN ('inbox','price_audit_log','export_jobs','archive_manifests')) THEN RAISE EXCEPTION 'Tabla fuera de inventario'; END IF;
    IF EXISTS (SELECT 1 FROM (VALUES
        ('inbox','pk_inbox','p'),
        ('inbox','uq_inbox_message_handler','u'),
        ('price_audit_log','pk_price_audit_log','p'),
        ('price_audit_log','fk_price_audit_log_inbox_id','f'),
        ('price_audit_log','ck_price_audit_log_type','c'),
        ('price_audit_log','ck_price_audit_log_operation','c'),
        ('price_audit_log','ck_price_audit_log_amounts','c'),
        ('price_audit_log','ck_price_audit_log_motivo','c'),
        ('price_audit_log','ck_price_audit_log_null_semantics','c'),
        ('export_jobs','pk_export_jobs','p'),
        ('export_jobs','ck_export_jobs_format','c'),
        ('export_jobs','ck_export_jobs_filters','c'),
        ('export_jobs','ck_export_jobs_limit','c'),
        ('archive_manifests','pk_archive_manifests','p'),
        ('archive_manifests','ck_archive_manifests_range','c'),
        ('archive_manifests','ck_archive_manifests_count','c'),
        ('archive_manifests','ck_archive_manifests_verified','c'),
        ('archive_manifests','ck_archive_manifests_purged','c')
    ) expected(tab,name,kind) LEFT JOIN pg_constraint k ON k.conrelid=to_regclass('price_audit.'||expected.tab)
      AND k.conname=expected.name AND k.contype::text=expected.kind AND k.convalidated
      WHERE k.oid IS NULL) THEN RAISE EXCEPTION 'Constraint requerido ausente/no validado'; END IF;
    -- Destino de FK se resuelve en TODO pg_catalog: detecta taxonomy/auth/public.
    IF EXISTS (SELECT 1 FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid
      JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_class d ON d.oid=k.confrelid
      JOIN pg_namespace dn ON dn.oid=d.relnamespace
      WHERE k.contype='f' AND n.nspname='price_audit' AND dn.nspname<>n.nspname)
      THEN RAISE EXCEPTION 'FK cross-context prohibida'; END IF;
    IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='price_audit' AND c.relkind='r' AND c.relname<>'schema_migrations'
      AND NOT EXISTS (SELECT 1 FROM pg_constraint k JOIN pg_attribute a ON a.attrelid=k.conrelid
          AND a.attnum=ANY(k.conkey) WHERE k.conrelid=c.oid AND k.contype='p'
          AND cardinality(k.conkey)=1 AND a.atttypid='uuid'::regtype))
      THEN RAISE EXCEPTION 'PK UUID requerida'; END IF;
    IF EXISTS (SELECT 1 FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid
      JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='price_audit' AND c.relkind='r'
      AND a.attnum>0 AND NOT a.attisdropped AND (a.attidentity<>'' OR
      a.atttypid IN ('real'::regtype,'double precision'::regtype,'money'::regtype,'timestamp'::regtype) OR
      EXISTS (SELECT 1 FROM pg_attrdef d WHERE d.adrelid=c.oid AND d.adnum=a.attnum
          AND pg_get_expr(d.adbin,d.adrelid) LIKE 'nextval(%')))
      THEN RAISE EXCEPTION 'Tipo/autoincremento prohibido'; END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid
      JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='price_audit' AND c.relname<>'schema_migrations'
      AND k.contype IN ('p','u','f','c','x') AND k.conname !~ '^(pk_|uq_|fk_|ck_)')
      THEN RAISE EXCEPTION 'Constraint sin nombre convencional'; END IF;
    IF EXISTS (SELECT 1 FROM (VALUES
        ('price_audit_log','ix_price_audit_log_inbox_id'),
        ('price_audit_log','ix_price_audit_log_timestamp'),
        ('price_audit_log','ix_price_audit_log_sku_timestamp'),
        ('price_audit_log','ix_price_audit_log_user_timestamp'),
        ('price_audit_log','ix_price_audit_log_canal_timestamp'),
        ('price_audit_log','ix_price_audit_log_batch_timestamp'),
        ('export_jobs','ix_export_jobs_worker'),
        ('archive_manifests','ix_archive_manifests_range')
    ) expected(tab,name) LEFT JOIN pg_class c ON c.oid=to_regclass('price_audit.'||expected.name)
      LEFT JOIN pg_index i ON i.indexrelid=c.oid AND i.indrelid=to_regclass('price_audit.'||expected.tab)
      WHERE i.indexrelid IS NULL OR NOT i.indisvalid OR NOT i.indisready)
      THEN RAISE EXCEPTION 'Indice critico ausente/invalido'; END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint k WHERE k.contype='f'
      AND k.connamespace='price_audit'::regnamespace AND NOT EXISTS (
        SELECT 1 FROM pg_index i WHERE i.indrelid=k.conrelid AND i.indisvalid
        AND i.indpred IS NULL AND (i.indkey::smallint[])[0:cardinality(k.conkey)-1] = k.conkey))
      THEN RAISE EXCEPTION 'FK sin indice de prefijo completo'; END IF;
    IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='price_audit' AND c.relkind='r' AND c.relrowsecurity)
      THEN RAISE EXCEPTION 'RLS no corresponde al schema de escritura'; END IF;
    IF EXISTS (SELECT 1 FROM pg_namespace n CROSS JOIN LATERAL aclexplode(COALESCE(n.nspacl,acldefault('n',n.nspowner))) a
      WHERE n.nspname='price_audit' AND a.grantee=0) THEN RAISE EXCEPTION 'Schema accesible a PUBLIC'; END IF;
    IF EXISTS (SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a
      WHERE p.pronamespace='price_audit'::regnamespace AND a.grantee=0 AND a.privilege_type='EXECUTE')
      THEN RAISE EXCEPTION 'Funcion accesible a PUBLIC'; END IF;
    IF pg_has_role('price_audit_app','po_price_audit_owner','MEMBER')
      OR has_schema_privilege('price_audit_app','price_audit','CREATE') THEN
      RAISE EXCEPTION 'Runtime puede modificar DDL/actuar como owner'; END IF;
    IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='price_audit' AND c.relkind='r' AND
        (has_table_privilege('price_audit_app',c.oid,'DELETE') OR has_table_privilege('price_audit_app',c.oid,'TRUNCATE')))
      THEN RAISE EXCEPTION 'Runtime con DELETE/TRUNCATE indebido'; END IF;
    IF (SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e WHERE e.enumtypid = 'price_audit.export_job_status'::regtype) <> ARRAY['QUEUED','PROCESSING','COMPLETED','FAILED_GENERAL']::text[] THEN RAISE EXCEPTION 'Enum export_job_status incorrecto'; END IF;
END
$structure$;
SELECT 'estructura, tipos, constraints, FK globales, indices, permisos y enums' AS comprobacion, 'PASS' AS resultado;

DO $conventions$
BEGIN
    IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        JOIN pg_attribute a ON a.attrelid=c.oid AND a.attname IN ('created_at','updated_at') AND NOT a.attisdropped
        LEFT JOIN pg_attrdef d ON d.adrelid=c.oid AND d.adnum=a.attnum
        WHERE n.nspname='price_audit' AND c.relkind='r'
        AND (d.oid IS NULL OR pg_get_expr(d.adbin,d.adrelid)<>'now()')) THEN
        RAISE EXCEPTION 'Timestamp tecnico sin DEFAULT now()'; END IF;
    IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        JOIN pg_attribute a ON a.attrelid=c.oid AND a.attname='updated_at' AND NOT a.attisdropped
        WHERE n.nspname='price_audit' AND c.relkind='r' AND NOT EXISTS (
        SELECT 1 FROM pg_trigger t WHERE t.tgrelid=c.oid AND NOT t.tgisinternal
        AND t.tgenabled<>'D' AND t.tgname='trg_'||c.relname||'_updated_at')) THEN
        RAISE EXCEPTION 'Trigger updated_at requerido ausente'; END IF;
    IF EXISTS(SELECT 1 FROM pg_proc p WHERE p.pronamespace='price_audit'::regnamespace AND p.proname !~ '^fn_') THEN
        RAISE EXCEPTION 'Funcion fuera de convencion'; END IF;
    IF EXISTS(SELECT 1 FROM pg_namespace n WHERE n.nspname IN
        ('taxonomy','catalog','pricing','price_audit','promotions','combos','inventory','bulk')
        AND n.nspname<>'price_audit' AND (has_schema_privilege('price_audit_app',n.oid,'USAGE')
        OR has_schema_privilege('price_audit_app',n.oid,'CREATE'))) THEN
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

DO $permissions$
BEGIN
    IF has_table_privilege('price_audit_app','price_audit.price_audit_log','UPDATE') OR
       has_table_privilege('price_audit_app','price_audit.inbox','UPDATE') OR
       has_function_privilege('price_audit_app','price_audit.fn_archive_hot_rows(uuid)','EXECUTE') OR
       pg_has_role('price_audit_app','price_audit_archiver','MEMBER') THEN
        RAISE EXCEPTION 'Runtime con mutacion historica/privilegios de archivo'; END IF;
    IF to_regclass('price_audit.outbox') IS NOT NULL THEN RAISE EXCEPTION 'Auditoria no publica outbox'; END IF;
    IF EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='price_audit.price_audit_log'::regclass
        AND attname IN ('updated_at','deleted_at') AND NOT attisdropped) THEN
        RAISE EXCEPTION 'Timestamps mutables no corresponden a bitacora'; END IF;
END
$permissions$;

DO $domain$
DECLARE msg uuid := gen_random_uuid(); fixture_inbox uuid := gen_random_uuid(); audit uuid := gen_random_uuid();
        manifest uuid := gen_random_uuid(); failed uuid := gen_random_uuid(); n integer; digest text;
        from_time timestamptz := '1901-01-01Z'; until_time timestamptz := '1901-01-02Z';
BEGIN
    -- Ventana fija de fixtures: detenerse si contiene datos existentes, no purgarlos.
    IF EXISTS(SELECT 1 FROM price_audit.price_audit_log WHERE timestamp>=from_time AND timestamp<until_time) THEN
        RAISE EXCEPTION 'Ventana fixture ocupada: ejecutar en base de validacion aislada'; END IF;
    INSERT INTO price_audit.inbox(id,message_id,handler,event_name,payload,result)
    VALUES(fixture_inbox,msg,'price_changed','pricing.price.changed','{}','COMPLETED');
    INSERT INTO price_audit.price_audit_log(id_auditoria,inbox_id,sku,product_id,tipo_precio,precio_anterior,precio_nuevo,
        variacion_porcentual,tipo_operacion,canal_origen,motivo_cambio,timestamp)
    VALUES(audit,fixture_inbox,'SKU-VALIDACION','product-fixture','REGULAR',NULL,100,NULL,'CREACION','API','Alta fixture',from_time);
    INSERT INTO price_audit.price_audit_log(inbox_id,sku,product_id,tipo_precio,precio_anterior,precio_nuevo,
        variacion_porcentual,tipo_operacion,canal_origen,motivo_cambio,timestamp)
    VALUES(fixture_inbox,'SKU-VALIDACION','product-fixture','OFERTA',90,NULL,NULL,'RETIRO_OFERTA','BACKOFFICE','Fin fixture',from_time);
    PERFORM pg_temp.fn_expect_error(format('UPDATE price_audit.price_audit_log SET motivo_cambio=%L WHERE id_auditoria=%L','Alterado',audit),'42501');
    PERFORM pg_temp.fn_expect_error(format('DELETE FROM price_audit.price_audit_log WHERE id_auditoria=%L',audit),'42501');
    PERFORM pg_temp.fn_expect_error('TRUNCATE price_audit.price_audit_log','42501');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO price_audit.price_audit_log(inbox_id,sku,product_id,tipo_precio,precio_anterior,precio_nuevo,
        variacion_porcentual,tipo_operacion,canal_origen,motivo_cambio,timestamp)
        VALUES(%L,'SKU','product','REGULAR',0,100,0,'CREACION','API','Nulo falso','1901-01-01Z')$s$,fixture_inbox),'23514');
    PERFORM pg_temp.fn_expect_error(format($s$INSERT INTO price_audit.inbox(message_id,handler,event_name,payload,result)
        VALUES(%L,'price_changed','pricing.price.changed','{}','COMPLETED')$s$,msg),'23505');
    SELECT count(*) INTO n FROM price_audit.price_audit_log WHERE inbox_id=fixture_inbox;
    IF n <> 2 THEN RAISE EXCEPTION 'Replay modifico cantidad de asientos'; END IF;
    INSERT INTO price_audit.export_jobs(formato,filters,record_count) VALUES('CSV','{}',100000),('PDF','{}',500);
    PERFORM pg_temp.fn_expect_error($s$INSERT INTO price_audit.export_jobs(formato,filters,record_count) VALUES('CSV','{}',100001)$s$,'23514');
    PERFORM pg_temp.fn_expect_error($s$INSERT INTO price_audit.export_jobs(formato,filters,record_count) VALUES('PDF','{}',501)$s$,'23514');
    PERFORM pg_temp.fn_expect_error($s$INSERT INTO price_audit.export_jobs(formato,filters,record_count) VALUES('XLSX','{}',1)$s$,'23514');
    IF EXISTS(SELECT 1 FROM price_audit.export_jobs WHERE record_count>100000 OR (formato='PDF' AND record_count>500)) THEN
        RAISE EXCEPTION 'Se creo exportacion excedida'; END IF;
    digest := price_audit.fn_archive_checksum(from_time,until_time);
    INSERT INTO price_audit.archive_manifests(id,range_start,range_end,object_uri,record_count,checksum)
    VALUES(failed,from_time,until_time,'fixture://archivo-no-verificado',2,digest);
    PERFORM pg_temp.fn_expect_error(format('SELECT price_audit.fn_archive_hot_rows(%L)',failed),'23514');
    SELECT count(*) INTO n FROM price_audit.price_audit_log WHERE inbox_id=fixture_inbox;
    IF n<>2 THEN RAISE EXCEPTION 'Archivo fallido retiro originales'; END IF;
    INSERT INTO price_audit.archive_manifests(id,range_start,range_end,object_uri,record_count,checksum,
        verified_count,verified_checksum,verified_at,recoverable)
    VALUES(manifest,from_time,until_time,'fixture://archivo-verificado',2,digest,2,digest,now(),true);
    -- Conteo correcto pero checksum incorrecto tampoco habilita retiro.
    UPDATE price_audit.archive_manifests SET checksum='incorrecto',verified_checksum='incorrecto' WHERE id=manifest;
    PERFORM pg_temp.fn_expect_error(format('SELECT price_audit.fn_archive_hot_rows(%L)',manifest),'23514');
    UPDATE price_audit.archive_manifests SET checksum=digest,verified_checksum=digest WHERE id=manifest;
    -- Simular datos posteriores a la verificacion invalida la purga.
    INSERT INTO price_audit.price_audit_log(inbox_id,sku,product_id,tipo_precio,precio_anterior,precio_nuevo,
        variacion_porcentual,tipo_operacion,canal_origen,motivo_cambio,timestamp)
    VALUES(fixture_inbox,'SKU-OTRO','product-fixture','REGULAR',1,20,1900,'MODIFICACION','API','Variacion sin tope inventado',from_time);
    PERFORM pg_temp.fn_expect_error(format('SELECT price_audit.fn_archive_hot_rows(%L)',manifest),'23514');
    SELECT count(*) INTO n FROM price_audit.price_audit_log WHERE inbox_id=fixture_inbox;
    IF n<>3 THEN RAISE EXCEPTION 'Conteo/checksum incoherente retiro originales'; END IF;
    digest := price_audit.fn_archive_checksum(from_time,until_time);
    -- Nueva verificacion completa; datos son fixture, no prueba del storage real.
    UPDATE price_audit.archive_manifests SET record_count=3,checksum=digest,
        verified_count=3,verified_checksum=digest WHERE id=manifest;
    n := price_audit.fn_archive_hot_rows(manifest);
    IF n<>3 OR price_audit.fn_archive_hot_rows(manifest)<>0 THEN RAISE EXCEPTION 'Archivo verificado/replay incorrecto'; END IF;
    IF EXISTS(SELECT 1 FROM price_audit.price_audit_log WHERE inbox_id=fixture_inbox) THEN
        RAISE EXCEPTION 'Copias calientes no retiradas'; END IF;
    -- La deduplicacion sobrevive al archivo, no se elimina el fixture_inbox.
    IF NOT EXISTS(SELECT 1 FROM price_audit.inbox WHERE id=fixture_inbox) THEN RAISE EXCEPTION 'Deduplicacion perdida tras archivo'; END IF;
END
$domain$;
SELECT 'append-only, null, fixture_inbox, limites inclusivos, archivo verificado/fallo/replay' AS comprobacion,'PASS' AS resultado;

SET LOCAL ROLE price_audit_app;
DO $runtime_write$
DECLARE i uuid := gen_random_uuid();
BEGIN
    INSERT INTO price_audit.inbox(id,message_id,handler,event_name,payload,result)
    VALUES(i,gen_random_uuid(),'runtime','pricing.price.changed','{}','COMPLETED');
    INSERT INTO price_audit.price_audit_log(inbox_id,sku,product_id,tipo_precio,precio_anterior,precio_nuevo,
        variacion_porcentual,tipo_operacion,canal_origen,motivo_cambio,timestamp)
    VALUES(i,'SKU-RUNTIME','product-fixture','REGULAR',NULL,10,NULL,'CREACION','API','Runtime autorizado',now());
END
$runtime_write$;
SELECT pg_temp.fn_expect_error('UPDATE price_audit.price_audit_log SET motivo_cambio=motivo_cambio','42501');
SELECT pg_temp.fn_expect_error('DELETE FROM price_audit.price_audit_log','42501');
SELECT pg_temp.fn_expect_error('TRUNCATE price_audit.price_audit_log','42501');
SELECT pg_temp.fn_expect_error('SELECT price_audit.fn_archive_hot_rows(gen_random_uuid())','42501');
SELECT 'runtime solo INSERT/SELECT historico, sin purga ni TRUNCATE' AS comprobacion,'PASS' AS resultado;
SET LOCAL ROLE price_audit_archiver;
SELECT pg_temp.fn_expect_error('DELETE FROM price_audit.price_audit_log','42501');
SELECT pg_temp.fn_expect_error('SELECT price_audit.fn_archive_hot_rows(gen_random_uuid())','23514');
SELECT 'archiver solo puede retirar mediante funcion verificada, no DELETE directo' AS comprobacion,'PASS' AS resultado;
RESET ROLE;
ROLLBACK;
-- Todos los fixtures y retiros de prueba se revierten; no hay acceso al storage.

