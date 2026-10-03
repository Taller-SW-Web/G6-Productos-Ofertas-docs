# SPEC-004 — Gestión de variantes y SKU

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** HU [HU-004](../hu/HU-004-gestion-variantes-skus.md) | Wireframe [WF-004](../wireframes/flows/WF-004-gestion-variantes-skus.md)

---

## 1. Objetivo

Administrar unidades vendibles de productos con variantes manteniendo identidad SKU, perfil físico e integración correcta con Pricing e Inventario.

## 2. Reglas

- Solo un producto con `tiene_variantes=true` admite variantes.
- La combinación de atributos identificadores es única dentro del producto.
- Cada variante posee SKU globalmente único.
- Peso/dimensiones pertenecen a la variante.
- El padre no representa una unidad física.

## 3. Inicialización de Pricing

Crear o reintentar una variante **no crea un precio base propio ni emite inicialización de Pricing**.

```text
sin override -> hereda el precio vigente del producto
con override -> Pricing gestiona posteriormente el precio específico de SKU
```

El comando `pricing.product.initialization.requested` se emite una sola vez para el producto padre (SPEC-003), **nunca por variante**. Una variante no puede solicitar ni reintentar preparación de Pricing.

## 4. Inicialización de Inventario

Solo **INVENTARIO** se inicializa y recupera a nivel de variante. Después de persistir una variante nueva, Catálogo registra la preparación en estado `PENDING` (`manual_retry_allowed=false`) y solicita:

```text
inventory.sku.initialization.requested
```

con:

```text
sku
product_id
variant_id
default_location_id opcional
```

Reglas del ciclo de Inventario de variante:
- `PENDING` ordinario: representa trabajo en curso o recuperación técnica automática; no muestra acción manual.
- Errores técnicos transitorios: se recuperan automáticamente mediante la política RabbitMQ existente de Inventario (hasta 3 reintentos con 30 s de espera antes de DLQ).
- Catálogo correlaciona resultados asíncronos mediante `causation_id = message_id` del comando requested activo, descartando/ignorando idempotentemente resultados tardíos de intentos anteriores como stale:
  - `inventory.sku.initialization.completed` → pasa a `COMPLETED`. La variante queda preparada para activación. Una preparación `COMPLETED` es terminal y nunca vuelve a ejecutarse ni reintentarse.
  - `inventory.sku.initialization.rejected` → pasa a `REJECTED`. Mantiene la variante como no publicable y registra el código recibido en `code`. No se reintenta automáticamente por infraestructura. El indicador `manual_retry_allowed` es calculado y autoritativo en Catálogo (la UI nunca es la autoridad). Si el rechazo requiere corrección de datos o atributos/perfil, el gestor modifica la variante; Catálogo revalida las precondiciones locales de la preparación; si es nuevamente elegible: `manual_retry_allowed=true`, de lo contrario permanece en `false`.
- Ausencia prolongada de resultado: tras un umbral operativo configurable sin confirmación, Catálogo puede habilitar `manual_retry_allowed=true` manteniendo `PENDING`. Catálogo no inspecciona directamente la DLQ del servicio consumidor ni la topología privada de RabbitMQ.
- Recuperación manual: cuando `manual_retry_allowed=true`, el Gestor Comercial puede solicitar `POST /api/v1/productos/{productoId}/variantes/{variantId}/preparacion/reintentar`.
  - La admisión es **atómica por preparación**: exactamente una solicitud concurrente pasa `manual_retry_allowed=true` a `PENDING / manual_retry_allowed=false` y devuelve HTTP `202 Accepted` (`OperationAccepted`) conservando la `operation_id` original.
  - Las solicitudes concurrentes competidoras o las realizadas sobre preparaciones en curso técnico, ya completadas o sin precondiciones validadas devuelven HTTP `409 PREPARACION_NO_REINTENTABLE`. Nunca se producen dos publicaciones RabbitMQ ni dos efectos de negocio.
  - El endpoint revalida autoritativamente las precondiciones antes de admitir (anti-TOCTOU), genera una nueva `message_id` para transporte RabbitMQ y construye el nuevo comando con el **estado actual validado de la variante** (perfil físico y atributos actualizados; no el payload antiguo).
  - La consulta `GET /api/v1/productos/{productoId}/preparacion` lee el estado de coordinación local de Catálogo sin realizar llamadas síncronas a Inventario.

## 5. Perfil físico

El perfil físico pertenece al SKU de la variante y se modela bajo la estructura contractual:

```text
perfilFisico.pesoKg > 0
perfilFisico.dimensionesCm.largo > 0
perfilFisico.dimensionesCm.ancho > 0
perfilFisico.dimensionesCm.alto > 0
```

Unidades contractuales: kg y cm. No se utilizan campos planos `largoCm/anchoCm/altoCm` directos en el DTO HTTP. Despacho consulta todas las unidades vendibles mediante el mismo endpoint físico.

Una variante en `BORRADOR` puede tener perfil físico incompleto; los valores informados deben ser positivos. Activar o reactivar exige los cuatro valores completos. El padre no tiene peso ni dimensiones propios; el volumen de la variante se deriva de sus dimensiones y no se ingresa por separado.

## 6. Edición, activación, desactivación y reactivación

La edición ordinaria permite actualizar atributos no identificadores, imagen y perfil físico válido. Conserva `variant_id`, el SKU comercial publicado y los atributos identificadores, conforme a `VarianteUpdateRequest` en OpenAPI vigente.

La edición actualiza la misma variante, sin crear otra ni cambiar su identidad comercial. Antes de guardar cambios de una variante `ACTIVA`, se comprueba que el resultado completo conserve las condiciones de activación de la variante. Si no las conserva, se rechaza la edición y se mantienen los datos y el estado anteriores, sin desactivación automática.

Activar requiere un padre con `tiene_variantes=true`, SKU globalmente único, combinación identificadora única dentro del producto, atributos e imagen válidos, perfil físico completo en kg/cm con valores mayores que cero e Inventario confirmado mediante `inventory.sku.initialization.completed` (`COMPLETED`). Las comprobaciones de unicidad excluyen la propia variante.

Desactivar una variante publica `catalog.sku.deactivated`. Si era la última variante activa y el padre estaba `ACTIVO`, se inactiva el padre conforme a SPEC-003. Si el padre estaba en `BORRADOR` o `INACTIVO`, conserva ese estado. Desactivar al padre conserva los estados individuales de sus variantes, pero bloquea su exposición comercial.

Reactivar una variante `INACTIVA` conserva `variant_id` y SKU, revalida las mismas condiciones de activación y solo entonces la devuelve a `ACTIVA`. Si no cumple, permanece `INACTIVA`. La preparación de Inventario rechazada o pendiente puede recuperarse manualmente conservando la identidad de operación original; una inicialización `COMPLETED` nunca se repite. Reactivar no crea precio base ni reactiva automáticamente al padre: este se revalida conforme a SPEC-003.

El padre no necesita estar `ACTIVO` para preparar, activar o reactivar una variante. Para activar o reactivar al padre se requiere al menos una variante activa y preparada; los hijos en `BORRADOR` o `INACTIVA` no bloquean al padre ni se ofrecen comercialmente. Reactivar al padre no reactiva variantes inactivas.

Las rutas `POST /productos/{productoId}/variantes/{variantId}/reactivar`, `POST /productos/{productoId}/variantes/{variantId}/preparacion/reintentar` y `GET /productos/{productoId}/preparacion` están declaradas en [OpenAPI vigente](../api/openapi.yaml), con estado `provisional-internal`. Los eventos de desactivación se publican mediante RabbitMQ y su fan-out corresponde a AsyncAPI 0.5.0.

## 7. No pertenece a esta capacidad

- saldo;
- reserva;
- precio master;
- empaque;
- pedido.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Extensión 0.5.0 — resolución de variante

Se mantiene:

```text
variant_id != sku
```

Cuando un código de barras identifica una unidad vendible de un producto con variantes:

```text
codigo_barras → sku de la variante
```

No se devuelve `variant_id` como identidad comercial.

Una variante inactiva o con producto padre no comercialmente vendible no produce una resolución válida. La ausencia temporal de stock **no** cambia la identidad SKU; disponibilidad se consulta separadamente.
<!-- HOMOLOGACION-HTTP-0.5.0:END -->
