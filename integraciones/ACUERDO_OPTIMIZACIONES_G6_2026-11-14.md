# Aprobación interna G6 para optimizaciones y contratos — 2026-11-14

## Estado y alcance

Este registro documenta la autorización expresa del coordinador G6 para completar las optimizaciones de Catálogo, Pricing, Auditoría, Combos y módulos relacionados en Backend PR #230 y Frontend PR #82, y para preparar esta versión contractual en Docs. Es una decisión interna de G6; no crea una DEC-F nueva ni declara homologación con Marketplace, Retail, Chatbot, Ventas o Seguridad (G7). No autoriza despliegues, cambios de datos productivos ni concesiones de permisos de G7.

Implementación, pruebas, grant G7 y aceptación externa se rastrean como estados separados. OpenAPI `0.6.0-rc.5` es una candidata documental sujeta a revisión y CI; su presencia no acredita runtime ni grants.

## Resolución SKU por lote

Se adoptan dos fronteras de seguridad con un núcleo interno compartible, sin compartir autenticación:

1. `POST /productos/administracion/skus/resolver`: consulta lógica de Catálogo para UI administrativa; `userBearer`, rol `GESTOR_COMERCIAL`; de 1 a 100 SKU opacos, cada uno de 1–256 caracteres sin NUL; conserva orden y duplicados. Cada fila distingue `ELEGIBLE`, `INACTIVO`, `NO_ELEGIBLE` y `NO_ENCONTRADO`, e incluye identidad/producto padre/variante/tipo según existencia. 400 entrada inválida, 401 token inválido, 403 rol insuficiente y 503 error técnico. El POST no muta estado comercial y no debe recibir retry automático propio de una escritura.
2. `POST /productos/skus/contexto/lote`: consulta privada exclusiva Pricing→Catálogo; `serviceBearer`, cliente `modulo-productos`, `aud=api-productos`, scope `catalogo:leer`; nunca Gateway ni token humano. Lote de 1–100, orden/duplicados preservados, resultado por elemento `FOUND` o `SKU_NO_ENCONTRADO` y contexto con los cinco campos ya publicados (`sku`, `productId`, `isVariant`, `active`, `eligible`). Fallo técnico es 503 a nivel de solicitud; inexistencia por elemento preserva la semántica del GET individual. El endpoint GET individual permanece compatible.

Grant y emisión real de G7 quedan sin acreditar en esta fuente. La matriz de solicitudes a G7 debe conservarse hasta que el owner publique registro/grant y evidencia no secreta de pruebas 200/401/403.

## Filtros por tipo antes de paginar

`GET /productos` y `GET /productos/administracion` admiten `tipoProductoIdsIncluidos` y `tipoProductoIdsExcluidos` repetidos (hasta 100 por lista). Los identificadores son opacos, exactos y no presuponen UUID. El provider rechaza entrada inválida; combina los filtros con búsqueda, estado, categoría, marca y canal, aplica inclusión/exclusión antes de orden y corte, y calcula `total`/`totalPaginas` sobre ese mismo universo. Los parámetros no se reconstruyen en cliente mediante descargas completas. La extensión compartida debe mantener compatibilidad de resultados cuando no se envían filtros; la homologación intermodular sigue siendo independiente de la aprobación G6.

## Semántica autorizada para filtro comercial por precio

`precioMin`/`precioMax` son inclusivos en PEN y evalúan precio efectivo vigente (oferta vigente si aplica; si no, regular), con canal y fallback ya definidos por Pricing; si no se envía canal, el alcance es global. Un producto cuenta una vez si algún SKU vendible/elegible cumple. SKU sin precio vigente no cuenta como cero. Ausencia contractual se distingue de timeout, 5xx y fallo de G7; si no puede evaluarse el conjunto con exactitud, la respuesta es 503, sin página/total parciales. Orden determinista y desempate por identidad de producto; el total se obtiene antes de paginar.

### Alternativas de lectura y decisión técnica

- **Escaneo de catálogo y lookup Pricing por SKU:** descartado por N+1. El benchmark ya disponible de Pricing midió para 20/100 SKU 38/194 SELECT de Pricing en la versión individual y 2 en batch; las llamadas a contexto Catalog aún fueron 20/100. En 100 SKU el p50 del fixture fue ~1.54–1.59 s frente a ~208–213 ms con el batch de precios. Son mediciones locales existentes de cinco muestras; no sustentan p95/p99 ni una extrapolación Azure.
- **Read model de precios en Catálogo:** no adoptado con los eventos/versiones hoy publicados. El evento `pricing.price.changed` no contiene una instantánea completa e inmutable por objetivo/SKU/canal, vigencia y versión que permita mantener exactamente oferta-vs-regular, alcance global, borrado y expiración tras caída/reorden/replay. Sin secuencia/watermark, snapshot inicial reconciliable y backfill, Catálogo tendría una autoridad comercial duplicada o resultados obsoletos.
- **Estrategia elegida para el contrato actual:** cálculo autoritativo bajo demanda mediante consultas batch de Pricing, candidatos elegibles del repositorio de Catálogo, concurrencia acotada, límite de deadline y fail-closed sin página parcial. Reutilizar el mismo instante y canal al resolver todos los lotes. Medir coste de consulta exacta y paginación con cardinalidades representativas; si excede el presupuesto, proponer por separado un read model con payload completo/versionado, replay ordenado, backfill y reconciliación antes de activarlo. No se accede a tablas Pricing desde Catálogo.

La evidencia de tiempos anterior es parcial, no una medición de extremo a extremo de Catálogo y no cierra la evaluación de coste exacto. Los límites y resultados actualizados deben quedar en el informe de performance asociado al SHA final.

## Auditoría administrativa y creación idempotente de Combos

Se documentan rutas existentes sin cambiar la representación pública histórica:

- `GET /auditoria-precios/administracion` y `GET /auditoria-precios/administracion/{auditId}` requieren identidad humana con rol `GESTOR_COMERCIAL`; aceptan filtros de `sku`, `desde`, `hasta`, `usuarioId`, `canal`, `batchId`, `pagina` y `tamanio` (1–200, default 20). La respuesta administrativa preserva `sku` y `canal_origen` nulos. La ruta pública existente permanece aparte y sin ampliación anónima. Errores de consulta/identidad se contrastan contra el controller.
- `POST /combos/administracion` requiere `userBearer`, rol `GESTOR_COMERCIAL` y `Idempotency-Key` de 1–128 caracteres ASCII `[A-Za-z0-9._:-]`. Alcance: actor autenticado más fingerprint del contenido semántico. Misma clave e intención devuelve el recurso durable original; clave con otra intención da 409 `IDEMPOTENCY_CONFLICT`. Timeout/confirmación perdida es incierto y exige conservar la clave para reconciliar; no crear clave nueva. `POST /combos` sigue publicado para compatibilidad. El Gateway solo puede enrutar las operaciones administrativas con autorización humana correspondiente; el POST privado batch SKU no se agrega a su registry.

## Matriz de conformidad documental

| Operación | OpenAPI candidata | Provider verificado en rama de Backend | Gateway | Consumidor | Seguridad / evidencia restante |
|---|---|---|---|---|---|
| Resolver SKU administrativo | `resolverSkusAdministracion`, userBearer | Catalog controller, 1–100 y clasificación por SKU | Gateway registry de Backend PR #230 agrega la operación como userBearer + GESTOR_COMERCIAL; su CI y SHA final aún deben verificarse | Frontend Combos usa lote | JWT humano y G7 efectivo requieren pruebas con issuer y CI final |
| Contexto SKU privado batch | `obtenerContextosSkuLote`, serviceBearer y client/scope declarados | Catalog private controller; respuesta por SKU | Excluido del Gateway externo | Pricing conserva GET individual y usa batch | Grant G7 no se infiere; pruebas locales aisladas no equivalen a token productivo |
| Filtros tipo pre-página | dos arrays repetidas | parser + query provider filtran antes de count/order/page | GET comercial existente | Selector Combos pasa todos los IDs excluidos | Contrato compartido necesita validación de consumidores antes de rollout |
| Auditoría admin | dos GET con rol humano | controller separado y mapper admin permite nulls | gateway registry ya contiene rutas | Frontend administrador | prueba contract/provider incluyendo nulos y JWT final |
| Combo create admin | POST con Idempotency-Key y rol | controller/provider conservan recibo durable y legacy POST | gateway registry ya contiene ruta | Frontend conserva reconciliación | integración JWT, fallo ambiguo y CI final |

Este documento registra intención, no certifica la matriz completa contra un SHA final. Cada afirmación “probada” deberá citar SHA, comando/run y resultado real en los PR correspondientes.
