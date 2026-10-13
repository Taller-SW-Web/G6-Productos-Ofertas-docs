-- G6 / inventory-svc / migración incremental sobre esquema previamente desplegado.
-- DEC-F-002,003,004,005,009,010. NO ejecutar a ciegas en producción.
-- Preflight: comprobar esquema, permisos, datos y compatibilidad del backend.
-- Debe ejecutarse con owner de inventory y transacción; revisar locks ALTER TYPE.
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '90s';

-- Los identificadores públicos de pedido de Ventas (ej. PED-2026-00001) son opacos.
-- uuid -> text es compatible con los UUID históricos representados como texto,
-- pero debe adaptarse la aplicación y cualquier vista/función dependiente ANTES del despliegue.
ALTER TABLE inventory.reservations
    ALTER COLUMN order_id TYPE text USING order_id::text;
ALTER TABLE inventory.inventory_operations
    ALTER COLUMN order_id TYPE text USING order_id::text;

ALTER TABLE inventory.reservations
    ADD CONSTRAINT ck_reservations_order_id_nonblank
      CHECK (order_id IS NULL OR length(btrim(order_id)) > 0);
ALTER TABLE inventory.inventory_operations
    ADD CONSTRAINT ck_inventory_operations_order_id_nonblank
      CHECK (order_id IS NULL OR length(btrim(order_id)) > 0);

-- Identidad estable para recuperar el estado por operation_id; nulos legados
-- permanecen nulos hasta una migración de datos validada.
ALTER TABLE inventory.inventory_operations
    ADD COLUMN operation_id uuid,
    ADD COLUMN client_id text,
    ADD COLUMN request_fingerprint text,
    ADD COLUMN request_payload jsonb,
    ADD COLUMN result_payload jsonb,
    ADD CONSTRAINT ck_inventory_operation_client_id
      CHECK (client_id IS NULL OR length(btrim(client_id)) > 0),
    ADD CONSTRAINT ck_inventory_operation_request_fingerprint
      CHECK (request_fingerprint IS NULL OR request_fingerprint ~ '^[0-9a-f]{64}$'),
    ADD CONSTRAINT ck_inventory_operation_request_payload
      CHECK (request_payload IS NULL OR jsonb_typeof(request_payload)='object'),
    ADD CONSTRAINT ck_inventory_operation_result_payload
      CHECK (result_payload IS NULL OR jsonb_typeof(result_payload)='object');
CREATE UNIQUE INDEX uq_inventory_operations_operation_id
    ON inventory.inventory_operations(operation_id)
    WHERE operation_id IS NOT NULL;
CREATE INDEX ix_inventory_operations_order_id
    ON inventory.inventory_operations(order_id);

-- La reserva asocia fingerprint y resultado de creación para replay estable.
ALTER TABLE inventory.reservations
    ADD COLUMN request_fingerprint text,
    ADD COLUMN accepted_payload jsonb,
    ADD CONSTRAINT ck_inventory_reservations_fingerprint
      CHECK (request_fingerprint IS NULL OR request_fingerprint ~ '^[0-9a-f]{64}$'),
    ADD CONSTRAINT ck_inventory_reservations_accepted_payload
      CHECK (accepted_payload IS NULL OR jsonb_typeof(accepted_payload)='object');
CREATE INDEX ix_inventory_reservations_order_id
    ON inventory.reservations(order_id);
CREATE UNIQUE INDEX uq_inventory_reservations_operation_id
    ON inventory.reservations(operation_id)
    WHERE operation_id IS NOT NULL;

-- D-INV-01: resolución interna de referencia pública de cumplimiento a UNA
-- ubicación elegible; no autoriza sumar stock entre dos ubicaciones distintas.
-- Sin mapeo exacto y activo, la verificación responde INDETERMINADO.
CREATE TABLE inventory.commercial_fulfillment_routes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id text NOT NULL CHECK (channel_id IN ('MARKETPLACE','CHATBOT','RETAIL')),
    mode text NOT NULL CHECK (mode IN ('ENVIO_DOMICILIO','RETIRO_TIENDA','VENTA_TIENDA')),
    fulfillment_ref text NOT NULL CHECK (length(btrim(fulfillment_ref))>0),
    location_id uuid NOT NULL REFERENCES inventory.locations(id) ON DELETE RESTRICT,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_commercial_fulfillment_routes_active
    ON inventory.commercial_fulfillment_routes(channel_id,mode,fulfillment_ref)
    WHERE active;
CREATE INDEX ix_commercial_fulfillment_routes_location
    ON inventory.commercial_fulfillment_routes(location_id)
    WHERE active;

-- Acceso mínimo para el runtime; no permite que los canales consulten tablas privadas.
DO $grants$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='po_inventory_runtime') THEN
    GRANT SELECT ON inventory.commercial_fulfillment_routes TO po_inventory_runtime;
  ELSE
    RAISE NOTICE 'Provisionar po_inventory_runtime antes del arranque del backend';
  END IF;
END $grants$;

-- La consulta externa no expone location_id; el mapeo queda detrás del API.
-- No concede escritura a canales: permisos del runtime del propietario únicamente.

-- POSTCHECK MANUAL (ejecutar tras analizar resultados):
-- SELECT pg_typeof(order_id) FROM inventory.reservations LIMIT 1;
-- SELECT pg_typeof(order_id) FROM inventory.inventory_operations LIMIT 1;
-- SELECT indexname FROM pg_indexes WHERE schemaname='inventory'
--   AND indexname IN ('uq_inventory_operations_operation_id',
--                     'uq_inventory_reservations_operation_id');
-- Verificar acceso del rol runtime, handlers, triggers, FK y funciones dependientes.
