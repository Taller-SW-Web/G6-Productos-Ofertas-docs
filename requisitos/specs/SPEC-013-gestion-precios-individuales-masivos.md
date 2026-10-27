# SPEC-013 — Gestión de precios individuales y masivos

**Responsable:** Cristian Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** HU [HU-013](../hu/HU-013-gestion-precios-individuales-masivos.md) | Wireframe [WF-013](..\..\ux\wireframes\flows\WF-013-gestion-precios-individuales-masivos.md)

---

## 1. Ownership

Pricing es owner de:

```text
precio_regular
precio_oferta
moneda
channel_id
vigencias
price_version
histórico
```

## 2. Resolución por SKU

- Producto simple: resuelve el precio del producto asociado a `sku_base`.
- Variante sin override: hereda el precio del producto.
- Variante con override: usa precio específico del SKU.
- Canal específico puede tener vigencia propia con fallback al global.

### 2.1. Contexto privado desde Catálogo

La consulta de contexto necesaria para resolver SKU/producto se documenta en el [acuerdo privado skuContext](../../integraciones/ACUERDO_PRICING_CATALOGO_SKU_CONTEXT.md) y en [OpenAPI](../../contratos/http/openapi.yaml). Pricing consume `GET /api/v1/productos/skus/{sku}/contexto` mediante el adaptador del puerto `PricingCatalogContext` existente. Solo `404 SKU_NO_ENCONTRADO` se traduce a `null`; `200` conserva los flags de inactividad/inelegibilidad. Fallos de red, técnicos y de autorización se mantienen como errores. El contexto no calcula precios ni disponibilidad y no cambia las reglas de herencia/override de §2. Diseño aprobado por G6; identidad final y token G7, adaptador e integración pendientes de evidencia.

## 3. Inicialización de precio

Al crear el producto, Catálogo publica:

```text
pricing.product.initialization.requested
```

Payload:

```text
product_id
sku_base
precio_regular
moneda
channel_id = null
motivo_cambio = ALTA_PRODUCTO
```

Pricing registra:

```text
tipo_operacion = CREACION
precio_anterior = null
variacion_porcentual = null
price_version = 1
```

y responde:

```text
pricing.product.initialization.completed
pricing.product.initialization.rejected
```

Después del commit publica:

```text
pricing.price.changed
```

## 4. Variante

La inicialización es del **producto**. Crear variante no repite este comando.

Un override SKU posterior utiliza las operaciones normales de Pricing.

## 5. Edición y vigencias

- `precio_regular > 0`.
- `0 < precio_oferta < precio_regular` cuando exista.
- No se admiten vigencias superpuestas para el mismo objetivo/canal.
- Escritura desde una lectura previa usa `price_version`.
- Una versión obsoleta produce `VERSION_CONFLICT`.

## 6. Carga masiva

La carga exclusiva de Pricing es local al dominio. La carga general de SPEC-001 coordina Catálogo/Pricing/Inventario con consistencia eventual.

## 7. Auditoría

Toda mutación confirmada conserva motivo, actor, versión y hecho `pricing.price.changed`.

Para filtros de catálogo, Catálogo consume el precio efectivo vigente que entrega esta capacidad: `precio_oferta` vigente; de lo contrario, `precio_regular`. Pricing resuelve herencia y precedencia de overrides SKU/canal/global; Catálogo no recalcula esas reglas. Los límites `precioMin`/`precioMax` se comparan inclusivamente en PEN, tras verificar `currency` y sin conversión de moneda. La decisión de excluir importes no-PEN es criterio técnico recomendado, no una ratificación adicional. Ver secuencia, lotes y errores en [SPEC-003 §7](SPEC-003-gestion-productos-crud.md).

> **Integración G1 Marketplace H4 (2026-10-20):** G6 aceptó y comunicó M-01–M-09 (`ACEPTADO_G6_COMUNICADO_G1`). Esta SPEC gobierna reglas funcionales de su dominio; operaciones HTTP se verifican en [OpenAPI](../../contratos/http/openapi.yaml), el reparto/estado operativo en [Acuerdo G1–G6 H4](../../integraciones/ACUERDO_G1_G6_H4_2026-10-20.md) y [alineación](../../integraciones/ALINEACION_MARKETPLACE.md). No declarar runtime, grants G7, despliegue o E2E por esta referencia. Las dependencias de otros owners se limitan a la operación que les corresponde.
