# HU-002 — Historia de Usuario: Gestión de combos de productos

**Responsable:** Marco Renato Castilla Huanca  
**Rama:** castilla  
**Trazabilidad:** Spec [SPEC-002](../specs/SPEC-002-gestion-combos-productos.md) | Flow [WF-002](../wireframes/flows/WF-002-gestion-combos-productos.md)

**Como** gestor comercial,
**quiero** crear y gestionar paquetes (combos) agrupando múltiples SKUs y productos
complementarios bajo un precio único promocional que sea estrictamente menor a la suma individual,
**para** incentivar las ventas, garantizando que el sistema calcule
la disponibilidad informativa a partir de una proyección eventualmente consistente, descuente el inventario ante la confirmación definitiva de la venta (`order.confirmed`),
y compense transaccionalmente ante cancelaciones o devoluciones.

## Criterios de aceptación

| **ID** | **Criterio** |
| --- | --- |
| **CA-01** | Solo un gestor comercial con los permisos correspondientes (Módulo Seguridad y Usuarios) puede crear, modificar, consultar y desactivar combos. |
| **CA-02** | El registro de un combo debe incluir obligatoriamente: nombre, descripción, selección de 2 o más SKUs vendibles **distintos** (SKU de variante o `sku_base` de producto simple) con sus respectivas cantidades, y un precio único de paquete. |
| **CA-03** | El sistema debe validar que el precio del paquete sea mayor a cero, menor que la suma de `precio_regular_vigente_sku × cantidad` y también menor que la suma de los **precios públicos efectivos vigentes** de los componentes (oferta propia de Pricing cuando exista, de lo contrario regular). No se incorporan promociones de carrito ni cupones contextuales a esta validación administrativa. |
| **CA-04** | Queda estrictamente prohibido el anidamiento: los combos únicamente pueden estar conformados por productos y SKUs individuales puros, rechazando la inclusión de otros combos. |
| **CA-05** | El sistema debe calcular la disponibilidad informativa (stock) del combo basándose en el SKU individual con menor disponibilidad proporcional ($stock\_disponible = \min \lfloor stock\_sku_i / cantidad\_requerida_i \rfloor$). |
| **CA-06** | Si alguno de los SKUs componentes del combo se queda sin stock (0 unidades), la disponibilidad del combo automáticamente pasa a ser 0 y se marca como no disponible para compra. |
| **CA-07** | Al emitirse el contrato provisional `order.confirmed` desde Ventas/Postventa con `order_id`, composición/SKUs y cantidades aceptadas, **Inventario** ejecuta el descuento ACID de todos los componentes o ninguno y publica resultado correlacionado; Combos no escribe stock. |
| **CA-08** | Si una venta ya confirmada se cancela antes del despacho (`order.cancelled`), el sistema compensa íntegramente el stock consumido. Un `order.created` que nunca llega a confirmarse no requiere compensación porque no afectó stock. |
| **CA-09** | La política de si una devolución de combo puede ser total o parcial pertenece a Ventas/Postventa. Al recibir el contrato homologado de devolución aceptada, Inventario repone **exactamente los SKU y cantidades físicamente reintegrables informados**, de forma idempotente, sin que Combos decida la elegibilidad de la devolución. |
| **CA-10** | Si un gestor comercial desactiva o da de baja un SKU o producto componente en el Catálogo, el combo debe inhabilitarse y ocultarse automáticamente en todos los canales de venta, emitiendo una notificación al gestor para su revisión. |
| **CA-11** | No se repite un mismo SKU como dos componentes; cada uno requiere cantidad entera positiva. La validación comercial muestra tanto la suma regular como la suma efectiva vigente de los componentes para evitar publicar un combo más caro que comprarlos individualmente en ese momento. |
| **CA-12** | Si un cambio de precios deja de cumplir el descuento real, el combo se vuelve no elegible para nuevas ventas y se notifica, sin alterar pedidos históricos. |
| **CA-13** | El precio de combo es un beneficio comercial propio. Su combinabilidad con promociones/cupones se resuelve por la política configurada del motor de Promociones; por defecto el MVP puede marcar el combo como exclusivo. El pedido confirmado conserva snapshot de precio y composición. |
| **CA-14** | Un rechazo de consumo desde Inventario se comunica a Ventas mediante resultado idempotente; la resolución de pedido/pago depende de Ventas/Postventa y no se presume exitosa. |
| **CA-15** | La disponibilidad mostrada del combo es una estimación calculada con la proyección de stock de sus SKUs; la consulta expone `calculated_at` y estado de actualización. Si es desconocida/obsoleta se informa «No verificable», nunca se garantiza una compra. Inventario revalida y descuenta atómicamente en `order.confirmed`, sin reservas. |

## Escenarios dado-cuando-entonces

**Escenario 1: Creación exitosa de un combo**

* **DADO** que el gestor comercial se encuentra en la pantalla de gestión de combos,
* **CUANDO** ingresa los datos del combo (nombre, descripción), selecciona 2 o más SKUs individuales distintos válidos con stock y establece un precio de paquete que es estrictamente menor a la suma de los precios de los artículos seleccionados,
* **ENTONCES** el sistema registra el combo, lo activa para su venta en los canales y vincula los SKUs con sus cantidades respectivas.

**Escenario 2: Rechazar precio de combo igual o superior a la suma de componentes**

* **DADO** que el gestor comercial está creando o editando un combo cuyos componentes suman S/ 120,
* **CUANDO** establece el precio del paquete en S/ 120, S/ 130 o un valor menor/igual a cero,
* **ENTONCES** el sistema muestra un mensaje de error impidiendo guardar el combo, explicando que el precio debe representar un descuento real frente a la suma de componentes.

**Escenario 3: Rechazar anidamiento de combos**

* **DADO** que el gestor comercial está seleccionando los componentes para un nuevo paquete,
* **CUANDO** intenta añadir un combo preexistente como ítem integrante,
* **ENTONCES** el sistema bloquea la acción y muestra un mensaje indicando que no se permite el anidamiento de combos.

**Escenario 4: Cálculo de disponibilidad basada en los SKUs componentes**

* **DADO** que existe un combo activo compuesto por 1 "Camiseta Talla M" (SKU-CAM-M, Stock: 10) y 2 "Medias Blancas" (SKU-MED-W, Stock: 15),
* **CUANDO** un canal de venta (Marketplace, Chatbot o Retail) consulta la disponibilidad del combo,
* **ENTONCES** el sistema calcula con la última proyección de Inventario y muestra como estimación 7 combos disponibles (limitado por las medias: $15 / 2 = 7.5 \rightarrow 7$).

**Escenario 5: Combo sin stock por producto agotado**

* **DADO** que uno de los SKUs individuales que conforman el combo se ha quedado sin stock (0 unidades),
* **CUANDO** un canal de venta consulta la disponibilidad actual del combo,
* **ENTONCES** el sistema responde que el stock del combo es 0 y lo muestra como temporalmente agotado.

**Escenario 6: Descuento de stock ante venta confirmada (`order.confirmed`)**

* **DADO** que un cliente inicia la compra de un combo compuesto por 1 "Raqueta" (Stock: 5) y 3 "Pelotas" (Stock: 20),
* **CUANDO** Ventas y Postventa emite `order.confirmed`,
* **ENTONCES** el sistema descuenta de forma transaccional 1 unidad a la "Raqueta" (Nuevo Stock: 4) y 3 unidades a las "Pelotas" (Nuevo Stock: 17).

**Escenario 7: Compensación de stock ante cancelación previa al despacho (`order.cancelled`)**

* **DADO** que se descontó el stock de los componentes de un combo por una venta confirmada,
* **CUANDO** la venta se cancela antes del despacho y se recibe `order.cancelled`,
* **ENTONCES** el sistema revierte la operación y repone transaccionalmente las unidades descontadas a cada SKU individual.

**Escenario 8: Desactivación automática del combo ante baja de un componente**

* **DADO** un combo activo que contiene el SKU de una zapatilla en liquidación,
* **CUANDO** el gestor desactiva ese SKU en el Catálogo,
* **ENTONCES** el sistema procesa la baja, marca el combo como inactivo y propaga el cambio a los canales mediante eventos; puede existir latencia de propagación y no se garantiza deshabilitación instantánea global. Además, notifica al gestor comercial para que edite o archive el paquete.

**Escenario 9: Dos unidades del mismo SKU no forman un combo válido**
* **DADO** un combo con una sola fila SKU y cantidad 2,
* **CUANDO** se intenta crearlo,
* **ENTONCES** el sistema rechaza el guardado porque necesita dos SKUs distintos.

**Escenario 10: Cambio de precio vigente invalida la conveniencia del combo**
* **DADO** un combo cuyo precio deja de ser inferior al total regular de componentes,
* **CUANDO** Pricing confirma el cambio,
* **ENTONCES** el combo se oculta para nuevas ventas y se notifica al gestor, sin alterar pedidos previos.

**Escenario 9: Disponibilidad proyectada no verificable**
* **DADO** un combo cuya proyección de un componente está ausente o se sabe desactualizada,
* **CUANDO** el canal consulta su disponibilidad,
* **ENTONCES** devuelve «No verificable» con estado de actualización y no presenta un stock cero ni promete disponibilidad para compra; Inventario comprobará el stock al confirmar.

## Interacción con otros módulos

| **Módulo** | **Necesidad de interacción** | **Información que esta funcionalidad recibe** | **Información que esta funcionalidad entrega** |
| --- | --- | --- | --- |
| **Canal Marketplace** | Mostrar combos en catálogo y permitir compra según stock dinámico. | Consultas de combos y peticiones de validación de carrito. | Detalles del combo, precio unificado, componentes y disponibilidad calculada. |
| **Canal Chatbot / Retail** | Consulta y venta presencial o asistida por chat. | Solicitudes de cotización y disponibilidad informativa basada en proyecciones. | Información comercial del combo, precio final y existencia. |
| **Ventas y Postventa** | Coordinar confirmación, cancelación previa al despacho y devolución mediante eventos de dominio. | Eventos `order.confirmed`, `order.cancelled` y `order.returned`. | Resultado del débito o compensación de stock de componentes. |
| **Seguridad y Usuarios** | Validar privilegios de gestión comercial. | Token de sesión y rol de usuario autenticado. | Solicitud de autorización para administrar combos. |

## Dependencias dentro de Productos y Ofertas

| Funcionalidad interna | Información necesaria |
|---|---|
| **Gestión de productos y variantes** | Identidad del SKU vendible, producto/variante a la que pertenece y estado comercial (`BORRADOR`, `ACTIVO`, `INACTIVO`) para impedir componentes no elegibles y reaccionar a `catalog.sku.deactivated`. **No suministra stock.** |
| **Gestión de inventario** | `available` por SKU/ubicación para la proyección informativa de disponibilidad; ejecución ACID del consumo de componentes ante la confirmación contractual; compensaciones por cancelación/devolución cuando corresponda. |
| **Gestión de precios** | `precio_regular` y precio público efectivo vigente del SKU (`precio_oferta` de Pricing cuando exista; de lo contrario regular) para validar que `precio_combo` sea inferior a ambas referencias. |

## Reglas acordadas de negocio y arquitectura

* **Disponibilidad informativa:** La disponibilidad del combo se calcula como $\min(\lfloor available_i / cantidad_i \rfloor)$ sobre la proyección conocida de Inventario, sin constituir una reserva ni garantía de venta.
* **Combinabilidad:** La combinabilidad del beneficio propio del combo con promociones y cupones pertenece a la política del motor de Promociones; el MVP puede usar exclusividad por defecto, pero no es una invariabilidad arquitectónica.
* **Baja de productos individuales:** Si un SKU componente es desactivado en el catálogo, **el combo se deshabilita y oculta automáticamente en los canales de venta** y se genera una notificación al gestor comercial para su revisión.
* **Devoluciones:** Ventas/Postventa define si una devolución de combo es total o parcial. Inventario repone únicamente las líneas y cantidades aceptadas físicamente que reciba en el contrato homologado; esta funcionalidad no impone una política de devolución al módulo propietario del pedido.
* **Anidamiento:** **Prohibido el anidamiento**. Un paquete solo puede conformarse por artículos y variantes directas, descartando complejidades recursivas.
* **Límites de precios:** Es una **validación obligatoria y bloqueante**: el precio configurado para el combo debe ser menor tanto que la suma regular como que la suma de precios públicos efectivos vigentes de los componentes. Los descuentos contextuales de carrito/cupón no forman parte de esta comparación administrativa.
