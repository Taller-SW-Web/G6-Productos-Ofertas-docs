-- SOLO SELECT, ejecutar con el rol de lectura autorizado del proyecto slzglmtiyrzygpkiuthf.
BEGIN READ ONLY;
SELECT current_database(), current_user, current_setting('server_version');
SELECT n.nspname, pg_get_userbyid(n.nspowner) AS owner
FROM pg_namespace n WHERE n.nspname IN
('bulk','catalog','combos','inventory','pricing','price_audit','promotions','taxonomy')
ORDER BY n.nspname;
SELECT n.nspname AS schema_name, count(*)::int AS domain_tables
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('bulk','catalog','combos','inventory','pricing','price_audit','promotions','taxonomy')
  AND c.relkind IN ('r','p')
GROUP BY n.nspname ORDER BY n.nspname;
SELECT c.relname, pg_get_userbyid(c.relowner) AS table_owner, c.relrowsecurity AS rls_enabled
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='inventory' AND c.relname IN ('outbox','outbox_delivery','inbox')
ORDER BY c.relname;
SELECT c.conname, pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='inventory' AND t.relname='outbox_delivery'
ORDER BY c.conname;
SELECT i.indexname, i.indexdef
FROM pg_indexes i WHERE i.schemaname='inventory' AND i.tablename='outbox_delivery'
ORDER BY i.indexname;
SELECT t.tgname, pg_get_triggerdef(t.oid) AS definition
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='inventory' AND c.relname='outbox_delivery' AND NOT t.tgisinternal
ORDER BY t.tgname;
SELECT n.nspname AS schema_name, c.relname AS ledger_table
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('bulk','catalog','combos','inventory','pricing','price_audit','promotions','taxonomy')
  AND c.relkind IN ('r','p') AND c.relname ILIKE '%migrat%'
ORDER BY n.nspname,c.relname;
SELECT destination, route_version, transport, count(*) AS rows
FROM inventory.outbox_delivery GROUP BY 1,2,3 ORDER BY 1,2,3;
SELECT count(*)::int AS inventory_delivery_rows FROM inventory.outbox_delivery;
SELECT version, checksum, applied_at FROM inventory.schema_migrations ORDER BY version;
SELECT event_name, delivery_transport, published_at IS NULL AS pending, count(*)::int AS rows
FROM catalog.outbox GROUP BY 1,2,3 ORDER BY 1,2,3;
SELECT count(*)::int AS sku_identities FROM catalog.sku_identity;
SELECT count(*)::int AS active_commercial_skus
FROM catalog.sku_identity s
LEFT JOIN catalog.variants v ON v.id=s.variant_id
JOIN catalog.products p ON p.id=coalesce(s.product_id,v.product_id)
WHERE p.estado::text='ACTIVO'
  AND ((s.variant_id IS NOT NULL AND v.estado::text='ACTIVA')
       OR (s.variant_id IS NULL AND p.tiene_variantes=false));
SELECT has_table_privilege(current_user,'inventory.outbox_delivery','SELECT') AS can_select,
       has_table_privilege(current_user,'inventory.outbox_delivery','INSERT') AS can_insert,
       has_table_privilege(current_user,'inventory.outbox_delivery','UPDATE') AS can_update;
COMMIT;
