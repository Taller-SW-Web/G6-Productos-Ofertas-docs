> **Transición H4→H5:** `inventory.stock.changed` y sus reglas de negocio son funcionales; su transporte se desacopla. El diagrama de reactividad H5 usa Azure Service Bus Basic interno G6, adoptado pero sin implementación/provisión acreditadas. RabbitMQ se conserva solo en el antecedente H4 de §4.4.

# FLOW-016 — Dashboard analítico y alertas de stock

---

## 1. Identificación

- **Código:** FLOW-016
- **Funcionalidad:** Dashboard analítico y alertas de stock
- **Relacionado con:** HU-016 / SPEC-016 / WF-016 / ADR-H5-SERVICE-BUS-BASIC
- **Responsable:** Miguel Ángel Taco Zavala
- **Última actualización:** 2026-10-02

---

## 2. Objetivo del flujo

Representar la carga, agrupación y actualización de las proyecciones del dashboard de solo lectura: cálculo de indicadores por SKU y ubicación, determinación del estado de disponibilidad, generación de alertas y reactividad ante `inventory.stock.changed`, incluyendo la consulta de traslados sin emitir eventos ni modificar saldos.

---

## 3. Actores participantes

- Gestor comercial con capacidades de consulta de inventario
- Sistema de Inventario (inventory-svc): autoridad del saldo, productor de `inventory.stock.changed` y owner del dominio de Inventario y del dashboard operativo
- Mensajería interna G6 para el evento funcional (transporte objetivo H5: Azure Service Bus Basic; pendiente de implementación)
- api-gateway/bff: consumidor técnico de `inventory.stock.changed`
- Dashboard UI: interfaz de consulta/refresco sobre proyección de solo lectura

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

### 4.3 Reactividad H5 ante inventory.stock.changed

```mermaid
flowchart LR
    subgraph INV["Sistema de Inventario (inventory-svc)"]
        direction TB
        A0["Mutación autoritativa de saldo confirmada tras el commit"]
        A1["Productor: publicar inventory.stock.changed"]
    end

    subgraph BUS["Azure Service Bus Basic (H5; objetivo adoptado, no aprovisionado) — interno G6"]
        direction TB
        E1(("inventory.stock.changed"))
    end

    subgraph PROJ["Consumidor/proyección interna G6 (owner y handler por verificar)"]
        direction TB
        A2["Recibir y validar el evento funcional según contrato aplicable"]
        A3["Actualizar read model / proyección sin trasladar reglas de negocio de saldo"]
    end

    subgraph DASH["Dashboard UI (interfaz de consulta/refresco)"]
        direction TB
        A4["Consultar la proyección de los saldos afectados"]
        A5["Recalcular KPIs, estados y alertas"]
        D1{"¿La mutación fue una recepción de traslado?"}
        A6["Refrescar KPIs de traslados por consulta GET /api/v1/inventario/traslados"]
        A7["Refrescar vista sin republicar eventos ni mutar saldos"]
    end

    subgraph RES["Resultado"]
        direction TB
        FIN(((Fin de la actualización)))
    end

    A0 --> A1
    A1 --> E1
    E1 --> A2
    A2 --> A3
    A3 --> A4
    A4 --> A5
    A5 --> D1
    D1 -->|"Sí"| A6
    D1 -->|"No"| A7
    A6 --> A7
    A7 --> FIN
```

### 4.4 Antecedente H4 — reactividad con RabbitMQ (no es el objetivo H5)

El esquema siguiente conserva el transporte documentado por AsyncAPI/topología 0.4.0 en H4. Sus bindings y broker no autorizan el diseño H5.

```mermaid
flowchart LR
    inv["inventory-svc: evento inventory.stock.changed"] --> rmq[("RabbitMQ H4 — legado")]
    rmq --> bff["api-gateway/bff H4: consumidor técnico"]
    bff --> proj["read model / proyección"]
    proj --> ui["Dashboard UI: consulta/refresco"]
```

### 4.5 KPIs de traslados por consulta

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

### 4.6 Filtros y caso sin resultados

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
- **Reactividad H5:** `inventory.stock.changed` es el evento funcional de actualización (SPEC-016 §4, HU-016 CA-07), independiente del broker. El objetivo interno G6 lo transporta por Azure Service Bus Basic hasta un consumidor de proyección cuyo owner/handler debe verificarse; no se atribuye ese rol a Gateway por el AsyncAPI H4. La UI consulta/refresca la proyección y no consume el broker (HU-016 CA-10). Implementación y aprovisionamiento siguen pendientes.
- **Triggers funcionales:** solo `inventory.stock.changed` acciona la actualización del dashboard; `inventory.stock.adjusted` no es trigger funcional de FLOW-016 aunque el BFF también lo consuma (SPEC-016/HU-016).
- **Traslados:** no existe evento contractual de traslados; los KPIs se obtienen por consulta `GET /api/v1/inventario/traslados` y la recepción la ejecuta un gestor comercial autorizado en WF-015, no desde el dashboard (SPEC-016 §6). Un traslado con discrepancia no altera por sí mismo las unidades disponibles (HU-016 CA-11).
- **Estados:** `available = max(on_hand - reserved - blocked, 0)`; `AGOTADO` cuando `available = 0`, `STOCK_BAJO` cuando `0 < available <= umbral_efectivo` y `DISPONIBLE` en el resto (SPEC-016 §3).
