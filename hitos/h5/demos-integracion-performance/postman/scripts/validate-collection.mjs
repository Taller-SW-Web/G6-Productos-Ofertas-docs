#!/usr/bin/env node
import { COLLECTION_PATH, POSTMAN_ROOT } from './lib/constants.mjs';
import { scanFilesForSecrets, validateCollectionStructure } from './lib/preflight-core.mjs';

const result = validateCollectionStructure(COLLECTION_PATH);
const secrets = scanFilesForSecrets(POSTMAN_ROOT);

if (!result.ok) {
  console.error('[VALIDATE] Errores en la coleccion Postman:');
  for (const err of result.errors) {
    console.error(`  - ${err}`);
  }
}

if (secrets.length > 0) {
  console.error('[VALIDATE] Posibles secretos detectados en archivos versionados:');
  for (const finding of secrets) {
    console.error(`  - ${finding.file} (patron: ${finding.pattern})`);
  }
}

if (!result.ok || secrets.length > 0) {
  process.exit(1);
}

console.log(
  `[VALIDATE] OK — Coleccion valida (${result.requests.length} solicitudes de lectura/negativos verificadas, 0 secretos detectados).`,
);
