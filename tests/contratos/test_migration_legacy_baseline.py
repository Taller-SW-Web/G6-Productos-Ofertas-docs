"""Contratos de reconciliacion; no requiere Supabase, psql ni credenciales."""
import hashlib
import importlib.util
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
RUNNER = ROOT / 'datos' / 'deploy' / 'migrate.py'
spec = importlib.util.spec_from_file_location('g6_migrations', RUNNER)
migrations = importlib.util.module_from_spec(spec)
spec.loader.exec_module(migrations)


class LegacyMigrationChecks(unittest.TestCase):
    def test_applied_files_checksums_not_changed(self):
        cases = {
            'datos/inventory-svc/migrations/0002_order_id_operaciones_disponibilidad.sql':
                'fb34676d4583f6923d04ad2e86acd55857b4a7a63fe3c7b78a61b5ed1bbe148a',
            'datos/promotions/migrations/0004_coupon_idempotency_receipts.sql':
                '84a628ee569abbe62524e8874505f3440ce299487d4cba8d1b88647b8743e061',
            'datos/inventory-svc/migrations/0001_inventory_initial.sql':
                '3f9db5f62391680a5fae6d16a77a86b67cf0b9d02837bf22c6b73890165bd0b8',
        }
        for path, expected in cases.items():
            with self.subTest(path=path):
                content = (ROOT / path).read_bytes().decode('utf-8-sig').replace('\r\n', '\n')
                self.assertEqual(hashlib.sha256(content.encode('utf-8')).hexdigest(), expected)

    def test_legacy_inventory_never_reapplies_0001(self):
        out = migrations.render_script('inventory', migrations.load_migrations('inventory', ROOT / 'datos'))
        self.assertIn('0001_create_inventory.sql', out)
        self.assertIn('b93267e287fbf9245881473beb53c1b5715f132b972348225f3786e2fe9cbb69', out)
        self.assertIn('INVENTORY_LEGACY_CHECKSUM_MISMATCH', out)
        self.assertIn('INVENTORY_DUPLICATE_BASELINE', out)
        self.assertIn('INVENTORY_LEGACY_0002_STRUCTURE_MISMATCH', out)
        self.assertIn('INVENTORY_RUNTIME_REQUIRED', out)
        self.assertIn('WHERE version IN (\'0001_inventory_initial.sql\',\'0001_create_inventory.sql\')', out)
        self.assertIn('0002_order_id_operaciones_disponibilidad.sql', out)

    def test_promotion_runner_stays_isolated(self):
        out = migrations.render_script('promotions', migrations.load_migrations('promotions', ROOT / 'datos'))
        self.assertIn('0004_coupon_idempotency_receipts.sql', out)
        self.assertNotIn('0001_create_inventory.sql', out)

    def test_rejects_nontransactional_migration(self):
        with tempfile.TemporaryDirectory() as folder:
            path = pathlib.Path(folder) / 'inventory-svc' / 'migrations'
            path.mkdir(parents=True)
            (path / '0001_bad.sql').write_text('BEGIN;\nSELECT 1;\nCOMMIT;\n', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'no apta para transaccion'):
                migrations.load_migrations('inventory', pathlib.Path(folder))

    def test_inventory_preflight_has_no_ledger_writes(self):
        sql = migrations.legacy_inventory_guard('inventory.schema_migrations')
        self.assertNotIn('INSERT INTO inventory.schema_migrations', sql)
        self.assertNotIn('UPDATE inventory.schema_migrations', sql)
        self.assertNotIn('DELETE FROM inventory.schema_migrations', sql)


if __name__ == '__main__':
    unittest.main()
