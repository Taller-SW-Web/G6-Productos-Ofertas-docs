import { readFile, stat } from 'node:fs/promises';

const args = process.argv.slice(2);
const filesFlag = args.indexOf('--changed-files');
if (filesFlag < 0 || !args[filesFlag + 1]) {
  throw new Error('Uso: should-publish-pages.mjs --changed-files <ruta>');
}

const changedFilesPath = args[filesFlag + 1];
const changedFilesStat = await stat(changedFilesPath);
if (!changedFilesStat.isFile()) {
  throw new Error('El diff debe ser un archivo regular');
}
const changedFilesContent = await readFile(changedFilesPath, 'utf8');
if (changedFilesContent.includes('\0')) {
  throw new Error('El diff contiene rutas inválidas');
}
const files = changedFilesContent
  .split(/\r?\n/)
  .filter(Boolean);
if (files.some((file) => file.startsWith('/') || file.split('/').includes('..'))) {
  throw new Error('El diff contiene rutas fuera del repositorio');
}
const publish = files.some((file) =>
  file.startsWith('swagger/') ||
  file === 'contratos/http/openapi.yaml' ||
  file === 'scripts/ci/verify-docs-results.mjs' ||
  file.startsWith('swagger/scripts/'),
);
console.log(`publish=${publish}`);
