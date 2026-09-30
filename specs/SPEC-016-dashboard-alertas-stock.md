# SPEC-016 — Especificación: Dashboard analítico y alertas de stock

**Responsable:** Miguel Ángel Taco Zavala  
**Rama:** taco  
**Trazabilidad:** HU [HU-016](../hu/HU-016-dashboard-alertas-stock.md) | Wireframe [WF-016](../wireframes/flows/WF-016-dashboard-alertas-stock.md)

## Descripción

El **Dashboard Analítico y Alertas de Stock** será una funcionalidad adicional orientada al **monitoreo del inventario**, permitiendo visualizar de manera resumida el estado de las variantes y detectar aquellas que requieren atención.

Esta funcionalidad permitirá transformar la información del inventario en indicadores y elementos visuales que faciliten el seguimiento de la disponibilidad de las variantes.

El dashboard estará pensado como una pantalla de consulta rápida, donde se pueda obtener una visión general del estado actual del inventario.

## Unidad de inventario

El dashboard utiliza como **unidad primaria de inventario la Variante/SKU**, en coherencia con la gestión de inventario:

* **Métrica operativa de inventario → SKU vendible:** los indicadores de disponibilidad, stock bajo y agotamiento se expresan sobre variantes.
* **Agrupación comercial → Producto:** el producto es un agrupador comercial. Las variantes pueden presentarse individualmente o agrupadas bajo su producto en una vista comercial, sin que esto cree un stock independiente por producto.

```text
Producto: Nike Air Max

├── SKU-001 → Negro / Talla 40 → stock 5
├── SKU-002 → Negro / Talla 41 → stock 0
└── SKU-003 → Blanco / Talla 40 → stock 8
```

El dashboard podrá mostrar las variantes individualmente y, cuando se requiera una vista comercial, agruparlas bajo "Nike Air Max".

---

## 1. Indicadores de inventario

El dashboard mostrará indicadores que permitan conocer rápidamente la situación general del inventario.

Entre los principales indicadores se podrán considerar:

* Cantidad total de SKUs vendibles.
* Cantidad total de unidades disponibles.
* SKUs con stock bajo.
* SKUs agotados.
* SKUs disponibles.

Estos indicadores permitirán identificar rápidamente el estado general del inventario sin necesidad de revisar cada variante individualmente ni contabilizar los productos como si cada uno tuviera un único stock.

Cuando el dashboard presente una vista comercial, podrá agrupar la información por producto para facilitar su interpretación, manteniendo siempre las variantes como la unidad operativa de inventario.

---

## 2. Alertas de stock

El sistema permitirá identificar variantes cuyo stock se encuentre en estado de stock bajo o agotado, según las reglas deterministas de la gestión de inventario por `(sku, location_id)`:

```text
0 < available <= umbral_efectivo
→ STOCK_BAJO → alerta

available = 0
→ AGOTADO → alerta
```

El `umbral_efectivo` se determina mediante la jerarquía: `umbral_efectivo = override SKU ?? umbral_global` (donde existe un umbral global configurable del sistema y un override específico por SKU cuando esté definido).

Cuando la cantidad disponible de una variante alcance el umbral o se encuentre por debajo de él, se mostrará una alerta que permita identificarla oportunamente.

Después de un consumo correctamente registrado, el estado mostrado de la variante debe reflejar el estado calculado resultante: si pasa de **Disponible → Stock bajo**, debe verse como **Stock bajo**; si pasa de **Stock bajo → Agotado**, debe verse como **Agotado**.

### Ejemplo

> **Stock bajo**
> Nike Air Max — SKU-001 (Negro / Talla 40) — 3 unidades disponibles
> umbral_stock_bajo: 5 unidades

Cuando no existan unidades:

> **Variante agotada**
> Nike Air Max — SKU-002 (Negro / Talla 41) — 0 unidades disponibles

Estas alertas permitirán detectar variantes que podrían requerir una reposición de inventario.

### Actualización de la información

El dashboard se actualizará cuando la gestión de inventario notifique un **cambio de stock** de una variante mediante el contrato de evento `inventory.stock.changed`. Ante cada notificación, los indicadores y alertas se recalcularán con el saldo y el estado vigentes de cada variante. La actualización es **reactiva a los cambios del inventario**; no depende de un intervalo fijo ni de un mecanismo adicional de actualización en tiempo real.

El dashboard es una vista **estrictamente de lectura**: únicamente consume `inventory.stock.changed` para recalcular sus proyecciones, **no lo republica** ni deriva de él operaciones de ajuste, reserva o consumo; tales mutaciones pertenecen exclusivamente a la gestión de inventario (WF-015).

---

## 3. Visualización de información

La información del inventario podrá representarse mediante elementos visuales como:

* Tarjetas de indicadores.
* Gráficos.
* Tablas.
* Listados de variantes/SKUs.
* Indicadores de variantes con stock bajo.
* Alertas de variantes agotadas.
* Listados agrupados por producto, cuando se requiera una vista comercial.

El objetivo será presentar la información de manera clara y facilitar su interpretación.

---

## 4. Distribución operativa de stock por ubicación

Cuando Inventario tenga más de una `location_id`, el dashboard podrá resumir la disponibilidad por ubicación sin convertirse en un reporte de ventas. Esta vista permite responder preguntas operativas como dónde existe stock bajo o agotado y evita mezclar el dominio de Inventario con la analítica comercial propia de Ventas/Postventa.

La métrica se define sobre datos autoritativos/proyectados de Inventario:
- total de `on_hand`, `reserved` y `available` por ubicación;
- cantidad de SKUs disponibles, con stock bajo y agotados por ubicación;
- filtros por producto, categoría, marca, SKU y `location_id`;
- posibilidad de agrupar por producto únicamente como presentación comercial, sin crear saldo a nivel producto.

### Ejemplo

> **Ubicación: Tienda San Isidro**
>
> On hand: 420 unidades  
> Reservadas: 18 unidades  
> Disponibles: 402 unidades  
> SKUs con stock bajo: 12  
> SKUs agotados: 4

Si el MVP opera con una única ubicación `DEFAULT`, la sección muestra un único resumen y no fuerza al usuario a seleccionar una ubicación inexistente.

La funcionalidad **no calcula Top de productos vendidos, ventas por canal, vendedor ni otros indicadores de ventas**, porque esas métricas pertenecen al Dashboard y reportes de Ventas/Postventa. Si en el futuro se desea mostrarlas como contexto, deberán consumirse como un dato publicado por el módulo propietario y no reconstruirse desde movimientos de inventario.

## 5. Resultado esperado

El Dashboard Analítico y Alertas de Stock permitirá disponer de una **vista general del estado del inventario**, facilitando la identificación de SKUs con stock bajo o agotado y la distribución de disponibilidad por ubicación, sin asumir propiedad sobre métricas de ventas.

La funcionalidad permitirá:

* Visualizar indicadores generales del inventario a nivel de variante/SKU.
* Identificar variantes con stock bajo, según el umbral configurado por variante.
* Identificar variantes agotadas.
* Mostrar alertas relacionadas con la disponibilidad de las variantes.
* Visualizar la distribución de `on_hand`, `reserved` y `available` por ubicación cuando existan varias ubicaciones.
* Agrupar la información por producto cuando se requiera una vista comercial.
* Representar la información mediante gráficos e indicadores visuales.
* Actualizarse de forma reactiva ante los cambios de stock notificados por la gestión de inventario mediante el contrato de evento `inventory.stock.changed`.

De esta manera, el dashboard complementará la gestión del inventario proporcionando una visión rápida y comprensible de su estado actual y facilitando la identificación de situaciones que requieran atención.
