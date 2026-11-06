import { test, expect } from '@playwright/test';

test('Contrato completo, navegación, seguridad y bloqueo de ejecución', async ({ page }) => {
  const errors = [];
  const external = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('request', request => { if (!request.url().startsWith('http://127.0.0.1:8080/')) external.push(request.url()); });
  const manifest = await (await page.request.get('/manifest.json')).json();
  await page.goto('/?url=https://example.invalid/hostile.yaml&configUrl=https://example.invalid/config');
  await expect(page.locator('.opblock-tag')).toHaveCount(manifest.tags);
  for (const tag of await page.locator('.opblock-tag').all()) await tag.click();
  await expect(page.locator('.opblock')).toHaveCount(manifest.operations);
  await expect(page.locator('.models')).toBeVisible();
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
  expect(await page.evaluate(() => { try { window.ui.getConfigs().requestInterceptor({ url: '/api/v1/productos' }); return false; } catch { return true; } })).toBe(true);
  await page.screenshot({ path: 'test-results/portal.png', fullPage: false });
  expect(errors).toEqual([]);
  expect(external).toEqual([]);
});
