# FLOW-016 — Dashboard analítico y alertas de stock

---

## 1. Identificación

- **Código:** FLOW-016
- **Funcionalidad:** Dashboard analítico y alertas de stock
- **Relacionado con:** HU-016 / SPEC-016 / WF-016
- **Responsable:** Miguel Ángel Taco Zavala
- **Última actualización:** 2026-09-30

---

## 2. Objetivo del flujo

Representar la carga, agrupación y actualización de las proyecciones del dashboard de solo lectura: cálculo de indicadores por SKU y ubicación, determinación del estado de disponibilidad, generación de alertas y reactividad ante `inventory.stock.changed`, incluyendo la consulta de traslados sin emitir eventos ni modificar saldos.

---

## 3. Actores participantes

- Responsable de inventario
- Sistema de Inventario (autoridad del saldo y flujo WF-015)
- Dashboard (proyección de solo lectura)

---

## 4. Diagramas de flujo

### 4.1 Carga y agrupación de indicadores

```mermaid
flowchart LR
    subgraph DASH["Dashboard"]
        direction TB
        INICIO((Abrir dashboard))
        A1["Consultar proyección vigente por (sku, location_id)"]
        A2["Calcular KPIs: físico, reservado, bloqueado y disponible"]
        A3["Contar SKU disponibles, stock bajo y agotados"]
        A4["Consultar traslados pendientes y con discrepancia"]
        A5["Agrupar por ubicación con on_hand, reserved, blocked y available"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["Presentar tabla de indicadores y distribución por ubicación"]
        FIN(((Fin de la carga)))
    end

    INICIO --> A1
    A1 --> A2
    A2 --> A3
    A3 --> A4
    A4 --> A5
    A5 --> B1
    B1 --> FIN
```

### 4.2 Determinación de estados y alertas

```mermaid
flowchart LR
    subgraph DASH["Dashboard"]
        direction TB
        INICIO((Indicadores cargados))
        D1{"¿available = 0?"}
        D2{"¿available <= umbral_efectivo?"}
        A1["Clasificar AGOTADO"]
        A2["Clasificar STOCK_BAJO"]
        A3["Clasificar DISPONIBLE"]
        A4["Activar alerta para AGOTADO y STOCK_BAJO"]
        A5["Mostrar alertas por ubicación"]
    end

    subgraph RES["Resultado"]
        direction TB
        FIN(((Fin de la alerta)))
    end

    INICIO --> D1
    D1 -->|"Sí"| A1
    D1 -->|"No"| D2
    D2 -->|"Sí"| A2
    D2 -->|"No"| A3
    A3 --> FIN
    A1 --> A4
    A2 --> A4
    A4 --> A5
    A5 --> FIN
```

### 4.3 Reactividad ante inventory.stock.changed

```mermaid
flowchart LR
    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("inventory.stock.changed recibido"))
    end

    subgraph DASH["Dashboard"]
        direction TB
        A1["Validar evento del contrato AsyncAPI"]
        A2["Actualizar la proyección de los saldos afectados"]
        A3["Recalcular KPIs, estados y alertas"]
        D1{"¿La mutación fue una recepción de traslado?"}
        A4["Refrescar KPIs de traslados por consulta"]
        A5["Refrescar vista sin republicar eventos ni mutar saldos"]
    end

    subgraph RES["Resultado"]
        direction TB
        FIN(((Fin de la actualización)))
    end

    E1 --> A1
    A1 --> A2
    A2 --> A3
    A3 --> D1
    D1 -->|"Sí"| A4
    D1 -->|"No"| A5
    A4 --> A5
    A5 --> FIN
```

### 4.4 KPIs de traslados por consulta

```mermaid
flowchart LR
    subgraph DASH["Dashboard"]
        direction TB
        INICIO((Refresco de indicadores de traslados))
        A1["Consultar GET /api/v1/inventario/traslados"]
        A2["Obtener estados EN_TRANSITO, RECIBIDO_PARCIAL y COMPLETADO_CON_DISCREPANCIA"]
        A3["Contar traslados pendientes y con discrepancia"]
        A4["Mostrar conteos y enlace a la recepción de WF-015"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["Conteos actualizados sin ejecutar la recepción"]
        FIN(((Fin de la consulta de traslados)))
    end

    INICIO --> A1
    A1 --> A2
    A2 --> A3
    A3 --> A4
    A4 --> B1
    B1 --> FIN
```

### 4.5 Filtros y caso sin resultados

```mermaid
flowchart LR
    subgraph DASH["Dashboard"]
        direction TB
        INICIO((Dashboard abierto))
        A1["Aplicar filtros de producto, categoría, marca, SKU, ubicación y estado"]
        D1{"¿Existen resultados?"}
        A2["Mostrar tabla, KPIs y alertas filtrados"]
        A3["Mostrar estado vacío"]
    end

    subgraph RES["Resultado"]
        direction TB
        FIN(((Fin de la visualización)))
    end

    INICIO --> A1
    A1 --> D1
    D1 -->|"Sí"| A2
    D1 -->|"No"| A3
    A2 --> FIN
    A3 --> FIN
```

---

## 5. Notas generales

- **Solo lectura:** el dashboard no publica eventos de Inventario ni modifica saldos ni Kardex (HU-016 CA-10, SPEC-016 §4).
- **Traslados:** no existe evento contractual de traslados; los KPIs se obtienen por consulta del estado confirmado y la recepción la ejecuta un operador en WF-015, no desde el dashboard (SPEC-016 §6). Un traslado con discrepancia no altera por sí mismo las unidades disponibles (HU-016 CA-11).
- **Estados:** `available = max(on_hand - reserved - blocked, 0)`; `AGOTADO` cuando `available = 0`, `STOCK_BAJO` cuando `0 < available <= umbral_efectivo` y `DISPONIBLE` en el resto (SPEC-016 §3).
- **Actualización:** la proyección se recalcula ante mutaciones confirmadas de reserva, consumo, liberación, incidencia/bloqueo, rehabilitación, merma, reintegro, conciliación offline y recepción de traslados (SPEC-016 §4, HU-016 CA-07).