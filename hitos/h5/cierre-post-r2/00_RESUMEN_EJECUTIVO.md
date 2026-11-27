# Cierre post R2 — corte de evidencia 2026-11-27

Fuentes de código: Backend `097dac1bf4a8dcf5c6e799742d2df340f6d893d5`, Frontend `2c6ad931b8dd48e4a4fe883a18ac899fb48b0c81`, Docs `5f30802129ba4bbc0674dcc5878f10065f443118`. La versión contractual consultada de OpenAPI y AsyncAPI es `0.7.0-rc.3`. Las 24 guías recibidas son requisitos de trabajo fechados 19/23 de noviembre; los diagnósticos allí no sustituyen el HEAD ni Azure actual.

## Resultado verificable

- Azure CLI mostró nueve Container Apps en `rg-g6-aca-chile`, ocho privadas y Gateway público, y 19 colas activas en `g6-sb-h5-chile-261127`. El baseline sanitizado está en `DEPLOY_BASELINE.json`.
- `az apim list` devolvió `[]`. No se aprovisionó APIM: faltan presupuesto/cotización para la oferta Azure for Students, conectividad privada/anti-bypass y configuración G7/autorización efectiva del filtro.
- Backend prepara, sin aplicar, una migración incremental para aceptar el destino R10 en `inventory.outbox_delivery`; el runtime R02/R10 permanece pendiente. La plantilla APIM ahora apunta por defecto a API/ruta candidata aislada, usa named values/logger aislados y sus pruebas estáticas pasan.
- No hubo deploy de código, SQL a Supabase, mutación de ACA ni de Service Bus. `APIM-T01..T08` y `RL-01..RL-06` no tienen resultados L2.

El estado del backend ya desplegado no se deduce del SHA Git: las imágenes tienen digests propios. Se preservan como valores observados, sin atribuirles un SHA fuente no demostrado. Las cifras de R2 en el prompt son históricas; no se reetiquetan como pruebas de este candidato.
