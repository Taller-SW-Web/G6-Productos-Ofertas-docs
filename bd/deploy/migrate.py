"""Migraciones transaccionales por owner; stdlib y psql, sin credenciales en argumentos."""
import argparse
import hashlib
import pathlib
import re
import subprocess
import sys

SCHEMA_DIRS = {
    'taxonomy': 'taxonomy',
    'catalog': 'catalog-svg',
    'pricing': 'pricing',
    'price_audit': 'price_audit',
    'promotions': 'promotions',
    'combos': 'combos',
    'inventory': 'inventory-svc',
    'bulk': 'bulk',
}
SCHEMAS = tuple(SCHEMA_DIRS.keys())

def literal(value):
    return "'" + value.replace("'", "''") + "'"

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('schema', choices=SCHEMAS)
    parser.add_argument('--root', type=pathlib.Path, default=pathlib.Path(__file__).resolve().parent.parent)
    parser.add_argument('--psql', default='psql')
    parser.add_argument('--container', help='Contenedor PostgreSQL local de validación')
    args = parser.parse_args()
    folder = args.root / SCHEMA_DIRS[args.schema] / 'migrations'
    if not folder.exists():
        raise ValueError(f'No existen migraciones en {folder}')
    files = sorted(folder.glob('*.sql'))
    if not files:
        raise ValueError(f'No existen migraciones en {folder}')
    migrations = []
    for number, file in enumerate(files, 1):
        if not re.fullmatch(rf'{number:04d}_[a-z0-9_]+\.sql', file.name):
            raise ValueError(f'Orden/nombre inválido: {file.name}; se esperaba {number:04d}_descripcion.sql')
        source = file.read_bytes().decode('utf-8-sig').replace('\r\n', '\n')
        checksum = hashlib.sha256(source.encode('utf-8')).hexdigest()
        migrations.append((file.name, checksum, source))
    s = args.schema
    ledger = f'{s}.schema_migrations'
    sql = [r'\set ON_ERROR_STOP on', f'SET ROLE po_{s}_owner;',
           f"SELECT pg_advisory_lock(hashtextextended('po:migrations:{s}', 0));",
           f'CREATE TABLE IF NOT EXISTS {ledger} (version text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now());']
    manifest = ','.join(literal(m[0]) for m in migrations)
    sql += [f"DO $guard$ BEGIN IF EXISTS (SELECT 1 FROM {ledger} WHERE version NOT IN ({manifest})) THEN RAISE EXCEPTION 'Historial aplicado ausente del checkout'; END IF; END $guard$;"]
    for name, _, _ in migrations:
        n = literal(name)
        sql += [f"DO $guard$ BEGIN IF EXISTS (SELECT 1 FROM {ledger} WHERE version>{n}) AND NOT EXISTS (SELECT 1 FROM {ledger} WHERE version={n}) THEN RAISE EXCEPTION 'Historial con hueco: {name}'; END IF; END $guard$;"]
    for name, checksum, source in migrations:
        n, h = literal(name), literal(checksum)
        sql += [f"DO $guard$ BEGIN IF EXISTS (SELECT 1 FROM {ledger} WHERE version={n} AND checksum<>{h}) THEN RAISE EXCEPTION 'Checksum alterado: {name}'; END IF; END $guard$;",
                f'SELECT NOT EXISTS (SELECT 1 FROM {ledger} WHERE version={n}) AS apply_migration \\gset',
                r'\if :apply_migration', 'BEGIN;', source,
                f'INSERT INTO {ledger}(version, checksum) VALUES ({n}, {h});', 'COMMIT;', r'\endif']
    sql += [f'SELECT version, checksum FROM {ledger} ORDER BY version;',
            f"SELECT pg_advisory_unlock(hashtextextended('po:migrations:{s}', 0));"]
    command = (['docker', 'exec', '-i', args.container, 'psql', '-U', 'postgres'] if args.container else [args.psql])
    result = subprocess.run(command + ['-X', '-v', 'ON_ERROR_STOP=1'],
                            input='\n'.join(sql)+'\n', text=True, encoding='utf-8')
    return result.returncode

if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
