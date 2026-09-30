# SPEC-004 — Gestión de variantes y SKU

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** HU [HU-004](../hu/HU-004-gestion-variantes-skus.md) | Wireframe [WF-004](../wireframes/flows/WF-004-gestion-variantes-skus.md)

---

## 1. Objetivo

Administrar unidades vendibles de productos con variantes manteniendo identidad SKU, perfil físico e integración correcta con Pricing e Inventario.

## 2. Reglas

- Solo un producto con `tiene_variantes=true` admite variantes.
- La combinación de atributos identificadores es única dentro del producto.
- Cada variante posee SKU globalmente único.
- Peso/dimensiones pertenecen a la variante.
- El padre no representa una unidad física.

## 3. Inicialización de Pricing

Crear una variante **no crea un precio base propio**.

```text
sin override -> hereda el precio vigente del producto
con override -> Pricing gestiona posteriormente el precio específico de SKU
```

El comando `pricing.product.initialization.requested` se emite una vez para el producto, no una vez por variante.

## 4. Inicialización de Inventario

Después de persistir una variante nueva, Catálogo solicita:

```text
inventory.sku.initialization.requested
```

con:

```text
sku
product_id
variant_id
default_location_id opcional
```

La variante solo se considera preparada para activación cuando recibe:

```text
inventory.sku.initialization.completed
```

Si se rechaza, permanece no publicable y puede reintentarse idempotentemente.

## 5. Perfil físico

```text
pesoKg > 0
largoCm > 0
anchoCm > 0
altoCm > 0
```

Despacho consulta todas las unidades vendibles mediante el mismo endpoint físico.

## 6. Desactivación

Desactivar una variante publica `catalog.sku.deactivated`. Si era la última variante activa, el producto padre se inactiva conforme a SPEC-003.

## 7. No pertenece a esta capacidad

- saldo;
- reserva;
- precio master;
- empaque;
- pedido.