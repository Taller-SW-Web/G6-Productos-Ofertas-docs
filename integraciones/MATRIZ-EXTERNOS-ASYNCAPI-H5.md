# Matriz de frontera externa H5 — AsyncAPI de G6 a HTTP

**Estado:** auditoría de contrato H4 y propuesta de cambio H5; homologación externa y permisos pendientes.
**Fuente principal:** `contratos/eventos/asyncapi.yaml` (`0.6.0-rc.4`, 40 mensajes) y `contratos/http/openapi.yaml` (`0.6.0-rc.4`).

## Qué grupos realmente aparecen como productores/consumidores externos

| Grupo | Estado contractual verificado | Decisión H5 propuesta |
|---|---|---|
| G1 Marketplace | BFF consulta Gateway por HTTP; no es productor directo declarado del broker G6 | Mantener HTTP sin otorgar acceso a Service Bus |
| G2 Despacho | `consultarDatosFisicos` por HTTP, acuerdos H-G2/D-G2 | Mantener HTTP, sin cambio de mensajería |
| G3 Chatbot | ADR de integración sin eventos, consumo HTTP bajo demanda | Mantener HTTP |
| G4 Retail | Lecturas/operaciones HTTP; conciliación offline requiere resolver divergencia G4/G5/G6 | No inventar cola directa ni alterar el ownership offline |
| G5 Ventas/Postventa | Productor de 2 comandos Promotions y consumidor de 11 mensajes Inventory/Promotions según AsyncAPI | Migrar frontera externa a HTTP + consulta de estado, sujeto a aceptación G5; estado de reserva propuesto por GET `/api/v1/inventario/reservas/{reservaId}/estado` |
| G7 Seguridad | Identidades/grants de cliente HTTP; no identificado como consumidor externo del bus G6 | Gestionar grants HTTP; no dar credenciales Basic |

`api-gateway/bff` en los mensajes de G6 no constituye prueba de que G1 Marketplace consuma el broker directamente.

## Los 13 mensajes de `modulo-ventas`

| Tipo | Mensaje AsyncAPI H4 | Consumidor/operación HTTP H5 propuesta |
|---|---|---|
| G5→G6 | `promotions.coupon.consumption.requested` | `POST /api/v1/cupones/consumos` |
| G5→G6 | `promotions.coupon.restoration.requested` | `POST /api/v1/cupones/restauraciones` |
| G6→G5 | `promotions.coupon.consumption.completed` | `GET /api/v1/cupones/operaciones/{operationId}` |
| G6→G5 | `promotions.coupon.consumption.rejected` | mismo GET |
| G6→G5 | `promotions.coupon.restoration.completed` | mismo GET |
| G6→G5 | `promotions.coupon.restoration.rejected` | mismo GET |
| G6→G5 | `inventory.reservation.created` | `GET /api/v1/inventario/operaciones/{operationId}` |
| G6→G5 | `inventory.reservation.rejected` | mismo GET |
| G6→G5 | `inventory.reservation.consumed` | mismo GET |
| G6→G5 | `inventory.reservation.released` | mismo GET |
| G6→G5 | `inventory.reservation.expired` | **revisar caso especial**: expiración espontánea puede ocurrir tras completar operación inicial |
| G6→G5 | `inventory.consumption.completed` | mismo GET |
| G6→G5 | `inventory.consumption.rejected` | mismo GET |

**P0 semántico:** consultar solo la operación inicial puede NO informar una expiración de reserva que sucede horas después de su éxito. Se propone `GET /api/v1/inventario/reservas/{reservaId}/estado?order_id=...`, limitado a consumidores aprobados, que retorna estado persistido (`ACTIVA`, `CONSUMIDA`, `LIBERADA`, `EXPIRADA`), `expires_at` y vigencia efectiva calculada. `ACTIVA` con vencimiento cumplido se expone como persistida `ACTIVA` + vigencia `VENCIDA` y nunca habilita pago/consumo. G5/G6 deben homologar esquema, autorización, consistencia y reacción; la ruta no existe en OpenAPI canónico ni se declara implementada. El `ReservationExpirationService` existente materializa la transición, sin worker paralelo.

La cola `g6.promotions.commands` es una cola H5 nueva para comandos HTTP durables de Promotions; no forma parte de las 18 relaciones H4 heredadas y demuestra por qué ese conteo no es tope de colas H5. Solo el adaptador HTTP interno envía y el worker Promotions consume; G5 obtiene admisión/resultado por HTTP.

## Hallazgos de consumidor real G5

- `CuponesClient.java` publica sobre de `schema_version: 1` y no aporta `reservation_id`/`commercial_snapshot_ref` requeridos para consumo v2.
- La restauración no aporta `consumption_operation_id` y genera un `cancelled_at` nuevo si se invoca nuevamente.
- `CuponesClient.restaurar()` registra el fallo de publicación pero puede perder la intención; necesita outbox/reintento durable G5.
- `ConsumidorProductos.java` depende de `@RabbitListener` en `po.sales.q` y `CuponesClient` de `RabbitTemplate` en `po.commands.x`; los nombres son anteriores al contrato físico español, y la infraestructura externa no fue homologada plenamente.
- `ProductosClient.confirmar()` devuelve ACEPTADA por respuesta HTTP de admisión, no por resultado de consumo confirmado; G5 debe separar ambos estados.
- `MensajeInventario` no cubre explícitamente `inventory.reservation.rejected` en su máquina de resultados.
- Simulación activada por defecto en `application.yml`; no constituye E2E real.

## Reglas para homologación G5

1. G6 ofrece ruta/DTO OpenAPI, estados, error codes, semántica de reintentos y scopes documentados.
2. G5 acepta por escrito la nueva frontera, corrige versiones/campos y cambia consumer/backend sin perder estados de pedido.
3. G7 registra/concede los permisos específicos. No reutilizar `cupones:validar` para consumir/restaurar.
4. G5/G6 prueban pérdida de respuesta, replay idempotente, expiración después de confirmación, consumo, restauración y rechazados.
5. Solo entonces retirar el acceso AMQP directo histórico; conservar la trazabilidad de H4.

## Acuerdos a preservar

- G5 `order_id` textual opaco (`PED-...`); operaciones UUID deterministas, con `operation_id` original en restauración.
- La confirmación de reserva es previa a consumo de cupón; `202` no significa confirmación.
- G5 gobierna pedido, pago y cancelación. G6 no cobra ni cambia estados de pedido.
- La conciliación offline Retail tiene discrepancias documentadas entre G4/G5/G6; no resolverla mediante la ADR de broker.
