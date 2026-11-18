"""Fallar si el entorno omite el validador opcional de date-time."""
from copy import deepcopy
from importlib.metadata import version
import json
from pathlib import Path
import sys

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tests/contratos'))
from test_asyncapi_h4_event_instances import AsyncApiH4EventInstanceTests

checker = Draft202012Validator.FORMAT_CHECKER
if 'date-time' not in checker.checkers:
    raise RuntimeError('date-time no registrado: instalar requirements-validation.txt')
if checker.conforms('not-a-date', 'date-time'):
    raise RuntimeError('El entorno acepta una fecha inválida')
if not checker.conforms('2026-11-05T19:00:00Z', 'date-time'):
    raise RuntimeError('El entorno rechaza una fecha RFC 3339 válida')

# Usar el mismo schema, fixture y FORMAT_CHECKER de las 61 pruebas existentes.
AsyncApiH4EventInstanceTests.setUpClass()
validator = AsyncApiH4EventInstanceTests.validator_for('InventoryStockChanged')
valid = deepcopy(AsyncApiH4EventInstanceTests.fixtures['inventoryStockChanged'])
validator.validate(valid)
invalid = deepcopy(valid)
invalid['data']['updated_at'] = 'not-a-date'
errors = list(validator.iter_errors(invalid))
if not any(list(error.absolute_path) == ['data', 'updated_at'] and error.validator == 'format' for error in errors):
    raise RuntimeError('InventoryStockChanged no rechaza updated_at por formato')

report = {
    'python': sys.version.split()[0],
    'dependencies': {name: version(name) for name in ('jsonschema', 'rfc3339-validator', 'six')},
    'dateTimeRegistered': True,
    'invalidDateRejected': True,
    'validDateAccepted': True,
    'validInventoryFixtureAccepted': True,
    'invalidInventoryUpdatedAtRejected': True,
    'errorPath': 'data/updated_at',
    'validator': 'format',
}
output = ROOT / 'swagger/reports/date-time-environment.json'
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
