# SPEC-002 — Gestión de combos de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** HU [HU-002](../hu/HU-002-gestion-combos-productos.md) | Wireframe [WF-002](../wireframes/flows/WF-002-gestion-combos-productos.md)

---

## 1. Objetivo

Administrar combos como oferta comercial compuesta sin convertirlos en un segundo owner de precio, stock o cupones.

## 2. Reglas

- Un combo contiene al menos dos componentes.
- No se admiten combos anidados.
- Cada componente referencia SKU/producto existente.
- Pricing mantiene el precio regular/oferta de los componentes.
- Inventario mantiene disponibilidad y reservas por SKU.
- Promociones/Cupones decide combinabilidad.

## 3. Inventario

La disponibilidad de un combo se deriva de sus componentes.

Cuando una compra real crea un pedido:

```text
Canal -> Ventas -> Inventario
```

El combo no reserva stock por cuenta propia.

## 4. Consumo y reglas de cupones

Validar un cupón durante la evaluación del combo:

```text
POST /cupones/validar
```

no consume.

Si el cupón forma parte de la alternativa comercial elegida, Ventas solicita el consumo después de confirmar reserva y antes del pago:

```text
promotions.coupon.consumption.requested
```

El combo no publica ese comando.

## 5. Criterios

- Precio del combo no altera los precios maestros.
- Un combo no crea stock propio.
- Un combo no consume/restaura cupones directamente.
- Desactivación de un componente puede volver el combo no elegible.