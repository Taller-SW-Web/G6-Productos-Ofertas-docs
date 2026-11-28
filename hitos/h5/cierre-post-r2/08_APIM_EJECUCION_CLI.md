# Ejecución CLI APIM

`az --version`: 2.93.0. `az apim list`: `[]`. `az bicep build --file ops/azure/apim/main.bicep`: PASS con advertencias de lint no bloqueantes. Tests APIM estáticos: 29/29 PASS al usar `APIM_ARM_TEMPLATE` compilado. No se ejecutó `az deployment group create`, `az apim api create/import/update` ni `az rest` de escritura. APIM recurso/API/revisión/hostname/policy hash en vivo: **NO EXISTEN**.

El candidato Bicep Backend usa por defecto `candidateApiName=g6-h5-candidate` y `candidateApiPath=h5-candidate/api/v1`, con preflight que rechaza el ID/ruta operativos. Su `serviceUrl` sigue apuntando al prefijo `/api/v1` del Gateway. Esto es preparación de código, no una instancia desplegada.

SHA256 de archivos locales al HEAD Backend `fabf2c43`: `main.bicep` `1A4B4C0FC045C7C47FA54A0A2CE6777BE9B2E97C9ABBB5BC81CEC55FD62B57F2`; `api.xml` `B6A93150F4FF00D35CBD75B18C0912712E16CBC4A5962F8DEF0F6D9089E8E909`; `operation-secured.xml` `0D250FEC3D444251719607FD6271DFC53E563EB2D5060C75CBE75980E02CC9A3`; `operation-public.xml` `DC909802DDBDBEA8866B05DD0F2C782B65CAF85243AFCDB686109B46199BAEA4`. Son hashes de origen, **no** de policy APIM en vivo.

Comando de ejecución futura (no ejecutado): `az deployment group create --resource-group <RG_APIM_APROBADO> --template-file ops/azure/apim/main.bicep --parameters @<PARAMS_LOCAL_SEGURO.json> --output json`; solo tras gates de `07_APIM_WHAT_IF.md` y con recursos APIM exclusivos. Capturar ID real y policy mediante GET de Azure CLI/REST, comparar hashes y probar rollback del candidato.
