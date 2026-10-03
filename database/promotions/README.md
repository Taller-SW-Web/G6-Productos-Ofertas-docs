# Persistencia de promotions-svc — #53

Schema interno `promotions`, propiedad de Axel Cueva. Implementa la persistencia de SPEC-005, SPEC-006 y SPEC-007; no crea un backend HTTP ni un consumidor RabbitMQ.

## Archivos y ejecución

- `logical-model.md`: entidades, relaciones e invariantes.
- `physical-model.md`: diccionario, índices, transacciones y decisiones de contrato.
- `provision-runtime.sql`: preparación administrativa del rol de aplicación sin login ni membresía del owner.
- `migrations/0001_promotions_persistence.sql` y `0002_promotions_global_price_projection.sql`: una única historia activa, compatible con `database/migrate.py`; la segunda añade precio global/override sin editar la primera.
- `validation.sql`: assertions y fixtures con rollback.
- `tests/verify.py`: reproducción local, concurrencia y permisos; requiere un contenedor PostgreSQL desechable indicado explícitamente.
- `validation-report.md`: evidencia real de ejecución y pendientes.

Orden: administrador ejecuta `database/bootstrap.sql` y `provision-runtime.sql`; deployer ejecuta `python database/migrate.py promotions`; después se ejecuta `validation.sql`. La migración fue creada con Supabase CLI y trasladada a la numeración de cuatro dígitos del ejecutor común. No hay un segundo historial de Supabase en este repositorio.

Para verificar en una base local vacía:

```text
python database/promotions/tests/verify.py --container CONTENEDOR_LOCAL
```

La prueba usa el usuario administrador **solo del contenedor local**, verifica el owner/runtime y conserva los objetos del schema, sin fixtures comerciales. No pasar un proyecto compartido a esta prueba.

## Integración de aplicación

La conexión runtime usa un login independiente miembro de `po_promotions_runtime`; nunca del owner. Toda modificación de un agregado se hace en una transacción. Primero bloquear sus padres antes de cambiar hijos; para cupones, bloquear el cupón antes de su promoción. Aplicar `READ COMMITTED`, transacciones cortas y retry completo ante `40P01`/`40001` (no repetir una sentencia aislada).

`fn_consume_coupon` y `fn_restore_coupon` guardan historia y controlan cupos. El adaptador aplica inbox, cambio de negocio y outbox en **la misma transacción**, confirmando el mensaje de RabbitMQ después del commit. `fn_begin_inbox(envelope, handler)` devuelve true para la primera entrega, false para el duplicado idéntico y rechaza un ID reutilizado con otro contenido. Si devuelve false, usar el `result` previo. No publicar directamente en RabbitMQ antes del commit. Outbox conserva el envelope contractual; el publicador marca `published_at` únicamente después de confirmación del broker. Esto permite reentrega: el consumidor deduplica por `(message_id, handler)`.

Las funciones no deciden pagos, cancelación del pedido, stock ni monto comercial. El backend autentica, autoriza, valida referencias activas y verifica el snapshot comercial final con Ventas antes de consumir. El evento de consumo no contiene líneas/subtotal: SQL no puede reconstruirlos. Una consulta/validación positiva no reserva ni consume.

La aplicación debe tratar la excepción `COUPON_IDENTITY_MISMATCH` como conflicto, nunca como un segundo éxito. Un uso restituido permanece registrado y no vuelve a consumirse al reentregar la misma pareja pedido/cupón. La política de cancelación se captura al consumir, para que editar el cupón no reescriba pedidos anteriores.

No exponer este schema en Data API ni conceder acceso a `anon`/`authenticated`. No almacenar claves ni conexiones en estos archivos.

## Entrega compartida

El despliegue en Supabase está pendiente por decisión de Axel: reunir antes el SQL de **todo el sistema**. El #53 requiere además revisión de BD/QA, despliegue real y evidencia del proyecto objetivo. La prueba local no permite cerrar ese criterio.
