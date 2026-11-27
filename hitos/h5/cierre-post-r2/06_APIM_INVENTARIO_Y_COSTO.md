# APIM: inventario, red y costo

`az apim list --query '[].{id:id,name:name,location:location,sku:sku.name,resourceGroup:resourceGroup}' -o json` devolvió `[]` en la suscripción Azure for Students `fef42188-accd-4470-ae88-78f583eb4906`. Región ACA/SB: `chilecentral`. No existe instancia reutilizable identificada.

El Bicep candidato usa Developer clásico, una unidad, VNet externa. [Microsoft Learn: modalidades de red](https://learn.microsoft.com/en-us/azure/api-management/virtual-network-concepts) confirma inyección externa para Developer/Premium y salida VNet para Standard v2/Premium v2; son modelos distintos. [Precio oficial](https://azure.microsoft.com/en-us/pricing/details/api-management/) remite a cotización/calculadora según oferta. **Costo numérico Chile Central/Azure for Students: NO COTIZADO**; no se presume gratuito. Estimación requerida: una unidad Developer × horas previstas + red/monitorización, obtenida en la calculadora de la suscripción y aprobada por la autoridad de presupuesto. Estado `BLOCKED_APIM_BUDGET`.

Gateway actual: `external=true`, FQDN público. El preflight del Backend exige `directRoutesBlocked=true`, que no puede acreditarse con este ingress sin un cutover futuro. La conectividad APIM→Gateway privado, VNet/subred dedicada, DNS y ACL también están `BLOCKED_APIM_NETWORK`. No se cambió el ingress.
