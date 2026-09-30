# SPEC-013 — Gestión de precios individuales y masivos

**Responsable:** Cristian Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** HU [HU-013](../hu/HU-013-gestion-precios-individuales-masivos.md) | Wireframe [WF-013](../wireframes/flows/WF-013-gestion-precios-individuales-masivos.md)

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