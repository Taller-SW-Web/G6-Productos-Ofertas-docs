import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { stringify } from 'yaml';
import { loadContract } from '../scripts/contract.mjs';
import { build } from '../scripts/build-local.mjs';

const workflowPath = new URL('../../.github/workflows/swagger-docs.yml', import.meta.url);

test('El candidato temporal refleja cambios contractuales y trazabilidad del commit', async t => {
  const temp = await mkdtemp(resolve(tmpdir(), 'g6-swagger-pages-'));
  t.after(() => rm(temp, { recursive: true, force: true }));
  const { spec } = await loadContract();
  const fixture = structuredClone(spec);
  fixture.info.title = 'Fixture temporal de Pages';
  fixture.info.version = '99.1.0-test';
  const contractPath = resolve(temp, 'fixture.yaml');
  const outputPath = resolve(temp, 'dist');
  const raw = stringify(fixture);
  await writeFile(contractPath, raw);

  await build({ contractPath, outputPath, commitSha: '0123456789abcdef0123456789abcdef01234567', generatedAt: '2026-11-24T12:34:56.000Z' });
  const generated = JSON.parse(await readFile(resolve(outputPath, 'openapi.json'), 'utf8'));
  const metadata = JSON.parse(await readFile(resolve(outputPath, 'version.json'), 'utf8'));
  assert.equal(generated.info.title, fixture.info.title);
  assert.equal(metadata.openapi_version, fixture.info.version);
  assert.equal(metadata.commit_sha, '0123456789abcdef0123456789abcdef01234567');
  assert.equal(metadata.commit_sha_short, '0123456');
  assert.equal(metadata.generated_at_utc, '2026-11-24T12:34:56.000Z');
  assert.equal(metadata.commit_url, 'https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/commit/0123456789abcdef0123456789abcdef01234567');
  assert.equal(metadata.contract_sha256, createHash('sha256').update(raw).digest('hex'));

  const entries = (await readdir(outputPath)).sort();
  assert.deepEqual(entries, ['LICENSE', 'NOTICE', 'index.html', 'manifest.json', 'openapi.json', 'openapi.yaml', 'portal.css', 'portal.js', 'swagger-ui-bundle.js', 'swagger-ui.css', 'version.json'].sort());
  const html = await readFile(resolve(outputPath, 'index.html'), 'utf8');
  assert.match(html, /(?:src|href)="\.\//);
  assert.doesNotMatch(html, /(?:src|href)="https?:\/\//);
  const portal = await readFile(resolve(outputPath, 'portal.js'), 'utf8');
  assert.match(portal, /new URL\(file, document\.baseURI\)/);
  for (const file of ['swagger-ui-bundle.js', 'swagger-ui.css', 'LICENSE', 'NOTICE']) assert.ok((await readFile(resolve(outputPath, file))).length > 0);
});

test('Un YAML inválido hace fallar la generación', async t => {
  const temp = await mkdtemp(resolve(tmpdir(), 'g6-swagger-invalid-'));
  t.after(() => rm(temp, { recursive: true, force: true }));
  const contractPath = resolve(temp, 'invalid.yaml');
  const outputPath = resolve(temp, 'dist');
  await writeFile(contractPath, 'openapi: [invalido\n');
  await assert.rejects(build({ contractPath, outputPath, commitSha: '0123456789abcdef0123456789abcdef01234567', generatedAt: '2026-11-24T12:34:56.000Z' }));
  await assert.rejects(readdir(outputPath));
});

test('Pages solo puede desplegar el candidato validado desde master y con compuerta habilitada', async () => {
  const yaml = await import('yaml');
  const workflow = yaml.parse(await readFile(workflowPath, 'utf8'));
  const job = workflow.jobs.publish_pages;
  assert.match(job.if, /needs\.contrato\.result == 'success'/);
  assert.match(job.if, /needs\.prepare_pages\.result == 'success'/);
  assert.match(job.if, /needs\.validate_docs\.result == 'success'/);
  assert.match(job.if, /vars\.SWAGGER_PAGES_PUBLICATION_APPROVED == 'true'/);
  assert.match(job.if, /github\.ref == 'refs\/heads\/master'/);
  assert.match(job.if, /github\.event_name == 'push'.*github\.event_name == 'workflow_dispatch'/s);
  assert.deepEqual(job.permissions, { contents: 'read', pages: 'write', 'id-token': 'write' });
  assert.equal(job.environment.name, 'github-pages');
  assert.deepEqual(job.concurrency, { group: 'swagger-pages-production', 'cancel-in-progress': false });
  const actionVersions = job.steps.filter(step => step.uses).map(step => step.uses);
  assert.ok(actionVersions.includes('actions/configure-pages@v6'));
  assert.ok(actionVersions.includes('actions/upload-pages-artifact@v5'));
  assert.ok(actionVersions.includes('actions/deploy-pages@v5'));
  assert.ok(actionVersions.includes('actions/download-artifact@v4'));
  const names = job.steps.map(step => step.name);
  const index = name => names.indexOf(name);
  assert.ok(index('Checkout de master para validar el candidato') < index('Confirmar checkout inicial del SHA evaluado'));
  assert.ok(index('Confirmar checkout inicial del SHA evaluado') < index('Descargar candidato fuera del workspace'));
  assert.ok(index('Descargar candidato fuera del workspace') < index('Validar integralmente el candidato descargado'));
  assert.ok(index('Validar integralmente el candidato descargado') < index('Configurar GitHub Pages'));
  assert.ok(index('Configurar GitHub Pages') < index('Preparar artefacto de Pages'));
  assert.ok(index('Preparar artefacto de Pages') < index('Confirmar que HEAD remoto de master sigue vigente'));
  assert.ok(index('Confirmar que HEAD remoto de master sigue vigente') < index('Desplegar versión validada'));
  assert.ok(index('Desplegar versión validada') < index('Verificar disponibilidad y contenido publicado'));
  assert.match(job.steps.find(step => step.name === 'Checkout de master para validar el candidato').with.ref, /^master$/);
  assert.equal(job.steps.find(step => step.name === 'Checkout de master para validar el candidato').with['persist-credentials'], false);
  assert.match(job.steps.find(step => step.name === 'Confirmar checkout inicial del SHA evaluado').run, /git rev-parse HEAD/);
  assert.match(job.steps.find(step => step.name === 'Descargar candidato fuera del workspace').with.path, /runner\.temp/);
  assert.doesNotMatch(job.steps.find(step => step.name === 'Descargar candidato fuera del workspace').with.path, /_pages_candidate/);
  assert.match(job.steps.find(step => step.name === 'Confirmar que HEAD remoto de master sigue vigente').run, /git ls-remote/);
  assert.match(job.steps.find(step => step.name === 'Verificar disponibilidad y contenido publicado').run, /verify-pages-site\.mjs/);
  assert.doesNotMatch(job.steps.map(step => step.run ?? '').join('\n'), /build:local|npm run build/);

  const preparation = workflow.jobs.prepare_pages;
  assert.deepEqual(preparation.permissions, { contents: 'read' });
  assert.deepEqual(workflow.jobs.validate_docs.needs, ['contrato', 'prepare_pages']);
  const prepNames = preparation.steps.map(step => step.name);
  assert.ok(prepNames.indexOf('Checkout del SHA evaluado') < prepNames.indexOf('Descargar candidato fuera del workspace'));
  assert.ok(prepNames.indexOf('Descargar candidato fuera del workspace') < prepNames.indexOf('Validar candidato y verificar su supervivencia al checkout'));
  assert.ok(prepNames.indexOf('Validar candidato y verificar su supervivencia al checkout') < prepNames.indexOf('Empaquetar sin publicar para probar la preparación'));
  assert.match(preparation.steps.find(step => step.name === 'Descargar candidato fuera del workspace').with.path, /runner\.temp/);
  const pagesAction = preparation.steps.find(step => step.uses === 'actions/upload-pages-artifact@v5');
  assert.match(pagesAction.with.name, /^swagger-pages-prepare-/);
  assert.ok(!preparation.steps.some(step => step.uses === 'actions/deploy-pages@v5'));
});
