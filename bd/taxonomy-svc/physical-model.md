# Taxonomía — Modelo Físico de `taxonomy-svc`

## 1. Identificación

- **Issue:** #48 (Convenciones de BD) / #54 (Persistencia de Taxonomía).
- **Responsable:** Leonardo Lopez (`lopez`).
- **Rol transversal:** Datos y Testing.
- **Funcionalidades:**
  - 008 Gestión de categorías y subcategorías
  - 009 Gestión de características y sus valores
  - 010 Asociación entre tipos de producto y características
  - 011 Gestión de marcas
  - 012 Gestión de SEO y metadatos
- **Bounded context:** Taxonomía y Atributos.
- **Microservicio:** `taxonomy-svc`.
- **Schema:** `taxonomy`.
- **Owner de despliegue:** `po_taxonomy_owner` (NOLOGIN, aprovisionado en `database/bootstrap.sql`).
- **Usuario runtime:** `taxonomy_app` (LOGIN, sin privilegios administrativos ni membresía owner).
- **Fecha:** 2026-10-03.
- **Estado:** BORRADOR PARA REVISIÓN.
- **Motor objetivo:** PostgreSQL 15+ / Supabase.
- **Modelo lógico de origen:** [logical-model.md](logical-model.md).
- **Migraciones:** [migrations/0001_create_taxonomy.sql](migrations/0001_create_taxonomy.sql).
- **Validación:** [validation.sql](validation.sql).

---

## 2. Fuentes y precedencia

Este diseño físico traduce a PostgreSQL las definiciones funcionales, conceptuales y lógicas consolidadas:

| Fuente | Aporte normativo al modelo físico |
|---|---|
| [Modelo_Conceptual.md §3](../../Modelo_Conceptual.md) | Definición conceptual de categorías, marcas, características, tipos de producto, SEO y operaciones de baja |
| [Arquitectura.md §7.1–7.2](../../Arquitectura.md) | Declaración formal del schema `taxonomy` y sus tablas componentes |
| [bd/CONVENCIONES_BD.md](../../bd/CONVENCIONES_BD.md) | Convenciones comunes: UUID, tipos, naming, índices, seguridad y aislamiento estricto |
| [SPEC-008 a SPEC-012](../../specs/) | Reglas de negocio e invariantes de datos |
| [api/openapi.yaml](../../api/openapi.yaml) 0.5.0 | Esquemas DTO de entrada/salida y códigos de error |
| [asyncapi/asyncapi.yaml](../../asyncapi/asyncapi.yaml) 0.4.0 | Eventos de dominio y estructura de mensajes |
| [logical-model.md](logical-model.md) | Estructura lógica de entidades, relaciones y atributos |

**Cadena de precedencia:**
```text
fuentes funcionales y contractuales
        ↓
modelo conceptual (Modelo_Conceptual.md)
        ↓
logical-model.md
        ↓
physical-model.md (este documento)
        ↓
migrations/ (0001_create_taxonomy.sql)
        ↓
validation.sql
```

---

## 3. Propósito

Materializar el modelo lógico de `taxonomy-svc` en un diseño físico ejecutable, seguro y de alto rendimiento sobre PostgreSQL/Supabase.

Define explícitamente:
- Tablas, columnas y tipos de datos nativos de PostgreSQL.
- Claves primarias mediante UUID (`gen_random_uuid()`).
- Claves foráneas internas y restricciones `ON DELETE RESTRICT`.
- Restricciones de unicidad (`UNIQUE`) y de comprobación (`CHECK`).
- Enumeraciones locales al schema.
- Índices B-Tree optimizados para consultas y claves foráneas.
- Triggers para auditoría (`updated_at`), inmutabilidad de tipos e historial de slugs.
- Tablas técnicas de integración transaccional (`outbox`, `inbox`).
- Aislamiento de seguridad y permisos de roles (`po_taxonomy_owner`, `taxonomy_app`).

---

## 4. Alcance del bounded context

### 4.1. Datos que posee (Ownership absoluto)
- `taxonomy.categories`: Categorías de navegación y su jerarquía recursiva.
- `taxonomy.brands`: Catálogo maestro de marcas comerciales.
- `taxonomy.characteristics`: Catálogo de características abstractas.
- `taxonomy.characteristic_values`: Valores predefinidos de características tipo `LISTA`.
- `taxonomy.product_types`: Familias y tipos de producto.
- `taxonomy.product_type_characteristics`: Esquema de atributos asociados a cada tipo.
- `taxonomy.category_seo`: Metadatos SEO vigentes y slug canónico de cada categoría.
- `taxonomy.category_slug_history`: Bitácora histórica de redirecciones 301 de URLs de categorías.
- `taxonomy.master_deactivation_operations`: Registro observable de solicitudes asíncronas de baja.
- `taxonomy.outbox`: Eventos de dominio pendientes o publicados.
- `taxonomy.inbox`: Eventos consumidos para procesamiento idempotente.

### 4.2. Datos que NO posee (Aislamiento)
- **Productos y Variantes:** Pertenecen a `catalog`.
- **Precios:** Pertenecen a `pricing`.
- **Stock:** Pertenece a `inventory`.
- **Usuarios / Clientes:** Pertenecen al proveedor de identidad.

---

## 5. Principios de diseño físico y aislamiento

1. **Aislamiento de schema:** Todo objeto de base de datos reside en el schema `taxonomy`.
2. **Prohibición absoluta de FK cross-service:** No existe ninguna clave foránea hacia tablas de `catalog`, `pricing`, `inventory` o `auth.users`.
3. **Prohibición de acceso SQL directo:** Otros microservicios interactúan exclusivamente mediante la API HTTP o eventos RabbitMQ; jamás ejecutan `SELECT` o `JOIN` sobre el schema `taxonomy`.
4. **Seguridad y privilegios:**
   - `REVOKE ALL ON SCHEMA taxonomy FROM PUBLIC;` es obligatorio.
   - Solo `taxonomy_app` tiene permisos de lectura/escritura en runtime.
   - `RLS` no se habilita en `taxonomy` (los microservicios de dominio se aíslan por rol y schema, reservando RLS exclusivamente para `read_model` según `CONVENCIONES_BD.md:606`).
5. **Convenciones de nombres:**
   - Tablas: `snake_case`, singular o plural según `Arquitectura.md:532` (`categories`, `brands`, `characteristics`, etc.).
   - Claves primarias: `id uuid NOT NULL DEFAULT gen_random_uuid()`, constraint `pk_<tabla>`.
   - Claves foráneas: constraint `fk_<tabla>_<columna>`.
   - Índices: `ix_<tabla>_<columna>` para búsquedas, `ux_<tabla>_<columnas>` para unicidades funcionales.
   - Checks: `ck_<tabla>_<regla>`.

---

## 6. Inventario de tablas

| Tabla | Propósito | Origen | Clave primaria | Tipo de persistencia |
|---|---|---|---|---|
| `taxonomy.categories` | Árbol jerárquico de categorías | Entidad `CATEGORIA` | `id` (UUID) | Mutable |
| `taxonomy.brands` | Marcas comerciales unificadas | Entidad `MARCA` | `id` (UUID) | Mutable |
| `taxonomy.characteristics` | Catálogo maestro de atributos | Entidad `CARACTERISTICA` | `id` (UUID) | Mutable (tipo inmutable) |
| `taxonomy.characteristic_values` | Opciones de características de lista | Entidad `VALOR_CARACTERISTICA` | `id` (UUID) | Mutable |
| `taxonomy.product_types` | Tipos y familias de producto | Entidad `TIPO_PRODUCTO` | `id` (UUID) | Mutable |
| `taxonomy.product_type_characteristics` | Matriz de esquemas de atributos | Relación `ASOCIACION` | `id` (UUID) | Mutable |
| `taxonomy.category_seo` | Configuración SEO y slug canónico | Entidad `SEO_CATEGORIA` | `id` (UUID) | Mutable |
| `taxonomy.category_slug_history` | Historial de redirecciones 301 | Entidad `HISTORIAL_SLUG` | `id` (UUID) | Append-only (sin `updated_at`) |
| `taxonomy.master_deactivation_operations` | Bitácora de bajas asíncronas | Entidad `OPERACION_BAJA` | `id` (UUID) | Mutable |
| `taxonomy.outbox` | Publicación de eventos de dominio | Patrón Outbox transaccional | `id` (UUID) | Cola / Ledger |
| `taxonomy.inbox` | Consumo idempotente de eventos | Patrón Inbox transaccional | `id` (UUID) | Ledger de deduplicación |

---

## 7. Enumeraciones locales del schema

Todos los tipos ENUM son locales a `taxonomy` para evitar acoplamiento cross-service:

```sql
CREATE TYPE taxonomy.estado_entidad AS ENUM (
    'ACTIVO',
    'INACTIVO',
    'DESACTIVACION_PENDIENTE'
);

CREATE TYPE taxonomy.tipo_caracteristica AS ENUM (
    'TEXTO',
    'NUMERO',
    'LISTA'
);

CREATE TYPE taxonomy.tipo_entidad_maestra AS ENUM (
    'CATEGORY',
    'BRAND',
    'CHARACTERISTIC',
    'CHARACTERISTIC_VALUE',
    'PRODUCT_TYPE',
    'PRODUCT_TYPE_CHARACTERISTIC'
);

CREATE TYPE taxonomy.estado_operacion_baja AS ENUM (
    'REQUESTED',
    'IN_PROGRESS',
    'COMPLETED',
    'REJECTED',
    'FAILED'
);
```

---

## 8. Especificación detallada de tablas físicas

### 8.1. `taxonomy.categories`
Almacena las categorías de navegación en un modelo recursivo con profundidad máxima 2 para el MVP.

```sql
CREATE TABLE taxonomy.categories (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    descripcion text NULL,
    categoria_padre_id uuid NULL,
    nivel smallint NOT NULL DEFAULT 1,
    orden integer NOT NULL DEFAULT 0,
    imagen_url text NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_categories PRIMARY KEY (id),
    CONSTRAINT fk_categories_categoria_padre FOREIGN KEY (categoria_padre_id)
        REFERENCES taxonomy.categories(id) ON DELETE RESTRICT,
    CONSTRAINT ck_categories_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_categories_nivel CHECK (nivel IN (1, 2)),
    CONSTRAINT ck_categories_orden CHECK (orden >= 0),
    CONSTRAINT ck_categories_version CHECK (taxonomy_version >= 0),
    CONSTRAINT ck_categories_no_self_parent CHECK (categoria_padre_id <> id),
    CONSTRAINT ck_categories_padre_nivel CHECK (
        (categoria_padre_id IS NULL AND nivel = 1) OR
        (categoria_padre_id IS NOT NULL AND nivel = 2)
    )
);
```

### 8.2. `taxonomy.brands`
Almacena las marcas comerciales. El nombre es estrictamente único en todo el catálogo.

```sql
CREATE TABLE taxonomy.brands (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    descripcion text NULL,
    logo_url text NULL,
    pais_origen_iso char(2) NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_brands PRIMARY KEY (id),
    CONSTRAINT uq_brands_nombre UNIQUE (nombre),
    CONSTRAINT ck_brands_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_brands_pais_iso CHECK (pais_origen_iso IS NULL OR pais_origen_iso ~ '^[A-Z]{2}$'),
    CONSTRAINT ck_brands_version CHECK (taxonomy_version >= 0)
);
```

### 8.3. `taxonomy.characteristics`
Almacena las características abstractas maestras. El tipo de dato es inmutable.

```sql
CREATE TABLE taxonomy.characteristics (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    tipo taxonomy.tipo_caracteristica NOT NULL,
    unidad_medida text NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_characteristics PRIMARY KEY (id),
    CONSTRAINT uq_characteristics_nombre UNIQUE (nombre),
    CONSTRAINT ck_characteristics_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_characteristics_unidad_medida CHECK (
        (tipo = 'NUMERO' AND unidad_medida IS NOT NULL AND length(trim(unidad_medida)) > 0) OR
        (tipo <> 'NUMERO' AND unidad_medida IS NULL)
    ),
    CONSTRAINT ck_characteristics_version CHECK (taxonomy_version >= 0)
);
```

### 8.4. `taxonomy.characteristic_values`
Valores predefinidos de características de tipo `LISTA`. Máximo 50 valores activos por característica.

```sql
CREATE TABLE taxonomy.characteristic_values (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    caracteristica_id uuid NOT NULL,
    nombre text NOT NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_characteristic_values PRIMARY KEY (id),
    CONSTRAINT fk_characteristic_values_caracteristica FOREIGN KEY (caracteristica_id)
        REFERENCES taxonomy.characteristics(id) ON DELETE RESTRICT,
    CONSTRAINT uq_characteristic_values_nombre UNIQUE (caracteristica_id, nombre),
    CONSTRAINT ck_characteristic_values_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_characteristic_values_version CHECK (taxonomy_version >= 0)
);
```

### 8.5. `taxonomy.product_types`
Tipos o familias de producto que definen esquemas de atributos técnicos.

```sql
CREATE TABLE taxonomy.product_types (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre text NOT NULL,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    schema_version bigint NOT NULL DEFAULT 1,
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_product_types PRIMARY KEY (id),
    CONSTRAINT uq_product_types_nombre UNIQUE (nombre),
    CONSTRAINT ck_product_types_nombre_not_empty CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_product_types_schema_version CHECK (schema_version >= 1),
    CONSTRAINT ck_product_types_version CHECK (taxonomy_version >= 0)
);
```

### 8.6. `taxonomy.product_type_characteristics`
Tabla de unión que compone el esquema de atributos por tipo de producto.

```sql
CREATE TABLE taxonomy.product_type_characteristics (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    tipo_producto_id uuid NOT NULL,
    caracteristica_id uuid NOT NULL,
    obligatoria boolean NOT NULL DEFAULT false,
    estado taxonomy.estado_entidad NOT NULL DEFAULT 'ACTIVO',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_product_type_characteristics PRIMARY KEY (id),
    CONSTRAINT fk_ptc_tipo_producto FOREIGN KEY (tipo_producto_id)
        REFERENCES taxonomy.product_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ptc_caracteristica FOREIGN KEY (caracteristica_id)
        REFERENCES taxonomy.characteristics(id) ON DELETE RESTRICT,
    CONSTRAINT uq_ptc_tipo_caracteristica UNIQUE (tipo_producto_id, caracteristica_id)
);
```

### 8.7. `taxonomy.category_seo`
Metadatos SEO asociados a una categoría (relación 1:1) y slug canónico globalmente único.

```sql
CREATE TABLE taxonomy.category_seo (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    categoria_id uuid NOT NULL,
    slug text NOT NULL,
    meta_titulo text NULL,
    meta_descripcion text NULL,
    taxonomy_version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_category_seo PRIMARY KEY (id),
    CONSTRAINT fk_category_seo_categoria FOREIGN KEY (categoria_id)
        REFERENCES taxonomy.categories(id) ON DELETE RESTRICT,
    CONSTRAINT uq_category_seo_categoria UNIQUE (categoria_id),
    CONSTRAINT uq_category_seo_slug UNIQUE (slug),
    CONSTRAINT ck_category_seo_slug_format CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    CONSTRAINT ck_category_seo_version CHECK (taxonomy_version >= 0)
);
```

### 8.8. `taxonomy.category_slug_history`
Bitácora inmutable (append-only) de cambios de slug para redirección 301 en Marketplace. Exenta de `updated_at`.

```sql
CREATE TABLE taxonomy.category_slug_history (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    categoria_id uuid NOT NULL,
    old_slug text NOT NULL,
    new_slug text NOT NULL,
    changed_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_category_slug_history PRIMARY KEY (id),
    CONSTRAINT fk_category_slug_history_categoria FOREIGN KEY (categoria_id)
        REFERENCES taxonomy.categories(id) ON DELETE RESTRICT,
    CONSTRAINT ck_category_slug_history_distinct CHECK (old_slug <> new_slug)
);
```

### 8.9. `taxonomy.master_deactivation_operations`
Bitácora de operaciones observables de baja maestra segura para el recurso `/taxonomia/operaciones/{operationId}`.

```sql
CREATE TABLE taxonomy.master_deactivation_operations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    operation_id text NOT NULL,
    entity_type taxonomy.tipo_entidad_maestra NOT NULL,
    entity_id uuid NOT NULL,
    status taxonomy.estado_operacion_baja NOT NULL DEFAULT 'REQUESTED',
    reason text NULL,
    correlation_id text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_master_deactivation_operations PRIMARY KEY (id),
    CONSTRAINT uq_mdo_operation_id UNIQUE (operation_id),
    CONSTRAINT ck_mdo_operation_id_not_empty CHECK (length(trim(operation_id)) > 0),
    CONSTRAINT ck_mdo_correlation_id_not_empty CHECK (length(trim(correlation_id)) > 0)
);
```

### 8.10. `taxonomy.outbox`
Patrón Outbox transaccional para publicación confiable hacia RabbitMQ sin dos fases de commit.

```sql
CREATE TABLE taxonomy.outbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    event_id uuid NOT NULL DEFAULT gen_random_uuid(),
    event_type text NOT NULL,
    aggregate_type text NOT NULL,
    aggregate_id text NOT NULL,
    payload jsonb NOT NULL,
    correlation_id text NOT NULL,
    status text NOT NULL DEFAULT 'PENDING',
    retry_count integer NOT NULL DEFAULT 0,
    error_message text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    published_at timestamptz NULL,
    CONSTRAINT pk_outbox PRIMARY KEY (id),
    CONSTRAINT uq_outbox_event_id UNIQUE (event_id),
    CONSTRAINT ck_outbox_status CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED')),
    CONSTRAINT ck_outbox_retry_count CHECK (retry_count >= 0)
);
```

### 8.11. `taxonomy.inbox`
Patrón Inbox transaccional para garantizar consumo idempotente de respuestas de Catálogo (`catalog.master.deactivation.checked`).

```sql
CREATE TABLE taxonomy.inbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    message_id text NOT NULL,
    event_type text NOT NULL,
    producer text NOT NULL,
    payload jsonb NOT NULL,
    status text NOT NULL DEFAULT 'PROCESSED',
    received_at timestamptz NOT NULL DEFAULT now(),
    processed_at timestamptz NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_inbox PRIMARY KEY (id),
    CONSTRAINT uq_inbox_message_id UNIQUE (message_id),
    CONSTRAINT ck_inbox_status CHECK (status IN ('RECEIVED', 'PROCESSED', 'FAILED'))
);
```

---

## 9. Funciones y disparadores (Triggers)

### 9.1. Actualización automática de `updated_at`
```sql
CREATE OR REPLACE FUNCTION taxonomy.fn_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;
```

### 9.2. Inmutabilidad del tipo de característica
Garantiza a nivel de base de datos que el campo `tipo` de una característica jamás pueda ser alterado:
```sql
CREATE OR REPLACE FUNCTION taxonomy.fn_prevent_characteristic_type_change()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.tipo <> NEW.tipo THEN
        RAISE EXCEPTION 'El tipo de característica (%) es inmutable y no puede modificarse a %',
            OLD.tipo, NEW.tipo;
    END IF;
    RETURN NEW;
END;
$$;
```

### 9.3. Control estricto de valores para tipo LISTA y tope de 50 activos
Garantiza que solo características de tipo `LISTA` puedan tener valores predefinidos y que no se superen los 50 valores en estado `ACTIVO`:
```sql
CREATE OR REPLACE FUNCTION taxonomy.fn_enforce_characteristic_value_rules()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_tipo taxonomy.tipo_caracteristica;
    v_activos integer;
BEGIN
    SELECT tipo INTO v_tipo FROM taxonomy.characteristics WHERE id = NEW.caracteristica_id;
    IF v_tipo <> 'LISTA' THEN
        RAISE EXCEPTION 'Solo las características de tipo LISTA pueden tener valores predefinidos. Tipo actual: %', v_tipo;
    END IF;

    IF NEW.estado = 'ACTIVO' THEN
        SELECT count(*) INTO v_activos
        FROM taxonomy.characteristic_values
        WHERE caracteristica_id = NEW.caracteristica_id
          AND estado = 'ACTIVO'
          AND id <> coalesce(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);
        IF v_activos >= 50 THEN
            RAISE EXCEPTION 'Límite alcanzado: una característica no puede tener más de 50 valores activos';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
```

### 9.4. Registro automático en el historial de redirecciones de slugs (301)
Cuando se actualiza el slug de una categoría en `category_seo`, se inserta automáticamente el asiento histórico:
```sql
CREATE OR REPLACE FUNCTION taxonomy.fn_track_slug_history()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.slug <> NEW.slug THEN
        INSERT INTO taxonomy.category_slug_history (categoria_id, old_slug, new_slug, changed_at)
        VALUES (NEW.categoria_id, OLD.slug, NEW.slug, now());
    END IF;
    RETURN NEW;
END;
$$;
```

### 9.5. Incremento de `schema_version` en `product_types`
Cualquier cambio en la obligatoriedad o asociación de características incrementa automáticamente la versión del esquema del tipo:
```sql
CREATE OR REPLACE FUNCTION taxonomy.fn_bump_product_type_schema_version()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    UPDATE taxonomy.product_types
    SET schema_version = schema_version + 1,
        updated_at = now()
    WHERE id = coalesce(NEW.tipo_producto_id, OLD.tipo_producto_id);
    RETURN NEW;
END;
$$;
```

---

## 10. Índices optimizados

Para optimizar claves foráneas y búsquedas frecuentes:

```sql
-- Índices en claves foráneas internas
CREATE INDEX ix_categories_padre_id ON taxonomy.categories(categoria_padre_id);
CREATE INDEX ix_characteristic_values_caracteristica_id ON taxonomy.characteristic_values(caracteristica_id);
CREATE INDEX ix_ptc_tipo_producto_id ON taxonomy.product_type_characteristics(tipo_producto_id);
CREATE INDEX ix_ptc_caracteristica_id ON taxonomy.product_type_characteristics(caracteristica_id);
CREATE INDEX ix_category_seo_categoria_id ON taxonomy.category_seo(categoria_id);
CREATE INDEX ix_category_slug_history_categoria_id ON taxonomy.category_slug_history(categoria_id);

-- Índice O(1) para resolución de redirecciones 301 en Marketplace
CREATE INDEX ix_category_slug_history_old_slug ON taxonomy.category_slug_history(old_slug);

-- Índices en colas de mensajería
CREATE INDEX ix_outbox_status_created ON taxonomy.outbox(status, created_at) WHERE status = 'PENDING';
CREATE INDEX ix_inbox_message_id ON taxonomy.inbox(message_id);

-- Índices en operaciones de baja
CREATE INDEX ix_mdo_entity ON taxonomy.master_deactivation_operations(entity_type, entity_id);
```

---

## 11. Seguridad y permisos de acceso

De acuerdo con `CONVENCIONES_BD.md` §16:

```sql
REVOKE ALL ON SCHEMA taxonomy FROM PUBLIC;
GRANT USAGE ON SCHEMA taxonomy TO taxonomy_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA taxonomy TO taxonomy_app;
ALTER DEFAULT PRIVILEGES FOR ROLE po_taxonomy_owner IN SCHEMA taxonomy
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO taxonomy_app;
ALTER DEFAULT PRIVILEGES FOR ROLE po_taxonomy_owner IN SCHEMA taxonomy
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA taxonomy TO taxonomy_app;
```

---

## 12. Checklist de aprobación y validación

- [x] Schema propio `taxonomy` con owner `po_taxonomy_owner`.
- [x] CERO Foreign Keys hacia otros microservicios.
- [x] Toda FK interna dispone de índice en su columna referenciante.
- [x] Todas las tablas tienen `created_at timestamptz NOT NULL DEFAULT now()`.
- [x] `updated_at` existe y tiene trigger en todas las tablas mutables (`category_slug_history` y colas exentas por diseño).
- [x] No se usan tipos `float`, `real`, `money`, `serial` ni `timestamp` sin zona horaria.
- [x] Todos los identificadores son UUID nativos generados por `gen_random_uuid()`.
- [x] Enums locales al schema sin dependencias cruzadas.
- [x] Integración Outbox / Inbox transaccional incluida.
- [x] Migración ejecutable reproducible desde cero en `migrations/0001_create_taxonomy.sql`.
- [x] Verificación automatizada con assertions en `validation.sql`.
