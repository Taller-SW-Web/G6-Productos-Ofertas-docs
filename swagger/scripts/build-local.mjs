import { cp, mkdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { loadContract, operations } from './contract.mjs';

export async function build({ contractPath, outputPath, commitSha, generatedAt } = {}) {
  const root = new URL('../', import.meta.url);
  const output = resolve(outputPath ?? fileURLToPath(new URL('dist/', root)));
  const contract = contractPath ?? process.env.SWAGGER_CONTRACT_PATH;
  const { raw, spec } = await loadContract(contract ?? undefined);
  await mkdir(output, { recursive: true });
  for (const file of ['index.html', 'portal.js', 'portal.css']) await cp(new URL(file, root), resolve(output, file));
  for (const file of ['swagger-ui-bundle.js', 'swagger-ui.css', 'LICENSE', 'NOTICE']) {
    await cp(new URL(`node_modules/swagger-ui-dist/${file}`, root), resolve(output, file));
  }
  await writeFile(resolve(output, 'openapi.yaml'), raw);
  await writeFile(resolve(output, 'openapi.json'), JSON.stringify(spec));
  const sha = commitSha ?? process.env.GITHUB_SHA ?? 'local';
  const timestamp = generatedAt ?? new Date().toISOString();
  if (!/^([0-9a-f]{40}|local)$/i.test(sha)) throw new Error('GITHUB_SHA debe ser un SHA completo de 40 caracteres.');
  if (Number.isNaN(Date.parse(timestamp)) || !timestamp.endsWith('Z')) throw new Error('La fecha de generación debe estar en UTC (ISO 8601 con Z).');
  const contractSha256 = createHash('sha256').update(raw).digest('hex');
  const version = {
    source: 'contratos/http/openapi.yaml',
    commit_sha: sha,
    commit_sha_short: sha === 'local' ? 'local' : sha.slice(0, 7),
    commit_url: sha === 'local' ? null : `https://github.com/${process.env.GITHUB_REPOSITORY ?? 'Taller-SW-Web/G6-Productos-Ofertas-docs'}/commit/${sha}`,
    generated_at_utc: timestamp,
    openapi_version: spec.info.version,
    contract_sha256: contractSha256
  };
  const manifest = { source: version.source, sha256: contractSha256, version: spec.info.version, swaggerUI: '5.34.1', operations: operations(spec).length, tags: spec.tags.length, schemas: Object.keys(spec.components.schemas).length, transformations: [] };
  await writeFile(resolve(output, 'version.json'), JSON.stringify(version, null, 2));
  await writeFile(resolve(output, 'manifest.json'), JSON.stringify(manifest, null, 2));
  console.log(JSON.stringify({ ...manifest, commit: version.commit_sha_short }, null, 2));
  return { version, manifest };
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) await build();
