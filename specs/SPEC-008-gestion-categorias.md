# SPEC-008 — Especificación: Gestión de categorías y subcategorías

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** HU [HU-008](./hu/HU-008-gestion-categorias.md) | Wireframe [WF-008](./wireframes/flows/WF-008-gestion-categorias.md)

## 1. Contexto
El Marketplace Multicanal organiza productos en categorías y subcategorías para navegación, filtros y clasificación. La estructura se administra en Taxonomía y se expone por API.

Las categorías **no definen ni heredan características de producto**; el esquema de atributos pertenece a `tipo_producto_id`.

## 2. Propósito
Permitir crear, consultar, actualizar, desactivar y reactivar categorías de navegación sobre un modelo recursivo. Para el MVP se configura `MAX_CATEGORY_DEPTH=2`, sin convertirlo en una restricción irreversible del modelo.

## 3. Alcance
- Categorías raíz y subcategorías.
- `categoria_padre_id` opcional y editable.
- Modelo recursivo sin ciclos.
- Profundidad máxima configurable, valor MVP 2.
- Consulta individual/listado/árbol.
- Baja lógica y reactivación.
- Baja segura mediante coordinación asíncrona con Catálogo.
- Consumo activo para canales/Catálogo.
- Integración con SEO para obtener el slug final durante la creación.

## 4. Requisitos

### Requisito 1: Crear categoría
Nombre requerido, descripción y `categoria_padre_id` opcional. El nombre NO necesita ser único.

Si existe padre, debe estar activo.

La creación solicita a la capacidad SEO el slug final mediante `POST /api/v1/seo/categorias/slug/resolver`. Si la normalización colisiona, SEO puede resolver mediante sufijo incremental, pero **Taxonomía no completa silenciosamente la publicación administrativa**: el slug final se devuelve al flujo y debe mostrarse al gestor antes de la confirmación final.

La propuesta no reserva el slug. La confirmación final se envía a `POST /api/v1/categorias` como `slugConfirmado`. La creación revalida unicidad inmediatamente antes de persistir; si otro proceso ocupó el slug desde la resolución previa, responde `409 SLUG_DUPLICADO` y el flujo debe resolver otra propuesta. Nunca se aplica un sufijo distinto sin volver a mostrarlo al gestor.

#### Escenario: Slug sin colisión
DADO nombre `Running`, CUANDO SEO devuelve `running`, ENTONCES el gestor puede confirmar la creación con ese slug visible.

#### Escenario: Slug con colisión
DADO que `futbol` ya está ocupado, CUANDO se crea otra categoría `Fútbol`, ENTONCES SEO propone `futbol-2`, el flujo muestra `/categoria/futbol-2` antes de confirmar y solo después se completa la creación.

### Requisito 2: Jerarquía
El modelo usa `categoria_padre_id`, sin ciclos. `MAX_CATEGORY_DEPTH=2` en el MVP: raíz + subcategoría.

### Requisito 3: Actualizar categoría
Permite editar nombre, descripción, orden, imagen y `categoria_padre_id`.

Al cambiar padre se valida:
- existencia;
- estado activo;
- ausencia de autorreferencia/ciclo;
- profundidad configurada.

Cambiar ubicación no altera productos ni sus características.

La edición posterior del slug y metadatos pertenece a SPEC-012.

### Requisito 4: Desactivar categoría
Toda baja es lógica.

Se bloquea si:
- existen subcategorías activas; o
- existen productos activos asociados.

La verificación de productos utiliza coordinación asíncrona:

```text
taxonomy.master.deactivation.check.requested
catalog.master.deactivation.checked
taxonomy.master.deactivated
taxonomy.master.deactivation.rejected
```

Taxonomía registra `PENDING_DEACTIVATION` y Catálogo instala una barrera concurrente. Solo `CLEAR` vigente permite confirmar la baja.

Timeout, error o falta de confirmación NUNCA autorizan la desactivación.

### Requisito 5: Reactivar
Una categoría inactiva puede reactivarse. Si tiene padre, este debe estar activo.

### Requisito 6: Consultar árbol
La administración puede ver activas e inactivas según permisos. Canales y Catálogo consumen únicamente categorías activas.

### Requisito 7: Reubicación segura
Antes de confirmar `categoria_padre_id` se revalidan ciclos, padre activo y profundidad. Un cambio confirmado emite el hecho versionado:

```text
taxonomy.category.updated
```

La propagación es eventual.

### Requisito 8: Contrato con SEO durante la creación
SPEC-012 es autoridad sobre normalización, colisiones, historia de slug y metadatos.

WF/SPEC-008 solo consumen la resolución del slug para la creación y muestran el resultado final antes de confirmar. No permiten editar manualmente SEO dentro de Categorías.

Contrato publicado:

```text
POST /api/v1/seo/categorias/slug/resolver
  { nombre }
  -> { slug, colisionResuelta }

POST /api/v1/categorias
  { .., slugConfirmado }
  -> 201 con slug confirmado
  -> 409 SLUG_DUPLICADO si la propuesta dejó de estar disponible
```

La segunda operación no autogenera una alternativa silenciosa: ante conflicto se regresa al paso de resolución/confirmación.

## 5. Requisitos no funcionales
- Árbol de referencia <1s con hasta 500 categorías.
- Escrituras autenticadas/autorizadas.
- Auditoría de creación/modificación.
- Sin transacción distribuida.
- Idempotencia y correlación en baja segura.

## 6. Fuera de alcance
- CRUD de características/marcas.
- Esquema de atributos por categoría.
- Edición de metadatos SEO.
- Asociación producto-categoría dentro de esta capacidad.

## Criterio de completitud
Creación/jerarquía/reubicación/baja/reactivación funcionan y la creación no oculta una colisión de slug resuelta por SEO.
