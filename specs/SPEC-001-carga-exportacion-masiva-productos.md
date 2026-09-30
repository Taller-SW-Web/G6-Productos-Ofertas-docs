# SPEC-001 — Carga y exportación masiva de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** HU [HU-001](../hu/HU-001-carga-exportacion-masiva-productos.md) | Wireframe [WF-001](../wireframes/flows/WF-001-carga-exportacion-masiva-productos.md)

---

## 1. Objetivo

Permitir importaciones masivas reproducibles de catálogo sin mezclar ownership entre Catálogo, Pricing e Inventario.

La carga general puede incluir datos de producto, SKU vendible, precio base inicial y stock inicial. Cada dominio persiste únicamente sus datos.

## 2. Regla de consistencia

No existe una transacción distribuida Catálogo + Pricing + Inventario.

```text
Bulk valida archivo
  -> Catálogo crea/actualiza borradores
  -> Catálogo solicita preparación de Pricing
  -> Catálogo solicita inicialización de SKU en Inventario
  -> cada dominio responde de forma idempotente
  -> el lote consolida el resultado
```

Un fallo parcial no se oculta ni se compensa borrando datos confirmados de otro dominio.

## 3. Inicialización de Pricing e Inventario

### Pricing

Para cada producto nuevo con precio base:

```text
pricing.product.initialization.requested
```

Payload funcional:

```text
product_id
sku_base
precio_regular
moneda
channel_id = null
motivo_cambio = ALTA_PRODUCTO
```

Resultados:

```text
pricing.product.initialization.completed
pricing.product.initialization.rejected
```

No se genera un precio inicial por variante: las variantes sin override heredan el precio del producto.

### Inventario

Para cada SKU vendible nuevo:

```text
inventory.sku.initialization.requested
```

Aplica a:

```text
producto simple -> sku_base
producto con variantes -> cada SKU de variante
```

El padre con variantes no crea saldo.

Si existe `default_location_id`, el saldo inicial es:

```text
on_hand = 0
reserved = 0
blocked = 0
available = 0
stock_version = 0
```

El stock cargado posteriormente se aplica mediante el contrato Bulk de Inventario.

## 4. Idempotencia

- El lote tiene identidad estable.
- Cada comando interno tiene `message_id`, `operation_id` y `correlation_id`.
- Reprocesar el mismo lote no debe duplicar productos, precios iniciales ni saldos.
- Reutilizar una identidad para otra intención produce conflicto.

## 5. Estados del lote

```text
VALIDANDO
PROCESANDO
COMPLETADO
COMPLETADO_CON_ERRORES
RECHAZADO
```

## 6. Criterios mínimos

- El archivo no puede producir SKU duplicados.
- Pricing conserva ownership del precio.
- Inventario conserva ownership del stock.
- Una variante no recibe precio base propio salvo override posterior.
- No se inventa una ubicación de Inventario cuando el proyecto no tiene `default_location_id`.
- El reporte final distingue errores por fila y por dominio.