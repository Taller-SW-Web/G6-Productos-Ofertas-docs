# API Contract — Módulo de Productos y Ofertas

**Fecha de actualización:** 2026-09-28  
**Módulo propietario:** Productos y Ofertas  
**Documento humano canónico:** `Contrato_Api.md`  
**Contrato HTTP canónico:** `api/openapi.yaml` (`0.3.5-p0`)  
**Contrato asíncrono canónico:** `asyncapi/asyncapi.yaml` (`0.2.1-p0`)  
**Catálogo de eventos:** `api/catalogo-eventos.md` (`0.2.1-p0`)  
**Catálogo de errores:** `api/catalogo-errores.md` (`0.2.4-p0`)  
**Versión contractual P0:** `0.3.5-p0`  
**Estado:** alineado con AsyncAPI `0.2.1-p0`, errores `0.2.4-p0` y eventos `0.2.1-p0`.

## Fuentes utilizadas

- `specs/SPEC-001` a `specs/SPEC-016`
- `hu/HU-001` a `hu/HU-016`
- `Arquitectura.md`
- `Modelo_Conceptual.md`
- `api/openapi.yaml`
- `asyncapi/asyncapi.yaml`
- `api/catalogo-eventos.md`
- `api/catalogo-errores.md`
- Lineamientos del Proyecto del Curso TCSW 2026-II
- Contrato de integración publicado por Seguridad y Usuarios
- Contrato de integración publicado por Despacho y Entrega
- Documentación de integración de Chatbot, Retail y Ventas/Postventa
- Acuerdo directo con Ventas/Postventa:
  - reserva al entrar el pedido en `CREADO`;
  - consumo definitivo al pasar a `PAGADO`;
  - liberación ante `PAGO_NO_COMPLETADO` o anulación aplicable;
  - Ventas/Postventa orquesta todo el ciclo de inventario;
  - los canales únicamente consultan disponibilidad.
- Acuerdo directo con Despacho:
  - Despacho es responsable del empaque.

> **Regla de autoridad documental:** las SPEC son la fuente de verdad de reglas de negocio.  
> `api/openapi.yaml` es la fuente de verdad de HTTP. `asyncapi/asyncapi.yaml` es la fuente de verdad de mensajería. `api/catalogo-errores.md` gobierna la semántica estable de `code`.  
> Este documento explica ownership, flujos, responsabilidades e integración entre módulos.

---

# 1. Propósito

Definir el contrato de integración del módulo **Productos y Ofertas** con:

- Marketplace;
- Chatbot;
- Retail;
- Ventas y Postventa;
- Despacho y Entrega;
- Seguridad y Usuarios.

El contrato busca evitar:

- acceso directo a bases de datos ajenas;
- duplicación de ownership;
- inconsistencias entre módulos;
- consumo duplicado de inventario;
- rutas inventadas por cada consumidor;
- uso de eventos como si fueran comandos;
- dependencias síncronas innecesarias;
- contradicciones entre SPEC, arquitectura y OpenAPI.

---

# 2. Principios de integración

## 2.1. Ownership

Cada entidad o dato de negocio tiene un único propietario.

| Dato / entidad | Owner |
|---|---|
| Producto / Variante / SKU | Productos y Ofertas — Catálogo |
| Categoría / Marca / Característica / Tipo de Producto | Productos y Ofertas — Taxonomía |
| Precio | Productos y Ofertas — Pricing |
| Promoción / Cupón / Recomendación | Productos y Ofertas — Promociones |
| Combo | Productos y Ofertas — Combos |
| Stock / Reserva / Kardex / Ubicación | Productos y Ofertas — Inventario |
| Auditoría de precios | Productos y Ofertas — Price Audit |
| Usuario / autenticación / roles | Seguridad y Usuarios |
| Pedido / pago / estado comercial | Ventas y Postventa |
| Devolución comercial / reembolso | Ventas y Postventa |
| Despacho / entrega / empaque | Despacho y Entrega |

No existen foreign keys ni acceso SQL entre bases de datos de módulos distintos.

---

## 2.2. Integración por APIs

Los módulos se integran exclusivamente mediante contratos publicados.

Se utilizarán:

- HTTP/HTTPS para consultas;
- HTTP `202 Accepted` para comandos que continúan de forma asíncrona;
- mensajería asíncrona para resultados, eventos y coordinación cross-module;
- OpenAPI para contratos HTTP;
- AsyncAPI + JSON Schema para contratos asíncronos.

---

## 2.3. Evento no es comando

Ejemplo:

```text
inventory.stock.changed
```

significa que el saldo **ya cambió y fue persistido**.

No significa:

```text
descuenta stock
```

De la misma forma:

```text
pricing.price.changed
```

es un hecho confirmado y no una instrucción de cambio de precio.

---

## 2.4. Consistencia

- ACID únicamente dentro del servicio propietario.
- Consistencia eventual entre módulos.
- Mutaciones externas críticas deben ser idempotentes.
- No se utilizarán transacciones SQL distribuidas.
- Los read models no sustituyen al owner.
- Una consulta de disponibilidad no constituye reserva.

---

# 3. Convenciones de la API

## 3.1. Prefijo

Todas las rutas del módulo usan:

```text
/api/v1
```

El `servers.url` de OpenAPI es:

```text
/api/v1
```

---

## 3.2. Idioma

Las rutas REST se publican en **español**.

Ejemplos:

```text
/productos
/categorias
/marcas
/precios
/promociones
/cupones
/recomendaciones
/combos
/inventario
/seo
```

---

## 3.3. Organización

Las rutas se organizan por **recurso/dominio**, no por nombre del microservicio.

Correcto:

```text
/api/v1/inventario/disponibilidad
```

No recomendado:

```text
/api/v1/inventory-svc/disponibilidad
```

---

## 3.4. Estados contractuales

| Estado | Significado |
|---|---|
| `stable` | Ruta y semántica ya definidas en OpenAPI P0 |
| `provisional` | Semántica suficientemente definida, pero todavía requiere cerrar algún detalle externo, permiso/scoping o homologación con otro módulo |
| `public` | Lectura pública sin autenticación |
| `internal` | Contrato interno del módulo, no consumible externamente sin publicación explícita |

La extensión OpenAPI utilizada es:

```yaml
x-status: stable
```

o:

```yaml
x-status: provisional
```

---

# 4. Resumen de APIs HTTP externas

La definición exacta de parámetros y schemas está en `api/openapi.yaml`.

| Método | Ruta | Estado | Consumidor principal |
|---|---|---|---|
| `GET` | `/api/v1/productos` | stable | Marketplace / Chatbot / Retail / Ventas |
| `GET` | `/api/v1/productos/{productoId}` | stable | Marketplace / Chatbot / Retail / Ventas |
| `GET` | `/api/v1/categorias` | stable | Canales |
| `GET` | `/api/v1/marcas` | stable | Canales |
| `GET` | `/api/v1/precios` | stable | Canales / Ventas |
| `GET` | `/api/v1/precios/skus/{sku}` | stable | Canales / Ventas |
| `GET` | `/api/v1/promociones` | stable | Canales / Ventas |
| `POST` | `/api/v1/promociones/evaluar` | stable | Canales / Ventas |
| `POST` | `/api/v1/cupones/validar` | stable | Canales / Ventas |
| `GET` | `/api/v1/recomendaciones` | stable | Marketplace / Chatbot / Retail |
| `GET` | `/api/v1/combos/{comboId}` | stable | Canales / Ventas |
| `GET` | `/api/v1/inventario/disponibilidad` | stable | Canales / Ventas |
| `POST` | `/api/v1/inventario/reservas` | provisional | Solo Ventas/Postventa |
| `POST` | `/api/v1/inventario/reservas/{reservaId}/confirmar` | provisional | Solo Ventas/Postventa |
| `POST` | `/api/v1/inventario/reservas/{reservaId}/liberar` | provisional | Solo Ventas/Postventa |
| `POST` | `/api/v1/productos/datos-fisicos/consulta` | provisional | Despacho |
| `GET` | `/api/v1/seo/{slug}` | stable / público | Marketplace |
| `GET` | `/api/v1/seo/resoluciones/{slugAnterior}` | stable / público | Marketplace |

---

# 5. Catálogo

## 5.1. Listar productos

```http
GET /api/v1/productos
```

Permite filtrar mediante parámetros definidos en OpenAPI, entre ellos:

- texto;
- categoría;
- marca;
- canal;
- paginación.

Los canales reciben únicamente productos comercialmente elegibles.

Catálogo no es owner de:

- precio vigente;
- stock;
- promoción aplicada;
- cupón;
- disponibilidad de combo.

---

## 5.2. Detalle de producto

```http
GET /api/v1/productos/{productoId}
```

El detalle incluye sus variantes/SKU activas.

Esta decisión evita que Chatbot, Marketplace o Retail deban realizar una segunda llamada únicamente para resolver las variantes del producto.

### Identidades

- `productoId`: identidad del producto.
- `variantId`: identidad interna estable de una variante.
- `sku`: identidad comercial e integración.
- `skuBase`: SKU vendible del producto simple.

`variantId` y `sku` no son equivalentes.

---

# 6. Taxonomía

## 6.1. Categorías

```http
GET /api/v1/categorias
```

Expone categorías activas para navegación y filtros.

La creación administrativa usa un flujo de dos pasos con SEO: primero se resuelve el slug propuesto y luego se crea la categoría con el `slugConfirmado`. La unicidad se revalida al persistir.

---

## 6.2. Marcas

```http
GET /api/v1/marcas
```

Expone marcas activas.

Catálogo referencia la marca, pero Taxonomía conserva el ownership.

---

## 6.3. Tipos de producto y esquema de características

El OpenAPI administrativo publica:

```text
GET  /api/v1/tipos-producto
POST /api/v1/tipos-producto
GET  /api/v1/tipos-producto/{tipoProductoId}

POST /api/v1/tipos-producto/{tipoProductoId}/desactivar
POST /api/v1/tipos-producto/{tipoProductoId}/reactivar

GET   /api/v1/tipos-producto/{tipoProductoId}/caracteristicas
POST  /api/v1/tipos-producto/{tipoProductoId}/caracteristicas
PATCH /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}
POST  /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}/desasociar
```

Semántica de error:

```text
TIPO_PRODUCTO_NO_ENCONTRADO -> 404
TIPO_PRODUCTO_INVALIDO      -> 422
```

El primer código representa un recurso de path inexistente. El segundo representa un tipo existente que no puede usarse por estado o incompatibilidad.

Toda modificación confirmada del esquema incrementa `schema_version` y se propaga a Catálogo mediante:

```text
taxonomy.product-type-schema.changed
```

Los renombres confirmados de valores `LISTA` se propagan mediante:

```text
taxonomy.characteristic-value.updated
```

---

## 6.4. Bajas seguras de entidades maestras

La desactivación/desasociación de entidades con dependencias usa el protocolo asíncrono genérico de baja segura. AsyncAPI `0.2.1-p0` cubre también:

```text
PRODUCT_TYPE
PRODUCT_TYPE_CHARACTERISTIC
```

Cuando una baja queda pendiente, su estado puede consultarse mediante:

```http
GET /api/v1/taxonomia/operaciones/{operationId}
```

Una identidad de operación inexistente devuelve:

```text
404 OPERACION_MAESTRA_NO_ENCONTRADA
```

`202 Accepted` significa únicamente admisión; el resultado definitivo depende del flujo asíncrono.

---

# 7. Precios

## 7.1. Consulta múltiple

```http
GET /api/v1/precios
```

Permite consultar precios de varios SKU según el contrato definido en OpenAPI.

---

## 7.2. Precio por SKU

```http
GET /api/v1/precios/skus/{sku}
```

Puede recibir contexto temporal para resolver precio vigente o histórico.

Pricing es owner de:

- precio regular;
- precio oferta;
- vigencia;
- versión de precio.

Ventas debe conservar el snapshot comercial utilizado para el pedido.

---

# 8. Promociones y cupones

## 8.1. Promociones vigentes

```http
GET /api/v1/promociones
```

Expone promociones comercialmente vigentes para el canal solicitado.

---

## 8.2. Evaluación de beneficios

```http
POST /api/v1/promociones/evaluar
```

La evaluación recibe contexto de compra suficiente para determinar el beneficio aplicable.

No modifica el pedido y no consume un cupón.

---

## 8.3. Validación de cupón

```http
POST /api/v1/cupones/validar
```

Regla crítica:

```text
VALIDAR != CONSUMIR
```

La validación informa si el cupón puede utilizarse y cuál sería su efecto.

El consumo definitivo del cupón ocurre únicamente dentro del flujo de confirmación comercial acordado con Ventas/Postventa.

---

# 9. Recomendaciones

```http
GET /api/v1/recomendaciones
```

Expone candidatos de:

- cross-sell;
- upsell.

El servicio:

- filtra entidades inactivas;
- evita duplicados;
- usa disponibilidad comercial;
- no realiza interpretación conversacional.

La interpretación en lenguaje natural sigue siendo responsabilidad de Chatbot.

---

# 10. Combos

```http
GET /api/v1/combos/{comboId}
```

Un combo:

- contiene al menos dos SKU distintos;
- no admite combos anidados;
- mantiene precio propio;
- expone disponibilidad informativa;
- no garantiza stock hasta la operación autoritativa de Inventario.

---

# 11. Inventario

## 11.1. Unidad de inventario

La unidad vendible es el SKU.

El saldo autoritativo se identifica por:

```text
(sku, location_id)
```

Inventario mantiene:

```text
on_hand
reserved
available
```

con:

```text
available = max(on_hand - reserved, 0)
```

---

## 11.2. Consulta de disponibilidad

```http
GET /api/v1/inventario/disponibilidad
```

Consumidores:

- Marketplace;
- Chatbot;
- Retail;
- Ventas/Postventa.

Los canales pueden **consultar**, pero no mutar stock.

La consulta:

- no reserva;
- no garantiza unidades futuras;
- puede consultar una ubicación concreta;
- puede utilizar un agregado cuando el contrato lo permita.

Estados mínimos:

```text
AGOTADO
STOCK_BAJO
DISPONIBLE
```

---

# 12. Flujo oficial de reserva y consumo

Este flujo queda cerrado funcionalmente con Ventas/Postventa.

```text
Canal
  |
  |-- consulta disponibilidad --> Productos y Ofertas
  |
  |-- crea pedido -------------> Ventas/Postventa|
                                      |-- pedido = CREADO
                                      |      |
                                      |      -> reservar stock
                                      |
                                      |-- pedido = PAGADO
                                      |      |
                                      |      -> confirmar consumo
                                      |
                                      |-- PAGO_NO_COMPLETADO
                                      |      o anulación aplicable
                                      |      |
                                      |      -> liberar reserva
```

## 12.1. Responsabilidad de los canales

Marketplace, Chatbot y Retail:

- consultan disponibilidad;
- construyen la experiencia de compra;
- envían la creación del pedido a Ventas/Postventa.

No deben:

- crear reservas;
- consumir stock;
- liberar reservas.

---

## 12.2. Responsabilidad de Ventas/Postventa

Ventas/Postventa:

- crea la reserva al entrar el pedido en `CREADO`;
- confirma el consumo cuando el pedido pasa a `PAGADO`;
- libera la reserva cuando existe `PAGO_NO_COMPLETADO`;
- libera cuando una anulación corresponda;
- conserva ownership del pedido;
- no modifica directamente las tablas de Inventario.

---

## 12.3. Responsabilidad de Productos y Ofertas

Inventario:

- valida disponibilidad;
- crea la reserva;
- incrementa `reserved`;
- reduce `available`;
- consume de forma definitiva;
- disminuye `on_hand`;
- elimina la reserva consumida;
- libera reservas;
- expira reservas;
- registra Kardex;
- aplica idempotencia;
- publica resultados.

---

# 13. Comandos HTTP de inventario

Las mutaciones entre Ventas y Productos siguen el requisito de integración asíncrona: el HTTP acepta el comando y el resultado final se publica por mensajería.

## 13.1. Crear reserva

```http
POST /api/v1/inventario/reservas
```

Consumidor autorizado:

```text
modulo-ventas
```

Respuesta exitosa inmediata:

```text
202 Accepted
```

Payload conceptual:

```json
{
  "order_id": "PED-2026-00981",
  "operation_id": "uuid",
  "channel_id": "MARKETPLACE",
  "lines": [
    {
      "sku": "SKU-001",
      "quantity": 2,
      "location_id": "DEFAULT"
    }
  ]
}
```

La definición exacta está en `api/openapi.yaml`.

---

## 13.2. Confirmar consumo

```http
POST /api/v1/inventario/reservas/{reservaId}/confirmar
```

Se utiliza cuando el pedido pasa a:

```text
PAGADO
```

Respuesta:

```text
202 Accepted
```

La confirmación:

- consume las unidades reservadas;
- actualiza `on_hand`;
- actualiza `reserved`;
- recalcula `available`;
- registra Kardex;
- es idempotente.

---

## 13.3. Liberar reserva

```http
POST /api/v1/inventario/reservas/{reservaId}/liberar
```

Motivos contractuales previstos:

```text
PAGO_NO_COMPLETADO
ANULACION
EXPIRACION_FORZADA
OTRO
```

Respuesta:

```text
202 Accepted
```

---

## 13.4. TTL de reserva

Toda reserva tiene expiración.

El TTL es configurable por:

- entorno;
- canal.

No se fija un número rígido en el contrato.

La API debe informar la expiración cuando el recurso de reserva definitivo lo requiera.

Una expiración automática produce liberación de unidades sin necesidad de una segunda mutación manual.

---

# 14. Idempotencia de inventario

Toda mutación externa de Inventario utiliza:

```http
Idempotency-Key: <valor-estable>
X-Correlation-Id: <uuid>
```

y el request incluye:

```text
operation_id
```

Semántica contractual:

```text
misma identidad idempotente
+
mismo payload semántico
=
retry legítimo
=
se reutiliza el resultado conocido sin repetir efectos
```

Por tanto, un retry no debe:

- crear una segunda reserva;
- consumir dos veces;
- liberar dos veces;
- duplicar movimientos de Kardex.

Si la misma identidad idempotente se reutiliza para una intención diferente:

```text
409
IDEMPOTENCY_CONFLICT
```

sin ejecutar nuevos efectos.

No se utiliza:

```text
OPERACION_DUPLICADA
```

para representar un retry legítimo.

`correlation_id` sirve para trazabilidad y no sustituye `Idempotency-Key` ni `operation_id`.

La implementación puede persistir un fingerprint/hash semántico para detectar reutilización conflictiva, pero ese detalle no forma parte del contrato externo.

# 15. Retail

La documentación actual de Retail plantea consumo directo:

```http
POST /api/v1/inventario/consumir
```

Ese flujo debe actualizarse.

El contrato homologado es:

```text
Retail
  -> consulta disponibilidad a Productos
  -> crea pedido en Ventas/Postventa
  -> Ventas reserva
  -> Ventas confirma consumo al quedar PAGADO
```

Por tanto, Retail no tendrá autorización para ejecutar directamente las operaciones de reserva/consumo/liberación.

---

# 16. Chatbot

Chatbot queda alineado con el contrato.

Debe:

- consultar catálogo;
- consultar precio;
- consultar promociones/cupones;
- consultar disponibilidad;
- crear el pedido mediante Ventas/Postventa.

No debe reservar ni consumir stock directamente.

---

# 17. Marketplace

Marketplace sigue el mismo patrón contractual de canal:

- consulta Productos y Ofertas;
- crea el pedido mediante Ventas/Postventa;
- no muta Inventario directamente.

La documentación pública de Marketplace todavía no define todos sus detalles técnicos, pero esto no bloquea P0 porque el ownership y el flujo del pedido ya están definidos por los lineamientos y por el acuerdo con Ventas.

---

# 18. Integración con Despacho

## 18.1. Delimitación de responsabilidades

Productos y Ofertas es owner de los datos físicos propios del SKU.

Despacho es owner de:

- empaque;
- agrupación logística;
- cantidad de paquetes;
- volumen operativo del despacho;
- capacidad de transporte.

Productos no debe decidir ni persistir `tipoEmpaque` como parte del contrato logístico compartido.

---

## 18.2. Datos físicos por SKU

Campos mínimos:

```text
sku
estado
pesoKg
largoCm
anchoCm
altoCm
actualizadoEn
```

El volumen puede ser calculado por Despacho:

```text
volumenUnitarioM3 =
(largoCm / 100) *
(anchoCm / 100) *
(altoCm / 100)
```

---

## 18.3. Consulta en lote

```http
POST /api/v1/productos/datos-fisicos/consulta
```

Consumidor:

```text
modulo-despacho
```

Request:

```json
{
  "skus": [
    "POL-NEG-M",
    "ZAP-RUN-42"
  ]
}
```

Respuesta conceptual:

```json
{
  "productos": [
    {
      "sku": "POL-NEG-M",
      "estado": "ACTIVO",
      "pesoKg": 0.25,
      "dimensionesCm": {
        "largo": 30,
        "ancho": 25,
        "alto": 3
      },
      "actualizadoEn": "2026-09-27T12:00:00Z"
    }
  ],
  "noEncontrados": []
}
```

Estado actual del endpoint:

```text
provisional
```

La semántica está acordada; queda formalizar el scope definitivo y pruebas de contrato.

Scope propuesto:

```text
productos:fisicos:leer
```

---

# 19. Seguridad y Usuarios

Productos y Ofertas adopta el contrato publicado por Seguridad.

## 19.1. Identidad técnica

```text
client_id = modulo-productos
```

Scopes concedidos por Seguridad:

```text
tokens:introspeccion
roles:leer
```

---

## 19.2. Validación ordinaria

La validación normal de JWT se realiza localmente mediante JWKS.

Endpoints de Seguridad:

```http
GET /api/v1/auth/.well-known/openid-configuration
GET /api/v1/auth/.well-known/jwks.json
```

Los roles viajan en:

```text
roles
```

No en `scope`.

---

## 19.3. Operaciones sensibles

Seguridad establece que operaciones sensibles deben utilizar introspección.

En Productos, cambiar precios es un ejemplo explícito de operación sensible.

Se utiliza:

```http
POST /api/v1/auth/introspeccion
```

con un token de servicio de `modulo-productos`.

---

## 19.4. Tokens de servicio

Productos obtiene su token mediante:

```http
POST /api/v1/auth/token
```

con:

```text
grant_type=client_credentials
client_id=modulo-productos
```

Los secretos reales no forman parte de este repositorio.

---

# 20. Autenticación de la API de Productos

OpenAPI define dos esquemas conceptuales:

```text
serviceBearer
userBearer
```

## `serviceBearer`

JWT técnico para comunicación módulo-a-módulo.

## `userBearer`

JWT humano para operaciones administrativas del Gestor Comercial cuando corresponda.

Las operaciones públicas SEO no requieren autenticación.

---

# 21. Permisos propios de Productos

Seguridad ya publica para `modulo-productos`:

```text
tokens:introspeccion
roles:leer
```

Los permisos granulares de operaciones de Productos todavía son propuestas pendientes de registro con Seguridad:

```text
inventario:reservar
inventario:consumir
inventario:liberar
productos:fisicos:leer
```

Asignación prevista:

```text
modulo-ventas:
  inventario:reservar
  inventario:consumir
  inventario:liberar

modulo-despacho:
  productos:fisicos:leer
```

Hasta su publicación por Seguridad, esos nombres no deben describirse como scopes oficiales concedidos.

La semántica HTTP sí está cerrada:

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

y los servicios no están obligados a revelar en `detail` el permiso exacto faltante.

# 22. SEO

## 22.1. Metadatos

```http
GET /api/v1/seo/{slug}
```

Lectura pública.

Productos y Ofertas conserva la metadata de negocio y SEO correspondiente.

---

## 22.2. Resolución de slug anterior

```http
GET /api/v1/seo/resoluciones/{slugAnterior}
```

Productos resuelve:

```text
slugAnterior -> slugActual
```

Marketplace decide cómo ejecutar el HTTP `301`.

---

## 22.3. Resolución previa del slug al crear categoría

Antes de completar una creación administrativa de categoría:

```http
POST /api/v1/seo/categorias/slug/resolver
```

recibe el nombre y devuelve la propuesta normalizada final, incluyendo sufijo incremental cuando existe una colisión en ese momento.

Después, el gestor confirma visualmente la URL y la creación usa:

```text
slugConfirmado
```

en `POST /api/v1/categorias`.

La resolución previa **no reserva** el slug. Por ello la creación revalida unicidad. Si otro proceso ocupa el slug entre ambos pasos:

```text
409 SLUG_DUPLICADO
```

y el cliente debe volver a resolver. El servidor no sustituye silenciosamente el slug ya confirmado por otro valor.

---

# 23. Manejo de errores

Fuente canónica:

```text
api/catalogo-errores.md
```

Todos los errores HTTP del módulo utilizan:

```http
Content-Type: application/problem+json
```

con semántica RFC 7807.

Schema conceptual:

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

En OpenAPI:

- `Problem.code` referencia `ErrorCode`;
- el enum global contiene los códigos publicados;
- cada operación restringe el subconjunto aplicable mediante `x-error-codes`;
- `SIN_AUTORIZACION` no forma parte de `ErrorCode`;
- `OPERACION_DUPLICADA` no forma parte de `ErrorCode`.

Reglas de seguridad:

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

Regla de idempotencia:

```text
misma identidad + distinta intención
-> IDEMPOTENCY_CONFLICT
```

Cierres HTTP relevantes de la línea base `0.3.5-p0` / catálogo `0.2.4-p0`:

```text
TIPO_PRODUCTO_NO_ENCONTRADO           -> 404
TIPO_PRODUCTO_INVALIDO                -> 422
PRODUCTO_NO_ADMITE_VARIANTES          -> 409
SLUG_DUPLICADO                        -> 409
OPERACION_MAESTRA_NO_ENCONTRADA       -> 404
AUDITORIA_PRECIO_NO_ENCONTRADA        -> 404
LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO -> 422
```

Los consumidores ramifican por:

```text
code
```

No por:

```text
title
detail
```

Un resultado comercial negativo puede ser una respuesta normal y no un error de transporte. Ejemplo: `POST /cupones/validar` puede responder `200` con un `code` de no aplicabilidad definido por `CodigoRechazoCupon`.

# 24. Códigos HTTP

Convención general:

| Código | Uso |
|---|---|
| `200` | consulta correcta |
| `201` | creación síncrona finalizada |
| `202` | comando asíncrono aceptado |
| `400` | request inválido |
| `401` | autenticación ausente/inválida |
| `403` | autorización/scope insuficiente |
| `404` | recurso inexistente |
| `409` | conflicto de estado, versión o idempotencia |
| `422` | regla de negocio impide procesar la solicitud |
| `429` | límite de solicitudes cuando corresponda |
| `500` | error inesperado |
| `503` | servicio o dependencia temporalmente no disponible |

La definición exacta por operación está en OpenAPI.

---

# 25. Concurrencia

## Inventario

Mutaciones por:

```text
(sku, location_id)
```

deben impedir:

- stock negativo;
- doble consumo;
- sobre-reserva.

Los ajustes absolutos utilizan:

```text
stock_version
```

cuando corresponda.

---

## Pricing

Las escrituras concurrentes utilizan:

```text
price_version
```

---

## Catálogo / Bulk

Se utiliza:

```text
catalog_version
```

cuando una escritura dependa de una lectura previa.

---

# 26. Mensajería asíncrona relevante

Fuente canónica:

```text
asyncapi/asyncapi.yaml
```

Referencia humana:

```text
api/catalogo-eventos.md
```

AsyncAPI `0.2.1-p0` documenta actualmente **29 mensajes lógicos** entre eventos, comandos internos y resultados.

Entre los mensajes externos/integradores más relevantes están:

```text
taxonomy.category.updated
taxonomy.product-type-schema.changed
taxonomy.characteristic-value.updated

catalog.product.deactivated
catalog.sku.deactivated

pricing.price.changed

inventory.stock.changed
inventory.stock.adjusted

inventory.reservation.created
inventory.reservation.released
inventory.reservation.expired
inventory.reservation.consumed

inventory.consumption.completed
inventory.consumption.rejected

promotions.coupon.consumption.completed
promotions.coupon.consumption.rejected
```

También están formalizados los comandos/resultados internos de Bulk y la baja segura de entidades maestras. El flujo de baja segura cubre `CATEGORY`, `BRAND`, `CHARACTERISTIC_VALUE`, `PRODUCT_TYPE` y `PRODUCT_TYPE_CHARACTERISTIC`.

El envelope, payload, productor, consumidores, `schema_version`, `operation_id`, `correlation_id` y semántica `at-least-once` pertenecen al AsyncAPI.

Deliberadamente todavía no se fijan nombres físicos definitivos de:

```text
exchange
queue
retry queue
DLQ
```

La topología física del broker es una decisión de despliegue.

# 27. Resultados asíncronos de Inventario

`202 Accepted` significa:

```text
comando admitido
```

y no:

```text
operación de negocio completada
```

## Reserva

Resultado exitoso:

```text
inventory.reservation.created
```

Un rechazo de negocio posterior a la admisión utiliza actualmente:

```text
inventory.consumption.rejected
operation_type = RESERVAR
```

Esta reutilización del nombre se conserva por compatibilidad P0 y está documentada como deuda semántica; una versión futura puede introducir `inventory.reservation.rejected` mediante cambio versionado.

## Confirmación de consumo

Resultados exitosos:

```text
inventory.reservation.consumed
inventory.consumption.completed
```

Rechazo:

```text
inventory.consumption.rejected
operation_type = CONFIRMAR_CONSUMO
```

Códigos posibles del rechazo asíncrono se restringen en AsyncAPI a causas de negocio posteriores a la admisión, por ejemplo:

```text
STOCK_INSUFICIENTE
SKU_NO_ENCONTRADO
SKU_INACTIVO
UBICACION_NO_ENCONTRADA
RESERVA_NO_ENCONTRADA
RESERVA_NO_ACTIVA
RESERVA_EXPIRADA
CANTIDAD_INVALIDA
```

`IDEMPOTENCY_CONFLICT` se resuelve durante la admisión HTTP y no se publica como un segundo resultado asíncrono.

## Liberación

Resultado:

```text
inventory.reservation.released
```

## Expiración

Resultado:

```text
inventory.reservation.expired
```

Ventas/Postventa debe correlacionar mediante:

```text
order_id
operation_id
correlation_id
reservation_id
```

# 28. Devoluciones

El ownership comercial de una devolución pertenece a Ventas/Postventa.

Inventario solo repone stock cuando recibe una comunicación equivalente a:

> devolución aceptada y físicamente reintegrable.

La reposición debe identificar como mínimo:

- pedido;
- operación;
- SKU;
- cantidad;
- `location_id` de reintegro.

El nombre y payload asíncrono definitivo de este contrato todavía debe formalizarse con Ventas/Postventa.

Una devolución comercial no equivale automáticamente a un movimiento de inventario.

---

# 29. Cancelaciones

Mientras exista una reserva activa:

- una anulación aplicable libera la reserva.

Si ya hubo consumo definitivo, cualquier reposición posterior debe corresponder a una regla explícita de compensación o devolución.

Productos y Ofertas no decide:

- reembolso;
- extorno;
- estado final del pedido.

---

# 30. `customer_ref`

Seguridad y Usuarios es owner de la identidad del cliente.

Productos puede conservar una referencia opaca cuando sea necesaria para:

- límites de cupón por cliente;
- idempotencia del beneficio;
- restitución de cupón.

No debe replicar:

- contraseña;
- documento;
- dirección;
- teléfono;
- perfil completo.

El mecanismo definitivo de transporte de `customer_ref` todavía debe quedar documentado de forma explícita.

---

# 31. Información que Productos no debe solicitar

## De Seguridad

No almacenar:

- contraseñas;
- hashes;
- secretos;
- sesiones internas.

## De Ventas

No asumir ownership de:

- pedido;
- pago;
- reembolso;
- comprobante;
- política comercial de devolución.

## De Despacho

No asumir ownership de:

- empaque;
- vehículo;
- repartidor;
- ruta;
- entrega;
- capacidad logística.

---

# 32. Contratos internos del módulo

Los bounded contexts de Productos y Ofertas utilizan mensajería interna.

Ejemplos:

```text
taxonomy.master.deactivation.check.requested
catalog.master.deactivation.checked
taxonomy.product-type-schema.changed
taxonomy.characteristic-value.updated

catalog.bulk.upsert.requested
catalog.bulk.upsert.completed
catalog.bulk.upsert.rejected

pricing.bulk.price.apply.requested
pricing.bulk.price.apply.completed
pricing.bulk.price.apply.rejected

inventory.bulk.stock.adjust.requested
inventory.bulk.stock.adjust.completed
inventory.bulk.stock.adjust.rejected
```

Estos contratos no deben exponerse automáticamente como API externa.

---

# 33. Bulk

`bulk-svc` coordina importaciones/exportaciones y no escribe directamente en schemas de Catálogo, Pricing o Inventario.

Principios:

- comandos idempotentes;
- `batch_id`;
- `row_id`;
- confirmación por dominio;
- reconciliación ante aplicación parcial;
- no rollback distribuido ficticio.

La cobertura HTTP administrativa de Bulk ya forma parte del OpenAPI `0.3.5-p0`. La forma exacta de rutas, requests, estados y errores se toma del contrato ejecutable; este documento conserva únicamente las reglas de ownership y coordinación.

---

# 34. Auditoría de precios

Price Audit conserva el historial inmutable de cambios de precio.

No se expone como parte de los contratos de canales; su superficie es administrativa.

OpenAPI `0.3.5-p0` publica:

```text
GET  /api/v1/auditoria-precios
GET  /api/v1/auditoria-precios/{auditId}
POST /api/v1/auditoria-precios/exportaciones
GET  /api/v1/auditoria-precios/exportaciones/{exportId}
GET  /api/v1/auditoria-precios/exportaciones/{exportId}/archivo
```

Reglas:

```text
CSV <= 100000 filas
PDF <= 500 filas
```

Si el resultado supera el límite del formato, la solicitud es semánticamente inválida para exportación:

```text
422 LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO
```

y no se crea un trabajo de exportación.

Un registro de auditoría inexistente devuelve:

```text
404 AUDITORIA_PRECIO_NO_ENCONTRADA
```

Los trabajos/archivos de exportación mantienen sus identidades y estados definidos por OpenAPI. La bitácora continúa siendo append-only.

---

# 35. Versionado

## HTTP

Prefijo estable:

```text
/api/v1
```

Línea base del artefacto HTTP:

```text
OpenAPI 3.1.0
info.version = 0.3.5-p0
```

Un cambio incompatible requiere nueva versión.

---

## Eventos

Todo mensaje debe incorporar:

```text
schema_version
```

Cambios rompientes requieren nueva versión del schema o del canal contractual.

---

## Cambios compatibles

- añadir campo opcional;
- añadir nuevo código de error documentado;
- ampliar una respuesta sin romper consumidores tolerantes.

## Cambios incompatibles

- eliminar o renombrar campos;
- convertir opcional en obligatorio;
- cambiar semántica;
- cambiar identidad;
- cambiar unidad;
- cambiar regla de idempotencia.

---

# 36. Trazabilidad principal

| Contrato | Fuente funcional |
|---|---|
| Catálogo | SPEC-003 / SPEC-004 |
| Categorías | SPEC-008 |
| Marcas | SPEC-011 |
| Pricing | SPEC-013 |
| Promociones | SPEC-006 |
| Cupones | SPEC-005 |
| Recomendaciones | SPEC-007 |
| Combos | SPEC-002 |
| Inventario | SPEC-015 |
| SEO | SPEC-012 |
| Bulk | SPEC-001 |
| Auditoría de precios | SPEC-014 |
| Dashboard inventario | SPEC-016 |

---

# 37. Estado de integración por contraparte

| Contraparte | Estado | Definición vigente |
|---|---|---|
| Seguridad y Usuarios | Alineado con pendientes granulares | Contrato publicado; `modulo-productos`, JWKS, introspección, `tokens:introspeccion` y `roles:leer`; permisos propios de Inventario/Datos físicos todavía pendientes de registro |
| Ventas/Postventa | Flujo P0 cerrado | Reserva en `CREADO`, consumo en `PAGADO`, liberación ante pago no completado/anulación |
| Chatbot | Alineado | Solo consulta disponibilidad; Ventas orquesta inventario |
| Retail | Requiere corrección documental | Debe eliminar consumo directo de stock desde el canal |
| Marketplace | Sin bloqueo P0 | Canal de lectura; inventario mutado mediante Ventas |
| Despacho | Ownership cerrado | Despacho define empaque; Productos entrega peso/dimensiones por SKU |

---

# 38. Pendientes reales después de P0

Ya no son pendientes:

- creación y estabilización del AsyncAPI;
- payloads/envelopes de reserva, consumo, liberación y expiración;
- catálogo de eventos `0.2.1-p0`;
- catálogo de errores `0.2.4-p0`;
- cobertura administrativa de OpenAPI `0.3.5-p0`;
- armonización HTTP de tipos de producto y variantes;
- resolución previa/confirmada del slug de categoría;
- baja segura de tipo de producto y asociación tipo-característica;
- propagación versionada del esquema de tipo y renombre de valores `LISTA`;
- 404 de operación maestra;
- 404 de auditoría de precios;
- límite contractual de exportación de auditoría;
- auditoría transversal SPEC/HU/WF contra el contrato administrativo en los bloques identificados.

Pendientes actuales:

| ID | Punto pendiente | Contraparte |
|---|---|---|
| OPEN-01 | Registrar permisos `inventario:reservar`, `inventario:consumir`, `inventario:liberar` | Seguridad |
| OPEN-02 | Registrar `productos:fisicos:leer` para `modulo-despacho` | Seguridad / Despacho |
| OPEN-03 | Formalizar contrato de devolución aceptada/reintegro físico | Ventas/Postventa |
| OPEN-04 | Homologar comando externo de consumo definitivo de cupón | Ventas/Postventa |
| OPEN-05 | Documentar transporte definitivo de `customer_ref` | Seguridad / Ventas |
| OPEN-06 | Formalizar preparación inicial Catálogo → Pricing | Interno |
| OPEN-07 | Formalizar inicialización de SKU Catálogo → Inventario | Interno |
| OPEN-08 | Añadir pruebas consumidor-productor Ventas ↔ Inventario | Ventas |
| OPEN-09 | Añadir pruebas consumidor-productor Despacho ↔ Datos físicos | Despacho |
| OPEN-10 | Corregir documentación Retail para quitar consumo directo | Retail |
| OPEN-12 | Definir topología física RabbitMQ para despliegue | Productos y Ofertas |

La validación final de congelamiento de documentación/artefactos se trata como actividad de release, no como contrato abierto.

# 39. Artefactos contractuales

Estructura recomendada:

```text
Productos-y-Ofertas-docs/
├── Contrato_Api.md
├── api/
│   ├── openapi.yaml
│   ├── catalogo-errores.md
│   ├── catalogo-eventos.md
│   └── kit-integracion.md
├── asyncapi/
│   └── asyncapi.yaml
├── specs/
├── hu/
├── flujos/
└── wireframes/
```

### Responsabilidades

`Contrato_Api.md`:

- explica la integración;
- ownership;
- decisiones;
- flujos;
- límites.

`api/openapi.yaml`:

- rutas;
- métodos;
- parámetros;
- DTOs;
- respuestas;
- seguridad HTTP.

`asyncapi/asyncapi.yaml`:

- eventos;
- comandos;
- resultados;
- canales lógicos;
- envelopes;
- schemas asíncronos;
- productores/consumidores;
- semántica de entrega.

`api/catalogo-eventos.md`:

- referencia humana de mensajería;
- correlación;
- idempotencia;
- retries/DLQ;
- flujos entre módulos.

`api/catalogo-errores.md`:

- códigos estables;
- aliases retirados;
- diferencias entre error HTTP y rechazo de negocio;
- gobierno de `Problem.code`.

---

# 40. Criterio de homologación

Un contrato con otro módulo se considera homologado cuando:

1. productor y consumidor están identificados;
2. ownership está claro;
3. ruta o nombre de evento está definido;
4. request/payload está versionado;
5. campos obligatorios están definidos;
6. errores/rechazos están definidos;
7. idempotencia está definida;
8. seguridad/scopes están definidos;
9. timeout/reintento está definido;
10. existen pruebas de contrato.

---

# 41. Conclusión contractual

Productos y Ofertas queda definido como owner de:

- catálogo;
- taxonomía;
- precios;
- promociones;
- cupones;
- recomendaciones;
- combos;
- inventario;
- datos físicos propios de SKU.

Los canales:

- consumen información comercial;
- consultan disponibilidad;
- no mutan directamente el inventario.

Ventas/Postventa:

- es owner del pedido;
- orquesta el ciclo de reserva y consumo de stock;
- reserva al entrar en `CREADO`;
- confirma consumo en `PAGADO`;
- libera ante pago no completado o anulación aplicable.

Despacho:

- consulta peso y dimensiones por SKU;
- define empaque y lógica logística;
- no consume ni reserva inventario.

Seguridad:

- autentica usuarios y servicios;
- publica JWKS/OpenID;
- registra scopes;
- permite introspección para operaciones sensibles.

La línea base documental de este contrato es OpenAPI `0.3.5-p0`, AsyncAPI `0.2.1-p0`, catálogo de errores `0.2.4-p0` y catálogo de eventos `0.2.1-p0`.

A partir de esta versión, cualquier cambio de rutas HTTP debe realizarse primero en `api/openapi.yaml`; los cambios de mensajería deben realizarse primero en `asyncapi/asyncapi.yaml`; después se actualizan los documentos humanos derivados.
