# Convenciones de Base de Datos 窶・Productos y Ofertas

> Documento transversal que define el modelo fﾃｭsico de los ocho bounded contexts del mﾃｳdulo sobre PostgreSQL/Supabase.
> Su objetivo es que cada responsable de microservicio construya su persistencia de forma autﾃｳnoma sin producir modelos incompatibles entre sﾃｭ.

---

## 1. Identificaciﾃｳn

- **Issue:** #48 窶・Convenciones comunes de base de datos
- **Rol:** BD / Testing (transversal)
- **Responsable:** Leonardo Lopez
- **Alcance:** 8 bounded contexts de negocio + `api-gateway` (read model)
- **ﾃ嗟tima actualizaciﾃｳn:** 2026-10-02
- **Complementa:** [`Arquitectura.md`](../Arquitectura.md) ﾂｧ7 Persistencia y ﾂｧ8 Migraciones, [`Modelo_Conceptual.md`](../Modelo_Conceptual.md) ﾂｧ15窶督ｧ18

---

## 2. Fuentes de verdad y precedencia

Estas convenciones **no inventan modelo**. Se limitan a traducir a PostgreSQL lo que ya estﾃ｡ decidido.

| Tema | Fuente de verdad |
|---|---|
| Reglas funcionales | `specs/SPEC-XXX-*.md` |
| Contrato HTTP | `api/openapi.yaml` |
| Mensajerﾃｭa asﾃｭncrona | `asyncapi/asyncapi.yaml` |
| Ownership e integraciﾃｳn | `Contrato_Api.md` |
| Arquitectura | `Arquitectura.md` |
| Ownership conceptual | `Modelo_Conceptual.md` |
| Nomenclatura fﾃｭsica | **este documento** |

Cuando una convenciﾃｳn fﾃｭsica contradice a una fuente oficial, **prevalece la fuente oficial** y este documento debe corregirse. No se agregan columnas, restricciones ni relaciones que no estﾃｩn respaldadas por una fuente oficial del bounded context.

---

## 3. Ownership de schemas

Cada bounded context es dueﾃｱo de **un schema propio**. No hay base de datos compartida.

| Servicio | Schema | Owner del dato |
|---|---|---|
| `taxonomy-svc` | `taxonomy` | categorﾃｭas, marcas, caracterﾃｭsticas, valores, tipos de producto, SEO de categorﾃｭa |
| `catalog-svc` | `catalog` | producto, variante, SKU, atributos, imﾃ｡genes, perfil fﾃｭsico |
| `pricing-svc` | `pricing` | precio regular/oferta, vigencia, canal, versiﾃｳn |
| `price-audit-svc` | `price_audit` | bitﾃ｡cora de precios, exportaciones, archivado |
| `promotions-svc` | `promotions` | promociones, cupones, cross-sell, upsell |
| `combos-svc` | `combos` | combos, componentes, disponibilidad proyectada |
| `inventory-svc` | `inventory` | saldos, reservas, kardex, ubicaciﾃｳn, incidentes, traslados |
| `bulk-svc` | `bulk` | trabajos masivos, filas, pasos por dominio |
| `api-gateway` | `read_model` | proyecciones agregadas de lectura |

Nota: la tabla de la fila `price-audit-svc` estﾃ｡ mal formada en `Arquitectura.md:506` (dos filas fusionadas). El DDL debe crear ambos schemas por separado: `CREATE SCHEMA price_audit;` y `CREATE SCHEMA promotions;`.

---

## 4. Regla de aislamiento entre bounded contexts

Esta es la regla de mayor prioridad del documento. Se implementa y se verifica, pero **nunca se negocia**.

```text
NO existe FOREIGN KEY entre schemas de microservicios distintos.
NO existe acceso SQL directo cross-service.
Toda referencia externa es una columna escalar sin integridad referencial cruzada.
```

### 4.1 Cﾃｳmo se materializa una referencia externa

Cuando un servicio necesita un dato de otro owner, se **duplica para leer** manteniendo el owner explﾃｭcito. Duplicar para leer no es compartir ownership (`Modelo_Conceptual.md:1364`).

Las referencias cruzadas se modelan asﾃｭ:

- columna escalar `text` o `uuid` segﾃｺn el tipo de dato (ﾂｧ6);
- **sin** `REFERENCES`, **sin** constraint que la valide contra otra BD;
- el dato se puebla desde el contrato HTTP o el evento;
- se acompaﾃｱa de `*_version` / `*_actualizado_en` cuando el dato puede cambiar, para invalidar cachﾃｩ.

### 4.2 Referencias cruzadas obligatorias

| Columna | Schema | Apunta a | Rellena desde |
|---|---|---|---|
| `categoria_id`, `marca_id`, `tipo_producto_id` | `catalog` | Taxonomﾃｭa | evento `taxonomy.*` |
| `sku` | `pricing`, `inventory`, `combos`, `promotions`, `bulk`, `price_audit` | Catﾃ｡logo | contrato / evento |
| `product_id`, `variant_id` | `pricing`, `promotions`, `combos` | Catﾃ｡logo | contrato / evento |
| `order_id` | `inventory` | Ventas/Postventa | contrato |
| `user_id`, `customer_ref` | todos | Seguridad | JWT (`sub`) |
| `correlation_id`, `operation_id` | todos | productor de la operaciﾃｳn | contrato |

### 4.3 Prohibiciones explﾃｭcitas

No crear (aunque la semﾃ｡ntica lo sugiera):

```sql
-- prohibidos
ALTER TABLE catalog.products            ADD FOREIGN KEY (categoria_id) REFERENCES taxonomy.categories(id);
ALTER TABLE pricing.prices              ADD FOREIGN KEY (sku)            REFERENCES catalog.variants(sku);
ALTER TABLE inventory.stock_balance     ADD FOREIGN KEY (sku)            REFERENCES catalog.variants(sku);
ALTER TABLE promotions.promotion_scopes ADD FOREIGN KEY (product_id)     REFERENCES catalog.products(id);
ALTER TABLE combos.combo_items          ADD FOREIGN KEY (sku)            REFERENCES catalog.variants(sku);
ALTER TABLE price_audit.price_audit_log ADD FOREIGN KEY (price_id)       REFERENCES pricing.prices(id);
```

Tampoco `cross-database`, `dblink`, `postgres_fdw` ni vistas que unan schemas de servicios distintos. El BFF (`read_model`) sﾃｭ consolida datos de varios dominios porque es su propﾃｳsito declarado.

---

## 5. Convenciﾃｳn de nombres

### 5.1 Schemas

`snake_case` en minﾃｺsculas, sin nﾃｺmeros, igual al nombre del dominio:

```text
taxonomy  catalog  pricing  price_audit  promotions  combos  inventory  bulk  read_model
```

### 5.2 Tablas

- `snake_case`, **singular** cuando la tabla representa una entidad (`product`, `category`, `reservation`).
- `snake_case`, **plural** cuando representa una relaciﾃｳn o un conjunto de elementos (`product_images`, `reservation_lines`, `stock_threshold_override`).
- Tablas asociativas o de Log genﾃｩrico: plural (`reservation_lines`, `coupon_uses`).
- Prefijo de dominio permitido para desambiguar, nunca para reemplazar el schema: `master_deactivation_operations`, `activation_checks`.

**Excepciﾃｳn heredada del modelo conceptual:** se conservan los nombres ya declarados en `Arquitectura.md:520-638`, que mezclan singular y plural (`products`, `variants`, `brands`, `stock_balance`, `kardex`, `inbox`, `outbox`). Cambiar esos nombres no aporta valor y genera ruido en el diff; lo que sﾃｭ se exige es que **los nombres nuevos** respeten esta regla.

### 5.3 Columnas

- `snake_case`, siempre en minﾃｺsculas, sin acentos ni `ﾃｱ`.
- Sin abreviaturas crﾃｭpticas. `operation_id`, no `op_id`. `external_ref`, no `ext`.
- Sustantivo singular para valores, plural para colecciones (`tags`, `labels`).
- Booleos: prefijo `es_`/`tiene_` o `is_`/`has_` solo si el dominio lo usa asﾃｭ; si no, usar `snake_case` simple (`activo`, `notificado`).

### 5.4 Constraints e ﾃｭndices

| Objeto | Prefijo | Ejemplo |
|---|---|---|
| Clave primaria | `pk_` | `pk_products` |
| Restricciﾃｳn ﾃｺnica | `uq_` | `uq_brands_nombre_normalizado` |
| ﾃ肱dice | `ix_` | `ix_products_estado` |
| Clave forﾃ｡nea | `fk_` | `fk_variants_producto_id` |
| CHECK | `ck_` | `ck_stock_balance_no_negativo` |
| Disparador | `trg_` | `trg_products_updated_at` |
| Funciﾃｳn | `fn_` | `fn_set_updated_at` |
| Vista | `v_` | `v_stock_disponible` |
| Secuencia | `seq_` | `seq_kardex_id` |

Toda constraint e ﾃｭndice lleva prefijo. Sin excepciﾃｳn: los nombres autogenerados de PostgreSQL (`categorias_pkey`, `products_categoria_id_fkey`) estﾃ｡n prohibidos porque no son predecibles ni legibles en los logs.

### 5.5 Nombres de constraint y longitud

Los nombres no deben superar los 63 caracteres (lﾃｭmite de PostgreSQL). Si se supera, abreviar la tabla antes que sacrificar el sufijo: `fk_product_type_characteristics_caracteristica_id` (53) es vﾃ｡lido; `fk_product_type_characteristics_caracteristica_id_product_type_id` (64) no lo es.

---

## 6. Estrategia de identificadores

### 6.1 Clave primaria

```sql
id uuid PRIMARY KEY DEFAULT gen_random_uuid()
```

`gen_random_uuid()` es nativo desde PostgreSQL 13; no requiere `pgcrypto`. Supabase corre PostgreSQL 15 o superior.

Prohibido `SERIAL`, `BIGSERIAL`, `IDENTITY` autoincremental y claves naturales como PK.

### 6.2 Clave natural de negocio

El **SKU** es la identidad vendible compartida del mﾃｳdulo (`Modelo_Conceptual.md`, `Contrato_Api.md`, `SPEC-015`). Por decisiﾃｳn del equipo se usa `text` porque en e-commerce es el estﾃ｡ndar de industria para transportar inventario y precios entre servicios sin depender de UUID opacos.

```sql
catalog.products.variants.sku   text NOT NULL UNIQUE
```

Reglas:

- `sku` es **natural key**, no primary key;
- se declara `UNIQUE` en el schema owner (`catalog`) y **solo** ahﾃｭ;
- en los demﾃ｡s schemas `sku` es columna escalar sin `UNIQUE` global ni FK;
- el `sku` es inmutable una vez asignado. Si un flujo exige cambiarlo, se modela como migraciﾃｳn explﾃｭcita, nunca como UPDATE directo;
- el formato exacto del SKU **no** se fija con `CHECK` hasta que exista una especificaciﾃｳn que lo formalice.

### 6.3 Identificadores por tipo de dato

| Dato | Tipo | Notas |
|---|---|---|
| PK surrogate | `uuid` | regla general |
| SKU, slug, cﾃｳdigo de cupﾃｳn, `external_ref` | `text` | identidad natural de negocio |
| `order_id`, `operation_id`, `correlation_id`, `message_id`, `batch_id`, `reservation_id` | `uuid` | identidad tﾃｩcnica |
| `user_id`, `customer_ref` | `text` | referencia escalar a Seguridad, **sin FK** |

`id_auditoria` es la clave primaria de `price_audit.price_audit_log` y sigue la regla general (`uuid`), por consistencia de tipo en todo el mﾃｳdulo.

### 6.4 Nombres de constraint de unicidad de negocio

Las unicidades que exige el modelo se aplican como `UNIQUE` total, **no** como ﾃｭndice parcial:

| Restricciﾃｳn | Motivo |
|---|---|
| `uq_brands_nombre_normalizado` | la unicidad del nombre de marca incluye **inactivas** (`FLOW-011`, `SPEC-011`) |
| `uq_categories_slug` | el slug es ﾃｺnico; la violaciﾃｳn se traduce a `409 SLUG_DUPLICADO` |
| `uq_stock_balance_sku_location` | el saldo autoritativo es `(sku, location_id)` |
| `uq_coupon_uses_order_cupon` | un consumo por `(order_id, cupon_id)` |

El nombre de categorﾃｭa **no** es ﾃｺnico (`SPEC-008`). El slug sﾃｭ, y su carrera se resuelve en la capa de aplicaciﾃｳn, no con sufijos silenciosos.

---

## 7. Tipos recomendados para fechas y horas

### 7.1 Regla

| Semﾃ｡ntica | Tipo | Ejemplos |
|---|---|---|
| Momento de un hecho | `timestamptz NOT NULL DEFAULT now()` | `created_at`, `updated_at`, `deleted_at`, `occurred_at` |
| Fecha de negocio sin hora | `date` | `valid_from`, `valid_to`, `fecha_inicio` |
| Instante de expiraciﾃｳn | `timestamptz NOT NULL` | `expires_at` |
| Vigencia abierta | `timestamptz NULL` | `valid_to` |

Reglas duras:

- **Prohibido** `timestamp` sin zona horaria. Todo instante es `timestamptz`.
- Los valores de negocio se generan con el puerto `Clock` inyectable (`Arquitectura.md:2919-2941`); el `DEFAULT now()` es respaldo de infraestructura, no la fuente de la regla de negocio.
- `date` es solo para fechas de calendario. Si el dato necesita hora o participa de expiraciﾃｳn, es `timestamptz`.

### 7.2 Timestamps obligatorios

| Columna | Obligatoria | Default |
|---|---|---|
| created_at 	imestamptz NOT NULL | sí | 
ow() |
| updated_at 	imestamptz NOT NULL | sí, excepto exentas (§7.3) | 
ow() |
| deleted_at 	imestamptz NULL | opcional | NULL |

`updated_at` se mantiene por disparador `trg_<tabla>_updated_at` (ﾂｧ12), no por responsabilidad de la aplicaciﾃｳn, para que no pueda olvidarse.

### 7.3 Tablas exentas de `updated_at` y `deleted_at`

| Tabla | Motivo |
|---|---|
| `price_audit.price_audit_log` | bitﾃ｡cora estrictamente append-only (`Arquitectura.md:1537`, `SPEC-014:20`) |
| `inventory.kardex` | libro de movimientos: los correcciones se insertan, nunca se editan |
| `<schema>.inbox` | registro de deduplicaciﾃｳn de mensajes ya procesados |
- Ninguna lectura de negocio consulta outbox directamente. Esta tabla de infraestructura mantiene timestamps operativos propios (published_at, ttempts, last_error); no lleva updated_at (§7.3).

Agregar `updated_at` a una tabla append-only produce una mentira estructural: la columna nunca cambia de valor y sugiere que la fila es editable. En estas tablas se resuelve el flujo con una **nueva fila**, nunca con `UPDATE`.

### 7.4 Ausencia de TTL de negocio

`expires_at` se implementa en `inventory.reservations`, pero **ninguna constraint fija los minutos del TTL**. La duraciﾃｳn es configuraciﾃｳn operativa por entorno/canal, no del esquema.

---

## 8. Tipos recomendados para valores monetarios

### 8.1 Regla

```sql
precio      numeric(12,2) NOT NULL
moneda      char(3)      NOT NULL
porcentaje  numeric(5,2)  NOT NULL
cantidad    integer      NOT NULL
```

Prohibido `float`, `real`, `double precision` y `money` para valores de negocio. `money` tiene escala fija dependiente de `lc_monetary` y dificulta la aritmﾃｩtica de descuentos.

### 8.2 Quﾃｩ NO se agrega

Por acuerdo intermodular vigente:

- **no** se crea `CHECK (moneda = 'PEN')`. `PEN` es el valor de los fixtures y demostraciones, no una restricciﾃｳn del modelo. El campo de moneda debe admitir la moneda del contrato vigente.
- **no** se agregan columnas fiscales (`igv`, `base_imponible`, `tasa_igv`, `monto_descuento`) en `pricing`. La semﾃ｡ntica tributaria pertenece al flujo comercial/fiscal y aﾃｺn no estﾃ｡ homologada con Ventas y Retail.
- **no** se agrega `codigo_barras` a `catalog` como elemento obligatorio. El baseline 0.5.0 ya lo reconoce contractualmente, pero su representaciﾃｳn fﾃｭsica definitiva en `catalog` **aﾃｺn queda abierta** y no se impone en este documento. En caso de modelarse, deberﾃ｡ ser una extensiﾃｳn nullable y alineada al modelo lﾃｳgico/fﾃｭsico aprobado.

### 8.3 Moneda nula como precio global

El precio sin canal especﾃｭfico usa `channel_id` efectivo nulo (`api/openapi.yaml`). Por eso `channel_id` es nullable y **no** tiene `UNIQUE` global.

### 8.4 Medidas fﾃｭsicas

```sql
peso_kg   numeric(8,3)  peso
largo_cm  numeric(8,2)  ancho_cm  numeric(8,2)  alto_cm  numeric(8,2)
```

Unidad contractual fija: kg y cm. La conversiﾃｳn ocurre en adaptadores, nunca en la BD.

---

## 9. Uso de NOT NULL, UNIQUE, CHECK y FK

### 9.1 NOT NULL

`NOT NULL` es el default. Nullable solo cuando el modelo lo exige:

| Columna | ﾂｿNullable? | Motivo |
|---|---|---|
| `categoria_id` | sﾃｭ | la categorﾃｭa raﾃｭz no tiene padre |
| `parent_id` | sﾃｭ | FK autorreferencial opcional |
| `variante_id` | sﾃｭ | un producto simple no tiene variante propia |
| `moneda` | no | el precio siempre tiene moneda |
| `porcentaje_descuento` | no | si aplica descuento, tiene valor |
| `valor_descuento` | sﾃｭ | alterno de `porcentaje_descuento` |
| `ends_at` / `valid_to` | sﾃｭ | vigencia abierta |
| `deleted_at` | sﾃｭ | solo en borrado lﾃｳgico |

### 9.2 UNIQUE

- Unique para identidad natural y reglas de negocio explﾃｭcitas del bounded context.
- `UNIQUE` compuesto sigue el orden `(scope, key)`: `uq_stock_balance_sku_location (sku, location_id)`.
- No usar `UNIQUE` para modelar "existe" cuando la regla es de negocio condicional; eso es un `CHECK` o lﾃｳgica de aplicaciﾃｳn.
- El nombre de la categorﾃｭa no lleva `UNIQUE`.

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

**No** se crea un `CHECK` a partir de un supuesto de coordinaciﾃｳn con otro mﾃｳdulo. `moneda`, formato de `sku`, equivalencia entre `tienda_id` de Retail y `location_id` siguen abiertos y se resuelven en contratos, no en el esquema.

### 9.4 FOREIGN KEY

- **Solo dentro del mismo schema.**
- Toda FK se crea con `ON DELETE RESTRICT` explﾃｭcito (default) o `ON DELETE CASCADE` solo en tablas dependentemente}\; nunca `ON DELETE SET NULL` sobre columnas `NOT NULL`.
- `catalog.variants 竊・catalog.products` usa `ON DELETE CASCADE` porque una variante sin producto no tiene sentido.
- Toda FK **requiere** su ﾃｭndice en la columna referenciante. PostgreSQL no lo crea solo. Prefijo `ix_<tabla>_<columna>`.

Las FK permitidas estﾃ｡n enumeradas en `Modelo_Conceptual.md:1234-1249` y las prohibidas en `Modelo_Conceptual.md:1253-1278`.

---

## 10. Convenciones para Outbox e Inbox

### 10.1 Cuﾃ｡ndo aplican

| Schema | Outbox | Inbox | Motivo |
|---|---|---|---|
| `taxonomy`, `catalog`, `pricing`, `promotions`, `combos`, `inventory`, `bulk` | sﾃｭ | sﾃｭ | publican hechos de dominio |
| `price_audit` | no | sﾃｭ | solo consume; su registro es append-only y no publica (`Arquitectura.md:566-573`) |
| `read_model` | no | sﾃｭ | proyecta; no publica hechos de dominio |

Si un bounded context no publica eventos, su `outbox` no se crea. No se crean tablas vacﾃｭas "por simetrﾃｭa".

### 10.2 Estructura obligatoria

```sql
CREATE TABLE <schema>.outbox (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id      uuid        NOT NULL UNIQUE,          -- correlaciﾃｳn de idempotencia de publicaciﾃｳn
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

1. El registro en `outbox` ocurre **en la misma transacciﾃｳn** del cambio de negocio (`Arquitectura.md:817`).
2. La publicaciﾃｳn ocurre **despuﾃｩs** del commit. Nunca dentro.
3. `inbox` garantiza unicidad por `(message_id, handler)` 窶・deduplicaciﾃｳn, no solo por `message_id`, para no bloquear handlers legﾃｭtimos distintos.
4. `published_at IS NULL` significa pendiente. El relay ordena por `occurred_at`.
5. Ninguna lectura de negocio consulta `outbox` directamente.

### 10.4 Idempotencia de negocio

La deduplicaciﾃｳn tﾃｩcnica (`inbox`) no sustituye la idempotencia de negocio. Donde aplique, se declara ademﾃ｡s:

```sql
CONSTRAINT uq_inventory_operations_operation_id UNIQUE (operation_id)
```

En Inventario, misma identidad + misma intenciﾃｳn = replay sin efectos; misma identidad + intenciﾃｳn distinta = `IDEMPOTENCY_CONFLICT`.

---

## 11. Criterios bﾃ｡sicos para ﾃｭndices

### 11.1 Cuﾃ｡ndo indexar

| Caso | ﾃ肱dice |
|---|---|
| Toda FK | `ix_<tabla>_<columna>` (obligatorio) |
| Filtro frecuente por estado | `ix_<tabla>_estado` |
| Bﾃｺsqueda por identidad natural | cubierto por el `UNIQUE` |
| Rango temporal (expiraciﾃｳn, vigencia) | `ix_<tabla>_expires_at` |
| Orden de salida del relay | `ix_outbox_pending (published_at, occurred_at)` |
| Reportes de dashboard | materializado en `dashboard_projection`, no sobre la tabla transaccional |

### 11.2 ﾃ肱dices parciales y compuestos

Se permiten ﾃｭndices parciales y compuestos cuando la consulta lo justifica. Se **exige** justification en `physical-model.md`.

```sql
CREATE INDEX ix_products_estado_activo
  ON catalog.products (estado)
  WHERE deleted_at IS NULL AND estado = 'ACTIVO';

CREATE INDEX ix_reservations_expires_at
  ON inventory.reservations (expires_at)
  WHERE estado = 'ACTIVA';
```

### 11.3 Quﾃｩ no indexar

- Columnas de baja cardinalidad sin filtro (`*_version`, booleanos sueltos).
- Columnas ya cubiertas por el ﾃｭndice de un `UNIQUE`.
- Texto largo o `jsonb` salvo necesidad de bﾃｺsqueda explﾃｭcita.
- No crear ﾃｭndices "por si acaso": cada ﾃｭndice cuesta en escritura.

---

## 12. Disparadores de `updated_at`

Un ﾃｺnico disparador por tabla, funciﾃｳn compartida en cada schema:

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

- **Nunca** en tablas exentas (ﾂｧ7.3).
- **Nunca** en tablas append-only.
- La funciﾃｳn es local al schema. No se crea en `public` ni se comparte entre servicios.

---

## 13. Enumeraciones

### 13.1 Tipo nativo frente a texto

Por decisiﾃｳn del equipo se usa **tipo nativo de PostgreSQL** para validaciﾃｳn estricta en base de datos:

```sql
CREATE TYPE catalog.estado_producto AS ENUM ('BORRADOR','ACTIVO','INACTIVO');
```

### 13.2 Cuﾃ｡ndo crear un tipo y cuﾃ｡ndo no

| Caso | Tipo |
|---|---|
| Estado de ciclo de vida de una entidad **propia** del bounded context y ya publicado en el contrato | tipo nativo |
| Catﾃ｡logo de valores de negocio abierto, en negociaciﾃｳn con otro mﾃｳdulo | `text` + `CHECK` |
| Cﾃｳdigo de canal, moneda, cﾃｳdigo de error, paﾃｭs | `text` + `CHECK` |

No se crea un tipo por cada `enum:` del OpenAPI: el contrato contiene cientos de enumeraciones y la mayorﾃｭa son cﾃｳdigos de error o catﾃ｡logos externos, no estados propios.

### 13.3 Alcance de los tipos

**Los tipos enumerados son propiedad del schema que los declara.**

- Se crean dentro del schema del servicio: `CREATE TYPE catalog.estado_producto ...`.
- Ningﾃｺn schema referencia un tipo de otro schema. Referenciarlo crearﾃｭa una dependencia cross-service, prohibida por ﾂｧ4.
- Si dos servicios necesitan la misma enumeraciﾃｳn, **cada una declara su tipo local**. La consecuencia 窶牌alores idﾃｩnticos duplicados窶・es el precio correcto de la aislamiento.
- Un tipo de `taxonomy` no se comparte con `catalog`, aunque ambos modelen un estado activo/inactivo.

### 13.4 Coste asumido

`ALTER TYPE ... ADD VALUE` no puede ejecutarse dentro de un bloque transaccional en PostgreSQL < 12 y su uso en migraciones es delicado. Esto refuerza la regla de migraciones: **las migraciones son reproducibles desde cero** (`Arquitectura.md:651`) y no se editan una vez aplicadas. Para agregar un valor se crea una migraciﾃｳn nueva, nunca se altera una aplicada.

Si en el futuro un estado debe dejar de existir, se planifica `expand/contract` (ﾂｧ15), no se edita la migraciﾃｳn que lo creﾃｳ.

---

## 14. Baja lﾃｳgica: `estado` y `deleted_at`

Son dos mecanismos distintos y **no intercambiables**.

### 14.1 `estado` 窶・baja de negocio

Es el mecanismo oficial y el que expone el contrato (`EstadoEntidad: ACTIVO | INACTIVO` en `api/openapi.yaml`). Conserva el `id` y permite la reactivaciﾃｳn con la misma identidad.

```sql
estado <estado_entidad> NOT NULL DEFAULT 'ACTIVO'
```

Se usa en: categorﾃｭas, marcas, caracterﾃｭsticas, valores, tipos de producto, variantes, promociones, combos.

### 14.2 `deleted_at` 窶・barrera de borrado fﾃｭsico

`deleted_at timestamptz NULL` no es un segundo mecanismo de baja. Es la garantﾃｭa de que **la fila no se borra fﾃｭsicamente**, para no romper proyecciones que otros servicios ya materializaron de ella.

```sql
deleted_at timestamptz NULL DEFAULT NULL
```

Reglas:

- `deleted_at` **nunca** sustituye a `estado`;
- una tabla **no** usa `estado` y `deleted_at` para el mismo propﾃｳsito;
- `deleted_at` no participa de la lﾃｳgica de negocio ni se filtra por defecto en el contrato HTTP; la proyecciﾃｳn de estado sigue siendo `estado`;
- no se construyen ﾃｭndices parciales `WHERE deleted_at IS NULL` para esquivar reglas de unicidad. Las unicidades que el modelo exige se aplican como `UNIQUE` total (ﾂｧ6.4), incluso entre filas dadas de baja, porque el modelo exige unicidad tambiﾃｩn entre inactivas.

### 14.3 Precedencia

```text
estado      竊・regla de negocio, visible en el contrato, controla reactivaciﾃｳn
deleted_at  竊・control de retenciﾃｳn, impide DELETE fﾃｭsico
```

Una tabla con `estado` **no** necesita `deleted_at`. Se documenta la excepciﾃｳn en `physical-model.md` (ﾂｧ7.3 y esta secciﾃｳn) para que la omisiﾃｳn sea deliberada y no un descuido.

---

## 15. Migraciones

### 15.1 Reglas

1. Una migraciﾃｳn **nunca** modifica el schema de otro servicio.
2. Las migraciones son **reproducibles desde cero**.
3. No se edita una migraciﾃｳn ya aplicada en un ambiente compartido.
4. Los cambios destructivos usan **expand/contract**.
5. Las migraciones se ejecutan antes de iniciar la nueva versiﾃｳn.
6. No se depende de creaciﾃｳn automﾃ｡tica de tablas del ORM (`Arquitectura.md:644-665`).

### 15.2 Expand/contract

```text
v1  aﾃｱadir columna nueva nullable
v2  escribir campo viejo + nuevo
v3  migrar datos histﾃｳricos
v4  leer solo el nuevo
v5  retirar el campo viejo
```

### 15.3 Nomenclatura

```text
<NNN>_<verbo>_<objeto>.sql        001_create_schema.sql
                                  002_create_enum_catalog.sql
                                  003_create_table_products.sql
```

La numeraciﾃｳn es secuencial y sin huecos dentro de un servicio.

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

- Un rol por schema. `catalog_app` no ve `pricing`, ni al revﾃｩs.
- `REVOKE ALL ON SCHEMA <x> FROM PUBLIC` es obligatorio en los nueve schemas.
- Cada servicio se conecta con su propio rol y sus propias credenciales (`Arquitectura.md:499`).

### 16.2 Row Level Security

- **RLS se habilita ﾃｺnicamente en `read_model`**, que es el ﾃｺnico schema expuesto por la API pﾃｺblica.
- Los schemas de escritura **no** activan RLS: su aislamiento se logra por rol y por `REVOKE`, no por polﾃｭticas de fila, porque una polﾃｭtica RLS incorrecta producirﾃｭa fallos silenciosos de escritura.
- `read_model` no tiene FK hacia schemas de dominio: son proyecciones reconstruibles.

### 16.3 Compatibilidad con Supabase

| Punto | Regla |
|---|---|
| Esquemas visibles | Supabase expone `public` por defecto. Los nueve schemas deben registrarse en la configuraciﾃｳn de la plataforma para que PostgREST los sirva; no se usa `public` para datos de negocio. |
| `auth.users` | **no** existe FK hacia `auth.users`. El usuario es `user_id text` / `customer_ref text`. |
| RLS | solo `read_model`. |
| Extensiones | `pgcrypto` no es necesaria con PostgreSQL 13+. Si un entorno concreto la exige, se declara en la migraciﾃｳn, nunca se asume. |
| Claims de JWT | no se copian al esquema; se resuelven en la capa de aplicaciﾃｳn. |

### 16.4 Identidad

Toda referencia a usuario es una columna escalar:

```sql
user_id      text NULL
customer_ref text NULL
```

Nunca FK. Nunca `uuid` con REFERENCES a `auth.users`.

---

## 17. Elementos que no deben modelarse

Por acuerdo intermodular vigente, ningﾃｺn schema debe crear:

| Elemento | Motivo |
|---|---|
| `reservation.location_id NOT NULL` como reemplazo de `location_line.location_id` | cierra prematuramente split fulfillment; la ubicaciﾃｳn se modela a nivel de lﾃｭnea |
| FK o tabla de Retail | `external_ref` es extensiﾃｳn opcional, no contrato |
| `CHECK (moneda = 'PEN')` | PEN es valor de fixture, no regla del modelo |
| `igv`, `base_imponible`, `tasa_igv` en `pricing` | semﾃ｡ntica tributaria aﾃｺn no homologada |
| `codigo_barras` en `catalog` | ya reconocido contractualmente, pero representaciﾃｳn fﾃｭsica aﾃｺn no definida; en caso de incluirlo, debe ser nullable |
| tablas Pickup (`pickup_order`, `pickup_handoff`, `pickup_store_receipt`) | sin contrato intermodular que las exija |
| `pedido`, `pago`, `reserva_inventario` en `combos` | Combos no es owner de pedido ni de pago |
| columnas fiscales o de despacho en cualquier schema | ﾂｧ4 y ﾂｧ8.2 |

---

## 18. Tablas aﾃｱadidas respecto a `Arquitectura.md` ﾂｧ7.2

`Arquitectura.md:602-615` enumera las tablas de `inventory` sin incluir la ubicaciﾃｳn, pese a que `Modelo_Conceptual.md:694` define LOCATION como entidad conceptual y `Contrato_Api.md` asigna a Inventario el ownership de Ubicaciﾃｳn.

Esta convenciﾃｳn aﾃｱade:

| Tabla | Motivo |
|---|---|
| `inventory.locations` | da soporte referencial a `stock_balance.location_id` y `reservation_lines.location_id` |

Columnas de referencia:

```text
id            uuid PRIMARY KEY
code          text NOT NULL UNIQUE
name          text NOT NULL
type          text NOT NULL
external_ref  text NULL      -- extensiﾃｳn; sin CHECK de formato, sin FK
active        boolean NOT NULL DEFAULT true
created_at    timestamptz NOT NULL DEFAULT now()
updated_at    timestamptz NOT NULL DEFAULT now()
```

`external_ref` es una posibilidad de implementaciﾃｳn para asociar `tienda_id` de Retail. No se le aplica `CHECK`, no se le da `UNIQUE` y no se declara FK.

Esta tabla requiere validaciﾃｳn del responsable de `inventory-svc` antes de aprobarse.

---

## 19. Checklist de aprobaciﾃｳn de un modelo fﾃｭsico

Antes de aprobar un `physical-model.md` o un `migration.sql`:

- [ ] No existe FK entre schemas de servicios distintos.
- [ ] No existe acceso SQL cross-service.
- [ ] Toda FK tiene ﾃｭndice en su columna referenciante.
- [ ] Toda tabla tiene `created_at timestamptz NOT NULL DEFAULT now()`.
- [ ] `updated_at` existe salvo en las tablas exentas de ﾂｧ7.3.
- [ ] No hay `float`, `real`, `double precision` ni `money` para valores de negocio.
- [ ] No hay `timestamp` sin zona horaria.
- [ ] No hay `serial`, `bigserial` ni PK natural.
- [ ] Los tipos enumerados son locales a su schema y no se referencian entre schemas.
- [ ] Toda constraint, ﾃｭndice, disparador y funciﾃｳn lleva prefijo.
- [ ] `estado` y `deleted_at` no se usan para el mismo propﾃｳsito.
- [ ] Las referencias externas son columnas escalares sin FK.
- [ ] Las unicidades exigidas por el modelo son `UNIQUE` totales.
- [ ] `outbox` existe solo en los schemas que publican eventos; `inbox` en los que consumen.
- [ ] El registro en `outbox` estﾃ｡ dentro de la transacciﾃｳn de negocio.
- [ ] RLS estﾃ｡ activo solo en `read_model`.
- [ ] Cada schema tiene `REVOKE ALL ... FROM PUBLIC` y su propio rol.
- [ ] No hay FK hacia `auth.users`; el usuario es `user_id text`.
- [ ] Las migraciones se ejecutan desde cero en una base vacﾃｭa.
- [ ] `validation.sql` del servicio devuelve todos los checks en `PASS`.

---

## 20. Plantillas

| Documento | Uso |
|---|---|
| [`plantillas/physical-model.md`](plantillas/physical-model.md) | Modelo fﾃｭsico de un bounded context |
| [`plantillas/migration.sql`](plantillas/migration.sql) | Estructura de migraciones de un bounded context |
| [`plantillas/validation.sql`](plantillas/validation.sql) | Checks verificables de un bounded context |
| [`README.md`](README.md) | ﾃ肱dice de los entregables de BD |

Cada microservicio copia las plantillas en su propia carpeta de persistencia y las rellena. La convenciﾃｳn no se reescribe por servicio.
