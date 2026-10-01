# HU-010 — Historia de Usuario: Asociación entre tipos de producto y características

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** Spec [SPEC-010](../specs/SPEC-010-asociacion-tipo-producto-caracteristica.md) | Flow [WF-010](../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md)

**Como** gestor comercial,  
**quiero** definir qué características son aplicables a cada tipo de producto e indicar si son obligatorias u opcionales,  
**para** que Catálogo construya formularios y valide productos mediante un esquema versionado independiente de las categorías de navegación.

## Criterios de aceptación

| ID | Criterio |
|---|---|
| **CA-01** | El sistema permite asociar una característica activa a un tipo de producto activo, indicando `OBLIGATORIA` u `OPCIONAL`. |
| **CA-02** | No permite asociar dos veces la misma característica al mismo tipo. |
| **CA-03** | La cantidad de asociaciones activas no supera `MAX_PRODUCT_TYPE_ATTRIBUTES`; el valor inicial del MVP es 20 y sigue siendo configurable. |
| **CA-04** | La consulta de un tipo devuelve sus características aplicables, obligatoriedad, metadatos y `schema_version`. Sin asociaciones devuelve lista vacía. |
| **CA-05** | Las categorías solo clasifican para navegación; mover un producto de categoría no cambia `tipo_producto_id` ni recalcula su esquema. |
| **CA-06** | Cambiar una característica de opcional a obligatoria no desactiva productos existentes; la nueva obligación se exige en la siguiente edición/guardado o activación conforme a Catálogo. |
| **CA-07** | Cada modificación confirmada de asociaciones incrementa `schema_version`. |
| **CA-08** | Una desasociación que pueda afectar productos/variantes activos se procesa mediante verificación segura; `202 Accepted` no significa que la asociación ya se eliminó. |
| **CA-09** | Si una característica identifica variantes activas o su retiro dejaría productos activos incompatibles, se rechaza la desasociación y se conserva la asociación. |
| **CA-10** | Error, timeout o ausencia de resultado de la verificación no autorizan la baja. |
| **CA-11** | Un tipo de producto con productos activos no se desactiva sin verificación segura confirmada. |
| **CA-12** | Un tipo inactivo o una característica inactiva no pueden usarse en nuevas altas/activaciones; el histórico no se borra. |
| **CA-13** | Reactivar un tipo conserva su identidad y permite volver a utilizarlo sujeto a las reglas vigentes. |
| **CA-14** | Todo cambio confirmado del esquema publica `taxonomy.product-type-schema.changed` hacia Catálogo con `tipo_producto_id`, versión vigente y naturaleza del cambio; la publicación incluye el cambio de obligatoriedad y la desasociación confirmada, no solo la asociación inicial. |
| **CA-15** | La baja segura de `PRODUCT_TYPE` y `PRODUCT_TYPE_CHARACTERISTIC` usa el flujo transversal publicado en AsyncAPI 0.4.0; la UI continúa tratando `202 Accepted` solo como admisión. |
| **CA-16** | Cambiar `tipo_producto_id` de un producto publicado o con variantes es una migración controlada fuera del CRUD ordinario. |
| **CA-17** | Las escrituras requieren usuario autenticado/autorizado; los nombres exactos de permisos granulares pertenecen a Seguridad. |

## Escenarios dado-cuando-entonces

### Escenario 1: Asociación exitosa

- **DADO** un tipo "Zapatilla" activo
- **Y** una característica "Talla" activa
- **CUANDO** el gestor la asocia como obligatoria
- **ENTONCES** se registra una única asociación y aumenta la versión del esquema.

### Escenario 2: Asociación duplicada

- **DADO** que "Talla" ya pertenece al esquema
- **CUANDO** se intenta asociar nuevamente
- **ENTONCES** se rechaza sin alterar la versión confirmada.

### Escenario 3: Consulta sin asociaciones

- **DADO** un tipo "Accesorio genérico" sin características
- **CUANDO** Catálogo consulta el esquema
- **ENTONCES** obtiene una lista vacía y la versión vigente.

### Escenario 4: Cambio de categoría

- **DADO** un producto de tipo "Zapatilla"
- **CUANDO** cambia de "Running" a "Ofertas"
- **ENTONCES** conserva su tipo y esquema.

### Escenario 5: Opcional a obligatoria

- **DADO** productos legados sin "Color"
- **CUANDO** "Color" pasa a obligatoria
- **ENTONCES** los productos no se desactivan automáticamente y la obligación se exige al volver a guardarlos/activarlos.

### Escenario 6: Desasociación segura admitida

- **DADO** una asociación cuya baja requiere verificación
- **CUANDO** el gestor confirma
- **ENTONCES** la UI muestra «Verificando uso» y no la elimina al recibir únicamente la admisión HTTP.

### Escenario 7: Desasociación confirmada

- **DADO** una solicitud pendiente
- **CUANDO** Catálogo confirma que no existe uso incompatible
- **ENTONCES** se desasocia lógicamente, aumenta `schema_version` y se actualiza la vista.

### Escenario 8: Desasociación rechazada

- **DADO** que "Talla" identifica variantes activas
- **CUANDO** se solicita su baja
- **ENTONCES** el resultado se rechaza y "Talla" permanece en el esquema.

### Escenario 9: Verificación no concluyente

- **DADO** una solicitud de baja
- **CUANDO** la verificación falla o no produce resultado confiable
- **ENTONCES** se conserva el estado anterior y se informa que no pudo completarse.

### Escenario 10: Desactivar tipo con productos activos

- **DADO** un tipo utilizado por productos activos
- **CUANDO** se solicita desactivarlo
- **ENTONCES** la operación entra en verificación y se rechaza si Catálogo informa uso activo.

### Escenario 11: Desactivar tipo no utilizado

- **DADO** un tipo sin productos activos
- **CUANDO** la verificación devuelve resultado seguro
- **ENTONCES** el tipo pasa a inactivo y deja de estar disponible para nuevas altas.

### Escenario 12: Cambio de tipo incompatible

- **DADO** un producto con variantes publicadas
- **CUANDO** se intenta cambiar su tipo mediante edición ordinaria
- **ENTONCES** se rechaza o deriva a una migración controlada; no se reescriben las identidades existentes.

## Interacción con otros módulos

| Módulo | Necesidad | Recibe | Entrega |
|---|---|---|---|
| Seguridad y Usuarios | Autorizar escrituras | Token/claims/permisos | Autorización o 401/403 |
| Catálogo Core | Construir/validar formularios | `tipo_producto_id`, versión y verificaciones de uso | Esquema efectivo; solicitudes/resultados de baja segura |
| Carga Masiva | Validar filas por tipo | `tipo_producto_id` | Esquema versionado |

## Dependencias internas

- Gestión de categorías: navegación, sin herencia de características.
- Gestión de características: IDs, tipo, valores y estado.
- Gestión de productos/variantes: uso real de las características e identidad SKU.

## Estado contractual relevante

AsyncAPI `0.4.0` publica los contratos requeridos por esta HU:

- `PRODUCT_TYPE` y `PRODUCT_TYPE_CHARACTERISTIC` forman parte del flujo transversal de baja segura;
- `taxonomy.product-type-schema.changed` propaga cada modificación confirmada del esquema a Catálogo;
- `202 Accepted` continúa significando **solicitud admitida**, no baja finalizada.

La integración asíncrona de esta HU queda cerrada sin modificar la regla funcional de fallo seguro.
