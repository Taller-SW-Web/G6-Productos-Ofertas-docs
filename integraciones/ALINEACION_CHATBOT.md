# Alineación documental G3 Chatbot ↔ G6 Productos y Ofertas

## Estado consolidado A16/A17

**Estado bilateral: ACEPTADO DOCUMENTALMENTE.** A16 fue respondido formalmente por G6 y aceptado por G3; A17 registra la aceptación expresa de G3 para D1, D2 y D3. Las fuentes son [G6 Docs #87, comentario A16 de G6](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/87#issuecomment-6207787656), [aceptación A16 de G3](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/87#issuecomment-6208570176), [cierre de compatibilidad H4 de G6](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/87#issuecomment-6303661264) y [aceptación A17 de G3](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/87#issuecomment-6379194162). Docs [#87](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/87) continúa abierto para que la auditoría compruebe la propagación; esta referencia no lo cierra ni declara homologación HTTP.

| Dimensión | Estado verificable |
|---|---|
| Acuerdo documental bilateral A16/A17 | Aceptado documentalmente según comentarios enlazados |
| Contrato G6 | OpenAPI `0.6.0-rc.1`, candidato; no implica publicación en runtime |
| Implementación G3/G6 | Pendiente de acreditación por los issues de backend/frontend vinculados |
| Despliegue/entorno | No acreditado por esta documentación |
| Registro, grants y credenciales G7 | Pendientes de verificación; ratificar scopes no los concede |
| Homologación HTTP real | Pendiente de prueba autenticada, reproducible y aceptada por los owners |

El detalle de propagación y sus criterios abiertos se mantiene en [G6 Docs #99](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/99); esta alineación evita duplicar su matriz de seguimiento.

El contrato consumidor de G3 consultado en `main` aún conserva texto anterior a A17 y estados `pending-security-registration` para los scopes. Eso representa la falta de registro/grant G7 y la propagación técnica/documental pendiente en G3; no revoca la ratificación de scopes ni la aceptación A17 registrada en #87. El seguimiento del consumidor está en [G3 Backend #52](https://github.com/Taller-SW-Web/G3-Chatbot-backend/issues/52) y [G3 Frontend #30](https://github.com/Taller-SW-Web/G3-Chatbot-frontend/issues/30).

## Corte operativo y operaciones

G3 consume HTTP desde su backend con el cliente técnico `modulo-chatbot`; no accede a la base de datos G6. El corte inicial incluye las diez operaciones de A16:

1. `GET /api/v1/productos`
2. `GET /api/v1/productos/{productoId}`
3. `GET /api/v1/categorias`
4. `GET /api/v1/marcas`
5. `GET /api/v1/precios`
6. `GET /api/v1/promociones`
7. `POST /api/v1/promociones/evaluar`
8. `POST /api/v1/cupones/validar`
9. `GET /api/v1/recomendaciones`
10. `GET /api/v1/inventario/disponibilidad/comercial`

El acuerdo incluye además `GET /api/v1/precios/skus/{sku}` para consulta individual de precio y `POST /api/v1/inventario/disponibilidad/comercial/verificar` para evaluar cantidades sin vincular stock. Las rutas, parámetros, schemas, scopes, allowlists y respuestas se rigen por [OpenAPI](../contratos/http/openapi.yaml) `0.6.0-rc.1`. El detalle de inventario `GET /api/v1/inventario/disponibilidad` y `GET /api/v1/combos/{comboId}` quedan fuera del acceso Chatbot de este corte; compartir nombre de scope no sustituye la allowlist por operación.

Catálogo, Pricing e Inventario se consultan separadamente. G3 obtiene las variantes y sus SKU desde el detalle del producto; las operaciones batch de precios y disponibilidad admiten hasta 100 SKU por solicitud según OpenAPI. No se agregan precio ni disponibilidad a la búsqueda de productos. No hay límite de concurrencia ni TTL de caché ratificado en este acuerdo.

En las consultas comerciales que incluyen canal (búsqueda/detalle, Pricing, promociones y GET de disponibilidad), G3 envía `canal=CHATBOT`; no envía `estado=ACTIVO` como filtro administrativo del consumidor. Para verificación por cantidad el campo del request es `channel_id=CHATBOT`. Si Pricing no devuelve un precio, la interfaz muestra «Precio no disponible» y no `S/ 0.00`.

## D1 — Contexto de cumplimiento

En este corte G3 utiliza exclusivamente envío a domicilio. La verificación por cantidad envía `channel_id=CHATBOT`, `fulfillment.mode=ENVIO_DOMICILIO` y `lines[{sku,quantity}]`; no envía `fulfillment_ref` inventado. OpenAPI exige `fulfillment`, pero no exige `fulfillment_ref`.

La respuesta usa `items[].result` (`SUFICIENTE`, `INSUFICIENTE` o `INDETERMINADO`) y `binding=false`. Es una evaluación informativa: no crea reserva ni promesa de disponibilidad futura. G5/Ventas conserva pedido, checkout y orquestación de la reserva efectiva.

## D2 — Resultados inválidos y errores

El GET comercial reconoce `DISPONIBLE`, `STOCK_BAJO`, `AGOTADO` e `INDETERMINADO`. Un `INDETERMINADO` contractual válido es distinto de una disponibilidad no obtenida y nunca significa agotado o pocas unidades. Respuestas incompletas, SKU faltante o no coincidente, estado fuera del enum y payload incompatible cuentan como **disponibilidad no obtenida**. En ese caso G3 no agrega el SKU al carrito ni permite continuar al checkout. Tampoco convierte errores de transporte/autorización en resultados comerciales.

`401`, `403`, `422`, `429` y `503` conservan la semántica publicada por OpenAPI; no se definen códigos HTTP ni códigos de negocio nuevos por inferencia. Ante `429`, G3 respeta `Retry-After` cuando la respuesta lo incluya.

## D3 — Homologación HTTP

La prueba de integración real se ejecuta con `MODULES_MODE=http`, separado de `MODULES_MODE=fake`. El reporte de homologación debe identificar entorno (local o staging), servicios reales participantes, versión contractual, SHA de los componentes, mecanismo/autenticación y evidencia reproducible asociada a esa ejecución. Los fakes y mocks sirven para pruebas aisladas; no prueban conectividad ni integración real.

## Identidad, autorización y correlación

Las llamadas reales de G3 a G6 usan `serviceBearer` del cliente técnico `modulo-chatbot`, con audiencia `api-productos`, scope requerido por operación y allowlist aplicable. G6 ratificó siete scopes para ese cliente: `catalogo:leer`, `precios:leer`, `promociones:leer`, `promociones:evaluar`, `cupones:validar`, `recomendaciones:leer` e `inventario:disponibilidad:leer`. Esta ratificación no demuestra registro, grant, emisión de token ni provisión de credenciales. Seguridad/G7 conserva esas responsabilidades; véanse [Seguridad #33](https://github.com/Taller-SW-Web/Modulo-de-Seguridad/issues/33) y [Seguridad #10](https://github.com/Taller-SW-Web/Modulo-de-Seguridad/issues/10).

G3 propaga `X-Correlation-Id` como UUID con guiones y conserva el mismo valor durante la interacción y sus llamadas a módulos. El token técnico autentica al servicio, no reemplaza la identidad del cliente: cuando una regla de cupón lo requiere, `customer_ref` corresponde al `sub` del cliente autenticado; nunca al `sub` técnico. En sesión anónima puede ser `null` si la regla lo permite.

## Responsabilidades y límites

- **G3 Chatbot:** adapta el BFF al contrato G6, compone las consultas separadas y presenta estados/precios conforme a A16/A17; no calcula precio autoritativo ni saldo, no inventa referencias de cumplimiento y no reserva inventario.
- **G6 Productos y Ofertas:** mantiene ownership de catálogo, taxonomía, Pricing, promociones, cupones e inventario; implementa las reglas internas bajo su responsabilidad. El contrato candidato no acredita handlers o despliegue.
- **G5 Ventas:** conserva ownership de pedido, pago, checkout y coordinación de la reserva/consumo efectivo.
- **G7 Seguridad:** administra registro y concesión de scopes, cliente, token y provisión segura de credenciales.

El GET comercial no expone cantidades ni ubicaciones internas. `POST /promociones/evaluar` no crea pedidos ni reserva stock; validar cupones no consume usos. El consumo posterior de beneficios y la reserva efectiva siguen el flujo de G5.

## Pendientes fuera del contrato operativo vigente

Las ampliaciones siguen fuera del contrato operativo vigente y requieren especificación, revisión de owners, homologación cuando afecten el contrato compartido y publicación versionada; no se deben asumir como implementadas.

| Pendiente | Owner(s) funcional(es) según A16 | Estado |
|---|---|---|
| B3: filtros de atributos/variantes, talla y color | `catalog-svc`, `taxonomy-svc` | No especificado ni vigente |
| B4: orden por precio y regla asociada | `catalog-svc`, `pricing-svc` | No especificado ni vigente |
| B6: campos de promoción (beneficio, alcance/modalidad) | `promotions-svc` | No especificado ni vigente |
| B7: desglose de beneficio por línea | `promotions-svc` | No especificado ni vigente |
| B8: monto faltante de mínimo de cupón | `promotions-svc` | No especificado ni vigente |
| Caché y concurrencia | G6, coordinado con G3 como consumidor | Pauta por validar; sin límite ni TTL acordados |

Las matrices proveedor también están pendientes: **B9** corresponde a `promotions-svc`, `catalog-svc`, `pricing-svc` y Gateway para validaciones, límites y respuestas HTTP/reintentos; **B10** corresponde a `catalog-svc`, `pricing-svc` e `inventory-svc` para SKU inexistente/inactivo, resultados de precio/disponibilidad y respuesta batch. No existe cuota numérica ni política nueva de rate limit ratificada. Para errores y estructuras ya publicados rige OpenAPI; no se amplían sus códigos mediante esta guía.

## Trazabilidad de implementación y desbloqueo

| Pendiente | Seguimiento | Condición de cierre |
|---|---|---|
| Propagación documental G6 | [Docs #99](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/99) | Documentos fusionados y trazabilidad revisada; implementación/homologación conservan estado separado |
| Homologación HTTP H4 en G6 | [Backend #27](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/27) y [Backend #19](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/19) | Prueba bilateral autenticada con alcance y evidencia reproducibles |
| Adaptación backend G3 | [G3 Backend #52](https://github.com/Taller-SW-Web/G3-Chatbot-backend/issues/52) | Adaptación y validación por su owner; issue permanece independiente |
| Presentación en frontend G3 | [G3 Frontend #30](https://github.com/Taller-SW-Web/G3-Chatbot-frontend/issues/30) | Casos de interfaz implementados y verificados por su owner |
| Grants y credenciales | [Seguridad #33](https://github.com/Taller-SW-Web/Modulo-de-Seguridad/issues/33), [Seguridad #10](https://github.com/Taller-SW-Web/Modulo-de-Seguridad/issues/10) | Confirmación de grant/credencial efectiva por G7 sin publicar secretos |

Los issues citados están abiertos según la consulta de fuentes para esta actualización. La documentación registra aceptación de contrato A16/A17; no declara completos esos trabajos ni atribuye homologación, implementación, prueba o despliegue.

### Antecedentes reemplazados

La sección histórica «Homologación HTTP 0.5.0» y el addendum G6 `0.6.0-rc.1` explicaban el estado anterior a A16/A17. En este corte las referencias a `fulfillment_ref` opcional (como objeto ambiguo), a disponibilidad no obtenida tratada como `INDETERMINADO`, a scopes Chatbot todavía no ratificados y a acuerdo bilateral incompleto quedan reemplazadas por esta consolidación y por las aceptaciones registradas en Docs #87. OpenAPI continúa como fuente normativa del contrato ejecutable.

Se conserva como contexto funcional que la búsqueda de productos acepta `q` textual y que el BFF puede mantener DTO internos en camelCase si su adaptador traduce el contrato HTTP. Para peso/volumen, Chatbot envía destino y líneas a Despacho por `POST /api/v1/cotizaciones`; Despacho obtiene los datos físicos de Productos con su propia identidad. Chatbot no calcula ni persiste peso/volumen. Estas notas no incorporan campos ni endpoints al contrato de G6.
