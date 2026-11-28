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

/**
 * Construye el reporte saneado usando exclusivamente una lista explicita de campos permitidos
 * (allowlist), descartando cuerpos de respuesta/solicitud y headers sensibles.
 */
export function sanitizeNewmanRun(rawSummary, options = {}) {
  const {
    runId = 'unknown-run',
    environmentName = 'unknown',
    profile = 'smoke',
    extraSecrets = [],
    evidenceLevel = 'LAB_AZURE',
  } = options;

  if (!rawSummary || typeof rawSummary !== 'object' || !rawSummary.run) {
    throw new Error('Resumen crudo de Newman invalido o ausente: no se puede sanear.');
  }

  const executions = Array.isArray(rawSummary.run.executions) ? rawSummary.run.executions : [];
  const cases = [];

  for (const exec of executions) {
    const itemName = redactString(exec.item?.name || 'Unnamed request', extraSecrets);
    const pmId = extractPmId(itemName);
    const meta = CASE_METADATA[pmId] || { intId: 'N/A', services: ['api-gateway'], type: 'lectura', scope: 'desconocido' };

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
      errorMessage: a.error ? redactString(a.error.message || String(a.error), extraSecrets) : null,
    }));

    const passedAssertions = assertions.filter((a) => a.passed).length;
    const failedAssertions = assertions.filter((a) => !a.passed).length;
    const requestError = exec.requestError
      ? redactString(
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

    // Extract safe URL without query secret leakage
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

    cases.push({
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
    });
  }

  const timings = rawSummary.run.timings || {};
  const totalDurationMs = timings.completed && timings.started ? timings.completed - timings.started : 0;

  const summary = {
    runId,
    environmentName,
    profile,
    evidenceLevel,
    generatedAtUtc: new Date().toISOString(),
    totals: {
      requests: cases.length,
      pass: cases.filter((c) => c.status === 'PASS').length,
      fail: cases.filter((c) => c.status === 'FAIL').length,
      inconclusive: cases.filter((c) => c.status === 'INCONCLUSIVE').length,
      notRun: cases.filter((c) => c.status === 'NOT_RUN').length,
      assertionsTotal: cases.reduce((acc, c) => acc + c.assertionsTotal, 0),
      assertionsPassed: cases.reduce((acc, c) => acc + c.assertionsPassed, 0),
      assertionsFailed: cases.reduce((acc, c) => acc + c.assertionsFailed, 0),
      durationMs: totalDurationMs,
    },
    cases,
  };

  // Fail-closed leak check before returning
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
