# Alineación Retail ↔ Productos y Ofertas — Código de barras → SKU

**Estado:** homologación contractual HTTP 0.5.0
**Fuente HTTP autoritativa:** [`../api/openapi.yaml`](../api/openapi.yaml)

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
```

y no expone saldos internos. Esta proyección sigue provisional mientras `D-INV-01` esté abierta.

## 10. Casos contractuales mínimos

- `CT-RTL-BAR-01`: simple → `sku_base`.
- `CT-RTL-BAR-02`: variante → SKU de variante.
- `CT-RTL-BAR-03`: inexistente → 404.
- `CT-RTL-BAR-04`: preserva ceros a la izquierda.
- `CT-RTL-BAR-05`: asociación no vendible no filtra motivo.
- `CT-RTL-BAR-06`: response mínimo solo necesita SKU.
- `CT-RTL-BAR-07`: allowlist exclusiva de Retail.
- `IT-RTL-BAR-01`: un código no resuelve a dos SKU.
- `IT-RTL-BAR-02`: después de resolver, Pricing/Inventario usan SKU.
