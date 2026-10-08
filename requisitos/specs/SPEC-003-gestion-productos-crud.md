# SPEC-003 — Gestión de productos (CRUD principal)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** HU [HU-003](../hu/HU-003-gestion-productos-crud.md) | Wireframe [WF-003](..\..\ux\wireframes\flows\WF-003-gestion-productos-crud.md)

---

## 1. Modelo

Un producto puede ser:

```text
simple: sku_base = SKU vendible
con variantes: sku_base = identidad base; cada variante posee SKU vendible
```

Catálogo es owner de identidad, descripción, clasificación, imágenes, slug y perfil físico del producto simple.

Pricing es owner del precio. Inventario es owner del saldo.

## 2. Creación

El producto se crea en `BORRADOR` con:

- nombre;
- descripción;
- categoría;
- tipo de producto;
- marca;
- `sku_base`;
- `tiene_variantes`;
- precio base inicial.

Guardar borrador no exige imagen, completar características ni datos físicos.

## 3. Preparación de Pricing

Después de persistir el borrador, Catálogo registra la preparación en estado `PENDING` (`manual_retry_allowed=false`) y publica idempotentemente:

```text
pricing.product.initialization.requested
```

con:

```text
product_id
sku_base
precio_regular
moneda
channel_id = null
motivo_cambio = ALTA_PRODUCTO
```

Reglas del ciclo de Pricing:
- `PENDING` representa la operación en curso o en recuperación técnica automática ordinaria del consumidor; no equivale a error ni genera botón de reintento humano inmediato.
- Los fallos técnicos transitorios en el procesamiento de Pricing se recuperan automáticamente mediante la política RabbitMQ existente de ese servicio.
- Pricing emite resultado asíncrono con `causation_id = message_id` del comando requested correspondiente. Catálogo conserva internamente cuál es la `message_id` del intento activo y solo procesa resultados cuyo `causation_id` coincida con dicho intento, descartando/ignorando idempotentemente resultados tardíos de intentos anteriores como stale:
  - `pricing.product.initialization.completed` → pasa a `COMPLETED`. Acredita la existencia del primer precio del producto. Pricing publica `pricing.price.changed` después de su commit. Una preparación `COMPLETED` es terminal y nunca vuelve a ejecutarse.
  - `pricing.product.initialization.rejected` → pasa a `REJECTED`. Mantiene el producto en `BORRADOR` y registra el código de causa en `code`. No se reintenta automáticamente por infraestructura. El flag `manual_retry_allowed` es calculado y autoritativo en Catálogo. Un `REJECTED` solo puede volverse manualmente reintentable cuando su causa pueda recuperarse mediante capacidades actualmente publicadas. Si la resolución exige modificar un dato para el que no existe operación publicada (por ejemplo `precioBaseInicial`), `manual_retry_allowed` permanece en `false`.
- Si no existe resultado concluyente tras un umbral operativo configurable, Catálogo mantiene `PENDING` y puede habilitar recuperación manual estableciendo `manual_retry_allowed=true`. Catálogo no inspecciona directamente la DLQ del servicio consumidor ni la topología privada de RabbitMQ.
- La recuperación manual excepcional (`POST /api/v1/productos/{productoId}/preparacion/reintentar` con `dependencia=PRICING`) solo es admitida cuando `manual_retry_allowed=true`. Revalida autoritativamente precondiciones en backend (anti-TOCTOU), conserva la `operation_id` original de la preparación, genera una nueva `message_id` para la republicación y vuelve la dependencia a `PENDING` (`manual_retry_allowed=false`). Si la causa del rechazo exigiese alterar el precio base inicial, `manual_retry_allowed` permanece `false` pues no existe endpoint publicado para modificar precio base inicial en borrador.

No se genera precio base por variante.

## 4. Inicialización de Inventario

### Producto simple

Catálogo registra la preparación de Inventario en estado `PENDING` (`manual_retry_allowed=false`) y publica:

```text
inventory.sku.initialization.requested
sku = sku_base
variant_id = null
```

- Los fallos técnicos transitorios del consumidor de Inventario se recuperan automáticamente mediante su política RabbitMQ (máximo 3 reintentos con 30 s de espera antes de DLQ).
- Catálogo correlaciona los resultados asíncronos mediante `causation_id = message_id` del requested activo, ignorando resultados stale de intentos previos:
  - `inventory.sku.initialization.completed` → pasa a `COMPLETED`. Es terminal y nunca se repite.
  - `inventory.sku.initialization.rejected` → pasa a `REJECTED`. Mantiene el producto en `BORRADOR` y registra `code`. No se reintenta automáticamente. La edición del borrador desencadena reevaluación autoritativa de precondiciones en Catálogo para determinar si `manual_retry_allowed` pasa a `true`.
- Si no hay resultado tras el umbral operativo configurable, Catálogo puede habilitar `manual_retry_allowed=true` manteniendo `PENDING` sin inspeccionar la DLQ de Inventario.
- La recuperación manual para producto simple se solicita mediante `POST /api/v1/productos/{productoId}/preparacion/reintentar` con `dependencia=INVENTARIO`, conservando `operation_id`, emitiendo nueva `message_id` y reconstruyendo el payload con los datos actuales validados del SKU base.

### Producto con variantes

El padre no crea saldo ni inicialización física propia (`inventario=null`). Cada SKU de variante se inicializa y recupera desde SPEC-004. El endpoint de producto rechaza reintentar inventario si `tiene_variantes=true`.

## 5. Activación y operaciones administrativas de preparación

`BORRADOR -> ACTIVO` requiere:

1. datos mínimos válidos;
2. categoría/tipo/marca válidos;
3. características obligatorias completas;
4. imagen;
5. Pricing preparado con estado `COMPLETED`;
6. Inventario preparado con estado `COMPLETED` para `sku_base` si es simple, o para todas las variantes activas si usa variantes;
7. si usa variantes, al menos una variante activa que cumpla SPEC-004; las variantes en `BORRADOR` o `INACTIVA` no se ofrecen comercialmente ni bloquean al padre;
8. si es simple, perfil físico completo y válido; el padre con variantes no tiene peso ni dimensiones propios.

Durante el alta, un rechazo de Pricing/Inventario en las dependencias requeridas mantiene el producto en `BORRADOR`; no existe rollback distribuido ficticio. El rechazo de preparación de una variante no activa no bloquea por sí solo al padre ni lo inactiva.

### Operaciones administrativas de preparación

- `GET /api/v1/productos/{productoId}/preparacion`: permite a la UI del Gestor Comercial conocer el estado real de cada dependencia (`status: PENDING | COMPLETED | REJECTED`, `manual_retry_allowed: boolean`, `code: string | null`) sin inferirlo de booleanos antiguos. Esta lectura consulta exclusivamente el estado local persistido de Catálogo sin realizar llamadas síncronas a Pricing ni a Inventario.
- `POST /api/v1/productos/{productoId}/preparacion/reintentar`: solicita recuperación manual de Pricing o del Inventario del `sku_base`. La admisión es **atómica por preparación**: exactamente una solicitud concurrente pasa `manual_retry_allowed=true` a `PENDING / manual_retry_allowed=false` y devuelve HTTP `202 Accepted` (`OperationAccepted`) con la `operation_id` original. `202` formaliza admisión del reintento, no éxito final. Las solicitudes concurrentes competidoras o las realizadas sobre preparaciones en curso técnico, ya completadas o sin precondiciones validadas devuelven HTTP `409 PREPARACION_NO_REINTENTABLE`. Nunca se producen dos publicaciones RabbitMQ ni dos efectos de negocio.

## 6. Perfil físico

Para producto simple, el perfil físico se modela bajo la estructura contractual:

```text
perfilFisico.pesoKg > 0
perfilFisico.dimensionesCm.largo > 0
perfilFisico.dimensionesCm.ancho > 0
perfilFisico.dimensionesCm.alto > 0
```

Unidades contractuales obligatorias: kilogramos (`kg`) y centímetros (`cm`).

El borrador puede tener perfil físico incompleto; los valores informados deben ser positivos. Para activar o reactivar un producto simple, los cuatro valores deben estar completos. El volumen se deriva de las dimensiones y no se ingresa como un dato independiente.

Despacho consulta los datos físicos mediante:

```http
POST /api/v1/productos/datos-fisicos/consulta
```

con `sub=modulo-despacho`, `aud=api-productos`, `scope=productos:fisicos:leer`.

## 7. Edición/desactivación

- `sku_base` no se recodifica por edición ordinaria.
- `tiene_variantes` no cambia tras publicar identidad.
- La edición actualiza el mismo producto y conserva su naturaleza comercial y la coherencia con sus variantes; no crea ni sustituye variantes. Un cambio que represente otro producto requiere una nueva alta, no reutilizar la identidad existente.
- Antes de guardar una edición de un producto `ACTIVO`, se valida el resultado completo contra las condiciones de activación. Si alguna deja de cumplirse, se rechaza la edición y se conservan los datos y el estado anteriores, sin desactivación automática.
- La baja es lógica.
- Desactivar publica `catalog.product.deactivated`.
- Desactivar al padre bloquea comercialmente todas sus variantes, conservando sus estados individuales.
- Reactivar vuelve a validar las condiciones (incluyendo Pricing e Inventario `COMPLETED`) y no reactiva automáticamente variantes inactivas. Reactivar una variante tampoco reactiva al padre.

## 8. Criterio de completitud

La capacidad queda completa cuando el CRUD, preparación de Pricing e inicialización de Inventario son idempotentes, las recuperaciones manuales conservan `operation_id`, emiten nueva `message_id`, correlacionan resultados por `causation_id` descartando mensajes stale, y la activación nunca presupone que un `requested` o `202` ya terminó correctamente.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Extensión 0.5.0 — identidad y exposición comercial

Se formaliza:

```text
product_id != variant_id != sku != codigo_barras
producto simple → sku_base = SKU vendible
```

Catálogo es owner de la capacidad de resolver un código de barras a un SKU vendible. Cada código resoluble identifica exactamente un SKU. La cardinalidad inversa SKU→código(s) y la administración de la asociación siguen abiertas (`D-CAT-01..04`).

La lectura comercial por slug aplica:

```text
producto.status = ACTIVO
AND elegible_para_canal(producto, canal)
```

`ACTIVO` no implica visibilidad automática en todos los canales. La persistencia y default de elegibilidad continúan abiertos (`D-CAT-05/06`).

Para producto simple, cuando exista una asociación resoluble:

```text
codigo_barras → sku_base
```

Desactivar el producto impide la resolución comercial mientras permanezca inactivo. No se define todavía si la asociación histórica se elimina/reutiliza.
<!-- HOMOLOGACION-HTTP-0.5.0:END -->
