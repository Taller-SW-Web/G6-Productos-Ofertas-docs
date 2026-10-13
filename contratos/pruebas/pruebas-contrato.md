# Matriz de pruebas de contrato e integración — Productos y Ofertas

**Contrato HTTP objetivo:** OpenAPI `0.6.0-rc.1` (candidato, no publicado).
**Contrato asíncrono objetivo:** AsyncAPI `0.6.0-rc.1` (candidato, no publicado).
**Referencia exacta auditada:** PR #86, rama `nueva`, commit `c1769607f30e2cabf1449e33c877fa4ef41defe5`.
**Estado:** definición documental de casos; no asignar `PASS` a pruebas de API, eventos, seguridad o integración sin ejecución reproducible.

En el commit auditado, **ambos YAML candidatos ya están presentes**: `contratos/http/openapi.yaml` y `contratos/eventos/asyncapi.yaml`, con `info.version=0.6.0-rc.1`. Por tanto, no procede describir su sustitución como un paso futuro. Los casos estáticos permanecen `PENDIENTE_EJECUCION` **hasta disponer de ejecución reproducible de validadores y evidencia vinculada al commit**; tampoco se consideran superadas pruebas provider, seguridad o E2E. `0.5.0` es línea base de compatibilidad, no prueba de despliegue del candidato.

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
| CT-STATIC-08 | STATIC_CONTRACT | YAML válido, AsyncAPI 3.0.0, `info.version=0.6.0-rc.1`, **40 canales y 40 mensajes**, `$ref` resolubles; se conservan `operation_id` y `causation_id` obligatorios en resultados v2 críticos y en inicializaciones donde corresponda | PENDIENTE_EJECUCION |
| CT-STATIC-09 | STATIC_CONTRACT | `reservaId` de `POST /inventario/reservas/{reservaId}/confirmar` y `/liberar` tiene `type: string`, `format: uuid`; `order_id` sigue siendo cadena opaca | PENDIENTE_EJECUCION |
| CT-STATIC-10 | STATIC_CONTRACT | `GET /inventario/operaciones/{operationId}` exige UUID y restringe consumidor a `modulo-ventas`, scope `inventario:operaciones:leer`, sin publicar stock interno | PENDIENTE_EJECUCION |
| CT-STATIC-11 | STATIC_CONTRACT | `POST /inventario/disponibilidad/comercial/verificar` devuelve evaluación no vinculante sin `location_id` ni cantidades internas; `INDETERMINADO` es una salida de negocio válida | PENDIENTE_EJECUCION |
| CT-STATIC-12 | STATIC_CONTRACT | Los mensajes `inventory.consumption.rejected`, `promotions.coupon.consumption.rejected` y `promotions.coupon.restoration.rejected` requieren `result_code` no vacío y usan esquemas de rechazo propios | PENDIENTE_EJECUCION |
| CT-STATIC-13 | STATIC_CONTRACT | Los esquemas de éxito de consumo/restauración siguen independientes de los de rechazo; las nuevas referencias no alteran nombres de mensajes, exchanges ni routing keys existentes | PENDIENTE_EJECUCION |
| CT-STATIC-14 | STATIC_CONTRACT | `ConsultaOperacionInventario` con `status=REJECTED` requiere `result_code` no vacío; sus estados `ACCEPTED`, `PROCESSING`, `COMPLETED`, `REJECTED` y `REQUIRES_REVIEW` conservan la semántica declarada | PENDIENTE_EJECUCION |
| CT-STATIC-15 | STATIC_CONTRACT | Respuestas `404` de consulta de operación y `422` por contexto comercial inválido usan los códigos del catálogo; `429` y `500` están declarados en las rutas nuevas | PENDIENTE_EJECUCION |
| CT-STATIC-16 | STATIC_CONTRACT | OpenAPI y AsyncAPI mantienen la misma versión candidata y no reemplazan la versión publicada sin adaptadores y pruebas de transición | PENDIENTE_EJECUCION |
| CT-STATIC-17 | STATIC_CONTRACT | GET detallado de Inventario solo admite `modulo-ventas` mediante `serviceBearer`, aparte de la autorización administrativa `userBearer`; los canales solo están autorizados en las operaciones comerciales | PENDIENTE_EJECUCION |
| CT-STATIC-18 | STATIC_CONTRACT | GET y POST comerciales incluyen allowlist `modulo-marketplace`, `modulo-chatbot`, `modulo-retail`, con el scope común `inventario:disponibilidad:leer`; `GET /inventario/operaciones/{operationId}` usa `inventario:operaciones:leer` y `modulo-ventas` | PENDIENTE_EJECUCION |

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
| CT-MKT-11 | Recomendaciones | Marketplace autorizado | PENDIENTE_EJECUCION |
| CT-MKT-12 | No fuga administrativa | Allowlist de campos comerciales; sin flags internos | PENDIENTE_EJECUCION |
| CT-MKT-13 | Correlación | `X-Correlation-Id` propagado | PENDIENTE_EJECUCION |

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
| CT-AVL-05 | Ventas intenta disponibilidad detallada | Permitido únicamente con concesión efectiva | BLOQUEADA_DEPENDENCIA_EXTERNA |
| CT-AVL-06 | Shape comercial | `sku` y `status`; sin on_hand/reserved/blocked/available ni `location_id` | PENDIENTE_EJECUCION |
| CT-AVL-07 | Vocabulario | `DISPONIBLE`, `STOCK_BAJO`, `AGOTADO`, `INDETERMINADO` | PENDIENTE_EJECUCION |
| CT-AVL-08 | Lectura | No muta saldos, reservas ni Kardex | PENDIENTE_EJECUCION |
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
