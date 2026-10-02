# API Contract — Módulo de Productos y Ofertas

**Fecha de actualización:** 2026-10-01  
**Módulo propietario:** Productos y Ofertas  
**Documento de integración:** `Contrato_Api.md`  
**Contrato HTTP canónico:** `api/openapi.yaml` (`0.4.0`)  
**Contrato asíncrono canónico:** `asyncapi/asyncapi.yaml` (`0.4.0`)  
**Catálogo de eventos:** `api/catalogo-eventos.md` (`0.4.0`)  
**Catálogo de errores canónico:** `api/catalogo-errores.md` (`0.4.0`)  
**Estado:** OpenAPI, AsyncAPI, topología RabbitMQ y recepción de traslados consolidados en `0.4.0`.

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
- Contrato de integración publicado por Seguridad y Usuarios:
  - `Taller-SW-Web/Modulo-de-Seguridad/specs/openapi.yaml`;
  - `Taller-SW-Web/Modulo-de-Seguridad/specs/kit-integracion.md`.
- Contrato de integración publicado por Despacho y Entrega
- Documentación de integración de Chatbot, Retail y Ventas/Postventa
- Acuerdo directo con Ventas/Postventa:
  - reserva al entrar el pedido en `CREADO`;
  - consumo definitivo al pasar a `PAGADO`;
  - liberación ante `PAGO_NO_COMPLETADO` o anulación aplicable;
  - Ventas/Postventa orquesta todo el ciclo de inventario;
  - Marketplace y Chatbot únicamente consultan disponibilidad; Retail además puede reportar/resolver incidencias físicas, sin ejecutar mutaciones comerciales de venta.
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
| `GET` | `/api/v1/productos` | stable | Marketplace / Chatbot / Retail |
| `GET` | `/api/v1/productos/{productoId}` | stable | Marketplace / Chatbot / Retail |
| `GET` | `/api/v1/categorias` | stable | Marketplace / Chatbot / Retail |
| `GET` | `/api/v1/marcas` | stable | Marketplace / Chatbot / Retail |
| `GET` | `/api/v1/precios` | stable | Marketplace / Chatbot / Retail |
| `GET` | `/api/v1/precios/skus/{sku}` | stable | Marketplace / Chatbot / Retail |
| `GET` | `/api/v1/promociones` | stable | Marketplace / Chatbot / Retail |
| `POST` | `/api/v1/promociones/evaluar` | stable | Marketplace / Chatbot / Retail |
| `POST` | `/api/v1/cupones/validar` | stable | Marketplace / Chatbot / Retail |
| `GET` | `/api/v1/recomendaciones` | stable | Chatbot |
| `GET` | `/api/v1/combos/{comboId}` | stable | Sin concesión externa inicial |
| `GET` | `/api/v1/inventario/disponibilidad` | stable | Canales / Ventas |
| `POST` | `/api/v1/inventario/reservas` | provisional | Solo Ventas/Postventa |
| `POST` | `/api/v1/inventario/reservas/{reservaId}/confirmar` | provisional | Solo Ventas/Postventa |
| `POST` | `/api/v1/inventario/reservas/{reservaId}/liberar` | provisional | Solo Ventas/Postventa |
| `POST` | `/api/v1/inventario/reintegros` | provisional | Solo Ventas/Postventa |
| `POST` | `/api/v1/inventario/conciliaciones-offline` | provisional | Solo Ventas/Postventa |
| `POST` | `/api/v1/inventario/incidencias` | provisional | Solo Retail |
| `POST` | `/api/v1/inventario/incidencias/{incidenciaId}/resolver` | provisional | Solo Retail |
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

La desactivación/desasociación de entidades con dependencias usa el protocolo asíncrono genérico de baja segura. AsyncAPI `0.4.0` cubre también:

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

`api/openapi.yaml` (`0.4.0`) es la fuente de verdad HTTP de Pricing. La superficie distingue consultas estables para consumidores y operaciones administrativas internas derivadas de SPEC-013.

## 7.1. Consultas estables para consumidores

```http
GET /api/v1/precios
GET /api/v1/precios/skus/{sku}
```

`GET /api/v1/precios` resuelve precios de varios SKU y admite contexto de canal y fecha (`at`) según OpenAPI.

`GET /api/v1/precios/skus/{sku}` resuelve el precio vigente o histórico de un SKU. Puede recibir `canal` y `at`; cuando existe un alcance específico de canal se aplica el fallback global definido por Pricing.

Estas rutas usan el contrato técnico `precios:leer` cuando son invocadas módulo-a-módulo por consumidores autorizados.

## 7.2. Administración de precio base y override

OpenAPI `0.4.0` publica además:

| Método | Ruta | Estado |
|---|---|---|
| `PATCH` | `/api/v1/precios/skus/{sku}` | `stable` |
| `GET` | `/api/v1/precios/skus/{sku}/programaciones` | `provisional-internal` |
| `POST` | `/api/v1/precios/skus/{sku}/programaciones` | `provisional-internal` |
| `GET` | `/api/v1/precios/productos/{productoId}` | `provisional-internal` |
| `PATCH` | `/api/v1/precios/productos/{productoId}` | `provisional-internal` |
| `GET` | `/api/v1/precios/productos/{productoId}/programaciones` | `provisional-internal` |
| `POST` | `/api/v1/precios/productos/{productoId}/programaciones` | `provisional-internal` |

El endpoint de producto devuelve el precio base administrativo del producto. En `0.4.0` no publica el parámetro `at`; el histórico temporal por `at` está definido en la consulta por SKU. Las rutas `/programaciones` permiten consultar las vigencias programadas del SKU o del producto.

Una variante sin override hereda el precio del producto. Un cambio específico del SKU crea o modifica el override administrado por Pricing.

## 7.3. Concurrencia y vigencias

Las actualizaciones de producto/SKU utilizan `priceVersion` de la lectura previa. Si la versión quedó obsoleta:

```text
409 VERSION_CONFLICT
```

No se admiten vigencias superpuestas para el mismo objetivo y canal:

```text
409 VIGENCIA_SUPERPUESTA
```

Las programaciones usan `validFrom` futuro y `validUntil` opcional. El contrato de programación no exige `priceVersion` en el request.

## 7.4. Carga masiva exclusiva de Pricing

La carga local de Pricing es distinta de la carga general coordinada por SPEC-001.

Prevalidación sin mutar precios:

```http
POST /api/v1/precios/importaciones/prevalidar
```

Admisión asíncrona:

```http
POST /api/v1/precios/importaciones
```

Una respuesta:

```text
202 Accepted
status = QUEUED
batch_id = <id del lote>
```

confirma únicamente que el lote fue admitido.

Seguimiento y reporte:

```http
GET /api/v1/precios/importaciones/{batchId}
GET /api/v1/precios/importaciones/{batchId}/reporte
```

Estados del lote:

```text
QUEUED
PROCESSING
COMPLETED
PARTIAL
FAILED
```

Las filas rechazadas no modifican precios ni publican `pricing.price.changed`.

## 7.5. Autorización de Pricing

La administración humana utiliza JWT de usuario y el rol global:

```text
GESTOR_COMERCIAL
```

Las lecturas administrativas y la prevalidación siguen la validación ordinaria local mediante JWKS.

Las mutaciones sensibles marcadas por OpenAPI requieren además introspección antes de ejecutar o admitir el cambio:

```http
PATCH /api/v1/precios/skus/{sku}
POST  /api/v1/precios/skus/{sku}/programaciones
PATCH /api/v1/precios/productos/{productoId}
POST  /api/v1/precios/productos/{productoId}/programaciones
POST  /api/v1/precios/importaciones
```

La introspección se realiza contra Seguridad y Usuarios con el scope técnico `tokens:introspeccion`.

`PRICING_READ`, `PRICING_WRITE`, `PRICING_BULK` y equivalentes, si existen en implementación, son capacidades internas de Productos y Ofertas; no son scopes externos que Seguridad deba publicar.

## 7.6. Publicación y auditoría

Toda mutación de precio confirmada persiste su cambio y Outbox en la transacción local. Después del commit, Pricing publica:

```text
pricing.price.changed
```

`price-audit-svc` consume el hecho de forma desacoplada. Pricing no escribe directamente la bitácora de auditoría.

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

La unidad autoritativa se identifica por:

```text
(sku, location_id)
```

Inventario mantiene:

```text
on_hand
reserved
blocked
available
stock_version
```

donde:

- `on_hand`: unidades físicamente contabilizadas;
- `reserved`: unidades comprometidas por reservas activas;
- `blocked`: unidades físicamente existentes pero temporalmente no vendibles por incidencia/cuarentena;
- `available`: unidades que pueden comprometerse en una nueva operación.

Regla:

```text
available = max(on_hand - reserved - blocked, 0)
```

Invariantes:

```text
on_hand >= 0
reserved >= 0
blocked >= 0
reserved + blocked <= on_hand
available >= 0
```

## 11.2. Consulta de disponibilidad

```http
GET /api/v1/inventario/disponibilidad
```

Consumidores:

- Marketplace;
- Chatbot;
- Retail;
- Ventas/Postventa.

La consulta:

- no crea reserva;
- no garantiza unidades futuras;
- puede consultar una ubicación concreta;
- devuelve `blocked` en `0.4.0`;
- calcula el estado sobre `available`.

Estados mínimos:

```text
AGOTADO
STOCK_BAJO
DISPONIBLE
```

Marketplace y Chatbot son consumidores de lectura. Retail también puede reportar/resolver **incidencias físicas**, pero eso no lo autoriza a reservar, consumir, liberar o reintegrar unidades por una venta.

---

# 12. Flujo oficial de reserva, consumo y compensación

El ownership se mantiene:

```text
Pedido / pago / devolución comercial -> Ventas/Postventa
Saldo / reserva / Kardex             -> Productos y Ofertas
Hecho físico de tienda               -> Retail reporta; Inventario decide el saldo
```

Flujo normal:

```text
Canal
  -> Ventas crea pedido CREADO
      -> Ventas solicita reserva
  -> pago aprobado
      -> Ventas pasa a PAGADO
      -> Ventas confirma consumo
```

Flujo pre-consumo:

```text
CREADO + PAGO_NO_COMPLETADO/anulación aplicable
  -> Ventas libera reserva
```

Flujo post-consumo:

```text
PAGADO / reserva CONSUMIDA
  -> nunca se "libera" la reserva consumida
  -> si las unidades regresan físicamente y Postventa las acepta:
       Ventas solicita reintegro
```

Venta Retail offline:

```text
Retail vende offline
  -> persiste ventaLocalUuid
  -> al recuperar conexión registra la venta en Ventas
  -> Ventas solicita conciliación offline a Inventario
```

Incidencia física:

```text
Retail detecta daño/no ubicación
  -> POST /inventario/incidencias
  -> Inventario incrementa blocked
  -> la unidad deja de estar disponible para todos los canales
```

## 12.1. Responsabilidad de los canales

Marketplace y Chatbot:

- consultan catálogo/beneficios/disponibilidad;
- crean el pedido mediante Ventas/Postventa;
- nunca mutan Inventario.

Retail:

- realiza lo anterior;
- puede reportar y resolver una incidencia física con scopes dedicados;
- no ejecuta reserva, consumo, liberación, reintegro ni conciliación comercial directamente.

## 12.2. Responsabilidad de Ventas/Postventa

Ventas/Postventa:

- reserva al crear pedido `CREADO`;
- confirma consumo al pasar a `PAGADO`;
- libera reservas pre-consumo;
- autoriza reintegros únicamente cuando existe recepción física aceptada;
- registra primero la venta offline y luego solicita conciliación;
- conserva ownership del pedido, pago y devolución comercial.

## 12.3. Responsabilidad de Productos y Ofertas

Inventario:

- es única autoridad de `on_hand`, `reserved`, `blocked`, `available` y `stock_version`;
- valida idempotencia y concurrencia;
- registra Kardex en toda mutación autoritativa;
- nunca permite saldo negativo;
- no decide política comercial de devolución;
- no interpreta una incidencia física como pedido ni pago.

---

# 13. Comandos HTTP de Inventario

## 13.1. Crear reserva

```http
POST /api/v1/inventario/reservas
scope: inventario:reservar
client_id: modulo-ventas
```

`202 Accepted` significa **comando admitido**, no reserva finalizada. El resultado definitivo se correlaciona mediante los eventos/resultados vigentes de AsyncAPI.

## 13.2. Confirmar consumo

```http
POST /api/v1/inventario/reservas/{reservaId}/confirmar
scope: inventario:consumir
client_id: modulo-ventas
```

Precondición comercial: pedido `PAGADO`.

Efecto:

```text
on_hand -= quantity
reserved -= quantity
blocked no cambia
available se recalcula
```

## 13.3. Liberar reserva

```http
POST /api/v1/inventario/reservas/{reservaId}/liberar
scope: inventario:liberar
client_id: modulo-ventas
```

Aplica mientras la reserva siga activa. Una reserva `CONSUMIDA` no se libera.

## 13.4. Reintegrar unidades postventa

```http
POST /api/v1/inventario/reintegros
scope: inventario:reintegrar
client_id: modulo-ventas
```

Condición contractual:

```text
devolución/retorno aceptado
+
unidades físicamente recibidas
+
unidades declaradas reintegrables
```

Una devolución comercial aprobada por sí sola **no** incrementa stock.

Efecto exitoso:

```text
on_hand += quantity
available se recalcula
```

La respuesta `200` es autoritativa e idempotente.

## 13.5. Conciliar venta Retail offline

```http
POST /api/v1/inventario/conciliaciones-offline
scope: inventario:conciliar-offline
client_id: modulo-ventas
```

Ventas debe haber registrado primero la venta.

Inventario:

- aplica como máximo unidades actualmente `available`;
- no consume `reserved` ni `blocked`;
- nunca genera `on_hand < 0`;
- devuelve `COMPLETED` cuando todo pudo aplicarse;
- devuelve `REQUIRES_REVIEW` y `unresolved_quantity` cuando existe discrepancia.

## 13.6. Reportar incidencia física

```http
POST /api/v1/inventario/incidencias
scope: inventario:incidencias:reportar
client_id: modulo-retail
```

Tipos iniciales:

```text
DANIO
NO_UBICADA
OTRO_FISICO
```

Efecto:

```text
blocked += quantity
on_hand no cambia
available se recalcula
```

Solo puede bloquearse cantidad actualmente disponible.

## 13.7. Resolver incidencia física

```http
POST /api/v1/inventario/incidencias/{incidenciaId}/resolver
scope: inventario:incidencias:resolver
client_id: modulo-retail
```

Resoluciones:

```text
REHABILITADO
MERMA
FALTANTE_CONFIRMADO
TRASLADO_ALMACEN_CENTRAL
```

Efectos:

```text
REHABILITADO:
  blocked -= quantity
  on_hand no cambia

MERMA / FALTANTE_CONFIRMADO:
  blocked -= quantity
  on_hand -= quantity

TRASLADO_ALMACEN_CENTRAL:
  salida de la ubicación origen;
  destino no aumenta hasta confirmación de recepción.
```

## 13.8. Recepción de traslado a almacén central

Cuando Retail resuelve una incidencia como:

```text
TRASLADO_ALMACEN_CENTRAL
```

Inventario crea un traslado interno y descuenta la unidad del origen:

```text
source.on_hand -= quantity
source.blocked -= quantity
source.available se mantiene/recalcula
```

El destino no aumenta todavía.

La recepción es una **operación humana de Inventario**, no de Retail ni de Despacho.

Rutas:

```http
GET  /api/v1/inventario/traslados
GET  /api/v1/inventario/traslados/{trasladoId}
POST /api/v1/inventario/traslados/{trasladoId}/recepciones
```

Autorización:

```text
userBearer
capacidad local INVENTARIO_TRASLADOS_LEER
capacidad local INVENTARIO_TRASLADOS_RECIBIR
```

No se crea un rol global nuevo en Seguridad. Productos vincula esas capacidades a un perfil local por `sub`.

Disposiciones de recepción:

```text
REINGRESAR_DISPONIBLE
REINGRESAR_BLOQUEADO
CONFIRMAR_MERMA
```

Efectos:

```text
REINGRESAR_DISPONIBLE:
  destino.on_hand += received_quantity
  destino.available += received_quantity

REINGRESAR_BLOQUEADO:
  destino.on_hand += received_quantity
  destino.blocked += received_quantity
  destino.available no aumenta

CONFIRMAR_MERMA:
  no se acredita stock en destino
  se registra Kardex/resultado de recepción
```

Recepción parcial:

```text
final_receipt = false
-> RECIBIDO_PARCIAL
```

Cierre con faltante:

```text
final_receipt = true
quantity_received < quantity_shipped
-> COMPLETADO_CON_DISCREPANCIA
missing_quantity > 0
```

Nunca se acredita una cantidad no recibida físicamente.

## 13.9. TTL de reserva

El TTL continúa configurable por entorno/canal. Expirar una reserva reduce `reserved`, no `blocked`.

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

Retail **no** consume inventario por una venta.

Flujo comercial:

```text
Retail -> Ventas/Postventa -> Inventario
```

Por tanto, Retail no recibe:

```text
inventario:reservar
inventario:consumir
inventario:liberar
inventario:reintegrar
inventario:conciliar-offline
```

Sí recibe capacidades físicas acotadas:

```text
inventario:incidencias:reportar
inventario:incidencias:resolver
```

Estas capacidades no convierten a Retail en owner del saldo. Retail reporta el hecho y la resolución/acta; `inventory-svc` valida invariantes, aplica el movimiento y registra Kardex.

En modo offline:

```text
Retail bloquea localmente la UX de la tienda
-> encola la venta/incidencia
-> al recuperar conexión sincroniza
```

Una venta offline se envía primero a Ventas/Postventa y **Ventas** solicita la conciliación de Inventario. Una incidencia física puede sincronizarse directamente Retail -> Productos utilizando su identidad idempotente.

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

Productos y Ofertas adopta como fuente contractual de identidad el `specs/openapi.yaml` y el `specs/kit-integracion.md` publicados por **Seguridad y Usuarios**.

## 19.1. Identidad técnica del módulo

```text
client_id = modulo-productos
```

Scopes que Seguridad concede a `modulo-productos` para consumir la API de Seguridad:

```text
tokens:introspeccion
roles:leer
```

Estos scopes pertenecen a la API de Seguridad. No deben confundirse con los scopes que otros módulos utilizan para invocar `api-productos`.

---

## 19.2. Rol oficial del personal comercial

Seguridad publica el siguiente código de rol global:

```text
GESTOR_COMERCIAL
```

Su perfil contractual es:

```text
Administra catálogo, precios y promociones
```

Por tanto, Productos y Ofertas utiliza `GESTOR_COMERCIAL` como rol global para las operaciones administrativas de catálogo, taxonomía comercial, precios, promociones, cupones, combos, recomendaciones y SEO cuando corresponda.

Los roles viajan en el claim:

```text
roles
```

El claim `permisos` de Seguridad contiene permisos propios del módulo de Seguridad; Productos y Ofertas **no espera que Seguridad publique permisos de negocio internos como `PRICING_READ`, `PRICING_WRITE` o equivalentes**. La autorización de negocio se resuelve con `roles` y, cuando se requiera granularidad adicional, con datos/capacidades propias del módulo.

Un perfil que no forme parte de los seis roles globales de Seguridad —por ejemplo, un responsable operativo de inventario— puede mantenerse como perfil local asociado al `sub` del usuario, sin inventar un nuevo rol global.

---

## 19.3. Validación ordinaria de JWT de usuario

La validación normal de JWT se realiza **localmente** mediante JWKS cacheado.

Endpoints de Seguridad:

```http
GET /api/v1/auth/.well-known/openid-configuration
GET /api/v1/auth/.well-known/jwks.json
```

La aplicación valida firma, emisor y expiración de acuerdo con el contrato de Seguridad. Descargar el JWKS en cada request está prohibido; debe utilizarse caché y respetarse el `kid` durante rotaciones.

Para operaciones ordinarias del Gestor Comercial no se llama a introspección.

---

## 19.4. Introspección para cambios de precio

El kit de Seguridad establece que las operaciones sensibles usan introspección y documenta explícitamente **cambiar un precio** como operación sensible. Además, la tabla de scopes asigna `tokens:introspeccion` a Productos y Ofertas para **autorizar cambios de precio**.

En el contrato vigente de este módulo, las mutaciones que actualizan o programan precios, así como la admisión de la importación exclusiva de Pricing, deben introspeccionar el token de usuario antes de ejecutar/admitir el cambio:

```http
POST /api/v1/auth/introspeccion
```

La llamada se realiza con un token de servicio de `modulo-productos` que incluya:

```text
tokens:introspeccion
```

Si la respuesta contiene:

```json
{ "activo": false }
```

la operación se deniega.

Las lecturas y las operaciones administrativas no clasificadas como sensibles continúan con validación local mediante JWKS. Si Seguridad amplía en el futuro el conjunto de operaciones sensibles aplicables a Productos y Ofertas, este contrato y OpenAPI deben versionarse antes de exigir una nueva introspección.

---

## 19.5. Tokens de servicio emitidos por Seguridad

Productos obtiene su token para consumir APIs externas mediante:

```http
POST /api/v1/auth/token
```

con:

```text
grant_type=client_credentials
client_id=modulo-productos
```

Los secretos reales no forman parte de este repositorio.

Seguridad también emite scopes definidos por APIs de otros módulos. Para un token de servicio destinado a Productos y Ofertas, la audiencia contractual es:

```text
api-productos
```

El token técnico recibido por esta API debe validar, como mínimo:

```text
iss
aud contiene api-productos
tipo = servicio
exp vigente
scope requerido por la operación
```

Los scopes viajan en el claim `scope`, separados por espacios.

---

# 20. Autenticación de la API de Productos

OpenAPI define dos esquemas conceptuales:

```text
serviceBearer
userBearer
```

## `serviceBearer`

JWT técnico para comunicación módulo-a-módulo. Debe estar emitido por Seguridad, identificar al módulo cliente en `sub`, declarar `tipo=servicio`, incluir `api-productos` en `aud` y contener el scope exigido por la operación cuando exista `x-required-scope`.

## `userBearer`

JWT humano emitido por Seguridad. Para administración comercial se comprueba el rol `GESTOR_COMERCIAL`; los perfiles operativos locales se resuelven dentro de Productos y Ofertas usando el `sub`.

Las operaciones públicas SEO no requieren autenticación.

---

# 21. Scopes propios de `api-productos`

La audiencia técnica es:

```text
api-productos
```

`0.4.0` conserva **16 scopes**. El registro/concesión efectiva en Seguridad continúa marcado como pendiente hasta que G7 lo publique.

| Scope | Operaciones | Clientes previstos |
|---|---|---|
| `catalogo:leer` | `GET /productos`, detalle, categorías, marcas | Marketplace, Chatbot, Retail |
| `precios:leer` | Consultas de precios | Marketplace, Chatbot, Retail |
| `promociones:leer` | Consultar promociones | Marketplace, Chatbot, Retail |
| `promociones:evaluar` | Evaluar promociones | Marketplace, Chatbot, Retail |
| `cupones:validar` | Validar cupón | Marketplace, Chatbot, Retail |
| `recomendaciones:leer` | `GET /recomendaciones` | Chatbot |
| `combos:leer` | Detalle/disponibilidad informativa de combos | Sin concesión externa inicial |
| `inventario:disponibilidad:leer` | Consultar disponibilidad | Marketplace, Chatbot, Retail, Ventas |
| `inventario:reservar` | Crear reserva | Ventas |
| `inventario:consumir` | Confirmar consumo | Ventas |
| `inventario:liberar` | Liberar reserva | Ventas |
| `inventario:reintegrar` | Reintegrar retorno físico aceptado | Ventas |
| `inventario:conciliar-offline` | Conciliar venta Retail offline | Ventas |
| `inventario:incidencias:reportar` | Reportar cuarentena física | Retail |
| `inventario:incidencias:resolver` | Resolver incidencia/acta | Retail |
| `productos:fisicos:leer` | Consultar peso/dimensiones | Despacho |

Matriz exacta solicitada:

```text
modulo-marketplace:
  catalogo:leer
  precios:leer
  promociones:leer
  promociones:evaluar
  cupones:validar
  inventario:disponibilidad:leer

modulo-chatbot:
  catalogo:leer
  precios:leer
  promociones:leer
  promociones:evaluar
  cupones:validar
  recomendaciones:leer
  inventario:disponibilidad:leer

modulo-retail:
  catalogo:leer
  precios:leer
  promociones:leer
  promociones:evaluar
  cupones:validar
  inventario:disponibilidad:leer
  inventario:incidencias:reportar
  inventario:incidencias:resolver

modulo-ventas:
  inventario:disponibilidad:leer
  inventario:reservar
  inventario:consumir
  inventario:liberar
  inventario:reintegrar
  inventario:conciliar-offline

modulo-despacho:
  productos:fisicos:leer
```

`combos:leer` existe contractualmente, pero permanece sin `client_id` externo hasta que exista un consumidor documentado.

Toda operación técnica declara:

```text
x-service-audience: api-productos
x-required-scope: <scope exacto>
x-scope-registration-status: pending-security-registration
```

Denegaciones:

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

---

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

Cierres HTTP relevantes de la línea base `0.4.0` / catálogo `0.4.0`:

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

AsyncAPI `0.4.0` documenta **39 mensajes lógicos** entre eventos, comandos internos y resultados.

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

P2 fija los nombres físicos de exchanges, queues, retry y DLQ en:

```text
api/rabbitmq-topologia.md
asyncapi/asyncapi.yaml
```

Los valores de entorno (host, credenciales, TLS y tamaño del cluster) siguen siendo configuración de infraestructura.
# 27. Resultados de Inventario

## Reserva/consumo/liberación

Se conserva el contrato asíncrono vigente:

```text
inventory.reservation.created
inventory.reservation.consumed
inventory.reservation.released
inventory.reservation.expired
inventory.consumption.completed
inventory.consumption.rejected
```

`202 Accepted` no equivale a finalización.

## Incidencias, reintegro y conciliación offline

Las cuatro capacidades añadidas en `0.4.0` devuelven un resultado HTTP autoritativo después de la transacción local:

```text
POST /inventario/incidencias                         -> 201
POST /inventario/incidencias/{id}/resolver           -> 200
POST /inventario/reintegros                          -> 200
POST /inventario/conciliaciones-offline              -> 200
```

No se crean nombres asíncronos nuevos solo para duplicar ese resultado.

Después del commit, Inventario puede publicar los hechos ya existentes:

```text
inventory.stock.changed
inventory.stock.adjusted
```

cuando corresponda.

Correlación/idempotencia externa:

```text
operation_id
Idempotency-Key
X-Correlation-Id
order_id cuando aplique
external_incident_id / offline_sale_id / source_ref cuando aplique
```

---

# 28. Devoluciones y reintegro físico

El ownership comercial de la devolución pertenece a Ventas/Postventa.

Estados comerciales como:

```text
SOLICITADA
EN_EVALUACION
APROBADA
```

no modifican por sí solos Inventario.

El reintegro se habilita únicamente cuando Ventas/Postventa confirma:

```text
devolución/retorno aceptado
+
producto físicamente recibido
+
producto reintegrable
```

Entonces invoca:

```http
POST /api/v1/inventario/reintegros
scope: inventario:reintegrar
```

Inventario registra Kardex e idempotencia.

Un producto devuelto que no sea vendible no se reintegra como `available`. Puede originar una incidencia física/cuarentena según el proceso operativo correspondiente.

---

# 29. Cancelaciones

La operación depende del estado real del Inventario.

## Antes del consumo

Si la reserva sigue `ACTIVA`:

```text
anulación / PAGO_NO_COMPLETADO
-> inventario:liberar
```

La liberación:

```text
reserved -= quantity
on_hand no cambia
blocked no cambia
```

## Después del consumo

Si la reserva ya está `CONSUMIDA`:

```text
NO liberar reserva
```

Una anulación comercial post-consumo puede provocar reembolso/extorno, pero **no incrementa stock automáticamente**.

Solo si las unidades retornan físicamente y Ventas/Postventa confirma que son reintegrables:

```text
-> inventario:reintegrar
```

Productos y Ofertas no decide el reembolso ni el estado comercial final del pedido.

---

# 30. `customer_ref`

Seguridad y Usuarios es owner de la identidad del cliente.

Contrato definitivo P1:

```text
customer_ref = claim sub del token de acceso (tipo=acceso) emitido por Seguridad
formato = UUID
```

Reglas:

- el canal obtiene `customer_ref` del `sub` del cliente autenticado;
- Ventas/Postventa persiste exactamente ese mismo valor como referencia del cliente del pedido;
- en el contrato actual de Ventas, `contacto.clienteId` debe homologarse a este valor;
- al consumir/restituir cupón, Ventas reutiliza el valor persistido en el pedido, no el token que exista en ese momento;
- el `sub` de un token de servicio (`modulo-chatbot`, `modulo-ventas`, etc.) **nunca** es `customer_ref`;
- un cliente anónimo utiliza `customer_ref=null`;
- si el cupón posee `max_usos_por_cliente`, `customer_ref=null` produce `CUSTOMER_REF_REQUERIDO`;
- Productos conserva la referencia como identificador opaco; no consulta ni replica perfil, documento, dirección, correo o teléfono.

Ejemplo:

```text
Security access token:
sub = 11111111-1111-1111-1111-111111111111

Productos:
customer_ref = 11111111-1111-1111-1111-111111111111

Ventas:
contacto.clienteId = 11111111-1111-1111-1111-111111111111
```

---


# 31. Contratos P1 cerrados

## 31.1. Chatbot — A5

Chatbot debe consumir las rutas publicadas de Productos:

```text
GET  /api/v1/productos
GET  /api/v1/productos/{productoId}
GET  /api/v1/categorias
GET  /api/v1/marcas
GET  /api/v1/precios
GET  /api/v1/inventario/disponibilidad
GET  /api/v1/promociones
POST /api/v1/promociones/evaluar
POST /api/v1/cupones/validar
GET  /api/v1/recomendaciones
```

La ruta:

```text
/recomendaciones/candidatos
```

no es contrato. Se reemplaza por:

```text
GET /recomendaciones?productoId=...&canal=CHATBOT
```

Los cuerpos de Productos conservan nombres contractuales `snake_case`, por ejemplo:

```text
channel_id
coupon_code
customer_ref
lines[].quantity
```

El BFF del Chatbot puede exponer otro naming a su frontend, pero debe traducir en el adaptador de integración.

## 31.2. Chatbot — A6

Chatbot no consume `/productos/datos-fisicos/consulta`.

Flujo definitivo:

```text
Chatbot
  -> Despacho: POST /api/v1/cotizaciones
     destino + lineas[{sku,cantidad}]
        -> Despacho
           -> Productos: POST /api/v1/productos/datos-fisicos/consulta
```

Productos entrega kg/cm a Despacho. Despacho calcula peso/volumen/costo/plazo. Chatbot no mantiene `pesos_por_categoria.yaml` como fuente autoritativa.

## 31.3. Chatbot — A7

`GET /api/v1/productos` soporta:

```text
q=<texto libre>
```

A7 queda cerrado.

## 31.4. Consumo de cupón

La validación del canal sigue siendo:

```http
POST /api/v1/cupones/validar
```

y **no consume**.

Flujo definitivo:

```text
1. Ventas crea pedido CREADO.
2. Ventas espera reserva de stock confirmada.
3. Ventas fija el snapshot comercial final del cupón.
4. Antes de permitir el intento de pago, Ventas publica:
   promotions.coupon.consumption.requested
5. promotions-svc consume el uso de forma atómica e idempotente.
6. Solo con promotions.coupon.consumption.completed el checkout puede continuar al pago.
```

Idempotencia de negocio:

```text
(order_id, cupon_id) = un único consumo
```

La concurrencia sobre el último uso se serializa dentro de `promotions-svc`.

El comando lleva `effective_at`: instante contra el cual se congeló la elegibilidad comercial. Al consumir se revalidan identidad, capacidad global/cliente y coherencia; no se recalcula ni sustituye el snapshot monetario del pedido.

## 31.5. Restitución de cupón

Cuando un pedido que ya consumió cupón se cancela:

```text
modulo-ventas
  -> promotions.coupon.restoration.requested
```

`promotions-svc` consulta el consumo por `order_id`.

Resultados:

```text
RESTAURAR_EN_CANCELACION -> restored=true
NO_RESTAURAR             -> restored=false / POLICY_KEEPS_CONSUMPTION
sin consumo previo        -> restored=false / NO_CONSUMPTION
```

La restitución es idempotente y nunca incrementa el cupo por encima del consumo realmente registrado.

## 31.6. Catálogo → Pricing

La preparación inicial se realiza a nivel de **producto**, conforme a SPEC-013:

```text
catalog-svc
  -> pricing.product.initialization.requested
  -> pricing-svc
  -> pricing.product.initialization.completed | rejected
```

Payload funcional:

```text
product_id
sku_base
precio_regular
moneda
channel_id = null
motivo_cambio = ALTA_PRODUCTO
```

Pricing registra el primer precio como `CREACION`, publica posteriormente `pricing.price.changed` y devuelve la confirmación de preparación a Catálogo.

Las variantes **no reciben un precio inicial artificial**: sin override, heredan el precio del producto; el override SKU es una operación posterior de Pricing.

## 31.7. Catálogo → Inventario

Todo SKU vendible se inicializa mediante:

```text
catalog-svc
  -> inventory.sku.initialization.requested
  -> inventory-svc
  -> inventory.sku.initialization.completed | rejected
```

Aplica a:

```text
producto simple -> sku_base
producto con variantes -> cada SKU de variante
```

No aplica al padre con variantes como saldo físico vendible.

Si `default_location_id` existe, el saldo inicial es:

```text
on_hand = 0
reserved = 0
blocked = 0
available = 0
stock_version = 0
```

Si no existe ubicación predeterminada, Inventario registra la identidad del SKU y crea el saldo cuando ocurra el primer alta/ajuste en una ubicación.

Catálogo puede activar la unidad comercial solo cuando las dependencias requeridas hayan confirmado preparación.


# 32. Información que Productos no debe solicitar

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

# 33. Contratos internos del módulo

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

# 34. Bulk

`bulk-svc` coordina importaciones/exportaciones y no escribe directamente en schemas de Catálogo, Pricing o Inventario.

Principios:

- comandos idempotentes;
- `batch_id`;
- `row_id`;
- confirmación por dominio;
- reconciliación ante aplicación parcial;
- no rollback distribuido ficticio.

La cobertura HTTP administrativa de Bulk ya forma parte del OpenAPI `0.4.0`. La forma exacta de rutas, requests, estados y errores se toma del contrato ejecutable; este documento conserva únicamente las reglas de ownership y coordinación.

---

# 35. Auditoría de precios

Price Audit conserva el historial inmutable de cambios de precio.

No se expone como parte de los contratos de canales; su superficie es administrativa.

OpenAPI `0.4.0` publica:

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

# 36. Versionado

## HTTP

Prefijo estable:

```text
/api/v1
```

Línea base del artefacto HTTP:

```text
OpenAPI 3.1.0
info.version = 0.4.0
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

# 37. Trazabilidad principal

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

# 38. Estado de integración por contraparte

| Contraparte | Estado en `0.4.0` | Definición vigente |
|---|---|---|
| Seguridad y Usuarios | Matriz cerrada; registro externo pendiente | 16 scopes definidos bajo `api-productos`; no se afirma concesión hasta que G7 lo registre |
| Ventas/Postventa | Flujo cerrado bajo supuesto de aceptación | Reserva, consumo, liberación, reintegro y conciliación offline |
| Chatbot | Alineado | Lectura/evaluación; no muta inventario |
| Retail | Ownership corregido | Ventas orquesta la venta; Retail solo consulta y reporta/resuelve incidencias físicas |
| Marketplace | Alineado | Canal de lectura/evaluación; mutaciones mediante Ventas |
| Despacho | Ownership cerrado | `POST /productos/datos-fisicos/consulta`, kg/cm, `productos:fisicos:leer`; Despacho calcula logística |

---


# 39. Topología RabbitMQ P2

VHost:

```text
/marketplace
```

Exchanges:

```text
po.commands.x
po.events.x
po.results.x
po.retry.x
po.dlx.x
po.unrouted.x
```

Reglas:

- routing key = nombre lógico del mensaje;
- colas principales, retry y DLQ son durables;
- colas principales usan quorum queues;
- publisher confirms obligatorios;
- ACK manual;
- `prefetch = 20` inicial;
- at-least-once;
- `message_id` para deduplicación;
- `operation_id` para idempotencia de negocio;
- Outbox en publisher e Inbox/dedupe en consumer;
- retry técnico: hasta 3 intentos con 30 s;
- rechazo de negocio válido no va a DLQ.

La tabla completa de queues/bindings vive en:

```text
api/rabbitmq-topologia.md
```

AsyncAPI `0.4.0` contiene la misma topología como `x-rabbitmq-topology`.


# 40. Pendientes de integración externa

Cerrados en P2:

- topología RabbitMQ física;
- recepción total/parcial de traslado a almacén central;
- autorización local del Gestor Comercial con capacidad de recepción de inventario.

Pendientes externos/de implementación:

| ID | Punto | Estado |
|---|---|---|
| OPEN-01 | Registro efectivo de los 16 scopes/grants de `api-productos` | Seguridad; supuesto aceptado para desarrollo |
| OPEN-08 | Contract tests Ventas ↔ Inventario contra `inventory-svc` real | Implementación |
| OPEN-09 | Consumer/provider tests Despacho ↔ Productos contra backends reales | Implementación |
| OPEN-14 | Sincronizar prototipos HTML con los WF definitivos | Después del freeze documental |

No queda una decisión funcional abierta de integración P0/P1/P2 dentro de la documentación contractual.
# 41. Artefactos contractuales

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

# 42. Criterio de homologación

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

# 43. Conclusión contractual

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
- publica los roles globales, incluido `GESTOR_COMERCIAL`;
- emite tokens de servicio con `aud` y `scope` para APIs propietarias;
- permite introspección para cambios de precio según el contrato vigente.

La línea base documental consolidada es OpenAPI `0.4.0`, AsyncAPI `0.4.0`, catálogo de errores `0.4.0` y catálogo de eventos `0.4.0`.

A partir de esta versión, cualquier cambio de rutas HTTP debe realizarse primero en `api/openapi.yaml`; los cambios de mensajería deben realizarse primero en `asyncapi/asyncapi.yaml`; después se actualizan los documentos humanos derivados.
