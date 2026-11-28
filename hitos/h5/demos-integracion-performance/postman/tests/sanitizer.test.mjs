import test from 'node:test';
import assert from 'node:assert/strict';
import { buildSanitizedJunitXml, containsSensitiveLeak, sanitizeNewmanRun } from '../scripts/lib/sanitizer-core.mjs';

const SYNTHETIC_JWT = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIifQ.syntheticSignature123456';
const SYNTHETIC_SECRET = 'synth-client-secret-998877';

test('sanitizeNewmanRun elimina JWT, Authorization headers, query secrets y cuerpos privados preservando PASS y FAIL', () => {
  const rawSummary = {
    run: {
      timings: { started: 1000, completed: 1450 },
      executions: [
        {
          item: { name: 'PM-002 - Gateway -> Catalog: Listar productos' },
          request: {
            method: 'GET',
            url: `https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io/api/v1/productos?access_token=${SYNTHETIC_SECRET}`,
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
          assertions: [
            { assertion: 'PM-002: HTTP 200', error: null },
          ],
        },
        {
          item: { name: 'PM-004 - Negativo: Sin autenticacion' },
          request: {
            method: 'GET',
            url: 'https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io/api/v1/productos',
            header: [],
          },
          response: {
            code: 500,
            responseTime: 80,
            header: [{ key: 'Content-Type', value: 'application/problem+json' }],
          },
          assertions: [
            {
              assertion: 'PM-004: HTTP 401',
              error: { message: `Expected 401 with Bearer ${SYNTHETIC_JWT} and ${SYNTHETIC_SECRET}` },
            },
          ],
        },
      ],
    },
  };

  const sanitized = sanitizeNewmanRun(rawSummary, {
    runId: 'test-sanitize-01',
    environmentName: 'local',
    profile: 'smoke',
    extraSecrets: [SYNTHETIC_JWT, SYNTHETIC_SECRET],
  });

  assert.equal(sanitized.totals.pass, 1);
  assert.equal(sanitized.totals.fail, 1);

  const jsonText = JSON.stringify(sanitized);
  assert.equal(jsonText.includes(SYNTHETIC_JWT), false, 'JWT sintetico no debe aparecer en JSON');
  assert.equal(jsonText.includes(SYNTHETIC_SECRET), false, 'Secreto sintetico no debe aparecer en JSON');
  assert.equal(jsonText.includes('super-private-cookie'), false, 'Cookie no debe aparecer en JSON');
  assert.equal(jsonText.includes('secret@example.com'), false, 'Cuerpo privado no debe publicarse');

  const junit = buildSanitizedJunitXml(sanitized, [SYNTHETIC_JWT, SYNTHETIC_SECRET]);
  assert.equal(junit.includes(SYNTHETIC_JWT), false, 'JWT sintetico no debe aparecer en JUnit');
  assert.equal(junit.includes(SYNTHETIC_SECRET), false, 'Secreto sintetico no debe aparecer en JUnit');
  assert.ok(junit.includes('<failure'));
});

test('sanitizeNewmanRun falla cerrado si el resumen crudo es invalido', () => {
  assert.throws(() => sanitizeNewmanRun(null), /invalido o ausente/i);
});

test('containsSensitiveLeak detecta JWTs y connection strings', () => {
  const res = containsSensitiveLeak(`error connecting postgresql://user:pass@host:5432/db`);
  assert.equal(res.leaked, true);
});
