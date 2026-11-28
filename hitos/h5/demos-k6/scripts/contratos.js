const opaqueId = (value) => typeof value === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(value);
const availability = ['DISPONIBLE', 'STOCK_BAJO', 'AGOTADO', 'INDETERMINADO'];
const unique = (values) => new Set(values).size === values.length;

export function buildReads(caseId, dataset, channel) {
  if (caseId === 'PERF-01') {
    const size = dataset.catalog?.page_size;
    const pages = dataset.catalog?.pages;
    if (!Number.isInteger(size) || size < 1 || size > 100 ||
        !Array.isArray(pages) || pages.length < 1 || pages.length > 10 ||
        !pages.every((page, i) => Array.isArray(page) && page.length > 0 &&
          page.length <= size && (i === pages.length - 1 || page.length === size) &&
          page.every(opaqueId)) || !unique(pages.flat())) {
      throw new Error('DATASET_CATALOGO_INVALIDO');
    }
    const total = pages.flat().length;
    return pages.map((ids, i) => {
      const page = i + 1;
      const filter = dataset.catalog.filter;
      if (filter !== undefined && !opaqueId(filter)) throw new Error('FILTRO_CATALOGO_INVALIDO');
      const path = `/api/v1/productos?canal=${channel}&pagina=${page}&tamanio=${size}&orden=NOMBRE_ASC`
        + (filter ? `&q=${encodeURIComponent(filter)}` : '');
      return {
        path,
        valid: (body) => body?.pagina === page && body?.tamanio === size && body?.total === total &&
          Array.isArray(body?.items) && body.items.length === ids.length &&
          body.items.every((item, index) => item?.product_id === ids[index] &&
            typeof item.name === 'string' && item.name.trim().length > 0 &&
            typeof item.tiene_variantes === 'boolean' &&
            (item.tiene_variantes ? item.sku_base === null : opaqueId(item.sku_base))),
      };
    });
  }

  if (caseId === 'PERF-02') {
    const skus = dataset.pricing?.skus;
    if (!Array.isArray(skus) || skus.length < 1 || skus.length > 10 ||
        !skus.every(opaqueId) || !unique(skus)) throw new Error('DATASET_PRICING_INVALIDO');
    return skus.map((sku) => ({
      path: `/api/v1/precios/skus/${encodeURIComponent(sku)}?canal=${channel}`,
      valid: (body) => body?.sku === sku && body.precio_regular > 0 &&
        Number.isFinite(body.precio_regular) &&
        (body.precio_oferta == null || (Number.isFinite(body.precio_oferta) && body.precio_oferta > 0)) &&
        typeof body.currency === 'string' && /^[A-Z]{3}$/.test(body.currency) &&
        (body.channel_id === null || body.channel_id === channel) &&
        typeof body.valid_from === 'string' && Number.isFinite(Date.parse(body.valid_from)) &&
        Number.isInteger(body.price_version) && body.price_version >= 0 &&
        typeof body.vigencia_id === 'string' && body.vigencia_id.length > 0 &&
        ['PRODUCTO', 'SKU_OVERRIDE'].includes(body.origen),
    }));
  }

  const items = dataset.inventory?.items;
  if (!Array.isArray(items) || items.length < 2 || items.length > 10 ||
      !items.every((item) => opaqueId(item?.sku) && availability.includes(item.status)) ||
      !unique(items.map((item) => item.sku)) ||
      !items.some((item) => ['DISPONIBLE', 'STOCK_BAJO'].includes(item.status)) ||
      !items.some((item) => ['AGOTADO', 'INDETERMINADO'].includes(item.status))) {
    throw new Error('DATASET_INVENTARIO_INVALIDO');
  }
  return items.map(({ sku, status }) => ({
    path: `/api/v1/inventario/disponibilidad/comercial?canal=${channel}&skus=${encodeURIComponent(sku)}`,
    valid: (body) => Array.isArray(body?.items) && body.items.length === 1 &&
      body.items[0]?.sku === sku && body.items[0]?.status === status &&
      Object.keys(body.items[0]).length === 2,
  }));
}
