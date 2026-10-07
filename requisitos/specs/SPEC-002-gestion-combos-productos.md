# SPEC-002 — Gestión de combos de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** HU [HU-002](../hu/HU-002-gestion-combos-productos.md) | Wireframe [WF-002](..\..\ux\wireframes\flows\WF-002-gestion-combos-productos.md)

---

## 1. Objetivo

Administrar combos como oferta comercial compuesta sin convertirlos en un segundo owner de precio, stock o cupones.

## 2. Reglas

- **Componentes mínimos:** Un combo contiene al menos dos componentes SKU vendibles directos.
- **Sin anidamiento:** No se admiten combos anidados ni combos que contengan otros combos.
- **Sin duplicados:** Cada componente referencia un SKU/producto existente y activo, sin duplicación de ítems dentro del mismo combo.
- **Regla de beneficio económico de precio:** El precio promocional del combo debe ser mayor a cero y estrictamente menor que la compra de los componentes por separado, evaluado tanto frente a la suma de sus precios regulares como frente a la suma de sus precios públicos vigentes. Si no cumple esta regla, la solicitud se rechaza con el código canónico `COMBO_PRECIO_INVALIDO`.
- **Precios maestros:** Pricing mantiene el precio regular y las ofertas de los componentes; el precio del combo no altera los precios maestros.
- **Inventario:** Inventario mantiene disponibilidad y reservas por SKU; el combo no posee saldo propio ni reserva existencias de forma autónoma.
- **Disponibilidad informativa:** La disponibilidad mostrada del combo se deriva en tiempo real como `min(floor(stock_disponible_i / cantidad_requerida_i))` y es de naturaleza puramente informativa.
- **Desactivación de componentes:** Si un producto o SKU componente es desactivado (`catalog.product.deactivated` o `catalog.sku.deactivated`), el combo deja de ser elegible y comprable para nuevas ventas, conservando intacta su definición administrativa histórica.
- **Promociones/Cupones:** Promociones decide la combinabilidad de cupones con ofertas de combo.

## 3. Inventario y compras

La disponibilidad de un combo se deriva de sus componentes. El combo no crea saldo de inventario ni reserva stock por cuenta propia.

Cuando una compra real crea un pedido:

```text
Canal -> Ventas -> Inventario (reserva por componente)
```

## 4. Consumo y reglas de cupones en Checkout

Validar un cupón durante la evaluación del combo:

```text
POST /cupones/validar
```

no consume el cupón ni muta estado.

Cuando se procesa el pedido en checkout, el módulo Ventas/Postventa orquesta el proceso con el siguiente orden estricto:

```text
1. Confirmación de reserva de existencias en Inventario por cada SKU componente
2. Si aplica cupón: solicitud asíncrona de consumo (promotions.coupon.consumption.requested)
3. Intento de pago
```

### Reglas de compensación en checkout

- **Reserva de stock fallida:** Se cancela el pedido; no hay reserva que liberar ni cupón que restaurar.
- **Consumo de cupón rechazado:** Se solicita la liberación de la reserva de stock a Inventario y se cancela el pedido; no se efectúa cobro ni restitución de cupón.
- **Pago fallido con cupón previamente consumido:** Se libera la reserva de stock en Inventario y se solicita la restitución del cupón consumido (`promotions.coupon.restoration.requested`).
- **Pago fallido sin cupón:** Se libera la reserva de stock en Inventario y se cancela el pedido; no se emite ninguna solicitud hacia Promociones.

El combo nunca publica comandos de consumo ni de restitución de cupones.

## 5. Criterios de cierre

- El precio del combo no altera los precios maestros.
- El precio del combo debe garantizar una ventaja económica frente a la suma de componentes individuales (`COMBO_PRECIO_INVALIDO`).
- Un combo no crea stock propio ni saldos en almacén.
- Un combo no consume ni restaura cupones directamente.
- La desactivación de un componente vuelve el combo no elegible para compra comercial.
- En cancelaciones de checkout, únicamente se solicita restitución de cupón si este fue efectivamente consumido.