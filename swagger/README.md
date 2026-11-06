# G6 Productos y Ofertas en Swagger Studio

**[Abrir G6 Productos y Ofertas](https://app.swaggerhub.com/apis/sanmarcos-bb0/G6-Productos-y-Ofertas/0.6.0-rc.3)** con la cuenta conectada a `sanmarcos-bb0`. El enlace fue devuelto por las herramientas oficiales. Lecturas posteriores confirman `private=true`, `published=false`, título `G6 Productos y Ofertas` y versión `0.6.0-rc.3`.

Estado: **IMPLEMENTAR_PARCIAL**. Recurso privado persistente verificado por API; ejecución directa desde navegador pendiente de CORS, preferencia de conexión y JWT real. No se controló Chrome ni se verificó visualmente My APIs. El complemento no expone proyectos, asignación de proyectos ni roles administrativos detallados; sí acreditó pertenencia a la organización autorizada y permiso efectivo de creación/lectura/actualización.

## Contrato y áreas

Fuente única: [OpenAPI oficial](../contratos/http/openapi.yaml), OpenAPI 3.1.0. La definición recuperada coincide completamente con la derivación autorizada: solo cambian `info.title` y `servers`. Conserva 136 operaciones, 13 tags, 177 schemas y todos los parámetros, bodies, respuestas, ejemplos, seguridad y extensiones. No se dividió el contrato.

| Área | Tags existentes | Operaciones | Runtime observado |
|---|---|---:|---|
| Catalog | Productos, Variantes, Despacho | 21 | Listado/ficha: 200 y cuerpo estructuralmente válido; JWT/SHA pendientes |
| Taxonomy | Taxonomía, SEO | 42 | Categorías: 200/cuerpo válido; marcas: 503 Caddy |
| Pricing | Precios | 13 | No probado |
| Price Audit | Auditoría de precios | 5 | No probado |
| Promotions | Promociones, Cupones, Recomendaciones | 22 | No probado |
| Inventory | Inventario | 19 | No probado |
| Bulk | Carga masiva | 8 | No probado |
| Combos | Combos | 6 | No probado |

Agrupación orientativa, sin cambiar tags ni ownership; ver [arquitectura](../arquitectura/Arquitectura.md). Se preservó la descripción del módulo. Las operaciones `x-internal` no se presumen expuestas en Gateway. Las extensiones de scopes, roles, clientes y estados siguen presentes en editor/exportación; el complemento no permite configurar ni comprobar cómo se renderiza cada extensión.

La [documentación oficial de Studio](https://support.smartbear.com/swagger/studio/docs/en/edit-apis/interactive-api-documentation.html) describe parámetros, respuestas, modelos, headers y duración de Try it out. Se verificó el contenido almacenado, no cada componente visual de esa interfaz.

## Try it out y seguridad

Servidor configurado en la copia privada: `https://g6-productos-ofertas.duckdns.org/api/v1`, obtenido de documentación Backend y verificado por DNS/HTTPS con certificado válido. Docs conserva `/api/v1`; ningún path incluye ese prefijo. No se duplicó la base.

GET reales directos con Node HTTPS, sin tokens, proxy ni escrituras:

| Ruta | HTTP | Duración | Resultado |
|---|---:|---:|---|
| `/api/v1/categorias` | 200 | 1149 ms | JSON, schema estructural PASS |
| `/api/v1/marcas` | 503 | 100 ms | Texto de Caddy, negocio no disponible en esta sonda |
| `/api/v1/productos?canal=MARKETPLACE&pagina=1&tamanio=1` | 200 | 12085 ms | JSON, schema estructural PASS |
| `/api/v1/productos/por-slug/{slug-real}?canal=MARKETPLACE` | 200 | 2046 ms | Slug obtenido del listado; JSON/schema estructural PASS |

[Resumen sin registros de negocio](evidence/runtime-summary-2026-11-05.json): headers, correlación, TLS y estructura. Cuerpos completos solo en `reports/runtime.json`, excluido de Git. Validación estructural con JSON Schema 2020-12 y referencias, sin comprobación adicional de formatos; no acredita negocio integral, E2E, SHA desplegado ni autenticación. Los 200 sin JWT no prueban grant G7 ni permiten deducir fase activa.

Las sondas enviaron `Origin: https://app.swaggerhub.com` y no recibieron `Access-Control-Allow-Origin` ni `Access-Control-Expose-Headers`. No se ejecutó preflight OPTIONS ni navegador. Falta revisar con Gateway/infraestructura el origen exacto, preflight para Authorization/correlación, métodos/headers mínimos y exposición de `X-Correlation-Id`. No se cambia CORS, Caddy ni Gateway aquí.

Studio permite conexión directa o proxy y guarda la selección en `localStorage`, según su documentación. **El complemento no expone esa preferencia.** No se configuró/utilizó proxy ni se enviaron tokens. Antes de usar un JWT en Authorize, seleccionar modo directo y resolver CORS; no autorizar su transmisión al proxy SmartBear por inferencia. Los tiempos anteriores proceden de Node, no de Try it out. Ejecución/headers/duración dentro de Studio siguen pendientes.

`serviceBearer` y `userBearer` se importaron intactos como HTTP Bearer JWT, preparados en la especificación para Authorize nativo; interacción visual no verificada. El [kit](../contratos/http/kit-integracion.md) gobierna firma/issuer/expiración, audiencia `api-productos` para servicio, scopes, roles y clientes. No se fabricó OAuth, no se guardaron credenciales ni se activó bypass. Se requiere provisión/grant G7 y mecanismo seguro autorizado para pruebas autenticadas. [Errores contractuales](../contratos/http/catalogo-errores.md).

## Validación y exportación reproducible

Node 24, desde la raíz:

```powershell
cd swagger
npm ci --ignore-scripts
npm run validate
npm run export
npm test
```

No se aloja una interfaz HTML. Se retiraron UI, servidor, Playwright y sus dependencias. `reports/studio.yaml` sin anclas, `reports/studio.json` y manifiesto son artefactos descartables, no se editan ni reemplazan la fuente. [studio.config.json](studio.config.json) solo contiene organización, nombre y presentación/servidor verificados. El manifiesto registra hash de fuente y semántico derivado.

La clave repetida idéntica de `obtenerPrecioSku` se eliminó con autorización expresa. El documento parseado antes/después es idéntico: no cambiaron rutas, scopes, permisos, clientes ni reglas. El parser ahora es estricto y rechaza duplicaciones.

El [workflow](../.github/workflows/swagger-docs.yml) valida, exporta, comprueba equivalencia/referencias y ejecuta regresión; adjunta `swagger-studio-revision`. No ejecuta sondas al backend ni publica en SmartBear. La prueba AsyncAPI preexistente de `InventoryStockChanged` continúa fallando, sin modificar contratos ajenos ni expectativas.

Para repetir sondas solo con autorización de lectura del entorno:

```powershell
npm run probe:runtime
python scripts/check-runtime.py
python scripts/summarize-runtime.py
```

Python requiere `PyYAML==6.0.3` y `jsonschema==4.25.1`. Revisar el resumen antes de versionarlo; no publicar cuerpos de negocio ni credenciales. Las sondas hacen solo GET y obtienen un slug real del listado.

## Actualización unidireccional

1. Cambiar/validar/aprobar contrato y SHA en Docs mediante PR. No editar reglas desde Studio.
2. Ejecutar validación/exportación/pruebas. Registrar hash, versión y transformaciones de presentación autorizadas.
3. Consultar `list_organizations` y `search_apis_and_domains`; acreditar owner, versión, privacidad y estado antes de escribir.
4. Importar YAML derivado mediante `create_or_update_api`. Para actualizar, leer `get_api_definition(format: text)` y usar `patch_api` con texto exacto; `newVersion` crea una versión privada cuando el owner apruebe una versión contractual nueva. No aplicar corrección IA automática.
5. Recuperar JSON sin resolver/flatten, guardarlo temporalmente y ejecutar `npm run verify:remote -- reports/remote.json`. Consultar nuevamente privacidad/publicación y `validate_api` por owner/nombre/versión.
6. Registrar URL devuelta, hashes y resultados. Docs mantiene autoridad; Studio es copia privada derivada.

La creación conservó realmente `0.6.0-rc.3`, pese a que el descriptor anunciaba 1.0.0; siempre verificar el resultado. No se creó versión de bootstrap. El complemento no expone sincronización Git, gestión de proyectos ni credenciales CI. No existe sincronización automática: actualización manual mediante herramientas oficiales y lectura posterior. No se crearon claves ni integración bidireccional.

[Creación/verificación](evidence/studio-2026-11-05.json), [resultados actuales](evidence/RESULTADOS-STUDIO.md), [hallazgos](HALLAZGOS.md). Evidencia anterior al cambio de objetivo es histórica. No se publicó recurso público ni se creó portal adicional.
