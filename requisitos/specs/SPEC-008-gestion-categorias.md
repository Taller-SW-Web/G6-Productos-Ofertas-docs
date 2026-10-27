# SPEC-008 — Especificación: Gestión de categorías y subcategorías

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** HU [HU-008](../hu/HU-008-gestion-categorias.md) | Wireframe [WF-008](..\..\ux\wireframes\flows\WF-008-gestion-categorias.md)

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

La creación sigue la secuencia **resolver → mostrar → confirmar → crear con `slugConfirmado` → revalidar unicidad**.

La propuesta no reserva el slug. La confirmación final se envía a `POST /api/v1/categorias` como `slugConfirmado`. La creación revalida unicidad inmediatamente antes de persistir; si otro proceso ocupó el slug desde la resolución previa, responde `409 SLUG_DUPLICADO`.

Ante ese `409 SLUG_DUPLICADO` la regla es obligatoria y en este orden:

1. **No** aplicar otro sufijo automáticamente;
2. solicitar una nueva propuesta a `POST /api/v1/seo/categorias/slug/resolver`;
3. mostrar la nueva propuesta al gestor;
4. pedir una nueva confirmación;
5. reintentar el alta con ese nuevo `slugConfirmado`.

Nunca se persiste un slug distinto al confirmado ni se presenta el alta como completada.

#### Escenario: Slug sin colisión
DADO nombre `Running`, CUANDO SEO devuelve `running`, ENTONCES el gestor puede confirmar la creación con ese slug visible.

#### Escenario: Slug con colisión
DADO que `futbol` ya está ocupado, CUANDO se crea otra categoría `Fútbol`, ENTONCES SEO propone `futbol-2`, el flujo muestra `/categoria/futbol-2` antes de confirmar y solo después se completa la creación.

#### Escenario: Carrera concurrente de slug
DADO que el gestor confirmó `futbol-2`, CUANDO otro proceso ocupa ese slug antes de que `POST /api/v1/categorias` persista, ENTONCES la creación responde `409 SLUG_DUPLICADO`, no aplica ningún sufijo por su cuenta, vuelve a resolver una propuesta, la muestra y exige una nueva confirmación antes de reintentar.

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

La segunda operación no autogenera una alternativa silenciosa: ante `409 SLUG_DUPLICADO` se regresa al paso de resolución, se muestra la nueva propuesta y se pide una nueva confirmación antes de reintentar.

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
- Reservar el slug durante la fase de propuesta.

## Criterio de completitud
Creación/jerarquía/reubicación/baja/reactivación funcionan y la creación no oculta una colisión de slug resuelta por SEO, incluida la carrera concurrente: el `409 SLUG_DUPLICADO` no produce ningún sufijo automático y obliga a mostrar y confirmar una nueva propuesta.

## Alineación del protocolo de baja segura de maestros

El protocolo transversal se aplica a `CATEGORY`, `BRAND`, `CHARACTERISTIC_VALUE`, `PRODUCT_TYPE` y `PRODUCT_TYPE_CHARACTERISTIC`; no incluye `CHARACTERISTIC`. Taxonomy registra la operación pendiente y responde `202` solo por admisión. Para cuatro maestros, `version` conserva la versión autoritativa capturada al admitir; para `PRODUCT_TYPE_CHARACTERISTIC`, `version` es el `schema_version` del tipo capturado al admitir la operación, no una versión de fila de asociación. Taxonomy produce los IDs autoritativos `tipo_producto_id` y `caracteristica_id` de la asociación. Solo `CLEAR` seguido por el evento final correlacionado confirma la baja. `CLEAR` por sí solo nunca libera barrera. `IN_USE`, timeout inicial de 60 s, fallo técnico o conflicto de versión llevan a rechazo/restauración y publicación durable del resultado final; si Catálogo no recibe un final verificable, conserva el bloqueo hasta entrega/reconciliación segura.

Una operación activa por maestro; misma `operation_id` e intención devuelve `202` pendiente o `200` final, otra concurrente `409 OPERACION_MAESTRA_EN_CURSO`, y reutilizarla con intención distinta `409 IDEMPOTENCY_CONFLICT`. Marco aprobó como diseño las migraciones aditivas mínimas para versiones autoritativas, unicidad de operación activa cuando corresponda, correlación y recuperación durable, reutilizando `master_deactivation_operations` y tablas existentes. Se requiere cambio versionado para configurar el timeout en `taxonomy.runtime_settings`. La especialización de los cuatro mensajes existentes está documentada en AsyncAPI candidata; homologación de productores/consumidores y aplicación en BD compartida siguen pendientes.

La comprobación responde exclusivamente `CLEAR` o `IN_USE`; `HAS_ACTIVE_PRODUCTS` no forma parte de la respuesta contractual. En `PRODUCT_TYPE_CHARACTERISTIC`, la comprobación detecta dependencias activas incompatibles, incluyendo `product_identifying_characteristics`, `variant_attribute_values.es_identificador` y `variants.identifying_key`. Detrás de una barrera no se admiten nuevas referencias ni reactivaciones incompatibles, incluidas operaciones Bulk; Bulk no escribe directamente en Catálogo. Los cuatro mensajes correlacionan `operation_id` de envelope, `correlation_id`, entidad/IDs y `version`; contrato de mensaje `schema_version` no se confunde con la versión autoritativa. El final exitoso de asociación porta `schema_version_resultante` posterior y válido. El enum físico conserva `FAILED`; estado público `PENDING_DEACTIVATION | COMPLETED | REJECTED`, con fallo técnico mapeado a `REJECTED` y `TECHNICAL_FAILURE`.

Productor/consumidor usan Inbox/Outbox existentes e idempotencia transaccional. Taxonomy registra solicitud y outbox; Catálogo instala barrera y encola respuesta en la misma transacción. Taxonomy confirma o rechaza y emite final durable; Catálogo libera solo tras validar su correlación completa. Duplicados exactos son idempotentes; mensajes tardíos o discordantes se conservan como no aplicables y no levantan barreras.
