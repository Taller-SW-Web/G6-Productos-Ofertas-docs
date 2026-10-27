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
- Si no existe resultado concluyente, Catálogo mantiene `PENDING` y no habilita retry por tiempo sin `published_at` de publicación confirmada. El umbral inicial y las demás condiciones están en §7. Catálogo no inspecciona directamente la DLQ del consumidor.
- Todo `REJECTED` de Pricing permanece no reintentable salvo que se acredite para un código específico la causa, la operación correctiva publicada y replay idempotente probado. La ruta HTTP solo admite estados autorizados por esa política. Si corresponde retry, revalida precondiciones anti-TOCTOU, conserva `operation_id`, genera `message_id` nueva y cambia a `PENDING` con `manual_retry_allowed=false`; `202` es solo admisión.

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
- Para `PENDING`, el timeout solo habilita evaluación si existe `published_at` de publicación confirmada del intento vigente y transcurrieron 300000 ms; además se exigen replay idempotente verificado, intención idéntica, admisión transaccional y un único ganador concurrente (ver §7). Sin `published_at` no se habilita por timeout.
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

## 7. Alineación de Catálogo (puntos 1–6)

Esta sección concreta las reglas funcionales de Catálogo y prevalece sobre cualquier descripción anterior incompatible en esta SPEC. La decisión comunicada sustenta el criterio funcional, pero no acredita ratificación externa, implementación ni despliegue.

### Elegibilidad comercial

La misma regla aplica a `MARKETPLACE`, `CHATBOT`, `RETAIL` y `VENTAS`: un producto simple `ACTIVO` expone `sku_base`; un producto con variantes se expone cuando su padre está `ACTIVO` y al menos una variante está `ACTIVA`, y solo se exponen variantes activas cuyo padre también está activo. Borradores, productos inactivos, variantes inactivas y padres sin variantes activas no son elegibles. No hay defaults ni asignaciones por canal. El parámetro `canal` permanece para el contexto solicitado, incluido Pricing, y no amplía consumidores autorizados. Aplicar elegibilidad antes del conteo y la paginación; el detalle por ID/slug no elegible responde `404 PRODUCTO_NO_ENCONTRADO`; una búsqueda elegible vacía responde `200` con `total=0`. Visibilidad no garantiza precio, stock ni promoción. D-CAT-05/06: decisión comunicada; pendiente de ratificación de Arquitectura y conformidad de consumidores.

### Filtros monetarios

`precioMin` y `precioMax` son extremos opcionales e inclusivos del precio efectivo vigente informado por Pricing: `precio_oferta` vigente, en otro caso `precio_regular`. Pricing resuelve herencia y precedencia SKU/canal/global; Catálogo no las recalcula. Solo se comparan importes `PEN`, verificando `currency` sin convertir ni interpretar otra moneda como PEN. Los valores negativos/no finitos o `precioMin > precioMax` son `400 VALIDACION`. En productos simples se compara `sku_base`; con variantes basta un SKU activo/elegible dentro del rango y el padre se cuenta una vez. Consultar todos los candidatos antes de paginar en lotes de 1–100 SKU a `GET /api/v1/precios`, fijando un único `at` con zona horaria por consulta y usando el `canal` solicitado. SKU ausente sin precio vigente no satisface el filtro. Filtrar, deduplicar, calcular `total`, ordenar por `NOMBRE_ASC`/`NOMBRE_DESC` con desempate por `product_id` y paginar al final. Mantener el orden por defecto del contrato. Error de Pricing, respuesta inválida o procesamiento incompleto detectado responde `503 SERVICIO_NO_DISPONIBLE`, sin resultados parciales; ausencia legítima de precio no equivale por sí sola a lote incompleto. Sin filtro monetario no se consulta Pricing para filtrar. Mapeo SKU→producto, canales y autorización Catálogo↔Pricing siguen como dependencias de integración no homologadas.

### Código de barras

Un SKU vendible tiene cero o más códigos; cada código exacto, opaco y globalmente único pertenece a un solo SKU, incluso después del retiro. Se preservan ceros iniciales sin imponer simbología o longitud. Producto simple usa `sku_base`; con variantes usa el SKU de la variante, nunca el SKU base no vendible del padre. No se exige código para activar. Solo `GESTOR_COMERCIAL` administra altas, consulta por SKU y retiro lógico; código y propietario son inmutables y no se reasignan ni reutilizan. Desactivar conserva la asociación. La resolución entrega SKU solo si el código está vigente y el SKU es comercialmente elegible; si no, `404 CODIGO_BARRAS_NO_ENCONTRADO`, sin consultar precios o stock. Una reactivación vuelve a resolver solo si la asociación sigue vigente. La migración candidata `sku_barcodes` en backend `poma` no acredita aplicación en base de datos ni homologación; la ratificación formal está pendiente de trazabilidad. OpenAPI y su DTO de resolución permanecen sin cambios por esta regla.

### Corrección de tipo (Q-06)

El PATCH existente admite la propiedad opcional `tipoProductoId`. Solo se permite en `BORRADOR`, con `tiene_variantes=false`, cero filas reales en `catalog.variants`, `publicado_alguna_vez=false`, tipo nuevo `ACTIVO` en Taxonomy, atributos compatibles con el esquema y `schemaVersion`, y concurrencia validada por `catalogVersion`. Publicación significa exclusivamente la primera transición confirmada `BORRADOR → ACTIVO`. El campo persistido `catalog.products.publicado_alguna_vez BOOLEAN NULL` requiere una futura migración versionada: nuevos productos empiezan en `false`, la primera activación confirmada lo fija en `true` atómicamente e irreversible; históricos son `NULL` salvo evidencia autoritativa y `NULL` bloquea la corrección. No inferirlo del estado actual.

Se conservan los atributos válidos; cualquier incompatibilidad rechaza toda la edición sin borrado automático, incluyendo atributos persistidos que permanezcan tras PATCH. El gestor envía la colección corregida; atributos obligatorios faltantes no bloquean guardar un borrador, solo activarlo. Se conservan `product_id`, `sku_base`, `tiene_variantes`, UUID y snapshots. Errores: `409 CAMBIO_ESTRUCTURAL_NO_PERMITIDO`, `409 VERSION_CONFLICT`, `422 TIPO_PRODUCTO_INVALIDO`, `400 VALIDACION`, `503 SERVICIO_NO_DISPONIBLE`; para incompatibilidad de atributos se reutiliza el error contractual vigente. Q-06 fue resuelta funcionalmente por Marco y López; columna, migración e implementación no están certificadas.

### Recuperación de preparaciones

Todo `REJECTED` es actualmente no reintentable (`manual_retry_allowed=false`). Solo un código específico podrá habilitarse después de acreditar causa real, operación correctiva publicada y recuperación idempotente probada. En particular, Inventory `UBICACION_NO_ENCONTRADA` e `IDEMPOTENCY_CONFLICT`, y rechazos de inicialización Pricing no acreditados (incluido `PRECIO_INVALIDO`, cuya presencia en ese evento no está acreditada), permanecen en `false`. `COMPLETED` es terminal. Para `PENDING`, el tiempo vencido por sí solo no basta: requiere publicación confirmada, intención idéntica, consumidor con replay idempotente verificado, admisión transaccional y un único reintento concurrente. Un reintento conserva `operation_id`, genera `message_id` nueva y correlaciona el resultado al nuevo intento, sin duplicar efectos; inválido = `409 PREPARACION_NO_REINTENTABLE`, y `202` solo confirma admisión.

Para entornos con mensajería real, el umbral inicial de `PENDING` es `CATALOG_PREPARATION_TIMEOUT_MS=300000` ms desde `published_at` de la publicación confirmada del intento vigente. Sin `published_at`, no habilitar timeout. En producción no homologada, dejar la variable sin configurar y el retry por timeout deshabilitado, sin default habilitante. Esto es distinto del timeout de 60 s de Taxonomy. Vera/Pricing y Taco/Inventory confirmaron compatibilidad de diseño; pruebas integradas y homologación están pendientes.

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

## Consulta privada de contexto SKU para Pricing

Catálogo entrega a Pricing el contexto autoritativo mediante `GET /api/v1/productos/skus/{sku}/contexto`, con el SKU codificado en el path sin alterar su valor. El diseño fue aprobado por Marco y se registra en el [acuerdo skuContext](../../integraciones/ACUERDO_PRICING_CATALOGO_SKU_CONTEXT.md); el [OpenAPI](../../contratos/http/openapi.yaml) gobierna la interfaz.

La respuesta reutiliza los cinco campos de `PricingCatalogContext`: identidad SKU/producto, indicador de variante, estado del SKU y elegibilidad comercial. Un SKU existente inactivo o inelegible responde `200` con sus flags; solo uno inexistente produce `404 SKU_NO_ENCONTRADO`. Los errores técnicos producen `503 SERVICIO_NO_DISPONIBLE` y se conservan `401/403` del contrato de Seguridad. No consulta precios ni disponibilidad para construir el contexto. Esta operación interna se autoriza exclusivamente a la identidad de Pricing propuesta en el acuerdo, con `serviceBearer`, `aud=api-productos` y `catalogo:leer`; confirmación de identidad y grant G7 pendientes. No amplía las allowlists comerciales.

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

Catálogo es owner de la capacidad de resolver un código de barras a un SKU vendible. Cada código exacto, opaco y globalmente único pertenece a un SKU; un SKU admite cero o más códigos, incluidos retiros lógicos que no liberan el valor para reutilizarse. La administración corresponde a `GESTOR_COMERCIAL`; la definición funcional D-CAT-01..04 está cerrada y el estado de la migración candidata se documenta en §7.

La lectura comercial por slug aplica:

```text
producto.status = ACTIVO
AND elegible_para_canal(producto, canal)
```

La política comunicada de D-CAT-05/06 aplica la elegibilidad común por estados descrita en §7, sin persistencia, default ni asignación por canal; requiere ratificación de Arquitectura y conformidad de consumidores.

Para producto simple, cuando exista una asociación vigente y el SKU sea elegible:

```text
codigo_barras → sku_base
```

Para productos con variantes, el código se asocia al SKU de la variante vendible, nunca al `sku_base` no vendible del padre. La resolución usa el mismo criterio de elegibilidad que ID/slug y no consulta precio ni stock; véase §7.

Desactivar el producto impide la resolución comercial mientras permanezca inactivo. No se define todavía si la asociación histórica se elimina/reutiliza.
<!-- HOMOLOGACION-HTTP-0.5.0:END -->

> **Integración G1 Marketplace H4 (2026-10-20):** G6 aceptó y comunicó M-01–M-09 (`ACEPTADO_G6_COMUNICADO_G1`). Esta SPEC gobierna reglas funcionales de su dominio; operaciones HTTP se verifican en [OpenAPI](../../contratos/http/openapi.yaml), el reparto/estado operativo en [Acuerdo G1–G6 H4](../../integraciones/ACUERDO_G1_G6_H4_2026-10-20.md) y [alineación](../../integraciones/ALINEACION_MARKETPLACE.md). No declarar runtime, grants G7, despliegue o E2E por esta referencia. Las dependencias de otros owners se limitan a la operación que les corresponde.
