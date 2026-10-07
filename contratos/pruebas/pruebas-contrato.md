# Matriz de pruebas de contrato e integración — Productos y Ofertas

**Contrato HTTP objetivo:** OpenAPI 0.5.0
**Contrato asíncrono objetivo:** AsyncAPI 0.5.0
**Estado inicial:** definición documental; ningún caso se marca `PASS` sin evidencia reproducible.

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
| CT-STATIC-01 | STATIC_CONTRACT | YAML válido, OpenAPI 3.1.x, `info.version=0.5.0`, `$ref` resolubles | PENDIENTE_EJECUCION |
| CT-STATIC-02 | STATIC_CONTRACT | `operationId` únicos | PENDIENTE_EJECUCION |
| CT-STATIC-03 | STATIC_CONTRACT | `ErrorCode` OpenAPI = tabla activa de `catalogo-errores.md` | PENDIENTE_EJECUCION |
| CT-STATIC-04 | STATIC_CONTRACT | Header canónico `X-Correlation-Id`; no nuevo `X-Request-Id` | PENDIENTE_EJECUCION |
| CT-STATIC-05 | STATIC_CONTRACT | Código de barras reutiliza `catalogo:leer`; sin scope nuevo | PENDIENTE_EJECUCION |
| CT-STATIC-06 | STATIC_CONTRACT | `DisponibilidadComercial` no contiene saldos internos | PENDIENTE_EJECUCION |
| CT-STATIC-07 | STATIC_CONTRACT | Schemas comerciales de Catálogo no contienen flags administrativos/perfiles físicos internos | PENDIENTE_EJECUCION |
| CT-STATIC-08 | STATIC_CONTRACT | YAML válido, AsyncAPI 3.0.0, `info.version=0.5.0`, 39 canales, 39 mensajes, `$ref` resolubles, `operation_id` requerido en inicializaciones y `causation_id` requerido en resultados | PENDIENTE_EJECUCION |

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
| CT-MKT-09 | SKU agotado | 200 + `AGOTADO`, no 404 | PENDIENTE_EJECUCION |
| CT-MKT-10 | Cupón no aplicable | Resultado de negocio conforme OpenAPI | PENDIENTE_EJECUCION |
| CT-MKT-11 | Recomendaciones | Marketplace autorizado | PENDIENTE_EJECUCION |
| CT-MKT-12 | No fuga administrativa | Allowlist de campos comerciales; sin flags internos | PENDIENTE_EJECUCION |
| CT-MKT-13 | Correlación | `X-Correlation-Id` propagado | PENDIENTE_EJECUCION |

## 3. Retail — código de barras

| ID | Caso | Resultado esperado | Estado |
|---|---|---|---|
| CT-RTL-BAR-01 | Producto simple | 200 + `sku_base` | PENDIENTE_EJECUCION |
| CT-RTL-BAR-02 | Variante | 200 + SKU de variante | PENDIENTE_EJECUCION |
| CT-RTL-BAR-03 | Código inexistente | 404 `CODIGO_BARRAS_NO_ENCONTRADO` | PENDIENTE_EJECUCION |
| CT-RTL-BAR-04 | `0001234567890` | Se preserva string completo | PENDIENTE_EJECUCION |
| CT-RTL-BAR-05 | Asociación no vendible | 404 sin filtrar motivo interno | PENDIENTE_EJECUCION |
| CT-RTL-BAR-06 | Response | Solo requiere `sku` | PENDIENTE_EJECUCION |
| CT-RTL-BAR-07 | Allowlist | Solo `modulo-retail` | PENDIENTE_EJECUCION |
| IT-RTL-BAR-01 | Integridad | Un código no resuelve a dos SKU | PENDIENTE_IMPLEMENTACION |
| IT-RTL-BAR-02 | Continuidad | Resolver → SKU → precio/disponibilidad por SKU | PENDIENTE_IMPLEMENTACION |

## 4. Disponibilidad comercial

| ID | Caso | Resultado esperado | Estado |
|---|---|---|---|
| CT-AVL-01 | Marketplace | Accede a `/disponibilidad/comercial` | PENDIENTE_EJECUCION |
| CT-AVL-02 | Chatbot | Accede a `/disponibilidad/comercial` | PENDIENTE_EJECUCION |
| CT-AVL-03 | Retail | Accede a `/disponibilidad/comercial` | PENDIENTE_EJECUCION |
| CT-AVL-04 | Canal intenta detallada | Rechazado por allowlist | PENDIENTE_EJECUCION |
| CT-AVL-05 | Ventas intenta detallada | Permitido con grant correcto | PENDIENTE_EJECUCION |
| CT-AVL-06 | Shape comercial | Solo `sku + status` | PENDIENTE_EJECUCION |
| CT-AVL-07 | Vocabulario | `DISPONIBLE/STOCK_BAJO/AGOTADO` | PENDIENTE_EJECUCION |
| CT-AVL-08 | Lectura | No muta saldos/reservas/Kardex | PENDIENTE_EJECUCION |
| CT-AVL-B01 | Multiubicación | Política todavía no definida | BLOQUEADA_DECISION |

`CT-AVL-B01` depende de `D-INV-01/B-INV-01`.

## 5. Recomendaciones

| ID | Caso | Resultado esperado | Estado |
|---|---|---|---|
| CT-REC-01 | Marketplace | Autorizado con `canal=MARKETPLACE` | PENDIENTE_EJECUCION |
| CT-REC-02 | Chatbot | Autorizado con `canal=CHATBOT` | PENDIENTE_EJECUCION |
| CT-REC-03 | Retail | Autorizado con `canal=RETAIL` | PENDIENTE_EJECUCION |
| CT-REC-04 | No elegible | Candidato excluido | PENDIENTE_EJECUCION |
| CT-REC-05 | Sin candidatos | 200 + `recommendations=[]` | PENDIENTE_EJECUCION |
| CT-REC-06 | Identidad | Recomendación principal por `product_id` | PENDIENTE_EJECUCION |
| CT-REC-07 | No fuga stock | Sin cantidades internas | PENDIENTE_EJECUCION |
| CT-REC-B01 | Availability product-level | Reutiliza `EstadoStock`, policy multi-SKU pendiente | BLOQUEADA_DECISION |
| CT-REC-B02 | Variantes → availability | Depende de `D-REC-01` | BLOQUEADA_DECISION |
| CT-REC-B03 | Variantes → current_price | Depende de `D-REC-02` | BLOQUEADA_DECISION |

## 6. Rate limiting

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-RATE-01 | 429 + `RATE_LIMIT_EXCEDIDO` | PENDIENTE_EJECUCION |
| CT-RATE-02 | `Retry-After` presente | PENDIENTE_EJECUCION |
| CT-RATE-03 | Correlación preservada | PENDIENTE_EJECUCION |
| CT-RATE-04 | Request limitada no produce side effects | PENDIENTE_IMPLEMENTACION |
| CT-RATE-05 | Test determinista con política controlable | PENDIENTE_IMPLEMENTACION |

## 7. Seguridad

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-SEC-01 | Token inválido → 401 `TOKEN_INVALIDO` | PENDIENTE_EJECUCION |
| CT-SEC-02 | `aud` sin `api-productos` → rechazo | PENDIENTE_EJECUCION |
| CT-SEC-03 | Scope insuficiente → 403 | PENDIENTE_EJECUCION |
| CT-SEC-04 | Scope correcto + cliente no permitido → rechazo | PENDIENTE_EJECUCION |
| CT-SEC-05 | Scope de disponibilidad no habilita automáticamente lectura detallada | PENDIENTE_EJECUCION |

Las pruebas con grants reales permanecen `BLOQUEADA_DEPENDENCIA_EXTERNA` mientras Seguridad no registre las concesiones.

## 8. Regresión Chatbot

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-CHAT-01 | Usa `/inventario/disponibilidad/comercial` | PENDIENTE_EJECUCION |
| CT-CHAT-02 | Sigue consumiendo `/recomendaciones?canal=CHATBOT` | PENDIENTE_EJECUCION |
| CT-CHAT-03 | No recibe cantidades internas | PENDIENTE_EJECUCION |

## 9. OPEN-08 — Ventas ↔ Inventario

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-SALES-01 | `CREADO` → reservar | PENDIENTE_IMPLEMENTACION |
| CT-SALES-02 | `PAGADO` → confirmar consumo sin doble descuento | PENDIENTE_IMPLEMENTACION |
| CT-SALES-03 | anulación pre-consumo → liberar | PENDIENTE_IMPLEMENTACION |
| CT-SALES-04 | retry idéntico → replay seguro | PENDIENTE_IMPLEMENTACION |
| CT-SALES-05 | misma idempotency + intención distinta → `IDEMPOTENCY_CONFLICT` | PENDIENTE_IMPLEMENTACION |
| CT-SALES-06 | Ventas puede leer saldo detallado con grant correcto | PENDIENTE_EJECUCION |

## 10. OPEN-09 — Despacho ↔ Productos

| ID | Resultado esperado | Estado |
|---|---|---|
| CT-DSP-01 | Batch de datos físicos por SKU | PENDIENTE_IMPLEMENTACION |
| CT-DSP-02 | Solo peso/dimensiones contractuales; no empaque | PENDIENTE_IMPLEMENTACION |
| CT-DSP-03 | Solo consumidor autorizado | PENDIENTE_EJECUCION |
| CT-DSP-04 | Sin stock/precio/pedido en respuesta física | PENDIENTE_EJECUCION |

## 11. Recuperación de preparación — Catálogo (FLOW-003 / FLOW-004 / Endurecimiento contractual)

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
| CT-PREP-16 | ARCHITECTURE_INVARIANT | No se crean mensajes AsyncAPI nuevos; se reutilizan comandos y resultados existentes de Pricing e Inventario | PENDIENTE_EJECUCION |
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

## 12. Evidencia futura

Cada ejecución debe registrar:

```text
test_id
timestamp
commit SHA provider
commit SHA consumer cuando aplique
OpenAPI version
entorno
resultado
correlation_id cuando aplique
workflow/run
```

No almacenar JWT completos, secretos ni PII.

Un mock exitoso no equivale a provider real exitoso.
