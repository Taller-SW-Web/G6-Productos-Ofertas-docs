import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import YAML from 'yaml';
import { loadContract, operations } from '../scripts/contract.mjs';

const readAsync = async () => YAML.parse(await readFile('../contratos/eventos/asyncapi.yaml', 'utf8'));

test('OpenAPI H5 completa lecturas Inventory y mantiene fronteras M2M privadas', async () => {
  const { spec } = await loadContract();
  const expected = [
    ['/inventario/administracion/saldos', 'get', 'listarSaldosFisicosAdministracion'],
    ['/inventario/alertas', 'get', 'listarAlertasOperativasInventario'],
    ['/inventario/ubicaciones', 'get', 'listarUbicacionesInventario'],
    ['/interno/productos/skus/filtrar', 'post', 'filtrarSkusVendiblesInterno'],
    ['/interno/inventario/reservas/{reservaId}/evidencia-cupon', 'get', 'obtenerEvidenciaReservaCuponInterno'],
  ];
  for (const [path, method, operationId] of expected) {
    assert.equal(spec.paths[path][method].operationId, operationId);
    assert.ok(spec.paths[path][method].responses['200']);
  }
  for (const path of ['/interno/productos/skus/filtrar', '/interno/inventario/reservas/{reservaId}/evidencia-cupon']) {
    assert.equal(spec.paths[path][path.endsWith('filtrar') ? 'post' : 'get']['x-internal'], true);
  }
  assert.equal(spec.paths['/interno/inventario/reservas/{reservaId}/evidencia-cupon'].get['x-allowed-client-ids'][0], 'promotions-svc');
  assert.equal(spec.paths['/inventario/alertas'].get.parameters.find(p => p.name === 'estado').schema.enum.includes('DISPONIBLE'), false);
  assert.equal(spec.paths['/inventario/ubicaciones'].get.parameters.find(p => p.name === 'soloActivas').schema.default, false);
  assert.ok(!spec.paths['/inventario/dashboard'].get.parameters.some(p => ['productoId', 'categoriaId', 'marcaId'].includes(p.name)));
  for (const path of ['/inventario/administracion/saldos', '/inventario/alertas', '/inventario/ubicaciones']) {
    const operation = spec.paths[path].get;
    assert.deepEqual(operation.security, [{ userBearer: [] }]);
    assert.equal(operation['x-required-role'], 'GESTOR_COMERCIAL');
    assert.match(operation.description, /Gateway\/APIM y JWT humano validado/);
  }
  for (const path of ['/interno/productos/skus/filtrar', '/interno/inventario/reservas/{reservaId}/evidencia-cupon']) {
    const operation = spec.paths[path][path.endsWith('filtrar') ? 'post' : 'get'];
    assert.equal(operation['x-internal'], true);
    assert.deepEqual(operation.security, [{ serviceBearer: [] }]);
    assert.match(operation.description, /exclusivamente M2M/);
    assert.doesNotMatch(operation.description, /navegador/);
  }
  assert.equal(operations(spec).length, new Set(operations(spec).map(op => op.operationId)).size);
  assert.equal(spec.paths['/inventario/administracion/saldos'].get.responses['200'].content['application/json'].examples.vacio.value.meta.total, 0);
});

test('AsyncAPI R02 y R10 tipados; R03/R14 reservados para no duplicar importador Pricing', async () => {
  const spec = await readAsync();
  assert.equal(spec.info.version, '0.7.0-rc.2');
  const schemas = spec.components.schemas;
  const request = schemas.InventoryBulkStockAdjustRequestedData;
  assert.equal(request.additionalProperties, false);
  assert.deepEqual(request.properties.reason, { type: 'string', const: 'BULK_INITIAL_STOCK' });
  assert.equal(request.properties.expected_stock_version.minimum, 0);
  assert.ok(!JSON.stringify(request).includes('GenericData'));
  assert.equal(spec.components.messages.InventoryBulkStockAdjustRequested.examples[0].payload.data.reason, 'BULK_INITIAL_STOCK');
  assert.equal(spec.components.messages.InventoryBulkStockAdjustRequested.examples[0].payload.data.expected_stock_version, 0);
  assert.ok(request.required.includes('location_id'));
  assert.equal(request.additionalProperties, false); // unknown fields are rejected
  assert.equal(schemas.InventoryBulkStockAdjustCompletedData.properties.applied_on_hand.minimum, 0);
  assert.ok(schemas.InventoryBulkStockAdjustRejectedData.required.includes('code'));
  assert.equal(spec.components.messages.InventoryBulkStockAdjustCompleted.examples[0].payload.data.stock_version, 1);
  assert.equal(spec.components.messages.InventoryBulkStockAdjustRejected.examples[0].payload.data.code, 'SKU_NO_INICIALIZADO');
  for (const n of ['PricingBulkPriceApplyRequested', 'PricingBulkPriceApplyCompleted', 'PricingBulkPriceApplyRejected']) {
    assert.equal(spec.components.messages[n]['x-runtime-status'], 'RESERVADO_NO_APLICA_BULK_V2');
  }
  assert.equal(spec.channels.g6_inventory_from_bulk['x-runtime-status'], 'PENDIENTE_IMPLEMENTACION');
  assert.ok(!spec['x-blocked-contracts'].includes('inventory.bulk.stock.adjust.requested'));
  assert.ok(spec['x-blocked-contracts'].includes('pricing.bulk.price.apply.requested'));
});
