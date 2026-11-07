"""Generar evidencia sin cuerpos ni valores de negocio para revisión pública."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
raw = json.loads((root / 'reports/runtime.json').read_text(encoding='utf-8'))
checks = json.loads((root / 'reports/runtime-validation.json').read_text(encoding='utf-8'))
summary = {key: raw[key] for key in ('observedAt', 'host', 'browserOrigin', 'backendSha')}
summary['requests'] = []
for request, check in zip(raw['requests'], checks):
    entry = {key: request.get(key) for key in ('method', 'path', 'status', 'headers', 'correlationId', 'durationMs', 'tls')}
    # No publicar slugs obtenidos de datos reales.
    if '/por-slug/' in entry['path']:
        entry['path'] = '/api/v1/productos/por-slug/{slug-real-redactado}?canal=MARKETPLACE'
    body = request.get('body')
    entry['bodySummary'] = {'type': type(body).__name__, 'keys': list(body) if isinstance(body, dict) else [], 'businessValues': '[OMITIDOS]'}
    entry['schemaResult'] = check['result']
    entry['jwtVerified'] = False
    summary['requests'].append(entry)
(root / 'evidence/runtime-summary-2026-11-05.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
print('Resumen guardado sin cuerpos, nombres, SKU, IDs de negocio ni slug real.')
