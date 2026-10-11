"""Migraciones por owner: SHA-256 UTF-8/LF, psql y transaccion por version.

Inventory reconoce el baseline historico exacto de Supabase sin modificar su fila.
No equipara los SQL 0001: solo valida el legado conocido y objetos minimos.
"""
import argparse
import hashlib
import pathlib
import re
import subprocess
import sys

SCHEMA_DIRS = {
    'taxonomy': 'taxonomy',
    'catalog': 'catalog-svc',
    'pricing': 'pricing',
    'price_audit': 'price_audit',
    'promotions': 'promotions',
    'combos': 'combos',
    'inventory': 'inventory-svc',
    'bulk': 'bulk',
}
SCHEMAS = tuple(SCHEMA_DIRS)
LEGACY_INVENTORY = (
    '0001_create_inventory.sql',
    'b93267e287fbf9245881473beb53c1b5715f132b972348225f3786e2fe9cbb69',
)


def literal(value):
    return "'" + value.replace("'", "''") + "'"


def load_migrations(schema, root):
    folder = root / SCHEMA_DIRS[schema] / 'migrations'
    if not folder.is_dir():
        raise ValueError(f'No existen migraciones en {folder}')
    files = sorted(folder.glob('*.sql'))
    if not files:
        raise ValueError(f'No existen migraciones en {folder}')
    result = []
    for number, file in enumerate(files, 1):
        if not re.fullmatch(rf'{number:04d}_[a-z0-9_]+\.sql', file.name):
            raise ValueError(f'Orden/nombre invalido: {file.name}')
        source = file.read_bytes().decode('utf-8-sig').replace('\r\n', '\n')
        if re.search(r'(?im)^\s*(BEGIN\s*;|COMMIT\s*;|ROLLBACK\s*;|CREATE\s+INDEX\s+CONCURRENTLY\b)', source):
            raise ValueError(f'Migracion no apta para transaccion: {file.name}')
        result.append((file.name, hashlib.sha256(source.encode('utf-8')).hexdigest(), source))
    return result


def legacy_inventory_guard(ledger):
    """Reconciliar identidad historica solo con firma exacta y esquema coherente.

    No inserta alias, no toca 0001, ni certifica igualdad binaria del DDL perdido.
    """
    legacy_name, legacy_sha = map(literal, LEGACY_INVENTORY)
    canonical = literal('0001_inventory_initial.sql')
    migrated = literal('0002_order_id_operaciones_disponibilidad.sql')
    return f"""DO $legacy_inventory$
BEGIN
  IF EXISTS (SELECT 1 FROM {ledger} WHERE version={legacy_name}) THEN
    IF NOT EXISTS (SELECT 1 FROM {ledger}
       WHERE version={legacy_name} AND checksum={legacy_sha}) THEN
      RAISE EXCEPTION 'INVENTORY_LEGACY_CHECKSUM_MISMATCH';
    END IF;
    IF EXISTS (SELECT 1 FROM {ledger} WHERE version={canonical}) THEN
      RAISE EXCEPTION 'INVENTORY_DUPLICATE_BASELINE';
    END IF;
    IF to_regclass('inventory.reservations') IS NULL
       OR to_regclass('inventory.inventory_operations') IS NULL
       OR to_regclass('inventory.locations') IS NULL
       OR to_regclass('inventory.stock_balance') IS NULL
       OR to_regclass('inventory.kardex') IS NULL THEN
      RAISE EXCEPTION 'INVENTORY_LEGACY_STRUCTURE_MISSING';
    END IF;
    IF EXISTS (SELECT 1 FROM {ledger} WHERE version={migrated}) THEN
      IF NOT EXISTS (SELECT 1 FROM pg_attribute
          WHERE attrelid='inventory.reservations'::regclass AND attname='order_id'
            AND atttypid='text'::regtype AND NOT attisdropped)
        OR NOT EXISTS (SELECT 1 FROM pg_attribute
          WHERE attrelid='inventory.inventory_operations'::regclass AND attname='order_id'
            AND atttypid='text'::regtype AND NOT attisdropped)
        OR to_regclass('inventory.commercial_fulfillment_routes') IS NULL THEN
        RAISE EXCEPTION 'INVENTORY_LEGACY_0002_STRUCTURE_MISMATCH';
      END IF;
    ELSE
      IF NOT EXISTS (SELECT 1 FROM pg_attribute
          WHERE attrelid='inventory.reservations'::regclass AND attname='order_id'
            AND atttypid='uuid'::regtype AND NOT attisdropped)
        OR NOT EXISTS (SELECT 1 FROM pg_attribute
          WHERE attrelid='inventory.inventory_operations'::regclass AND attname='order_id'
            AND atttypid='uuid'::regtype AND NOT attisdropped)
        OR to_regclass('inventory.commercial_fulfillment_routes') IS NOT NULL THEN
        RAISE EXCEPTION 'INVENTORY_LEGACY_PRE_0002_STRUCTURE_MISMATCH';
      END IF;
    END IF;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM {ledger}
      WHERE version IN ({legacy_name},{canonical}))
    AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='inventory' AND c.relkind='r'
        AND c.relname<>'schema_migrations') THEN
    RAISE EXCEPTION 'INVENTORY_BASELINE_REQUIRED: no registrar un 0001 ficticio';
  END IF;
END $legacy_inventory$;"""


def render_script(schema, migrations):
    ledger = f'{schema}.schema_migrations'
    manifest_names = [m[0] for m in migrations]
    if schema == 'inventory':
        manifest_names.append(LEGACY_INVENTORY[0])
    manifest = ','.join(literal(name) for name in manifest_names)
    sql = [
        r'\set ON_ERROR_STOP on',
        f'SET ROLE po_{schema}_owner;',
        f"SELECT pg_advisory_lock(hashtextextended('po:migrations:{schema}', 0));",
        f'CREATE TABLE IF NOT EXISTS {ledger} ('
        'version text PRIMARY KEY, checksum text NOT NULL, '
        'applied_at timestamptz NOT NULL DEFAULT now());',
        f"DO $guard$ BEGIN IF EXISTS (SELECT 1 FROM {ledger} "
        f"WHERE version NOT IN ({manifest})) THEN "
        "RAISE EXCEPTION 'Historial aplicado ausente del checkout'; "
        'END IF; END $guard$;',
    ]
    if schema == 'inventory':
        sql.append(legacy_inventory_guard(ledger))
        sql.append("""DO $inventory_runtime$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles
     WHERE rolname='po_inventory_runtime' AND NOT rolcanlogin AND NOT rolsuper
       AND NOT rolcreatedb AND NOT rolcreaterole AND NOT rolreplication
       AND NOT rolbypassrls)
    OR pg_has_role('po_inventory_runtime','po_inventory_owner','MEMBER')
    OR NOT has_schema_privilege('po_inventory_runtime','inventory','USAGE')
    OR has_schema_privilege('po_inventory_runtime','inventory','CREATE') THEN
    RAISE EXCEPTION 'INVENTORY_RUNTIME_REQUIRED: ejecutar provision-runtime.sql';
  END IF;
END $inventory_runtime$;""")
    for index, (name, checksum, source) in enumerate(migrations):
        n, h = literal(name), literal(checksum)
        later = [x[0] for x in migrations[index + 1:]]
        if later:
            successors = ','.join(literal(x) for x in later)
            prior_accepted = [name]
            if schema == 'inventory' and index == 0:
                prior_accepted.append(LEGACY_INVENTORY[0])
            accepted = ','.join(literal(x) for x in prior_accepted)
            sql.append(
                f"DO $gap$ BEGIN IF EXISTS (SELECT 1 FROM {ledger} WHERE version IN ({successors})) "
                f"AND NOT EXISTS (SELECT 1 FROM {ledger} WHERE version IN ({accepted})) "
                f"THEN RAISE EXCEPTION 'Historial con hueco: {name}'; "
                'END IF; END $gap$;'
            )
        sql.append(
            f"DO $checksum$ BEGIN IF EXISTS (SELECT 1 FROM {ledger} "
            f"WHERE version={n} AND checksum<>{h}) THEN "
            f"RAISE EXCEPTION 'Checksum alterado: {name}'; "
            'END IF; END $checksum$;'
        )
        if schema == 'inventory' and index == 0:
            legacy = literal(LEGACY_INVENTORY[0])
            apply_expr = (f'NOT EXISTS (SELECT 1 FROM {ledger} '
                          f'WHERE version IN ({n},{legacy}))')
        else:
            apply_expr = f'NOT EXISTS (SELECT 1 FROM {ledger} WHERE version={n})'
        sql.extend([
            f'SELECT {apply_expr} AS apply_migration \\gset',
            r'\if :apply_migration',
            'BEGIN;',
            source,
            f'INSERT INTO {ledger}(version, checksum) VALUES ({n}, {h});',
            'COMMIT;',
            r'\endif',
        ])
    sql.extend([
        f'SELECT version, checksum, applied_at FROM {ledger} ORDER BY version;',
        f"SELECT pg_advisory_unlock(hashtextextended('po:migrations:{schema}', 0));",
    ])
    return '\n'.join(sql) + '\n'


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('schema', choices=SCHEMAS)
    parser.add_argument('--root', type=pathlib.Path,
                        default=pathlib.Path(__file__).resolve().parent.parent)
    parser.add_argument('--psql', default='psql')
    parser.add_argument('--container', help='Contenedor PostgreSQL local de ensayo')
    parser.add_argument('--render-sql', action='store_true',
                        help='Mostrar script generado sin conectarse a la BD')
    args = parser.parse_args(argv)
    sql = render_script(args.schema, load_migrations(args.schema, args.root))
    if args.render_sql:
        print(sql, end='')
        return 0
    command = (['docker', 'exec', '-i', args.container, 'psql', '-U', 'postgres']
               if args.container else [args.psql])
    result = subprocess.run(command + ['-X', '-v', 'ON_ERROR_STOP=1'],
                            input=sql, text=True, encoding='utf-8')
    return result.returncode


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
