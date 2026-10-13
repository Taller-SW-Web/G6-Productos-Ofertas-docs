-- G6 / promotions-svc / migración incremental DEC-F-008/009.
-- No altera ni borra usos de cupones existentes; mantiene uq_coupon_uses_order_coupon.
-- Los handlers del servicio deben usar el ledger en una transacción con el consumo/restauración.
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '90s';

CREATE TABLE promotions.coupon_command_receipts (
    operation_id uuid PRIMARY KEY,
    order_id text NOT NULL CHECK (length(btrim(order_id))>0),
    source_client_id text NOT NULL CHECK (length(btrim(source_client_id))>0),
    intention text NOT NULL CHECK (intention IN ('CONSUMIR','RESTAURAR')),
    coupon_code text,
    reservation_id uuid,
    commercial_snapshot_ref text,
    request_fingerprint text NOT NULL
      CHECK (request_fingerprint ~ '^[0-9a-f]{64}$'),
    request_payload jsonb NOT NULL CHECK (jsonb_typeof(request_payload)='object'),
    status text NOT NULL DEFAULT 'RECIBIDO'
      CHECK (status IN ('RECIBIDO','COMPLETED','REJECTED')),
    result_payload jsonb,
    received_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz,
    CONSTRAINT ck_coupon_command_complete CHECK (
       (status = 'RECIBIDO' AND completed_at IS NULL AND result_payload IS NULL)
       OR (status IN ('COMPLETED','REJECTED')
          AND completed_at IS NOT NULL AND result_payload IS NOT NULL
          AND jsonb_typeof(result_payload)='object')),
    CONSTRAINT ck_coupon_command_consumption_context CHECK (
       intention <> 'CONSUMIR' OR
       (coupon_code IS NOT NULL AND length(btrim(coupon_code))>0
        AND reservation_id IS NOT NULL
        AND commercial_snapshot_ref IS NOT NULL
        AND length(btrim(commercial_snapshot_ref))>0))
);
CREATE INDEX ix_coupon_command_receipts_order ON promotions.coupon_command_receipts(order_id);
CREATE INDEX ix_coupon_command_receipts_received ON promotions.coupon_command_receipts(received_at);

-- Permisos explícitos mínimos: sin DELETE ni UPDATE arbitrario del fingerprint.
REVOKE ALL ON promotions.coupon_command_receipts FROM PUBLIC;
GRANT SELECT, INSERT ON promotions.coupon_command_receipts TO po_promotions_runtime;
GRANT UPDATE(status,result_payload,completed_at)
  ON promotions.coupon_command_receipts TO po_promotions_runtime;

-- Actores: solo el servicio Promotions debe gestionar este ledger.
-- El provisioning/owner existente controla los grants al rol técnico.

-- REGLAS BACKEND OBLIGATORIAS (la tabla no ejecuta lógica por sí misma):
-- 1. Tomar bloqueo transaccional por operation_id antes de aplicar consumo/restauración.
-- 2. Si ya existe y fingerprint/actor/intención coinciden, devolver result_payload original;
--    si difieren, emitir IDEMPOTENCY_CONFLICT sin efectos.
-- 3. Persistir consumo/restauración y resultado definitivo en la MISMA transacción.
-- 4. Cupones no confía solo en commercial_snapshot_ref: revalida elegibilidad/cupo.
-- 5. No consumir sin reserva confirmada; verificar precondición con Ventas/Inventario.
-- 6. Nunca permitir que la restauración incremente usos sin consumo previo.
-- 7. Publicar resultado con outbox y correlación operation_id; handler deduplica message_id.
