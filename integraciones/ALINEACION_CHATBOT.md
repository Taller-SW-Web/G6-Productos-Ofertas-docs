# Alineación Chatbot ↔ Productos y Ofertas

## Acuerdos de Integración Consolidados

## 1. Contrato de Productos

| Chatbot actual | Contrato definitivo |
|---|---|
| `/recomendaciones/candidatos` | `/recomendaciones` |
| `{canal, lineas[{sku,cantidad}], cupon?}` | `{channel_id, lines[{sku,quantity,product_id?}], coupon_code?, customer_ref?}` |
| `{codigo, canal, customerRef, lineas[]}` | `{coupon_code, channel_id, customer_ref, lines[]}` |
| Ruta/payload “propuesto” | OpenAPI de Productos como fuente |

Rutas:

```text
GET /api/v1/productos
GET /api/v1/productos/{productoId}
GET /api/v1/categorias
GET /api/v1/marcas
GET /api/v1/precios
GET /api/v1/inventario/disponibilidad/comercial
GET /api/v1/promociones
POST /api/v1/promociones/evaluar
POST /api/v1/cupones/validar
GET /api/v1/recomendaciones
```

El BFF Chatbot puede conservar camelCase internamente, pero su adaptador a Productos traduce al contrato publicado.

## 2. Envío y Dimensiones Físicas

Eliminar el parche autoritativo `pesos_por_categoria.yaml`.

```text
Chatbot
  -> POST /api/v1/cotizaciones (Despacho)
     destino
     lineas[{sku,cantidad}]
```

Despacho obtiene por su cuenta:

```text
POST /api/v1/productos/datos-fisicos/consulta
```

con:

```text
sub = modulo-despacho
aud = api-productos
scope = productos:fisicos:leer
```

Chatbot no calcula ni persiste peso o volumen.

## 3. — Texto libre

Productos soporta:

```text
GET /api/v1/productos?q=<texto>
```

por lo que A7 deja de estar abierto.

## customer_ref

En sesión autenticada:

```text
customer_ref = accessToken.sub
```

En anónimo:

```text
customer_ref = null
```

si el cupón exige límite por cliente, la validación debe informar `CUSTOMER_REF_REQUERIDO`.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Actualización HTTP 0.5.0

La disponibilidad consumida por Chatbot es la proyección comercial:

```text
sku + status
status ∈ {DISPONIBLE, STOCK_BAJO, AGOTADO, INDETERMINADO}
```

Chatbot no recibe `location_id`, `on_hand`, `reserved`, `blocked`, `available`, `threshold` ni `stock_version`.

La política `D-INV-01` ya está adoptada: no se suman saldos entre ubicaciones independientes. Cuando el cumplimiento es incierto, Chatbot debe presentar disponibilidad no confirmada (`INDETERMINADO`), nunca afirmar que hay stock o que está agotado por falta de mapeo. La implementación de esta proyección continúa provisional. Recomendaciones conservan su contrato `GET /api/v1/recomendaciones?productoId=...&canal=CHATBOT`.
### Verificación de cantidades

Cuando el usuario consulta una cantidad específica, Chatbot puede usar `POST /api/v1/inventario/disponibilidad/comercial/verificar` con `channel_id=CHATBOT`, `fulfillment={mode, fulfillment_ref?}` y `lines=[{sku, quantity}]`. Solo recibe `SUFICIENTE`, `INSUFICIENTE` o `INDETERMINADO`, con `binding=false`. `SUFICIENTE` significa capacidad informativa del cumplimiento solicitado, no una reserva; la confirmación real corresponde a Ventas. Una correspondencia de ubicación ausente/ambigua devuelve `INDETERMINADO` (no `AGOTADO`). No divulgar `location_id` ni saldos.

No confundir los estados del GET con los resultados del POST. La autorización por `client_id` y scope depende de G7.

<!-- HOMOLOGACION-HTTP-0.5.0:END -->

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

**Canales:** un resultado `SUFICIENTE` del **POST de verificación** es informativo; Ventas sigue siendo quien reserva. `INDETERMINADO` obliga a no prometer disponibilidad de la cantidad solicitada.
