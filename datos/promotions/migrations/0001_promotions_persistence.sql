-- #53. El ejecutor común envuelve este archivo y su ledger en una transacción.
-- Referencias externas opacas; ninguna FK cruza el schema.
DO $guard$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='po_promotions_runtime') THEN
    RAISE EXCEPTION 'Ejecutar provision-runtime.sql con el administrador primero';
  END IF;
END $guard$;

CREATE FUNCTION promotions.fn_normalize_code(value text) RETURNS text
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE SET search_path=pg_catalog
AS $$ SELECT translate(btrim(value, U&'\0009\000A\000B\000C\000D\0020\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF'),
  'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ') $$;

CREATE FUNCTION promotions.fn_valid_channels(value text[]) RETURNS boolean
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE SET search_path=pg_catalog
AS $$ SELECT cardinality(value)>0 AND array_ndims(value)=1
  AND array_position(value,NULL) IS NULL
  AND value <@ ARRAY['MARKETPLACE','CHATBOT','RETAIL','VENTAS']::text[]
  AND cardinality(value)=(SELECT count(DISTINCT x) FROM unnest(value) x) $$;

CREATE FUNCTION promotions.fn_valid_envelope(value jsonb) RETURNS boolean
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE SET search_path=pg_catalog AS $$
SELECT coalesce(jsonb_typeof(value)='object'
  AND value ?& ARRAY['message_id','schema_version','occurred_at','correlation_id','producer','kind','name','data']
  AND NOT EXISTS (SELECT 1 FROM unnest(ARRAY['message_id','occurred_at','correlation_id','producer','kind','name']) k
    WHERE jsonb_typeof(value->k) IS DISTINCT FROM 'string' OR length(btrim(value->>k))=0)
  AND CASE WHEN jsonb_typeof(value->'schema_version')='number' THEN
    (value->>'schema_version')::numeric BETWEEN 1 AND 2147483647
    AND trunc((value->>'schema_version')::numeric)=(value->>'schema_version')::numeric ELSE false END
  AND value->>'kind' IN ('event','command','result') AND jsonb_typeof(value->'data')='object'
  AND (NOT value ? 'causation_id' OR jsonb_typeof(value->'causation_id') IN ('string','null'))
  AND (NOT value ? 'operation_id' OR jsonb_typeof(value->'operation_id')='null'
    OR (jsonb_typeof(value->'operation_id')='string' AND value->>'operation_id' ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')),false) $$;

CREATE TABLE promotions.promotions (
  id uuid DEFAULT gen_random_uuid() CONSTRAINT pk_promotions PRIMARY KEY,
  name text NOT NULL CONSTRAINT ck_promotions_name CHECK (length(btrim(name))>0),
  discount_type text NOT NULL CONSTRAINT ck_promotions_discount_type CHECK (discount_type IN ('PORCENTAJE','MONTO_FIJO')),
  discount_value numeric NOT NULL,
  modality text NOT NULL CONSTRAINT ck_promotions_modality CHECK (modality IN ('AUTOMATICA','CUPON')),
  state text NOT NULL CONSTRAINT ck_promotions_state CHECK (state IN ('ACTIVO','INACTIVO')),
  valid_from timestamptz NOT NULL,
  valid_until timestamptz NOT NULL,
  priority integer NOT NULL CONSTRAINT ck_promotions_priority CHECK (priority>0),
  enabled_channels text[] NOT NULL CONSTRAINT ck_promotions_channels CHECK (promotions.fn_valid_channels(enabled_channels)),
  first_activated_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_promotions_discount CHECK (discount_value>0 AND discount_value NOT IN ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric) AND (discount_type<>'PORCENTAJE' OR discount_value<=100)),
  CONSTRAINT ck_promotions_period CHECK (isfinite(valid_from) AND isfinite(valid_until) AND valid_from<valid_until),
  CONSTRAINT ck_promotions_activation CHECK (state<>'ACTIVO' OR first_activated_at IS NOT NULL)
);
CREATE INDEX ix_promotions_evaluation ON promotions.promotions(priority,valid_from,valid_until,id) WHERE state='ACTIVO';

CREATE TABLE promotions.promotion_scopes (
  id uuid DEFAULT gen_random_uuid() CONSTRAINT pk_promotion_scopes PRIMARY KEY,
  promotion_id uuid NOT NULL CONSTRAINT fk_promotion_scopes_promotion REFERENCES promotions.promotions(id),
  product_id text,
  sku text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_promotion_scopes_reference CHECK (
    (product_id IS NOT NULL AND length(btrim(product_id))>0 AND sku IS NULL)
    OR (sku IS NOT NULL AND length(btrim(sku))>0 AND product_id IS NULL))
);
CREATE UNIQUE INDEX uq_promotion_scopes_product ON promotions.promotion_scopes(promotion_id,product_id) WHERE product_id IS NOT NULL;
CREATE UNIQUE INDEX uq_promotion_scopes_sku ON promotions.promotion_scopes(promotion_id,sku) WHERE sku IS NOT NULL;
CREATE INDEX ix_promotion_scopes_promotion ON promotions.promotion_scopes(promotion_id);
CREATE INDEX ix_promotion_scopes_product ON promotions.promotion_scopes(product_id,promotion_id) WHERE product_id IS NOT NULL;
CREATE INDEX ix_promotion_scopes_sku ON promotions.promotion_scopes(sku,promotion_id) WHERE sku IS NOT NULL;

CREATE TABLE promotions.combination_policy (
  promotion_id uuid CONSTRAINT pk_combination_policy PRIMARY KEY
    CONSTRAINT fk_combination_policy_promotion REFERENCES promotions.promotions(id),
  pricing_offer boolean NOT NULL,
  automatic_promotion boolean NOT NULL,
  coupon boolean NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE promotions.coupons (
  id uuid DEFAULT gen_random_uuid() CONSTRAINT pk_coupons PRIMARY KEY,
  promotion_id uuid NOT NULL CONSTRAINT fk_coupons_promotion REFERENCES promotions.promotions(id),
  code text NOT NULL CONSTRAINT uq_coupons_code UNIQUE,
  state text NOT NULL CONSTRAINT ck_coupons_state CHECK (state IN ('ACTIVO','INACTIVO')),
  minimum_amount numeric CONSTRAINT ck_coupons_minimum CHECK (minimum_amount>0 AND minimum_amount NOT IN ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric)),
  max_global_uses integer CONSTRAINT ck_coupons_global CHECK (max_global_uses>0),
  max_customer_uses integer CONSTRAINT ck_coupons_customer CHECK (max_customer_uses>0),
  cancellation_policy text NOT NULL CONSTRAINT ck_coupons_policy CHECK (cancellation_policy IN ('RESTAURAR_EN_CANCELACION','NO_RESTAURAR')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_coupons_code CHECK (code=promotions.fn_normalize_code(code) AND code COLLATE "C" ~ '^[A-Z0-9_-]+$')
);
CREATE INDEX ix_coupons_promotion ON promotions.coupons(promotion_id);

CREATE TABLE promotions.coupon_uses (
  id uuid DEFAULT gen_random_uuid() CONSTRAINT pk_coupon_uses PRIMARY KEY,
  coupon_id uuid NOT NULL CONSTRAINT fk_coupon_uses_coupon REFERENCES promotions.coupons(id),
  promotion_id uuid NOT NULL CONSTRAINT fk_coupon_uses_promotion REFERENCES promotions.promotions(id),
  order_id text NOT NULL CONSTRAINT ck_coupon_uses_order CHECK (length(btrim(order_id))>0),
  customer_ref uuid,
  channel_id text NOT NULL CONSTRAINT ck_coupon_uses_channel CHECK (channel_id IN ('MARKETPLACE','CHATBOT','RETAIL')),
  consumed_at timestamptz NOT NULL CONSTRAINT ck_coupon_uses_consumed CHECK (isfinite(consumed_at)),
  cancellation_policy text NOT NULL CONSTRAINT ck_coupon_uses_policy CHECK (cancellation_policy IN ('RESTAURAR_EN_CANCELACION','NO_RESTAURAR')),
  restored_at timestamptz,
  CONSTRAINT uq_coupon_uses_order_coupon UNIQUE(order_id,coupon_id),
  CONSTRAINT ck_coupon_uses_restored CHECK (restored_at IS NULL OR (isfinite(restored_at) AND restored_at>=consumed_at AND cancellation_policy='RESTAURAR_EN_CANCELACION'))
);
CREATE INDEX ix_coupon_uses_coupon ON promotions.coupon_uses(coupon_id);
CREATE INDEX ix_coupon_uses_promotion ON promotions.coupon_uses(promotion_id);
CREATE INDEX ix_coupon_uses_capacity ON promotions.coupon_uses(coupon_id,customer_ref) WHERE restored_at IS NULL;

CREATE TABLE promotions.recommendation_rules (
  id uuid DEFAULT gen_random_uuid() CONSTRAINT pk_recommendation_rules PRIMARY KEY,
  name text NOT NULL CONSTRAINT ck_recommendation_rules_name CHECK (length(btrim(name))>0),
  recommendation_type text NOT NULL CONSTRAINT ck_recommendation_rules_type CHECK (recommendation_type IN ('CROSS_SELL','UPSELL')),
  origin_type text NOT NULL CONSTRAINT ck_recommendation_rules_origin_type CHECK (origin_type IN ('PRODUCTO','CATEGORIA')),
  origin_id text NOT NULL CONSTRAINT ck_recommendation_rules_origin CHECK (length(btrim(origin_id))>0),
  priority integer NOT NULL CONSTRAINT ck_recommendation_rules_priority CHECK (priority>0),
  state text NOT NULL CONSTRAINT ck_recommendation_rules_state CHECK (state IN ('ACTIVO','INACTIVO')),
  valid_from timestamptz NOT NULL,
  valid_until timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_recommendation_rules_period CHECK (isfinite(valid_from) AND isfinite(valid_until) AND valid_from<valid_until)
);
CREATE INDEX ix_recommendation_rules_origin ON promotions.recommendation_rules(origin_type,origin_id,priority,id) WHERE state='ACTIVO';

CREATE TABLE promotions.recommendation_items (
  id uuid DEFAULT gen_random_uuid() CONSTRAINT pk_recommendation_items PRIMARY KEY,
  rule_id uuid NOT NULL CONSTRAINT fk_recommendation_items_rule REFERENCES promotions.recommendation_rules(id),
  product_id text NOT NULL CONSTRAINT ck_recommendation_items_product CHECK (length(btrim(product_id))>0),
  item_order integer NOT NULL CONSTRAINT ck_recommendation_items_order CHECK (item_order>0),
  superiority_criterion text CONSTRAINT ck_recommendation_items_criterion CHECK (superiority_criterion IN ('MAYOR_RENDIMIENTO','MEJOR_MATERIAL','MAYOR_CAPACIDAD','FUNCIONALIDAD_ADICIONAL')),
  commercial_justification text CONSTRAINT ck_recommendation_items_justification CHECK (length(commercial_justification)<=500),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_recommendation_items_product UNIQUE(rule_id,product_id)
);
CREATE INDEX ix_recommendation_items_order ON promotions.recommendation_items(rule_id,item_order,id);

-- Lecturas locales, no entidades del owner externo. Payload original disponible
-- para el adaptador: AsyncAPI declara estos eventos como GenericData.
CREATE TABLE promotions.catalog_projection (
  reference_type text NOT NULL CONSTRAINT ck_catalog_projection_type CHECK (reference_type IN ('PRODUCTO','SKU')),
  reference_id text NOT NULL CONSTRAINT ck_catalog_projection_reference CHECK (length(btrim(reference_id))>0),
  product_id text NOT NULL CONSTRAINT ck_catalog_projection_product CHECK (length(btrim(product_id))>0),
  active boolean NOT NULL,
  snapshot jsonb NOT NULL CONSTRAINT ck_catalog_projection_snapshot CHECK (jsonb_typeof(snapshot)='object'),
  source_version bigint CONSTRAINT ck_catalog_projection_version CHECK (source_version>0),
  source_occurred_at timestamptz NOT NULL CONSTRAINT ck_catalog_projection_time CHECK (isfinite(source_occurred_at)),
  source_message_id text NOT NULL CONSTRAINT ck_catalog_projection_message CHECK (length(btrim(source_message_id))>0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_catalog_projection PRIMARY KEY(reference_type,reference_id),
  CONSTRAINT ck_catalog_projection_product_identity CHECK (reference_type<>'PRODUCTO' OR reference_id=product_id)
);
CREATE INDEX ix_catalog_projection_product ON promotions.catalog_projection(product_id);

CREATE TABLE promotions.price_projection (
  sku text NOT NULL CONSTRAINT ck_price_projection_sku CHECK (length(btrim(sku))>0),
  channel_id text NOT NULL CONSTRAINT ck_price_projection_channel CHECK (channel_id IN ('MARKETPLACE','CHATBOT','RETAIL','VENTAS')),
  snapshot jsonb NOT NULL CONSTRAINT ck_price_projection_snapshot CHECK (jsonb_typeof(snapshot)='object'),
  source_version bigint CONSTRAINT ck_price_projection_version CHECK (source_version>0),
  source_occurred_at timestamptz NOT NULL CONSTRAINT ck_price_projection_time CHECK (isfinite(source_occurred_at)),
  source_message_id text NOT NULL CONSTRAINT ck_price_projection_message CHECK (length(btrim(source_message_id))>0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_price_projection PRIMARY KEY(sku,channel_id)
);

CREATE TABLE promotions.stock_projection (
  sku text CONSTRAINT pk_stock_projection PRIMARY KEY CONSTRAINT ck_stock_projection_sku CHECK (length(btrim(sku))>0),
  availability text NOT NULL CONSTRAINT ck_stock_projection_availability CHECK (availability IN ('DISPONIBLE','STOCK_BAJO','AGOTADO')),
  snapshot jsonb NOT NULL CONSTRAINT ck_stock_projection_snapshot CHECK (jsonb_typeof(snapshot)='object'),
  source_version bigint CONSTRAINT ck_stock_projection_version CHECK (source_version>0),
  source_occurred_at timestamptz NOT NULL CONSTRAINT ck_stock_projection_time CHECK (isfinite(source_occurred_at)),
  source_message_id text NOT NULL CONSTRAINT ck_stock_projection_message CHECK (length(btrim(source_message_id))>0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE promotions.outbox (
  message_id text CONSTRAINT pk_outbox PRIMARY KEY CONSTRAINT ck_outbox_message CHECK (length(btrim(message_id))>0),
  schema_version integer NOT NULL CONSTRAINT ck_outbox_version CHECK (schema_version>0),
  occurred_at timestamptz NOT NULL CONSTRAINT ck_outbox_time CHECK (isfinite(occurred_at)),
  correlation_id text NOT NULL CONSTRAINT ck_outbox_correlation CHECK (length(btrim(correlation_id))>0),
  causation_id text,
  operation_id uuid,
  producer text NOT NULL CONSTRAINT ck_outbox_producer CHECK (producer='promotions-svc'),
  kind text NOT NULL CONSTRAINT ck_outbox_kind CHECK (kind IN ('event','command','result')),
  name text NOT NULL CONSTRAINT ck_outbox_name CHECK (length(btrim(name))>0),
  data jsonb NOT NULL CONSTRAINT ck_outbox_data CHECK (jsonb_typeof(data)='object'),
  created_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  attempts integer NOT NULL DEFAULT 0 CONSTRAINT ck_outbox_attempts CHECK (attempts>=0),
  last_error text,
  CONSTRAINT ck_outbox_published CHECK (published_at IS NULL OR (isfinite(published_at) AND published_at>=created_at))
);
CREATE INDEX ix_outbox_pending ON promotions.outbox(created_at,message_id) WHERE published_at IS NULL;

CREATE TABLE promotions.inbox (
  message_id text NOT NULL CONSTRAINT ck_inbox_message CHECK (length(btrim(message_id))>0),
  handler text NOT NULL CONSTRAINT ck_inbox_handler CHECK (length(btrim(handler))>0),
  envelope jsonb NOT NULL CONSTRAINT ck_inbox_envelope CHECK (promotions.fn_valid_envelope(envelope) AND envelope->>'message_id'=message_id),
  received_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  result jsonb,
  CONSTRAINT pk_inbox PRIMARY KEY(message_id,handler),
  CONSTRAINT ck_inbox_result CHECK ((completed_at IS NULL AND result IS NULL) OR
    (completed_at IS NOT NULL AND isfinite(completed_at) AND completed_at>=received_at AND result IS NOT NULL AND jsonb_typeof(result)='object'))
);

CREATE FUNCTION promotions.fn_touch_updated_at() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
BEGIN NEW.updated_at:=clock_timestamp(); RETURN NEW; END $$;

CREATE FUNCTION promotions.fn_guard_promotion() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
BEGIN
  IF TG_OP='INSERT' THEN
    IF NEW.state='ACTIVO' THEN NEW.first_activated_at:=clock_timestamp();
    ELSE NEW.first_activated_at:=NULL; END IF;
  ELSE
    IF NEW.id<>OLD.id OR NEW.created_at<>OLD.created_at THEN RAISE EXCEPTION 'IMMUTABLE_PROMOTION_IDENTITY'; END IF;
    IF NEW.modality<>OLD.modality AND (OLD.state<>'INACTIVO' OR NEW.state<>'INACTIVO'
       OR OLD.first_activated_at IS NOT NULL
       OR EXISTS(SELECT 1 FROM promotions.coupons WHERE promotion_id=OLD.id)
       OR EXISTS(SELECT 1 FROM promotions.coupon_uses WHERE promotion_id=OLD.id)) THEN
      RAISE EXCEPTION 'PROMOTION_MODALITY_LOCKED';
    END IF;
    NEW.first_activated_at:=OLD.first_activated_at;
    IF NEW.state='ACTIVO' AND NEW.first_activated_at IS NULL THEN NEW.first_activated_at:=clock_timestamp(); END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_promotions_guard BEFORE INSERT OR UPDATE ON promotions.promotions FOR EACH ROW EXECUTE FUNCTION promotions.fn_guard_promotion();

CREATE FUNCTION promotions.fn_guard_coupon() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE m text;
BEGIN
  IF TG_OP='DELETE' THEN
    PERFORM 1 FROM promotions.promotions WHERE id=OLD.promotion_id FOR UPDATE;
    RETURN OLD;
  END IF;
  IF TG_OP='UPDATE' THEN
    IF NEW.id<>OLD.id OR NEW.created_at<>OLD.created_at THEN RAISE EXCEPTION 'IMMUTABLE_COUPON_IDENTITY'; END IF;
    PERFORM 1 FROM promotions.promotions WHERE id IN (OLD.promotion_id,NEW.promotion_id) ORDER BY id FOR UPDATE;
  END IF;
  SELECT modality INTO m FROM promotions.promotions WHERE id=NEW.promotion_id FOR UPDATE;
  IF NOT FOUND OR m<>'CUPON' THEN RAISE EXCEPTION 'COUPON_REQUIRES_COUPON_PROMOTION'; END IF;
  NEW.code:=promotions.fn_normalize_code(NEW.code);
  RETURN NEW;
END $$;
CREATE TRIGGER tr_coupons_guard BEFORE INSERT OR UPDATE OR DELETE ON promotions.coupons FOR EACH ROW EXECUTE FUNCTION promotions.fn_guard_coupon();

-- Hijos serializan sobre su agregado; evita que dos transacciones eliminen
-- sendos hijos y ambas crean que aún queda uno. Reparentado no contractual.
CREATE FUNCTION promotions.fn_lock_parent() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE old_id uuid; new_id uuid; target_id uuid;
BEGIN
  IF TG_OP<>'INSERT' THEN old_id:=(to_jsonb(OLD)->>TG_ARGV[1])::uuid; END IF;
  IF TG_OP<>'DELETE' THEN new_id:=(to_jsonb(NEW)->>TG_ARGV[1])::uuid; END IF;
  IF TG_OP='UPDATE' AND old_id<>new_id THEN RAISE EXCEPTION 'IMMUTABLE_AGGREGATE_PARENT'; END IF;
  target_id:=coalesce(new_id,old_id);
  EXECUTE format('SELECT 1 FROM promotions.%I WHERE id=$1 FOR UPDATE',TG_ARGV[0]) USING target_id;
  IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END $$;
CREATE TRIGGER tr_promotion_scopes_lock BEFORE INSERT OR UPDATE OR DELETE ON promotions.promotion_scopes FOR EACH ROW EXECUTE FUNCTION promotions.fn_lock_parent('promotions','promotion_id');
CREATE TRIGGER tr_combination_policy_lock BEFORE INSERT OR UPDATE OR DELETE ON promotions.combination_policy FOR EACH ROW EXECUTE FUNCTION promotions.fn_lock_parent('promotions','promotion_id');
CREATE TRIGGER tr_recommendation_items_lock BEFORE INSERT OR UPDATE OR DELETE ON promotions.recommendation_items FOR EACH ROW EXECUTE FUNCTION promotions.fn_lock_parent('recommendation_rules','rule_id');

CREATE FUNCTION promotions.fn_check_promotion_complete() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE parent_id uuid;
BEGIN
  IF TG_TABLE_NAME='promotions' THEN parent_id:=coalesce(NEW.id,OLD.id);
  ELSE parent_id:=coalesce(NEW.promotion_id,OLD.promotion_id); END IF;
  IF EXISTS(SELECT 1 FROM promotions.promotions WHERE id=parent_id) AND (
      NOT EXISTS(SELECT 1 FROM promotions.promotion_scopes WHERE promotion_id=parent_id)
      OR NOT EXISTS(SELECT 1 FROM promotions.combination_policy WHERE promotion_id=parent_id)) THEN
    RAISE EXCEPTION 'PROMOTION_REQUIRES_SCOPE_AND_POLICY';
  END IF;
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER ct_promotions_complete AFTER INSERT OR UPDATE ON promotions.promotions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION promotions.fn_check_promotion_complete();
CREATE CONSTRAINT TRIGGER ct_promotion_scopes_complete AFTER INSERT OR UPDATE OR DELETE ON promotions.promotion_scopes DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION promotions.fn_check_promotion_complete();
CREATE CONSTRAINT TRIGGER ct_combination_policy_complete AFTER INSERT OR UPDATE OR DELETE ON promotions.combination_policy DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION promotions.fn_check_promotion_complete();

CREATE FUNCTION promotions.fn_check_recommendation_complete() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE parent_id uuid; r promotions.recommendation_rules%ROWTYPE;
BEGIN
  IF TG_TABLE_NAME='recommendation_rules' THEN parent_id:=coalesce(NEW.id,OLD.id);
  ELSE parent_id:=coalesce(NEW.rule_id,OLD.rule_id); END IF;
  SELECT * INTO r FROM promotions.recommendation_rules WHERE id=parent_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF NOT EXISTS(SELECT 1 FROM promotions.recommendation_items WHERE rule_id=parent_id) THEN RAISE EXCEPTION 'RECOMMENDATION_REQUIRES_ITEMS'; END IF;
  IF EXISTS(SELECT 1 FROM promotions.recommendation_items WHERE rule_id=parent_id
      AND ((r.origin_type='PRODUCTO' AND product_id=r.origin_id)
      OR (r.recommendation_type='UPSELL' AND superiority_criterion IS NULL))) THEN
    RAISE EXCEPTION 'INVALID_RECOMMENDATION_ITEM';
  END IF;
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER ct_recommendation_rules_complete AFTER INSERT OR UPDATE ON promotions.recommendation_rules DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION promotions.fn_check_recommendation_complete();
CREATE CONSTRAINT TRIGGER ct_recommendation_items_complete AFTER INSERT OR UPDATE OR DELETE ON promotions.recommendation_items DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION promotions.fn_check_recommendation_complete();

CREATE FUNCTION promotions.fn_guard_coupon_use() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE c promotions.coupons%ROWTYPE; p promotions.promotions%ROWTYPE;
BEGIN
  IF TG_OP='DELETE' THEN RAISE EXCEPTION 'COUPON_HISTORY_IMMUTABLE'; END IF;
  IF TG_OP='UPDATE' THEN
    IF (to_jsonb(NEW)-'restored_at') IS DISTINCT FROM (to_jsonb(OLD)-'restored_at')
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
CREATE TRIGGER tr_coupon_uses_guard BEFORE INSERT OR UPDATE OR DELETE ON promotions.coupon_uses FOR EACH ROW EXECUTE FUNCTION promotions.fn_guard_coupon_use();

CREATE FUNCTION promotions.fn_consume_coupon(p_order_id text,p_coupon_id uuid,
  p_customer_ref uuid,p_channel_id text,p_effective_at timestamptz) RETURNS uuid
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE existing promotions.coupon_uses%ROWTYPE; use_id uuid;
BEGIN
  -- RESTORE/CONSUME serializan por pedido; cupos serializan por cupón.
  PERFORM pg_advisory_xact_lock(hashtextextended('promotions:order:'||p_order_id,0));
  PERFORM 1 FROM promotions.coupons WHERE id=p_coupon_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'COUPON_NOT_FOUND'; END IF;
  SELECT * INTO existing FROM promotions.coupon_uses WHERE order_id=p_order_id AND coupon_id=p_coupon_id;
  IF FOUND THEN
    IF existing.customer_ref IS DISTINCT FROM p_customer_ref OR existing.channel_id IS DISTINCT FROM p_channel_id
       OR existing.consumed_at IS DISTINCT FROM p_effective_at THEN RAISE EXCEPTION 'COUPON_IDENTITY_MISMATCH'; END IF;
    RETURN existing.id;
  END IF;
  INSERT INTO promotions.coupon_uses(coupon_id,promotion_id,order_id,customer_ref,channel_id,consumed_at,cancellation_policy)
    VALUES(p_coupon_id,p_coupon_id,p_order_id,p_customer_ref,p_channel_id,p_effective_at,'NO_RESTAURAR') RETURNING id INTO use_id;
  RETURN use_id;
END $$;

CREATE FUNCTION promotions.fn_restore_coupon(p_order_id text,p_cancelled_at timestamptz)
RETURNS TABLE(coupon_id uuid,outcome text)
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE u promotions.coupon_uses%ROWTYPE;
BEGIN
  IF p_order_id IS NULL OR length(btrim(p_order_id))=0 OR p_cancelled_at IS NULL OR NOT isfinite(p_cancelled_at) THEN RAISE EXCEPTION 'INVALID_RESTORATION_REQUEST'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('promotions:order:'||p_order_id,0));
  -- Siempre cupón antes de uso, igual que CONSUME; no depender de UPDATE FOR
  -- una fila de uso antes de tomar el lock del cupón.
  PERFORM 1 FROM promotions.coupons c WHERE c.id IN
    (SELECT cu.coupon_id FROM promotions.coupon_uses cu WHERE cu.order_id=p_order_id) ORDER BY c.id FOR UPDATE;
  FOR u IN SELECT * FROM promotions.coupon_uses cu WHERE cu.order_id=p_order_id ORDER BY cu.coupon_id FOR UPDATE LOOP
    coupon_id:=u.coupon_id;
    IF u.cancellation_policy='NO_RESTAURAR' THEN outcome:='POLICY_KEEPS_CONSUMPTION';
    ELSE
      IF u.restored_at IS NULL THEN UPDATE promotions.coupon_uses SET restored_at=p_cancelled_at WHERE id=u.id; END IF;
      outcome:='RESTORED';
    END IF;
    RETURN NEXT;
  END LOOP;
  IF NOT FOUND THEN coupon_id:=NULL; outcome:='NO_CONSUMPTION'; RETURN NEXT; END IF;
END $$;

CREATE FUNCTION promotions.fn_guard_projection() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
BEGIN
  IF (to_jsonb(NEW)-ARRAY['snapshot','active','availability','source_version','source_occurred_at','source_message_id','updated_at'])
    IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['snapshot','active','availability','source_version','source_occurred_at','source_message_id','updated_at']) THEN
    RAISE EXCEPTION 'IMMUTABLE_PROJECTION_IDENTITY';
  END IF;
  IF NEW.source_message_id=OLD.source_message_id THEN
    IF (to_jsonb(NEW)-'updated_at') IS DISTINCT FROM (to_jsonb(OLD)-'updated_at') THEN RAISE EXCEPTION 'PROJECTION_MESSAGE_CONFLICT'; END IF;
    RETURN NULL;
  END IF;
  IF OLD.source_version IS NOT NULL AND NEW.source_version IS NULL THEN RAISE EXCEPTION 'PROJECTION_VERSION_REQUIRED'; END IF;
  IF OLD.source_version IS NOT NULL AND NEW.source_version IS NOT NULL THEN
    IF NEW.source_version<OLD.source_version THEN RETURN NULL; END IF;
    IF NEW.source_version=OLD.source_version THEN RAISE EXCEPTION 'PROJECTION_ORDER_AMBIGUOUS'; END IF;
  ELSE
    IF NEW.source_occurred_at<OLD.source_occurred_at THEN RETURN NULL; END IF;
    IF NEW.source_occurred_at=OLD.source_occurred_at THEN RAISE EXCEPTION 'PROJECTION_ORDER_AMBIGUOUS'; END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE FUNCTION promotions.fn_guard_message_history() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
BEGIN
  IF TG_OP='DELETE' THEN RAISE EXCEPTION 'MESSAGE_HISTORY_IMMUTABLE'; END IF;
  IF TG_TABLE_NAME='outbox' THEN
    IF (to_jsonb(NEW)-ARRAY['published_at','attempts','last_error']) IS DISTINCT FROM
       (to_jsonb(OLD)-ARRAY['published_at','attempts','last_error']) OR NEW.attempts<OLD.attempts
       OR (OLD.published_at IS NOT NULL AND NEW.published_at IS DISTINCT FROM OLD.published_at) THEN
      RAISE EXCEPTION 'OUTBOX_ENVELOPE_IMMUTABLE';
    END IF;
  ELSE
    IF (to_jsonb(NEW)-ARRAY['completed_at','result']) IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['completed_at','result'])
       OR (OLD.completed_at IS NOT NULL AND (NEW.completed_at IS DISTINCT FROM OLD.completed_at OR NEW.result IS DISTINCT FROM OLD.result)) THEN
      RAISE EXCEPTION 'INBOX_RESULT_IMMUTABLE';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_outbox_history BEFORE UPDATE OR DELETE ON promotions.outbox FOR EACH ROW EXECUTE FUNCTION promotions.fn_guard_message_history();
CREATE TRIGGER tr_inbox_history BEFORE UPDATE OR DELETE ON promotions.inbox FOR EACH ROW EXECUTE FUNCTION promotions.fn_guard_message_history();

CREATE FUNCTION promotions.fn_begin_inbox(p_envelope jsonb,p_handler text) RETURNS boolean
LANGUAGE plpgsql SET search_path=pg_catalog,promotions AS $$
DECLARE inserted_id text; existing_envelope jsonb;
BEGIN
  INSERT INTO promotions.inbox(message_id,handler,envelope)
    VALUES(p_envelope->>'message_id',p_handler,p_envelope)
    ON CONFLICT(message_id,handler) DO NOTHING RETURNING message_id INTO inserted_id;
  IF inserted_id IS NOT NULL THEN RETURN true; END IF;
  SELECT envelope INTO existing_envelope FROM promotions.inbox
    WHERE message_id=p_envelope->>'message_id' AND handler=p_handler;
  IF existing_envelope IS DISTINCT FROM p_envelope THEN RAISE EXCEPTION 'INBOX_MESSAGE_CONFLICT'; END IF;
  RETURN false;
END $$;

DO $triggers$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['promotions','combination_policy','coupons','recommendation_rules','recommendation_items','catalog_projection','price_projection','stock_projection'] LOOP
    EXECUTE format('CREATE TRIGGER tr_%I_touch BEFORE UPDATE ON promotions.%I FOR EACH ROW EXECUTE FUNCTION promotions.fn_touch_updated_at()',t,t);
  END LOOP;
  FOREACH t IN ARRAY ARRAY['catalog_projection','price_projection','stock_projection'] LOOP
    EXECUTE format('CREATE TRIGGER tr_%I_guard BEFORE UPDATE ON promotions.%I FOR EACH ROW EXECUTE FUNCTION promotions.fn_guard_projection()',t,t);
  END LOOP;
END $triggers$;

REVOKE ALL ON ALL TABLES IN SCHEMA promotions FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA promotions FROM PUBLIC;
GRANT USAGE ON SCHEMA promotions TO po_promotions_runtime;
GRANT SELECT,INSERT,UPDATE,DELETE ON promotions.promotions,promotions.promotion_scopes,
  promotions.combination_policy,promotions.coupons,promotions.recommendation_rules,
  promotions.recommendation_items TO po_promotions_runtime;
GRANT SELECT,INSERT,UPDATE ON promotions.catalog_projection,promotions.price_projection,
  promotions.stock_projection TO po_promotions_runtime;
GRANT SELECT,INSERT ON promotions.coupon_uses,promotions.inbox,promotions.outbox TO po_promotions_runtime;
GRANT UPDATE(restored_at) ON promotions.coupon_uses TO po_promotions_runtime;
GRANT UPDATE(completed_at,result) ON promotions.inbox TO po_promotions_runtime;
GRANT UPDATE(published_at,attempts,last_error) ON promotions.outbox TO po_promotions_runtime;
GRANT EXECUTE ON FUNCTION promotions.fn_normalize_code(text),promotions.fn_valid_channels(text[]),
  promotions.fn_valid_envelope(jsonb),promotions.fn_begin_inbox(jsonb,text),
  promotions.fn_consume_coupon(text,uuid,uuid,text,timestamptz),
  promotions.fn_restore_coupon(text,timestamptz) TO po_promotions_runtime;
