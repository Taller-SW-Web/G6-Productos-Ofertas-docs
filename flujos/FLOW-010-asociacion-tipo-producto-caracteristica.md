# FLOW-010 — Asociación entre tipos de producto y características

## 1. Identificación

- **Código:** FLOW-010
- **Funcionalidad:** Asociación entre tipos de producto y características
- **Relacionado con:** [HU-010](../hu/HU-010-asociacion-tipo-producto-caracteristica.md) / [SPEC-010](../specs/SPEC-010-asociacion-tipo-producto-caracteristica.md) / [WF-010](../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md)
- **Responsable:** Leonardo Lopez
- **Última actualización:** 2026-09-24

---

## 2. Objetivo del flujo

Representar la gestión de tipos de producto ligeros y su asociación con características activas, indicando obligatoriedad y respetando el límite configurable (`MAX_PRODUCT_TYPE_ATTRIBUTES = 20`). El flujo contempla la consulta del esquema efectivo, el cambio de obligatoriedad sin invalidar productos preexistentes y la desasociación segura con verificación asíncrona cuando la característica es obligatoria o identificadora.

---

## 3. Actores participantes

- **Gestor comercial:** crea tipos de producto y administra las asociaciones.
- **Taxonomía:** mantiene el esquema de asociación, su versión y el límite configurable.
- **Catálogo Core:** consulta el esquema efectivo y verifica el uso de una característica antes de desasociarla.

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
        T1["Listar tipos con contador X / MAX_PRODUCT_TYPE_ATTRIBUTES"]
        T2["Crear tipo de producto ligero con tipo_producto_id"]
        T3["Mostrar esquema efectivo con obligatoriedad"]
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
        T1["Validar característica activa y no asociada"]
        D1{"¿Ya está asociada o se supera el límite configurado?"}
        T2["Registrar la asociación e incrementar la versión del esquema"]
        T3["Publicar evento versionado"]
    end

    FIN_ASOCIADA(((Característica asociada)))
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

> Las categorías de navegación no definen ni heredan características: el esquema de atributos se resuelve únicamente a través de `tipo_producto_id`.

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
        T1["Guardar el cambio e incrementar la versión"]
        D1{"¿La característica pasó a obligatoria?"}
        T2["No invalidar productos existentes; exigir en la próxima edición"]
        T3["Mantener la regla vigente para nuevas escrituras"]
    end

    FIN_ACTUALIZADO(((Esquema actualizado)))

    INICIO --> G1
    G1 --> G2
    G2 --> T1
    T1 --> D1
    D1 -->|"Sí"| T2
    T2 --> FIN_ACTUALIZADO
    D1 -->|"No"| T3
    T3 --> FIN_ACTUALIZADO
```

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
        T2["Remover la asociación y conservar el histórico"]
        T3["Registrar baja a la espera del resultado"]
        D2{"¿Resultado CLEAR vigente?"}
    end

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        C1["Verificar uso en variantes activas"]
        C2["Publicar resultado correlacionado"]
    end

    FIN_REMOVIDA(((Asociación removida)))
    FIN_BLOQUEADA(((Desasociación rechazada)))

    INICIO --> G1
    G1 --> T1
    T1 --> D1
    D1 -->|"No"| T2
    T2 --> FIN_REMOVIDA
    D1 -->|"Sí"| T3
    T3 --> C1
    C1 --> C2
    C2 --> D2
    D2 -->|"CLEAR"| T2
    T2 --> FIN_REMOVIDA
    D2 -->|"No"| FIN_BLOQUEADA
    T3 --> E1(("Time out o error en la verificación"))
    E1 --> FIN_BLOQUEADA
```

### 4.5 Consulta del esquema por tipo de producto

```mermaid
flowchart LR

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        INICIO((Solicitud de esquema por tipo de producto))
        G1["Invocar API de solo lectura"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Devolver características activas con obligatoriedad y versión"]
        D1{"¿Existen asociaciones?"}
        T2["Devolver lista vacía sin error"]
    end

    FIN_ESQUEMA(((Esquema efectivo entregado)))

    INICIO --> G1
    G1 --> T1
    T1 --> D1
    D1 -->|"Sí"| FIN_ESQUEMA
    D1 -->|"No"| T2
    T2 --> FIN_ESQUEMA
```