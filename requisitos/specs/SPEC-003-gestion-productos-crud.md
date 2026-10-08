# SPEC-003 — Gestión de productos (CRUD principal)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** HU [HU-003](../hu/HU-003-gestion-productos-crud.md) | Wireframe [WF-003](..\..\ux\wireframes\flows\WF-003-gestion-productos-crud.md)

---

## 1. Modelo

Un producto puede ser:

```text
simple: sku_base = SKU vendible
con variantes: sku_base = identidad base; cada variante posee SKU vendible
```

Catálogo es owner de identidad, descripción, clasificación, imágenes, slug y perfil físico del producto simple.

Pricing es owner del precio. Inventario es owner del saldo.

## 2. Creación

El producto se crea en `BORRADOR` con:

- nombre;
- descripción;
- categoría;
- tipo de producto;
- marca;
- `sku_base`;
- `tiene_variantes`;
- precio base inicial.

Guardar borrador no exige imagen, completar características ni datos físicos.

## 3. Preparación de Pricing

Después de persistir el borrador, Catálogo publica idempotentemente:

```text
pricing.product.initialization.requested
```

con:

```text
product_id
sku_base
precio_regular
moneda
channel_id = null
motivo_cambio = ALTA_PRODUCTO
```

Pricing responde:

```text
pricing.product.initialization.completed
pricing.product.initialization.rejected
```

`completed` significa que existe el primer precio del producto. Pricing publica `pricing.price.changed` después de su commit.

No se genera precio base por variante.

## 4. Inicialización de Inventario

### Producto simple

Catálogo publica:

```text
inventory.sku.initialization.requested
sku = sku_base
variant_id = null
```

### Producto con variantes

El padre no crea saldo. Cada SKU de variante se inicializa desde SPEC-004.

Resultados:

```text
inventory.sku.initialization.completed
inventory.sku.initialization.rejected
```

## 5. Activación

`BORRADOR -> ACTIVO` requiere:

1. datos mínimos válidos;
2. categoría/tipo/marca válidos;
3. características obligatorias completas;
4. imagen;
5. Pricing preparado;
6. Inventario inicializado para `sku_base` si es simple, o para todas las variantes activas si usa variantes;
7. si usa variantes, al menos una variante activa que cumpla SPEC-004; las variantes en `BORRADOR` o `INACTIVA` no se ofrecen comercialmente ni bloquean al padre;
8. si es simple, perfil físico completo y válido; el padre con variantes no tiene peso ni dimensiones propios.

Durante el alta, un rechazo de Pricing/Inventario en las dependencias requeridas mantiene el producto en `BORRADOR`; no existe rollback distribuido ficticio. El rechazo de preparación de una variante no activa no bloquea por sí solo al padre ni lo inactiva.

## 6. Perfil físico

Para producto simple:

```text
pesoKg > 0
largoCm > 0
anchoCm > 0
altoCm > 0
```

Unidades contractuales: kg y cm.

El borrador puede tener perfil físico incompleto; los valores informados deben ser positivos. Para activar o reactivar un producto simple, los cuatro valores deben estar completos. El volumen se deriva de las dimensiones y no se ingresa como un dato independiente.

Despacho consulta:

```http
POST /api/v1/productos/datos-fisicos/consulta
```

con `sub=modulo-despacho`, `aud=api-productos`, `scope=productos:fisicos:leer`.

## 7. Edición/desactivación

- `sku_base` no se recodifica por edición ordinaria.
- `tiene_variantes` no cambia tras publicar identidad.
- La edición actualiza el mismo producto y conserva su naturaleza comercial y la coherencia con sus variantes; no crea ni sustituye variantes. Un cambio que represente otro producto requiere una nueva alta, no reutilizar la identidad existente.
- Antes de guardar una edición de un producto `ACTIVO`, se valida el resultado completo contra las condiciones de activación. Si alguna deja de cumplirse, se rechaza la edición y se conservan los datos y el estado anteriores, sin desactivación automática.
- La baja es lógica.
- Desactivar publica `catalog.product.deactivated`.
- Desactivar al padre bloquea comercialmente todas sus variantes, conservando sus estados individuales.
- Reactivar vuelve a validar las condiciones y no reactiva automáticamente variantes inactivas. Reactivar una variante tampoco reactiva al padre.

## 8. Criterio de completitud

La capacidad queda completa cuando el CRUD, preparación de Pricing e inicialización de Inventario son idempotentes y la activación nunca presupone que un `requested` ya terminó correctamente.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Extensión 0.5.0 — identidad y exposición comercial

Se formaliza:

```text
product_id != variant_id != sku != codigo_barras
producto simple → sku_base = SKU vendible
```

Catálogo es owner de la capacidad de resolver un código de barras a un SKU vendible. Cada código resoluble identifica exactamente un SKU. La cardinalidad inversa SKU→código(s) y la administración de la asociación siguen abiertas (`D-CAT-01..04`).

La lectura comercial por slug aplica:

```text
producto.status = ACTIVO
AND elegible_para_canal(producto, canal)
```

`ACTIVO` no implica visibilidad automática en todos los canales. La persistencia y default de elegibilidad continúan abiertos (`D-CAT-05/06`).

Para producto simple, cuando exista una asociación resoluble:

```text
codigo_barras → sku_base
```

Desactivar el producto impide la resolución comercial mientras permanezca inactivo. No se define todavía si la asociación histórica se elimina/reutiliza.
<!-- HOMOLOGACION-HTTP-0.5.0:END -->
