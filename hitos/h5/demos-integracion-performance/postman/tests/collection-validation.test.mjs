import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import {
  COLLECTION_PATH,
  COVERAGE_CSV_PATH,
  OPENAPI_CONTRACT_PATH,
  POSTMAN_ROOT,
  SCHEMAS_PATH,
} from '../scripts/lib/constants.mjs';
import {
  scanFilesForSecrets,
  validateCollectionAgainstOpenApi,
  validateCollectionStructure,
  validateMatrixParity,
} from '../scripts/lib/preflight-core.mjs';

test('La coleccion Postman es JSON valido v2.1.0, solo lectura, sin IDs duplicados y con followRedirects=false (Punto 3)', () => {
  const result = validateCollectionStructure(COLLECTION_PATH);
  assert.equal(result.ok, true, `Errores de validacion: ${result.errors.join(' | ')}`);
  assert.equal(result.requests.length, 38);
  for (const req of result.requests) {
    assert.equal(
      req.protocolProfileBehavior?.followRedirects,
      false,
      `Falta followRedirects=false en ${req.name}`,
    );
  }
});

test('H10+Punto 5: Rutas /api/v1 coinciden con OpenAPI 0.7.0-rc.3, matriz CSV conciliada y JSON Schemas presentes', () => {
  const openApi = validateCollectionAgainstOpenApi(COLLECTION_PATH, OPENAPI_CONTRACT_PATH);
  assert.equal(openApi.ok, true, `Errores OpenAPI: ${openApi.errors.join(' | ')}`);
  assert.equal(openApi.openApiOperationCount, 156);

  const parity = validateMatrixParity(COLLECTION_PATH, COVERAGE_CSV_PATH);
  assert.equal(parity.ok, true, `Errores de paridad CSV: ${parity.errors.join(' | ')}`);
  assert.equal(parity.collectionCount, parity.csvCount);

  assert.equal(existsSync(SCHEMAS_PATH), true, 'Debe existir schemas/openapi-response-schemas.json');
  const schemas = JSON.parse(readFileSync(SCHEMAS_PATH, 'utf8'));
  for (const key of ['PaginaProductosComercial', 'ProductoDetalleComercial', 'Precio', 'DisponibilidadStock', 'DisponibilidadComercial', 'Problem']) {
    assert.ok(schemas.$defs[key], `Falta JSON Schema ${key}`);
  }
});

test('H09: La coleccion valida URL final resuelta en prerequest y redirecciones en test global', () => {
  const raw = JSON.parse(readFileSync(COLLECTION_PATH, 'utf8'));
  assert.equal(raw.info.name, 'G6 - H5 Integration Suite');

  const pre = (raw.event || []).find((e) => e.listen === 'prerequest');
  assert.ok(pre);
  const preCode = pre.script.exec.join('\n');
  assert.ok(preCode.includes('pm.variables.replaceIn(pm.request.url.toString())'));
  assert.ok(preCode.includes('apim-g6-productos-chile.azure-api.net'));

  const globalTest = (raw.event || []).find((e) => e.listen === 'test');
  assert.ok(globalTest);
  assert.ok(globalTest.script.exec.join('\n').includes('Location'));
});

test('No existen secretos reales en archivos versionados del directorio postman', () => {
  const findings = scanFilesForSecrets(POSTMAN_ROOT);
  assert.deepEqual(findings, [], `Se detectaron posibles secretos: ${JSON.stringify(findings)}`);
});
