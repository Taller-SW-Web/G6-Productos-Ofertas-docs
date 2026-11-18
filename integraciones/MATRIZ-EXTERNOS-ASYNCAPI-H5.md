# Matriz de frontera externa H5 — AsyncAPI de G6 a HTTP

**Estado:** cuatro rutas externas incorporadas en OpenAPI H5 `0.7.0-rc.1` (`SEMIFINAL_G6`). La hipótesis `ACEPTACION_G5_ASUMIDA_PARA_PLANIFICACION` permite planificar trabajo interno compatible; homologación bilateral efectiva y grants G7 comprobados siguen pendientes.
**Trazabilidad de origen:** snapshot H4 `contratos/historico/h4/eventos/asyncapi.yaml` (`0.6.0-rc.4`, 40 mensajes). Frontera destino: OpenAPI H5 canónico `0.7.0-rc.1`, `SEMIFINAL_G6`, homologación G5/G7 pendiente; la mensajería externa directa por Service Bus queda excluida.

## Qué grupos realmente aparecen como productores/consumidores externos

| Grupo | Estado contractual verificado | Decisión H5 propuesta |
|---|---|---|
| G1 Marketplace | BFF consulta Gateway por HTTP; no es productor directo declarado del broker G6 | Mantener HTTP sin otorgar acceso a Service Bus |
| G2 Despacho | `consultarDatosFisicos` por HTTP, acuerdos H-G2/D-G2 | Mantener HTTP, sin cambio de mensajería |
| G3 Chatbot | ADR de integración sin eventos, consumo HTTP bajo demanda | Mantener HTTP |
| G4 Retail | Lecturas/operaciones HTTP; conciliación offline requiere resolver divergencia G4/G5/G6 | No inventar cola directa ni alterar el ownership offline |
| G5 M1 Ventas / M2 Postventa | 13 asignaciones H4 (2 comandos G5→G6 y 11 resultados G6→G5) se sustituyen durante transición | HTTPS/JWT por APIM/Gateway según `G5-G6-H5-REVISION-01`; las cuatro rutas están en la baseline semifinal bajo hipótesis de aceptación para planificación. M1 usa `modulo-ventas`; M2 `modulo-postventa`. Sin grants acreditados ni corte externo. |
| G7 Seguridad | Identidades/grants de cliente HTTP; no identificado como consumidor externo del bus G6 | Gestionar grants HTTP; no dar credenciales Basic |

Las referencias históricas `api-gateway/bff` se conservan en el inventario H4 y mantienen cobertura de transición pendiente de verificación. No constituyen prueba de handler o suscripción directa; no se incorpora un consumidor BFF ni G5 al Service Bus H5.

## Los 13 mensajes de `modulo-ventas`

| Tipo | Mensaje AsyncAPI H4 | Consumidor/operación HTTP H5 en baseline semifinal |
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
| G6→G5 | `inventory.reservation.expired` | `GET /api/v1/inventario/reservas/{reservaId}/estado?order_id=...` más conciliación durable de G5; consultar para siempre solo la operación inicial no detecta la transición tardía |
| G6→G5 | `inventory.consumption.completed` | mismo GET |
| G6→G5 | `inventory.consumption.rejected` | mismo GET |

**P0 semántico:** consultar solo la operación inicial puede NO informar una expiración posterior. La ruta `GET /api/v1/inventario/reservas/{reservaId}/estado?order_id=...` pertenece a OpenAPI H5 `SEMIFINAL_G6` y devuelve estado persistido (`ACTIVA`, `CONSUMIDA`, `LIBERADA`, `EXPIRADA`), `expires_at` y vigencia efectiva calculada. `ACTIVA` con vencimiento cumplido se representa `ACTIVA` + `VENCIDA`, sin permiso de pago/consumo. Decisión G6 para planificación conforme a `G5-G6-H5-REVISION-01`; homologación efectiva, grants y runtime no acreditados. La transición persistida continúa a cargo del mecanismo Inventory existente; el GET no crea worker ni modifica estado.

El GET no notifica espontáneamente a G5. En H5, G5 persiste la relación pedido-reserva e inicia seguimiento al recuperar por HTTP el resultado durable `COMPLETED` de la operación de creación; no depende de recibir el evento RabbitMQ H4 `inventory.reservation.created` después del corte. El barrido periódico/al reinicio incluye pedidos y reemplazos elegibles donde Inventory informa `ACTIVA` + `VENCIDA` **o** `EXPIRADA` persistida. `EXPIRADA` se excluye únicamente tras decisión de conciliación durable G5 o cuando el estado comercial G5 determine que la transición no corresponde. Una lectura exitosa por sí misma no marca conciliado: checkpoint/lease se cierra junto con la decisión G5 durable; un fallo antes del commit mantiene elegibilidad y reintenta. Clave idempotente por reserva+transición y serialización contra pago/anulación evitan doble efecto. La propuesta no fija duración de retención, frecuencia de conciliación ni deadline comercial; esos parámetros quedan pendientes de cierre y no bloquean el trabajo interno. **El mecanismo de conciliación no está implementado ni homologado**; G6 no administra estados de pedido.

Distinción comercial obligatoria: evento `inventory.reservation.created` o resultado de creación `COMPLETED` confirma que la reserva fue creada; no confirma consumo definitivo de stock. El consumo es la operación aparte `POST /api/v1/inventario/reservas/{reservaId}/confirmar`. Para Marketplace con cupón: reserva creada → verificar vigencia → consumir cupón y esperar éxito → procesar pago → confirmar consumo del stock y esperar resultado. No adelantar `/confirmar` al cupón o pago. Chatbot mantiene su acuerdo de consultas comerciales sin reservar ni confirmar stock. Reemplazo M1 crea su orden G5 separada, sin cobro; solicita consumo al sellar paquete y espera resultado antes del despacho; si la reserva vence antes, anula y, si procede conforme al contrato G5, crea orden/reserva nueva.

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
- La creación efectiva de la reserva es previa al consumo de cupón; `202` solo indica admisión. El consumo definitivo de stock vía `/confirmar` es posterior al pago en Marketplace con cupón; ambos significados de “confirmación” no deben mezclarse.
- G5 gobierna pedido, pago y cancelación. G6 no cobra ni cambia estados de pedido.
- La conciliación offline Retail tiene discrepancias documentadas entre G4/G5/G6; no resolverla mediante la ADR de broker.
