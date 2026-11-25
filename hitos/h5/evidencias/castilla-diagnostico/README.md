# Diagnóstico H5 Castilla — solo lectura

Este directorio contiene un inventario saneado de disponibilidad y discrepancias observadas. **No contiene evidencia de ejecución de casos ni certificación.** Los resultados de casos H5 permanecen `NOT_RUN`, `NOT_VERIFIED` o `BLOCKED_*` hasta que se adjunten bytes verificables y su procedencia.

## Inventario Azure consultado

Consulta de solo lectura del 24/11/2026 (America/Lima), recibida del operador:

- `az account show`: sesión legible; identificadores suprimidos.
- `az resource list --resource-type Microsoft.ApiManagement/service`: 0 recursos APIM.
- `az resource list --resource-type Microsoft.App/containerApps`: 9 Container Apps en Chile Central.
- `az resource list --resource-type Microsoft.ServiceBus/namespaces`: 2 namespaces, SKU Basic.
- `az resource list --resource-type Microsoft.Network/virtualNetworks`: 1 VNet.
- `az network private-dns zone list`: 0 zonas DNS privadas.
- Consulta de role assignments: lectura legible, 53 asignaciones; no se retuvieron IDs de principal ni alcance.

No se conservaron nombres, resource IDs, suscripción, tenant, endpoints, IPs, identidades ni credenciales. La existencia de namespaces/ACA no prueba conectividad, habilitación de flujos, deployment de este release, permisos de workload, APIM ni homologación. H5-04A permanece sin recurso APIM observado en este alcance.

## Disponibilidad de evidencia

`inventory.json` marca fuentes/evidencias que no se pudieron validar en este paquete como `NOT_ACCESSIBLE` o `NOT_VERIFIED`. No se descargaron artefactos CI ni se calcularon checksums de bytes externos. La presencia de rutas de código no se usa como resultado de ejecución.

## Reconciliación de IDs APIM-T

Fuente de trazabilidad docente: `hitos/h5/04_API_MANAGEMENT.md`. Ahí APIM-T05 es el caso integral de protección contra exceso/rate limiting; los demás casos de APIM-T01–T08 corresponden a pruebas HTTP/APIM distintas. `ops/azure/apim/README.md` del Backend asigna T05 a CORS y emplea otra numeración. No se fusionaron esas definiciones. Ver `apim-id-reconciliation.json`; una propuesta de renumeración requiere revisión de owners de ambos repositorios.

## Estados separados

- `implementation_state`: la utilería y el harness pueden quedar `DONE_LOCAL` cuando estén escritos.
- `execution_result`: para este inventario, no ejecutado (`NOT_RUN`); Azure lectura no ejecuta pruebas de caso.
- `deployment_state`: `UNKNOWN` por caso/release; los conteos de recursos no vinculan deploy a SHA.
- `homologation_state`: `PENDING` para integraciones bilaterales aplicables; no hay acta adjunta.
