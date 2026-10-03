# Evidencia local — pricing-svc / #55

Fecha: 2026-10-03 (America/Bogota). Estado: **PASS local; Supabase y revisión pendientes**.

Motor observado: `PostgreSQL 18.3 (PGlite 0.5.8) on wasm32-unknown-emscripten, compiled by emcc (Emscripten gcc/clang-like replacement + linker emulating GNU ld) 3.1.74 (1092ec30a3fb1d46b1782ff1b4db5094d3d06ae5), 32-bit`. Runtime PGlite 0.5.8/WASM en memoria, aislado y sin credenciales ni datos comerciales. Base del checkout: `6d2c739ef27fdb635ae6a0a95d92e0f36a4db5d3`; correcciones de revisión sin commit al ejecutar. El checksum identifica el SQL exacto probado.

| Archivo | SHA-256 UTF-8 sin BOM / LF |
|---|---|
| `migrations/0001_create_pricing.sql` | `5a3590e1d5149d081d491c4919ec9bab916ae892998b10aecdeb2087b0b6a98b` |
| `validation.sql` | `844e5ea63c291ca973bb6d18dd2ffbd69b1059ae8b9db1e727dbc72826f1d46f` |

## Ejecución y resultados

1. Instancia PostgreSQL nueva; ejecutar bootstrap oficial y provisionar roles runtime de pruebas sin privilegios administrativos.
2. Solo para Pricing: instalar btree_gist en extensions y dar USAGE a po_pricing_owner. Es preparación administrativa externa a la migración.
3. Aplicar migración dentro de BEGIN/COMMIT con SET LOCAL ROLE del owner.
4. Ejecutar validation.sql dos veces; comprobar conteos antes/después en cada tabla.
5. Probar ledger/checksum en SQL local (modelo del mecanismo), índice faltante, FK de prueba hacia taxonomy y DDL que falla dentro de transacción.

| Prueba | Resultado |
|---|---|
| `migration_clean_isolated` | PASS |
| `negative_commit_version_without_snapshot` (COMMIT rechazado con 23514; cero filas persistidas) | PASS |
| `validation_1_and_no_fixtures` | PASS |
| `validation_2_and_no_fixtures` | PASS |
| `ledger_checksum_replay_model` | PASS |
| `negative_missing_index` | PASS |
| `negative_fk_other_schema` | PASS |
| `failed_transaction_rollback` | PASS |
| `runner_bd_root_and_manifest_generation` (cliente capturado) | PASS |

Grupos de assertions de validation.sql:

- estructura, tipos, constraints, FK globales, indices, permisos y enums: PASS.
- timestamps, triggers y aislamiento del runtime: PASS.
- objetivo, CAS, avance sin snapshot rechazado y avance con snapshot atómico aceptado, dinero, as-of, vigencias/programaciones, parcial, inbox/outbox atomicos: PASS.
- runtime escribe con triggers/constraints; sin DELETE/TRUNCATE/DDL: PASS.

Tablas: `bulk_price_jobs`, `bulk_price_rows`, `inbox`, `outbox`, `price_validities`, `prices`, `scheduled_prices`. Cero fixtures persistidos tras ROLLBACK. Resultados completos: [local-validation.json](evidence/local-validation.json).

## Límites de esta evidencia

No se ejecutó `database/migrate.py` con psql ni contra un servidor remoto; el check de ledger comprueba SQL/identidad de checksum, no certifica el cliente de despliegue. Tampoco conexiones concurrentes, API/broker o almacenamiento de archivos real. El despliegue Supabase **no se realizó**; el PR asociado es [#81](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/pull/81), con revisión BD/QA pendiente. Los issues #55 y #56 siguen pendientes de cierre hasta acreditar la ejecución real en el servidor objetivo.

## Reproducción en servidor objetivo

Con roles/runtime/prerequisites provisionados y conexión configurada fuera de Git:

```powershell
python database/migrate.py pricing --root bd
psql -X -v ON_ERROR_STOP=1 -f bd/pricing/validation.sql
python database/migrate.py pricing --root bd
```

Registrar server_version, commit y manifiesto/checksum del ledger. Utilizar una base de pruebas aislada para fixtures/escenarios de retención; no limpiar schemas compartidos. Extensión/roles se provisionan por infraestructura; no usar un login administrador como runtime. Para el método embebido empleado aquí, [PGlite](https://pglite.dev/docs/about) ejecuta PostgreSQL/WASM y [su catálogo](https://pglite.dev/extensions/) publica btree_gist.

## Compatibilidad final con el ejecutor

Se invocó main() de migrate.py capturando subprocess, sin abrir conexión: `--root bd` selecciona el historial del contexto sin cambiar el ejecutor común; SET ROLE, versión/checksum, ledger, secuencia de aplicación y encoding UTF-8 resultaron correctos. Esta verificación de generación **no** es una ejecución psql ni un despliegue.

## Checklist de entrega

- [x] PR asociado: [#81](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/pull/81).
- [x] Validación local embebida; alcance descrito arriba.
- [ ] Ejecutar migrate.py mediante psql en el proyecto Supabase autorizado.
- [ ] Ejecutar validation.sql contra ese servidor y repetir migrate.py sin cambios.
- [ ] Registrar proyecto/entorno, server_version, commit, ledger/checksums y resultados sin secretos.
- [ ] Revisión BD/QA para cerrar el issue.

## Servidor objetivo identificado

- Proyecto: **Módulo de Productos y Ofertas**.
- Project Reference: `slzglmtiyrzygpkiuthf`.
- Project URL: `https://slzglmtiyrzygpkiuthf.supabase.co` (API; no es la conexión PostgreSQL).
- Entorno declarado: Desarrollo / Staging; clasificación exacta por confirmar.
- Conexión directa indicada: host `db.slzglmtiyrzygpkiuthf.supabase.co`, puerto `5432`, base `postgres`, usuario `postgres`, SSL `require`.
- DNS observado: el host directo publica una dirección IPv6 (AAAA).

No se abrió conexión ni se desplegó SQL. En esta sesión no se encontró psql/Supabase CLI en PATH, connector MCP Supabase ni autenticación PostgreSQL configurada. Falta configurar el acceso fuera de Git. Si se necesita pooler session, obtener su host/puerto/usuario exactos de Connect; no reutilizar el host directo con puerto 6543. El ejecutor común requiere psql y una conexión PostgreSQL autenticada; no se ha probado mediante un token de API.

Antes de aplicar migraciones, consultar el ledger real, tablas, ownership, roles y extensión. Si 0001 ya está aplicada, conservar su checksum publicado y preparar la corrección en una nueva versión; no editar el historial aplicado.
