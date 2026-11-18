import assert from 'node:assert/strict';
import { test } from 'node:test';
import { loadContract } from '../scripts/contract.mjs';

test('El detalle administrativo de Catalog se conserva como candidato humano y versionado', async () => {
  const { spec } = await loadContract();
  const detail = spec.paths['/productos/administracion/{productoId}'].get;
  assert.equal(detail.operationId, 'obtenerProductoAdministracion');
  assert.equal(detail['x-status'], 'implemented-candidate');
  assert.equal(detail['x-required-role'], 'GESTOR_COMERCIAL');
  assert.deepEqual(detail.security, [{ userBearer: [] }]);
  assert.deepEqual(detail.parameters[0].schema, { type: 'string', format: 'uuid' });
  assert.deepEqual(detail['x-error-codes']['404'], ['PRODUCTO_NO_ENCONTRADO']);
  const schema = spec.components.schemas.ProductoAdministracionDetalle.allOf[1];
  assert.equal(schema.properties.elegibleCorreccionTipo.type, 'boolean');
  assert.ok(!schema.required.includes('elegibleCorreccionTipo'));
  assert.deepEqual(spec.components.schemas.ProductoResumenAdministracion.properties.publicadoAlgunaVez.type, ['boolean', 'null']);
});

test('Los contextos SKU permanecen internos y las dos lecturas de variantes publican VALIDACION', async () => {
  const { spec } = await loadContract();
  for (const operation of [
    spec.paths['/productos/skus/{sku}/contexto'].get,
    spec.paths['/productos/skus/contexto/lote'].post,
  ]) {
    assert.equal(operation['x-internal'], true);
    assert.deepEqual(operation.security, [{ serviceBearer: [] }]);
  }
  for (const path of ['/productos/{productoId}/variantes', '/productos/{productoId}/variantes/{variantId}']) {
    assert.deepEqual(spec.paths[path].get['x-error-codes']['400'], ['VALIDACION']);
  }
});
