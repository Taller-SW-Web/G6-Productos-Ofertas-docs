# FLOW-009 — Gestión de características y sus valores

## 1. Identificación

- **Código:** FLOW-009
- **Funcionalidad:** Gestión de características y sus valores
- **Relacionado con:** [HU-009](../hu/HU-009-gestion-caracteristicas.md) / [SPEC-009](../specs/SPEC-009-gestion-caracteristicas.md) / [WF-009](../wireframes/flows/WF-009-gestion-caracteristicas.md)
- **Responsable:** Leonardo Lopez
- **Última actualización:** 2026-10-01

---

## 2. Objetivo del flujo

Representar la creación de características tipadas (`TEXTO`, `NUMERO`, `LISTA`), la gestión de valores de tipo `LISTA` (agregar, renombrar por ID y baja lógica), la desactivación lógica y la reactivación de una característica completa conservando su ID, y la protección del tipo inmutable. El flujo contempla los límites operativos configurables (`MAX_TEXT_ATTRIBUTE_LENGTH = 100` y `MAX_ACTIVE_LIST_VALUES = 50`), la propagación del renombrado mediante `taxonomy.characteristic-value.updated` y la verificación asíncrona con Catálogo, mediante el protocolo transversal publicado, antes de dar de baja un valor en uso.

---

## 3. Actores participantes

- **Gestor comercial:** crea, consulta, renombra, desactiva y reactiva características y sus valores.
- **Taxonomía:** administra características tipadas, valores, sus límites operativos y su estado lógico.
- **Catálogo Core:** verifica el uso de un valor en SKUs o productos activos y confirma la baja segura.
- **Asociación Tipo de Producto–Característica (FLOW-010):** solo ofrece características activas para nuevas asociaciones.

---

## 4. Diagramas de flujo

### 4.1 Creación de una característica tipada

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Acceso a gestión de características))
        G1["Seleccionar crear característica"]
        G2["Ingresar nombre"]
        G3["Seleccionar tipo TEXTO, NUMERO o LISTA"]
        G4["Indicar unidad de medida"]
        G5["Guardar característica"]
        G6["Corregir los datos ingresados"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Listar características con ID, tipo y estado"]
        D1{"¿El tipo es NUMERO?"}
        T2["Validar límites según el tipo"]
        D2{"¿Los datos cumplen las reglas configuradas?"}
        T3["Registrar la característica con tipo inmutable"]
    end

    FIN_CREADA(((Característica creada)))
    FIN_RECHAZADA(((Característica rechazada)))

    INICIO --> T1
    T1 --> G1
    G1 --> G2
    G2 --> G3
    G3 --> D1
    D1 -->|"Sí"| G4
    G4 --> T2
    D1 -->|"No"| T2
    T2 --> D2
    D2 -->|"No"| G6
    G6 --> G2
    D2 -->|"Sí"| T3
    T3 --> FIN_CREADA
```

> El tipo de una característica es inmutable desde su creación; intentar cambiarlo se rechaza y se indica crear otra característica con un ID distinto.

### 4.2 Gestión de valores de tipo LISTA

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Acceso a una característica LISTA))
        D1{"¿Qué operación realizar?"}
        G1["Ingresar etiqueta del nuevo valor"]
        G2["Ingresar el nuevo nombre del valor"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Validar MAX_ACTIVE_LIST_VALUES vigente"]
        D2{"¿Se supera el límite de valores activos?"}
        T2["Crear el valor con ID estable"]
        T3["Renombrar conservando el ID"]
        T4["Publicar taxonomy.characteristic-value.updated con change_type=RENAMED"]
    end

    FIN_LIMITE(((Agregado rechazado por límite)))
    FIN_AGREGADO(((Valor agregado)))
    FIN_RENOMBRADO(((Valor renombrado por ID)))

    INICIO --> D1
    D1 -->|"Agregar valor"| G1
    G1 --> T1
    T1 --> D2
    D2 -->|"Sí"| FIN_LIMITE
    D2 -->|"No"| T2
    T2 --> FIN_AGREGADO
    D1 -->|"Renombrar valor"| G2
    G2 --> T3
    T3 --> T4
    T4 --> FIN_RENOMBRADO
```

> Renombrar un valor conserva su ID y la actualización de las vistas de Catálogo es por eventos. El renombrado confirmado de un valor `LISTA` publica explícitamente `taxonomy.characteristic-value.updated`; no se reescriben SKUs existentes ni snapshots de pedidos.

### 4.3 Baja segura de un valor LISTA

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Solicitar baja de un valor LISTA))
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Mantener la solicitud pendiente y el valor no seleccionable"]
        T2["Publicar taxonomy.master.deactivation.check.requested e instalar barrera de escritura"]
        DS1{"¿Resultado CLEAR vigente?"}
        T3["Confirmar la baja lógica conservando ID e histórico y publicar taxonomy.master.deactivated"]
        T4["Publicar taxonomy.master.deactivation.rejected, levantar la barrera y rechazar la baja"]
        T5["Restaurar el estado anterior ante falta de confirmación"]
    end

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        C1["Verificar uso del valor en SKU ACTIVO o producto ACTIVO"]
        C2["Publicar catalog.master.deactivation.checked correlacionado"]
    end

    FIN_CONFIRMADA(((Baja lógica confirmada)))
    FIN_RECHAZADA(((Baja rechazada)))

    INICIO --> T1
    T1 --> T2
    T2 --> C1
    C1 --> C2
    C2 --> DS1
    DS1 -->|"CLEAR"| T3
    T3 --> FIN_CONFIRMADA
    DS1 -->|"HAS_ACTIVE_PRODUCTS"| T4
    T4 --> FIN_RECHAZADA
    T2 --> E1(("Time out o error en la verificación"))
    E1 --> T5
    T5 --> FIN_RECHAZADA
```

> La baja de un valor `LISTA` usa únicamente el protocolo transversal publicado para la entidad maestra `CHARACTERISTIC_VALUE`: `taxonomy.master.deactivation.check.requested` → `catalog.master.deactivation.checked` → `taxonomy.master.deactivated` o `taxonomy.master.deactivation.rejected`. El `202 Accepted` de `POST /api/v1/caracteristicas/{caracteristicaId}/valores/{valorId}/desactivar` es solo admisión de la solicitud, no una baja completada; el estado pendiente se consulta con `GET /api/v1/taxonomia/operaciones/{operationId}`. Durante la comprobación no se asigna el valor a nuevos productos o variantes. Un fallo o la ausencia de respuesta no autoriza la baja; los productos inactivos y pedidos históricos conservan sus referencias y snapshots.

### 4.4 Desactivación lógica y reactivación de una característica

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Abrir una característica existente))
        D1{"¿Está ACTIVA?"}
        G1["Solicitar desactivación lógica"]
        G2["Solicitar reactivación"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Cambiar el estado a INACTIVO conservando ID, tipo y valores"]
        T2["Volver a ACTIVO conservando ID, tipo y valores"]
        T3["Excluir la característica de la oferta para nuevas asociaciones"]
        T4["Admitirla de nuevo para nuevas asociaciones"]
    end

    subgraph ASOCIACION["Asociación Tipo de Producto–Característica"]
        direction TB
        A1["El selector solo ofrece características activas"]
        A2["Las asociaciones históricas se conservan sin modificación"]
    end

    FIN_INACTIVA(((Característica inactiva con el mismo ID)))
    FIN_ACTIVA(((Característica reactivada con el mismo ID)))

    INICIO --> D1
    D1 -->|"Sí"| G1
    G1 --> T1
    T1 --> T3
    T3 --> A1
    A1 --> FIN_INACTIVA
    D1 -->|"No"| G2
    G2 --> T2
    T2 --> T4
    T4 --> A2
    A2 --> FIN_ACTIVA
```

> La desactivación de una característica completa es lógica: nunca se borra y su ID se conserva, por lo que la reactivación recupera exactamente la misma identidad junto con su tipo y sus valores. Una característica inactiva no se ofrece para nuevas asociaciones en FLOW-010, pero las asociaciones ya existentes y su histórico permanecen vigentes.
