# SPEC-005 — Gestión de cupones de descuento

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** HU [HU-005](../hu/HU-005-gestion-cupones-descuento.md) | Wireframe [WF-005](..\..\ux\wireframes\flows\WF-005-gestion-cupones-descuento.md)

---

## 1. Objetivo

Administrar cupones asociados a promociones y controlar validación, consumo y restitución sin trasladar ownership del pedido a Promociones.

## 2. Identidad del cliente

Contrato asíncrono:

```text
customer_ref = claim sub del token de acceso de Seguridad
formato = UUID
```

- El canal copia el `sub` del cliente autenticado.
- Ventas persiste ese mismo UUID como referencia del cliente del pedido.
- El `sub` de un token de servicio nunca es `customer_ref`.
- `null` se admite para anónimo solo si la regla no requiere límite por cliente.

Si existe `max_usos_por_cliente` y falta identidad:

```text
CUSTOMER_REF_REQUERIDO
```

## 3. Validación

```http
POST /api/v1/cupones/validar
```

Validar:

- comprueba existencia/estado/vigencia/alcance/límites;
- evalúa el beneficio;
- **no consume**.

Una validación positiva no reserva el último uso.

## 4. Consumo de cupones

Secuencia:

```text
Ventas crea CREADO
-> reserva de Inventario confirmada
-> snapshot comercial final
-> promotions.coupon.consumption.requested
-> promotions.coupon.consumption.completed | rejected
-> solo completed habilita continuar al intento de pago
```

Idempotencia de negocio:

```text
(order_id, cupon_id) = un único consumo
```

Al consumir se vuelve a comprobar atómicamente:

- cupo global;
- cupo por cliente;
- identidad del cupón;
- coherencia con el pedido.

Dos pedidos compitiendo por el último uso producen como máximo un consumo exitoso.

## 5. Restitución de cupones

Si un pedido que ya pudo consumir cupón se cancela:

```text
promotions.coupon.restoration.requested
```

Resultados:

```text
RESTORED
POLICY_KEEPS_CONSUMPTION
NO_CONSUMPTION
```

Políticas:

```text
RESTAURAR_EN_CANCELACION
NO_RESTAURAR
```

La restitución es idempotente.

## 6. Fuera de alcance

Cupones no procesa pagos, reembolsos ni decide el estado del pedido.
## Administración del código y límites

El código se normaliza eliminando espacios en los extremos y convirtiendo letras ASCII a mayúsculas; solo admite letras ASCII, números, guion y guion bajo. La unicidad se compara después de normalizar y excluye el propio registro al editar. El cliente normaliza antes de enviar el request y el servicio mantiene la misma regla.

Los límites opcionales vacíos se representan como `null` (Sin límite). Si se informan, son enteros positivos. El monto mínimo opcional vacío es `null`; si se informa, debe ser mayor que cero. Un guardado inválido conserva el formulario y no comunica éxito.

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

**Precondición de cupón:** `reservation_id` debe ser una reserva confirmada del pedido. `commercial_snapshot_ref` es una referencia duradera producida por Ventas; no sustituye la revalidación de las reglas propias de Promociones. Una respuesta de evaluación nunca consume usos. La restauración no precede a consumo confirmado y se deduplica por operación de negocio.
