# SPEC-015 — Especificación: Control de stock y disponibilidad

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** HU [HU-015](./hu/HU-015-control-stock-disponibilidad.md) | Wireframe [WF-015](./wireframes/flows/WF-015-control-stock-disponibilidad.md)  
**Contrato HTTP:** [`./api/openapi.yaml`](./api/openapi.yaml)  
**Contrato de integración:** [`./Contrato_Api.md`](./Contrato_Api.md)  
**Arquitectura:** [`./Arquitectura.md`](./Arquitectura.md)  
**Modelo conceptual:** [`./Modelo_Conceptual.md`](./Modelo_Conceptual.md)  
**Contrato asíncrono:** [`./asyncapi/asyncapi.yaml`](./asyncapi/asyncapi.yaml)  
**Catálogo de errores:** [`./api/catalogo-errores.md`](./api/catalogo-errores.md)

**Versión:** v1.1 — idempotencia y códigos de error armonizados

---

## 1. Contexto

La gestión de inventario del módulo **Productos y Ofertas** mantiene la disponibilidad autoritativa de los SKU vendibles para todos los canales del Marketplace Multicanal.

El módulo es responsable de:

- consultar disponibilidad;
- mantener saldos por SKU y ubicación;
- reservar unidades temporalmente;
- confirmar su consumo definitivo;
- liberar reservas;
- expirar reservas vencidas;
- registrar movimientos de inventario;
- notificar cambios de stock.

Los canales **Marketplace, Chatbot y Retail** consumen información de disponibilidad, pero **no reservan ni consumen stock directamente**.

El ciclo de reserva y consumo es orquestado por **Ventas y Postventa**:

```text
Pedido CREADO
    -> reservar stock

Pedido PAGADO
    -> confirmar consumo definitivo

PAGO_NO_COMPLETADO o anulación aplicable
    -> liberar reserva
```

Despacho y Entrega no genera un segundo consumo de inventario.

---

## 2. Propósito

Garantizar que la disponibilidad de cada SKU sea consistente frente a:

- consultas concurrentes;
- reservas de pedidos;
- confirmaciones de pago;
- cancelaciones;
- expiración de reservas;
- ajustes manuales o masivos;
- múltiples ubicaciones;
- reintentos y mensajes duplicados.

El sistema debe impedir:

- stock negativo;
- doble reserva de las mismas unidades;
- doble consumo;
- doble liberación;
- sobrescritura de saldos recientes mediante ajustes obsoletos.

---

## 3. Alcance

Incluye:

1. consulta de disponibilidad por SKU y ubicación;
2. cálculo de `on_hand`, `reserved` y `available`;
3. determinación de estado de stock;
4. creación de reservas;
5. confirmación de reservas como consumo definitivo;
6. liberación de reservas;
7. expiración por TTL;
8. movimientos de Kardex;
9. idempotencia;
10. concurrencia;
11. integración con Ventas/Postventa;
12. eventos de cambio de stock;
13. interacción con Bulk;
14. soporte de múltiples ubicaciones.

No incluye:

- creación del pedido;
- procesamiento del pago;
- reembolso;
- política comercial de devolución;
- empaque;
- ejecución del despacho;
- creación o edición del SKU;
- precio;
- promociones.

---

# 4. Unidad de inventario

La unidad comercial es el **SKU vendible**.

El saldo autoritativo se identifica por:

```text
(sku, location_id)
```

## 4.1. Producto simple

Si:

```text
tiene_variantes = false
```

el `sku_base` funciona como SKU vendible.

## 4.2. Producto con variantes

Si:

```text
tiene_variantes = true
```

cada variante posee un SKU comercial único.

El producto padre:

- no tiene stock propio;
- no puede reservarse;
- no puede consumirse directamente.

---

# 5. Magnitudes de inventario

Cada saldo mantiene:

```text
on_hand
reserved
available
stock_version
```

donde:

```text
available = max(on_hand - reserved, 0)
```

## 5.1. Interpretación

### `on_hand`

Cantidad física registrada en la ubicación.

### `reserved`

Cantidad temporalmente comprometida para pedidos aún no consumidos definitivamente.

### `available`

Cantidad actualmente ofrecible para nuevas operaciones.

### `stock_version`

Versión del saldo utilizada para control de concurrencia y ajustes absolutos.

---

# 6. Estados de disponibilidad

El estado comercial del saldo se calcula sobre `available`.

```text
available = 0
-> AGOTADO

0 < available <= umbral_stock_bajo_resuelto
-> STOCK_BAJO

available > umbral_stock_bajo_resuelto
-> DISPONIBLE
```

Inventario mantiene:

- `umbral_stock_bajo_default` global configurable;
- `umbral_stock_bajo` opcional por SKU.

Regla:

```text
umbral_stock_bajo_resuelto =
  override SKU ?? umbral global
```

El umbral no se define por ubicación en el alcance actual.

---

# 7. Requisito 1 — Consulta de disponibilidad

El sistema DEBE permitir consultar la disponibilidad autoritativa de un SKU.

Contrato técnico canónico:

```http
GET /api/v1/inventario/disponibilidad
```

La SPEC define la semántica; los parámetros exactos pertenecen a OpenAPI.

## 7.1. Datos mínimos

La consulta debe permitir resolver:

```text
sku
location_id, cuando aplique
on_hand
reserved
available
estado
umbral_stock_bajo_resuelto
stock_version, cuando el consumidor autorizado lo requiera
```

## 7.2. Reglas

- La consulta no crea una reserva.
- La consulta no garantiza disponibilidad futura.
- `location_id` puede omitirse únicamente cuando exista una única ubicación inequívoca o el contrato permita una agregación explícita.
- Un agregado no reemplaza los saldos autoritativos por ubicación.
- Marketplace, Chatbot y Retail pueden consultar disponibilidad.

## 7.3. Escenario — SKU disponible

**DADO** un SKU con:

```text
on_hand = 10
reserved = 2
```

**CUANDO** se consulta su disponibilidad

**ENTONCES**:

```text
available = 8
```

y el estado se determina con el umbral resuelto.

---

# 8. Requisito 2 — Crear reserva

Cuando Ventas/Postventa crea un pedido y este entra en estado:

```text
CREADO
```

Ventas DEBE solicitar una reserva de inventario.

Contrato técnico:

```http
POST /api/v1/inventario/reservas
```

La operación es exclusiva para consumidores autorizados del módulo Ventas/Postventa.

## 8.1. Datos conceptuales mínimos

```text
order_id
operation_id
channel_id
lines[]
  sku
  quantity
  location_id
```

El request HTTP exacto se define en OpenAPI.

## 8.2. Reglas

La creación de reserva DEBE:

1. validar que `order_id` y `operation_id` sean válidos;
2. validar que todas las cantidades sean enteros positivos;
3. validar que cada SKU sea vendible;
4. resolver la ubicación;
5. comprobar idempotencia;
6. validar disponibilidad real;
7. reservar todas las líneas de la operación de forma consistente;
8. registrar la reserva y sus líneas;
9. incrementar `reserved`;
10. recalcular `available`;
11. registrar la operación;
12. escribir el registro de Outbox dentro de la misma transacción local que persiste la reserva;
13. publicar los mensajes de Outbox únicamente después del commit.

## 8.3. Efecto

Para cada línea:

```text
reserved_nuevo = reserved_anterior + quantity

available_nuevo =
  on_hand - reserved_nuevo
```

`on_hand` no cambia al reservar.

---

# 9. Requisito 3 — Atomicidad de reserva

Una reserva con múltiples líneas debe ser aceptada o rechazada de forma consistente dentro del límite transaccional de Inventario.

Ejemplo:

```text
Pedido:
SKU-A x 2
SKU-B x 1
```

Si:

```text
SKU-A tiene disponibilidad
SKU-B no tiene disponibilidad
```

la operación no debe dejar reservado únicamente `SKU-A` como si la reserva completa hubiera sido exitosa.

El resultado debe indicar rechazo y conservar invariantes.

---

# 10. Requisito 4 — Estado de la reserva

Toda reserva mantiene un estado.

Estados:

```text
ACTIVA
CONSUMIDA
LIBERADA
EXPIRADA
```

Máquina de estados:

```text
                 +---------+
                 | ACTIVA  |
                 +----+----+
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
      CONSUMIDA   LIBERADA    EXPIRADA
```

No se permiten transiciones de retorno hacia `ACTIVA`.

---

# 11. Requisito 5 — Confirmar consumo definitivo

Cuando Ventas/Postventa cambia el pedido a:

```text
PAGADO
```

DEBE confirmar el consumo de la reserva.

Contrato técnico:

```http
POST /api/v1/inventario/reservas/{reservaId}/confirmar
```

## 11.1. Precondición

La reserva debe encontrarse:

```text
ACTIVA
```

o la operación debe reconocerse como repetición idempotente de una confirmación previamente aplicada.

## 11.2. Efecto

Para cada línea:

```text
on_hand_nuevo =
  on_hand_anterior - quantity

reserved_nuevo =
  reserved_anterior - quantity

available_nuevo =
  on_hand_nuevo - reserved_nuevo
```

La reserva pasa a:

```text
CONSUMIDA
```

## 11.3. Kardex

El consumo definitivo debe producir movimientos trazables con:

- SKU;
- ubicación;
- cantidad;
- saldo anterior;
- saldo posterior;
- tipo de operación;
- `order_id`;
- `operation_id`;
- timestamp.

---

# 12. Requisito 6 — Liberar reserva

Cuando el pedido:

- no completa el pago; o
- es anulado antes del consumo definitivo cuando corresponda;

Ventas/Postventa DEBE solicitar la liberación.

Contrato técnico:

```http
POST /api/v1/inventario/reservas/{reservaId}/liberar
```

## 12.1. Motivos previstos

Como mínimo:

```text
PAGO_NO_COMPLETADO
ANULACION
EXPIRACION_FORZADA
OTRO
```

La enumeración técnica exacta pertenece a OpenAPI.

## 12.2. Efecto

```text
on_hand
  no cambia

reserved_nuevo =
  reserved_anterior - quantity

available_nuevo =
  on_hand - reserved_nuevo
```

La reserva pasa a:

```text
LIBERADA
```

---

# 13. Requisito 7 — Expiración de reserva

Toda reserva activa DEBE tener un vencimiento.

El TTL:

- es configurable;
- puede variar por canal o entorno;
- no se fija como constante funcional dentro de esta SPEC.

La reserva almacena conceptualmente:

```text
created_at
expires_at
```

Cuando:

```text
now >= expires_at
```

y la reserva continúa `ACTIVA`, Inventario puede expirar la reserva automáticamente.

La transición es:

```text
ACTIVA -> EXPIRADA
```

y libera las unidades reservadas.

---

# 14. Requisito 8 — Concurrencia entre confirmar, liberar y expirar

Puede ocurrir que simultáneamente:

- Ventas confirme una reserva;
- Ventas solicite liberarla;
- el worker de expiración la detecte como vencida.

Solo **una transición terminal** puede aplicarse.

Ejemplo:

```text
ACTIVA
  -> CONSUMIDA
```

Si luego llega una expiración atrasada:

- no debe restaurar unidades;
- no debe modificar nuevamente el saldo;
- si corresponde al **mismo intento lógico ya aplicado**, debe resolverse mediante replay idempotente;
- si es una **operación distinta** que intenta cambiar una reserva ya terminal, debe rechazarse con el código estable correspondiente, por ejemplo `RESERVA_NO_ACTIVA` o `RESERVA_EXPIRADA`.

La idempotencia no convierte una transición de negocio incompatible en una operación válida.

---

# 15. Requisito 9 — Idempotencia

Las mutaciones externas de Inventario DEBEN ser idempotentes.

El contrato HTTP utiliza conjuntamente:

```text
Idempotency-Key
operation_id
```

Reglas:

1. un retry de la misma operación DEBE conservar la misma identidad idempotente;
2. una repetición con la **misma identidad y el mismo payload semántico** no vuelve a ejecutar efectos;
3. si la operación original sigue en proceso, se devuelve o reproduce su reconocimiento sin lanzar un segundo procesamiento;
4. si la operación original ya terminó, el consumidor obtiene el mismo resultado lógico conocido sin volver a modificar saldos;
5. reutilizar la misma identidad idempotente para una **intención semánticamente distinta** se rechaza con:

```text
IDEMPOTENCY_CONFLICT
```

6. ese conflicto no modifica reserva, saldo ni Kardex;
7. `correlation_id` sirve para trazabilidad y no reemplaza la identidad idempotente.

El sistema NO debe utilizar:

```text
OPERACION_DUPLICADA
```

para representar un retry legítimo.

## 15.1. Crear reserva repetida

Si Ventas reenvía la misma creación de reserva con la misma identidad idempotente y el mismo contenido de negocio:

- no se crea una segunda reserva;
- no se incrementa nuevamente `reserved`;
- se reutiliza el estado o resultado de la operación original.

## 15.2. Confirmación repetida

Si una confirmación ya aplicada se reintenta con la misma identidad y el mismo payload:

- no vuelve a disminuir `on_hand`;
- no vuelve a disminuir `reserved`;
- se devuelve o reproduce el resultado de la confirmación original.

## 15.3. Liberación repetida

Si una liberación ya aplicada se reintenta con la misma identidad y el mismo payload:

- no vuelve a disminuir `reserved`;
- no vuelve a aumentar `available`;
- se devuelve o reproduce el resultado de la liberación original.

## 15.4. Reutilización conflictiva

Ejemplo:

```text
Idempotency-Key = abc
operation_id = op-123
```

se utilizó para:

```text
reservar SKU-A x 1
```

y posteriormente se intenta reutilizar para:

```text
reservar SKU-A x 3
```

El segundo request debe rechazarse con:

```text
409
IDEMPOTENCY_CONFLICT
```

sin aplicar ningún efecto nuevo.

La comparación se realiza sobre la intención de negocio definida por el contrato; metadatos puramente de trazabilidad no deben convertir un retry legítimo en una nueva operación.

---

# 16. Requisito 10 — Concurrencia del saldo

Dos operaciones concurrentes no pueden comprometer las mismas unidades.

Inventario DEBE garantizar:

```text
on_hand >= 0
reserved >= 0
available >= 0
reserved <= on_hand
```

cuando corresponda al modelo de saldo.

## 16.1. Estrategia conceptual

La implementación puede utilizar:

- bloqueo transaccional breve por saldo;
- actualización condicional;
- versión optimista;
- orden determinista de adquisición de registros.

No se permite un lock global de Inventario.

---

# 17. Escenario — Dos reservas sobre las últimas unidades

**DADO**:

```text
on_hand = 5
reserved = 0
available = 5
```

y dos solicitudes concurrentes:

```text
Reserva A = 3
Reserva B = 3
```

**ENTONCES** solo una puede reservar tres unidades.

Resultado posible:

```text
Reserva A: ACEPTADA
Reserva B: RECHAZADA - STOCK_INSUFICIENTE
```

Saldo final:

```text
on_hand = 5
reserved = 3
available = 2
```

---

# 18. Escenario — Confirmación después de reserva

**DADO**:

```text
on_hand = 10
reserved = 3
available = 7
```

y una reserva ACTIVA de 3 unidades

**CUANDO** Ventas confirma el pedido como `PAGADO`

**ENTONCES**:

```text
on_hand = 7
reserved = 0
available = 7
```

y la reserva queda:

```text
CONSUMIDA
```

---

# 19. Escenario — Pago no completado

**DADO**:

```text
on_hand = 10
reserved = 3
available = 7
```

**CUANDO** Ventas informa `PAGO_NO_COMPLETADO` y solicita liberar la reserva

**ENTONCES**:

```text
on_hand = 10
reserved = 0
available = 10
```

y la reserva queda:

```text
LIBERADA
```

---

# 20. Escenario — Expiración

**DADO** una reserva:

```text
estado = ACTIVA
expires_at <= now
```

**Y** no existe una confirmación definitiva aplicada

**CUANDO** el proceso de expiración la ejecuta

**ENTONCES**:

- libera las cantidades;
- recalcula `available`;
- marca `EXPIRADA`;
- registra operación;
- publica el resultado correspondiente.

---

# 21. Integración con canales

Marketplace, Chatbot y Retail pueden consultar:

```http
GET /api/v1/inventario/disponibilidad
```

No deben invocar:

```text
crear reserva
confirmar consumo
liberar reserva
```

La creación del pedido se dirige a Ventas/Postventa.

---

# 22. Integración con Ventas/Postventa

Ventas/Postventa es owner del pedido.

Inventario no cambia:

- estado del pedido;
- pago;
- reembolso;
- comprobante.

Flujo homologado:

| Estado/acción en Ventas | Acción sobre Inventario |
|---|---|
| Pedido pasa a `CREADO` | Crear reserva |
| Pedido pasa a `PAGADO` | Confirmar reserva / consumir |
| `PAGO_NO_COMPLETADO` | Liberar reserva |
| Anulación aplicable antes del consumo | Liberar reserva |
| Devolución aceptada físicamente después del consumo | Reintegrar únicamente cantidades aceptadas |

---

# 23. Integración con Despacho

Despacho:

- no crea reservas;
- no confirma reservas;
- no consume stock;
- no libera stock por sí mismo.

Despacho opera sobre pedidos cuya responsabilidad comercial pertenece a Ventas/Postventa.

Una entrega física no produce un segundo débito de inventario.

---

# 24. Devoluciones

Si una venta ya fue consumida definitivamente, una devolución NO equivale automáticamente a reposición.

Solo se reintegra inventario cuando Ventas/Postventa comunique una devolución:

- aceptada;
- físicamente reintegrable;
- con SKU;
- cantidad;
- `location_id`.

La política comercial de devolución pertenece a Ventas/Postventa.

El nombre/payload asíncrono definitivo debe formalizarse en AsyncAPI.

---

# 25. Ajustes masivos

SPEC-001 puede solicitar ajustes absolutos de stock.

Cada ajuste se identifica por:

```text
(sku, location_id)
```

y utiliza:

```text
stock_version
```

para evitar sobrescribir operaciones posteriores.

Ejemplo:

1. se exporta `stock_version = 12`;
2. ocurre una reserva y el saldo pasa a versión 13;
3. llega una importación con versión esperada 12;
4. Inventario rechaza:

```text
VERSION_CONFLICT
```

No se reaplica el conteo obsoleto.

---

# 26. Inicialización de SKU

Cuando Catálogo confirma un nuevo SKU vendible, Inventario debe poder inicializarlo idempotentemente.

Estado inicial:

```text
on_hand = 0
reserved = 0
available = 0
stock_version = 0
```

en la ubicación predeterminada cuando corresponda.

La creación repetida del mismo SKU no debe generar saldos duplicados.

---

# 27. Kardex

Toda mutación autoritativa de saldo debe ser trazable.

Tipos conceptuales de operación:

```text
RESERVE
CONSUME
RELEASE
EXPIRE
ADJUST
RETURN
```

Cada movimiento registra como mínimo:

```text
sku
location_id
operation_id
tipo
cantidad
on_hand_anterior
on_hand_nuevo
reserved_anterior
reserved_nuevo
available_anterior
available_nuevo
occurred_at
```

El Kardex no es editable como mecanismo ordinario.

---

# 28. Eventos de dominio

Después del commit local pueden publicarse:

```text
inventory.stock.changed
inventory.stock.adjusted

inventory.reservation.created
inventory.reservation.consumed
inventory.reservation.released
inventory.reservation.expired

inventory.consumption.completed
inventory.consumption.rejected
```

## 28.1. Regla

Un evento comunica un hecho ya persistido.

No debe reutilizarse:

```text
inventory.stock.changed
```

como comando para modificar stock.

---

# 29. `inventory.stock.changed`

Es el evento canónico para:

- dashboard;
- proyecciones de Combos;
- proyecciones de Promociones;
- BFF/read model;
- consumidores autorizados.

Debe contener información suficiente para que una proyección identifique:

```text
sku
location_id
on_hand
reserved
available
estado
stock_version
updated_at
```

El schema final pertenece a AsyncAPI.

---

# 30. Resultados asíncronos hacia Ventas

Las operaciones HTTP de mutación pueden devolver:

```text
202 Accepted
```

cuando el comando fue **admitido**, pero el resultado de negocio todavía se procesa de forma asíncrona.

Por tanto:

```text
202 Accepted != operación completada
```

La creación de reserva puede terminar posteriormente en:

```text
inventory.reservation.created
```

o en un rechazo de negocio correlacionado.

La confirmación puede terminar en:

```text
inventory.reservation.consumed
inventory.consumption.completed
```

o:

```text
inventory.consumption.rejected
```

Ventas debe correlacionar resultados mediante:

```text
order_id
operation_id
correlation_id
reservation_id
```

Un conflicto de idempotencia detectado antes de admitir el comando utiliza:

```text
409
IDEMPOTENCY_CONFLICT
```

y no debe tratarse como una segunda operación asíncrona.

Los nombres, envelopes y payloads canónicos pertenecen a:

```text
asyncapi/asyncapi.yaml
```

---

# 31. Errores y rechazos funcionales

El catálogo canónico de códigos pertenece a:

```text
api/catalogo-errores.md
```

## 31.1. Admisión HTTP

Los códigos relevantes para las mutaciones de Inventario incluyen:

```text
VALIDACION
TOKEN_INVALIDO
SCOPE_INSUFICIENTE
IDEMPOTENCY_CONFLICT
CANTIDAD_INVALIDA
RESERVA_NO_ENCONTRADA
RESERVA_NO_ACTIVA
RESERVA_EXPIRADA
VERSION_CONFLICT
ERROR_INTERNO
SERVICIO_NO_DISPONIBLE
```

El mapeo exacto por endpoint y status pertenece a OpenAPI y utiliza:

```text
application/problem+json
```

## 31.2. Rechazos de negocio asíncronos

Después de un `202 Accepted`, una reserva o confirmación puede producir códigos como:

```text
STOCK_INSUFICIENTE
SKU_NO_ENCONTRADO
SKU_INACTIVO
UBICACION_NO_ENCONTRADA
CANTIDAD_INVALIDA
RESERVA_NO_ENCONTRADA
RESERVA_NO_ACTIVA
RESERVA_EXPIRADA
```

según el tipo de operación y el contrato AsyncAPI.

## 31.3. Código retirado

No emitir en nuevos contratos:

```text
OPERACION_DUPLICADA
```

Un retry legítimo no es un error.

Si la misma identidad idempotente se reutiliza con una intención diferente:

```text
IDEMPOTENCY_CONFLICT
```

Los consumidores deben ramificar por `code`, no por `title`, `detail` ni el texto del mensaje.

---

# 32. Seguridad

## 32.1. Consulta de disponibilidad

Requiere el mecanismo de autenticación definido para consumidores de canal cuando corresponda.

Para respuestas HTTP autenticadas:

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

según el contrato adoptado de Seguridad.

## 32.2. Mutaciones

Reserva, confirmación y liberación son operaciones servicio-a-servicio.

Consumidor autorizado:

```text
modulo-ventas
```

Scopes propuestos:

```text
inventario:reservar
inventario:consumir
inventario:liberar
```

Deben registrarse con Seguridad antes de considerarse contractualmente definitivos.

---

# 33. Requisitos no funcionales

## 33.1. Consistencia

Las invariantes de un movimiento de Inventario deben persistirse dentro de una transacción local.

No existe transacción distribuida con Ventas.

## 33.2. Idempotencia

Toda mutación externa debe soportar reintentos sin duplicar efectos.

Un retry con la misma identidad y la misma intención debe ser seguro. La reutilización de esa identidad para una intención distinta debe terminar en `IDEMPOTENCY_CONFLICT` sin efectos secundarios.

## 33.3. Concurrencia

Los locks deben:

- ser locales;
- ser breves;
- afectar únicamente los saldos requeridos.

## 33.4. Trazabilidad

Cada operación debe conservar:

```text
operation_id
correlation_id
order_id cuando aplique
actor/service
timestamp
```

## 33.5. Observabilidad

Registrar métricas al menos de:

```text
reservas aceptadas
reservas rechazadas
consumos confirmados
liberaciones
expiraciones
conflictos
latencia
```

## 33.6. Disponibilidad

La caída temporal del broker no debe perder cambios persistidos; utilizar Outbox.

---

# 34. Reglas de mantenibilidad de implementación

La implementación de esta SPEC debe respetar `Arquitectura.md`.

En particular:

- reglas de inventario dentro de `domain/application`;
- controllers delgados;
- repositorios mediante puertos;
- DTO HTTP separados de entidades de dominio;
- ningún acceso directo a tablas de Ventas;
- ningún import de código de otros microservicios;
- Outbox/Inbox para integración;
- pruebas unitarias sin NestJS/DB para invariantes;
- pruebas de integración con DB/broker real mediante Testcontainers.

---

# 35. Casos de prueba mínimos

La implementación no se considera completa sin pruebas para:

1. consulta de SKU disponible;
2. consulta de SKU agotado;
3. reserva exitosa;
4. reserva insuficiente;
5. reserva multilínea atómica;
6. repetición idempotente de reserva con mismo payload;
7. reutilización conflictiva de `Idempotency-Key`/`operation_id` con payload distinto -> `IDEMPOTENCY_CONFLICT`;
8. confirmación de reserva;
9. confirmación repetida;
10. liberación;
11. liberación repetida;
12. expiración;
13. confirmación vs expiración concurrentes;
14. liberación vs confirmación concurrentes;
15. dos reservas por últimas unidades;
16. `stock_version` obsoleta;
17. SKU inexistente;
18. ubicación inexistente;
19. replay de mensaje;
20. persistencia de Kardex;
21. persistencia de Outbox en la misma transacción local;
22. publicación de Outbox posterior al commit.

---

# 36. Fuera de alcance

Esta SPEC no define:

- proceso de checkout;
- aprobación del pago;
- estado maestro del pedido;
- reembolso;
- empaque;
- despacho;
- definición física del producto;
- reglas de pricing;
- reglas de promociones;
- UI del dashboard analítico completo de WF-016.

---

# 37. Resultado esperado

Al completarse esta funcionalidad:

- cada SKU vendible tiene disponibilidad autoritativa por ubicación;
- Marketplace, Chatbot y Retail pueden consultar stock;
- los canales no mutan inventario;
- Ventas reserva al crear el pedido;
- Ventas confirma consumo al quedar pagado;
- Ventas libera ante pago fallido/anulación aplicable;
- las reservas pueden expirar;
- ninguna operación válida deja stock negativo;
- un retry legítimo no duplica efectos;
- reutilizar una identidad idempotente para otra intención produce `IDEMPOTENCY_CONFLICT`;
- Bulk no puede pisar un saldo más reciente;
- Dashboard y proyecciones reciben cambios mediante eventos;
- Despacho no produce un segundo consumo.

---

# 38. Criterio de completitud

SPEC-015 se considera implementada cuando:

- [ ] existe consulta autoritativa por SKU/ubicación;
- [ ] `on_hand`, `reserved` y `available` cumplen sus invariantes;
- [ ] existe creación idempotente de reserva;
- [ ] existe confirmación idempotente;
- [ ] existe liberación idempotente;
- [ ] un retry con misma identidad + mismo payload reutiliza el resultado sin duplicar efectos;
- [ ] misma identidad + payload semánticamente distinto produce `IDEMPOTENCY_CONFLICT`;
- [ ] `OPERACION_DUPLICADA` no se emite en contratos nuevos;
- [ ] existe expiración de reservas;
- [ ] existe Kardex;
- [ ] existe Outbox/Inbox para los flujos asíncronos;
- [ ] la concurrencia está cubierta por pruebas;
- [ ] los ajustes absolutos respetan `stock_version`;
- [ ] los eventos están versionados;
- [ ] las rutas coinciden con `api/openapi.yaml`;
- [ ] los contratos asíncronos coinciden con `asyncapi/asyncapi.yaml`;
- [ ] Ventas/Postventa tiene pruebas de contrato sobre reserva/consumo/liberación;
- [ ] los canales no poseen permisos de mutación de inventario.
