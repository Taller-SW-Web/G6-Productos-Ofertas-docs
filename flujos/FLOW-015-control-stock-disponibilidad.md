# FLOW-015 — Control de stock y disponibilidad

---

## 1. Identificación

- **Código:** FLOW-015
- **Funcionalidad:** Control de stock y disponibilidad
- **Relacionado con:** HU-015 / SPEC-015 / WF-015
- **Responsable:** Miguel Ángel Taco Zavala
- **Última actualización:** 2026-10-01

---

## 2. Objetivo del flujo

Representar el ciclo de inventario por `(sku, location_id)`: consulta determinística del saldo y su estado, reserva, consumo definitivo, liberación, expiración por TTL, ajustes masivos, incidencias físicas, reintegros, conciliación de ventas offline y recepción de traslados, garantizando en cada mutación las invariantes del saldo, el registro de Kardex, la idempotencia y la publicación de eventos posterior al commit.

---

## 3. Actores participantes

- Gestor comercial con capacidades de inventario
- Ventas/Postventa
- Retail
- Carga masiva (Bulk)
- Worker de expiración
- Sistema de Inventario
- Catálogo

---

## 4. Diagramas de flujo

### 4.1 Consulta y determinación de estado

```mermaid
flowchart LR
    subgraph GESTOR["Gestor comercial"]
        direction TB
        INICIO((Inicio de consulta))
        A1["Consultar saldo por SKU y ubicación"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("Solicitud de consulta recibida"))
        A2["Leer saldo autoritativo (sku, location_id)"]
        A3["Calcular available = max(on_hand - reserved - blocked, 0)"]
        A4["Verificar invariantes del saldo"]
        D1{"¿available = 0?"}
        D2{"¿available <= umbral_efectivo?"}
        A5["Clasificar AGOTADO"]
        A6["Clasificar STOCK_BAJO"]
        A7["Clasificar DISPONIBLE"]
        A8["Responder on_hand, reserved, blocked, available, status y stock_version"]
    end

    subgraph RES["Resultado"]
        direction TB
        F1["Mostrar saldo y estado"]
        FIN(((Fin de la consulta)))
    end

    INICIO --> A1
    A1 --> E1
    E1 --> A2
    A2 --> A3
    A3 --> A4
    A4 --> D1
    D1 -->|"Sí"| A5
    D1 -->|"No"| D2
    D2 -->|"Sí"| A6
    D2 -->|"No"| A7
    A5 --> A8
    A6 --> A8
    A7 --> A8
    A8 --> F1
    F1 --> FIN
```

> Marketplace y Chatbot solo consultan Inventario; la consulta nunca modifica saldos (HU-015 CA-06).

### 4.2 Reserva de unidades

```mermaid
flowchart LR
    subgraph VENT["Ventas / Postventa"]
        direction TB
        INICIO((Pedido en estado CREADO))
        A1["Solicitar reserva con identidad idempotente"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("Comando de reserva recibido"))
        D1{"¿Misma identidad con intención distinta?"}
        A2["Rechazar con 409 IDEMPOTENCY_CONFLICT"]
        D2{"¿Misma identidad con misma intención?"}
        A3["Responder resultado previo sin efectos"]
        A4["Admitir comando - 202 Accepted"]
        D3{"¿Hay stock suficiente?"}
        A5["Reservar: reserved aumenta y available disminuye"]
        A6["Persistir Kardex y Outbox en la misma transacción"]
        A7["Publicar inventory.reservation.created tras el commit"]
    end

    subgraph RES["Resultado"]
        direction TB
        A8["Reserva ACTIVA disponible para el pedido"]
        B1["Rechazo de negocio correlacionado STOCK_INSUFICIENTE"]
        FIN_OK(((Fin reservada)))
        FIN_CONF(((Fin conflicto de idempotencia)))
        FIN_NEG(((Fin sin stock)))
    end

    INICIO --> A1
    A1 --> E1
    E1 --> D1
    D1 -->|"Sí"| A2
    D1 -->|"No"| D2
    D2 -->|"Sí"| A3
    D2 -->|"No"| A4
    A2 --> FIN_CONF
    A3 --> A8
    A4 --> D3
    D3 -->|"No"| B1
    D3 -->|"Sí"| A5
    B1 --> FIN_NEG
    A5 --> A6
    A6 --> A7
    A7 --> A8
    A8 --> FIN_OK
```

### 4.3 Consumo definitivo y liberación

```mermaid
flowchart LR
    subgraph VENT["Ventas / Postventa"]
        direction TB
        D0{"¿Pedido pagado o anulado?"}
        A1["PAGADO: confirmar consumo de la reserva"]
        A2["PAGO_NO_COMPLETADO o anulación: liberar la reserva"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("Comando de mutación recibido"))
        D1{"¿Misma identidad con intención distinta?"}
        A3["Rechazar con 409 IDEMPOTENCY_CONFLICT"]
        D2{"¿Misma identidad con misma intención?"}
        A4["Responder resultado previo sin efectos"]
        A5["Admitir comando - 202 Accepted"]
        D3{"¿Reserva ACTIVA?"}
        A6["Rechazo de negocio: RESERVA_NO_ACTIVA / RESERVA_EXPIRADA"]
        D4{"¿Operación a aplicar?"}
        A7["Confirmar consumo: on_hand y reserved disminuyen"]
        A8["Liberar: reserved disminuye y on_hand sin cambios"]
        A9["Persistir Kardex y Outbox en la misma transacción"]
        A10["Publicar inventory.reservation.consumed y inventory.consumption.completed o inventory.reservation.released tras el commit"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["Reserva CONSUMIDA"]
        B2["Reserva LIBERADA"]
        B3["Pedido sin compromiso de stock"]
        FIN_OK(((Fin consumo confirmado)))
        FIN_LIB(((Fin reserva liberada)))
        FIN_CONF(((Fin conflicto de idempotencia)))
        FIN_REJ(((Fin rechazo de negocio)))
    end

    D0 -->|"PAGADO"| A1
    D0 -->|"No completado o anulación"| A2
    A1 --> E1
    A2 --> E1
    E1 --> D1
    D1 -->|"Sí"| A3
    D1 -->|"No"| D2
    A3 --> FIN_CONF
    D2 -->|"Sí"| A4
    D2 -->|"No"| A5
    A4 -->|"Consumo previo"| B1
    A4 -->|"Liberación previa"| B2
    A5 --> D3
    D3 -->|"No"| A6
    D3 -->|"Sí"| D4
    A6 --> B3
    B3 --> FIN_REJ
    D4 -->|"Confirmar"| A7
    D4 -->|"Liberar"| A8
    A7 --> A9
    A8 --> A9
    A9 --> A10
    A10 -->|"Consumo"| B1
    A10 -->|"Liberación"| B2
    B1 --> FIN_OK
    B2 --> FIN_LIB
```

### 4.4 Expiración por TTL y carrera hacia una única terminal

```mermaid
flowchart LR
    subgraph WORK["Worker de expiración"]
        direction TB
        INICIO((Revisión periódica de reservas ACTIVA))
        A1["Identificar reserva ACTIVA vencida"]
        D1{"¿Ya se aplicó una transición terminal?"}
        A2["Expirar: reserved disminuye, available se recalcula y la reserva pasa a EXPIRADA"]
        A3["Persistir Kardex y Outbox en la misma transacción"]
        A4["Confirmar commit local"]
        A5["Publicar inventory.reservation.expired"]
        A6["Publicar inventory.stock.changed por el cambio de saldo"]
    end

    subgraph VENT["Ventas / Postventa"]
        direction TB
        P1{"¿Confirmar o liberar?"}
        A7["Confirmar consumo"]
        A8["Liberar reserva"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        D2{"¿La reserva sigue ACTIVA?"}
        A9["Rechazar: RESERVA_EXPIRADA / RESERVA_NO_ACTIVA"]
        A10["Persistir Kardex y Outbox en la misma transacción"]
        A11["Aplicar transición terminal solicitada"]
    end

    subgraph RES["Resultado"]
        direction TB
        E1(("Una sola transición terminal alcanzada"))
        FIN(((Fin de la carrera)))
    end

    INICIO --> A1
    A1 --> D1
    D1 -->|"No"| A2
    D1 -->|"Sí"| FIN
    A2 --> A3
    A3 --> A4
    A4 --> A5
    A5 --> A6
    A6 --> E1
    P1 -->|"Confirmar"| A7
    P1 -->|"Liberar"| A8
    A7 --> D2
    A8 --> D2
    D2 -->|"No"| A9
    D2 -->|"Sí"| A11
    A11 --> A10
    A10 --> E1
    A9 --> FIN
    E1 --> FIN
```

### 4.5 Ajuste absoluto masivo (Bulk)

```mermaid
flowchart LR
    subgraph BULK["Carga masiva (Bulk)"]
        direction TB
        INICIO((Importación de ajustes absolutos))
        A1["Exportar saldo objetivo con stock_version"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("inventory.bulk.stock.adjust.requested recibido"))
        D1{"¿La stock_version coincide con la actual?"}
        A2["Rechazar con VERSION_CONFLICT y no reaplicar conteo obsoleto"]
        A3["Aplicar saldo absoluto por (sku, location_id)"]
        A4["Persistir Kardex y Outbox en la misma transacción"]
        A5["Incrementar stock_version y publicar inventory.stock.adjusted o stock.changed"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["Ajuste COMPLETADO"]
        B2["Ajuste RECHAZADO"]
        FIN_OK(((Fin ajuste aplicado)))
        FIN_CONF(((Fin ajuste obsoleto)))
    end

    INICIO --> A1
    A1 --> E1
    E1 --> D1
    D1 -->|"No"| A2
    D1 -->|"Sí"| A3
    A2 --> B2
    A3 --> A4
    A4 --> A5
    A5 --> B1
    B1 --> FIN_OK
    B2 --> FIN_CONF
```

### 4.6 Incidencia física (bloqueo y resolución)

```mermaid
flowchart LR
    subgraph RET["Retail"]
        direction TB
        INICIO((Detectar daño o ubicación no identificada))
        A1["Reportar incidencia con scope inventario:incidencias:reportar"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("Incidencia reportada"))
        D1{"¿Hay unidades disponibles?"}
        A2["Bloquear: blocked aumenta y on_hand sin cambios"]
        A3["Validar act_ref de resolución"]
        D3{"¿Act_ref válida?"}
        A4["Rechazar resolución"]
        D2{"¿Tipo de resolución?"}
        A5["REHABILITADO: blocked disminuye"]
        A6["MERMA o FALTANTE_CONFIRMADO: blocked y on_hand disminuyen una sola vez"]
        A7["TRASLADO_ALMACEN_CENTRAL: continuar en el subflujo 4.9"]
        A8["Persistir Kardex, act_ref y Outbox en la misma transacción"]
        A9["Publicar inventory.stock.adjusted o stock.changed tras el commit"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["Unidades bloqueadas y ocultas a la venta"]
        B2["Cuarentena resuelta"]
        FIN(((Fin de la incidencia)))
    end

    INICIO --> A1
    A1 --> E1
    E1 --> D1
    D1 -->|"No"| FIN
    D1 -->|"Sí"| A2
    A2 --> B1
    B1 --> A3
    A3 --> D3
    D3 -->|"No"| A4
    D3 -->|"Sí"| D2
    A4 --> FIN
    D2 -->|"REHABILITADO"| A5
    D2 -->|"MERMA o FALTANTE"| A6
    D2 -->|"TRASLADO_ALMACEN_CENTRAL"| A7
    A5 --> A8
    A6 --> A8
    A7 --> A8
    A8 --> A9
    A9 --> B2
    B2 --> FIN
```

### 4.7 Reintegro por devolución física aceptada

```mermaid
flowchart LR
    subgraph PV["Postventa"]
        direction TB
        INICIO((Devolución física recibida))
        A1["Confirmar recepción física y aptitud de reintegro"]
    end

    subgraph VENT["Ventas / Postventa"]
        direction TB
        A2["Solicitar reintegro con scope inventario:reintegrar"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("Solicitud de reintegro recibida"))
        D2{"¿Unidad recibida físicamente y apta?"}
        A3["Rechazar con REINTEGRO_NO_APLICABLE"]
        D1{"¿Misma identidad ya procesada?"}
        A4["Responder resultado previo sin duplicar"]
        A5["Incrementar on_hand y recalcular available"]
        A6["Incrementar stock_version"]
        A7["Registrar Kardex exactamente una vez"]
        A8["Publicar inventory.stock.changed tras el commit"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["Saldo reintegrado"]
        FIN(((Fin del reintegro)))
    end

    INICIO --> A1
    A1 --> A2
    A2 --> E1
    E1 --> D2
    D2 -->|"No"| A3
    D2 -->|"Sí"| D1
    A3 --> FIN
    D1 -->|"Sí"| A4
    D1 -->|"No"| A5
    A4 --> B1
    A5 --> A6
    A6 --> A7
    A7 --> A8
    A8 --> B1
    B1 --> FIN
```

### 4.8 Venta Retail offline y conciliación

```mermaid
flowchart LR
    subgraph RET["Retail"]
        direction TB
        INICIO((Venta realizada sin conectividad))
        A1["Registrar venta offline en Ventas/Postventa"]
    end

    subgraph VENT["Ventas / Postventa"]
        direction TB
        A2["Solicitar conciliación offline con scope inventario:conciliar-offline"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("Conciliación recibida"))
        D1{"¿Misma identidad ya procesada?"}
        A3["Aplicar min(requested, available) sin tocar reserved ni blocked"]
        D2{"¿Puede aplicarse todo lo solicitado?"}
        A4["Calcular unresolved_quantity conservando saldos no negativos"]
        A5["Persistir Kardex y Outbox en la misma transacción"]
        A6["Publicar inventory.stock.adjusted o stock.changed tras el commit"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["Conciliación COMPLETED"]
        B2["Conciliación REQUIRES_REVIEW con unresolved_quantity > 0"]
        FIN_OK(((Fin conciliado)))
        FIN_REV(((Fin con revisión)))
    end

    INICIO --> A1
    A1 --> A2
    A2 --> E1
    E1 --> D1
    D1 -->|"Sí"| B1
    D1 -->|"No"| A3
    A3 --> D2
    D2 -->|"Sí"| A5
    D2 -->|"No"| A4
    A4 --> A5
    A5 --> A6
    A6 -->|"COMPLETED"| B1
    A6 -->|"REQUIRES_REVIEW"| B2
    B1 --> FIN_OK
    B2 --> FIN_REV
```

### 4.9 Traslado a almacén central y recepción

```mermaid
flowchart LR
    subgraph ORIGEN["Sistema de Inventario"]
        direction TB
        INICIO((Incidencia resuelta como TRASLADO_ALMACEN_CENTRAL))
        A1["Descontar on_hand y blocked en el origen"]
        A2["Crear traslado EN_TRANSITO sin acreditar destino"]
    end

    subgraph GESTOR["Gestor comercial autorizado"]
        direction TB
        A3["Registrar recepción con cantidad, disposición y final_receipt"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("Solicitud de recepción recibida"))
        D1{"¿Misma identidad de recepción ya usada?"}
        A4["Responder resultado previo sin duplicar saldos"]
        D2{"¿Cantidad recibida <= cantidad pendiente?"}
        A5["Rechazar recepción"]
        D3{"¿Disposición declarada?"}
        A6["REINGRESAR_DISPONIBLE: acreditar unidades disponibles"]
        A7["REINGRESAR_BLOQUEADO: conservar cuarentena"]
        A8["CONFIRMAR_MERMA: no acreditar stock"]
        A9["Persistir Kardex y Outbox en la misma transacción"]
        A10["Publicar inventory.stock.changed o stock.adjusted tras el commit"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["Registrar estado RECIBIDO_PARCIAL, COMPLETADO o COMPLETADO_CON_DISCREPANCIA"]
        FIN_OK(((Fin del traslado)))
        FIN_REJ(((Fin recepción rechazada)))
    end

    INICIO --> A1
    A1 --> A2
    A2 --> A3
    A3 --> E1
    E1 --> D1
    D1 -->|"Sí"| A4
    D1 -->|"No"| D2
    A4 --> FIN_OK
    D2 -->|"No"| A5
    D2 -->|"Sí"| D3
    A5 --> FIN_REJ
    D3 -->|"Disponible"| A6
    D3 -->|"Bloqueado"| A7
    D3 -->|"Merma"| A8
    A6 --> A9
    A7 --> A9
    A8 --> A9
    A9 --> A10
    A10 --> B1
    B1 --> FIN_OK
```

### 4.10 Inicialización de SKU

```mermaid
flowchart LR
    subgraph CAT["Catálogo"]
        direction TB
        INICIO((SKU vendible confirmado))
        A1["Publicar inventory.sku.initialization.requested"]
    end

    subgraph INV["Sistema de Inventario"]
        direction TB
        E1(("Solicitud de inicialización recibida"))
        D1{"¿El SKU ya fue inicializado?"}
        A2["Responder resultado previo sin duplicar saldos"]
        A3["Crear saldo on_hand = 0, reserved = 0, blocked = 0 y available = 0"]
        A4["Establecer stock_version = 0 en la ubicación predeterminada"]
        A5["Responder inventory.sku.initialization.completed"]
    end

    subgraph RES["Resultado"]
        direction TB
        B1["SKU listo para reserva y venta"]
        FIN(((Fin de la inicialización)))
    end

    INICIO --> A1
    A1 --> E1
    E1 --> D1
    D1 -->|"Sí"| A2
    D1 -->|"No"| A3
    A2 --> A5
    A3 --> A4
    A4 --> A5
    A5 --> B1
    B1 --> FIN
```

---

## 5. Notas generales

- **Actor humano:** el usuario del backoffice en este flujo es el `GESTOR_COMERCIAL`; la granularidad de inventario se expresa mediante capacidades locales asociadas a su `sub`, no mediante un rol global independiente.
- **Idempotencia:** repetir un comando con la misma identidad y la misma intención responde el resultado previo sin efectos secundarios; reutilizar la identidad con otra intención produce `409 IDEMPOTENCY_CONFLICT` (HU-015 CA-14, SPEC-015 §30).
- **202 Accepted:** es la admisión del comando, no el resultado final. Los resultados asíncronos se correlacionan mediante `order_id`, `operation_id`, `correlation_id` y `reservation_id` (SPEC-015 §30).
- **Kardex y Outbox:** toda mutación autoritativa registra Kardex con saldos anterior/posterior, operación, SKU y ubicación, y persiste el Outbox en la misma transacción local; la publicación de eventos ocurre después del commit (HU-015 CA-16/CA-19, SPEC-015 §27).
- **Invariantes:** en toda operación se cumple `on_hand >= 0`, `reserved >= 0`, `blocked >= 0`, `reserved + blocked <= on_hand` y `available >= 0` (HU-015 CA-04).
- **Concurrencia:** confirmar, liberar y expirar la misma reserva produce una única transición terminal; dos operaciones concurrentes nunca comprometen las mismas unidades disponibles (HU-015 CA-13/CA-15).
- **Consulta:** el subflujo 4.1 es de solo lectura y nunca modifica saldos ni registra eventos (HU-015 CA-06).

### Contratos de referencia

| Endpoint (OpenAPI 0.5.0) | Subflujo |
|---|---|
| `POST /api/v1/inventario/reservas` | 4.2 — Reserva de unidades |
| `POST /api/v1/inventario/reservas/{reservaId}/confirmar` | 4.3 — Consumo definitivo |
| `POST /api/v1/inventario/reservas/{reservaId}/liberar` | 4.3 — Liberación |
| `POST /api/v1/inventario/incidencias` | 4.6 — Reportar incidencia |
| `POST /api/v1/inventario/incidencias/{incidenciaId}/resolver` | 4.6 — Resolución (incluye traslado) |
| `POST /api/v1/inventario/reintegros` | 4.7 — Reintegro |
| `POST /api/v1/inventario/conciliaciones-offline` | 4.8 — Venta offline |
| `GET /api/v1/inventario/traslados` | 4.9 — Consulta de traslados |
| `POST /api/v1/inventario/traslados/{trasladoId}/recepciones` | 4.9 — Recepción de traslado |

Los eventos publicados corresponden al catálogo de AsyncAPI (`inventory.reservation.*`, `inventory.consumption.*`, `inventory.stock.changed`, `inventory.stock.adjusted`, `inventory.bulk.stock.adjust.*`, `inventory.sku.initialization.*`).

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Flujos de lectura 0.5.0

### Consulta detallada

```text
Gestor/Ventas autorizado
→ leer (sku, location_id)
→ calcular available
→ validar invariantes
→ determinar status
→ devolver saldo detallado
```

### Consulta comercial

```text
Marketplace/Chatbot/Retail
→ solicitar skus + canal
→ inventory-svc obtiene disponibilidad autoritativa
→ resolver disponibilidad comercial según política
→ proyectar sku + status
→ responder
```

La política multiubicación sigue marcada `D-INV-01`; no se inventa suma, máximo ni ubicación por defecto.

Ambas consultas son de solo lectura.
<!-- HOMOLOGACION-HTTP-0.5.0:END -->
