-- =============================================================================
-- _TEMPLATE — migration.sql
-- Estructura de migraciones de un bounded context
-- =============================================================================
-- Uso:
--   1. Copiar la estructura de este archivo en <svc>/src/infrastructure/
--      persistence/migrations/<NNN>_<verbo>_<objeto>.sql
--   2. Eliminar los bloques de ejemplo que no correspondan al servicio.
--   3. No reutilizar este archivo tal cual: es una estructura, no un script
--      de despliegue completo.
--
-- Reglas vigentes (ver bd/CONVENCIONES_BD.md):
--   - Una migracion NUNCA modifica el schema de otro servicio.
--   - Las migraciones son reproducibles desde cero.
--   - No se edita una migracion ya aplicada.
--   - Cambios destructivos: estrategia expand/contract.
--   - Sin creacion automatica de tablas por ORM.
--
-- Convenciones:
--   - PK:    id uuid PRIMARY KEY DEFAULT gen_random_uuid()
--   - Fechas: timestamptz (nunca timestamp sin zona)
--   - Dinero: numeric(12,2) + char(3); nunca float ni money
--   - Cantidades: integer con CHECK >= 0
--   - Toda constraint/indice/funcion/disparador lleva prefijo
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. EXTENSIONES
--    gen_random_uuid() es nativo desde PostgreSQL 13; no requiere pgcrypto.
--    Solo declarar si el entorno concreto lo exige.
-- -----------------------------------------------------------------------------
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- 2. SCHEMA Y PERMISOS
--    Un rol por schema. Cada servicio se conecta con sus propias credenciales.
-- -----------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS [nombre_schema];

-- El rol de aplicacion se crea una sola vez por infraestructura, no en cada
-- migracion. Se deja aqui como referencia.
-- CREATE ROLE [nombre_schema]_app LOGIN PASSWORD 'gestionado-por-infraestructura';

REVOKE ALL ON SCHEMA [nombre_schema] FROM PUBLIC;

GRANT USAGE ON SCHEMA [nombre_schema] TO [nombre_schema]_app;

-- -----------------------------------------------------------------------------
-- 3. TIPOS ENUMERADOS
--    Solo estados de ciclo de vida PROPIOS del bounded context ya publicados
--    en el contrato. Ver CONVENCIONES_BD.md 13.2.
--    Los tipos son locales a este schema: ningun otro schema los referencia.
-- -----------------------------------------------------------------------------

-- CREATE TYPE [nombre_schema].[nombre_enum] AS ENUM ('VALOR_1', 'VALOR_2');

-- -----------------------------------------------------------------------------
-- 4. FUNCIONES COMPARTIDAS
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION [nombre_schema].fn_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. TABLAS
--    Orden: primero las entidades, despues las dependientes, al final las
--    tablas de infraestructura (outbox / inbox).
--
--    Convenciones obligatorias por tabla:
--      - id uuid PK DEFAULT gen_random_uuid()
--      - created_at timestamptz NOT NULL DEFAULT now()
--      - updated_at timestamptz NOT NULL DEFAULT now()  (exento si append-only)
--      - deleted_at timestamptz NULL DEFAULT NULL       (exento si append-only)
--      - estado <enum> NOT NULL  si la entidad tiene baja logica de negocio
--
--    NOTAS IMPORTANTES:
--      - estado y deleted_at NO resuelven lo mismo (ver CONVENCIONES_BD.md 14).
--      - Las tablas append-only NO llevan updated_at ni deleted_at.
--      - No declarar REFERENCES hacia otro schema.
-- -----------------------------------------------------------------------------

-- CREATE TABLE [nombre_schema].[nombre_tabla] (
--     id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
--     -- ... columnas del dominio ...
--     created_at  timestamptz NOT NULL DEFAULT now(),
--     updated_at  timestamptz NOT NULL DEFAULT now(),
--     deleted_at  timestamptz NULL     DEFAULT NULL,
--
--     CONSTRAINT ck_[nombre_tabla]_[regla] CHECK (...)
-- );

-- -----------------------------------------------------------------------------
-- 6. INDICES
--    Toda FK requiere indice en su columna referenciante.
--    Indices parciales requieren justificacion en physical-model.md.
-- -----------------------------------------------------------------------------

-- CREATE INDEX ix_[nombre_tabla]_[columna]
--     ON [nombre_schema].[nombre_tabla] ([columna]);

-- CREATE INDEX ix_[nombre_tabla]_[columna]_parcial
--     ON [nombre_schema].[nombre_tabla] ([columna])
--     WHERE [condicion];

-- -----------------------------------------------------------------------------
-- 7. CONSTRAINTS
--    Separar las constraints declarativas para que las alterations sobre
--    tablas existentes sean explicitas (expand/contract).
-- -----------------------------------------------------------------------------

-- ALTER TABLE [nombre_schema].[nombre_tabla]
--     ADD CONSTRAINT uq_[nombre_tabla]_[regla] UNIQUE ([columna]);

-- ALTER TABLE [nombre_schema].[nombre_tabla]
--     ADD CONSTRAINT fk_[nombre_tabla]_[columna]
--     FOREIGN KEY ([columna])
--     REFERENCES [nombre_schema].[otra_tabla] ([id])
--     ON DELETE RESTRICT;   -- CASCADE solo si la dependencia es total

-- -----------------------------------------------------------------------------
-- 8. DISPARADORES
--    updated_at se mantiene por disparador, no por la aplicacion.
--    Nunca en tablas append-only.
-- -----------------------------------------------------------------------------

-- CREATE TRIGGER trg_[nombre_tabla]_updated_at
-- BEFORE UPDATE ON [nombre_schema].[nombre_tabla]
-- FOR EACH ROW
-- EXECUTE FUNCTION [nombre_schema].fn_set_updated_at();

-- -----------------------------------------------------------------------------
-- 9. OUTBOX / INBOX
--    Crear solo si aplican. Ver CONVENCIONES_BD.md 10.1.
--    El registro en outbox ocurre SIEMPRE dentro de la transaccion de negocio.
-- -----------------------------------------------------------------------------

-- CREATE TABLE [nombre_schema].outbox (
--     id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
--     message_id     uuid        NOT NULL,
--     event_name     text        NOT NULL,
--     kind           text        NOT NULL,
--     schema_version integer     NOT NULL DEFAULT 1,
--     correlation_id uuid        NOT NULL,
--     causation_id   uuid        NULL,
--     operation_id   uuid        NULL,
--     occurred_at    timestamptz NOT NULL,
--     payload        jsonb       NOT NULL,
--     published_at   timestamptz NULL,
--     attempts       integer     NOT NULL DEFAULT 0,
--     last_error     text        NULL,
--     created_at     timestamptz NOT NULL DEFAULT now(),
--
--     CONSTRAINT uq_outbox_message_id UNIQUE (message_id),
--     CONSTRAINT ck_outbox_kind       CHECK (kind IN ('command','event','result')),
--     CONSTRAINT ck_outbox_attempts   CHECK (attempts >= 0)
-- );
--
-- CREATE INDEX ix_outbox_pending ON [nombre_schema].outbox (published_at, occurred_at);
--
-- CREATE TABLE [nombre_schema].inbox (
--     id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
--     message_id     uuid        NOT NULL,
--     handler        text        NOT NULL,
--     event_name     text        NOT NULL,
--     correlation_id uuid        NULL,
--     payload        jsonb       NOT NULL,
--     result         text        NOT NULL,
--     processed_at   timestamptz NOT NULL DEFAULT now(),
--
--     CONSTRAINT uq_inbox_message_handler UNIQUE (message_id, handler)
-- );

-- -----------------------------------------------------------------------------
-- 10. ROW LEVEL SECURITY
--     Solo read_model. Los schemas de escritura se aíslan por REVOKE y rol.
-- -----------------------------------------------------------------------------

-- ALTER TABLE [nombre_schema].[tabla] ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 11. GRANTS
-- -----------------------------------------------------------------------------

GRANT ALL ON ALL TABLES IN SCHEMA [nombre_schema] TO [nombre_schema]_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA [nombre_schema]
    GRANT ALL ON TABLES TO [nombre_schema]_app;

-- -----------------------------------------------------------------------------
-- 12. COMENTARIOS
--     Documentar en la base lo que no se explica con el nombre.
-- -----------------------------------------------------------------------------

-- COMMENT ON TABLE  [nombre_schema].[nombre_tabla]
--     IS '[descripcion breve]';
-- COMMENT ON COLUMN [nombre_schema].[nombre_tabla].[columna]
--     IS '[descripcion breve, incluir valores permitidos si aplica]';

COMMIT;

-- =============================================================================
-- 13. EXPAND / CONTRACT (ejemplo de secuencia)
--
--   v1  añadir columna nueva nullable
--   v2  escribir campo viejo + nuevo
--   v3  migrar datos historicos
--   v4  leer solo el nuevo
--   v5  retirar el campo viejo
--
--   Nunca editar v1..v4 una vez aplicadas.
-- =============================================================================

-- =============================================================================
-- 14. VERIFICACION POST-MIGRACION
--     Ejecutar validation.sql del servicio y confirmar todos los checks en PASS.
-- =============================================================================