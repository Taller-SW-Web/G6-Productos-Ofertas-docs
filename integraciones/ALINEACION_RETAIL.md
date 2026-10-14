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

## 11. Conciliación offline — acuerdo G5 comunicado y homologación pendiente

El acuerdo de esta alineación para resolver código de barras→SKU conserva su estado de homologación HTTP 0.5.0. Los bloqueos siguientes corresponden a una capacidad distinta: conciliación offline; no suspenden ni reabren el acuerdo de códigos de barras.

Las DEC-F-013, 014 y 015 están adoptadas internamente por G6, pero no acreditan una homologación externa ni implementación:

- **DEC-F-013:** Inventario conserva la autoridad del saldo central y concilia una venta física ya ocurrida sin reserva retroactiva. Aplica solo cantidades admisibles, no consume unidades reservadas o bloqueadas, no produce saldos negativos ni descuentos duplicados. Una conciliación parcial conserva `requested_quantity`, `applied_quantity` y `unresolved_quantity`; la operación puede quedar registrada sin movimiento cuando la cantidad aplicada es cero. Replay semántico idéntico devuelve el resultado anterior y un payload conflictivo se rechaza con `409 IDEMPOTENCY_CONFLICT`, conforme a DEC-F-009.
- **DEC-F-014:** una referencia pública de tienda no es `location_id`. Antes de una mutación, Inventario debe resolver y autorizar internamente la ubicación. Mapeo ausente/ambiguo, actor sin autorización o permiso de lectura comercial no autorizan escritura.
- **DEC-F-015:** un resultado futuro para Retail debe minimizar la información interna; no debe exponer innecesariamente saldos, `location_id` ni `stock_version`.

**Actualización 2026-10-14 — confirmación comunicada por G5:** G5 confirma que Retail invoca directamente `POST /api/v1/inventario/conciliaciones-offline`; M1/Ventas no reserva, confirma consumo ni concilia stock para ventas Retail. G5 registra esta responsabilidad en `ACUERDO_G4_RETAIL.md` R9 y `ACUERDO_G6_PRODUCTOS.md`. Esto es `ACUERDO_EXTERNO_DOCUMENTADO` por G5 y una confirmación comunicada en esta fecha; no acredita por sí sola ratificación documental vigente de G4, conformidad contractual de G6, grants G7 ni implementación.

La fuente G4 `specs/api-contracts.md` v0.4 §4.2 todavía prohíbe la llamada Retail a conciliaciones-offline y §5.10 dirige la sincronización a Ventas; F10 v1.0/RF-28 documenta `POST /api/v1/ordenes/sincronizar`. G5 `ACUERDO_G4_RETAIL.md` R9 y su confirmación del 14/10 establecen Retail→G6 directo. G6 OpenAPI candidato conserva como descripción Ventas→G6 y solo permite `modulo-ventas`. Se registra la contradicción; no se fija orden entre venta POS, alta del pedido G5, pago y conciliación.

El OpenAPI actual publica `POST /api/v1/inventario/conciliaciones-offline` con allowlist exclusiva de `modulo-ventas` y scope `inventario:conciliar-offline`, con registro pendiente. Retail no está autorizado por el contrato actual. La matriz G7 consultada (corte 2026-10-11) no acredita aprobación, grant ni aprovisionamiento de `inventario:conciliar-offline` para `modulo-retail`; el permiso de disponibilidad comercial no concede mutación.

La entrada `ConciliacionOfflineRequest.lines` referencia `LineaInventarioUbicada` y exige `location_id`, incompatible con DEC-F-014: G6 debe resolver y autorizar internamente la ubicación antes de mutar. La decisión de representación compatible queda propuesta para homologación: Retail enviaría la referencia pública de tienda que ya pertenezca al payload aprobado por G4/G5; G6 resolvería tienda→ubicación interna y rechazaría la ausencia o ambigüedad. No se agrega un campo ni se decide cuál identificador existente se reutiliza hasta que G4, G5 y G6 lo confirmen formalmente.

G4 usa `ventaLocalUuid`; el contrato G6 declara `offline_sale_id`, `operation_id` y `order_id`. Su correspondencia, la identidad estable de una venta, el ámbito de unicidad y la idempotencia entre reintentos con diferentes identidades técnicas siguen pendientes de homologación. No se presume que esos identificadores sean equivalentes ni que su presencia implemente la deduplicación.

La respuesta candidata actual de conciliación incluye cantidades funcionales y `location_id`, `on_hand`, `reserved`, `blocked`, `available` y `stock_version`; su consumidor contractual es Ventas. Conforme a DEC-F-015, propuesta para homologación: Retail recibe únicamente identidad de operación/venta, estado y por línea SKU/cantidades solicitada, aplicada y no resuelta que necesite para revisión; no recibe `location_id`, saldos internos ni `stock_version`. G4/G5/G6 deben confirmar los campos y si Retail requiere una consulta durable posterior. No se modifica el DTO actual antes de homologar la transición compatible.

### 11.1 Propuesta exacta de homologación — no vigente hasta aceptación

Solicitar confirmación registrada a los owners concernidos con este alcance:

1. **G4 (Retail):** ratificar formalmente que el backend/servicio de Retail es el invocador directo de la ruta G6 publicada, luego de la venta offline y según la secuencia que G4 publique; retirar o corregir en su contrato la prohibición actual y la asignación de esa conciliación a Ventas. Confirmar la identidad estable de la venta (incluida la relación entre `ventaLocalUuid`, `offline_sale_id`, `order_id` y `operation_id`, sin declararlos equivalentes), la referencia pública de tienda ya disponible y la política/reintento de ventas con más de 72 horas.
2. **G5 (Ventas):** confirmar en sus fuentes normativas que el alta/sincronización del pedido Retail no dispara reserva, confirmación, liberación ni conciliación de stock; aclarar cómo se relaciona `pedidoId` con la conciliación directa de Retail, sin establecer un orden no documentado. La confirmación recibida el 14/10 se conserva como acuerdo externo comunicado, pendiente de propagación formal.
3. **G6 (Productos):** tras las respuestas, proponer cambio versionado del OpenAPI para permitir el consumidor homologado sin exponer ubicación interna, conservar DEC-F-013/014/015, definir respuesta minimizada para Retail y documentar compatibilidad/retirada del consumidor actual. Mantener el contrato ejecutable presente mientras no se complete esa homologación.
4. **G7 (Seguridad):** aprobar/registrar el scope existente `inventario:conciliar-offline` para audiencia `api-productos` y `client_id=modulo-retail`, y confirmar grant/provisión de credencial de servicio. G6 solo incorporará al consumidor la allowlist contractual después de esa confirmación; no se propone scope nuevo ni se atribuye concesión por el contrato.

**Desbloqueo:** habilitación directa solo después de respuestas formales G4/G5/G6 sobre actor, identidad, mapeo, secuencia, respuesta y transición de contrato; registro/concesión/provisión verificables G7; y pruebas consumer-provider y de autorización sobre una versión candidata identificada. Mientras tanto, `BLOQUEADO_ESPECÍFICO` aplica a la invocación Retail/contrato/grant. `IMPLEMENTAR_AHORA` aplica a invariantes autónomas de Inventario DEC-F-013; `IMPLEMENTAR_PARCIAL` a resolución/autorización interna de ubicación y minimización, aisladas del DTO público pendiente.
