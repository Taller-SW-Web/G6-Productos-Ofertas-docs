# SPEC-001 — Especificación: Carga y exportación masiva de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** HU [HU-001](./hu/HU-001-carga-exportacion-masiva-productos.md) | Wireframe [WF-001](./wireframes/flows/WF-001-carga-exportacion-masiva-productos.md)

## 1. Contexto
El gestor comercial maneja frecuentemente un volumen amplio de productos, precios y existencias en el catálogo. Modificar o ingresar cientos de registros de forma manual a través de la interfaz web resulta ineficiente. Se requiere una vía para manejar grandes volúmenes de datos usando herramientas ofimáticas estructuradas (archivos XLSX o CSV), garantizando la correcta distribución de responsabilidades entre los dominios de Catálogo, Precios (Pricing) e Inventario.

## 2. Propósito
Proporcionar una herramienta para descargar el catálogo completo en una plantilla de Excel o CSV a nivel de SKU vendible, permitir su edición sin conexión, e importar dicho archivo para registrar o actualizar masivamente los registros en el sistema de forma asíncrona y desacoplada mediante **comandos idempotentes por dominio y eventos de resultados confirmados**.

## 3. Alcance
Incluye:

- Descarga de una plantilla vacía (Excel/CSV) con el formato predefinido de campos a nivel de SKU vendible y código de producto base.
- Exportación **asíncrona** del catálogo actual a un archivo Excel/CSV estructurado por SKU, con descarga posterior cuando concluya el trabajo.
- Importación asíncrona y validación por filas para creación y actualización masiva (límite de hasta 5,000 filas o 10 MB).
- Coordinación arquitectónica mediante un Worker/Job asíncrono que emite comandos idempotentes hacia Catálogo, Pricing e Inventario y consume sus resultados y eventos de cambio confirmados, correlacionados por `batch_id` y `row_id`.
- Seguimiento de estado por fila (`PENDING`, `PROCESSING`, `COMPLETED`, `FAILED`) y por dominio. Una fila solo se considera exitosa cuando todos los dominios requeridos confirman su procesamiento.
- Consistencia eventual: no se utiliza una transacción distribuida global entre bases de datos. Ante fallos transitorios se reintenta de forma idempotente; ante fallo definitivo la fila queda `FAILED` con el detalle del dominio afectado **y de los dominios que ya aplicaron cambios**, sin afirmar una reversión global inexistente.
- Política de actualización de campos: las celdas en blanco en filas de actualización (SKU existente) se ignoran, preservando los valores actuales.
- Manejo de concurrencia en stock mediante comandos de ajuste de Inventario con control optimista; `inventory.stock.adjusted` solo se emite tras persistir el ajuste y el registro formal en Kardex.
- Generación de resumen de resultados en pantalla y descarga de un archivo CSV con el detalle de filas fallidas y motivos de rechazo.

## 4. Requisitos

### Requisito 1: Exportación del catálogo y plantilla por SKU
El sistema DEBE permitir la descarga del catálogo actual y de una plantilla vacía donde cada fila represente un SKU vendible concreto vinculado a su producto base.

#### Escenario: Exportación del catálogo completo
- DADO que el gestor comercial se encuentra en la sección de carga masiva
- CUANDO solicita exportar el catálogo completo
- ENTONCES el sistema encola una exportación asíncrona y, al completarse, ofrece para descarga un archivo Excel/CSV con todos los SKUs vendibles registrados, incluidos productos simples, detallando por fila código de producto base, SKU vendible, atributos de variante, precio vigente, stock actual, marca, categoría y estado.

#### Escenario: Descarga de plantilla vacía
- DADO que el gestor comercial requiere registrar nuevos productos y variantes
- CUANDO solicita descargar la plantilla de carga masiva
- ENTONCES el sistema provee un archivo Excel/CSV con las cabeceras requeridas predefinidas y filas de ejemplo ilustrativas eliminables.

### Requisito 2: Carga masiva asíncrona coordinada por eventos de dominio
El sistema DEBE procesar el archivo mediante un Worker asíncrono que valide la estructura y emita **comandos de aplicación** a cada dominio y consuma resultados. Cada dominio emite sus propios hechos de cambio tras persistir.

Los eventos `pricing.price.changed` e `inventory.stock.adjusted` son hechos posteriores al commit y **no se usan como instrucciones de escritura**.

#### Escenario: Carga masiva exitosa
- DADO que el gestor comercial sube un archivo con hasta 5,000 filas válidas respetando la plantilla
- CUANDO confirma la importación
- ENTONCES el sistema encola la tarea, asigna `batch_id`/`row_id`, emite mensajes idempotentes a los dominios requeridos y espera sus confirmaciones; una fila pasa a `COMPLETED` únicamente cuando todos los dominios requeridos confirman su aplicación.

#### Escenario: Errores parciales
- DADO un archivo donde algunas filas tienen precio inválido y otras una categoría inexistente
- CUANDO el Worker procesa el archivo
- ENTONCES aplica las filas válidas, rechaza las inválidas, muestra el resumen y genera un CSV descargable con fila y causa del fallo.

### Requisito 3: Actualización, preservación de datos y concurrencia
Cuando el SKU existe, las celdas vacías conservan el valor actual.

#### Escenario: Celdas vacías
- DADO un SKU existente cuya descripción está vacía en el archivo y cuyo precio/stock cambian
- CUANDO se procesa la fila
- ENTONCES se conserva la descripción y solo se solicitan los cambios expresamente informados.

#### Escenario: Concurrencia de stock durante la importación
- DADO que Bulk intenta aplicar un conteo absoluto sobre un SKU
- CUANDO, en ese mismo intervalo, **Inventario procesa una operación de reserva/consumo orquestada por Ventas/Postventa** y cambia el saldo/versionado de ese SKU
- ENTONCES la operación de venta no se atribuye al canal; Inventario conserva su autoridad, detecta la versión obsoleta del ajuste masivo y rechaza el conteo antiguo con `VERSION_CONFLICT`, sin sobrescribir el movimiento ya confirmado.

Marketplace, Chatbot y Retail consultan disponibilidad; no mutan Inventario directamente.

### Requisito 4: Contrato de plantilla y alta de SKU
La plantilla posee `operacion=CREAR_PRODUCTO_SIMPLE | CREAR_VARIANTE | ACTUALIZAR`.

`CREAR_PRODUCTO_SIMPLE` requiere `sku_base` nuevo y `tiene_variantes=false`.

`CREAR_VARIANTE` requiere `product_id` o `sku_base` de un padre `tiene_variantes=true` ya existente o declarado para creación en el mismo lote, `tipo_producto_id`, atributos identificadores y un **SKU comercial opcional**. Si `sku` queda vacío, Catálogo lo genera; si se informa, valida formato y unicidad global. `variant_id` siempre es generado por Catálogo y no depende del SKU comercial.

Si el padre aún no existe, las filas del grupo aportan metadatos coherentes; Catálogo crea un único padre `BORRADOR` idempotente antes de sus variantes. Una discrepancia de metadatos compartidos rechaza el grupo.

`ACTUALIZAR` requiere SKU existente y no permite alterar por esta vía la identidad publicada: `sku_base`, `tiene_variantes`, `tipo_producto_id` fijado y atributos identificadores.

La plantilla usa `template_version=2`, sin mapeo dinámico.

### Requisito 5: Comandos, resultados y correlación
El orquestador usa:

```text
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

Cada mensaje lleva la correlación necesaria (`operation_id`, `batch_id`, `row_id`, identificador de mensaje/comando y versión contractual).

Si Catálogo crea un SKU, Bulk espera que las preparaciones iniciales de Pricing e Inventario estén confirmadas antes de aplicar cambios posteriores que dependan de ese SKU.

**Decisión pendiente preservada:** la necesidad funcional de inicializar precio/base e Inventario a cero está definida, pero los **nombres y payloads específicos de los comandos Catálogo → Pricing y Catálogo → Inventario para esa inicialización todavía no están congelados en AsyncAPI**. Esta SPEC no inventa esos nombres. Los contratos bulk listados arriba sí están publicados y se utilizan para la operación masiva que corresponda.

Cada dominio publica únicamente sus propios hechos posteriores al commit, como `pricing.price.changed`, `inventory.stock.adjusted` e `inventory.stock.changed`.

Se emplean Outbox/Inbox e idempotencia. Un ACK técnico del broker no equivale a aplicación funcional exitosa.

### Requisito 6: Estado real de fila y fallo parcial
Una fila se declara `COMPLETED` solo después de todos los resultados requeridos.

Un fallo definitivo produce `FAILED` con:

- dominios ya aplicados;
- dominio fallido;
- causa;
- indicador de necesidad de conciliación cuando existan efectos parciales.

No se revierte automáticamente un cambio ya aplicado si ello pudiera pisar operaciones posteriores. Los SKU nuevos incompletos no se publican comercialmente.

El CSV distingue una fila rechazada sin efectos de una fila parcialmente aplicada que necesita conciliación.

### Requisito 7: Concurrencia por dominio y stock absoluto seguro
La exportación incluye:

```text
catalog_version
price_version
stock_version
```

En `ACTUALIZAR`, el dominio propietario rechaza con `VERSION_CONFLICT` una escritura absoluta basada en una versión obsoleta.

Una celda `stock` no vacía expresa **conteo absoluto** en `location_id`. En SKU existente requiere `stock_version`. En SKU nuevo, Bulk espera la inicialización confirmada a cero y la versión inicial definida por Inventario.

Inventario registra en Kardex valor anterior, valor nuevo, delta y motivo de carga masiva. Una celda `stock` vacía conserva el saldo.

### Requisito 8: Seguridad, exportación y estados HTTP
- Rechazar fórmulas, macros o contenido activo en prevalidación.
- Escapar/proteger cadenas peligrosas en exportación.
- La exportación usa una captura lógica con `exported_at` y versiones fuente; no promete snapshot ACID interdominio.
- Crear una importación responde HTTP `202 Accepted` con `batch_id`.
- Crear una exportación responde HTTP `202 Accepted` con `export_id`.
- El seguimiento posterior informa estado y habilita descarga cuando corresponde.

### Requisito 9: Contrato de plantilla general v2
Las columnas, en este orden exacto, son:

```text
operacion
product_id
variant_id
sku_base
sku
nombre
descripcion
categoria_id
tipo_producto_id
marca_id
tiene_variantes
caracteristicas_identificadoras
atributos_identificadores
atributos_no_identificadores
imagen_url
precio_regular
precio_oferta
accion_precio_oferta
location_id
stock
catalog_version
price_version
stock_version
estado
motivo_cambio
```

Todas las cabeceras existen aunque algunas celdas sean condicionales.

La versión XLSX usa hojas auxiliares protegidas y listas de referencia para evitar que el gestor deba redactar JSON manualmente. CSV puede utilizar la representación compacta documentada para integraciones/usuarios avanzados.

Reglas principales:

- `CREAR_PRODUCTO_SIMPLE`: requiere `sku_base`, nombre, descripción, categoría, tipo, marca, `tiene_variantes=false`, precio regular y motivo.
- `CREAR_VARIANTE`: requiere padre, tipo, características/atributos identificadores e imagen; `sku` opcional y `variant_id` vacío.
- `ACTUALIZAR`: requiere `sku`; celdas vacías conservan datos. Cambios de Catálogo, Pricing o Inventario exigen la versión correspondiente.
- `accion_precio_oferta` vacía/`CONSERVAR` conserva la oferta; `ESTABLECER` exige importe positivo; `ELIMINAR` exige oferta vacía.
- La exportación completa es asíncrona y no se trunca por el límite de 5,000 filas de importación.

### Requisito 10: Fallo general y seguimiento
Ante error transitorio del worker se permiten hasta tres reintentos con espera creciente e idempotencia.

Un fallo no recuperable o agotamiento de reintentos marca `FAILED_GENERAL`, conserva el estado real por fila y permite reanudar pendientes con el **mismo `batch_id`** sin repetir aplicaciones confirmadas.

La interfaz debe distinguir:

- fallo general del trabajo;
- fallo por fila;
- fallo al consultar estado.

## 5. Requisitos no funcionales
- Importación de hasta 5,000 filas o 10 MB.
- Worker asíncrono desacoplado.
- Sin transacción distribuida global.
- Validación de extensión, MIME, cabeceras y contenido activo.
- Auditoría de usuario, Batch ID, timestamp y archivo procesado.
- Integración sin acceso directo a bases de datos de otros dominios.

## 6. Fuera de alcance
- Carga física de imágenes; solo URLs.
- Mapeo dinámico de columnas.
- Procesamiento síncrono bloqueante.
- Definir aquí nombres/payloads de inicialización Catálogo → Pricing/Inventario que todavía no estén publicados en AsyncAPI.

## Criterio de completitud
La capacidad se considera correctamente especificada cuando:

- los contratos bulk publicados y las reglas de negocio descritas se respetan;
- los límites 5,000 filas / 10 MB aplican solo a importación;
- el resumen y reporte de errores distinguen fallo sin efectos y conciliación;
- las celdas vacías preservan valores;
- la concurrencia de stock no atribuye mutaciones a Marketplace/Chatbot/Retail;
- los contratos de inicialización todavía no homologados permanecen identificados como dependencia pendiente.
