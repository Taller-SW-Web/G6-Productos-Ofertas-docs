# Inventario — baseline 0001 registrado y migración 0002

> Estado comprobado en Supabase compartido el **11/10/2026** (PostgreSQL **17.11**). No insertar un segundo baseline, no reejecutar 0001 y no modificar los registros históricos.

## 1. Registro real en Supabase

En `inventory.schema_migrations` están registradas estas versiones, con comprobación estructural satisfactoria de 24/24 en el postcheck conjunto con Promociones:

| Versión registrada | SHA-256 normalizado UTF-8/LF | Estado |
| --- | --- | --- |
| `0001_create_inventory.sql` | `b93267e287fbf9245881473beb53c1b5715f132b972348225f3786e2fe9cbb69` | Histórico del 03/10/2026; conservar |
| `0002_order_id_operaciones_disponibilidad.sql` | `fb34676d4583f6923d04ad2e86acd55857b4a7a63fe3c7b78a61b5ed1bbe148a` | Aplicado mediante Supabase SQL Editor el 11/10/2026 |

El repositorio incorpora **otra** migración de arranque:

- `datos/inventory-svc/migrations/0001_inventory_initial.sql`, SHA-256 `3f9db5f62391680a5fae6d16a77a86b67cf0b9d02837bf22c6b73890165bd0b8`.
- Se obtuvo de `datos/inventory-svc/migration.sql` retirando `BEGIN` y `COMMIT`; **no** es la versión identificada por el ledger histórico.
- No se recuperó el archivo original exacto `0001_create_inventory.sql`; por lo tanto **no está demostrada una identidad binaria entre ambos baselines**.

La aprobación 24/24 acredita las verificaciones estructurales especificadas por ese postcheck, no una comparación exhaustiva con un DDL histórico no localizado, ni pruebas funcionales de los microservicios.

## 2. Procedimiento para el Supabase compartido

El preflight constató que `reservations` e `inventory_operations` estaban vacías antes de `0002`. Se aprovisionó `po_inventory_runtime`, se retiró `EXECUTE` público de tres funciones de trigger y se ajustaron privilegios predeterminados de funciones. Se aplicó `0002` y quedó registrada con su checksum **en la misma transacción**. El postcheck final informó `APROBADO_ESTRUCTURAL` con 24/24 verificaciones correctas y ninguna fallida.

**No ejecutar de nuevo** los scripts 01, 02 ni las migraciones `0001` sobre esta instancia. Para consultar el estado:

```sql
SELECT version, checksum, applied_at
FROM inventory.schema_migrations
ORDER BY version;
```

## 3. Reproducibilidad sin falsificar el historial

`datos/deploy/migrate.py` reconoce **dos arranques alternativos, incompatibles entre sí**:

1. **Base nueva y vacía:** el ejecutor aplica `0001_inventory_initial.sql` y registra ese nombre y checksum, después aplica `0002`. Se requiere `po_inventory_runtime` correctamente aprovisionado **antes** de ejecutar Inventario; usar `datos/inventory-svc/provision-runtime.sql` con credenciales administrativas y autorización.
2. **Base restaurada con baseline legado:** solo se acepta `0001_create_inventory.sql` si su checksum coincide exactamente con el histórico; se comprueba un conjunto de invariantes estructurales según esté presente o no `0002`. El ejecutor **omite** `0001_inventory_initial.sql`, nunca crea un alias en el ledger y solo aplica versiones nuevas faltantes.

El ejecutor detiene la ejecución ante checksum alterado, doble baseline, esquema incoherente o ausencia del baseline en una base poblada. El soporte del baseline legado es una compatibilidad operacional acotada al registro verificado, **no** una certificación de equivalencia completa de las dos migraciones 0001.

Para inspeccionar el SQL generado **sin conectarse**:

```powershell
py datos/deploy/migrate.py inventory --render-sql
```

La implementación y las pruebas locales del runner no acreditan despliegue ni pruebas E2E del backend. Mantener pendiente la recuperación del DDL 0001 exacto si se exige reconstrucción histórica completa.
