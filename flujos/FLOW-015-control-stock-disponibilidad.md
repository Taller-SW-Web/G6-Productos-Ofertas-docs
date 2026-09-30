# FLOW-015 — Control de stock y disponibilidad

## 1. Identificación

- **Código:** FLOW-015
- **Funcionalidad:** Control de stock y disponibilidad
- **Relacionado con:** [HU-015](../hu/HU-015-control-stock-disponibilidad.md) / [SPEC-015](../specs/SPEC-015-control-stock-disponibilidad.md) / [WF-015](../wireframes/flows/WF-015-control-stock-disponibilidad.md)
- **Responsable:** Miguel Ángel Taco Zavala
- **Última actualización:** 2026-09-30

---

## 2. Objetivo del flujo

Representar el ciclo operativo del inventario: la consulta de disponibilidad por `(sku, location_id)`, la determinación determinista del estado de stock, la configuración de umbrales (global + override por SKU), el ciclo de reserva del pedido (`CREADO` → reserva, `PAGADO` → confirmación/consumo, liberación por pago no completado/anulación/TTL), las compensaciones y devoluciones provisionales, y el ajuste absoluto masivo con `stock_version`. El stock nunca puede quedar negativo, toda mutación autoritativa registra Kardex y se publica `inventory.stock.changed` solo después del commit.

---

## 3. Actores participantes

- **Canal (Marketplace / Retail / Chatbot):** consulta la disponibilidad; no resguarda ni muta stock.
- **Responsable de inventario:** configura umbrales y consulta saldos.
- **Ventas / Postventa:** solicita reserva, confirmación (consumo), liberación y compensaciones; decide el ciclo del pedido.
- **Despacho:** entrega unidades de ventas ya confirmadas sin generar consumo.
- **Worker de expiración:** libera reservas `ACTIVA` al vencer su TTL.
- **Carga masiva (Bulk):** solicita ajustes absolutos con `location_id` y `stock_version`.
- **Sistema de Inventario:** ejecuta las mutaciones idempotentes, registra Kardex y publica eventos.

---

## 4. Diagramas de flujo

### 4.1 Consulta de disponibilidad por SKU y ubicación

```mermaid
flowchart LR

    subgraph CANAL["Canal (Marketplace / Retail / Chatbot)"]
        direction TB
        INICIO((Solicitud de disponibilidad))
        C1["Enviar SKU y location_id opcional"]
        C2["Recibir on_hand, reserved y available"]
        C3["Visualizar estado de la variante"]
    end

    subgraph INVENTARIO["Sistema de Inventario"]
        direction TB
        V1["Validar el SKU vendible"]
        D1{"¿El SKU existe y es vendible?"}
        V2["Rechazar con SKU_NO_ENCONTRADO"]
        V3["Leer saldo autoritativo de (sku, location_id)"]
        D2{"¿El canal solicita disponibilidad global?"}
        V4["Agregar ubicaciones elegibles (solo lectura)"]
        V5["Devolver on_hand, reserved y available por ubicación"]
    end

    FIN_OK(((Disponibilidad entregada)))
    FIN_ERROR(((Consulta rechazada)))

    INICIO --> C1
    C1 --> V1
    V1 --> D1
    D1 -->|"No"| V2
    V2 --> FIN_ERROR
    D1 -->|"Sí"| V3
    V3 --> D2
    D2 -->|"No"| V5
    D2 -->|"Sí"| V4
    V4 --> V5
    V5 --> C2
    C2 --> C3
    C3 --> FIN_OK
```

> La consulta devuelve el saldo autoritativo y no constituye reserva ni garantía de stock. Cuando solo existe `DEFAULT`, el canal puede omitir `location_id` sin ambigüedad.

---

### 4.2 Determinación del estado de stock

```mermaid
flowchart LR

    subgraph INVENTARIO["Sistema de Inventario"]
        direction TB
        INICIO((Calcular estado de stock))
        E1["Obtener available del saldo (sku, location_id)"]
        E2["Obtener umbral_efectivo (override SKU ?? umbral_global)"]
        D1{"¿available = 0?"}
        D2{"¿available <= umbral_efectivo?"}
        E3["Determinar estado AGOTADO"]
        E4["Determinar estado STOCK_BAJO"]
        E5["Determinar estado DISPONIBLE"]
    end

    FIN_AGOTADO(((Estado: AGOTADO)))
    FIN_BAJO(((Estado: STOCK_BAJO)))
    FIN_DISPONIBLE(((Estado: DISPONIBLE)))

    INICIO --> E1
    E1 --> E2
    E2 --> D1
    D1 -->|"Sí"| E3
    E3 --> FIN_AGOTADO
    D1 -->|"No"| D2
    D2 -->|"Sí"| E4
    E4 --> FIN_BAJO
    D2 -->|"No"| E5
    E5 --> FIN_DISPONIBLE
```

---

### 4.3 Configuración de umbrales (global y override por SKU)

```mermaid
flowchart LR

    subgraph GESTOR["Responsable de inventario"]
        direction TB
        INICIO((Acceso a configuración de umbrales))
        G1["Elegir umbral global o override por SKU"]
        G2["Ingresar valor entero mayor o igual a 0"]
    end

    subgraph INVENTARIO["Sistema de Inventario"]
        direction TB
        V1["Validar formato y rango del valor"]
        D1{"¿El valor es válido?"}
        V2["Rechazar con error de validación"]
        D2{"¿Configura umbral global u override de SKU?"}
        V3["Persistir umbral global"]
        V4["Establecer, actualizar o eliminar override del SKU"]
        V5["Recalcular umbral_efectivo y estado de los SKUs afectados"]
    end

    FIN_OK(((Umbral actualizado)))
    FIN_ERROR(((Cambio rechazado)))

    INICIO --> G1
    G1 --> G2
    G2 --> V1
    V1 --> D1
    D1 -->|"No"| V2
    V2 --> FIN_ERROR
    D1 -->|"Sí"| D2
    D2 -->|"Global"| V3
    D2 -->|"Override SKU"| V4
    V3 --> V5
    V4 --> V5
    V5 --> FIN_OK
```

> La jerarquía del umbral es `umbral_efectivo = override SKU ?? umbral_global`; el umbral aplica a nivel de SKU y no por ubicación. Al eliminar un override, el SKU vuelve a evaluar con el umbral global.

---

### 4.4 Ajuste absoluto masivo con control de concurrencia

```mermaid
flowchart LR

    subgraph BULK["Carga masiva (Bulk)"]
        direction TB
        INICIO((Comando de ajuste absoluto masivo))
        B1["Enviar conteo absoluto con location_id y stock_version"]
    end

    subgraph INVENTARIO["Sistema de Inventario"]
        direction TB
        V1["Verificar existencia del par (sku, location_id)"]
        V2["Comparar stock_version enviada con la vigente"]
        D1{"¿La versión vigente coincide?"}
        V3["Rechazar con VERSION_CONFLICT sin sobrescribir"]
        V4["Aplicar conteo absoluto en transacción local acotada"]
        V5["Registrar Kardex con valores anteriores y nuevos"]
        V6["Commit local y publicar inventory.stock.adjusted e inventory.stock.changed"]
    end

    FIN_OK(((Ajuste aplicado)))
    FIN_CONFLICTO(((Rechazado por versión obsoleta)))

    INICIO --> B1
    B1 --> V1
    V1 --> V2
    V2 --> D1
    D1 -->|"No"| V3
    V3 --> FIN_CONFLICTO
    D1 -->|"Sí"| V4
    V4 --> V5
    V5 --> V6
    V6 --> FIN_OK
```

---

### 4.5 Ciclo de reserva y confirmación de consumo

```mermaid
flowchart LR

    subgraph VENTAS["Ventas / Postventa"]
        direction TB
        INICIO((Pedido CREADO))
        V1["Solicitar inventory.reserve (order_id, operation_id, SKU, cantidad, location_id, TTL)"]
        PAGADO(("Pedido PAGADO / venta confirmada"))
        V2["Solicitar inventory.consume (confirmación de reserva)"]
        V3["Recibir resultado de la operación"]
    end

    subgraph INVENTARIO["Sistema de Inventario"]
        direction TB
        I1["Reconstruir clave de idempotencia (order_id + tipo_operacion + sku)"]
        D1{"¿La reserva ya fue procesada?"}
        I2["Responder el resultado previo (no-op)"]
        D2{"¿La segunda intención contradice el estado vigente?"}
        I3["Responder IDEMPOTENCY_CONFLICT"]
        D3{"¿available >= cantidad y el SKU es válido?"}
        I4["Rechazar la reserva por stock insuficiente"]
        I5["Reservar: reserved + cantidad, available - cantidad, on_hand sin cambios"]
        I6["Persistir la reserva en estado ACTIVA y registrar Kardex"]
        I7["Deduplicar la confirmación (order_id + tipo_operacion + sku)"]
        D4{"¿La confirmación ya fue procesada?"}
        I8["Responder el resultado previo (no-op)"]
        D5{"¿La intención contradice el estado de la reserva?"}
        I9["Responder IDEMPOTENCY_CONFLICT"]
        D6{"¿La reserva es ACTIVA y la cantidad es válida?"}
        I10["Rechazar la confirmación por reserva inexistente o divergente"]
        I11["Consumir: on_hand - cantidad y reserved - cantidad"]
        I12["Persistir el estado terminal CONSUMIDA y registrar Kardex"]
        I13["Commit local y publicar inventory.stock.changed"]
    end

    FIN_RESERVA_OK(((Reserva ACTIVA registrada)))
    FIN_CONSUMO_OK(((Consumo confirmado / CONSUMIDA)))
    FIN_RECHAZO(((Reserva rechazada)))
    FIN_PREVIO1(((No-op / resultado previo)))
    FIN_CONFLICTO(((IDEMPOTENCY_CONFLICT)))
    FIN_PREVIO2(((No-op / resultado previo)))
    FIN_CONFLICTO2(((IDEMPOTENCY_CONFLICT)))
    FIN_CONSUMO_RECHAZADO(((Consumo rechazado)))

    INICIO --> V1
    V1 --> I1
    I1 --> D1
    D1 -->|"Sí"| I2
    I2 --> V3
    V3 --> FIN_PREVIO1
    D1 -->|"No"| D2
    D2 -->|"Sí"| I3
    I3 --> V3
    V3 --> FIN_CONFLICTO
    D2 -->|"No"| D3
    D3 -->|"No"| I4
    I4 --> V3
    V3 --> FIN_RECHAZO
    D3 -->|"Sí"| I5
    I5 --> I6
    I6 --> V3
    V3 --> FIN_RESERVA_OK

    PAGADO --> V2
    V2 --> I7
    I7 --> D4
    D4 -->|"Sí"| I8
    I8 --> V3
    V3 --> FIN_PREVIO2
    D4 -->|"No"| D5
    D5 -->|"Sí"| I9
    I9 --> V3
    V3 --> FIN_CONFLICTO2
    D5 -->|"No"| D6
    D6 -->|"No"| I10
    I10 --> V3
    V3 --> FIN_CONSUMO_RECHAZADO
    D6 -->|"Sí"| I11
    I11 --> I12
    I12 --> I13
    I13 --> V3
    V3 --> FIN_CONSUMO_OK
```

> La reserva modifica `reserved`/`available`, nunca `on_hand`. El consumo confirmado reduce `on_hand` y `reserved` simultáneamente. Si Ventas/Postventa no utiliza la fase de reserva, el consumo se valida directamente contra `available` con la confirmación acordada.

---

### 4.6 Liberación y expiración de reservas

```mermaid
flowchart LR

    subgraph VENTAS["Ventas / Postventa"]
        direction TB
        NO_PAGO(("PAGO_NO_COMPLETADO o anulación aplicable"))
        V1["Solicitar inventory.release (order_id, operation_id, SKU, cantidad)"]
        V2["Recibir resultado de la liberación"]
    end

    subgraph INVENTARIO["Sistema de Inventario"]
        direction TB
        I1["Reconstruir clave de idempotencia (order_id + tipo_operacion + sku)"]
        D1{"¿La liberación ya fue procesada?"}
        I2["Responder el resultado previo (no-op)"]
        D2{"¿La intención contradice el estado vigente?"}
        I3["Responder IDEMPOTENCY_CONFLICT"]
        D3{"¿La reserva es ACTIVA y la cantidad es válida?"}
        I4["Rechazar la liberación por reserva inexistente o divergente"]
        I5["Liberar: reserved - cantidad, available + cantidad, on_hand sin cambios"]
        I6["Persistir el estado terminal LIBERADA y registrar Kardex"]
        I7["Commit local y publicar inventory.stock.changed"]
    end

    subgraph WORKER["Worker de expiración"]
        direction TB
        TTL(("TTL vencido"))
        W1["Buscar reservas ACTIVA vencidas"]
        W2["Expirar reserva: liberar reserved y pasar a EXPIRADA"]
        W3["Registrar Kardex"]
    end

    FIN_LIBERADO(((Reserva LIBERADA)))
    FIN_EXPIRADO(((Reserva EXPIRADA)))
    FIN_PREVIO(((No-op / resultado previo)))
    FIN_CONFLICTO(((IDEMPOTENCY_CONFLICT)))
    FIN_RECHAZO(((Liberación rechazada)))

    NO_PAGO --> V1
    V1 --> I1
    I1 --> D1
    D1 -->|"Sí"| I2
    I2 --> V2
    V2 --> FIN_PREVIO
    D1 -->|"No"| D2
    D2 -->|"Sí"| I3
    I3 --> V2
    V2 --> FIN_CONFLICTO
    D2 -->|"No"| D3
    D3 -->|"No"| I4
    I4 --> V2
    V2 --> FIN_RECHAZO
    D3 -->|"Sí"| I5
    I5 --> I6
    I6 --> I7
    I7 --> V2
    V2 --> FIN_LIBERADO

    TTL --> W1
    W1 --> W2
    W2 --> W3
    W3 --> FIN_EXPIRADO
```

> La liberación recupera `available` sin incrementar `on_hand`. Los estados `CONSUMIDA`, `LIBERADA` y `EXPIRADA` son terminales y no vuelven a `ACTIVA`. El reintento idéntico de una liberación ya aplicada es un no-op; una intención contradictoria responde `IDEMPOTENCY_CONFLICT`.

---

### 4.7 Compensaciones, devoluciones y delimitación de Despacho

```mermaid
flowchart LR

    subgraph VENTAS["Ventas / Postventa"]
        direction TB
        CANCEL(("order.cancelled / consumo previo"))
        V1["Solicitar compensación del consumo previo no compensado"]
        RET(("order.returned / aceptación física"))
        V2["Solicitar reposición de unidades aceptadas y reintegrables"]
    end

    subgraph INVENTARIO["Sistema de Inventario"]
        direction TB
        I1["Validar consumo previo efectivo y no compensado"]
        D1{"¿Aplica compensación?"}
        I2["No compensar y conservar el estado actual"]
        I3["Compensar en la ubicación acordada y registrar Kardex"]
        I4["Validar SKU, cantidad y ubicación de reintegro"]
        D2{"¿La devolución física es válida?"}
        I5["No reponer la devolución no aceptada"]
        I6["Reponer solo las unidades aceptadas en el reintegro"]
        I7["Commit local y publicar inventory.stock.changed"]
    end

    subgraph DESPACHO["Despacho"]
        direction TB
        CICLO(("Venta consolidada / consumo ya aplicado"))
        D3["Entregar unidades de ventas confirmadas sin generar consumo ni modificar stock"]
    end

    FIN_COMPENSADO(((Consumo compensado)))
    FIN_NO_COMPENSA(((Sin compensación)))
    FIN_REPUESTO(((Stock repuesto)))
    FIN_NO_REPONE(((Sin reposición)))
    FIN_DESPACHO(((Despacho sin segundo consumo)))

    CANCEL --> V1
    V1 --> I1
    I1 --> D1
    D1 -->|"Sí"| I3
    I3 --> I7
    I7 --> FIN_COMPENSADO
    D1 -->|"No"| I2
    I2 --> FIN_NO_COMPENSA

    RET --> V2
    V2 --> I4
    I4 --> D2
    D2 -->|"No"| I5
    I5 --> FIN_NO_REPONE
    D2 -->|"Sí"| I6
    I6 --> I7
    I7 --> FIN_REPUESTO

    CICLO --> D3
    D3 --> FIN_DESPACHO
```

> La política de devolución (total o parcial, incluidos combos) pertenece a Ventas/Postventa; Inventario solo repone unidades físicamente aceptadas y reintegrables. Una anulación administrativa posterior al despacho sin devolución física no repone stock.

---

## 5. Delimitaciones operativas del flujo

- Unidad operativa: `(sku, location_id)` con `available = max(on_hand - reserved, 0)`; el stock nunca queda negativo.
- Toda mutación autoritativa registra Kardex y el mensaje Outbox en la misma transacción local, y publica `inventory.stock.changed` solo después del commit local.
- Todos los hitos externos (`CREADO`, `PAGADO`, `PAGO_NO_COMPLETADO`, `order.cancelled`, `order.returned`) son contratos provisionales pendientes de homologación con Ventas/Postventa; un `202 Accepted` solo admite la solicitud, no confirma la operación de inventario.