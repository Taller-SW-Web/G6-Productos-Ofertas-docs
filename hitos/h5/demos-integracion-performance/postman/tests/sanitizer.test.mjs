import test from 'node:test';
import assert from 'node:assert/strict';
import {
  buildSanitizedJunitXml,
  containsSensitiveLeak,
  sanitizeErrorMessage,
  sanitizeNewmanRun,
} from '../scripts/lib/sanitizer-core.mjs';

const SYNTHETIC_JWT = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIifQ.syntheticSignature123456';
const SYNTHETIC_SECRET = 'synth-client-secret-998877';

test('H09: sanitizeErrorMessage elimina cuerpos privados multilinea y correos en excepciones', () => {
  const rawErr = `Unexpected token '<' at 1:1\n{"email":"privado@empresa.pe","secret":"${SYNTHETIC_SECRET}"}\n^`;
  const clean = sanitizeErrorMessage(rawErr, [SYNTHETIC_SECRET]);
  assert.equal(clean.includes('privado@empresa.pe'), false);
  assert.equal(clean.includes(SYNTHETIC_SECRET), false);
  assert.equal(clean.includes('\n'), false);
});

test('sanitizeNewmanRun elimina JWT, headers sensibles, query secrets y reconcilia NOT_RUN e INCONCLUSIVE (H04)', () => {
  const rawSummary = {
    run: {
      timings: { started: 1000, completed: 1450 },
      executions: [
        {
          item: { name: 'PM-002 - Gateway -> Catalog: Listar productos autorizados' },
          request: {
            method: 'GET',
            url: `https://apim-g6-productos-chile.azure-api.net/api/v1/productos?access_token=${SYNTHETIC_SECRET}`,
            header: [
              { key: 'Authorization', value: `Bearer ${SYNTHETIC_JWT}` },
              { key: 'X-Correlation-Id', value: 'corr-12345' },
            ],
          },
          response: {
            code: 200,
            responseTime: 120,
            header: [
              { key: 'Content-Type', value: 'application/json' },
              { key: 'Set-Cookie', value: 'session=super-private-cookie' },
            ],
            stream: Buffer.from(JSON.stringify({ privateEmail: 'secret@example.com', token: SYNTHETIC_JWT })),
          },
          assertions: [{ assertion: 'PM-002: HTTP 200', error: null }],
        },
      ],
    },
  };

  const plannedCases = [
    { pmId: 'PM-002', name: 'PM-002 - Gateway -> Catalog: Listar productos autorizados', method: 'GET', url: 'https://apim-g6-productos-chile.azure-api.net/api/v1/productos', executable: true },
    { pmId: 'PM-005', name: 'PM-005 - Negativo: Autorizacion insuficiente (403 estricto)', method: 'GET', url: 'https://apim-g6-productos-chile.azure-api.net/api/v1/auditoria-precios', executable: false, blockerReason: 'BLOCKED_AUTH' },
  ];

  const sanitized = sanitizeNewmanRun(rawSummary, {
    runId: 'test-sanitize-01',
    environmentName: 'local',
    profile: 'smoke',
    extraSecrets: [SYNTHETIC_JWT, SYNTHETIC_SECRET],
    plannedCases,
  });

  assert.equal(sanitized.totals.planned, 2);
  assert.equal(sanitized.totals.executed, 1);
  assert.equal(sanitized.totals.pass, 1);
  assert.equal(sanitized.totals.notRun, 1);
  assert.equal(sanitized.overallVerdict, 'PARTIAL_NOT_COMPLETE');

  const jsonText = JSON.stringify(sanitized);
  assert.equal(jsonText.includes(SYNTHETIC_JWT), false);
  assert.equal(jsonText.includes(SYNTHETIC_SECRET), false);
  assert.equal(jsonText.includes('super-private-cookie'), false);
  assert.equal(jsonText.includes('secret@example.com'), false);

  const junit = buildSanitizedJunitXml(sanitized, [SYNTHETIC_JWT, SYNTHETIC_SECRET]);
  assert.equal(junit.includes(SYNTHETIC_JWT), false);
  assert.ok(junit.includes('<skipped'));
});

test('sanitizeNewmanRun falla cerrado si el resumen crudo es invalido', () => {
  assert.throws(() => sanitizeNewmanRun(null), /invalido o ausente/i);
});

test('containsSensitiveLeak detecta connection strings', () => {
  assert.equal(containsSensitiveLeak('postgresql://user:pass@host:5432/db').leaked, true);
});
