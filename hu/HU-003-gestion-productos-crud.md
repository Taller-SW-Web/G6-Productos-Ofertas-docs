# HU-003 — Historia de Usuario: Gestión de productos (CRUD principal)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** Spec [SPEC-003](../specs/SPEC-003-gestion-productos-crud.md) | Flow [WF-003](../wireframes/flows/WF-003-gestion-productos-crud.md)

## Historia de usuario principal

Como gestor comercial,
quiero registrar, actualizar, consultar, desactivar y reactivar productos del catálogo, definiendo sus datos generales, categoría, marca, características, imágenes y precio base referencial,
para que estén disponibles y actualizados en el catálogo central que consultan los canales de venta (Marketplace, Chatbot y Retail).

Un producto pasa por tres estados: **borrador** (recién creado, aún no visible), **activo** (visible y disponible para los canales) e **inactivo** (desactivado; conserva su registro e historial pero no se muestra). Solo se ve en los canales de venta mientras está en estado "activo".

## Criterios de aceptación

| ID | Criterio |
|---|---|
| CA-01 | Solo un gestor comercial con los permisos correspondientes puede crear, modificar, activar, desactivar o reactivar productos. |
| CA-02 | Para **crear** un producto (estado "borrador") se requiere nombre, descripción, una categoría de navegación (`categoria_id`), `tipo_producto_id`, marca, precio base referencial, `sku_base` y `tiene_variantes`. No se exige imagen ni completar todavía todos los atributos del tipo. |
| CA-03 | El sistema valida que la categoría de navegación (`categoria_id`), el tipo de producto y la marca indicados existan y estén activos antes de guardar o activar según corresponda. La categoría clasifica el producto; `tipo_producto_id` define su esquema de atributos. |
| CA-04 | El sistema debe impedir el registro de un producto con el mismo `sku_base` que otro existente. Si detecta la misma combinación normalizada `(nombre, marca_id)`, debe mostrar una **advertencia de posible duplicado** y permitir continuar con confirmación explícita si el `sku_base` y la identidad del producto son distintos. |
| CA-05 | Un producto solo puede pasar de "borrador" a "activo" cuando, además de los campos de CA-02, tenga completos **todos los valores obligatorios definidos por su tipo de producto** y al menos una imagen. Si el tipo no define atributos obligatorios, no se exige inventar uno para activar. Si `tiene_variantes=true`, requiere también una variante ACTIVA válida. La publicación comercial espera confirmaciones de preparación de Pricing e Inventario para los SKU vendibles. |
| CA-06 | El gestor comercial puede consultar los productos registrados, filtrando por categoría, marca o estado, y ver el detalle completo de cada uno. |
| CA-07 | Al actualizar un producto, el sistema valida las mismas reglas según su estado. Los cambios válidos se propagan por eventos y no se garantiza visibilidad instantánea global. `tiene_variantes` y `tipo_producto_id` no se cambian como edición ordinaria cuando afecten identidad/variantes; una transformación estructural se trata como migración controlada fuera del CRUD normal. |
| CA-08 | Al desactivar un producto, deja de mostrarse para nuevas ventas, conserva su registro/snapshot histórico y emite `catalog.product.deactivated` para que Promociones, Combos y otros consumidores reaccionen. |
| CA-09 | Un producto inactivo puede reactivarse; al reactivarlo, el sistema debe volver a validar las condiciones de CA-05 antes de marcarlo como "activo" nuevamente. |
| CA-10 | El sistema genera y mantiene el **slug** del producto (a partir del nombre) como parte de este componente; no depende del componente de Taxonomía y SEO. |
| CA-11 | El precio base ingresado en la creación se notifica al Motor de Precios para abrir su historial de auditoría; las actualizaciones posteriores del precio (individuales o masivas) son responsabilidad exclusiva de ese componente, no de Catálogo Core. |
| CA-12 | Toda operación (registro, actualización, activación, desactivación, reactivación) debe quedar trazable con usuario, fecha/hora y resultado. |
| CA-13 | Si se desactiva la última variante ACTIVA de un producto con variantes, Catálogo inactiva el producto padre en la misma transacción local; las demás entidades y pedidos históricos conservan sus datos. |
| CA-14 | Una barrera de baja de categoría o marca impide crear, activar o reasignar productos a esa entidad durante la verificación asíncrona; Catálogo confirma el resultado por `operation_id`. |
| CA-15 | El producto no se ofrece comercialmente hasta que Pricing confirme la preparación de su precio y, para el SKU vendible ofrecido, Inventario confirme la inicialización. |
| CA-16 | Al crear un producto, el precio base se solicita a Pricing con operación idempotente; el evento `pricing.price.changed` lo emite Pricing tras persistirlo, no Catálogo. |
| CA-17 | Durante la baja asíncrona de un valor LISTA identificador o requerido, Catálogo bloquea nuevos vínculos bajo barrera, confirma el uso activo con `operation_id` y no altera SKU/pedidos. Un producto `tiene_variantes=true` selecciona sus características identificadoras entre las LISTA activas definidas por su `tipo_producto_id` antes de crear la primera variante; después no las cambia por edición ordinaria. Cambiar la categoría de navegación no modifica esta configuración. |

## Escenarios dado-cuando-entonces

**Escenario 1: Registrar un producto en borrador**
● DADO que el gestor comercial tiene permisos,
● CUANDO registra un producto con nombre, descripción, categoría de navegación (`categoria_id`), `tipo_producto_id`, marca, precio base referencial, `sku_base` y `tiene_variantes` válidos, sin imagen ni completar aún todos los atributos del tipo,
● ENTONCES el sistema lo guarda en estado "borrador", genera su identificador y slug, y confirma el registro al gestor.

**Escenario 2: Activar un producto completo**
● DADO que un producto en borrador tiene categoría (`categoria_id`), tipo de producto (`tipo_producto_id`) y marca activos, todos los valores obligatorios definidos por su tipo completos (o ninguno si el tipo no exige obligatorios), al menos una imagen, variante activa válida si `tiene_variantes=true`, y confirmación de preparación de Pricing e Inventario,
● CUANDO el gestor comercial solicita su activación,
● ENTONCES el sistema cambia su estado a "activo" y lo hace visible para los canales de venta.

**Escenario 3: Rechazar activación incompleta**
● DADO que un producto en borrador no tiene ninguna imagen, o tiene una o más características obligatorias definidas por su tipo de producto (`tipo_producto_id`) sin valor, o `tiene_variantes=true` sin al menos una variante activa, o no cuenta con la confirmación de Pricing o Inventario,
● CUANDO el gestor comercial intenta activarlo,
● ENTONCES el sistema impide la activación, indica qué requisito falta y mantiene el producto en "borrador".

**Escenario 4: Rechazar categoría, tipo o marca inválida**
● DADO que el gestor comercial está registrando o actualizando un producto,
● CUANDO selecciona una categoría, tipo de producto o marca que no existe o está desactivada,
● ENTONCES el sistema impide guardar el producto e indica cuál relación no es válida.

**Escenario 5: Rechazar `sku_base` duplicado y advertir posible duplicado nombre+marca**
● DADO que existe un producto con `sku_base` "ZAP-PSX", o un producto activo llamado "Zapatillas Running ProSpeed X" de la marca "ProSpeed",
● CUANDO el gestor comercial intenta registrar otro producto con el mismo `sku_base`, o con el mismo nombre y la misma marca,
● ENTONCES el sistema rechaza el registro e indica cuál de las dos reglas de unicidad se violó.

**Escenario 6: Actualizar un producto existente**
● DADO que existe un producto registrado y el gestor comercial cuenta con permisos,
● CUANDO modifica su descripción, valores de atributos del tipo o imágenes con datos válidos,
● ENTONCES el sistema guarda los cambios, conserva el historial de la modificación y actualiza la información disponible para los canales.

**Escenario 7: Consultar productos por filtros**
● DADO que existen productos registrados en distintas categorías y estados,
● CUANDO el gestor comercial consulta el catálogo filtrando por categoría, marca o estado,
● ENTONCES el sistema devuelve la lista de productos que cumplen los filtros con su información principal.

**Escenario 8: Desactivar un producto**
● DADO que existe un producto activo,
● CUANDO el gestor comercial lo desactiva,
● ENTONCES el sistema conserva su registro, deja de mostrarlo a los canales de venta y lo marca como no disponible para nuevos pedidos.

**Escenario 9: Reactivar un producto**
● DADO que existe un producto inactivo que, en su momento, cumplía las condiciones de CA-05,
● CUANDO el gestor comercial solicita su reactivación,
● ENTONCES el sistema vuelve a validar categoría, tipo de producto, marca, características obligatorias de su tipo, variante activa (si aplica) e imagen; si todo es válido lo marca como "activo", y si algo cambió (ej. la categoría o el tipo de producto fue desactivado) rechaza la reactivación e indica el motivo.

**Escenario 10: Usuario sin permisos intenta modificar un producto**
● DADO que un usuario autenticado no tiene el rol de gestor comercial ni el permiso correspondiente,
● CUANDO intenta registrar, actualizar, activar, desactivar o reactivar un producto,
● ENTONCES el sistema rechaza la solicitud con un error de autorización y no aplica ningún cambio.

**Escenario adicional: Última variante activa**
* **DADO** un producto activo con una sola variante activa,
* **CUANDO** el gestor desactiva esa variante,
* **ENTONCES** el producto padre queda INACTIVO en la misma transacción y se notifican ambas bajas, conservando snapshots históricos.

**Escenario adicional: Inicialización de precio pendiente**
* **DADO** un borrador cuya inicialización de precio aún no ha sido confirmada por Pricing,
* **CUANDO** el gestor intenta activarlo,
* **ENTONCES** Catálogo rechaza la activación e informa qué preparación sigue pendiente.

## Interacción con otros módulos

| Módulo | Necesidad de interacción | Información que esta funcionalidad recibe | Información que esta funcionalidad entrega |
|---|---|---|---|
| Canal Marketplace | Mostrar el catálogo y el detalle de cada producto **activo** al cliente. | Filtros de búsqueda: categoría, marca y palabras clave. | Listado y detalle de productos activos: nombre, descripción, precio base, imágenes, categoría, marca, características, slug y estado. |
| Canal Chatbot | Responder consultas conversacionales sobre productos activos y sus características. | Criterios de búsqueda en lenguaje natural traducidos a filtros (precio, categoría, marca). | Productos activos que cumplen los criterios, con descripción, precio e imágenes. |
| Canal Retail | Permitir que el vendedor consulte el catálogo durante la venta asistida. | Filtros de búsqueda o identificador de producto. | Detalle del producto: precio base, características, imágenes y estado (incluye borrador/inactivo para uso administrativo). |
| Ventas y Postventa | Obtener el detalle vigente del producto para armar el pedido o la boleta. | Identificador del producto. | Nombre, precio base vigente, imagen y estado, como snapshot para el pedido. |
| Seguridad y Usuarios | Verificar quién puede crear, actualizar, activar, desactivar o reactivar productos. | Identidad autenticada, roles y permisos mediante el mecanismo de autenticación acordado. | Solicitudes de validación de identidad o permisos, cuando el mecanismo de integración lo requiera. |

## Dependencias dentro de Productos y Ofertas

Estas son coordinaciones internas con otras funcionalidades del mismo módulo.

| Funcionalidad interna | Información necesaria |
|---|---|
| Categorías y subcategorías — Persona 1 | Identificador, nombre y estado de la categoría, para validar su existencia al registrar, actualizar o reactivar un producto. |
| Tipos de producto, marcas y características — Persona 1 | Identificador, nombre y estado del tipo de producto y marca; esquema de características definidas por el tipo de producto para asociarlas al producto. |
| Taxonomía y SEO — Persona 1 | El slug del producto es propiedad de Catálogo Core y se genera aquí; Taxonomía y SEO solo gestiona metadatos adicionales (meta-título, meta-descripción, palabras clave) y no lo sobrescribe. |
| Gestión de precios — Persona 3 | Recibe el precio base inicial del producto al crearse, para abrir su historial de auditoría. Los cambios posteriores del precio (individuales o masivos) son responsabilidad exclusiva de este componente, no de Catálogo Core. |
| Inventario y stock — Persona 6 | Notificación de producto creado para inicializar su stock en 0, **solo si el producto no maneja variantes** (`tiene_variantes = false`). Si el producto maneja variantes, el stock se inicializa por cada variante y no a nivel de producto (ver HU de Gestión de Variantes). |
| Motor de promociones — Persona 4 | Consulta de existencia y estado del producto antes de asociarlo a una promoción (esta funcionalidad es consumida, no consumidora). |
| Agrupaciones y combos — Persona 5 | Consulta de existencia, estado y precio del producto antes de incluirlo en un combo (esta funcionalidad es consumida, no consumidora). |

## Reglas de negocio consolidadas

1. Los cambios válidos sobre productos activos se publican inmediatamente; no existe un estado adicional de revisión.
2. `tiene_variantes` es inmutable después de la creación.
3. Al desactivar un producto se emite `catalog.product.deactivated`; promociones y combos dejan de considerarlo para nuevas operaciones, mientras pedidos confirmados conservan su snapshot.
