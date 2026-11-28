import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { executeSuite } from '../scripts/run-newman.mjs';
import { sha256Buffer } from '../scripts/lib/sanitizer-core.mjs';

/**
 * H06: Servidor HTTP local con respuestas 100% conformes a OpenAPI 0.7.0-rc.3
 * y modos de inyeccion de defectos para pruebas de regresion.
 */
function startOpenApiHarnessServer({
  variantFirst = false,
  legacyCamelCaseDto = false,
  emptyCatalog = false,
  wrongPricingSku = false,
  readyReturns503 = false,
  failPriceFilter = false,
  delayMs = 0,
} = {}) {
  const simpleProduct = {
    product_id: 'prod-h5-001',
    slug: 'producto-simple-h5',
    name: 'Producto Simple H5',
    description: 'Fixture simple OpenAPI',
    categoria_id: 'cat-h5-001',
    tipo_producto_id: 'tp-h5-001',
    marca_id: 'marca-h5-001',
    tiene_variantes: false,
    sku_base: 'SKU-H5-001',
    images: [],
    attributes: [],
  };

  const variantProduct = {
    product_id: 'prod-h5-002',
    slug: 'producto-variantes-h5',
    name: 'Producto Variantes H5',
    description: 'Fixture variantes OpenAPI',
    categoria_id: 'cat-h5-001',
    tipo_producto_id: 'tp-h5-001',
    marca_id: 'marca-h5-001',
    tiene_variantes: true,
    sku_base: null,
    images: [],
    attributes: [],
  };

  const pricesBySku = {
    'SKU-H5-001': {
      sku: 'SKU-H5-001',
      precio_regular: 55,
      precio_oferta: 45,
      currency: 'PEN',
      channel_id: 'MARKETPLACE',
      valid_from: '2026-11-01T00:00:00.000Z',
      valid_until: null,
      price_version: 1,
      vigencia_id: 'vig-h5-001',
      origen: 'PRODUCTO',
    },
    'SKU-H5-VAR-01': {
      sku: 'SKU-H5-VAR-01',
      precio_regular: 85,
      precio_oferta: null,
      currency: 'PEN',
      channel_id: 'MARKETPLACE',
      valid_from: '2026-11-01T00:00:00.000Z',
      valid_until: null,
      price_version: 2,
      vigencia_id: 'vig-h5-002',
      origen: 'SKU_OVERRIDE',
    },
  };

  const server = http.createServer(async (req, res) => {
    if (delayMs > 0) await new Promise((r) => setTimeout(r, delayMs));
    const u = new URL(req.url, 'http://127.0.0.1');
    const corrId = req.headers['x-correlation-id'] || 'harness-corr';
    res.setHeader('X-Correlation-Id', corrId);

    if (u.pathname === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', service: 'api-gateway' }));
      return;
    }

    if (u.pathname === '/health/ready') {
      if (readyReturns503) {
        res.writeHead(503, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'not_ready', service: 'api-gateway' }));
        return;
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ready', service: 'api-gateway' }));
      return;
    }

    if (u.pathname === '/api/v1/ruta-inexistente-h5-probe') {
      res.writeHead(404, { 'Content-Type': 'application/problem+json' });
      res.end(JSON.stringify({ title: 'No encontrado', status: 404, code: 'NO_ENCONTRADO' }));
      return;
    }

    const auth = req.headers.authorization || '';
    if (!auth.startsWith('Bearer ') || auth === 'Bearer invalid.jwt.fixture' || auth === 'Bearer ') {
      res.writeHead(401, { 'Content-Type': 'application/problem+json' });
      res.end(JSON.stringify({ title: 'No autenticado', status: 401, code: 'TOKEN_INVALIDO' }));
      return;
    }

    if (u.pathname === '/api/v1/auditoria-precios' && auth === 'Bearer restricted-synth-token') {
      res.writeHead(403, { 'Content-Type': 'application/problem+json' });
      res.end(JSON.stringify({ title: 'Prohibido', status: 403, code: 'SCOPE_INSUFICIENTE' }));
      return;
    }

    if (u.pathname === '/api/v1/productos') {
      const canal = u.searchParams.get('canal');
      const pagina = Number(u.searchParams.get('pagina') || '1');
      const tamanio = Number(u.searchParams.get('tamanio') || '20');
      const min = u.searchParams.get('precioMin');
      const max = u.searchParams.get('precioMax');

      if (canal === 'CANAL_INVALIDO' || pagina < 1) {
        res.writeHead(400, { 'Content-Type': 'application/problem+json' });
        res.end(JSON.stringify({ title: 'Validacion', status: 400, code: 'VALIDACION' }));
        return;
      }
      if (min !== null && max !== null && Number(min) > Number(max)) {
        res.writeHead(400, { 'Content-Type': 'application/problem+json' });
        res.end(JSON.stringify({ title: 'Rango invalido', status: 400, code: 'VALIDACION' }));
        return;
      }
      if (failPriceFilter && max === '100') {
        res.writeHead(500, { 'Content-Type': 'application/problem+json' });
        res.end(JSON.stringify({ title: 'Error interno', status: 500, code: 'ERROR_INTERNO' }));
        return;
      }

      if (emptyCatalog) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ items: [], pagina, tamanio, total: 0 }));
        return;
      }

      if (legacyCamelCaseDto) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ items: [{ id: 'prod-h5-001', sku: 'SKU-H5-001', nombre: 'Legacy' }], pagina, tamanio, total: 1 }));
        return;
      }

      const ordered = variantFirst ? [variantProduct, simpleProduct] : [simpleProduct, variantProduct];
      const priceMap = { 'prod-h5-001': 45, 'prod-h5-002': 85 };
      const filtered = ordered.filter((p) => {
        const eff = priceMap[p.product_id];
        if (min !== null && eff < Number(min)) return false;
        if (max !== null && eff > Number(max)) return false;
        return true;
      });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ items: filtered, pagina, tamanio, total: filtered.length }));
      return;
    }

    if (u.pathname === '/api/v1/productos/prod-h5-001') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ...simpleProduct, marca: { marca_id: 'marca-h5-001', name: 'Marca H5' }, variants: [] }));
      return;
    }

    if (u.pathname === '/api/v1/productos/prod-h5-002') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        ...variantProduct,
        marca: { marca_id: 'marca-h5-001', name: 'Marca H5' },
        variants: [{ variant_id: 'var-h5-001', sku: 'SKU-H5-VAR-01', identifying_attributes: [], non_identifying_attributes: [], images: [] }],
      }));
      return;
    }

    if (u.pathname.startsWith('/api/v1/productos/00000000-0000-4000-8000-000000000404')) {
      res.writeHead(404, { 'Content-Type': 'application/problem+json' });
      res.end(JSON.stringify({ title: 'No encontrado', status: 404, code: 'PRODUCTO_NO_ENCONTRADO' }));
      return;
    }

    if (u.pathname === '/api/v1/precios') {
      const skus = (u.searchParams.get('skus') || '').split(',').filter(Boolean);
      const items = wrongPricingSku
        ? [{ ...pricesBySku['SKU-H5-001'], sku: 'SKU-INCORRECTO-999' }]
        : skus.map((s) => pricesBySku[s]).filter(Boolean);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ items }));
      return;
    }

    if (u.pathname === '/api/v1/inventario/disponibilidad') {
      const skus = (u.searchParams.get('skus') || '').split(',').filter(Boolean);
      const items = skus.map((s) => ({
        sku: s,
        location_id: 'LOC-LIMA-01',
        on_hand: 20,
        reserved: 3,
        blocked: 2,
        available: 15,
        status: 'DISPONIBLE',
        threshold: 5,
      }));
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ items }));
      return;
    }

    if (u.pathname === '/api/v1/inventario/disponibilidad/comercial') {
      const skus = (u.searchParams.get('skus') || '').split(',').filter(Boolean);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ items: skus.map((s) => ({ sku: s, status: 'DISPONIBLE' })) }));
      return;
    }

    res.writeHead(404, { 'Content-Type': 'application/problem+json' });
    res.end(JSON.stringify({ title: 'No encontrado', status: 404, code: 'NO_ENCONTRADO' }));
  });

  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => {
      resolve({ server, baseUrl: `http://127.0.0.1:${server.address().port}` });
    });
  });
}

test('H01+H03+H04: Smoke completo PASS con producto simple, DTO OpenAPI real y hashes SHA-256 validos', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ variantFirst: false });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-runner-pass-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      profile: 'smoke',
      runId: 'harness-smoke-simple',
      outDir,
      accessToken: 'synth-user-token-harness',
      restrictedAccessToken: 'restricted-synth-token',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });

    assert.equal(res.ok, true, `Fallo inesperado: ${JSON.stringify(res)}`);
    assert.equal(res.overallVerdict, 'PASS');
    assert.equal(res.exitCode, 0);
    assert.equal(res.totals.planned, 14);
    assert.equal(res.totals.executed, 14);
    assert.equal(res.totals.notRun, 0);

    const runDir = join(outDir, 'harness-smoke-simple');
    const index = JSON.parse(readFileSync(join(runDir, 'evidence-index.json'), 'utf8'));
    for (const art of index.artifacts) {
      assert.equal(sha256Buffer(readFileSync(join(runDir, art.file))), art.sha256);
    }
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('H01: Encadenamiento Catalog->Pricing funciona tambien cuando el primer producto tiene variantes (sku_base=null)', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ variantFirst: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-runner-var-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '01 - Catalog y Pricing',
      runId: 'harness-variants',
      outDir,
      accessToken: 'synth-user-token-harness',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.ok, true, `Fallo con producto con variantes: ${JSON.stringify(res)}`);
    assert.equal(res.overallVerdict, 'PASS');
    assert.equal(res.totals.pass, 5);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('H02+H04 Regresion: Sin restrictedAccessToken, PM-005 queda NOT_RUN y veredicto es PARTIAL_NOT_COMPLETE (no PASS)', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer();
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-runner-partial-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      profile: 'smoke',
      runId: 'harness-partial-auth',
      outDir,
      accessToken: 'synth-user-token-harness',
      restrictedAccessToken: '',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.ok, false);
    assert.equal(res.overallVerdict, 'PARTIAL_NOT_COMPLETE');
    assert.equal(res.totals.planned, 14);
    assert.equal(res.totals.executed, 13);
    assert.equal(res.totals.notRun, 1);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('H06 Regresion: DTO camelCase no contractual (id en vez de product_id) produce FAIL', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ legacyCamelCaseDto: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-reg-dto-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '01 - Catalog y Pricing',
      runId: 'reg-legacy-dto',
      outDir,
      accessToken: 'synth-user-token-harness',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.exitCode, 1);
    assert.equal(res.overallVerdict, 'FAIL');
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('H06+H03 Regresion: Respuesta vacia items=[] en Catalog produce FAIL (sin aprobacion vacia)', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ emptyCatalog: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-reg-empty-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '01 - Catalog y Pricing',
      runId: 'reg-empty-catalog',
      outDir,
      accessToken: 'synth-user-token-harness',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.exitCode, 1);
    assert.equal(res.overallVerdict, 'FAIL');
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('H06+H07 Regresion: SKU incorrecto en respuesta de Pricing produce FAIL', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ wrongPricingSku: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-reg-sku-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '01 - Catalog y Pricing',
      runId: 'reg-wrong-sku',
      outDir,
      accessToken: 'synth-user-token-harness',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.exitCode, 1);
    assert.equal(res.overallVerdict, 'FAIL');
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('H08 Regresion: /health/ready con 503 contractual NO acredita disponibilidad operativa (FAIL)', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ readyReturns503: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-reg-503-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '00 - Preflight y autenticacion',
      runId: 'reg-ready-503',
      outDir,
      allowNoAuth: true,
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.exitCode, 1);
    assert.equal(res.overallVerdict, 'FAIL');
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('Runner detecta timeout de solicitud y preserva fallo controlado', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ delayMs: 500 });
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
    assert.equal(res.exitCode, 1);
    assert.equal(res.overallVerdict, 'FAIL');
    assert.equal(existsSync(join(outDir, 'harness-timeout', 'report.md')), true);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});
