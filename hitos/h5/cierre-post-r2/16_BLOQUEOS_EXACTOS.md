# Bloqueos específicos y desbloqueo

| Código | Owner | Operación afectada | Condición verificable |
|---|---|---|---|
| BLOCKED_APIM_BUDGET | Infra / autoridad presupuestaria | Crear APIM Developer clásico | Cotización oficial Chile Central para Azure for Students, duración/costo total y aprobación de gasto documentada |
| BLOCKED_APIM_NETWORK | Infra + owner Gateway | APIM privado y anti-bypass | ACA env hoy tiene `vnetConfiguration=null`; Gateway `external=true` sin `ipSecurityRestrictions`; no hay subred APIM dedicada. Probar VNet/subred/DNS y aprobar un cutover posterior que cierre ruta directa; Gateway actual queda intacto |
| BLOCKED_APIM_CONFIG | G7 + owner de publicación | `what-if` útil y JWT positivo | Issuer/OpenID/audience/grants reales, perfil/allowlist y manifiesto `effectivePublication.authorized=true`; parámetros seguros y ownership del APIM |
| BLOCKED_DB_RELEASE | Owner BD G6/Inventory | Aprobación y ejecución futura del delta R10 en proyecto `slzglmtiyrzygpkiuthf` | La lectura directa ya confirmó owner, grants, check de tres destinos, índice y cero entregas; falta conciliar ledger y cuatro eventos Catalog heredados, aprobar ventana y aplicar solo en release autorizado |
| BLOCKED_R02_R10_E2E | Taco/Inventory + Castilla/Bulk | Certificar entrega terminal conjunta | Ejecutar R02 desde Bulk y R10 hasta Inbox/estado terminal Bulk en PostgreSQL y bus aislados; confirmar flags efectivos, luego aplicar migración solo en release autorizado |
| BLOCKED_G7_G5 | G7 y módulos consumidores | Positivos intergrupo | Identidades/grants de prueba y acta de homologación bilateral para operación/versiones concretas |

Ninguno de estos bloqueos autoriza mutar ACA, SB o Supabase compartido en esta entrega.
