# Despliegue por schema en Supabase — issue #49

Estado: procedimiento verificable localmente; no se ha ejecutado contra un proyecto Supabase compartido. Cada owner ejecuta sus migraciones; DevOps mantiene este procedimiento. [Arquitectura §7–8](../Arquitectura.md) y [modelo conceptual](../Modelo_Conceptual.md) gobiernan el aislamiento.

## 1. Convenciones y responsabilidades

| Schema | Servicio / responsable |
|---|---|
| taxonomy | taxonomy-svc / Leonardo Lopez |
| catalog | catalog-svc / Gabriel Poma |
| pricing | pricing-svc / Leonardo Vera |
| price_audit | price-audit-svc / Leonardo Vera |
| promotions | promotions-svc / Axel Cueva |
| combos | combos-svc / Marco Castilla |
| inventory | inventory-svc / Miguel Taco |
| bulk | bulk-svc / Marco Castilla |

`read_model` pertenece al gateway y queda fuera de estos ocho contextos. No crear tablas de otro servicio, FK entre schemas, joins operativos entre contextos ni grants cruzados. Los IDs externos son referencias; cada servicio mantiene sus proyecciones y outbox/inbox cuando corresponda.

### Flujo de diseño y derivación

```text
fuentes funcionales y contractuales
        ↓
Modelo_Conceptual.md
        ↓
logical-model.md
        ↓
physical-model.md
        ↓
migrations/
        ↓
validation.sql
```

### Entregables por bounded context

Cada bounded context debe contar con los siguientes cuatro entregables documentales y de persistencia:

1. `logical-model.md`: modelo lógico puro (entidades, atributos, cardinalidades, reglas de negocio, sin tipos ni sintaxis PostgreSQL).
2. `physical-model.md`: modelo físico detallado sobre PostgreSQL/Supabase (tablas, columnas, tipos, constraints, índices, triggers).
3. `migrations/`: scripts DDL ordenados correlativamente (`0001_*.sql`, etc.) ejecutables desde cero.
4. `validation.sql`: script de validación determinista que comprueba constraints, aislamiento y ausencia de violaciones.

Mientras este repositorio contiene los entregables de BD, guardar en `database/<schema>/` (o la carpeta asignada al servicio en `bd/`): `logical-model.md`, `physical-model.md`, `migrations/0001_descripcion.sql` y `validation.sql`. Al incorporar el backend, conservar los mismos archivos y versiones en `infrastructure/persistence/` del servicio (Arquitectura §4). No mantener dos historiales activos ni volver a ejecutar una versión trasladada.

Versiones de cuatro dígitos consecutivas desde 0001, un cambio por archivo, SQL PostgreSQL UTF-8, nombres snake_case y objetos calificados con schema. El checksum usa texto UTF-8 sin BOM y saltos LF, para que Windows/Linux produzcan el mismo resultado. No editar ni borrar migraciones aplicadas. Cambios destructivos requieren estrategia expand/contract, respaldo y coordinación de versión. Cada archivo es transaccional: no BEGIN/COMMIT, VACUUM ni CREATE INDEX CONCURRENTLY. Para cambios no transaccionales se necesita un procedimiento independiente revisado, no introducirlos en este ejecutor.

## 2. Preparación única del proyecto

El administrador obtiene la conexión desde **Connect** del proyecto Supabase. Para migraciones usar conexión directa, o pooler **session** cuando la red solo permite IPv4; no pooler transaction. Copiar host, puerto y usuario exactamente del panel, incluidos los sufijos del usuario. No deducir hostnames. [Conexiones oficiales](https://supabase.com/docs/guides/database/connecting-to-postgres).

Instalar Python 3 y cliente `psql` PostgreSQL 17; comprobar `python --version`, `psql --version`. Docker con `postgres:17` permite reproducir las verificaciones en un entorno limpio. Supabase puede tener otra versión: comprobar `SHOW server_version` y repetir validaciones con esa versión antes del despliegue.

El administrador ejecuta `bootstrap.sql` una vez con un usuario autorizado para crear roles/schemas. Crea ocho roles `po_<schema>_owner` NOLOGIN, ocho schemas sin acceso PUBLIC y el rol runtime `taxonomy_app` sin password versionado. Asigna a cada deployer un login independiente, miembro únicamente de su owner; configura su contraseña fuera de Git. Para un login recién creado y sin membresías previas:

```sql
GRANT po_promotions_owner TO deploy_promotions;
```

No entregar el login administrador a los servicios. El runtime tiene otro login, sin membresía del owner, con USAGE del schema y solo permisos explícitos sobre sus tablas/secuencias y funciones de aplicación. Después de crear las tablas, el owner declara dichos grants en una migración revisada. Revocar EXECUTE a PUBLIC en cada función y concederlo únicamente donde corresponda. Evitar SECURITY DEFINER salvo necesidad justificada con search_path fijo.

No añadir estos schemas internos a **Exposed schemas** de la Data API; no otorgar acceso a `anon` ni `authenticated`. Si una futura capacidad requiere Data API, diseñar RLS/policies/grants como cambio explícito antes de exponerla. [Roles de PostgreSQL en Supabase](https://supabase.com/docs/guides/database/postgres/roles).

## 3. Configuración local sin secretos en Git

Configurar variables en la sesión o gestor de secretos del entorno. Nunca pegar contraseñas/URLs con contraseña en PR, reportes, capturas o comandos versionados.

| Variable | Valor / uso |
|---|---|
| PGHOST | Host copiado de Connect |
| PGPORT | Puerto de conexión directa/session |
| PGDATABASE | Base indicada en Connect (normalmente postgres) |
| PGUSER | Login deployer propio, usuario exacto del panel |
| PGPASSWORD | Contraseña del deployer; solo entorno de proceso |
| PGSSLMODE | verify-full con CA confiable configurada |
| PGSSLROOTCERT | Ruta local al certificado CA requerido por el proyecto |

Alternativa: `PGPASSFILE` apuntando a un archivo local protegido fuera del repositorio. No imprimir el entorno. En desarrollo local aislado se admite `PGSSLMODE=disable`; nunca trasladarlo al proyecto remoto. Añadir `.env*`, `*.pgpass` y certificados privados a exclusiones si se generan localmente. El ejecutor no necesita tokens de GitHub ni claves de la API de Supabase.

## 4. Desplegar desde cero y actualizar

1. Confirmar destino con `psql -X -c "SELECT current_database(), current_user, version();"`. Verificar permisos del deployer y schema propio. Leer el diff y `physical-model.md`, obtener revisión del SQL.
2. Ejecutar desde la raíz `python database/migrate.py <schema>`. Para taxonomy: `python database/migrate.py taxonomy`. Sustituir solo el schema propio. Si `psql` no está en PATH, agregar `--psql RUTA_AL_EJECUTABLE`.
3. El ejecutor valida orden, toma un advisory lock por schema, hace SET ROLE del owner y registra versión, SHA-256 y fecha en `<schema>.schema_migrations`. Aplica cada archivo y su registro en la misma transacción. En reejecución comprueba checksum y omite versiones ya aplicadas; un historial alterado/faltante o un error SQL detiene el proceso. No se avanza a la siguiente versión ni se arranca el nuevo servicio si falla.
4. Ejecutar `psql -X -v ON_ERROR_STOP=1 -f database/<schema>/validation.sql`. Para taxonomy: `psql -X -v ON_ERROR_STOP=1 -f database/taxonomy/validation.sql`. Las comprobaciones deben usar ROLLBACK para fixtures; no introducir seeds comerciales permanentes. Revisar tanto constraints/índices como reglas y ausencia de FK/grants externos.
5. Consultar `SELECT version, checksum, applied_at FROM <schema>.schema_migrations ORDER BY version;`; para taxonomy: `SELECT version, checksum, applied_at FROM taxonomy.schema_migrations ORDER BY version;`. Comparar con el manifiesto del ejecutor y commit desplegado. Registrar versión del servidor, commit, schema, checksums, resultado y fecha en evidencia sin secretos. Un exit code 0 confirma la ejecución; un archivo SQL que solo muestra datos sin assertions no constituye validación.
6. Arrancar la versión compatible del servicio con su login runtime y hacer smoke test. El owner de cada servicio controla su despliegue.

Los ocho contextos son independientes y pueden desplegarse en cualquier orden después del bootstrap. Una migración no espera tablas de otro schema. Integración de eventos/proyecciones se coordina por contrato y versión, no por FK. Dentro de cada schema el orden es estricto. Ante fallo de validación, detener el arranque; corregir con una migración nueva o restaurar el entorno según el respaldo acordado. No hacer rollback destructivo improvisado sobre datos compartidos.

## 5. Reproducción en limpio

Crear una base local desechable sin datos comerciales. Ejecutar bootstrap, todas las migraciones propias, validation.sql, repetir el ejecutor (sin cambios) y comparar ledger/objetos con el primer despliegue. Probar también una migración inválida: sus tablas y ledger no deben persistir. No limpiar el Supabase compartido para reproducir desde cero; utilizar otro proyecto/base autorizado. [Evidencia local del mecanismo](validation-report.md).

Para prueba local con un contenedor PostgreSQL ya inicializado se admite `python database/migrate.py <schema> --container NOMBRE`; por ejemplo `python database/migrate.py taxonomy --container NOMBRE`. Usa exclusivamente `docker exec -i NOMBRE psql` y el usuario administrador local del contenedor para SET ROLE. Este modo es de validación local, no una receta para credenciales de producción. Copiar fixtures de prueba a una carpeta aislada y pasar `--root RUTA`; el árbol versionado solo incluye migraciones reales de cada owner.

## 6. Criterio de entrega de cada owner

PR con modelo físico, migraciones, constraints/índices, validation.sql, evidencia en limpio y repetición, aislamiento probado y evidencia del proyecto objetivo cuando tenga acceso. Un despliegue local no acredita un despliegue Supabase. La [entrega local de #53](promotions/README.md) se valida por separado; Axel ya dispone de acceso, pero indicó esperar a reunir el SQL de **todo el sistema** antes del despliegue compartido.
