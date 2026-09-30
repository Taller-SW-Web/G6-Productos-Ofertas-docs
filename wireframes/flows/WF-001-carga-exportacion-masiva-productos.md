# WF-001 — Carga y exportación masiva de productos


## Usuario objetivo
Gestor comercial.

## Objetivo
Cargar un archivo, revisar errores y conocer el resultado por fila sin exponer la coordinación interna entre servicios.

## Pantallas
- S-01 Cargar archivo.
- S-02 Prevalidación.
- S-03 Procesamiento.
- S-04 Resultado.
- S-04-E Resultado con errores.

## Contenido visible
- Archivo seleccionado.
- Cantidad de filas.
- Errores de datos.
- Estado: Validando / Procesando / Completado / Completado con errores.
- Descarga de reporte.

## No mostrar
`pricing.product.initialization.requested`, `inventory.sku.initialization.requested`, `operation_id`, colas o estados técnicos.

## Regla de consistencia
La UI puede indicar “Preparando precio e inventario” mientras las dependencias se completan. No afirmar éxito total hasta consolidar los resultados.
