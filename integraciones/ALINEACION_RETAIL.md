# Alineación Retail ↔ Productos y Ofertas — Código de barras → SKU

**Estado:** homologación contractual HTTP 0.5.0
**Fuente HTTP autoritativa:** [`../contratos/http/openapi.yaml`](../contratos/http/openapi.yaml)

## 1. Acuerdo confirmado

```text
codigo_barras != sku
```

Retail obtiene del lector el valor impreso, lo envía sin interpretarlo a Productos y Ofertas y recibe el SKU vendible correspondiente.

Después de resolver:

```text
codigo_barras → sku
```

Retail utiliza únicamente `sku` para carrito, precio, disponibilidad y venta.

## 2. Operación

```http
POST /api/v1/productos/codigos-barras/resolver
```

Request:

```json
{
  "codigo_barras": "0001234567890"
}
```

Response:

```json
{
  "sku": "SKU-001"
}
```

## 3. Semántica del identificador

`codigo_barras`:

- es un `string` opaco;
- conserva ceros a la izquierda;
- no se convierte a número;
- no se interpreta por segmentos;
- no presupone EAN, UPC, GTIN ni otra simbología;
- no tiene una longitud máxima arbitraria publicada.

Regla confirmada:

```text
cada codigo_barras resoluble → exactamente un SKU vendible
```

No está definida todavía la cardinalidad inversa:

```text
SKU → uno o varios códigos
```

## 4. Unidad vendible

Producto simple:

```text
codigo_barras → sku_base
```

cuando `sku_base` es su SKU vendible.

Producto con variantes:

```text
codigo_barras → sku de la variante vendible
```

No se devuelve `variant_id` como sustituto de SKU.

La ausencia de stock no cambia la identidad resuelta. La disponibilidad se consulta después por SKU.

## 5. No encontrado

Cuando el valor no produce una resolución comercial válida:

```text
HTTP 404
Problem.code = CODIGO_BARRAS_NO_ENCONTRADO
```

No se responde `200 + sku:null` ni se filtra el motivo administrativo interno.

## 6. Seguridad

```text
serviceBearer
aud = api-productos
scope = catalogo:leer
client = modulo-retail
```

Marketplace y Chatbot no obtienen acceso al resolver solo por poseer `catalogo:leer`.

## 7. Correlación

```text
X-Correlation-Id
```

es el header canónico.

## 8. Ownership

Productos y Ofertas es owner de la identidad comercial y de la capacidad de resolver la asociación.

Retail es owner de:

- captura del valor;
- envío del valor sin transformación;
- UX de escaneo;
- uso posterior del SKU.

No se define todavía:

- alta/edición/baja/reasignación;
- importación/exportación masiva;
- UI administrativa;
- reutilización/historial;
- cardinalidad inversa.

## 9. Disponibilidad posterior

Después de obtener el SKU, Retail consulta:

```text
GET /api/v1/inventario/disponibilidad/comercial
```

La respuesta comercial usa:

```text
DISPONIBLE
STOCK_BAJO
AGOTADO
INDETERMINADO
```

y no expone saldos internos. `D-INV-01` ya fue adoptada: no se combinan existencias de tiendas independientes. Si no existe una tienda/ubicación única elegible, devolver `INDETERMINADO` en lugar de inferir `AGOTADO`. El endpoint sigue provisional hasta probar su implementación.

### 9.1. Verificación por cantidad y tienda

Después de resolver el código de barras a `sku`, Retail puede consultar `POST /api/v1/inventario/disponibilidad/comercial/verificar` con `channel_id=RETAIL`, `fulfillment.mode=VENTA_TIENDA` o `RETIRO_TIENDA`, una `fulfillment_ref` pública/opaca de tienda y líneas `{sku, quantity}`. Inventario resuelve internamente tienda → `location_id`; Retail **nunca** recibe esa ubicación interna.

La respuesta `binding=false` contiene `SUFICIENTE`, `INSUFICIENTE` o `INDETERMINADO`. Si el mapeo no existe o es ambiguo, se responde `INDETERMINADO` y no debe confirmarse stock. No sumar tiendas. Un `SUFICIENTE` es informativo: Ventas orquesta las reservas y confirmaciones de la venta online; una venta Retail offline se concilia sin reserva retroactiva según SPEC-015. El acceso sigue sujeto a Seguridad/G7.

El **GET** comercial devuelve estados (`DISPONIBLE/STOCK_BAJO/AGOTADO/INDETERMINADO`), no resultados `SUFICIENTE`.

## 10. Casos contractuales mínimos

- `CT-RTL-BAR-01`: producto simple → respuesta con campo `sku`, cuyo valor corresponde al SKU base vendible (no existe un campo de respuesta `sku_base`).
- `CT-RTL-BAR-02`: variante → SKU de variante.
- `CT-RTL-BAR-03`: inexistente → 404.
- `CT-RTL-BAR-04`: preserva ceros a la izquierda.
- `CT-RTL-BAR-05`: asociación no vendible no filtra motivo.
- `CT-RTL-BAR-06`: response mínimo solo necesita SKU.
- `CT-RTL-BAR-07`: allowlist exclusiva de Retail.
- `IT-RTL-BAR-01`: un código no resuelve a dos SKU.
- `IT-RTL-BAR-02`: después de resolver, Pricing/Inventario usan SKU.

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

**Retail:** `fulfillment_ref` es una referencia pública de tienda (no se permite exponer `location_id`). La correspondencia tienda→ubicación debe provisionarse en Inventario y validarse antes de afirmar suficiencia.

## 11. Conciliación offline — decisiones internas y homologación pendiente

El acuerdo de esta alineación para resolver código de barras→SKU conserva su estado de homologación HTTP 0.5.0. Los bloqueos siguientes corresponden a una capacidad distinta: conciliación offline; no suspenden ni reabren el acuerdo de códigos de barras.

Las DEC-F-013, 014 y 015 están adoptadas internamente por G6, pero no acreditan una homologación externa ni implementación:

- **DEC-F-013:** Inventario conserva la autoridad del saldo central y concilia una venta física ya ocurrida sin reserva retroactiva. Aplica solo cantidades admisibles, no consume unidades reservadas o bloqueadas, no produce saldos negativos ni descuentos duplicados. Una conciliación parcial conserva `requested_quantity`, `applied_quantity` y `unresolved_quantity`; la operación puede quedar registrada sin movimiento cuando la cantidad aplicada es cero. Replay semántico idéntico devuelve el resultado anterior y un payload conflictivo se rechaza con `409 IDEMPOTENCY_CONFLICT`, conforme a DEC-F-009.
- **DEC-F-014:** una referencia pública de tienda no es `location_id`. Antes de una mutación, Inventario debe resolver y autorizar internamente la ubicación. Mapeo ausente/ambiguo, actor sin autorización o permiso de lectura comercial no autorizan escritura.
- **DEC-F-015:** un resultado futuro para Retail debe minimizar la información interna; no debe exponer innecesariamente saldos, `location_id` ni `stock_version`.

La secuencia documentada actualmente por G6 es Retail→Ventas/Postventa→G6: Retail sincroniza su venta y `modulo-ventas` invoca la conciliación. El antecedente Retail→G6 directo no está homologado; G4 v0.4 además documenta una secuencia distinta. No se establece un orden nuevo entre venta, pedido, pago y conciliación.

El OpenAPI actual publica `POST /api/v1/inventario/conciliaciones-offline` con allowlist exclusiva de `modulo-ventas` y scope `inventario:conciliar-offline` cuyo registro/grant efectivo sigue pendiente de Seguridad/G7. Retail no está autorizado como consumidor actual de esta operación. El scope `inventario:disponibilidad:leer` solo habilita las consultas comerciales según su allowlist y no concede permiso de mutación.

La entrada `ConciliacionOfflineRequest.lines` referencia `LineaInventarioUbicada` y exige `location_id`, incompatible con el objetivo de que Retail no elija una ubicación interna. Esta incompatibilidad contractual y una forma de entrada compatible siguen pendientes; no se resuelven en esta alineación.

G4 usa `ventaLocalUuid`; el contrato G6 declara `offline_sale_id`, `operation_id` y `order_id`. Su correspondencia, la identidad estable de una venta, el ámbito de unicidad y la idempotencia entre reintentos con diferentes identidades técnicas siguen pendientes de homologación. No se presume que esos identificadores sean equivalentes ni que su presencia implemente la deduplicación.

La respuesta candidata actual de conciliación incluye las cantidades funcionales y `location_id`, `on_hand`, `reserved`, `blocked`, `available` y `stock_version`; su consumidor contractual es Ventas. No se retiran campos del contrato vigente ni se afirma que Retail reciba o consuma hoy esa respuesta. La representación futura para Retail, su consumidor, scope y eventual consulta posterior requieren acuerdo G4/G7. La forma actual está documentada en [OpenAPI](../contratos/http/openapi.yaml); las reglas y estados internos se detallan en [DEC-F-013–015](../arquitectura/decisiones/REGISTRO_DEC_F.md) y [SPEC-015 §24.5](../requisitos/specs/SPEC-015-control-stock-disponibilidad.md).
