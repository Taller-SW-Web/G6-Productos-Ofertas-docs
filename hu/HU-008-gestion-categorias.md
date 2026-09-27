# HU-008 — Historia de Usuario: Gestión de categorías y subcategorías

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** Spec [SPEC-008](../specs/SPEC-008-gestion-categorias.md) | Flow [WF-008](../wireframes/flows/WF-008-gestion-categorias.md)

**Como** **gestor comercial**,

**quiero** crear, organizar y mantener las categorías y subcategorías del catálogo

**para** que los clientes y canales de venta puedan navegar y filtrar los productos correctamente.

## Criterios de aceptación

| **ID** | **Criterio** |
| --- | --- |
| **CA-01** | El sistema debe permitir crear una categoría con nombre y descripción, indicando opcionalmente una categoría padre. El nombre NO necesita ser único. |
| **CA-02** | El modelo de categorías es jerárquico y recursivo mediante `categoria_padre_id`. Para el alcance del MVP se configura `MAX_CATEGORY_DEPTH=2` (categoría raíz y subcategoría), sin codificar dos niveles como limitación permanente del modelo. |
| **CA-03** | El sistema no debe permitir que una categoría se asigne como su propia categoría padre (referencia circular). |
| **CA-04** | El sistema debe incluir explícitamente el campo `categoria_padre_id` entre los campos editables al actualizar (junto con nombre, descripción, orden e imagen), sin afectar productos ya asociados. |
| **CA-05** | Al cambiar el `categoria_padre_id`, el sistema debe validar que el nuevo padre esté activo, que no exista ciclo y que no se supere `MAX_CATEGORY_DEPTH`; para el MVP dicho máximo es 2. |
| **CA-06** | El sistema debe permitir desactivar (baja lógica) una categoría, mediante verificación asíncrona confirmada por Catálogo y sin productos activos asociados; no confirma la baja ante timeout, error ni verificación pendiente. |
| **CA-07** | El sistema debe permitir reactivar una categoría previamente desactivada, exigiendo que su categoría padre (si la tuviese) esté en estado activo. |
| **CA-08** | El sistema NUNCA debe eliminar físicamente una categoría; toda baja es lógica. |
| **CA-09** | La administración debe poder consultar el árbol jerárquico completo, incluidas categorías inactivas según permisos; Catálogo Core y los canales externos consumen únicamente el árbol de categorías activas. |
| CA-10 | Al solicitar desactivación, Taxonomía deja la solicitud `PENDING_DEACTIVATION`; Catálogo bloquea altas/activaciones/reasignaciones concurrentes para esa categoría, responde por `operation_id` y solo un resultado `CLEAR` vigente permite confirmar la baja. Un rechazo, timeout o fallo conserva la categoría activa. |
| CA-11 | Antes de cambiar `categoria_padre_id`, se revalidan ciclos, padre activo y `MAX_CATEGORY_DEPTH`. Las características del producto **no se recalculan por jerarquía de categorías**, porque el esquema de atributos pertenece al `tipo_producto_id`. |
| CA-12 | El cambio confirmado de jerarquía y la baja lógica generan eventos versionados que actualizan las vistas de consumidores; no se promete actualización instantánea de todos los canales. |

## Escenarios dado-cuando-entonces

**Escenario 1: Actualización del campo `categoria_padre_id`**
* **DADO** que existe una subcategoría "Accesorios" y una categoría raíz "Fútbol",
* **CUANDO** el gestor actualiza la subcategoría asignando el `categoria_padre_id` de "Fútbol",
* **ENTONCES** el sistema cambia su ubicación en el árbol respetando `MAX_CATEGORY_DEPTH=2` configurado para el MVP.

**Escenario 2: Reactivación de categoría con padre inactivo**
* **DADO** que la categoría "Running" (hija) y "Zapatillas" (padre) están inactivas,
* **CUANDO** el gestor solicita reactivar "Running",
* **ENTONCES** el sistema arroja un error requiriendo reactivar primero la categoría padre.

**Escenario 3: Baja lógica y productos**
* **DADO** que una categoría tiene al menos un producto activo,
* **CUANDO** se intenta desactivar,
* **ENTONCES** se bloquea la acción para no dejar productos huérfanos en canales de venta.

## Reglas resueltas (formalizadas)
* **Categoría padre editable:** Se confirma que `categoria_padre_id` se mantiene como campo editable en CA-04.
* **Reactivación:** Alineado completamente con la especificación (Escenario 2).
* **Reglas abiertas:** Para el MVP se configura una profundidad máxima de 2 niveles sobre un modelo jerárquico recursivo; se mantiene la verificación asíncrona con barrera de escrituras en Catálogo y la prohibición absoluta de eliminación física.

---

**Escenario 4: Baja pendiente y creación concurrente**
* **DADO** una categoría sin productos activos,
* **CUANDO** se solicita su baja y Catálogo acepta verificarla,
* **ENTONCES** Catálogo bloquea la activación o reasignación concurrente a esa categoría y Taxonomía solo confirma la baja al recibir `CLEAR` para la operación vigente.

**Escenario 5: Reubicación que excede la profundidad configurada**
* **DADO** una categoría cuya nueva ubicación produciría una profundidad mayor que `MAX_CATEGORY_DEPTH=2` en el MVP,
* **CUANDO** se modifica `categoria_padre_id`,
* **ENTONCES** se rechaza sin cambiar la jerarquía ni alterar el esquema de atributos de los productos existentes.
