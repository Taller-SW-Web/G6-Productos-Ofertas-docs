"""Contrastar cuerpos capturados por GET; no ejecuta solicitudes ni valida grants."""
import json
from pathlib import Path
from jsonschema import Draft202012Validator, RefResolver

root = Path(__file__).resolve().parents[1]
spec = json.loads((root / 'reports/studio.json').read_text(encoding='utf-8'))
report = json.loads((root / 'reports/runtime.json').read_text(encoding='utf-8'))
results = []
for request in report['requests']:
    path = request['path'].split('?')[0]
    if path.startswith('/api/v1/productos/por-slug/'):
        contract_path = '/productos/por-slug/{slug}'
    else:
        contract_path = path.removeprefix('/api/v1')
    operation = spec['paths'][contract_path]['get']
    response = operation['responses'].get(str(request.get('status')))
    if response and '$ref' in response:
        with RefResolver.from_schema(spec).resolving(response['$ref']) as resolved:
            response = resolved
    schema = (response or {}).get('content', {}).get('application/json', {}).get('schema')
    errors = []
    if schema and isinstance(request.get('body'), dict):
        validator = Draft202012Validator(schema, resolver=RefResolver.from_schema(spec))
        errors = [{'path': '/'.join(map(str, e.absolute_path)), 'message': e.message} for e in validator.iter_errors(request['body'])]
        result = 'BODY_SCHEMA_PASS' if not errors else 'BODY_SCHEMA_FAIL'
    else:
        result = 'NO_VALIDADO: respuesta no JSON o schema de éxito ausente'
    results.append({'operationId': operation['operationId'], 'status': request.get('status'), 'result': result, 'errors': errors, 'jwtVerified': False, 'backendSha': None})
(root / 'reports/runtime-validation.json').write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding='utf-8')
print(json.dumps(results, indent=2, ensure_ascii=False))
