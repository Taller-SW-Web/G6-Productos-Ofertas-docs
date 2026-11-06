# Hallazgos para auditoría

Base Docs: `a7778ec1a22811c1213a94ef096ab905911342cc` (`master`, 2026-11-05).

| Fuente y ubicación | Operación / problema | Impacto y propuesta |
|---|---|---|
| `contratos/http/openapi.yaml:1968` y `:2183` | `GET /precios/skus/{sku}`, `obtenerPrecioSku`: `x-allowed-client-ids` aparece dos veces con los mismos cuatro valores | YAML estricto inválido; owner contractual G6/Pricing debe aprobar retirar la repetición, sin alterar valores. Contrato intacto en este PR. El build elimina solo redundancia idéntica en JSON derivado y lo informa; el CI estricto permanece rojo |
| YAML original, validación SmartBear apidom-ls | 459 errores informados, muchos sobre anclas/alias y parámetros referenciados | No son 459 defectos confirmados: la copia JSON sin anclas pasa Swagger Parser y SmartBear con cero errores. No cambiar `$ref` ni extensiones válidas para silenciar diagnósticos |
| Backend `apps/api-gateway/test/generate-routes.mjs`, master observado `58b94a694fc22ad4401450feaffe8b708330518d` | El generador exige operationId y deshabilita regeneración completa; concatena `/api/v1` + path, refresca seguridad/errores en ruta existente y no filtra `x-internal` | No reconstruir Swagger desde controladores ni tabla parcial. Owner Gateway debe revisar filtro explícito antes de futuras generaciones internas. No se cambia Backend ni se afirma una fuga runtime |
| SmartBear `scan_api_standardization`, organización accesible | HTTP 404: no existe configuración de gobierno | Validación estructural sí funciona; reglas organizacionales pendientes del administrador, sin modificar permisos ni configuración |
| `tests/contratos/test_asyncapi_h4_event_instances.py:151` / `InventoryStockChanged` | El fixture negativo `inventoryStockChanged` resulta válido | Fallo reproducido sobre el SHA base intacto. Owner Inventario/contratos debe determinar si corresponde corregir schema o fixture; no modificar unilateralmente AsyncAPI ni la expectativa en este PR |

Backend y Frontend se consultaron en modo lectura mediante GitHub. El README Frontend describe modo demo y adapters; no acredita backend desplegado. La lectura de fuentes de código no constituye prueba runtime.
