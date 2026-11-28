import test from 'node:test';
import assert from 'node:assert/strict';
import { runPreflight, validateBaseUrl, validateRedirectTarget } from '../scripts/lib/preflight-core.mjs';

test('validateBaseUrl acepta Gateway ACA autorizado con HTTPS y rechaza HTTP', () => {
  const ok = validateBaseUrl(
    'https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io',
    'azure-aca-chile',
  );
  assert.equal(ok.ok, true);

  const badProto = validateBaseUrl(
    'http://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io',
    'azure-aca-chile',
  );
  assert.equal(badProto.ok, false);
  assert.ok(badProto.errors.some((e) => e.includes('HTTPS')));
});

test('validateBaseUrl rechaza hosts no autorizados y credenciales embebidas', () => {
  const badHost = validateBaseUrl('https://evil.example.com', 'azure-aca-chile');
  assert.equal(badHost.ok, false);

  const badCreds = validateBaseUrl('http://user:pass@127.0.0.1:3000', 'local');
  assert.equal(badCreds.ok, false);

  const invalid = validateBaseUrl('not-a-url', 'local');
  assert.equal(invalid.ok, false);
});

test('validateRedirectTarget bloquea redirecciones hacia hosts fuera de allowlist', () => {
  const blocked = validateRedirectTarget('https://attacker.example.net/steal', 'azure-aca-chile');
  assert.equal(blocked.allowed, false);

  const allowed = validateRedirectTarget('http://127.0.0.1:3000/api/v1/productos', 'local');
  assert.equal(allowed.allowed, true);
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
  assert.ok(missingAuth.errors.some((e) => e.includes('accessToken')));

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
