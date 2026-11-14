# Evaluación económica y límites Azure — propuesta H5

**Estado:** estimación metodológica, NO cotización comercial ni recursos desplegados.

## Escenario

- Service Bus **Basic**: colas internas de G6; contabilizar API calls/operaciones, retries, receives, settles, gestión de mensajes y consumidores para estimar consumo mensual.
- API Management **Consumption**: cobro propio por llamadas y restricciones de políticas; no asumir un nivel gratuito ilimitado.
- Infraestructura y auxiliares: Azure App Service/VM/Containers según despliegue, BD, salida de datos interregional, observabilidad, Azure Storage si claim-check Bulk, CI contra Azure real.
- No confundir facturación de operaciones con número de colas; no asumir costo fijo mensual igual a Standard.

## Fórmula estimada de operaciones de mensajería

```text
operaciones_mes = publicaciones + recepciones + confirmaciones
                + renovaciones/reintentos + inspecciones/DLQ + administración asociada
costo_estimado = operaciones_mes / 1_000_000 * tarifa_regional
               + costo_APIM + storage_blob + observabilidad + egress
```

Esta fórmula es una aproximación de planificación: confirmar **qué cuenta como operación facturable** y la tarifa real de la región/suscripción en la calculadora del proveedor. Las réplicas por destinatario multiplican las publicaciones/recepciones. No publicar USD exactos sin una cotización fechada.

## Límites y riesgo

| Riesgo | Restricción | Mitigación |
|---|---|---|
| Payload Bulk | Máximo 256 KB por mensaje/lote incluyendo propiedades; Basic no admite `DefaultMessageTimeToLive` | Chunking semántico o Blob + claim-check; validar checksum. La expiración de reservas sigue `expires_at` durable en Inventory, no TTL del mensaje |
| Fan-out | Basic no tiene topics ni suscripciones | Outbox por destino, entrega independiente |
| Duplicados | Basic no tiene broker duplicate detection | SQL inbox/idempotencia, IDs estables |
| Orden | Basic no tiene sessions | Versión de agregado y exclusión de procesamiento concurrente en DB |
| Seguridad | RBAC no separa servicios si comparten identidad | Managed identities/workload identities segregadas |
| API Management Consumption | No admite `rate-limit-by-key` | Usar políticas soportadas; cuotas por suscripción solo donde apliquen; backend anti-abuso adicional |
| Testing | Emulador no replica todas las capacidades de Azure | E2E con Azure real y pruebas de identidad |

## Criterio económico de cambio a Standard

Reevaluar si el costo de mantenimiento, nuevas suscripciones, fan-out, fallos y riesgo supera el cargo base adicional de Standard. Registrar mediciones de carga, operaciones y tiempo invertido. No imponer Standard por anticipación sin necesidad, ni fijar Basic irrevocablemente si los requisitos empresariales dejan de cumplir.

## Referencias

- https://azure.microsoft.com/en-us/pricing/details/service-bus/
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quotas
- https://learn.microsoft.com/en-us/azure/api-management/api-management-policy-reference
- https://learn.microsoft.com/en-us/azure/service-bus-messaging/overview-emulator
