# FLOW-008 — Gestión de categorías y subcategorías

## 1. Identificación

- **Código:** FLOW-008
- **Funcionalidad:** Gestión de categorías y subcategorías
- **Relacionado con:** [HU-008](../hu/HU-008-gestion-categorias.md) / [SPEC-008](../specs/SPEC-008-gestion-categorias.md) / [WF-008](../wireframes/flows/WF-008-gestion-categorias.md)
- **Responsable:** Leonardo Lopez
- **Última actualización:** 2026-09-24

---

## 2. Objetivo del flujo

Representar la consulta del árbol jerárquico, la creación de categorías raíz y subcategorías, la edición con reasignación de padre y la baja lógica asíncrona con confirmación de Catálogo. El flujo incluye la validación de profundidad máxima (`MAX_CATEGORY_DEPTH = 2`), la ausencia de ciclos, la confirmación del slug generado por la capacidad SEO antes de publicar y la reactivación condicionada al estado del padre.

---

## 3. Actores participantes

- **Gestor comercial:** consulta el árbol, crea, edita, desactiva y reactiva categorías.
- **Capacidad SEO:** normaliza y genera el slug final ante colisiones.
- **Taxonomía:** administra la jerarquía y ejecuta la baja lógica bajo verificación asíncrona.
- **Catálogo Core:** verifica productos activos, instala la barrera de escritura y responde por `operation_id`.

---

## 4. Diagramas de flujo

### 4.1 Consulta y creación de categoría raíz o subcategoría

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Acceso a gestión de categorías))
        G1["Consultar árbol jerárquico"]
        D1{"¿Qué categoría desea crear?"}
        G2["Ingresar nombre, descripción, imagen y orden"]
        G3["Seleccionar categoría padre"]
        G4["Confirmar slug final mostrado"]
        G5["Corregir datos de la categoría"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Listar árbol completo con estados"]
        T2["Validar padre activo y profundidad MAX_CATEGORY_DEPTH=2"]
        D2{"¿El padre es válido y no excede dos niveles?"}
        T3["Solicitar slug normalizado a la capacidad SEO"]
        T4["Crear categoría y publicar el cambio"]
    end

    subgraph SEO["Capacidad SEO"]
        direction TB
        S1["Generar slug normalizado"]
        D3{"¿El slug colisiona con uno existente?"}
        S2["Proponer sufijo numérico incremental"]
        S3["Devolver slug final visible"]
    end

    FIN_CREADA(((Categoría creada y publicada)))
    FIN_CANCELADA(((Creación cancelada)))

    INICIO --> G1
    G1 --> T1
    T1 --> D1
    D1 -->|"Crear raíz"| G2
    D1 -->|"Añadir subcategoría"| G3
    G3 --> G2
    G2 --> T2
    T2 --> D2
    D2 -->|"No"| G5
    G5 --> G2
    D2 -->|"Sí"| T3
    T3 --> S1
    S1 --> D3
    D3 -->|"Sí"| S2
    S2 --> S3
    D3 -->|"No"| S3
    S3 --> G4
    G4 --> D4{"¿El gestor confirma el slug final?"}
    D4 -->|"No"| FIN_CANCELADA
    D4 -->|"Sí"| T4
    T4 --> FIN_CREADA
```

> El slug final autogenerado siempre se muestra antes de confirmar; no se permite un cambio silencioso de URL. La edición posterior del slug y los metadatos pertenece a la capacidad SEO (WF-012).

### 4.2 Edición y reasignación de categoría padre

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Abrir categoría existente))
        G1["Seleccionar Editar"]
        G2["Modificar nombre, descripción, imagen, orden y categoría padre"]
        G3["Guardar cambios"]
        G4["Corregir la nueva ubicación"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Cargar campos incluido categoria_padre_id"]
        T2["Revalidar padre activo, ausencia de ciclo y MAX_CATEGORY_DEPTH"]
        D1{"¿La nueva ubicación es válida?"}
        T3["Confirmar el cambio atómico con versión"]
        T4["Publicar taxonomy.category.updated"]
    end

    FIN_REUBICADA(((Categoría reubicada sin afectar productos)))

    INICIO --> G1
    G1 --> T1
    T1 --> G2
    G2 --> T2
    T2 --> D1
    D1 -->|"No"| G4
    G4 --> G2
    D1 -->|"Sí"| T3
    T3 --> T4
    T4 --> FIN_REUBICADA
```

> Reubicar una categoría no recalcula el esquema de atributos de los productos: el esquema se resuelve por `tipo_producto_id`, no por la jerarquía de navegación.

### 4.3 Baja lógica con verificación asíncrona de Catálogo

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Solicitar desactivación))
        G1["Confirmar desactivación"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Comprobar subcategorías activas"]
        D1{"¿Tiene subcategorías activas?"}
        T2["Registrar PENDING_DEACTIVATION y publicar solicitud"]
        D2{"¿Resultado CLEAR vigente?"}
        T3["Confirmar la baja lógica"]
        T4["Rechazar la baja y mantener la categoría activa"]
        T5["Conservar estado pendiente recuperable"]
    end

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        C1["Instalar barrera de escritura"]
        C2["Revisar productos activos asociados"]
        C3["Publicar resultado con operation_id"]
        C4["Liberar barrera de escritura"]
    end

    FIN_DESACTIVADA(((Categoría desactivada)))
    FIN_BLOQUEADA(((Baja bloqueada por productos activos)))
    FIN_PENDIENTE(((Baja no confirmada)))

    INICIO --> T1
    T1 --> D1
    D1 -->|"Sí"| T4
    T4 --> FIN_BLOQUEADA
    D1 -->|"No"| G1
    G1 --> T2
    T2 --> C1
    C1 --> C2
    C2 --> C3
    C3 --> D2
    D2 -->|"CLEAR"| T3
    T3 --> C4
    C4 --> FIN_DESACTIVADA
    D2 -->|"HAS_ACTIVE_PRODUCTS"| T4
    T4 --> C4
    C4 --> FIN_BLOQUEADA
    T2 --> E1(("Time out o error en la comprobación"))
    E1 --> T5
    T5 --> FIN_PENDIENTE
```

> La desactivación es una operación asíncrona de dos fases: Taxonomía solo confirma la baja lógica ante un resultado `CLEAR` vigente. Un timeout, error o verificación pendiente nunca autoriza la baja.

### 4.4 Reactivación de una categoría

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Solicitar reactivación))
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Validar estado de la categoría padre"]
        D1{"¿No tiene padre o su padre está activo?"}
        T2["Reactivar la categoría y publicar el cambio"]
        T3["Registrar bloqueo por padre inactivo"]
    end

    FIN_REACTIVADA(((Categoría reactivada)))
    FIN_BLOQUEADA(((Reactivación bloqueada)))

    INICIO --> T1
    T1 --> D1
    D1 -->|"Sí"| T2
    T2 --> FIN_REACTIVADA
    D1 -->|"No"| T3
    T3 --> FIN_BLOQUEADA
```