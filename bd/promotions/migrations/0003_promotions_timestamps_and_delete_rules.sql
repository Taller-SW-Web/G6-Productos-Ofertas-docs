-- Correcciones de revisión #53. El runner aplica DDL + ledger atómicamente.
-- Conservar 0001/0002 y sus checksums; no cambiar identidad contractual ni tablas.
ALTER TABLE promotions.combination_policy ADD COLUMN created_at timestamptz;
ALTER TABLE promotions.coupon_uses ADD COLUMN created_at timestamptz;
ALTER TABLE promotions.catalog_projection ADD COLUMN created_at timestamptz;
ALTER TABLE promotions.price_projection ADD COLUMN created_at timestamptz;
ALTER TABLE promotions.stock_projection ADD COLUMN created_at timestamptz;
ALTER TABLE promotions.inbox ADD COLUMN created_at timestamptz;
ALTER TABLE promotions.promotion_scopes ADD COLUMN updated_at timestamptz;
ALTER TABLE promotions.coupon_uses ADD COLUMN updated_at timestamptz;

-- Backfill técnico: no reconstruye una fecha de creación histórica desconocida.
-- UPDATE dispara las protecciones de historia/procedencia: suspender SOLO los
-- triggers de estas tablas durante el backfill, dentro de esta transacción.
DO $backfill$
DECLARE item record;
BEGIN
  FOR item IN SELECT c.relname,t.tgname FROM pg_trigger t
    JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='promotions' AND NOT t.tgisinternal AND c.relname IN
      ('combination_policy','coupon_uses','catalog_projection','price_projection','stock_projection','inbox','promotion_scopes')
  LOOP
    EXECUTE format('ALTER TABLE promotions.%I DISABLE TRIGGER %I',item.relname,item.tgname);
  END LOOP;
END $backfill$;
UPDATE promotions.combination_policy SET created_at=updated_at;
UPDATE promotions.coupon_uses SET created_at=consumed_at,updated_at=coalesce(restored_at,consumed_at);
UPDATE promotions.catalog_projection SET created_at=updated_at;
UPDATE promotions.price_projection SET created_at=updated_at;
UPDATE promotions.stock_projection SET created_at=updated_at;
UPDATE promotions.inbox SET created_at=received_at;
UPDATE promotions.promotion_scopes SET updated_at=created_at;
DO $timestamps$
DECLARE item record;
BEGIN
  FOR item IN SELECT * FROM (VALUES
    ('combination_policy','created_at'),('coupon_uses','created_at'),
    ('catalog_projection','created_at'),('price_projection','created_at'),
    ('stock_projection','created_at'),('inbox','created_at'),
    ('promotion_scopes','updated_at'),('coupon_uses','updated_at')) AS columns_to_fix(table_name,column_name)
  LOOP
    EXECUTE format('ALTER TABLE promotions.%I ALTER COLUMN %I SET NOT NULL, ALTER COLUMN %I SET DEFAULT now()',
                   item.table_name,item.column_name,item.column_name);
  END LOOP;
  FOR item IN SELECT c.relname,t.tgname FROM pg_trigger t
    JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='promotions' AND NOT t.tgisinternal AND c.relname IN
      ('combination_policy','coupon_uses','catalog_projection','price_projection','stock_projection','inbox','promotion_scopes')
  LOOP
    EXECUTE format('ALTER TABLE promotions.%I ENABLE TRIGGER %I',item.relname,item.tgname);
  END LOOP;
END $timestamps$;

ALTER TABLE promotions.promotion_scopes DROP CONSTRAINT fk_promotion_scopes_promotion,
  ADD CONSTRAINT fk_promotion_scopes_promotion FOREIGN KEY(promotion_id) REFERENCES promotions.promotions(id) ON DELETE RESTRICT;
ALTER TABLE promotions.combination_policy DROP CONSTRAINT fk_combination_policy_promotion,
  ADD CONSTRAINT fk_combination_policy_promotion FOREIGN KEY(promotion_id) REFERENCES promotions.promotions(id) ON DELETE RESTRICT;
ALTER TABLE promotions.coupons DROP CONSTRAINT fk_coupons_promotion,
  ADD CONSTRAINT fk_coupons_promotion FOREIGN KEY(promotion_id) REFERENCES promotions.promotions(id) ON DELETE RESTRICT;
ALTER TABLE promotions.coupon_uses DROP CONSTRAINT fk_coupon_uses_coupon,
  ADD CONSTRAINT fk_coupon_uses_coupon FOREIGN KEY(coupon_id) REFERENCES promotions.coupons(id) ON DELETE RESTRICT;
ALTER TABLE promotions.coupon_uses DROP CONSTRAINT fk_coupon_uses_promotion,
  ADD CONSTRAINT fk_coupon_uses_promotion FOREIGN KEY(promotion_id) REFERENCES promotions.promotions(id) ON DELETE RESTRICT;
ALTER TABLE promotions.recommendation_items DROP CONSTRAINT fk_recommendation_items_rule,
  ADD CONSTRAINT fk_recommendation_items_rule FOREIGN KEY(rule_id) REFERENCES promotions.recommendation_rules(id) ON DELETE RESTRICT;

-- La única mutación funcional del uso sigue siendo restored_at. El timestamp
-- técnico no debe bloquear la restitución; created_at/identidad siguen inmutables.
CREATE OR REPLACE FUNCTION promotions.fn_guard_coupon_use() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE c promotions.coupons%ROWTYPE; p promotions.promotions%ROWTYPE;
BEGIN
  IF TG_OP='DELETE' THEN RAISE EXCEPTION 'COUPON_HISTORY_IMMUTABLE'; END IF;
  IF TG_OP='UPDATE' THEN
    IF (to_jsonb(NEW)-ARRAY['restored_at','updated_at']) IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['restored_at','updated_at'])
       OR (OLD.restored_at IS NOT NULL AND NEW.restored_at IS DISTINCT FROM OLD.restored_at) THEN
      RAISE EXCEPTION 'COUPON_HISTORY_IMMUTABLE';
    END IF;
    PERFORM 1 FROM promotions.coupons WHERE id=OLD.coupon_id FOR UPDATE;
    RETURN NEW;
  END IF;
  SELECT * INTO c FROM promotions.coupons WHERE id=NEW.coupon_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'COUPON_NOT_FOUND'; END IF;
  SELECT * INTO p FROM promotions.promotions WHERE id=c.promotion_id FOR UPDATE;
  IF c.state<>'ACTIVO' OR p.state<>'ACTIVO' OR p.modality<>'CUPON'
     OR NOT (NEW.consumed_at>=p.valid_from AND NEW.consumed_at<p.valid_until)
     OR NOT (NEW.channel_id=ANY(p.enabled_channels)) THEN RAISE EXCEPTION 'COUPON_NOT_ELIGIBLE'; END IF;
  IF NEW.restored_at IS NOT NULL THEN RAISE EXCEPTION 'COUPON_NEW_USE_ALREADY_RESTORED'; END IF;
  IF c.max_customer_uses IS NOT NULL AND NEW.customer_ref IS NULL THEN RAISE EXCEPTION 'CUSTOMER_REF_REQUERIDO'; END IF;
  IF c.max_global_uses IS NOT NULL AND (SELECT count(*) FROM promotions.coupon_uses WHERE coupon_id=c.id AND restored_at IS NULL)>=c.max_global_uses THEN RAISE EXCEPTION 'COUPON_GLOBAL_LIMIT'; END IF;
  IF c.max_customer_uses IS NOT NULL AND (SELECT count(*) FROM promotions.coupon_uses WHERE coupon_id=c.id AND customer_ref=NEW.customer_ref AND restored_at IS NULL)>=c.max_customer_uses THEN RAISE EXCEPTION 'COUPON_CUSTOMER_LIMIT'; END IF;
  NEW.promotion_id:=c.promotion_id;
  NEW.cancellation_policy:=c.cancellation_policy;
  RETURN NEW;
END $$;

-- Aplicar también la convención de nombres a los triggers existentes.
DO $trigger_names$
DECLARE item record; target_name text;
BEGIN
  FOR item IN SELECT c.relname,t.tgname FROM pg_trigger t
    JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='promotions' AND NOT t.tgisinternal AND t.tgname ~ '^(tr_|ct_)'
  LOOP
    target_name:=CASE WHEN item.tgname LIKE '%_touch' THEN 'trg_'||item.relname||'_updated_at'
                     ELSE regexp_replace(item.tgname,'^(tr_|ct_)','trg_') END;
    EXECUTE format('ALTER TRIGGER %I ON promotions.%I RENAME TO %I',item.tgname,item.relname,target_name);
  END LOOP;
END $trigger_names$;
CREATE TRIGGER trg_promotion_scopes_updated_at BEFORE UPDATE ON promotions.promotion_scopes
  FOR EACH ROW EXECUTE FUNCTION promotions.fn_touch_updated_at();
CREATE TRIGGER trg_coupon_uses_updated_at BEFORE UPDATE ON promotions.coupon_uses
  FOR EACH ROW EXECUTE FUNCTION promotions.fn_touch_updated_at();
