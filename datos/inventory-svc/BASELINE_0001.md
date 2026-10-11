# Baseline seguro de Inventario

**No aplicar migraciones en Supabase compartido antes de verificar el estado real y tener una copia de ensayo.**

El esquema inventory se creó previamente desde `datos/inventory-svc/migration.sql` sin estar necesariamente en `inventory.schema_migrations`. `0001_inventory_initial.sql` es el mismo DDL histórico, retirando únicamente BEGIN/COMMIT para cumplir el runner; NO debe ejecutarse encima del esquema ya existente.

## Base vacía

Ejecutar el runner oficial `py datos/deploy/migrate.py inventory` con el rol autorizado. El runner aplica 0001 y 0002 consecutivamente, guardando el SHA-256 calculado en cada paso.

## Base preexistente

1. Comprobar con consultas **solo lectura** la presencia de tablas, tipos, funciones, índices y datos, y que el esquema coincide con el DDL histórico. Confirmar si existe `inventory.schema_migrations` y sus filas. Guardar respaldo/restauración de prueba.
2. Antes del baseline verificar que `order_id` sigue siendo UUID. Nunca insertar una fila ficticia si la estructura difiere o hay una migración parcial.
3. Obtener el checksum exacto (normalización UTF-8 LF) de `0001_inventory_initial.sql`, conforme a `migrate.py`.
4. Tras aprobación de BD y solo en un entorno de ensayo, registrar la línea base `0001_inventory_initial.sql` y su checksum real en `inventory.schema_migrations`, con el rol owner, **sin ejecutar el DDL de 0001 de nuevo**. Este acto no sustituye la validación de igualdad del esquema.
5. Ejecutar el runner para aplicar solo 0002, validar el resultado, rollback ante fallos y revisar privilegios del runtime. Repetir ensayo antes de producción.

El runner bloquea explícitamente Inventario con tablas preexistentes y ledger vacío, por diseño. No automatizar el registro de baseline sobre la instancia compartida.
