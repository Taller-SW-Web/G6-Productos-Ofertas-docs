# HU-004 — Historia de Usuario: Gestión avanzada de variantes (SKUs)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** Spec [SPEC-004](../specs/SPEC-004-gestion-variantes-skus.md) | Flow [WF-004](../wireframes/flows/WF-004-gestion-variantes-skus.md)

## Historia de usuario principal

Como gestor comercial,
quiero definir y administrar variantes (SKU) de un producto según sus características distintivas —por ejemplo, talla y color—, cada una con su propia imagen, identificador interno inmutable (`variant_id`) y SKU comercial único (suministrado o autogenerado),
para que el catálogo permita vender exactamente la versión que el cliente elige, y que cada canal pueda mostrarla y consultar su disponibilidad de forma independiente.

Esta funcionalidad solo aplica a productos con el atributo `tiene_variantes = true`. Una variante hereda del producto padre los datos generales (nombre, descripción, categoría, marca), pero tiene su propio SKU (inmutable) y su propia imagen. **El stock nunca lo almacena ni lo calcula este componente**: siempre es propiedad del componente de Inventario, tanto para variantes como para productos simples sin variantes.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | Solo un gestor comercial con los permisos correspondientes puede crear, modificar o desactivar variantes de un producto. |
| CA-02 | Una variante debe asociarse a un producto existente con `tiene_variantes = true` y definir valores de las características identificadoras permitidas por el `tipo_producto_id` del padre (ej. talla, color), heredando los demás datos del producto cuando corresponda. |
| CA-03 | El sistema genera siempre un `variant_id` interno, inmutable y no significativo. El **SKU comercial** de la variante puede ser proporcionado por el gestor/importación si cumple unicidad global y formato, o puede dejarse vacío para generación automática a partir de `sku_base` y atributos. El SKU no funciona como clave primaria interna. |
| CA-04 | Cada variante debe tener al menos una imagen propia que la represente. |
| CA-05 | El sistema debe impedir el registro de dos variantes de un mismo producto con exactamente la misma combinación de características identificadoras (ej. dos variantes "Talla 42 – Negro"). |
| CA-06 | El gestor comercial puede consultar todas las variantes de un producto, filtrando por característica o por estado. |
| CA-07 | Al crear una variante, el sistema debe **notificar** al componente de Inventario para que este inicialice su stock en 0; Variantes no almacena ni calcula esa cantidad, solo consulta disponibilidad cuando lo necesita. |
| CA-08 | Un producto con `tiene_variantes = true` no puede pasar a estado "activo" ni mostrarse en los canales de venta si no tiene al menos una variante activa con SKU e imagen válidos. Un producto con `tiene_variantes = false` se activa directamente según las reglas de Gestión de Productos, sin pasar por esta funcionalidad. |
| CA-09 | Al desactivar una variante, esta deja de mostrarse en canales y conserva su registro histórico; las demás variantes mantienen sus stocks. Si era la última variante ACTIVA, el producto padre pasa también a INACTIVO en la misma transacción de Catálogo. |
| CA-10 | Las características identificadoras que definen la identidad comercial de una variante (ej. talla, color) son **inmutables** una vez creada, aunque el SKU haya sido suministrado externamente. Para cambiarlas se desactiva la variante y se crea otra. Atributos no identificadores e imagen sí son editables. |
| CA-11 | Toda operación de registro, actualización o desactivación de una variante debe quedar trazable con usuario, fecha/hora y resultado. |
| CA-12 | Pricing puede definir un precio específico para un SKU de variante; si no existe override, se usa el precio base vigente del producto. |
| CA-13 | Los combos referencian componentes por SKU vendible; para una variante utilizan su SKU y para un producto simple su `sku_base`. |
| CA-14 | Los pedidos confirmados conservan un snapshot del SKU vendido aunque la variante se desactive posteriormente. |
| CA-15 | Una variante nueva inicia en BORRADOR; solo puede activarse si posee `variant_id`, SKU comercial único (suministrado o generado), atributos identificadores e imagen válidos, precio aplicable confirmado y registro inicializado en Inventario. |
| CA-16 | Una variante INACTIVA puede reactivarse tras las mismas validaciones y conserva su SKU; el producto padre no se reactiva automáticamente. |
| CA-17 | Una fila de carga masiva que crea variante identifica padre existente o creado como BORRADOR por grupo `sku_base`, `tipo_producto_id` y atributos. Catálogo genera `variant_id` y devuelve el SKU comercial validado o generado correlacionado por `batch_id`/`row_id`; un SKU informado se acepta solo si cumple las reglas de unicidad y formato. |
| CA-18 | Una variante ACTIVA no es vendible mientras su producto padre esté BORRADOR o INACTIVO. La activación de una variante preparada no activa automáticamente el producto padre. |
| CA-19 | Antes de la primera variante, el gestor configura por producto con `tiene_variantes=true` uno o más `caracteristica_id` LISTA activos y definidos por su **tipo de producto**; tras crear la primera variante el conjunto queda inmutable para el CRUD ordinario incluso si luego se desactiva. |
| CA-20 | Cada variante proporciona exactamente un `valor_id` activo por característica identificadora configurada; la unicidad se valida por IDs de la combinación incluso frente a variantes inactivas. Renombrar etiquetas no cambia identidad ni SKU. Cambiar categorías de navegación no invalida esta configuración; un cambio incompatible de tipo de producto requiere migración. |

## Escenarios dado-cuando-entonces

**Escenario 1: Registrar una variante válida**
● DADO que existe el producto "Zapatillas Running ProSpeed X" con `tiene_variantes = true`, en estado borrador o activo,
● CUANDO el gestor comercial registra una variante con talla "42", color "Negro", una imagen propia y no suministra un SKU comercial manual,
● ENTONCES el sistema genera un identificador interno inmutable (`variant_id`), genera automáticamente un SKU comercial único para la variante según la regla de nomenclatura, la guarda en estado "borrador" y notifica al componente de Inventario para que inicialice su stock en 0.

**Escenario 2: Rechazar una combinación de características duplicada**
● DADO que ya existe la variante "Talla 42 – Negro" para el producto,
● CUANDO el gestor comercial intenta registrar otra variante con la misma combinación de talla y color,
● ENTONCES el sistema rechaza el registro e indica que esa combinación ya existe para el producto.

**Escenario 3: Rechazar una variante sin imagen propia**
● DADO que el gestor comercial completa las características de la variante pero no adjunta ninguna imagen,
● CUANDO intenta guardar la variante,
● ENTONCES el sistema impide guardar y solicita al menos una imagen para esa variante.

**Escenario 4: Impedir la activación de un producto con variantes sin ninguna variante válida**
● DADO que un producto con `tiene_variantes = true` no tiene ninguna variante registrada o todas están desactivadas,
● CUANDO el gestor comercial intenta activar el producto para que sea visible en los canales de venta,
● ENTONCES el sistema impide la activación e indica que debe existir al menos una variante activa con SKU e imagen válidos.

**Escenario 5: Actualizar los atributos no identificadores de una variante**
● DADO que existe una variante registrada,
● CUANDO el gestor comercial modifica su imagen o un atributo que no forma parte del SKU (ej. material),
● ENTONCES el sistema guarda los cambios, conserva el historial de la modificación y actualiza la información disponible para los canales, sin alterar el SKU existente.

**Escenario 6: Rechazar el cambio de un atributo que forma parte del SKU**
● DADO que existe la variante con SKU "ZAP-PSX-42-NEG" (talla 42, color negro),
● CUANDO el gestor comercial intenta modificar el color a "blanco" en esa misma variante,
● ENTONCES el sistema rechaza el cambio e indica que debe desactivar la variante actual y registrar una nueva con el atributo correcto, ya que el color forma parte del SKU y es inmutable.

**Escenario 7: Consultar las variantes de un producto**
● DADO que un producto tiene varias variantes registradas en distintos estados,
● CUANDO el gestor comercial consulta las variantes filtrando por característica o por estado,
● ENTONCES el sistema devuelve la lista de variantes que cumplen los filtros, con su SKU, imagen y estado.

**Escenario 8: Desactivar una variante**
● DADO que existe una variante activa,
● CUANDO el gestor comercial la desactiva,
● ENTONCES el sistema conserva su registro, deja de mostrarla en los canales de venta y la marca como no disponible para nuevos pedidos, sin afectar a las demás variantes del producto.

**Escenario 9: Producto simple sin variantes**
● DADO que un producto tiene `tiene_variantes = false`,
● CUANDO el gestor comercial intenta acceder a la gestión de variantes de ese producto,
● ENTONCES el sistema indica que el producto no maneja variantes y que su activación se administra en Gestión de Productos y su stock exclusivamente en Inventario.

**Escenario 10: Usuario sin permisos intenta modificar una variante**
● DADO que un usuario autenticado no tiene el rol de gestor comercial ni el permiso correspondiente,
● CUANDO intenta registrar, actualizar o desactivar una variante,
● ENTONCES el sistema rechaza la solicitud con un error de autorización y no aplica ningún cambio.

**Escenario 11: Activar una variante preparada**
* **DADO** una variante BORRADOR con SKU, imagen válida y stock inicializado a 0 en Inventario,
* **CUANDO** el gestor solicita activarla y se valida precio base del padre y entidades maestras,
* **ENTONCES** pasa a ACTIVA sin modificar su SKU.

**Escenario 12: Desactivar la última variante activa**
* **DADO** un producto activo con una sola variante activa,
* **CUANDO** esta se desactiva,
* **ENTONCES** el producto padre también pasa a INACTIVO y ambos dejan de ofrecerse para nuevas ventas.

**Escenario 13: Creación masiva e individual con SKU comercial o autogenerado**
* **DADO** una fila o solicitud de registro con producto padre y atributos identificadores,
* **CUANDO** se envía con un SKU comercial informado (ej. de ERP/proveedor), el sistema valida formato y unicidad global y lo conserva; si el campo SKU se omite o viene vacío, el sistema genera automáticamente el SKU comercial a partir de la regla configurada,
* **ENTONCES** Catálogo asigna un `variant_id` interno inmutable, registra la variante asociada a la fila/solicitud y notifica a Inventario.

**Escenario 14: Variante activa con padre borrador**
* **DADO** una variante preparada y ACTIVA, cuyo producto padre continúa BORRADOR,
* **CUANDO** un canal consulta artículos disponibles para comprar,
* **ENTONCES** no se ofrece esa variante hasta que el producto padre sea activado satisfactoriamente.

**Escenario 15: Configurar y congelar identificadores**
* **DADO** un producto con variantes aún sin variantes y características LISTA efectivas «Talla» y «Color»,
* **CUANDO** el gestor selecciona ambas y crea su primera variante con un `valor_id` de cada una,
* **ENTONCES** se genera su SKU y ya no se permite cambiar el conjunto identificador del producto.

**Escenario 16: Rechazar característica o valor inválido**
* **DADO** un producto con identificadores LISTA configurados,
* **CUANDO** se intenta crear una variante con valor desactivado, tipo TEXTO o una combinación repetida aunque esté inactiva,
* **ENTONCES** se rechaza sin generar un nuevo SKU.

## Interacción con otros módulos

| Módulo | Necesidad de interacción | Información que esta funcionalidad recibe | Información que esta funcionalidad entrega |
|---|---|---|---|
| Canal Marketplace | Mostrar al cliente las variantes disponibles de un producto para que elija la versión exacta a comprar. | Identificador del producto consultado. | Lista de variantes con SKU, característica distintiva (talla/color), imagen propia y estado (la disponibilidad de stock la entrega Inventario, no este componente). |
| Canal Chatbot | Permitir que el cliente indique conversacionalmente la variante deseada (ej. "talla 42, negro") y validar que exista. | Producto y características mencionadas en la conversación. | SKU de la variante encontrada, su imagen y estado. |
| Canal Retail | Permitir que el vendedor seleccione o escanee la variante exacta durante la venta asistida. | Identificador de producto o SKU escaneado. | Detalle de la variante: SKU, imagen, características y estado. |
| Ventas y Postventa | Registrar en el pedido el SKU exacto de la variante vendida, no solo el producto genérico. | SKU de la variante incluida en el pedido. | Nombre, características, imagen y estado de esa variante, como snapshot del pedido. |
| Seguridad y Usuarios | Verificar quién puede crear, actualizar o desactivar variantes. | Identidad autenticada, roles y permisos mediante el mecanismo de autenticación acordado. | Solicitudes de validación de identidad o permisos, cuando el mecanismo de integración lo requiera. |

## Dependencias dentro de Productos y Ofertas

Estas son coordinaciones internas con otras funcionalidades del mismo módulo.

| Funcionalidad interna | Información necesaria |
|---|---|
| Gestión de productos (misma persona) | Identificador, `sku_base`, nombre, categoría, marca, estado y bandera `tiene_variantes` del producto padre, del cual la variante hereda los datos generales. |
| Marcas y características — Persona 1 | Catálogo de características disponibles (ej. talla, color) para asociarlas a cada variante como identificador del SKU. |
| Inventario y stock — Persona 6 | Notificación de variante creada o desactivada, para que Inventario inicialice y gestione su stock de forma independiente por SKU. Variantes nunca almacena ni calcula cantidades; solo consulta disponibilidad cuando el canal lo requiere. |
| Gestión de precios — Persona 3 | Una variante puede tener precio específico por SKU; si no existe, hereda el precio base vigente del producto. |
| Agrupaciones y combos — Persona 5 | Los combos referencian componentes por SKU vendible. |

## Reglas de negocio consolidadas

1. Una variante puede tener precio específico en Pricing; si no lo tiene, hereda el precio base del producto.
2. `tiene_variantes` es inmutable después de crear el producto.
3. Combos trabaja con SKUs vendibles.
4. Promociones pueden tener alcance a nivel producto o SKU según su configuración.
5. Los pedidos confirmados conservan snapshot de la variante aunque después sea desactivada.
