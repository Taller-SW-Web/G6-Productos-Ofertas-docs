# Matriz de pruebas de contrato e integración — Productos y Ofertas

**Contrato HTTP objetivo:** OpenAPI `0.6.0-rc.1` (candidato, no publicado).
**Contrato asíncrono objetivo:** AsyncAPI `0.6.0-rc.2` (candidato, no publicado).
**Referencia histórica auditada:** PR #86, rama `nueva`, commit `c1769607f30e2cabf1449e33c877fa4ef41defe5`; esta matriz conserva los estados pendientes y actualiza la expectativa del vhost en `CT-STATIC-18`.
**Estado:** definición documental de casos; no asignar `PASS` a pruebas de API, eventos, seguridad o integración sin ejecución reproducible.

En la revisión actual, `contratos/http/openapi.yaml` conserva `0.6.0-rc.1` y `contratos/eventos/asyncapi.yaml` es `0.6.0-rc.2`. AsyncAPI avanzó por el cambio de vhost y una precisión documental sobre la señalización existente de unroutable; la numeración independiente evita modificar la candidata HTTP sin cambio. Los casos estáticos permanecen `PENDIENTE_EJECUCION` **hasta disponer de ejecución reproducible de validadores y evidencia vinculada al commit**; tampoco se consideran superadas pruebas provider, seguridad o E2E. `0.5.0` es línea base de compatibilidad, no prueba de despliegue de los candidatos.

## Estados

```text
DEFINIDA
BLOQUEADA_DECISION
BLOQUEADA_DEPENDENCIA_EXTERNA
PENDIENTE_IMPLEMENTACION
PENDIENTE_EJECUCION
PASS
FAIL
```

`PENDIENTE_IMPLEMENTACION`: requiere desarrollar o completar el proveedor/consumidor. `PENDIENTE_EJECUCION`: existe una comprobación definida, pero falta evidencia verificable de su ejecución sobre la versión objetivo. `BLOQUEADA_DECISION`: falta acuerdo contractual explícito. `BLOQUEADA_DEPENDENCIA_EXTERNA`: falta una autorización, servicio o confirmación de otro módulo. No convertir resultados de SQL aislado ni mocks en `PASS` de extremo a extremo.

## Tipos

```text
STATIC_CONTRACT
PROVIDER_CONTRACT
CONSUMER_PROVIDER
INTEGRATION
SECURITY_INTEGRATION
ARCHITECTURE_INVARIANT
```

## 1. Contrato estático

| ID | Tipo | Resultado esperado | Estado |
|---|---|---|---|
| CT-STATIC-01 | STATIC_CONTRACT | YAML válido, OpenAPI 3.1.x, `info.version=0.6.0-rc.1`, `$ref` locales resolubles | PENDIENTE_EJECUCION |
| CT-STATIC-02 | STATIC_CONTRACT | `operationId` únicos | PENDIENTE_EJECUCION |
| CT-STATIC-03 | STATIC_CONTRACT | `ErrorCode` de OpenAPI coincide con la tabla activa de `contratos/http/catalogo-errores.md`, incluidos `OPERACION_INVENTARIO_NO_ENCONTRADA` y `CONTEXTO_ABASTECIMIENTO_INVALIDO` | PENDIENTE_EJECUCION |
| CT-STATIC-04 | STATIC_CONTRACT | Header canónico `X-Correlation-Id`; no introducir `X-Request-Id` alternativo | PENDIENTE_EJECUCION |
| CT-STATIC-05 | STATIC_CONTRACT | Código de barras reutiliza `catalogo:leer`; sin scope nuevo | PENDIENTE_EJECUCION |
| CT-STATIC-06 | STATIC_CONTRACT | `DisponibilidadComercial` expone `sku` y `status`, sin saldos ni ubicaciones internas | PENDIENTE_EJECUCION |
| CT-STATIC-07 | STATIC_CONTRACT | Schemas comerciales de Catálogo no contienen flags administrativos ni perfiles físicos internos | PENDIENTE_EJECUCION |
| CT-STATIC-08 | STATIC_CONTRACT | YAML válido, AsyncAPI 3.0.0, `info.version=0.6.0-rc.2`, **40 canales y 40 mensajes**, `$ref` resolubles; se conservan `operation_id` y `causation_id` obligatorios en resultados v2 críticos y en inicializaciones donde corresponda | PENDIENTE_EJECUCION |
| CT-STATIC-09 | STATIC_CONTRACT | `reservaId` de `POST /inventario/reservas/{reservaId}/confirmar` y `/liberar` tiene `type: string`, `format: uuid`; `order_id` sigue siendo cadena opaca | PENDIENTE_EJECUCION |
| CT-STATIC-10 | STATIC_CONTRACT | `GET /inventario/operaciones/{operationId}` exige UUID y restringe consumidor a `modulo-ventas`, scope `inventario:operaciones:leer`, sin publicar stock interno | PENDIENTE_EJECUCION |
| CT-STATIC-11 | STATIC_CONTRACT | `POST /inventario/disponibilidad/comercial/verificar` devuelve evaluación no vinculante sin `location_id` ni cantidades internas; `INDETERMINADO` es una salida de negocio válida | PENDIENTE_EJECUCION |
| CT-STATIC-12 | STATIC_CONTRACT | Los mensajes `inventory.consumption.rejected`, `promotions.coupon.consumption.rejected` y `promotions.coupon.restoration.rejected` requieren `result_code` no vacío y usan esquemas de rechazo propios | PENDIENTE_EJECUCION |
| CT-STATIC-13 | STATIC_CONTRACT | Los esquemas de éxito de consumo/restauración siguen independientes de los de rechazo; las nuevas referencias no alteran nombres de mensajes, exchanges ni routing keys existentes | PENDIENTE_EJECUCION |
| CT-STATIC-14 | STATIC_CONTRACT | `ConsultaOperacionInventario` con `status=REJECTED` requiere `result_code` no vacío; sus estados `ACCEPTED`, `PROCESSING`, `COMPLETED`, `REJECTED` y `REQUIRES_REVIEW` conservan la semántica declarada | PENDIENTE_EJECUCION |
| CT-STATIC-15 | STATIC_CONTRACT | Respuestas `404` de consulta de operación y `422` por contexto comercial inválido usan los códigos del catálogo; `429` y `500` están declarados en las rutas nuevas | PENDIENTE_EJECUCION |
| CT-STATIC-16 | STATIC_CONTRACT | OpenAPI `0.6.0-rc.1` y AsyncAPI `0.6.0-rc.2` identifican candidatas independientes; AsyncAPI cambia el vhost y explicita la señalización unroutable sin reemplazar la línea publicada `0.5.0` en runtime | PENDIENTE_EJECUCION |
| CT-STATIC-17 | STATIC_CONTRACT | GET detallado admite exactamente `modulo-ventas` y `modulo-postventa` con `inventario:disponibilidad:leer` y `serviceBearer`, además de `userBearer` para acceso humano autorizado; Marketplace, Chatbot y Retail quedan excluidos del detalle y usan solo rutas comerciales | PENDIENTE_EJECUCION |
| CT-STATIC-18 | STATIC_CONTRACT | AsyncAPI `servers.rabbitmq.x-vhost` y `x-rabbitmq-topology.vhost` coinciden con `g6-productos-ofertas`; la topología y las operaciones mantienen exchanges, queues, bindings y routing keys respecto de `0.6.0-rc.1` | PENDIENTE_EJECUCION |
| CT-STATIC-19 | STATIC_CONTRACT | GET y POST comerciales incluyen allowlist `modulo-marketplace`, `modulo-chatbot`, `modulo-retail`, con el scope común `inventario:disponibilidad:leer`; `GET /inventario/operaciones/{operationId}` usa `inventario:operaciones:leer` y `modulo-ventas` | PENDIENTE_EJECUCION |

**Control de conteos:** el contrato AsyncAPI candidato del commit `c1769607` contiene 40 canales y 40 mensajes (el baseline histórico `0.5.0` tenía 39 mensajes). Este recuento de estructuras **no equivale a pasar CT-STATIC-08**: los `$ref`, formatos UUID, schemas y obligatoriedad de campos siguen pendientes de un validador reproducible. Un cambio intencional exige actualizar conteos y justificarlo.

## 2. Marketplace ↔ Productos y Ofertas

| ID | Operación/caso | Resultado esperado | Estado |
|---|---|---|---|
| CT-MKT-01 | `GET /productos?canal=MARKETPLACE` elegible | Producto puede aparecer | PENDIENTE_EJECUCION |
| CT-MKT-02 | Producto activo no elegible | No aparece; `estado` no permite bypass | PENDIENTE_EJECUCION |
| CT-MKT-03 | Página sin resultados | HTTP 200 + lista vacía | PENDIENTE_EJECUCION |
| CT-MKT-04 | Slug activo/elegible | 200 + detalle comercial | PENDIENTE_EJECUCION |
| CT-MKT-05 | Slug no elegible | No se expone ficha ni motivo administrativo | PENDIENTE_EJECUCION |
| CT-MKT-06 | Producto con variantes | `variant_id != sku` | PENDIENTE_EJECUCION |
| CT-MKT-07 | Precio regular | Contrato de Pricing por SKU | PENDIENTE_EJECUCION |
| CT-MKT-08 | Precio con oferta | Regular/oferta diferenciados | PENDIENTE_EJECUCION |
| CT-MKT-09 | SKU sin existencias en fuente de cumplimiento determinada | HTTP 200 + `AGOTADO`, no 404; si la fuente no puede determinarse, `INDETERMINADO` | PENDIENTE_EJECUCION |
| CT-MKT-10 | Cupón no aplicable | Resultado de negocio conforme OpenAPI | PENDIENTE_EJECUCION |
| CT-MKT-11 | Recomendaciones | La operación allowlist enumera Marketplace/Chatbot/Retail; scope registry pending enumera solo Chatbot. Registrar discrepancia; no inferir grant G7. | PENDIENTE_ALINEACION_CONTRACTUAL_G7 |
| CT-MKT-12 | No fuga administrativa | Allowlist de campos comerciales; sin flags internos | PENDIENTE_EJECUCION |
| CT-MKT-13 | Correlación | `X-Correlation-Id` propagado | PENDIENTE_EJECUCION |

### Cobertura adicional del primer corte G1–G6

Los siguientes casos amplían la cobertura sin cambiar el significado de CT-MKT-01 a CT-MKT-13. Los operationId OpenAPI son `listarCategorias`, `listarProductos` y `obtenerProductoPorSlug`; el prefijo `/api/v1` procede de `servers.url`, no se omite en las solicitudes completas. `STATIC_CONTRACT` verifica estructura declarada, no comportamiento del proveedor. `PROVIDER_CONTRACT`, `CONSUMER_PROVIDER` y pruebas de seguridad necesitan ejecución independiente contra implementaciones identificadas.

| ID | Tipo | Operación OpenAPI / schema | Caso y resultado esperado | Estado |
|---|---|---|---|---|
| CT-MKT-14 | STATIC_CONTRACT | `listarCategorias`, `listarProductos`, `obtenerProductoPorSlug` | Rutas, `operationId`, `catalogo:leer`, audiencia `api-productos`, `pending-security-registration` y allowlists declaradas incluyen `modulo-marketplace`; se respetan los esquemas de seguridad publicados por cada operación. | PASS |
| CT-MKT-15 | STATIC_CONTRACT | `listarCategorias` → `Categoria` | `200` tiene wrapper `categories` de arreglo. `Categoria` requiere `categoria_id`, `name` y `status`; `status` permite `ACTIVA` o `INACTIVA`. No prohibir esa propiedad en el schema. | PASS |
| CT-MKT-16 | PROVIDER_CONTRACT | `listarCategorias` → `Categoria` | El endpoint comercial devuelve únicamente categorías activas; `categories: []` es una respuesta válida cuando no hay resultados. No devuelve campos administrativos. La validación estática de propiedades no acredita filtrado ni ausencia de filtraciones en runtime. | PENDIENTE_IMPLEMENTACION |
| CT-MKT-17 | STATIC_CONTRACT | `listarCategorias` | Contrato declara respuestas 401 `TOKEN_INVALIDO`, 403 `SCOPE_INSUFICIENTE`, 503 `SERVICIO_NO_DISPONIBLE`, `X-Correlation-Id` opcional y 429 con `Retry-After`. Llamadas de seguridad/disponibilidad real siguen pendientes. | PASS |
| CT-MKT-18 | STATIC_CONTRACT | `listarProductos` → `PaginaProductosComercial`, `ProductoResumenComercial` | `200` referencia `PaginaProductosComercial` (`items`, `pagina`, `tamanio`, `total`); `q` y `canal` se inspeccionan según OpenAPI. `pagina` tiene mínimo 1/default 1; `tamanio` mínimo 1/máximo 100/default 20. | PASS |
| CP-MKT-01 | CONSUMER_PROVIDER | BFF G1 F-007/F-010 ↔ `listarProductos` | G1 valida `page >= 0`, `1 <= pageSize <= 48`, `q` de 2 a 120 caracteres; `pageSize=24` de F-007 no es el default G6 20. Mapea `pagina=page+1`, `tamanio=pageSize` (página 0→1 y página 1→2), `items`→`data` y metadatos al contrato BFF. Si deriva `totalPages`, lo calcula desde `total` y tamaño efectivo. | PENDIENTE_IMPLEMENTACION |
| CT-MKT-19 | PROVIDER_CONTRACT | `listarProductos` → `PaginaProductosComercial` | Búsqueda `q` devuelve productos activos y comercialmente elegibles; producto activo no elegible queda excluido. Sin coincidencias: `200` con `items: []`, no 404. El G1 aplica su regla de longitud de `q`; OpenAPI G6 no incorpora los límites F-007. | PENDIENTE_IMPLEMENTACION |
| CT-MKT-20 | PROVIDER_CONTRACT | `listarProductos` | El filtro administrativo `estado` no permite a una identidad de canal ampliar visibilidad ni eludir elegibilidad. Solo se expone información comercial; inspeccionar propiedades declaradas no demuestra filtrado en runtime. | PENDIENTE_IMPLEMENTACION |
| CT-MKT-21 | STATIC_CONTRACT | `obtenerProductoPorSlug` → `ProductoDetalleComercial` | Ruta condicional requiere `slug` y `canal`; `200` referencia `ProductoDetalleComercial`, `404` declara `PRODUCTO_NO_ENCONTRADO`, y existen respuestas 401, 403, 503 y 429. Se conserva `userBearer` donde está publicado. | PASS |
| CT-MKT-22 | PROVIDER_CONTRACT | `obtenerProductoPorSlug` → `ProductoResumenComercial` | Slug elegible responde 200; inexistente/no elegible responde 404 sin motivo administrativo. Para un producto simple, validar funcionalmente `sku_base`: OpenAPI lo permite nullable y no lo requiere para todo resumen. | PENDIENTE_IMPLEMENTACION |
| CT-MKT-23 | PROVIDER_CONTRACT | `obtenerProductoPorSlug` → `VarianteComercial` | Para productos con variantes, validar `variant_id` y `sku` como identidades distintas y exponer solo variantes elegibles. El schema no incluye `status`; la validación de elegibilidad y la ausencia de campos administrativos necesitan prueba provider. | PENDIENTE_IMPLEMENTACION |
| CT-MKT-24 | STATIC_CONTRACT | `listarProductos`, `obtenerProductoPorSlug`, parámetro `CorrelationId` | `X-Correlation-Id` está declarado como header opcional UUID; `429` referencia `RateLimitExceeded` con header `Retry-After`. La propagación efectiva requiere prueba de integración. | PASS |
| CT-MKT-25 | SECURITY_INTEGRATION | Las tres operaciones del corte | Con JWT de servicio real, verificar según el contrato G7 que la identidad técnica está asociada a `client_id=modulo-marketplace`. Validar únicamente lo requerido por G6 `serviceBearer`: firma/JWKS, `iss`, `exp`, `tipo=servicio`, `aud` que contenga `api-productos`, scope de la operación y que `sub` identifique al `client_id`; comprobar además la allowlist por operación y negativos 401/403. No asumir que el texto literal de `sub` debe ser `modulo-marketplace` ni añadir claims no publicados. Mantener `userBearer` según cada operación. Requiere proveedor y grant/provisión efectivos de G7; el YAML no es prueba de autorización. | PENDIENTE_IMPLEMENTACION |

Los métodos `test_marketplace_*` comprueban únicamente aserciones `STATIC_CONTRACT` sobre el YAML cargado. Su `PASS` no cambia el estado de los casos provider, consumer/provider, autorización real ni integración BFF→G6.

## 3. Retail — código de barras

| ID | Caso | Resultado esperado | Estado |
|---|---|---|---|
| CT-RTL-BAR-01 | Producto simple | HTTP 200 + campo `sku` que identifica al SKU base vendible | PENDIENTE_EJECUCION |
| CT-RTL-BAR-02 | Variante | HTTP 200 + campo `sku` de la variante vendible | PENDIENTE_EJECUCION |
| CT-RTL-BAR-03 | Código inexistente | HTTP 404 `CODIGO_BARRAS_NO_ENCONTRADO` | PENDIENTE_EJECUCION |
| CT-RTL-BAR-04 | `0001234567890` | Se preserva la cadena completa, incluidos ceros iniciales | PENDIENTE_EJECUCION |
| CT-RTL-BAR-05 | Asociación no vendible | HTTP 404 sin filtrar motivo interno | PENDIENTE_EJECUCION |
| CT-RTL-BAR-06 | Response | Solo requiere `sku` (`ResolverCodigoBarrasResponse`) | PENDIENTE_EJECUCION |
| CT-RTL-BAR-07 | Allowlist | Solo `modulo-retail` | PENDIENTE_EJECUCION |
| IT-RTL-BAR-01 | Integridad | Un código no resuelve a dos SKU | PENDIENTE_IMPLEMENTACION |
| IT-RTL-BAR-02 | Continuidad | Resolver → SKU → precio/disponibilidad por SKU | PENDIENTE_IMPLEMENTACION |

## 4. Disponibilidad comercial

| ID | Caso | Resultado esperado | Estado |
|---|---|---|---|
| CT-AVL-01 | Marketplace | Accede a `/disponibilidad/comercial` con scope y client_id válidos | PENDIENTE_EJECUCION |
| CT-AVL-02 | Chatbot | Accede a `/disponibilidad/comercial` con scope y client_id válidos | PENDIENTE_EJECUCION |
| CT-AVL-03 | Retail | Accede a `/disponibilidad/comercial` con scope y client_id válidos | PENDIENTE_EJECUCION |
| CT-AVL-04 | Canal intenta disponibilidad detallada | Rechazado por allowlist | PENDIENTE_EJECUCION |
| CT-AVL-05 | M1/Ventas intenta disponibilidad detallada | Permitido contractualmente con scope y concesión efectiva; grant G7 por confirmar | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-AVL-06 | Shape comercial | `sku` y `status`; sin on_hand/reserved/blocked/available ni `location_id` | PENDIENTE_EJECUCION |
| CT-AVL-07 | Vocabulario | `DISPONIBLE`, `STOCK_BAJO`, `AGOTADO`, `INDETERMINADO` | PENDIENTE_EJECUCION |
| CT-AVL-08 | Lectura | No muta saldos, reservas ni Kardex | PENDIENTE_EJECUCION |
| CT-AVL-09 | M2/Postventa intenta disponibilidad detallada para CAMBIO | Permitido contractualmente con `inventario:disponibilidad:leer`; grant efectivo de G7 pendiente | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-AVL-B01 | Política D-INV-01 | No sumar ubicaciones independientes; un origen de cumplimiento único determinable o `INDETERMINADO` | PENDIENTE_IMPLEMENTACION |
| CT-AVL-B02 | Verificación comercial por cantidad | `SUFICIENTE` solo si una fuente ejecutable abastece toda la cantidad; `INSUFICIENTE` si está determinada pero no alcanza | PENDIENTE_IMPLEMENTACION |
| CT-AVL-B03 | Fuente no mapeada o ambigua | HTTP 200 + `INDETERMINADO`, sin revelar ubicación ni saldos | PENDIENTE_IMPLEMENTACION |
| CT-AVL-B04 | Contexto comercial semánticamente inválido | HTTP 422 + `CONTEXTO_ABASTECIMIENTO_INVALIDO`; no confundir con falta de mapeo | PENDIENTE_IMPLEMENTACION |
| CT-AVL-B05 | Verificación no vinculante | `binding=false`; no crea reserva ni promete stock futuro | PENDIENTE_IMPLEMENTACION |
| CT-AVL-B06 | Canal con scope de disponibilidad intenta GET detallado | HTTP 403 aun con `inventario:disponibilidad:leer`, por client_id fuera de la allowlist; usuario administrador usa autorización `userBearer` distinta | PENDIENTE_IMPLEMENTACION |
| CT-AVL-B07 | Contexto sin mapeo vs inválido | Falta de mapping o fuente ambigua produce respuesta de negocio `200 INDETERMINADO`; contexto semánticamente inválido `422 CONTEXTO_ABASTECIMIENTO_INVALIDO`; ninguna operación modifica stock | PENDIENTE_IMPLEMENTACION |

**D-INV-01:** la **decisión contractual ya está adoptada** en `arquitectura/decisiones/ADR-DEC-F-BLOQUEANTES.md` y `SPEC-015`. El bloqueo ahora es de implementación/validación, no de decisión. Se mantienen bloqueadas las políticas de recomendaciones multi-SKU no resueltas por D-REC, que constituyen un asunto distinto.

## 5. Recomendaciones

| ID | Caso | Resultado esperado | Estado |
|---|---|---|---|
| CT-REC-01 | Marketplace | Autorizado con `canal=MARKETPLACE` | PENDIENTE_EJECUCION |
| CT-REC-02 | Chatbot | Autorizado con `canal=CHATBOT` | PENDIENTE_EJECUCION |
| CT-REC-03 | Retail | Autorizado con `canal=RETAIL` | PENDIENTE_EJECUCION |
| CT-REC-04 | No elegible | Candidato excluido | PENDIENTE_EJECUCION |
| CT-REC-05 | Sin candidatos | HTTP 200 + `recommendations=[]` | PENDIENTE_EJECUCION |
| CT-REC-06 | Identidad | Recomendación principal por `product_id` | PENDIENTE_EJECUCION |
| CT-REC-07 | No fuga stock | Sin cantidades internas | PENDIENTE_EJECUCION |
| CT-REC-B01 | Availability product-level | Reutiliza `EstadoStock`, policy multi-SKU pendiente de decisión propia de Recomendaciones | BLOQUEADA_DECISION |
| CT-REC-B02 | Variantes → availability | Depende de `D-REC-01` | BLOQUEADA_DECISION |
| CT-REC-B03 | Variantes → current_price | Depende de `D-REC-02` | BLOQUEADA_DECISION |

## 6. Rate limiting

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-RATE-01 | HTTP 429 + `RATE_LIMIT_EXCEDIDO` | PENDIENTE_EJECUCION |
| CT-RATE-02 | `Retry-After` presente | PENDIENTE_EJECUCION |
| CT-RATE-03 | Correlación preservada | PENDIENTE_EJECUCION |
| CT-RATE-04 | Request limitada no produce efectos secundarios | PENDIENTE_IMPLEMENTACION |
| CT-RATE-05 | Test determinista con política controlable | PENDIENTE_IMPLEMENTACION |

## 7. Seguridad

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-SEC-01 | Token inválido → 401 `TOKEN_INVALIDO` | PENDIENTE_EJECUCION |
| CT-SEC-02 | `aud` sin `api-productos` → rechazo | PENDIENTE_EJECUCION |
| CT-SEC-03 | Scope insuficiente → HTTP 403 | PENDIENTE_EJECUCION |
| CT-SEC-04 | Scope correcto + cliente no permitido → rechazo | PENDIENTE_EJECUCION |
| CT-SEC-05 | Scope de disponibilidad no habilita automáticamente lectura detallada | PENDIENTE_EJECUCION |
| CT-SEC-06 | `modulo-ventas` con `inventario:operaciones:leer` obtiene token con `aud=api-productos`; otros clientes no reciben acceso a consultas de operaciones | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-SEC-07 | Los scopes de Productos para Chatbot definidos por G6 constan como confirmados y otorgados por G7, no solo propuestos | BLOQUEADA_DEPENDENCIA_EXTERNA |

Las pruebas con grants reales permanecen `BLOQUEADA_DEPENDENCIA_EXTERNA` mientras Seguridad no registre y aprovisione las concesiones. La existencia de `x-required-scope` en OpenAPI **no prueba** que G7 emita el scope.

## 8. Regresión Chatbot

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-CHAT-01 | Usa `/inventario/disponibilidad/comercial` | PENDIENTE_EJECUCION |
| CT-CHAT-02 | Sigue consumiendo `/recomendaciones?canal=CHATBOT` | PENDIENTE_EJECUCION |
| CT-CHAT-03 | No recibe cantidades internas | PENDIENTE_EJECUCION |

## 9. OPEN-08 — Ventas ↔ Inventario

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-SALES-01 | `CREADO` → reservar; `202` de Inventario **no** equivale a reserva confirmada | PENDIENTE_IMPLEMENTACION |
| CT-SALES-02 | `PAGADO` → confirmar consumo sin doble descuento | PENDIENTE_IMPLEMENTACION |
| CT-SALES-03 | Anulación pre-consumo → liberar | PENDIENTE_IMPLEMENTACION |
| CT-SALES-04 | Retry idéntico → replay seguro | PENDIENTE_IMPLEMENTACION |
| CT-SALES-05 | Misma identidad idempotente e intención distinta → `IDEMPOTENCY_CONFLICT` | PENDIENTE_IMPLEMENTACION |
| CT-SALES-06 | Ventas puede leer saldo detallado con grant correcto | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-SALES-07 | G5 no responde al canal `201 Created` declarando stock reservado/cupón consumido hasta tener confirmación definitiva, salvo nuevo acuerdo formal sobre semántica externa | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-SALES-08 | Correlación `order_id` opaco, `operation_id` UUID y resultado posterior recuperable por GET sin reejecutar comando | PENDIENTE_IMPLEMENTACION |

### Desglose de dependencias técnicas G5↔Inventario

La línea base revisada no contiene los identificadores `CT-G5-INV-04` ni `CT-G5-INV-05`. Para responder a la auditoría sin mezclar trabajo interno con gates externos, se desglosan a continuación. Los sufijos son casos distintos; sus estados no representan pruebas ejecutadas.

| ID | Tipo | Resultado esperado / dependencia | Estado |
|---|---|---|---|
| CT-G5-INV-04A | PROVIDER_CONTRACT | G6 persiste resultado definitivo de reserva/consumo/liberación y lo publica mediante Outbox tras commit; replay idempotente no duplica efectos | PENDIENTE_IMPLEMENTACION |
| CT-G5-INV-04B | INFRASTRUCTURE | Infraestructura confirma acceso al broker real, vhost coincidente con la candidata AsyncAPI `0.6.0-rc.2` (`g6-productos-ofertas`), credenciales, exchanges, colas y bindings; OCI `g6` solo está reportado, no verificado | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-G5-INV-04C | CONSUMER_PROVIDER | G5 consume el evento/result esperado de la operación G6 y correlaciona `operation_id`, `causation_id` y `correlation_id`; requiere proveedor/consumidor y broker identificados | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-G5-INV-05A | PROVIDER_CONTRACT | `GET /inventario/operaciones/{operationId}` devuelve el resultado persistido de la operación admitida sin reejecutar efectos | PENDIENTE_IMPLEMENTACION |
| CT-G5-INV-05B | SECURITY_INTEGRATION | G7 acredita registro, aprobación, grant y credencial para `modulo-ventas` con `inventario:operaciones:leer` y audiencia `api-productos` | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-G5-INV-05C | INTEGRATION | Tras respuesta `202`, M1 recupera por GET el resultado durable con token autorizado, sin reenviar el comando; registrar commit/versiones, entorno y resultado | BLOQUEADA_DEPENDENCIA_EXTERNA |

CT-G5-INV-04A y CT-G5-INV-05A son trabajo interno implementable en G6 sin esperar configuración OCI ni concesión de G7. Los casos 04B/04C y 05B/05C identifican dependencias externas concretas; cuando estas se resuelvan, la ejecución reproducible aún deberá documentarse antes de cambiar un estado a `PASS`.

**Acuerdo externo pendiente:** el contrato de G5 documenta `201 Created` con reserva/cupón confirmados. G6 documenta `202 Accepted` como admisión, no finalización. No alterar unilateralmente la API pública de G5: acordar espera interna de resultado o evolución versionada de su API.

## 10. OPEN-09 — Despacho ↔ Productos

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-DSP-01 | Batch de datos físicos por SKU | PENDIENTE_IMPLEMENTACION |
| CT-DSP-02 | Solo peso/dimensiones contractuales; no empaque | PENDIENTE_IMPLEMENTACION |
| CT-DSP-03 | Solo consumidor autorizado | PENDIENTE_EJECUCION |
| CT-DSP-04 | Sin stock/precio/pedido en respuesta física | PENDIENTE_EJECUCION |

## 11. Recuperación de preparación — Catálogo (FLOW-003 / FLOW-004 / endurecimiento contractual)

| ID | Tipo | Caso / Resultado esperado | Estado |
|---|---|---|---|
| CT-PREP-01 | PROVIDER_CONTRACT | `GET /productos/{productoId}/preparacion` devuelve detalle rico (`ProductoPreparacion`) con pricing, inventario de `sku_base` (o null si `tiene_variantes=true`) y variantes | PENDIENTE_EJECUCION |
| CT-PREP-02 | PROVIDER_CONTRACT | Estados `PENDING`, `COMPLETED` y `REJECTED` modelados con código funcional opcional en `code` | PENDIENTE_EJECUCION |
| CT-PREP-03 | PROVIDER_CONTRACT | `manual_retry_allowed=false` durante recuperación técnica automática ordinaria y PENDING en curso | PENDIENTE_EJECUCION |
| CT-PREP-04 | PROVIDER_CONTRACT | Recuperación manual de Pricing (`POST /productos/{productoId}/preparacion/reintentar` con `dependencia=PRICING`) devuelve HTTP 202 `OperationAccepted` | PENDIENTE_EJECUCION |
| CT-PREP-05 | PROVIDER_CONTRACT | Recuperación manual de Inventario de producto simple (`POST /productos/{productoId}/preparacion/reintentar` con `dependencia=INVENTARIO`) devuelve HTTP 202 `OperationAccepted` | PENDIENTE_EJECUCION |
| CT-PREP-06 | PROVIDER_CONTRACT | Recuperación manual de Inventario de variante (`POST /productos/{productoId}/variantes/{variantId}/preparacion/reintentar`) devuelve HTTP 202 `OperationAccepted` | PENDIENTE_EJECUCION |
| CT-PREP-07 | STATIC_CONTRACT | Variante no puede solicitar inicialización de Pricing; contrato de variante solo expone reintento de inventario | PENDIENTE_EJECUCION |
| CT-PREP-08 | PROVIDER_CONTRACT | Producto con variantes (`tiene_variantes=true`) rechaza reintento de inventario a nivel padre | PENDIENTE_EJECUCION |
| CT-PREP-09 | PROVIDER_CONTRACT | Respuesta HTTP 202 `OperationAccepted` formaliza admisión de recuperación, no terminación exitosa ni COMPLETED | PENDIENTE_EJECUCION |
| CT-PREP-10 | INTEGRATION | Admisión de recuperación manual conserva `operation_id` original de la preparación para correlación e idempotencia | PENDIENTE_IMPLEMENTACION |
| CT-PREP-11 | INTEGRATION | Republicación de comando por recuperación manual genera nueva `message_id` para transporte RabbitMQ | PENDIENTE_IMPLEMENTACION |
| CT-PREP-12 | PROVIDER_CONTRACT | Dependencia con estado COMPLETED nunca vuelve a ejecutarse ni reintentarse | PENDIENTE_EJECUCION |
| CT-PREP-13 | PROVIDER_CONTRACT | Solicitud de reintento sobre preparación no recuperable (en curso técnico, COMPLETED o sin precondiciones) devuelve HTTP 409 `PREPARACION_NO_REINTENTABLE` | PENDIENTE_EJECUCION |
| CT-PREP-14 | INTEGRATION | Concurrencia atómica de reintento: exactamente 1 solicitud obtiene 202 Accepted, solicitudes concurrentes competidoras obtienen 409 PREPARACION_NO_REINTENTABLE, exactamente 1 sola publicación efectiva | PENDIENTE_IMPLEMENTACION |
| CT-PREP-15 | STATIC_CONTRACT | Schemas comerciales (`ProductoResumenComercial`, `ProductoDetalleComercial`, variantes comerciales) no exponen estado administrativo de preparación | PENDIENTE_EJECUCION |
| CT-PREP-16 | ARCHITECTURE_INVARIANT | Recuperación manual de preparación no introduce mensajes propios adicionales; reutiliza comandos/resultados de inicialización de Pricing e Inventario (sin prohibir los mensajes nuevos de otros flujos de `0.6.0-rc.1`) | PENDIENTE_EJECUCION |
| CT-PREP-17 | PROVIDER_CONTRACT | REJECTED no habilita automáticamente un reintento (`manual_retry_allowed=false`) mientras las precondiciones funcionales sigan inválidas | PENDIENTE_IMPLEMENTACION |
| CT-PREP-18 | PROVIDER_CONTRACT | Edición válida del borrador provoca reevaluación autoritativa de elegibilidad en Catálogo; si las precondiciones de la preparación quedan satisfechas, `manual_retry_allowed=true`; de lo contrario permanece `false` | PENDIENTE_IMPLEMENTACION |
| CT-PREP-19 | ARCHITECTURE_INVARIANT | `manual_retry_allowed` es potestad exclusiva del backend; la UI no puede forzar la admisión sin precondiciones validadas | PENDIENTE_IMPLEMENTACION |
| CT-PREP-20 | PROVIDER_CONTRACT | Endpoint POST de reintento revalida las precondiciones antes de admitir para prevenir TOCTOU (devuelve 409 si ya no es reintentable) | PENDIENTE_IMPLEMENTACION |
| CT-PREP-21 | INTEGRATION | Nuevo comando `*.requested` publicado tras corrección se construye usando el estado actual validado del borrador (no el payload antiguo) | PENDIENTE_IMPLEMENTACION |
| CT-PREP-22 | INTEGRATION | Consumidor reconoce que misma `operation_id` con nueva `message_id` tras `REJECTED` autorizado representa un nuevo intento de la misma preparación y no una segunda entidad | PENDIENTE_IMPLEMENTACION |
| CT-PREP-23 | INTEGRATION | Misma `operation_id` recibida cuando la preparación ya está `COMPLETED` se descarta idempotentemente sin reejecución de efectos | PENDIENTE_IMPLEMENTACION |
| CT-PREP-24 | ARCHITECTURE_INVARIANT | Agotamiento del retry técnico del consumidor y su envío a DLQ no requiere que Catálogo lea la DLQ; Catálogo permanece en PENDING hasta el umbral operativo | PENDIENTE_IMPLEMENTACION |
| CT-PREP-25 | INTEGRATION | Correlación por intento mediante `causation_id`: resultado (`*.completed` / `*.rejected`) porta `causation_id = message_id` del `*.requested` activo y actualiza autoritativamente el estado en Catálogo | PENDIENTE_IMPLEMENTACION |
| CT-PREP-26 | INTEGRATION | Descarte de resultados stale: resultado tardío con `causation_id` de un intento previo se ignora/registra idempotentemente como stale sin alterar el estado del intento activo | PENDIENTE_IMPLEMENTACION |
| CT-PREP-27 | INTEGRATION | Coexistencia de identidades: dos intentos distintos de la misma preparación comparten `operation_id` pero generan `message_id` distintos en cada publicación | PENDIENTE_IMPLEMENTACION |
| CT-PREP-28 | PROVIDER_CONTRACT | Inadmisibilidad de reintento por mutación no publicada: rechazo de pricing que exija modificar precio base inicial mantiene `manual_retry_allowed=false` por carecer de endpoint de modificación de precio inicial en borrador | PENDIENTE_IMPLEMENTACION |
| CT-PREP-29 | STATIC_CONTRACT | Validación de schema AsyncAPI: mensaje de inicialización sin `operation_id` o resultado de inicialización sin `causation_id` es rechazado | PENDIENTE_EJECUCION |
| CT-PREP-30 | PROVIDER_CONTRACT | PENDING prolongado tras umbral operativo configurable habilita `manual_retry_allowed=true` manteniendo `PENDING` sin consultar DLQ del consumidor | PENDIENTE_IMPLEMENTACION |

## 12. Evidencia y control de ejecución

Cada prueba ejecutada debe registrar, cuando aplique:

```text
test_id
timestamp
commit SHA provider
commit SHA consumer
OpenAPI version y AsyncAPI version
entorno
resultado y salida reproducible
correlation_id
workflow/run o evidencia de ejecución SQL
```

No almacenar JWT completos, secretos ni PII. Una ejecución exitosa contra mocks **no** equivale a un proveedor real funcionando. No deducir del código de una prueba que esta fue ejecutada.

**Evidencia SQL obtenida durante la revisión del PR #86, sin elevar los casos HTTP/eventos a PASS:**

| Verificación | Evidencia comunicada | Alcance |
|---|---|---|
| Postcheck estructural Supabase | 24/24 verificaciones satisfactorias | Estructura, permisos e historial; no integración E2E |
| `datos/inventory-svc/validation.sql` | `VALIDACION_FINALIZADA_SATISFACTORIAMENTE`, 16 tablas | Validación SQL de Inventario con reversión de datos de prueba |
| `datos/promotions/validation.sql` | `132` aserciones, `PASS` | Validación SQL de Promociones con reversión de datos de prueba |

Esta evidencia proviene de las ejecuciones comunicadas por el responsable; no sustituye logs, SHA exacto de cada ejecución ni pruebas concurrentes de servicios desplegados. Las migraciones `0002` de Inventario y `0004` de Promociones ya se aplicaron: **no reejecutarlas** para validar cambios documentales.

## 13. Pruebas específicas `0.6.0-rc.1` — Cuatro bloqueantes G6

| ID | Tipo | Resultado esperado | Estado |
|---|---|---|---|
| CT-G6-B1-01 | PROVIDER_CONTRACT | `order_id=PED-*` se conserva como cadena opaca; `operation_id` y `reservation_id` son UUID | PENDIENTE_IMPLEMENTACION |
| CT-G6-B1-02 | INTEGRATION | Operación recuperable por GET después de pérdida de respuesta/evento; consultar no dispara una segunda operación | PENDIENTE_IMPLEMENTACION |
| CT-G6-B1-03 | INTEGRATION | Correlación estable entre solicitud, fila persistida, `operation_id`, `message_id`, `correlation_id` y `causation_id` | PENDIENTE_IMPLEMENTACION |
| CT-G6-B2-01 | INTEGRATION | Reserva rechazada después de HTTP `202` emite `inventory.reservation.rejected` v2 con código funcional no vacío | PENDIENTE_IMPLEMENTACION |
| CT-G6-B2-02 | INTEGRATION | Mensajes críticos v2 conservan `operation_id` y `causation_id`; replay no duplica efectos | PENDIENTE_IMPLEMENTACION |
| CT-G6-B2-03 | PROVIDER_CONTRACT | Consumo rechazado de Inventario y de cupón requiere `result_code` estable no vacío, compatible con AsyncAPI | PENDIENTE_IMPLEMENTACION |
| CT-G6-B2-04 | PROVIDER_CONTRACT | Restauración de cupón rechazada usa payload propio con `result_code`; `outcome` se reserva a resultados completados | PENDIENTE_IMPLEMENTACION |
| CT-G6-B3-01 | INTEGRATION | Cinco unidades en dos tiendas no se suman para una ubicación sin política multi-origen | PENDIENTE_IMPLEMENTACION |
| CT-G6-B3-02 | PROVIDER_CONTRACT | Tienda no mapeada o ambigua devuelve `INDETERMINADO` sin divulgar saldos | PENDIENTE_IMPLEMENTACION |
| CT-G6-B3-03 | PROVIDER_CONTRACT | Verificación comercial por cantidad devuelve `binding=false`, no reserva y no expone `location_id` | PENDIENTE_IMPLEMENTACION |
| CT-G6-B4-01 | INTEGRATION | Mismo cupón, operación e intención: replay sin doble consumo | PENDIENTE_IMPLEMENTACION |
| CT-G6-B4-02 | INTEGRATION | Operación reutilizada con fingerprint diferente: `IDEMPOTENCY_CONFLICT` | PENDIENTE_IMPLEMENTACION |
| CT-G6-B4-03 | INTEGRATION | Cupón consumido + pago fallido: restauración según política y sin duplicaciones | PENDIENTE_IMPLEMENTACION |
| CT-G6-B4-04 | INTEGRATION | Fallo técnico entre persistencia y outbox no pierde resultado definitivo | PENDIENTE_IMPLEMENTACION |
| CT-G6-B4-05 | INTEGRATION | Sin `consumption_operation_id`, una restauración transitoria solo puede resolverse inequívocamente por pedido; con ambigüedad no ejecuta efectos | BLOQUEADA_DECISION |
| CT-G6-B4-06 | INTEGRATION | Con `consumption_operation_id` explícito, restauración corresponde al consumo original; no se acepta correlación cruzada entre pedidos | PENDIENTE_IMPLEMENTACION |

## 13.1. Conciliación Retail offline — DEC-F-013/014/015

Estos casos describen la fotografía del contrato candidato `0.6.0-rc.1` y las pruebas futuras requeridas. Las verificaciones estáticas no aprueban la permanencia futura de sus incompatibilidades conocidas; los estados no afirman implementación, grants efectivos ni homologación.

### 13.1.1. Contrato estático candidato

| ID | Tipo | Resultado esperado | Estado |
|---|---|---|---|
| CT-OFF-STATIC-01 | STATIC_CONTRACT | Existe `POST /inventario/conciliaciones-offline`, `operationId=conciliarVentaOffline`, `x-status=provisional`; request y respuesta `200` referencian `ConciliacionOfflineRequest` y `ConciliacionOfflineResponse` | PENDIENTE_EJECUCION |
| CT-OFF-STATIC-02 | STATIC_CONTRACT | Allowlist actual exclusiva `modulo-ventas`; scope `inventario:conciliar-offline`; `serviceBearer`; registro de scope `pending-security-registration` | PENDIENTE_EJECUCION |
| CT-OFF-STATIC-03 | STATIC_CONTRACT | Request actual: `operation_id` UUID, `order_id` string opaco, `offline_sale_id` string independiente, `channel_id=RETAIL`, `occurred_at` date-time y `lines` array; no confundir `channel_id` con cliente técnico | PENDIENTE_EJECUCION |
| CT-OFF-STATIC-04 | STATIC_CONTRACT | `ConciliacionOfflineRequest.lines` referencia actualmente `LineaInventarioUbicada`, cuyo `location_id` es requerido. Es una fotografía del candidato e incompatibilidad pendiente frente a DEC-F-014, no aprobación de permanencia | PENDIENTE_EJECUCION |
| CT-OFF-STATIC-05 | STATIC_CONTRACT | `ConciliacionOfflineResponse` requiere `operation_id`, `order_id`, `offline_sale_id`, `status`, `lines` y `completed_at`; línea expone cantidades funcionales y actualmente requiere `location_id`, `on_hand`, `reserved`, `blocked`, `available`, `stock_version`. Fotografía candidata e incompatibilidad DEC-F-015; no aprobación futura | PENDIENTE_EJECUCION |
| CT-OFF-STATIC-06 | STATIC_CONTRACT | Los estados candidatos son `COMPLETED` y `REQUIRES_REVIEW`; la conciliación exitosa responde `200` | PENDIENTE_EJECUCION |
| CT-OFF-STATIC-07 | STATIC_CONTRACT | La ruta declara `409` con `IDEMPOTENCY_CONFLICT` en la respuesta y en `x-error-codes` | PENDIENTE_EJECUCION |

### 13.1.2. Invariantes provider y conciliación

| ID | Tipo | Resultado esperado | Estado |
|---|---|---|---|
| CT-OFF-PROV-01 | PROVIDER_CONTRACT | Venta completamente aplicada devuelve `COMPLETED` | PENDIENTE_IMPLEMENTACION |
| CT-OFF-PROV-02 | PROVIDER_CONTRACT | Aplicación parcial devuelve `REQUIRES_REVIEW` y conserva `requested_quantity`, `applied_quantity` y `unresolved_quantity` | PENDIENTE_IMPLEMENTACION |
| CT-OFF-PROV-03 | PROVIDER_CONTRACT | Con cero unidades aplicadas el resultado queda registrado y no se genera movimiento Kardex de cantidad cero | PENDIENTE_IMPLEMENTACION |
| CT-OFF-PROV-04 | PROVIDER_CONTRACT | La conciliación no consume unidades reservadas ni bloqueadas | PENDIENTE_IMPLEMENTACION |
| CT-OFF-PROV-05 | PROVIDER_CONTRACT | La conciliación nunca produce `on_hand` negativo | PENDIENTE_IMPLEMENTACION |
| CT-OFF-PROV-06 | PROVIDER_CONTRACT | Una mutación efectiva registra Kardex y el cambio de saldo/resultado se mantiene atómico | PENDIENTE_IMPLEMENTACION |
| CT-OFF-PROV-07 | PROVIDER_CONTRACT | Para la misma identidad técnica del comando, replay semánticamente idéntico devuelve el resultado previo sin nuevos efectos; no prueba la deduplicación de una venta con otro `operation_id` | PENDIENTE_IMPLEMENTACION |
| CT-OFF-PROV-08 | PROVIDER_CONTRACT | Para la misma identidad técnica del comando, contenido distinto produce `409 IDEMPOTENCY_CONFLICT` sin efectos; no prueba la deduplicación de una venta con otro `operation_id` | PENDIENTE_IMPLEMENTACION |
| CT-OFF-PROV-09 | INTEGRATION | La misma venta física con otro `operation_id` no causa doble descuento | BLOQUEADA_DECISION |
| CT-OFF-PROV-10 | INTEGRATION | Sin reserva de Inventario confirmada, el flujo vigente de conciliación offline no inicia consumo de cupón | PENDIENTE_IMPLEMENTACION |

El caso de replay entre distintos `operation_id` queda bloqueado hasta homologar la identidad estable de venta y su ámbito de unicidad. Los casos de replay/conflicto del comando con identidad técnica estable no resuelven esa brecha. No se prescriben campo, clave, fingerprint, índice ni mecanismo de persistencia.

### 13.1.3. Seguridad y autorización

| ID | Tipo | Resultado esperado | Estado |
|---|---|---|---|
| CT-OFF-SEC-01 | SECURITY_INTEGRATION | Token ausente o inválido es rechazado antes de procesar la conciliación | PENDIENTE_IMPLEMENTACION |
| CT-OFF-SEC-02 | SECURITY_INTEGRATION | Token sin `inventario:conciliar-offline` es rechazado | PENDIENTE_IMPLEMENTACION |
| CT-OFF-SEC-03 | SECURITY_INTEGRATION | Cliente fuera de la allowlist es rechazado aunque presente el scope nominal | PENDIENTE_IMPLEMENTACION |
| CT-OFF-SEC-04 | SECURITY_INTEGRATION | Verificar el registro y grant efectivo de G7 para el cliente autorizado | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-OFF-SEC-05 | PROVIDER_CONTRACT | Una vez homologada una entrada compatible con la resolución interna, mapeo inexistente o ambiguo impide la mutación | BLOQUEADA_DECISION |
| CT-OFF-SEC-06 | SECURITY_INTEGRATION | Actor no autorizado para la operación o ubicación no puede mutar | PENDIENTE_IMPLEMENTACION |
| CT-OFF-SEC-07 | SECURITY_INTEGRATION | Se autoriza al actor antes de devolver cualquier resultado persistido de replay | PENDIENTE_IMPLEMENTACION |
| CT-OFF-SEC-08 | SECURITY_INTEGRATION | El permiso de consulta comercial de disponibilidad no autoriza conciliación | PENDIENTE_IMPLEMENTACION |

La allowlist y el scope documentados no acreditan permisos efectivos. No atribuir a G7 concesiones aún pendientes ni habilitar Retail directamente.

### 13.1.4. Homologación y compatibilidad externa

| ID | Tipo | Resultado esperado | Estado |
|---|---|---|---|
| CT-OFF-HOM-01 | CONSUMER_PROVIDER | Una vez aprobada la correspondencia, la prueba verifica que la identidad G4 de la venta corresponde inequívocamente a la identidad estable declarada en G6 | BLOQUEADA_DECISION |
| CT-OFF-HOM-02 | CONSUMER_PROVIDER | Una vez homologados invocador y secuencia, la prueba verifica que el consumidor invoca el actor acordado y sigue el flujo publicado, sin inferir orden previo entre venta, pedido, pago y conciliación | BLOQUEADA_DECISION |
| CT-OFF-HOM-03 | CONSUMER_PROVIDER | Una vez publicado el tratamiento G4/G5, para una venta sincronizada después de 72 horas la respuesta observable coincide con ese tratamiento | BLOQUEADA_DECISION |
| CT-OFF-HOM-04 | CONSUMER_PROVIDER | Una vez acordada la representación, la respuesta observada por Retail contiene solo los datos minimizados convenidos y la respuesta contractual actual de Ventas conserva su forma aprobada | BLOQUEADA_DECISION |
| CT-OFF-HOM-05 | CONSUMER_PROVIDER | Cualquier flujo alternativo de cupón offline sin reserva confirmada requiere contrato y acuerdo explícitos antes de probarse | BLOQUEADA_DECISION |
| CT-OFF-HOM-06 | CONSUMER_PROVIDER | La prueba consumer-provider valida la compatibilidad y transición de los consumidores desde la línea base `0.5.0` antes de publicar cambios incompatibles | BLOQUEADA_DECISION |
| CT-OFF-HOM-07 | GOVERNANCE | G4 actualiza/ratifica formalmente que Retail invoca G6 directamente y alinea F10/§5.10 con el actor, flujo e identidad offline acordados; la confirmación G5 del 2026-10-14 por sí sola no supera este gate | BLOQUEADA_DECISION |
| CT-OFF-HOM-08 | SECURITY_INTEGRATION | G7 aprueba/registra `inventario:conciliar-offline` para audiencia `api-productos` y `modulo-retail`, y evidencia grant y credencial provisionada antes de la llamada real | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-OFF-HOM-09 | CONSUMER_PROVIDER | Tras homologar y versionar el contrato, Retail envía la referencia pública acordada sin `location_id`; G6 resuelve la ubicación internamente y la respuesta observable cumple DEC-F-015 | BLOQUEADA_DECISION |

### Puertas de integración pendientes

1. **G5 Ventas:** acordar si espera la confirmación asíncrona de stock y cupón antes de responder `201 Created` al canal, o publica una evolución versionada de su API. `202` de Inventario nunca equivale por sí mismo a éxito.
2. **G5 y G6 Promociones:** acordar el carácter obligatorio o transitorio de `consumption_operation_id`, verificando correlación unívoca por pedido en la versión actual. No volver obligatorio ese campo en AsyncAPI sin acuerdo y transición.
3. **G7 Seguridad:** registrar y aprobar `inventario:operaciones:leer` para `modulo-ventas` y confirmar la lista de scopes de Productos para Chatbot (A9). La documentación `x-required-scope` no acredita emisión de tokens.
4. **G1/G3/G4 y otros consumidores:** comunicar el estado `INDETERMINADO` y la prohibición de sumar saldos de ubicaciones independientes; ejecutar pruebas consumer-provider al contar con APIs reales.
5. **G6 backend:** completar handlers, outbox/inbox, adaptadores v1↔v2 cuando correspondan, autorización y pruebas E2E; no declarar `0.6.0-rc.1` desplegado antes de terminar.

## 14. Política de compatibilidad y trazabilidad

- `ADR-DEC-F-BLOQUEANTES.md` establece las decisiones B1–B4; esta matriz aporta pruebas, **no crea nuevas decisiones de negocio**.
- OpenAPI y AsyncAPI son las fuentes canónicas de forma, rutas, mensajes y errores. `catalogo-errores.md` es catálogo humano del vocabulario; los códigos deben coincidir con `ErrorCode`.
- Los identificadores `CT-STATIC-*`, `CT-AVL-*`, `CT-G6-*`, los 30 `CT-PREP-*` existentes y `CT-OFF-*` se conservan para trazabilidad; los nuevos casos se agregan con IDs únicos.
- Los conteos de canales, mensajes, rutas y códigos deben recalcularse tras cada modificación; no adaptar expectativas para ocultar una pérdida accidental de contratos.
- Cambiar una restricción de payload puede afectar consumidores aun sin cambiar el nombre del mensaje. Revisar compatibilidad, versionado de `schema_version` y adaptadores antes del despliegue.
- Mantener los casos funcionales `PENDIENTE_IMPLEMENTACION` o `PENDIENTE_EJECUCION` hasta contar con evidencias del proveedor real. `PASS` requiere resultado reproducible asociado a un commit y un entorno. La inspección documental de esta tarea **no cambia estados** ni satisface los grants de Seguridad/G7.

## 13.2. Homologación G5 F3 — reintegro Postventa

Los estados separan inspección estática, requisito de proveedor, seguridad real e integración entre módulos. Ningún estado `PASS` se infiere de esta documentación. Los casos funcionales nuevos permanecen sin ejecutar mientras no exista backend verificable.

| ID | Tipo | Resultado esperado | Estado |
|---|---|---|---|
| CT-G5-F3-STATIC-01 | STATIC_CONTRACT | `POST /inventario/reintegros` conserva allowlist exacta `modulo-ventas`, `modulo-postventa` | PENDIENTE_EJECUCION |
| CT-G5-F3-STATIC-02 | STATIC_CONTRACT | `modulo-postventa` requiere `inventario:reintegrar`, audiencia `api-productos`, `serviceBearer` y scope con registro pendiente | PENDIENTE_EJECUCION |
| CT-G5-F3-STATIC-03 | STATIC_CONTRACT | Request mantiene campos/tipos canónicos: `operation_id` UUID, `order_id` string opaco, `source_ref`, `reason`, `lines[]` con SKU, cantidad y ubicación | PENDIENTE_EJECUCION |
| CT-G5-F3-STATIC-04 | STATIC_CONTRACT | El enum admite `DEVOLUCION_ACEPTADA` para F3 | PENDIENTE_EJECUCION |
| CT-G5-F3-PROVIDER-01 | PROVIDER_CONTRACT | Aprobación comercial sin recepción física confirmada no habilita reintegro ni aumenta stock | PENDIENTE_IMPLEMENTACION |
| CT-G5-F3-PROVIDER-02 | PROVIDER_CONTRACT | Solo se reintegra cantidad recibida físicamente y apta para reventa; cantidades solicitada, recibida, apta y reintegrada se distinguen | PENDIENTE_IMPLEMENTACION |
| CT-G5-F3-PROVIDER-03 | PROVIDER_CONTRACT | Replay idéntico conserva `operation_id` y payload y no duplica saldo ni Kardex | PENDIENTE_IMPLEMENTACION |
| CT-G5-F3-PROVIDER-04 | PROVIDER_CONTRACT | Una nueva recepción parcial efectiva utiliza otra identidad lógica (`operation_id`) | PENDIENTE_IMPLEMENTACION |
| CT-G5-F3-STATIC-05 | STATIC_CONTRACT | Éxito de reintegro documentado como HTTP `200` con `status: COMPLETED` | PENDIENTE_EJECUCION |
| CT-G5-F3-STATIC-06 | STATIC_CONTRACT | M2 no aparece en scopes/allowlists de reserva, consumo, liberación, conciliación offline ni consulta de operaciones | PENDIENTE_EJECUCION |
| CT-G5-F3-SEC-01 | SECURITY_INTEGRATION | M2 usa scope de reintegro y disponibilidad solo tras credenciales de servicio y grants efectivos de G7; no hay concesión confirmada | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-G5-F3-STATIC-07 | STATIC_CONTRACT | GET detallado incluye M2 contractualmente bajo scope/allowlist, pero el grant de G7 no está confirmado | PENDIENTE_EJECUCION |
| CT-G5-F3-SEC-02 | SECURITY_INTEGRATION | Probar tokens reales `client_credentials`, audiencia `api-productos` y permisos concedidos de M2 | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-G5-F3-CP-01 | CONSUMER_PROVIDER | G5 consume el payload acordado, recupera `items[].sku` del pedido original y ejecuta F3 tras recepción física apta | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-G5-F3-CP-02 | CONSUMER_PROVIDER | Integración controlada G5↔G6 verifica `200 COMPLETED`, idempotencia y ausencia de duplicados | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-G5-F3-DEP-01 | PROVIDER_CONTRACT | Ubicación receptora real y mecanismo de resolución de `location_id` se definen sin asumir un valor; el campo sigue obligatorio en el OpenAPI | BLOQUEADA_DEPENDENCIA_EXTERNA |

La homologación contractual documentada en G5 issue #51 no acredita implementación, grant de G7 ni integración E2E.

## Addendum contractual `0.6.0-rc.1` — Cuatro bloqueantes G6

**Decisiones internas aceptadas; publicación y despliegue pendientes.**

- `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- `POST /inventario/reservas`, `/confirmar` y `/liberar` responden `202` solamente cuando admiten el comando. El éxito/rechazo se determina por resultado persistido y evento.
- Contratos provisionales: `GET /inventario/operaciones/{operationId}` (solo Ventas; scope `inventario:operaciones:leer`) y `POST /inventario/disponibilidad/comercial/verificar` (canales; consulta sin efectos secundarios).
- Nuevo evento `inventory.reservation.rejected`; reserva/consumo/liberación/expiración publican datos tipados y correlación obligatoria. Los rechazos definitivos v2 llevan `result_code` no vacío conforme a la corrección candidata de AsyncAPI.
- D-INV-01: no sumar saldos independientes; devolver `INDETERMINADO` cuando no puede resolverse un punto único de cumplimiento. `SUFICIENTE` exige una fuente realizable para la cantidad completa y no supone reserva.
- Cupones: después de reserva confirmada, Ventas envía `reservation_id` y `commercial_snapshot_ref` para solicitar consumo; restauración según política y correlación acordada. La obligatoriedad de `consumption_operation_id` en nuevos contratos queda pendiente de G5/G6.
- Misma identidad/operación/payload semántico produce replay sin efectos nuevos; identidad reutilizada con payload diferente produce conflicto. `message_id` identifica cada entrega RabbitMQ.
- Las transiciones pagar/expirar/liberar se serializan por reserva y respetan el `expires_at` real de Inventario.
- Estos contratos siguen **provisionales** hasta que backend, seguridad y pruebas integradas demuestren conformidad. No comunicar disponibilidad real por el solo hecho de que el esquema SQL fue validado.

## Marketplace H4: cobertura adicional y evidencias

Casos ampliados CT-MKT:

| ID | Tipo | Caso / aserción | Estado |
|---|---|---|---|
| CT-MKT-26 | PROVIDER_CONTRACT | Producto simple elegible usa `sku_base` cuando corresponda; no deduce SKU de IDs | PENDIENTE_PROVIDER |
| CT-MKT-27 | PROVIDER_CONTRACT | Producto con variantes conserva `variant_id != sku`; variantes no elegibles se excluyen | PENDIENTE_PROVIDER |
| CT-MKT-28 | CONSUMER_PROVIDER | G1 page 0/1 se traduce a G6 pagina 1/2; pageSize y metadatos se preservan | PENDIENTE |
| CT-MKT-29 | PROVIDER_CONTRACT | Filtros publicados aplican globalmente; múltiples/precio no se simulan sobre página parcial | PENDIENTE; brecha explícita |
| CT-MKT-30 | PROVIDER_CONTRACT | Disponibilidad mapea los cuatro estados; `INDETERMINADO` es 200 distinto de 404/5xx | PENDIENTE_PROVIDER |
| CT-MKT-31 | PROVIDER_CONTRACT | POST verificación con N líneas devuelve SUFICIENTE/INSUFICIENTE/INDETERMINADO y `binding=false`; no reserva | PENDIENTE_PROVIDER |
| CT-MKT-32 | PROVIDER_CONTRACT | Contexto fulfillment válido, ausente/ambiguo y semánticamente inválido: fuente no resoluble → indeterminado; inválido → 422 conforme al contrato | PENDIENTE; contexto G2/G5/G6 |
| CT-MKT-33 | PROVIDER_CONTRACT | Promoción aplicable/no aplicable y cupón válido/inválido no consumen beneficio | PENDIENTE_HTTP_HANDLER |
| CT-MKT-34 | STATIC_CONTRACT | OperationIds y schemas de catálogo, precio, inventario, promoción, cupón/recomendación concuerdan con OpenAPI | Validar en suite estática existente |
| CT-MKT-35 | SECURITY_INTEGRATION | JWT firmado, audience/cliente/scope/allowlist válidos permite operación | PENDIENTE_GRANT_G7 |
| CT-MKT-36 | SECURITY_INTEGRATION | Sin scope o cliente no autorizado → 403; token expirado/firma inválida → 401 | PENDIENTE_SEGURIDAD |
| CT-MKT-37 | CONSUMER_PROVIDER | timeout, error upstream y respuesta/schema inválido no se traducen a INDETERMINADO/AGOTADO; correlación conservada | PENDIENTE |
| CT-MKT-38 | PROVIDER_CONTRACT | Búsqueda sin coincidencias → 200 vacío; producto no elegible no se filtra fuera de elegibilidad | PENDIENTE_PROVIDER |
| CT-MKT-39 | E2E | Recorrido BFF G1→Gateway→owner con JWT real, dataset identificado y error/reintento | PENDIENTE_E2E |
| CT-MKT-40 | E2E | Journey Marketplace completo con BFF/Gateway/owners, identidad real y dataset identificado; confirmar que el resultado corresponde a la función ejecutada | PENDIENTE_E2E |

## Funciones de carrito, checkout y favoritos — evidencia separada

Cada caso corresponde a una función G1 distinta; las llamadas G6 son dependencias de datos y no trasladan el ownership del BFF.

| ID | Función | Verificación | Estado |
|---|---|---|---|
| CT-MKT-41 | F-019 visualizar carrito | La lectura del carrito G1 no modifica cantidades; errores de enriquecimiento conservan representación coherente o atención por línea. | PENDIENTE_G1_E2E |
| CT-MKT-42 | F-020 fusionar carrito anónimo | Fusión, propiedad, concurrencia, transacción e idempotencia son G1; verificación Inventory `binding=false` no autoriza por sí sola cantidad ajustada para mutación. | PENDIENTE_G1_E2E |
| CT-MKT-43 | F-021 mover ítem del carrito a favoritos | G1 valida identidad/elegibilidad, upsert Wishlist y borra línea transaccionalmente; no evalúa promociones ni muta stock. | PENDIENTE_G1_E2E |
| CT-MKT-44 | F-023 cotización de checkout | G1 compone datos Catalog/Pricing/Inventory/Promotions según uso y consulta cotización de envío G2; la ruta BFF no se atribuye a G6 y quote vencida no se prepara. | PENDIENTE_G1_G2_G5 |
| CT-MKT-45 | F-024 validar/aplicar cupón | Promotions `evaluarPromociones` y `validarCupon`; evaluación/validación repetida no consume ni reserva. Consumo/restauración corresponde a secuencia G5. | PENDIENTE_HTTP_HANDLER |
| CT-MKT-46 | F-025 preparar checkout/revalidar stock | `verificarCantidadComercial` usa N y contexto aplicable; `SUFICIENTE` no reserva; `STOCK_NOT_AVAILABLE` solo se justifica con respuesta autoritativa para esa cantidad. | PENDIENTE_G1_G6_G2_G5 |
| CT-MKT-47 | F-026 crear pedido | G5 `POST /api/v1/pedidos`; retry conserva `Idempotency-Key` y payload; recuperación según G5; `CREADO` no es `PAGADO`; no inventar `pago.metodoPago`. | PENDIENTE_G1_G5 |
| CT-MKT-48 | F-036 agregar favorito | G1 persiste por identidad de producto definida; Catalog valida identidad/elegibilidad; no hay API Wishlist G6. | PENDIENTE_G1_E2E |
| CT-MKT-49 | F-037 visualizar favoritos | G1 devuelve solo titular; Catalog valida identidad/elegibilidad y Pricing/Inventory aportan datos actuales solo si la vista los presenta. | PENDIENTE_G1_E2E |
| CT-MKT-50 | F-038 quitar favorito/Deshacer | Delete es local G1; al restaurar se revalida el recurso y no se accede a Wishlist G6. | PENDIENTE_G1_E2E |
| CT-MKT-51 | F-039 mover favorito al carrito | G1 no elimina favorito hasta éxito; verifica selección de variante y consulta disponibilidad según cantidad; POST Inventory sigue no vinculante. | PENDIENTE_G1_E2E |
| CT-MKT-52 | F-006 inicio/categorías/destacados | Taxonomy `listarCategorias` y Catalog `listarProductos` se prueban como operaciones separadas; `featuredProducts[]` lo compone G1 y G6 no ofrece curaduría editorial. | PENDIENTE_PROVIDER_Y_BFF |

`STATIC_CONTRACT` solo verifica el YAML. Provider, Consumer/Provider, Seguridad y E2E son estados independientes. No marcar PASS sin ejecución vinculada a SHA exacto; ver [matriz de evidencia H4](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/castilla/integraciones/g1-marketplace/MATRIZ_OPERACIONES_H4.md).
