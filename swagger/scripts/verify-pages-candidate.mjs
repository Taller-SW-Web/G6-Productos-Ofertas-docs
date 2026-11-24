import { createHash } from 'node:crypto';
import { lstat, readFile, readdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { isDeepStrictEqual } from 'node:util';
import { parseDocument } from 'yaml';

export const ALLOWED_FILES = Object.freeze([
  'LICENSE', 'NOTICE', 'index.html', 'manifest.json', 'openapi.json', 'openapi.yaml',
  'portal.css', 'portal.js', 'swagger-ui-bundle.js', 'swagger-ui.css', 'version.json'
]);
const SECRET_PATTERNS = [
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,
  /\bgh[pousr]_[A-Za-z0-9]{30,}\b/,
  /\bgithub_pat_[A-Za-z0-9_]{50,}\b/,
  /\bAKIA[0-9A-Z]{16}\b/
];

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

function fail(message) {
  throw new Error(`Candidato Pages inválido: ${message}`);
}

export async function verifyCandidate({ candidateDir, expectedSha, officialContractPath, remoteHeadSha } = {}) {
  if (!candidateDir) fail('falta el directorio del artefacto.');
  if (!/^[0-9a-f]{40}$/i.test(expectedSha ?? '')) fail('github.sha esperado debe tener 40 caracteres hexadecimales.');
  if (remoteHeadSha && remoteHeadSha.toLowerCase() !== expectedSha.toLowerCase()) {
    fail(`candidato obsoleto: HEAD remoto master ${remoteHeadSha} difiere de SHA evaluado ${expectedSha}.`);
  }

  let root;
  try { root = await lstat(candidateDir); }
  catch { fail(`no existe el artefacto en ${candidateDir}.`); }
  if (root.isSymbolicLink() || !root.isDirectory()) fail('la raíz debe ser un directorio real, no enlace simbólico.');

  const entries = await readdir(candidateDir, { withFileTypes: true });
  const actualNames = entries.map(entry => entry.name).sort();
  const allowedNames = [...ALLOWED_FILES].sort();
  const missing = allowedNames.filter(name => !actualNames.includes(name));
  const extra = actualNames.filter(name => !allowedNames.includes(name));
  if (missing.length) fail(`faltan archivos obligatorios: ${missing.join(', ')}.`);
  if (extra.length) fail(`archivos o directorios no permitidos: ${extra.join(', ')}.`);
  for (const entry of entries) {
    const filePath = resolve(candidateDir, entry.name);
    const info = await lstat(filePath);
    if (entry.isSymbolicLink() || info.isSymbolicLink()) fail(`no se permiten enlaces simbólicos: ${entry.name}.`);
    if (!entry.isFile() || !info.isFile()) fail(`solo se permiten archivos regulares: ${entry.name}.`);
  }

  const read = name => readFile(resolve(candidateDir, name));
  for (const name of ALLOWED_FILES) {
    const text = (await readFile(resolve(candidateDir, name))).toString('utf8');
    if (SECRET_PATTERNS.some(pattern => pattern.test(text))) fail(`se detectó material sensible en ${name}.`);
  }
  const [yamlBytes, jsonBytes, versionBytes, manifestBytes] = await Promise.all([
    read('openapi.yaml'), read('openapi.json'), read('version.json'), read('manifest.json')
  ]);

  let version;
  let manifest;
  let jsonSpec;
  let yamlSpec;
  try {
    version = JSON.parse(versionBytes.toString('utf8'));
    manifest = JSON.parse(manifestBytes.toString('utf8'));
    jsonSpec = JSON.parse(jsonBytes.toString('utf8'));
    const document = parseDocument(yamlBytes.toString('utf8'), { uniqueKeys: true });
    if (document.errors.length) fail(`YAML inválido: ${document.errors.map(error => error.message).join('; ')}.`);
    yamlSpec = document.toJS({ maxAliasCount: 10000 });
  } catch (error) {
    if (error.message.startsWith('Candidato Pages inválido:')) throw error;
    fail(`no se pudieron interpretar los metadatos o especificaciones: ${error.message}.`);
  }

  const candidateHash = sha256(yamlBytes);
  let officialBytes;
  try {
    const officialInfo = await lstat(officialContractPath);
    if (!officialInfo.isFile() || officialInfo.isSymbolicLink()) fail('el contrato oficial no es un archivo regular.');
    officialBytes = await readFile(officialContractPath);
  } catch (error) {
    if (error.message.startsWith('Candidato Pages inválido:')) throw error;
    fail(`no se pudo leer el contrato oficial del checkout: ${error.message}.`);
  }
  const officialHash = sha256(officialBytes);

  if (version.commit_sha !== expectedSha) fail(`version.json commit_sha ${version.commit_sha} no coincide con github.sha ${expectedSha}.`);
  if (version.commit_sha_short !== expectedSha.slice(0, 7)) fail('version.json commit_sha_short no coincide con los primeros 7 caracteres de github.sha.');
  if (candidateHash !== officialHash) fail(`SHA-256 del openapi.yaml (${candidateHash}) difiere del contrato oficial (${officialHash}).`);
  if (version.contract_sha256 !== candidateHash) fail('version.json contract_sha256 no coincide con openapi.yaml.');
  if (manifest.sha256 !== candidateHash) fail('manifest.json sha256 no coincide con openapi.yaml.');
  if (version.source !== 'contratos/http/openapi.yaml' || manifest.source !== version.source) fail('la ruta de fuente debe ser contratos/http/openapi.yaml en ambos metadatos.');
  if (!isDeepStrictEqual(yamlSpec, jsonSpec)) fail('openapi.yaml y openapi.json no representan el mismo contrato.');
  if (!yamlSpec.info?.version || jsonSpec.info?.version !== yamlSpec.info.version) fail('info.version falta o difiere entre YAML y JSON.');
  if (version.openapi_version !== yamlSpec.info.version || manifest.version !== yamlSpec.info.version) fail('info.version no coincide con version.json y manifest.json.');

  return { commitSha: expectedSha, contractSha256: candidateHash, openapiVersion: yamlSpec.info.version, files: actualNames };
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const [candidateDir, expectedSha, officialContractPath, remoteHeadSha] = process.argv.slice(2);
  try {
    const result = await verifyCandidate({ candidateDir, expectedSha, officialContractPath, remoteHeadSha });
    console.log(JSON.stringify(result, null, 2));
    if (process.env.GITHUB_OUTPUT) {
      const { appendFile } = await import('node:fs/promises');
      await appendFile(process.env.GITHUB_OUTPUT, `contract_sha256=${result.contractSha256}\n`);
    }
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
