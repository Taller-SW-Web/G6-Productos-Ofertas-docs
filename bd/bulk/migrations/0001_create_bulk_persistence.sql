-- =============================================================================
-- bulk-svc — 0001_create_bulk_persistence.sql
-- Issue #57 — Hito 2
-- PostgreSQL / Supabase
--
-- Prerrequisito:
--   bd/deploy/bootstrap.sql ya creó schema bulk con owner po_bulk_owner.
--
-- IMPORTANTE:
--   NO incluir BEGIN/COMMIT. bd/deploy/migrate.py envuelve esta versión en una
--   transacción y registra su checksum en bulk.schema_migrations.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. Seguridad del schema
-- ----------------------------------------------------------------------------
REVOKE ALL ON SCHEMA bulk FROM PUBLIC;

-- ----------------------------------------------------------------------------
-- 2. Tipos enumerados de ciclo de vida
-- ----------------------------------------------------------------------------
CREATE TYPE bulk.job_status AS ENUM (
    'QUEUED',
    'PROCESSING',
    'COMPLETED',
    'FAILED_GENERAL'
);

CREATE TYPE bulk.row_status AS ENUM (
    'PENDING',
    'PROCESSING',
    'COMPLETED',
    'FAILED'
);

CREATE TYPE bulk.step_status AS ENUM (
    'PENDING',
    'PROCESSING',
    'COMPLETED',
    'FAILED'
);

-- ----------------------------------------------------------------------------
-- 3. Función compartida de updated_at
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION bulk.fn_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. Tablas del workflow
-- ----------------------------------------------------------------------------
CREATE TABLE bulk.file_manifests (
    id          uuid        NOT NULL DEFAULT gen_random_uuid(),
    role        text        NOT NULL,
    format      text        NOT NULL,
    content_ref text        NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_file_manifests PRIMARY KEY (id),
    CONSTRAINT ck_file_manifests_role
        CHECK (role IN ('ENTRADA_IMPORTACION','REPORTE_IMPORTACION','RESULTADO_EXPORTACION')),
    CONSTRAINT ck_file_manifests_format
        CHECK (format IN ('CSV','XLSX')),
    CONSTRAINT ck_file_manifests_report_csv
        CHECK (role <> 'REPORTE_IMPORTACION' OR format = 'CSV')
);

CREATE TABLE bulk.batch_jobs (
    id                   uuid            NOT NULL DEFAULT gen_random_uuid(),
    batch_id             uuid            NOT NULL,
    input_file_id        uuid            NOT NULL,
    report_file_id       uuid            NULL,
    status               bulk.job_status NOT NULL DEFAULT 'QUEUED',
    template_version     integer         NOT NULL,
    correlation_id       uuid            NOT NULL,
    total_rows           integer         NOT NULL DEFAULT 0,
    completed_rows       integer         NOT NULL DEFAULT 0,
    failed_rows          integer         NOT NULL DEFAULT 0,
    needs_reconciliation boolean         NOT NULL DEFAULT false,
    created_at           timestamptz     NOT NULL DEFAULT now(),
    updated_at           timestamptz     NOT NULL DEFAULT now(),

    CONSTRAINT pk_batch_jobs PRIMARY KEY (id),
    CONSTRAINT uq_batch_jobs_batch_id UNIQUE (batch_id),
    CONSTRAINT uq_batch_jobs_report_file_id UNIQUE (report_file_id),
    CONSTRAINT fk_batch_jobs_input_file_id
        FOREIGN KEY (input_file_id) REFERENCES bulk.file_manifests(id) ON DELETE RESTRICT,
    CONSTRAINT fk_batch_jobs_report_file_id
        FOREIGN KEY (report_file_id) REFERENCES bulk.file_manifests(id) ON DELETE RESTRICT,
    CONSTRAINT ck_batch_jobs_template_version CHECK (template_version > 0),
    CONSTRAINT ck_batch_jobs_total_rows CHECK (total_rows >= 0),
    CONSTRAINT ck_batch_jobs_completed_rows CHECK (completed_rows >= 0),
    CONSTRAINT ck_batch_jobs_failed_rows CHECK (failed_rows >= 0),
    CONSTRAINT ck_batch_jobs_completed_lte_total CHECK (completed_rows <= total_rows),
    CONSTRAINT ck_batch_jobs_failed_lte_total CHECK (failed_rows <= total_rows),
    CONSTRAINT ck_batch_jobs_terminal_lte_total
        CHECK (completed_rows + failed_rows <= total_rows),
    CONSTRAINT ck_batch_jobs_completed_terminal
        CHECK (status <> 'COMPLETED' OR completed_rows + failed_rows = total_rows),
    CONSTRAINT ck_batch_jobs_completed_reconciliation
        CHECK (status <> 'COMPLETED' OR needs_reconciliation = (failed_rows > 0))
);

CREATE TABLE bulk.batch_rows (
    id                   uuid            NOT NULL DEFAULT gen_random_uuid(),
    batch_job_id         uuid            NOT NULL,
    row_id               uuid            NOT NULL,
    status               bulk.row_status NOT NULL DEFAULT 'PENDING',
    required_domains     text[]          NOT NULL,
    applied_domains      text[]          NOT NULL DEFAULT ARRAY[]::text[],
    failed_domain        text            NULL,
    needs_reconciliation boolean         NOT NULL DEFAULT false,
    error_code           text            NULL,
    error_detail         text            NULL,
    created_at           timestamptz     NOT NULL DEFAULT now(),
    updated_at           timestamptz     NOT NULL DEFAULT now(),

    CONSTRAINT pk_batch_rows PRIMARY KEY (id),
    CONSTRAINT uq_batch_rows_batch_row UNIQUE (batch_job_id, row_id),
    CONSTRAINT fk_batch_rows_batch_job_id
        FOREIGN KEY (batch_job_id) REFERENCES bulk.batch_jobs(id) ON DELETE CASCADE,
    CONSTRAINT ck_batch_rows_required_cardinality
        CHECK (cardinality(required_domains) BETWEEN 1 AND 3),
    CONSTRAINT ck_batch_rows_required_values
        CHECK (required_domains <@ ARRAY['CATALOGO','PRICING','INVENTARIO']::text[]),
    CONSTRAINT ck_batch_rows_applied_values
        CHECK (applied_domains <@ ARRAY['CATALOGO','PRICING','INVENTARIO']::text[]),
    CONSTRAINT ck_batch_rows_required_no_null
        CHECK (array_position(required_domains, NULL) IS NULL),
    CONSTRAINT ck_batch_rows_applied_no_null
        CHECK (array_position(applied_domains, NULL) IS NULL),
    CONSTRAINT ck_batch_rows_required_unique
        CHECK (
            cardinality(required_domains) =
              CASE WHEN 'CATALOGO' = ANY(required_domains) THEN 1 ELSE 0 END +
              CASE WHEN 'PRICING' = ANY(required_domains) THEN 1 ELSE 0 END +
              CASE WHEN 'INVENTARIO' = ANY(required_domains) THEN 1 ELSE 0 END
        ),
    CONSTRAINT ck_batch_rows_applied_unique
        CHECK (
            cardinality(applied_domains) =
              CASE WHEN 'CATALOGO' = ANY(applied_domains) THEN 1 ELSE 0 END +
              CASE WHEN 'PRICING' = ANY(applied_domains) THEN 1 ELSE 0 END +
              CASE WHEN 'INVENTARIO' = ANY(applied_domains) THEN 1 ELSE 0 END
        ),
    CONSTRAINT ck_batch_rows_applied_subset
        CHECK (applied_domains <@ required_domains),
    CONSTRAINT ck_batch_rows_failed_domain_value
        CHECK (failed_domain IS NULL OR failed_domain IN ('CATALOGO','PRICING','INVENTARIO')),
    CONSTRAINT ck_batch_rows_failed_domain_required
        CHECK (failed_domain IS NULL OR failed_domain = ANY(required_domains)),
    CONSTRAINT ck_batch_rows_failed_domain_not_applied
        CHECK (failed_domain IS NULL OR NOT (failed_domain = ANY(applied_domains))),
    CONSTRAINT ck_batch_rows_completed_consistency
        CHECK (
            status <> 'COMPLETED'
            OR (
                failed_domain IS NULL
                AND needs_reconciliation = false
                AND required_domains <@ applied_domains
                AND applied_domains <@ required_domains
            )
        ),
    CONSTRAINT ck_batch_rows_failed_has_domain
        CHECK (status <> 'FAILED' OR failed_domain IS NOT NULL),
    CONSTRAINT ck_batch_rows_failed_domain_requires_failed
        CHECK (failed_domain IS NULL OR status = 'FAILED'),
    CONSTRAINT ck_batch_rows_reconciliation
        CHECK (
            needs_reconciliation = false
            OR (status = 'FAILED' AND cardinality(applied_domains) > 0)
        )
);

CREATE TABLE bulk.row_domain_steps (
    id           uuid             NOT NULL DEFAULT gen_random_uuid(),
    batch_row_id uuid             NOT NULL,
    domain       text             NOT NULL,
    status       bulk.step_status NOT NULL DEFAULT 'PENDING',
    error_code   text             NULL,
    error_detail text             NULL,
    created_at   timestamptz      NOT NULL DEFAULT now(),
    updated_at   timestamptz      NOT NULL DEFAULT now(),

    CONSTRAINT pk_row_domain_steps PRIMARY KEY (id),
    CONSTRAINT uq_row_domain_steps_row_domain UNIQUE (batch_row_id, domain),
    CONSTRAINT fk_row_domain_steps_batch_row_id
        FOREIGN KEY (batch_row_id) REFERENCES bulk.batch_rows(id) ON DELETE CASCADE,
    CONSTRAINT ck_row_domain_steps_domain
        CHECK (domain IN ('CATALOGO','PRICING','INVENTARIO'))
);

CREATE TABLE bulk.export_jobs (
    id             uuid            NOT NULL DEFAULT gen_random_uuid(),
    export_id      uuid            NOT NULL,
    status         bulk.job_status NOT NULL DEFAULT 'QUEUED',
    format         text            NOT NULL,
    output_file_id uuid            NULL,
    created_at     timestamptz     NOT NULL DEFAULT now(),
    completed_at   timestamptz     NULL,
    updated_at     timestamptz     NOT NULL DEFAULT now(),

    CONSTRAINT pk_export_jobs PRIMARY KEY (id),
    CONSTRAINT uq_export_jobs_export_id UNIQUE (export_id),
    CONSTRAINT uq_export_jobs_output_file_id UNIQUE (output_file_id),
    CONSTRAINT fk_export_jobs_output_file_id
        FOREIGN KEY (output_file_id) REFERENCES bulk.file_manifests(id) ON DELETE RESTRICT,
    CONSTRAINT ck_export_jobs_format CHECK (format IN ('CSV','XLSX')),
    CONSTRAINT ck_export_jobs_completed_file
        CHECK (status <> 'COMPLETED' OR (output_file_id IS NOT NULL AND completed_at IS NOT NULL))
);

-- ----------------------------------------------------------------------------
-- 5. Outbox / Inbox según CONVENCIONES_BD.md §10
-- ----------------------------------------------------------------------------
CREATE TABLE bulk.outbox (
    id             uuid        NOT NULL DEFAULT gen_random_uuid(),
    message_id     text        NOT NULL,
    event_name     text        NOT NULL,
    kind           text        NOT NULL,
    schema_version integer     NOT NULL DEFAULT 1,
    correlation_id text        NOT NULL,
    causation_id   text        NULL,
    operation_id   uuid        NULL,
    occurred_at    timestamptz NOT NULL,
    payload        jsonb       NOT NULL,
    published_at   timestamptz NULL,
    attempts       integer     NOT NULL DEFAULT 0,
    last_error     text        NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_outbox PRIMARY KEY (id),
    CONSTRAINT uq_outbox_message_id UNIQUE (message_id),
    CONSTRAINT uq_outbox_operation_event UNIQUE (operation_id, event_name),
    CONSTRAINT ck_outbox_kind CHECK (kind IN ('command','event','result')),
    CONSTRAINT ck_outbox_schema_version CHECK (schema_version > 0),
    CONSTRAINT ck_outbox_attempts CHECK (attempts >= 0)
);

CREATE TABLE bulk.inbox (
    id             uuid        NOT NULL DEFAULT gen_random_uuid(),
    message_id     text        NOT NULL,
    handler        text        NOT NULL,
    event_name     text        NOT NULL,
    correlation_id text        NULL,
    payload        jsonb       NOT NULL,
    result         text        NOT NULL,
    processed_at   timestamptz NOT NULL DEFAULT now(),
    created_at     timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_inbox PRIMARY KEY (id),
    CONSTRAINT uq_inbox_message_handler UNIQUE (message_id, handler)
);

-- ----------------------------------------------------------------------------
-- 6. Índices
-- Toda FK debe estar cubierta por un índice cuyo primer campo sea la FK.
-- ----------------------------------------------------------------------------
CREATE INDEX ix_batch_jobs_input_file_id
    ON bulk.batch_jobs (input_file_id);

CREATE INDEX ix_batch_jobs_status_created_at
    ON bulk.batch_jobs (status, created_at);

CREATE INDEX ix_batch_jobs_reconciliation
    ON bulk.batch_jobs (updated_at)
    WHERE needs_reconciliation = true;

CREATE INDEX ix_batch_rows_batch_status
    ON bulk.batch_rows (batch_job_id, status);

CREATE INDEX ix_batch_rows_reconciliation
    ON bulk.batch_rows (batch_job_id)
    WHERE needs_reconciliation = true;

CREATE INDEX ix_batch_rows_failed_domain
    ON bulk.batch_rows (batch_job_id, failed_domain)
    WHERE failed_domain IS NOT NULL;

CREATE INDEX ix_row_domain_steps_status_updated_at
    ON bulk.row_domain_steps (status, updated_at);

CREATE INDEX ix_export_jobs_status_created_at
    ON bulk.export_jobs (status, created_at);

CREATE INDEX ix_outbox_pending
    ON bulk.outbox (published_at, occurred_at);

-- ----------------------------------------------------------------------------
-- 7. Validación de roles de archivo
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION bulk.fn_validate_batch_job_files()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_role   text;
    v_format text;
BEGIN
    SELECT role, format
      INTO v_role, v_format
      FROM bulk.file_manifests
     WHERE id = NEW.input_file_id;

    IF v_role IS DISTINCT FROM 'ENTRADA_IMPORTACION' THEN
        RAISE EXCEPTION USING
            ERRCODE = '23514',
            MESSAGE = 'input_file_id debe referenciar un archivo ENTRADA_IMPORTACION';
    END IF;

    IF NEW.report_file_id IS NOT NULL THEN
        SELECT role, format
          INTO v_role, v_format
          FROM bulk.file_manifests
         WHERE id = NEW.report_file_id;

        IF v_role IS DISTINCT FROM 'REPORTE_IMPORTACION' OR v_format IS DISTINCT FROM 'CSV' THEN
            RAISE EXCEPTION USING
                ERRCODE = '23514',
                MESSAGE = 'report_file_id debe referenciar un REPORTE_IMPORTACION CSV';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION bulk.fn_validate_export_job_file()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_role   text;
    v_format text;
BEGIN
    IF NEW.output_file_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT role, format
      INTO v_role, v_format
      FROM bulk.file_manifests
     WHERE id = NEW.output_file_id;

    IF v_role IS DISTINCT FROM 'RESULTADO_EXPORTACION' OR v_format IS DISTINCT FROM NEW.format THEN
        RAISE EXCEPTION USING
            ERRCODE = '23514',
            MESSAGE = 'output_file_id debe ser RESULTADO_EXPORTACION y coincidir en formato';
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION bulk.fn_protect_file_manifest_usage()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.role IS NOT DISTINCT FROM OLD.role
       AND NEW.format IS NOT DISTINCT FROM OLD.format THEN
        RETURN NEW;
    END IF;

    IF EXISTS (
        SELECT 1 FROM bulk.batch_jobs WHERE input_file_id = OLD.id
    ) AND NEW.role IS DISTINCT FROM 'ENTRADA_IMPORTACION' THEN
        RAISE EXCEPTION USING ERRCODE = '23514',
            MESSAGE = 'archivo usado como entrada debe conservar ENTRADA_IMPORTACION';
    END IF;

    IF EXISTS (
        SELECT 1 FROM bulk.batch_jobs WHERE report_file_id = OLD.id
    ) AND (NEW.role IS DISTINCT FROM 'REPORTE_IMPORTACION' OR NEW.format IS DISTINCT FROM 'CSV') THEN
        RAISE EXCEPTION USING ERRCODE = '23514',
            MESSAGE = 'archivo usado como reporte debe conservar REPORTE_IMPORTACION/CSV';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM bulk.export_jobs ej
         WHERE ej.output_file_id = OLD.id
           AND (NEW.role IS DISTINCT FROM 'RESULTADO_EXPORTACION' OR NEW.format IS DISTINCT FROM ej.format)
    ) THEN
        RAISE EXCEPTION USING ERRCODE = '23514',
            MESSAGE = 'archivo usado como exportación debe conservar rol y formato';
    END IF;

    RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 8. Triggers
-- ----------------------------------------------------------------------------
CREATE TRIGGER trg_file_manifests_updated_at
BEFORE UPDATE ON bulk.file_manifests
FOR EACH ROW EXECUTE FUNCTION bulk.fn_set_updated_at();

CREATE TRIGGER trg_batch_jobs_updated_at
BEFORE UPDATE ON bulk.batch_jobs
FOR EACH ROW EXECUTE FUNCTION bulk.fn_set_updated_at();

CREATE TRIGGER trg_batch_rows_updated_at
BEFORE UPDATE ON bulk.batch_rows
FOR EACH ROW EXECUTE FUNCTION bulk.fn_set_updated_at();

CREATE TRIGGER trg_row_domain_steps_updated_at
BEFORE UPDATE ON bulk.row_domain_steps
FOR EACH ROW EXECUTE FUNCTION bulk.fn_set_updated_at();

CREATE TRIGGER trg_export_jobs_updated_at
BEFORE UPDATE ON bulk.export_jobs
FOR EACH ROW EXECUTE FUNCTION bulk.fn_set_updated_at();

CREATE TRIGGER trg_batch_jobs_file_roles
BEFORE INSERT OR UPDATE OF input_file_id, report_file_id
ON bulk.batch_jobs
FOR EACH ROW EXECUTE FUNCTION bulk.fn_validate_batch_job_files();

CREATE TRIGGER trg_export_jobs_file_role
BEFORE INSERT OR UPDATE OF output_file_id, format
ON bulk.export_jobs
FOR EACH ROW EXECUTE FUNCTION bulk.fn_validate_export_job_file();

CREATE TRIGGER trg_file_manifests_protect_usage
BEFORE UPDATE OF role, format
ON bulk.file_manifests
FOR EACH ROW EXECUTE FUNCTION bulk.fn_protect_file_manifest_usage();

-- ----------------------------------------------------------------------------
-- 9. Comentarios
-- ----------------------------------------------------------------------------
COMMENT ON TABLE bulk.file_manifests IS 'Archivos de entrada, reporte y exportación del process manager Bulk.';
COMMENT ON TABLE bulk.batch_jobs IS 'Estado durable agregado de importaciones masivas.';
COMMENT ON TABLE bulk.batch_rows IS 'Estado durable por fila y por dominios aplicados/fallidos.';
COMMENT ON TABLE bulk.row_domain_steps IS 'Estado funcional consolidado por dominio para cada fila.';
COMMENT ON TABLE bulk.export_jobs IS 'Trabajos asíncronos de exportación completa CSV/XLSX.';
COMMENT ON TABLE bulk.outbox IS 'Transactional Outbox; published_at NULL significa pendiente.';
COMMENT ON TABLE bulk.inbox IS 'Deduplicación por message_id + handler después del procesamiento.';
