# HU-001 — Historia de Usuario: Carga y exportación masiva de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** Spec [SPEC-001](./specs/SPEC-001-carga-exportacion-masiva-productos.md) | Flow [WF-001](./wireframes/flows/WF-001-carga-exportacion-masiva-productos.md)

**Como** gestor comercial,  
**quiero** descargar el catálogo completo y cargar archivos Excel o CSV estructurados por SKU vendible,  
**para** registrar nuevos productos/variantes o actualizar masivamente los existentes coordinando Catálogo, Pricing e Inventario de forma asíncrona.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | La plantilla vacía y la exportación se estructuran por SKU vendible. El límite de 5,000 filas / 10 MB aplica a importación; la exportación completa no se trunca. |
| CA-02 | La importación usa la plantilla oficial sin mapeo dinámico; estructura/cabeceras inválidas producen rechazo total en prevalidación. |
| CA-03 | La plantilla distingue `CREAR_PRODUCTO_SIMPLE`, `CREAR_VARIANTE` y `ACTUALIZAR`; `variant_id` lo genera Catálogo y `sku` comercial puede informarse o autogenerarse según la operación. |
| CA-04 | En `ACTUALIZAR`, una celda vacía conserva el valor actual. |
| CA-05 | Las imágenes se informan mediante URL; no se incrustan archivos físicos. |
| CA-06 | Errores parciales no invalidan filas correctas; se muestra resumen y CSV de errores. |
| CA-07 | El procesamiento es asíncrono, correlacionado por `batch_id`/`row_id`, idempotente y sin transacción distribuida global. |
| CA-07A | Una fila solo es exitosa cuando todos los dominios requeridos confirman aplicación. Un fallo definitivo informa efectos parciales y necesidad de conciliación. |
| CA-08 | Las escrituras condicionadas usan `catalog_version`, `price_version` y/o `stock_version`; una versión obsoleta se rechaza. |
| CA-09 | Fórmulas, macros o contenido activo provocan rechazo total; la exportación protege cadenas que pudieran interpretarse como fórmulas. |
| CA-10 | Se auditan usuario, timestamp, Batch ID y archivo procesado. |
| CA-11 | Producto padre nuevo con múltiples filas de variante se crea una sola vez en `BORRADOR` si los metadatos compartidos son coherentes. |
| CA-12 | `pricing.price.changed` e `inventory.stock.adjusted` son hechos posteriores al commit, no comandos de escritura. |
| CA-13 | No se afirma rollback distribuido. El reporte identifica dominios aplicados, fallido y conciliación. |
| CA-14 | Un conteo absoluto de stock existente requiere `location_id` y `stock_version`; un cambio confirmado posterior provoca `VERSION_CONFLICT`. |
| CA-15 | El lote de importación se crea de forma asíncrona y permite consultar resultado. |
| CA-16 | La exportación incluye `exported_at` y versiones fuente y no promete snapshot ACID interdominio. |
| CA-17 | La plantilla general v2 conserva las 25 columnas y su orden contractual. |
| CA-18 | Descargar plantilla es inmediato; exportar catálogo crea trabajo asíncrono con `export_id`. |
| CA-19 | Un fallo general del worker conserva estado por fila y permite reanudar pendientes con el mismo `batch_id`. |
| CA-20 | `accion_precio_oferta` vacía/`CONSERVAR` conserva; `ESTABLECER` exige importe; `ELIMINAR` retira. |
| CA-21 | Marketplace, Chatbot y Retail no descuentan stock directamente. Si durante Bulk cambia el saldo por una operación de Inventario orquestada por Ventas/Postventa, la versión obsoleta se rechaza sin sobrescribir ese movimiento. |
| CA-22 | La preparación inicial de Pricing e Inventario para un SKU nuevo sigue siendo una dependencia funcional; los nombres/payloads de los comandos específicos Catálogo → Pricing/Inventario no se consideran homologados hasta publicarse en AsyncAPI. |

## Escenarios dado-cuando-entonces

### Escenario 1: Exportación completa
**DADO** el gestor en Carga Masiva  
**CUANDO** solicita exportar el catálogo  
**ENTONCES** se crea una exportación asíncrona con `export_id` y, al concluir, se descarga el catálogo completo por SKU.

### Escenario 2: Plantilla vacía
**DADO** que necesita registrar productos/variantes  
**CUANDO** descarga la plantilla  
**ENTONCES** recibe XLSX/CSV v2 con cabeceras oficiales y ejemplos eliminables.

### Escenario 3: Importación exitosa
**DADO** un archivo válido de hasta 5,000 filas/10 MB  
**CUANDO** confirma la importación  
**ENTONCES** el Worker coordina los comandos bulk por dominio y solo declara exitosa cada fila tras todas las confirmaciones requeridas.

### Escenario 4: Celdas vacías
**DADO** un SKU existente con descripción vacía en el archivo  
**CUANDO** se modifica precio u otro campo informado  
**ENTONCES** la descripción actual se conserva.

### Escenario 5: Errores parciales
**DADO** filas válidas e inválidas  
**CUANDO** termina el procesamiento  
**ENTONCES** se aplican las válidas, se rechazan las inválidas y se ofrece CSV detallado.

### Escenario 6: Concurrencia de Inventario
**DADO** un conteo masivo basado en `stock_version=5`  
**CUANDO** Inventario confirma una reserva/consumo solicitado por Ventas/Postventa y eleva la versión a 6 antes de aplicar Bulk  
**ENTONCES** Inventario rechaza el conteo obsoleto con `VERSION_CONFLICT`; ningún canal se modela como mutador directo de stock.

### Escenario 7: Variante con SKU comercial opcional
**DADO** una fila `CREAR_VARIANTE`  
**CUANDO** Catálogo la acepta  
**ENTONCES** siempre genera `variant_id` y valida el SKU informado o genera uno si quedó vacío.

### Escenario 8: Fallo parcial multidominio
**DADO** Catálogo confirmado y Pricing rechazado definitivamente  
**CUANDO** concluye la fila  
**ENTONCES** queda fallida, informa el efecto parcial y requiere conciliación sin rollback global.

### Escenario 9: Conteo obsoleto
**DADO** una versión exportada anterior al saldo vigente  
**CUANDO** se intenta aplicar ese conteo  
**ENTONCES** se rechaza con conflicto de versión.

### Escenario 10: Contenido activo
**DADO** CSV/XLSX con fórmula/macros  
**CUANDO** se prevalida  
**ENTONCES** el archivo se rechaza íntegramente sin ejecutar su contenido.

### Escenario 11: Variantes de padre nuevo
**DADO** varias filas coherentes del mismo padre inexistente  
**CUANDO** se procesa el lote  
**ENTONCES** se crea un único padre BORRADOR y sus variantes.

### Escenario 12: Exportación superior a 5,000 SKU
**DADO** un catálogo con más de 5,000 SKU  
**CUANDO** se exporta  
**ENTONCES** el trabajo produce todas las filas; el límite corresponde únicamente a importación.

### Escenario 13: Fallo general y reanudación
**DADO** un lote parcialmente procesado  
**CUANDO** el worker agota reintentos transitorios  
**ENTONCES** el trabajo queda en fallo general y puede reanudarse con el mismo `batch_id` sin duplicar confirmados.

## Interacción con otros módulos

| Módulo | Necesidad | Información recibida | Información entregada |
|---|---|---|---|
| Seguridad y Usuarios | Autorizar y auditar | identidad/token | trazabilidad |
| Marketplace / Chatbot / Retail | Consumir cambios confirmados | no intervienen en la carga | cambios quedan disponibles eventualmente |
| Ventas/Postventa | Orquestar el ciclo de pedido que puede competir con Bulk sobre Inventario | no envía comandos a Bulk | sus operaciones pueden provocar cambio de versión en Inventario |
| Inventario | Autoridad del saldo | versión/saldo confirmado | resultado del ajuste masivo |
| Pricing | Autoridad del precio | versión/precio confirmado | resultado de aplicación |
| Catálogo | Autoridad del producto/SKU | identidad y relaciones | resultado de alta/actualización |

## Dependencias internas de Bulk

- `catalog.bulk.upsert.requested|completed|rejected`
- `pricing.bulk.price.apply.requested|completed|rejected`
- `inventory.bulk.stock.adjust.requested|completed|rejected`
- hechos posteriores al commit: `pricing.price.changed`, `inventory.stock.adjusted`, `inventory.stock.changed`

La inicialización específica de un SKU recién creado en Pricing/Inventario mantiene nombres/payloads pendientes de homologación.

## Reglas de negocio y arquitectura
- Importación: máximo 5,000 filas o 10 MB.
- Celdas vacías en actualización: conservar.
- Fila exitosa: todas las confirmaciones requeridas.
- Fallo parcial: reportar efectos y conciliación.
- Concurrencia: versionado optimista por dominio.
- Consistencia eventual e idempotencia.
- Canales de venta: consulta de disponibilidad, no mutación directa de Inventario.
