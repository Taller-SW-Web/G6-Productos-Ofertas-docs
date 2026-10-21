# Kit de integración — Productos y Ofertas

**Fecha de actualización:** 2026-10-14

**Repositorio:** `Taller-SW-Web/G6-Productos-Ofertas-docs`
**API propietaria:** `api-productos`  
**Contrato HTTP canónico:** `openapi.yaml`
**Contrato de integración:** `Contrato_Api.md`  
**Contrato asíncrono:** `../eventos/asyncapi.yaml`
**Catálogo de errores:** `catalogo-errores.md`

**Catálogo de eventos:** `../eventos/catalogo-eventos.md`

> Este documento es una guía práctica para integrar otros módulos con Productos y Ofertas.  
> Si existe una contradicción, prevalecen `openapi.yaml` para HTTP y `../eventos/asyncapi.yaml` para mensajería.

---

# 1. Qué ofrece Productos y Ofertas

Productos y Ofertas es owner de:

- catálogo de productos, variantes y SKU;
- categorías, marcas, tipos y características;
- precios;
- promociones;
- cupones;
- recomendaciones;
- combos;
- inventario;
- peso y dimensiones físicas propias del SKU.

No es owner de:

- usuarios, credenciales o roles;
- pedidos y pagos;
- reembolsos y anulaciones comerciales;
- empaque, rutas o entregas.

Los módulos consumidores nunca deben leer directamente las tablas internas de Productos y Ofertas.

---

# 2. Base de la API

Todas las rutas HTTP pertenecen a:

```text
/api/v1
```

El host depende del entorno.

Ejemplo conceptual:

```text
{PRO}/api/v1/productos
```

**Versión documental de referencia:** `0.6.0-rc.1` (contrato candidato OpenAPI/AsyncAPI, aún no acreditado como backend desplegado o integración E2E). Las reglas anteriores no modificadas conservan `0.5.0` como baseline de compatibilidad; su mención histórica no reemplaza los contratos candidatos.

---

# 3. Autenticación

Productos y Ofertas acepta dos tipos de JWT emitidos por Seguridad y Usuarios.

## 3.1. JWT de usuario

Se utiliza para operaciones administrativas humanas.

La validación ordinaria se realiza localmente mediante JWKS.

Endpoints publicados por Seguridad:

```http
GET /api/v1/auth/.well-known/openid-configuration
GET /api/v1/auth/.well-known/jwks.json
```

El rol global oficial utilizado por este módulo es:

```text
GESTOR_COMERCIAL
```

Seguridad lo define como el perfil que administra:

```text
catálogo
precios
promociones
```

El rol viaja en:

```text
roles
```

No en `scope`.

## 3.2. JWT de servicio

Se utiliza para comunicación módulo-a-módulo.

El token debe ser emitido por Seguridad y contener, como mínimo:

```text
iss
sub = client_id del módulo consumidor
aud contiene api-productos
tipo = servicio
exp vigente
scope requerido por la operación
```

Los scopes viajan en el claim:

```text
scope
```

separados por espacios.

Productos y Ofertas responde:

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

No se debe depender del texto de `detail` para tomar decisiones.

---

# 4. Cómo pedir un token técnico

Los módulos obtienen tokens desde Seguridad:

```http
POST /api/v1/auth/token
Content-Type: application/x-www-form-urlencoded
```

Ejemplo conceptual:

```text
grant_type=client_credentials
client_id=modulo-chatbot
client_secret=<secreto>
scope=inventario:disponibilidad:leer
```

Los secretos reales no deben almacenarse en este repositorio.

Para scopes pertenecientes a `api-productos`, Seguridad debe registrar previamente:

```text
cliente
scope
API propietaria = api-productos
```

Un consumidor no debe inventar un scope que Productos y Ofertas no haya publicado.

---

# 5. Scopes propios de `api-productos`

La línea base conserva **16 scopes** de `api-productos`; la candidata `0.6.0-rc.1` incorpora como propuesta contractual adicional `inventario:operaciones:leer` para `modulo-ventas`. **G7 todavía debe registrar y conceder este scope**. No se considera parte de los 16 scopes heredados ni un permiso ya aprovisionado.

| Scope | Operación principal | `client_id` previsto |
|---|---|---|
| `catalogo:leer` | Catálogo/categorías/marcas | Marketplace, Chatbot, Retail |
| `precios:leer` | Precio | Marketplace, Chatbot, Retail |
| `promociones:leer` | Promociones | Marketplace, Chatbot, Retail |
| `promociones:evaluar` | Evaluación | Marketplace, Chatbot, Retail |
| `cupones:validar` | Cupón | Marketplace, Chatbot, Retail |
| `recomendaciones:leer` | Recomendaciones | Chatbot |
| `combos:leer` | Combos | Sin grant externo inicial |
| `inventario:disponibilidad:leer` | Disponibilidad detallada y comercial según allowlist | Marketplace, Chatbot, Retail, Ventas, Postventa |
| `inventario:reservar` | Reserva | Ventas |
| `inventario:consumir` | Consumo | Ventas |
| `inventario:liberar` | Liberación | Ventas |
| `inventario:reintegrar` | Reintegro físico | M2/Postventa (F3), M1/Ventas (otros motivos contractuales) |
| `inventario:conciliar-offline` | Conciliación de venta Retail offline; OpenAPI vigente solo permite `modulo-ventas` | Ventas (contrato actual); Retail propuesto por homologar |
| `inventario:incidencias:reportar` | Cuarentena física | Retail |
| `inventario:incidencias:resolver` | Resolver incidencia/acta | Retail |
| `productos:fisicos:leer` | Peso/dimensiones | Despacho |

**Límite de autorización de Retail:** `modulo-retail` no está autorizado por el contrato vigente para reservar, consumir, liberar ni reintegrar stock; esas operaciones no incluyen Retail en sus allowlists. Solo está pendiente de homologación su posible invocación directa de `POST /api/v1/inventario/conciliaciones-offline`. El acuerdo G5–G4 que registra esa llamada no concede permiso ni modifica el OpenAPI. `inventario:disponibilidad:leer` permite consultas de disponibilidad según allowlist y no autoriza conciliación. G7 debe confirmar registro, aprobación, grant y credenciales de servicio para la operación/consumidor que se acuerden.

**Scope adicional candidato:** `inventario:operaciones:leer` — consulta durable `GET /api/v1/inventario/operaciones/{operationId}`, exclusiva para el cliente de servicio `modulo-ventas`. OpenAPI `0.6.0-rc.1` registra `x-scope-registration-status: pending-security-registration`; su utilización efectiva requiere concesión explícita de G7.

**El scope compartido de disponibilidad no concede acceso indistinto a todas las representaciones.** `GET /api/v1/inventario/disponibilidad` devuelve saldo detallado y su allowlist de clientes de servicio contiene `modulo-ventas` y `modulo-postventa`. M2 lo usa de forma informativa para CAMBIO; la consulta no reserva ni garantiza stock futuro. En cambio, `GET /api/v1/inventario/disponibilidad/comercial` y `POST /api/v1/inventario/disponibilidad/comercial/verificar` tienen allowlist de servicio para `modulo-marketplace`, `modulo-chatbot` y `modulo-retail`. Comparten el scope `inventario:disponibilidad:leer`, pero no el acceso a cantidades ni ubicaciones internas. La lectura detallada administrativa mediante JWT de usuario conserva su autorización humana correspondiente. El proveedor debe comprobar audiencia, scope y cliente admitido en la operación; un token de canal con el scope correcto no autoriza el endpoint detallado.

Todo endpoint técnico valida:

```text
tipo = servicio
iss válido
aud contiene api-productos
exp vigente
sub autorizado por la operación
scope contiene x-required-scope
client_id del servicio está incluido en x-allowed-client-ids, cuando corresponda
```

El estado sigue siendo:

```text
pending-security-registration
```

hasta que Seguridad registre formalmente los scopes/grants. Esto no bloquea mocks, CI ni implementación interna.

## 5.1. Contrato mínimo de inventario para G5

El alcance documentado con M1/Ventas para pedidos web es:

1. Al crear un pedido, M1 solicita `POST /api/v1/inventario/reservas`. HTTP `202 Accepted` confirma admisión del comando; no confirma stock reservado.
2. Al pasar el pedido a `PAGADO`, M1 solicita la confirmación de consumo sobre la reserva. Ante `PAGO_NO_COMPLETADO` o una anulación que aplique antes del consumo, solicita liberación.
3. M1 consume los resultados tipados de reserva (`inventory.reservation.created` o `inventory.reservation.rejected`), consumo y liberación publicados por RabbitMQ conforme a AsyncAPI. La topología documenta exchanges durables, colas quorum, ACK manual, publisher confirms y entrega at-least-once; son requisitos de diseño y no acreditan que el broker de un entorno esté disponible.
4. El contrato candidato G6 ofrece `GET /api/v1/inventario/operaciones/{operationId}` para recuperar el resultado persistido de una operación aceptada. Su consumo por M1 es parte de la preparación técnica, pero la documentación G5 consultada no registra aceptación explícita de esta consulta. La ruta es exclusiva de `modulo-ventas`; `inventario:operaciones:leer` está pendiente de registro/concesión de G7. `operation_id` es UUID y no sustituye `order_id` opaco.
5. Postventa solicita el reintegro físico por `POST /api/v1/inventario/reintegros` tras recepción física confirmada y aptitud; es una mutación HTTP síncrona con respuesta `200 COMPLETED`, distinta de liberar una reserva. Requiere `location_id` resuelto y autorización efectiva. Para restaurar cupón ante anulación aplicable después del consumo, el flujo de Promociones usa el comando/evento de restauración definido en AsyncAPI, correlacionado con el consumo original. El acuerdo F3 no autoriza reserva/consumo de reemplazo por M2.

### Estado de disponibilidad por capa

| Capa | Evidencia actual | Estado / comprobación requerida |
|---|---|---|
| Protocolo/broker | AsyncAPI candidata `0.6.0-rc.3` y [topología](../eventos/rabbitmq-topologia.md) declaran `g6-productos-ofertas` en el servidor y `x-vhost` | La candidata anterior `0.6.0-rc.2` usa el mismo vhost; `rc.3` reconcilia exchanges/colas con la observación Oracle del 2026-10-19. La observación no acredita estado actual, homologación G5, despliegue ni conexión; la aceptación de nombres y la red siguen pendientes |
| Broker disponible | La documentación especifica protocolo y topología deseada | Disponibilidad, DNS/red, autenticación y acceso al broker real: sin verificar; requiere evidencia operativa de Infraestructura |
| Exchanges, colas y bindings | AsyncAPI `0.6.0-rc.3` y su matriz documentan nombres base observados y bindings contractuales | Hay 57 bindings en el reporte, pero la correspondencia individual sigue `PENDIENTE_VERIFICACION`; el código y runtime no están acreditados |
| Implementación G6 | HTTP, eventos y consulta durable están especificados | Productores/consumidores NestJS, Outbox/Inbox y persistencia de resultado no quedan acreditados por YAML ni docs; requieren evidencia de código y prueba |
| Permisos G7 | Scopes y allowlists declarados por operación | Grants/provisión de `inventario:reservar`, `inventario:consumir`, `inventario:liberar`, `inventario:operaciones:leer` y `inventario:reintegrar` requieren evidencia G7 por consumidor; no se deducen de nombres contractuales |
| Prueba integrada G5↔G6 | G5 documenta consumo directo del broker; AsyncAPI define eventos y resultados | Prueba reproducible con commits/versions de productor G6, consumidor G5 y entorno broker aún no disponible |
| Despliegue | OpenAPI identifica `0.6.0-rc.1`; AsyncAPI `0.6.0-rc.3` es candidata | Despliegue operativo y transición de consumidores requieren evidencia de versión/entorno, compatibilidad y pruebas reproducibles; la candidata no es runtime |

Para Retail offline, G5 confirmó el 2026-10-14 que Retail invoca directamente `POST /api/v1/inventario/conciliaciones-offline` y que M1 no reserva, confirma ni concilia inventario Retail. Retail no está autorizado para reservar, consumir, liberar ni reintegrar. El permiso de disponibilidad comercial no autoriza conciliaciones. La ruta del OpenAPI vigente solo permite `modulo-ventas`, exige `location_id` en cada línea y devuelve ubicación/saldos internos. G4 v0.4 aún prohíbe esa llamada directa. Se conserva como `ACUERDO_EXTERNO_DOCUMENTADO` de G5, no como homologación bilateral ni permiso. G7 debe confirmar registro, aprobación, grant y credenciales de servicio; su estado no se infiere del acuerdo G5–G4. La propuesta y los responsables de homologación constan en [ALINEACION_RETAIL](../../integraciones/ALINEACION_RETAIL.md). No cambies la llamada al contrato hasta que G4/G5/G6 acuerden actor, identidad, referencia pública de tienda, secuencia, DTO minimizado y transición.

## 5.2. Matriz congelada por consumidor

```text
modulo-marketplace:
  catalogo:leer precios:leer promociones:leer promociones:evaluar
  cupones:validar inventario:disponibilidad:leer

modulo-chatbot:
  catalogo:leer precios:leer promociones:leer promociones:evaluar
  cupones:validar recomendaciones:leer inventario:disponibilidad:leer

modulo-retail:
  catalogo:leer precios:leer promociones:leer promociones:evaluar
  cupones:validar inventario:disponibilidad:leer
  inventario:incidencias:reportar inventario:incidencias:resolver

modulo-ventas:
  inventario:disponibilidad:leer inventario:reservar inventario:consumir
  inventario:liberar inventario:reintegrar inventario:conciliar-offline

modulo-postventa:
  inventario:disponibilidad:leer inventario:reintegrar

modulo-despacho:
  productos:fisicos:leer
```

**Extensión candidata de la matriz (sin concesión efectiva):** `modulo-ventas` podrá utilizar `inventario:operaciones:leer` solo cuando G7 registre y otorgue el permiso para `api-productos`. No corresponde a Marketplace, Chatbot ni Retail, y su documentación no prueba que la API ya esté activa.

Los scopes enumerados para `modulo-postventa` (`inventario:disponibilidad:leer` e `inventario:reintegrar`) están sujetos a registro y concesión de G7 (`pending-security-registration`); la matriz no afirma grants efectivos.

# 6. Integración de canales — Marketplace, Chatbot y Retail

Los canales consumen información comercial y disponibilidad.

No reservan, consumen ni liberan stock directamente.

## 6.1. Buscar productos

```http
GET /api/v1/productos
```

Para consumo técnico:

```text
catalogo:leer
```

Parámetros publicados:

```text
q
categoriaId
marcaId
canal
pagina
tamanio
estado
precioMin
precioMax
```

Ejemplo:

```http
GET /api/v1/productos?q=zapatillas&marcaId=ADIDAS&canal=CHATBOT&pagina=1&tamanio=20
```

El parámetro `estado` está descrito como filtro de backoffice/usuario autorizado; una identidad de canal no debe usarlo para ampliar visibilidad. El proveedor conserva la regla de productos activos y elegibles por canal.

La respuesta es paginada mediante:

```text
items
pagina
tamanio
total
```

## 6.2. Obtener detalle

```http
GET /api/v1/productos/{productoId}
```

Para consumo técnico:

```text
catalogo:leer
```

El detalle incluye:

- datos del producto;
- atributos;
- imágenes;
- variantes;
- SKU correspondientes.

## 6.3. Categorías y marcas

```http
GET /api/v1/categorias
GET /api/v1/marcas
```

Para consumo técnico:

```text
catalogo:leer
```

Son las fuentes autoritativas para normalizar filtros de canal.

## 6.4. Consultar precios

```http
GET /api/v1/precios?skus=SKU-001,SKU-002&canal=CHATBOT
```

Para consumo técnico:

```text
precios:leer
```

`skus` es obligatorio.

`canal` es opcional.

También puede utilizarse:

```text
at=<timestamp>
```

para resolución temporal cuando corresponda.

Campos relevantes por precio:

```text
sku
precio_regular
precio_oferta
currency
channel_id
valid_from
valid_until
price_version
vigencia_id
origen
```

`channel_id = null` representa alcance global.

## 6.5. Consultar disponibilidad

```http
GET /api/v1/inventario/disponibilidad/comercial?skus=SKU-001,SKU-002&canal=MARKETPLACE
Authorization: Bearer <token-servicio>
```

Scope:

```text
inventario:disponibilidad:leer
```

Audiencia:

```text
api-productos
```

Puede enviarse opcionalmente:

```text
location_id
```

Cada resultado contiene:

```text
sku
location_id
on_hand
reserved
blocked
available
status
threshold
```

Estados:

```text
AGOTADO
STOCK_BAJO
DISPONIBLE
```

La consulta:

- no crea reserva;
- no garantiza stock futuro;
- no autoriza al canal a mutar Inventario.

## 6.6. Consultar promociones

```http
GET /api/v1/promociones?canal=CHATBOT&vigentes=true
```

Para consumo técnico:

```text
promociones:leer
```

`canal` es obligatorio.

## 6.7. Evaluar promociones

```http
POST /api/v1/promociones/evaluar
Content-Type: application/json
```

Para consumo técnico:

```text
promociones:evaluar
```

Request:

```json
{
  "channel_id": "CHATBOT",
  "lines": [
    {
      "sku": "SKU-001",
      "quantity": 2
    }
  ],
  "coupon_code": null,
  "customer_ref": null
}
```

Respuesta conceptual:

```json
{
  "promotion_id": "PROM-001",
  "original_amount": 300.00,
  "discount_amount": 30.00,
  "result_amount": 270.00,
  "currency": "PEN",
  "reason": null
}
```

## 6.8. Validar cupón

```http
POST /api/v1/cupones/validar
```

Para consumo técnico:

```text
cupones:validar
```

Request:

```json
{
  "coupon_code": "RUN10",
  "customer_ref": null,
  "channel_id": "CHATBOT",
  "lines": [
    {
      "sku": "SKU-001",
      "quantity": 1
    }
  ]
}
```

Validar un cupón:

```text
NO consume el cupón
```

La respuesta usa:

```text
valid
rejection_reason
benefit
discount_amount
result_amount
currency
code
```

Cuando:

```text
valid = false
```

el consumidor debe ramificar por:

```text
code
```

no por `rejection_reason`.

## 6.9. Obtener recomendaciones

Ruta canónica:

```http
GET /api/v1/recomendaciones?productoId={productoId}&canal=CHATBOT
```

Para consumo técnico:

```text
recomendaciones:leer
```

No usar:

```text
/recomendaciones/candidatos
```

como ruta contractual.


## 6.10. Consultar combos

```http
GET /api/v1/combos/{comboId}
GET /api/v1/combos/{comboId}/disponibilidad
```

Para consumo técnico:

```text
combos:leer
```

La disponibilidad de un combo es informativa y no crea una reserva de sus componentes.

---

## 6.11. Primer corte Marketplace ↔ Productos y Ofertas (G1–G6)

Esta guía separa la API interna de G6 del contrato público del BFF G1. OpenAPI gobierna las rutas, parámetros, esquemas de seguridad, respuestas y schemas G6. Las menciones al BFF describen su adaptación y no amplían el contrato G6.

### Frontera y host

```text
Frontend Marketplace → Backend/BFF Marketplace → Gateway G6 → servicio owner
```

El navegador llama al BFF; el BFF obtiene/usa el JWT de servicio para G6. No expone `client_secret`, token de servicio ni otras credenciales al navegador. OpenAPI declara `servers.url: /api/v1`, una base relativa. Al combinarla con los paths se obtienen las rutas completas siguientes; no se ha acreditado aquí un host absoluto por ambiente.

### Rutas del corte y schemas

| Alcance | Solicitud completa | operationId | Respuesta 200 G6 |
|---|---|---|---|
| Obligatoria | `GET /api/v1/categorias` | `listarCategorias` | Objeto `{"categories":[...]}` con elementos `Categoria`. El campo `status` está definido y admite `ACTIVA`/`INACTIVA`; el contrato de esta operación declara categorías activas. El proveedor debe validar ese filtro. |
| Obligatoria | `GET /api/v1/productos?canal=MARKETPLACE&q={texto}&pagina={n}&tamanio={n}` | `listarProductos` | `PaginaProductosComercial`: `items`, `pagina`, `tamanio`, `total`; los elementos son `ProductoResumenComercial`. |
| Condicional | `GET /api/v1/productos/por-slug/{slug}?canal=MARKETPLACE` | `obtenerProductoPorSlug` | `ProductoDetalleComercial`, compuesto por `ProductoResumenComercial`, `marca` y `variants` de tipo `VarianteComercial`. |

Para solicitudes módulo-a-módulo, `canal=MARKETPLACE` se incluye en listado y detalle. El schema del parámetro `canal` en listado no marca `required: true`, pero su descripción lo exige semánticamente para consumidores de canal. En detalle tanto `slug` como `canal` están marcados obligatorios. `q` es opcional en G6; F-007 lo exige en el BFF y valida entre 2 y 120 caracteres antes de reenviar. No trasladar ese límite a OpenAPI G6.

### Paginación y adaptación del BFF

G1 valida `page >= 0` y `1 <= pageSize <= 48`. F-007 ejemplifica `pageSize=24`; no es el default del proveedor. G6 usa `pagina >= 1`, `tamanio` entre 1 y 100, con defaults publicados 1 y 20. El adaptador transforma:

```text
pagina = page + 1
tamanio = pageSize
```

Por tanto, G1 `page=0&pageSize=24` consulta G6 `pagina=1&tamanio=24`; G1 `page=1&pageSize=24` consulta G6 `pagina=2&tamanio=24`. G6 responde `items/pagina/tamanio/total`; el BFF publica su propio `data` y metadatos `page` conforme a F-007/F-010. Si necesita `totalPages`, se deriva de `total` y del tamaño efectivo; no se exige ese campo a G6. Sin coincidencias conserva el `200` y `items: []`, nunca convierte automáticamente la página vacía en 404.

### Ejemplos contractuales reproducibles

Las solicitudes siguientes son plantillas. `<HOST-VERIFICADO>` y `<JWT-SERVICIO>` son placeholders; no son URL, credencial ni evidencia de llamada realizada. La ruta condicional puede omitirse si G1 no la necesita en el gate inicial.

Categorías:

```http
GET <HOST-VERIFICADO>/api/v1/categorias
Authorization: Bearer <JWT-SERVICIO>
X-Correlation-Id: 3fa85f64-5717-4562-b3fc-2c963f66afa6
```

Resultado esperado: `200 application/json` con `{ "categories": [...] }`; el arreglo puede estar vacío. Una fixture documental válida podría incluir `{"categoria_id":"CAT-FIXTURE-01","parent_id":null,"name":"Calzado","status":"ACTIVA"}`. Es una fixture ilustrativa, no dato productivo. Provider debe confirmar que no se devuelvan categorías inactivas.

Búsqueda y página vacía:

```http
GET <HOST-VERIFICADO>/api/v1/productos?canal=MARKETPLACE&q=zapatillas&pagina=1&tamanio=24
Authorization: Bearer <JWT-SERVICIO>
X-Correlation-Id: 3fa85f64-5717-4562-b3fc-2c963f66afa6
```

Resultado esperado: `200 application/json` conforme a `PaginaProductosComercial`; una respuesta sin coincidencias usa `{"items":[],"pagina":1,"tamanio":24,"total":0}`. Producto activo no elegible no debe aparecer. `estado` no es un mecanismo para ampliar visibilidad.

Detalle condicional:

```http
GET <HOST-VERIFICADO>/api/v1/productos/por-slug/zapatillas-demo?canal=MARKETPLACE
Authorization: Bearer <JWT-SERVICIO>
X-Correlation-Id: 3fa85f64-5717-4562-b3fc-2c963f66afa6
```

Resultado esperado: `200` según `ProductoDetalleComercial`; slug inexistente/no elegible usa `404` y `Problem.code=PRODUCTO_NO_ENCONTRADO`. En producto simple validar `sku_base` según el caso funcional aunque OpenAPI lo permite `null` y no lo requiere a todo producto. Para producto con variantes validar identidad separada `variant_id`/`sku` y elegibilidad. `VarianteComercial` no declara `status`. Los ejemplos de detalle con IDs ficticios deben tratarse como fixtures, nunca como observaciones de datos productivos.

### Seguridad, errores y correlación

Para estas operaciones OpenAPI `0.6.0-rc.1` declara `client_id=modulo-marketplace` en las allowlists, `x-required-scope: catalogo:leer`, `x-service-audience: api-productos` y `x-scope-registration-status: pending-security-registration`. G7 debe registrar y conceder el grant; el YAML no prueba autorización efectiva.

- `listarCategorias` admite `serviceBearer`.
- `listarProductos` declara `serviceBearer` y `userBearer` como alternativas del security requirement. Un llamado BFF usa el token de servicio; no se le exigen claims humanos del esquema de usuario.
- `obtenerProductoPorSlug` conserva ambas alternativas publicadas (`serviceBearer` y `userBearer`). El BFF usa el JWT técnico para su llamada módulo-a-módulo; no se infieren claims humanos para ese token.
- `X-Correlation-Id` es header UUID opcional en OpenAPI G6. Si el BFF entrega un `X-Request-Id` con UUID válido, el adaptador puede copiar ese valor sin cambios a `X-Correlation-Id` en la llamada a G6 para conservar la correlación; si no hay UUID disponible, puede omitir el header, pues G6 no lo exige. La transformación no cambia el contrato público del BFF ni vuelve obligatorio el header de G6.
- Las respuestas G6 incluyen `401 TOKEN_INVALIDO`, `403 SCOPE_INSUFICIENTE` y `503 SERVICIO_NO_DISPONIBLE`. El detalle puede además responder `404 PRODUCTO_NO_ENCONTRADO`. Las operaciones declaran `429 RATE_LIMIT_EXCEDIDO` con header `Retry-After`.
- F-007/F-010 documentan códigos públicos BFF como `INVALID_SEARCH_QUERY`, `INVALID_PAGE` y `CATALOG_UNAVAILABLE`. No son automáticamente equivalentes a los códigos G6; la traducción pertenece al contrato/implementación G1 y requiere su propia validación.

### Tipos y límites de evidencia

Una fixture documental muestra la forma de un ejemplo; una aserción `STATIC_CONTRACT` verifica propiedades estructuradas del YAML. Ninguna de las dos acredita comportamiento Provider, autorización real, llamada HTTP desde G1 ni E2E. Esos resultados requieren pruebas `PROVIDER_CONTRACT`/`CONSUMER_PROVIDER`/integradas reproducibles sobre versiones y entornos identificados.

Los schemas comerciales declaran las propiedades publicadas, no necesariamente `additionalProperties: false`. La revisión estática puede comprobar que campos como `pricing_preparado`, `inventario_inicializado`, `perfil_fisico`, saldos o ubicaciones no forman parte de sus `properties`; solo una prueba provider puede comprobar filtrado efectivo ante datos de origen.

### Dependencias y límites abiertos

- OpenAPI no acredita URL pública del proveedor, credenciales, grant efectivo de G7, handlers implementados, despliegue ni pruebas BFF→G6.
- F-006 espera `slug` e imagen en tarjetas de categoría; G6 `Categoria` no garantiza esos campos. No inventarlos ni declarar resuelta la composición de tarjetas mediante `listarCategorias` solamente.
- F-011 define un DTO BFF público distinto de `ProductoDetalleComercial`. Su transformación, incluidas marca, galería y especificaciones, debe probarse por separado; este kit no la declara homologada ni probada.
- El primer corte excluye Pricing, Inventario, promociones, cupones, checkout, pago y recomendaciones. Las pruebas históricas correspondientes se conservan en la matriz sin atribuirles implementación de esta entrega.

La matriz y estados de prueba están en [pruebas-contrato.md](../pruebas/pruebas-contrato.md).

---

# 7. Integración de Ventas/Postventa con Inventario

## 7.1. Pedido `CREADO` — reserva

```http
POST /api/v1/inventario/reservas
scope: inventario:reservar
```

Respuesta: `202 Accepted`. Ventas espera el resultado asíncrono antes de tratar la reserva como confirmada.

## 7.2. Pedido `PAGADO` — consumo

```http
POST /api/v1/inventario/reservas/{reservaId}/confirmar
scope: inventario:consumir
```

Respuesta: `202 Accepted`.

## 7.3. Pago no completado/anulación pre-consumo — liberación

```http
POST /api/v1/inventario/reservas/{reservaId}/liberar
scope: inventario:liberar
```

Nunca se libera una reserva `CONSUMIDA`.

## 7.4. Devolución/retorno físicamente reintegrable

```http
POST /api/v1/inventario/reintegros
scope: inventario:reintegrar
client_id: modulo-postventa
```

M2/Postventa invoca directamente F3 solo después de confirmar recepción física y aptitud de las unidades. Usa `items[].sku` del pedido original de Ventas y el payload canónico; `location_id` sigue pendiente de definición. Reintentos idénticos reutilizan identidad y payload; cada nueva recepción parcial lleva otro `operation_id`. La allowlist conserva `modulo-ventas` para otros motivos contractuales.

Respuesta contractual exitosa: `200` con `status: COMPLETED`. El grant efectivo de G7 está pendiente.

## 7.5. Venta Retail offline

Retail sincroniza primero la venta con Ventas. Luego Ventas invoca:

```http
POST /api/v1/inventario/conciliaciones-offline
scope: inventario:conciliar-offline
```

Respuesta:

```text
COMPLETED
REQUIRES_REVIEW
```

`REQUIRES_REVIEW` contiene cantidades no conciliadas y nunca implica saldo negativo.

### Alcance y pendientes de homologación

La secuencia documentada actualmente por G6 es: Retail realiza la venta física offline, la sincroniza con Ventas/Postventa y `modulo-ventas` invoca Inventario. La alternativa Retail→G6 directo sigue pendiente de homologación; esta descripción no fija un nuevo orden entre venta, pedido, pago y conciliación.

DEC-F-013 establece que Inventario conserva la autoridad del stock central y concilia solo cantidades admisibles, sin reserva retroactiva, saldo negativo ni consumo de unidades reservadas o bloqueadas. Una conciliación parcial conserva las cantidades solicitadas, aplicadas y no resueltas. Si `applied_quantity=0`, el resultado puede quedar registrado sin generar movimiento Kardex de cantidad cero. Un replay semánticamente idéntico devuelve el resultado anterior sin nuevos efectos; reutilizar la identidad con contenido diferente produce `409 IDEMPOTENCY_CONFLICT`.

La identidad estable de la venta física, su ámbito de unicidad y su correspondencia con `ventaLocalUuid`, `offline_sale_id`, `operation_id` y `order_id` siguen pendientes de homologación. Esas referencias no se consideran equivalentes ni definen por sí solas la deduplicación entre reintentos técnicos.

DEC-F-014 requiere que Inventario resuelva y autorice internamente la ubicación antes de mutar. Sin embargo, el request OpenAPI candidato todavía requiere `location_id` en cada línea; esta incompatibilidad contractual no se resuelve en esta guía. DEC-F-015 requiere minimizar la información destinada a Retail: el response candidato actual incluye cantidades funcionales, saldos y ubicación interna, y su consumidor contractual es `modulo-ventas`. No hay una representación mínima para Retail homologada.

El scope `inventario:conciliar-offline` sigue pendiente de registro y grant efectivo con G7. Esta guía no autoriza a Retail a invocar la conciliación: los permisos de disponibilidad no conceden permiso de conciliación. También siguen pendientes el tratamiento de ventas offline sincronizadas después del límite de 72 horas documentado por G5 y cualquier flujo de cupones offline sin reserva confirmada.

Referencias: [DEC-F-009 y DEC-F-013–015](../../arquitectura/decisiones/REGISTRO_DEC_F.md), [SPEC-015 §24.5](../../requisitos/specs/SPEC-015-control-stock-disponibilidad.md), [alineación Retail](../../integraciones/ALINEACION_RETAIL.md) y [alineación Ventas](../../integraciones/ALINEACION_VENTAS.md).

## 7.6. Regla de ownership

Ventas no actualiza tablas de Inventario. Inventario no decide pagos, reembolsos ni política comercial de devolución.

# 8. Resultados de Inventario

Reserva/consumo/liberación mantienen resultados asíncronos:

| Evento/resultado | Uso |
|---|---|
| `inventory.reservation.created` | reserva confirmada |
| `inventory.reservation.consumed` | reserva consumida |
| `inventory.reservation.released` | reserva liberada |
| `inventory.reservation.expired` | TTL |
| `inventory.consumption.completed` | consumo confirmado |
| `inventory.consumption.rejected` | rechazo posterior a `202` |

Incidencias, reintegros y conciliación offline son transacciones HTTP síncronas en `0.4.0`. Después del commit pueden producir `inventory.stock.changed`/`inventory.stock.adjusted`; no se introducen eventos nuevos obligatorios que dupliquen la respuesta HTTP.

# 9. Integración de Despacho

Despacho consulta los datos físicos vigentes del SKU.

Ruta canónica:

```http
POST /api/v1/productos/datos-fisicos/consulta
Authorization: Bearer <token-modulo-despacho>
```

Cliente autorizado:

```text
modulo-despacho
```

Scope:

```text
productos:fisicos:leer
```

Audiencia:

```text
api-productos
```

Request:

```json
{
  "skus": [
    "SKU-001",
    "SKU-002"
  ]
}
```

Máximo contractual:

```text
100 SKU por solicitud
```

Respuesta:

```json
{
  "productos": [
    {
      "sku": "SKU-001",
      "estado": "ACTIVO",
      "pesoKg": 0.25,
      "dimensionesCm": {
        "largo": 30,
        "ancho": 20,
        "alto": 10
      },
      "actualizadoEn": "2026-09-29T18:00:00Z"
    }
  ],
  "noEncontrados": [
    "SKU-002"
  ]
}
```

Productos y Ofertas entrega:

```text
pesoKg
largo
ancho
alto
```

Despacho calcula:

```text
volumenUnitarioM3
peso total
volumen total
peso volumétrico
empaque
capacidad logística
```

Productos y Ofertas no decide el empaque.

---

# 10. Administración humana

Las operaciones administrativas se realizan con JWT de usuario.

Rol global:

```text
GESTOR_COMERCIAL
```

Productos y Ofertas no espera que Seguridad publique permisos internos como:

```text
PRICING_READ
PRICING_WRITE
PRICING_BULK
PRICING_AUDIT_READ
PRICING_AUDIT_EXPORT
```

Si se conservan esos identificadores, son capacidades internas del módulo.

---

# 11. Pricing: consultas, programaciones e importación

`contratos/http/openapi.yaml` es la fuente de verdad HTTP. Esta sección resume la superficie de Pricing publicada en OpenAPI `0.5.0` y su política de autorización.

## 11.1. Consultas

Rutas estables para consumidores:

```http
GET /api/v1/precios
GET /api/v1/precios/skus/{sku}
```

Para llamadas módulo-a-módulo se utiliza:

```text
scope = precios:leer
aud = api-productos
```

La consulta por SKU admite `canal` y `at` para resolver precio vigente o histórico. La consulta múltiple también admite el contexto publicado por OpenAPI.

Consultas administrativas humanas:

```http
GET /api/v1/precios/productos/{productoId}
GET /api/v1/precios/skus/{sku}/programaciones
GET /api/v1/precios/productos/{productoId}/programaciones
GET /api/v1/precios/importaciones/{batchId}
GET /api/v1/precios/importaciones/{batchId}/reporte
```

Las rutas administrativas derivadas de SPEC-013 permanecen `provisional-internal`. Se validan mediante JWT de usuario y la vía ordinaria de JWKS.

En `0.4.0`, `GET /precios/productos/{productoId}` no publica el parámetro `at`; la resolución histórica por `at` pertenece a la consulta por SKU.

## 11.2. Prevalidación de importación

```http
POST /api/v1/precios/importaciones/prevalidar
```

La prevalidación:

```text
no modifica precios
no publica pricing.price.changed
devuelve valid, total_rows y errores por fila
```

Utiliza autenticación de usuario y validación ordinaria local; no es la admisión del lote.

## 11.3. Mutaciones sensibles

Las siguientes operaciones están marcadas en OpenAPI con:

```text
x-required-role = GESTOR_COMERCIAL
x-auth-validation = introspection
```

Rutas:

```http
PATCH /api/v1/precios/skus/{sku}
POST  /api/v1/precios/skus/{sku}/programaciones
PATCH /api/v1/precios/productos/{productoId}
POST  /api/v1/precios/productos/{productoId}/programaciones
POST  /api/v1/precios/importaciones
```

Antes de ejecutar o admitir la mutación, Productos y Ofertas consulta:

```http
POST /api/v1/auth/introspeccion
```

con su token técnico y:

```text
tokens:introspeccion
```

La respuesta debe confirmar que el JWT de usuario continúa activo. El actor humano debe conservar el rol global `GESTOR_COMERCIAL`.

`PRICING_READ`, `PRICING_WRITE` y `PRICING_BULK`, si se mantienen en código, son capacidades internas del módulo; no permisos externos pendientes de Seguridad.

## 11.4. Carga masiva exclusiva de Pricing

Flujo contractual:

```text
prevalidar archivo
-> confirmar admisión
-> 202 Accepted + batch_id + QUEUED
-> consultar estado
-> COMPLETED | PARTIAL | FAILED
-> descargar reporte
```

Rutas:

```http
POST /api/v1/precios/importaciones/prevalidar
POST /api/v1/precios/importaciones
GET  /api/v1/precios/importaciones/{batchId}
GET  /api/v1/precios/importaciones/{batchId}/reporte
```

`202 Accepted` confirma admisión, no éxito final.

Una fila rechazada no modifica el precio ni publica evento. Toda mutación confirmada persiste cambio + Outbox y, después del commit, publica:

```text
pricing.price.changed
```

Auditoría consume ese hecho; Pricing no escribe directamente `price-audit-svc`.

---

# 12. Errores HTTP

Todos los errores de Productos y Ofertas utilizan:

```http
Content-Type: application/problem+json
```

Formato:

```json
{
  "type": "/errores/stock-insuficiente",
  "title": "Stock insuficiente",
  "status": 409,
  "detail": "No existe disponibilidad suficiente.",
  "instance": "/api/v1/inventario/reservas",
  "code": "STOCK_INSUFICIENTE",
  "correlationId": "uuid",
  "details": {}
}
```

La lógica del consumidor debe utilizar:

```text
code
```

Nunca:

```text
title
detail
```

Reglas transversales:

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

Un resultado comercial negativo puede ser HTTP `200`.

Ejemplo:

```text
POST /cupones/validar
-> 200
-> valid=false
-> code=<código de no aplicabilidad>
```

---

# 13. Idempotencia y correlación

Las mutaciones externas de Inventario usan:

```http
Idempotency-Key: <valor-estable>
X-Correlation-Id: <uuid>
```

y un:

```text
operation_id
```

Regla:

```text
misma identidad idempotente
+
misma intención
=
retry legítimo sin repetir efectos
```

Si la misma identidad se reutiliza para otra intención:

```text
409 IDEMPOTENCY_CONFLICT
```

No interpretar un timeout HTTP como prueba de que la operación no ocurrió.

El consumidor debe consultar/correlacionar el resultado antes de generar una intención nueva.

---

# 14. Contratos que los consumidores NO deben asumir

Rutas externas detectadas que **no** son contrato:

```text
POST /api/v1/inventario/consumir
POST /api/v1/inventario/incrementar-stock
POST /api/v1/productos/inventario/ajuste-discrepancia
```

Equivalentes/contratos correctos:

```text
consumo de venta -> Ventas usa /inventario/reservas/{id}/confirmar
devolución física F3 apta -> Postventa usa /inventario/reintegros
incidencia/merma -> Retail usa /inventario/incidencias y /resolver
venta offline -> Ventas usa /inventario/conciliaciones-offline
```

No inferir permisos por similitud de nombres. Cada operación exige su scope exacto.

# 15. Regla especial para Retail

Retail puede consultar información comercial/disponibilidad y además:

```http
POST /api/v1/inventario/incidencias
POST /api/v1/inventario/incidencias/{incidenciaId}/resolver
```

Scopes:

```text
inventario:incidencias:reportar
inventario:incidencias:resolver
```

Retail no recibe scopes de reserva/consumo/liberación/reintegro/conciliación.

Saldo:

```text
available = max(on_hand - reserved - blocked, 0)
```

Una incidencia online debe registrarse centralmente para que la unidad deje de estar disponible también en Marketplace/Chatbot. En offline, Retail puede bloquear su UI local y sincronizar la incidencia al recuperar conexión.

# 16. Regla especial para Chatbot

A5/A6/A7 están cerrados.

## Productos

Usar:

```text
GET /productos
GET /productos/{productoId}
GET /categorias
GET /marcas
GET /precios
GET /inventario/disponibilidad/comercial?skus={SKU}&canal=CHATBOT
GET /promociones
POST /promociones/evaluar
POST /cupones/validar
GET /recomendaciones
```

No usar:

```text
GET /inventario/disponibilidad
GET /recomendaciones/candidatos
```

`/inventario/disponibilidad` expone saldos detallados y **no autoriza a `modulo-chatbot`**, aunque posea el scope `inventario:disponibilidad:leer`. Para consultar una cantidad determinada, Chatbot podrá utilizar `POST /api/v1/inventario/disponibilidad/comercial/verificar` con `channel_id=CHATBOT`, `fulfillment={mode, fulfillment_ref?}` y `lines=[{sku, quantity}]`. El resultado `SUFICIENTE`, `INSUFICIENTE` o `INDETERMINADO` es informativo (`binding=false`) y no reserva stock. Si el contexto de cumplimiento no tiene mapeo inequívoco, corresponde `INDETERMINADO`, no prometer disponibilidad ni asumir agotamiento.

Búsqueda libre:

```text
GET /productos?q=<texto>
```

## Peso/volumen

Chatbot no pide datos físicos a Productos.

```text
Chatbot -> Despacho POST /api/v1/cotizaciones
Despacho -> Productos POST /api/v1/productos/datos-fisicos/consulta
```

El request de Productos usa `snake_case`. El BFF del Chatbot puede traducir sus DTO internos.

## Identidad de cliente

Para cupón:

```text
customer_ref = Security access-token sub
```

Nunca usar `sub=modulo-chatbot`.

# 17. Regla especial para Despacho

Queda confirmado contractualmente:

```text
POST /api/v1/productos/datos-fisicos/consulta
scope = productos:fisicos:leer
aud = api-productos
sub = modulo-despacho
```

Las unidades son:

```text
peso -> kg
dimensiones -> cm
```

Despacho continúa siendo responsable de transformar esos datos físicos en información logística.

---

# 18. Regla especial para Ventas/Postventa

M1/Ventas conserva la orquestación de reserva, consumo y liberación del pedido. M2/Postventa invoca directamente el reintegro físico F3 después de recepción apta.

Scopes de M1/Ventas:

```text
inventario:reservar
inventario:consumir
inventario:liberar
inventario:reintegrar
inventario:conciliar-offline
```

Para M1/Ventas, `inventario:reintegrar` se conserva para otros motivos contractuales.

Scopes documentados para M2/Postventa (sin concesión efectiva de G7):

```text
inventario:disponibilidad:leer
inventario:reintegrar
```

M2 no está autorizado por este acuerdo a reservar, consumir o liberar reemplazos.

Cupones P1:

```text
promotions.coupon.consumption.requested
promotions.coupon.consumption.completed
promotions.coupon.consumption.rejected

promotions.coupon.restoration.requested
promotions.coupon.restoration.completed
promotions.coupon.restoration.rejected
```

Secuencia recomendada:

```text
CREADO
-> reserva de stock confirmada
-> consumo de cupón confirmado, si aplica
-> pago habilitado
```

Si el pedido se cancela después del consumo, Ventas solicita restitución. La política del cupón decide si el contador se restaura.

Ventas debe persistir:

```text
contacto.clienteId = customer_ref = Security.sub
```

y reutilizarlo en el comando de consumo; no debe derivarlo del token técnico.


# 19. Recepción interna de traslados

`TRASLADO_ALMACEN_CENTRAL` no crea un endpoint de Retail ni de Despacho para acreditar stock.

Gestor Comercial con capacidad local de inventario:

```http
GET /api/v1/inventario/traslados
GET /api/v1/inventario/traslados/{trasladoId}
POST /api/v1/inventario/traslados/{trasladoId}/recepciones
```

Autorización local:

```text
INVENTARIO_TRASLADOS_LEER
INVENTARIO_TRASLADOS_RECIBIR
```

No agregar esos nombres a los scopes `api-productos`: son capacidades humanas locales.

# 20. Checklist mínimo de integración

Antes de declarar una integración cerrada:

1. El consumidor conoce la ruta canónica en `contratos/http/openapi.yaml`.
2. El `client_id` está identificado.
3. El scope pertenece a `api-productos` y está registrado en Seguridad cuando corresponda.
4. El JWT técnico contiene `api-productos` en `aud`.
5. El receptor valida `iss`, `aud`, `tipo`, `exp`, scope y, para JWT de servicio, `client_id` contra la allowlist de la operación; el scope compartido no autoriza saldos detallados a los canales.
6. El consumidor ramifica por `Problem.code`.
7. Las mutaciones idempotentes utilizan las cabeceras exigidas.
8. Los `202 Accepted` no se interpretan como resultado final.
9. Los resultados asíncronos conservan correlación.
10. Existe al menos una prueba de contrato consumidor-productor.

---

# 21. Pendientes abiertos de integración

| Pendiente | Estado |
|---|---|
| Registro de los 16 scopes de la línea base y sus grants en Seguridad | Externo; no bloquea documentación, sí el acceso real |
| Registro de `inventario:operaciones:leer` para `modulo-ventas` (candidato `0.6.0-rc.1`) | G7; pendiente de confirmación y concesión, no operativo por el mero OpenAPI |
| Crear recursos RabbitMQ del entorno desde la topología P2 | Implementación/infra |
| Contract tests runtime Ventas ↔ Inventario | Implementación |
| Consumer/provider tests Despacho ↔ Productos | Implementación |
| Sincronizar prototipos HTML con WF definitivos | Después del freeze |

P2 ya cerró la topología y la recepción de traslados.
# 22. Versionado y cambios

La fuente de verdad HTTP es:

```text
contratos/http/openapi.yaml
```

La fuente de verdad asíncrona es:

```text
contratos/eventos/asyncapi.yaml
```

Un cambio incompatible requiere una nueva versión contractual.

Proceso:

```text
decisión funcional
-> contrato ejecutable
-> Contrato_Api.md
-> kit-integracion.md
-> SPEC / HU / FLOW / WF afectados
-> pruebas de contrato
```

No se deben crear rutas nuevas únicamente en documentación de un consumidor.

Sincronización documental 2026-10-01:

```text
kit-integracion.md se alinea con contratos/http/openapi.yaml 0.5.0 para Pricing.
No se agregan rutas HTTP nuevas.
Se documentan explícitamente consultas administrativas, prevalidación,
importación, seguimiento y reporte ya presentes en OpenAPI.
```

---

# 23. Contacto de integración

Cuando otro equipo necesite una capacidad no publicada, debe enviar como mínimo:

```text
módulo consumidor
client_id
caso de uso
ruta/capacidad solicitada
datos mínimos necesarios
si es lectura o mutación
idempotencia esperada
scope propuesto si aplica
audiencia = api-productos
```

La ruta o scope solo se considera contractual después de incorporarse al artefacto canónico correspondiente.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Guía práctica — HTTP 0.5.0

### Marketplace

Su frontend llama a su backend/BFF; el BFF consume `api-productos`.

```text
GET /productos?canal=MARKETPLACE&orden=NOMBRE_ASC
GET /productos/por-slug/{slug}?canal=MARKETPLACE
```

### Retail — resolver código

```http
POST /api/v1/productos/codigos-barras/resolver
Content-Type: application/json
X-Correlation-Id: <uuid>

{"codigo_barras":"0001234567890"}
```

Respuesta:

```json
{"sku":"SKU-001"}
```

Retail no transforma el valor y, desde la respuesta, usa SKU para precio/disponibilidad/venta.

### Disponibilidad de canales

```text
GET /api/v1/inventario/disponibilidad/comercial?skus=SKU-001,SKU-002&canal={CANAL}
```

Respuesta:

```json
{"items":[{"sku":"SKU-001","status":"DISPONIBLE"}]}
```

No expone `location_id`, `on_hand`, `reserved`, `blocked`, `available`, `threshold` ni `stock_version`. La política **D-INV-01 ya fue adoptada**: solo se considera una ubicación elegible por contexto de cumplimiento, sin sumar ubicaciones independientes. El endpoint sigue provisional **por implementación y pruebas pendientes**, no por una decisión abierta. Una correspondencia de cumplimiento inexistente o ambigua produce `INDETERMINADO`.

### Recomendaciones

```text
GET /api/v1/recomendaciones?productoId={id}&canal={MARKETPLACE|CHATBOT|RETAIL}
```

`availability/current_price` product-level siguen provisionales por `D-REC-01/D-REC-02`.

### Rate limiting

`429 RATE_LIMIT_EXCEDIDO` puede incluir `Retry-After`. No se publica una cuota numérica universal.
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
