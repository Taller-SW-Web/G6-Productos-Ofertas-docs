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

## Addendum contractual 0.6.0-rc.1 — Cuatro bloqueantes G6

**Decisión interna aprobada; objetivo 0.6.0-rc.1 (no desplegado).**

- `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- `POST /inventario/reservas`, `/confirmar` y `/liberar` responden `202` solamente cuando aceptan el comando. El éxito o rechazo se determina por resultado persistido y evento.
- Nuevos contratos provisionales: `GET /inventario/operaciones/{operationId}` (solo Ventas; scope `inventario:operaciones:leer`) y `POST /inventario/disponibilidad/comercial/verificar` (canales, consulta sin efectos).
- Nuevo evento `inventory.reservation.rejected`; resultados de reserva/consumo/liberación/expiración con datos tipados y correlación obligatoria.
- `D-INV-01`: no se suman saldos de ubicaciones independientes por defecto. Un canal obtiene `INDETERMINADO` cuando el punto único de cumplimiento no se puede resolver. `SUFICIENTE` exige una fuente de abastecimiento realizable para la cantidad completa; no supone reserva.
- Cupones: después de reserva confirmada, Ventas envía `reservation_id` y `commercial_snapshot_ref` al solicitar consumo. Los resultados de consumo se tipan y la restauración se vincula a la operación previamente consumida.
- Misma identidad/operación/payload semántico => mismo resultado y cero efectos nuevos; identidad reutilizada con payload distinto => `IDEMPOTENCY_CONFLICT`. Los eventos tienen `message_id` propio para deduplicación de transporte.
- Las transiciones pagar/expirar/liberar se serializan por reserva; se respeta `expires_at` emitido por Inventario.
- Estos contratos siguen **provisionales** hasta que la implementación, migraciones y pruebas integradas sean verificadas. No anunciar disponibilidad real antes del cierre.

**Ventas:** no declarar stock reservado tras recibir `202`. Correlacionar por `operation_id`, conservar `reservation_id` y `expires_at` al recibir confirmación; consultar el estado persistido si se pierde un resultado. La autorización efectiva depende de Seguridad y de la disponibilidad de adaptador/mensajería de G5.
