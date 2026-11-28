import test from 'node:test';
import assert from 'node:assert/strict';
import { runPreflight, validateBaseUrl, validateRedirectTarget } from '../scripts/lib/preflight-core.mjs';

test('H05: validateBaseUrl acepta APIM autorizado y Gateway ACA con HTTPS y rechaza HTTP', () => {
  const apimOk = validateBaseUrl('https://apim-g6-productos-chile.azure-api.net', 'azure-apim-chile');
  assert.equal(apimOk.ok, true);

  const apimHttp = validateBaseUrl('http://apim-g6-productos-chile.azure-api.net', 'azure-apim-chile');
  assert.equal(apimHttp.ok, false);

  const acaOk = validateBaseUrl(
    'https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io',
    'azure-aca-chile',
  );
  assert.equal(acaOk.ok, true);

  const crossEnv = validateBaseUrl(
    'https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io',
    'azure-apim-chile',
  );
  assert.equal(crossEnv.ok, false);
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

test('runPreflight rechaza credenciales ausentes, perfiles desconocidos y fixtures invalidos', () => {
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
