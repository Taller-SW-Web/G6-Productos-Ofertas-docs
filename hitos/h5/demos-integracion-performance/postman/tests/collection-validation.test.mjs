import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { COLLECTION_PATH, COVERAGE_CSV_PATH, OPENAPI_CONTRACT_PATH, POSTMAN_ROOT } from '../scripts/lib/constants.mjs';
import {
  scanFilesForSecrets,
  validateCollectionAgainstOpenApi,
  validateCollectionStructure,
  validateMatrixParity,
} from '../scripts/lib/preflight-core.mjs';

test('La coleccion Postman es JSON valido v2.1.0, solo lectura y sin IDs duplicados', () => {
  const result = validateCollectionStructure(COLLECTION_PATH);
  assert.equal(result.ok, true, `Errores de validacion: ${result.errors.join(' | ')}`);
  assert.equal(result.requests.length, 38);
});

test('H10: Cada ruta /api/v1 de la coleccion coincide con OpenAPI 0.7.0-rc.3 y la matriz CSV esta 100% conciliada', () => {
  const openApi = validateCollectionAgainstOpenApi(COLLECTION_PATH, OPENAPI_CONTRACT_PATH);
  assert.equal(openApi.ok, true, `Errores OpenAPI: ${openApi.errors.join(' | ')}`);
  assert.equal(openApi.openApiOperationCount, 156);

  const parity = validateMatrixParity(COLLECTION_PATH, COVERAGE_CSV_PATH);
  assert.equal(parity.ok, true, `Errores de paridad CSV: ${parity.errors.join(' | ')}`);
  assert.equal(parity.collectionCount, parity.csvCount);
});

test('H09: La coleccion valida URL final resuelta en prerequest y redirecciones en test global', () => {
  const raw = JSON.parse(readFileSync(COLLECTION_PATH, 'utf8'));
  assert.equal(raw.info.name, 'G6 - H5 Integration Suite');

  const pre = (raw.event || []).find((e) => e.listen === 'prerequest');
  assert.ok(pre, 'Debe existir script prerequest a nivel de coleccion');
  const preCode = pre.script.exec.join('\n');
  assert.ok(preCode.includes('pm.variables.replaceIn(pm.request.url.toString())'), 'Debe validar URL final resuelta');
  assert.ok(preCode.includes('apim-g6-productos-chile.azure-api.net'), 'Debe incluir origen APIM autorizado');

  const globalTest = (raw.event || []).find((e) => e.listen === 'test');
  assert.ok(globalTest, 'Debe existir script test global para validar redirecciones');
  const testCode = globalTest.script.exec.join('\n');
  assert.ok(testCode.includes('Location'), 'Debe inspeccionar Location en respuestas 3xx');
});

test('No existen secretos reales en archivos versionados del directorio postman', () => {
  const findings = scanFilesForSecrets(POSTMAN_ROOT);
  assert.deepEqual(findings, [], `Se detectaron posibles secretos: ${JSON.stringify(findings)}`);
});
