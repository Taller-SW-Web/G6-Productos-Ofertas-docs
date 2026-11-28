import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { executeSuite } from '../scripts/run-newman.mjs';
import { sha256Buffer } from '../scripts/lib/sanitizer-core.mjs';

function startOpenApiHarnessServer({
  multiVariantFirst = false,
  paginatedOver20 = false,
  unsafeRedirectOnHealth = false,
  legacyCamelCaseDto = false,
  emptyCatalog = false,
  wrongPricingSku = false,
  readyReturns503 = false,
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

  // Punto 2: Producto con multiples variantes (variants[0] fuera de rango 150, variants[1] dentro de rango 50)
  const multiVariantProduct = {
    product_id: 'prod-h5-002',
    slug: 'producto-multivariante-h5',
    name: 'Producto Multi-Variante H5',
    description: 'Fixture multivariante OpenAPI',
    categoria_id: 'cat-h5-001',
    tipo_producto_id: 'tp-h5-001',
    marca_id: 'marca-h5-001',
    tiene_variantes: true,
    sku_base: null,
    images: [],
    attributes: [],
  };

  // Punto 2: Dataset > 20 productos (25 productos en 2 paginas; el #23 tiene precio 40 en rango acotado)
  const paginatedCatalog = Array.from({ length: 25 }, (_, i) => ({
    product_id: `prod-pag-${String(i + 1).padStart(2, '0')}`,
    slug: `producto-pag-${i + 1}`,
    name: `Producto Paginado ${i + 1}`,
    description: null,
    categoria_id: 'cat-h5-001',
    tipo_producto_id: 'tp-h5-001',
    marca_id: 'marca-h5-001',
    tiene_variantes: false,
    sku_base: `SKU-PAG-${String(i + 1).padStart(2, '0')}`,
    images: [],
    attributes: [],
  }));

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
    'SKU-H5-VAR-EXPENSIVE': {
      sku: 'SKU-H5-VAR-EXPENSIVE',
      precio_regular: 150,
      precio_oferta: null,
      currency: 'PEN',
      channel_id: 'MARKETPLACE',
      valid_from: '2026-11-01T00:00:00.000Z',
      valid_until: null,
      price_version: 2,
      vigencia_id: 'vig-h5-002',
      origen: 'SKU_OVERRIDE',
    },
    'SKU-H5-VAR-ELIGIBLE': {
      sku: 'SKU-H5-VAR-ELIGIBLE',
      precio_regular: 70,
      precio_oferta: 50,
      currency: 'PEN',
      channel_id: 'MARKETPLACE',
      valid_from: '2026-11-01T00:00:00.000Z',
      valid_until: null,
      price_version: 3,
      vigencia_id: 'vig-h5-003',
      origen: 'SKU_OVERRIDE',
    },
  };

  for (let i = 1; i <= 25; i += 1) {
    const sku = `SKU-PAG-${String(i).padStart(2, '0')}`;
    pricesBySku[sku] = {
      sku,
      precio_regular: i === 23 ? 40 : 80,
      precio_oferta: null,
      currency: 'PEN',
      channel_id: 'MARKETPLACE',
      valid_from: '2026-11-01T00:00:00.000Z',
      valid_until: null,
      price_version: 1,
      vigencia_id: `vig-pag-${i}`,
      origen: 'PRODUCTO',
    };
  }

  const server = http.createServer(async (req, res) => {
    if (delayMs > 0) await new Promise((r) => setTimeout(r, delayMs));
    const u = new URL(req.url, 'http://127.0.0.1');
    const corrId = req.headers['x-correlation-id'] || 'harness-corr';
    res.setHeader('X-Correlation-Id', corrId);

    if (u.pathname === '/health') {
      if (unsafeRedirectOnHealth) {
        res.writeHead(302, { Location: 'https://evil.example.com/steal' });
        res.end();
        return;
      }
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

      if (paginatedOver20) {
        const filtered = paginatedCatalog.filter((p, idx) => {
          const price = idx + 1 === 23 ? 40 : 80;
          if (min !== null && price < Number(min)) return false;
          if (max !== null && price > Number(max)) return false;
          return true;
        });
        const start = (pagina - 1) * tamanio;
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          items: filtered.slice(start, start + tamanio),
          pagina,
          tamanio,
          total: filtered.length,
        }));
        return;
      }

      const ordered = multiVariantFirst ? [multiVariantProduct, simpleProduct] : [simpleProduct, multiVariantProduct];
      const effMinPrice = { 'prod-h5-001': 45, 'prod-h5-002': 50 };
      const filtered = ordered.filter((p) => {
        const eff = effMinPrice[p.product_id];
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
        ...multiVariantProduct,
        marca: { marca_id: 'marca-h5-001', name: 'Marca H5' },
        variants: [
          { variant_id: 'var-h5-01', sku: 'SKU-H5-VAR-EXPENSIVE', identifying_attributes: [], non_identifying_attributes: [], images: [] },
          { variant_id: 'var-h5-02', sku: 'SKU-H5-VAR-ELIGIBLE', identifying_attributes: [], non_identifying_attributes: [], images: [] },
        ],
      }));
      return;
    }

    if (u.pathname.startsWith('/api/v1/productos/prod-pag-')) {
      const pid = u.pathname.split('/').pop();
      const found = paginatedCatalog.find((p) => p.product_id === pid);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ...found, marca: { marca_id: 'marca-h5-001', name: 'Marca H5' }, variants: [] }));
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
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        items: skus.map((s) => ({
          sku: s,
          location_id: 'LOC-LIMA-01',
          on_hand: 20,
          reserved: 3,
          blocked: 2,
          available: 15,
          status: 'DISPONIBLE',
          threshold: 5,
        })),
      }));
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

test('Punto 1 + H01 + H03: Smoke completo devuelve exitCode=0 EXCLUSIVAMENTE en PASS con hashes SHA-256 validos', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer();
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-pass-'));
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
    assert.equal(res.overallVerdict, 'PASS');
    assert.equal(res.exitCode, 0);
    const runDir = join(outDir, 'harness-smoke-pass');
    const index = JSON.parse(readFileSync(join(runDir, 'evidence-index.json'), 'utf8'));
    for (const art of index.artifacts) {
      assert.equal(sha256Buffer(readFileSync(join(runDir, art.file))), art.sha256);
    }
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('Punto 1 Regresion: PARTIAL_NOT_COMPLETE devuelve exitCode distinto de 0 (exitCode=5)', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer();
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-partial-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      profile: 'smoke',
      runId: 'reg-partial-exit',
      outDir,
      accessToken: 'synth-user-token-harness',
      restrictedAccessToken: '',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.overallVerdict, 'PARTIAL_NOT_COMPLETE');
    assert.equal(res.ok, false);
    assert.equal(res.exitCode, 5, 'PARTIAL_NOT_COMPLETE nunca puede devolver exitCode=0');
    assert.equal(res.totals.notRun, 1);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('Punto 2 Regresion (multiples variantes): variants[0] fuera de rango (150) y variants[1] elegible (50) pasa correctamente', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ multiVariantFirst: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-multivar-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '01 - Catalog y Pricing',
      runId: 'reg-multivariant',
      outDir,
      accessToken: 'synth-user-token-harness',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.ok, true, `Fallo en multivariante: ${JSON.stringify(res)}`);
    assert.equal(res.overallVerdict, 'PASS');
    assert.equal(res.exitCode, 0);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('Punto 2 Regresion (paginacion > 20): 25 productos en 2 paginas validan subconjunto exacto sin omitirlo', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ paginatedOver20: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-paginated-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '01 - Catalog y Pricing',
      runId: 'reg-paginated-25',
      outDir,
      accessToken: 'synth-user-token-harness',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.ok, true, `Fallo en paginacion > 20: ${JSON.stringify(res)}`);
    assert.equal(res.overallVerdict, 'PASS');
    assert.equal(res.exitCode, 0);
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('Punto 3 Regresion: Redireccion 302 hacia host externo no se sigue y falla asercion de seguridad', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ unsafeRedirectOnHealth: true });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-redir-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '00 - Preflight y autenticacion',
      runId: 'reg-unsafe-redirect',
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

test('Punto 4 Regresion: Carpeta 10 sin fixture sku registra PM-082 como NOT_RUN (BLOCKED_FIXTURE) y exitCode=5', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer();
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-fixture-'));
  try {
    const res = await executeSuite({
      env: 'local',
      baseUrl,
      folder: '10 - Integraciones externas',
      runId: 'reg-blocked-fixture',
      outDir,
      ventasAccessToken: 'synth-ventas-token',
      sku: '',
      evidenceLevel: 'ISOLATED',
      skipSecretScan: true,
    });
    assert.equal(res.overallVerdict, 'PARTIAL_NOT_COMPLETE');
    assert.equal(res.exitCode, 5);
    const results = JSON.parse(readFileSync(join(outDir, 'reg-blocked-fixture', 'integration-results.json'), 'utf8'));
    const pm082 = results.cases.find((c) => c.pmId === 'PM-082');
    assert.equal(pm082.status, 'NOT_RUN');
    assert.ok(pm082.blockerReason.includes('BLOCKED_FIXTURE'));
  } finally {
    server.close();
    rmSync(outDir, { recursive: true, force: true });
  }
});

test('H06 Regresiones: DTO legacy camelCase, catalogo vacio, SKU erroneo en Pricing y readiness 503 producen FAIL', async () => {
  for (const cfg of [
    { name: 'legacy-dto', opts: { legacyCamelCaseDto: true }, folder: '01 - Catalog y Pricing' },
    { name: 'empty-cat', opts: { emptyCatalog: true }, folder: '01 - Catalog y Pricing' },
    { name: 'wrong-sku', opts: { wrongPricingSku: true }, folder: '01 - Catalog y Pricing' },
    { name: 'ready-503', opts: { readyReturns503: true }, folder: '00 - Preflight y autenticacion', allowNoAuth: true },
  ]) {
    const { server, baseUrl } = await startOpenApiHarnessServer(cfg.opts);
    const outDir = mkdtempSync(join(tmpdir(), `g6-h5-${cfg.name}-`));
    try {
      const res = await executeSuite({
        env: 'local',
        baseUrl,
        folder: cfg.folder,
        runId: `reg-${cfg.name}`,
        outDir,
        accessToken: 'synth-user-token-harness',
        allowNoAuth: Boolean(cfg.allowNoAuth),
        evidenceLevel: 'ISOLATED',
        skipSecretScan: true,
      });
      assert.equal(res.exitCode, 1, `Esperado FAIL en ${cfg.name}`);
      assert.equal(res.overallVerdict, 'FAIL', `Esperado verdict FAIL en ${cfg.name}`);
    } finally {
      server.close();
      rmSync(outDir, { recursive: true, force: true });
    }
  }
});

test('Runner detecta timeout y preserva fallo controlado con evidencia saneada', async () => {
  const { server, baseUrl } = await startOpenApiHarnessServer({ delayMs: 500 });
  const outDir = mkdtempSync(join(tmpdir(), 'g6-h5-timeout-'));
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
