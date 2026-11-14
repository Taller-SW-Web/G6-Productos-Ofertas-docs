# ADR — Cierre contractual de cuatro bloqueantes intermodulares

- **Estado de las decisiones:** Accepted por el equipo G6, 10-10-2026.
- **Estado de implementación:** Pendiente de implementar y validar; no afirmar desplegado.
- **Fuente base:** G6-Productos-Ofertas-docs, `master` SHA `be5c2db16aca6d6d18b3005a2da4205f724038e3`, OpenAPI y AsyncAPI 0.5.0.
- **Versión propuesta:** 0.6.0-rc.1 (no publicada), sujeta a compatibilidad y pruebas.

## B1 — Identidad y correlación de operaciones

`order_id` es referencia opaca textual de Ventas (ej.: `PED-2026-00001`). `operation_id` y `reservation_id` son UUID; el identificador de pedido nunca se convierte artificialmente a UUID. La creación, confirmación, liberación, expiración y consumo referencian una operación estable; `message_id` identifica el envío de transporte, `causation_id` la causa y `correlation_id` la conversación/flujo. La consulta durable es `GET /api/v1/inventario/operaciones/{operationId}` (provisional, Ventas, nuevo scope pendiente de G7). El `202` anterior solo indica admisión.

Los registros anteriores con `operation_id` ausente quedan legados, no se inventan UUID sin plan de correlación. El backend deberá persistir la operación y su resultado antes de publicar eventos.

## B2 — Resultado asíncrono definitivo

Un éxito de reserva publica `inventory.reservation.created` con `reservation_id`, `order_id`, `expires_at` y líneas. Un rechazo posterior a `202` publica `inventory.reservation.rejected` con `result_code` estable. Consumo, liberación y expiración tienen schemas específicos. Todos los mensajes críticos tienen `operation_id` UUID y `causation_id` no vacío. Mensajes con payload cambiado incrementan `schema_version` a 2 en publicación, y durante transición se admite v1 únicamente mediante adaptador explícito. La DLQ es para errores técnicos; rechazos de negocio producen resultado tipado. Entrega at-least-once implica deduplicación y replay idempotente.

## B3 — D-INV-01: disponibilidad comercial multiubicación

**Política aprobada:** no agregar saldos de ubicaciones diferentes sin capacidad real de cumplimiento conjunto. Para la primera entrega, toda `fulfillment_ref` de un canal/modalidad resuelve a una sola ubicación elegible mediante mapeo interno. Si el mapeo no existe, está ambiguo, o no hay prueba de cumplimiento, la respuesta es `INDETERMINADO`, no `DISPONIBLE` ni `AGOTADO`. Se mantiene el GET comercial de estados, con `INDETERMINADO` admitido; se agrega `POST /inventario/disponibilidad/comercial/verificar` con líneas `{sku,quantity}` y contexto de cumplimiento opaco. No expone saldos, no reserva stock. Una sumatoria multi-origen queda fuera de alcance de esta versión y exigirá ADR posterior.

## B4 — Consumo y restauración de cupones

El consumo es posterior a reserva confirmada y evaluación comercial congelada; el comando de Ventas incluye `reservation_id`, `commercial_snapshot_ref` y correlación UUID. Resultados completed/rejected usan payload tipado. Para fallo/anulación aplicable posterior al consumo, Ventas solicita restauración; Promociones aplica política `RESTAURAR_EN_CANCELACION` o `NO_RESTAURAR`, deduplica por operación y publica resultado. Misma intención y fingerprint produce replay sin efectos; misma identidad con distinta intención/payload es conflicto. Validación HTTP de cupón no consume usos. Promotions no decide pagos ni estados del pedido.

## Política de publicación y transición

1. No reemplazar contratos 0.5.0 consumidos hasta que existan adaptadores, eventos v2 y pruebas de conformidad.
2. Registrar con G7 el scope nuevo `inventario:operaciones:leer`; verificar aud/client_id.
3. Validar migraciones en Supabase de ensayo y permisos runtime; desplegar solo tras inspección de diferencias.
4. Notificar a G5/G4/G1/G3 de cambios incompatibles con fecha de corte acordada.
5. Estos ADR gobiernan intención y contrato; no acreditan ejecución real hasta CI/E2E PASS.
