import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const wf = await readFile('.github/workflows/swagger-docs.yml', 'utf8');
const sync = await readFile('.github/workflows/sync-workspaces.yml', 'utf8');
const syncTests = await readFile('tests/automation/test_sync_workspaces.py', 'utf8');

function extractJobBlock(workflow, jobName) {
  const jobsMatch = /^jobs:\s*$/m.exec(workflow);
  assert.ok(jobsMatch, 'El workflow debe declarar jobs en el nivel raíz.');

  const jobsSection = workflow.slice(jobsMatch.index + jobsMatch[0].length);
  const jobHeaders = [...jobsSection.matchAll(/^  ([a-z][a-z0-9_-]*):\s*$/gm)];
  const jobIndex = jobHeaders.findIndex(([, name]) => name === jobName);
  assert.ok(jobIndex >= 0, `No se encontró el job ${jobName}.`);

  const start = jobHeaders[jobIndex].index;
  const end = jobHeaders[jobIndex + 1]?.index ?? jobsSection.length;
  return jobsSection.slice(start, end);
}

test('Swagger docs ejecuta en Draft/Ready y posmerge con agregador estable', () => {
  assert.match(wf, /opened, reopened, synchronize, ready_for_review, converted_to_draft, edited/);
  assert.match(wf, /push:[\s\S]*?branches: \[master\]/);
  assert.match(wf, /name: validate-docs/);
  assert.match(wf, /draft == false/);
});

test('la concurrencia separa PR de master y despacho manual no cancela', () => {
  assert.match(wf, /group: swagger-docs-\$\{\{ github\.event\.pull_request\.number \|\| github\.ref \}\}/);
  assert.match(wf, /cancel-in-progress: \$\{\{ github\.event_name == 'pull_request' \|\| \(github\.event_name == 'push' && github\.ref == 'refs\/heads\/master'\) \}\}/);
  assert.match(wf, /group: swagger-pages-production[\s\S]*?cancel-in-progress: false/);
});

test('sin paths filter, conserva despacho y pruebas contractuales/Playwright', () => {
  assert.match(wf, /workflow_dispatch:/);
  assert.doesNotMatch(wf, /^    paths:/m);
  for (const check of ['npm run validate', 'npm run test:browser', 'python -m unittest discover']) {
    assert.ok(wf.includes(check));
  }
});

test('un push documental fuera de Swagger no publica Pages', async () => {
  const { spawnSync } = await import('node:child_process');
  const { mkdtemp, writeFile, rm } = await import('node:fs/promises');
  const { tmpdir } = await import('node:os');
  const { join } = await import('node:path');
  const directory = await mkdtemp(join(tmpdir(), 'pages-scope-'));
  try {
    const changedFiles = join(directory, 'changed-files.txt');
    const decide = async (files) => {
      await writeFile(changedFiles, files.join('\n'));
      return spawnSync('node', [
        'scripts/ci/should-publish-pages.mjs',
        '--changed-files',
        changedFiles,
      ], { encoding: 'utf8' });
    };
    for (const files of [
      ['hitos/h5/CIERRE-MK001-BULK-H5-SIN-DESPLIEGUE.md'],
      ['scripts/ci/should-publish-pages.mjs'],
    ]) {
      const docsOnly = await decide(files);
      assert.equal(docsOnly.status, 0);
      assert.match(docsOnly.stdout, /publish=false/);
    }
    for (const files of [
      ['contratos/http/openapi.yaml'],
      ['swagger/index.html'],
      ['swagger/scripts/build.mjs'],
      ['hitos/h5/report.md', 'contratos/http/openapi.yaml'],
      ['contratos/http/openapi.yaml'], // Ruta antigua de un rename emitido con --no-renames.
      ['contratos/http/openapi.yaml', 'contratos/http/openapi-v2.yaml'],
    ]) {
      const contract = await decide(files);
      assert.equal(contract.status, 0);
      assert.match(contract.stdout, /publish=true/);
    }
    await writeFile(changedFiles, '\0invalid');
    assert.notEqual((await import('node:child_process')).spawnSync('node', [
      'scripts/ci/should-publish-pages.mjs', '--changed-files', changedFiles,
    ], { encoding: 'utf8' }).status, 0);
    assert.notEqual((await import('node:child_process')).spawnSync('node', [
      'scripts/ci/should-publish-pages.mjs',
      '--changed-files',
      join(directory, 'missing-diff.txt'),
    ], { encoding: 'utf8' }).status, 0);
    assert.match(wf, /git diff --name-only --no-renames/);
    assert.match(wf, /needs\.publication_scope\.outputs\.publish == 'true'/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('sincronización sigue manual, dry-run por defecto y apunta al repo canónico', () => {
  assert.match(sync, /workflow_dispatch:/);
  assert.match(sync, /default: true/);
  assert.match(sync, /Taller-SW-Web\/G6-Productos-Ofertas-docs/);
});

test('validate-docs usa checkout y Node sin npm ci; contrato ejecuta pruebas sync locales', () => {
  const aggregate = extractJobBlock(wf, 'validate_docs');
  assert.match(aggregate, /needs: \[contrato, prepare_pages\]/);
  const checkout = aggregate.indexOf('actions/checkout@v4');
  const setup = aggregate.indexOf('actions/setup-node@v4');
  const run = aggregate.indexOf('scripts/ci/verify-docs-results.mjs');
  assert.ok(checkout >= 0 && setup > checkout && run > setup);
  assert.match(aggregate, /node-version: '24'/);
  assert.doesNotMatch(aggregate, /npm ci/);

  const contract = extractJobBlock(wf, 'contrato');
  const pythonSetup = contract.indexOf('actions/setup-python@v5');
  const syncRun = contract.indexOf('python -m unittest discover -s tests\/automation -p "test_sync_workspaces.py" -v');
  assert.ok(pythonSetup >= 0 && syncRun > pythonSetup);
  assert.match(contract, /working-directory: \./);
  assert.match(syncTests, /self\.remote = self\.root \/ "remote\.git"/);
  assert.match(syncTests, /init", "--bare"/);

  const preparation = extractJobBlock(wf, 'prepare_pages');
  assert.match(preparation, /permissions:\s*\n\s+contents: read/);
  assert.doesNotMatch(preparation, /pages:\s*write|id-token:\s*write|actions\/deploy-pages|environment:/);
  assert.match(preparation, /actions\/upload-pages-artifact@v5/);
});
