const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(__dirname, '../../..');
const checks = [];
async function check(name, run) { await run(); checks.push(name); }

(async () => {
  const browser = await chromium.launch({headless: true, ...(process.env.CHROME_PATH ? {executablePath: process.env.CHROME_PATH} : {})});
  try {
    const page = await browser.newPage({viewport: {width: 1440, height: 900}});
    const errors = [], requests = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => { if (request.url().startsWith('http')) requests.push(request.url()); });
    async function load(id, slug, hash = '') { await page.goto(pathToFileURL(path.join(root, 'wireframes/prototipos', `${id}-${slug}`, 'index.html')).href + hash); }
    const coupons = hash => load('WF-005', 'gestion-cupones-descuento', hash);
    const promotions = hash => load('WF-006', 'gestion-ofertas-promociones', hash);
    const recommendations = hash => load('WF-007', 'reglas-venta-cruzada-upselling', hash);
    async function fields(values) { for (const [id, value] of Object.entries(values)) await page.locator('#' + id).fill(value); }
    const couponSave = () => page.getByRole('button', {name: 'Guardar', exact: true}).click();
    const promotionSave = () => page.getByRole('button', {name: 'Guardar promoción', exact: true}).click();

    await coupons();
    await check('005: detalle del cupón seleccionado', async () => {
      await page.locator('tbody tr').nth(1).getByRole('button', {name: 'Ver', exact: true}).click();
      const text = await page.locator('#modalBody').innerText();
      assert(text.includes('SETIEMBRE10')); assert(!text.includes('BIENVENIDA20')); assert(text.includes('No restaurar')); assert(text.includes('Sin límite'));
      await page.keyboard.press('Escape');
    });
    await page.locator('[data-action=create]').click();
    await check('005: código vacío y monto negativo no se guardan', async () => {
      await page.locator('#minimum').fill('-1'); await couponSave();
      assert.equal(await page.evaluate(() => coupons.length), 2);
      assert.equal(await page.locator('#code').getAttribute('aria-invalid'), 'true');
      assert.equal(await page.locator('#minimum').inputValue(), '-1');
    });
    await check('005: unicidad tras normalizar', async () => {
      await fields({code: ' bienvenida20 ', minimum: ''}); await page.locator('#promotion').selectOption('pm3'); await couponSave();
      assert.match(await page.locator('#code-error').innerText(), /Ya existe/);
    });
    await check('005: límites cero/fraccionario rechazados', async () => {
      await fields({code: ' prueba_15 ', globalLimit: '0', customerLimit: '1.5'}); await couponSave();
      assert.equal(await page.evaluate(() => coupons.length), 2);
      assert.match(await page.locator('#globalLimit-error').innerText(), /entero positivo/);
      assert.match(await page.locator('#customerLimit-error').innerText(), /entero positivo/);
    });
    await check('005: crear, normalizar y límites vacíos como null', async () => {
      await fields({globalLimit: '', customerLimit: ''}); await couponSave();
      assert.deepEqual(await page.evaluate(() => ({code: coupons[0].code, global: coupons[0].globalLimit, client: coupons[0].customerLimit})), {code: 'PRUEBA_15', global: null, client: null});
      assert.equal(await page.locator('tbody tr').count(), 3);
    });
    await check('005: edición propia no dispara duplicado', async () => {
      await page.locator('tbody tr').first().getByRole('button', {name: 'Ver', exact: true}).click(); await page.locator('[data-modal=edit]').click();
      await page.locator('#minimum').fill('80'); await couponSave(); assert.equal(await page.evaluate(() => coupons[0].minimum), 80);
    });
    await check('005: cambio de estado confirmado conserva usos', async () => {
      await page.locator('tbody tr').nth(1).getByRole('button', {name: 'Ver', exact: true}).click(); await page.locator('[data-modal=state]').click();
      await page.locator('[data-modal=confirmState]').click(); assert.deepEqual(await page.evaluate(() => ({state: coupons[1].state, used: coupons[1].used})), {state: 'INACTIVO', used: 83});
    });

    await promotions(); await page.locator('[data-a=new]').click();
    await check('006: cancelar sigue funcionando tras cambiar campos', async () => {
      await page.locator('#name').fill('Borrador'); await page.locator('#value').click(); await page.locator('[data-a=back]').click();
      assert.equal(await page.evaluate(() => state.view), 'list');
    });
    await page.locator('[data-a=new]').click();
    await fields({name: 'Campaña de prueba', value: '101', start: '2026-10-03T00:00', end: '2026-10-04T00:00'});
    await page.locator('[data-product=p1]').check();
    await check('006: errores de descuento/canales y valores conservados', async () => {
      await promotionSave(); assert.equal(await page.evaluate(() => state.view), 'form');
      assert.match(await page.locator('#value-error').innerText(), /hasta 100/); assert.match(await page.locator('#channels-error').innerText(), /al menos un canal/);
      assert.equal(await page.locator('#name').inputValue(), 'Campaña de prueba');
    });
    await check('006: corregir errores y guardar conserva producto completo', async () => {
      await page.locator('#value').fill('15'); await page.locator('[data-channel=Marketplace]').check(); await promotionSave();
      assert.equal(await page.evaluate(() => state.view), 'detail');
      assert.deepEqual(await page.evaluate(() => byId(state.current).scope), {productIds: ['p1'], skus: []});
      assert.equal(await page.evaluate(() => promos.length), 4);
    });
    await check('006: SKU nuevo sigue cubierto por producto completo', async () => {
      assert.equal(await page.evaluate(() => { catalog[0].skus.push(['RUN-42', 'Talla 42']); return matchesScope(byId(state.current), 'RUN-42'); }), true);
    });
    await check('006: editar conserva acciones y datos', async () => {
      await page.locator('[data-a=edit]').click(); await page.locator('#name').fill('Campaña editada'); await promotionSave();
      assert.equal(await page.evaluate(() => byId(state.current).name), 'Campaña editada');
    });
    await check('006: modalidad cambia en inactiva nunca activada', async () => {
      await page.locator('[data-a=back]').click(); await page.locator('[data-a=detail][data-id=pr2]').first().click(); await page.locator('[data-a=edit]').click();
      assert.equal(await page.locator('#mode').isDisabled(), false); await page.locator('#mode').selectOption('CUPON'); await promotionSave();
      assert.equal(await page.evaluate(() => byId('pr2').mode), 'CUPON');
    });
    await check('006: activar/desactivar conserva antecedente y bloquea modalidad', async () => {
      await page.locator('[data-a=state]').click(); await page.locator('#applyState').click();
      await page.locator('[data-a=state]').click(); await page.locator('#applyState').click();
      await page.locator('[data-a=edit]').click(); assert.equal(await page.locator('#mode').isDisabled(), true);
      assert.equal(await page.evaluate(() => byId('pr2').everActivated), true);
    });
    await check('006: cupones o usos históricos bloquean aun sin activación', async () => {
      for (const history of [{couponCount: 1, usesCount: 0}, {couponCount: 0, usesCount: 1}]) {
        const allowed = await page.evaluate(history => canChangeMode({...byId('pr2'), state: 'INACTIVA', everActivated: false, ...history}), history);
        assert.equal(allowed, false);
      }
    });
    await check('006: SKU específico no equivale a producto completo', async () => {
      await promotions(); await page.locator('[data-a=new]').click(); await page.locator('[data-sku="RUN-40"]').check();
      assert.deepEqual(await page.evaluate(() => state.edit.scope), {productIds: [], skus: ['RUN-40']});
      await page.locator('[data-product=p1]').check(); await page.locator('[data-product=p1]').uncheck();
      assert.deepEqual(await page.evaluate(() => state.edit.scope), {productIds: [], skus: []});
    });

    await recommendations(); await page.locator('[data-a=new]').click();
    await fields({name: 'Regla de prueba'}); await page.locator('#origin').selectOption('p1');
    await check('007: selector excluye origen e inactivos', async () => {
      await page.locator('[data-a=add]').click(); const ids = await page.locator('#pick option').evaluateAll(xs => xs.map(x => x.value));
      assert(!ids.includes('p1')); assert(!ids.includes('p6')); await page.locator('#addPick').click();
    });
    await check('007: no guarda sin vigencia ni con orden cero', async () => {
      await page.locator('.ord').fill('0'); await couponSave(); assert.equal(await page.evaluate(() => rules.length), 2);
      assert.match(await page.locator('#start-error').innerText(), /inicio/); assert.match(await page.locator('#order-0-error').innerText(), /entero positivo/);
    });
    await check('007: rechaza orden negativo/fraccionario y fechas invertidas', async () => {
      await fields({start: '2026-10-04T00:00', end: '2026-10-03T00:00'});
      for (const value of ['-1', '1.5']) { await page.locator('.ord').fill(value); await couponSave(); assert.match(await page.locator('#order-0-error').innerText(), /entero positivo/); }
      assert.match(await page.locator('#end-error').innerText(), /posterior/);
    });
    await check('007: guardar válido respeta estado inicial y origen tipado', async () => {
      await fields({start: '2026-10-03T00:00', end: '2026-10-04T00:00'}); await page.locator('.ord').fill('1'); await page.locator('#ruleState').selectOption('ACTIVO'); await couponSave();
      assert.deepEqual(await page.evaluate(() => ({view: s.view, origin: rules[0].origin, state: rules[0].state})), {view: 'list', origin: {type: 'PRODUCTO', id: 'p1'}, state: 'ACTIVO'});
    });
    await check('007: detalle no inventa precio ni saldo', async () => {
      await page.locator('[data-a=detail][data-i="0"]').first().click(); const text = await page.locator('#app').innerText();
      assert(text.includes('Precio: No disponible')); assert(text.includes('Disponibilidad: No disponible')); assert(!text.includes('S/ 99')); assert(!text.includes('10 disponibles'));
    });
    await check('007: edición, categoría y Upsell sin criterio', async () => {
      await page.locator('[data-a=edit]').click(); await page.locator('#originType').selectOption('CATEGORIA'); await page.locator('#origin').selectOption('running');
      await page.locator('input[value=UPSELL]').check(); await couponSave(); assert.match(await page.locator('#criterion-0-error').innerText(), /criterio/);
      assert.equal(await page.locator('#name').inputValue(), 'Regla de prueba');
    });
    await check('007: 501 caracteres rechazados incluso si se evita maxlength', async () => {
      await page.locator('.crit').selectOption('MAYOR_RENDIMIENTO'); await page.locator('.note').evaluate(x => { x.value = 'x'.repeat(501); }); await couponSave();
      assert.match(await page.locator('#note-0-error').innerText(), /500/); assert.equal(await page.evaluate(() => rules[0].type), 'CROSS_SELL');
      await page.locator('.note').fill('Mejor amortiguación'); await couponSave();
      assert.deepEqual(await page.evaluate(() => ({type: rules[0].type, origin: rules[0].origin})), {type: 'UPSELL', origin: {type: 'CATEGORIA', id: 'running'}});
    });
    await check('007: cambio de estado y eliminación de recomendado', async () => {
      await page.locator('[data-a=detail][data-i="0"]').first().click(); await page.locator('[data-a=toggle]').click(); await page.locator('#stateConfirm').click();
      assert.equal(await page.evaluate(() => rules[0].state), 'INACTIVO'); await page.locator('[data-a=edit]').click(); await page.locator('[data-a=remove]').click(); await couponSave();
      assert.match(await page.locator('#items-error').innerText(), /al menos un/);
    });
    await check('007: no permite duplicados ni recomendar el propio origen', async () => {
      const results = await page.evaluate(() => { const r = structuredClone(rules[1]); r.origin = {type: 'PRODUCTO', id: 'p1'}; r.items = [{productId: 'p1', order: 1, criterion: '', note: ''}]; const self = validateRule(r); r.items = [{productId: 'p2', order: 1, criterion: '', note: ''}, {productId: 'p2', order: 2, criterion: '', note: ''}]; return {self, duplicate: validateRule(r)}; });
      assert(results.self.items); assert(results.duplicate.items);
    });
    await check('Todos: guardado fallido conserva entradas', async () => {
      await coupons('#save-error'); await page.locator('[data-action=create]').click(); await fields({code: 'ERROR_TEST'}); await page.locator('#promotion').selectOption('pm3'); await couponSave(); assert.equal(await page.evaluate(() => coupons.length), 2); assert.match(await page.locator('#formError').innerText(), /datos se conservan/);
      await promotions('#save-error'); await page.locator('[data-a=detail][data-id=pr2]').first().click(); await page.locator('[data-a=edit]').click(); await page.locator('#name').fill('No perder'); await promotionSave(); assert.equal(await page.locator('#name').inputValue(), 'No perder'); assert.equal(await page.evaluate(() => byId('pr2').name), 'S/ 25 en Running 40');
      await recommendations('#save-error'); await page.locator('[data-a=detail][data-i="0"]').first().click(); await page.locator('[data-a=edit]').click(); await couponSave(); assert.equal(await page.evaluate(() => s.view), 'form'); assert.match(await page.locator('#err').innerText(), /datos se conservan/);
    });
    await check('Todos: estados de carga, vacío, permisos y sesión', async () => {
      for (const loadPage of [coupons, promotions, recommendations]) {
        await loadPage('#list-loading'); assert.match(await page.locator('main').innerText(), /Cargando/);
        await loadPage('#list-empty'); assert.match(await page.locator('main').innerText(), /No hay/);
        await loadPage('#no-permission'); assert.match(await page.locator('main').innerText(), /permiso/); assert.equal(await page.locator('main button').count(), 0);
        await loadPage('#session-expired'); assert.match(await page.locator('main').innerText(), /sesión finalizó/);
      }
    });
    await check('Todos: no errores de consola ni llamadas a servicios', async () => { assert.deepEqual(errors, []); assert.deepEqual(requests, []); });
    const report = {passed: checks.length, checks};
    if (process.env.VALIDATION_OUTPUT) fs.writeFileSync(process.env.VALIDATION_OUTPUT, JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report, null, 2));
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
