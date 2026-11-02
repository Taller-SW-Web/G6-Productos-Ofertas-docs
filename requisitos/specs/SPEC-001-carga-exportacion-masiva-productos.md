# SPEC-001 — Carga y exportación masiva de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** HU [HU-001](../hu/HU-001-carga-exportacion-masiva-productos.md) | Wireframe [WF-001](..\..\ux\wireframes\flows\WF-001-carga-exportacion-masiva-productos.md)

---

## 1. Objetivo

Permitir importaciones y exportaciones masivas reproducibles de catálogo sin mezclar ownership entre Catálogo, Pricing e Inventario.

- **Carga masiva:** permite procesar en lote datos de producto, SKU vendible, precio base inicial y stock inicial. Cada dominio persiste únicamente sus datos y responde de forma asíncrona.
- **Exportación masiva:** permite generar un consolidado asíncrono en formatos CSV o XLSX con la información vigente de catálogo, precios base/oferta y existencias de inventario sin degradar la operativa transaccional.

---

## 2. Regla de consistencia e importación multidominio

No existe una transacción distribuida Catálogo + Pricing + Inventario.

```text
Bulk valida archivo y plantilla
  -> Catálogo crea/actualiza borradores de productos y variantes
  -> Catálogo solicita preparación de Pricing (pricing.product.initialization.requested)
  -> Catálogo solicita inicialización de SKU en Inventario (inventory.sku.initialization.requested)
  -> Si la fila incluye stock inicial > 0 y existe ubicación: Bulk solicita ajuste masivo (inventory.bulk.stock.adjust.requested)
  -> Cada dominio responde de forma idempotente
  -> El lote consolida el resultado por fila y por dominio
```

### Gestión de fallos asimétricos y ausencia de rollback distribuido

Un fallo parcial no se oculta ni se compensa borrando datos confirmados de otro dominio:

- **Pricing completado + Inventario rechazado:** La fila queda en estado `FAILED`, registrando `applied_domains: [CATALOGO, PRICING]`, `failed_domain: INVENTARIO` y la bandera `needs_reconciliation: true`. Catálogo mantiene el borrador y Pricing conserva el precio base registrado; no se ejecuta compensación destructiva.
- **Pricing rechazado + Inventario completado:** La fila queda en estado `FAILED`, registrando `applied_domains: [CATALOGO, INVENTARIO]`, `failed_domain: PRICING` y `needs_reconciliation: true`. Catálogo e Inventario conservan los datos confirmados.
- **Catálogo rechazado:** La fila queda en estado `FAILED` con `failed_domain: CATALOGO` y no se emiten comandos hacia Pricing ni Inventario.

---

## 3. Inicialización de Pricing e Inventario

### Pricing

Para cada producto nuevo con precio base:

```text
pricing.product.initialization.requested
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

Resultados:

```text
pricing.product.initialization.completed
pricing.product.initialization.rejected
```

No se genera un precio inicial por variante: las variantes sin override heredan el precio del producto.

### Inventario

Para cada SKU vendible nuevo:

```text
inventory.sku.initialization.requested
```

Aplica a:

```text
producto simple -> sku_base
producto con variantes -> cada SKU de variante
```

El padre con variantes no crea saldo.

#### Manejo de default_location_id

- Si existe `default_location_id`, el saldo inicial se crea con existencias en cero:

```text
on_hand = 0
reserved = 0
blocked = 0
available = 0
stock_version = 0
```

- Si no existe ubicación predeterminada (`default_location_id = null`), Inventario **no** rechaza la solicitud: registra la identidad del SKU sin saldo y responde `inventory.sku.initialization.completed`. El saldo se creará posteriormente con el primer movimiento o recepción en una ubicación específica.

Resultados:

```text
inventory.sku.initialization.completed
inventory.sku.initialization.rejected
```

### Procesamiento de stock inicial

Inicializar un SKU en saldo cero **no equivale** a aplicar el stock cargado en el archivo. Si la fila del archivo incluye existencias iniciales mayores a cero (`stock_inicial > 0`) y la inicialización fue confirmada:

- Si existe `default_location_id`, el servicio Bulk solicita la aplicación de stock mediante el contrato Bulk de Inventario:

```text
inventory.bulk.stock.adjust.requested
```

Resultados:

```text
inventory.bulk.stock.adjust.completed
inventory.bulk.stock.adjust.rejected
```

- Si **no** existe ubicación predeterminada (`default_location_id = null`), no se inventa una ubicación: la fila se reporta con observación/error de ubicación y no se emite el comando de ajuste masivo.

---

## 4. Exportación masiva de catálogo

Permite a los gestores comerciales exportar la totalidad del catálogo activo para análisis externo, auditoría o integración de canales.

### Endpoints técnicos (OpenAPI 0.4.0)

- `POST /carga-masiva/productos/exportaciones`: solicita la generación de un trabajo de exportación indicando el formato (`CSV` o `XLSX`). Responde `202 Accepted` con esquema `TrabajoExportacion` y estado `QUEUED`.
- `GET /carga-masiva/productos/exportaciones/{exportId}`: consulta el estado del trabajo (`QUEUED`, `PROCESSING`, `COMPLETED`, `FAILED_GENERAL`).
- `GET /carga-masiva/productos/exportaciones/{exportId}/archivo`: descarga directa del archivo consolidado una vez alcanzado el estado `COMPLETED`.

### Reglas de exportación

1. **Procesamiento desacoplado:** La exportación se procesa en segundo plano para evitar tiempos de espera excesivos en llamadas síncronas.
2. **Consolidación observada:** La exportación captura `requested_at` UTC y registra por fuente instantes de observación/versiones disponibles; no existe snapshot atómico multi-servicio. Un fallo en fuente requerida termina `FAILED_GENERAL` sin publicar parcial como completa.
3. **Formatos soportados:** Exclusivamente `CSV` y `XLSX` (sin filtros de segmentación en la petición según `CrearExportacionProductosRequest`).

---

## 5. Idempotencia y reintentos

- El lote de importación tiene identidad estable (`batch_id`).
- Cada comando interno transporta `message_id`, `operation_id` y `correlation_id`.
- Reprocesar el mismo lote mediante `POST /carga-masiva/productos/importaciones/{batchId}/reanudar` no duplica productos, precios iniciales ni saldos; únicamente reanuda operaciones pendientes o reconciliables (`needs_reconciliation: true`).
- Reutilizar una identidad idempotente para una intención distinta produce conflicto (`409 IDEMPOTENCY_CONFLICT`).

---

## 6. Estados del lote y reporte

Estados de importación:

```text
QUEUED
PROCESSING
COMPLETED
FAILED_GENERAL
```

- Si todas las filas concluyen exitosamente, el lote pasa a `COMPLETED`.
- Si existen filas con fallo, el lote se marca como `COMPLETED` con `failed_rows > 0` y `needs_reconciliation: true` (o funcionalmente `COMPLETED_CON_ERRORES`).
- El reporte descargable (`GET /carga-masiva/productos/importaciones/{batchId}/reporte`) discrimina el resultado por fila y detalla el dominio fallido (`failed_domain`), código canónico (`code`) y mensaje (`detail`).

---

## 7. Criterios mínimos

- El archivo no puede producir SKU duplicados.
- Pricing conserva ownership del precio.
- Inventario conserva ownership del stock.
- Una variante no recibe precio base propio salvo override posterior.
- Si no existe `default_location_id`, Inventario registra la identidad del SKU sin saldo y no rechaza la inicialización.
- No se inventa una ubicación de Inventario cuando el proyecto no tiene `default_location_id` y la fila solicita aplicar stock inicial.
- El reporte final distingue errores por fila y por dominio sin invocar compensaciones destructivas entre servicios.
- La exportación de catálogo se procesa de forma asíncrona y no bloquea las consultas transaccionales.

Bulk coordina el procesamiento mediante `catalog.bulk.upsert.*` tipados en AsyncAPI; no crea rutas paralelas ni omite validaciones, identidad SKU, versiones, barreras o transacciones locales de Catalog. La estructura por fila/dominio se define en AsyncAPI 0.6.0-rc.4, con referencias a DTO de Catalog del OpenAPI; los pasos de Pricing/Inventory siguen separados y no se simula éxito de dominio.

## Addendum G6 H4 — DEC-G6-INT-08/09/10

Este addendum complementa las reglas anteriores y resuelve las dependencias contractuales de Bulk; los campos de importación/exportación descritos abajo prevalecen sobre cualquier cláusula anterior que dejara el payload pendiente. Bulk v2 es la entrada única de carga multidominio y no escribe directamente en Catalog, Pricing ni Inventory. `catalog.bulk.upsert.requested` lleva batch/row operation IDs estables, template_version 2, modo ALTA/ACTUALIZACION y filas SKU con referencias a DTO de Catalog de OpenAPI; Catalog agrupa por `sku_base`, persiste el padre una sola vez y rechaza atributos contradictorios. Resultados `completed` son por fila y pueden incluir rechazos; `rejected` representa rechazo previo al procesamiento por fila. Idempotencia por row_operation_id y payload semántico; conflicto de payload ⇒ `IDEMPOTENCY_CONFLICT`. No hay rollback distribuido; Bulk consolida `applied_domains`, `failed_domain` y `needs_reconciliation` y no inventa éxito de otros dominios.

La plantilla H4 tiene 16 columnas, CSV UTF-8 o XLSX de una hoja sin macros, archivo máximo 10,485,760 bytes, 5,000 filas de datos y 50 MiB descomprimidos para XLSX; encabezados exactos y SKU sin duplicados. Los literales y reglas de transformación de Bulk v2 se publican normativamente en la sección “Plantilla Bulk v2” de esta SPEC. Los CSV reproducibles están en [`tests/contratos/fixtures/bulk-v2/`](../../tests/contratos/fixtures/bulk-v2/). Esta publicación documental no declara implementación, homologación, despliegue ni aceptación de archivos productivos.

Las rutas de importación propia de Pricing `prevalidarImportacionPrecios`/`crearImportacionPrecios` quedan fuera del gate H4: no se declaran implementadas ni se devuelve `202` ficticio sin formato y worker específicos. Las operaciones de precio individuales/programadas y sus eventos oficiales pueden avanzar por separado.

La exportación no es snapshot ACID multi-servicio: captura `requested_at` UTC, fija ese instante en consultas que acepten `at`, y registra en manifiesto Bulk los instantes observados por dominio y versiones disponibles. El resultado es un consolidado observado. Fallo en una fuente requerida produce `FAILED_GENERAL`; no se publica como completa una exportación parcial. Reintentos conservan identidad; reejecución explícita usa nuevo intento/versión sin sobrescribir un artefacto publicado.

## Plantilla Bulk v2 — encabezados y transformación normativa

La siguiente tabla fija los **16 encabezados exactos**, su orden y la regla de transformación. CSV UTF-8 debe usar coma y comillas dobles RFC 4180; XLSX debe contener una hoja declarada, sin macros. Una fila representa un SKU vendible. No se agregan columnas alias ni campos al contrato AsyncAPI.

| # | Encabezado exacto | Tipo/obligatoriedad | Regla y transformación |
|---:|---|---|---|
| 1 | `operacion` | `ALTA` o `ACTUALIZACION`, obligatorio | La plantilla v2 exige un solo valor para todo el archivo. Se transforma en `data.mode` del comando; el modo es por comando en AsyncAPI, y la regla por archivo pertenece a esta plantilla. |
| 2 | `producto_id` | ID opaco de Catalog | Vacío en ALTA; obligatorio en ACTUALIZACION; se asigna a `rows[].producto_id`. |
| 3 | `catalog_version` | JSON de versiones | Vacío en ALTA. En actualización: `{"producto":3,"variante":2}` o `{"producto":3,"variante":null}`; `producto` es entero no negativo obligatorio y `variante` entero no negativo o null. Se transforma a `product.catalogVersion` y, al actualizar variante, `variant.catalogVersion`. Versiones de padre e hija no se sustituyen entre sí. |
| 4 | `sku_base` | Texto no vacío, obligatorio | Identificador de agrupación del producto. En ALTA se asigna al campo externo `sku_base` y a `product.skuBase`; en ACTUALIZACION se verifica contra el producto existente y no se recodifica. |
| 5 | `sku_variante` | Texto | Simple: vacío; variante: SKU explícito, único y no vacío. ALTA → `variant.sku`. ACTUALIZACION: no se envía SKU en DTO de variante; resolver SKU a `variant_id` mediante lectura contractual autorizada de Catalog. La consulta actual exige identidad `GESTOR_COMERCIAL`, no autorizada a Bulk. Requiere allowlist interna restringida conforme a DEC-G6-INT-01, verificación de producto padre/SKU, rechazo por ausencia/ambigüedad/inconsistencia y revalidación en la transacción de Catalog. No reenviar JWT de usuario, inventar principal ni consultar SQL cross-schema. Pendiente de Poma. |
| 6 | `nombre` | Texto | Obligatorio no vacío en ALTA; se asigna a `product.nombre`; en actualización solo se envía si cambia. |
| 7 | `descripcion` | Texto | Obligatoria no vacía en ALTA; se asigna a `product.descripcion`; vacía en ACTUALIZACION significa sin cambio, no borrado. |
| 8 | `categoria_id` | ID opaco Taxonomy | Obligatorio en archivo; ALTA → `product.categoriaId`; actualización se verifica y puede mapearse al campo permitido del DTO si se modifica. Catalog revalida maestro. |
| 9 | `marca_id` | ID opaco Taxonomy | Obligatorio; ALTA → `product.marcaId`; actualización se verifica y puede mapearse al campo permitido del DTO si se modifica. Catalog revalida maestro. |
| 10 | `tipo_producto_id` | ID opaco Taxonomy | Obligatorio en archivo; ALTA → `product.tipoProductoId`. En ACTUALIZACION debe coincidir con el tipo existente y no se envía para migrar estructura. |
| 11 | `tiene_variantes` | Booleano estricto (`true` o `false`, minúscula) | Obligatorio. ALTA → `product.tieneVariantes`; en ACTUALIZACION debe coincidir con la estructura existente y no se cambia. |
| 12 | `precio_regular` | Decimal positivo, punto decimal | Obligatorio en ALTA; se transforma a `product.precioBaseInicial` de ProductoCreateRequest. Catalog persiste el producto y solicita una vez `pricing.product.initialization.requested`; Bulk no publica otra inicialización ni escribe en Pricing. ACTUALIZACION: no forma parte de ProductoUpdateRequest; valor no vacío se rechaza con el error contractual existente `PLANTILLA_INCOMPATIBLE`. No se descarta ni se declara soportado un paso de cambio de precio. |
| 13 | `atributos_producto` | Array JSON de Atributo | ALTA: celda vacía equivale a `[]`; de informarse, contiene la lista completa. Cada atributo requiere `caracteristica_id`, `nombre`, `valor`; `valor_id` es opcional en OpenAPI, pero esta plantilla exige incluirlo siempre como string o null. En actualización vacío = sin cambio; se validan los atributos permitidos por DTO y Taxonomy. |
| 14 | `atributos_variante` | Objeto JSON con arrays `identificadores` y `no_identificadores` para variantes; celda vacía permitida para producto simple | ALTA variante: ambos arrays según DTO y al menos un identificador requerido. ALTA simple: celda vacía, sin exigir objeto JSON; se transforma a `variant=null` en AsyncAPI. ACTUALIZACION variante: `identificadores` vacío; solo se permite cambiar atributos no identificadores. ACTUALIZACION simple: celda vacía y `variant=null`. Sin SKU, identidad ni atributos identificadores mutables. |
| 15 | `imagen_url` | URI absoluta | ALTA variante: obligatoria → `variant.imagenUrl`. Producto simple: si se informa, convertir a `product.imagenes:[{"url":"...","principal":true}]`. ACTUALIZACION variante: opcional → `variant.imagenUrl`; simple: si se informa, actualizar la lista de imágenes mediante DTO permitido. |
| 16 | `stock_inicial` | Entero no negativo | Vacío equivale a 0. No pertenece al DTO Catalog. SKU se inicializa separadamente en Inventory; identidad inicializada sin saldo no prueba stock positivo. Si stock > 0, solo solicitar ajuste cuando haya ubicación autorizada/verificada y contrato Bulk de Inventory operativo. Mientras `inventory.bulk.stock.adjust.requested` esté pendiente, el dominio INVENTARIO no se declara completado para la fila con saldo solicitado. |

### Archivo, orden y agrupación

- Máximo **10 485 760 bytes** por archivo, **5 000 filas de datos** y **50 MiB** de contenido XLSX descomprimido. Rechazar excesos, inconsistencias y contenido activo antes de producir efectos. XLSX: una hoja declarada, sin macros; CSV: UTF-8.
- Cabeceras literales exactas y orden fijo como la tabla. IDs/SKU son texto opaco (no normalizar a UUID ni número). JSON de celda debe parsear. Rechazar fila vacía intermedia, SKU vendible duplicado en el archivo, fórmulas, macros, vínculos externos peligrosos, XLSX malformado u hoja adicional.
- Filas del mismo `sku_base` forman una familia contigua; todos los datos del padre deben concordar. Producto simple: una fila, sin `sku_variante` y con `atributos_variante` vacía; esta celda se transforma a `variant=null` en AsyncAPI. Producto con variantes: una fila por variante vendible, SKU distinto, combinación identificadora distinta. El padre con variantes no constituye SKU vendible ni saldo.
- Las familias no se dividen al particionar mensajes. Toda fila tiene `row_number` de archivo y un `row_operation_id` UUID que Bulk genera y persiste antes de publicación, estable para esa fila lógica entre reintentos; no es una cabecera CSV. El archivo se representa con un `batch_id`; cada comando/chunk con un `batch_operation_id` UUID distinto, persistido antes de publicación y estable para ese comando entre reintentos; cada `row_operation_id` es estable para su fila según su alcance contractual. El `operation_id` del envelope es el `batch_operation_id` del chunk y `correlation_id` permanece estable para el batch. El registro durable de Outbox conserva exactamente su `message_id`, payload e identidad de operación cuando se reintenta su publicación. Mensajes distintos pueden representar una operación semántica ya procesada: el consumidor mantiene idempotencia por identidad de operación, sin depender exclusivamente de `message_id`. Persistir la relación batch→chunks→filas/row_operation_id→correlación→resultado para reanudación y consolidación. Usar campos existentes de envelope, mensajes y workflow; no sumar campos AsyncAPI ni eventos.
- Medir el envelope serializado completo en UTF-8. Cada comando debe ser menor o igual a **1 048 576 bytes**. Empaquetar familias completas de `sku_base` en orden estable; crear nuevo chunk solo entre familias. Si una familia sola excede el máximo, rechazarla antes de publicación; no fragmentarla ni elevar límite. `mode` es homogéneo dentro de cada comando. Un solo `operacion` por archivo es regla de plantilla v2, no una obligación deducible solo de AsyncAPI.
- `batch_operation_id` identifica intención de comando/chunk; al reintentar conserva ID y payload. `row_operation_id` se conserva por fila lógica. Igual row ID + mismo payload semántico reproduce resultado sin efectos; otro payload produce `IDEMPOTENCY_CONFLICT`; cambiar `message_id` no duplica efecto. `completed` describe el comando procesado y sus resultados por fila, que pueden incluir rechazos; `rejected` es rechazo previo al procesamiento por fila. Se conservan `CatalogBulkUpsertRequestedData`, `CatalogBulkUpsertCompletedData`, `CatalogBulkUpsertRejectedData` y las referencias DTO existentes de AsyncAPI 0.6.0-rc.4/OpenAPI 0.6.0-rc.2; no se agregan eventos, columnas o campos.

### Transformación por modo y versiones

| Entidad | ALTA | ACTUALIZACION |
|---|---|---|
| Producto | ProductoCreateRequest: `nombre`, `descripcion`, `categoriaId`, `tipoProductoId`, `marcaId`, `precioBaseInicial`, `skuBase`, `tieneVariantes`, atributos e imágenes aplicables. | ProductoUpdateRequest solo con campos permitidos modificados y `catalogVersion`. Sin cambio de `sku_base`, `tiene_variantes` ni migración estructural; tipo debe coincidir. |
| Variante | VarianteCreateRequest: `sku`, atributos identificadores y no identificadores, `imagenUrl`. | Resolver `variant_id`; VarianteUpdateRequest solo `atributosNoIdentificadores`, `imagenUrl`, perfil físico y `catalogVersion`. No enviar ni modificar SKU o atributos identificadores. |
| Pricing | Catalog emite inicialización oficial una vez después de persistir el padre. | Precio no está en DTO update. Valor no vacío de `precio_regular` se rechaza hasta una operación Pricing explícitamente soportada. |
| Inventory | Inicializar cada SKU vendible; padre con variantes no crea saldo. | No convertir `stock_inicial` en reemplazo de saldo; ajuste es paso separado. |

Si varias filas actualizan variantes del mismo padre, Catalog agrupa el comando por `sku_base`, comprueba que la versión esperada del padre sea única y aplica la mutación del padre como máximo una vez por transacción. Luego aplica cada variante con su propia versión esperada. No repetir la mutación del padre por fila ni comparar filas posteriores con la versión incrementada durante el mismo comando. Contradicción de versión del padre dentro de la familia rechaza la familia. Actualizaciones de variante conservan SKU, identidad y atributos identificadores.

### Fixtures reproducibles y ejemplos inválidos

- [Plantilla CSV v2 (solo cabecera)](../../tests/contratos/fixtures/bulk-v2/plantilla-v2.csv)
- [Ejemplo válido de producto simple](../../tests/contratos/fixtures/bulk-v2/ejemplo-simple-v2.csv)
- [Ejemplo válido de producto con dos variantes](../../tests/contratos/fixtures/bulk-v2/ejemplo-variantes-v2.csv)

Los ejemplos usan identificadores opacos de las fixtures de AsyncAPI (por ejemplo, categoria-1, marca-1, tipo-1, talla), URLs reservadas para ejemplo y stock 0, por lo que no dependen de una ubicación. Son fixtures de contrato/documentación, no prueba de que esos maestros existan en un entorno ni de ejecución E2E.

| Ejemplo inválido | Resultado esperado antes de efectos |
|---|---|
| Cabecera ausente, reordenada, alias o columna extra; fila no tiene exactamente 16 celdas | Rechazar plantilla con `PLANTILLA_INCOMPATIBLE`. |
| JSON inválido, atributo sin `caracteristica_id`/`nombre`/`valor`, o sin `valor_id` explícito en la plantilla | Rechazar fila/plantilla sin emitir comandos. |
| SKU duplicado o dos filas simples para un producto simple; variante sin SKU/identificador/imagen requerida | Rechazar fila/familia; no transformar alta en actualización. |
| ACTUALIZACION sin producto_id/catalog_version, familia con distintas versiones parentales, variante ausente/ambigua o de otro padre | Rechazar la fila/familia; la variante requiere lectura Catalog autorizada y revalidación transaccional. |
| ACTUALIZACION con `precio_regular` informado o cambios de SKU/estructura/identificadores de variante | Rechazar conforme al error contractual existente; no mutar Catalog/Pricing. |
| Archivo > 10 485 760 bytes, > 5 000 filas, XLSX > 50 MiB expandido, macros, fórmulas o contenido activo | Rechazar archivo antes de efectos con el error HTTP existente aplicable. |
| `stock_inicial > 0` sin ubicación verificable o con ajuste Bulk aún no operativo | No declarar INVENTARIO completado ni inventar ubicación; documentar la divergencia de inicialización más abajo. |

### Divergencia de implementación Inventory — seguimiento Taco

**Regla normativa de SPEC-001:** si `default_location_id` es null, Inventory debe registrar la identidad del SKU sin saldo y responder `inventory.sku.initialization.completed`; nunca rechazar solo por ausencia de ubicación. El stock positivo es una operación posterior. Si no hay ubicación, no emitir ajuste ni inventar una ubicación.

**Código inspeccionado en el checkout Backend disponible (no es prueba runtime):** el handler toma `default_location_id` del mensaje; no se identificó configuración ni lectura contratada por Bulk para obtenerlo. Si falta, el código selecciona la única ubicación activa cuando hay exactamente una (crea saldo cero), y responde `UBICACION_NO_ENCONTRADA` si no hay ubicaciones o hay varias. Ambos resultados divergen de la regla de SPEC-001: cuando falta default debe conservar identidad sin saldo y completar la inicialización. DEC-G6-INT-08/09 no aprueban cambiar esa regla funcional.

**Acción:** Taco debe adaptar el handler para que ausencia de `default_location_id` persista identidad sin saldo y emita el resultado de inicialización aprobado; conservar validación de un ID provisto cuando aplique. La ubicación debe provenir de Inventory mediante configuración/mecanismo autorizado; Bulk no consulta SQL ajeno ni inventa ID. Mantener pruebas provider/consumer pendientes hasta que haya evidencia por SHA. `inventory.sku.initialization.completed` confirma la inicialización de identidad, no el ajuste de stock positivo. El ajuste `inventory.bulk.stock.adjust.requested` permanece pendiente de contrato operativo/implementación; una fila que solicitó saldo no puede declarar el dominio INVENTARIO completado mientras el ajuste no concluya.

### Estado de implementación e integración (no equivale a aprobación contractual externa)

| Responsable | Pendiente verificable |
|---|---|
| Poma / Catalog | Handler funcional `catalog.bulk.upsert.requested`; upsert de padre una sola vez por familia; lectura interna autorizada SKU→variant_id con allowlist DEC-G6-INT-01; revalidación e idempotencia transaccional. |
| Vera / Pricing | Consumidor de `pricing.product.initialization.requested`, persistencia idempotente y resultados oficiales. No flujo paralelo de importación ni inicialización duplicada por Bulk. |
| López / Taxonomy | Lecturas de detalle/esquema de tipos, características, asociaciones y valores conforme a endpoints existentes en OpenAPI que requiere CatalogMasterClient. |
| Taco / Inventory | Corregir divergencia de inicialización sin ubicación; contrato/handler de ajuste masivo de stock; resultados e idempotencia. |
| Marco / Bulk | Storage privado, API HTTP/worker de Bulk, parser, límite 1 MiB, chunking durable y consolidación por fila/dominio. |
| Owners de integración | Adaptadores AMQP y pruebas provider/consumer, broker aislado y E2E. Sin declaración de homologación, despliegue o funcionalidad por publicar esta SPEC/fixtures. |
