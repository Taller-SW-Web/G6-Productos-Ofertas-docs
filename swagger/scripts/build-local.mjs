import { cp, mkdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { loadContract, operations } from './contract.mjs';

const root = new URL('../', import.meta.url);
const output = new URL('dist/', root);
const { raw, spec } = await loadContract();
await mkdir(output, { recursive: true });
for (const file of ['index.html', 'portal.js', 'portal.css']) await cp(new URL(file, root), new URL(file, output));
for (const file of ['swagger-ui-bundle.js', 'swagger-ui.css', 'LICENSE', 'NOTICE']) {
  await cp(new URL(`node_modules/swagger-ui-dist/${file}`, root), new URL(file, output));
}
await writeFile(new URL('openapi.yaml', output), raw);
await writeFile(new URL('openapi.json', output), JSON.stringify(spec));
const manifest = { source: 'contratos/http/openapi.yaml', sha256: createHash('sha256').update(raw).digest('hex'), version: spec.info.version, swaggerUI: '5.34.1', operations: operations(spec).length, tags: spec.tags.length, schemas: Object.keys(spec.components.schemas).length, transformations: [] };
await writeFile(new URL('manifest.json', output), JSON.stringify(manifest, null, 2));
console.log(JSON.stringify(manifest, null, 2));
