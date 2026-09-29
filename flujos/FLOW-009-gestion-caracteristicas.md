# FLOW-009 — Gestión de características y sus valores

## 1. Identificación

- **Código:** FLOW-009
- **Funcionalidad:** Gestión de características y sus valores
- **Relacionado con:** [HU-009](../hu/HU-009-gestion-caracteristicas.md) / [SPEC-009](../specs/SPEC-009-gestion-caracteristicas.md) / [WF-009](../wireframes/flows/WF-009-gestion-caracteristicas.md)
- **Responsable:** Leonardo Lopez
- **Última actualización:** 2026-09-24

---

## 2. Objetivo del flujo

Representar la creación de características tipadas (`TEXTO`, `NUMERO`, `LISTA`), la gestión de valores de tipo `LISTA` (agregar, renombrar por ID y baja lógica) y la protección del tipo inmutable. El flujo contempla los límites operativos configurables (`MAX_TEXT_ATTRIBUTE_LENGTH = 100` y `MAX_ACTIVE_LIST_VALUES = 50`) y la verificación asíncrona con Catálogo antes de dar de baja un valor en uso.

---

## 3. Actores participantes

- **Gestor comercial:** crea, consulta, renombra y da de baja características y sus valores.
- **Taxonomía:** administra características tipadas, valores y sus límites operativos.
- **Catálogo Core:** verifica el uso de un valor en SKUs o productos activos y confirma la baja segura.

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
        T4["Publicar evento versionado para proyecciones de Catálogo"]
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

> Renombrar un valor conserva su ID y la actualización de las vistas de Catálogo es por eventos; no se reescriben SKUs existentes ni snapshots de pedidos.

### 4.3 Baja lógica de un valor LISTA

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Solicitar baja de un valor LISTA))
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Mantener la solicitud pendiente y el valor no seleccionable"]
        T2["Instalar barrera de escritura"]
        D2{"¿Resultado CLEAR vigente?"}
        T3["Confirmar la baja lógica conservando ID e histórico"]
        T4["Levantar la barrera y rechazar la baja"]
        T5["Restaurar el estado anterior ante falta de confirmación"]
    end

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        C1["Verificar uso del valor en SKU ACTIVO o producto ACTIVO"]
        C2["Publicar resultado correlacionado"]
    end

    FIN_CONFIRMADA(((Baja lógica confirmada)))
    FIN_RECHAZADA(((Baja rechazada)))

    INICIO --> T1
    T1 --> T2
    T2 --> C1
    C1 --> C2
    C2 --> D2
    D2 -->|"CLEAR"| T3
    T3 --> FIN_CONFIRMADA
    D2 -->|"HAS_ACTIVE_PRODUCTS"| T4
    T4 --> FIN_RECHAZADA
    T2 --> E1(("Time out o error en la verificación"))
    E1 --> T5
    T5 --> FIN_RECHAZADA
```

> Durante la comprobación no se asigna el valor a nuevos productos o variantes. Un fallo o la ausencia de respuesta no autoriza la baja; los productos inactivos y pedidos históricos conservan sus referencias y snapshots.