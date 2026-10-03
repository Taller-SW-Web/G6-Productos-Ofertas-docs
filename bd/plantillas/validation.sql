-- =============================================================================
-- _TEMPLATE 窶・validation.sql
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
-- SECCION 0 窶・CONFIGURACION
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
-- SECCION 1 窶・VERIFICACION GLOBAL
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
  AND (a.attidentity <> '' OR EXISTS (
        SELECT 1 FROM pg_attrdef ad
        WHERE ad.adrelid = a.attrelid AND ad.adnum = a.attnum
          AND pg_get_expr(ad.adbin, ad.adrelid) LIKE 'nextval(%')
      ))
