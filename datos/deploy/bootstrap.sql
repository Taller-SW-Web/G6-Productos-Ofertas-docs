-- Ejecutar únicamente con el administrador autorizado del proyecto.
BEGIN;
DO $bootstrap$
DECLARE s text; r text;
BEGIN
  FOREACH s IN ARRAY ARRAY['taxonomy','catalog','pricing','price_audit','promotions','combos','inventory','bulk'] LOOP
    r := 'po_' || s || '_owner';
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION', r);
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname=r AND (rolcanlogin OR rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls)) THEN
      RAISE EXCEPTION 'Owner % tiene atributos inesperados; revisar configuración', r;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname=s AND pg_get_userbyid(nspowner)<>r) THEN
      RAISE EXCEPTION 'Schema % ya existe con otro owner; revisar, no reasignar automáticamente', s;
    END IF;
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I AUTHORIZATION %I', s, r);
    EXECUTE format('REVOKE ALL ON SCHEMA %I FROM PUBLIC', s);
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC', r, s);
  END LOOP;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'taxonomy_app') THEN
    EXECUTE 'CREATE ROLE taxonomy_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM pg_roles
    WHERE rolname = 'taxonomy_app'
      AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls)
  ) OR pg_has_role('taxonomy_app', 'po_taxonomy_owner', 'MEMBER') THEN
    RAISE EXCEPTION 'Runtime taxonomy_app tiene privilegios inesperados; revisar configuracion';
  END IF;
END
$bootstrap$;
COMMIT;
