import { test, expect } from '@playwright/test';

test('Contrato completo sin acceso externo ni ejecución de APIs', async ({ page, context }) => {
  const errors = [];
  const external = [];
  page.on('pageerror', error => errors.push(error.message));
  await context.route('**/*', route => {
    const url = new URL(route.request().url());
    if (url.origin !== 'http://localhost:8080') { external.push(url.origin); return route.abort(); }
    return route.continue();
  });
  const manifest = await (await page.request.get('/manifest.json')).json();
  const expected = await (await page.request.get('/openapi.json')).json();
  await page.goto('/?url=https://example.invalid/hostile.yaml&configUrl=https://example.invalid/config');
  await expect(page.locator('.opblock-tag')).toHaveCount(manifest.tags);
  await expect(page.locator('#status')).toContainText(`${manifest.operations} operaciones`);
  await page.locator('#security-reference summary').click();
  await expect(page.locator('#security-schemes dt')).toHaveCount(2);
  await expect(page.locator('#security-schemes')).toContainText('serviceBearer');
  await expect(page.locator('#security-schemes')).toContainText('userBearer');
  await expect(page.locator('#security-schemes dd').first()).toBeVisible();
  await page.screenshot({ path: 'test-results/local-security.png' });
  await page.locator('#security-reference summary').click();
  await page.screenshot({ path: 'test-results/local-overview.png' });
  for (const tag of await page.locator('.opblock-tag').all()) await tag.click();
  await expect(page.locator('.opblock')).toHaveCount(manifest.operations);
  await expect(page.locator('.models')).toBeVisible();
  expect(await page.evaluate(() => window.ui.specSelectors.specJson().toJS())).toEqual(expected);
  expect(await page.evaluate(() => Object.keys(window.ui.specSelectors.specJson().toJS().components.schemas).length)).toBe(manifest.schemas);
  expect(await page.evaluate(() => Object.keys(window.ui.specSelectors.specJson().toJS().components.securitySchemes))).toEqual(['serviceBearer', 'userBearer']);
  expect(await page.evaluate(() => window.ui.getConfigs().supportedSubmitMethods)).toEqual([]);
  expect(await page.evaluate(() => window.ui.getConfigs().queryConfigEnabled)).toBe(false);
  expect(await page.evaluate(() => window.ui.getConfigs().validatorUrl)).toBe(null);
  expect(await page.evaluate(() => window.ui.specSelectors.specJson().toJS().servers[0].url)).toBe('/api/v1');
  await page.locator('#operations-Productos-obtenerContextoSku .opblock-summary').click();
  await expect(page.locator('.try-out__btn')).toHaveCount(0);
  await expect(page.locator('.execute')).toHaveCount(0);
  await expect(page.locator('.auth-wrapper .authorize')).toHaveCount(0);
  await expect(page.locator('input[type="password"]')).toHaveCount(0);
  expect(await page.evaluate(() => { try { window.ui.getConfigs().requestInterceptor({ url: '/api/v1/productos' }); return false; } catch { return true; } })).toBe(true);
  await page.locator('#operations-Productos-crearProducto .opblock-summary').click();
  const create = page.locator('#operations-Productos-crearProducto');
  await expect(create).toContainText('Request body');
  await expect(create.locator('.responses-wrapper')).toBeVisible();
  await page.locator('#operations-Productos-obtenerContextoSku .opblock-summary').scrollIntoViewIfNeeded();
  await page.screenshot({ path: 'test-results/local-endpoint.png' });
  expect(errors).toEqual([]);
  expect(external).toEqual([]);
});

test('Servidor local solo sirve documentación por GET/HEAD', async ({ request }) => {
  expect((await request.get('/manifest.json')).status()).toBe(200);
  expect((await request.head('/openapi.yaml')).status()).toBe(200);
  expect((await request.get('/api/v1/productos')).status()).toBe(404);
  expect((await request.get('/..%2Fpackage.json')).status()).toBe(404);
  expect((await request.post('/openapi.json', { data: {} })).status()).toBe(405);
});
