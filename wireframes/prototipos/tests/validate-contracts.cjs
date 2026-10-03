const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const YAML = require(process.env.YAML_MODULE || 'yaml');
const Ajv = require(process.env.AJV_MODULE || 'ajv/dist/2020');
const addFormats = require(process.env.AJV_FORMATS_MODULE || 'ajv-formats');
const root = path.resolve(__dirname, '../../..');
const checks = [];
function check(name, run) { run(); checks.push(name); }
function parse(file) {
  const doc = YAML.parseDocument(fs.readFileSync(path.join(root, file), 'utf8'), {uniqueKeys: true});
  assert.deepEqual(doc.errors.map(e => e.message), [], file);
  return doc.toJS();
}
const openapi = parse('api/openapi.yaml');
const asyncapi = parse('asyncapi/asyncapi.yaml');
function validateRefs(doc) {
  let count = 0;
  const seen = new WeakSet();
  function walk(value) {
    if (!value || typeof value !== 'object' || seen.has(value)) return;
    seen.add(value);
    if (typeof value.$ref === 'string' && value.$ref.startsWith('#/')) {
      const pointer = value.$ref.slice(2).split('/').map(p => p.replace(/~1/g, '/').replace(/~0/g, '~'));
      let target = doc;
      for (const key of pointer) { assert(target && Object.hasOwn(target, key), value.$ref); target = target[key]; }
      count++;
    }
    Object.values(value).forEach(walk);
  }
  walk(doc);
  return count;
}
const refs = {openapi: validateRefs(openapi), asyncapi: validateRefs(asyncapi)};
const ajv = new Ajv({strict: false, allErrors: true});
addFormats(ajv);
ajv.addSchema({$id: 'urn:productos:openapi', components: openapi.components});
const validate = name => ajv.compile({$ref: `urn:productos:openapi#/components/schemas/${name}`});
const create = validate('PromocionWriteRequest');
const update = validate('PromocionUpdateRequest');
const read = validate('PromocionAdmin');
const promotion = {nombre: 'Prueba', tipoDescuento: 'PORCENTAJE', valor: 15, modalidad: 'AUTOMATICA', estado: 'INACTIVO', validFrom: '2026-10-03T00:00:00-05:00', validUntil: '2026-10-04T00:00:00-05:00', alcance: {productIds: ['p1'], skus: []}, prioridad: 1, canalesHabilitados: ['MARKETPLACE'], politicaCombinacion: {ofertaPricing: false, promocionAutomatica: false, cupon: false}};
check('Contrato: creación con canales explícitos válida', () => assert(create(promotion), JSON.stringify(create.errors)));
check('Contrato: creación sin canales rechazada', () => { const p = {...promotion}; delete p.canalesHabilitados; assert.equal(create(p), false); });
check('Contrato: canales vacíos, duplicados o desconocidos rechazados', () => { for (const channels of [[], ['MARKETPLACE', 'MARKETPLACE'], ['DESCONOCIDO']]) assert.equal(create({...promotion, canalesHabilitados: channels}), false); });
check('Contrato: PATCH puede conservar canales, no vaciarlos', () => { assert(update({nombre: 'Renombrada'})); assert.equal(update({canalesHabilitados: []}), false); assert(update({canalesHabilitados: ['RETAIL']})); });
check('Contrato: capacidad de modalidad en respuesta administrativa', () => {
  const p = {...promotion, promotionId: 'pr1', puedeCambiarModalidad: true};
  assert(read(p), JSON.stringify(read.errors)); delete p.puedeCambiarModalidad; assert.equal(read(p), false);
  assert.equal(openapi.components.schemas.PromocionAdmin.properties.puedeCambiarModalidad.readOnly, true);
});
check('Contrato: límites de cupón positivos o null', () => {
  const coupon = validate('CuponCreateRequest');
  const p = {codigo: 'TEST15', promocionId: 'pr1', estado: 'ACTIVO', politicaCancelacion: 'RESTAURAR_EN_CANCELACION', maxUsosGlobal: null, maxUsosPorCliente: 1};
  assert(coupon(p), JSON.stringify(coupon.errors));
  for (const invalid of [0, -1, 1.5]) assert.equal(coupon({...p, maxUsosGlobal: invalid}), false);
  assert.equal(coupon({...p, montoMinimo: -1}), false);
});
check('Contrato: recomendación exige fechas, orden positivo y justificación hasta 500', () => {
  const rule = validate('ReglaRecomendacionWriteRequest');
  const p = {nombre: 'Prueba', tipo: 'UPSELL', origen: {tipo: 'PRODUCTO', id: 'p1'}, prioridad: 1, estado: 'ACTIVO', validFrom: promotion.validFrom, validUntil: promotion.validUntil, recomendados: [{productId: 'p2', orden: 1, criterioSuperioridad: 'MAYOR_RENDIMIENTO', justificacionComercial: 'Mejor material'}]};
  assert(rule(p), JSON.stringify(rule.errors));
  const noDates = {...p}; delete noDates.validFrom; assert.equal(rule(noDates), false);
  assert.equal(rule({...p, recomendados: [{...p.recomendados[0], orden: 0}]}), false);
  assert.equal(rule({...p, recomendados: [{...p.recomendados[0], justificacionComercial: 'x'.repeat(501)}]}), false);
});
const report = {passed: checks.length, refs, checks};
if (process.env.CONTRACT_VALIDATION_OUTPUT) fs.writeFileSync(process.env.CONTRACT_VALIDATION_OUTPUT, JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
