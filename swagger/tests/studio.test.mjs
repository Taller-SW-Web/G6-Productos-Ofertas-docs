import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { loadContract, operations } from '../scripts/contract.mjs';
import { forStudio, config } from '../scripts/studio.mjs';

test('Exportación para Studio conserva todo salvo título y servidor autorizado', async () => {
  const { raw, spec } = await loadContract();
  const derived = JSON.parse(await readFile('reports/studio.json', 'utf8'));
  assert.deepEqual(derived, forStudio(spec));
  const restored = structuredClone(derived);
  restored.info.title = spec.info.title;
  restored.servers = spec.servers;
  assert.deepEqual(restored, spec);
  const manifest = JSON.parse(await readFile('reports/manifest.json', 'utf8'));
  assert.equal(manifest.sourceSha256, createHash('sha256').update(raw).digest('hex'));
  assert.equal(manifest.operations, operations(spec).length);
  const editor = new URL(config.studioUrl);
  const docs = new URL(config.documentationUrl);
  const identity = `${config.owner}/${config.apiName}/${spec.info.version}`;
  assert.equal(editor.origin, 'https://app.swaggerhub.com');
  assert.equal(docs.origin, editor.origin);
  assert.equal(editor.pathname, `/apis/${identity}`);
  assert.equal(docs.pathname, `/apis-docs/${identity}`);
  assert.equal(editor.search + editor.hash + docs.search + docs.hash, '');
  const server = new URL(config.servers[0].url);
  assert.equal(server.protocol, 'https:');
  assert.equal(server.pathname, '/api/v1');
  assert.equal(server.username + server.password + server.search + server.hash, '');
  for (const op of operations(derived)) assert.ok(!op.path.startsWith('/api/v1'));
  function walk(value) {
    if (!value || typeof value !== 'object') return;
    if (value.$ref) {
      assert.ok(value.$ref.startsWith('#/'), value.$ref);
      let target = derived;
      for (const part of value.$ref.slice(2).split('/')) target = target?.[part.replaceAll('~1', '/').replaceAll('~0', '~')];
      assert.notEqual(target, undefined, value.$ref);
    }
    Object.values(value).forEach(walk);
  }
  walk(derived);
  assert.doesNotMatch(JSON.stringify(derived), /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,}/);
});
