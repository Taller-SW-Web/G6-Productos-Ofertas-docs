# Contrato HTTP candidato H5 — operaciones asíncronas de cupones y estado de reserva

**Estado normativo G6:** operaciones incluidas en OpenAPI H5 `0.7.0-rc.3`, `APPROVED_G6` por el acta del 22/11/2026. La aceptación de G5 se asume solo para planificación (`ACEPTACION_G5_ASUMIDA_PARA_PLANIFICACION`); la homologación bilateral efectiva sigue pendiente de constancia. Grants G7 no comprobados, implementación/runtime por verificar y publicación externa/despliegue no realizados. No sustituye los snapshots OpenAPI/AsyncAPI H4 ni modifica sus fixtures.

Este documento conserva esquemas JSON Schema y ejemplos contractuales derivados de `G5-G6-H5-REVISION-01` (17/11/2026). Las operaciones están incorporadas a OpenAPI H5 `0.7.0-rc.3` y aprobadas por G6. La hipótesis de aceptación G5 permite planificar y preparar implementación compatible, pero no equivale a aceptación formal ni homologación. Los grants G7 y la implementación/runtime siguen pendientes; los scopes y allowlists son contrato G6 aprobado, no concesiones.

## Operaciones candidatas

| Método | Ruta candidata | Owner | Efecto/lectura | Cliente de servicio propuesto |
|---|---|---|---|---|
| POST | `/api/v1/cupones/consumos` | Promotions | Admite consumo durable, devuelve 202 | `modulo-ventas` tras allowlist y autorización G7 |
| POST | `/api/v1/cupones/restauraciones` | Promotions | Admite restauración durable, devuelve 202 | `modulo-ventas` (M1) según propuesta Axel; allowlist/grant G7 no acreditados |
| GET | `/api/v1/cupones/operaciones/{operationId}?order_id={orderId}` | Promotions | Resultado durable, sin ejecutar comandos | `modulo-ventas` (M1) según propuesta Axel; allowlist/grant G7 no acreditados |
| GET | `/api/v1/inventario/reservas/{reservaId}/estado?order_id={orderId}` | Inventory | Lectura de estado persistido y vigencia efectiva | `modulo-ventas` (M1); scope dedicado H5, grant G7 no acreditado |

`order_id` es texto opaco de G5. En ambas consultas es requerido y debe coincidir con el pedido persistido en la operación/reserva. Una reserva/operación ausente y una que no corresponde al pedido o cliente se responden con el mismo `404`, para no revelar existencia. `reservation_id` y `operation_id` UUID no son credenciales.

El GET H5 de estado de reserva utiliza el scope dedicado `inventario:reservas:estado:leer`; no reutiliza ni hereda `inventario:reservar` o `inventario:operaciones:leer`. Los scopes H5 de consumo, restauración y lectura de operación de cupón quedan definidos en el OpenAPI semifinal (`cupones:consumir`, `cupones:restaurar`, `cupones:operaciones:leer`) como propuesta G6 para G7. La allowlist acepta solo `modulo-ventas` para estas cuatro rutas. Grants y permisos efectivos no están comprobados.

## Seguridad y trazabilidad

- JWT de servicio validado en APIM/Gateway y nuevamente en el owner: firma, issuer, audiencia `api-productos`, `client_id`, scope y allowlist por operación. `producer` del envelope interno nunca autentica.
- `modulo-ventas` (G5 M1) es el cliente permitido por operación para estas cuatro rutas según la propuesta; `modulo-postventa` (M2) conserva su alcance de devoluciones y no recibe permisos para reservar/consumir stock de reemplazo. Aceptación formal y grants efectivos G7 siguen pendientes. No se entregan credenciales Service Bus.
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

Misma identidad y mismo contenido semántico: si es la primera admisión, `202` con snapshot `ACCEPTED`; si es un replay del POST, `200` con el snapshot durable vigente, sin nuevo efecto. La discrepancia D-05 queda resuelta para esta baseline: header ausente/malformado/UUID inválido → `400 VALIDACION`; `operation_id` ausente/malformado → `400 VALIDACION`; dos UUID válidos distintos → `409 IDEMPOTENCY_CONFLICT`; misma identidad con fingerprint distinto → `409 IDEMPOTENCY_CONFLICT`. La retención de idempotencia debe cubrir reintentos/reconciliación y no puede purgarse con Outbox pendiente o resultado ambiguo; plazo exacto sigue pendiente de cierre.

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
    "commercial_snapshot_ref": { "type": "string", "minLength": 1, "description": "Exactamente igual a order_id; no requiere hash ni tabla adicional." }
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

La propuesta HTTP y el comando interno AsyncAPI H5 exigen el `consumption_operation_id` del consumo original confirmado. El snapshot AsyncAPI H4 conserva su forma histórica transicional, byte a byte; no se altera H4. `cancelled_at` es el instante original de cancelación y debe permanecer idéntico en todos los reintentos, nunca regenerarse al reenviar.

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

## Estado vigente de reserva — operación en baseline semifinal H5

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

No se llama a `/confirmar` antes del consumo del cupón o del pago. El endpoint de estado en la baseline es una lectura puntual y no notifica por sí mismo expiraciones futuras; por eso la propuesta requiere una conciliación periódica durable dentro de G5 para pedidos y órdenes de reemplazo con reservas aún elegibles. La conciliación debe detectar tanto `ACTIVA` + `vigencia_efectiva=VENCIDA` como `EXPIRADA` persistida; el `ReservationExpirationService` existente puede persistir `EXPIRADA` entre barridos. G5 inicia el seguimiento al recuperar por HTTP el resultado durable `COMPLETED` de creación de reserva, sin depender del evento RabbitMQ H4 `inventory.reservation.created` después del corte H5. Un GET exitoso solo informa el estado observado y no cierra el seguimiento: G5 lo cierra únicamente después de persistir la decisión/transición comercial aplicable. G5 aplica sus transiciones existentes; G6 no administra estados de pedido. Véanse disparadores, elegibilidad, exclusiones, concurrencia, recuperación e hitos de homologación en la [ADR H5](../../arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md#reconciliación-durable-g5-ante-expiración-tardía--propuesta-pendiente). El mecanismo de conciliación no está implementado ni aceptado por G5.

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
| 400 | `VALIDACION` | UUID/header o body ausente o malformado; query `order_id` o JSON inválidos. Si header/body son UUID válidos pero distintos, responde 409. |
| 401 | `TOKEN_INVALIDO` | Token ausente, inválido, expirado o audiencia incorrecta |
| 403 | `SCOPE_INSUFICIENTE` | Identidad válida fuera del permiso/allowlist aprobados |
| 404 | `RESERVA_NO_ENCONTRADA` / `OPERACION_CUPON_NO_ENCONTRADA` | Reserva/operación ausente, ajena al pedido o no visible para el cliente autenticado; respuesta uniforme para evitar filtración. El segundo código ya figura en catálogo/OpenAPI semifinal y sigue sujeto a homologación. |
| 409 | `IDEMPOTENCY_CONFLICT` | Reuso de clave/operación con otra intención o fingerprint |
| 409 | `RESERVA_NO_ACTIVA` / `RESERVA_EXPIRADA` | Operación síncrona de Inventory que pierde carrera contra la expiración; una admisión asíncrona de cupón ya aceptada expone rechazo por resultado GET |
| 429 | `RATE_LIMIT_EXCEDIDO` | Limitación de Gateway efectiva para el tier/configuración elegida |
| 500 | `ERROR_INTERNO` | Fallo no controlado; sin incluir secretos/detalles internos |
| 503 | `SERVICIO_NO_DISPONIBLE` | Owner o dependencia SQL no puede aceptar/leer con consistencia requerida |

La tabla resume los errores incluidos en el OpenAPI semifinal y el catálogo. Su uso externo permanece sujeto a homologación formal. No añadir un 422 para un rechazo de negocio que puede quedar durable como `REJECTED`.

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

`OPERACION_CUPON_NO_ENCONTRADA` ya está incorporado al catálogo y al OpenAPI semifinal; su uso externo aún requiere homologación. Ningún error de esta especificación crea ni autoriza un scope G7.

## Consistencia, polling y expiración tardía

- GET de reserva consulta la fuente autoritativa de Inventory y compara `expires_at` con el reloj UTC del servidor en una lectura consistente. Si la transición persistida está atrasada, devuelve `ACTIVA` + `VENCIDA`; no espera al worker para deshabilitar pago/consumo.
- El worker existente `ReservationExpirationService` busca filas `ACTIVA` vencidas y ejecuta `expirarReservaDurable`; el GET no dispara otro timer/worker. Pago/consumo confirma de nuevo bajo lock y no confía en una lectura previa.
- G5 consulta estado de reserva tras recuperar un resultado tardío o timeout; si la vigencia no es `VIGENTE`, no cobra ni solicita consumo de cupón. El resultado de la operación de crear reserva no sustituye esta consulta actual.
- Polling de operación: `Retry-After: 2` segundos, backoff exponencial con jitter e intervalo máximo candidato de 30 segundos. No se define una duración numérica definitiva de retención, frecuencia de conciliación ni deadline comercial; son parámetros pendientes de cierre y no bloquean el trabajo interno autónomo. Un deadline acordado agotado deja el pedido pendiente/reconciliable, nunca permite inferir éxito ni generar otro `operation_id`.
- Si POST pierde respuesta, repetir la misma solicitud y `Idempotency-Key`; si estado pendiente, continuar GET con la misma operación; nunca crear otra identidad para descubrir el resultado.

## Estados y condiciones antes de homologar externamente y habilitar

1. OpenAPI H5 incorpora las cuatro rutas como `APPROVED_G6`; esto no acredita homologación formal G5 ni publicación externa.
2. G7 debe comprobar en tokens reales audiencia `api-productos`, `client_id`, scopes dedicados y allowlists; la hipótesis de aceptación no es grant.
3. Cerrar la duración numérica de retención, frecuencia de conciliación y deadline comercial, preservando operaciones pendientes o ambiguas.
4. Ejecutar pruebas provider/consumer, autorización positiva/negativa, carrera de vencimiento y pérdida/replay sin duplicación antes de activación o corte.
5. Implementación, infraestructura compartida, E2E, homologación bilateral, publicación externa y despliegue son estados independientes. No se declara realizado el corte ni el rollback.
