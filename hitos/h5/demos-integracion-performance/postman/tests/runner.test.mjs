import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { executeSuite } from '../scripts/run-newman.mjs';
import { sha256Buffer } from '../scripts/lib/sanitizer-core.mjs';

function startLocalHarnessServer({ failPriceFilter = false, delayMs = 0 } = {}) {
  const server = http.createServer(async (req, res) => {
    if (delayMs > 0) {
      await new Promise((r) => setTimeout(r, delayMs));
    }
    const u = new URL(req.url, 'http://127.0.0.1');
    const corrId = req.headers['x-correlation-id'] || 'harness-corr';
    res.setHeader('X-Correlation-Id', corrId);

    if (u.pathname === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', service: 'api-gateway' }));
      return;
    }

    if (u.pathname === '/health/ready') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ready', service: 'api-gateway' }));
      return;
    }

    const auth = req.headers.authorization || '';
    if (!auth.startsWith('Bearer ') || auth === 'Bearer invalid.jwt.fixture' || auth === 'Bearer ') {
      res.writeHead(401, { 'Content-Type': 'application/problem+json' });
      res.end(JSON.stringify({ status: 401, code: 'TOKEN_INVALIDO', title: 'No autenticado' }));
      return;
    }

    if (u.pathname === '/api/v1/auditoria-precios' && auth === 'Bearer restricted-synth-token') {
      res.writeHead(403, { 'Content-Type': 'application/problem+json' });
      res.end(JSON.stringify({ status: 403, code: 'SCOPE_INSUFICIENTE', title: 'Prohibido' }));
      return;
    }

    if (u.pathname === '/api/v1/productos') {
      const canal = u.searchParams.get('canal');
      const pagina = Number(u.searchParams.get('pagina') || '1');
      const min = u.searchParams.get('precioMin');
      const max = u.searchParams.get('precioMax');

      if (canal === 'CANAL_INVALIDO' || pagina < 1) {
        res.writeHead(400, { 'Content-Type': 'application/problem+json' });
        res.end(JSON.stringify({ status: 400, code: 'VALIDACION', title: 'Parametros invalidos' }));
        return;
      }

      if (min !== null && max !== null && Number(min) > Number(max)) {
        res.writeHead(400, { 'Content-Type': 'application/problem+json' });
        res.end(JSON.stringify({ status: 400, code: 'VALIDACION', title: 'Rango invalido' }));
        return;
      }

      if (failPriceFilter && max === '100') {
        res.writeHead(500, { 'Content-Type': 'application/problem+json' });
        res.end(JSON.stringify({ status: 500, code: 'ERROR_INTERNO' }));
        return;
      }

      const allItems = [
        { id: 'prod-h5-001', sku: 'SKU-H5-001', nombre: 'Producto A', precioEfectivo: 45 },
        { id: 'prod-h5-002', sku: 'SKU-H5-002', nombre: 'Producto B', precioEfectivo: 85 },
      ];
      const filtered = allItems.filter((it) => {
        if (min !== null && it.precioEfectivo < Number(min)) return false;
        if (max !== null && it.precioEfectivo > Number(max)) return false;
        return true;
      });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ items: filtered, pagina: 1, tamanio: 20, total: filtered.length }));
      return;
    }

    if (u.pathname === '/api/v1/productos/prod-h5-001') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ id: 'prod-h5-001', sku: 'SKU-H5-001', nombre: 'Producto A' }));
      return;
    }

    if (u.pathname.startsWith('/api/v1/productos/00000000-0000-4000-8000-000000000404')) {
      res.writeHead(404, { 'Content-Type': 'application/problem+json' });
      res.end(JSON.stringify({ status: 404, code: 'PRODUCTO_NO_ENCONTRADO' }));
      return;
    }

    if (u.pathname === '/api/v1/precios') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ items: [{ sku: 'SKU-H5-001', precioEfectivo: 45 }] }));
      return;
    }

    res.writeHead(404, { 'Content-Type': 'application/problem+json' });
    res.end(JSON.stringify({ status: 404, code: 'NO_ENCONTRADO' }));
  });

  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => {
      const addr = server.address();
      resolve({ server, baseUrl: `http://127.0.0.1:${addr.port}` });
    });
  });
}

test('Runner ejecuta perfil smoke contra harness local, genera evidencias saneadas y hashes SHA-256 validos', async () => {
  const { server, baseUrl } = await startLocalHarnessServer();
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-runner-pass-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      profile: 'smoke',
      runId: 'harness-smoke-pass',
      outDir,
      accessToken: 'synth-user-token-harness',
      restrictedAccessToken: 'restricted-synth-token',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });

    assert.equal(res.ok, true, `Fallo inesperado: ${JSON.stringify(res)}`);
    assert.equal(res.exitCode, 0);
    assert.equal(res.totals.fail, 0);
    assert.ok(res.totals.pass >= 12);

    const runDir = join(outDir, 'harness-smoke-pass');
    for (const f of [
      'manifest.json',
      'newman-summary.json',
      'newman.junit.xml',
      'integration-results.json',
      'report.md',
      'evidence-index.json',
    ]) {
      assert.equal(existsSync(join(runDir, f)), true, `Falta artefacto ${f}`);
    }

    // Verify SHA-256 integrity of every artifact in evidence-index.json
    const index = JSON.parse(readFileSync(join(runDir, 'evidence-index.json'), 'utf8'));
    assert.equal(index.artifacts.some((a) => a.file === 'evidence-index.json'), false);
    for (const art of index.artifacts) {
      const bytes = readFileSync(join(runDir, art.file));
      assert.equal(sha256Buffer(bytes), art.sha256, `Hash SHA-256 invalido para ${art.file}`);
    }

    // Ensure synthetic token did not leak into any artifact
    const allReportText = readFileSync(join(runDir, 'integration-results.json'), 'utf8');
    assert.equal(allReportText.includes('synth-user-token-harness'), false);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('Runner preserva codigo de salida 1 ante asercion fallida y genera igualmente evidencia saneada', async () => {
  const { server, baseUrl } = await startLocalHarnessServer({ failPriceFilter: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-runner-fail-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      profile: 'smoke',
      runId: 'harness-smoke-fail',
      outDir,
      accessToken: 'synth-user-token-harness',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });

    assert.equal(res.ok, false);
    assert.equal(res.exitCode, 1);
    assert.ok(res.totals.fail >= 1);
    assert.equal(existsSync(join(outDir, 'harness-smoke-fail', 'report.md')), true);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('Runner detecta timeout de solicitud y preserva fallo controlado', async () => {
  const { server, baseUrl } = await startLocalHarnessServer({ delayMs: 600 });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-runner-timeout-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '00 - Preflight y autenticacion',
      runId: 'harness-timeout',
      outDir,
      timeoutRequestMs: 120,
      allowNoAuth: true,
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });

    assert.equal(res.ok, false);
    assert.equal(res.exitCode, 1);
    assert.ok(res.totals.fail >= 1);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});
