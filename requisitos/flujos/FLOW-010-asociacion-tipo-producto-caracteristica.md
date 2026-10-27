# FLOW-010 — Asociación entre tipos de producto y características

## 1. Identificación

- **Código:** FLOW-010
- **Funcionalidad:** Asociación entre tipos de producto y características
- **Relacionado con:** [HU-010](../hu/HU-010-asociacion-tipo-producto-caracteristica.md) / [SPEC-010](../specs/SPEC-010-asociacion-tipo-producto-caracteristica.md) / [WF-010](..\..\ux\wireframes\flows\WF-010-asociacion-tipo-producto-caracteristica.md)
- **Responsable:** Leonardo Lopez
- **Última actualización:** 2026-10-26

---

## 2. Objetivo del flujo

Representar la gestión de tipos de producto ligeros y su asociación con características activas, indicando obligatoriedad y respetando el límite configurable (`MAX_PRODUCT_TYPE_ATTRIBUTES = 20`). El flujo contempla la consulta del esquema efectivo con `schema_version`, el incremento de `schema_version` en **todo** cambio confirmado, la publicación de `taxonomy.product-type-schema.changed` en cada modificación confirmada —incluidos el cambio de obligatoriedad y la desasociación—, la desactivación y reactivación del tipo de producto con verificación segura cuando existen productos activos, la lectura del `202 Accepted` como simple admisión y la derivación del cambio de `tipo_producto_id` de productos publicados o con variantes a una migración controlada.

---

## 3. Actores participantes

- **Gestor comercial:** crea tipos de producto, administra asociaciones, obligatoriedad y estados.
- **Taxonomía:** mantiene el esquema de asociación, su `schema_version`, el límite configurable y publica los hechos del esquema.
- **Catálogo Core:** consulta el esquema efectivo, verifica el uso de un tipo de producto o de una característica antes de confirmar una baja y proyecta los cambios del esquema.

---

## 4. Diagramas de flujo

### 4.1 Creación y consulta de tipos de producto

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Acceso a tipos de producto))
        D1{"¿Qué acción desea realizar?"}
        G1["Ingresar el nombre del tipo de producto"]
        G2["Abrir el detalle del tipo de producto"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Listar tipos con estado y contador X / MAX_PRODUCT_TYPE_ATTRIBUTES"]
        T2["Crear tipo de producto ligero con tipo_producto_id y estado ACTIVO"]
        T3["Mostrar el esquema efectivo con obligatoriedad y schema_version"]
    end

    FIN_CREADO(((Tipo de producto creado)))
    FIN_CONSULTADO(((Esquema consultado)))

    INICIO --> T1
    T1 --> D1
    D1 -->|"Crear"| G1
    G1 --> T2
    T2 --> FIN_CREADO
    D1 -->|"Consultar"| G2
    G2 --> T3
    T3 --> FIN_CONSULTADO
```

### 4.2 Asociar una característica a un tipo de producto

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Abrir tipo de producto))
        G1["Seleccionar Asociar característica"]
        G2["Elegir una característica activa"]
        G3["Indicar obligatoria u opcional"]
        G4["Guardar la asociación"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Validar que el tipo y la característica estén activos y no asociada"]
        D1{"¿Ya está asociada o se supera el límite configurado?"}
        T2["Registrar la asociación e incrementar schema_version"]
        T3["Publicar taxonomy.product-type-schema.changed con change_type=ASSOCIATED"]
    end

    FIN_ASOCIADA(((Característica asociada y propagada)))
    FIN_RECHAZADA(((Asociación rechazada)))

    INICIO --> G1
    G1 --> T1
    T1 --> D1
    D1 -->|"Sí"| FIN_RECHAZADA
    D1 -->|"No"| G2
    G2 --> G3
    G3 --> G4
    G4 --> T2
    T2 --> T3
    T3 --> FIN_ASOCIADA
```

> Las categorías de navegación no definen ni heredan características: el esquema de atributos se resuelve únicamente a través de `tipo_producto_id`. La asociación solo se publica cuando el cambio queda confirmado.

### 4.3 Cambio de obligatoriedad

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Editar una asociación existente))
        G1["Cambiar la condición obligatoria u opcional"]
        G2["Confirmar el cambio"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Guardar el cambio e incrementar schema_version"]
        D1{"¿La característica pasó a obligatoria?"}
        T2["No invalidar productos existentes; exigir en la próxima edición"]
        T3["Mantener la regla vigente para nuevas escrituras"]
        T4["Publicar taxonomy.product-type-schema.changed con change_type=REQUIREMENT_CHANGED"]
    end

    FIN_ACTUALIZADO(((Esquema actualizado y propagado)))

    INICIO --> G1
    G1 --> G2
    G2 --> T1
    T1 --> D1
    D1 -->|"Sí"| T2
    D1 -->|"No"| T3
    T3 --> T4
    T2 --> T4
    T4 --> FIN_ACTUALIZADO
```

> El cambio de obligatoriedad es un cambio de esquema confirmado: incrementa `schema_version` y se propaga a Catálogo mediante `taxonomy.product-type-schema.changed`.

### 4.4 Desasociación segura de una característica

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Solicitar desasociación))
        G1["Confirmar la desasociación"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Evaluar si la característica es obligatoria o identificadora"]
        D1{"¿Requiere verificación asíncrona con Catálogo?"}
        T2["Admitir la solicitud y mostrar la asociación como en verificación"]
        T3["Registrar la solicitud y publicar taxonomy.master.deactivation.check.requested"]
        DS1{"¿Resultado CLEAR vigente?"}
        T4["Eliminar la asociación lógicamente, conservar el histórico e incrementar schema_version"]
        T5["Publicar taxonomy.master.deactivation.rejected y conservar la asociación"]
        T6["Publicar taxonomy.product-type-schema.changed con change_type=DISASSOCIATED"]
    end

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        C1["Verificar uso en variantes activas"]
        C2["Publicar catalog.master.deactivation.checked con operation_id"]
    end

    FIN_REMOVIDA(((Asociación removida y propagada)))
    FIN_BLOQUEADA(((Desasociación rechazada)))

    INICIO --> G1
    G1 --> T1
    T1 --> D1
    D1 -->|"No"| T4
    D1 -->|"Sí"| T2
    T2 -->|"202 Accepted: solo admisión"| T3
    T3 --> C1
    C1 --> C2
    C2 --> DS1
    DS1 -->|"CLEAR"| T4
    DS1 -->|"No"| T5
    T5 --> FIN_BLOQUEADA
    T3 --> E1(("Time out o error en la verificación"))
    E1 --> FIN_BLOQUEADA
    T4 --> T6
    T6 --> FIN_REMOVIDA
```

> La desasociación de riesgo se solicita por `POST /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}/desasociar`, que responde `202 Accepted`: ese código es **solo admisión**. La asociación se retira únicamente al recibir un resultado `CLEAR` vigente, y solo entonces se incrementa `schema_version` y se publica `taxonomy.product-type-schema.changed`. El estado pendiente se consulta con `GET /api/v1/taxonomia/operaciones/{operationId}`.

### 4.5 Desactivación y reactivación de un tipo de producto

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Abrir un tipo de producto existente))
        D1{"¿El tipo está activo?"}
        G1["Confirmar la desactivación"]
        G2["Confirmar la reactivación"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Registrar PENDING_DEACTIVATION y publicar taxonomy.master.deactivation.check.requested"]
        T2["Devolver 202 Accepted como admisión"]
        T3["Publicar taxonomy.master.deactivated y pasar el tipo a INACTIVO conservando su ID"]
        T4["Publicar taxonomy.master.deactivation.rejected y conservar el tipo ACTIVO"]
        T6["Dejar de ofrecer el tipo para nuevas altas o activaciones"]
        T7["Volver a ACTIVO conservando ID y nombre"]
        T8["Volver a ofrecer el tipo para nuevas altas o activaciones"]
    end

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        C1["Instalar barrera y verificar si existen productos activos que dependan del tipo"]
        C2["Publicar catalog.master.deactivation.checked con operation_id"]
        C3["Recibir taxonomy.master.deactivated correlacionado y vigente;<br/>actualizar proyección y liberar barrera"]
        C4["Recibir taxonomy.master.deactivation.rejected correlacionado y vigente;<br/>conservar tipo activo y liberar barrera"]
        C5["Si falta el evento final: mantener barrera y alertar"]
    end

    FIN_INACTIVO(((Tipo inactivo con el mismo ID)))
    FIN_ACTIVO(((Baja rechazada; tipo conservado activo)))
    FIN_REACTIVO(((Tipo reactivado con el mismo ID)))

    INICIO --> D1
    D1 -->|"Sí"| G1
    G1 --> T1
    T1 --> T2
    T2 --> C1
    C1 --> C2
    C2 --> DS1{"¿Resultado CLEAR vigente?"}
    DS1 -->|"CLEAR"| T3
    DS1 -->|"IN_USE"| T4
    T3 -->|"Evento final recibido"| C3
    C3 --> T6
    T6 --> FIN_INACTIVO
    T4 -->|"Evento final recibido"| C4
    C4 --> FIN_ACTIVO
    T2 --> E1(("Timeout, fallo técnico o conflicto de versión"))
    E1 --> T4
    T3 -.->|"Evento final no recibido"| C5
    T4 -.->|"Evento final no recibido"| C5
    D1 -->|"No"| G2
    G2 --> T7
    T7 --> T8
    T8 --> FIN_REACTIVO
```

> La desactivación de `PRODUCT_TYPE` utiliza el protocolo transversal publicado. El `202 Accepted` de `POST /api/v1/tipos-producto/{tipoProductoId}/desactivar` es únicamente admisión: si existen productos activos la verificación responde uso incompatible y el tipo permanece activo; ante error o falta de respuesta tampoco se desactiva. `POST /api/v1/tipos-producto/{tipoProductoId}/reactivar` conserva el `tipo_producto_id` y vuelve a habilitar el tipo para nuevas operaciones.

`CLEAR` vigente habilita la confirmación de Taxonomía, pero no libera la barrera de Catálogo. `IN_USE`, timeout o fallo técnico siguen exclusivamente el rechazo y conservan el tipo activo. Catálogo libera la barrera solo al consumir el evento final correlacionado, sea de confirmación o rechazo; si ese evento no llega, mantiene el bloqueo y alerta. Los detalles públicos de este protocolo siguen como contrato candidato pendiente de homologación; el diagrama no acredita compatibilidad runtime.

### 4.6 Consulta del esquema por tipo de producto

```mermaid
flowchart LR

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        INICIO((Solicitud de esquema por tipo de producto))
        G1["Invocar API de solo lectura"]
        D2{"¿La schema_version difiere de la conocida?"}
        G2["Invalidar o refrescar la proyección del tipo"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Devolver tipo, estado, características activas, obligatoriedad y schema_version"]
        D1{"¿Existen asociaciones?"}
        T2["Devolver lista vacía conservando la schema_version vigente"]
    end

    FIN_ESQUEMA(((Esquema efectivo entregado con schema_version)))

    INICIO --> G1
    G1 --> T1
    T1 --> D1
    D1 -->|"Sí"| D2
    D1 -->|"No"| T2
    D2 -->|"Sí"| G2
    D2 -->|"No"| T2
    G2 --> T2
    T2 --> FIN_ESQUEMA
```

> La `schema_version` forma parte del esquema efectivo en todas las respuestas, incluso cuando la lista de características está vacía. Catálogo la usa para detectar reglas obsoletas en una escritura concurrente y para refrescar su proyección.

### 4.7 Cambio de `tipo_producto_id` de un producto

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Editar un producto))
        G1["Cambiar tipo_producto_id en la edición ordinaria"]
    end

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        C1["Verificar BORRADOR, tiene_variantes=false, cero filas variants,<br/>publicado_alguna_vez=false y catalogVersion"]
        D1{"¿El producto cumple las condiciones del CRUD ordinario?"}
        C2["Rechazar el PATCH ordinario; informar que requiere migración controlada"]
        C3["Validar concurrencia y confirmar atómicamente el PATCH;<br/>conservar IDs, SKU y snapshots"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Resolver el esquema efectivo y su schema_version del nuevo tipo"]
        D2{"¿El esquema del nuevo tipo es compatible con el producto?"}
        T2["Rechazar toda la edición si atributos no son compatibles;<br/>no borrar atributos automáticamente"]
    end

    FIN_ORDINARIO(((Tipo cambiado en borrador)))
    FIN_RECHAZADO(((PATCH rechazado sin cambios)))

    INICIO --> G1
    G1 --> C1
    C1 --> D1
    D1 -->|"No"| C2
    C2 --> FIN_RECHAZADO
    D1 -->|"Sí"| T1
    T1 --> D2
    D2 -->|"Sí"| C3
    C3 --> FIN_ORDINARIO
    D2 -->|"No"| T2
    T2 --> FIN_RECHAZADO
```

El diagrama representa únicamente el PATCH ordinario Q-06: un esquema compatible y las precondiciones vigentes permiten confirmar el cambio; un esquema incompatible rechaza toda la edición. La migración controlada es un proceso separado, fuera de este CRUD y de este diagrama: el rechazo no la ejecuta ni la autoriza. Un conflicto de `catalogVersion` también rechaza el PATCH sin cambios, según el contrato vigente.

> Q-06: el PATCH existente admite `tipoProductoId` opcional. Solo se permite en `BORRADOR`, `tiene_variantes=false`, cero filas reales en `catalog.variants`, `publicado_alguna_vez=false`, tipo nuevo activo en Taxonomy, atributos compatibles con esquema efectivo/`schemaVersion` y concurrencia `catalogVersion`. Identidad publicada significa primera transición confirmada `BORRADOR → ACTIVO`; preparar, asignar SKU o una activación pendiente no cuenta. `publicado_alguna_vez` requiere una futura migración versionada: nuevos productos `false`, primera activación confirmada `true` atómico e irreversible; históricos `NULL` sin evidencia autoritativa y `NULL` bloquea. Atributos incompatibles rechazan toda la edición, sin borrado automático; faltantes obligatorios no bloquean guardar borrador, solo activar. Se conservan IDs, SKU, modelo de variantes y snapshots. Para error incompatible se reutiliza el código contractual vigente. La regla se comunica como definida; migración, implementación y validación siguen pendientes.

## 5. Contratos publicados

Eventos del AsyncAPI 0.4.0 utilizados por esta capacidad:

```text
taxonomy.product-type-schema.changed
taxonomy.master.deactivation.check.requested
catalog.master.deactivation.checked
taxonomy.master.deactivated
taxonomy.master.deactivation.rejected
```

Rutas administrativas:

```text
GET   /api/v1/tipos-producto
POST  /api/v1/tipos-producto
GET   /api/v1/tipos-producto/{tipoProductoId}

POST  /api/v1/tipos-producto/{tipoProductoId}/desactivar
POST  /api/v1/tipos-producto/{tipoProductoId}/reactivar

GET   /api/v1/tipos-producto/{tipoProductoId}/caracteristicas
POST  /api/v1/tipos-producto/{tipoProductoId}/caracteristicas
PATCH /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}
POST  /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}/desasociar

GET   /api/v1/taxonomia/operaciones/{operationId}
```

`desactivar` y `desasociar` responden `202 Accepted` con `OperationAccepted`: es admisión de la solicitud, nunca el resultado final.
