# Evidencia local — pricing-svc / #55

Fecha: 2026-10-03 (America/Bogota). Estado: **PASS local; Supabase y revisión pendientes**.

Motor observado: `PostgreSQL 18.3 (PGlite 0.5.8) on wasm32-unknown-emscripten, compiled by emcc (Emscripten gcc/clang-like replacement + linker emulating GNU ld) 3.1.74 (1092ec30a3fb1d46b1782ff1b4db5094d3d06ae5), 32-bit`. Runtime PGlite 0.5.8/WASM en memoria, aislado y sin credenciales ni datos comerciales. Base de fuentes: `26ce90332bf677b20e8350553ccd4c6e8af21bf1`; entregables nuevos sin commit al ejecutar. El checksum identifica el SQL exacto probado.

| Archivo | SHA-256 UTF-8 sin BOM / LF |
|---|---|
| `migrations/0001_create_pricing.sql` | `6a42f72fa0f92645a80ba193a5ad399fd4e4d3d1e9beededb25ea2b74e60d584` |
| `validation.sql` | `1c46925d51036622688f7d79db488999ec99eda774997c7e2892e4c8130c3df8` |

## Ejecución y resultados

1. Instancia PostgreSQL nueva; ejecutar bootstrap oficial y provisionar roles runtime de pruebas sin privilegios administrativos.
2. Solo para Pricing: instalar btree_gist en extensions y dar USAGE a po_pricing_owner. Es preparación administrativa externa a la migración.
3. Aplicar migración dentro de BEGIN/COMMIT con SET LOCAL ROLE del owner.
4. Ejecutar validation.sql dos veces; comprobar conteos antes/después en cada tabla.
5. Probar ledger/checksum en SQL local (modelo del mecanismo), índice faltante, FK de prueba hacia taxonomy y DDL que falla dentro de transacción.

| Prueba | Resultado |
|---|---|
| `migration_clean_isolated` | PASS |
| `validation_1_and_no_fixtures` | PASS |
| `validation_2_and_no_fixtures` | PASS |
| `ledger_checksum_replay_model` | PASS |
| `negative_missing_index` | PASS |
| `negative_fk_other_schema` | PASS |
| `failed_transaction_rollback` | PASS |

Grupos de assertions de validation.sql:

- estructura, tipos, constraints, FK globales, indices, permisos y enums: PASS.
- timestamps, triggers y aislamiento del runtime: PASS.
- objetivo, CAS, dinero, as-of, vigencias/programaciones, parcial, inbox/outbox atomicos: PASS.
- runtime escribe con triggers/constraints; sin DELETE/TRUNCATE/DDL: PASS.

Tablas: `bulk_price_jobs`, `bulk_price_rows`, `inbox`, `outbox`, `price_validities`, `prices`, `scheduled_prices`. Cero fixtures persistidos tras ROLLBACK. Resultados completos: [local-validation.json](evidence/local-validation.json).

## Límites de esta evidencia

No se ejecutó `database/migrate.py` con psql ni contra un servidor remoto; el check de ledger comprueba SQL/identidad de checksum, no certifica el cliente de despliegue. Tampoco conexiones concurrentes, API/broker o almacenamiento de archivos real. El despliegue Supabase **no se realizó**; no existe aprobación de BD/QA ni PR creado en esta entrega.

## Reproducción en servidor objetivo

Con roles/runtime/prerequisites provisionados y conexión configurada fuera de Git:

```powershell
python database/migrate.py pricing --root bd
psql -X -v ON_ERROR_STOP=1 -f bd/pricing/validation.sql
python database/migrate.py pricing --root bd
```

Registrar server_version, commit y manifiesto/checksum del ledger. Utilizar una base de pruebas aislada para fixtures/escenarios de retención; no limpiar schemas compartidos. Extensión/roles se provisionan por infraestructura; no usar un login administrador como runtime. Para el método embebido empleado aquí, [PGlite](https://pglite.dev/docs/about) ejecuta PostgreSQL/WASM y [su catálogo](https://pglite.dev/extensions/) publica btree_gist.

## Compatibilidad final con el ejecutor

Se revisó la actualización `fc771b9` de origin/vera: los cambios contractuales corresponden a Promociones y no alteran los DTO de estos contextos. Se invocó main() de migrate.py capturando subprocess, sin abrir conexión: `--root bd`, SET ROLE, versión/checksum, ledger, secuencia de aplicación y encoding UTF-8 resultaron correctos. Esta verificación de generación **no** es una ejecución psql ni un despliegue.
