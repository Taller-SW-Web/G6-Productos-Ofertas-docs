# MK-009 — Component Spec: gestión de características y sus valores

## 1. Identificación y estado

| Campo | Valor |
|---|---|
| Issue / coordinación | Ejecución general #61; entradas transversales #59 y #60 |
| Responsable / rama | Leonardo Lopez (`lopez`) / `lopez` |
| Versión / fecha | 1.0.0 / 2026-10-03 |
| Estado documental | En revisión; no acredita aprobación funcional, implementación ni visto bueno para Figma |
| Funcionalidad / actor | Atributos maestros del catálogo: tipos de dato, unidades y valores / Gestor Comercial |
| Plataforma | Web desktop; revisión canónica a 1440 × 900 px, con scroll vertical |

Este documento define la especificación formal del resultado esperado de MK-009. [Plan](plan.md) define la estrategia de construcción y [Tasks](tasks.md) las acciones ejecutables. Subordinado a las fuentes normativas, no redefine reglas de negocio ni introduce una propuesta UX paralela.

---

## 2. Fuentes y trazabilidad

| Fuente | Alcance consumido |
|---|---|
| [SPEC-009](../../specs/SPEC-009-gestion-caracteristicas.md) | Tipos exactos (`TEXTO`, `NUMERO`, `LISTA`), inmutabilidad del tipo, unidad de medida requerida para NUMERO, límite de 50 valores activos para LISTA, baja segura de valores |
| [HU-009](../../hu/HU-009-gestion-caracteristicas.md) | Criterios CA-01 a CA-12: validación de tipos, propagación por ID, preservación de valores en uso y exclusión de características inactivas para nuevas asociaciones |
| [WF-009](../../wireframes/flows/WF-009-gestion-caracteristicas.md) | Pantallas S-01 a S-06 (incluyendo S-04-P, S-04-R y S-05), interacción y copys normativos |
| [FLOW-009](../../flujos/FLOW-009-gestion-caracteristicas.md) | §4.1 consulta y filtros; §4.2 creación condicional; §4.3 inmutabilidad en edición; §4.4 gestión y baja segura de valores |
| [OpenAPI 0.5.0](../../api/openapi.yaml) | `CaracteristicaAdmin`, `CaracteristicaCreateRequest`, `CaracteristicaUpdateRequest`, `ValorCaracteristica`, `PaginaCaracteristicas`, `/caracteristicas/*` |
| [AsyncAPI](../../asyncapi/asyncapi.yaml), [Contrato API](../../Contrato_Api.md) | Evento de propagación de renombrado (`taxonomy.characteristic-value.updated`) y protocolo de verificación de uso para baja segura |
| [Propuesta UX](../ux/propuesta-ux.md) | UX 2.0; matriz de aplicabilidad: UX-P01 Alta (visibilidad de tipo/valores), UX-P02 Alta (revelación progresiva por tipo de dato), UX-P03 Alta (conservación de datos en uso y error contextual) |
| [UX Decisions](../ux/ux-decisions.md) | UXD-001 (contexto), UXD-002 (revelación de campos condicionales), UXD-003 (tablas y filtros), UXD-005 (feedback situado), UXD-008 (estados transitorios), UXD-011 (acciones críticas) |
| [UX Guidelines](../ux/ux-guidelines.md) | UXG-003 a UXG-006, UXG-009 a UXG-015, UXG-018, UXG-020 a UXG-022 |
| [Design System](../DESIGN.md) | Versión 1.0.0: layout desktop, foundations, DS-C01, DS-C02, DS-C03, DS-C04, DS-C06, DS-C13, DS-C14, DS-C17, DS-C18, DS-C19, DS-C21, DS-C22, DS-C24, DS-C25, DS-C28 |
| [Gobernanza](../../EQUIPO_Y_RESPONSABILIDADES.md) | Ownership funcional de `taxonomy-svc`, revisión transversal UX por Leonardo Vera Rodríguez |

---

## 3. Objetivo funcional, alcance y límites

### 3.1. Objetivo
Permitir al Gestor Comercial definir y mantener el catálogo maestro de características y atributos (`TEXTO`, `NUMERO`, `LISTA`) que posteriormente estructurarán los esquemas de los tipos de producto, garantizando la inmutabilidad de los tipos de dato, la integridad de los valores en uso en productos y la trazabilidad de bajas lógicas.

### 3.2. Alcance incluido
- Listado paginado de características maestras con filtros por nombre y tipo de dato.
- Creación de características aplicando revelación progresiva (UX-P02):
  - `TEXTO`: longitud máxima configurable (máx. 100).
  - `NUMERO`: selector/input obligatorio de unidad de medida (ej. cm, kg, W, L).
  - `LISTA`: gestión integrada de catálogo de opciones predefinidas (hasta 50 activas).
- Edición de características: actualización de nombre y unidad de medida; el tipo de dato permanece **estrictamente inmutable**.
- Administración de valores de tipo LISTA: alta de nuevos valores, renombrado conservando ID y baja lógica segura con verificación asíncrona de impacto.
- Desactivación y reactivación de la característica maestra (una característica inactiva conserva su histórico pero no se ofrece para nuevas asociaciones en MK-010).

### 3.3. Fuera de alcance
- Asignación de características a categorías (las categorías **no** tienen características en este sistema).
- Asociación de características a tipos de producto (corresponde a MK-010).
- Poblado o asignación de valores concretos a productos o variantes (corresponde a MK-003 y MK-004 de Catálogo).
- Eliminación física de características o valores (solo baja lógica).

---

## 4. Inventario completo de pantallas P0

| ID | Correspondencia WF / Propósito | Entrada y acción principal / salida | Ruta directa |
|---|---|---|---|
| MK-009-S01 | WF S-01; Listado de características | Vista paginada de características; filtrar por tipo/estado; abrir creación, edición, valores o desactivación | `/MK009/S01` |
| MK-009-S02 | WF S-02; Creación de característica | Selector de tipo (`TEXTO`, `NUMERO`, `LISTA`); campos condicionales revelados; «Crear característica» | `/MK009/S02` |
| MK-009-S03 | WF S-03; Edición de característica | Característica seleccionada; edición de nombre y unidad; tipo bloqueado como solo lectura; «Guardar cambios» | `/MK009/S03` |
| MK-009-S04 | WF S-04; Gestión de valores (tipo LISTA) | Vista de valores del catálogo de la característica; agregar nuevo valor, editar nombre, dar de baja | `/MK009/S04` |
| MK-009-S04-P | WF S-04-P; Verificando uso de valor de lista | Diálogo / banner transitorio `Comprobando uso en productos` (202 Accepted); valor permanece visible | `/MK009/S04-P` |
| MK-009-S04-R | WF S-04-R; Rechazo de baja de valor | Diálogo de rechazo con indicación de que el valor está asignado a productos activos en Catálogo; «Entendido» | `/MK009/S04-R` |
| MK-009-S05 | WF S-05; Desactivar / Reactivar característica | Diálogo de confirmación de cambio de estado de la característica maestra; aviso de conservación de ID | `/MK009/S05` |
| MK-009-S06 | WF S-06; Detalle de característica | Ficha técnica de la característica, metadatos, tipo, unidad, lista de valores asociados y estado | `/MK009/S06` |

---

## 5. Navegación y jerarquía de pantallas

```mermaid
flowchart TD
    S01["MK-009-S01 Listado de características"] -->|Nueva característica| S02["MK-009-S02 Creación condicional"]
    S02 -->|Crear: 201 Created| S01
    S02 -->|Cancelar| S01

    S01 -->|Editar| S03["MK-009-S03 Edición (Tipo inmutable)"]
    S03 -->|Guardar: 200 OK| S01

    S01 -->|Gestionar valores (Solo LISTA)| S04["MK-009-S04 Valores de lista"]
    S04 -->|Dar de baja valor| S04P["MK-009-S04-P Comprobando uso"]
    S04P -->|Valor en uso activo| S04R["MK-009-S04-R Baja rechazada"]
    S04P -->|Sin productos vinculados: 200 OK| S04
    S04R -->|Entendido| S04
    S04 -->|Volver al listado| S01

    S01 -->|Cambiar estado| S05["MK-009-S05 Desactivar / Reactivar"]
    S05 -->|Confirmar: 200 OK| S01

    S01 -->|Ver detalle| S06["MK-009-S06 Detalle"]
    S06 -->|Editar| S03
    S06 -->|Valores| S04
    S06 -->|Volver| S01
```

---

## 6. Contratos de datos y operaciones admitidas

Base HTTP: `/api/v1`.

| Operación / Endpoint | Uso en MK-009 | DTO / Contrato | Regla de representación en interfaz |
|---|---|---|---|
| `GET /caracteristicas` | S01 | Query: `pagina, tamanio, tipo, estado`<br>Res: `PaginaCaracteristicas` | Tabla paginada; filtros en FilterBar; muestra badge por tipo (`TEXTO`, `NUMERO`, `LISTA`) |
| `POST /caracteristicas` | S02 | Req: `CaracteristicaCreateRequest { nombre, tipo, unidadMedida }`<br>Res: 201 `CaracteristicaAdmin` | Formulario dinámico; si `tipo=NUMERO`, `unidadMedida` es obligatoria; si `tipo=LISTA`, redirige a S04 tras crear |
| `GET /caracteristicas/{id}` | S03, S06 | Res: 200 `CaracteristicaAdmin` | Carga datos completos para edición o ficha técnica |
| `PUT /caracteristicas/{id}` | S03 | Req: `CaracteristicaUpdateRequest { nombre, unidadMedida, version }`<br>Res: 200 `CaracteristicaAdmin` | Actualiza nombre o unidad; el campo `tipo` se muestra deshabilitado con badge explicativo |
| `GET /caracteristicas/{id}/valores` | S04, S06 | Res: 200 Array de `ValorCaracteristica` | Tabla de valores con estado (`ACTIVO`/`INACTIVO`), conteo de valores y botón de agregar |
| `POST /caracteristicas/{id}/valores` | S04 | Req: `ValorCaracteristicaWriteRequest { nombre }`<br>Res: 201 `ValorCaracteristica` | Alta de valor; valida límite de hasta 50 valores activos; rechaza duplicados locales |
| `PUT /caracteristicas/{id}/valores/{vid}` | S04 | Req: `ValorCaracteristicaWriteRequest { nombre, version }`<br>Res: 200 `ValorCaracteristica` | Renombrado de valor; conserva `valorId`; aclara que se propaga a productos |
| `POST /caracteristicas/{id}/valores/{vid}/desactivar` | S04 → S04P | Res: 202 `Accepted` | Admisión de baja; UI muestra estado transitorio `Comprobando uso en productos` |
| `POST /caracteristicas/{id}/desactivar` | S05 | Res: 200 `CaracteristicaAdmin` | Desactivación síncrona de la característica; advierte que no se ofrecerá para nuevos esquemas |
| `POST /caracteristicas/{id}/reactivar` | S05 | Res: 200 `CaracteristicaAdmin` | Reactivación síncrona; vuelve a estar disponible para asociaciones en MK-010 |

### Reglas críticas de interacción:
1. **Inmutabilidad estricta del tipo de dato:** En S03, el selector de tipo se reemplaza por un texto no editable con un candado visual y el texto: *"El tipo de dato es inmutable tras la creación de la característica para garantizar integridad histórica"*.
2. **Unidad de medida obligatoria para NUMERO:** El campo de unidad se revela automáticamente al seleccionar `NUMERO` y no permite enviar el formulario vacío.
3. **Baja segura de valores de lista (202 Accepted):** La baja no elimina la fila de la vista inmediatamente; muestra el badge `COMPROBANDO_USO` mientras se verifica con Catálogo. Ante rechazo, se conserva intacta con aviso de error persistente.

---

## 7. Componentes del Design System utilizados

| Componente DS | Identificador | Pantallas | Uso específico |
|---|---|---|---|
| Botón principal y secundario | DS-C01 | S01–S06 | Acciones de crear, guardar valor, confirmar baja, volver |
| Iconos de acción | DS-C02 | S01, S04 | Acciones de fila: editar, ver valores, desactivar, reactivar |
| Input de texto | DS-C03 | S01–S04 | Nombre de característica, unidad de medida, nombre de valor de lista |
| Selector desplegable | DS-C06 | S01, S02 | Selector de tipo de dato (`TEXTO`, `NUMERO`, `LISTA`) y filtro de tipo |
| Barra de filtros | DS-C13 | S01 | Filtrado por texto, tipo de dato y estado activo/inactivo |
| Badge de estado y tipo | DS-C14 | S01, S03, S04, S06 | Badges: `TEXTO` (azul), `NUMERO` (verde), `LISTA` (morado), `ACTIVO`, `INACTIVO` |
| Tabla de datos | DS-C17 | S01, S04 | Tabla con cabeceras comprensibles, alineación y acciones fijas |
| Paginación | DS-C18 | S01 | Navegación entre páginas de características con indicador de total |
| Card de contenido | DS-C19 | S02, S03, S04, S06 | Contenedores modulares de formularios y listas |
| Modal de confirmación | DS-C21 | S04P, S04R, S05 | Diálogos de baja segura y cambio de estado de característica |
| Alertas contextuales | DS-C22 | S02, S03, S04P, S04R | Mensajes informativos de inmutabilidad y advertencias de uso |
| Skeleton / Loader | DS-C24 | S01, S04, S06 | Carga inicial de tablas y verificación de uso en productos |
| Estado vacío | DS-C25 | S01, S04 | Lista de características vacía o característica tipo LISTA sin valores creados |
| Migas de pan | DS-C28 | S01–S06 | Ruta: `Inicio > Taxonomía > Características` |

---

## 8. Componentes locales (`MK-009-CXX`)

| ID | Nombre | Pantallas | Props principales | Comportamiento y accesibilidad |
|---|---|---|---|---|
| MK-009-C01 | FormularioTipoDato | S02, S03 | `tipo: TipoCaracteristica`, `unidad?: string`, `isEdit: boolean`, `onChange` | Aplica revelación progresiva de campos; deshabilita y bloquea tipo en edición |
| MK-009-C02 | TablaValoresLista | S04 | `valores: ValorCaracteristica[]`, `onAdd`, `onEdit`, `onDeactivate` | Tabla accesible con edición inline o modal de nombres y control de límite de 50 activos |
| MK-009-C03 | ModalBajaValor | S04, S04P, S04R | `valor: ValorCaracteristica`, `isOpen: boolean`, `status: EstadoBaja`, `onConfirm`, `onClose` | Gestiona el flujo `Confirmar → 202 Comprobando → Rechazo/Éxito` con focus trap |

---

## 9. Decisiones UX locales (`LUX-09`)

* **LUX-09-01: Revelación de gestión de valores post-creación:**  
  Al crear una característica de tipo `LISTA` en S02, el botón principal cambia de *"Crear característica"* a *"Crear y configurar valores"*, redirigiendo automáticamente a S04 con mensaje de éxito para permitir la carga inmediata de opciones.
* **LUX-09-02: Contador visible de límite operativo de valores:**  
  En S04, sobre la tabla de valores se muestra un indicador visual en formato pill *"X de 50 valores activos utilizados"*, cambiando a color ámbar a partir del valor 45 para prevenir al gestor antes de alcanzar el tope contractual.

---

## 10. Fixtures deterministas para prototipo

| Fixture ID | Escenario representado | Datos mock |
|---|---|---|
| `FX-009-01` | Listado general con 3 tipos | Lista con `Color` (LISTA), `Material` (TEXTO), `Potencia` (NUMERO, W), `Peso` (NUMERO, kg) |
| `FX-009-02` | Creación de característica NUMERO | Selección de tipo NUMERO con campo obligatorio de unidad precargado con `cm` |
| `FX-009-03` | Edición con tipo inmutable | Característica `Color`: tipo LISTA deshabilitado, nombre editable |
| `FX-009-04` | Catálogo de valores de Color | 12 valores activos (`Rojo`, `Azul`, `Negro`, etc.) con contador `12 / 50 activos` |
| `FX-009-05` | Baja de valor en verificación | Valor `Azul Marino` en estado transitorio `COMPROBANDO_USO` (202 Accepted) |
| `FX-009-06` | Rechazo de baja por uso | Rechazo de baja de `Rojo` con mensaje: *"El valor está asignado a 82 variantes activas"* |
| `FX-009-07` | Desactivación de característica | Diálogo para desactivar `Potencia` con aviso de preservación de histórico |

---

## 11. Criterios de aceptación (Coverage HU-009)

- [ ] **CA-01 (Reglas TEXTO):** S02 permite crear característica de texto sin requerir unidad ni catálogo de valores.
- [ ] **CA-02 (Reglas NUMERO):** S02 exige obligatoriamente especificar unidad de medida para características numéricas.
- [ ] **CA-03 (Reglas LISTA):** S04 gestiona valores predefinidos y controla el tope máximo de 50 valores activos.
- [ ] **CA-04 (Renombrado y propagación):** S04 permite renombrar valores conservando el identificador único.
- [ ] **CA-05 (Consulta y detalle):** S01 y S06 muestran el tipo de dato, unidad y valores vinculados.
- [ ] **CA-08 (Inmutabilidad del tipo):** S03 bloquea cualquier modificación del tipo de dato en edición.
- [ ] **CA-09 (Baja segura de valor):** S04-P y S04-R gestionan la verificación asíncrona y el rechazo por uso activo.
- [ ] **CA-11 (Estado de característica):** S05 permite desactivar y reactivar la característica maestra sin perder histórico.
