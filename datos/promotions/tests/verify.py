"""Prueba de #53 en un contenedor PostgreSQL local vacío; nunca contra Supabase."""
import argparse
import concurrent.futures
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import threading
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[3]
FOLDER = ROOT / 'bd' / 'promotions'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--container', required=True)
    parser.add_argument('--report', type=pathlib.Path, help='Guardar el resultado JSON sin credenciales')
    args = parser.parse_args()
    checks = []

    def check(label, condition):
        if not condition:
            raise AssertionError(label)
        checks.append(label)

    def sql(source, database='postgres', success=True):
        result = subprocess.run(
            ['docker', 'exec', '-i', args.container, 'psql', '-U', 'postgres',
             '-d', database, '-X', '-q', '-A', '-t', '-v', 'ON_ERROR_STOP=1'],
            input=source.encode('utf-8'), capture_output=True, timeout=30)
        if success and result.returncode:
            raise RuntimeError(result.stderr.decode('utf-8'))
        return result

    def text(result):
        return result.stdout.decode('utf-8').strip()

    def migrate(root=None):
        command = [sys.executable, str(ROOT / 'bd' / 'deploy' / 'migrate.py'),
                   'promotions', '--container', args.container]
        if root:
            command.extend(['--root', str(root)])
        return subprocess.run(command, capture_output=True, timeout=45,
                              encoding='utf-8', errors='replace',
                              env={**os.environ, 'PYTHONUTF8': '0'})

    check('base objetivo vacía', text(sql("SELECT NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname='promotions');")) == 't')
    bootstrap = (ROOT / 'bd' / 'deploy' / 'bootstrap.sql').read_text(encoding='utf-8')
    provision = (FOLDER / 'provision-runtime.sql').read_text(encoding='utf-8')
    migrations = {file.name: file.read_text(encoding='utf-8-sig').replace('\r\n', '\n')
                  for file in sorted((FOLDER / 'migrations').glob('*.sql'))}
    migration = '\n'.join(migrations.values())
    sql(bootstrap + '\n' + provision)
    first = migrate()
    if first.returncode:
        raise RuntimeError(first.stderr)
    check('migración inicial runner', first.returncode == 0)
    digests = {name: hashlib.sha256(source.encode()).hexdigest() for name, source in migrations.items()}
    ledger_sql = "SELECT version||':'||checksum||':'||applied_at::text FROM promotions.schema_migrations ORDER BY version;"
    ledger = text(sql(ledger_sql))
    check('checksums registrados', all(name + ':' + digest + ':' in ledger for name, digest in digests.items()))
    check('historial completo', len(ledger.splitlines()) == len(migrations))
    repeated = migrate()
    check('repetición sin aplicar de nuevo', repeated.returncode == 0 and text(sql(ledger_sql)) == ledger)
    validation_source = (FOLDER / 'validation.sql').read_text(encoding='utf-8')
    validation = text(sql(validation_source))
    match = re.search(r'\{"assertions"\s*:\s*(\d+),\s*"result"\s*:\s*"PASS"\}', validation)
    check('assertions SQL', match is not None)
    assertions = int(match.group(1))
    check('fixtures SQL con rollback', text(sql("SELECT (SELECT count(*) FROM promotions.promotions)+(SELECT count(*) FROM promotions.coupons)+(SELECT count(*) FROM promotions.inbox)+(SELECT count(*) FROM promotions.outbox);")) == '0')
    # Probar que la validación realmente detecta regresiones de convención.
    # Cada alteración vive en su transacción/conexión desechable y se revierte.
    for label, alteration, expected in [
        ('detecta created_at ausente', 'ALTER TABLE promotions.combination_policy DROP COLUMN created_at;', 'combination_policy.created_at obligatorio'),
        ('detecta timestamp nullable', 'ALTER TABLE promotions.catalog_projection ALTER COLUMN created_at DROP NOT NULL;', 'catalog_projection.created_at obligatorio'),
        ('detecta timestamp sin zona', 'ALTER TABLE promotions.stock_projection ALTER COLUMN created_at TYPE timestamp;', 'stock_projection.created_at obligatorio'),
        ('detecta default ausente', 'ALTER TABLE promotions.coupon_uses ALTER COLUMN updated_at DROP DEFAULT;', 'coupon_uses.updated_at obligatorio'),
        ('detecta trigger ausente', 'DROP TRIGGER trg_promotion_scopes_updated_at ON promotions.promotion_scopes;', 'promotion_scopes.updated_at trigger'),
        ('detecta FK sin RESTRICT', 'ALTER TABLE promotions.coupons DROP CONSTRAINT fk_coupons_promotion; ALTER TABLE promotions.coupons ADD CONSTRAINT fk_coupons_promotion FOREIGN KEY(promotion_id) REFERENCES promotions.promotions(id);', 'seis FK con RESTRICT explícito'),
        ('detecta customer_ref text', 'ALTER TABLE promotions.coupon_uses ALTER COLUMN customer_ref TYPE text USING customer_ref::text;', 'customer_ref permanece UUID'),
        ('detecta nombre fuera del inventario aprobado', 'ALTER TABLE promotions.promotions RENAME TO promotion;', 'solo entidades del contexto y ledger')]:
        rejected = sql('BEGIN; SET LOCAL ROLE po_promotions_owner;\n' + alteration + '\n' + validation_source, success=False)
        check(label, rejected.returncode != 0 and 'ASSERTION FAILED: ' + expected in rejected.stderr.decode('utf-8'))
    check('regresiones de convención revertidas', text(sql("SELECT count(*)=6 AND bool_and(confdeltype='r') FROM pg_constraint WHERE contype='f' AND connamespace='promotions'::regnamespace;")) == 't')
    with tempfile.TemporaryDirectory(prefix='po-promotions-test-') as tmp:
        fixtures = pathlib.Path(tmp) / 'promotions' / 'migrations'
        fixtures.mkdir(parents=True)
        initial = fixtures / '0001_promotions_persistence.sql'
        for name, source in migrations.items():
            (fixtures / name).write_text(source, encoding='utf-8', newline='\n')
        initial.write_text(migrations[initial.name] + '\n-- altered checksum fixture\n', encoding='utf-8')
        altered = migrate(pathlib.Path(tmp))
        check('checksum alterado rechazado', altered.returncode != 0 and 'Checksum alterado' in altered.stderr)
        initial.write_text(migrations[initial.name], encoding='utf-8', newline='\n')
        # Archivo deliberadamente inválido, solo fixture temporal del ejecutor.
        (fixtures / f'{len(migrations)+1:04d}_invalid_fixture.sql').write_text(
            'CREATE TABLE promotions.invalid_fixture(id integer);\nSELECT no_such_function_for_test();\n', encoding='utf-8')
        invalid = migrate(pathlib.Path(tmp))
        check('migración fallida se detiene', invalid.returncode != 0 and 'no_such_function_for_test' in invalid.stderr)
        check('rollback DDL y ledger', text(sql(f"SELECT to_regclass('promotions.invalid_fixture') IS NULL AND (SELECT count(*) FROM promotions.schema_migrations)={len(migrations)};")) == 't')

    for label, statement in [
        ('runtime sin DDL', 'CREATE TABLE promotions.forbidden(id integer);'),
        ('runtime sin otro schema', 'CREATE TABLE catalog.forbidden(id integer);'),
        ('runtime sin borrar historia', 'DELETE FROM promotions.coupon_uses;'),
        ('runtime sin editar pedido', "UPDATE promotions.coupon_uses SET order_id='x';"),
        ('runtime sin editar outbox', "UPDATE promotions.outbox SET data='{}';"),
        ('runtime sin editar ledger', 'DELETE FROM promotions.schema_migrations;')]:
        result = sql('SET ROLE po_promotions_runtime;\n' + statement, success=False)
        check(label, result.returncode != 0 and 'permission denied' in result.stderr.decode('utf-8'))

    # Concurrencia requiere commits entre conexiones: aislarla en una base nueva
    # y efímera para conservar la base validada sin historia comercial de prueba.
    race_db = 'po_promotions_test_' + uuid.uuid4().hex
    created = False
    try:
        sql('CREATE DATABASE ' + race_db + ';')
        created = True
        first_name = next(iter(migrations))
        sql(bootstrap + '\nSET ROLE po_promotions_owner; BEGIN;\n' + migrations[first_name] + '\nCOMMIT;', race_db)
        sql("""
SET ROLE po_promotions_runtime;
BEGIN;
INSERT INTO promotions.promotions(id,name,discount_type,discount_value,modality,state,valid_from,valid_until,priority,enabled_channels)
VALUES('54000000-0000-0000-0000-000000000001','Upgrade','PORCENTAJE',10,'CUPON','ACTIVO','2000-01-01','2100-01-01',1,ARRAY['MARKETPLACE']);
INSERT INTO promotions.promotion_scopes(promotion_id,product_id,created_at) VALUES('54000000-0000-0000-0000-000000000001','upgrade-product','2000-01-01');
INSERT INTO promotions.combination_policy(promotion_id,pricing_offer,automatic_promotion,coupon,updated_at) VALUES('54000000-0000-0000-0000-000000000001',false,false,false,'2000-01-01');
INSERT INTO promotions.coupons(id,promotion_id,code,state,cancellation_policy) VALUES('54000000-0000-0000-0000-000000000011','54000000-0000-0000-0000-000000000001','UPGRADE','ACTIVO','RESTAURAR_EN_CANCELACION');
SELECT promotions.fn_consume_coupon('upgrade-order','54000000-0000-0000-0000-000000000011','54000000-0000-0000-0000-000000000099','MARKETPLACE','2026-10-03');
SELECT promotions.fn_restore_coupon('upgrade-order','2026-10-04');
INSERT INTO promotions.price_projection(sku,channel_id,snapshot,source_occurred_at,source_message_id,updated_at) VALUES('upgrade-fixture','RETAIL','{"preserved":true}','2026-10-03','upgrade-price','2000-01-01');
INSERT INTO promotions.catalog_projection(reference_type,reference_id,product_id,active,snapshot,source_occurred_at,source_message_id,updated_at) VALUES('PRODUCTO','upgrade-product','upgrade-product',true,'{"preserved":true}','2026-10-03','upgrade-catalog','2000-01-01');
INSERT INTO promotions.stock_projection(sku,availability,snapshot,source_occurred_at,source_message_id,updated_at) VALUES('upgrade-fixture','DISPONIBLE','{"preserved":true}','2026-10-03','upgrade-stock','2000-01-01');
INSERT INTO promotions.inbox(message_id,handler,envelope,received_at) VALUES('upgrade-inbox','consume','{"message_id":"upgrade-inbox","schema_version":1,"occurred_at":"2026-10-03T00:00:00Z","correlation_id":"upgrade","producer":"ventas-svc","kind":"command","name":"promotions.coupon.consumption.requested","data":{}}','2000-01-01');
COMMIT;
""", race_db)
        upgrade_tables = ('combination_policy','coupon_uses','catalog_projection','price_projection','stock_projection','inbox','promotion_scopes')
        before_upgrade = {table: json.loads(text(sql(f'SELECT jsonb_agg(to_jsonb(t)) FROM promotions.{table} t;', race_db))) for table in upgrade_tables}
        for name, source in migrations.items():
            if name != first_name:
                sql('SET ROLE po_promotions_owner; BEGIN;\n' + source + '\nCOMMIT;', race_db)
        check('upgrade conserva snapshot y asigna id', text(sql("SELECT id IS NOT NULL AND snapshot='{\"preserved\":true}'::jsonb FROM promotions.price_projection WHERE sku='upgrade-fixture' AND channel_id='RETAIL';", race_db)) == 't')
        for table in upgrade_tables:
            after = json.loads(text(sql(f'SELECT jsonb_agg(to_jsonb(t)) FROM promotions.{table} t;', race_db)))
            check('upgrade preserva datos de ' + table, len(after) == len(before_upgrade[table]) and all(any(all(row.get(key) == value for key, value in old.items()) for row in after) for old in before_upgrade[table]))
        check('upgrade rellena timestamps históricos', text(sql("""
SELECT (SELECT created_at=updated_at FROM promotions.combination_policy)
AND (SELECT created_at=consumed_at AND updated_at=restored_at AND customer_ref='54000000-0000-0000-0000-000000000099'::uuid FROM promotions.coupon_uses)
AND (SELECT created_at=updated_at FROM promotions.catalog_projection)
AND (SELECT created_at=updated_at FROM promotions.price_projection)
AND (SELECT created_at=updated_at FROM promotions.stock_projection)
AND (SELECT created_at=received_at FROM promotions.inbox)
AND (SELECT updated_at=created_at FROM promotions.promotion_scopes);
""", race_db)) == 't')
        # El snapshot histórico creado en 0001 sigue protegido después del upgrade.
        immutable = sql("SET ROLE po_promotions_runtime; UPDATE promotions.coupon_uses SET restored_at='2026-10-05' WHERE order_id='upgrade-order';", race_db, success=False)
        check('upgrade mantiene restitución histórica inmutable', immutable.returncode != 0 and 'COUPON_HISTORY_IMMUTABLE' in immutable.stderr.decode('utf-8'))
        sql("""
SET ROLE po_promotions_runtime;
BEGIN;
INSERT INTO promotions.promotions(id,name,discount_type,discount_value,modality,state,valid_from,valid_until,priority,enabled_channels)
VALUES('53000000-0000-0000-0000-000000000001','Race','PORCENTAJE',10,'CUPON','ACTIVO','2000-01-01','2100-01-01',1,ARRAY['MARKETPLACE']);
INSERT INTO promotions.promotion_scopes(promotion_id,product_id) VALUES('53000000-0000-0000-0000-000000000001','race-product');
INSERT INTO promotions.combination_policy(promotion_id,pricing_offer,automatic_promotion,coupon) VALUES('53000000-0000-0000-0000-000000000001',false,false,false);
INSERT INTO promotions.coupons(id,promotion_id,code,state,max_global_uses,max_customer_uses,cancellation_policy) VALUES
('53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000001','RACE-GLOBAL','ACTIVO',1,NULL,'RESTAURAR_EN_CANCELACION'),
('53000000-0000-0000-0000-000000000012','53000000-0000-0000-0000-000000000001','RACE-CUSTOMER','ACTIVO',NULL,1,'RESTAURAR_EN_CANCELACION'),
('53000000-0000-0000-0000-000000000013','53000000-0000-0000-0000-000000000001','RACE-DUPLICATE','ACTIVO',1,NULL,'RESTAURAR_EN_CANCELACION');
COMMIT;
""", race_db)
        check('runtime administra agregado completo', True)

        def race(coupon, orders, customer='NULL', error=None):
            barrier = threading.Barrier(2)

            def worker(order):
                barrier.wait(timeout=10)
                return sql(f"SET ROLE po_promotions_runtime; BEGIN; SELECT promotions.fn_consume_coupon('{order}','{coupon}',{customer},'MARKETPLACE','2026-10-03'); SELECT pg_sleep(0.6); COMMIT;", race_db, success=False)

            with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
                results = list(pool.map(worker, orders))
            successes = [r for r in results if r.returncode == 0]
            if error:
                failures = [r for r in results if r.returncode != 0]
                check('race ' + error, len(successes) == 1 and len(failures) == 1 and error in failures[0].stderr.decode('utf-8'))
            else:
                check('race reentrega ambas responden', len(successes) == 2)
                use_ids = [re.search(r'[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}', text(r)).group(0) for r in successes]
                check('race reentrega mismo uso', use_ids[0] == use_ids[1])
            check('race único consumo ' + coupon, text(sql(f"SELECT count(*) FROM promotions.coupon_uses WHERE coupon_id='{coupon}';", race_db)) == '1')

        race('53000000-0000-0000-0000-000000000011', ['race-global-a', 'race-global-b'], error='COUPON_GLOBAL_LIMIT')
        race('53000000-0000-0000-0000-000000000012', ['race-customer-a', 'race-customer-b'], "'53000000-0000-0000-0000-000000000099'", 'COUPON_CUSTOMER_LIMIT')
        race('53000000-0000-0000-0000-000000000013', ['race-duplicate', 'race-duplicate'])
        winner = text(sql("SELECT order_id FROM promotions.coupon_uses WHERE coupon_id='53000000-0000-0000-0000-000000000011';", race_db))
        restored = text(sql(f"SET ROLE po_promotions_runtime; SELECT outcome FROM promotions.fn_restore_coupon('{winner}','2026-10-04');", race_db))
        check('runtime restituye', restored == 'RESTORED')
        result = sql("SET ROLE po_promotions_runtime; SELECT promotions.fn_consume_coupon('race-reused','53000000-0000-0000-0000-000000000011',NULL,'MARKETPLACE','2026-10-03');", race_db)
        check('cupo restituido reutilizable por otro pedido', bool(re.search(r'[a-f0-9-]{36}', text(result))))
        envelope = json.dumps({'message_id': 'race-inbox', 'schema_version': 1,
                              'occurred_at': '2026-10-03T00:00:00Z', 'correlation_id': 'opaque',
                              'producer': 'ventas-svc', 'kind': 'command',
                              'name': 'promotions.coupon.consumption.requested', 'data': {}})
        check('runtime inbox deduplica', text(sql(f"SET ROLE po_promotions_runtime; SELECT promotions.fn_begin_inbox('{envelope}'::jsonb,'consume'); SELECT promotions.fn_begin_inbox('{envelope}'::jsonb,'consume');", race_db)).splitlines() == ['t', 'f'])
    finally:
        if created:
            # Solo la base que esta ejecución acaba de crear; sin datos ajenos.
            sql('DROP DATABASE ' + race_db + ';')
    check('base original sin fixtures de concurrencia', text(sql('SELECT count(*) FROM promotions.coupon_uses;')) == '0')
    report = json.dumps({'result': 'PASS', 'sql_assertions': assertions,
                      'integration_checks': len(checks), 'checks': checks,
                      'migrations_sha256': digests,
                      'postgres_version': text(sql('SHOW server_version;'))}, ensure_ascii=False, indent=2)
    if args.report:
        args.report.write_text(report + '\n', encoding='utf-8', newline='\n')
    print(report)


if __name__ == '__main__':
    main()
