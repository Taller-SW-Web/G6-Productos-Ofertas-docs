# Persistencia de promotions-svc — #53

Schema interno `promotions`, propiedad de Axel Cueva. Implementa la persistencia de SPEC-005, SPEC-006 y SPEC-007; no crea un backend HTTP ni un consumidor RabbitMQ.

## Archivos y ejecución

- `logical-model.md`: entidades, relaciones e invariantes.
- `physical-model.md`: diccionario, índices, transacciones y decisiones de contrato.
- `provision-runtime.sql`: preparación administrativa del rol de aplicación sin login ni membresía del owner.
- `migrations/0001_promotions_persistence.sql`, `0002_promotions_global_price_projection.sql` y `0003_promotions_timestamps_and_delete_rules.sql`: historia única compatible con `bd/deploy/migrate.py`; 0002 añade precio global/override y 0003 completa timestamps/FK/triggers sin editar las versiones publicadas.
- `validation.sql`: assertions y fixtures con rollback.
- `tests/verify.py`: reproducción local, concurrencia y permisos; requiere un contenedor PostgreSQL desechable indicado explícitamente.
- `validation-report.md`: evidencia real de ejecución y pendientes.

Orden: administrador ejecuta `bd/deploy/bootstrap.sql` y `provision-runtime.sql`; deployer ejecuta `python bd/deploy/migrate.py promotions`; después se ejecuta `validation.sql`. La generación inicial utilizó Supabase CLI y se trasladó a la numeración de cuatro dígitos del ejecutor común; las correcciones posteriores se incorporan mediante nuevas migraciones versionadas. No hay un segundo historial de Supabase en este repositorio.

Para verificar en una base local vacía:

```text
python bd/promotions/tests/verify.py --container CONTENEDOR_LOCAL
```

La prueba usa el usuario administrador **solo del contenedor local**, verifica el owner/runtime y conserva los objetos del schema, sin fixtures comerciales. No pasar un proyecto compartido a esta prueba.

## Integración de aplicación

La conexión runtime usa un login independiente miembro de `po_promotions_runtime`; nunca del owner. Toda modificación de un agregado se hace en una transacción. Primero bloquear sus padres antes de cambiar hijos; para cupones, bloquear el cupón antes de su promoción. Aplicar `READ COMMITTED`, transacciones cortas y retry completo ante `40P01`/`40001` (no repetir una sentencia aislada).

`fn_consume_coupon` y `fn_restore_coupon` guardan historia y controlan cupos. El adaptador aplica inbox, cambio de negocio y outbox en **la misma transacción**, confirmando el mensaje de RabbitMQ después del commit. `fn_begin_inbox(envelope, handler)` devuelve true para la primera entrega, false para el duplicado idéntico y rechaza un ID reutilizado con otro contenido. Si devuelve false, usar el `result` previo. No publicar directamente en RabbitMQ antes del commit. Outbox conserva el envelope contractual; el publicador marca `published_at` únicamente después de confirmación del broker. Esto permite reentrega: el consumidor deduplica por `(message_id, handler)`.

Las funciones no deciden pagos, cancelación del pedido, stock ni monto comercial. El backend autentica, autoriza, valida referencias activas y verifica el snapshot comercial final con Ventas antes de consumir. El evento de consumo no contiene líneas/subtotal: SQL no puede reconstruirlos. Una consulta/validación positiva no reserva ni consume.

La aplicación debe tratar la excepción `COUPON_IDENTITY_MISMATCH` como conflicto, nunca como un segundo éxito. Un uso restituido permanece registrado y no vuelve a consumirse al reentregar la misma pareja pedido/cupón. La política de cancelación se captura al consumir, para que editar el cupón no reescriba pedidos anteriores.

No exponer este schema en Data API ni conceder acceso a `anon`/`authenticated`. No almacenar claves ni conexiones en estos archivos.

## Límites del modelo para Hito 2

El modelo deriva de SPEC-005/006/007, OpenAPI, AsyncAPI, Arquitectura y Modelo Conceptual. Un escenario de presentación no añade restricciones permanentes: referencias externas escalares, sin FK ni acceso SQL a otro servicio; valores numéricos exactos sin imponer dos decimales ni una moneda única.

Si un snapshot de Pricing contiene moneda, se conserva explícitamente en ese snapshot conforme al contrato del owner; no se sustituye por PEN implícito. PEN y dos decimales pueden usarse en una demostración, pero no son límites del schema. Promociones no calcula IGV/base imponible ni persiste costo de envío, Pickup, ubicaciones de fulfillment, pagos o reservas.

La restitución implementada corresponde a **cancelación de pedido** en SPEC-005 y AsyncAPI. No se extiende a devoluciones parciales, reembolsos ni distribución fiscal de descuentos sin un acuerdo contractual oficial. D-REC-01/02 y los payloads GenericData de proyecciones siguen pendientes: conservar snapshot/procedencia permite avanzar sin fijar interpretaciones comerciales nuevas.

La revisión de estos límites se comprueba en `validation.sql`. 0001/0002 conservan sus checksums; las correcciones de timestamps, FK explícitas y triggers se aplican en 0003. El upgrade preserva registros previos y documenta la aproximación del backfill; no recupera una fecha de creación histórica desconocida. Los documentos temporales de coordinación no forman parte de las fuentes de datos ni se publican con esta entrega.

Las tablas mantienen los nombres heredados de Arquitectura conforme a la excepción vigente de `bd/CONVENCIONES_BD.md` §5.2. `customer_ref` sigue siendo UUID por el contrato oficial, sin FK a Seguridad. La validación comprueba tanto estos puntos como las fechas obligatorias, los triggers y las seis FK RESTRICT; las pruebas negativas demuestran que esas comprobaciones detectan regresiones. Modelo físico en revisión BD/QA; decisiones transversales pendientes registradas en su §23.

## Entrega compartida

El despliegue en Supabase está pendiente por decisión de Axel: reunir antes el SQL de **todo el sistema**. El #53 requiere además revisión de BD/QA, despliegue real y evidencia del proyecto objetivo. La prueba local no permite cerrar ese criterio.
