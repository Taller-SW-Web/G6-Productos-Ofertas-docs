\set ON_ERROR_STOP on
-- Fixtures deterministas dentro de una transacción. Nada comercial persiste.
BEGIN;
SET LOCAL ROLE po_promotions_owner;
CREATE TEMP TABLE assertions(label text PRIMARY KEY);
CREATE FUNCTION pg_temp.assert_true(label text,passed boolean) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN
  IF passed IS DISTINCT FROM true THEN RAISE EXCEPTION 'ASSERTION FAILED: %',label; END IF;
  INSERT INTO assertions VALUES(label);
END $$;
CREATE FUNCTION pg_temp.expect_error(label text,statement text,expected_state text,fragment text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE caught boolean:=false;
BEGIN
  BEGIN EXECUTE statement;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE<>expected_state OR (fragment IS NOT NULL AND position(fragment IN SQLERRM)=0) THEN
      RAISE EXCEPTION 'WRONG ERROR [%]: % %',label,SQLSTATE,SQLERRM;
    END IF;
    caught:=true;
  END;
  PERFORM pg_temp.assert_true(label,caught);
END $$;

SELECT pg_temp.assert_true('12 tablas de arquitectura',
 (SELECT count(*)=12 FROM pg_tables WHERE schemaname='promotions' AND tablename<>'schema_migrations'));
SELECT pg_temp.assert_true('owner aislado',
 (SELECT pg_get_userbyid(nspowner)='po_promotions_owner' FROM pg_namespace WHERE nspname='promotions'));
SELECT pg_temp.assert_true('ninguna FK entre schemas',NOT EXISTS(
 SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
 JOIN pg_namespace n ON n.oid=t.relnamespace JOIN pg_class p ON p.oid=c.confrelid
 WHERE c.contype='f' AND n.nspname='promotions' AND p.relnamespace<>t.relnamespace));
SELECT pg_temp.assert_true('FK con índice de prefijo',NOT EXISTS(
 SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
 JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype='f' AND n.nspname='promotions'
 AND NOT EXISTS(SELECT 1 FROM pg_index i WHERE i.indrelid=c.conrelid
   AND i.indisvalid AND i.indpred IS NULL AND
   ARRAY(SELECT key FROM unnest(i.indkey) WITH ORDINALITY q(key,pos)
     WHERE pos<=cardinality(c.conkey))=c.conkey)));
SELECT pg_temp.assert_true('funciones invoker',NOT EXISTS(
 SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='promotions' AND p.prosecdef));
SELECT pg_temp.assert_true('PUBLIC sin schema',NOT EXISTS(
 SELECT 1 FROM pg_namespace n CROSS JOIN LATERAL aclexplode(coalesce(n.nspacl,acldefault('n',n.nspowner))) a
 WHERE n.nspname='promotions' AND a.grantee=0));
SELECT pg_temp.assert_true('PUBLIC sin execute',NOT EXISTS(
 SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
 WHERE n.nspname='promotions' AND a.grantee=0));
SELECT pg_temp.assert_true('anon/authenticated sin acceso',NOT EXISTS(
 SELECT 1 FROM pg_roles WHERE rolname IN ('anon','authenticated')
 AND has_schema_privilege(oid,'promotions','USAGE')));
SELECT pg_temp.assert_true('runtime no es owner',NOT pg_has_role('po_promotions_runtime','po_promotions_owner','MEMBER'));
SELECT pg_temp.assert_true('runtime sin ledger',NOT has_table_privilege('po_promotions_runtime','promotions.schema_migrations','INSERT'));
SELECT pg_temp.assert_true('runtime sin borrar historia',NOT has_table_privilege('po_promotions_runtime','promotions.coupon_uses','DELETE'));
SELECT pg_temp.assert_true('runtime sin editar identidad de uso',NOT has_column_privilege('po_promotions_runtime','promotions.coupon_uses','order_id','UPDATE'));
SELECT pg_temp.assert_true('runtime sin editar envelope',NOT has_column_privilege('po_promotions_runtime','promotions.outbox','data','UPDATE'));

INSERT INTO promotions.promotions(id,name,discount_type,discount_value,modality,state,valid_from,valid_until,priority,enabled_channels) VALUES
 ('53000000-0000-0000-0000-000000000001','Fixture cupón','PORCENTAJE',10,'CUPON','ACTIVO','2000-01-01','2100-01-01',1,ARRAY['MARKETPLACE','RETAIL']),
 ('53000000-0000-0000-0000-000000000002','Fixture automática','MONTO_FIJO',5,'AUTOMATICA','INACTIVO','2000-01-01','2100-01-01',2,ARRAY['CHATBOT']),
 ('53000000-0000-0000-0000-000000000003','Fixture modalidad','PORCENTAJE',5,'AUTOMATICA','INACTIVO','2000-01-01','2100-01-01',2,ARRAY['CHATBOT']);
INSERT INTO promotions.combination_policy SELECT id,false,false,false FROM promotions.promotions WHERE id IN
 ('53000000-0000-0000-0000-000000000001','53000000-0000-0000-0000-000000000002','53000000-0000-0000-0000-000000000003');
INSERT INTO promotions.promotion_scopes(promotion_id,product_id) VALUES
 ('53000000-0000-0000-0000-000000000001','product-fixture'),
 ('53000000-0000-0000-0000-000000000002','product-fixture'),
 ('53000000-0000-0000-0000-000000000003','product-fixture');
INSERT INTO promotions.promotion_scopes(promotion_id,sku) VALUES('53000000-0000-0000-0000-000000000001','SKU-fixture');
INSERT INTO promotions.coupons(id,promotion_id,code,state,max_global_uses,max_customer_uses,cancellation_policy) VALUES
 ('53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000001','  test-53  ','ACTIVO',2,1,'RESTAURAR_EN_CANCELACION'),
 ('53000000-0000-0000-0000-000000000012','53000000-0000-0000-0000-000000000001','KEEP-53','ACTIVO',1,NULL,'NO_RESTAURAR'),
 ('53000000-0000-0000-0000-000000000013','53000000-0000-0000-0000-000000000001','ANON-53','ACTIVO',NULL,NULL,'RESTAURAR_EN_CANCELACION');
INSERT INTO promotions.recommendation_rules(id,name,recommendation_type,origin_type,origin_id,priority,state,valid_from,valid_until) VALUES
 ('53000000-0000-0000-0000-000000000021','Fixture cross','CROSS_SELL','PRODUCTO','origin-fixture',1,'ACTIVO','2000-01-01','2100-01-01'),
 ('53000000-0000-0000-0000-000000000022','Fixture up','UPSELL','CATEGORIA','category-fixture',2,'INACTIVO','2000-01-01','2100-01-01');
INSERT INTO promotions.recommendation_items(rule_id,product_id,item_order,superiority_criterion) VALUES
 ('53000000-0000-0000-0000-000000000021','recommended-fixture',1,NULL),
 ('53000000-0000-0000-0000-000000000022','better-fixture',1,'MEJOR_MATERIAL');
SET CONSTRAINTS ALL IMMEDIATE;

SELECT pg_temp.assert_true('normalización ASCII',
 (SELECT code='TEST-53' FROM promotions.coupons WHERE id='53000000-0000-0000-0000-000000000011'));
SELECT pg_temp.assert_true('trim no elimina letras v',promotions.fn_normalize_code(' viva ')='VIVA');
SELECT pg_temp.assert_true('trim de espacios Unicode',promotions.fn_normalize_code(U&'\00A0viva\00A0')='VIVA');
SELECT pg_temp.expect_error('código duplicado normalizado',$q$UPDATE promotions.coupons SET code=' test-53 ' WHERE code='KEEP-53'$q$,'23505');
SELECT pg_temp.expect_error('código no ASCII',$q$UPDATE promotions.coupons SET code='CUPÓN' WHERE code='KEEP-53'$q$,'23514');
SELECT pg_temp.expect_error('límite global cero',$q$UPDATE promotions.coupons SET max_global_uses=0 WHERE code='KEEP-53'$q$,'23514');
SELECT pg_temp.expect_error('límite por cliente negativo',$q$UPDATE promotions.coupons SET max_customer_uses=-1 WHERE code='KEEP-53'$q$,'23514');
SELECT pg_temp.expect_error('monto mínimo cero',$q$UPDATE promotions.coupons SET minimum_amount=0 WHERE code='KEEP-53'$q$,'23514');
SELECT pg_temp.expect_error('porcentaje mayor de 100',$q$UPDATE promotions.promotions SET discount_value=101 WHERE id='53000000-0000-0000-0000-000000000001'$q$,'23514');
SELECT pg_temp.expect_error('porcentaje no se redondea a válido',$q$UPDATE promotions.promotions SET discount_value=100.001 WHERE id='53000000-0000-0000-0000-000000000001'$q$,'23514');
SELECT pg_temp.expect_error('monto fijo infinito',$q$UPDATE promotions.promotions SET discount_value='Infinity' WHERE id='53000000-0000-0000-0000-000000000002'$q$,'23514');
SELECT pg_temp.expect_error('mínimo NaN',$q$UPDATE promotions.coupons SET minimum_amount='NaN' WHERE code='KEEP-53'$q$,'23514');
UPDATE promotions.coupons SET minimum_amount=0.001 WHERE code='KEEP-53';
SELECT pg_temp.assert_true('mínimo positivo sin pérdida de precisión',(SELECT minimum_amount=0.001 FROM promotions.coupons WHERE code='KEEP-53'));
SELECT pg_temp.expect_error('fechas invertidas',$q$UPDATE promotions.promotions SET valid_until=valid_from WHERE id='53000000-0000-0000-0000-000000000001'$q$,'23514');
SELECT pg_temp.expect_error('canales vacíos',$q$UPDATE promotions.promotions SET enabled_channels=ARRAY[]::text[] WHERE id='53000000-0000-0000-0000-000000000001'$q$,'23514');
SELECT pg_temp.expect_error('canales duplicados',$q$UPDATE promotions.promotions SET enabled_channels=ARRAY['RETAIL','RETAIL'] WHERE id='53000000-0000-0000-0000-000000000001'$q$,'23514');
SELECT pg_temp.expect_error('canal inválido',$q$UPDATE promotions.promotions SET enabled_channels=ARRAY['OTRO'] WHERE id='53000000-0000-0000-0000-000000000001'$q$,'23514');
SELECT pg_temp.expect_error('canal null',$q$UPDATE promotions.promotions SET enabled_channels=ARRAY['RETAIL',NULL] WHERE id='53000000-0000-0000-0000-000000000001'$q$,'23514');
SELECT pg_temp.expect_error('scope XOR',$q$INSERT INTO promotions.promotion_scopes(promotion_id,product_id,sku) VALUES('53000000-0000-0000-0000-000000000001','p','s')$q$,'23514');
SELECT pg_temp.expect_error('scope duplicado',$q$INSERT INTO promotions.promotion_scopes(promotion_id,product_id) VALUES('53000000-0000-0000-0000-000000000001','product-fixture')$q$,'23505');
SELECT pg_temp.expect_error('último alcance',$q$DELETE FROM promotions.promotion_scopes WHERE promotion_id='53000000-0000-0000-0000-000000000002'$q$,'P0001','PROMOTION_REQUIRES_SCOPE_AND_POLICY');
SELECT pg_temp.expect_error('política obligatoria',$q$DELETE FROM promotions.combination_policy WHERE promotion_id='53000000-0000-0000-0000-000000000002'$q$,'P0001','PROMOTION_REQUIRES_SCOPE_AND_POLICY');
SELECT pg_temp.expect_error('cupón no automático',$q$UPDATE promotions.coupons SET promotion_id='53000000-0000-0000-0000-000000000002' WHERE code='KEEP-53'$q$,'P0001','COUPON_REQUIRES_COUPON_PROMOTION');
UPDATE promotions.promotions SET modality='CUPON' WHERE id='53000000-0000-0000-0000-000000000003';
SELECT pg_temp.assert_true('cambio inicial permitido',(SELECT modality='CUPON' FROM promotions.promotions WHERE id='53000000-0000-0000-0000-000000000003'));
UPDATE promotions.promotions SET state='ACTIVO' WHERE id='53000000-0000-0000-0000-000000000003';
UPDATE promotions.promotions SET state='INACTIVO',first_activated_at=NULL WHERE id='53000000-0000-0000-0000-000000000003';
SELECT pg_temp.assert_true('activación persistente',(SELECT first_activated_at IS NOT NULL FROM promotions.promotions WHERE id='53000000-0000-0000-0000-000000000003'));
SELECT pg_temp.expect_error('modalidad histórica bloqueada',$q$UPDATE promotions.promotions SET modality='AUTOMATICA' WHERE id='53000000-0000-0000-0000-000000000003'$q$,'P0001','PROMOTION_MODALITY_LOCKED');
SELECT pg_temp.expect_error('recomendado propio origen',$q$UPDATE promotions.recommendation_items SET product_id='origin-fixture' WHERE rule_id='53000000-0000-0000-0000-000000000021'$q$,'P0001','INVALID_RECOMMENDATION_ITEM');
SELECT pg_temp.expect_error('upsell sin criterio',$q$UPDATE promotions.recommendation_items SET superiority_criterion=NULL WHERE rule_id='53000000-0000-0000-0000-000000000022'$q$,'P0001','INVALID_RECOMMENDATION_ITEM');
SELECT pg_temp.expect_error('cambiar tipo exige criterios',$q$UPDATE promotions.recommendation_rules SET recommendation_type='UPSELL' WHERE id='53000000-0000-0000-0000-000000000021'$q$,'P0001','INVALID_RECOMMENDATION_ITEM');
SELECT pg_temp.expect_error('regla requiere recomendados',$q$DELETE FROM promotions.recommendation_items WHERE rule_id='53000000-0000-0000-0000-000000000021'$q$,'P0001','RECOMMENDATION_REQUIRES_ITEMS');
SELECT pg_temp.expect_error('recomendado duplicado',$q$INSERT INTO promotions.recommendation_items(rule_id,product_id,item_order) VALUES('53000000-0000-0000-0000-000000000021','recommended-fixture',2)$q$,'23505');
SELECT pg_temp.expect_error('orden positivo',$q$UPDATE promotions.recommendation_items SET item_order=0 WHERE rule_id='53000000-0000-0000-0000-000000000021'$q$,'23514');

SELECT pg_temp.expect_error('identidad obligatoria con límite',$q$SELECT promotions.fn_consume_coupon('order-fixture-0','53000000-0000-0000-0000-000000000011',NULL,'MARKETPLACE','2026-10-03')$q$,'P0001','CUSTOMER_REF_REQUERIDO');
SELECT pg_temp.expect_error('consumo fuera de canal',$q$SELECT promotions.fn_consume_coupon('order-fixture-0','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000099','CHATBOT','2026-10-03')$q$,'P0001','COUPON_NOT_ELIGIBLE');
SELECT pg_temp.expect_error('consumo fuera de vigencia',$q$SELECT promotions.fn_consume_coupon('order-fixture-0','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000099','MARKETPLACE','2100-01-01')$q$,'P0001','COUPON_NOT_ELIGIBLE');
SELECT promotions.fn_consume_coupon('order-fixture-1','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000099','MARKETPLACE','2026-10-03');
SELECT pg_temp.assert_true('consumo idempotente',
 promotions.fn_consume_coupon('order-fixture-1','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000099','MARKETPLACE','2026-10-03')=
 (SELECT id FROM promotions.coupon_uses WHERE order_id='order-fixture-1'));
SELECT pg_temp.expect_error('pedido con identidad distinta',$q$SELECT promotions.fn_consume_coupon('order-fixture-1','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000098','MARKETPLACE','2026-10-03')$q$,'P0001','COUPON_IDENTITY_MISMATCH');
SELECT pg_temp.expect_error('cupo por cliente',$q$SELECT promotions.fn_consume_coupon('order-fixture-2','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000099','MARKETPLACE','2026-10-03')$q$,'P0001','COUPON_CUSTOMER_LIMIT');
SELECT promotions.fn_consume_coupon('order-fixture-2','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000098','MARKETPLACE','2026-10-03');
SELECT pg_temp.expect_error('cupo global',$q$SELECT promotions.fn_consume_coupon('order-fixture-3','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000097','MARKETPLACE','2026-10-03')$q$,'P0001','COUPON_GLOBAL_LIMIT');
UPDATE promotions.coupons SET cancellation_policy='NO_RESTAURAR' WHERE code='TEST-53';
SELECT pg_temp.assert_true('política del pedido es snapshot',(SELECT cancellation_policy='RESTAURAR_EN_CANCELACION' FROM promotions.coupon_uses WHERE order_id='order-fixture-1'));
SELECT pg_temp.assert_true('restitución libera cupo',(SELECT outcome='RESTORED' FROM promotions.fn_restore_coupon('order-fixture-1','2026-10-04')));
SELECT pg_temp.assert_true('restitución repetida',(SELECT outcome='RESTORED' FROM promotions.fn_restore_coupon('order-fixture-1','2026-10-05')));
SELECT pg_temp.assert_true('fecha restituida no cambia',(SELECT restored_at='2026-10-04'::timestamptz FROM promotions.coupon_uses WHERE order_id='order-fixture-1'));
SELECT promotions.fn_consume_coupon('order-fixture-3','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000097','MARKETPLACE','2026-10-03');
SELECT promotions.fn_consume_coupon('order-fixture-1','53000000-0000-0000-0000-000000000011','53000000-0000-0000-0000-000000000099','MARKETPLACE','2026-10-03');
SELECT pg_temp.assert_true('reentrega no vuelve a consumir',(SELECT count(*)=1 AND count(restored_at)=1 FROM promotions.coupon_uses WHERE order_id='order-fixture-1'));
SELECT promotions.fn_consume_coupon('order-fixture-keep','53000000-0000-0000-0000-000000000012',NULL,'MARKETPLACE','2026-10-03');
SELECT pg_temp.assert_true('NO_RESTAURAR conserva cupo',(SELECT outcome='POLICY_KEEPS_CONSUMPTION' FROM promotions.fn_restore_coupon('order-fixture-keep','2026-10-04')));
SELECT pg_temp.assert_true('sin consumo no suma cupo',(SELECT outcome='NO_CONSUMPTION' AND coupon_id IS NULL FROM promotions.fn_restore_coupon('order-fixture-none','2026-10-04')));
SELECT pg_temp.expect_error('no borrar historia',$q$DELETE FROM promotions.coupon_uses WHERE order_id='order-fixture-keep'$q$,'P0001','COUPON_HISTORY_IMMUTABLE');
SELECT pg_temp.expect_error('no editar pedido consumido',$q$UPDATE promotions.coupon_uses SET order_id='otro' WHERE order_id='order-fixture-keep'$q$,'P0001','COUPON_HISTORY_IMMUTABLE');
SELECT pg_temp.expect_error('no restaurar política NO_RESTAURAR',$q$UPDATE promotions.coupon_uses SET restored_at='2026-10-04' WHERE order_id='order-fixture-keep'$q$,'23514');

INSERT INTO promotions.stock_projection(sku,availability,snapshot,source_version,source_occurred_at,source_message_id)
 VALUES('fixture-stock','AGOTADO','{}',2,'2026-10-03','stock-2');
UPDATE promotions.stock_projection SET availability='DISPONIBLE',source_version=1,source_message_id='stock-1',source_occurred_at='2026-10-02' WHERE sku='fixture-stock';
SELECT pg_temp.assert_true('proyección antigua no reactiva',(SELECT availability='AGOTADO' AND source_version=2 FROM promotions.stock_projection WHERE sku='fixture-stock'));
SELECT pg_temp.expect_error('proyección misma versión conflictiva',$q$UPDATE promotions.stock_projection SET availability='DISPONIBLE',source_message_id='stock-other' WHERE sku='fixture-stock'$q$,'P0001','PROJECTION_ORDER_AMBIGUOUS');
SELECT pg_temp.expect_error('message id reutilizado conflictivo',$q$UPDATE promotions.stock_projection SET availability='DISPONIBLE' WHERE sku='fixture-stock'$q$,'P0001','PROJECTION_MESSAGE_CONFLICT');
INSERT INTO promotions.price_projection(sku,channel_id,snapshot,source_occurred_at,source_message_id)
 VALUES('fixture-price','RETAIL','{}','2026-10-03','price-1');
SELECT pg_temp.expect_error('timestamp ambiguo sin versión',$q$UPDATE promotions.price_projection SET source_message_id='price-2' WHERE sku='fixture-price'$q$,'P0001','PROJECTION_ORDER_AMBIGUOUS');

INSERT INTO promotions.inbox(message_id,handler,envelope) VALUES('fixture-msg','consume',
 '{"message_id":"fixture-msg","schema_version":1,"occurred_at":"2026-10-03T00:00:00Z","correlation_id":"opaque","producer":"ventas-svc","kind":"command","name":"promotions.coupon.consumption.requested","data":{}}');
SELECT pg_temp.expect_error('inbox deduplica',$q$INSERT INTO promotions.inbox SELECT message_id,handler,envelope,received_at,completed_at,result FROM promotions.inbox WHERE message_id='fixture-msg'$q$,'23505');
SELECT pg_temp.assert_true('inbox misma entrega devuelve false',NOT promotions.fn_begin_inbox(
 (SELECT envelope FROM promotions.inbox WHERE message_id='fixture-msg'),'consume'));
SELECT pg_temp.expect_error('inbox id con otro contenido',$q$SELECT promotions.fn_begin_inbox(
 (SELECT jsonb_set(envelope,'{data}','{"other":true}') FROM promotions.inbox WHERE message_id='fixture-msg'),'consume')$q$,'P0001','INBOX_MESSAGE_CONFLICT');
SELECT pg_temp.expect_error('envelope incompleto',$q$INSERT INTO promotions.inbox(message_id,handler,envelope) VALUES('incomplete','consume','{}')$q$,'23514');
UPDATE promotions.inbox SET completed_at=clock_timestamp(),result='{"ok":true}' WHERE message_id='fixture-msg';
SELECT pg_temp.expect_error('inbox resultado inmutable',$q$UPDATE promotions.inbox SET result='{"ok":false}' WHERE message_id='fixture-msg'$q$,'P0001','INBOX_RESULT_IMMUTABLE');
INSERT INTO promotions.outbox(message_id,schema_version,occurred_at,correlation_id,producer,kind,name,data)
 VALUES('fixture-result',1,now(),'opaque-correlation','promotions-svc','event','promotions.coupon.consumption.completed','{}');
SELECT pg_temp.expect_error('outbox deduplica',$q$INSERT INTO promotions.outbox(message_id,schema_version,occurred_at,correlation_id,producer,kind,name,data) VALUES('fixture-result',1,now(),'opaque-correlation','promotions-svc','event','promotions.coupon.consumption.completed','{}')$q$,'23505');
SELECT pg_temp.expect_error('outbox envelope inmutable',$q$UPDATE promotions.outbox SET data='{"changed":true}' WHERE message_id='fixture-result'$q$,'P0001','OUTBOX_ENVELOPE_IMMUTABLE');
SAVEPOINT atomic_unit;
INSERT INTO promotions.inbox(message_id,handler,envelope) SELECT 'fixture-atomic','consume',jsonb_set(envelope,'{message_id}','"fixture-atomic"') FROM promotions.inbox WHERE message_id='fixture-msg';
SELECT promotions.fn_consume_coupon('order-fixture-atomic','53000000-0000-0000-0000-000000000013',NULL,'MARKETPLACE','2026-10-03');
INSERT INTO promotions.outbox(message_id,schema_version,occurred_at,correlation_id,producer,kind,name,data)
 VALUES('fixture-atomic-result',1,now(),'opaque','promotions-svc','event','promotions.coupon.consumption.completed','{}');
ROLLBACK TO SAVEPOINT atomic_unit;
SELECT pg_temp.assert_true('rollback negocio inbox outbox',
 NOT EXISTS(SELECT 1 FROM promotions.coupon_uses WHERE order_id='order-fixture-atomic')
 AND NOT EXISTS(SELECT 1 FROM promotions.inbox WHERE message_id='fixture-atomic')
 AND NOT EXISTS(SELECT 1 FROM promotions.outbox WHERE message_id='fixture-atomic-result'));

SELECT json_build_object('assertions',count(*),'result','PASS') AS validation_result FROM assertions;
ROLLBACK;
