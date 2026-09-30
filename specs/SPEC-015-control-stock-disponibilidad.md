# SPEC-015 — Especificación: Control de stock y disponibilidad

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** HU [HU-015](../hu/HU-015-control-stock-disponibilidad.md) | Wireframe [WF-015](../wireframes/flows/WF-015-control-stock-disponibilidad.md)

## Descripción

La funcionalidad de **Gestión de inventario** permitirá controlar y mantener actualizada la disponibilidad de las variantes dentro del Marketplace.

Esta funcionalidad contempla dos operaciones principales: la **consulta de disponibilidad de stock** y la **actualización del stock por consumo**. Ambas permitirán que los diferentes canales y módulos del sistema trabajen con información actualizada sobre las unidades disponibles.

La gestión del inventario se realizará de manera integrada con los demás componentes del Marketplace, permitiendo consultar la disponibilidad de las variantes y actualizarla cuando se produzca un consumo.

## Unidad de inventario

En este módulo la unidad comercial sigue siendo el **SKU vendible**, pero el saldo operativo se identifica por **`(sku, location_id)`** para permitir tienda, almacén u otra ubicación sin rediseñar el dominio. Si el MVP despliega una sola ubicación, Inventario configura `location_id=DEFAULT` y las APIs pueden omitirla solo cuando no exista ambigüedad. Todo elemento vendible mantiene exactamente una identidad SKU:

* producto simple (`tiene_variantes = false`) → usa su `sku_base` como SKU vendible;
* producto con variantes (`tiene_variantes = true`) → cada variante posee un SKU comercial único (suministrado o generado) y el producto padre no tiene stock propio.

* **Inventario → SKU vendible + ubicación:** `on_hand`, `reserved` y `available` se controlan por `(sku, location_id)`; `available = max(on_hand - reserved, 0)`.
* **Producto simple:** su `sku_base` funciona como SKU vendible y tiene un único registro de inventario.
* **Producto con variantes:** el producto es agrupador comercial y no posee stock propio; el inventario reside en los SKUs de sus variantes.

```text
Producto: Nike Air Max

├── SKU-001 → Negro / Talla 40 → stock 5
├── SKU-002 → Negro / Talla 41 → stock 0
└── SKU-003 → Blanco / Talla 40 → stock 8
```

Por lo tanto, toda consulta, registro o actualización de stock referencia un **SKU vendible** y una ubicación. La respuesta puede agregar ubicaciones cuando el canal solicite disponibilidad global, pero nunca confunde un agregado comercial con el saldo autoritativo de cada `location_id`.

---

## 1. Consulta de disponibilidad de stock

Esta funcionalidad permitirá consultar `on_hand`, `reserved` y especialmente `available` de un SKU por ubicación o de forma agregada según el contrato del canal, y conocer su estado actual dentro del inventario.

Los diferentes canales podrán utilizar esta información para determinar si una variante se encuentra disponible antes de ofrecerla o realizar una operación relacionada con ella. Cuando se consulte el stock, la referencia obligatoria será el **SKU vendible**; `location_id` será obligatorio cuando exista más de una ubicación o cuando el canal necesite disponibilidad de una ubicación concreta.

Se contemplan principalmente los siguientes estados:

* **Disponible:** la variante cuenta con unidades disponibles.
* **Stock bajo:** la variante todavía cuenta con unidades, pero su cantidad se encuentra en o por debajo del umbral configurado.
* **Agotado:** no existen unidades disponibles.

Las reglas de determinación del estado son las siguientes:

```text
available = 0
→ AGOTADO

0 < available <= umbral_efectivo
→ STOCK_BAJO

available > umbral_efectivo
→ DISPONIBLE
```

Inventario mantiene un `umbral_global` global configurable y permite un `umbral_stock_bajo` específico por SKU como override. El `umbral_efectivo` usa primero el override del SKU y, si no existe, el valor global. Esto evita tener que configurar manualmente miles de SKUs sin perder la capacidad de ajustar artículos sensibles. Gestión de Variantes puede consultar el valor resuelto, pero no lo edita.

### Ejemplo

Una variante presenta:

> **Producto:** Nike Air Max
> **Variante/SKU:** SKU-001 — Negro / Talla 40
> **Stock disponible:** 8 unidades
> **Estado:** Disponible

Cuando el stock llegue a cero:

> **Producto:** Nike Air Max
> **Variante/SKU:** SKU-002 — Negro / Talla 41
> **Stock disponible:** 0 unidades
> **Estado:** Agotado

Cuando el stock se encuentre en el umbral o por debajo de él:

> **Producto:** Nike Air Max
> **Variante/SKU:** SKU-003 — Blanco / Talla 40
> **Stock disponible:** 3 unidades
> **umbral_stock_bajo:** 5 unidades
> **Estado:** Stock bajo

La consulta estará disponible para los diferentes canales contemplados por el proyecto, como **Marketplace, Retail y Chatbot**, permitiendo que cada uno conozca el estado actualizado del inventario de las variantes.

---

## 2. Actualización de stock por consumo

Esta funcionalidad permitirá actualizar el inventario cuando se produzca el **consumo de unidades de una variante**.

Cuando una operación implique consumo, Inventario descuenta `on_hand` y recalcula `available` en la ubicación correspondiente. Si existe una reserva homologada previa, el consumo libera simultáneamente la cantidad reservada; si no existe reserva, el débito se valida directamente contra `available`.

### Ejemplo

Si una variante cuenta inicialmente con:

> **Variante/SKU:** SKU-001 — Negro / Talla 40
> **Stock:** 10 unidades

y se consumen:

> **Cantidad consumida:** 3 unidades

el inventario se actualizará a:

> **Stock disponible:** 7 unidades

De esta manera, las unidades consumidas dejarán de considerarse disponibles para futuras operaciones.

---

## 3. Validación del consumo

Antes de actualizar el inventario se deberá verificar que exista una cantidad suficiente de unidades disponibles.

Si la cantidad solicitada supera el stock existente, el consumo no deberá realizarse.

### Reglas de consumo

La actualización por consumo deberá garantizar lo siguiente:

* El stock de una variante **nunca puede quedar negativo**.
* El consumo **no puede superar el stock disponible** de la variante.
* **Dos consumos simultáneos no pueden consumir las mismas unidades**; cada consumo debe operar sobre unidades disponibles reales.
* La actualización del stock debe realizarse de forma **atómica/transaccional**, sin estados intermedios que corrompan la información.
* Para ello, el descuento se ejecutará como una **actualización condicional sobre el stock disponible**: el consumo se acepta únicamente si, al momento de aplicarse, la cantidad solicitada está cubierta por las unidades disponibles.
* La protección de los consumos concurrentes será la misma definida para las operaciones masivas de actualización de inventario del módulo (**control de concurrencia optimista**), de modo que los consumos por venta y los ajustes masivos convivan sin inconsistencias ni bloqueos globales.
* Si no se puede garantizar la disponibilidad de las unidades solicitadas, la operación debe **rechazarse**.

### Ejemplo

> **Variante/SKU:** SKU-001 — Negro / Talla 40
> **Stock inicial:** 5 unidades
>
> **Consumo A = 3 unidades**
> **Consumo B = 3 unidades**

No se deben aceptar ambos consumos.

Resultado válido:

> **Consumo A:** Aceptado — Stock final: 2 unidades
> **Consumo B:** Rechazado por stock insuficiente

En el resultado, una operación se acepta, la otra se rechaza por stock insuficiente y el stock nunca queda negativo.

---

## 4. Integración con otros módulos

La gestión de inventario estará integrada con los diferentes componentes que necesiten consultar o actualizar la disponibilidad de las variantes.

### Dependencias internas del módulo de Productos y Ofertas

La gestión de inventario se sustenta en las siguientes capacidades del mismo módulo, por lo que no constituyen integraciones externas:

* **Gestión de productos:** define el producto como agrupador comercial de las variantes.
* **Gestión de variantes/SKUs:** define cada variante, su código único y sus atributos; es la base sobre la cual se controla el stock.
* **Gestión de características:** proporciona los atributos (talla, color, entre otros) que distinguen a cada variante.
* **Gestión de precios:** identifica la variante y su precio vigente cuando los canales necesiten relacionar la disponibilidad con la información comercial del producto.

### Canales

La **consulta de disponibilidad** será utilizada por los canales que necesiten conocer el stock disponible de una variante. Los canales **Marketplace, Retail y Chatbot** consultan disponibilidad referenciando una **Variante/SKU**; este consumo de información no cambia la unidad de inventario.

### Integraciones externas

La **actualización por consumo** permitirá reflejar las unidades utilizadas en las operaciones correspondientes. Para las operaciones que impliquen consumo de stock, se contempla la comunicación con los módulos de **Ventas y Despacho**.

**Delimitación de Ventas y Despacho:**

Si Ventas/Postventa utiliza la fase de reserva, la **lógica operativa homologada** del ciclo pedido → stock es la siguiente:

* **Pedido `CREADO`** → Ventas/Postventa solicita `inventory.reserve` de los SKUs con TTL y referencia de operación. La reserva modifica `reserved` y `available`, pero **no** altera `on_hand`.
* **Pedido `PAGADO` / venta confirmada** → Ventas/Postventa solicita `inventory.consume`, que **confirma la reserva** y descuenta simultáneamente `on_hand` y `reserved`. Sin esta confirmación no se aplica consumo definitivo.
* **`PAGO_NO_COMPLETADO` o anulación aplicable** → Ventas/Postventa solicita `inventory.release`: se libera `reserved` y se recupera `available` **sin incrementar `on_hand`**.
* **TTL vencido** → la reserva se **expira/libera automáticamente**.
* Las reservas tienen un estado transicional **`ACTIVA`** y estados terminales **`CONSUMIDA`**, **`LIBERADA`** y **`EXPIRADA`**; una vez alcanzado un estado terminal no se vuelve a `ACTIVA`.
* Todas las operaciones son **idempotentes** por `(order_id/operation_id + tipo_operacion + sku)`. Una operación duplicada responde con el resultado previo (no-op); si la intención del segundo mensaje **contradice** el estado vigente, Inventario responde `IDEMPOTENCY_CONFLICT`.
* Un **HTTP 202 Accepted** al recibir una solicitud solo significa solicitud admitida, no operación de inventario terminada; el resultado se confirma con el procesamiento asíncrono correspondiente.

Si Ventas/Postventa **no** utiliza la fase de reserva:

* `order.created` por sí solo no reserva ni descuenta y `reserved` puede permanecer en cero en el MVP; el consumo ocurre **únicamente con la confirmación acordada** (pago aprobado o estado equivalente para un canal sin pago electrónico) y el débito se valida **directamente contra `available`**.

Reglas comunes a ambos modelos:

* El módulo de **Despacho no genera consumo adicional ni modifica directamente el stock**: se limita a entregar las unidades correspondientes a ventas ya confirmadas, cuyos consumos ya fueron aplicados y validados bajo la misma regla de consumo.
* Si una venta confirmada es anulada **antes del despacho**, el evento provisional `order.cancelled` solicita compensar únicamente un consumo previo exitoso y no compensado, o liberar la reserva pendiente según el estado comunicado.
* Si la mercadería ya fue entregada, la reposición solo ocurre ante una **devolución aceptada y físicamente reintegrable**, comunicada mediante el contrato provisional `order.returned` con SKU, `location_id` de reintegro y cantidades aceptadas. La política de devolución total o parcial —incluidos combos— pertenece a Ventas/Postventa.
* Una anulación administrativa posterior al despacho que no implique devolución física no repone stock.

Después de cada actualización de stock (por consumo, reserva, liberación o ajuste), la gestión de inventario **notificará el cambio de stock** de la variante mediante el contrato de evento `inventory.stock.changed`, que será consumido por el dashboard analítico y por otros componentes interesados para mantenerse actualizados.

La comunicación entre módulos se realizará mediante las interfaces de integración establecidas para el proyecto, manteniendo la separación entre los diferentes componentes.

---

### Contrato provisional de reserva, consumo, compensación y venta sin stock
Los nombres y payloads de los hitos de pedido (creación, pago confirmado, pago no completado, anulación, devolución) y de los resultados de Inventario constituyen un **contrato de integración propuesto**, pendiente de homologación final con Ventas y Postventa. Los mensajes mencionados en esta SPEC (`CREADO`/`order.created`, `PAGADO`/`order.confirmed`, `PAGO_NO_COMPLETADO`, `order.cancelled`, `order.returned`, y los resultados `inventory.reserve.completed|rejected`, `inventory.consumption.completed|rejected`, `inventory.release.completed|rejected`) son la interpretación interna que implementará Productos y Ofertas cuando reciba una comunicación equivalente acordada; ninguna implementación puede presumir que el equipo externo ya publica tales mensajes, ni que el pago queda automáticamente revertido ante un rechazo de Inventario.

El ciclo de reserva solicita `inventory.reserve` en `CREADO` con `order_id`, `operation_id`, `occurred_at`, SKUs y cantidades por línea, `location_id` y TTL; `inventory.consume` en `PAGADO` confirma la reserva descontando `on_hand` y `reserved`; `inventory.release` libera la reserva ante `PAGO_NO_COMPLETADO`/anulación. Inventario verifica existencia, elegibilidad, stock y deduplicación por `order_id + tipo_operacion + sku`, aplica el movimiento ACID para **todas las líneas de la misma operación** y registra Kardex y Outbox en la misma transacción local. Publica el resultado correspondiente (aceptado o rechazado, incluido `IDEMPOTENCY_CONFLICT`) sin decidir ni alterar estados del pedido o pagos. Si el stock es insuficiente tras un pedido/pago confirmado, Ventas/Postventa resuelve la anulación, sustitución o reembolso mediante su propio proceso pendiente de coordinación. La consulta anterior a la venta no constituye reserva ni garantía de stock.

Las compensaciones `order.cancelled`/`order.returned` deben referenciar `order_id`, operación previa, `location_id` y líneas/cantidades aceptadas. `order.cancelled` revierte solamente consumos efectivos y previos a despacho o libera la reserva pendiente; `order.returned` registra solo unidades realmente aceptadas y físicamente reintegrables. El procesamiento es idempotente, tolera llegada desordenada con estado pendiente/reconciliación, evita acreditar dos veces el mismo consumo y responde `IDEMPOTENCY_CONFLICT` ante intenciones contradictorias. Ningún evento de Despacho ocasiona débito adicional ni decide disponibilidad.

### Ajuste masivo y control de concurrencia
Inventario inicializa cada nuevo SKU vendible con saldo 0 y `stock_version=0` en la ubicación predeterminada, de forma idempotente. Los conteos absolutos de `SPEC-001-carga-exportacion-masiva-productos.md` identifican `(sku, location_id)` y requieren `stock_version`. Inventario es el único dueño del ajuste; registra Kardex con valores anteriores/nuevos de `on_hand`, `reserved` y `available` cuando corresponda. Si hubo consumo, reserva o ajuste concurrente que cambió la versión, publica `VERSION_CONFLICT` y no reaplica un conteo obsoleto. Solo después del commit emite `inventory.stock.adjusted` y `inventory.stock.changed`. Se permiten bloqueos transaccionales breves por `(sku, location_id)`, nunca un bloqueo global del inventario.

### Límite de aprobación de contratos externos
Los nombres y payloads de `order.confirmed`, `order.cancelled` y `order.returned`, y de los resultados de consumo, constituyen un **contrato de integración propuesto**, pendiente de homologación con Ventas y Postventa. Hasta ese acuerdo, ninguna implementación puede presumir que el equipo externo ya publica tales mensajes, ni que el pago queda automáticamente revertido ante un rechazo de Inventario. El consumo y las compensaciones aquí descritos son las reglas internas que implementará Productos al recibir una comunicación equivalente acordada.

## 5. Resultado esperado

La funcionalidad permitirá mantener un inventario actualizado y disponible para los diferentes componentes del Marketplace.

En términos generales, permitirá:

* Consultar la cantidad disponible de una variante.
* Conocer el estado actual del stock de cada variante.
* Identificar SKUs disponibles, con stock bajo o agotados mediante el umbral resuelto global/SKU y, cuando aplique, por ubicación.
* Registrar el consumo de unidades sobre una variante.
* Reservar, confirmar o liberar unidades según el hito del pedido comunicado por Ventas/Postventa (`CREADO` → reserva, `PAGADO` → confirmación/consumo, `PAGO_NO_COMPLETADO`/anulación/TTL → liberación), con estados terminales `CONSUMIDA`, `LIBERADA` y `EXPIRADA`.
* Actualizar la cantidad disponible después de cada consumo.
* Evitar consumos superiores al stock existente y consumos concurrentes sobre las mismas unidades.
* Aplicar el consumo únicamente cuando exista una venta confirmada, quedando Despacho limitado a la entrega de unidades ya vendidas.
* Notificar los cambios de stock mediante el contrato de evento `inventory.stock.changed` para mantener actualizados el dashboard analítico y los componentes integrados.
* Mantener las proyecciones de disponibilidad utilizadas por los canales mediante eventos; las vistas son eventualmente consistentes y el consumo definitivo vuelve a comprobar el stock en Inventario.

Con estas funcionalidades, el inventario proporcionará información actualizada sobre la disponibilidad de las variantes y permitirá reflejar correctamente los cambios producidos por su consumo.
