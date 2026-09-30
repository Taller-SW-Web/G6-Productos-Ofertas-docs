# SPEC-006 — Gestión de ofertas y promociones

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** HU [HU-006](../hu/HU-006-gestion-ofertas-promociones.md) | Wireframe [WF-006](../wireframes/flows/WF-006-gestion-ofertas-promociones.md)

---

## 1. Objetivo

Administrar reglas promocionales y evaluación comercial sin alterar el precio maestro de Pricing.

## 2. Evaluación

```http
POST /api/v1/promociones/evaluar
```

El request usa:

```text
channel_id
lines[{sku, quantity, product_id?}]
at?
coupon_code?
customer_ref?
```

La evaluación puede seleccionar una alternativa con cupón, pero **no consume** el cupón.

## 3. Reglas de cupones en promociones

Si la alternativa ganadora usa cupón, Ventas conserva el snapshot y posteriormente solicita:

```text
promotions.coupon.consumption.requested
```

Promociones/Cupones vuelve a comprobar capacidad atómica y publica resultado.

## 4. Pricing

Pricing aporta precio regular/oferta propia. Promociones aplica sus reglas sin sobrescribir esos valores.

## 5. Reglas

- Canal forma parte de la evaluación.
- Vigencia se evalúa contra `at`.
- Una promoción `CUPON` exige código válido.
- `customer_ref` se usa para límites por cliente.
- La evaluación no crea pedido ni reserva stock.