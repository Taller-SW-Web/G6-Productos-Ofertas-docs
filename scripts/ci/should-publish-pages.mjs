import { readFile } from 'node:fs/promises';

const args = process.argv.slice(2);
const filesFlag = args.indexOf('--changed-files');
if (filesFlag < 0 || !args[filesFlag + 1]) {
  throw new Error('Uso: should-publish-pages.mjs --changed-files <ruta>');
}

const files = (await readFile(args[filesFlag + 1], 'utf8'))
  .split(/\r?\n/)
  .filter(Boolean);
const publish = files.some((file) =>
  file.startsWith('swagger/') ||
  file === 'contratos/http/openapi.yaml' ||
  file === 'scripts/ci/verify-docs-results.mjs' ||
  file.startsWith('swagger/scripts/'),
);
console.log(`publish=${publish}`);
