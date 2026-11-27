# Bloqueos externos — auditoría en curso

Consulta Azure CLI de solo lectura en esta sesión (2026-11-26 Lima): namespace g6-sb-h5-int-32cdqgbnlk7ow, región Chile Central, Basic, Active, autenticación local deshabilitada;19colas Active. Cero mensajes activos observados. Dos mensajes DLQ preexistentes en g6.catalog.from.taxonomy se preservaron.

El ejecutor tiene Owner/Contributor de plano de administración; la consulta completa de asignaciones (incluyendo ámbitos hijo de colas) no encontró Data Sender/Receiver para las identidades runtime observadas. Los Container Apps usan principalmente la identidad compartida g6-h5-qa-acr-pull; no debe recibir roles de negocio por conveniencia. Promotions tiene además g6-h5-int-promotions, sin los roles de datos observados.

Comprobación SDK de solo lectura: ServiceBusClient con AzureCliCredential y peekMessages sobre g6.catalog.from.bulk, WebSockets, maxRetries=0. Primer intento limitado5s:ServiceTimeout. Segundo intento limitado15s/AbortSignal20s: **ServiceBusError code UnauthorizedAccess: Unauthorized access. 'Listen' claim(s) are required to perform this operation. Resource: 'sb://g6-sb-h5-int-32cdqgbnlk7ow.servicebus.windows.net/g6.catalog.from.bulk/$management'.** No se envió ni consumió mensaje alguno.

AZURE_SERVICE_BUS_REAL=NOT_RUN_BLOCKED_INFRA. Owner de desbloqueo:Axel Cueva, con aprobación del responsable de infraestructura. Acción: confirmar identidad propia por servicio y asignar Azure Service Bus Data Sender al productor y Data Receiver al consumidor en cada cola de la topología canónica; confirmar identidad de ejecutor para pruebas aisladas sin tocar mensajes ajenos. Procedimiento y19mapeos en HANDOFF_AXEL_DESPLIEGUE.md (borrador en preparación). No se modificó RBAC ni infraestructura.

G7 real: grants externos no confirmados por esta sesión. Responsable:G7; debe emitir JWT con issuer/audience/client_id/scope/roles aprobados y verificar consumidores conforme a la matriz80, sin inferir homologación de JWT locales. G5 real: evidencias de pedido/cancelación pendientes del responsable G5; el servidor contractual local no acredita su módulo. Azure Chile: despliegue exclusivo de Axel, todavía no ejecutado por este agente.

LOCAL_G6_GO=false; AZURE_G6_GO=false. Los bloqueos externos no detienen las verificaciones locales pendientes.
