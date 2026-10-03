-- =============================================================================
-- validation.sql — combos-svc
-- Basado en bd/plantillas/validation.sql y CONVENCIONES_BD.md.
--
-- SOLO LECTURA: no INSERT/UPDATE/DELETE/DDL.
-- Ejecutar con:
--   psql -X -v ON_ERROR_STOP=1 -f database/combos/validation.sql
--
-- Nota:
--   combos.schema_migrations se excluye de los checks de tablas de dominio
--   porque lo crea database/migrate.py y usa version text como PK.
-- =============================================================================

\set ON_ERROR_STOP on

-- =============================================================================
-- SECCIÓN 1 — MATRIZ DE CHECKS
-- =============================================================================


WITH schemas_a_validar(nsp) AS (
    SELECT unnest(ARRAY['combos'])
),
tablas_exentas(qualified) AS (
    SELECT unnest(ARRAY[
        'combos.inbox',
        'combos.outbox'
    ])
),
tablas_de_interes AS (
    SELECT c.oid AS relid,
           n.nspname,
           c.relname,
           n.nspname || '.' || c.relname AS qualified
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN schemas_a_validar s ON s.nsp = n.nspname
     WHERE c.relkind = 'r'
       AND c.relname <> 'schema_migrations'
),
fks AS (
    SELECT tc.oid AS conoid,
           tc.conname,
           tc.conrelid,
           tc.confrelid,
           tc.conkey,
           src.qualified AS tabla,
           tgt_n.nspname || '.' || tgt.relname AS tabla_ref,
           src.nspname AS schema_origen,
           tgt_n.nspname AS schema_destino
      FROM pg_constraint tc
      JOIN tablas_de_interes src ON src.relid = tc.conrelid
      JOIN pg_class tgt ON tgt.oid = tc.confrelid
      JOIN pg_namespace tgt_n ON tgt_n.oid = tgt.relnamespace
     WHERE tc.contype = 'f'
),
checks AS (
    SELECT 1 AS orden,
           'schema_existe' AS check_name,
           'Existe schema combos' AS detalle,
           CASE WHEN to_regnamespace('combos') IS NULL THEN 1 ELSE 0 END::bigint AS fallos

    UNION ALL
    SELECT 2,
           'schema_owner_correcto',
           'combos pertenece a po_combos_owner',
           COUNT(*) FILTER (
               WHERE n.nspname = 'combos'
                 AND pg_get_userbyid(n.nspowner) <> 'po_combos_owner'
           )
           + CASE WHEN NOT EXISTS (
               SELECT 1 FROM pg_namespace WHERE nspname='combos'
             ) THEN 1 ELSE 0 END
      FROM pg_namespace n
     WHERE n.nspname = 'combos'

    UNION ALL
    SELECT 3,
           'schema_sin_public_acl',
           'PUBLIC no conserva privilegios explícitos sobre combos',
           COUNT(*)
      FROM pg_namespace n
      CROSS JOIN LATERAL aclexplode(COALESCE(n.nspacl, acldefault('n', n.nspowner))) a
     WHERE n.nspname = 'combos'
       AND a.grantee = 0

    UNION ALL
    SELECT 4,
           'tablas_esperadas',
           'Existen las 5 tablas del bounded context',
           COUNT(*)
      FROM (VALUES
            ('combos'),('combo_items'),('component_projection'),('outbox'),('inbox')
           ) e(relname)
     WHERE to_regclass('combos.' || e.relname) IS NULL

    UNION ALL
    SELECT 5,
           'sin_tablas_dominio_inesperadas',
           'No hay tablas de dominio fuera del inventario; schema_migrations se excluye por ser ledger del deployer',
           COUNT(*)
      FROM pg_class c
      JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='combos'
       AND c.relkind='r'
       AND c.relname NOT IN (
           'combos','combo_items','component_projection','outbox','inbox','schema_migrations'
       )

    UNION ALL
    SELECT 6,
           'sin_fk_cross_schema',
           'Ninguna FK de combos cruza a otro schema',
           COUNT(*)
      FROM fks
     WHERE schema_origen <> schema_destino

    UNION ALL
    SELECT 7,
           'sin_fk_auth_public',
           'No hay FK hacia auth/public',
           COUNT(*)
      FROM fks
     WHERE schema_destino IN ('auth','public')

    UNION ALL
    SELECT 8,
           'pk_uuid_surrogate',
           'Cada tabla de dominio posee PK de una sola columna UUID',
           COUNT(*)
      FROM pg_constraint tc
      JOIN tablas_de_interes t ON t.relid=tc.conrelid
     WHERE tc.contype='p'
       AND (
          array_length(tc.conkey,1) <> 1
          OR NOT EXISTS (
              SELECT 1
                FROM pg_attribute a
               WHERE a.attrelid=tc.conrelid
                 AND a.attnum=tc.conkey[1]
                 AND format_type(a.atttypid,a.atttypmod)='uuid'
          )
       )

    UNION ALL
    SELECT 9,
           'todas_tablas_tienen_pk',
           'Las cinco tablas poseen PK explícita',
           COUNT(*)
      FROM tablas_de_interes t
     WHERE NOT EXISTS (
         SELECT 1 FROM pg_constraint c
          WHERE c.conrelid=t.relid AND c.contype='p'
     )

    UNION ALL
    SELECT 10,
           'sin_serial_identity',
           'No se usa SERIAL/BIGSERIAL/IDENTITY',
           COUNT(*)
      FROM pg_attribute a
      JOIN tablas_de_interes t ON t.relid=a.attrelid
     WHERE a.attnum>0
       AND NOT a.attisdropped
       AND (
          a.attidentity <> ''
          OR EXISTS (
              SELECT 1 FROM pg_attrdef ad
               WHERE ad.adrelid=a.attrelid
                 AND ad.adnum=a.attnum
                 AND pg_get_expr(ad.adbin, ad.adrelid) LIKE 'nextval(%'
          )
       )

    UNION ALL
    SELECT 11,
           'created_at_obligatorio',
           'Toda tabla del bounded context tiene created_at timestamptz NOT NULL DEFAULT now()',
           COUNT(*)
      FROM tablas_de_interes t
     WHERE NOT EXISTS (
         SELECT 1
           FROM pg_attribute a
           JOIN pg_attrdef d
             ON d.adrelid=a.attrelid AND d.adnum=a.attnum
          WHERE a.attrelid=t.relid
            AND a.attname='created_at'
            AND a.attnotnull
            AND format_type(a.atttypid,a.atttypmod)='timestamp with time zone'
            AND pg_get_expr(d.adbin,d.adrelid) = 'now()'
     )

    UNION ALL
    SELECT 12,
           'updated_at_en_mutables',
           'combos, combo_items y component_projection tienen updated_at timestamptz NOT NULL DEFAULT now()',
           COUNT(*)
      FROM (VALUES ('combos'),('combo_items'),('component_projection')) e(relname)
     WHERE NOT EXISTS (
         SELECT 1
           FROM information_schema.columns c
          WHERE c.table_schema='combos'
            AND c.table_name=e.relname
            AND c.column_name='updated_at'
            AND c.data_type='timestamp with time zone'
            AND c.is_nullable='NO'
            AND c.column_default='now()'
     )

    UNION ALL
    SELECT 13,
           'sin_updated_at_en_infra_exenta',
           'inbox/outbox no llevan updated_at',
           COUNT(*)
      FROM information_schema.columns
     WHERE table_schema='combos'
       AND table_name IN ('inbox','outbox')
       AND column_name='updated_at'

    UNION ALL
    SELECT 14,
           'triggers_updated_at',
           'Las tres tablas mutables usan trg_*_updated_at -> fn_set_updated_at',
           CASE WHEN COUNT(*) = 3 THEN 0 ELSE 1 END
      FROM pg_trigger t
      JOIN pg_class r ON r.oid=t.tgrelid
      JOIN pg_namespace n ON n.oid=r.relnamespace
      JOIN pg_proc p ON p.oid=t.tgfoid
     WHERE n.nspname='combos'
       AND NOT t.tgisinternal
       AND t.tgname IN (
          'trg_combos_updated_at',
          'trg_combo_items_updated_at',
          'trg_component_projection_updated_at'
       )
       AND p.proname='fn_set_updated_at'

    UNION ALL
    SELECT 15,
           'dinero_convencion',
           'combo_price=numeric(12,2) y currency=character(3)',
           (CASE WHEN EXISTS (
               SELECT 1 FROM pg_attribute a
               JOIN pg_class r ON r.oid=a.attrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos' AND r.relname='combos'
                AND a.attname='combo_price'
                AND format_type(a.atttypid,a.atttypmod)='numeric(12,2)'
                AND a.attnotnull
           ) THEN 0 ELSE 1 END)
           +
           (CASE WHEN EXISTS (
               SELECT 1 FROM pg_attribute a
               JOIN pg_class r ON r.oid=a.attrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos' AND r.relname='combos'
                AND a.attname='currency'
                AND format_type(a.atttypid,a.atttypmod)='character(3)'
                AND a.attnotnull
           ) THEN 0 ELSE 1 END)

    UNION ALL
    SELECT 16,
           'sin_tipos_prohibidos',
           'No hay float/real/double precision/money ni timestamp sin zona',
           COUNT(*)
      FROM pg_attribute a
      JOIN tablas_de_interes t ON t.relid=a.attrelid
     WHERE a.attnum>0 AND NOT a.attisdropped
       AND format_type(a.atttypid,a.atttypmod) IN (
          'real','double precision','money','timestamp without time zone'
       )

    UNION ALL
    SELECT 17,
           'enum_combo_status',
           'combo_status contiene exactamente ACTIVO, INACTIVO',
           CASE WHEN (
               SELECT array_agg(e.enumlabel ORDER BY e.enumsortorder)
                 FROM pg_type ty
                 JOIN pg_namespace n ON n.oid=ty.typnamespace
                 JOIN pg_enum e ON e.enumtypid=ty.oid
                WHERE n.nspname='combos'
                  AND ty.typname='combo_status'
           ) IS NOT DISTINCT FROM ARRAY['ACTIVO','INACTIVO']::text[]
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 18,
           'uq_combo_items_combo_sku',
           'La identidad de negocio del componente es única por combo+sku',
           CASE WHEN EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND r.relname='combo_items'
                AND c.conname='uq_combo_items_combo_sku'
                AND c.contype='u'
                AND pg_get_constraintdef(c.oid)='UNIQUE (combo_id, sku)'
           ) THEN 0 ELSE 1 END

    UNION ALL
    SELECT 19,
           'uq_projection_combo_item',
           'Máximo una component_projection por combo_item',
           CASE WHEN EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND r.relname='component_projection'
                AND c.conname='uq_component_projection_combo_item_id'
                AND c.contype='u'
                AND pg_get_constraintdef(c.oid)='UNIQUE (combo_item_id)'
           ) THEN 0 ELSE 1 END

    UNION ALL
    SELECT 20,
           'fk_internas_exactas',
           'Existen exactamente las 2 FK internas esperadas con CASCADE',
           CASE WHEN (
               SELECT COUNT(*) FROM fks
           ) = 2
           AND EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND r.relname='combo_items'
                AND c.conname='fk_combo_items_combo_id'
                AND c.contype='f'
                AND c.confdeltype='c'
           )
           AND EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND r.relname='component_projection'
                AND c.conname='fk_component_projection_combo_item_id'
                AND c.contype='f'
                AND c.confdeltype='c'
           )
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 21,
           'fk_con_indice',
           'Toda FK tiene un índice utilizable cuya primera columna es la FK',
           COUNT(*)
      FROM fks f
     WHERE NOT EXISTS (
         SELECT 1
           FROM pg_index i
          WHERE i.indrelid=f.conrelid
            AND i.indisvalid
            AND i.indisready
            AND i.indkey[0]=f.conkey[1]
     )

    UNION ALL
    SELECT 22,
           'nombres_constraints',
           'PK/UQ/FK/CHECK tienen prefijo y <=63 caracteres',
           COUNT(*)
      FROM pg_constraint c
      JOIN tablas_de_interes t ON t.relid=c.conrelid
     WHERE c.contype IN ('p','u','f','c')
       AND (
          length(c.conname)>63
          OR (
             c.contype='p' AND c.conname !~ '^pk_'
          )
          OR (
             c.contype='u' AND c.conname !~ '^uq_'
          )
          OR (
             c.contype='f' AND c.conname !~ '^fk_'
          )
          OR (
             c.contype='c' AND c.conname !~ '^ck_'
          )
       )

    UNION ALL
    SELECT 23,
           'nombres_funciones_triggers',
           'Funciones propias usan fn_ y triggers propios usan trg_',
           (
             SELECT COUNT(*)
               FROM pg_proc p
               JOIN pg_namespace n ON n.oid=p.pronamespace
              WHERE n.nspname='combos'
                AND p.proname !~ '^fn_'
           )
           +
           (
             SELECT COUNT(*)
               FROM pg_trigger t
               JOIN pg_class r ON r.oid=t.tgrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND NOT t.tgisinternal
                AND t.tgname !~ '^trg_'
           )

    UNION ALL
    SELECT 24,
           'constraint_triggers_min_componentes',
           'Los dos triggers de mínimo 2 son DEFERRABLE INITIALLY DEFERRED',
           CASE WHEN COUNT(*) = 2 THEN 0 ELSE 1 END
      FROM pg_trigger t
      JOIN pg_class r ON r.oid=t.tgrelid
      JOIN pg_namespace n ON n.oid=r.relnamespace
     WHERE n.nspname='combos'
       AND NOT t.tgisinternal
       AND t.tgname IN (
          'trg_combos_min_components',
          'trg_combo_items_min_components'
       )
       AND t.tgconstraint <> 0
       AND t.tgdeferrable
       AND t.tginitdeferred

    UNION ALL
    SELECT 25,
           'lock_composicion',
           'fn_assert_combo_min_components contiene FOR UPDATE',
           CASE WHEN EXISTS (
               SELECT 1 FROM pg_proc p
               JOIN pg_namespace n ON n.oid=p.pronamespace
              WHERE n.nspname='combos'
                AND p.proname='fn_assert_combo_min_components'
                AND position('FOR UPDATE' IN upper(pg_get_functiondef(p.oid))) > 0
           ) THEN 0 ELSE 1 END

    UNION ALL
    SELECT 26,
           'outbox_estructura',
           'Outbox usa published_at/attempts, UQ message_id y tipos contractuales',
           CASE WHEN
             EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos' AND r.relname='outbox'
                AND c.conname='uq_outbox_message_id' AND c.contype='u'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='message_id' AND data_type='text' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='correlation_id' AND data_type='text' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='operation_id' AND udt_name='uuid' AND is_nullable='YES'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='published_at'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='attempts'
             )
             AND NOT EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='status'
             )
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 27,
           'inbox_estructura',
           'Inbox deduplica por message_id+handler y conserva tipos contractuales',
           CASE WHEN
             EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos' AND r.relname='inbox'
                AND c.conname='uq_inbox_message_handler'
                AND c.contype='u'
                AND pg_get_constraintdef(c.oid)='UNIQUE (message_id, handler)'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='inbox'
                  AND column_name='message_id' AND data_type='text' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='inbox'
                  AND column_name='correlation_id' AND data_type='text' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='inbox'
                  AND column_name='operation_id' AND udt_name='uuid' AND is_nullable='YES'
             )
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 28,
           'indices_criticos',
           'Existen ix_combos_status, ix_combo_items_sku e ix_outbox_pending',
           CASE WHEN COUNT(*) = 3 THEN 0 ELSE 1 END
      FROM pg_indexes
     WHERE schemaname='combos'
       AND indexname IN (
          'ix_combos_status',
          'ix_combo_items_sku',
          'ix_outbox_pending'
       )

    UNION ALL
    SELECT 29,
           'projection_shape',
           'component_projection referencia combo_item y separa frescura Catalog/Inventory',
           CASE WHEN
             EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='component_projection'
                  AND column_name='combo_item_id' AND udt_name='uuid' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='component_projection'
                  AND column_name='catalog_observed_at'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='component_projection'
                  AND column_name='inventory_observed_at'
             )
             AND NOT EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='component_projection'
                  AND column_name='sku'
             )
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 30,
           'rls_deshabilitado',
           'Schemas de escritura no usan RLS',
           COUNT(*)
      FROM pg_class c
      JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='combos'
       AND c.relkind='r'
       AND c.relname <> 'schema_migrations'
       AND c.relrowsecurity

    UNION ALL
    SELECT 31,
           'sin_objetos_forbidden_combostock',
           'No existen tablas de pedido/pago/stock/reserva propias de combos',
           COUNT(*)
      FROM pg_class c
      JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='combos'
       AND c.relkind='r'
       AND c.relname IN (
          'pedido','pedidos','pago','pagos',
          'combo_stock','combo_stocks','combo_reservations',
          'reservation','reservations','stock'
       )
)

SELECT orden,
       check_name AS "check",
       detalle,
       fallos,
       CASE WHEN fallos = 0 THEN 'PASS' ELSE 'FAIL' END AS resultado
  FROM checks
 ORDER BY orden;

-- =============================================================================
-- SECCIÓN 2 — ASSERTION FINAL PARA CI/PSQL
-- Repite la matriz de forma deliberada para convertir cualquier FAIL en
-- exit code distinto de cero sin modificar la base.
-- =============================================================================


WITH schemas_a_validar(nsp) AS (
    SELECT unnest(ARRAY['combos'])
),
tablas_exentas(qualified) AS (
    SELECT unnest(ARRAY[
        'combos.inbox',
        'combos.outbox'
    ])
),
tablas_de_interes AS (
    SELECT c.oid AS relid,
           n.nspname,
           c.relname,
           n.nspname || '.' || c.relname AS qualified
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN schemas_a_validar s ON s.nsp = n.nspname
     WHERE c.relkind = 'r'
       AND c.relname <> 'schema_migrations'
),
fks AS (
    SELECT tc.oid AS conoid,
           tc.conname,
           tc.conrelid,
           tc.confrelid,
           tc.conkey,
           src.qualified AS tabla,
           tgt_n.nspname || '.' || tgt.relname AS tabla_ref,
           src.nspname AS schema_origen,
           tgt_n.nspname AS schema_destino
      FROM pg_constraint tc
      JOIN tablas_de_interes src ON src.relid = tc.conrelid
      JOIN pg_class tgt ON tgt.oid = tc.confrelid
      JOIN pg_namespace tgt_n ON tgt_n.oid = tgt.relnamespace
     WHERE tc.contype = 'f'
),
checks AS (
    SELECT 1 AS orden,
           'schema_existe' AS check_name,
           'Existe schema combos' AS detalle,
           CASE WHEN to_regnamespace('combos') IS NULL THEN 1 ELSE 0 END::bigint AS fallos

    UNION ALL
    SELECT 2,
           'schema_owner_correcto',
           'combos pertenece a po_combos_owner',
           COUNT(*) FILTER (
               WHERE n.nspname = 'combos'
                 AND pg_get_userbyid(n.nspowner) <> 'po_combos_owner'
           )
           + CASE WHEN NOT EXISTS (
               SELECT 1 FROM pg_namespace WHERE nspname='combos'
             ) THEN 1 ELSE 0 END
      FROM pg_namespace n
     WHERE n.nspname = 'combos'

    UNION ALL
    SELECT 3,
           'schema_sin_public_acl',
           'PUBLIC no conserva privilegios explícitos sobre combos',
           COUNT(*)
      FROM pg_namespace n
      CROSS JOIN LATERAL aclexplode(COALESCE(n.nspacl, acldefault('n', n.nspowner))) a
     WHERE n.nspname = 'combos'
       AND a.grantee = 0

    UNION ALL
    SELECT 4,
           'tablas_esperadas',
           'Existen las 5 tablas del bounded context',
           COUNT(*)
      FROM (VALUES
            ('combos'),('combo_items'),('component_projection'),('outbox'),('inbox')
           ) e(relname)
     WHERE to_regclass('combos.' || e.relname) IS NULL

    UNION ALL
    SELECT 5,
           'sin_tablas_dominio_inesperadas',
           'No hay tablas de dominio fuera del inventario; schema_migrations se excluye por ser ledger del deployer',
           COUNT(*)
      FROM pg_class c
      JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='combos'
       AND c.relkind='r'
       AND c.relname NOT IN (
           'combos','combo_items','component_projection','outbox','inbox','schema_migrations'
       )

    UNION ALL
    SELECT 6,
           'sin_fk_cross_schema',
           'Ninguna FK de combos cruza a otro schema',
           COUNT(*)
      FROM fks
     WHERE schema_origen <> schema_destino

    UNION ALL
    SELECT 7,
           'sin_fk_auth_public',
           'No hay FK hacia auth/public',
           COUNT(*)
      FROM fks
     WHERE schema_destino IN ('auth','public')

    UNION ALL
    SELECT 8,
           'pk_uuid_surrogate',
           'Cada tabla de dominio posee PK de una sola columna UUID',
           COUNT(*)
      FROM pg_constraint tc
      JOIN tablas_de_interes t ON t.relid=tc.conrelid
     WHERE tc.contype='p'
       AND (
          array_length(tc.conkey,1) <> 1
          OR NOT EXISTS (
              SELECT 1
                FROM pg_attribute a
               WHERE a.attrelid=tc.conrelid
                 AND a.attnum=tc.conkey[1]
                 AND format_type(a.atttypid,a.atttypmod)='uuid'
          )
       )

    UNION ALL
    SELECT 9,
           'todas_tablas_tienen_pk',
           'Las cinco tablas poseen PK explícita',
           COUNT(*)
      FROM tablas_de_interes t
     WHERE NOT EXISTS (
         SELECT 1 FROM pg_constraint c
          WHERE c.conrelid=t.relid AND c.contype='p'
     )

    UNION ALL
    SELECT 10,
           'sin_serial_identity',
           'No se usa SERIAL/BIGSERIAL/IDENTITY',
           COUNT(*)
      FROM pg_attribute a
      JOIN tablas_de_interes t ON t.relid=a.attrelid
     WHERE a.attnum>0
       AND NOT a.attisdropped
       AND (
          a.attidentity <> ''
          OR EXISTS (
              SELECT 1 FROM pg_attrdef ad
               WHERE ad.adrelid=a.attrelid
                 AND ad.adnum=a.attnum
                 AND pg_get_expr(ad.adbin, ad.adrelid) LIKE 'nextval(%'
          )
       )

    UNION ALL
    SELECT 11,
           'created_at_obligatorio',
           'Toda tabla del bounded context tiene created_at timestamptz NOT NULL DEFAULT now()',
           COUNT(*)
      FROM tablas_de_interes t
     WHERE NOT EXISTS (
         SELECT 1
           FROM pg_attribute a
           JOIN pg_attrdef d
             ON d.adrelid=a.attrelid AND d.adnum=a.attnum
          WHERE a.attrelid=t.relid
            AND a.attname='created_at'
            AND a.attnotnull
            AND format_type(a.atttypid,a.atttypmod)='timestamp with time zone'
            AND pg_get_expr(d.adbin,d.adrelid) = 'now()'
     )

    UNION ALL
    SELECT 12,
           'updated_at_en_mutables',
           'combos, combo_items y component_projection tienen updated_at timestamptz NOT NULL DEFAULT now()',
           COUNT(*)
      FROM (VALUES ('combos'),('combo_items'),('component_projection')) e(relname)
     WHERE NOT EXISTS (
         SELECT 1
           FROM information_schema.columns c
          WHERE c.table_schema='combos'
            AND c.table_name=e.relname
            AND c.column_name='updated_at'
            AND c.data_type='timestamp with time zone'
            AND c.is_nullable='NO'
            AND c.column_default='now()'
     )

    UNION ALL
    SELECT 13,
           'sin_updated_at_en_infra_exenta',
           'inbox/outbox no llevan updated_at',
           COUNT(*)
      FROM information_schema.columns
     WHERE table_schema='combos'
       AND table_name IN ('inbox','outbox')
       AND column_name='updated_at'

    UNION ALL
    SELECT 14,
           'triggers_updated_at',
           'Las tres tablas mutables usan trg_*_updated_at -> fn_set_updated_at',
           3 - COUNT(*)
      FROM pg_trigger t
      JOIN pg_class r ON r.oid=t.tgrelid
      JOIN pg_namespace n ON n.oid=r.relnamespace
      JOIN pg_proc p ON p.oid=t.tgfoid
     WHERE n.nspname='combos'
       AND NOT t.tgisinternal
       AND t.tgname IN (
          'trg_combos_updated_at',
          'trg_combo_items_updated_at',
          'trg_component_projection_updated_at'
       )
       AND p.proname='fn_set_updated_at'

    UNION ALL
    SELECT 15,
           'dinero_convencion',
           'combo_price=numeric(12,2) y currency=character(3)',
           (CASE WHEN EXISTS (
               SELECT 1 FROM pg_attribute a
               JOIN pg_class r ON r.oid=a.attrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos' AND r.relname='combos'
                AND a.attname='combo_price'
                AND format_type(a.atttypid,a.atttypmod)='numeric(12,2)'
                AND a.attnotnull
           ) THEN 0 ELSE 1 END)
           +
           (CASE WHEN EXISTS (
               SELECT 1 FROM pg_attribute a
               JOIN pg_class r ON r.oid=a.attrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos' AND r.relname='combos'
                AND a.attname='currency'
                AND format_type(a.atttypid,a.atttypmod)='character(3)'
                AND a.attnotnull
           ) THEN 0 ELSE 1 END)

    UNION ALL
    SELECT 16,
           'sin_tipos_prohibidos',
           'No hay float/real/double precision/money ni timestamp sin zona',
           COUNT(*)
      FROM pg_attribute a
      JOIN tablas_de_interes t ON t.relid=a.attrelid
     WHERE a.attnum>0 AND NOT a.attisdropped
       AND format_type(a.atttypid,a.atttypmod) IN (
          'real','double precision','money','timestamp without time zone'
       )

    UNION ALL
    SELECT 17,
           'enum_combo_status',
           'combo_status contiene exactamente ACTIVO, INACTIVO',
           CASE WHEN (
               SELECT array_agg(e.enumlabel ORDER BY e.enumsortorder)
                 FROM pg_type ty
                 JOIN pg_namespace n ON n.oid=ty.typnamespace
                 JOIN pg_enum e ON e.enumtypid=ty.oid
                WHERE n.nspname='combos'
                  AND ty.typname='combo_status'
           ) IS NOT DISTINCT FROM ARRAY['ACTIVO','INACTIVO']::text[]
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 18,
           'uq_combo_items_combo_sku',
           'La identidad de negocio del componente es única por combo+sku',
           CASE WHEN EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND r.relname='combo_items'
                AND c.conname='uq_combo_items_combo_sku'
                AND c.contype='u'
                AND pg_get_constraintdef(c.oid)='UNIQUE (combo_id, sku)'
           ) THEN 0 ELSE 1 END

    UNION ALL
    SELECT 19,
           'uq_projection_combo_item',
           'Máximo una component_projection por combo_item',
           CASE WHEN EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND r.relname='component_projection'
                AND c.conname='uq_component_projection_combo_item_id'
                AND c.contype='u'
                AND pg_get_constraintdef(c.oid)='UNIQUE (combo_item_id)'
           ) THEN 0 ELSE 1 END

    UNION ALL
    SELECT 20,
           'fk_internas_exactas',
           'Existen exactamente las 2 FK internas esperadas con CASCADE',
           CASE WHEN (
               SELECT COUNT(*) FROM fks
           ) = 2
           AND EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND r.relname='combo_items'
                AND c.conname='fk_combo_items_combo_id'
                AND c.contype='f'
                AND c.confdeltype='c'
           )
           AND EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND r.relname='component_projection'
                AND c.conname='fk_component_projection_combo_item_id'
                AND c.contype='f'
                AND c.confdeltype='c'
           )
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 21,
           'fk_con_indice',
           'Toda FK tiene un índice utilizable cuya primera columna es la FK',
           COUNT(*)
      FROM fks f
     WHERE NOT EXISTS (
         SELECT 1
           FROM pg_index i
          WHERE i.indrelid=f.conrelid
            AND i.indisvalid
            AND i.indisready
            AND i.indkey::smallint[] @> ARRAY[f.conkey[1]]::smallint[]
            AND i.indkey[0]=f.conkey[1]
     )

    UNION ALL
    SELECT 22,
           'nombres_constraints',
           'PK/UQ/FK/CHECK tienen prefijo y <=63 caracteres',
           COUNT(*)
      FROM pg_constraint c
      JOIN tablas_de_interes t ON t.relid=c.conrelid
     WHERE c.contype IN ('p','u','f','c')
       AND (
          length(c.conname)>63
          OR (
             c.contype='p' AND c.conname !~ '^pk_'
          )
          OR (
             c.contype='u' AND c.conname !~ '^uq_'
          )
          OR (
             c.contype='f' AND c.conname !~ '^fk_'
          )
          OR (
             c.contype='c' AND c.conname !~ '^ck_'
          )
       )

    UNION ALL
    SELECT 23,
           'nombres_funciones_triggers',
           'Funciones propias usan fn_ y triggers propios usan trg_',
           (
             SELECT COUNT(*)
               FROM pg_proc p
               JOIN pg_namespace n ON n.oid=p.pronamespace
              WHERE n.nspname='combos'
                AND p.proname !~ '^fn_'
           )
           +
           (
             SELECT COUNT(*)
               FROM pg_trigger t
               JOIN pg_class r ON r.oid=t.tgrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos'
                AND NOT t.tgisinternal
                AND t.tgname !~ '^trg_'
           )

    UNION ALL
    SELECT 24,
           'constraint_triggers_min_componentes',
           'Los dos triggers de mínimo 2 son DEFERRABLE INITIALLY DEFERRED',
           2 - COUNT(*)
      FROM pg_trigger t
      JOIN pg_class r ON r.oid=t.tgrelid
      JOIN pg_namespace n ON n.oid=r.relnamespace
     WHERE n.nspname='combos'
       AND NOT t.tgisinternal
       AND t.tgname IN (
          'trg_combos_min_components',
          'trg_combo_items_min_components'
       )
       AND t.tgconstraint <> 0
       AND t.tgdeferrable
       AND t.tginitdeferred

    UNION ALL
    SELECT 25,
           'lock_composicion',
           'fn_assert_combo_min_components contiene FOR UPDATE',
           CASE WHEN EXISTS (
               SELECT 1 FROM pg_proc p
               JOIN pg_namespace n ON n.oid=p.pronamespace
              WHERE n.nspname='combos'
                AND p.proname='fn_assert_combo_min_components'
                AND position('FOR UPDATE' IN upper(pg_get_functiondef(p.oid))) > 0
           ) THEN 0 ELSE 1 END

    UNION ALL
    SELECT 26,
           'outbox_estructura',
           'Outbox usa published_at/attempts, UQ message_id y tipos contractuales',
           CASE WHEN
             EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos' AND r.relname='outbox'
                AND c.conname='uq_outbox_message_id' AND c.contype='u'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='message_id' AND data_type='text' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='correlation_id' AND data_type='text' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='operation_id' AND udt_name='uuid' AND is_nullable='YES'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='published_at'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='attempts'
             )
             AND NOT EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='outbox'
                  AND column_name='status'
             )
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 27,
           'inbox_estructura',
           'Inbox deduplica por message_id+handler y conserva tipos contractuales',
           CASE WHEN
             EXISTS (
               SELECT 1 FROM pg_constraint c
               JOIN pg_class r ON r.oid=c.conrelid
               JOIN pg_namespace n ON n.oid=r.relnamespace
              WHERE n.nspname='combos' AND r.relname='inbox'
                AND c.conname='uq_inbox_message_handler'
                AND c.contype='u'
                AND pg_get_constraintdef(c.oid)='UNIQUE (message_id, handler)'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='inbox'
                  AND column_name='message_id' AND data_type='text' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='inbox'
                  AND column_name='correlation_id' AND data_type='text' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='inbox'
                  AND column_name='operation_id' AND udt_name='uuid' AND is_nullable='YES'
             )
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 28,
           'indices_criticos',
           'Existen ix_combos_status, ix_combo_items_sku e ix_outbox_pending',
           3 - COUNT(*)
      FROM pg_indexes
     WHERE schemaname='combos'
       AND indexname IN (
          'ix_combos_status',
          'ix_combo_items_sku',
          'ix_outbox_pending'
       )

    UNION ALL
    SELECT 29,
           'projection_shape',
           'component_projection referencia combo_item y separa frescura Catalog/Inventory',
           CASE WHEN
             EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='component_projection'
                  AND column_name='combo_item_id' AND udt_name='uuid' AND is_nullable='NO'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='component_projection'
                  AND column_name='catalog_observed_at'
             )
             AND EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='component_projection'
                  AND column_name='inventory_observed_at'
             )
             AND NOT EXISTS (
               SELECT 1 FROM information_schema.columns
                WHERE table_schema='combos' AND table_name='component_projection'
                  AND column_name='sku'
             )
           THEN 0 ELSE 1 END

    UNION ALL
    SELECT 30,
           'rls_deshabilitado',
           'Schemas de escritura no usan RLS',
           COUNT(*)
      FROM pg_class c
      JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='combos'
       AND c.relkind='r'
       AND c.relname <> 'schema_migrations'
       AND c.relrowsecurity

    UNION ALL
    SELECT 31,
           'sin_objetos_forbidden_combostock',
           'No existen tablas de pedido/pago/stock/reserva propias de combos',
           COUNT(*)
      FROM pg_class c
      JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='combos'
       AND c.relkind='r'
       AND c.relname IN (
          'pedido','pedidos','pago','pagos',
          'combo_stock','combo_stocks','combo_reservations',
          'reservation','reservations','stock'
       )
)

SELECT (COALESCE(SUM(fallos),0) > 0)::text AS validation_failed,
       COALESCE(SUM(fallos),0) AS total_fallos
  FROM checks
\gset

\if :validation_failed
    \echo 'VALIDACION_FALLIDA - total_fallos=' :total_fallos
    \quit 1
\else
    \echo 'VALIDACION_FINALIZADA_SATISFACTORIAMENTE'
\endif
