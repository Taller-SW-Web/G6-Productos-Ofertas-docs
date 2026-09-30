# WF-010 — Asociación entre tipos de producto y características

> **Fuentes normativas:** `././specs/SPEC-010-asociacion-tipo-producto-caracteristica.md`, `././hu/HU-010-asociacion-tipo-producto-caracteristica.md`, `./DESIGN.md` y `./INDEX.md`. Ante contradicción, prevalece SPEC → HU → WF.

## 0. Instrucciones para el agente

Genera un wireframe navegable para administrar tipos de producto y sus características.

Reglas:

- El esquema pertenece al **Tipo de Producto**, no a Categorías.
- No expongas IDs internos como dato principal de interfaz.
- No agregues orden visual de características: no forma parte del contrato.
- Mostrar límite operativo como «X de N características», sin exponer el nombre técnico de la constante.
- Una desasociación potencialmente riesgosa **no es inmediata**.
- Una desactivación de tipo potencialmente riesgosa **no es inmediata**.
- `202 Accepted` se representa como «Verificando»/«Solicitud recibida», nunca «Completado».
- Ante rechazo o falta de confirmación, conservar el estado previo.
- Usar los contratos AsyncAPI publicados; no mostrar sus nombres técnicos al usuario final.
- No mostrar detalles de broker, scopes, entidades técnicas o códigos de error al usuario.
- Escala de grises, sin sombras y responsive según DESIGN.md.

## 1. Metadatos

| Campo | Valor |
|---|---|
| ID | WF-010 |
| Nombre | Asociación entre tipos de producto y características |
| Versión | 0.9 |
| Estado | Alineado documentalmente |
| Responsable | Leonardo Lopez |
| Última actualización | 2026-09-28 |

## 2. Trazabilidad

| Fuente | Aporte |
|---|---|
| SPEC-010 | Esquema, obligatoriedad, límite, versionado y bajas seguras |
| HU-010 | CA-01 a CA-17 |
| DESIGN.md | Diseño |
| OpenAPI `0.3.5-p0` | HTTP administrativo vigente |
| AsyncAPI `0.2.1-p0` | Baja segura de tipo/asociación y propagación de cambio de esquema |

## 3. Incluye

- listar tipos;
- crear tipo ligero;
- consultar detalle;
- asociar característica;
- cambiar obligatoriedad;
- desasociar con verificación;
- desactivar tipo con verificación;
- reactivar tipo;
- límite configurable;
- estados de carga/error/conflicto/permisos;
- resultado pendiente/confirmado/rechazado.

## 4. Fuera de alcance

- CRUD de características/valores;
- categorías;
- captura de valores de producto;
- migración de productos publicados entre tipos;
- eliminación física;
- orden visual de atributos;
- definición unilateral de mensajes fuera del AsyncAPI canónico.

## 5. Usuario objetivo

Gestor comercial encargado de los esquemas del catálogo.

La interfaz debe expresar términos operativos:

```text
Tipo de producto
Característica
Obligatoria
Opcional
Verificando uso
No se pudo completar
```

y no identificadores de infraestructura.

## 6. Secuencia principal

### Flujo A — Consultar tipos

1. Cargar tipos.
2. Mostrar nombre, estado y conteo de características.
3. Seleccionar tipo.
4. Ver esquema.

### Flujo B — Crear tipo

1. `Nuevo tipo de producto`.
2. Ingresar nombre.
3. Guardar.
4. Abrir el nuevo tipo activo.

El identificador se genera internamente y no necesita mostrarse al gestor.

### Flujo C — Asociar característica

1. Abrir un tipo activo.
2. Revisar contador `X de N`.
3. `Asociar característica`.
4. Elegir una característica activa no asociada.
5. Elegir Obligatoria/Opcional.
6. Guardar.
7. Actualizar esquema tras confirmación.

### Flujo D — Cambiar obligatoriedad

1. Cambiar Obligatoria/Opcional.
2. Guardar.
3. Mostrar confirmación.
4. Si pasa a obligatoria, informar:

> Se exigirá al volver a guardar o activar los productos que correspondan.

### Flujo E — Desasociar

1. `Desasociar`.
2. Diálogo explica el impacto.
3. Confirmar.
4. Estado `Verificando uso`.
5. Resultado:
   - seguro → retirar asociación;
   - uso activo → conservar y explicar bloqueo;
   - fallo/timeout → conservar y ofrecer reintento.

### Flujo F — Desactivar tipo

1. `Desactivar tipo`.
2. Confirmar.
3. Estado `Verificando uso`.
4. Resultado:
   - sin productos activos → Inactivo;
   - con productos activos → sigue Activo;
   - resultado no confiable → sigue Activo.

### Flujo G — Reactivar

Una vez inactivo, `Reactivar tipo` vuelve a habilitarlo conforme al contrato vigente.

## 7. Alternativas

| ID | Condición | Resultado |
|---|---|---|
| ALT-01 | Límite alcanzado | Asociar deshabilitado |
| ALT-02 | Característica ya asociada | Excluir del selector |
| ALT-03 | Tipo sin características | Estado vacío |
| ALT-04 | Desasociación bloqueada | Asociación se conserva |
| ALT-05 | Verificación fallida | Estado anterior se conserva |
| ALT-06 | Tipo inactivo | Esquema en lectura; reactivación disponible |
| ALT-07 | Error de guardado | Conservar datos |
| ALT-08 | Sin permisos | Bloquear acciones |
| ALT-09 | Sesión expirada | Reingreso |

## 8. Pantallas

| ID | Pantalla |
|---|---|
| S-01 | Tipos de producto |
| S-01-E | Vacío/error |
| S-01-N | Crear tipo |
| S-02 | Esquema del tipo |
| S-02-P | Operación en verificación |
| S-02-R | Operación rechazada |
| S-03 | Asociar característica |
| S-04 | Confirmar desasociación |
| S-05 | Confirmar desactivación de tipo |

## 9. S-01 — Tipos

Mostrar:

- nombre;
- estado;
- `X de N características`;
- acción `Abrir`.

No mostrar `tipo_producto_id` como columna necesaria.

## 10. S-02 — Esquema

Encabezado:

- nombre;
- estado;
- contador;
- `Asociar característica`;
- `Desactivar tipo` o `Reactivar tipo`.

Tabla:

| Columna | Contenido |
|---|---|
| Característica | Nombre |
| Tipo de dato | Texto/Número/Lista |
| Condición | Obligatoria/Opcional |
| Acciones | Cambiar condición / Desasociar |

No mostrar una acción de «reordenar».

## 11. S-03 — Asociación

Selector de características activas no asociadas.

Campos:

- característica;
- condición.

Si se alcanza el límite, bloquear el guardado y explicar el límite vigente.

## 12. S-04 — Desasociación

Copy:

> Antes de retirar esta característica debemos comprobar que el cambio no deje productos o variantes activos en un estado incompatible.

Al confirmar:

```text
Verificando uso…
```

No retirar la fila hasta recibir resultado final.

### Rechazo

> No se puede retirar esta característica porque todavía participa en productos o variantes activos.

## 13. S-05 — Desactivar tipo

Copy:

> Antes de desactivar este tipo debemos comprobar que no tenga productos activos que dependan de él.

La misma regla de fallo cerrado aplica.

## 14. Estados

- cargando;
- vacío;
- datos;
- guardando;
- verificación pendiente;
- operación confirmada;
- operación rechazada;
- verificación no concluyente;
- límite alcanzado;
- sin permisos;
- sesión expirada.

## 15. Contratos HTTP

```text
GET  /api/v1/tipos-producto
POST /api/v1/tipos-producto
GET  /api/v1/tipos-producto/{tipoProductoId}

POST /api/v1/tipos-producto/{tipoProductoId}/desactivar
POST /api/v1/tipos-producto/{tipoProductoId}/reactivar

GET  /api/v1/tipos-producto/{tipoProductoId}/caracteristicas
POST /api/v1/tipos-producto/{tipoProductoId}/caracteristicas
PATCH /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}
POST /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}/desasociar
```

Las bajas seguras devuelven admisión asíncrona. No se presenta como finalización.

## 16. Contratos AsyncAPI publicados

AsyncAPI `0.2.1-p0` cierra las dependencias de esta funcionalidad:

1. `PRODUCT_TYPE` participa en la verificación transversal de baja segura;
2. `PRODUCT_TYPE_CHARACTERISTIC` participa en la misma verificación para desasociaciones de riesgo;
3. los cambios confirmados del esquema publican `taxonomy.product-type-schema.changed`.

La interfaz continúa mostrando únicamente estados operativos como **Verificando**, **Completado** o **No se pudo completar**; los nombres técnicos de mensajería no forman parte de la UI.

## 17. Responsividad y accesibilidad

- >900 px: navegación lateral + tabla.
- <=900 px: bloques apilados.
- <=600 px: tarjetas/formulario de una columna.
- 320 px sin overflow del body.
- controles >=44 px.
- foco visible.
- modales con foco contenido.
- `aria-live` para resultados asíncronos.
- estados por texto, no solo color.

## 18. Microcopy

| Contexto | Texto |
|---|---|
| límite | `Has alcanzado el límite configurado de características para este tipo.` |
| obligatoria | `Se exigirá al volver a guardar o activar los productos que correspondan.` |
| pendiente | `Estamos comprobando si el cambio puede realizarse de forma segura.` |
| rechazo | `No se puede completar porque existen productos o variantes activos que dependen de esta configuración.` |
| no concluyente | `No pudimos confirmar que el cambio sea seguro. No se realizó ninguna modificación.` |
