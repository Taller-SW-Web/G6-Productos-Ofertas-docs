# WF-001 — Carga y exportación masiva de productos

> **Fuentes normativas:** `././specs/SPEC-001-carga-exportacion-masiva-productos.md`, `././hu/HU-001-carga-exportacion-masiva-productos.md`, `./DESIGN.md` y `./INDEX.md`. Ante contradicción prevalece SPEC → HU → WF. Los detalles técnicos permanecen en este documento y no deben filtrarse a la interfaz del gestor.

## 0. Instrucciones para el agente

Genera un prototipo HTML/CSS/JS estático y navegable para carga/exportación masiva.

Reglas obligatorias:

- XLSX o CSV.
- Importación: máximo 10 MB / 5,000 filas.
- Exportación completa: asíncrona y sin truncamiento por el límite de importación.
- Plantilla v2, 25 columnas, sin mapeo dinámico.
- Una fila representa un SKU vendible.
- Celdas vacías en actualización conservan el valor actual.
- No adjuntar imágenes físicas: solo URL.
- Rechazar fórmulas/macros/contenido activo.
- No afirmar rollback global.
- Una fila no se considera exitosa hasta recibir todas las confirmaciones necesarias.
- Una fila parcialmente aplicada se muestra como fallida y requiere conciliación.
- La UI no atribuye consumos de stock a Marketplace/Chatbot/Retail.
- La concurrencia con ventas se explica, si fuera necesario, como cambio confirmado de Inventario originado por el flujo de Ventas/Postventa.
- Los nombres/payloads de inicialización de SKU hacia Pricing/Inventario siguen pendientes; no inventarlos en UI.
- Estilo monocromático de `DESIGN.md`, sin sombras.

## 1. Metadatos

| Campo | Valor |
|---|---|
| ID | WF-001 |
| Nombre | Carga y exportación masiva de productos |
| Versión | 0.6 |
| Estado | Alineado |
| Responsable | Marco Renato Castilla Huanca |
| Última actualización | 2026-09-28 |

## 2. Trazabilidad

| Fuente | Aporte |
|---|---|
| SPEC-001 | límites, plantilla, EDA, versionado, conciliación, exportación |
| HU-001 | criterios observables y escenarios |
| DESIGN.md | representación visual |
| OpenAPI 0.3.5-p0 | rutas administrativas vigentes de plantilla/importación/exportación |

## 3. Funcionalidades incluidas

- Descargar plantilla XLSX/CSV.
- Exportar catálogo XLSX/CSV.
- Seleccionar/prevalidar archivo.
- Confirmar importación.
- Seguir lote.
- Ver resultado.
- Descargar CSV de errores.
- Reanudar pendientes del mismo lote tras fallo general.
- Distinguir error de consulta, error por fila y fallo general.

## 4. Fuera de alcance

- Carga física de imágenes.
- Mapeo manual de columnas.
- Cancelar/revertir globalmente un lote ya parcialmente aplicado.
- Editar directamente el stock desde esta pantalla.
- Exponer detalles internos de comandos, colas, scopes o eventos.
- Fijar desde el wireframe los contratos de inicialización que aún no estén homologados.

## 5. Usuario objetivo

Gestor comercial autorizado para importar/exportar productos. El código granular exacto del permiso sigue dependiendo de Seguridad y no se muestra en interfaz.

## 6. Objetivo del flujo

Permitir que el gestor use una estructura oficial para importación masiva y consulte el resultado real sin confundir:

- archivo inválido;
- fila rechazada;
- fila parcialmente aplicada;
- lote interrumpido;
- fallo de consulta.

## 7. Pantallas

| ID | Pantalla/variante | Propósito |
|---|---|---|
| S-01 | Centro de carga/exportación | Punto de entrada |
| S-01-X | Trabajo de exportación | En cola / procesando / listo / fallido |
| S-02 | Archivo prevalidado | Resumen antes de confirmar |
| S-02-R | Archivo rechazado | Motivo y recuperación |
| S-03 | Confirmar importación | Confirmación explícita |
| S-04 | Lote en procesamiento | Progreso y Batch ID |
| S-04-E | Error de consulta | Reintentar consulta sin crear otro lote |
| S-05 | Resultado | Totales y detalle |
| S-05-F | Procesamiento interrumpido | Reanudar pendientes del mismo lote |
| S-G | Sin permiso / sesión expirada | Estados globales |

## 8. Secuencia principal

### Flujo A — Descargar plantilla
1. Abrir S-01.
2. Elegir XLSX o CSV.
3. Descargar plantilla v2 inmediatamente.

### Flujo B — Exportar catálogo
1. Elegir formato.
2. Solicitar exportación.
3. Recibir referencia de trabajo.
4. Mostrar En cola/Procesando.
5. Al completar, habilitar descarga.

### Flujo C — Importar
1. Seleccionar archivo.
2. Prevalidar tipo/tamaño/estructura/contenido activo.
3. Mostrar resumen.
4. Confirmar importación.
5. Crear lote asíncrono.
6. Mostrar Batch ID y estado.
7. Consultar hasta resultado.
8. Mostrar exitosas, fallidas y conciliación.
9. Habilitar reporte CSV cuando existan fallos.

## 9. S-01 — Centro de carga/exportación

### Jerarquía
1. Título.
2. Reglas previas.
3. Selección de archivo.
4. Plantilla.
5. Exportación.

### Reglas visibles antes de elegir archivo
- XLSX o CSV.
- Hasta 10 MB.
- Hasta 5,000 filas.
- Usar la plantilla oficial.
- Celdas vacías conservan datos al actualizar.
- Imágenes mediante URL.
- El procesamiento continúa en segundo plano.

No mostrar `catalog_version`, `price_version`, `stock_version`, nombres de eventos ni DTOs en el panel principal.

## 10. S-02 — Archivo prevalidado

Mostrar:

- nombre;
- tamaño;
- cantidad estimada de filas;
- formato;
- estado “Listo para revisar”.

Si falla estructura, tamaño, filas o contenido activo, usar S-02-R.

## 11. S-03 — Confirmación

Texto de confirmación:

> La importación se procesará en segundo plano. Las filas correctas pueden aplicarse aunque otras sean rechazadas.

Evitar copy que prometa “todo o nada”.

## 12. S-04 — Procesamiento

Mostrar:

- Batch ID;
- estado comprensible (`En cola`, `Procesando`);
- filas procesadas;
- exitosas;
- fallidas.

No exponer ACK, `row_id`, `PENDING`, `PROCESSING`, nombres de dominio o códigos de versión al usuario final.

## 13. S-05 — Resultado

### Éxito completo
> La importación terminó correctamente.

### Fallos de fila
> Algunas filas no pudieron completarse. Revisa el reporte.

### Conciliación
> Algunas filas alcanzaron a aplicar una parte de los cambios antes de fallar. Revisa el detalle antes de reintentar.

No decir “se revirtieron todos los cambios”.

### Fallo general
> El procesamiento se interrumpió antes de finalizar. Puedes reanudar las operaciones pendientes sin duplicar las ya confirmadas.

Acción: `Reanudar pendientes`.

## 14. Rutas HTTP administrativas

OpenAPI `0.3.5-p0` define bajo `/api/v1`:

```text
GET  /carga-masiva/productos/plantilla
POST /carga-masiva/productos/importaciones
GET  /carga-masiva/productos/importaciones/{batchId}
GET  /carga-masiva/productos/importaciones/{batchId}/reporte
POST /carga-masiva/productos/importaciones/{batchId}/reanudar
POST /carga-masiva/productos/exportaciones
GET  /carga-masiva/productos/exportaciones/{exportId}
GET  /carga-masiva/productos/exportaciones/{exportId}/archivo
```

Las rutas dejan de estar pendientes en el WF. Los permisos granulares exactos siguen dependiendo de Seguridad.

## 15. Contratos asíncronos relacionados

Publicados para Bulk:

```text
catalog.bulk.upsert.requested|completed|rejected
pricing.bulk.price.apply.requested|completed|rejected
inventory.bulk.stock.adjust.requested|completed|rejected
```

Hechos posteriores al commit:

```text
pricing.price.changed
inventory.stock.adjusted
inventory.stock.changed
```

La inicialización específica Catálogo → Pricing/Inventario de un SKU recién creado sigue siendo una dependencia de contrato pendiente.

## 16. Estados de interfaz

- inicial;
- descargando plantilla;
- exportación en cola/procesando/lista;
- archivo prevalidado;
- archivo rechazado;
- confirmando;
- lote en cola;
- lote procesando;
- resultado completo;
- resultado parcial;
- conciliación requerida;
- procesamiento interrumpido;
- error de consulta;
- sin conexión;
- sin permiso;
- sesión expirada.

## 17. Responsividad

- Escritorio: tabla/resumen en dos columnas cuando corresponda.
- Tablet: regiones apiladas parcialmente.
- Móvil: una columna.
- 320 px sin overflow del `body`.
- Tablas con scroll interno.
- No usar controles falsos de dispositivo.

## 18. Accesibilidad

- WCAG 2.2 AA como objetivo.
- Foco visible.
- Botones/controles >=44 px.
- Mensajes de error asociados.
- Cambios de estado anunciados con `aria-live`.
- No depender del color.

## 19. Criterios de aceptación del wireframe
- reglas visibles antes de archivo;
- plantilla inmediata;
- exportación asíncrona;
- importación asíncrona;
- Batch ID visible;
- reporte CSV;
- fallo parcial sin rollback ficticio;
- reanudación del mismo lote;
- rutas OpenAPI cerradas;
- no canal mutando stock;
- no contratos de inicialización inventados.
