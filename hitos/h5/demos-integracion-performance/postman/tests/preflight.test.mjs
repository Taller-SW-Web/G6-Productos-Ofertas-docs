import test from 'node:test';
import assert from 'node:assert/strict';
import { resolveProfileFolders } from '../scripts/lib/constants.mjs';
import { runPreflight, validateBaseUrl, validateRedirectTarget } from '../scripts/lib/preflight-core.mjs';

test('H05: validateBaseUrl acepta APIM autorizado y Gateway ACA con HTTPS y rechaza HTTP', () => {
  assert.equal(validateBaseUrl('https://apim-g6-productos-chile.azure-api.net', 'azure-apim-chile').ok, true);
  assert.equal(validateBaseUrl('http://apim-g6-productos-chile.azure-api.net', 'azure-apim-chile').ok, false);
  assert.equal(validateBaseUrl('https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io', 'azure-aca-chile').ok, true);
  assert.equal(validateBaseUrl('https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io', 'azure-apim-chile').ok, false);
});

test('Punto 6: Perfiles APIM (integration y smoke) excluyen carpeta privada 00 - Preflight y autenticacion (/health)', () => {
  const apimInt = resolveProfileFolders('integration', 'azure-apim-chile');
  assert.equal(apimInt.includes('00 - Preflight y autenticacion'), false);
  assert.equal(apimInt.includes('01 - Catalog y Pricing'), true);
  assert.equal(apimInt.includes('09 - APIM, Gateway y G7'), true);

  const apimSmoke = resolveProfileFolders('smoke', 'azure-apim-chile');
  assert.equal(apimSmoke.includes('00 - Preflight y autenticacion'), false);

  const localInt = resolveProfileFolders('integration', 'local');
  assert.equal(localInt.includes('00 - Preflight y autenticacion'), true);
});

test('validateBaseUrl rechaza hosts no autorizados y credenciales embebidas', () => {
  assert.equal(validateBaseUrl('https://evil.example.com', 'azure-apim-chile').ok, false);
  assert.equal(validateBaseUrl('http://user:pass@127.0.0.1:3000', 'local').ok, false);
  assert.equal(validateBaseUrl('not-a-url', 'local').ok, false);
});

test('validateRedirectTarget bloquea redirecciones hacia hosts fuera de allowlist', () => {
  assert.equal(validateRedirectTarget('https://attacker.example.net/steal', 'azure-apim-chile').allowed, false);
  assert.equal(validateRedirectTarget('https://apim-g6-productos-chile.azure-api.net/api/v1/productos', 'azure-apim-chile').allowed, true);
});

test('Punto 4: runPreflight rechaza carpetas inexistentes, credenciales ausentes, perfiles desconocidos y fixtures invalidos', () => {
  const badFolder = runPreflight({
    baseUrl: 'http://127.0.0.1:3000',
    environmentName: 'local',
    folder: '99 - Carpeta Inexistente',
    requireAuth: false,
    skipSecretScan: true,
  });
  assert.equal(badFolder.ok, false);
  assert.ok(badFolder.errors.some((e) => e.includes('Carpeta inexistente')));

  const missingAuth = runPreflight({
    baseUrl: 'http://127.0.0.1:3000',
    environmentName: 'local',
    profile: 'smoke',
    requireAuth: true,
    accessToken: '',
    skipSecretScan: true,
  });
  assert.equal(missingAuth.ok, false);

  const badProfile = runPreflight({
    baseUrl: 'http://127.0.0.1:3000',
    environmentName: 'local',
    profile: 'non-existent',
    requireAuth: false,
    skipSecretScan: true,
  });
  assert.equal(badProfile.ok, false);

  const badFixtures = runPreflight({
    baseUrl: 'http://127.0.0.1:3000',
    environmentName: 'local',
    profile: 'smoke',
    requireAuth: false,
    skipSecretScan: true,
    fixtures: { priceMin: 500, priceMax: 100 },
  });
  assert.equal(badFixtures.ok, false);
});
