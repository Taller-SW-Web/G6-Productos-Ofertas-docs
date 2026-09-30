# FLOW-016 — Dashboard analítico y alertas de stock

## 1. Identificación

- **Código:** FLOW-016
- **Funcionalidad:** Dashboard analítico y alertas de stock
- **Relacionado con:** [HU-016](../hu/HU-016-dashboard-alertas-stock.md) / [SPEC-016](../specs/SPEC-016-dashboard-alertas-stock.md) / [WF-016](../wireframes/flows/WF-016-dashboard-alertas-stock.md)
- **Responsable:** Miguel Ángel Taco Zavala
- **Última actualización:** 2026-09-30

---

## 2. Objetivo del flujo

Representar el flujo 100 % de lectura del dashboard analítico y alertas de stock: la carga de indicadores a nivel de SKU vendible, la determinación determinista de estados y alertas con el umbral efectivo, la aplicación de filtros, la reactividad ante `inventory.stock.changed` y la distribución operativa por ubicación. El dashboard no ajusta, reserva ni consume stock, no publica `inventory.stock.changed` y no calcula métricas comerciales (ventas, rankings o Top de productos), cuyo dueño es Ventas/Postventa.

---

## 3. Actores participantes

- **Responsable de inventario:** consulta el dashboard, aplica filtros y visualiza indicadores/alertas.
- **Sistema de Inventario (WF-015):** provee los saldos y emite `inventory.stock.changed` tras cada mutación.
- **Dashboard (vista de proyección):** consume datos autoritativos/proyectados de Inventario; no genera mutaciones.

---

## 4. Diagramas de flujo

### 4.1 Carga de indicadores por SKU vendible

```mermaid
flowchart LR

    subgraph RESPONSABLE["Responsable de inventario"]
        direction TB
        INICIO((Acceso al dashboard de inventario))
        R1["Abrir dashboard de inventario"]
        R2["Visualizar tarjetas de indicadores"]
    end

    subgraph DASHBOARD["Dashboard (proyección)"]
        direction TB
        I1["Calcular indicadores a nivel de SKU vendible por (sku, location_id)"]
        I2["Contar SKUs disponibles, con stock bajo y agotados"]
        I3["Sumar unidades disponibles (available) y total de SKUs vendibles"]
        I4["Preparar agrupación comercial por producto (solo vista, sin saldo propio)"]
    end

    FIN_OK(((Indicadores cargados)))

    INICIO --> R1
    R1 --> I1
    I1 --> I2
    I2 --> I3
    I3 --> I4
    I4 --> R2
    R2 --> FIN_OK
```

---

### 4.2 Determinación determinista de estados y alertas

```mermaid
flowchart LR

    subgraph DASHBOARD["Dashboard (proyección)"]
        direction TB
        INICIO((Recalcular estados y alertas))
        E1["Obtener available y umbral_efectivo (override SKU ?? umbral_global) por SKU/ubicación"]
        D1{"¿available = 0?"}
        E2["Marcar AGOTADO y generar alerta"]
        D2{"¿0 < available <= umbral_efectivo?"}
        E3["Marcar STOCK_BAJO y generar alerta"]
        E4["Marcar DISPONIBLE (sin alerta)"]
    end

    FIN_AGOTADO(((Variante AGOTADA en alerta)))
    FIN_BAJO(((Variante en STOCK_BAJO / alerta)))
    FIN_DISPONIBLE(((Variante DISPONIBLE sin alerta)))

    INICIO --> E1
    E1 --> D1
    D1 -->|"Sí"| E2
    E2 --> FIN_AGOTADO
    D1 -->|"No"| D2
    D2 -->|"Sí"| E3
    E3 --> FIN_BAJO
    D2 -->|"No"| E4
    E4 --> FIN_DISPONIBLE
```

> Los estados siguen las reglas deterministas de la gestión de inventario: `available = 0 → AGOTADO`; `0 < available <= umbral_efectivo → STOCK_BAJO`; de lo contrario `DISPONIBLE`.

---

### 4.3 Filtros y caso sin resultados

```mermaid
flowchart LR

    subgraph RESPONSABLE["Responsable de inventario"]
        direction TB
        INICIO((Consulta del dashboard))
        R1["Aplicar filtros: producto, categoría, marca, SKU, ubicación y estado"]
        R2["Visualizar panel filtrado"]
        R3["Limpiar filtros o ajustar criterios"]
    end

    subgraph DASHBOARD["Dashboard (proyección)"]
        direction TB
        I1["Filtrar la proyección según los criterios"]
        D1{"¿Existen resultados para los filtros?"}
        I2["Recalcular indicadores, alertas y distribución con los filtros"]
        I3["Mostrar estado sin resultados con opción de limpiar filtros"]
    end

    FIN_OK(((Panel filtrado)))
    FIN_SIN_RESULTADOS(((Sin resultados)))

    INICIO --> R1
    R1 --> I1
    I1 --> D1
    D1 -->|"Sí"| I2
    I2 --> R2
    R2 --> FIN_OK
    D1 -->|"No"| I3
    I3 --> R3
    R3 --> FIN_SIN_RESULTADOS
```

---

### 4.4 Reactividad ante inventory.stock.changed

```mermaid
flowchart LR

    subgraph INVENTARIO["Sistema de Inventario (WF-015)"]
        direction TB
        EVENTO(("inventory.stock.changed posterior al commit de una mutación"))
    end

    subgraph DASHBOARD["Dashboard (proyección)"]
        direction TB
        L1["Consumir inventory.stock.changed"]
        L2["Recalcular indicadores y alertas con el saldo y estado vigentes"]
        L3["Actualizar la distribución operativa por ubicación"]
        L4["Reflejar transición de estado (Disponible a Stock bajo, o Stock bajo a Agotado)"]
    end

    FIN_OK(((Dashboard actualizado)))

    EVENTO --> L1
    L1 --> L2
    L2 --> L3
    L3 --> L4
    L4 --> FIN_OK
```

> El dashboard es estrictamente de lectura: consume el evento y **no lo publica**, y tampoco ajusta, reserva ni consume stock. No aplica actualización optimista; refleja solo estados confirmados.

---

### 4.5 Distribución operativa del stock por ubicación

```mermaid
flowchart LR

    subgraph RESPONSABLE["Responsable de inventario"]
        direction TB
        INICIO((Consultar distribución operativa))
        R1["Seleccionar location_id cuando existan varias ubicaciones"]
    end

    subgraph DASHBOARD["Dashboard (proyección)"]
        direction TB
        I1["Agregar on_hand, reserved y available por location_id"]
        I2["Contar SKUs disponibles, con stock bajo y agotados por ubicación"]
        D1{"¿Existe más de una ubicación habilitada?"}
        I3["Mostrar tabla de distribución por location_id"]
        I4["Mostrar una vista única con la ubicación DEFAULT"]
    end

    FIN_MULTI(((Distribución por ubicaciones)))
    FIN_DEFAULT(((Vista única DEFAULT)))

    INICIO --> R1
    R1 --> I1
    I1 --> I2
    I2 --> D1
    D1 -->|"Sí"| I3
    I3 --> FIN_MULTI
    D1 -->|"No"| I4
    I4 --> FIN_DEFAULT
```

> Si el MVP opera con una única ubicación `DEFAULT`, la sección muestra un único resumen y no fuerza a seleccionar ubicaciones inexistentes. Este flujo no calcula Top de productos vendidos, ventas por canal ni otros indicadores comerciales de Ventas/Postventa.

---

## 5. Delimitaciones operativas del flujo

- Unidad primaria de inventario: **SKU vendible**; el producto es solo un agrupador comercial sin saldo propio.
- Indicadores mínimos: total de SKUs vendibles, total de unidades disponibles (`available`) y cantidad de SKUs por estado (Disponible, Stock bajo, Agotado).
- Filtros permitidos: producto, categoría, marca, SKU, ubicación (`location_id`) y estado.
- Sin rankings de ventas ni métricas comerciales; sin exportaciones de alertas en el alcance del MVP (WF-016 Q-02).