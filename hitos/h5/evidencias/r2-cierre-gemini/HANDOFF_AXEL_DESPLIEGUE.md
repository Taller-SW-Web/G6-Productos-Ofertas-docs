# Entrega a Axel — preparación en curso, NO autorizada para desplegar

Este documento no certifica release. HEAD candidatos de partida: Backend b75f1ff7a33c72cec33110b464697cd4a4dc191f, Frontend 778bd03e0180c9ec399626e6b6a417f679b90135, Docs35a31708025e0c1b00f6f7055c92f699e366f4ca. Falta aprobación técnica final y SHAs finales. CODE_AND_LAB_FUNCTIONAL_READY=false, LOCAL_G6_GO=false, AZURE_G6_GO=false.

## Diagnóstico RBAC y procedimiento mínimo (solo preparar)

Consulta26/11: namespace Basic Chile activo y claves locales deshabilitadas. Ejecutor CLI tiene Owner/Contributor de control plane; no se observó rol de datos en ámbito namespace. Definiciones consultadas con Azure CLI: Azure Service Bus Data Sender → Microsoft.ServiceBus/*/send/action; Data Receiver → Microsoft.ServiceBus/*/receive/action. No usar una identidad administrada ajena desde el PC. Nuevas Container Apps del RG laboratorio existen con UserAssigned; su configuración no acredita uso de esta rama ni autorización del ejecutor local. Revisar permisos por identidad/cola separadamente.

Axel debe confirmar principal por servicio y aislamiento del laboratorio; no conceder Data Owner global. Para cada fila aprobada de la topología, Sender al productor y Receiver al consumidor en el recurso queue. N01 usa promotions-svc en ambos sentidos sobre g6.promotions.commands. api-gateway no consume colas.

```powershell
# SOLO AXEL, tras autorizar el cambio. No ejecutado por Codex.
$labRg = 'rg-g6-sb-h5-int-fork'
$labNs = 'g6-sb-h5-int-32cdqgbnlk7ow'
$namespaceResource = az servicebus namespace show -g $labRg -n $labNs --query id -o tsv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo resolver namespace' }
# Introducir object ID del principal legítimo del servicio y cola de la topología.
$principalObjectId = Read-Host 'Object ID autorizado del servicio'
$queueName = Read-Host 'Cola exacta aprobada'
$role = Read-Host 'Azure Service Bus Data Sender o Azure Service Bus Data Receiver'
if ($role -notin @('Azure Service Bus Data Sender','Azure Service Bus Data Receiver')) { throw 'Rol no permitido' }
$queueResource = az servicebus queue show -g $labRg --namespace-name $labNs -n $queueName --query id -o tsv
if ($LASTEXITCODE -ne 0 -or -not $queueResource.StartsWith($namespaceResource + '/queues/')) { throw 'Cola no pertenece al laboratorio' }
az role assignment create --assignee-object-id $principalObjectId --assignee-principal-type ServicePrincipal --role $role --scope $queueResource
if ($LASTEXITCODE -ne 0) { throw 'Asignación fallida; conservar evidencia saneada' }
```

Este ejemplo aplica a service principal/managed identity. Un usuario ejecutor necesita autorización separada y principal-type User, sin suplantar servicios. Confirmar propagación con peek SDK autorizado y prueba aislada identificada; no tocar DLQ preexistente2 ni mensajes ajenos. No publicar object IDs ni secretos en evidencia.

## Pendiente antes de entregar como listo

Completar auditoría HTTP, frontend real y dos regresiones limpias; matriz de permisos por19colas y variables exactas de código; migraciones, digests, readiness, smoke y rollback. No ejecutar deploy ni merge. Las instrucciones finales de despliegue se derivarán del pipeline y recursos comprobados, sin inventar variables.

## Permisos mínimos por entrega

Fuente: matriz ejecutable de19relaciones; contrastar nuevamente antes de conceder. Sender al productor y Receiver al consumidor de cada fila, con scope de queue, no de suscripción. Para N01, mismo promotions-svc con ambos roles. El ejecutor local requiere autorización específica separada; su rol Owner no es una concesión de datos.

**La identidad compartida `g6-h5-qa-acr-pull` observada en varias apps no debe recibir permisos de negocio como atajo.** Axel debe identificar/aprovisionar y asociar identidades propias autorizadas por servicio; solo promotions-svc muestra además g6-h5-int-promotions. No se modificó ninguna identidad. Consulta de todas las asignaciones en suscripción, filtrada por principal y scope namespace/colas, no encontró roles efectivos de datos para las identidades de esas apps.

| Flujo | Cola | Sender: productor | Receiver: consumidor |
|---|---|---|---|
| R01 | `g6.catalog.from.bulk` | bulk-svc | catalog-svc |
| R02 | `g6.inventory.from.bulk` | bulk-svc | inventory-svc |
| R03 | `g6.pricing.from.bulk` | bulk-svc | pricing-svc |
| R04 | `g6.bulk.from.catalog` | catalog-svc | bulk-svc |
| R05 | `g6.combos.from.catalog` | catalog-svc | combos-svc |
| R06 | `g6.inventory.from.catalog` | catalog-svc | inventory-svc |
| R07 | `g6.pricing.from.catalog` | catalog-svc | pricing-svc |
| R08 | `g6.promotions.from.catalog` | catalog-svc | promotions-svc |
| R09 | `g6.taxonomy.from.catalog` | catalog-svc | taxonomy-svc |
| R10 | `g6.bulk.from.inventory` | inventory-svc | bulk-svc |
| R11 | `g6.catalog.from.inventory` | inventory-svc | catalog-svc |
| R12 | `g6.combos.from.inventory` | inventory-svc | combos-svc |
| R13 | `g6.promotions.from.inventory` | inventory-svc | promotions-svc |
| R14 | `g6.bulk.from.pricing` | pricing-svc | bulk-svc |
| R15 | `g6.catalog.from.pricing` | pricing-svc | catalog-svc |
| R16 | `g6.price-audit.from.pricing` | pricing-svc | price-audit-svc |
| R17 | `g6.promotions.from.pricing` | pricing-svc | promotions-svc |
| R18 | `g6.catalog.from.taxonomy` | taxonomy-svc | catalog-svc |
| N01 | `g6.promotions.commands` | promotions-svc (HTTP) | promotions-svc (Worker/isolatedCouponH5Bus en test) |

Azure MI/RBAC autentica el transporte. Los JWT G7 de las llamadas HTTP son identidades y scopes distintos; no colocar secretos M2M ni credenciales Azure en React.
