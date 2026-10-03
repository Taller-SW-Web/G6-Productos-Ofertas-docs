# MK-010 — Component Spec: asociación entre tipos de producto y características

## 1. Identificación y estado

| Campo | Valor |
|---|---|
| Issue / coordinación | Ejecución general #61; entradas transversales #59 y #60 |
| Responsable / rama | Leonardo Lopez (`lopez`) / `lopez` |
| Versión / fecha | 1.0.0 / 2026-10-03 |
| Estado documental | En revisión; no acredita aprobación funcional, implementación ni visto bueno para Figma |
| Funcionalidad / actor | Definición de esquemas de atributos por tipo de producto / Gestor Comercial |
| Plataforma | Web desktop; revisión canónica a 1440 × 900 px, con scroll vertical |

Este documento define la especificación formal del resultado esperado de MK-010. [Plan](plan.md) define la estrategia constructiva y [Tasks](tasks.md) las acciones ejecutables. Subordinado a las fuentes normativas, no redefine reglas de negocio ni introduce una propuesta UX paralela.

---

## 2. Fuentes y trazabilidad

| Fuente | Alcance consumido |
|---|---|
| [SPEC-010](../../specs/SPEC-010-asociacion-tipo-producto-caracteristica.md) | El esquema de atributos pertenece a `TipoProducto` (nunca a categoría), obligatoriedad/opcionalidad, límite configurable de características, versionado de esquema y bajas seguras |
| [HU-010](../../hu/HU-010-asociacion-tipo-producto-caracteristica.md) | Criterios CA-01 a CA-17: creación ligera de tipo, configuración de esquema, asociación, cambio de obligatoriedad, desasociación con verificación y estados de entidad |
| [WF-010](../../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md) | Pantallas S-01 a S-07, reglas de no exposición de IDs técnicos, ausencia de ordenamiento visual arbitrario y copy normativo |
| [FLOW-010](../../flujos/FLOW-010-asociacion-tipo-producto-caracteristica.md) | §4.1 consulta de esquemas; §4.2 creación de tipo; §4.3 asociación de características; §4.4 desasociación segura con Catálogo |
| [OpenAPI 0.5.0](../../api/openapi.yaml) | `TipoProductoAdmin`, `TipoProductoCreateRequest`, `AsociacionTipoCaracteristica`, `EsquemaTipoProducto`, `/tipos-producto/*` |
| [AsyncAPI](../../asyncapi/asyncapi.yaml), [Contrato API](../../Contrato_Api.md) | Eventos de cambio de esquema (`taxonomy.product-type.schema-updated`) y verificación asíncrona de desasociación |
| [Propuesta UX](../ux/propuesta-ux.md) | UX 2.0; matriz de aplicabilidad: UX-P01 Alta (visibilidad de esquema), UX-P02 Alta (configuración de atributos), UX-P03 Alta (conservación de datos ante conflicto y desasociación segura) |
| [UX Decisions](../ux/ux-decisions.md) | UXD-001 (contexto), UXD-002 (complejidad pertinente), UXD-003 (tablas legibles), UXD-005 (feedback situado), UXD-007 (confirmación de cambios), UXD-008 (estados transitorios), UXD-011 (acciones críticas) |
| [UX Guidelines](../ux/ux-guidelines.md) | UXG-003 a UXG-006, UXG-009 a UXG-015, UXG-018, UXG-020 a UXG-022 |
| [Design System](../DESIGN.md) | Versión 1.0.0: layout desktop, foundations, DS-C01, DS-C02, DS-C03, DS-C06, DS-C10 (Switch), DS-C14, DS-C17, DS-C19, DS-C21, DS-C22, DS-C24, DS-C25, DS-C28 |
| [Gobernanza](../../EQUIPO_Y_RESPONSABILIDADES.md) | Ownership funcional de `taxonomy-svc`, revisión transversal UX por Leonardo Vera Rodríguez |

---

## 3. Objetivo funcional, alcance y límites

### 3.1. Objetivo
Permitir al Gestor Comercial definir tipos de producto y componer sus esquemas de atributos mediante la asociación de características maestras activas, marcándolas como obligatorias u opcionales, controlando el límite operativo por tipo y garantizando que desasociaciones o bajas no destruyan datos de productos en uso.

### 3.2. Alcance incluido
- Listado de tipos de producto con estado (`ACTIVO`/`INACTIVO`), conteo de características asociadas y versión del esquema.
- Creación rápida de un nuevo tipo de producto (formulario ligero: nombre).
- Vista de configuración y detalle del esquema de un tipo de producto.
- Asociación de características activas (seleccionables de MK-009) con validación de límite operativo («X de N características»).
- Modificación de obligatoriedad (Switch `Obligatoria` / `Opcional`) que incrementa la versión del esquema.
- Desasociación segura de característica con verificación asíncrona de impacto en productos (`202 Accepted`).
- Desactivación y reactivación controlada del tipo de producto.

### 3.3. Fuera de alcance
- Asignación de esquemas a categorías (principio rector: **las categorías no estructuran atributos**).
- Reordenamiento visual arbitrario de características (el contrato no define orden posicional).
- Captura de valores de producto concretos (responsabilidad de Catálogo en MK-003).
- Eliminación física de tipos o asociaciones.

---

## 4. Inventario completo de pantallas P0

| ID | Correspondencia WF / Propósito | Entrada y acción principal / salida | Ruta directa |
|---|---|---|---|
| MK-010-S01 | WF S-01; Listado de tipos de producto | Vista tabular de tipos; conteo de características y versión de esquema; abrir creación, esquema o cambio de estado | `/MK010/S01` |
| MK-010-S02 | WF S-02; Creación de tipo de producto | Formulario ligero (nombre requerido); «Crear y configurar esquema» o «Cancelar» | `/MK010/S02` |
| MK-010-S03 | WF S-03; Configuración del esquema | Ficha del tipo y tabla de características asociadas; switch obligatoria; indicador de versión; «Asociar característica» | `/MK010/S03` |
| MK-010-S04 | WF S-04; Modal de asociar característica | Selector de características maestras activas disponibles; visualización de límite operativo; «Asociar al esquema» | `/MK010/S04` |
| MK-010-S05 | WF S-05; Diálogo de desasociación segura | Advertencia de impacto; confirmación de inicio de verificación; estados transitorios (202 Comprobando / Rechazo / Éxito) | `/MK010/S05` |
| MK-010-S06 | WF S-06; Desactivación de tipo de producto | Diálogo de baja lógica con advertencia sobre productos asociados; confirmación de solicitud | `/MK010/S06` |
| MK-010-S07 | WF S-07; Reactivación de tipo de producto | Confirmación síncrona de reactivación; tipo vuelve a estar disponible para nuevos productos | `/MK010/S07` |

---

## 5. Navegación y jerarquía de pantallas

```mermaid
flowchart TD
    S01["MK-010-S01 Listado de tipos de producto"] -->|Nuevo tipo| S02["MK-010-S02 Creación ligera"]
    S02 -->|Crear: 201 Created| S03["MK-010-S03 Configuración de esquema"]
    S02 -->|Cancelar| S01

    S01 -->|Configurar esquema| S03
    S03 -->|Asociar característica| S04["MK-010-S04 Modal de asociación"]
    S04 -->|Confirmar asociación: 201| S03
    S04 -->|Cancelar| S03

    S03 -->|Desasociar| S05["MK-010-S05 Desasociación segura"]
    S05 -->|Verificación rechazada (en uso)| S03
    S05 -->|Verificación exitosa: 200 OK| S03

    S01 -->|Desactivar tipo| S06["MK-010-S06 Desactivación"]
    S06 -->|Confirmar baja| S01

    S01 -->|Reactivar tipo| S07["MK-010-S07 Reactivación"]
    S07 -->|Confirmar reactivación| S01
```

---

## 6. Contratos de datos y operaciones admitidas

Base HTTP: `/api/v1`.

| Operación / Endpoint | Uso en MK-010 | DTO / Contrato | Regla de representación en interfaz |
|---|---|---|---|
| `GET /tipos-producto` | S01 | Res: Array de `TipoProductoAdmin` | Listado general; muestra nombre, estado, `schemaVersion` y conteo de características |
| `POST /tipos-producto` | S02 | Req: `TipoProductoCreateRequest { nombre }`<br>Res: 201 `TipoProductoAdmin` | Creación ligera; al confirmar redirige directamente a la configuración del esquema S03 |
| `GET /tipos-producto/{id}/caracteristicas` | S03 | Res: Array de `AsociacionTipoCaracteristica` | Tabla de características del esquema; muestra nombre, tipo, unidad, obligatoriedad y versión |
| `POST /tipos-producto/{id}/caracteristicas` | S04 | Req: `AsociacionTipoCaracteristicaCreateRequest { caracteristicaId, obligatoria }`<br>Res: 201 | Asocia característica activa; valida que no esté ya asociada y que no supere el límite del tipo |
| `PUT /tipos-producto/{id}/caracteristicas/{cid}` | S03 | Req: `AsociacionTipoCaracteristicaUpdateRequest { obligatoria, schemaVersion }`<br>Res: 200 | Modifica obligatoriedad mediante Switch; incrementa `schemaVersion` y muestra feedback de guardado |
| `POST /tipos-producto/{id}/caracteristicas/{cid}/desasociar` | S05 | Res: 202 `Accepted` (o 409 si en uso) | Desasociación segura; UI muestra `Comprobando impacto en productos`; si hay productos poblados, rechaza con detalle |
| `POST /tipos-producto/{id}/desactivar` | S06 | Res: 202 `Accepted` con `OperacionMaestra` | Baja lógica de tipo coordinada con Catálogo; no permite desactivar si hay productos activos vinculados |
| `POST /tipos-producto/{id}/reactivar` | S07 | Res: 200 `TipoProductoAdmin` | Reactivación síncrona; reactiva el tipo para selección en creación de productos |

### Reglas críticas de interacción:
1. **Límite operativo de características:** En S03 y S04 se visualiza el contador: *"X de N características permitidas"*. Si se alcanza el límite, el botón de asociación se deshabilita con tooltip explicativo.
2. **Versión del esquema solo lectura:** El número de versión (`schemaVersion`) se expone como un badge de soporte informativo: *"Versión del esquema: v3"*, no como un control editable.
3. **No invención de orden:** La tabla de características no ofrece controles de «subir/bajar» o «drag & drop», ya que el contrato no modela orden posicional de atributos.

---

## 7. Componentes del Design System utilizados

| Componente DS | Identificador | Pantallas | Uso específico |
|---|---|---|---|
| Botón principal y secundario | DS-C01 | S01–S07 | Acciones de crear tipo, asociar característica, confirmar desasociación |
| Iconos de acción | DS-C02 | S01, S03 | Acciones de fila: configurar esquema, desasociar, desactivar |
| Input de texto | DS-C03 | S01, S02 | Nombre del tipo de producto y buscador en tablas |
| Selector desplegable | DS-C06 | S04 | Selector de características maestras activas |
| Switch / Interruptor | DS-C10 | S03, S04 | Control de `Obligatoria` (activado) u `Opcional` (desactivado) |
| Badge de estado y versión | DS-C14 | S01, S03 | Badges: `ACTIVO`, `INACTIVO`, `v1/v2/v3` (esquema) |
| Tabla de datos | DS-C17 | S01, S03 | Listado de tipos de producto y tabla de características del esquema |
| Card de contenido | DS-C19 | S01, S02, S03 | Contenedor principal de configuración de esquema y fichas de datos |
| Modal de confirmación | DS-C21 | S04, S05, S06, S07 | Diálogos de asociación, desasociación y cambio de estado |
| Alertas contextuales | DS-C22 | S03, S05, S06 | Advertencias de impacto en productos y notificaciones de versión |
| Skeleton / Loader | DS-C24 | S01, S03 | Carga inicial y estados de espera de desasociación |
| Estado vacío | DS-C25 | S01, S03 | Tipo de producto sin características asociadas aún |
| Migas de pan | DS-C28 | S01–S07 | Navegación: `Inicio > Taxonomía > Tipos de producto` |

---

## 8. Componentes locales (`MK-010-CXX`)

| ID | Nombre | Pantallas | Props principales | Comportamiento y accesibilidad |
|---|---|---|---|---|
| MK-010-C01 | TablaEsquemaCaracteristicas | S03 | `caracteristicas: AsociacionTipoCaracteristica[]`, `onToggleObligatoria`, `onRemove` | Tabla con switches de obligatoriedad accesibles (`aria-checked`) y botón de desasociación |
| MK-010-C02 | ModalAsociarCaracteristica | S04 | `isOpen: boolean`, `disponibles: CaracteristicaAdmin[]`, `limiteAlcanzado: boolean`, `onAdd`, `onClose` | Selector filtrado por búsqueda con switch de obligatoriedad inicial y focus trap |
| MK-010-C03 | ModalDesasociarSegura | S05 | `caracteristica: AsociacionTipoCaracteristica`, `isOpen: boolean`, `onConfirm`, `onClose` | Modal de confirmación con explicación de impacto y manejo de rechazo por productos en uso |

---

## 9. Decisiones UX locales (`LUX-10`)

* **LUX-10-01: Confirmación suave al cambiar obligatoriedad de característica:**  
  Al conmutar el Switch de obligatoriedad en S03, en lugar de abrir un modal bloqueante invasivo, la interfaz aplica el cambio de inmediato, actualiza el badge de versión de esquema y muestra un toast/banner no intrusivo con opción de *"Deshacer"* durante 5 segundos.
* **LUX-10-02: Visualización amigable de límites operativos:**  
  La relación de características se presenta como una barra de progreso compacta acompañada del texto *"8 / 15 características configuradas"*, cambiando a color de advertencia al superar el 80% de la capacidad.

---

## 10. Fixtures deterministas para prototipo

| Fixture ID | Escenario representado | Datos mock |
|---|---|---|
| `FX-010-01` | Listado general de tipos de producto | `Calzado Deportivo` (activo, 6 características, v2), `Electrodoméstico` (activo, 9 características, v4), `Ropa` (activo, 4 características, v1) |
| `FX-010-02` | Esquema de Calzado Deportivo | Características: `Talla` (LISTA, Obligatoria), `Color` (LISTA, Obligatoria), `Material` (TEXTO, Opcional), `Peso` (NUMERO, Opcional) |
| `FX-010-03` | Asociación de nueva característica | Selector con características no asociadas (`Garantía`, `Impermeabilidad`) y límite en 6/15 |
| `FX-010-04` | Límite máximo de características alcanzado | Esquema con 15/15 características; botón de asociar deshabilitado con alerta |
| `FX-010-05` | Desasociación en verificación | Característica `Impermeabilidad` en estado `COMPROBANDO_USO` |
| `FX-010-06` | Desasociación rechazada por uso | Rechazo al desasociar `Talla`: *"No es posible desasociar una característica poblada en 140 productos"* |
| `FX-010-07` | Desactivación de tipo de producto | Diálogo para desactivar `Electrodoméstico` con comprobación de catálogo |

---

## 11. Criterios de aceptación (Coverage HU-010)

- [ ] **CA-01 (Creación ligera):** S02 permite crear un nuevo tipo de producto solo con el nombre.
- [ ] **CA-02 (Consulta de esquema):** S03 muestra las características asociadas, su obligatoriedad y versión de esquema.
- [ ] **CA-03 (Asociación):** S04 permite agregar características maestras activas que no estén ya en el esquema.
- [ ] **CA-04 (Control de límites):** S03 y S04 impiden superar el límite configurado de características por tipo.
- [ ] **CA-05 (Cambio de obligatoriedad):** S03 permite alternar entre obligatoria y opcional incrementando la versión.
- [ ] **CA-06 (Desasociación segura):** S05 valida dependencias y rechaza la operación si hay productos con valores asignados.
- [ ] **CA-07 (Baja de tipo):** S06 gestiona la desactivación coordinada con Catálogo.
- [ ] **CA-08 (No ordenamiento inventado):** La interfaz respeta la ausencia de controles posicionales arbitrarios.
