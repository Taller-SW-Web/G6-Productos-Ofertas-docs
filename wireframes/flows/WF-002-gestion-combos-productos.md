# WF-002 — Gestión de combos de productos

> **Fuentes normativas:** `././specs/SPEC-002-gestion-combos-productos.md`, `././hu/HU-002-gestion-combos-productos.md`, `./DESIGN.md` y `./INDEX.md`. Ante contradicción prevalece SPEC → HU → WF. Los movimientos del pedido pertenecen a Ventas/Postventa e Inventario y **no son acciones manuales del backoffice de Combos**.

## 0. Instrucciones para el agente

Genera un wireframe detallado, anotado y navegable para administrar combos.

Antes de diseñar:

1. Consulta SPEC-002.
2. Consulta HU-002.
3. Consulta DESIGN.md.
4. Usa este documento para composición, navegación y estados.

Reglas:

- No agregues reglas no documentadas.
- Usa únicamente SKUs vendibles directos como componentes.
- Exige como mínimo 2 SKUs distintos.
- Cantidad entera positiva.
- No permitas combos dentro de combos.
- No introduzcas un máximo de componentes si la SPEC no lo define.
- Valida `precio_combo` contra suma regular y suma pública vigente.
- La disponibilidad es informativa.
- No muestres controles para reservar, consumir, liberar o reponer stock.
- No presentes `order.created`, `order.confirmed`, `order.cancelled` o `order.returned` como contratos vigentes del módulo.
- En lenguaje de usuario evita nombres de eventos, tablas, microservicios o estados técnicos del broker.
- Usa escala de grises, sin sombras, conforme a DESIGN.md.

### Entregable

`./prototipos/WF-002-gestion-combos-productos/index.html`

HTML/CSS/JS estáticos, responsivos y sin dependencias externas.

## 1. Metadatos

| Campo | Valor |
|---|---|
| ID | WF-002 |
| Nombre | Gestión de combos de productos |
| Versión | 0.6 |
| Estado | Alineado |
| Responsable | Marco Renato Castilla Huanca |
| Última actualización | 2026-09-28 |

## 2. Trazabilidad

| Fuente | Cobertura |
|---|---|
| SPEC-002 | Componentes, precio, disponibilidad, stock y límites de responsabilidad |
| HU-002 | CA-01 a CA-18 y escenarios |
| DESIGN.md | Wireframe monocromático, responsive y accesible |
| OpenAPI `0.3.5-p0` | CRUD administrativo y consulta de disponibilidad vigentes |
| Contrato de Inventario | Reserva, confirmación y liberación ejecutadas fuera de esta UI |

### Incluye

- listado;
- alta;
- edición;
- selector de componentes;
- cantidades;
- validación de precio;
- detalle;
- disponibilidad informativa;
- desactivación manual;
- estado inactivo por baja de componente;
- estados de carga, vacío, error, conflicto, permisos y sesión.

### Fuera de alcance

- reservar/consumir/liberar stock manualmente;
- editar inventario;
- simular pagos;
- gestionar pedidos;
- decidir devoluciones;
- reintegrar stock por devolución;
- anidar combos;
- eliminación física;
- reactivación mientras no exista regla aprobada.

## 3. Usuario objetivo

| Aspecto | Definición |
|---|---|
| Persona | Gestor comercial |
| Necesidad | Crear un paquete válido y entender su situación comercial |
| Dispositivo | Escritorio; tablet y móvil soportados |
| Permisos | Administración de combos; códigos exactos gestionados por Seguridad |

## 4. Objetivo del flujo

Permitir administrar un combo sin convertir el backoffice comercial en una consola de Inventario.

El gestor ve:

- composición;
- cantidad;
- precio regular;
- precio público vigente;
- precio del combo;
- disponibilidad estimada;
- estado comercial.

No ve controles de reserva/consumo.

## 5. Precondiciones y puntos de entrada

- Sesión válida.
- Usuario autorizado.
- Catálogo con SKUs vendibles.
- Precios vigentes consultables.
- Proyección de disponibilidad consultable cuando exista.

### Rutas de interfaz propuestas

- `/productos/combos`
- `/productos/combos/nuevo`
- `/productos/combos/:id`

Las rutas frontend son de navegación; no son endpoints de API.

## 6. Secuencia principal

### Flujo A — Listar

1. Abrir Gestión de combos.
2. Mostrar nombre, precio, cantidad de componentes, disponibilidad estimada y estado.
3. Abrir detalle, editar o desactivar según permisos.

### Flujo B — Crear

1. `Crear combo`.
2. Nombre y descripción.
3. `Añadir componentes`.
4. Seleccionar SKUs vendibles directos.
5. Definir cantidades.
6. Calcular:
   - suma regular;
   - suma pública vigente;
   - disponibilidad estimada.
7. Introducir precio.
8. Bloquear si:
   - < 2 SKUs distintos;
   - cantidad inválida;
   - componente repetido;
   - componente es combo;
   - precio <= 0;
   - precio >= cualquiera de las dos referencias.
9. Guardar.
10. Mostrar detalle.

### Flujo C — Editar

Igual a creación, cargando la versión vigente del combo. Si cambian precios/estado/disponibilidad mientras el formulario está abierto, refrescar y pedir revisión antes de guardar.

### Flujo D — Desactivar

Confirmación explícita y posterior estado Inactivo. No afecta el estado de los SKU.

### Flujo E — Baja automática por componente

Ante la actualización recibida del catálogo:

1. el combo deja de ser elegible;
2. el detalle muestra «Requiere revisión»;
3. se identifica el componente que dejó de estar activo;
4. no se ofrece «reactivar automáticamente».

### Flujo F — Contexto informativo del pedido

No es una pantalla.

La documentación puede explicar:

```text
CREADO -> reserva
PAGADO -> confirmación/consumo
PAGO_NO_COMPLETADO / cancelación aplicable -> liberación
```

pero el HTML no debe exponer acciones para ejecutar ese flujo.

## 7. Alternativas

| ID | Condición | Resultado |
|---|---|---|
| ALT-01 | Menos de 2 SKUs | Bloquear guardado |
| ALT-02 | SKU duplicado | Bloquear selección/repetición |
| ALT-03 | Combo seleccionado | Bloquear selección |
| ALT-04 | Cantidad no entera/<=0 | Error de fila |
| ALT-05 | Precio inválido | Error bloqueante |
| ALT-06 | Componente agotado | Disponibilidad estimada = 0 |
| ALT-07 | Proyección desconocida | «No verificable» |
| ALT-08 | Precio cambió | Recalcular y solicitar revisión |
| ALT-09 | SKU se desactivó | Combo requiere revisión |
| ALT-10 | Error de guardado | Mantener datos |
| ALT-11 | Sin permisos | Bloquear acciones |
| ALT-12 | Sesión expirada | Solicitar ingreso de nuevo |

## 8. Inventario de pantallas

| ID | Pantalla | Propósito |
|---|---|---|
| S-01 | Listado | Consultar combos |
| S-01-E | Vacío/error | Recuperación |
| S-02 | Crear/Editar | Configurar combo |
| S-02-C | Datos cambiaron | Revisar valores vigentes |
| S-03 | Selector | Seleccionar SKUs |
| S-04 | Confirmar desactivación | Evitar baja accidental |
| S-05 | Detalle | Consultar combo |
| S-05-I | Inactivo | Baja manual |
| S-05-A | Requiere revisión | Baja automática por componente |
| S-05-E | No verificable | Error/ausencia de disponibilidad |

## 9. Pantallas

### S-01 — Listado

Mostrar:

- nombre;
- precio;
- número de componentes;
- disponibilidad como **Estimación**;
- `No verificable` cuando corresponda;
- estado.

Acciones:

- Crear combo;
- Ver detalle;
- Editar;
- Desactivar.

No mostrar Eliminar.

### S-02 — Crear/Editar

#### Datos generales

| Campo | Regla |
|---|---|
| Nombre | Obligatorio |
| Descripción | Obligatoria según la fuente actual |
| Precio | >0 y menor que ambas sumas |

#### Componentes

| Dato | Uso |
|---|---|
| SKU | Identidad vendible |
| Producto / variante | Contexto legible |
| Precio regular | Referencia |
| Precio público vigente | Referencia |
| Disponibilidad | Proyección |
| Cantidad | Entero >0 |
| Aporte | `floor(available/cantidad)` |

La UI **no impone un máximo de componentes no definido por SPEC/HU**.

#### Resumen

- Suma regular.
- Suma pública vigente.
- Precio del combo.
- Disponibilidad estimada.
- Componente limitante.
- Última actualización de disponibilidad.

### S-03 — Selector

- Buscar por nombre/SKU.
- Solo SKU vendibles directos.
- Excluir:
  - combos;
  - SKU inactivos;
  - SKU ya seleccionados.

### S-04 — Desactivar

Copy:

> El combo dejará de estar disponible para nuevas ventas. Los productos que lo componen no serán desactivados.

### S-05 — Detalle

Mostrar composición, cantidades y las dos referencias de precio.

Bloque de disponibilidad:

> **Disponibilidad estimada**  
> Calculada con la última información disponible. La existencia definitiva se verifica durante el pedido.

No mostrar nombres de endpoints ni eventos.

## 10. Estados de interfaz

- cargando;
- vacío;
- datos;
- guardando;
- error;
- conflicto;
- sin permisos;
- sesión expirada;
- disponibilidad 0;
- disponibilidad no verificable;
- inactivo;
- requiere revisión.

## 11. Responsividad

### > 900 px

- tabla;
- formulario en 2 columnas;
- resumen lateral.

### <= 900 px

- tabla contenida o tarjetas;
- formulario apilado parcialmente.

### <= 600 px

- tarjetas;
- formulario de una columna;
- diálogos casi a ancho completo;
- acciones de 44 px mínimo.

No debe existir scroll horizontal del `body` a 320 px.

## 12. Accesibilidad

- WCAG 2.2 AA.
- Un H1.
- labels persistentes.
- errores vinculados al campo.
- foco visible.
- diálogos con foco contenido.
- estados no dependen del color.
- región `aria-live` para confirmaciones.

## 13. Microcopy

| Contexto | Texto |
|---|---|
| mínimo | `Añade al menos 2 SKUs distintos.` |
| anidamiento | `No se permiten combos dentro de otros combos.` |
| cantidad | `Ingresa una cantidad entera mayor que cero.` |
| precio | `El precio debe ser menor que comprar los componentes por separado.` |
| estimación | `Disponibilidad estimada con la última información recibida.` |
| no verificable | `No pudimos verificar la disponibilidad en este momento.` |
| baja automática | `Este combo requiere revisión porque uno de sus componentes dejó de estar activo.` |

## 14. Contratos relacionados

### OpenAPI

```text
GET   /api/v1/combos
POST  /api/v1/combos
GET   /api/v1/combos/{comboId}
PATCH /api/v1/combos/{comboId}
POST  /api/v1/combos/{comboId}/desactivar
GET   /api/v1/combos/{comboId}/disponibilidad
```

### Inventario

La UI no llama a mutaciones de stock. El ciclo de pedido usa el contrato de Ventas/Postventa e Inventario:

```text
POST /api/v1/inventario/reservas
POST /api/v1/inventario/reservas/{reservaId}/confirmar
POST /api/v1/inventario/reservas/{reservaId}/liberar
```

Los canales solo consultan.

### Eventos

- `catalog.sku.deactivated` puede causar inhabilitación del combo.
- No declarar `order.*` como eventos publicados por el AsyncAPI actual.
- El reintegro de devolución queda pendiente de homologación.

## 15. Seguridad

- Autorización real en backend.
- 401/403 según contrato.
- No revelar detalles internos.
- Evitar doble guardado.
- El frontend no es autoridad de precio ni stock.

## 16. Cobertura HU

| CA | Cobertura |
|---|---|
| 01 | permisos/estados globales |
| 02–04 | S-02/S-03 |
| 05–06 | disponibilidad |
| 07–10 | restricciones documentales del ciclo de pedido; sin controles UI |
| 11–14 | S-02/S-05 |
| 15 | detalle/snapshot fuera de edición histórica |
| 16 | fuera de alcance explícito |
| 17–18 | contrato técnico; no contenido UI |

## 17. Supuestos y pendientes reales

| ID | Tema | Estado |
|---|---|---|
| Q-01 | Longitud de nombre/descripción | Abierta |
| Q-02 | Moneda/multimoneda del combo | Abierta |
| Q-03 | Redondeo comercial definitivo | Abierta |
| Q-04 | Reactivación de combo | Abierta |
| Q-05 | Contrato de devolución/reintegro | Paso de homologación externa |
| D-01 | Librería UI/CSS productiva | Pendiente de frontend |

Se elimina como pendiente el flujo `order.confirmed` sin reserva: fue sustituido por el ciclo homologado `CREADO → reserva`, `PAGADO → consumo`, `PAGO_NO_COMPLETADO → liberación`.

## 18. Alineación definitiva

- Combo = capacidad comercial.
- Inventario = propietario del stock.
- Ventas/Postventa = propietario del pedido y orquestador de movimientos.
- Canales = consulta.
- Disponibilidad = estimación.
- Reserva = al crear pedido.
- Consumo = al pagar.
- Liberación = pago no completado/cancelación aplicable.
- Devolución = contrato todavía pendiente.
