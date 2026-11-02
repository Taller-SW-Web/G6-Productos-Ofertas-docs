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

La plantilla H4 tiene 16 columnas, CSV UTF-8 o XLSX de una hoja sin macros, archivo máximo 10,485,760 bytes, 5,000 filas de datos y 50 MiB descomprimidos para XLSX; encabezados exactos y SKU sin duplicados. Los literales de las 16 cabeceras deben provenir de la propuesta de plantilla de `apps/bulk-svc/docs/` antes de aceptar archivos productivos. Hasta contar con esos encabezados publicados, solo se implementa y prueba con fixtures explícitos.

Las rutas de importación propia de Pricing `prevalidarImportacionPrecios`/`crearImportacionPrecios` quedan fuera del gate H4: no se declaran implementadas ni se devuelve `202` ficticio sin formato y worker específicos. Las operaciones de precio individuales/programadas y sus eventos oficiales pueden avanzar por separado.

La exportación no es snapshot ACID multi-servicio: captura `requested_at` UTC, fija ese instante en consultas que acepten `at`, y registra en manifiesto Bulk los instantes observados por dominio y versiones disponibles. El resultado es un consolidado observado. Fallo en una fuente requerida produce `FAILED_GENERAL`; no se publica como completa una exportación parcial. Reintentos conservan identidad; reejecución explícita usa nuevo intento/versión sin sobrescribir un artefacto publicado.
