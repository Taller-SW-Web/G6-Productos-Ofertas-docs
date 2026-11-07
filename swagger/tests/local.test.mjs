import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { loadContract, operations } from '../scripts/contract.mjs';

test('Visor local deriva del YAML oficial sin transformaciones de Studio', async () => {
  const { raw, spec } = await loadContract();
  const built = JSON.parse(await readFile('dist/openapi.json', 'utf8'));
  const manifest = JSON.parse(await readFile('dist/manifest.json', 'utf8'));
  assert.deepEqual(built, spec);
  assert.equal(await readFile('dist/openapi.yaml', 'utf8'), raw);
  assert.equal(manifest.sha256, createHash('sha256').update(raw).digest('hex'));
  assert.equal(manifest.operations, operations(spec).length);
  assert.equal(manifest.tags, spec.tags.length);
  assert.equal(manifest.schemas, Object.keys(spec.components.schemas).length);
  assert.deepEqual(manifest.transformations, []);
  const html = await readFile('dist/index.html', 'utf8');
  for (const match of html.matchAll(/(?:src|href)="\.\/([^"#]+)"/g)) await readFile(`dist/${match[1]}`);
  for (const asset of ['swagger-ui-bundle.js', 'swagger-ui.css', 'LICENSE', 'NOTICE']) assert.ok((await readFile(`dist/${asset}`)).length > 0);
  assert.doesNotMatch(html, /(?:src|href)="https?:\/\//);
});
