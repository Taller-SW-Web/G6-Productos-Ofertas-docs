# Convenciones de Base de Datos — Productos y Ofertas

> Documento transversal que define el modelo físico de los ocho bounded contexts del módulo sobre PostgreSQL/Supabase.
> Su objetivo es que cada responsable de microservicio construya su persistencia de forma autónoma sin producir modelos incompatibles entre sí.
>
> `/bd` es la única raíz canónica para los artefactos de persistencia del módulo. Cada contexto mantiene en `/bd/<contexto>/` sus modelos, migraciones y validaciones, mientras que las herramientas compartidas de despliegue residen en `/bd/deploy/`. No debe existir un segundo historial activo fuera de `/bd`.

---

## 1. Identificación

- **Issue:** #48 — Convenciones comunes de base de datos
- **Rol:** BD / Testing (transversal)
- **Responsable:** Leonardo Lopez
- **Alcance:** 8 bounded contexts de negocio + `api-gateway` (read model)
- **Última actualización:** 2026-10-02
- **Complementa:** [`Arquitectura.md`](../Arquitectura.md) §7 Persistencia y §8 Migraciones, [`Modelo_Conceptual.md`](../Modelo_Conceptual.md) §15–§18

---

## 2. Fuentes de verdad y precedencia

Estas convenciones **no inventan modelo**. Se limitan a traducir a PostgreSQL lo que ya está decidido.

| Tema | Fuente de verdad |
|---|---|
| Reglas funcionales | `specs/SPEC-XXX-*.md` |
| Contrato HTTP | `api/openapi.yaml` |
| Mensajería asíncrona | `asyncapi/asyncapi.yaml` |
| Ownership e integración | `Contrato_Api.md` |
| Arquitectura | `Arquitectura.md` |
| Ownership conceptual | `Modelo_Conceptual.md` |
| Nomenclatura física | **este documento** |

Cuando una convención física contradice a una fuente oficial, **prevalece la fuente oficial** y este documento debe corregirse. No se agregan columnas, restricciones ni relaciones que no estén respaldadas por una fuente oficial del bounded context.

---

## 3. Ownership de schemas

Cada bounded context es dueño de **un schema propio**. No hay base de datos compartida.

| Servicio | Schema | Owner del dato |
|---|---|---|
| `taxonomy-svc` | `taxonomy` | categorías, marcas, características, valores, tipos de producto, SEO de categoría |
| `catalog-svc` | `catalog` | producto, variante, SKU, atributos, imágenes, perfil físico |
| `pricing-svc` | `pricing` | precio regular/oferta, vigencia, canal, versión |
| `price-audit-svc` | `price_audit` | bitácora de precios, exportaciones, archivado |
| `promotions-svc` | `promotions` | promociones, cupones, cross-sell, upsell |
| `combos-svc` | `combos` | combos, componentes, disponibilidad proyectada |
| `inventory-svc` | `inventory` | saldos, reservas, kardex, ubicación, incidentes, traslados |
| `bulk-svc` | `bulk` | trabajos masivos, filas, pasos por dominio |
| `api-gateway` | `read_model` | proyecciones agregadas de lectura |

Nota: la tabla de la fila `price-audit-svc` está mal formada en `Arquitectura.md:506` (dos filas fusionadas). El DDL debe crear ambos schemas por separado: `CREATE SCHEMA price_audit;` y `CREATE SCHEMA promotions;`.

---

## 4. Regla de aislamiento entre bounded contexts

Esta es la regla de mayor prioridad del documento. Se implementa y se verifica, pero **nunca se negocia**.

```text
NO existe FOREIGN KEY entre schemas de microservicios distintos.
NO existe acceso SQL directo cross-service.
Toda referencia externa es una columna escalar sin integridad referencial cruzada.
```

### 4.1 Cómo se materializa una referencia externa

Cuando un servicio necesita un dato de otro owner, se **duplica para leer** manteniendo el owner explícito. Duplicar para leer no es compartir ownership (`Modelo_Conceptual.md:1364`).

Las referencias cruzadas se modelan así:

- columna escalar `text` o `uuid` según el tipo de dato (§6);
- **sin** `REFERENCES`, **sin** constraint que la valide contra otra BD;
- el dato se puebla desde el contrato HTTP o el evento;
- se acompaña de `*_version` / `*_actualizado_en` cuando el dato puede cambiar, para invalidar caché.

### 4.2 Referencias cruzadas obligatorias

| Columna | Schema | Apunta a | Rellena desde |
|---|---|---|---|
| `categoria_id`, `marca_id`, `tipo_producto_id` | `catalog` | Taxonomía | evento `taxonomy.*` |
| `sku` | `pricing`, `inventory`, `combos`, `promotions`, `bulk`, `price_audit` | Catálogo | contrato / evento |
| `product_id`, `variant_id` | `pricing`, `promotions`, `combos` | Catálogo | contrato / evento |
| `order_id` | `inventory` | Ventas/Postventa | contrato |
| `user_id`, `customer_ref` | todos | Seguridad | JWT (`sub`) |
| `correlation_id`, `operation_id` | todos | productor de la operación | contrato |

### 4.3 Prohibiciones explícitas

No crear (aunque la semántica lo sugiera):

```sql
-- prohibidos
ALTER TABLE catalog.products            ADD FOREIGN KEY (categoria_id) REFERENCES taxonomy.categories(id);
ALTER TABLE pricing.prices              ADD FOREIGN KEY (sku)            REFERENCES catalog.variants(sku);
ALTER TABLE inventory.stock_balance     ADD FOREIGN KEY (sku)            REFERENCES catalog.variants(sku);
ALTER TABLE promotions.promotion_scopes ADD FOREIGN KEY (product_id)     REFERENCES catalog.products(id);
ALTER TABLE combos.combo_items          ADD FOREIGN KEY (sku)            REFERENCES catalog.variants(sku);
ALTER TABLE price_audit.price_audit_log ADD FOREIGN KEY (price_id)       REFERENCES pricing.prices(id);
```

Tampoco `cross-database`, `dblink`, `postgres_fdw` ni vistas que unan schemas de servicios distintos. El BFF (`read_model`) sí consolida datos de varios dominios porque es su propósito declarado.

---

## 5. Convención de nombres

### 5.1 Schemas

`snake_case` en minúsculas, sin números, igual al nombre del dominio:

```text
taxonomy  catalog  pricing  price_audit  promotions  combos  inventory  bulk  read_model
```

### 5.2 Tablas

- `snake_case`, **singular** cuando la tabla representa una entidad (`product`, `category`, `reservation`).
- `snake_case`, **plural** cuando representa una relación o un conjunto de elementos (`product_images`, `reservation_lines`, `stock_threshold_override`).
- Tablas asociativas o de Log genérico: plural (`reservation_lines`, `coupon_uses`).
- Prefijo de dominio permitido para desambiguar, nunca para reemplazar el schema: `master_deactivation_operations`, `activation_checks`.

**Excepción heredada del modelo conceptual:** se conservan los nombres ya declarados en `Arquitectura.md:520-638`, que mezclan singular y plural (`products`, `variants`, `brands`, `stock_balance`, `kardex`, `inbox`, `outbox`). Cambiar esos nombres no aporta valor y genera ruido en el diff; lo que sí se exige es que **los nombres nuevos** respeten esta regla.

### 5.3 Columnas

- `snake_case`, siempre en minúsculas, sin acentos ni `ñ`.
- Sin abreviaturas crípticas. `operation_id`, no `op_id`. `external_ref`, no `ext`.
- Sustantivo singular para valores, plural para colecciones (`tags`, `labels`).
- Booleos: prefijo `es_`/`tiene_` o `is_`/`has_` solo si el dominio lo usa así; si no, usar `snake_case` simple (`activo`, `notificado`).

### 5.4 Constraints e índices

| Objeto | Prefijo | Ejemplo |
|---|---|---|
| Clave primaria | `pk_` | `pk_products` |
| Restricción única | `uq_` | `uq_brands_nombre_normalizado` |
| Índice | `ix_` | `ix_products_estado` |
| Clave foránea | `fk_` | `fk_variants_producto_id` |
| CHECK | `ck_` | `ck_stock_balance_no_negativo` |
| Disparador | `trg_` | `trg_products_updated_at` |
| Función | `fn_` | `fn_set_updated_at` |
| Vista | `v_` | `v_stock_disponible` |
| Secuencia | `seq_` | `seq_kardex_id` |

Toda constraint e índice lleva prefijo. Sin excepción: los nombres autogenerados de PostgreSQL (`categorias_pkey`, `products_categoria_id_fkey`) están prohibidos porque no son predecibles ni legibles en los logs.

### 5.5 Nombres de constraint y longitud

Los nombres no deben superar los 63 caracteres (límite de PostgreSQL). Si se supera, abreviar la tabla antes que sacrificar el sufijo: `fk_product_type_characteristics_caracteristica_id` (53) es válido; `fk_product_type_characteristics_caracteristica_id_product_type_id` (64) no lo es.

---

## 6. Estrategia de identificadores

### 6.1 Clave primaria

```sql
id uuid PRIMARY KEY DEFAULT gen_random_uuid()
```

`gen_random_uuid()` es nativo desde PostgreSQL 13; no requiere `pgcrypto`. Supabase corre PostgreSQL 15 o superior.

Prohibido `SERIAL`, `BIGSERIAL`, `IDENTITY` autoincremental y claves naturales como PK.

### 6.2 Clave natural de negocio

El **SKU** es la identidad vendible compartida del módulo (`Modelo_Conceptual.md`, `Contrato_Api.md`, `SPEC-015`). Por decisión del equipo se usa `text` porque en e-commerce es el estándar de industria para transportar inventario y precios entre servicios sin depender de UUID opacos.

```sql
catalog.products.variants.sku   text NOT NULL UNIQUE
```

Reglas:

- `sku` es **natural key**, no primary key;
- se declara `UNIQUE` en el schema owner (`catalog`) y **solo** ahí;
- en los demás schemas `sku` es columna escalar sin `UNIQUE` global ni FK;
- el `sku` es inmutable una vez asignado. Si un flujo exige cambiarlo, se modela como migración explícita, nunca como UPDATE directo;
- el formato exacto del SKU **no** se fija con `CHECK` hasta que exista una especificación que lo formalice.

### 6.3 Identificadores por tipo de dato

| Dato | Tipo | Notas |
|---|---|---|
| PK surrogate | `uuid` | regla general |
| SKU, slug, código de cupón, `external_ref` | `text` | identidad natural de negocio |
| `order_id`, `operation_id`, `correlation_id`, `message_id`, `batch_id`, `reservation_id` | `uuid` | identidad técnica |
| `user_id`, `customer_ref` | `text` | referencia escalar a Seguridad, **sin FK** |

`id_auditoria` es la clave primaria de `price_audit.price_audit_log` y sigue la regla general (`uuid`), por consistencia de tipo en todo el módulo.

### 6.4 Nombres de constraint de unicidad de negocio

Las unicidades que exige el modelo se aplican como `UNIQUE` total, **no** como índice parcial:

| Restricción | Motivo |
|---|---|
| `uq_brands_nombre_normalizado` | la unicidad del nombre de marca incluye **inactivas** (`FLOW-011`, `SPEC-011`) |
| `uq_categories_slug` | el slug es único; la violación se traduce a `409 SLUG_DUPLICADO` |
| `uq_stock_balance_sku_location` | el saldo autoritativo es `(sku, location_id)` |
| `uq_coupon_uses_order_cupon` | un consumo por `(order_id, cupon_id)` |

El nombre de categoría **no** es único (`SPEC-008`). El slug sí, y su carrera se resuelve en la capa de aplicación, no con sufijos silenciosos.

---

## 7. Tipos recomendados para fechas y horas

### 7.1 Regla

| Semántica | Tipo | Ejemplos |
|---|---|---|
| Momento de un hecho | `timestamptz NOT NULL DEFAULT now()` | `created_at`, `updated_at`, `deleted_at`, `occurred_at` |
| Fecha de negocio sin hora | `date` | `valid_from`, `valid_to`, `fecha_inicio` |
| Instante de expiración | `timestamptz NOT NULL` | `expires_at` |
| Vigencia abierta | `timestamptz NULL` | `valid_to` |

Reglas duras:

- **Prohibido** `timestamp` sin zona horaria. Todo instante es `timestamptz`.
- Los valores de negocio se generan con el puerto `Clock` inyectable (`Arquitectura.md:2919-2941`); el `DEFAULT now()` es respaldo de infraestructura, no la fuente de la regla de negocio.
- `date` es solo para fechas de calendario. Si el dato necesita hora o participa de expiración, es `timestamptz`.

### 7.2 Timestamps obligatorios

| Columna | Obligatoria | Default |
|---|---|---|
| `created_at timestamptz NOT NULL` | sí | `now()` |
| `updated_at timestamptz NOT NULL` | sí, excepto exentas (§7.3) | `now()` |
| `deleted_at timestamptz NULL` | opcional | `NULL` |

`updated_at` se mantiene por disparador `trg_<tabla>_updated_at` (§12), no por responsabilidad de la aplicación, para que no pueda olvidarse.

### 7.3 Tablas exentas de `updated_at` y `deleted_at`

| Tabla | Motivo |
|---|---|
| `price_audit.price_audit_log` | bitácora estrictamente append-only (`Arquitectura.md:1537`, `SPEC-014:20`) |
| `inventory.kardex` | libro de movimientos: las correcciones se insertan, nunca se editan |
| `<schema>.inbox` | registro de deduplicación de mensajes ya procesados |
| `<schema>.outbox` | tabla de infraestructura: ninguna lectura de negocio la consulta directamente; mantiene timestamps operativos propios (`published_at`, `attempts`, `last_error`); no lleva `updated_at` |

Agregar `updated_at` a una tabla append-only produce una mentira estructural: la columna nunca cambia de valor y sugiere que la fila es editable. En estas tablas se resuelve el flujo con una **nueva fila**, nunca con `UPDATE`.

### 7.4 Ausencia de TTL de negocio

`expires_at` se implementa en `inventory.reservations`, pero **ninguna constraint fija los minutos del TTL**. La duración es configuración operativa por entorno/canal, no del esquema.

---

## 8. Tipos recomendados para valores monetarios

### 8.1 Regla

```sql
precio      numeric(12,2) NOT NULL
moneda      char(3)       NOT NULL
porcentaje  numeric(5,2)  NOT NULL
cantidad    integer       NOT NULL
```

Prohibido `float`, `real`, `double precision` y `money` para valores de negocio. `money` tiene escala fija dependiente de `lc_monetary` y dificulta la aritmética de descuentos.

### 8.2 Qué NO se agrega

Por acuerdo intermodular vigente:

- **no** se crea `CHECK (moneda = 'PEN')`. `PEN` es el valor de los fixtures y demostraciones, no una restricción del modelo. El campo de moneda debe admitir la moneda del contrato vigente.
- **no** se agregan columnas fiscales (`igv`, `base_imponible`, `tasa_igv`, `monto_descuento`) en `pricing`. La semántica tributaria pertenece al flujo comercial/fiscal y aún no está homologada con Ventas y Retail.
- **no** se agrega `codigo_barras` a `catalog` como elemento obligatorio. El baseline 0.5.0 ya lo reconoce contractualmente, pero su representación física definitiva en `catalog` **aún queda abierta** y no se impone en este documento. En caso de modelarse, deberá ser una extensión nullable y alineada al modelo lógico/físico aprobado.

### 8.3 Moneda nula como precio global

El precio sin canal específico usa `channel_id` efectivo nulo (`api/openapi.yaml`). Por eso `channel_id` es nullable y **no** tiene `UNIQUE` global.

### 8.4 Medidas físicas

```sql
peso_kg   numeric(8,3)
largo_cm  numeric(8,2)
ancho_cm  numeric(8,2)
alto_cm   numeric(8,2)
```

Unidad contractual fija: kg y cm. La conversión ocurre en adaptadores, nunca en la BD.

---

## 9. Uso de NOT NULL, UNIQUE, CHECK y FK

### 9.1 NOT NULL

`NOT NULL` es el default. Nullable solo cuando el modelo lo exige:

| Columna | ¿Nullable? | Motivo |
|---|---|---|
| `categoria_id` | sí | la categoría raíz no tiene padre |
| `parent_id` | sí | FK autorreferencial opcional |
| `variante_id` | sí | un producto simple no tiene variante propia |
| `moneda` | no | el precio siempre tiene moneda |
| `porcentaje_descuento` | no | si aplica descuento, tiene valor |
| `valor_descuento` | sí | alterno de `porcentaje_descuento` |
| `ends_at` / `valid_to` | sí | vigencia abierta |
| `deleted_at` | sí | solo en borrado lógico |

### 9.2 UNIQUE

- Unique para identidad natural y reglas de negocio explícitas del bounded context.
- `UNIQUE` compuesto sigue el orden `(scope, key)`: `uq_stock_balance_sku_location (sku, location_id)`.
- No usar `UNIQUE` para modelar "existe" cuando la regla es de negocio condicional; eso es un `CHECK` o lógica de aplicación.
- El nombre de la categoría no lleva `UNIQUE`.

### 9.3 CHECK

Todo `CHECK` se nombra `ck_<tabla>_<regla>` y expresa una invariante que el motor debe proteger.

```sql
CONSTRAINT ck_stock_balance_no_negativo
  CHECK (on_hand >= 0 AND reserved >= 0 AND blocked >= 0),

CONSTRAINT ck_reservation_lines_cantidad_positiva
  CHECK (quantity > 0),

CONSTRAINT ck_price_validities_orden
  CHECK (valid_to IS NULL OR valid_to > valid_from),

CONSTRAINT ck_categories_slug_formato
  CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),

CONSTRAINT ck_marcas_nombre_normalizado_obligatorio
  CHECK (nombre_normalizado IS NOT NULL AND length(btrim(nombre_normalizado)) > 0)
```

**No** se crea un `CHECK` a partir de un supuesto de coordinación con otro módulo. `moneda`, formato de `sku`, equivalencia entre `tienda_id` de Retail y `location_id` siguen abiertos y se resuelven en contratos, no en el esquema.

### 9.4 FOREIGN KEY

- **Solo dentro del mismo schema.**
- Toda FK se crea con `ON DELETE RESTRICT` explícito (default) o `ON DELETE CASCADE` solo en tablas dependientes; nunca `ON DELETE SET NULL` sobre columnas `NOT NULL`.
- `catalog.variants → catalog.products` usa `ON DELETE CASCADE` porque una variante sin producto no tiene sentido.
- Toda FK **requiere** su índice en la columna referenciante. PostgreSQL no lo crea solo. Prefijo `ix_<tabla>_<columna>`.

Las FK permitidas están enumeradas en `Modelo_Conceptual.md:1234-1249` y las prohibidas en `Modelo_Conceptual.md:1253-1278`.

---

## 10. Convenciones para Outbox e Inbox

### 10.1 Cuándo aplican

| Schema | Outbox | Inbox | Motivo |
|---|---|---|---|
| `taxonomy`, `catalog`, `pricing`, `promotions`, `combos`, `inventory`, `bulk` | sí | sí | publican hechos de dominio |
| `price_audit` | no | sí | solo consume; su registro es append-only y no publica (`Arquitectura.md:566-573`) |
| `read_model` | no | sí | proyecta; no publica hechos de dominio |

Si un bounded context no publica eventos, su `outbox` no se crea. No se crean tablas vacías "por simetría".

### 10.2 Estructura obligatoria

```sql
CREATE TABLE <schema>.outbox (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id      uuid        NOT NULL UNIQUE,          -- correlación de idempotencia de publicación
    event_name      text        NOT NULL,
    kind            text        NOT NULL,
    schema_version  integer     NOT NULL DEFAULT 1,
    correlation_id  uuid        NOT NULL,
    causation_id    uuid        NULL,
    operation_id    uuid        NULL,
    occurred_at     timestamptz NOT NULL,
    payload         jsonb       NOT NULL,
    published_at    timestamptz NULL,
    attempts        integer     NOT NULL DEFAULT 0,
    last_error      text        NULL,
    CONSTRAINT ck_outbox_kind         CHECK (kind IN ('command','event','result')),
    CONSTRAINT ck_outbox_attempts     CHECK (attempts >= 0)
);

CREATE TABLE <schema>.inbox (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id    uuid        NOT NULL,
    handler       text        NOT NULL,
    event_name    text        NOT NULL,
    correlation_id uuid       NULL,
    payload       jsonb       NOT NULL,
    processed_at  timestamptz NOT NULL DEFAULT now(),
    result        text        NOT NULL,
    CONSTRAINT uq_inbox_message_handler UNIQUE (message_id, handler)
);
```

### 10.3 Reglas

1. El registro en `outbox` ocurre **en la misma transacción** del cambio de negocio (`Arquitectura.md:817`).
2. La publicación ocurre **después** del commit. Nunca dentro.
3. `inbox` garantiza unicidad por `(message_id, handler)` — deduplicación, no solo por `message_id`, para no bloquear handlers legítimos distintos.
4. `published_at IS NULL` significa pendiente. El relay ordena por `occurred_at`.
5. Ninguna lectura de negocio consulta `outbox` directamente.

### 10.4 Idempotencia de negocio

La deduplicación técnica (`inbox`) no sustituye la idempotencia de negocio. Donde aplique, se declara además:

```sql
CONSTRAINT uq_inventory_operations_operation_id UNIQUE (operation_id)
```

En Inventario, misma identidad + misma intención = replay sin efectos; misma identidad + intención distinta = `IDEMPOTENCY_CONFLICT`.

---

## 11. Criterios básicos para índices

### 11.1 Cuándo indexar

| Caso | Índice |
|---|---|
| Toda FK | `ix_<tabla>_<columna>` (obligatorio) |
| Filtro frecuente por estado | `ix_<tabla>_estado` |
| Búsqueda por identidad natural | cubierto por el `UNIQUE` |
| Rango temporal (expiración, vigencia) | `ix_<tabla>_expires_at` |
| Orden de salida del relay | `ix_outbox_pending (published_at, occurred_at)` |
| Reportes de dashboard | materializado en `dashboard_projection`, no sobre la tabla transaccional |

### 11.2 Índices parciales y compuestos

Se permiten índices parciales y compuestos cuando la consulta lo justifica. Se **exige** justificación en `physical-model.md`.

```sql
CREATE INDEX ix_products_estado_activo
  ON catalog.products (estado)
  WHERE deleted_at IS NULL AND estado = 'ACTIVO';

CREATE INDEX ix_reservations_expires_at
  ON inventory.reservations (expires_at)
  WHERE estado = 'ACTIVA';
```

### 11.3 Qué no indexar

- Columnas de baja cardinalidad sin filtro (`*_version`, booleanos sueltos).
- Columnas ya cubiertas por el índice de un `UNIQUE`.
- Texto largo o `jsonb` salvo necesidad de búsqueda explícita.
- No crear índices "por si acaso": cada índice cuesta en escritura.

---

## 12. Disparadores de `updated_at`

Un único disparador por tabla, función compartida en cada schema:

```sql
CREATE OR REPLACE FUNCTION <schema>.fn_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_<tabla>_updated_at
BEFORE UPDATE ON <schema>.<tabla>
FOR EACH ROW EXECUTE FUNCTION <schema>.fn_set_updated_at();
```

Reglas:

- **Nunca** en tablas exentas (§7.3).
- **Nunca** en tablas append-only.
- La función es local al schema. No se crea en `public` ni se comparte entre servicios.

---

## 13. Enumeraciones

### 13.1 Tipo nativo frente a texto

Por decisión del equipo se usa **tipo nativo de PostgreSQL** para validación estricta en base de datos:

```sql
CREATE TYPE catalog.estado_producto AS ENUM ('BORRADOR','ACTIVO','INACTIVO');
```

### 13.2 Cuándo crear un tipo y cuándo no

| Caso | Tipo |
|---|---|
| Estado de ciclo de vida de una entidad **propia** del bounded context y ya publicado en el contrato | tipo nativo |
| Catálogo de valores de negocio abierto, en negociación con otro módulo | `text` + `CHECK` |
| Código de canal, moneda, código de error, país | `text` + `CHECK` |

No se crea un tipo por cada `enum:` del OpenAPI: el contrato contiene cientos de enumeraciones y la mayoría son códigos de error o catálogos externos, no estados propios.

### 13.3 Alcance de los tipos

**Los tipos enumerados son propiedad del schema que los declara.**

- Se crean dentro del schema del servicio: `CREATE TYPE catalog.estado_producto ...`.
- Ningún schema referencia un tipo de otro schema. Referenciarlo crearía una dependencia cross-service, prohibida por §4.
- Si dos servicios necesitan la misma enumeración, **cada uno declara su tipo local**. La consecuencia —valores idénticos duplicados— es el precio correcto del aislamiento.
- Un tipo de `taxonomy` no se comparte con `catalog`, aunque ambos modelen un estado activo/inactivo.

### 13.4 Coste asumido

`ALTER TYPE ... ADD VALUE` no puede ejecutarse dentro de un bloque transaccional en PostgreSQL < 12 y su uso en migraciones es delicado. Esto refuerza la regla de migraciones: **las migraciones son reproducibles desde cero** (`Arquitectura.md:651`) y no se editan una vez aplicadas. Para agregar un valor se crea una migración nueva, nunca se altera una aplicada.

Si en el futuro un estado debe dejar de existir, se planifica `expand/contract` (§15), no se edita la migración que lo creó.

---

## 14. Baja lógica: `estado` y `deleted_at`

Son dos mecanismos distintos y **no intercambiables**.

### 14.1 `estado` — baja de negocio

Es el mecanismo oficial y el que expone el contrato (`EstadoEntidad: ACTIVO | INACTIVO` en `api/openapi.yaml`). Conserva el `id` y permite la reactivación con la misma identidad.

```sql
estado <estado_entidad> NOT NULL DEFAULT 'ACTIVO'
```

Se usa en: categorías, marcas, características, valores, tipos de producto, variantes, promociones, combos.

### 14.2 `deleted_at` — barrera de borrado físico

`deleted_at timestamptz NULL` no es un segundo mecanismo de baja. Es la garantía de que **la fila no se borra físicamente**, para no romper proyecciones que otros servicios ya materializaron de ella.

```sql
deleted_at timestamptz NULL DEFAULT NULL
```

Reglas:

- `deleted_at` **nunca** sustituye a `estado`;
- una tabla **no** usa `estado` y `deleted_at` para el mismo propósito;
- `deleted_at` no participa de la lógica de negocio ni se filtra por defecto en el contrato HTTP; la proyección de estado sigue siendo `estado`;
- no se construyen índices parciales `WHERE deleted_at IS NULL` para esquivar reglas de unicidad. Las unicidades que el modelo exige se aplican como `UNIQUE` total (§6.4), incluso entre filas dadas de baja, porque el modelo exige unicidad también entre inactivas.

### 14.3 Precedencia

```text
estado      →  regla de negocio, visible en el contrato, controla reactivación
deleted_at  →  control de retención, impide DELETE físico
```

Una tabla con `estado` **no** necesita `deleted_at`. Se documenta la excepción en `physical-model.md` (§7.3 y esta sección) para que la omisión sea deliberada y no un descuido.

---

## 15. Migraciones

### 15.1 Reglas

1. Una migración **nunca** modifica el schema de otro servicio.
2. Las migraciones son **reproducibles desde cero**.
3. No se edita una migración ya aplicada en un ambiente compartido.
4. Los cambios destructivos usan **expand/contract**.
5. Las migraciones se ejecutan antes de iniciar la nueva versión.
6. No se depende de creación automática de tablas del ORM (`Arquitectura.md:644-665`).

### 15.2 Expand/contract

```text
v1  añadir columna nueva nullable
v2  escribir campo viejo + nuevo
v3  migrar datos históricos
v4  leer solo el nuevo
v5  retirar el campo viejo
```

### 15.3 Nomenclatura

```text
<NNN>_<verbo>_<objeto>.sql        001_create_schema.sql
                                  002_create_enum_catalog.sql
                                  003_create_table_products.sql
```

La numeración es secuencial y sin huecos dentro de un servicio.

---

## 16. Seguridad, roles y Supabase

### 16.1 Roles

```sql
CREATE SCHEMA IF NOT EXISTS catalog;
REVOKE ALL ON SCHEMA catalog FROM PUBLIC;
GRANT  USAGE ON SCHEMA catalog TO catalog_app;
GRANT  ALL   ON ALL TABLES IN SCHEMA catalog TO catalog_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA catalog
       GRANT ALL ON TABLES TO catalog_app;
```

- Un rol por schema. `catalog_app` no ve `pricing`, ni al revés.
- `REVOKE ALL ON SCHEMA <x> FROM PUBLIC` es obligatorio en los nueve schemas.
- Cada servicio se conecta con su propio rol y sus propias credenciales (`Arquitectura.md:499`).

### 16.2 Row Level Security

- **RLS se habilita únicamente en `read_model`**, que es el único schema expuesto por la API pública.
- Los schemas de escritura **no** activan RLS: su aislamiento se logra por rol y por `REVOKE`, no por políticas de fila, porque una política RLS incorrecta produciría fallos silenciosos de escritura.
- `read_model` no tiene FK hacia schemas de dominio: son proyecciones reconstruibles.

### 16.3 Compatibilidad con Supabase

| Punto | Regla |
|---|---|
| Esquemas visibles | Supabase expone `public` por defecto. Los nueve schemas deben registrarse en la configuración de la plataforma para que PostgREST los sirva; no se usa `public` para datos de negocio. |
| `auth.users` | **no** existe FK hacia `auth.users`. El usuario es `user_id text` / `customer_ref text`. |
| RLS | solo `read_model`. |
| Extensiones | `pgcrypto` no es necesaria con PostgreSQL 13+. Si un entorno concreto la exige, se declara en la migración, nunca se asume. |
| Claims de JWT | no se copian al esquema; se resuelven en la capa de aplicación. |

### 16.4 Identidad

Toda referencia a usuario es una columna escalar:

```sql
user_id      text NULL
customer_ref text NULL
```

Nunca FK. Nunca `uuid` con REFERENCES a `auth.users`.

---

## 17. Elementos que no deben modelarse

Por acuerdo intermodular vigente, ningún schema debe crear:

| Elemento | Motivo |
|---|---|
| `reservation.location_id NOT NULL` como reemplazo de `location_line.location_id` | cierra prematuramente split fulfillment; la ubicación se modela a nivel de línea |
| FK o tabla de Retail | `external_ref` es extensión opcional, no contrato |
| `CHECK (moneda = 'PEN')` | PEN es valor de fixture, no regla del modelo |
| `igv`, `base_imponible`, `tasa_igv` en `pricing` | semántica tributaria aún no homologada |
| `codigo_barras` en `catalog` | ya reconocido contractualmente, pero representación física aún no definida; en caso de incluirlo, debe ser nullable |
| tablas Pickup (`pickup_order`, `pickup_handoff`, `pickup_store_receipt`) | sin contrato intermodular que las exija |
| `pedido`, `pago`, `reserva_inventario` en `combos` | Combos no es owner de pedido ni de pago |
| columnas fiscales o de despacho en cualquier schema | §4 y §8.2 |

---

## 18. Tablas añadidas respecto a `Arquitectura.md` §7.2

`Arquitectura.md:602-615` enumera las tablas de `inventory` sin incluir la ubicación, pese a que `Modelo_Conceptual.md:694` define LOCATION como entidad conceptual y `Contrato_Api.md` asigna a Inventario el ownership de Ubicación.

Esta convención añade:

| Tabla | Motivo |
|---|---|
| `inventory.locations` | da soporte referencial a `stock_balance.location_id` y `reservation_lines.location_id` |

Columnas de referencia:

```text
id            uuid PRIMARY KEY
code          text NOT NULL UNIQUE
name          text NOT NULL
type          text NOT NULL
external_ref  text NULL      -- extensión; sin CHECK de formato, sin FK
active        boolean NOT NULL DEFAULT true
created_at    timestamptz NOT NULL DEFAULT now()
updated_at    timestamptz NOT NULL DEFAULT now()
```

`external_ref` es una posibilidad de implementación para asociar `tienda_id` de Retail. No se le aplica `CHECK`, no se le da `UNIQUE` y no se declara FK.

Esta tabla requiere validación del responsable de `inventory-svc` antes de aprobarse.

---

## 19. Checklist de aprobación de un modelo físico

Antes de aprobar un `physical-model.md` o un `migration.sql`:

- [ ] No existe FK entre schemas de servicios distintos.
- [ ] No existe acceso SQL cross-service.
- [ ] Toda FK tiene índice en su columna referenciante.
- [ ] Toda tabla tiene `created_at timestamptz NOT NULL DEFAULT now()`.
- [ ] `updated_at` existe salvo en las tablas exentas de §7.3.
- [ ] No hay `float`, `real`, `double precision` ni `money` para valores de negocio.
- [ ] No hay `timestamp` sin zona horaria.
- [ ] No hay `serial`, `bigserial` ni PK natural.
- [ ] Los tipos enumerados son locales a su schema y no se referencian entre schemas.
- [ ] Toda constraint, índice, disparador y función lleva prefijo.
- [ ] `estado` y `deleted_at` no se usan para el mismo propósito.
- [ ] Las referencias externas son columnas escalares sin FK.
- [ ] Las unicidades exigidas por el modelo son `UNIQUE` totales.
- [ ] `outbox` existe solo en los schemas que publican eventos; `inbox` en los que consumen.
- [ ] El registro en `outbox` está dentro de la transacción de negocio.
- [ ] RLS está activo solo en `read_model`.
- [ ] Cada schema tiene `REVOKE ALL ... FROM PUBLIC` y su propio rol.
- [ ] No hay FK hacia `auth.users`; el usuario es `user_id text`.
- [ ] Las migraciones se ejecutan desde cero en una base vacía.
- [ ] `validation.sql` del servicio devuelve todos los checks en `PASS`.

---

## 20. Plantillas

| Documento | Uso |
|---|---|
| [`plantillas/logical-model.md`](plantillas/logical-model.md) | Modelo lógico de un bounded context |
| [`plantillas/physical-model.md`](plantillas/physical-model.md) | Modelo físico de un bounded context |
| [`plantillas/migration.sql`](plantillas/migration.sql) | Estructura de migraciones de un bounded context |
| [`plantillas/validation.sql`](plantillas/validation.sql) | Checks verificables de un bounded context |
| [`README.md`](README.md) | Índice de los entregables de BD |

Cada microservicio copia las plantillas en su propia carpeta de persistencia y las rellena. La convención no se reescribe por servicio.
