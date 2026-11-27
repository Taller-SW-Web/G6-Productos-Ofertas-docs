# APIM what-if

Estado: **NOT_RUN**. El manifiesto regenerado desde Docs `5f30802129ba4bbc0674dcc5878f10065f443118` y Backend `097dac1bf4a8dcf5c6e799742d2df340f6d893d5` tiene 145 operaciones candidatas, cinco internas excluidas y G5 deshabilitado, pero `publicationMode=candidate` y `effectivePublication.status=BLOCKED_MISSING_ENV_CONFIG`. La plantilla Bicep no materializa la API si falla ese gate. Faltan además RG/instancia APIM aprobados, subred, G7 y parámetros seguros. Un `what-if` con valores inventados sería engañoso.

Comando pendiente tras reunir evidencia y validar parámetros: `az deployment group what-if --resource-group <RG_APIM_APROBADO> --template-file ops/azure/apim/main.bicep --parameters @<PARAMS_LOCAL_SEGURO.json> --output json`. Revisar cada `Create/Modify/Delete`; abortar ante API/policy ajena, ACA, Service Bus, red compartida o eliminación. El `create` se mantiene bloqueado hasta resultado APIM-only, costo, ownership, red y autorización operativa.
