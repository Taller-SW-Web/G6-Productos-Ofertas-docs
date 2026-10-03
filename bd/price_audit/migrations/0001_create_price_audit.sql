-- #56 / price-audit-svc. PostgreSQL >= 15. Modelo: ../physical-model.md.
-- Transaccion/ledger administrados por bd/deploy/migrate.py; sin BEGIN/COMMIT.
-- Runtime price_audit_app; trabajador de retencion price_audit_archiver.
-- Los roles/schemas los provisiona infraestructura, sin credenciales en Git.
DO $guard$
BEGIN
    IF current_user <> 'po_price_audit_owner' OR NOT EXISTS (
        SELECT 1 FROM pg_namespace WHERE nspname = 'price_audit'
        AND pg_get_userbyid(nspowner) = current_user
    ) THEN RAISE EXCEPTION 'Ejecutar con po_price_audit_owner sobre price_audit'; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'price_audit_app') OR
       NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'price_audit_archiver') THEN
        RAISE EXCEPTION 'Infraestructura debe provisionar price_audit_app y price_audit_archiver';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname IN ('price_audit_app','price_audit_archiver')
        AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls)) OR
        pg_has_role('price_audit_app','po_price_audit_owner','MEMBER') OR
        pg_has_role('price_audit_archiver','po_price_audit_owner','MEMBER') OR
        pg_has_role('price_audit_app','price_audit_archiver','MEMBER') THEN
        RAISE EXCEPTION 'Runtime y archiver no deben tener privilegios owner';
    END IF;
END
$guard$;

REVOKE ALL ON SCHEMA price_audit FROM PUBLIC;
GRANT USAGE ON SCHEMA price_audit TO price_audit_app, price_audit_archiver;
ALTER DEFAULT PRIVILEGES IN SCHEMA price_audit REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
CREATE TYPE price_audit.export_job_status AS ENUM ('QUEUED','PROCESSING','COMPLETED','FAILED_GENERAL');

CREATE FUNCTION price_audit.fn_set_updated_at() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog, price_audit AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END;
$$;

CREATE TABLE price_audit.inbox (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    message_id uuid NOT NULL,
    handler text NOT NULL,
    event_name text NOT NULL,
    correlation_id uuid,
    payload jsonb NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    result text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_inbox PRIMARY KEY (id),
    CONSTRAINT uq_inbox_message_handler UNIQUE (message_id, handler)
);

CREATE TABLE price_audit.price_audit_log (
    id_auditoria uuid NOT NULL DEFAULT gen_random_uuid(),
    inbox_id uuid NOT NULL,
    sku text NOT NULL,
    product_id text NOT NULL,
    tipo_precio text NOT NULL,
    precio_anterior numeric(12,2),
    precio_nuevo numeric(12,2),
    -- El contrato no limita porcentajes a 999.99: no imponer numeric(5,2).
    variacion_porcentual numeric,
    tipo_operacion text NOT NULL,
    canal_origen text NOT NULL,
    motivo_cambio text NOT NULL,
    batch_id uuid,
    usuario_id text,
    usuario_email text,
    ip_origen text,
    timestamp timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_price_audit_log PRIMARY KEY (id_auditoria),
    CONSTRAINT fk_price_audit_log_inbox_id FOREIGN KEY (inbox_id)
        REFERENCES price_audit.inbox (id) ON DELETE RESTRICT,
    CONSTRAINT ck_price_audit_log_type CHECK (tipo_precio IN ('REGULAR','OFERTA')),
    CONSTRAINT ck_price_audit_log_operation CHECK (tipo_operacion IN ('CREACION','MODIFICACION','RETIRO_OFERTA')),
    CONSTRAINT ck_price_audit_log_amounts CHECK (
        (precio_anterior IS NULL OR (precio_anterior >= 0 AND precio_anterior <> 'NaN'::numeric)) AND
        (precio_nuevo IS NULL OR (precio_nuevo >= 0 AND precio_nuevo <> 'NaN'::numeric)) AND
        (variacion_porcentual IS NULL OR variacion_porcentual NOT IN ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric))),
    CONSTRAINT ck_price_audit_log_motivo CHECK (length(btrim(motivo_cambio)) > 0),
    CONSTRAINT ck_price_audit_log_null_semantics CHECK (
        (tipo_operacion = 'CREACION' AND precio_anterior IS NULL AND precio_nuevo IS NOT NULL
         AND variacion_porcentual IS NULL) OR
        (tipo_operacion = 'MODIFICACION' AND precio_anterior IS NOT NULL AND precio_nuevo IS NOT NULL
         AND variacion_porcentual IS NOT NULL) OR
        (tipo_operacion = 'RETIRO_OFERTA' AND tipo_precio = 'OFERTA' AND precio_anterior IS NOT NULL
         AND precio_nuevo IS NULL AND variacion_porcentual IS NULL)
    )
);
CREATE INDEX ix_price_audit_log_inbox_id ON price_audit.price_audit_log (inbox_id);
CREATE INDEX ix_price_audit_log_timestamp ON price_audit.price_audit_log (timestamp DESC, id_auditoria DESC);
CREATE INDEX ix_price_audit_log_sku_timestamp ON price_audit.price_audit_log (sku, timestamp DESC, id_auditoria DESC);
CREATE INDEX ix_price_audit_log_user_timestamp ON price_audit.price_audit_log (usuario_id, timestamp DESC);
CREATE INDEX ix_price_audit_log_canal_timestamp ON price_audit.price_audit_log (canal_origen, timestamp DESC);
CREATE INDEX ix_price_audit_log_batch_timestamp ON price_audit.price_audit_log (batch_id, timestamp DESC);

CREATE TABLE price_audit.export_jobs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    status price_audit.export_job_status NOT NULL DEFAULT 'QUEUED',
    formato text NOT NULL,
    filters jsonb NOT NULL,
    record_count integer NOT NULL,
    usuario_id text,
    download_url text,
    completed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_export_jobs PRIMARY KEY (id),
    CONSTRAINT ck_export_jobs_format CHECK (formato IN ('CSV','PDF')),
    CONSTRAINT ck_export_jobs_filters CHECK (jsonb_typeof(filters) = 'object'),
    CONSTRAINT ck_export_jobs_limit CHECK (record_count >= 0 AND
        ((formato = 'CSV' AND record_count <= 100000) OR (formato = 'PDF' AND record_count <= 500)))
);
CREATE INDEX ix_export_jobs_worker ON price_audit.export_jobs (created_at)
    WHERE status IN ('QUEUED','PROCESSING');

-- Metadata tecnica del archivo; sin tabla de estados inventada ni TTL fijo.
CREATE TABLE price_audit.archive_manifests (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    range_start timestamptz NOT NULL,
    range_end timestamptz NOT NULL,
    object_uri text NOT NULL,
    record_count integer NOT NULL,
    checksum text NOT NULL,
    verified_count integer,
    verified_checksum text,
    verified_at timestamptz,
    recoverable boolean NOT NULL DEFAULT false,
    purged_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_archive_manifests PRIMARY KEY (id),
    CONSTRAINT ck_archive_manifests_range CHECK (range_end > range_start),
    CONSTRAINT ck_archive_manifests_count CHECK (record_count > 0 AND (verified_count IS NULL OR verified_count >= 0)),
    CONSTRAINT ck_archive_manifests_verified CHECK (verified_at IS NULL OR
        (verified_count IS NOT NULL AND verified_count = record_count AND
         verified_checksum IS NOT NULL AND verified_checksum = checksum AND recoverable)),
    CONSTRAINT ck_archive_manifests_purged CHECK (purged_at IS NULL OR verified_at IS NOT NULL)
);
CREATE INDEX ix_archive_manifests_range ON price_audit.archive_manifests (range_start, range_end);

-- Checksum de CONTENIDO canonico local, no sello legal ni checksum del archivo
-- comprimido. El worker debe verificar el contenido recuperado con igual protocolo.
CREATE FUNCTION price_audit.fn_archive_checksum(p_start timestamptz, p_end timestamptz)
RETURNS text LANGUAGE sql STABLE SET search_path = pg_catalog, price_audit
SET TimeZone = 'UTC' AS $$
    SELECT encode(sha256(convert_to(COALESCE(string_agg(to_jsonb(a)::text, E'\n'
        ORDER BY a.id_auditoria), ''), 'UTF8')), 'hex')
    FROM price_audit.price_audit_log a WHERE a.timestamp >= p_start AND a.timestamp < p_end;
$$;

CREATE FUNCTION price_audit.fn_guard_audit_immutable() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, price_audit AS $$
DECLARE manifest uuid;
BEGIN
    IF TG_OP = 'DELETE' AND current_user = 'po_price_audit_owner' THEN
        manifest := NULLIF(current_setting('price_audit.archive_manifest', true), '')::uuid;
        IF manifest IS NOT NULL AND EXISTS (
            SELECT 1 FROM price_audit.archive_manifests m WHERE m.id = manifest
            AND m.verified_at IS NOT NULL AND m.verified_count = m.record_count
            AND m.verified_checksum = m.checksum AND m.recoverable AND m.purged_at IS NULL
            AND OLD.timestamp >= m.range_start AND OLD.timestamp < m.range_end
        ) THEN RETURN OLD; END IF;
    END IF;
    RAISE EXCEPTION 'Bitacora append-only: operacion % no autorizada', TG_OP USING ERRCODE = '42501';
END;
$$;
CREATE TRIGGER trg_price_audit_log_immutable BEFORE UPDATE OR DELETE ON price_audit.price_audit_log
FOR EACH ROW EXECUTE FUNCTION price_audit.fn_guard_audit_immutable();
CREATE TRIGGER trg_price_audit_log_no_truncate BEFORE TRUNCATE ON price_audit.price_audit_log
FOR EACH STATEMENT EXECUTE FUNCTION price_audit.fn_guard_audit_immutable();

-- Unica excepcion operativa al DELETE de copia caliente: archivo ya verificado.
-- SECURITY DEFINER con search_path fijo, sin SQL dinamico, sin permisos a PUBLIC/app.
CREATE FUNCTION price_audit.fn_archive_hot_rows(p_manifest uuid) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, price_audit AS $$
DECLARE m price_audit.archive_manifests%ROWTYPE; n integer; removed integer;
BEGIN
    SELECT * INTO m FROM price_audit.archive_manifests WHERE id = p_manifest FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Manifiesto no encontrado' USING ERRCODE = '23514'; END IF;
    IF m.purged_at IS NOT NULL THEN RETURN 0; END IF;
    IF m.verified_at IS NULL OR m.verified_count IS DISTINCT FROM m.record_count
        OR m.verified_checksum IS DISTINCT FROM m.checksum OR NOT m.recoverable THEN
        RAISE EXCEPTION 'Archivo sin verificacion completa; se conservan originales' USING ERRCODE = '23514';
    END IF;
    LOCK TABLE price_audit.price_audit_log IN SHARE ROW EXCLUSIVE MODE;
    SELECT count(*) INTO n FROM price_audit.price_audit_log
        WHERE timestamp >= m.range_start AND timestamp < m.range_end;
    IF n <> m.record_count OR price_audit.fn_archive_checksum(m.range_start,m.range_end) <> m.checksum THEN
        RAISE EXCEPTION 'Contenido caliente no coincide con manifiesto; se conservan originales' USING ERRCODE = '23514';
    END IF;
    PERFORM set_config('price_audit.archive_manifest',p_manifest::text,true);
    DELETE FROM price_audit.price_audit_log WHERE timestamp >= m.range_start AND timestamp < m.range_end;
    GET DIAGNOSTICS removed = ROW_COUNT;
    PERFORM set_config('price_audit.archive_manifest','',true);
    UPDATE price_audit.archive_manifests SET purged_at = now() WHERE id = p_manifest;
    RETURN removed;
END;
$$;

CREATE TRIGGER trg_export_jobs_updated_at BEFORE UPDATE ON price_audit.export_jobs
FOR EACH ROW EXECUTE FUNCTION price_audit.fn_set_updated_at();
CREATE TRIGGER trg_archive_manifests_updated_at BEFORE UPDATE ON price_audit.archive_manifests
FOR EACH ROW EXECUTE FUNCTION price_audit.fn_set_updated_at();

REVOKE ALL ON ALL TABLES IN SCHEMA price_audit FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA price_audit FROM PUBLIC;
GRANT SELECT, INSERT ON price_audit.price_audit_log, price_audit.inbox TO price_audit_app;
GRANT SELECT, INSERT, UPDATE ON price_audit.export_jobs TO price_audit_app;
GRANT SELECT ON price_audit.price_audit_log TO price_audit_archiver;
GRANT SELECT, INSERT ON price_audit.archive_manifests TO price_audit_archiver;
GRANT UPDATE (verified_count, verified_checksum, verified_at, recoverable)
    ON price_audit.archive_manifests TO price_audit_archiver;
GRANT EXECUTE ON FUNCTION price_audit.fn_archive_checksum(timestamptz,timestamptz),
    price_audit.fn_archive_hot_rows(uuid) TO price_audit_archiver;
COMMENT ON TABLE price_audit.price_audit_log IS 'Append-only; PK id_auditoria UUID. Sin moneda inferida del precio actual ni FK hacia Pricing/Catalogo/Seguridad.';
COMMENT ON TABLE price_audit.inbox IS 'Deduplicacion por message_id + handler; insertar inbox y asientos en la misma transaccion local.';
COMMENT ON TABLE price_audit.archive_manifests IS 'Retencion configurable y prueba de recuperabilidad del worker; purge requiere count + checksum local + verificacion externa.';
