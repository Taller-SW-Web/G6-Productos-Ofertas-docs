import { createHash } from 'node:crypto';
import { CASE_METADATA, SENSITIVE_KEY_PATTERNS, SENSITIVE_VALUE_PATTERNS } from './constants.mjs';

const REDACTED = '[REDACTED]';

export function redactString(input, extraSecrets = []) {
  if (typeof input !== 'string') return input;
  let out = input;

  for (const secret of extraSecrets) {
    if (typeof secret === 'string' && secret.length >= 6) {
      out = out.split(secret).join(REDACTED);
    }
  }

  for (const pattern of SENSITIVE_VALUE_PATTERNS) {
    pattern.lastIndex = 0;
    if (pattern.source.startsWith('([?&]')) {
      out = out.replace(pattern, `$1${REDACTED}`);
    } else {
      out = out.replace(pattern, REDACTED);
    }
  }

  return out;
}

/**
 * H09: Evita que mensajes de excepcion (como JSON.parse o aserciones Chai) incorporen
 * cuerpos de respuesta privados en las evidencias publicadas.
 */
export function sanitizeErrorMessage(rawMessage, extraSecrets = []) {
  if (!rawMessage) return null;
  const text = typeof rawMessage === 'string' ? rawMessage : String(rawMessage);
  // Keep only the first line so multi-line echoed response bodies are never persisted
  let firstLine = text.split(/\r?\n/)[0].trim();
  // Strip JSON object/array payloads that Chai or JSON.parse might embed inline
  firstLine = firstLine.replace(/\{[^}]{12,}\}/g, '{[BODY_REDACTED]}');
  firstLine = firstLine.replace(/\[[^\]]{24,}\]/g, '[[BODY_REDACTED]]');
  // Redact email addresses or private tokens inside error messages
  firstLine = firstLine.replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, '[EMAIL_REDACTED]');
  firstLine = redactString(firstLine, extraSecrets);
  if (firstLine.length > 220) {
    firstLine = `${firstLine.slice(0, 217)}...`;
  }
  return firstLine;
}

export function sanitizeUrl(rawUrl, extraSecrets = []) {
  if (!rawUrl || typeof rawUrl !== 'string') return '';
  try {
    const u = new URL(rawUrl);
    for (const k of Array.from(u.searchParams.keys())) {
      if (SENSITIVE_KEY_PATTERNS.some((rx) => rx.test(k))) {
        u.searchParams.delete(k);
      }
    }
    u.username = '';
    u.password = '';
    return redactString(u.toString(), extraSecrets);
  } catch {
    return redactString(rawUrl, extraSecrets);
  }
}

export function containsSensitiveLeak(text, extraSecrets = []) {
  if (typeof text !== 'string') return { leaked: false, reasons: [] };
  const reasons = [];

  for (const secret of extraSecrets) {
    if (typeof secret === 'string' && secret.length >= 6 && text.includes(secret)) {
      reasons.push('Exact runtime secret match detected in output');
    }
  }

  for (const pattern of SENSITIVE_VALUE_PATTERNS) {
    pattern.lastIndex = 0;
    if (pattern.test(text)) {
      reasons.push(`Sensitive pattern matched: ${pattern.source}`);
    }
  }

  return { leaked: reasons.length > 0, reasons };
}

function getHeaderValue(headers = [], targetName) {
  const lower = targetName.toLowerCase();
  const found = (headers || []).find((h) => String(h.key || h.name || '').toLowerCase() === lower);
  return found ? String(found.value || '') : '';
}

function extractPmId(itemName = '') {
  const match = String(itemName).match(/^(PM-\d+[A-Z]?)\b/);
  return match ? match[1] : 'PM-UNKNOWN';
}

export function computeOverallVerdict(totals) {
  if (totals.fail > 0) return 'FAIL';
  if (totals.inconclusive > 0) return 'INCONCLUSIVE';
  if (totals.planned > 0 && totals.notRun > 0) return 'PARTIAL_NOT_COMPLETE';
  if (totals.planned > 0 && totals.pass === totals.planned) return 'PASS';
  if (totals.requests > 0 && totals.pass === totals.requests && totals.notRun === 0) return 'PASS';
  return 'INCONCLUSIVE';
}

/**
 * Construye el reporte saneado usando exclusivamente una lista explicita de campos permitidos
 * (allowlist), reconciliando casos planificados vs ejecutados (H04) y saneando excepciones (H09).
 */
export function sanitizeNewmanRun(rawSummary, options = {}) {
  const {
    runId = 'unknown-run',
    environmentName = 'unknown',
    profile = 'smoke',
    extraSecrets = [],
    evidenceLevel = 'LAB_AZURE',
    plannedCases = null, // Array of { pmId, name, method, url, executable, blockerReason }
  } = options;

  if (!rawSummary || typeof rawSummary !== 'object' || !rawSummary.run) {
    throw new Error('Resumen crudo de Newman invalido o ausente: no se puede sanear.');
  }

  const executions = Array.isArray(rawSummary.run.executions) ? rawSummary.run.executions : [];
  const executedById = new Map();
  const executedList = [];

  for (const exec of executions) {
    const itemName = redactString(exec.item?.name || 'Unnamed request', extraSecrets);
    const pmId = extractPmId(itemName);
    const meta = CASE_METADATA[pmId] || {
      intId: 'N/A',
      services: ['api-gateway'],
      type: 'lectura',
      scope: 'desconocido',
    };

    const reqHeaders = exec.request?.header || [];
    const resHeaders = exec.response?.header || [];
    const correlationId = redactString(
      getHeaderValue(resHeaders, 'x-correlation-id') || getHeaderValue(reqHeaders, 'x-correlation-id') || '',
      extraSecrets,
    );
    const contentType = redactString(getHeaderValue(resHeaders, 'content-type') || '', extraSecrets);

    const assertionsRaw = Array.isArray(exec.assertions) ? exec.assertions : [];
    const assertions = assertionsRaw.map((a) => ({
      name: redactString(a.assertion || '', extraSecrets),
      passed: !a.error,
      errorMessage: a.error ? sanitizeErrorMessage(a.error.message || String(a.error), extraSecrets) : null,
    }));

    const passedAssertions = assertions.filter((a) => a.passed).length;
    const failedAssertions = assertions.filter((a) => !a.passed).length;
    const requestError = exec.requestError
      ? sanitizeErrorMessage(
          exec.requestError.message ||
            exec.requestError.code ||
            (typeof exec.requestError === 'object' ? JSON.stringify(exec.requestError) : String(exec.requestError)),
          extraSecrets,
        )
      : null;

    let status = 'PASS';
    let blockerReason = null;

    if (requestError) {
      status = 'FAIL';
      blockerReason = requestError;
    } else if (failedAssertions > 0) {
      status = 'FAIL';
    } else if (assertions.length === 0) {
      status = 'INCONCLUSIVE';
      blockerReason = 'No se ejecutaron aserciones en la solicitud.';
    }

    let rawUrl = '';
    if (typeof exec.request?.url === 'string') {
      rawUrl = exec.request.url;
    } else if (exec.request?.url && typeof exec.request.url === 'object') {
      const u = exec.request.url;
      const proto = u.protocol ? `${u.protocol}://` : 'https://';
      const host = Array.isArray(u.host) ? u.host.join('.') : String(u.host || '');
      const port = u.port ? `:${u.port}` : '';
      const path = Array.isArray(u.path) ? `/${u.path.join('/')}` : String(u.path || '');
      const query = Array.isArray(u.query) && u.query.length > 0
        ? `?${u.query.filter((q) => !q.disabled).map((q) => `${encodeURIComponent(q.key)}=${encodeURIComponent(q.value ?? '')}`).join('&')}`
        : '';
      rawUrl = `${proto}${host}${port}${path}${query}`;
    }

    const record = {
      pmId,
      intId: meta.intId,
      name: itemName,
      services: meta.services,
      type: meta.type,
      scope: meta.scope,
      method: String(exec.request?.method || 'GET').toUpperCase(),
      url: sanitizeUrl(rawUrl, extraSecrets),
      httpStatus: exec.response?.code ?? null,
      contentType,
      durationMs: exec.response?.responseTime ?? 0,
      correlationId,
      assertionsTotal: assertions.length,
      assertionsPassed: passedAssertions,
      assertionsFailed: failedAssertions,
      assertions,
      requestError,
      evidenceLevel,
      status,
      blockerReason,
    };

    executedById.set(pmId, record);
    executedList.push(record);
  }

  // Reconcile plannedCases vs executedCases (H04)
  let cases;
  if (Array.isArray(plannedCases) && plannedCases.length > 0) {
    cases = [];
    for (const plan of plannedCases) {
      const executed = executedById.get(plan.pmId);
      if (executed) {
        cases.push(executed);
      } else {
        const meta = CASE_METADATA[plan.pmId] || {
          intId: 'N/A',
          services: ['api-gateway'],
          type: 'lectura',
          scope: 'desconocido',
        };
        const isBlockedNotRun = !plan.executable;
        cases.push({
          pmId: plan.pmId,
          intId: meta.intId,
          name: redactString(plan.name, extraSecrets),
          services: meta.services,
          type: meta.type,
          scope: meta.scope,
          method: plan.method || 'GET',
          url: sanitizeUrl(plan.url || '', extraSecrets),
          httpStatus: null,
          contentType: '',
          durationMs: 0,
          correlationId: '',
          assertionsTotal: 0,
          assertionsPassed: 0,
          assertionsFailed: 0,
          assertions: [],
          requestError: null,
          evidenceLevel,
          status: isBlockedNotRun ? 'NOT_RUN' : 'INCONCLUSIVE',
          blockerReason: isBlockedNotRun
            ? plan.blockerReason || 'Caso no ejecutado por bloqueo previo.'
            : 'Caso planificado para ejecucion pero ausente en el resultado de Newman (ejecucion incompleta).',
        });
      }
    }
  } else {
    cases = executedList;
  }

  const timings = rawSummary.run.timings || {};
  const totalDurationMs = timings.completed && timings.started ? timings.completed - timings.started : 0;

  const totals = {
    planned: Array.isArray(plannedCases) && plannedCases.length > 0 ? plannedCases.length : cases.length,
    executed: executedList.length,
    requests: cases.length,
    pass: cases.filter((c) => c.status === 'PASS').length,
    fail: cases.filter((c) => c.status === 'FAIL').length,
    inconclusive: cases.filter((c) => c.status === 'INCONCLUSIVE').length,
    notRun: cases.filter((c) => c.status === 'NOT_RUN').length,
    assertionsTotal: cases.reduce((acc, c) => acc + c.assertionsTotal, 0),
    assertionsPassed: cases.reduce((acc, c) => acc + c.assertionsPassed, 0),
    assertionsFailed: cases.reduce((acc, c) => acc + c.assertionsFailed, 0),
    durationMs: totalDurationMs,
  };

  const overallVerdict = computeOverallVerdict(totals);

  const summary = {
    runId,
    environmentName,
    profile,
    evidenceLevel,
    overallVerdict,
    generatedAtUtc: new Date().toISOString(),
    totals,
    cases,
  };

  const serialized = JSON.stringify(summary);
  const leakCheck = containsSensitiveLeak(serialized, extraSecrets);
  if (leakCheck.leaked) {
    throw new Error(`Sanitizacion bloqueada: se detecto posible fuga sensible (${leakCheck.reasons.join('; ')}).`);
  }

  return summary;
}

export function buildSanitizedJunitXml(sanitizedSummary, extraSecrets = []) {
  const escapeXml = (str) =>
    String(str ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');

  const tests = sanitizedSummary.cases.length;
  const failures = sanitizedSummary.cases.filter((c) => c.status === 'FAIL').length;
  const skipped = sanitizedSummary.cases.filter((c) => c.status === 'NOT_RUN' || c.status === 'INCONCLUSIVE').length;
  const timeSec = ((sanitizedSummary.totals.durationMs || 0) / 1000).toFixed(3);

  const lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<testsuites name="G6 - H5 Integration Suite" tests="${tests}" failures="${failures}" skipped="${skipped}" time="${timeSec}">`,
    `  <testsuite name="${escapeXml(sanitizedSummary.profile)}" tests="${tests}" failures="${failures}" skipped="${skipped}" time="${timeSec}">`,
  ];

  for (const c of sanitizedSummary.cases) {
    const caseTime = ((c.durationMs || 0) / 1000).toFixed(3);
    lines.push(`    <testcase classname="${escapeXml(c.intId)}" name="${escapeXml(c.name)}" time="${caseTime}">`);
    if (c.status === 'FAIL') {
      const failedMsgs = c.assertions
        .filter((a) => !a.passed)
        .map((a) => `${a.name}: ${a.errorMessage || 'failed'}`);
      if (c.requestError) failedMsgs.unshift(`RequestError: ${c.requestError}`);
      lines.push(`      <failure message="${escapeXml(failedMsgs.join(' | ') || 'Assertion failed')}"/>`);
    } else if (c.status === 'NOT_RUN' || c.status === 'INCONCLUSIVE') {
      lines.push(`      <skipped message="${escapeXml(c.blockerReason || c.status)}"/>`);
    }
    lines.push('    </testcase>');
  }

  lines.push('  </testsuite>');
  lines.push('</testsuites>');

  const xml = `${lines.join('\n')}\n`;
  const leakCheck = containsSensitiveLeak(xml, extraSecrets);
  if (leakCheck.leaked) {
    throw new Error(`Sanitizacion JUnit bloqueada: posible fuga sensible (${leakCheck.reasons.join('; ')}).`);
  }
  return xml;
}

export function sha256Buffer(bufferOrString) {
  return createHash('sha256').update(bufferOrString).digest('hex');
}
