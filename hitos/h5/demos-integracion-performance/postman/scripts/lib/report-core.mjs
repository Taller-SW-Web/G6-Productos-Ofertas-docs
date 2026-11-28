import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { OPENAPI_CONTRACT_VERSION } from './constants.mjs';
import { containsSensitiveLeak, sha256Buffer } from './sanitizer-core.mjs';

export function resolveGitHead(repoPath) {
  if (!repoPath || !existsSync(repoPath)) return 'UNAVAILABLE';
  try {
    return execFileSync('git', ['-C', repoPath, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
  } catch {
    return 'UNAVAILABLE';
  }
}

export function buildManifest({
  runId,
  environmentName,
  profile,
  baseUrlOrigin,
  collectionPath,
  newmanVersion,
  backendSha,
  frontendSha,
  docsSha,
  deployedRevision = 'NO_VERIFICADO_EN_ESTA_CORRIDA',
  evidenceLevel = 'LAB_AZURE',
  deploymentState = 'NO_VERIFICADO',
  selectedCases = [],
  fixtures = {},
  blockers = [],
  durationMs = 0,
  exitCode = 0,
}) {
  const collectionHash = existsSync(collectionPath)
    ? sha256Buffer(readFileSync(collectionPath))
    : 'UNAVAILABLE';

  return {
    schemaVersion: '1.0.0',
    runId,
    timestampUtc: new Date().toISOString(),
    environment: environmentName,
    targetOrigin: baseUrlOrigin,
    profile,
    subjects: {
      backendLocalHeadSha: backendSha,
      frontendLocalHeadSha: frontendSha,
      docsLocalHeadSha: docsSha,
      note: 'Los SHAs locales corresponden a los working trees inspeccionados y no se atribuyen al despliegue remoto sin verificacion independiente.',
    },
    deployedRevision,
    collection: {
      file: basename(collectionPath),
      sha256: collectionHash,
    },
    runtime: {
      nodeVersion: process.versions.node,
      newmanVersion,
    },
    contract: {
      openApiVersion: OPENAPI_CONTRACT_VERSION,
      path: 'contratos/http/openapi.yaml',
    },
    selectedCases,
    fixtures,
    evidenceLevel,
    deploymentState,
    blockers,
    durationMs,
    exitCode,
  };
}

export function buildMarkdownReport(manifest, sanitizedSummary, extraSecrets = []) {
  const t = sanitizedSummary.totals;
  const lines = [
    `# Reporte de Pruebas de Integracion HTTP — G6 Hito 5`,
    '',
    `- **Run ID:** \`${manifest.runId}\``,
    `- **Fecha UTC:** \`${manifest.timestampUtc}\``,
    `- **Entorno:** \`${manifest.environment}\` (\`${manifest.targetOrigin}\`)`,
    `- **Perfil:** \`${manifest.profile}\``,
    `- **Nivel de evidencia:** \`${manifest.evidenceLevel}\``,
    `- **Estado de despliegue:** \`${manifest.deploymentState}\``,
    `- **Contrato OpenAPI:** \`${manifest.contract.openApiVersion}\``,
    `- **Node.js / Newman:** \`${manifest.runtime.nodeVersion}\` / \`${manifest.runtime.newmanVersion}\``,
    `- **SHA Docs (local):** \`${manifest.subjects.docsLocalHeadSha}\``,
    `- **SHA Backend (local, solo lectura):** \`${manifest.subjects.backendLocalHeadSha}\``,
    `- **SHA Frontend (local, solo lectura):** \`${manifest.subjects.frontendLocalHeadSha}\``,
    `- **SHA-256 Coleccion:** \`${manifest.collection.sha256}\``,
    '',
    '## Resumen de ejecucion',
    '',
    '| Metrica | Valor |',
    '|---|---:|',
    `| Solicitudes ejecutadas | ${t.requests} |`,
    `| PASS | ${t.pass} |`,
    `| FAIL | ${t.fail} |`,
    `| INCONCLUSIVE | ${t.inconclusive} |`,
    `| NOT_RUN | ${t.notRun} |`,
    `| Aserciones totales | ${t.assertionsTotal} |`,
    `| Aserciones aprobadas | ${t.assertionsPassed} |`,
    `| Aserciones fallidas | ${t.assertionsFailed} |`,
    `| Duracion total (ms) | ${t.durationMs} |`,
    '',
    '## Resultados por caso',
    '',
    '| ID PM | ID INT | Caso | Metodo | HTTP | Aserciones | Duracion (ms) | Correlation ID | Estado |',
    '|---|---|---|---|---:|---:|---:|---|---|',
  ];

  for (const c of sanitizedSummary.cases) {
    lines.push(
      `| ${c.pmId} | ${c.intId} | ${c.name} | ${c.method} | ${c.httpStatus ?? 'ERR'} | ${c.assertionsPassed}/${c.assertionsTotal} | ${c.durationMs} | \`${c.correlationId || '-'}\` | **${c.status}** |`,
    );
  }

  const failedCases = sanitizedSummary.cases.filter((c) => c.status === 'FAIL');
  if (failedCases.length > 0) {
    lines.push('', '## Detalle de fallos', '');
    for (const c of failedCases) {
      lines.push(`### ${c.pmId} — ${c.name}`);
      if (c.requestError) {
        lines.push(`- Error de red/solicitud: \`${c.requestError}\``);
      }
      for (const a of c.assertions.filter((x) => !x.passed)) {
        lines.push(`- Asercion fallida: **${a.name}** — \`${a.errorMessage || 'sin detalle'}\``);
      }
      lines.push('');
    }
  }

  if (manifest.blockers && manifest.blockers.length > 0) {
    lines.push('', '## Bloqueos y advertencias', '');
    for (const b of manifest.blockers) {
      lines.push(`- ${b}`);
    }
  }

  const md = `${lines.join('\n')}\n`;
  const leakCheck = containsSensitiveLeak(md, extraSecrets);
  if (leakCheck.leaked) {
    throw new Error(`Sanitizacion Markdown bloqueada: posible fuga sensible (${leakCheck.reasons.join('; ')}).`);
  }
  return md;
}

/**
 * Escribe todos los artefactos saneados en outDir y genera evidence-index.json
 * con los hashes SHA-256 de los bytes efectivamente guardados (sin incluirse a si mismo).
 */
export function writeEvidenceBundle(outDir, { manifest, sanitizedSummary, junitXml, markdownReport }) {
  const filesToWrite = [
    { name: 'manifest.json', content: `${JSON.stringify(manifest, null, 2)}\n` },
    { name: 'newman-summary.json', content: `${JSON.stringify({ runId: sanitizedSummary.runId, totals: sanitizedSummary.totals, generatedAtUtc: sanitizedSummary.generatedAtUtc }, null, 2)}\n` },
    { name: 'integration-results.json', content: `${JSON.stringify(sanitizedSummary, null, 2)}\n` },
    { name: 'newman.junit.xml', content: junitXml },
    { name: 'report.md', content: markdownReport },
  ];

  const artifacts = [];
  for (const f of filesToWrite) {
    const fullPath = join(outDir, f.name);
    writeFileSync(fullPath, f.content, 'utf8');
    const savedBytes = readFileSync(fullPath);
    artifacts.push({
      file: f.name,
      bytes: savedBytes.length,
      sha256: sha256Buffer(savedBytes),
    });
  }

  const index = {
    schemaVersion: '1.0.0',
    runId: manifest.runId,
    generatedAtUtc: new Date().toISOString(),
    note: 'evidence-index.json no se incluye en su propio calculo de checksum.',
    artifacts,
  };

  const indexPath = join(outDir, 'evidence-index.json');
  writeFileSync(indexPath, `${JSON.stringify(index, null, 2)}\n`, 'utf8');

  return { indexPath, artifacts };
}
