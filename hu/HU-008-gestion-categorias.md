# HU-008 — Historia de Usuario: Gestión de categorías y subcategorías

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** Spec [SPEC-008](../specs/SPEC-008-gestion-categorias.md) | Flow [WF-008](../wireframes/flows/WF-008-gestion-categorias.md)

**Como** gestor comercial, **quiero** crear, organizar y mantener categorías/subcategorías, **para** que clientes y canales naveguen y filtren correctamente.

## Criterios de aceptación
| ID | Criterio |
|---|---|
| CA-01 | Crear categoría con nombre, descripción y padre opcional; nombre no único. |
| CA-02 | Modelo recursivo; `MAX_CATEGORY_DEPTH=2` en MVP. |
| CA-03 | No autorreferencia/ciclos. |
| CA-04 | `categoria_padre_id` editable junto con datos de categoría. |
| CA-05 | Reubicar valida padre activo, ciclos y profundidad. |
| CA-06 | Baja lógica solo tras verificación asíncrona segura de productos. |
| CA-07 | Reactivar exige padre activo. |
| CA-08 | Nunca eliminación física. |
| CA-09 | Administración puede ver árbol completo; consumidores externos solo activas. |
| CA-10 | Baja queda `PENDING_DEACTIVATION`; solo `CLEAR` vigente confirma. |
| CA-11 | Categorías no recalculan características; estas dependen del tipo de producto. |
| CA-12 | Reubicación confirmada propaga `taxonomy.category.updated` de forma eventual. |
| CA-13 | En creación, el slug final resuelto por SEO se muestra antes de confirmar la publicación administrativa; una colisión con sufijo no se aplica silenciosamente. |
| CA-14 | La creación usa `POST /api/v1/seo/categorias/slug/resolver` y envía el resultado como `slugConfirmado`; si la propuesta dejó de estar libre, `POST /api/v1/categorias` responde `409 SLUG_DUPLICADO` y se solicita una nueva resolución sin cambiar el slug silenciosamente. |

## Escenarios
### 1. Reubicar
DADO una subcategoría y un padre activo, CUANDO se cambia el padre, ENTONCES se valida profundidad/ciclo y se actualiza sin modificar atributos de productos.

### 2. Reactivar con padre inactivo
DADO hija y padre inactivos, CUANDO se reactiva la hija, ENTONCES se exige reactivar primero el padre.

### 3. Baja con productos
DADO productos activos, CUANDO se solicita baja, ENTONCES se rechaza.

### 4. Baja pendiente
DADO categoría sin productos, CUANDO inicia la comprobación, ENTONCES Catálogo aplica barrera y Taxonomía espera `CLEAR`.

### 5. Profundidad
DADO que la nueva ubicación produciría un tercer nivel, CUANDO se reubica, ENTONCES se rechaza.

### 6. Colisión de slug al crear
DADO que `futbol` existe, CUANDO se crea otra categoría con nombre Fútbol, ENTONCES el gestor ve `/categoria/futbol-2` y debe confirmar ese slug antes de completar el alta.

### 7. Colisión concurrente después de confirmar propuesta
DADO que el gestor confirmó `futbol-2`, Y otro proceso ocupa ese slug antes de persistir, CUANDO se envía el alta, ENTONCES el sistema responde `409 SLUG_DUPLICADO`, no crea la categoría con otro sufijo y vuelve a resolver una propuesta para que el gestor la confirme.

## Regla resuelta
WF-008 consume la generación automática de SPEC-012 únicamente para la creación. La edición posterior de slug/metadatos se realiza en WF-012.
