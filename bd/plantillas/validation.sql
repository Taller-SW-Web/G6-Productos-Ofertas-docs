-- =============================================================================
-- _TEMPLATE — validation.sql
-- Checks verificables del modelo fisico de un bounded context
-- =============================================================================
-- Uso:
--   1. Copiar en <svc>/src/infrastructure/persistence/validation.sql
--   2. Editar las dos variables de configuracion de la SECCION 0
--      (schemas_a_validar y tablas_exentas)
--   3. Ejecutar contra la base ya migrada
--   4. Todos los checks deben devolver PASS antes de aprobar el modelo
--
-- Como leer el resultado:
--   fallos = 0  -> PASS
--   fallos > 0  -> FAIL, revisar la consulta de detalle correspondiente
--
-- Nota: este script SOLO LEE. No modifica nada.
--       No debe usarse para 'arreglar' la base.
-- =============================================================================


-- =============================================================================
-- SECCION 0 — CONFIGURACION
-- Editar estos dos bloques antes de ejecutar.
-- =============================================================================

-- Schemas que pertenecen a este modulo.
-- Un responsable ejecuta el script con SU schema; el equipo puede correr la
-- version completa con los nueve.
--    'taxonomy','catalog','pricing','price_audit',
--    'promotions','combos','inventory','bulk','read_model'


-- Tablas append-only o de registro inmutable: exentas de updated_at y
-- deleted_at por CONVENCIONES_BD.md 7.3.
-- Las tablas outbox e inbox se tratan como exentas por patron de nombre.
--    'price_audit.price_audit_log',
--    'inventory.kardex',
--    'read_model.event_offsets'


-- =============================================================================
-- SECCION 1 — VERIFICACION GLOBAL
-- Devuelve una fila por check con PASS / FAIL.
-- Copiar el bloque completo y ajustar los dos VALUES de arriba.
-- =============================================================================

WITH schemas_a_validar(nsp) AS (
    SELECT unnest(ARRAY[
        'taxonomy','catalog','pricing','price_audit',
        'promotions','combos','inventory','bulk','read_model'
    ])
),
tablas_exentas(qualified) AS (
    SELECT unnest(ARRAY[
        'price_audit.price_audit_log',
        'inventory.kardex',
        'read_model.event_offsets'
    ])
),
tablas_de_interes AS (
    SELECT c.oid       AS relid,
           n.nspname   AS nspname,
           c.relname   AS relname,
           n.nspname || '.' || c.relname AS qualified
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN schemas_a_validar s ON s.nsp = n.nspname
    WHERE c.relkind = 'r'
),
fks AS (
    SELECT tc.oid       AS conoid,
           tc.conname   AS conname,
           tc.conrelid  AS relid,
           tc.confrelid AS refrelid,
           tc.conkey    AS conkey,
           src.qualified AS tabla,
           tgt.qualified AS tabla_ref,
           src.nspname  AS schema_origen,
           tgt.nspname  AS schema_destino
    FROM pg_constraint tc
    JOIN tablas_de_interes src ON src.relid = tc.conrelid
    JOIN tablas_de_interes tgt ON tgt.relid = tc.confrelid
    WHERE tc.contype = 'f'
)
SELECT * FROM (

-- 1. Schemaowner existe
SELECT 1  AS orden,
       'schema_por_service_existe'        AS check,
       'Cada schema del modulo esta creado' AS detalle,
       (SELECT COUNT(*) FROM schemas_a_validar s
         WHERE NOT EXISTS (SELECT 1 FROM pg_namespace n WHERE n.nspname = s.nsp)
       ) AS fallos,
       CASE WHEN (SELECT COUNT(*) FROM schemas_a_validar s
                   WHERE NOT EXISTS (SELECT 1 FROM pg_namespace n WHERE n.nspname = s.nsp)) = 0
            THEN 'PASS' ELSE 'FAIL' END AS resultado

-- 2. REGLA CRITICA: ninguna FK entre schemas de servicios distintos
UNION ALL
SELECT 2,
       'sin_fk_cross_schema',
       'Ninguna FK debe cruzar de schema entre microservicios (CONVENCIONES_BD.md 4)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM fks
WHERE schema_origen <> schema_destino

-- 3. Ninguna FK hacia auth ni public
UNION ALL
SELECT 3,
       'sin_fk_hacia_auth_o_public',
       'El usuario se referencia como user_id text; nunca FK a auth.users',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM fks
WHERE schema_destino IN ('auth','public')

-- 4. Todas las PK son uuid
UNION ALL
SELECT 4,
       'pk_tipo_uuid',
       'Toda PK debe ser uuid (CONVENCIONES_BD.md 6.1)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM pg_constraint tc
JOIN tablas_de_interes t ON t.relid = tc.conrelid
JOIN pg_attribute a ON a.attrelid = tc.conrelid AND a.attnum = ANY (tc.conkey)
WHERE tc.contype = 'p'
  AND format_type(a.atttypid, a.atttypmod) <> 'uuid'

-- 5. Sin SERIAL / BIGSERIAL
UNION ALL
SELECT 5,
       'sin_serial_ni_bigserial',
       'Prohibido SERIAL, BIGSERIAL e IDENTITY autoincremental',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM pg_attribute a
JOIN tablas_de_interes t ON t.relid = a.attrelid
WHERE a.attnum > 0
  AND NOT a.attisdropped
  AND (a.attidentity <> '' OR a.attdefault IS NOT NULL)
  AND a.attdefault LIKE 'nextval(%'

-- 6. Sin timestamp sin zona horaria
UNION ALL
SELECT 6,
       'fechas_con_zona_horaria',
       'Prohibido timestamp without time zone; usar timestamptz',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM pg_attribute a
JOIN tablas_de_interes t ON t.relid = a.attrelid
JOIN information_schema.columns c
     ON c.table_schema = t.nspname AND c.table_name = t.relname
    AND c.column_name = a.attname
WHERE a.attnum > 0 AND NOT a.attisdropped
  AND c.data_type = 'timestamp without time zone'

-- 7. Sin float / real / double precision / money
UNION ALL
SELECT 7,
       'sin_float_ni_money',
       'Prohibido float, real, double precision y money (CONVENCIONES_BD.md 8.1)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM information_schema.columns c
WHERE c.table_schema IN (SELECT nsp FROM schemas_a_validar)
  AND c.table_schema <> 'auth'
  AND c.data_type IN ('real','double precision','money')

-- 8. created_at obligatorio en toda tabla
UNION ALL
SELECT 8,
       'created_at_obligatorio',
       'Toda tabla debe tener created_at timestamptz NOT NULL DEFAULT now()',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM tablas_de_interes t
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = t.nspname AND c.table_name = t.relname
      AND c.column_name = 'created_at'
      AND c.is_nullable = 'NO'
)

-- 9. updated_at obligatorio salvo exentas
UNION ALL
SELECT 9,
       'updated_at_obligatorio',
       'Salvo tablas append-only declaradas exentas (CONVENCIONES_BD.md 7.3)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM tablas_de_interes t
WHERE t.qualified NOT IN (SELECT qualified FROM tablas_exentas)
  AND t.relname NOT IN ('outbox','inbox')
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = t.nspname AND c.table_name = t.relname
      AND c.column_name = 'updated_at'
      AND c.is_nullable = 'NO'
)

-- 10. deleted_at presente salvo exentas
UNION ALL
SELECT 10,
       'deleted_at_presente',
       'Salvo tablas append-only; en tablas con estado puede omitirse por decision',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM tablas_de_interes t
WHERE t.qualified NOT IN (SELECT qualified FROM tablas_exentas)
  AND t.relname NOT IN ('outbox','inbox')
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = t.nspname AND c.table_name = t.relname
      AND c.column_name = 'deleted_at'
      AND c.is_nullable = 'YES'
)

-- 11. Append-only sin updated_at ni deleted_at
UNION ALL
SELECT 11,
       'append_only_sin_updated_at',
       'Las tablas exentas no deben tener updated_at ni deleted_at',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM tablas_de_interes t
JOIN tablas_exentas e ON e.qualified = t.qualified
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = t.nspname AND c.table_name = t.relname
      AND c.column_name IN ('updated_at','deleted_at')
)

-- 12. Toda FK tiene indice en su columna referenciante
UNION ALL
SELECT 12,
       'fk_con_indice',
       'PostgreSQL no crea indice en columnas FK automaticamente',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM fks f
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_index i
    WHERE i.indrelid = f.relid
      AND i.indkey[0:array_length(f.conkey, 1) - 1] @> f.conkey
)

-- 13. Constraints con prefijo
UNION ALL
SELECT 13,
       'constraints_con_prefijo',
       'Toda constraint debe empezar por pk_, uq_, fk_ o ck_',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM pg_constraint tc
JOIN tablas_de_interes t ON t.relid = tc.conrelid
WHERE tc.contype IN ('p','u','f','c')
  AND tc.conname !~ '^(pk_|uq_|fk_|ck_)'

-- 14. Indices con prefijo
UNION ALL
SELECT 14,
       'indices_con_prefijo',
       'Todo indice debe empezar por ix_, uq_ o pk_',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM pg_index i
JOIN tablas_de_interes t ON t.relid = i.indrelid
JOIN pg_class ic ON ic.oid = i.indexrelid
WHERE ic.relname !~ '^(ix_|uq_|pk_)'

-- 15. Tipos enum no se referencian entre schemas
UNION ALL
SELECT 15,
       'enums_locales_al_schema',
       'Los tipos enumerados son propiedad de su schema (CONVENCIONES_BD.md 13.3)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT DISTINCT n.nspname AS tabla_schema, tn.nspname AS tipo_schema
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_type pt ON pt.oid = a.atttypid
    JOIN pg_namespace tn ON tn.oid = pt.typnamespace
    WHERE n.nspname IN (SELECT nsp FROM schemas_a_validar)
      AND pt.typtype = 'e'
      AND tn.nspname <> n.nspname
      AND tn.nspname <> 'pg_catalog'
) x

-- 16. RLS activo solo en read_model
UNION ALL
SELECT 16,
       'rls_solo_en_read_model',
       'RLS se habilita unicamente en read_model (CONVENCIONES_BD.md 16.2)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM pg_class c
JOIN tablas_de_interes t ON t.relid = c.oid
WHERE c.relrowsecurity
  AND t.nspname <> 'read_model'

-- 17. PUBLIC sin privilegios sobre los schemas del modulo
UNION ALL
SELECT 17,
       'schemas_sin_privilegio_public',
       'Cada schema debe ejecutar REVOKE ALL ON SCHEMA <x> FROM PUBLIC',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM pg_namespace n
JOIN schemas_a_validar s ON s.nsp = n.nspname
WHERE has_schema_privilege('public', n.nspname, 'USAGE')

-- 18. Sin datos de negocio en public
UNION ALL
SELECT 18,
       'public_sin_tablas_de_negocio',
       'Los datos de negocio viven en su schema, nunca en public',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'

-- 19. inbox con unicidad de deduplicacion
UNION ALL
SELECT 19,
       'inbox_con_uniquidad',
       'inbox debe ser UNIQUE (message_id, handler) (CONVENCIONES_BD.md 10.2)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM tablas_de_interes t
WHERE t.relname = 'inbox'
  AND NOT EXISTS (
    SELECT 1
    FROM pg_constraint tc
    WHERE tc.conrelid = t.relid
      AND tc.contype = 'u'
      AND tc.conkey = ARRAY[
            (SELECT attnum FROM pg_attribute
              WHERE attrelid = t.relid AND attname = 'message_id'),
            (SELECT attnum FROM pg_attribute
              WHERE attrelid = t.relid AND attname = 'handler')
          ]::int2[]
)

-- 20. outbox con unicidad de message_id
UNION ALL
SELECT 20,
       'outbox_con_uniquidad',
       'outbox debe ser UNIQUE (message_id)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM tablas_de_interes t
WHERE t.relname = 'outbox'
  AND NOT EXISTS (
    SELECT 1
    FROM pg_constraint tc
    WHERE tc.conrelid = t.relid
      AND tc.contype = 'u'
      AND tc.conkey = ARRAY[
            (SELECT attnum FROM pg_attribute
              WHERE attrelid = t.relid AND attname = 'message_id')
          ]::int2[]
)

) AS resumen
ORDER BY orden;


-- =============================================================================
-- SECCION 2 — CONSULTAS DE DETALLE
-- Ejecutar solo cuando un check devuelve FAIL, para localizar las filas.
-- =============================================================================

-- 2.1. Que FKs cruzan schemas entre microservicios
-- SELECT
--     tc.conname,
--     src_ns.nspname || '.' || src.relname  AS tabla_origen,
--     tgt_ns.nspname || '.' || tgt.relname  AS tabla_destino
-- FROM pg_constraint tc
-- JOIN pg_class src      ON src.oid = tc.conrelid
-- JOIN pg_namespace src_ns ON src_ns.oid = src.relnamespace
-- JOIN pg_class tgt      ON tgt.oid = tc.confrelid
-- JOIN pg_namespace tgt_ns ON tgt_ns.oid = tgt.relnamespace
-- WHERE tc.contype = 'f'
--   AND src_ns.nspname <> tgt_ns.nspname
--   AND src_ns.nspname IN ('taxonomy','catalog','pricing','price_audit',
--                          'promotions','combos','inventory','bulk','read_model')
-- ORDER BY 2, 3;

-- 2.2. Que FKs no tienen indice
-- SELECT
--     src_ns.nspname || '.' || src.relname AS tabla,
--     tc.conname AS fk,
--     (SELECT string_agg(a.attname, ', ')
--        FROM pg_attribute a
--       WHERE a.attrelid = tc.conrelid AND a.attnum = ANY (tc.conkey)) AS columnas
-- FROM pg_constraint tc
-- JOIN pg_class src ON src.oid = tc.conrelid
-- JOIN pg_namespace src_ns ON src_ns.oid = src.relnamespace
-- WHERE tc.contype = 'f'
--   AND NOT EXISTS (
--     SELECT 1 FROM pg_index i
--     WHERE i.indrelid = tc.conrelid
--       AND i.indkey[0:array_length(tc.conkey, 1) - 1] @> tc.conkey
--   )
-- ORDER BY 1;

-- 2.3. Columnas monetarias que no usan numeric
-- SELECT table_schema, table_name, column_name, data_type, numeric_precision, numeric_scale
-- FROM information_schema.columns
-- WHERE table_schema IN ('pricing','promotions','combos','price_audit')
--   AND (column_name ~ '(precio|monto|importe|subtotal|total|descuento)')
--   AND data_type <> 'numeric'
-- ORDER BY 1, 2;

-- 2.4. Columnas que parecen fecha pero no son timestamptz
-- SELECT table_schema, table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema IN ('taxonomy','catalog','pricing','price_audit',
--                        'promotions','combos','inventory','bulk','read_model')
--   AND (column_name ~ '(fecha|_at$|_from$|_to$|expires|occurred)')
--   AND data_type IN ('date','text','character varying','bigint','integer')
-- ORDER BY 1, 2, 3;

-- 2.5. Tablas sin created_at
-- SELECT t.nspname AS schema, t.relname AS tabla
-- FROM pg_class t
-- JOIN pg_namespace n ON n.oid = t.relnamespace
-- WHERE t.relkind = 'r'
--   AND n.nspname IN ('taxonomy','catalog','pricing','price_audit',
--                     'promotions','combos','inventory','bulk','read_model')
--   AND NOT EXISTS (
--     SELECT 1 FROM pg_attribute a
--     WHERE a.attrelid = t.oid
--       AND a.attname = 'created_at'
--       AND NOT a.attisdropped
--   )
-- ORDER BY 1, 2;

-- 2.6. Constraints e indices sin prefijo
-- SELECT n.nspname AS schema, c.relname AS objeto,
--        CASE c.relkind WHEN 'r' THEN 'tabla' ELSE 'indice' END AS tipo
-- FROM pg_class c
-- JOIN pg_namespace n ON n.oid = c.relnamespace
-- WHERE n.nspname IN ('taxonomy','catalog','pricing','price_audit',
--                     'promotions','combos','inventory','bulk','read_model')
--   AND c.relkind IN ('r','i')
--   AND c.relname !~ '^(ix_|uq_|pk_|fk_|ck_)'
-- ORDER BY 1, 2;


-- =============================================================================
-- SECCION 3 — CHECKS DE DATOS (opcional)
-- Ejecutar sobre datos de prueba, no sobre una base recien creada.
-- =============================================================================

-- 3.1. Unicidades de negocio exigidas por el modelo
-- SELECT 'brands.nombre_normalizado' AS unicidad, COUNT(*) AS duplicados
-- FROM (SELECT nombre_normalizado FROM taxonomy.brands
--       GROUP BY nombre_normalizado HAVING COUNT(*) > 1) d
-- UNION ALL
-- SELECT 'categories.slug', COUNT(*)
-- FROM (SELECT slug FROM taxonomy.categories GROUP BY slug HAVING COUNT(*) > 1) d
-- UNION ALL
-- SELECT 'stock_balance(sku, location_id)', COUNT(*)
-- FROM (SELECT sku, location_id FROM inventory.stock_balance
--       GROUP BY sku, location_id HAVING COUNT(*) > 1) d
-- UNION ALL
-- SELECT 'coupon_uses(order_id, cupon_id)', COUNT(*)
-- FROM (SELECT order_id, cupon_id FROM promotions.coupon_uses
--       GROUP BY order_id, cupon_id HAVING COUNT(*) > 1) d;

-- 3.2. Reservas coherentes con su saldo
-- SELECT r.id AS reservation_id, r.estado, r.expires_at, r.created_at
-- FROM inventory.reservations r
-- WHERE r.estado = 'ACTIVA'
--   AND r.expires_at IS NOT NULL
--   AND r.expires_at < now();

-- 3.3. Outbox con publicaciones fallidas
-- SELECT id, event_name, attempts, last_error, occurred_at
-- FROM [nombre_schema].outbox
-- WHERE published_at IS NULL
--   AND attempts > 0
-- ORDER BY occurred_at;

-- 3.4. Tablas con estado y deleted_at usados a la vez
-- SELECT t.nspname AS schema, t.relname AS tabla
-- FROM pg_class t
-- JOIN pg_namespace n ON n.oid = t.relnamespace
-- WHERE t.relkind = 'r'
--   AND n.nspname IN ('taxonomy','catalog','pricing','promotions','combos','inventory')
--   AND EXISTS (SELECT 1 FROM pg_attribute a
--               WHERE a.attrelid = t.oid AND a.attname = 'estado' AND NOT a.attisdropped)
--   AND EXISTS (SELECT 1 FROM pg_attribute a
--               WHERE a.attrelid = t.oid AND a.attname = 'deleted_at' AND NOT a.attisdropped);

-- 3.5. Huellas de estado / deleted_at divergentes
-- SELECT id, estado, deleted_at
-- FROM [nombre_schema].[nombre_tabla]
-- WHERE estado = 'INACTIVO' AND deleted_at IS NOT NULL;