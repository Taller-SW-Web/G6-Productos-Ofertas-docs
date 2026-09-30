# WF-001 — Carga y exportación masiva de productos

## Usuario objetivo
Gestor comercial.

## Objetivo
Cargar archivos masivos, revisar observaciones, conocer el resultado por fila y dominio sin exponer la coordinación interna entre servicios, y solicitar la exportación completa del catálogo vigente en formatos estándar.

## Pantallas
- **S-01 Cargar archivo:** selección de archivo CSV/XLSX, enlace a plantilla y acceso a descargas/exportación.
- **S-02 Prevalidación:** revisión de formato, número de filas válidas y advertencias estructurales antes de confirmar.
- **S-03 Procesamiento:** barra de avance por fases (registro de borradores, preparación de precios, preparación de inventario y stock inicial).
- **S-04 Resultado:** resumen de filas procesadas exitosamente.
- **S-04-E Resultado con errores:** detalle de filas observadas con discriminación por dominio (Catálogo, Pricing, Inventario) y opción de reanudar lote.
- **S-05 Descargas y exportación de catálogo:** descarga de plantillas vacías y solicitud de exportación del catálogo en formatos CSV o XLSX.

## Contenido visible
- Archivo seleccionado y selector de formato de exportación (CSV / XLSX).
- Cantidad de filas detectadas, listas para importar y con observaciones.
- Errores de datos con motivo funcional y dominio responsable.
- Estados funcionales visibles: Validando / Procesando / Completado / Completado con observaciones / Exportando catálogo.
- Descarga de plantilla oficial, descarga de reporte detallado de importación y descarga de archivo de catálogo exportado.

## Flujo UX de exportación de catálogo
1. El gestor accede a la sección de descargas o pulsa el botón «Exportar catálogo» en la cabecera.
2. Selecciona el formato deseado (`CSV` o `XLSX`) y confirma la solicitud.
3. La interfaz muestra un indicador de preparación en segundo plano mientras se consolida la información de catálogo, precios y existencias.
4. Una vez concluida la generación, se habilita el botón de descarga directa del archivo consolidado.

## No mostrar
- Identificadores técnicos de mensajería (`pricing.product.initialization.requested`, `inventory.sku.initialization.requested`, `inventory.bulk.stock.adjust.requested`).
- Identificadores internos (`operation_id`, nombres de colas RabbitMQ o detalles de base de datos).

## Reglas de consistencia en interfaz
- Durante el procesamiento, la UI muestra mensajes comprensibles como «Preparando precios base» y «Preparando unidades de inventario».
- No afirmar éxito total de una fila ni del lote hasta consolidar todas las dependencias requeridas.
- En caso de fallos parciales, ofrecer la descarga del reporte CSV de inconsistencias y la opción de reintentar/reanudar el lote sin repetir datos confirmados.
