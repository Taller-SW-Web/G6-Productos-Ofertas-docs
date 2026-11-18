# Hallazgos vigentes — Swagger Studio

| Hallazgo | Estado / responsable |
|---|---|
| Clave `x-allowed-client-ids` idéntica repetida en `obtenerPrecioSku` | Corregida con autorización; cinco líneas retiradas y comparación semántica total PASS; YAML estricto PASS |
| Anclas YAML y SmartBear | Importación derivada sin anclas; contenido recuperado idéntico y validación SmartBear PASS |
| Privacidad | Verificada después de crear/actualizar: `sanmarcos-bb0`, versión `0.6.0-rc.3`, `private=true`, `published=false` |
| CORS de Studio | GET observados sin Allow-Origin/Expose-Headers para `https://app.swaggerhub.com`; owner Gateway/infraestructura debe revisar origen exacto, preflight, headers mínimos y correlación; sin cambios de infraestructura |
| GET marcas | 503 en texto de Caddy; owner Gateway/Taxonomy/infraestructura debe revisar exposición/upstream; no se afirma negocio funcional |
| JWT real / versión desplegada | No acreditados por GET sin credenciales; provisión/grant G7 y SHA de runtime pendientes |
| Modo navegador/proxy de Studio | Preferencia local del navegador no expuesta por complemento; sin proxy ni tokens utilizados; comprobación visual manual pendiente |
| `InventoryStockChanged`, prueba negativa línea 151 | Causa identificada y corregida en el entorno: faltaba `rfc3339-validator`, dejando `date-time` sin registrar en FORMAT_CHECKER. Instalación fijada y preflight que rechaza `not-a-date`; AsyncAPI, fixture y expectativa intactos. Ver evidencia de auditoría |
| Generador Gateway | Fuente consultada no filtra `x-internal`; owner Gateway debe revisar antes de generar nuevas rutas; documentación no acredita exposición |
| Gobierno SmartBear | Evaluación previa 404 por configuración de reglas inexistente; no se cambian organización/roles/plan |

Solo se modifican Docs y la API privada autorizada. Backend/Frontend, permisos G7, Caddy, CORS, Oracle, Azure y Vercel no se modifican.
