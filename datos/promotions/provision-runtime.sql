-- Preparación administrativa; sin credenciales. Ejecutar antes de la migración.
BEGIN;
DO $runtime$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='po_promotions_runtime') THEN
    CREATE ROLE po_promotions_runtime NOLOGIN NOSUPERUSER NOCREATEDB
      NOCREATEROLE NOREPLICATION NOBYPASSRLS;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='po_promotions_runtime'
      AND (rolcanlogin OR rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls))
      OR EXISTS (SELECT 1 FROM pg_auth_members m JOIN pg_roles r ON r.oid=m.member
                 WHERE r.rolname='po_promotions_runtime') THEN
    RAISE EXCEPTION 'Runtime tiene atributos o membresías inesperados; revisar sin reasignar';
  END IF;
END
$runtime$;
COMMIT;
