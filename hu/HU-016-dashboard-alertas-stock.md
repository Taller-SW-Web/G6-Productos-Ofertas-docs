# HU-016 — Historia de Usuario: Dashboard analítico y alertas de stock

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** Spec [SPEC-016](../specs/SPEC-016-dashboard-alertas-stock.md) | Flow [WF-016](../wireframes/flows/WF-016-dashboard-alertas-stock.md)

**Como** responsable de inventario,

**quiero** visualizar indicadores, niveles de stock y alertas sobre el estado del inventario,

**para** identificar oportunamente unidades con baja disponibilidad o agotadas y analizar cómo se distribuye operativamente el stock entre ubicaciones, sin duplicar los reportes de ventas cuyo dueño es Ventas/Postventa.

El dashboard permitirá visualizar información consolidada del inventario mediante indicadores y gráficos, facilitando el seguimiento del estado del stock y la identificación de situaciones que requieran atención.

La unidad primaria de inventario del dashboard es el **SKU vendible**. El Producto puede utilizarse únicamente como **agrupador comercial** cuando corresponda, sin representar una unidad de inventario independiente.

## Criterios de aceptación

| **ID** | **Criterio** |
| --- | --- |
| **CA-01** | El sistema debe mostrar la cantidad de variantes que se encuentran en estado **Disponible, Stock bajo y Agotado**. |
| **CA-02** | El sistema debe mostrar indicadores que permitan conocer el estado general del inventario. |
| **CA-03** | El sistema identifica Stock bajo usando `available` y el umbral efectivo: override por SKU cuando exista o umbral global configurable como fallback. El estado puede mostrarse por ubicación y, cuando proceda, agregado por SKU. |
| **CA-04** | El sistema debe mostrar alertas para las variantes que se encuentren en estado **Stock bajo** o **Agotado**, según el estado calculado de cada SKU. |
| **CA-05** | El sistema debe mostrar la **distribución operativa del inventario por ubicación**, indicando al menos unidades `on_hand`, `reserved` y `available` y cantidad de SKU en Stock bajo/Agotado por `location_id`. El dashboard no calcula rankings de ventas por producto. |
| **CA-06** | Los indicadores deben representar el estado actual del inventario y las alertas deben generarse según el estado calculado de cada SKU en ese momento. |
| **CA-07** | Los indicadores y alertas deben actualizarse cuando la gestión de inventario notifique un cambio de stock de una variante mediante el contrato de evento `inventory.stock.changed`; la actualización debe reflejar el saldo y el estado vigentes. |
| **CA-08** | Después de un consumo correctamente registrado, el estado del SKU debe reflejarse correctamente en el dashboard: si pasa de **Disponible → Stock bajo**, debe verse como **Stock bajo**; si pasa de **Stock bajo → Agotado**, debe verse como **Agotado**. |
| **CA-09** | El dashboard permite filtrar por `location_id` y comparar ubicaciones habilitadas. Si solo existe `DEFAULT`, mantiene una vista única sin inventar tiendas o almacenes no configurados. |
| **CA-10** | El dashboard es estrictamente de lectura: consume `inventory.stock.changed` para recalcular indicadores y alertas, **no lo publica** ni ajusta, reserva o consume stock desde la pantalla. |

## Escenarios dado-cuando-entonces

### Escenario 1: Visualizar estado general del inventario

* **DADO** que existen variantes con diferentes cantidades de stock,
* **CUANDO** el responsable de inventario accede al dashboard,
* **ENTONCES** el sistema muestra indicadores con la cantidad de variantes en estado **Disponible, Stock bajo y Agotado**.

### Escenario 2: Identificar una variante con stock bajo

* **DADO** que el `umbral_efectivo` (`override SKU ?? umbral_global`) de una variante en una ubicación está configurado y la variante tiene `0 < available <= umbral_efectivo`,
* **CUANDO** el responsable de inventario consulta el dashboard,
* **ENTONCES** el sistema muestra una alerta indicando que la variante presenta **Stock bajo**.

### Escenario 3: Identificar una variante agotada

* **DADO** que una variante tiene `available = 0` unidades en una ubicación,
* **CUANDO** el responsable de inventario consulta el dashboard,
* **ENTONCES** el sistema muestra la variante como **Agotada** y genera la alerta correspondiente.

### Escenario 4: Visualizar distribución de stock por ubicación

* **DADO** que el mismo SKU posee existencias en `ALMACEN_CENTRAL` y `TIENDA_01`,
* **CUANDO** el responsable consulta la distribución operativa,
* **ENTONCES** el sistema muestra por ubicación sus unidades `on_hand`, `reserved` y `available`, sin interpretar esos datos como ventas ni duplicar reportes de Ventas/Postventa.

### Escenario 5: Actualización de una alerta después de un consumo (Disponible → Stock bajo)

* **DADO** que una variante tiene `available = 6` unidades y su `umbral_efectivo` está configurado en 5 unidades,
* **CUANDO** se registra el consumo de 1 unidad,
* **ENTONCES** el saldo disponible se actualiza a `available = 5`, la variante pasa de **Disponible** a **Stock bajo** y aparece como **Stock bajo** en el dashboard.

### Escenario 6: Actualización del dashboard después de agotar una variante (Stock bajo → Agotado)

* **DADO** que una variante tiene `available = 1` unidad y su `umbral_efectivo` está configurado en 5 unidades (por lo que se encuentra en estado **Stock bajo**),
* **CUANDO** se registra correctamente el consumo de esa unidad pasando a `available = 0`,
* **ENTONCES** el dashboard actualiza la información de la variante a **Agotado** y muestra la alerta correspondiente.

### Escenario 7: Actualización reactiva del dashboard ante un cambio de stock

* **DADO** que la gestión de inventario modifica el stock disponible de una variante (por ejemplo, `available <= umbral_efectivo`),
* **CUANDO** la gestión de inventario notifica el cambio mediante el contrato de evento `inventory.stock.changed`,
* **ENTONCES** el dashboard recalcula los indicadores y alertas con el saldo y el estado vigentes de la variante por `(sku, location_id)`.

## Interacción con otros módulos

| **Módulo** | **Necesidad de interacción** | **Información que esta funcionalidad recibe** | **Información que esta funcionalidad entrega** |
| --- | --- | --- | --- |
| **Ventas y Postventa** | No es fuente obligatoria de este dashboard. Los reportes de ventas por producto/canal pertenecen a Ventas/Postventa; Inventario únicamente puede recibir sus solicitudes de reserva/consumo mediante los contratos de WF/HU-015. | Contratos de movimientos de inventario cuando correspondan. | Disponibilidad/resultado de inventario, no analítica de ventas. |

## Dependencias dentro de Productos y Ofertas

| **Funcionalidad interna** | **Información necesaria** |
| --- | --- |
| **Gestión de productos** | Identificación de productos y variantes para mostrar los indicadores y análisis de inventario, y para agrupar la información por producto como vista comercial. |
| **Gestión de variantes/SKUs** | Identificación y atributos de cada variante/SKU analizada por los indicadores y alertas. |
| **Gestión de características** | Características de las variantes, como talla y color, para identificar correctamente las unidades analizadas. |
| **Gestión de inventario** | Cantidades actuales, estados de disponibilidad y registros de consumo necesarios para generar los indicadores y alertas, así como la notificación de cambios de stock mediante el contrato de evento `inventory.stock.changed`. |

## Reglas de negocio consolidadas

* **Indicadores mínimos:** total de SKUs vendibles, total de unidades disponibles y cantidad de SKUs por estado (Disponible, Stock bajo y Agotado).
* **Umbral:** se usa un umbral global configurable como fallback y override por SKU cuando exista.
* **Filtros:** el dashboard permite filtrar por producto, categoría, marca, SKU, ubicación (`location_id`) y estado de inventario.
* **Distribución:** la vista por ubicación muestra `on_hand`, `reserved`, `available` y estados de stock; los rankings de ventas quedan fuera del alcance y pertenecen a Ventas/Postventa.
