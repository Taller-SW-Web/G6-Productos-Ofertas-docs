# Alineación Marketplace ↔ Productos y Ofertas

**Estado documental:** propuesta de homologación bilateral basada en la respuesta de G1 del 2026-10-13; la conformidad de G6 no consta en las fuentes consultadas. La línea base histórica es `0.5.0`; `0.6.0-rc.1` es el contrato candidato de G6, no evidencia de despliegue.
**Fuente HTTP autoritativa:** [`../contratos/http/openapi.yaml`](../contratos/http/openapi.yaml)
**Respuesta externa:** [`ACUERDOS_G1_MARKETPLACE_2026-10-13.md`](ACUERDOS_G1_MARKETPLACE_2026-10-13.md)

## 1. Objetivo

Documentar la frontera que el backend/BFF de Marketplace consume de Productos y Ofertas sin trasladar ownership de Catálogo, Pricing, Promociones o Inventario. La respuesta de G1 del 13/10 propone como primer corte del 14/10 dos lecturas obligatorias y una condicional; el resto queda para etapas posteriores y acuerdos adicionales.

## 2. Frontera de integración

```text
Frontend Marketplace
→ backend/BFF Marketplace
→ API Gateway de Productos y Ofertas
→ servicio owner
```

El frontend de Marketplace no consume directamente `api-productos`. G1 conserva la presentación y el transporte; G6 conserva la autoridad de elegibilidad comercial, catálogo, precios, beneficios e inventario en sus respectivos bounded contexts.

## 3. Identidades de producto

```text
product_id != variant_id != sku
```

- `product_id` y `slug` identifican la ficha de producto.
- Para un producto simple, `sku_base` es la identidad vendible.
- Para un producto con variantes, cada opción vendible tiene `variant_id` y su propio `sku`.
- El BFF no construye ni deduce SKU desde `product_id`, `variant_id` u otros identificadores.
- Precio, disponibilidad, carrito y pedido se resuelven usando el SKU vendible.
- G6 determina la elegibilidad comercial; no se exponen variantes inactivas o no vendibles.

El esquema comercial G6 `VarianteComercial` no incorpora un `status`; G1 no debe deducirlo ni añadirlo al esquema. G6 conserva la autoridad de elegibilidad comercial y la proyección debe limitarse a opciones vendibles; el mecanismo exacto de filtrado debe respetar el contrato publicado.

## 4. Catálogo y primer corte

La prioridad contractual propuesta para el 14/10 es:

**Obligatorio**

```http
GET /api/v1/categorias
GET /api/v1/productos?canal=MARKETPLACE&q=...
```

**Condicional**

```http
GET /api/v1/productos/por-slug/{slug}?canal=MARKETPLACE
```

Las tres rutas existen en OpenAPI `0.6.0-rc.1`; su existencia no prueba implementación, disponibilidad de servicio ni concesión de permisos. Para el listado, OpenAPI permite `q` y `canal`; la ruta por slug exige `canal`. Las lecturas comerciales deben limitarse a productos activos y elegibles para Marketplace según la proyección contractual. No se exponen flags administrativos como `catalog_version`, `pricing_preparado`, `inventario_inicializado`, `perfil_fisico` o `physical_profile`.

El ordenamiento publicado se limita a `NOMBRE_ASC` y `NOMBRE_DESC`; ordenar por precio queda fuera mientras no haya una regla product-level para productos con múltiples SKU/overrides. Categorías y búsqueda constituyen la primera evidencia contractual; fixture y prueba reproducible son evidencia propuesta por G1. La integración HTTP real desde el BFF y el despliegue deben acreditarse separadamente.

Pricing por SKU, disponibilidad comercial, verificación de cantidades, promociones/cupones, checkout y pagos son posteriores. No se incorporan al corte inicial.

## 5. Precio — posterior al primer corte

```http
GET /api/v1/precios?skus=...
GET /api/v1/precios/skus/{sku}
```

El precio se resuelve por SKU, canal e instante según OpenAPI. La integración de Pricing no forma parte del corte del 14/10. El snapshot comercial conjunto sigue pendiente: no se declara un DTO integral publicado ni una congelación conjunta de versiones, beneficios, envío y total.

## 6. Disponibilidad y verificación por cantidad — posteriores

Marketplace consume la proyección comercial, cuando se habilite el alcance posterior:

```http
GET /api/v1/inventario/disponibilidad/comercial
```

La respuesta comercial G6 admite `DISPONIBLE`, `STOCK_BAJO`, `AGOTADO` e `INDETERMINADO`, con SKU y estado, sin cantidades internas ni ubicación. El mapeo propuesto por G1 es:

| Estado G6 | Presentación BFF G1 |
|---|---|
| `DISPONIBLE` | `AVAILABLE` |
| `STOCK_BAJO` | `STOCK_LOW` |
| `AGOTADO` | `OUT_OF_STOCK` |
| `INDETERMINADO` | `UNDETERMINED` |

`UNDETERMINED` es un resultado comercial válido, no un error de infraestructura. El BFF conserva HTTP 200 ante ese resultado, no presenta disponibilidad garantizada ni agotamiento, y permite reintento. Distingue 503, timeout y respuesta inválida; nunca convierte un error técnico en estado de inventario. La política interna `D-INV-01` prohíbe sumar saldos de ubicaciones independientes por defecto: si no se puede demostrar una fuente única y ejecutable, el resultado es `INDETERMINADO`, no `AGOTADO`.

**Discrepancia documental pendiente:** el contrato G1 F-014 consultado en `main` aún enumera solo `AVAILABLE`, `STOCK_LOW` y `OUT_OF_STOCK`; la respuesta M-01 del 13/10 acepta añadir `UNDETERMINED`. Se conserva la respuesta más reciente como propuesta registrada, pero la adaptación consumible requiere que G1 actualice/homologue F-014 y que G6 confirme su conformidad. Hasta entonces M-01 no se declara bilateralmente cerrada.

La verificación de cantidades es una operación distinta y no vinculante:

```http
POST /api/v1/inventario/disponibilidad/comercial/verificar
```

El candidato de solicitud usa `channel_id=MARKETPLACE`, `fulfillment.mode=ENVIO_DOMICILIO`, `fulfillment_ref` opcional según OpenAPI y líneas con `sku` y `quantity`. La respuesta declara `binding=false`; `SUFICIENTE` no equivale a reserva, `INSUFICIENTE` indica que la cantidad no está cubierta e `INDETERMINADO` que no se puede verificar el cumplimiento. Un contexto semánticamente inválido puede responder 422. Si solo falta un mapeo interno válido, corresponde resultado comercial `INDETERMINADO`, no necesariamente error HTTP. No se exponen saldos ni ubicaciones.

El origen, formato y validez de `fulfillment_ref` siguen pendientes de G2/G5/G6; no se inventa una referencia. G5 conserva la responsabilidad de reservar y esperar confirmación definitiva. Ambas rutas comerciales de inventario están marcadas provisionales en OpenAPI; su implementación y pruebas no están acreditadas por este documento.

## 7. Promociones, cupones y snapshot — posteriores

G1 propone consumir posteriormente:

```http
GET /api/v1/promociones
POST /api/v1/promociones/evaluar
POST /api/v1/cupones/validar
```

Evaluar promociones o validar cupones no consume beneficios. G6 conserva la autoridad del beneficio; G5 mantiene la orquestación de consumo/restauración. El DTO vigente de evaluación no garantiza beneficios simultáneos ni publica `applied_benefits[]`; no se inventa esa estructura.

El snapshot comercial conjunto requiere contrato entre G6 (precios y beneficios), G2 (envío), G5 (monto final del pedido) y G1 (visualización/transporte). Siguen pendientes `price_version` y vigencias coordinadas, referencias de promociones/cupones, desglose de beneficios, cotización de envío, total confirmado, correlación y rechazo de referencias vencidas. No se presenta un DTO agregado como publicado.

## 8. Recomendaciones — fuera del primer corte

```http
GET /api/v1/recomendaciones?productoId={id}&canal=MARKETPLACE
```

La capacidad de recomendaciones permanece a nivel `product_id`; `availability` reutiliza `EstadoStock`. El enriquecimiento `availability/current_price` sigue provisional mientras `D-REC-01` y `D-REC-02` permanezcan abiertas. Marketplace, Chatbot y Retail son consumidores previstos, sujetos a sus contratos y autorizaciones. Esta capacidad no forma parte del primer corte del 14/10.

## 9. Checkout y pagos — posteriores

G1 acepta estas semánticas de estado, sujetas a las fuentes y autoridad de G5:

- `PREPARED`: consentimiento registrado; sin pedido ni pago confirmado.
- `SUBMITTED`: pedido enviado; operación pendiente.
- `CREADO`: existe un pedido; no significa compra exitosa.
- `PAGADO`: condición para confirmar compra.
- `ANULADO`: fallo terminal conforme al estado autorizado por G5.
- Timeout: estado incierto; no se infiere éxito ni fallo.

G1 no calcula TTL autónomamente. G5 debe publicar los estados, causas terminales y `expires_at` aplicables. Aún falta acordar el body completo válido de `POST /api/v1/pedidos`, el literal permitido para `pago.metodoPago` y la recuperación tras pérdida de respuesta. G1 propone persistir `checkoutOperationId`, `Idempotency-Key` UUID v4, fingerprint, payload semánticamente idéntico y `pedidoId` cuando exista; la persistencia transitoria y su privacidad requieren resolución de G1. No se inventan métodos de pago ni rutas de recuperación.

**Discrepancia documental pendiente:** el contrato G1 F-026 consultado describe repetir `POST /api/v1/pedidos` con la misma clave/payload para recuperar una respuesta perdida, mientras M-07 declara que la política de recuperación aún debe acordarse con G5. No se trata esa descripción de F-026 como política bilateral aprobada; G1/G5 deben reconciliar las fuentes antes de habilitar recuperación.

## 10. Correlación

El header canónico de Productos y Ofertas es `X-Correlation-Id`. Si Marketplace utiliza internamente `X-Request-Id`, su BFF adapta/propaga el identificador conforme al contrato acordado.

## 11. Rate limiting

Las operaciones externas pueden responder `429 RATE_LIMIT_EXCEDIDO` con `Retry-After`, según contrato. No hay una cuota numérica universal fijada en este acuerdo.

## 12. Identidad técnica y permisos

La propuesta de identidad técnica de G1 es `client_id=modulo-marketplace`, audiencia `api-productos` y JWT de servicio emitido/obtenido por su BFF. Los secretos no se exponen al navegador. Para las dos primeras rutas del corte G1 prevé `catalogo:leer`. OpenAPI marca el registro de scopes como `pending-security-registration`; el grant efectivo corresponde a G7 y no está acreditado. La URL base absoluta por entorno y la provisión de credenciales siguen pendientes.

Los scopes `precios:leer`, `promociones:leer`, `promociones:evaluar`, `cupones:validar`, `recomendaciones:leer` e `inventario:disponibilidad:leer` se mantienen como previsiones para capacidades posteriores; no forman parte del primer corte ni se afirman concedidos.

## 13. Aceptación documental, dependencias y evidencia

La respuesta de G1 del 13/10 consta en el registro enlazado y contiene tres aceptaciones (M-01, M-02, M-06) y seis propuestas de cambio (M-03 a M-05, M-07 a M-09). Esto acredita la respuesta de G1, no la conformidad de G6 ni una homologación bilateral cerrada. Responsables técnicos no sustituyen aprobación formal.

Además, las fuentes G1 requieren conciliación: F-014 conserva tres estados aunque M-01 acepta cuatro; F-013 representa `status: ACTIVE` aunque G6 `VarianteComercial` no publica `status`; y F-026 describe un retry de recuperación que M-07 deja pendiente con G5. Se mantienen ambas referencias y sus estados; no se elige una semántica por inferencia. Desbloqueo: G1 revisa/actualiza los contratos F afectados y los owners G1/G5/G6 registran conformidad de frontera.

Dependencias: G2/G5/G6 deben resolver origen, formato y validez de `fulfillment_ref`; G2/G5/G6 deben acordar snapshot y vigencias; G5 debe publicar estados, causas terminales, expiración y contrato de creación/recuperación del pedido; G7 debe registrar y conceder los permisos; G1 debe resolver persistencia transitoria y privacidad. La URL base y credenciales por entorno también faltan.

G1 propone contrato, fixture y prueba reproducible como primera evidencia. La llamada real BFF→G6, despliegue, grants y pruebas E2E necesitan evidencia propia ligada a versión/commit. Ni documentación ni YAML acreditan esos estados.

## 14. Casos contractuales mínimos

- `CT-MKT-01`: producto activo y elegible aparece.
- `CT-MKT-02`: producto no elegible no aparece.
- `CT-MKT-03`: página vacía responde 200 con lista vacía.
- `CT-MKT-04/05`: detalle por slug elegible/no elegible.
- `CT-MKT-06`: `variant_id` y SKU son identidades distintas.
- `CT-MKT-07/08`: precio regular/oferta (posterior al primer corte).
- `CT-MKT-09`: SKU agotado responde `AGOTADO`, no 404.
- `CT-MKT-10`: cupón inválido/no aplicable (posterior al primer corte).
- `CT-MKT-11`: recomendaciones autorizadas.
- `CT-MKT-12`: no hay filtración de datos administrativos.
- `CT-MKT-13`: correlación.

La existencia de estos casos no acredita que se hayan ejecutado. Las pruebas aplicables requieren evidencia reproducible para considerar cerrada la integración runtime.

## Addendum contractual G6 — decisiones y contratos candidatos

Las decisiones internas y contratos candidatos G6 de `0.6.0-rc.1` conservan las siguientes reglas, sin que este resumen modifique OpenAPI o AsyncAPI:

- `order_id` es referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- Las operaciones de reserva, confirmación y liberación responden `202` cuando admiten el comando; resultado de negocio se acredita por persistencia/evento conforme a AsyncAPI.
- `GET /inventario/operaciones/{operationId}` es solo para Ventas con `inventario:operaciones:leer`; la verificación comercial por cantidad es provisional y no vinculante.
- `inventory.reservation.rejected` y resultados de consumo/restauración son mensajes tipados con correlación; los nombres y schemas canónicos pertenecen a AsyncAPI.
- D-INV-01: no sumar ubicaciones independientes por defecto; mapeo irresoluble resulta `INDETERMINADO`. `SUFICIENTE` no constituye reserva.
- El consumo de beneficios por Ventas requiere reserva confirmada y referencias contractuales; G1 no consume ni restaura beneficios por su cuenta.
- Misma identidad y payload semántico deben evitar efectos duplicados; identidad reutilizada con intención distinta produce `IDEMPOTENCY_CONFLICT`, conforme al contrato aplicable.
- Se respeta `expires_at` emitido por Inventario; las transiciones concurrentes obedecen la regla interna adoptada.

Estos contratos siguen candidatos/provisionales hasta que implementación y pruebas integradas sean verificadas. La documentación no prueba despliegue ni conformidad externa.

## Addendum contractual G6 `0.6.0-rc.1`

La versión `0.6.0-rc.1` es candidata y no desplegada según las fuentes G6 consultadas; la homologación HTTP `0.5.0` permanece como antecedente histórico. Las decisiones internas y contratos candidatos G6 no prueban aceptación externa, permisos efectivos, handlers ni pruebas de integración. La respuesta M-01 a M-09 se mantiene diferenciada por punto en el [registro de acuerdos](ACUERDOS_G1_MARKETPLACE_2026-10-13.md).
