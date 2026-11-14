# SPEC-005 — Gestión de cupones de descuento

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** HU [HU-005](../hu/HU-005-gestion-cupones-descuento.md) | Wireframe [WF-005](../../ux/wireframes/flows/WF-005-gestion-cupones-descuento.md)
**Contratos canónicos:** [OpenAPI](../../contratos/http/openapi.yaml) | [AsyncAPI](../../contratos/eventos/asyncapi.yaml)
**Decisiones:** [ADR de los cuatro bloqueantes](../../arquitectura/decisiones/ADR-DEC-F-BLOQUEANTES.md) | [Alineación con Ventas](../../integraciones/ALINEACION_VENTAS.md)

---

## 1. Objetivo

Administrar cupones asociados a promociones y controlar validación, consumo y restitución sin trasladar la autoridad sobre el pedido a Promociones.

**Estado de evidencia:** las decisiones contractuales de `0.6.0-rc.1` están adoptadas en G6 como objetivo, pero siguen pendientes las pruebas de integración y la implementación de los consumidores/productores reales. La migración `datos/promotions/migrations/0004_coupon_idempotency_receipts.sql` ya fue aplicada y su validación SQL en Supabase pasó; eso **no acredita** handlers, publicaciones RabbitMQ ni integración de extremo a extremo.

## 2. Identidad del cliente

La identidad intermodular del comprador se representa como:

```text
customer_ref = UUID del usuario autenticado (claim sub del JWT de usuario emitido por Seguridad)
```

- El canal transmite a Ventas el UUID verificado del comprador según su contrato; Ventas persiste esa misma referencia para el pedido y la comunica a Promociones cuando corresponda.
- El `sub` de un **token de servicio** identifica al módulo, **no** al comprador; nunca se debe reutilizar como `customer_ref`.
- `customer_ref = null` solo se admite cuando la política del cupón **no** requiere identificación para controlar usos por cliente.
- Si el cupón impone `max_usos_por_cliente` y no se conoce la identidad del comprador, el resultado debe reflejar `CUSTOMER_REF_REQUERIDO` conforme al contrato aplicable.

La identidad del emisor del comando (`client_id`, por ejemplo `modulo-ventas`) y la del comprador (`customer_ref`) son campos conceptualmente distintos; el servicio verifica y registra al emisor autenticado sin atribuirle la identidad del cliente.

## 3. Validación de cupones (sin efectos secundarios)

```http
POST /api/v1/cupones/validar
```

La validación:

- comprueba existencia, estado, vigencia, alcance y límites;
- evalúa la aplicabilidad y el beneficio;
- **no consume ni reserva usos**;
- devuelve un resultado de aplicabilidad, incluido el motivo de no aplicación, con la semántica definida en OpenAPI.

Una validación positiva no garantiza conservar el último uso disponible. El consumo posterior revalida sus invariantes y no se basa únicamente en una validación previa o en una referencia comercial.

## 4. Consumo de cupones

### 4.1. Secuencia y precondiciones

```text
Ventas crea el pedido CREADO
-> Inventario confirma efectivamente la reserva (no basta HTTP 202)
-> Ventas dispone de snapshot comercial durable
-> promotions.coupon.consumption.requested
-> promotions.coupon.consumption.completed | promotions.coupon.consumption.rejected
-> solo completed permite continuar al intento de pago conforme al flujo de G5
```

El mensaje `promotions.coupon.consumption.requested` de AsyncAPI v2 tiene:

- **Sobre:** `message_id` (entrega), `schema_version = 2`, `operation_id` UUID (identidad del comando), `causation_id` no vacío y datos de correlación; su emisor es `modulo-ventas`.
- **Datos obligatorios:** `order_id` (cadena opaca de Ventas), `coupon_code`, `channel_id`, `reservation_id` (UUID de una reserva efectivamente confirmada), `commercial_snapshot_ref` (referencia durable) y `effective_at`.
- **Dato opcional/anulable:** `customer_ref` UUID o `null`, sujeto a la regla de identidad por cliente indicada en el apartado 2.

`commercial_snapshot_ref` lo provee Ventas para correlacionar las condiciones comerciales del pedido. **No** sustituye las comprobaciones autoritativas de Promociones ni prueba por sí solo que Inventario haya confirmado la reserva. Promociones no convierte una mera respuesta `202 Accepted` en reserva exitosa.

### 4.2. Dos niveles distintos de idempotencia

**Invariante de consumo de negocio:**

```text
(order_id, cupon_id) = como máximo un consumo del cupón para ese pedido
```

Esta unicidad está protegida por `uq_coupon_uses_order_coupon` en el modelo de datos. No equivale a la clave de idempotencia del comando.

**Idempotencia de comando:** la migración `0004` incorpora `promotions.coupon_command_receipts`, cuyo identificador es `operation_id` UUID y cuyo registro contiene `order_id`, `source_client_id`, `intention` (`CONSUMIR`/`RESTAURAR`), `request_fingerprint`, payload y resultado. El handler debe aplicar las siguientes reglas **en una transacción**:

1. La misma operación, emisor, intención y contenido semántico devuelve el **mismo resultado persistido**, sin repetir consumo, restauración ni publicación efectiva.
2. Reutilizar `operation_id` con emisor, intención o contenido semántico incompatible constituye `IDEMPOTENCY_CONFLICT`, sin efectos secundarios adicionales.
3. Una **nueva** `operation_id` no habilita a consumir dos veces el mismo `(order_id, cupon_id)`.
4. `message_id` identifica cada entrega de mensajería y sirve para deduplicación de transporte; no reemplaza `operation_id`.
5. El consumo/rechazo final, el receipt y su outbox deben coordinarse transaccionalmente; el SQL de la tabla **no implementa por sí solo** la lógica de los handlers.

El servicio debe revalidar atómicamente el cupo global, el cupo por cliente, el cupón elegido y la coherencia con el pedido. Dos pedidos que compiten por el último uso deben producir **como máximo un consumo exitoso**.

### 4.3. Resultado definitivo

- `promotions.coupon.consumption.completed`: consumo confirmado; permite a Ventas continuar el flujo previsto.
- `promotions.coupon.consumption.rejected`: rechazo definitivo de negocio; **no** autoriza seguir cobrando con ese snapshot.
- Los eventos v2 mantienen `operation_id` UUID, `causation_id` no vacío y `schema_version = 2` en el sobre. El rechazo debe identificar una causa de negocio estable (`result_code` obligatorio y no vacío en el esquema corregido de la entrega 02).
- Un error técnico de transporte o un mensaje en DLQ no equivale a un rechazo de negocio ni a una confirmación de consumo.

**Compatibilidad:** el esquema de rechazo específico es una corrección del AsyncAPI candidato `0.6.0-rc.1`, no una afirmación de que los consumidores de G5 ya lo procesen. Publicar v2 frente a consumidores v1 requiere adaptación y acuerdo explícitos.

## 5. Restitución de cupones

### 5.1. Disparador y contrato

Cuando Ventas conoce que el pedido tuvo un **consumo confirmado** y ocurre una cancelación/fallo aplicable, solicita:

```text
promotions.coupon.restoration.requested
```

El payload de AsyncAPI exige `order_id`, `cancellation_reason` y `cancelled_at`; permite además `consumption_operation_id` como **opcional y anulable**, de tipo UUID cuando se informa. El sobre v2 exige identidad y causalidad igual que el del consumo.

**Decisión pendiente con G5:** no hacer obligatorio `consumption_operation_id` sin acuerdo intermodular y actualización versionada del contrato. Si no llega, Promociones solo puede usar una correlación alternativa **inequívoca** con un consumo previo persistido del mismo pedido; un caso ambiguo no se debe restaurar por suposición. Esta regla describe el tratamiento seguro del contrato actual, no acredita que el backend ya disponga de dicha correlación.

### 5.2. Política y resultados

Políticas del cupón:

```text
RESTAURAR_EN_CANCELACION
NO_RESTAURAR
```

Los resultados funcionales de `promotions.coupon.restoration.completed` son:

```text
RESTORED
POLICY_KEEPS_CONSUMPTION
NO_CONSUMPTION
```

- `RESTORED`: se realizó la restitución admitida por la política, una sola vez.
- `POLICY_KEEPS_CONSUMPTION`: la política no permite restituir; no se devuelve capacidad consumida.
- `NO_CONSUMPTION`: no existía un consumo previo aplicable; no se incrementa capacidad.
- `promotions.coupon.restoration.rejected` es **distinto** de los tres resultados anteriores: representa rechazo definitivo con un `result_code` de negocio explícito en el esquema específico de la entrega 02.

La restitución es idempotente tanto frente a reentregas de mensajes como frente a reintentos del mismo comando. Ninguna solicitud de restauración debe crear un uso inexistente ni aumentar cupos si el consumo previo no existió. Promociones **no** determina el estado del pago, la anulación, el pedido ni los reembolsos.

## 6. Administración del código y límites

El código de cupón se normaliza eliminando espacios en los extremos y convirtiendo letras ASCII a mayúsculas; solo admite letras ASCII, números, guion y guion bajo. La unicidad se comprueba **después** de normalizar y excluye el propio registro al editar. El cliente normaliza antes de enviar y el servicio aplica la misma regla.

- Los límites opcionales vacíos se representan como `null` (**Sin límite**); si se informan, son enteros positivos.
- El monto mínimo opcional vacío se representa como `null`; si se informa, debe ser mayor que cero.
- Un guardado inválido conserva el formulario y no comunica éxito.
- Crear, editar, activar y desactivar son operaciones administrativas; la UI no ofrece controles para consumir/restaurar cupones manualmente. Tales cambios no borran registros de uso existentes.

## 7. Fuera de alcance y dependencias

Este microservicio no procesa pagos, reembolsos ni decide el estado del pedido. Tampoco es propietario de las reservas de Inventario ni debe consultar/modificar directamente las tablas autoritativas de Ventas o Inventario: la verificación de precondiciones se resuelve mediante contratos entre servicios.

**Pendiente para integración real:** acuerdo G5 sobre confirmación de reserva antes de consumir, tratamiento del `201` externo y correlación de restauraciones; compatibilidad y despliegue de eventos v2; implementación del handler/outbox con replay seguro y pruebas concurrentes. La validación SQL de la migración `0004` no sustituye esas evidencias.

## Addendum contractual 0.6.0-rc.1 — Cuatro bloqueantes G6

**Decisión interna aprobada; objetivo `0.6.0-rc.1` no publicado como integración funcional.** Las migraciones `inventory 0002` y `promotions 0004` están aplicadas en Supabase y superaron los validadores SQL correspondientes; el backend y los eventos reales siguen pendientes de prueba.

- **B1:** `order_id` es referencia opaca textual de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID ni intercambiar las identidades de operación y mensaje.
- **B2:** las operaciones de Inventario `POST /inventario/reservas`, `/confirmar` y `/liberar` devuelven `202` solo cuando admiten el comando. El éxito o rechazo definitivo se recupera de la operación/evento; `inventory.reservation.rejected` expresa rechazo posterior a la admisión.
- **B3 / D-INV-01:** no sumar saldos de ubicaciones independientes sin política de cumplimiento realizable. El endpoint `POST /inventario/disponibilidad/comercial/verificar` es una consulta sin efectos; la ausencia/ambigüedad de mapeo de cumplimiento se expresa como `INDETERMINADO`, no como una promesa de stock.
- **B4:** consumo de cupón **después de reserva confirmada** y snapshot comercial durable; `reservation_id` y `commercial_snapshot_ref` viajan en el comando. `operation_id` + fingerprint gobiernan replay/conflictos y `(order_id, cupon_id)` impide doble consumo. Restauración solo para consumos previos, con política y resultado tipado.
- La misma identidad/operación/payload semántico devuelve igual resultado sin efectos nuevos; reutilizar identidad con otra intención/payload genera `IDEMPOTENCY_CONFLICT`. Cada entrega tiene su propio `message_id` para deduplicación de transporte.
- Las transiciones de pago, expiración y liberación se coordinan con Ventas e Inventario, serializadas por reserva y respetando `expires_at`; no se transforman señales `202` ni verificaciones comerciales en reservas confirmadas.
- Los nuevos endpoints `GET /inventario/operaciones/{operationId}` (solo Ventas; scope `inventario:operaciones:leer`) y `POST /inventario/disponibilidad/comercial/verificar` permanecen provisionales. El scope nuevo necesita registro con G7.
- Los cambios incompatibles respecto a v1/`0.5.0` requieren adaptadores, pruebas de conformidad y acuerdo con los módulos consumidores antes de publicar v2.

**Precondición de cupón:** `reservation_id` debe referir una reserva realmente confirmada del pedido. `commercial_snapshot_ref` es una referencia durable producida por Ventas; no sustituye la revalidación de reglas propias de Promociones. Una evaluación no consume usos, y una restauración no precede a un consumo exitoso.

> **Integración G1 Marketplace H4 (2026-10-20):** G6 aceptó y comunicó M-01–M-09 (`ACEPTADO_G6_COMUNICADO_G1`). Esta SPEC gobierna reglas funcionales de su dominio; operaciones HTTP se verifican en [OpenAPI](../../contratos/http/openapi.yaml), el reparto/estado operativo en [Acuerdo G1–G6 H4](../../integraciones/ACUERDO_G1_G6_H4_2026-10-20.md) y [alineación](../../integraciones/ALINEACION_MARKETPLACE.md). No declarar runtime, grants G7, despliegue o E2E por esta referencia. Las dependencias de otros owners se limitan a la operación que les corresponde.
