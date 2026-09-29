# SPEC-002 — Especificación: Gestión de combos de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** HU [HU-002](./hu/HU-002-gestion-combos-productos.md) | Wireframe [WF-002](./wireframes/flows/WF-002-gestion-combos-productos.md)

## 1. Contexto

La empresa deportiva busca incentivar las ventas agrupando productos complementarios en paquetes (combos) atractivos para los clientes. El gestor comercial necesita una herramienta para crear y gestionar estos combos bajo un precio promocional unificado.

El combo es una capacidad comercial. **No es propietario del inventario ni del pedido.** Cada componente se identifica por **SKU vendible** y los movimientos de stock son ejecutados exclusivamente por Inventario cuando Ventas/Postventa los solicita como parte del ciclo de vida del pedido.

## 2. Propósito

Permitir al gestor comercial agrupar múltiples artículos individuales a nivel de SKU vendible en un combo con un precio único con descuento garantizado, ofreciendo una disponibilidad **informativa** basada en la proyección de existencias y manteniendo el flujo de stock alineado con Ventas/Postventa:

```text
Pedido CREADO
→ Ventas/Postventa solicita reservar los SKU componentes

Pedido PAGADO
→ Ventas/Postventa solicita confirmar la reserva
→ Inventario realiza el consumo definitivo

PAGO_NO_COMPLETADO o cancelación aplicable antes del consumo
→ Ventas/Postventa solicita liberar la reserva
```

Marketplace, Chatbot y Retail consultan disponibilidad; **no reservan, liberan ni consumen stock directamente**.

## 3. Alcance

Incluye:

- Creación, edición, consulta y desactivación de combos.
- Configuración de componentes exclusivamente por **SKU vendible** —SKU de variante o `sku_base` de producto simple— con cantidades enteras positivas.
- Mínimo de **2 SKUs vendibles distintos** por combo.
- Validación de precio comercial:
  - `precio_combo > 0`;
  - `precio_combo < suma_regular`;
  - `precio_combo < suma_publica_vigente`.
- Prohibición estricta de anidamiento de combos.
- Cálculo informativo de disponibilidad proporcional:
  `min(floor(available_i / cantidad_i))`.
- Reserva de todos los SKU componentes como una única intención de inventario cuando Ventas/Postventa crea el pedido.
- Confirmación/consumo definitivo de la reserva cuando Ventas/Postventa informa que el pedido pasó a `PAGADO`.
- Liberación de la reserva por `PAGO_NO_COMPLETADO`, anulación aplicable o expiración.
- Desactivación reactiva del combo cuando se desactiva un SKU componente mediante `catalog.sku.deactivated`.
- Conservación del snapshot comercial de composición/precio en el pedido propietario de Ventas/Postventa.

No se considera homologado todavía el contrato externo de reintegro por devolución física. La política comercial de devolución pertenece a Ventas/Postventa; Productos y Ofertas no la decide.

## 4. Requisitos

### Requisito 1: Gestión de combos y validación de componentes

El sistema DEBE permitir crear y modificar combos definiendo nombre, descripción, componentes, cantidades y precio final.

Cada combo DEBE:

- tener como mínimo dos SKUs vendibles distintos;
- impedir que el mismo SKU se repita en más de una fila;
- exigir cantidad entera positiva por componente;
- rechazar componentes que sean otros combos;
- usar únicamente SKU existentes y comercialmente elegibles.

#### Escenario: Creación exitosa

- **DADO** un gestor autorizado
- **Y** dos o más SKUs vendibles distintos y elegibles
- **CUANDO** registra nombre, descripción, cantidades y precio válido
- **ENTONCES** el combo se registra y queda disponible conforme a su estado comercial.

#### Escenario: Rechazo de anidamiento

- **DADO** que el gestor selecciona componentes
- **CUANDO** intenta agregar otro combo
- **ENTONCES** el sistema bloquea la selección e informa que los combos solo se componen de SKUs vendibles directos.

### Requisito 2: Precio comercial del combo

Pricing entrega por SKU el precio regular y, cuando existe, su oferta vigente. Para cada componente se multiplica el precio por la cantidad requerida.

Se calculan:

```text
suma_regular =
SUM(precio_regular_vigente_sku × cantidad)

suma_publica_vigente =
SUM(precio_publico_vigente_sku × cantidad)
```

donde el precio público vigente es la oferta propia de Pricing cuando existe; de lo contrario, el regular.

El combo DEBE cumplir:

```text
0 < precio_combo < suma_regular
precio_combo < suma_publica_vigente
```

Promociones automáticas y cupones contextuales no forman parte de esta comparación administrativa.

Si un cambio de Pricing deja de cumplir alguna desigualdad, el combo deja de ser elegible para nuevas ventas y se notifica al gestor. Los pedidos históricos no se reescriben.

### Requisito 3: Disponibilidad informativa del combo

La disponibilidad mostrada es una **estimación** derivada de la proyección conocida de Inventario:

```text
disponibilidad_combo =
min(floor(available_sku_i / cantidad_requerida_i))
```

La respuesta o proyección DEBE permitir distinguir:

- disponibilidad calculada;
- fecha/hora de cálculo (`calculated_at`);
- estado de actualización;
- disponibilidad no verificable cuando falta información o se conoce desactualizada.

Una consulta informativa **no reserva stock ni garantiza una compra**.

#### Escenario: Disponibilidad proporcional

- **DADO** 1 camiseta con `available=10`
- **Y** 2 medias por combo con `available=15`
- **CUANDO** se calcula la disponibilidad informativa
- **ENTONCES** el resultado es 7 combos.

#### Escenario: Información no verificable

- **DADO** que falta o está obsoleta la proyección de un componente
- **CUANDO** se consulta el combo
- **ENTONCES** se informa «No verificable» y no se sustituye por cero.

### Requisito 4: Reserva de componentes al crear el pedido

Cuando Ventas/Postventa registra el pedido en estado `CREADO`, solicita a Inventario una reserva idempotente de los SKU componentes y sus cantidades.

Para un combo:

- las líneas enviadas a Inventario son los SKU componentes descompuestos con sus cantidades totales;
- la intención de reserva corresponde al pedido/operación de Ventas;
- Inventario debe aceptar la reserva completa o rechazarla sin dejar una reserva parcial del combo;
- la reserva aumenta `reserved` y reduce `available`, sin reducir `on_hand`;
- el resultado final es asíncrono; `202 Accepted` significa **comando admitido**, no reserva completada.

Los canales no ejecutan esta operación directamente.

#### Escenario: Reserva completa

- **DADO** un combo de 1 raqueta y 3 pelotas
- **Y** disponibilidad suficiente
- **CUANDO** Ventas/Postventa crea el pedido y solicita la reserva
- **ENTONCES** Inventario reserva todas las líneas de forma consistente e idempotente.

#### Escenario: Reserva rechazada

- **DADO** disponibilidad insuficiente en una línea
- **CUANDO** Inventario procesa la solicitud
- **ENTONCES** no deja el combo parcialmente reservado y comunica el rechazo a Ventas/Postventa.

### Requisito 5: Confirmación de consumo al pasar a PAGADO

Cuando el pedido pasa a `PAGADO`, Ventas/Postventa solicita confirmar la reserva.

Inventario:

- valida la reserva asociada;
- consume definitivamente sus líneas;
- reduce `on_hand`;
- reduce la reserva correspondiente;
- conserva las invariantes de Inventario y Kardex;
- procesa reintentos de forma idempotente.

Combos **no** cambia stock.

#### Escenario: Consumo de reserva

- **DADO** una reserva activa de 1 raqueta y 3 pelotas
- **CUANDO** Ventas/Postventa confirma el consumo por pedido pagado
- **ENTONCES** Inventario consume exactamente esas cantidades una sola vez.

### Requisito 6: Liberación de reserva

Si el pedido no llega al consumo definitivo por `PAGO_NO_COMPLETADO`, cancelación aplicable o expiración, Ventas/Postventa solicita liberar la reserva o la reserva expira conforme al TTL configurado.

La liberación:

- reduce `reserved`;
- restaura `available`;
- no crea unidades nuevas;
- no incrementa `on_hand`;
- es idempotente.

No se utiliza una compensación de consumo para un pedido que nunca llegó a `PAGADO`.

### Requisito 7: Desactivación automática por baja de componente

Al procesar `catalog.sku.deactivated`, el combo que lo contiene DEBE dejar de ser elegible para nuevas ventas y quedar marcado para revisión.

La propagación a canales es eventual; no se promete actualización instantánea global.

### Requisito 8: Snapshot del pedido

Ventas/Postventa es propietario del pedido y conserva el snapshot comercial utilizado para vender el combo:

- `combo_id`;
- versión/composición aceptada;
- SKU componentes y cantidades;
- precio y beneficios aceptados según el contrato de Ventas.

Cambios posteriores del combo no reescriben pedidos históricos.

### Requisito 9: Devolución y reintegro

La elegibilidad de devoluciones, devolución total/parcial, autorizaciones y reembolsos pertenecen a Ventas/Postventa.

Productos e Inventario solo podrán reponer unidades cuando exista un **contrato homologado de devolución físicamente aceptada** que indique SKU, cantidad y ubicación reintegrable.

Hasta que ese contrato se formalice:

- esta SPEC no fija nombres `order.returned`;
- no afirma que dicho evento exista en AsyncAPI;
- no habilita una acción administrativa manual de reposición desde Combos.

## 5. Contratos técnicos relacionados

### HTTP administrativo

El OpenAPI administrativo P0 cubre:

```text
GET   /api/v1/combos
POST  /api/v1/combos
GET   /api/v1/combos/{comboId}
PATCH /api/v1/combos/{comboId}
POST  /api/v1/combos/{comboId}/desactivar
GET   /api/v1/combos/{comboId}/disponibilidad
```

La forma de rutas derivadas de capacidad permanece marcada como interna/provisional hasta congelar el contrato final.

### Inventario

El ciclo P0 de stock usa:

```text
POST /api/v1/inventario/reservas
POST /api/v1/inventario/reservas/{reservaId}/confirmar
POST /api/v1/inventario/reservas/{reservaId}/liberar
```

Los resultados/eventos asíncronos de Inventario pertenecen al contrato AsyncAPI. Combos no emite comandos de pedido ni inventa eventos `order.*`.

## 6. Requisitos no funcionales

- La lectura de disponibilidad del combo es informativa y debe estar optimizada para navegación; el objetivo existente de referencia es `< 200 ms` para la proyección, no para una mutación de Inventario.
- Los importes se manejan con decimal exacto y redondeo monetario definido por la moneda.
- Las operaciones de reserva/confirmación/liberación son idempotentes en Inventario.
- No existe transacción distribuida entre Combos, Ventas e Inventario.
- El frontend nunca se considera autoridad de stock o precio.

## 7. Fuera de alcance

- Facturación, cobro y ciclo de vida del pedido — Ventas/Postventa.
- Despacho y configuración del empaque — Despacho.
- Política de devolución y reembolso — Ventas/Postventa.
- Edición manual de stock — Inventario.
- Anidamiento de combos.
- Reactivación de combos mientras no exista regla funcional aprobada.
- Contrato definitivo de reintegro por devolución, todavía pendiente de homologación.

## Criterio de completitud

La capacidad se considera correctamente documentada cuando:

- los combos se componen solo de SKUs vendibles directos;
- el precio cumple ambas comparaciones;
- la disponibilidad se presenta como estimación;
- el ciclo de stock es `reserva → confirmación/consumo` o `reserva → liberación`;
- Ventas/Postventa orquesta las mutaciones de stock;
- los canales solo consultan;
- Combos no simula ni ejecuta stock;
- la devolución queda delimitada hasta tener contrato homologado;
- la baja de un SKU componente inhabilita el combo para nuevas ventas.
