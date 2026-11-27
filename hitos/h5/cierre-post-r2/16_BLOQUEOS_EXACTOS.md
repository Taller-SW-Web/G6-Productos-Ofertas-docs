# Bloqueos específicos y desbloqueo

| Código | Owner | Operación afectada | Condición verificable |
|---|---|---|---|
| BLOCKED_APIM_BUDGET | Infra / autoridad presupuestaria | Crear APIM Developer clásico | Cotización oficial Chile Central para Azure for Students, duración/costo total y aprobación de gasto documentada |
| BLOCKED_APIM_NETWORK | Infra + owner Gateway | APIM privado y anti-bypass | ACA env hoy tiene `vnetConfiguration=null`; Gateway `external=true` sin `ipSecurityRestrictions`; no hay subred APIM dedicada. Probar VNet/subred/DNS y aprobar un cutover posterior que cierre ruta directa; Gateway actual queda intacto |
| BLOCKED_APIM_CONFIG | G7 + owner de publicación | `what-if` útil y JWT positivo | Issuer/OpenID/audience/grants reales, perfil/allowlist y manifiesto `effectivePublication.authorized=true`; parámetros seguros y ownership del APIM |
| BLOCKED_DB_ACCESS | Owner BD G6/Inventory | Auditoría de Supabase y reconciliación ledger | Metadata del proyecto G6, rol SELECT real y resultados de `BD_PREDEPLOY_CHECKS.sql`/checksums |
| BLOCKED_PG17_LOCAL | Responsable de entorno de prueba | Validación SQL R10 y E2E transaccional | PostgreSQL 17 descartable accesible; repetir up/rollback/positivos/negativos |
| BLOCKED_R02_R10_RUNTIME | Taco/Inventory + Castilla/Bulk | Entrega completa R02↔R10 | Handler tipado durable, Outbox/Inbox por destino, flag, pruebas de redelivery y luego migración aprobada; la cola y el SQL por sí solos no bastan |
| BLOCKED_G7_G5 | G7 y módulos consumidores | Positivos intergrupo | Identidades/grants de prueba y acta de homologación bilateral para operación/versiones concretas |

Ninguno de estos bloqueos autoriza mutar ACA, SB o Supabase compartido en esta entrega.
