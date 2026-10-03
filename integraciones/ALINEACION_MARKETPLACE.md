# Alineación Marketplace ↔ Productos y Ofertas

**Estado:** homologación contractual HTTP 0.5.0
**Fuente HTTP autoritativa:** [`../api/openapi.yaml`](../api/openapi.yaml)

## 1. Objetivo

Formalizar el contrato que el backend/BFF de Marketplace consume para explorar y comprar productos sin trasladar ownership de Catálogo, Pricing, Promociones o Inventario.

## 2. Frontera de integración

```text
Frontend Marketplace
→ backend/BFF Marketplace
→ API Gateway de Productos y Ofertas
→ servicio owner
```

El frontend de Marketplace no consume directamente `api-productos`.

## 3. Identidades

```text
product_id != variant_id != sku
```

`sku` es la identidad comercial para:

```text
precio
disponibilidad
carrito
pedido
venta
inventario
```

Para productos con variantes, `variant_id` identifica la variante pero no sustituye su SKU.

## 4. Catálogo

Marketplace consume:

```text
GET /api/v1/productos?canal=MARKETPLACE
GET /api/v1/productos/por-slug/{slug}?canal=MARKETPLACE
```

Las lecturas comerciales solo exponen productos:

```text
ACTIVO
+
elegibles para MARKETPLACE
```

El ordenamiento contractual publicado inicialmente se limita a:

```text
NOMBRE_ASC
NOMBRE_DESC
```

El orden por precio queda fuera mientras no exista una regla product-level para productos con múltiples SKU/overrides.

Las respuestas de canal utilizan una proyección comercial segura y no exponen flags administrativos como:

```text
catalog_version
pricing_preparado
inventario_inicializado
perfil_fisico
physical_profile
```

## 5. Precio

```text
GET /api/v1/precios/skus/{sku}
scope: precios:leer
```

El precio se resuelve por SKU, canal e instante según el contrato vigente.

## 6. Disponibilidad

Marketplace consume la proyección:

```text
GET /api/v1/inventario/disponibilidad/comercial
scope: inventario:disponibilidad:leer
```

Respuesta mínima:

```text
sku
status ∈ {DISPONIBLE, STOCK_BAJO, AGOTADO}
```

No se exponen cantidades internas ni desglose por ubicación.

**Estado:** provisional mientras `D-INV-01` siga abierta, porque el saldo autoritativo existe por `(sku, location_id)` y todavía no se ha definido la reducción multiubicación a un único estado comercial.

## 7. Cupones y promociones

Marketplace puede consumir:

```text
GET  /api/v1/promociones
POST /api/v1/promociones/evaluar
POST /api/v1/cupones/validar
```

Un cupón no aplicable puede continuar como resultado de negocio HTTP 200 cuando así lo define OpenAPI.

## 8. Recomendaciones

```text
GET /api/v1/recomendaciones?productoId={id}&canal=MARKETPLACE
scope: recomendaciones:leer
```

Consumidores autorizados de la capacidad:

```text
Marketplace
Chatbot
Retail
```

La recomendación permanece a nivel `product_id`.

`availability` reutiliza `EstadoStock`. El enriquecimiento `availability/current_price` se considera provisional mientras `D-REC-01` y `D-REC-02` sigan abiertas.

## 9. Correlación

El header canónico de Productos y Ofertas es:

```text
X-Correlation-Id
```

Si Marketplace usa internamente `X-Request-Id`, su BFF lo adapta/propaga hacia `X-Correlation-Id`.

## 10. Rate limiting

Las operaciones externas pueden responder:

```text
429 RATE_LIMIT_EXCEDIDO
Retry-After
```

No existe una cuota numérica universal fijada en este acuerdo.

## 11. Seguridad prevista

Audiencia:

```text
api-productos
```

Scopes previstos para `modulo-marketplace`:

```text
catalogo:leer
precios:leer
promociones:leer
promociones:evaluar
cupones:validar
recomendaciones:leer
inventario:disponibilidad:leer
```

El registro efectivo de grants depende del módulo de Seguridad.

## 12. Casos contractuales mínimos

- `CT-MKT-01`: producto activo/elegible aparece.
- `CT-MKT-02`: producto no elegible no aparece.
- `CT-MKT-03`: página vacía responde 200 + lista vacía.
- `CT-MKT-04/05`: detalle por slug elegible/no elegible.
- `CT-MKT-06`: `variant_id != sku`.
- `CT-MKT-07/08`: precio regular/oferta.
- `CT-MKT-09`: SKU agotado responde `AGOTADO`, no 404.
- `CT-MKT-10`: cupón inválido/no aplicable.
- `CT-MKT-11`: recomendaciones autorizadas.
- `CT-MKT-12`: no administrative data leakage.
- `CT-MKT-13`: correlación.

La homologación no se considera cerrada runtime hasta que las pruebas aplicables cuenten con evidencia reproducible.
