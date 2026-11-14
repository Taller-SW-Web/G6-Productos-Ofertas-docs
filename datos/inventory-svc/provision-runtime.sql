-- G6 Inventory | aprovisionamiento administrativo para instalaciones nuevas.
-- Se ejecuta una vez con rol con permiso para CREATE ROLE y ALTER DEFAULT PRIVILEGES.
-- Los grants de operaciones son responsabilidad del backend/migraciones posteriores.
-- No ejecutarlo nuevamente en Supabase compartido: provisionamiento 01 ya aplicado.
BEGIN;
DO $provision$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='po_inventory_runtime') THEN
    CREATE ROLE po_inventory_runtime NOLOGIN NOSUPERUSER NOCREATEDB
      NOCREATEROLE NOREPLICATION NOBYPASSRLS;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles
             WHERE rolname='po_inventory_runtime'
               AND (rolcanlogin OR rolsuper OR rolcreatedb OR rolcreaterole
                    OR rolreplication OR rolbypassrls))
    OR pg_has_role('po_inventory_runtime','po_inventory_owner','MEMBER') THEN
    RAISE EXCEPTION 'po_inventory_runtime no satisface privilegio minimo';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_namespace
        WHERE nspname='inventory'
          AND pg_get_userbyid(nspowner)='po_inventory_owner') THEN
    RAISE EXCEPTION 'inventory debe existir con owner po_inventory_owner';
  END IF;
END $provision$;
GRANT USAGE ON SCHEMA inventory TO po_inventory_runtime;
REVOKE CREATE ON SCHEMA inventory FROM po_inventory_runtime;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA inventory FROM PUBLIC;
-- Importante: no limitar este REVOKE a IN SCHEMA; el default global prima.
ALTER DEFAULT PRIVILEGES FOR ROLE po_inventory_owner
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
DO $verify$
BEGIN
  IF NOT has_schema_privilege('po_inventory_runtime','inventory','USAGE')
    OR has_schema_privilege('po_inventory_runtime','inventory','CREATE')
    OR EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n
       ON n.oid=p.pronamespace
       CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
       WHERE n.nspname='inventory' AND a.grantee=0 AND a.privilege_type='EXECUTE') THEN
    RAISE EXCEPTION 'No se cumplieron las aserciones de aprovisionamiento';
  END IF;
END $verify$;
COMMIT;
