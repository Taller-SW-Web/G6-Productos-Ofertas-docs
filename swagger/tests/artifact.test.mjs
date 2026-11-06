import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { loadContract, operations } from '../scripts/contract.mjs';

test('Artefacto conserva contrato, operaciones y referencias locales', async () => {
  const { raw, spec } = await loadContract();
  const built = JSON.parse(await readFile('dist/openapi.json', 'utf8'));
  const manifest = JSON.parse(await readFile('dist/manifest.json', 'utf8'));
  assert.deepEqual(built, spec);
  assert.equal(await readFile('dist/openapi.yaml', 'utf8'), raw);
  assert.equal(manifest.sha256, createHash('sha256').update(raw).digest('hex'));
  assert.equal(manifest.operations, operations(spec).length);
  function walk(node) {
    if (!node || typeof node !== 'object') return;
    if (node.$ref) {
      assert.ok(node.$ref.startsWith('#/'), `Referencia externa no empaquetada: ${node.$ref}`);
      let target = built;
      for (const part of node.$ref.slice(2).split('/')) target = target?.[part.replaceAll('~1', '/').replaceAll('~0', '~')];
      assert.notEqual(target, undefined, node.$ref);
    }
    Object.values(node).forEach(walk);
  }
  walk(built);
  assert.doesNotMatch(JSON.stringify(built), /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,}/);
  const html = await readFile('dist/index.html', 'utf8');
  for (const match of html.matchAll(/(?:src|href)="\.\/([^"#]+)"/g)) await readFile(`dist/${match[1]}`);
});
