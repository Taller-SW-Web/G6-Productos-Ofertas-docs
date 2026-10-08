# SPEC-004 — Gestión de variantes y SKU

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** HU [HU-004](../hu/HU-004-gestion-variantes-skus.md) | Wireframe [WF-004](..\..\ux\wireframes\flows\WF-004-gestion-variantes-skus.md)

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

Una variante en `BORRADOR` puede tener perfil físico incompleto; los valores informados deben ser positivos. Activar o reactivar exige los cuatro valores completos. El padre no tiene peso ni dimensiones propios; el volumen de la variante se deriva de sus dimensiones y no se ingresa por separado.

## 6. Edición, activación, desactivación y reactivación

La edición ordinaria permite actualizar atributos no identificadores, imagen y perfil físico válido. Conserva `variant_id`, el SKU comercial publicado y los atributos identificadores, conforme a `VarianteUpdateRequest` en OpenAPI vigente.

La edición actualiza la misma variante, sin crear otra ni cambiar su identidad comercial. Antes de guardar cambios de una variante `ACTIVA`, se comprueba que el resultado completo conserve las condiciones de activación de la variante. Si no las conserva, se rechaza la edición y se mantienen los datos y el estado anteriores, sin desactivación automática.

Activar requiere un padre con `tiene_variantes=true`, SKU globalmente único, combinación identificadora única dentro del producto, atributos e imagen válidos, perfil físico completo en kg/cm con valores mayores que cero e Inventario confirmado mediante `inventory.sku.initialization.completed`. Las comprobaciones de unicidad excluyen la propia variante.

Desactivar una variante publica `catalog.sku.deactivated`. Si era la última variante activa y el padre estaba `ACTIVO`, se inactiva el padre conforme a SPEC-003. Si el padre estaba en `BORRADOR` o `INACTIVO`, conserva ese estado. Desactivar al padre conserva los estados individuales de sus variantes, pero bloquea su exposición comercial.

Reactivar una variante `INACTIVA` conserva `variant_id` y SKU, revalida las mismas condiciones de activación y solo entonces la devuelve a `ACTIVA`. Si no cumple, permanece `INACTIVA`. La preparación de Inventario rechazada o pendiente puede reintentarse idempotentemente conservando la identidad de operación; una inicialización completada no se repite. Reactivar no crea precio base ni activa automáticamente al padre: este se revalida conforme a SPEC-003.

El padre no necesita estar `ACTIVO` para preparar, activar o reactivar una variante. Para activar o reactivar al padre se requiere al menos una variante activa y preparada; los hijos en `BORRADOR` o `INACTIVA` no bloquean al padre ni se ofrecen comercialmente. Reactivar al padre no reactiva variantes inactivas.

La ruta `POST /productos/{productoId}/variantes/{variantId}/reactivar` está declarada en [OpenAPI vigente](..\..\contratos\http\openapi.yaml), con estado `provisional-internal`. Los eventos de desactivación se publican mediante RabbitMQ y su fan-out corresponde a AsyncAPI 0.4.0.

## 7. No pertenece a esta capacidad

- saldo;
- reserva;
- precio master;
- empaque;
- pedido.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Extensión 0.5.0 — resolución de variante

Se mantiene:

```text
variant_id != sku
```

Cuando un código de barras identifica una unidad vendible de un producto con variantes:

```text
codigo_barras → sku de la variante
```

No se devuelve `variant_id` como identidad comercial.

Una variante inactiva o con producto padre no comercialmente vendible no produce una resolución válida. La ausencia temporal de stock **no** cambia la identidad SKU; disponibilidad se consulta separadamente.
<!-- HOMOLOGACION-HTTP-0.5.0:END -->
