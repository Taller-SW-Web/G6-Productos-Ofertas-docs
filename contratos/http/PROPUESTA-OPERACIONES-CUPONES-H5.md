# Contrato HTTP candidato H5 — operaciones asíncronas de cupones y estado de reserva

**Estado:** `PROPUESTA_NO_PUBLICADA_EN_OPENAPI`; pendiente de revisión interna G6, homologación G5 y autorización G7. Sin implementación H5 acreditada. No sustituye OpenAPI/AsyncAPI H4 ni modifica sus fixtures.

Este documento contiene esquemas JSON Schema candidatos y ejemplos verificables para discusión. Las rutas no existen en OpenAPI vigente. Los nombres de scope pendientes son requisitos funcionales, no concesiones.

## Operaciones candidatas

| Método | Ruta candidata | Owner | Efecto/lectura | Cliente de servicio propuesto |
|---|---|---|---|---|
| POST | `/api/v1/cupones/consumos` | Promotions | Admite consumo durable, devuelve 202 | `modulo-ventas` tras allowlist y autorización G7 |
| POST | `/api/v1/cupones/restauraciones` | Promotions | Admite restauración durable, devuelve 202 | `modulo-ventas` tras allowlist y autorización G7 |
| GET | `/api/v1/cupones/operaciones/{operationId}?order_id={orderId}` | Promotions | Resultado durable, sin ejecutar comandos | `modulo-ventas` tras allowlist y autorización G7 |
| GET | `/api/v1/inventario/reservas/{reservaId}/estado?order_id={orderId}` | Inventory | Lectura de estado persistido y vigencia efectiva | Consumidor aprobado explícitamente; inicialmente se propone solo `modulo-ventas` |

`order_id` es texto opaco de G5. En ambas consultas es requerido y debe coincidir con el pedido persistido en la operación/reserva. Una reserva/operación ausente y una que no corresponde al pedido o cliente se responden con el mismo `404`, para no revelar existencia. `reservation_id` y `operation_id` UUID no son credenciales.

El scope histórico `inventario:operaciones:leer` está documentado para consultar operaciones de Inventory. Su suficiencia para esta ruta debe confirmarse con G7; la ruta no hereda una concesión por aparecer en esta propuesta. Los scopes de consumo, restauración y lectura de resultado de cupones deben definirse/autorizarse con G7. La allowlist acepta únicamente consumidores externos aprobados; no se amplía por conveniencia técnica.

## Seguridad y trazabilidad

- JWT de servicio validado en APIM/Gateway y nuevamente en el owner: firma, issuer, audiencia `api-productos`, `client_id`, scope y allowlist por operación. `producer` del envelope interno nunca autentica.
- `modulo-ventas` es la única identidad externa propuesta para estas operaciones de G5; aceptación y permiso G7 siguen pendientes. No se entregan credenciales Service Bus.
- El backend compara `order_id` con el valor dueño asociado a la reserva/operación y comprueba que el cliente autenticado está autorizado para la operación. Desajuste y no existencia responden igual para evitar enumeración.
- El `customer_ref` funcional no reemplaza `client_id` y no autoriza acceso. No se devuelve información de otro pedido, otras campañas ni payloads internos.
- `X-Correlation-ID` se propaga por HTTP, operación, Outbox, cola interna, Inbox y respuesta; no forma parte del fingerprint idempotente.

## Admisión, idempotencia y cola interna

El body contiene `operation_id` UUID y el header requerido `Idempotency-Key` debe contener exactamente el mismo UUID. Esta regla candidata elimina ambigüedad de precedencia. G5 conserva ese identificador en todos los reintentos de la misma intención. El fingerprint cubre el body funcional normalizado y la identidad de cliente; excluye headers de transporte/traza.

1. Promotions valida autenticación, allowlist, esquema, idempotencia, pedido y precondiciones autoritativamente verificables. En consumo, exige `reservation_id` y `commercial_snapshot_ref`.
2. En una transacción local escribe la operación `ACCEPTED`, su fingerprint/clave idempotente y la intención Outbox. Devuelve `202 Accepted` únicamente después del commit; Service Bus puede estar caído.
3. El relay envía a la cola interna candidata `g6.promotions.commands`; no ofrece acceso AMQP a G5. Las copias/reintentos mantienen su identidad de mensaje y no se marcan confirmados ante timeout ambiguo.
4. El worker exclusivo de operaciones Promotions usa Inbox por `message_id`, deduplica efectos por `operation_id`, persiste efecto, estado y resultado terminal en la transacción de Promotions, y después completa el mensaje.
5. El GET consulta el estado durable; no publica, consume ni restaura otra vez.

Misma identidad y mismo contenido semántico: si es la primera admisión, `202` con snapshot `ACCEPTED`; si es un replay del POST, `200` con el snapshot vigente de la operación, sin nuevo efecto. Misma clave/`operation_id` con contenido o intención distinto, o header/body distintos: `409 IDEMPOTENCY_CONFLICT`. La retención de idempotencia debe cubrir la ventana de reintentos/reconciliación y no puede purgarse con Outbox pendiente o resultado ambiguo; plazo exacto requiere acuerdo antes del OpenAPI definitivo.

Los rechazos de negocio producidos por procesamiento se guardan como `REJECTED` y se consultan por GET; un `202` no significa cupón consumido. Los errores de autenticación, formato, colisión o indisponibilidad síncronos no crean una admisión durable.

### Request JSON Schema candidato: `CouponConsumptionRequest`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://g6.invalid/proposals/h5/CouponConsumptionRequest.json",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "operation_id": { "type": "string", "format": "uuid" },
    "order_id": { "type": "string", "minLength": 1 },
    "coupon_code": { "type": "string", "minLength": 1 },
    "channel_id": { "type": "string", "enum": ["MARKETPLACE", "CHATBOT", "RETAIL"] },
    "customer_ref": { "oneOf": [{ "type": "string", "format": "uuid" }, { "type": "null" }] },
    "effective_at": { "type": "string", "format": "date-time" },
    "reservation_id": { "type": "string", "format": "uuid" },
    "commercial_snapshot_ref": { "type": "string", "minLength": 1 }
  },
  "required": ["operation_id", "order_id", "coupon_code", "channel_id", "effective_at", "reservation_id", "commercial_snapshot_ref"]
}
```

Este body conserva los campos funcionales requeridos por `CouponConsumptionRequestedData` AsyncAPI v2; `customer_ref` continúa siendo opcional/nulo en ese contrato.

### Request JSON Schema candidato: `CouponRestorationRequest`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://g6.invalid/proposals/h5/CouponRestorationRequest.json",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "operation_id": { "type": "string", "format": "uuid" },
    "order_id": { "type": "string", "minLength": 1 },
    "consumption_operation_id": { "type": "string", "format": "uuid" },
    "cancellation_reason": { "type": "string", "minLength": 1 },
    "cancelled_at": { "type": "string", "format": "date-time" }
  },
  "required": ["operation_id", "order_id", "consumption_operation_id", "cancellation_reason", "cancelled_at"]
}
```

La propuesta HTTP exige el `consumption_operation_id` del consumo confirmado que se restaura. El AsyncAPI v2 vigente conserva una forma transicional nullable/opcional; endurecerlo para H5 necesita revisión de compatibilidad y homologación G5, no cambia el contrato H4 aquí. `cancelled_at` es el instante original de cancelación y debe permanecer idéntico en todos los reintentos, nunca regenerarse al reenviar.

## Respuesta de admisión y consulta de operación

Primera admisión: `202 Accepted`, `Location` apunta al GET de operación con el mismo `order_id`, `Retry-After: 2`. Replay: `200 OK` y mismo recurso durable. Los resultados finales se obtienen por GET.

### JSON Schema candidato: `CouponOperationSnapshot`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://g6.invalid/proposals/h5/CouponOperationSnapshot.json",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "operation_id": { "type": "string", "format": "uuid" },
    "operation_type": { "type": "string", "enum": ["CONSUMIR_CUPON", "RESTAURAR_CUPON"] },
    "status": { "type": "string", "enum": ["ACCEPTED", "PROCESSING", "COMPLETED", "REJECTED"] },
    "order_id": { "type": "string", "minLength": 1 },
    "accepted_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "completed_at": { "oneOf": [{ "type": "string", "format": "date-time" }, { "type": "null" }] },
    "result": {
      "oneOf": [
        { "type": "null" },
        {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "order_id": { "type": "string", "minLength": 1 },
            "result_code": { "oneOf": [{ "type": "string", "minLength": 1 }, { "type": "null" }] },
            "consumption_id": { "oneOf": [{ "type": "string", "format": "uuid" }, { "type": "null" }] },
            "reservation_id": { "type": "string", "format": "uuid" },
            "commercial_snapshot_ref": { "type": "string", "minLength": 1 },
            "coupon_code": { "type": "string", "minLength": 1 },
            "consumption_operation_id": { "oneOf": [{ "type": "string", "format": "uuid" }, { "type": "null" }] },
            "restored": { "type": "boolean" },
            "outcome": { "type": "string", "enum": ["RESTORED", "POLICY_KEEPS_CONSUMPTION", "NO_CONSUMPTION"] },
            "decided_at": { "type": "string", "format": "date-time" },
            "completed_at": { "type": "string", "format": "date-time" }
          },
          "required": []
        }
      ]
    }
  },
  "required": ["operation_id", "operation_type", "status", "order_id", "accepted_at", "updated_at", "completed_at", "result"],
  "allOf": [
    {
      "if": { "properties": { "status": { "enum": ["ACCEPTED", "PROCESSING"] } }, "required": ["status"] },
      "then": { "properties": { "completed_at": { "type": "null" }, "result": { "type": "null" } } }
    },
    {
      "if": { "properties": { "status": { "enum": ["COMPLETED", "REJECTED"] } }, "required": ["status"] },
      "then": { "properties": { "completed_at": { "type": "string", "format": "date-time" }, "result": { "type": "object" } } }
    },
    {
      "if": { "properties": { "status": { "const": "REJECTED" } }, "required": ["status"] },
      "then": { "properties": { "result": { "properties": { "result_code": { "type": "string", "minLength": 1, "pattern": "\\S" } }, "required": ["result_code"] } } }
    },
    {
      "if": { "properties": { "operation_type": { "const": "CONSUMIR_CUPON" }, "status": { "enum": ["COMPLETED", "REJECTED"] } }, "required": ["operation_type", "status"] },
      "then": { "properties": { "result": { "required": ["order_id", "coupon_code", "reservation_id", "commercial_snapshot_ref", "decided_at"] } } }
    },
    {
      "if": { "properties": { "operation_type": { "const": "RESTAURAR_CUPON" }, "status": { "const": "COMPLETED" } }, "required": ["operation_type", "status"] },
      "then": { "properties": { "result": { "properties": { "consumption_operation_id": { "type": "string", "format": "uuid" } }, "required": ["order_id", "consumption_operation_id", "restored", "outcome", "completed_at"] } } }
    },
    {
      "if": { "properties": { "operation_type": { "const": "RESTAURAR_CUPON" }, "status": { "const": "REJECTED" } }, "required": ["operation_type", "status"] },
      "then": { "properties": { "result": { "properties": { "consumption_operation_id": { "type": "string", "format": "uuid" } }, "required": ["order_id", "consumption_operation_id", "completed_at"] } } }
    }
  ]
}
```

Consistencia adicional: `ACCEPTED`/`PROCESSING` usan `completed_at: null` y `result: null`; `COMPLETED`/`REJECTED` requieren resultado y `completed_at`. `REJECTED` requiere `result_code` no vacío; `COMPLETED` de consumo conserva `reservation_id`, `commercial_snapshot_ref` y `decided_at`, y de restauración conserva `consumption_operation_id`, `restored`, `outcome` y `completed_at`. El consumidor interpreta esos campos por `operation_type`; no deriva el estado del pedido ni del pago desde Promotions.

Consulta GET pendiente devuelve `200` con estado vigente, no `202` indefinido. El `404` de operación no existente o ajena usa el mismo código/shape. El GET no ejecuta el comando.

## Estado vigente de reserva — ruta candidata

`GET /api/v1/inventario/reservas/{reservaId}/estado?order_id={orderId}` devuelve lectura del estado persistido más la vigencia efectiva al `observed_at` del servidor. `estado_persistido` usa únicamente `ACTIVA`, `CONSUMIDA`, `LIBERADA`, `EXPIRADA`; `expires_at` siempre se devuelve. Para `ACTIVA`, `expires_at <= observed_at` significa `vigencia_efectiva: VENCIDA`, `permite_pago: false` y `permite_consumo_cupon: false`, aunque el ciclo persistido aún no haya guardado la transición `EXPIRADA`. La igualdad se considera vencida.

El GET es de solo lectura. `ReservationExpirationService` existente y su worker actual siguen siendo los mecanismos de transición persistida; no se crea un worker de expiración paralelo ni se afirma que esta propuesta esté implementada. La autorización de pago/consumo y las mutaciones vuelven a comprobar estado y `expires_at` dentro de Inventory de forma atómica; una respuesta GET es una observación y no una reserva de vigencia futura.

`permite_pago` es una precondición de Inventory sobre la reserva, no una decisión de pago ni una orden de cobro: G5 conserva en todo momento el ownership y la decisión comercial del pedido/pago. G5 debe tratar `false` como bloqueo y corroborar el estado al confirmar consumo.

### Secuencia comercial: reserva creada no es stock consumido

La creación efectiva de una reserva se acredita por `inventory.reservation.created` o por el resultado durable de la operación de reserva en `COMPLETED`, con `reservation_id` y `expires_at`. `202 Accepted` solo acredita admisión; no acredita que la reserva exista. Esta creación tampoco equivale al consumo definitivo de unidades, que es la mutación separada `POST /api/v1/inventario/reservas/{reservaId}/confirmar` (admisión `202`, resultado definitivo por evento/operación durable).

Para checkout de Marketplace con cupón, la secuencia candidata, preservando ownership G5, es:

1. Crear pedido conforme al flujo G5 y esperar la creación efectiva de la reserva.
2. Consultar/validar que la reserva siga vigente (`ACTIVA` y `expires_at > observed_at`).
3. Admitir consumo del cupón; esperar resultado terminal `COMPLETED`. Si se rechaza o no puede confirmarse el éxito, no procesar el pago.
4. Procesar el pago mediante el flujo de G5.
5. Tras pago exitoso, solicitar `POST /api/v1/inventario/reservas/{reservaId}/confirmar` y esperar su resultado durable de consumo definitivo. Si pago no completado/anulación antes de consumir stock, seguir la liberación y restauración de cupón existentes cuando correspondan.

No se llama a `/confirmar` antes del consumo del cupón o del pago. El endpoint propuesto de estado es una lectura puntual y no notifica por sí mismo expiraciones futuras; por eso la propuesta requiere una conciliación periódica durable dentro de G5 para pedidos y órdenes de reemplazo con reservas activas. Esa tarea solo consulta Inventory y aplica transiciones ya existentes del workflow G5; G6 no administra estados de pedido. Véanse disparadores, exclusiones, concurrencia, recuperación e hitos de homologación en la [ADR H5](../../arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md#reconciliación-durable-g5-ante-expiración-tardía--propuesta-pendiente). El mecanismo de conciliación no está implementado ni aceptado por G5.

Variantes ya documentadas se mantienen: Chatbot conserva su integración actual de consultas comerciales (no crea reservas ni confirma stock); una orden de reemplazo es orden G5 independiente y sin cobro, M1 concilia su reserva por separado, al sellar el paquete solicita el consumo definitivo y espera su resultado antes de despacho. Si vence antes, M1 anula mediante su transición existente y puede abrir otra orden/reserva conforme a su regla vigente. La propuesta H5 no agrega comportamiento a esos flujos sin homologación.

### JSON Schema candidato: `ReservationStatusSnapshot`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://g6.invalid/proposals/h5/ReservationStatusSnapshot.json",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "reservation_id": { "type": "string", "format": "uuid" },
    "order_id": { "type": "string", "minLength": 1 },
    "estado_persistido": { "type": "string", "enum": ["ACTIVA", "CONSUMIDA", "LIBERADA", "EXPIRADA"] },
    "expires_at": { "type": "string", "format": "date-time" },
    "observed_at": { "type": "string", "format": "date-time" },
    "vigencia_efectiva": { "type": "string", "enum": ["VIGENTE", "VENCIDA", "NO_APLICA"] },
    "permite_pago": { "type": "boolean" },
    "permite_consumo_cupon": { "type": "boolean" }
  },
  "required": ["reservation_id", "order_id", "estado_persistido", "expires_at", "observed_at", "vigencia_efectiva", "permite_pago", "permite_consumo_cupon"]
}
```

Ejemplo crítico de operación atrasada: `estado_persistido=ACTIVA`, `expires_at=2026-11-13T10:00:00Z`, `observed_at=2026-11-13T10:01:00Z`, `vigencia_efectiva=VENCIDA`, ambos permisos `false`. El API no maquilla el estado persistido como `EXPIRADA`; explica por separado la vigencia efectiva. Para estados terminales se usa `vigencia_efectiva=NO_APLICA` y ambos permisos son `false`. Solo `ACTIVA` con `expires_at > observed_at` produce `VIGENTE` y permite proceder a la siguiente validación atómica de negocio.

### Errores HTTP candidatos

Los errores usan el shape Problem Details del contrato HTTP vigente (`type`, `title`, `status`, `code`, `correlationId`); códigos existentes reutilizados cuando su semántica coincide:

| HTTP | `code` | Uso propuesto |
|---:|---|---|
| 400 | `VALIDACION` | UUID, query `order_id`, JSON, `Idempotency-Key` o igualdad header/body inválidos |
| 401 | `TOKEN_INVALIDO` | Token ausente, inválido, expirado o audiencia incorrecta |
| 403 | `SCOPE_INSUFICIENTE` | Identidad válida fuera del permiso/allowlist aprobados |
| 404 | `RESERVA_NO_ENCONTRADA` / `OPERACION_CUPON_NO_ENCONTRADA` (segundo código candidato) | Reserva/operación ausente o pedido/cliente no asociado; respuesta uniforme para evitar filtración. `OPERACION_CUPON_NO_ENCONTRADA` requiere aprobación y alta en catálogo antes de publicar |
| 409 | `IDEMPOTENCY_CONFLICT` | Reuso de clave/operación con otra intención o fingerprint |
| 409 | `RESERVA_NO_ACTIVA` / `RESERVA_EXPIRADA` | Operación síncrona de Inventory que pierde carrera contra la expiración; una admisión asíncrona de cupón ya aceptada expone rechazo por resultado GET |
| 429 | `RATE_LIMIT_EXCEDIDO` | Limitación de Gateway efectiva para el tier/configuración elegida |
| 500 | `ERROR_INTERNO` | Fallo no controlado; sin incluir secretos/detalles internos |
| 503 | `SERVICIO_NO_DISPONIBLE` | Owner o dependencia SQL no puede aceptar/leer con consistencia requerida |

La lista es una propuesta derivada del catálogo de errores; registrar en el catálogo/OpenAPI solo tras aprobación. No añadir un 422 para un rechazo de negocio que ya puede quedar durable como `REJECTED`.

### JSON Schema candidato: `CouponApiProblem`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://g6.invalid/proposals/h5/CouponApiProblem.json",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "type": { "type": "string", "format": "uri-reference" },
    "title": { "type": "string", "minLength": 1 },
    "status": { "type": "integer", "minimum": 400, "maximum": 599 },
    "code": { "type": "string", "enum": ["VALIDACION", "TOKEN_INVALIDO", "SCOPE_INSUFICIENTE", "RESERVA_NO_ENCONTRADA", "OPERACION_CUPON_NO_ENCONTRADA", "IDEMPOTENCY_CONFLICT", "RESERVA_NO_ACTIVA", "RESERVA_EXPIRADA", "RATE_LIMIT_EXCEDIDO", "ERROR_INTERNO", "SERVICIO_NO_DISPONIBLE"] },
    "correlationId": { "type": "string", "minLength": 1 }
  },
  "required": ["type", "title", "status", "code", "correlationId"]
}
```

`OPERACION_CUPON_NO_ENCONTRADA` es un identificador propuesto, no un código hoy agregado al catálogo normativo. Ningún error de esta especificación crea ni autoriza un scope G7.

## Consistencia, polling y expiración tardía

- GET de reserva consulta la fuente autoritativa de Inventory y compara `expires_at` con el reloj UTC del servidor en una lectura consistente. Si la transición persistida está atrasada, devuelve `ACTIVA` + `VENCIDA`; no espera al worker para deshabilitar pago/consumo.
- El worker existente `ReservationExpirationService` busca filas `ACTIVA` vencidas y ejecuta `expirarReservaDurable`; el GET no dispara otro timer/worker. Pago/consumo confirma de nuevo bajo lock y no confía en una lectura previa.
- G5 consulta estado de reserva tras recuperar un resultado tardío o timeout; si la vigencia no es `VIGENTE`, no cobra ni solicita consumo de cupón. El resultado de la operación de crear reserva no sustituye esta consulta actual.
- Polling de operación: obedecer `Retry-After`, iniciar en 2 s, backoff exponencial con jitter hasta un máximo propuesto de 30 s; detener al deadline de flujo acordado. Deadline agotado deja el pedido pendiente/reconciliable, nunca permite inferir éxito ni generar nuevo `operation_id`. Parámetros requieren homologación G5.
- Si POST pierde respuesta, repetir la misma solicitud y `Idempotency-Key`; si estado pendiente, continuar GET con la misma operación; nunca crear otra identidad para descubrir el resultado.

## Gates antes de publicar en OpenAPI

1. Homologar con G5 métodos, schemas, `order_id`, comparación vigente de reserva, estados, polling y comportamiento ante expiración tardía.
2. Obtener de G7 la allowlist y permisos efectivos por cliente/operación; confirmar si el scope H4 `inventario:operaciones:leer` cubre el GET de reserva.
3. Acordar retención de claves y resultados para replay/reconciliación.
4. Ejecutar pruebas provider/consumer, autorización positiva/negativa, carrera entre consulta y vencimiento, y caída/replay sin duplicación.
5. Solo después preparar un candidato OpenAPI H5 versionado independiente. Esta propuesta no cambia endpoints canónicos H4 ni declara ruta, implementación o homologación.
