import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { isDeepStrictEqual } from 'node:util';
import { parseDocument } from 'yaml';

export const VERIFY_MAX_WAIT_MS = 180_000;
export const VERIFY_REQUEST_TIMEOUT_MS = 8_000;
export const VERIFY_RETRY_DELAY_MS = 5_000;
const RESOURCES = [
  'portal.js', 'portal.css', 'swagger-ui-bundle.js', 'swagger-ui.css', 'LICENSE', 'NOTICE'
];

const sleep = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));
const sha256 = content => createHash('sha256').update(content).digest('hex');

async function fetchText(url, deadline) {
  const remaining = deadline - Date.now();
  if (remaining <= 0) throw new Error('se agotó el tiempo total de verificación.');
  const timeout = Math.min(VERIFY_REQUEST_TIMEOUT_MS, remaining);
  let response;
  try { response = await fetch(url, { signal: AbortSignal.timeout(timeout), redirect: 'follow' }); }
  catch (error) { throw new Error(`${url}: ${error.name === 'TimeoutError' ? `timeout ${timeout} ms` : error.message}`); }
  if (!response.ok) throw new Error(`${url}: HTTP ${response.status} ${response.statusText}`);
  return response.text();
}

export async function verifyPublishedSite({ pageUrl, expectedSha, expectedContractSha256, maxWaitMs = VERIFY_MAX_WAIT_MS } = {}) {
  if (!pageUrl) throw new Error('Falta la URL devuelta por actions/deploy-pages.');
  if (!/^[0-9a-f]{40}$/i.test(expectedSha ?? '')) throw new Error('El SHA esperado debe tener 40 caracteres hexadecimales.');
  if (!/^[0-9a-f]{64}$/i.test(expectedContractSha256 ?? '')) throw new Error('El hash contractual esperado debe tener 64 caracteres hexadecimales.');
  if (!Number.isSafeInteger(maxWaitMs) || maxWaitMs < VERIFY_REQUEST_TIMEOUT_MS) throw new Error('maxWaitMs debe ser al menos 8000 ms y finito.');
  const base = new URL(pageUrl);
  const localHttp = base.protocol === 'http:' && ['localhost', '127.0.0.1', '[::1]'].includes(base.hostname);
  if (base.protocol !== 'https:' && !localHttp) throw new Error('La URL publicada debe usar HTTPS (HTTP solo se permite en loopback para pruebas locales).');
  base.pathname = `${base.pathname.replace(/\/+$/, '')}/`;
  base.search = '';
  base.hash = '';

  const deadline = Date.now() + maxWaitMs;
  let attempts = 0;
  let lastError = 'sin intentos';
  while (Date.now() < deadline) {
    attempts += 1;
    try {
      const paths = ['', 'version.json', 'openapi.yaml', 'openapi.json', 'manifest.json', ...RESOURCES];
      const contents = await Promise.all(paths.map(path => fetchText(new URL(path, base), deadline)));
      const [indexHtml, versionText, yamlText, jsonText, manifestText] = contents;
      if (!/id="swagger-ui"/.test(indexHtml)) throw new Error('index.html no contiene el punto de montaje Swagger UI.');
      const version = JSON.parse(versionText);
      const manifest = JSON.parse(manifestText);
      const jsonSpec = JSON.parse(jsonText);
      const yamlDocument = parseDocument(yamlText, { uniqueKeys: true });
      if (yamlDocument.errors.length) throw new Error(`openapi.yaml inválido: ${yamlDocument.errors.map(error => error.message).join('; ')}`);
      const yamlSpec = yamlDocument.toJS({ maxAliasCount: 10000 });
      const publishedHash = sha256(Buffer.from(yamlText));
      if (version.commit_sha !== expectedSha) throw new Error(`version.json SHA ${version.commit_sha} difiere del desplegado ${expectedSha}.`);
      if (publishedHash !== expectedContractSha256) throw new Error(`SHA-256 publicado ${publishedHash} difiere del candidato ${expectedContractSha256}.`);
      if (version.contract_sha256 !== expectedContractSha256 || manifest.sha256 !== expectedContractSha256) throw new Error('Los metadatos publicados no coinciden con el hash del candidato.');
      if (version.openapi_version !== yamlSpec.info?.version || manifest.version !== yamlSpec.info?.version) throw new Error('info.version publicado no coincide con sus metadatos.');
      if (!isDeepStrictEqual(yamlSpec, jsonSpec)) throw new Error('openapi.yaml y openapi.json publicados no son equivalentes.');
      return { url: base.href, attempts, commitSha: version.commit_sha, contractSha256: publishedHash, openapiVersion: yamlSpec.info.version };
    } catch (error) {
      lastError = error.message;
      const remaining = deadline - Date.now();
      if (remaining <= 0) break;
      await sleep(Math.min(VERIFY_RETRY_DELAY_MS, remaining));
    }
  }
  throw new Error(`La verificación posterior a Pages agotó ${maxWaitMs} ms tras ${attempts} intentos. Último diagnóstico: ${lastError}`);
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const [pageUrl, expectedSha, expectedContractSha256] = process.argv.slice(2);
  try {
    const result = await verifyPublishedSite({ pageUrl, expectedSha, expectedContractSha256 });
    console.log(`Verificación de Pages PASS: ${JSON.stringify(result)}`);
  } catch (error) {
    console.error(`FALLO de verificación posterior a Pages: ${error.message}`);
    process.exitCode = 1;
  }
}
