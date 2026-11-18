# Incremento candidato de mensajería H5 para Catálogo

**Estado:** CANDIDATO_H5. El proceso Nest de Catálogo sigue usando RabbitMQ según la configuración vigente. El candidato requiere composición explícita del escritor y del worker antes del corte.

| Componente | Comportamiento del candidato |
| --- | --- |
| Emisor | SDK Azure fijado a `@azure/service-bus@7.10.0`. Reutiliza el sender de cada cola y verifica el tamaño AMQP completo con el batch del SDK antes del envío. |
| Receptor | Peek-Lock, validación de sobre y metadatos, persistencia vía handler Catalog e Inbox antes de completar. Abandona en falla transitoria y envía mensajes inválidos a DLQ. |
| Identidad | `@azure/identity@4.14.1` con identidad administrada. RBAC Sender y Receiver por cola. Cada cola de entrada debe tener un productor exclusivo autorizado. |
| Configuración | `MESSAGING_PROVIDER=AZURE_SERVICE_BUS`, `SERVICE_BUS_NAMESPACE_FQDN` y RabbitMQ deshabilitado en el proceso H5 dedicado. Sin conexión automática desde la aplicación H4. |
| Persistencia | Migración candidata `apps/catalog-svc/migrations-candidate/h5/0001_outbox_delivery.sql`. Clave por mensaje y destino, lease, contador, última falla y confirmación independiente. |
| Integridad | Claim con `FOR UPDATE SKIP LOCKED`. Envío tras commit del claim. El token del lease protege ante confirmaciones tardías. El reintento conserva `MessageId`. `published_at` en el outbox H4 queda bajo control del relay H4. |

El evento de baja de producto produce una copia por cada consumidor interno candidato, Promotions y Combos. El evento de baja de SKU agrega Inventory y Pricing. Las inicializaciones se dirigen a Pricing o Inventory y los resultados específicos a Bulk o Taxonomy. No se usa una cola compartida entre servicios independientes.

## Verificación y límites

- Las pruebas locales del adaptador usan dobles del SDK para confirmación ambigua, reintento, orden de settlement, redelivery, sobre inválido y rechazo de tamaño. El relay tiene una prueba PostgreSQL descartable de fan-out independiente.
- Azure real debe probar autenticación y permisos por cola, propiedad del productor, comportamiento del lock, tamaño real, DLQ, concurrencia, latencia, expiración y recuperación. El handler debe preservar versiones ante desorden.
- Los lotes Bulk grandes necesitan fragmentación segura o claim-check antes del corte. El adaptador rechaza el envío que excede el límite y conserva el registro para diagnóstico. El broker no resuelve retención comercial ni idempotencia funcional.
- Los flujos externos permanecen bajo sus contratos H4 hasta homologar sus transiciones HTTP, incluidos G5 y G7.

## Habilitación y reversión pendientes

1. Aprobar con Marco y los owners la topología, la migración, el escritor exclusivo, el inventario de mensajes y la política de reconciliación. Aprovisionar namespace, colas y permisos en un ambiente descartable.
2. Probar por SHA con los casos de [verificación H5](../tests/contratos/PLAN-VERIFICACION-SERVICE-BUS-H5.md) y registrar Azure real, identidad, ambiente, resultado y limitaciones. Obtener aprobación bilateral en las fronteras afectadas y verificar los grants de G7 para HTTP.
3. Congelar nuevas publicaciones durante el corte. Inventariar pendientes H4 y resolver estados ambiguos comparando Outbox, Inbox y resultados de negocio. Arrancar solamente el escritor y el relay elegidos para el ambiente.
4. Si hay que volver a H4, detener emisores y consumidores H5. Conciliar cada entrega y conservar la tabla como evidencia. Reanudar RabbitMQ sobre mensajes aprobados y con la identidad original. Replay después de TTL o DLQ requiere autorización y verificación de efectos terminales.
