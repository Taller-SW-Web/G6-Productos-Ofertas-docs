# HU-010 — Historia de Usuario: Asociación entre tipos de producto y características

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** Spec [SPEC-010](../specs/SPEC-010-asociacion-tipo-producto-caracteristica.md) | Flow [WF-010](../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md)

**Como** **gestor comercial**,

**quiero** definir qué características son aplicables a cada tipo de producto, indicando si son obligatorias u opcionales

**para** que el módulo de Catálogo Core pueda construir formularios de producto dinámicos y consistentes según el esquema del producto, sin acoplar dicho esquema a las categorías de navegación.

## Criterios de aceptación

| **ID** | **Criterio** |
| --- | --- |
| **CA-01** | El sistema debe permitir asociar una característica existente a un tipo de producto existente, indicando si es obligatoria u opcional. El tipo de producto es la entidad que define el esquema de atributos del producto. |
| **CA-02** | El sistema no debe permitir asociar una misma característica dos veces al mismo tipo de producto. |
| **CA-03** | El sistema debe permitir eliminar la asociación entre una característica y un tipo de producto cuando ya no sea aplicable, respetando las verificaciones de uso necesarias para no dejar productos activos en un estado inválido. |
| **CA-04** | El sistema debe exponer, para un tipo de producto dado, el listado de características aplicables junto con su condición de obligatoriedad, vía API de solo lectura. |
| **CA-05** | Si un tipo de producto o una característica se desactiva, sus asociaciones dejan de estar disponibles para nuevas altas o activaciones, sin necesidad de eliminarlas físicamente ni reescribir el histórico. |
| **CA-06** | Las categorías y subcategorías son exclusivamente de navegación/clasificación y no determinan ni heredan el esquema de características. En el MVP cada producto conserva una única `categoria_id`, que puede modificarse sin alterar automáticamente su `tipo_producto_id` ni sus atributos. |
| **CA-07** | Cada producto referencia un único `tipo_producto_id` para definir su esquema. Cambiar el tipo de producto de un producto existente no es una edición trivial: requiere validar compatibilidad de atributos obligatorios e identificadores y, si afecta identidad de variantes, debe tratarse como una migración controlada fuera del CRUD ordinario. |
| **CA-08** | El número máximo de características asociables a un tipo de producto es un **límite técnico configurable**. Para el MVP se usa 20 como valor inicial, sin presentarlo como una restricción empresarial permanente. |
| **CA-09** | Si una característica cambia de opcional a obligatoria, los productos existentes no se invalidan inmediatamente; la obligatoriedad se exige en la siguiente edición/guardado o proceso explícito de validación/migración. |
| **CA-10** | La consulta debe indicar las características efectivas del tipo de producto, su obligatoriedad y su estado. No existe origen «heredado por categoría» porque las asociaciones son directas al tipo de producto. |
| **CA-11** | Asociar o reactivar una característica verifica el límite técnico configurado del tipo de producto y la compatibilidad con productos/variantes activos; un incumplimiento rechaza la operación sin alterar las asociaciones existentes. |
| **CA-12** | Modificar la clasificación de un producto en el árbol de categorías no recalcula sus características. Cambiar `tipo_producto_id`, cuando se habilite mediante migración, sí debe revalidar atributos obligatorios e identidad de variantes antes de confirmarse. |

## Escenarios dado-cuando-entonces

**Escenario 1: Asociación exitosa de una característica obligatoria**

* **DADO** que existen el tipo de producto "Zapatilla" (id 10) y la característica "Talla" (id 3), ambos activos,
* **CUANDO** el gestor comercial asocia la característica 3 al tipo de producto 10 marcándola como obligatoria,
* **ENTONCES** el sistema registra la asociación y la característica "Talla" aparece como obligatoria al consultar el esquema de "Zapatilla".

**Escenario 2: Intento de asociar una característica ya asociada al mismo tipo**

* **DADO** que la característica "Talla" ya está asociada al tipo de producto "Zapatilla",
* **CUANDO** el gestor comercial intenta asociar nuevamente "Talla" a "Zapatilla",
* **ENTONCES** el sistema rechaza la operación e indica que la asociación ya existe.

**Escenario 3: Consulta exitosa de características de un tipo de producto**

* **DADO** que el tipo de producto "Zapatilla" tiene asociadas las características "Talla" (obligatoria) y "Color" (opcional),
* **CUANDO** Catálogo Core solicita las características del tipo de producto "Zapatilla",
* **ENTONCES** el sistema devuelve ambas características indicando correctamente cuál es obligatoria y cuál opcional.

**Escenario 4: Consulta de tipo de producto sin asociaciones**

* **DADO** que el tipo de producto "Accesorio genérico" no tiene ninguna característica asociada,
* **CUANDO** se solicita su listado de características,
* **ENTONCES** el sistema devuelve una lista vacía sin generar error.

**Escenario 5: Desasociación exitosa**

* **DADO** que la característica "Material" está asociada al tipo de producto "Balón" y la verificación de uso permite retirarla,
* **CUANDO** el gestor comercial elimina esa asociación,
* **ENTONCES** el sistema deja de listar "Material" como característica aplicable para nuevas ediciones de productos de tipo "Balón" y conserva el histórico existente.

**Escenario 6: Intento de desasociar una relación inexistente**

* **DADO** que la característica "Talla" nunca fue asociada al tipo de producto "Balón",
* **CUANDO** el gestor comercial intenta eliminar esa asociación inexistente,
* **ENTONCES** el sistema devuelve un error indicando que la asociación no existe.

**Escenario 7: Categoría de navegación no modifica el esquema**

* **DADO** un producto de tipo "Zapatilla" con "Talla" obligatoria y `categoria_id=Running`,
* **CUANDO** el gestor cambia su categoría de navegación a "Ofertas",
* **ENTONCES** el producto conserva el mismo `tipo_producto_id` y el mismo esquema de características; únicamente cambia su clasificación de navegación.

**Escenario 8: Cambio de opcional a obligatoria**

* **DADO** que existen productos antiguos de un tipo sin valor para "Color",
* **CUANDO** "Color" pasa de opcional a obligatoria en ese tipo,
* **ENTONCES** los productos conservan su estado hasta su próxima edición o migración; al guardarlos, se exige completar "Color".

**Escenario 9: Límite técnico configurable de características**

* **DADO** que un tipo de producto alcanzó el límite técnico configurado, cuyo valor MVP es 20 características activas,
* **CUANDO** el gestor intenta agregar una adicional,
* **ENTONCES** el sistema rechaza la asociación e informa el límite configurado, sin tratar el número 20 como una regla empresarial inmutable.

**Escenario 10: Cambio de tipo que afectaría identidad de variantes**
* **DADO** un producto con variantes cuyo tipo actual define características identificadoras ya utilizadas por sus SKU,
* **CUANDO** se intenta cambiar a otro tipo de producto incompatible,
* **ENTONCES** el CRUD ordinario no modifica la identidad existente y deriva el cambio a una migración controlada o lo rechaza según el alcance habilitado.

## Interacción con otros módulos

| **Módulo** | **Necesidad de interacción** | **Información que esta funcionalidad recibe** | **Información que esta funcionalidad entrega** |
| --- | --- | --- | --- |
| **Seguridad y Usuarios** | Verificar permisos de administración de esquemas de producto; la definición de roles concretos pertenece al módulo de Seguridad. | Identidad del usuario, token de sesión y permisos. | Solicitudes de validación de permisos para las operaciones de escritura. |
| **Catálogo Core (Productos)** | Consultar, al crear o editar un producto, qué características debe solicitar según su `tipo_producto_id`. | Identificador del tipo de producto del producto a crear/editar. | Listado de características aplicables a ese tipo, con su condición de obligatoriedad. |

## Dependencias dentro de Productos y Ofertas

| **Funcionalidad interna** | **Información necesaria** |
| --- | --- |
| **Gestión de categorías y subcategorías** | Árbol de navegación independiente; no define el esquema de características del producto. |
| **Gestión de características y sus valores** | Identificador, tipo, valores y estado de la característica a asociar. |
| **Gestión de productos y variantes** | `tipo_producto_id`, atributos actuales y uso de características identificadoras para validar cambios incompatibles. |

## Reglas de negocio consolidadas

* **Separación de responsabilidades:** las categorías clasifican para navegación; el tipo de producto define el esquema de atributos.
* **Límite:** máximo configurable de características por tipo; el MVP parte de 20 como guardrail técnico.
* **Obligatoriedad:** el cambio de opcional a obligatoria no invalida productos preexistentes de inmediato; se exige al siguiente guardado o migración.
* **Identidad:** un cambio de tipo que altere características identificadoras no reescribe SKU existentes y requiere una migración controlada.
