# FLOW-011 — Gestión de marcas

## 1. Identificación

- **Código:** FLOW-011
- **Funcionalidad:** Gestión de marcas
- **Relacionado con:** [HU-011](../hu/HU-011-gestion-marcas.md) / [SPEC-011](../specs/SPEC-011-gestion-marcas.md) / [WF-011](../wireframes/flows/WF-011-gestion-marcas.md)
- **Responsable:** Leonardo Lopez
- **Última actualización:** 2026-09-24

---

## 2. Objetivo del flujo

Representar la creación, consulta, actualización, desactivación y reactivación de las marcas del catálogo. El flujo contempla la unicidad global del nombre normalizado (activas e inactivas), las validaciones del logo (PNG, JPG/JPEG o WebP de hasta 5 MB) y del país ISO 3166-1, la baja lógica asíncrona bajo barrera de Catálogo y la exposición de marcas activas a los canales.

---

## 3. Actores participantes

- **Gestor comercial:** crea, consulta, edita, desactiva y reactiva marcas.
- **Taxonomía:** administra las marcas, sus validaciones y la baja lógica.
- **Catálogo Core:** verifica productos activos asociados y responde por `operation_id`.
- **Canales de venta:** consumen el listado de marcas activas para sus filtros.

---

## 4. Diagramas de flujo

### 4.1 Creación de una marca

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Acceso a gestión de marcas))
        G1["Ingresar nombre, descripción y país de origen"]
        G2["Subir logo"]
        G3["Guardar la marca"]
        G4["Corregir logo según el motivo"]
        G5["Corregir el nombre duplicado"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Validar formato y tamaño del logo"]
        D1{"¿El logo es PNG, JPG/JPEG o WebP y de hasta 5 MB?"}
        T2["Normalizar el país contra ISO 3166-1"]
        T3["Normalizar y validar la unicidad del nombre"]
        D2{"¿El nombre no está reservado por otra marca?"}
        T4["Registrar la marca en estado ACTIVO"]
    end

    FIN_CREADA(((Marca creada y activa)))
    FIN_RECHAZADA(((Marca rechazada)))

    INICIO --> G1
    G1 --> G2
    G2 --> T1
    T1 --> D1
    D1 -->|"No"| G4
    G4 --> G2
    D1 -->|"Sí"| T2
    T2 --> T3
    T3 --> D2
    D2 -->|"No"| G5
    G5 --> G1
    D2 -->|"Sí"| G3
    G3 --> T4
    T4 --> FIN_CREADA
```

> El nombre normalizado de la marca es único entre todas las marcas, incluidas las inactivas. La unicidad se protege además con una restricción de base de datos.

### 4.2 Consulta y actualización de una marca

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Abrir una marca existente))
        G1["Seleccionar Editar"]
        G2["Modificar nombre, descripción, logo o país"]
        G3["Guardar cambios"]
        G4["Corregir datos inválidos"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Cargar los datos de la marca"]
        T2["Revalidar unicidad del nombre, logo y país"]
        D1{"¿Los datos modificados son válidos?"}
        T3["Actualizar la marca y su updated_at"]
        T4["Publicar evento de actualización"]
    end

    FIN_ACTUALIZADA(((Marca actualizada)))

    INICIO --> G1
    G1 --> T1
    T1 --> G2
    G2 --> T2
    T2 --> D1
    D1 -->|"No"| G4
    G4 --> G2
    D1 -->|"Sí"| G3
    G3 --> T3
    T3 --> T4
    T4 --> FIN_ACTUALIZADA
```

### 4.3 Baja lógica con verificación asíncrona de Catálogo

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Solicitar desactivación))
        G1["Confirmar la desactivación"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Registrar PENDING_DEACTIVATION y publicar solicitud"]
        D2{"¿Resultado CLEAR vigente?"}
        T2["Cambiar el estado a INACTIVO"]
        T3["Mantener la marca activa y registrar rechazo"]
        T4["Conservar estado pendiente recuperable"]
    end

    subgraph CATALOGO["Catálogo Core"]
        direction TB
        C1["Instalar barrera de escritura"]
        C2["Revisar productos activos asociados"]
        C3["Publicar resultado con operation_id"]
        C4["Liberar barrera de escritura"]
    end

    FIN_DESACTIVADA(((Marca desactivada)))
    FIN_BLOQUEADA(((Baja bloqueada por productos activos)))
    FIN_PENDIENTE(((Baja no confirmada)))

    INICIO --> G1
    G1 --> T1
    T1 --> C1
    C1 --> C2
    C2 --> C3
    C3 --> D2
    D2 -->|"CLEAR"| T2
    T2 --> C4
    C4 --> FIN_DESACTIVADA
    D2 -->|"HAS_ACTIVE_PRODUCTS"| T3
    T3 --> C4
    C4 --> FIN_BLOQUEADA
    T1 --> E1(("Time out o error en la comprobación"))
    E1 --> T4
    T4 --> FIN_PENDIENTE
```

> La desactivación solo concluye tras una confirmación asíncrona `CLEAR` bajo barrera concurrente; un rechazo o la falta de respuesta no desactiva la marca. El nombre y el ID se conservan para una posible reactivación.

### 4.4 Reactivación de una marca

```mermaid
flowchart LR

    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Solicitar reactivación))
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Reactivar conservando el ID y el nombre"]
        T2["Publicar evento de estado"]
    end

    subgraph CANALES["Canales de venta"]
        direction TB
        C1["Volver a mostrar la marca en los filtros"]
    end

    FIN_REACTIVADA(((Marca reactivada)))

    INICIO --> T1
    T1 --> T2
    T2 --> C1
    C1 --> FIN_REACTIVADA
```

### 4.5 Consulta de marcas activas

```mermaid
flowchart LR

    subgraph CONSUMIDOR["Catálogo Core o canal de venta"]
        direction TB
        INICIO((Consulta de marcas para filtros))
        G1["Invocar endpoint de solo lectura"]
    end

    subgraph TAXONOMIA["Taxonomía"]
        direction TB
        T1["Devolver únicamente marcas en estado ACTIVO"]
    end

    FIN_LISTADO(((Listado de marcas activas)))

    INICIO --> G1
    G1 --> T1
    T1 --> FIN_LISTADO
```