import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { extname, resolve } from 'node:path';
import { build } from '../scripts/build-local.mjs';
import { source } from '../scripts/contract.mjs';
import { verifyPublishedSite } from '../scripts/verify-pages-site.mjs';

const SHA = '0123456789abcdef0123456789abcdef01234567';
const contentTypes = { '.html': 'text/html', '.json': 'application/json', '.yaml': 'application/yaml', '.js': 'text/javascript', '.css': 'text/css' };

test('Verificación posterior comprueba SHA, hash y recursos en la subruta publicada', async t => {
  const { root, version } = await makeCandidate(t, 'site-good');
  const server = createServer(async (request, response) => {
    try {
      const name = new URL(request.url, 'http://localhost').pathname.slice(1).replace(/^pages\//, '') || 'index.html';
      const content = await readFile(resolve(root, name));
      response.writeHead(200, { 'content-type': contentTypes[extname(name)] ?? 'application/octet-stream' });
      response.end(content);
    } catch {
      response.writeHead(404);
      response.end('missing');
    }
  });
  await new Promise(resolveListen => server.listen(0, '127.0.0.1', resolveListen));
  t.after(() => new Promise(resolveClose => server.close(resolveClose)));
  const { port } = server.address();
  const result = await verifyPublishedSite({
    pageUrl: `http://127.0.0.1:${port}/pages/`,
    expectedSha: version.commit_sha,
    expectedContractSha256: version.contract_sha256,
    maxWaitMs: 8_000
  });
  assert.equal(result.commitSha, version.commit_sha);
  assert.equal(result.contractSha256, version.contract_sha256);
  assert.equal(result.openapiVersion, version.openapi_version);
});

test('La comprobación de sitio falla con diagnóstico claro ante SHA publicado incorrecto', async t => {
  const { root, version } = await makeCandidate(t, 'site-wrong-sha');
  const server = createServer(async (request, response) => {
    try {
      const name = new URL(request.url, 'http://localhost').pathname.slice(1) || 'index.html';
      response.writeHead(200);
      response.end(await readFile(resolve(root, name)));
    } catch {
      response.writeHead(404);
      response.end('missing');
    }
  });
  await new Promise(resolveListen => server.listen(0, '127.0.0.1', resolveListen));
  t.after(() => new Promise(resolveClose => server.close(resolveClose)));
  const { port } = server.address();
  await assert.rejects(
    verifyPublishedSite({ pageUrl: `http://127.0.0.1:${port}/`, expectedSha: 'f'.repeat(40), expectedContractSha256: version.contract_sha256, maxWaitMs: 8_000 }),
    /verificación posterior a Pages agotó .*version\.json SHA/
  );
});

async function makeCandidate(t, prefix) {
  const temp = await mkdtemp(resolve(tmpdir(), `g6-${prefix}-`));
  t.after(() => rm(temp, { recursive: true, force: true }));
  const root = resolve(temp, 'dist');
  await build({ contractPath: source, outputPath: root, commitSha: SHA, generatedAt: '2026-11-24T12:34:56.000Z' });
  const version = JSON.parse(await readFile(resolve(root, 'version.json'), 'utf8'));
  return { root, version };
}
