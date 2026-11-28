#!/usr/bin/env node
import { AUTHORIZED_HOSTS, COLLECTION_PATH, POSTMAN_ROOT } from './lib/constants.mjs';
import { runPreflight } from './lib/preflight-core.mjs';

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token.startsWith('--')) {
      const key = token.slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        args[key] = next;
        i += 1;
      } else {
        args[key] = 'true';
      }
    }
  }
  return args;
}

const cli = parseArgs(process.argv.slice(2));
const environmentName = cli.env || process.env.G6_ENV || 'azure-apim-chile';
const defaultBaseUrl =
  environmentName === 'local'
    ? 'http://127.0.0.1:3000'
    : `https://${(AUTHORIZED_HOSTS[environmentName] || AUTHORIZED_HOSTS['azure-apim-chile'])[0]}`;

const baseUrl = cli['base-url'] || process.env.G6_BASE_URL || defaultBaseUrl;
const profile = cli.profile || process.env.G6_PROFILE || 'apim-edge';
const folder = cli.folder || null;
const requireAuth = cli['allow-no-auth'] === 'true' ? false : true;

const result = runPreflight({
  baseUrl,
  environmentName,
  profile,
  folder,
  requireAuth,
  accessToken: process.env.G6_ACCESS_TOKEN || '',
  marketplaceAccessToken: process.env.G6_MARKETPLACE_ACCESS_TOKEN || '',
  ventasAccessToken: process.env.G6_VENTAS_ACCESS_TOKEN || '',
  collectionPath: cli.collection || COLLECTION_PATH,
  scanRoot: POSTMAN_ROOT,
  fixtures: {
    priceMin: process.env.G6_PRICE_MIN ?? 0,
    priceMax: process.env.G6_PRICE_MAX ?? 100,
  },
});

console.log(`=== Preflight G6 H5 Postman/Newman (${environmentName}) ===`);
for (const chk of result.checks) {
  console.log(`  [${chk.ok ? 'OK' : 'FAIL'}] ${chk.id}: ${chk.detail}`);
}
for (const warn of result.warnings) {
  console.warn(`  [WARN] ${warn}`);
}

if (!result.ok) {
  console.error('\n[PREFLIGHT] Bloqueado por errores de configuracion o seguridad:');
  for (const err of result.errors) {
    console.error(`  - ${err}`);
  }
  process.exit(2);
}

console.log('\n[PREFLIGHT] OK — Configuracion autorizada y lista para ejecucion.');
