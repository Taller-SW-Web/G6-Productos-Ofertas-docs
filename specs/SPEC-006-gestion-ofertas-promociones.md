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
## 6. Administración y persistencia de la configuración

- El alcance conserva por separado `productIds` y `skus`. Seleccionar un producto completo no se convierte en una foto de sus SKU actuales; incluye sus SKU vendibles elegibles, deduplicando coincidencias con alcances específicos.
- `canalesHabilitados` es una selección explícita, única y no vacía al crear. Un PATCH puede omitirla para conservarla, pero no enviarla vacía. No existe un default implícito «todos».
- `PromocionAdmin.puedeCambiarModalidad` es una capacidad calculada por el servicio según HU-006 CA-13: inactiva, nunca activada, sin cupones asociados ni usos históricos. El cliente no decide esa capacidad ni puede autorizarla mediante el request. El servicio revalida la condición en la operación de actualización.
- Activar una promoción deja un antecedente persistente de activación, incluso si luego se desactiva mediante edición o la acción de estado. No se elimina al desactivar.
- Si un consumidor todavía no recibe `puedeCambiarModalidad`, considera desconocida la elegibilidad y no infiere permiso desde el estado inactivo. Los fixtures de demostración sí deben representar tanto el caso permitido como los bloqueados.
