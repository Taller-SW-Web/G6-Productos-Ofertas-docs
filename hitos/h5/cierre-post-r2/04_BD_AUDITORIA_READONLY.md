# Auditoría BD: alcance real

**NOT_RUN / BLOCKED_DB_ACCESS.** En esta sesión no se identificó mediante metadata un proyecto Supabase G6 ni un rol de consulta autorizado. No se abrió conexión SQL. Los recuentos de las guías (stock, SKU, Outbox/Inbox, auditorías y ledger) son antecedentes y no se presentan como valores actuales.

El contraste local sí encontró en Backend `apps/inventory-svc/migrations-candidate/h5/0001_outbox_delivery.sql` el check con tres destinos, mientras AsyncAPI `0.7.0-rc.3` define `g6.bulk.from.inventory`. El runtime de `inventory-command.service.ts` sigue bloqueando `inventory.bulk.stock.adjust.requested`; `service-bus-deliveries.ts` solo registra Catalog/Combos/Promotions. Por ello ampliar el check prepara almacenamiento, pero **no habilita R10** ni justifica desplegarlo.

Owner de desbloqueo: responsable de BD G6/Inventory. Condición: identificar proyecto por metadata, conceder lectura del catálogo/ledger a rol real, ejecutar `BD_PREDEPLOY_CHECKS.sql` en transacción de solo lectura y contrastar cada definición y checksum con el código candidato. La migración se aplica únicamente en un release futuro aprobado.
