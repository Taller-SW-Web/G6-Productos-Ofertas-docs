-- SOLO SELECT, ejecutar con el rol de lectura autorizado del proyecto G6 identificado.
BEGIN READ ONLY;
SELECT current_database(), current_user, current_setting('server_version');
SELECT n.nspname, pg_get_userbyid(n.nspowner) AS owner
FROM pg_namespace n WHERE n.nspname IN
('bulk','catalog','combos','inventory','pricing','price_audit','promotions','taxonomy')
ORDER BY n.nspname;
SELECT c.conname, pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='inventory' AND t.relname='outbox_delivery'
ORDER BY c.conname;
SELECT destination, route_version, transport, count(*) AS rows
FROM inventory.outbox_delivery GROUP BY 1,2,3 ORDER BY 1,2,3;
SELECT has_table_privilege(current_user,'inventory.outbox_delivery','SELECT') AS can_select,
       has_table_privilege(current_user,'inventory.outbox_delivery','INSERT') AS can_insert,
       has_table_privilege(current_user,'inventory.outbox_delivery','UPDATE') AS can_update;
COMMIT;
