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
status ∈ {DISPONIBLE, STOCK_BAJO, AGOTADO}
```

Chatbot no recibe `location_id`, `on_hand`, `reserved`, `blocked`, `available`, `threshold` ni `stock_version`.

La proyección permanece provisional por `D-INV-01`. Recomendaciones continúan disponibles mediante `GET /api/v1/recomendaciones?productoId=...&canal=CHATBOT`.
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

**Canales:** una consulta comercial `SUFICIENTE` es informativa; Ventas sigue siendo quien reserva. `INDETERMINADO` obliga a no prometer disponibilidad de la cantidad solicitada.
