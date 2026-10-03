-- =============================================================================
-- bulk-svc — validation.sql
-- Issue #57 — validación solo lectura
--
-- Ejecutar después de: python database/migrate.py bulk
-- Uso: psql -X -v ON_ERROR_STOP=1 -f database/bulk/validation.sql
--
-- Este script NO inserta, actualiza ni elimina datos. Si detecta un incumplimiento
-- lanza RAISE EXCEPTION y finaliza con error.
-- =============================================================================

DO $$
DECLARE
    v_count bigint;
BEGIN
    -- -------------------------------------------------------------------------
    -- 1. Schema y tablas del modelo
    -- -------------------------------------------------------------------------
    IF to_regnamespace('bulk') IS NULL THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [1]: schema bulk no existe';
    END IF;

    SELECT count(*) INTO v_count
      FROM (VALUES
        ('file_manifests'),('batch_jobs'),('batch_rows'),('row_domain_steps'),
        ('export_jobs'),('outbox'),('inbox')
      ) e(name)
     WHERE to_regclass('bulk.' || e.name) IS NULL;
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [2]: faltan % tablas esperadas', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM information_schema.tables
     WHERE table_schema='bulk'
       AND table_type='BASE TABLE'
       AND table_name NOT IN (
           'file_manifests','batch_jobs','batch_rows','row_domain_steps',
           'export_jobs','outbox','inbox','schema_migrations'
       );
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [3]: existen % tablas no documentadas en bulk', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 2. PK UUID del modelo (schema_migrations es ledger del migrador y se excluye)
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM pg_constraint c
      JOIN pg_class t ON t.oid=c.conrelid
      JOIN pg_namespace n ON n.oid=t.relnamespace
      JOIN pg_attribute a ON a.attrelid=t.oid AND a.attnum=ANY(c.conkey)
     WHERE n.nspname='bulk'
       AND t.relname IN ('file_manifests','batch_jobs','batch_rows','row_domain_steps','export_jobs','outbox','inbox')
       AND c.contype='p'
       AND format_type(a.atttypid,a.atttypmod) <> 'uuid';
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [4]: hay % columnas de PK no uuid', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM pg_class t
      JOIN pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='bulk'
       AND t.relname IN ('file_manifests','batch_jobs','batch_rows','row_domain_steps','export_jobs','outbox','inbox')
       AND NOT EXISTS (
           SELECT 1 FROM pg_constraint c WHERE c.conrelid=t.oid AND c.contype='p'
       );
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [5]: % tablas no tienen PK', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 3. Sin SERIAL/BIGSERIAL/IDENTITY
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM pg_attribute a
      JOIN pg_class t ON t.oid=a.attrelid
      JOIN pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='bulk'
       AND t.relname IN ('file_manifests','batch_jobs','batch_rows','row_domain_steps','export_jobs','outbox','inbox')
       AND a.attnum>0 AND NOT a.attisdropped
       AND (
           a.attidentity <> ''
           OR EXISTS (
               SELECT 1 FROM pg_attrdef d
                WHERE d.adrelid=a.attrelid AND d.adnum=a.attnum
                  AND pg_get_expr(d.adbin,d.adrelid) LIKE 'nextval(%'
           )
       );
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [6]: se detectaron % columnas identity/serial', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 4. FK internas y prohibición cross-schema/auth/public
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM pg_constraint c
      JOIN pg_class src ON src.oid=c.conrelid
      JOIN pg_namespace sn ON sn.oid=src.relnamespace
      JOIN pg_class dst ON dst.oid=c.confrelid
      JOIN pg_namespace dn ON dn.oid=dst.relnamespace
     WHERE sn.nspname='bulk' AND c.contype='f' AND dn.nspname <> 'bulk';
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [7]: existen % FK cross-schema', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM pg_constraint c
      JOIN pg_class src ON src.oid=c.conrelid
      JOIN pg_namespace sn ON sn.oid=src.relnamespace
      JOIN pg_class dst ON dst.oid=c.confrelid
      JOIN pg_namespace dn ON dn.oid=dst.relnamespace
     WHERE sn.nspname='bulk' AND c.contype='f' AND dn.nspname IN ('auth','public');
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [8]: existe FK hacia auth/public';
    END IF;

    SELECT count(*) INTO v_count
      FROM pg_constraint c
      JOIN pg_class t ON t.oid=c.conrelid
      JOIN pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='bulk' AND c.contype='f';
    IF v_count <> 5 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [9]: se esperaban 5 FK internas y hay %', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 5. Toda FK debe estar cubierta por un índice cuyo prefijo sea la FK
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM pg_constraint c
      JOIN pg_class t ON t.oid=c.conrelid
      JOIN pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='bulk'
       AND c.contype='f'
       AND NOT EXISTS (
           SELECT 1
             FROM pg_index i
            WHERE i.indrelid=c.conrelid
              AND i.indisvalid
              AND i.indkey[0] = c.conkey[1]
       );
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [10]: % FK no tienen índice de soporte', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 6. Timestamps obligatorios y prohibición timestamp sin zona
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM (VALUES
        ('file_manifests'),('batch_jobs'),('batch_rows'),('row_domain_steps'),
        ('export_jobs'),('outbox'),('inbox')
      ) e(name)
     WHERE NOT EXISTS (
         SELECT 1 FROM information_schema.columns c
          WHERE c.table_schema='bulk' AND c.table_name=e.name
            AND c.column_name='created_at' AND c.data_type='timestamp with time zone'
            AND c.is_nullable='NO'
     );
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [11]: % tablas carecen de created_at timestamptz NOT NULL', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM (VALUES
        ('file_manifests'),('batch_jobs'),('batch_rows'),('row_domain_steps'),('export_jobs')
      ) e(name)
     WHERE NOT EXISTS (
         SELECT 1 FROM information_schema.columns c
          WHERE c.table_schema='bulk' AND c.table_name=e.name
            AND c.column_name='updated_at' AND c.data_type='timestamp with time zone'
            AND c.is_nullable='NO'
     );
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [12]: % tablas mutables carecen de updated_at', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM information_schema.columns
     WHERE table_schema='bulk'
       AND table_name IN ('outbox','inbox')
       AND column_name='updated_at';
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [13]: outbox/inbox no deben tener updated_at';
    END IF;

    SELECT count(*) INTO v_count
      FROM information_schema.columns
     WHERE table_schema='bulk'
       AND table_name IN ('file_manifests','batch_jobs','batch_rows','row_domain_steps','export_jobs','outbox','inbox')
       AND data_type='timestamp without time zone';
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [14]: existen % timestamp sin zona', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 7. Enums locales esperados
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
     WHERE n.nspname='bulk' AND t.typtype='e'
       AND t.typname IN ('job_status','row_status','step_status');
    IF v_count <> 3 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [15]: se esperaban 3 enums y hay %', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
     WHERE n.nspname='bulk' AND t.typtype='e'
       AND t.typname NOT IN ('job_status','row_status','step_status');
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [16]: existen % enums no documentados', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 8. Tipos contractuales críticos
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count FROM information_schema.columns
     WHERE table_schema='bulk' AND table_name='batch_jobs' AND column_name='batch_id'
       AND udt_name='uuid';
    IF v_count <> 1 THEN RAISE EXCEPTION 'VALIDACION FALLADA [17]: batch_id debe ser uuid'; END IF;

    SELECT count(*) INTO v_count FROM information_schema.columns
     WHERE table_schema='bulk' AND table_name='batch_rows' AND column_name='row_id'
       AND udt_name='uuid';
    IF v_count <> 1 THEN RAISE EXCEPTION 'VALIDACION FALLADA [18]: row_id debe ser uuid'; END IF;

    SELECT count(*) INTO v_count FROM information_schema.columns
     WHERE table_schema='bulk' AND table_name='export_jobs' AND column_name='export_id'
       AND udt_name='uuid';
    IF v_count <> 1 THEN RAISE EXCEPTION 'VALIDACION FALLADA [19]: export_id debe ser uuid'; END IF;

    SELECT count(*) INTO v_count FROM information_schema.columns
     WHERE table_schema='bulk' AND table_name='outbox' AND column_name='message_id'
       AND data_type='text';
    IF v_count <> 1 THEN RAISE EXCEPTION 'VALIDACION FALLADA [20]: outbox.message_id debe ser text por AsyncAPI vigente'; END IF;

    SELECT count(*) INTO v_count FROM information_schema.columns
     WHERE table_schema='bulk' AND table_name='inbox' AND column_name='message_id'
       AND data_type='text';
    IF v_count <> 1 THEN RAISE EXCEPTION 'VALIDACION FALLADA [21]: inbox.message_id debe ser text por AsyncAPI vigente'; END IF;

    -- -------------------------------------------------------------------------
    -- 9. Constraints, funciones, triggers e índices con prefijo
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM pg_constraint c
      JOIN pg_class t ON t.oid=c.conrelid
      JOIN pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='bulk'
       AND t.relname IN ('file_manifests','batch_jobs','batch_rows','row_domain_steps','export_jobs','outbox','inbox')
       AND c.contype IN ('p','u','f','c')
       AND c.conname !~ '^(pk|uq|fk|ck)_';
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [22]: % constraints no siguen prefijo', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM pg_indexes
     WHERE schemaname='bulk'
       AND indexname NOT LIKE 'ix_%'
       AND indexname NOT LIKE 'pk_%'
       AND indexname NOT LIKE 'uq_%'
       AND tablename IN ('file_manifests','batch_jobs','batch_rows','row_domain_steps','export_jobs','outbox','inbox');
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [23]: % índices tienen nombre no convencional', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='bulk' AND p.proname NOT LIKE 'fn_%';
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [24]: % funciones no usan prefijo fn_', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM pg_trigger tg
      JOIN pg_class t ON t.oid=tg.tgrelid
      JOIN pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='bulk' AND NOT tg.tgisinternal
       AND tg.tgname NOT LIKE 'trg_%';
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [25]: % triggers no usan prefijo trg_', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 10. Objetos obligatorios de Outbox / Inbox
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM information_schema.columns
     WHERE table_schema='bulk' AND table_name='outbox'
       AND column_name IN ('id','message_id','event_name','kind','schema_version','correlation_id',
                           'causation_id','operation_id','occurred_at','payload','published_at',
                           'attempts','last_error','created_at');
    IF v_count <> 14 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [26]: estructura Outbox incompleta (%/14 columnas)', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM information_schema.columns
     WHERE table_schema='bulk' AND table_name='inbox'
       AND column_name IN ('id','message_id','handler','event_name','correlation_id','payload','result','processed_at','created_at');
    IF v_count <> 9 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [27]: estructura Inbox incompleta (%/9 columnas)', v_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON t.oid=c.conrelid
        JOIN pg_namespace n ON n.oid=t.relnamespace
        WHERE n.nspname='bulk' AND t.relname='inbox'
          AND c.conname='uq_inbox_message_handler' AND c.contype='u'
    ) THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [28]: falta uq_inbox_message_handler';
    END IF;

    IF to_regclass('bulk.ix_outbox_pending') IS NULL THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [29]: falta ix_outbox_pending';
    END IF;

    -- -------------------------------------------------------------------------
    -- 11. RLS deshabilitado en schema de escritura
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM pg_class t JOIN pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='bulk'
       AND t.relname IN ('file_manifests','batch_jobs','batch_rows','row_domain_steps','export_jobs','outbox','inbox')
       AND t.relrowsecurity;
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [30]: RLS está habilitado en % tablas de escritura', v_count;
    END IF;

    -- -------------------------------------------------------------------------
    -- 12. Consistencia de datos existentes (solo estados terminales)
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count
      FROM bulk.batch_jobs bj
     WHERE bj.status='COMPLETED'
       AND (
          bj.total_rows <> (SELECT count(*) FROM bulk.batch_rows br WHERE br.batch_job_id=bj.id)
          OR bj.completed_rows <> (SELECT count(*) FROM bulk.batch_rows br WHERE br.batch_job_id=bj.id AND br.status='COMPLETED')
          OR bj.failed_rows <> (SELECT count(*) FROM bulk.batch_rows br WHERE br.batch_job_id=bj.id AND br.status='FAILED')
       );
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [31]: % lotes COMPLETED tienen contadores divergentes', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM bulk.batch_rows br
     WHERE br.status IN ('COMPLETED','FAILED')
       AND EXISTS (
           SELECT 1
             FROM unnest(br.required_domains) req(domain)
            WHERE NOT EXISTS (
                SELECT 1 FROM bulk.row_domain_steps ds
                 WHERE ds.batch_row_id=br.id AND ds.domain=req.domain
            )
       );
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [32]: % filas terminales carecen de pasos requeridos', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM bulk.row_domain_steps ds
      JOIN bulk.batch_rows br ON br.id=ds.batch_row_id
     WHERE br.status IN ('COMPLETED','FAILED')
       AND NOT (ds.domain = ANY(br.required_domains));
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLADA [33]: % pasos terminales usan dominio no requerido', v_count;
    END IF;

    SELECT count(*) INTO v_count
      FROM bulk.batch_jobs bj
      JOIN bulk.file_manifests f ON f.id=bj.input_file_id
     WHERE f.role <> 'ENTRADA_IMPORTACION';
    IF v_count <> 0 THEN RAISE EXCEPTION 'VALIDACION FALLADA [34]: lote enlazado a archivo de entrada con rol incorrecto'; END IF;

    SELECT count(*) INTO v_count
      FROM bulk.batch_jobs bj
      JOIN bulk.file_manifests f ON f.id=bj.report_file_id
     WHERE f.role <> 'REPORTE_IMPORTACION' OR f.format <> 'CSV';
    IF v_count <> 0 THEN RAISE EXCEPTION 'VALIDACION FALLADA [35]: reporte enlazado con rol/formato incorrecto'; END IF;

    SELECT count(*) INTO v_count
      FROM bulk.export_jobs ej
      JOIN bulk.file_manifests f ON f.id=ej.output_file_id
     WHERE f.role <> 'RESULTADO_EXPORTACION' OR f.format <> ej.format;
    IF v_count <> 0 THEN RAISE EXCEPTION 'VALIDACION FALLADA [36]: archivo de exportación con rol/formato incorrecto'; END IF;

    RAISE NOTICE 'VALIDACION BULK: todos los checks obligatorios PASS';
END $$;

SELECT
    'PASS' AS resultado,
    'VALIDACION_FINALIZADA_SATISFACTORIAMENTE' AS detalle;
