# SPEC-015 — Especificación: Control de stock y disponibilidad

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** HU [HU-015](../hu/HU-015-control-stock-disponibilidad.md) | Wireframe [WF-015](../../ux/wireframes/flows/WF-015-control-stock-disponibilidad.md)

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
- bloquear unidades por incidencia física (`blocked`);
- resolver cuarentenas, mermas y faltantes;
- reintegrar unidades postventa físicamente aceptadas;
- conciliar ventas Retail realizadas offline;
- notificar cambios de stock.

Marketplace y Chatbot consumen disponibilidad sin mutar Inventario. Retail tampoco reserva ni consume por una venta, pero puede reportar/resolver incidencias físicas mediante contratos dedicados.

El ciclo de pedido, pago y mutaciones comerciales de inventario es responsabilidad y orquestación de **M1/Ventas (`modulo-ventas`)**. M1 crea reservas, confirma consumo y libera reservas; esa responsabilidad no se transfiere a M2/Postventa. M2 es responsable de devoluciones y cambios; para F3 invoca directamente el reintegro después de recepción física y evaluación apta para reventa. M2 puede consultar disponibilidad detallada de forma informativa para CAMBIO, pero no tiene autorización acordada para reservar, consumir o liberar reemplazos.

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
2. cálculo de `on_hand`, `reserved`, `blocked` y `available`;
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

Cada saldo por `(sku, location_id)` conserva:

```text
on_hand
reserved
blocked
available
stock_version
```

## 5.1. Interpretación

### `on_hand`

Unidades físicamente contabilizadas en la ubicación.

### `reserved`

Unidades comprometidas por reservas activas solicitadas por M1/Ventas.

### `blocked`

Unidades físicamente existentes pero temporalmente no vendibles por una incidencia/cuarentena.

`blocked` no representa una reserva comercial ni una merma definitiva.

### `available`

```text
available = max(on_hand - reserved - blocked, 0)
```

### `stock_version`

Versión optimista del saldo para detectar escrituras obsoletas y conciliaciones.

Invariantes obligatorias:

```text
on_hand >= 0
reserved >= 0
blocked >= 0
reserved + blocked <= on_hand
available >= 0
```

# 6. Estados de disponibilidad

El estado del **saldo autoritativo por `(sku, location_id)`** se calcula sobre `available`. La proyección comercial se obtiene con la política D-INV-01 y puede ser `INDETERMINADO` si no se determina una fuente única y ejecutable de cumplimiento; no se calcula sumando ubicaciones independientes.

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
- La lectura detallada/autoritativa de `/inventario/disponibilidad` admite M1/Ventas y M2/Postventa con sus scopes/allowlists y usuarios humanos autorizados; M2 la usa informativamente para CAMBIO; **Marketplace, Chatbot y Retail solo acceden a la proyección** `/inventario/disponibilidad/comercial` o a la verificación comercial por cantidades, conforme a sus allowlists.
- Las consultas comerciales no exponen saldos ni `location_id` y no reservan stock.

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

Cuando M1/Ventas crea el pedido y este entra en estado:

```text
CREADO
```

M1/Ventas DEBE solicitar una reserva de inventario.

Contrato técnico:

```http
POST /api/v1/inventario/reservas
```

La reserva comercial la solicita M1/Ventas (`modulo-ventas`) como parte de su responsabilidad sobre pedido y pago. M2/Postventa no está autorizado para crear reservas de reemplazo.

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
  max(on_hand - reserved_nuevo - blocked, 0)
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

Cuando M1/Ventas cambia el pedido a:

```text
PAGADO
```

M1/Ventas DEBE solicitar la confirmación del consumo de la reserva.

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
  max(on_hand_nuevo - reserved_nuevo - blocked, 0)
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

M1/Ventas DEBE solicitar la liberación.

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
  max(on_hand - reserved_nuevo - blocked, 0)
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
blocked >= 0
reserved + blocked <= on_hand
available >= 0
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

## Marketplace y Chatbot

Pueden consultar disponibilidad, pero no ejecutan ninguna mutación de Inventario.

## Retail

En la secuencia actualmente documentada para G6, Retail no ejecuta directamente mutaciones comerciales de venta:

```text
reservar
consumir
liberar
reintegrar
conciliar-offline
```

La secuencia vigente en G6 conserva a Ventas/Postventa como consumidor contractual de la conciliación. El antecedente de una llamada directa Retail→G6 está pendiente de homologación con los módulos involucrados; no se presume que Retail tenga actualmente acceso al endpoint ni se cambia aquí la secuencia documentada.

Retail sí puede reportar hechos físicos:

```http
POST /api/v1/inventario/incidencias
POST /api/v1/inventario/incidencias/{incidenciaId}/resolver
```

Un reporte de incidencia no significa que Retail sea owner del saldo. Inventario valida disponibilidad, idempotencia e invariantes y registra Kardex.

# 22. Integración con Ventas/Postventa

M1/Ventas (`modulo-ventas`) es responsable del pedido y pago y orquesta exclusivamente el ciclo comercial de reserva, consumo y liberación. M2/Postventa es responsable de devoluciones y cambios; invoca directamente el reintegro F3. M1 conserva la capacidad contractual de reintegro para otros motivos, como `ANULACION_POST_CONSUMO` y `RETORNO_LOGISTICO`.

```text
M1/Ventas: CREADO -> inventario:reservar
M1/Ventas: PAGADO -> inventario:consumir
M1/Ventas: PAGO_NO_COMPLETADO/anulación pre-consumo -> inventario:liberar
M2/Postventa: devolución física recibida y apta -> inventario:reintegrar (F3)
M1/Ventas: otros motivos contractuales de reintegro
M1/Ventas: venta Retail offline ya registrada -> inventario:conciliar-offline
```

En la conciliación offline, Ventas/Postventa es el consumidor contractual vigente en la documentación G6. La eventual llamada directa Retail→G6 permanece pendiente de homologación; esta secuencia no fija un orden nuevo entre venta, pedido, pago y conciliación.

Una reserva `CONSUMIDA` no se puede liberar.

# 23. Integración con Despacho

Despacho no modifica stock.

Su integración con Catálogo para peso/dimensiones permanece separada del bounded context Inventario.

# 24. Integraciones físicas de postventa y Retail

## 24.1. Reintegro postventa

Una devolución comercial no equivale automáticamente a stock disponible.

Solo se acepta:

```http
POST /api/v1/inventario/reintegros
```

cuando M2/Postventa confirma recepción física y evalúa aptitud para reventa. La aprobación comercial por sí sola no acredita stock. M2 obtiene el SKU exacto de `items[].sku` en el pedido original consultado a Ventas, nunca lo deduce de `productoId`. M2 arma el payload canónico `operation_id` (UUID), `order_id` (referencia textual opaca), `source_ref` (referencia de devolución `devolucionId`), `reason: DEVOLUCION_ACEPTADA` y `lines[]` (`sku`, `quantity`, `location_id`), y llama directamente al endpoint con cliente `modulo-postventa`, scope `inventario:reintegrar`, audiencia `api-productos` y autenticación de servicio `client_credentials` (`serviceBearer`). El grant efectivo de G7 sigue pendiente.

`location_id` es obligatorio en el OpenAPI vigente, pero la ubicación receptora real y su mecanismo de resolución siguen pendientes; no se inventa un UUID, código ni mapeo. La cantidad reintegrada no puede exceder la efectivamente recibida y apta; deben distinguirse cantidades solicitada, recibida, apta y reintegrada.

Efecto:

```text
on_hand += quantity
blocked no cambia salvo un contrato explícito distinto
available se recalcula
stock_version += 1
```

La operación exitosa responde HTTP `200` con `status: COMPLETED`. Un reintento idéntico conserva el mismo `operation_id` y payload y no duplica stock ni Kardex. Una recepción parcial efectiva posterior es una operación lógica nueva y requiere otro `operation_id`. Inventario valida la precondición, aplica el incremento y registra un único movimiento Kardex asociado a la operación lógica; un retry idéntico no crea efectos nuevos.

## 24.2. Reporte de incidencia física

Tipos iniciales:

```text
DANIO
NO_UBICADA
OTRO_FISICO
```

Precondición: la cantidad a bloquear debe estar actualmente disponible.

Efecto:

```text
blocked += quantity
on_hand no cambia
reserved no cambia
available se recalcula
```

La respuesta confirma centralmente la cuarentena antes de que Retail la trate como sincronizada.

## 24.3. Resolución de incidencia

Resoluciones:

```text
REHABILITADO
MERMA
FALTANTE_CONFIRMADO
TRASLADO_ALMACEN_CENTRAL
```

Efectos:

```text
REHABILITADO:
  blocked -= quantity

MERMA / FALTANTE_CONFIRMADO:
  blocked -= quantity
  on_hand -= quantity

TRASLADO_ALMACEN_CENTRAL:
  registra salida de la ubicación origen;
  crea un traslado EN_TRANSITO;
  el destino no aumenta hasta una recepción confirmada.
```

Toda resolución exige referencia de acta (`act_ref`) y queda en Kardex.

## 24.4. Recepción de traslado

La recepción pertenece a Inventario y la ejecuta un **Gestor Comercial con capacidad local de recepción de inventario**.

Estados:

```text
EN_TRANSITO
RECIBIDO_PARCIAL
COMPLETADO
COMPLETADO_CON_DISCREPANCIA
```

Disposiciones:

```text
REINGRESAR_DISPONIBLE
REINGRESAR_BLOQUEADO
CONFIRMAR_MERMA
```

Reglas:

- no acreditar más unidades de las enviadas;
- cada recepción usa `operation_id` e idempotencia;
- `REINGRESAR_DISPONIBLE` aumenta `on_hand` y `available`;
- `REINGRESAR_BLOQUEADO` aumenta `on_hand` y `blocked`;
- `CONFIRMAR_MERMA` no aumenta el saldo de destino;
- una recepción parcial puede continuar;
- si `final_receipt=true` con faltante, el traslado queda `COMPLETADO_CON_DISCREPANCIA`;
- las unidades faltantes no se inventan ni se acreditan en ninguna ubicación.

Autorización:

```text
INVENTARIO_TRASLADOS_LEER
INVENTARIO_TRASLADOS_RECIBIR
```

son capacidades locales asociadas al `sub` del usuario, no scopes de servicio.

## 24.5. Conciliación de venta Retail offline

Una venta offline ya ocurrió físicamente, por lo que no se crea una reserva retroactiva.

Flujo:

```text
Retail sincroniza venta -> Ventas/Postventa
Ventas registra la venta
Ventas -> POST /inventario/conciliaciones-offline
```

Ventas/Postventa conserva el rol de invocador contractual vigente en la documentación G6. La propuesta de invocación directa Retail→G6 permanece pendiente de homologación; este flujo no establece un orden nuevo entre la venta, el pedido, el pago y la conciliación.

Por línea:

```text
applied_quantity = min(requested_quantity, available)
unresolved_quantity = requested_quantity - applied_quantity
```

Si todas las líneas se aplican:

```text
status = COMPLETED
```

Si existe una cantidad no conciliable:

```text
status = REQUIRES_REVIEW
```

La conciliación no crea reservas retroactivas. Inventario conserva la autoridad del saldo central y solo aplica unidades disponibles; `reserved` y `blocked` no se consumen. El resultado de conciliación se registra aunque no haya unidades aplicadas, pero solo un cambio efectivo de saldo genera movimiento de Kardex. No se registra un movimiento de cantidad cero. Si hay aplicación parcial, se conserva el resultado `REQUIRES_REVIEW` con las cantidades originales de la solicitud y las cantidades aplicadas/no resueltas.

La misma venta física no puede descontar stock más de una vez, aunque un reintento técnico use otra identidad. La identidad estable, su ámbito de unicidad y el mecanismo de deduplicación continúan pendientes de definición/homologación; esta regla funcional no acredita que la idempotencia esté implementada ni autoriza elegir un campo, clave o índice.

Antes de mutar, Inventario debe resolver internamente la referencia de tienda a ubicación y autorizar al actor para esa mutación y ubicación. Mapeo inexistente o ambiguo, o falta de autorización, no permite modificar el saldo. El contrato OpenAPI vigente aún requiere `location_id` en las líneas de conciliación; la compatibilidad de contrato y el consumidor autorizado permanecen pendientes, sin modificación contractual en este documento.

La representación destinada a Retail debe limitarse a las cantidades funcionales necesarias (`requested_quantity`, `applied_quantity` y `unresolved_quantity`) y al resultado acordado; no debe exponer saldos ni identificadores de ubicación internos innecesarios. La forma contractual futura y sus consumidores autorizados siguen pendientes de homologación G4/G7. El DTO candidato actual no acredita esa representación ni habilita acceso de Retail.

Nunca se permite:

```text
on_hand < 0
reserved + blocked > on_hand
```

La discrepancia queda explícita; no se oculta consumiendo reservas o unidades bloqueadas.


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
blocked = 0
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
BLOCK
UNBLOCK
WRITE_OFF
OFFLINE_RECONCILE
TRANSFER_OUT
TRANSFER_RECEIPT
TRANSFER_WRITE_OFF
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
inventory.reservation.rejected
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
blocked
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

o en `inventory.reservation.rejected` con `operation_id`, `causation_id` y `result_code` no vacío. La admisión previa con HTTP `202` no es prueba de stock reservado.

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
contratos/eventos/asyncapi.yaml
```

---

# 31. Errores y rechazos funcionales

El catálogo canónico de códigos pertenece a:

```text
contratos/http/catalogo-errores.md
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
INCIDENCIA_NO_ENCONTRADA
INCIDENCIA_NO_ACTIVA
RESOLUCION_INCIDENCIA_INVALIDA
REINTEGRO_NO_APLICABLE
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

Para llamadas módulo-a-módulo, la API utiliza la audiencia:

```text
api-productos
```

y propone el scope técnico:

```text
inventario:disponibilidad:leer
```

Consumidores previstos de las **consultas comerciales** (`GET /inventario/disponibilidad/comercial` y `POST /inventario/disponibilidad/comercial/verificar`):

```text
modulo-marketplace
modulo-chatbot
modulo-retail
```

La consulta **detallada** (`GET /inventario/disponibilidad`) admite los clientes técnicos M1/Ventas (`modulo-ventas`) y M2/Postventa (`modulo-postventa`) con scope `inventario:disponibilidad:leer` y allowlist propia de la operación; M2 la consulta de forma informativa para CAMBIO, sin crear reservas ni garantizar stock futuro. El acceso humano autorizado mediante `userBearer` permanece separado. Marketplace, Chatbot y Retail quedan fuera de la allowlist del detalle y conservan sus endpoints comerciales.

El token de servicio debe validar `iss`, `exp`, `tipo=servicio`, `aud` y el scope requerido. El scope permanece pendiente de registro con Seguridad.

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

según el contrato adoptado de Seguridad.

## 32.2. Mutaciones de Ventas y reintegro de Postventa

M1/Ventas (`modulo-ventas`) conserva la responsabilidad del pedido y pago y orquesta reservas, consumo y liberación. Su matriz previa de permisos comerciales no cambia: `inventario:reservar`, `inventario:consumir`, `inventario:liberar`, `inventario:reintegrar` para motivos distintos de F3, y `inventario:conciliar-offline`. No transfiere a M2 su responsabilidad de reservas.

Consumidor autorizado de las mutaciones comerciales de M1:

```text
sub = modulo-ventas
aud = api-productos
```

Scopes:

```text
inventario:reservar
inventario:consumir
inventario:liberar
inventario:reintegrar
inventario:conciliar-offline
```

M2/Postventa (`modulo-postventa`) solo recibe los scopes previstos `inventario:disponibilidad:leer` y `inventario:reintegrar`, con allowlist por operación. Para F3 invoca directamente `/inventario/reintegros` tras recepción física y evaluación apta; M1 permanece admitido para motivos de reintegro distintos de F3. El registro y grant efectivo de ambos scopes de M2 por G7 siguen pendientes. M2 no está autorizado para `inventario:reservar`, `inventario:consumir`, `inventario:liberar`, `inventario:conciliar-offline` ni `inventario:operaciones:leer`. La consulta informativa de M2 no reserva stock. La eventual invocación directa Retail→G6 y sus permisos requieren homologación; la consulta comercial de Retail no autoriza mutaciones. Para toda mutación, la autorización debe cubrir la operación y la ubicación resuelta internamente.

## 32.3. Incidencias físicas de Retail

Consumidor autorizado:

```text
sub = modulo-retail
aud = api-productos
```

Scopes:

```text
inventario:incidencias:reportar
inventario:incidencias:resolver
```

Retail no recibe, según la documentación G6 vigente, scopes comerciales de reserva/consumo/liberación/reintegro/conciliación. La conciliación directa Retail→G6 permanece pendiente de homologación con G4/G7; no se afirma que Retail disponga actualmente de ese permiso o endpoint.

Todos los scopes permanecen pendientes de registro efectivo en Seguridad hasta que G7 los publique.

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


## Casos adicionales de traslados e incidencias

- reportar daño sobre una unidad disponible → `blocked` aumenta;
- intentar bloquear más que `available` → rechazo sin romper invariantes;
- rehabilitar una incidencia → `blocked` disminuye;
- confirmar merma → `blocked` y `on_hand` disminuyen exactamente una vez;
- reintegro duplicado con misma identidad → un solo incremento;
- devolución aprobada sin recepción física → no se reintegra;
- venta offline totalmente conciliable → `COMPLETED`;
- venta offline parcialmente conciliable → `REQUIRES_REVIEW`;
- ninguna conciliación produce saldo negativo;
- operación concurrente de reserva e incidencia sobre últimas unidades → solo cantidades compatibles con las invariantes quedan aplicadas.

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
- Marketplace, Chatbot y Retail pueden consultar exclusivamente la **disponibilidad comercial**, sin saldos ni ubicaciones internas;
- Marketplace y Chatbot no mutan Inventario; Retail solo reporta/resuelve incidencias físicas mediante contratos autorizados;
- M1/Ventas reserva al crear el pedido;
- M1/Ventas confirma consumo al quedar pagado;
- M1/Ventas libera ante pago fallido/anulación aplicable;
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

- existe consulta autoritativa por SKU/ubicación;
- `on_hand`, `reserved` y `available` cumplen sus invariantes;
- existe creación idempotente de reserva;
- existe confirmación idempotente;
- existe liberación idempotente;
- un retry con misma identidad + mismo payload reutiliza el resultado sin duplicar efectos;
- misma identidad + payload semánticamente distinto produce `IDEMPOTENCY_CONFLICT`;
- `OPERACION_DUPLICADA` no se emite en contratos nuevos;
- existe expiración de reservas;
- existe Kardex;
- existe Outbox/Inbox para los flujos asíncronos;
- la concurrencia está cubierta por pruebas;
- los ajustes absolutos respetan `stock_version`;
- los eventos están versionados;
- las rutas coinciden con `contratos/http/openapi.yaml`;
- los contratos asíncronos coinciden con `contratos/eventos/asyncapi.yaml`;
- M1/Ventas tiene pruebas de contrato sobre reserva/consumo/liberación;
- Marketplace y Chatbot no poseen permisos de mutación; Retail solo posee capacidades de incidencias físicas; M1 conserva las mutaciones comerciales de pedido (reserva/consumo/liberación) y M2 ejecuta el reintegro F3; no se autorizan a M2 mutaciones de reemplazo.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Extensión 0.5.0 — saldo detallado vs disponibilidad comercial

Esta sección sustituye cualquier referencia anterior que presente el saldo detallado como respuesta normal de Marketplace/Chatbot/Retail.

```text
GET /api/v1/inventario/disponibilidad
→ saldo detallado/autoritativo
→ M1/Ventas + M2/Postventa + usuarios humanos autorizados

GET /api/v1/inventario/disponibilidad/comercial
→ proyección para Marketplace / Chatbot / Retail
→ sku + status
```

La proyección comercial no expone `location_id`, `on_hand`, `reserved`, `blocked`, `available`, `threshold` ni `stock_version`; no reserva ni garantiza stock.

Estados del **GET comercial**:

```text
DISPONIBLE
STOCK_BAJO
AGOTADO
INDETERMINADO
```

`D-INV-01` está **adoptada** en el ADR de bloqueantes (0.6.0-rc.1): la disponibilidad comercial se determina por una única ubicación elegible y un plan de cumplimiento realmente ejecutable, nunca sumando saldos independientes. Si el mapeo del contexto de cumplimiento falta, es ambiguo o no permite justificar un resultado, responder `INDETERMINADO`; **no** inferir `AGOTADO`. El contrato sigue `provisional` porque falta comprobar su implementación, no porque la decisión siga abierta.
### Verificación comercial de cantidades — contrato 0.6.0-rc.1

```http
POST /api/v1/inventario/disponibilidad/comercial/verificar
```

- **Consumidores:** Marketplace, Chatbot y Retail con el scope `inventario:disponibilidad:leer` y `client_id` autorizado; registro de scopes sujeto a G7.
- **Entrada:** `channel_id` (`MARKETPLACE`, `CHATBOT` o `RETAIL`), `fulfillment` (`mode`: `ENVIO_DOMICILIO`, `RETIRO_TIENDA` o `VENTA_TIENDA`; `fulfillment_ref` opaca y opcional según modalidad) y `lines` de uno a cien elementos `{sku, quantity}`, con cantidades enteras positivas.
- **Salida:** `evaluated_at`, `binding: false` y `items` con `{sku, requested_quantity, result, reason_code?}`. `result` pertenece a `SUFICIENTE`, `INSUFICIENTE`, `INDETERMINADO`.
- **Política:** solo `SUFICIENTE` si existe una ubicación elegible/mecanismo único capaz de atender íntegramente la cantidad requerida. No sumar tiendas por defecto.
- **Contexto:** falta de correspondencia interna o ambigüedad de abastecimiento → `200 INDETERMINADO` (resultado de negocio). Contexto **semánticamente inválido** → `422 CONTEXTO_ABASTECIMIENTO_INVALIDO`; request malformado → `400 VALIDACION`.
- **Límites:** nunca exponer `location_id`, `on_hand`, `reserved`, `blocked`, `available` ni `stock_version`. No muta Inventario ni garantiza disponibilidad al pagar: Ventas es responsable de reservar y esperar confirmación definitiva.

No confundir `GET.status` (`DISPONIBLE/STOCK_BAJO/AGOTADO/INDETERMINADO`) con `POST.items[].result` (`SUFICIENTE/INSUFICIENTE/INDETERMINADO`).

<!-- HOMOLOGACION-HTTP-0.5.0:END -->

## Addendum contractual 0.6.0-rc.1 — Cuatro bloqueantes G6

**Decisión interna aprobada; objetivo 0.6.0-rc.1 (no desplegado).**

- `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- `POST /inventario/reservas`, `/confirmar` y `/liberar` responden `202` solamente cuando aceptan el comando. El éxito o rechazo se determina por resultado persistido y evento.
- Nuevos contratos provisionales: `GET /inventario/operaciones/{operationId}` (solo Ventas; scope `inventario:operaciones:leer`) y `POST /inventario/disponibilidad/comercial/verificar` (canales, consulta sin efectos).
- Nuevo evento `inventory.reservation.rejected`; resultados de reserva/consumo/liberación/expiración con datos tipados y correlación obligatoria.
- `D-INV-01`: no se suman saldos de ubicaciones independientes por defecto. Un canal obtiene `INDETERMINADO` cuando el punto único de cumplimiento no se puede resolver. `SUFICIENTE` exige una fuente de abastecimiento realizable para la cantidad completa; no supone reserva.
- Cupones: después de reserva confirmada, Ventas envía `reservation_id` y `commercial_snapshot_ref` al solicitar consumo. Los resultados de consumo se tipan y la restauración se vincula a la operación previamente consumida.
- Misma identidad/operación/payload semántico => mismo resultado y cero efectos nuevos; identidad reutilizada con payload distinto => `IDEMPOTENCY_CONFLICT`. Los eventos tienen `message_id` propio para deduplicación de transporte.
- Las transiciones pagar/expirar/liberar se serializan por reserva; se respeta `expires_at` emitido por Inventario.
- Estos contratos siguen **provisionales** hasta que la implementación, migraciones y pruebas integradas sean verificadas. No anunciar disponibilidad real antes del cierre.

**Política explícita D-INV-01 (adoptada):** una sola ubicación elegible por referencia de cumplimiento comercial mientras no exista un plan multi-origen verificable. La configuración de correspondencia `fulfillment_ref`/`location_id` es interna a Inventario. Si falta la correspondencia o hay ambigüedad, devolver `INDETERMINADO`; nunca convertir ambigüedad en `AGOTADO` o `DISPONIBLE`. La verificación comercial no admite mutaciones ni garantiza la compra. Los casos que necesiten sumar ubicaciones requieren otra ADR y capacidad demostrada.

> **Integración G1 Marketplace H4 (2026-10-20):** G6 aceptó y comunicó M-01–M-09 (`ACEPTADO_G6_COMUNICADO_G1`). Esta SPEC gobierna reglas funcionales de su dominio; operaciones HTTP se verifican en [OpenAPI](../../contratos/http/openapi.yaml), el reparto/estado operativo en [Acuerdo G1–G6 H4](../../integraciones/ACUERDO_G1_G6_H4_2026-10-20.md) y [alineación](../../integraciones/ALINEACION_MARKETPLACE.md). No declarar runtime, grants G7, despliegue o E2E por esta referencia. Las dependencias de otros owners se limitan a la operación que les corresponde.
