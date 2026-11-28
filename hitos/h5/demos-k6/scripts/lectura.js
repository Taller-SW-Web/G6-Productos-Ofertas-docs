import http from 'k6/http';
import { check, fail, sleep } from 'k6';
import { sha256 } from 'k6/crypto';
import execution from 'k6/execution';
import { Counter, Rate, Trend } from 'k6/metrics';
import { buildReads } from './contratos.js';

const profiles = {
  'demo-smoke': [1, 60, 5],
  'demo-normal': [5, 180, 10],
  'formal-carga': [20, 300, 20],
};

function parseJson(response) {
  if (!/^application\/(?:[a-z0-9.+-]+\+)?json(?:\s*;|$)/i.test(response.headers['Content-Type'] ?? '')) return null;
  try { return response.json(); } catch { return null; }
}

export function reader(caseId) {
  const target = __ENV.G6_K6_TARGET ?? '';
  const token = __ENV.G6_K6_TEST_TOKEN ?? '';
  const environment = __ENV.G6_K6_ENVIRONMENT;
  const approvedUntil = Number(__ENV.G6_K6_END_EPOCH);
  const profile = __ENV.G6_K6_PROFILE;
  const channel = __ENV.G6_K6_CHANNEL;
  const [vus, seconds, ceiling] = profiles[profile] ?? [];
  const maxRps = Number(__ENV.G6_K6_MAX_RPS);
  const local = environment === 'ISOLATED';
  const originAllowed = local
    ? /^http:\/\/127\.0\.0\.1:[1-9]\d{0,4}$/.test(target)
    : environment === 'STAGING_APIM' && /^https:\/\/[a-z0-9.-]+(?::\d{1,5})?$/.test(target) &&
      target === __ENV.G6_K6_APPROVED_ORIGIN;
  if (!originAllowed || !token || /\s/.test(token) || !Number.isFinite(approvedUntil) ||
      !vus || !Number.isInteger(maxRps) || maxRps < 1 || maxRps > ceiling ||
      !['MARKETPLACE', 'CHATBOT', 'RETAIL'].includes(channel) ||
      (local && (caseId !== 'PERF-01' || profile !== 'demo-smoke'))) fail('PREFLIGHT_CONFIG_INVALIDA');

  const datasetBytes = open(__ENV.G6_K6_DATASET);
  const datasetHash = sha256(datasetBytes, 'hex');
  if (datasetHash !== __ENV.G6_K6_DATASET_SHA256) fail('PREFLIGHT_HASH_DATASET_INVALIDO');
  const reads = buildReads(caseId, JSON.parse(datasetBytes.replace(/^\uFEFF/, '')), channel);
  const tags = { caso: caseId, ambiente: environment, perfil: profile };
  const unexpected = new Rate('demo_inesperados');
  const semantic = new Rate('demo_invariantes_2xx');
  const accepted = new Counter('demo_2xx_validos');
  const duration = new Trend('demo_2xx_duracion', true);
  const statuses = Object.fromEntries(['2xx','401','403','429','4xx_otros','5xx','otros']
    .map((name) => [name, new Counter(`demo_http_${name}`)]));
  const negative = new Counter('demo_negativa_401');
  const finished = new Counter('demo_postflight');

  const options = {
    scenarios: { medicion: { executor: 'constant-vus', vus, duration: `${seconds}s`, gracefulStop: '5s' } },
    setupTimeout: '25s',
    teardownTimeout: '10s',
    rps: maxRps,
    maxRedirects: 0,
    systemTags: ['status', 'method', 'scenario', 'expected_response', 'check'],
    tags,
    summaryTrendStats: ['p(50)', 'p(95)', 'p(99)'],
    thresholds: {
      demo_inesperados: [
        'rate<0.01',
        { threshold: 'rate<0.20', abortOnFail: true, delayAbortEval: '10s' },
      ],
      demo_invariantes_2xx: ['rate==1'],
      demo_2xx_validos: ['count>0'],
      demo_postflight: ['count==1'],
    },
  };

  function read(probe, phase, authenticated = true) {
    if (Date.now() + 5000 >= approvedUntil) execution.test.abort('VENTANA_AUTORIZADA_FINALIZADA');
    const headers = { Accept: 'application/json' };
    if (authenticated) headers.Authorization = `Bearer ${token}`;
    return http.get(target + probe.path, {
      headers, timeout: '5s', redirects: 0, tags: { fase: phase },
    });
  }

  const validate = (response, probe) => response.status === 200 && probe.valid(parseJson(response));

  function setup() {
    for (const probe of reads) {
      if (!validate(read(probe, 'preflight'), probe)) fail('PREFLIGHT_HTTP_O_INVARIANTE_INVALIDA');
    }
    if (__ENV.G6_K6_NEGATIVE_401 === '1') {
      const response = read(reads[0], 'negativa', false);
      if (response.status !== 401) fail('PREFLIGHT_NEGATIVA_DISTINTA_DE_401');
      negative.add(1);
    }
    return { started: Date.now() };
  }

  function run() {
    const probe = reads[execution.scenario.iterationInTest % reads.length];
    const response = read(probe, 'medicion');
    const status = response.status;
    const is2xx = status >= 200 && status < 300;
    const bucket = is2xx ? '2xx' : [401, 403, 429].includes(status) ? String(status)
      : status >= 400 && status < 500 ? '4xx_otros' : status >= 500 ? '5xx' : 'otros';
    statuses[bucket].add(1);
    const passed = check(response, { 'lectura HTTP 200 e invariantes': (result) => validate(result, probe) });
    unexpected.add(!passed);
    if (is2xx) semantic.add(passed);
    if (passed) {
      accepted.add(1);
      duration.add(response.timings.duration);
    }
    if ([401, 403, 429].includes(status)) execution.test.abort('AUTORIZACION_O_CUOTA_INTERRUMPIO_LA_DEMO');
    sleep(0.1);
  }

  function teardown(data) {
    if (!data?.started || Date.now() - data.started < seconds * 1000 - 1000) return;
    if (!validate(read(reads[0], 'postflight'), reads[0])) fail('POSTFLIGHT_INVARIANTE_INVALIDA');
    finished.add(1);
  }

  function handleSummary(data) {
    const metric = (name) => data.metrics[name]?.values ?? {};
    const counts = Object.fromEntries(Object.keys(statuses).map((name) => [name, metric(`demo_http_${name}`).count ?? 0]));
    const latency = metric('demo_2xx_duracion');
    const valid = metric('demo_2xx_validos').count ?? 0;
    const runtime = {
      dataset_sha256: datasetHash,
      configured_vus: vus,
      observed_max_vus: metric('vus').max ?? null,
      configured_seconds: seconds,
      elapsed_seconds: data.state.testRunDurationMs / 1000,
      iterations: metric('iterations').count ?? 0,
      status_counts: counts,
      valid_2xx: valid,
      rps_valid_2xx: valid / seconds,
      p50_ms: latency['p(50)'] ?? null,
      p95_ms: latency['p(95)'] ?? null,
      p99_ms: latency['p(99)'] ?? null,
      critical_checks: metric('demo_invariantes_2xx').rate ?? null,
      unexpected_error_rate: metric('demo_inesperados').rate ?? null,
      negative_401: metric('demo_negativa_401').count ?? 0,
      completed: metric('demo_postflight').count === 1,
    };
    return { [__ENV.G6_K6_RUNTIME_OUTPUT]: JSON.stringify(runtime, null, 2) + '\n' };
  }

  return { options, setup, run, teardown, handleSummary };
}
