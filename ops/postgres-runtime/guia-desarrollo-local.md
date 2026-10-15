# Manual para conectar los microservicios a PostgreSQL en desarrollo

Este manual sirve para guardar la configuración local de cada microservicio y comprobar su conexión con `psql`. El acceso se aprovisionó en el proyecto Supabase `slzglmtiyrzygpkiuthf`, usando el **Session Pooler**. No habilita por sí solo la conexión de una aplicación NestJS.

## 1. Guarda una configuración por microservicio

En el clon local del repositorio Backend, coloca el archivo del servicio en:

```text
backend/apps/<servicio>/.env.local
```

Ejemplos:

```text
backend/apps/taxonomy-svc/.env.local
backend/apps/price-audit-svc/.env.local
```

El `.gitignore` del Backend ignora `.env.local`. Compruébalo antes de compartir cambios y nunca hagas commit de ese archivo. Si una persona mantiene dos servicios (Vera o Castilla), conserva dos archivos separados, uno por servicio y por identidad.

Crea el archivo local con las variables de la sección 2 y reemplaza los valores propios del servicio y del equipo. Recibe la contraseña del servicio por el canal privado designado; no la publiques en GitHub, chats, tickets, capturas ni comandos.

**No copies sin cambios la ruta `PGSSLROOTCERT` de otra persona.** La ruta del certificado depende del equipo. Guarda el certificado raíz descargado del proyecto en una ruta local legible solo por tu usuario y cambia esa variable para que apunte a tu propio archivo. Ejemplos:

- Windows: `C:\Users\<tu-usuario>\AppData\Local\G6\PostgresRuntime\supabase-server-root.crt`
- Linux: `/home/<tu-usuario>/.local/share/G6/PostgresRuntime/supabase-server-root.crt`

El certificado es público; la contraseña y el archivo `.env.local` son privados.

## 2. Completa los valores del servicio

Estos son los parámetros del Session Pooler ya verificados:

| Variable | Valor |
|---|---|
| `PGHOST` | `aws-0-sa-east-1.pooler.supabase.com` |
| `PGPORT` | `5432` |
| `PGDATABASE` | `postgres` |
| `PGUSER` | El usuario de la tabla siguiente, incluido el sufijo `.slzglmtiyrzygpkiuthf` |
| `PGPASSWORD` | La contraseña privada asignada a ese usuario |
| `PGSSLMODE` | `verify-full` |
| `PGSSLROOTCERT` | Ruta absoluta al certificado raíz en tu equipo |
| `G6_DATABASE_SCHEMA` | El schema propio indicado en la tabla |
| `G6_CONNECTION_MODE` | `session` |

| Servicio | Schema | `PGUSER` |
|---|---|---|
| `taxonomy-svc` | `taxonomy` | `taxonomy_dev_login.slzglmtiyrzygpkiuthf` |
| `catalog-svc` | `catalog` | `catalog_dev_login.slzglmtiyrzygpkiuthf` |
| `pricing-svc` | `pricing` | `pricing_dev_login.slzglmtiyrzygpkiuthf` |
| `price-audit-svc` | `price_audit` | `price_audit_dev_login.slzglmtiyrzygpkiuthf` |
| `promotions-svc` | `promotions` | `promotions_dev_login.slzglmtiyrzygpkiuthf` |
| `combos-svc` | `combos` | `combos_dev_login.slzglmtiyrzygpkiuthf` |
| `inventory-svc` | `inventory` | `inventory_dev_login.slzglmtiyrzygpkiuthf` |
| `bulk-svc` | `bulk` | `bulk_dev_login.slzglmtiyrzygpkiuthf` |

Usa solo la identidad del servicio que estás probando. En la conexión de Supavisor, `PGUSER` lleva el sufijo del proyecto; después de autenticar, PostgreSQL muestra el rol base (por ejemplo, `taxonomy_dev_login`) como `current_user`. Eso es normal.

## 3. Prueba la conexión con `psql`

`psql` no carga `.env.local` automáticamente. Para la prueba, exporta las variables no secretas en una sesión temporal de PowerShell y deja que `psql -W` solicite la contraseña sin mostrarla. Sustituye usuario, schema y ruta del certificado por los de tu servicio y equipo:

```powershell
$env:PGHOST = 'aws-0-sa-east-1.pooler.supabase.com'
$env:PGPORT = '5432'
$env:PGDATABASE = 'postgres'
$env:PGUSER = 'taxonomy_dev_login.slzglmtiyrzygpkiuthf'
$env:PGSSLMODE = 'verify-full'
$env:PGSSLROOTCERT = 'C:\Users\<tu-usuario>\AppData\Local\G6\PostgresRuntime\supabase-server-root.crt'
psql -W -X
```

En el prompt de `psql`, introduce la contraseña correspondiente y ejecuta una consulta de solo lectura. Cambia `taxonomy` si estás probando otro servicio:

```sql
SELECT current_user,
       current_database(),
       has_schema_privilege(current_user, 'taxonomy', 'USAGE') AS can_use_schema,
       has_schema_privilege(current_user, 'taxonomy', 'CREATE') AS can_create_objects;
```

El resultado esperado es tu rol (`<servicio>_dev_login`), la base `postgres`, `can_use_schema = true` y `can_create_objects = false`. Sal con `\q`.

Para comprobar los permisos de tablas sin modificar datos, ejecuta esta consulta en `psql`. Cambia `taxonomy` por tu schema:

```sql
SELECT n.nspname AS schema_name,
       count(*) AS relations,
       count(*) FILTER (WHERE has_table_privilege(current_user, c.oid, 'SELECT')) AS can_select,
       count(*) FILTER (WHERE has_table_privilege(current_user, c.oid, 'INSERT')) AS can_insert,
       count(*) FILTER (WHERE has_table_privilege(current_user, c.oid, 'UPDATE')) AS can_update,
       count(*) FILTER (WHERE has_table_privilege(current_user, c.oid, 'DELETE')) AS can_delete
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'taxonomy'
  AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
GROUP BY n.nspname;
```

El resultado esperado es que las cuatro columnas `can_*` coincidan con `relations`. Esta comprobación consulta los permisos; no ejecuta operaciones CRUD.

## 4. Carga automática desde NestJS

NestJS no busca automáticamente archivos `.env.local` dentro de cada aplicación. Para cargarlos al iniciar, añade `--env-file` al script de desarrollo de cada servicio en `backend/package.json`. Por ejemplo:

```json
"start:dev:taxonomy-svc": "nest start taxonomy-svc --watch --env-file apps/taxonomy-svc/.env.local"
```

Repite el patrón para cada servicio, cambiando el nombre del proyecto y la ruta al archivo correspondiente. Ejecuta `npm run start:dev:taxonomy-svc` desde la raíz de `backend`; la ruta de `--env-file` es relativa al directorio actual. El Nest CLI carga esas variables en `process.env` antes de iniciar la aplicación.

Cargar variables no crea por sí solo un pool ni conecta la aplicación. El servicio debe tener un cliente PostgreSQL configurado para usar `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PGSSLMODE` y `PGSSLROOTCERT`.

Mantén la configuración Oracle de Inventory separada; no la reemplaces al añadir la conexión PostgreSQL.

## 5. Alcance de permisos y uso de datos

- Cada login tiene `SELECT`, `INSERT`, `UPDATE` y `DELETE` sobre las relaciones de su propio schema y no sobre los otros schemas G6. También tiene permisos de uso de secuencias para inserciones. No tiene permiso `CREATE` en el schema.
- Los permisos aplican a las relaciones actuales y a futuras tablas y secuencias creadas por el owner correspondiente.
- Inventory ahora tiene CRUD completo sobre las 16 relaciones actuales de `inventory`; esto reemplaza la matriz anterior de permisos parciales.
- CRUD permite modificar y borrar datos existentes. La guía solo propone comprobaciones de permisos de lectura; coordina antes de operar sobre datos compartidos.
- No uses `inventory_app`, `po_inventory_runtime`, cuentas `seed_*`, owners ni credenciales administrativas. Esto no cambia Oracle ni RabbitMQ.
- No cambies `PGSSLMODE` a `disable` para resolver errores de certificado. Corrige `PGSSLROOTCERT` para que señale al CA correcto y existente en tu equipo.

## 6. Errores comunes

| Mensaje o síntoma | Revisión |
|---|---|
| `password authentication failed` | Usa la contraseña del usuario indicado en `PGUSER`; no mezcles credenciales entre servicios. |
| No encuentra el certificado o falla la validación SSL | Revisa que `PGSSLROOTCERT` sea una ruta absoluta válida en tu equipo y que apunte al certificado raíz del proyecto. |
| No conecta con el servidor | Confirma `PGHOST`, puerto `5432`, acceso de red al Session Pooler y que el proyecto sea `slzglmtiyrzygpkiuthf`. |
| `can_use_schema = false` | Detén la prueba y avisa al responsable de infraestructura; no te concedas permisos manualmente. |
