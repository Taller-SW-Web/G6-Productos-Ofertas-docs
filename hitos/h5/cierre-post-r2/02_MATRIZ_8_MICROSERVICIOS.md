# Matriz diferencial de ocho servicios

Base Backend `097dac1b`; contrato Docs `5f308021`. `NO_REEVALUADO` significa que esta entrega no repitió las pruebas del servicio, aunque el R2 histórico haya tenido resultados. Ningún renglón autoriza deploy.

| MK | Servicio / owner primario | Delta de esta entrega | Estado |
|---|---|---|---|
| 001 | Bulk / Castilla | Producer R02 y consumidor R10 identificados; E2E conjunto aún pendiente | IMPLEMENTADO_SIN_PRUEBA_SUFICIENTE |
| 002 | Combos / Castilla | PR FE #92 inspeccionado por rutas, no integrado | NO_REEVALUADO |
| 003–004 | Catalog / Poma | Sin cambio runtime | NO_REEVALUADO |
| 005–007 | Promotions / Cueva | PR BE #296 abierto, sin cherry-pick | NO_REEVALUADO |
| 008–012 | Taxonomy / López | PR BE #300 Draft, sin merge ni duplicación | NO_REEVALUADO |
| 013 | Pricing / Vera | PR FE #94 abierto, sin cherry-pick | NO_REEVALUADO |
| 014 | Price Audit / Vera | Sin cambio runtime | NO_REEVALUADO |
| 015–016 | Inventory / Taco | SQL candidato `0002_allow_bulk_r10_delivery` y rollback; corrección de rollback transaccional ante fallo técnico R02; PR #297 permanece independiente | PG17 26/26 PASS; despliegue NO APLICADO |

Gateway transversal: filtro APIM candidato regenerado desde HEAD, cinco rutas internas excluidas; `effectivePublication` sigue bloqueado. Frontend #90/#92/#94/#101 se inspeccionó por lista de archivos; no se atribuye a master su delta sin revisión y tests. Las 16 MK no se declaran cerradas por esta tabla.
