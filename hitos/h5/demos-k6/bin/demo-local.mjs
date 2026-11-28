import { createHash } from 'node:crypto';
import { mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// Adapta datos del fixture existente. Backend conserva el servidor, los datos
// sintéticos y el aislamiento de red. Este archivo no define ninguna ruta.
const [, , fixturePath, backendSha, frontendSha, docsSha, k6Path, ...flags] = process.argv;
if (!fixturePath || basename(fixturePath) !== 'catalog-pagination.fixture-server.h5.mjs' ||
    ![backendSha, frontendSha, docsSha].every((sha) => /^[a-f0-9]{40}$/.test(sha ?? '')) ||
    flags.some((flag) => !['--validar', '--dashboard'].includes(flag))) {
  process.stderr.write('USO: node bin/demo-local.mjs <fixture Backend> <SHA Backend> <SHA Frontend> <SHA Docs> <k6.exe> [--validar] [--dashboard]\n');
  process.exit(2);
}

const base = dirname(dirname(fileURLToPath(import.meta.url)));
const cache = join(base, '.local');
await mkdir(cache, { recursive: true });
const directory = await mkdtemp(join(cache, 'fixture-'));
const digest = (value) => createHash('sha256').update(value).digest('hex');
const utc = (timestamp) => new Date(timestamp).toISOString().replace(/\.\d{3}Z$/, 'Z');
const channel = 'MARKETPLACE';
const fixture = await import(pathToFileURL(resolve(fixturePath)).href);
const manifestPath = resolve(dirname(fixturePath), '../../fixtures/h5/catalog-h5-fixture.mjs');
const { buildManifest } = await import(pathToFileURL(manifestPath).href);
const manifest = buildManifest();
const ids = manifest.products.filter((product) => product.eligible_channels.includes(channel))
  .sort((a, b) => a.nombre.localeCompare(b.nombre, 'es') || a.product_id.localeCompare(b.product_id, 'en'))
  .map((product) => product.product_id);
const size = manifest.pagination.page_size;
const pages = Array.from({ length: Math.ceil(ids.length / size) }, (_, i) => ids.slice(i * size, (i + 1) * size));
const data = { catalog: { page_size: size, pages } };
const dataset = JSON.stringify(data);
const datasetPath = join(directory, 'dataset.json');
await writeFile(datasetPath, dataset);
const badDatasetPath = join(directory, 'dataset-invalido.json');
const badDataset = JSON.stringify({ catalog: { page_size: size, pages: [[]] } });
await writeFile(badDatasetPath, badDataset);
const wrongDatasetPath = join(directory, 'dataset-semanticamente-incorrecto.json');
const wrongPages = pages.map((page, i) => i === 0 ? ['DEMO-ID-INCORRECTO', ...page.slice(1)] : page);
const wrongDataset = JSON.stringify({ catalog: { page_size: size, pages: wrongPages } });
await writeFile(wrongDatasetPath, wrongDataset);

const config = {
  environment: 'ISOLATED',
  case_id: 'PERF-01',
  channel,
  profiles: ['demo-smoke'],
  max_rps: 2,
  window_start_utc: utc(Date.now() - 30_000),
  window_end_utc: utc(Date.now() + 600_000),
  approval_ref: 'FIXTURE_LOCAL',
  revision: 'FIXTURE_CATALOGO',
  backend_sha: backendSha,
  frontend_sha: frontendSha,
  docs_sha: docsSha,
  dataset_sha256: digest(dataset),
  allow_negative_401: true,
};
const configPath = join(directory, 'config.json');
await writeFile(configPath, JSON.stringify(config));
const invalidConfigPath = join(directory, 'config-dataset-invalido.json');
await writeFile(invalidConfigPath, JSON.stringify({ ...config, dataset_sha256: digest(badDataset) }));
const wrongConfigPath = join(directory, 'config-semanticamente-incorrecto.json');
await writeFile(wrongConfigPath, JSON.stringify({ ...config, dataset_sha256: digest(wrongDataset) }));

const server = await fixture.startCatalogPaginationFixtureServer({ manifest });
try {
  if (!/^http:\/\/127\.0\.0\.1:[1-9]\d{0,4}$/.test(server.baseUrl)) throw new Error('FIXTURE_NO_LOOPBACK');
  const env = {
    ...process.env,
    G6_K6_TARGET: server.baseUrl,
    G6_K6_APPROVED_ORIGIN: '',
    G6_K6_TEST_TOKEN: server.authorization.replace(/^Bearer /, ''),
  };

  function invoke({ configFile = configPath, dataFile = datasetPath, extra = [], override = {} } = {}) {
    return new Promise((complete, reject) => {
      const args = ['-NoProfile', '-File', join(base, 'bin/ejecutar-demo.ps1'),
        '-Config', configFile, '-Dataset', dataFile,
        ...(k6Path ? ['-K6Path', resolve(k6Path)] : []), ...extra];
      const child = spawn('powershell.exe', args, {
        env: { ...env, ...override }, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'],
      });
      let output = '';
      for (const stream of [child.stdout, child.stderr]) {
        stream.setEncoding('utf8').on('data', (chunk) => { output += chunk; });
      }
      child.once('error', reject);
      child.once('close', (code) => complete({ code, output }));
    });
  }

  async function verify(label, options, expectedCode, expectedMessage) {
    const result = await invoke(options);
    if (result.code !== expectedCode || !expectedMessage.test(result.output) ||
        result.output.includes(server.authorization) || result.output.includes(server.baseUrl)) {
      throw new Error(label + '_FALLO (' + result.code + ') ' +
        (result.output.match(/(?:PREFLIGHT|EVIDENCIA)_[A-Z0-9_]+/)?.[0] ?? 'SIN_DIAGNOSTICO'));
    }
    process.stdout.write(label + ' OK\n');
    return result;
  }

  await verify('INSPECT', { extra: ['-SoloValidar'] }, 0, /NO_EJECUTADO/);
  await verify('HOST_AJENO', { extra: ['-SoloValidar'], override: { G6_K6_TARGET: 'https://example.invalid' } },
    2, /PREFLIGHT_LOOPBACK_INVALIDO/);
  await verify('PERFIL_DENEGADO', { extra: ['-SoloValidar', '-Profile', 'demo-normal'] },
    2, /PREFLIGHT_CASO_CANAL_O_PERFIL_NO_AUTORIZADO/);
  await verify('DATASET_AUSENTE', { dataFile: join(directory, 'ausente.json'), extra: ['-SoloValidar'] },
    2, /PREFLIGHT_DATASET_AUSENTE/);
  await verify('DATASET_HASH_AJENO', { dataFile: badDatasetPath, extra: ['-SoloValidar'] },
    2, /PREFLIGHT_HASH_DATASET_INVALIDO/);
  await verify('DATASET_INVALIDO', { configFile: invalidConfigPath, dataFile: badDatasetPath, extra: ['-SoloValidar'] },
    2, /PREFLIGHT_K6_INSPECT_RECHAZADO/);
  if (!flags.includes('--validar')) {
    for (const [label, options] of [
      ['HTTP_401_PREVIO', { override: { G6_K6_TEST_TOKEN: 'fixture-token-no-valido' } }],
      ['HTTP_200_INVARIANTES_INVALIDAS', { configFile: wrongConfigPath, dataFile: wrongDatasetPath }],
    ]) {
      const result = await invoke(options);
      if (!result.code || result.code === 2 || !/\bFAIL\b/.test(result.output) ||
          result.output.includes(server.baseUrl) || result.output.includes(server.authorization)) {
        throw new Error(label + '_NO_BLOQUEADA');
      }
      process.stdout.write(label + ' OK\n');
    }
    const live = await verify('PERF_01_FIXTURE', {
      extra: ['-Negative401', ...(flags.includes('--dashboard') ? ['-Dashboard'] : [])],
    }, 0, /\bPASS\b/);
    const location = /\.local\/[a-f0-9]{32}\/summary\.json/.exec(live.output)?.[0];
    const file = await readFile(join(base, location), 'utf8');
    const report = JSON.parse(file.replace(/^\uFEFF/, ''));
    if (report.scope !== 'L1_FIXTURE_SINTETICO' || report.metrics.negative_401 !== 1 ||
        file.includes(server.baseUrl) || file.includes(env.G6_K6_TEST_TOKEN)) throw new Error('EVIDENCIA_NO_SEGURA');
    process.stdout.write(live.output);
  }
} catch (error) {
  process.stderr.write((/^[A-Z0-9_ ()-]+$/.test(error.message) ? error.message : 'DEMO_LOCAL_FALLO') + '\n');
  process.exitCode = 1;
} finally {
  await server.close();
}
