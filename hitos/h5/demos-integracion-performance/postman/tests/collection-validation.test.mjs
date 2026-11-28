import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { COLLECTION_PATH, POSTMAN_ROOT } from '../scripts/lib/constants.mjs';
import { scanFilesForSecrets, validateCollectionStructure } from '../scripts/lib/preflight-core.mjs';

test('La coleccion Postman es JSON valido v2.1.0, solo lectura y sin IDs duplicados', () => {
  const result = validateCollectionStructure(COLLECTION_PATH);
  assert.equal(result.ok, true, `Errores de validacion: ${result.errors.join(' | ')}`);
  assert.ok(result.requests.length >= 25, `Se esperaban >=25 solicitudes, encontradas: ${result.requests.length}`);
});

test('La coleccion define el nombre oficial y script prerequest de proteccion', () => {
  const raw = JSON.parse(readFileSync(COLLECTION_PATH, 'utf8'));
  assert.equal(raw.info.name, 'G6 - H5 Integration Suite');
  const pre = (raw.event || []).find((e) => e.listen === 'prerequest');
  assert.ok(pre, 'Debe existir un script prerequest a nivel de coleccion');
  const code = pre.script.exec.join('\n');
  assert.ok(code.includes('allowedHosts'), 'El prerequest debe validar hosts autorizados');
  assert.ok(code.includes('correlationId'), 'El prerequest debe generar correlationId');
});

test('No existen secretos reales en archivos versionados del directorio postman', () => {
  const findings = scanFilesForSecrets(POSTMAN_ROOT);
  assert.deepEqual(findings, [], `Se detectaron posibles secretos: ${JSON.stringify(findings)}`);
});
