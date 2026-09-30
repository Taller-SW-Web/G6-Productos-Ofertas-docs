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
GET /api/v1/inventario/disponibilidad
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
