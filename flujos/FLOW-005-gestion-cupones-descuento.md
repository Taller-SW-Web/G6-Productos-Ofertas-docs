# FLOW-005 — Gestión de cupones de descuento

## 1. Identificación

- **Código:** FLOW-005
- **Funcionalidad:** Gestión de cupones de descuento
- **Relacionado con:** [SPEC-005](../specs/SPEC-005-gestion-cupones-descuento.md) / [HU-005](../hu/HU-005-gestion-cupones-descuento.md) / [WF-005](../wireframes/flows/WF-005-gestion-cupones-descuento.md)
- **Responsable:** Axel Andree Cueva Alcalá
- **Última actualización:** 2026-10-02
- **Contratos consultados:** [OpenAPI 0.5.0](../api/openapi.yaml), [AsyncAPI 0.4.0](../asyncapi/asyncapi.yaml), [catálogo de eventos](../api/catalogo-eventos.md) y [Contrato API, §§31.4–31.5](../Contrato_Api.md).

## 2. Objetivo del flujo

Representar la creación, edición y activación/desactivación de cupones asociados a promociones, su validación sin consumo y su consumo y restitución automáticos vinculados al pedido. La administración configura límites y política; Ventas/Postventa coordina el ciclo comercial y conserva el ownership del pedido y del pago.

## 3. Actores participantes

- **Gestor comercial:** consulta, crea, edita y cambia el estado de cupones con autorización de Seguridad.
- **Canal de venta:** Marketplace, Chatbot o Retail; solicita validación y transmite la identidad del cliente autenticado.
- **Promociones/Cupones (`promotions-svc`):** administra cupones, evalúa beneficios y controla usos atómicos e idempotentes.
- **Ventas/Postventa:** crea el pedido, espera la reserva confirmada, conserva el snapshot comercial y solicita consumo o restitución.

Inventario confirma la reserva al flujo de Ventas; ese proceso se documenta en su propio dominio. Seguridad proporciona identidad y permisos, sin incorporar una llamada remota adicional en cada paso del FLOW.

## 4. Diagramas de flujo

Los subflujos usan orientación `TB` para conservar la legibilidad al renderizar en GitHub. Se mantienen actores separados, decisiones etiquetadas e inicio y fin explícitos conforme a [FLOW_TEMPLATE](FLOW_TEMPLATE.md).

### 4.1 Creación y edición

```mermaid
flowchart TB
    subgraph G["Gestor comercial"]
        direction TB
        I(("Gestión abierta"))
        G1["Consultar listado y detalle"]
        G2["Elegir crear o editar cupón"]
        G3["Ingresar código, promoción, estado, límites, monto mínimo y política"]
        G4["Corregir los datos conservados"]
        G5["Consultar cupón y uso global actualizado"]
        F((("Guardado")))
    end
    subgraph P["Promociones/Cupones"]
        direction TB
        D1{"¿Sesión y permisos válidos?"}
        P1["Normalizar código y comprobar unicidad, excluyendo el cupón editado"]
        D2{"¿Código único y configuración válida?"}
        P2["Validar promoción asociada, límites opcionales y política de restitución"]
        D3{"¿Datos válidos?"}
        P3["Guardar creación o edición"]
        P4["Informar validación o código duplicado sin guardar"]
        X((("Sin acceso")))
    end
    I --> G1 --> G2 --> D1
    D1 -->|"Sí"| G3
    D1 -->|"No"| X
    G3 --> P1 --> D2
    D2 -->|"Sí"| P2 --> D3
    D2 -->|"No"| P4
    D3 -->|"Sí"| P3 --> G5 --> F
    D3 -->|"No"| P4
    P4 --> G4 --> G3
```

- El código normalizado es único (HU-005 CA-01). El FLOW no define un algoritmo de normalización adicional al contrato.
- Los límites global y por cliente son opcionales: vacío representa «Sin límite»; si se informan, son enteros positivos. El monto mínimo opcional debe ser positivo, conforme a OpenAPI.
- La política es `RESTAURAR_EN_CANCELACION` o `NO_RESTAURAR`.
- Crear y editar usan `POST /api/v1/cupones` y `PATCH /api/v1/cupones/{cuponId}`; listado y detalle usan las consultas del mismo recurso. Los payloads se mantienen en OpenAPI.

### 4.2 Activación y desactivación

```mermaid
flowchart TB
    subgraph G["Gestor comercial"]
        direction TB
        I(("Cambio solicitado"))
        G1["Seleccionar cupón y estado destino"]
        G2["Consultar estado actualizado"]
        F((("Actualizado")))
    end
    subgraph P["Promociones/Cupones"]
        direction TB
        P1["Validar sesión, permisos, existencia y solicitud"]
        D1{"¿Solicitud válida?"}
        P2["Activar o desactivar cupón"]
        P3["Informar el rechazo sin cambiar el estado"]
        X((("Rechazado")))
    end
    I --> G1 --> P1 --> D1
    D1 -->|"Sí"| P2 --> G2 --> F
    D1 -->|"No"| P3 --> X
```

Se utilizan `POST /api/v1/cupones/{cuponId}/activar` y `POST /api/v1/cupones/{cuponId}/desactivar`. La administración no ofrece acciones «Consumir» o «Restituir» (WF-005).

### 4.3 Validación sin consumo

```mermaid
flowchart TB
    subgraph C["Canal de venta"]
        direction TB
        I(("Validación solicitada"))
        C1["Enviar código, cesta, canal e identidad del cliente cuando corresponda"]
        C2["Recibir validez, beneficio o motivo de rechazo"]
        F((("Sin consumo")))
    end
    subgraph P["Promociones/Cupones"]
        direction TB
        P0["Validar solicitud y autorización del canal"]
        D0{"¿Solicitud válida y autorizada?"}
        P1["Normalizar código y buscar cupón"]
        D1{"¿Cupón existente, activo, vigente y aplicable al alcance?"}
        D2{"¿Requiere límite por cliente?"}
        D3{"¿Está presente la identidad del cliente requerida?"}
        P2["Comprobar límites global y por cliente y monto mínimo aplicable"]
        D4{"¿Cumple las condiciones?"}
        P3["Evaluar beneficio sin registrar un uso"]
        P4["Responder 200 con valid=false y motivo de negocio"]
        P5["Responder 200 con CUSTOMER_REF_REQUERIDO"]
        P6["Responder error HTTP contractual"]
    end
    I --> C1 --> P0 --> D0
    D0 -->|"Sí"| P1 --> D1
    D0 -->|"No"| P6 --> C2
    D1 -->|"Sí"| D2
    D1 -->|"No"| P4
    D2 -->|"Sí"| D3
    D2 -->|"No"| P2
    D3 -->|"Sí"| P2 --> D4
    D3 -->|"No"| P5
    D4 -->|"Sí"| P3 --> C2
    D4 -->|"No"| P4
    P4 --> C2
    P5 --> C2
    C2 --> F
```

La consulta usa `POST /api/v1/cupones/validar`. Un cupón no aplicable es un resultado de negocio HTTP 200 con `valid=false` y `code`; los errores de solicitud, autorización o infraestructura usan los errores HTTP publicados en OpenAPI 0.5.0. `customer_ref = sub` UUID del usuario autenticado en Seguridad; Ventas persiste ese mismo UUID. El `sub` del token de servicio no identifica al cliente. Se permite anónimo (`null`) solo si no se requiere límite por cliente; un UUID mal formado se trata como solicitud inválida conforme al contrato.

Validar o evaluar no consume cupón, no crea pedido, no reserva stock ni reserva el último uso. Una respuesta positiva no garantiza capacidad al consumir (SPEC-005 §3; HU-005 CA-02–04).

### 4.4 Consumo después de reserva confirmada y antes del pago

```mermaid
flowchart TB
    subgraph V["Ventas/Postventa"]
        direction TB
        I(("Pedido CREADO"))
        V1["Esperar resultado de reserva de Inventario"]
        D1{"¿Reserva confirmada?"}
        V2["Fijar snapshot comercial final y effective_at"]
        V3["Publicar promotions.coupon.consumption.requested"]
        V4["Habilitar intento de pago solo con completed"]
        V5["Impedir cobrar con ese snapshot"]
        F((("Pago habilitado")))
        X((("Pago no habilitado")))
    end
    subgraph P["Promociones/Cupones"]
        direction TB
        P1["Validar comando, identidad del cupón y coherencia con pedido y snapshot"]
        D0{"¿Comando válido y coherente?"}
        D2{"¿Ya existe resultado para este consumo?"}
        P2["Devolver el mismo resultado lógico sin duplicar efectos"]
        P3["Revalidar identidad requerida y capacidad global y por cliente atómicamente"]
        D3{"¿Consumo válido y con capacidad?"}
        P4["Registrar un único consumo por order_id y cupon_id y publicar completed"]
        P5["Publicar promotions.coupon.consumption.rejected"]
        D4{"¿Resultado completed?"}
    end
    I --> V1 --> D1
    D1 -->|"Sí"| V2 --> V3 --> P1 --> D0
    D1 -->|"No"| X
    D0 -->|"Sí"| D2
    D0 -->|"No"| P5
    D2 -->|"Sí"| P2 --> D4
    D2 -->|"No"| P3 --> D3
    D3 -->|"Sí"| P4 --> D4
    D3 -->|"No"| P5 --> D4
    D4 -->|"Sí"| V4 --> F
    D4 -->|"No"| V5 --> X
```

Los resultados son `promotions.coupon.consumption.completed` y `promotions.coupon.consumption.rejected`. La identidad de negocio `(order_id, cupon_id)` admite como máximo un consumo; dos pedidos por el último uso producen como máximo un ganador. Los reintentos conservan el mismo efecto lógico (HU-005 CA-05–08).

`effective_at` conserva el instante de elegibilidad comercial. El consumo revalida identidad, cupos y coherencia sin recalcular ni sustituir el snapshot monetario del pedido (Contrato API §31.4). Los resultados de consumo permanecen `provisional-external` en AsyncAPI; este FLOW no los declara homologados definitivamente.

### 4.5 Restitución idempotente

```mermaid
flowchart TB
    subgraph V["Ventas/Postventa"]
        direction TB
        I(("Pedido cancelado"))
        V1["Publicar promotions.coupon.restoration.requested con order_id"]
        V2["Recibir resultado de restitución"]
        F((("Respondida")))
    end
    subgraph P["Promociones/Cupones"]
        direction TB
        P1["Validar comando y consultar consumo del pedido"]
        D1{"¿Comando válido?"}
        P2["Publicar promotions.coupon.restoration.rejected"]
        D2{"¿Restitución ya procesada?"}
        P3["Devolver el mismo resultado sin aumentar de nuevo el cupo"]
        D3{"¿Existe consumo previo?"}
        P4["Responder NO_CONSUMPTION sin aumentar el cupo"]
        D4{"¿Política RESTAURAR_EN_CANCELACION?"}
        P5["Restituir una sola vez el uso registrado y responder RESTORED"]
        P6["Conservar el consumo y responder POLICY_KEEPS_CONSUMPTION"]
        P7["Publicar promotions.coupon.restoration.completed con outcome y restored"]
    end
    I --> V1 --> P1 --> D1
    D1 -->|"No"| P2 --> V2
    D1 -->|"Sí"| D2
    D2 -->|"Sí"| P3 --> V2
    D2 -->|"No"| D3
    D3 -->|"No"| P4 --> P7
    D3 -->|"Sí"| D4
    D4 -->|"Sí"| P5 --> P7
    D4 -->|"No: NO_RESTAURAR"| P6 --> P7
    P7 --> V2 --> F
```

`RESTORED` corresponde a `restored=true`; `POLICY_KEEPS_CONSUMPTION` y `NO_CONSUMPTION` a `restored=false`. Un pedido sin consumo previo no genera cupo y la restitución nunca supera el uso realmente registrado (HU-005 CA-09–11). Promociones no decide cancelación, pago ni reembolso (CA-12).

## 5. Coherencia y trazabilidad

| Reglas | Fuente | Representación |
|---|---|---|
| Administración, código único, límites y política | HU-005 CA-01; WF-005; OpenAPI CuponCreateRequest/CuponUpdateRequest | §§4.1–4.2 |
| Identidad y validación sin consumo | SPEC-005 §§2–3; HU-005 CA-02–04 | §4.3 |
| Reserva → consumo → pago; atomicidad e idempotencia | SPEC-005 §4; HU-005 CA-05–08; Contrato API §31.4 | §4.4 |
| Restitución y límites de ownership | SPEC-005 §§5–6; HU-005 CA-09–12; Contrato API §31.5 | §4.5 |

Los comandos/resultados de consumo y restitución pertenecen al proceso del pedido. Los eventos de catálogo, stock y precio actualizan proyecciones internas como se representa en [FLOW-006 §4.4](FLOW-006-gestion-ofertas-promociones.md#44-actualización-de-proyecciones-locales); su recepción no equivale a una acción administrativa del gestor ni a un consumo/restitución de cupón.
