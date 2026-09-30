# Alineación Ventas/Postventa ↔ Productos y Ofertas

## customer_ref

El identificador inter-módulo del cliente debe ser el UUID de Seguridad:

```text
contacto.clienteId = customer_ref = claim sub del token de acceso
```

El ejemplo `CLI-8841` debe sustituirse por un UUID de Seguridad o declararse explícitamente como alias interno no utilizable como `customer_ref`.

## Consumo de cupón

Después de crear `CREADO` y confirmar reserva de Inventario:

```text
modulo-ventas
  -> promotions.coupon.consumption.requested
```

Si el resultado es:

```text
promotions.coupon.consumption.completed
```

el checkout puede continuar al intento de pago.

Si es:

```text
promotions.coupon.consumption.rejected
```

no se debe intentar el cobro con ese snapshot de cupón.

## Cancelación

Si el pedido había consumido cupón:

```text
modulo-ventas
  -> promotions.coupon.restoration.requested
```

Promociones aplica `RESTAURAR_EN_CANCELACION` o `NO_RESTAURAR` y devuelve un resultado idempotente.

## Inventario

Acuerdos de inventario homologados:

```text
CREADO -> reservar
PAGADO -> consumir reserva
cancelación pre-consumo -> liberar
retorno físico aceptado -> reintegrar
venta Retail offline -> conciliar
```
