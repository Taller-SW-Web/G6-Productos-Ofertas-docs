# SPEC-010 — Especificación: Asociación entre tipos de producto y características

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** HU [HU-010](../hu/HU-010-asociacion-tipo-producto-caracteristica.md) | Wireframe [WF-010](../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md)

## 1. Contexto

No todos los productos comparten el mismo esquema de datos: una zapatilla necesita "Talla" y "Material", mientras un balón necesita "Tamaño" y "Material de cubierta". Las categorías se utilizan para navegación y pueden cambiar por campañas o merchandising sin que eso deba alterar los atributos estructurales del producto.

Por ello, esta capacidad utiliza `tipo_producto_id` como la entidad que define el esquema de atributos del producto y mantiene ese esquema desacoplado de la taxonomía de navegación.

## 2. Propósito

Permitir al gestor comercial definir qué características son aplicables a cada **tipo de producto**, indicando obligatoriedad y límites operativos, de modo que Catálogo Core construya y valide formularios consistentes aunque un producto cambie de categoría de navegación.

## 3. Alcance

Incluye:

- creación y consulta de tipos de producto ligeros (`tipo_producto_id`, nombre, estado);
- asociación de características activas a un tipo de producto activo;
- obligatoriedad `OBLIGATORIA | OPCIONAL`;
- cambio de obligatoriedad;
- límite técnico configurable `MAX_PRODUCT_TYPE_ATTRIBUTES` —valor inicial del MVP: 20—;
- consulta del esquema efectivo por `tipo_producto_id`;
- versionado del esquema;
- desasociación lógica segura;
- desactivación/reactivación de tipos de producto;
- coordinación segura con Catálogo cuando una baja pueda afectar productos o variantes activos;
- API de solo lectura para Catálogo Core y Carga Masiva.

Las categorías **no** son propietarias del esquema de características.

## 4. Requisitos

### Requisito 1: Asociar característica a tipo de producto

El sistema DEBE permitir asociar una característica existente y activa a un tipo de producto existente y activo, indicando si es obligatoria u opcional.

Reglas:

- no se permite asociar dos veces la misma característica al mismo tipo;
- el número de asociaciones activas no supera `MAX_PRODUCT_TYPE_ATTRIBUTES`;
- el valor inicial del MVP es 20;
- el límite es configuración operativa, no una restricción conceptual irreversible;
- una asociación confirmada incrementa la versión del esquema.

#### Escenario: Asociación exitosa

- **DADO** que existen el tipo "Zapatilla" y la característica "Talla", ambos activos
- **CUANDO** el gestor asocia "Talla" como obligatoria
- **ENTONCES** se registra la asociación, aumenta la versión del esquema y la consulta del tipo incluye "Talla" como obligatoria.

#### Escenario: Límite operativo

- **DADO** que el tipo alcanzó el límite configurado
- **CUANDO** se intenta agregar otra característica
- **ENTONCES** la operación se rechaza sin alterar el esquema existente.

### Requisito 2: Separación respecto de categorías

Las categorías NO heredan ni definen características.

Un producto:

- conserva su `tipo_producto_id` aunque cambie de categoría;
- puede cambiar de categoría sin recalcular automáticamente sus atributos;
- utiliza su tipo de producto para construir y validar el esquema.

Una categoría puede contener productos de tipos distintos y un mismo tipo puede aparecer en distintas categorías.

#### Escenario: Cambio de categoría

- **DADO** un producto de tipo "Zapatilla" con Talla y Material obligatorios
- **CUANDO** se mueve de la categoría "Running" a "Ofertas"
- **ENTONCES** conserva el mismo `tipo_producto_id` y el mismo esquema de atributos.

### Requisito 3: Cambio de obligatoriedad

El sistema DEBE permitir cambiar una asociación entre `OPCIONAL` y `OBLIGATORIA`.

Si una característica pasa a obligatoria:

- los productos preexistentes no se desactivan automáticamente;
- la obligación se exige en su siguiente edición/guardado o antes de una nueva activación, conforme a Catálogo;
- la modificación incrementa `schema_version`.

#### Escenario: Producto legado

- **DADO** productos existentes sin "Color"
- **Y** "Color" cambia de opcional a obligatorio
- **CUANDO** esos productos solo se consultan
- **ENTONCES** conservan su estado;
- **Y CUANDO** se editan y guardan
- **ENTONCES** Catálogo exige completar "Color".

### Requisito 4: Consultar esquema efectivo

El sistema DEBE exponer por `tipo_producto_id`:

- tipo de producto;
- estado;
- características activas;
- obligatoriedad;
- tipo de dato;
- unidad cuando aplique;
- metadatos necesarios para formularios;
- `schema_version`.

Si no hay asociaciones, devuelve una lista vacía.

Catálogo utiliza `schema_version` para detectar reglas obsoletas durante una escritura concurrente.

### Requisito 5: Desasociación lógica segura

El sistema DEBE permitir solicitar la desasociación de una característica.

Si la característica:

- es obligatoria; o
- participa como identificadora en variantes activas,

la baja requiere verificación segura con Catálogo antes de confirmarse.

La solicitud:

1. es admitida y correlacionada;
2. queda pendiente mientras se verifica uso;
3. no se presenta como completada por el mero `202 Accepted`;
4. solo se confirma cuando Catálogo informa que la operación es segura;
5. se rechaza si existe uso incompatible;
6. ante error o falta de confirmación no se presume éxito.

Los productos históricos conservan IDs y snapshots; no se reescriben SKUs ni pedidos.

#### Escenario: Desasociación segura

- **DADO** que "Material" puede retirarse sin invalidar productos activos
- **CUANDO** el gestor solicita desasociarla
- **ENTONCES** la operación queda en verificación y solo se retira tras resultado seguro.

#### Escenario: Desasociación bloqueada

- **DADO** que "Talla" identifica variantes activas
- **CUANDO** se solicita desasociarla
- **ENTONCES** Catálogo reporta uso activo y la asociación permanece vigente.

### Requisito 6: Desactivación y reactivación de tipos de producto

Un tipo de producto inactivo no puede utilizarse en nuevas altas o activaciones.

La desactivación de un tipo que pueda tener productos activos asociados requiere la misma propiedad de seguridad:

- operación correlacionada;
- estado pendiente;
- verificación en Catálogo;
- fallo cerrado;
- confirmación únicamente con resultado seguro.

La reactivación conserva la identidad del tipo y vuelve a habilitarlo para nuevas operaciones, sujeto a las validaciones vigentes.

Una característica desactivada tampoco se ofrece para nuevas asociaciones o activaciones, sin borrar el histórico de asociaciones existentes.

### Requisito 7: Versionado de reglas

`schema_version` forma parte del esquema efectivo y toda modificación confirmada de asociaciones DEBE incrementarla.

Esto incluye:

- asociar característica;
- cambiar obligatoriedad;
- desasociar característica cuando la baja se confirma;
- reactivar una asociación si se habilita mediante el flujo correspondiente.

Un cambio que solo resulta **admitido** (`202 Accepted`) y aún no confirmado no incrementa `schema_version`.

Catálogo valida escrituras contra una versión vigente.

### Requisito 8: Propagación de cambios del esquema

Cada modificación confirmada del esquema DEBE publicar `taxonomy.product-type-schema.changed`. La publicación no se limita a la asociación inicial: también corresponde al cambio de obligatoriedad y a la desasociación confirmada.

El dominio propietario publica un **hecho interno versionado** para que Catálogo actualice sus proyecciones sin polling obligatorio.

El mensaje debe transportar como mínimo:

- identidad del tipo de producto;
- `schema_version`;
- correlación;
- naturaleza del cambio suficiente para invalidar/refrescar la proyección.

**Contrato publicado:** el hecho interno canónico es `taxonomy.product-type-schema.changed`. Se emite únicamente después de confirmar el cambio y transporta `tipo_producto_id`, la `schema_version` de negocio vigente, `change_type`, la `caracteristica_id` afectada cuando aplique y `updated_at`. Catálogo lo utiliza para invalidar o refrescar su proyección; el `schema_version` del payload no debe confundirse con el `schema_version` del envelope de mensajería.

### Requisito 9: Baja segura de tipo/asociación — contrato asíncrono

La baja segura de `PRODUCT_TYPE` y `PRODUCT_TYPE_CHARACTERISTIC` requiere extender el contrato transversal de verificación de entidades maestras para cubrir estas entidades o formalizar un contrato equivalente.

**Contrato publicado:** AsyncAPI 0.4.0 amplía el flujo transversal de baja segura para `PRODUCT_TYPE` y `PRODUCT_TYPE_CHARACTERISTIC`. Por tanto:

- la regla funcional de fallo cerrado es obligatoria;
- el endpoint HTTP puede admitir la solicitud con `202`;
- no debe afirmarse que la operación concluyó hasta recibir `catalog.master.deactivation.checked` y el resultado final correspondiente;
- `taxonomy.master.deactivated` confirma la baja y `taxonomy.master.deactivation.rejected` conserva el estado previo ante uso incompatible.

### Requisito 10: Cambio de `tipo_producto_id` de un producto

`tipo_producto_id` puede corregirse mediante el CRUD ordinario solo mientras el producto:

- permanezca en borrador;
- no tenga variantes;
- no tenga identidad comercial publicada.

Cuando ya existen variantes o identidad publicada, el cambio puede alterar campos obligatorios e identidad de SKU y se considera una **migración de modelo** fuera del CRUD ordinario. En ese caso la edición ordinaria rechaza la operación y deriva el cambio a la migración controlada; no se reescriben identidades SKU ni snapshots históricos.

## 5. Contratos HTTP relacionados

El OpenAPI administrativo contempla:

```text
GET  /api/v1/tipos-producto
POST /api/v1/tipos-producto

GET  /api/v1/tipos-producto/{tipoProductoId}

POST /api/v1/tipos-producto/{tipoProductoId}/desactivar
POST /api/v1/tipos-producto/{tipoProductoId}/reactivar

GET  /api/v1/tipos-producto/{tipoProductoId}/caracteristicas
POST /api/v1/tipos-producto/{tipoProductoId}/caracteristicas

PATCH /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}

POST /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}/desasociar
```

Las operaciones de baja segura que responden `202 Accepted` representan **admisión**, no resultado final. El estado pendiente se consulta con:

```text
GET /api/v1/taxonomia/operaciones/{operationId}
```

y una identidad inexistente responde `404 OPERACION_MAESTRA_NO_ENCONTRADA`.

Semántica HTTP de tipo de producto:

- `TIPO_PRODUCTO_NO_ENCONTRADO` → `404` cuando una ruta identificada por `tipoProductoId` apunta a un tipo inexistente;
- `TIPO_PRODUCTO_INVALIDO` → `422` cuando un tipo informado existe como referencia contractual pero no puede utilizarse por estado o incompatibilidad con la operación.

No se reutiliza `TIPO_PRODUCTO_INVALIDO` como `404`, porque mezclaría ausencia del recurso con una validación semántica.

Las rutas administrativas derivadas permanecen sujetas al congelamiento final del OpenAPI.

## 6. Requisitos no funcionales

- Rendimiento de referencia de consulta del esquema: `< 500 ms`.
- Escrituras autenticadas y autorizadas por Seguridad; esta capacidad no define roles globales.
- IDs estables.
- Concurrencia optimista mediante `schema_version`.
- Idempotencia en verificaciones asíncronas.
- No existe transacción distribuida entre Taxonomía y Catálogo.
- Ante timeout/error en una verificación de baja, no se presume que sea seguro desactivar/desasociar.
- El frontend no confirma por sí solo una baja pendiente.

## 7. Fuera de alcance

- CRUD de categorías de navegación.
- CRUD de características y valores.
- Persistencia de valores concretos de características en productos.
- Personalización de atributos por canal/cliente.
- Migración automática de productos publicados entre tipos incompatibles.
- Borrado físico de asociaciones históricas.
- Definir unilateralmente contratos asíncronos fuera del AsyncAPI canónico.

## Criterio de completitud

La capacidad se considera correctamente documentada cuando:

- el esquema depende de `tipo_producto_id`, no de categoría;
- la asociación y obligatoriedad respetan límite/versionado;
- la consulta devuelve esquema versionado;
- la desasociación y desactivación fallan de forma segura;
- `202` no se interpreta como finalización;
- los cambios confirmados requieren propagación versionada;
- los contratos AsyncAPI de baja segura y propagación del esquema están publicados y trazables.
