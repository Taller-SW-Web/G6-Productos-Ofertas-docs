# Ejecución CLI APIM

`az --version`: 2.93.0. `az apim list`: `[]`. `az bicep build --file ops/azure/apim/main.bicep`: PASS con advertencias de lint no bloqueantes. Tests APIM estáticos: 29/29 PASS al usar `APIM_ARM_TEMPLATE` compilado. No se ejecutó `az deployment group create`, `az apim api create/import/update` ni `az rest` de escritura. APIM recurso/API/revisión/hostname/policy hash en vivo: **NO EXISTEN**.

El candidato Bicep Backend usa por defecto `candidateApiName=g6-h5-candidate` y `candidateApiPath=h5-candidate/api/v1`, con preflight que rechaza el ID/ruta operativos. Su `serviceUrl` sigue apuntando al prefijo `/api/v1` del Gateway. Esto es preparación de código, no una instancia desplegada.

Comando de ejecución futura (no ejecutado): `az deployment group create --resource-group <RG_APIM_APROBADO> --template-file ops/azure/apim/main.bicep --parameters @<PARAMS_LOCAL_SEGURO.json> --output json`; solo tras gates de `07_APIM_WHAT_IF.md` y con recursos APIM exclusivos. Capturar ID real y policy mediante GET de Azure CLI/REST, comparar hashes y probar rollback del candidato.
