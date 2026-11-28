#!/usr/bin/env node
import { createRequire } from 'node:module';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import {
  AUTHORIZED_HOSTS,
  CASE_METADATA,
  COLLECTION_PATH,
  DOCS_ROOT,
  ENVIRONMENTS_DIR,
  EVIDENCIAS_DIR,
  POSTMAN_ROOT,
  PROFILES,
} from './lib/constants.mjs';
import { extractRequestsFromItems, runPreflight } from './lib/preflight-core.mjs';
import { buildMarkdownReport, buildManifest, resolveGitHead, writeEvidenceBundle } from './lib/report-core.mjs';
import { buildSanitizedJunitXml, sanitizeNewmanRun } from './lib/sanitizer-core.mjs';

const require = createRequire(import.meta.url);

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token.startsWith('--')) {
      const key = token.slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        args[key] = next;
        i += 1;
      } else {
        args[key] = 'true';
      }
    }
  }
  return args;
}

function buildRuntimeEnvironment(envTemplatePath, overrides) {
  const base = existsSync(envTemplatePath)
    ? JSON.parse(readFileSync(envTemplatePath, 'utf8'))
    : { name: 'runtime', values: [] };

  const map = new Map();
  for (const item of base.values || []) {
    map.set(item.key, { ...item });
  }

  for (const [key, value] of Object.entries(overrides)) {
    if (value !== undefined && value !== null) {
      const existing = map.get(key);
      map.set(key, {
        key,
        value: String(value),
        type: existing?.type || (key.toLowerCase().includes('token') ? 'secret' : 'default'),
        enabled: true,
      });
    }
  }

  return {
    id: `runtime-${overrides.runId}`,
    name: `${base.name} (runtime)`,
    values: Array.from(map.values()),
    _postman_variable_scope: 'environment',
  };
}

/**
 * H02 + H04: Planificacion previa de casos seleccionados segun perfil/carpeta y disponibilidad
 * real de credenciales. Ningun caso sin su credencial requerida se ejecuta para aprobar con 401.
 */
export function planExecution(collection, targetFolders, tokens = {}) {
  const selectedFolders = new Set(targetFolders);
  const plannedCases = [];

  const filteredItems = (collection.item || [])
    .filter((folder) => selectedFolders.has(folder.name))
    .map((folder) => {
      const keptRequests = [];
      for (const reqItem of folder.item || []) {
        const pmId = reqItem.name.match(/^(PM-\d+[A-Z]?)\b/)?.[1] || 'PM-UNKNOWN';
        const meta = CASE_METADATA[pmId] || { authRequirement: 'user' };
        const reqAuth = meta.authRequirement || 'user';

        let executable = true;
        let blockerReason = null;

        if (reqAuth === 'user' && !tokens.accessToken) {
          executable = false;
          blockerReason = 'BLOCKED_AUTH: Requiere G6_ACCESS_TOKEN (userBearer GESTOR_COMERCIAL).';
        } else if (reqAuth === 'restricted' && !tokens.restrictedAccessToken) {
          executable = false;
          blockerReason = 'BLOCKED_AUTH: Requiere G6_RESTRICTED_ACCESS_TOKEN (identidad autenticada sin permiso para validar 403).';
        } else if (reqAuth === 'marketplace' && !tokens.marketplaceAccessToken) {
          executable = false;
          blockerReason = 'BLOCKED_AUTH: Requiere G6_MARKETPLACE_ACCESS_TOKEN (serviceBearer modulo-marketplace).';
        } else if (reqAuth === 'ventas' && !tokens.ventasAccessToken) {
          executable = false;
          blockerReason = 'BLOCKED_AUTH: Requiere G6_VENTAS_ACCESS_TOKEN (serviceBearer modulo-ventas).';
        }

        const rawUrl = typeof reqItem.request?.url === 'string'
          ? reqItem.request.url
          : reqItem.request?.url?.raw || '';

        plannedCases.push({
          pmId,
          folder: folder.name,
          name: reqItem.name,
          method: (reqItem.request?.method || 'GET').toUpperCase(),
          url: rawUrl,
          authRequirement: reqAuth,
          executable,
          blockerReason,
        });

        if (executable) {
          keptRequests.push(reqItem);
        }
      }

      return { ...folder, item: keptRequests };
    })
    .filter((folder) => folder.item.length > 0);

  const filteredCollection = {
    ...collection,
    item: filteredItems,
  };

  return {
    plannedCases,
    executableCount: plannedCases.filter((c) => c.executable).length,
    notRunCount: plannedCases.filter((c) => !c.executable).length,
    filteredCollection,
  };
}

export async function executeSuite(options = {}) {
  const environmentName = options.env || process.env.G6_ENV || 'azure-apim-chile';
  const defaultBaseUrl =
    environmentName === 'local'
      ? 'http://127.0.0.1:3000'
      : `https://${(AUTHORIZED_HOSTS[environmentName] || AUTHORIZED_HOSTS['azure-apim-chile'])[0]}`;

  const baseUrl = options.baseUrl || process.env.G6_BASE_URL || defaultBaseUrl;
  const profile = options.profile || process.env.G6_PROFILE || 'apim-edge';
  const folder = options.folder || null;
  const runId =
    options.runId ||
    process.env.G6_RUN_ID ||
    `${profile}-${new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)}Z`;
  const timeoutRequestMs = Number(options.timeoutRequestMs || process.env.G6_TIMEOUT_MS || 20000);
  const collectionPath = options.collectionPath || COLLECTION_PATH;
  const allowNoAuth = Boolean(options.allowNoAuth);
  const evidenceLevel =
    options.evidenceLevel ||
    (environmentName === 'local' ? 'ISOLATED' : 'LAB_AZURE');
  const deploymentState =
    options.deploymentState ||
    (environmentName === 'local'
      ? 'LOCAL_HARNESS'
      : environmentName === 'azure-apim-chile'
        ? 'APIM_LIVE_145_OPS'
        : 'ACA_MODALIDAD_B_RESTRINGIDA');
  const outRoot = options.outDir ? resolve(options.outDir) : EVIDENCIAS_DIR;

  const accessToken = options.accessToken ?? process.env.G6_ACCESS_TOKEN ?? '';
  const restrictedAccessToken = options.restrictedAccessToken ?? process.env.G6_RESTRICTED_ACCESS_TOKEN ?? '';
  const marketplaceAccessToken = options.marketplaceAccessToken ?? process.env.G6_MARKETPLACE_ACCESS_TOKEN ?? '';
  const ventasAccessToken = options.ventasAccessToken ?? process.env.G6_VENTAS_ACCESS_TOKEN ?? '';
  const extraSecrets = [accessToken, restrictedAccessToken, marketplaceAccessToken, ventasAccessToken].filter(Boolean);

  const preflight = runPreflight({
    baseUrl,
    environmentName,
    profile,
    folder,
    requireAuth: !allowNoAuth,
    accessToken,
    marketplaceAccessToken,
    ventasAccessToken,
    collectionPath,
    scanRoot: POSTMAN_ROOT,
    skipSecretScan: Boolean(options.skipSecretScan),
    fixtures: {
      priceMin: options.priceMin ?? process.env.G6_PRICE_MIN ?? 0,
      priceMax: options.priceMax ?? process.env.G6_PRICE_MAX ?? 100,
    },
  });

  if (!preflight.ok) {
    return {
      ok: false,
      exitCode: 2,
      stage: 'preflight',
      errors: preflight.errors,
      warnings: preflight.warnings,
    };
  }

  let newman;
  let newmanVersion = 'unknown';
  try {
    newman = require('newman');
    const newmanPkg = require('newman/package.json');
    newmanVersion = newmanPkg.version;
  } catch (err) {
    return {
      ok: false,
      exitCode: 3,
      stage: 'newman_load',
      errors: [`No se pudo cargar Newman local. Ejecute 'npm ci' primero. Detalle: ${err.message}`],
      warnings: preflight.warnings,
    };
  }

  const rawCollection = JSON.parse(readFileSync(collectionPath, 'utf8'));
  const targetFolders = folder
    ? [folder]
    : [...(PROFILES[profile]?.folders || PROFILES['apim-edge'].folders)];

  const plan = planExecution(rawCollection, targetFolders, {
    accessToken,
    restrictedAccessToken,
    marketplaceAccessToken,
    ventasAccessToken,
  });

  const privateTmpDir = mkdtempSync(join(tmpdir(), 'g6-h5-newman-'));
  const rawJsonPath = join(privateTmpDir, 'raw-newman.json');
  const tempEnvPath = join(privateTmpDir, 'runtime-env.json');

  const envTemplatePath =
    environmentName === 'local'
      ? join(ENVIRONMENTS_DIR, 'local.example.json')
      : environmentName === 'azure-apim-chile'
        ? join(ENVIRONMENTS_DIR, 'apim.example.json')
        : join(ENVIRONMENTS_DIR, 'environment.example.json');

  const runtimeEnv = buildRuntimeEnvironment(envTemplatePath, {
    environmentName,
    baseUrl,
    channel: options.channel || process.env.G6_CHANNEL || 'MARKETPLACE',
    accessToken,
    restrictedAccessToken,
    marketplaceAccessToken,
    ventasAccessToken,
    productId: options.productId || process.env.G6_PRODUCT_ID || '',
    sku: options.sku || process.env.G6_SKU || '',
    priceMin: options.priceMin ?? process.env.G6_PRICE_MIN ?? '0',
    priceMax: options.priceMax ?? process.env.G6_PRICE_MAX ?? '100',
    priceMaxNarrow: options.priceMaxNarrow ?? process.env.G6_PRICE_MAX_NARROW ?? '60',
    runId,
  });

  writeFileSync(tempEnvPath, JSON.stringify(runtimeEnv), { mode: 0o600 });

  const startedAt = Date.now();
  let newmanExitCode = 0;
  let newmanSummary = null;
  let newmanError = null;

  if (plan.executableCount > 0) {
    try {
      newmanSummary = await new Promise((resolveRun, rejectRun) => {
        newman.run(
          {
            collection: plan.filteredCollection,
            environment: tempEnvPath,
            reporters: ['json'],
            reporter: {
              json: { export: rawJsonPath },
            },
            timeoutRequest: timeoutRequestMs,
            ignoreRedirects: true,
            bail: false,
          },
          (err, summary) => {
            if (err) {
              rejectRun(err);
              return;
            }
            resolveRun(summary);
          },
        );
      });

      const failures = newmanSummary?.run?.failures || [];
      if (failures.length > 0) {
        newmanExitCode = 1;
      }
    } catch (err) {
      newmanError = err;
      newmanExitCode = 1;
    }
  } else {
    newmanSummary = {
      run: {
        executions: [],
        failures: [],
        timings: { started: startedAt, completed: Date.now() },
      },
    };
  }

  const durationMs = Date.now() - startedAt;

  let sanitizedSummary;
  let junitXml;
  let manifest;
  let markdownReport;
  const evidenceDir = join(outRoot, runId);

  try {
    const rawData = existsSync(rawJsonPath)
      ? JSON.parse(readFileSync(rawJsonPath, 'utf8'))
      : newmanSummary;

    if (!rawData) {
      throw new Error(`Newman fallo antes de producir resumen: ${newmanError?.message || 'sin detalle'}`);
    }

    sanitizedSummary = sanitizeNewmanRun(rawData, {
      runId,
      environmentName,
      profile: folder ? `folder:${folder}` : profile,
      evidenceLevel,
      extraSecrets,
      plannedCases: plan.plannedCases,
    });

    // Preserve fail exit code if any case failed or was inconclusive
    if (sanitizedSummary.totals.fail > 0 || sanitizedSummary.totals.inconclusive > 0) {
      newmanExitCode = 1;
    }

    junitXml = buildSanitizedJunitXml(sanitizedSummary, extraSecrets);

    const workspaceParent = resolve(DOCS_ROOT, '..');
    const backendRepo = process.env.G6_BACKEND_ROOT || join(workspaceParent, 'G6-Productos-Ofertas-backend-poma-hito-5-pruebas-v2');
    const frontendRepo = process.env.G6_FRONTEND_ROOT || join(workspaceParent, 'G6-Productos-Ofertas-frontend-poma-hito-5-pruebas-v2');

    const blockers = [...preflight.warnings];
    const notRunList = sanitizedSummary.cases.filter((c) => c.status === 'NOT_RUN');
    if (notRunList.length > 0) {
      blockers.push(
        `Ejecucion parcial (${sanitizedSummary.overallVerdict}): ${notRunList.length} de ${sanitizedSummary.totals.planned} casos planificados quedaron NOT_RUN por credenciales ausentes.`,
      );
    }

    manifest = buildManifest({
      runId,
      environmentName,
      profile: folder ? `folder:${folder}` : profile,
      baseUrlOrigin: new URL(baseUrl).origin,
      collectionPath,
      newmanVersion,
      backendSha: resolveGitHead(backendRepo),
      frontendSha: resolveGitHead(frontendRepo),
      docsSha: resolveGitHead(DOCS_ROOT),
      evidenceLevel,
      deploymentState,
      overallVerdict: sanitizedSummary.overallVerdict,
      plannedCases: plan.plannedCases.map((c) => c.pmId),
      executedCases: sanitizedSummary.cases.filter((c) => c.status !== 'NOT_RUN').map((c) => c.pmId),
      notRunCases: notRunList.map((c) => ({ pmId: c.pmId, reason: c.blockerReason })),
      fixtures: {
        channel: options.channel || process.env.G6_CHANNEL || 'MARKETPLACE',
        priceMin: Number(options.priceMin ?? process.env.G6_PRICE_MIN ?? 0),
        priceMax: Number(options.priceMax ?? process.env.G6_PRICE_MAX ?? 100),
        priceMaxNarrow: Number(options.priceMaxNarrow ?? process.env.G6_PRICE_MAX_NARROW ?? 60),
      },
      blockers,
      durationMs,
      exitCode: newmanExitCode,
    });

    markdownReport = buildMarkdownReport(manifest, sanitizedSummary, extraSecrets);

    mkdirSync(evidenceDir, { recursive: true });
    writeEvidenceBundle(evidenceDir, {
      manifest,
      sanitizedSummary,
      junitXml,
      markdownReport,
    });
  } catch (sanitizeErr) {
    return {
      ok: false,
      exitCode: 4,
      stage: 'sanitization',
      errors: [`Fallo en sanitizacion o generacion de evidencia (publicacion bloqueada): ${sanitizeErr.message}`],
      warnings: preflight.warnings,
      originalTestExitCode: newmanExitCode,
    };
  } finally {
    rmSync(privateTmpDir, { recursive: true, force: true });
  }

  return {
    ok: newmanExitCode === 0 && sanitizedSummary.overallVerdict === 'PASS',
    exitCode: newmanExitCode,
    overallVerdict: sanitizedSummary.overallVerdict,
    stage: 'completed',
    runId,
    evidenceDir,
    totals: sanitizedSummary.totals,
    warnings: preflight.warnings,
  };
}

const isMain = process.argv[1] && resolve(process.argv[1]) === resolve(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
if (isMain) {
  const cli = parseArgs(process.argv.slice(2));
  const res = await executeSuite({
    env: cli.env,
    baseUrl: cli['base-url'],
    profile: cli.profile,
    folder: cli.folder,
    runId: cli['run-id'],
    outDir: cli['out-dir'],
    channel: cli.channel,
    timeoutRequestMs: cli.timeout,
    allowNoAuth: cli['allow-no-auth'] === 'true',
    evidenceLevel: cli['evidence-level'],
  });

  if (res.stage === 'completed') {
    console.log(`\n=== Resumen de Ejecucion Newman (${res.runId}) ===`);
    console.log(`  Veredicto   : ${res.overallVerdict}`);
    console.log(`  Planificados: ${res.totals.planned}`);
    console.log(`  Ejecutados  : ${res.totals.executed}`);
    console.log(`  PASS        : ${res.totals.pass}`);
    console.log(`  FAIL        : ${res.totals.fail}`);
    console.log(`  INCONCLUSIVE: ${res.totals.inconclusive}`);
    console.log(`  NOT_RUN     : ${res.totals.notRun}`);
    console.log(`  Aserciones  : ${res.totals.assertionsPassed}/${res.totals.assertionsTotal}`);
    console.log(`  Duracion    : ${res.totals.durationMs} ms`);
    console.log(`  Evidencia   : ${res.evidenceDir}`);
  } else {
    console.error(`\n[RUNNER] Ejecucion detenida en etapa '${res.stage}':`);
    for (const err of res.errors || []) {
      console.error(`  - ${err}`);
    }
  }

  process.exit(res.exitCode);
}
