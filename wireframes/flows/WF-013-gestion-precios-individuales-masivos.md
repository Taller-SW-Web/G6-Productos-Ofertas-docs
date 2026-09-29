# WF-013 — Gestión de precios individuales y masivos

> **Fuentes normativas:** `././specs/SPEC-013-gestion-precios-individuales-masivos.md`, `././hu/HU-013-gestion-precios-individuales-masivos.md`, `./DESIGN.md` y `./INDEX.md`. Ante contradicción, prevalece SPEC → HU → WF.

## 0. Instrucciones para el agente

Genera un wireframe navegable de Pricing.

Reglas:

- Todas las referencias HTTP de Pricing usan el recurso REST en español `/precios`.
- Contratos REST del módulo en español: `/api/v1/precios/..`.
- No presentar `PRICING_*` como permisos oficiales.
- No mostrar roles concretos como requisito técnico al usuario.
- Canal es opcional; «Todos los canales» representa scope global.
- En la respuesta global, `channel_id` puede ser `null`.
- Consulta histórica muestra la referencia de vigencia.
- El resultado parcial se obtiene consultando el proceso asíncrono; no se define una respuesta síncrona adicional.
- Procesamiento masivo siempre se representa asíncrono tras admisión 202.
- Blanco en oferta significa **conservar**.
- `ELIMINAR` es la única acción que retira la oferta en el archivo.
- No inventar un límite máximo de filas; 5,000 es benchmark.
- No ejecutar ni interpretar contenido del archivo en el prototipo.
- Diseño monocromático, sin sombras, conforme a DESIGN.md.

## 1. Metadatos

| Campo | Valor |
|---|---|
| ID | WF-013 |
| Nombre | Gestión de precios individuales y masivos |
| Versión | 0.6 |
| Estado | Alineado documentalmente |
| Responsable | Leonardo Vera Rodríguez |
| Última actualización | 2026-09-28 |

## 2. Funcionalidades incluidas

- detalle de precio;
- origen producto/override;
- actualización;
- programación;
- consulta histórica;
- prevalidación de CSV/XLSX;
- modo Todo o nada;
- modo tolerante;
- procesamiento asíncrono;
- consulta de lote;
- resultado total/parcial/rechazado;
- reporte CSV;
- conflicto de versión;
- vigencia superpuesta;
- guardrail de variación.

## 3. Fuera de alcance

- promociones/cupones/combos;
- costos y margen;
- checkout;
- exportación general;
- plantilla;
- mapeo de columnas;
- cancelación de programación no aprobada.

## 4. Usuario objetivo

Gestor comercial autorizado.

La interfaz comunica «Acceso restringido» ante 403 y «Sesión finalizada» ante 401 sin mostrar nombres de scopes aún no homologados.

## 5. Navegación

Pestañas:

1. **Precio vigente**
2. **Consulta histórica**
3. **Carga masiva**

### Contratos HTTP relevantes

```text
GET   /api/v1/precios/skus/{sku}
PATCH /api/v1/precios/skus/{sku}

GET  /api/v1/precios/skus/{sku}/programaciones
POST /api/v1/precios/skus/{sku}/programaciones

GET   /api/v1/precios/productos/{productoId}
PATCH /api/v1/precios/productos/{productoId}

GET  /api/v1/precios/productos/{productoId}/programaciones
POST /api/v1/precios/productos/{productoId}/programaciones

POST /api/v1/precios/importaciones/prevalidar
POST /api/v1/precios/importaciones
GET  /api/v1/precios/importaciones/{batchId}
GET  /api/v1/precios/importaciones/{batchId}/reporte
```

Para histórico:

```http
GET /api/v1/precios/skus/{sku}?at={timestamp}
```

`canal` es opcional.

## 6. Flujo A — Precio vigente

S-01 muestra:

- SKU;
- producto;
- precio regular;
- oferta opcional;
- moneda;
- alcance:
  - Todos los canales; o
  - canal específico;
- vigencia;
- versión;
- origen:
  - Precio del producto;
  - Precio propio del SKU.

Acciones:

- Actualizar precio;
- Programar precio;
- Consulta histórica.

## 7. Flujo B — Actualizar precio

Campos:

| Campo | Regla |
|---|---|
| Precio regular | >0 |
| Oferta | opcional; >0 y < regular |
| Canal | opcional; Todos los canales = global |
| Vigente hasta | opcional |
| Motivo | obligatorio |
| Versión | enviada por el contrato, no editable |

Antes de guardar:

- validar;
- calcular variación;
- mostrar guardrail si es extraordinaria;
- confirmar.

Ante conflicto de versión, refrescar el precio vigente y solicitar revisión.

## 8. Flujo C — Programar

Además:

- fecha/hora de inicio;
- fin opcional.

No permitir solapamiento del mismo scope.

La UI muestra estado legible:

```text
Programado
```

No necesita mostrar `SCHEDULED` como término principal.

## 9. Flujo D — Consulta histórica

S-04:

- SKU;
- fecha/hora;
- canal opcional.

Resultado:

- regular;
- oferta si existía;
- moneda;
- canal efectivo o «Global»;
- inicio/fin de vigencia;
- **Referencia de vigencia** (`vigencia_id`).

No mostrar «SCD Tipo 2» como copy de usuario.

## 10. Flujo E — Carga masiva

### Columnas

Obligatorias:

```text
sku
precio_regular
motivo_cambio
```

Opcionales:

```text
precio_oferta
accion_precio_oferta
channel_id
valid_from
valid_until
price_version
```

### Microcopy visible

> Si dejas vacía la oferta, se conservará. Para crear o cambiar una oferta, usa **Establecer oferta** e indica el importe. Para retirarla, usa **Quitar oferta** y deja vacío el importe. Si el nuevo precio regular invalida la oferta conservada, la fila se rechazará.

En la plantilla o archivo de importación sí se conservan los valores contractuales exactos `ESTABLECER` / `ELIMINAR` y los encabezados técnicos requeridos. Esos identificadores no se muestran como copy principal de la interfaz.

### Prevalidación

1. seleccionar archivo;
2. validar tipo/tamaño/cabeceras;
3. mostrar resumen;
4. elegir:
   - Todo o nada;
   - Tolerante a fallos.

La prevalidación no aplica precios.

## 11. Flujo F — Procesamiento asíncrono

Después de confirmar:

```text
202 Accepted
+ referencia del proceso
```

La pantalla muestra:

```text
En cola
Procesando
Completado
Completado con filas rechazadas
Rechazado
```

El resultado parcial se representa únicamente como estado final del proceso.

El usuario puede abandonar la pantalla; el trabajo continúa.

## 12. Resultados

### Total

Todas las filas aplicadas.

### Parcial

Solo `allow_partial=true`.

Mostrar:

- total;
- aplicadas;
- rechazadas;
- descargar CSV de errores.

### Rechazo total

Modo Todo o nada con error:

- 0 aplicadas;
- reporte de errores;
- ninguna modificación persistida.

## 13. Alternativas

| ID | Caso | Resultado |
|---|---|---|
| ALT-01 | Motivo vacío | Error |
| ALT-02 | Regular <=0 | Error |
| ALT-03 | Oferta >= regular | Error |
| ALT-04 | Vigencia inválida | Error |
| ALT-05 | Solapamiento | Conflicto |
| ALT-06 | SKU inexistente | No encontrado |
| ALT-07 | Versión obsoleta | Conflicto |
| ALT-08 | Archivo inválido | Rechazo antes de encolar |
| ALT-09 | >10 MB | Rechazo |
| ALT-10 | Todo o nada con error | Lote rechazado |
| ALT-11 | Tolerante con errores | Resultado parcial |
| ALT-12 | Error consultando estado | No afirmar que el lote falló |
| ALT-13 | 401 | Sesión finalizada |
| ALT-14 | 403 | Acceso restringido |

## 14. Pantallas

| ID | Pantalla |
|---|---|
| S-01 | Precio vigente |
| S-01-E | Error/no encontrado |
| S-02 | Actualizar/Programar |
| S-03 | Confirmación |
| S-04 | Consulta histórica |
| S-04-E | Sin precio en ese instante |
| S-05 | Carga masiva |
| S-06 | Prevalidación |
| S-07 | Confirmar lote |
| S-08 | Estado del proceso |
| S-08-E | Error al consultar estado |
| S-09-S | Éxito |
| S-09-P | Éxito parcial |
| S-09-R | Rechazo total |

## 15. Copy de canal

Las opciones visibles son:

```text
Todos los canales
Marketplace
Chatbot
Retail
```

«Todos los canales» representa el alcance global (`channel_id=null`) en el contrato.

## 16. Estado contractual del OpenAPI

OpenAPI `0.3.5-p0` ya refleja la semántica vigente de Pricing utilizada por este wireframe:

- `canal` opcional en la consulta;
- `channel_id` nullable para el alcance global;
- `vigencia_id` en la resolución temporal cuando corresponde;
- procesamiento masivo asíncrono con resultado consultado mediante el estado del lote.

Estos puntos ya no son pendientes de congelamiento. El wireframe debe mantenerse alineado con el contrato canónico vigente y no con versiones históricas de OpenAPI.

## 17. Seguridad

Los nombres `PRICING_READ`, `PRICING_WRITE`, `PRICING_BULK` siguen siendo propuestos.

La UI solo necesita distinguir:

- sesión inválida;
- acceso insuficiente.

## 18. Responsividad y accesibilidad

- >900: tablas y formulario 2 columnas.
- <=900: paneles apilables.
- <=600: una columna/tarjetas.
- 320 px sin overflow del body.
- controles >=44 px.
- foco visible.
- labels.
- errores asociados.
- `aria-live`.
- estados no dependen del color.

## 20. Registro de revisión

| Versión | Fecha | Cambio |
|---|---|---|
| 0.5 | 2026-09-28 | Rutas REST en español, canal global opcional, vigencia histórica explícita, flujo masivo exclusivamente asíncrono y saneamiento de permisos/copy de carga. |
| 0.6 | 2026-09-28 | Humanización de la carga masiva: copy operacional en UI y nombres contractuales reservados para la plantilla/archivo. |
| 0.7 | 2026-09-28 | Se elimina la narrativa pre-freeze y se referencia OpenAPI `0.3.5-p0` como baseline contractual vigente. |
