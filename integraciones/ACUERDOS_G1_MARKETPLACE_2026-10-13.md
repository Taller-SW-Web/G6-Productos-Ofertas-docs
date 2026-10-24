> **REGISTRO HISTÓRICO — NO REPRESENTA EL ESTADO ACTUAL DE ACEPTACIÓN.** El contenido siguiente conserva literalmente la comunicación G1 fechada 2026-10-13. El estado de G6 fue actualizado posteriormente: aceptación de M-01–M-09 comunicada 2026-10-20, `ACEPTADO_G6_COMUNICADO_G1`. La fuente vigente es el [Acuerdo G1–G6 H4](ACUERDO_G1_G6_H4_2026-10-20.md); esta cabecera no reescribe la evidencia original.

# Registro de respuesta externa — G1 Marketplace

## 1. Metadatos y fuentes

| Campo | Valor |
|---|---|
| Identificador | `G6-G1-01` |
| Fecha de respuesta | 2026-10-13 |
| Corte de integración propuesto | 2026-10-14 |
| Módulo externo | G1 Marketplace |
| Fuente primaria indicada | `Respuesta-G1-a-G6-acuerdos-integracion-v1-1.docx` |
| Estado de inspección del DOCX | No disponible en el workspace; este registro utiliza exclusivamente el resumen normativo proporcionado en el encargo. |
| Fuentes G1 consultadas | `plan/DECISIONES-Y-BLOQUEOS.md`; `plan/iteraciones/S01-semanas-07-08.md`; contratos F-006, F-007, F-011, F-013, F-014, F-024, F-025 y F-026 en `SPECS/contrato-api/`; F-014 funcional RN-F014-02. |
| Fuente HTTP G6 | [`../contratos/http/openapi.yaml`](../contratos/http/openapi.yaml) |
| Otras fuentes G6 | [Alineación Marketplace](ALINEACION_MARKETPLACE.md), [matriz intermodular](MATRIZ_INTERMODULAR_BACKEND.md), DEC-F, matriz de trazabilidad y SPEC-003/004/015. |

## Propuesta de posición G6 — lote 3

La respuesta de G1 se conserva literalmente y con sus estados originales en este registro. La propuesta de posición de G6 sobre M-01–M-09, incluidas discrepancias y dependencias abiertas, está en [G6-G1-03 — Propuesta de cierre](ACUERDO_G1_G6_H4_2026-10-20.md). **Pendiente de aprobación de G6; no enviada y no constituye homologación bilateral.**

## 2. Versiones y commits contrastados

- G1 `main`: `a8c3a7e21482063d71a083fd950dd8fa418b615c` (confirmado como `HEAD` remoto durante este lote).
- G6 docs: `942bf73`, commit histórico declarado por G1 para el contraste; no es el HEAD actual de esta rama documental.
- G6 docs `origin/master` antes de este lote: `0db404a1e4a4d604cb345d245dcb3470f7e23580`.
- Commit G5 incorporado a G6: `c83f8257e714e5fdf17a759ef6cf5ee3d52cdb7b`, ancestro de `origin/master` al iniciar el lote.
- OpenAPI G6: `0.6.0-rc.1`, candidato. La línea base `0.5.0` se conserva como antecedente histórico; ninguna de las dos etiquetas acredita despliegue.
- `plan/DECISIONES-Y-BLOQUEOS.md` consultado en G1 `main` declara versión 0.4.0. `plan/iteraciones/S01-semanas-07-08.md` declara versión 0.3.0.

Los commits anteriores identifican fuentes contrastadas y no implican aceptación de G6 ni estado de runtime.

## 3. Estado de aprobación

- **G1:** respuesta documental recibida el 2026-10-13; M-01, M-02 y M-06 están marcadas `ACEPTAMOS`; M-03, M-04, M-05, M-07, M-08 y M-09 están marcadas `PROPONEMOS CAMBIO`.
- **G6:** no consta conformidad formal de G6 a esta respuesta en las fuentes consultadas.
- **Bilateral:** existe respuesta externa documentada; la homologación bilateral no se declara cerrada. Los tres puntos aceptados por G1 no equivalen a aceptación G6.

## 4. Respuestas M-01–M-09

| Punto | Respuesta exacta G1 | Contenido y límite documentado | Estado en G6 |
|---|---|---|---|
| M-01 — Cuarto estado de disponibilidad | `ACEPTAMOS` | Mapeo G6→BFF: `DISPONIBLE`→`AVAILABLE`, `STOCK_BAJO`→`STOCK_LOW`, `AGOTADO`→`OUT_OF_STOCK`, `INDETERMINADO`→`UNDETERMINED`. Este último es resultado comercial válido y conserva HTTP 200; no se presenta agotamiento ni disponibilidad garantizada; permite reintento y distingue 503, timeout y respuesta inválida. Errores técnicos no se convierten en estados de inventario. | Aceptación de G1; conformidad G6 pendiente. D-INV-01 es decisión interna G6 separada. |
| M-02 — Producto, variante y SKU | `ACEPTAMOS` | `product_id` y `slug` identifican la ficha. Producto simple: `sku_base` es vendible. Producto con variantes: cada opción utiliza `variant_id` y `sku`. El BFF no deduce SKU. Precio, disponibilidad, carrito y pedido usan SKU vendible. G6 conserva elegibilidad comercial. No exponer variantes inactivas/no vendibles ni inventar `status` en `VarianteComercial` si no está publicado. G6 entrega variantes elegibles; G1 puede mapearlas a `status: ACTIVE` en su DTO y validar SKU/atributos. La cobertura de producto simple mediante `sku_base` queda pendiente de prueba contractual. | Aceptación de G1; conformidad G6 pendiente. |
| M-03 — Verificación de cantidades | `PROPONEMOS CAMBIO` | Contrato candidato `POST /api/v1/inventario/disponibilidad/comercial/verificar`; solicitud con `channel_id=MARKETPLACE`, `fulfillment.mode=ENVIO_DOMICILIO`, `fulfillment_ref` opcional según contrato y líneas `sku`/`quantity`. Respuesta `binding=false`; `SUFICIENTE` no reserva, `INSUFICIENTE` no cubre cantidad, `INDETERMINADO` no permite verificar cumplimiento. No inventar `fulfillment_ref`: origen, formato y validez pendientes de G2/G5/G6. Contexto semánticamente inválido puede dar 422; falta de mapeo interno válido produce resultado comercial indeterminado, no necesariamente error HTTP. | Contrapropuesta G1; ruta candidata G6 marcada provisional. Pendiente frontera de fulfillment y evidencia runtime. |
| M-04 — Snapshot comercial | `PROPONEMOS CAMBIO` | Autoridades: G6 precios/beneficios; G2 envío; G5 monto final del pedido; G1 visualización/transporte. Pendientes conjuntos: `price_version` y vigencias, referencias de promociones/cupones, desglose de beneficios, cotización de envío, total confirmado, correlación y rechazo de referencias vencidas. No inventar DTO agregado ni declarar snapshot integral publicado. | Contrapropuesta G1; requiere acuerdo G2/G5/G6/G1. |
| M-05 — Promociones y cupones | `PROPONEMOS CAMBIO` | El primer corte del 14/10 no incluye compra con cupón. Posteriormente G1 podrá usar `POST /api/v1/promociones/evaluar` y `POST /api/v1/cupones/validar`; esas operaciones no consumen beneficios. G5 orquesta consumo/restauración; G6 es autoridad del beneficio. DTO actual no garantiza múltiples beneficios simultáneos ni `applied_benefits[]`; no inventarlo. Si la regla requiere `customer_ref`, se obtiene del `sub` del token del usuario y nunca del token técnico. Las decisiones ante rechazos usan el código contractual estable, no textos humanos. | Contrapropuesta G1; capacidades posteriores y consumo de Ventas por su contrato/flujo. |
| M-06 — Estados de checkout | `ACEPTAMOS` | `PREPARED`: consentimiento registrado, sin pedido/pago confirmado. `SUBMITTED`: pedido enviado, pendiente. `CREADO`: pedido existente, no compra exitosa. `PAGADO`: condición para confirmar compra. `ANULADO`: fallo terminal conforme al estado autorizado de G5. Timeout: incierto, no éxito ni fallo inferido. G1 no calcula TTL autónomo; G5 debe publicar estados, causas terminales y `expires_at`. | Aceptación de G1; conformidad G6 pendiente. Owner G5. |
| M-07 — Pago simulado e idempotencia | `PROPONEMOS CAMBIO` | G1 ratifica que, si se pierde el `201` de `POST /api/v1/pedidos`, recupera repitiendo la solicitud con la misma `Idempotency-Key` y el mismo payload semántico, para obtener el mismo pedido. Conserva `checkoutOperationId`, UUID v4, fingerprint y `pedidoId` cuando exista. Siguen pendientes con G5 el body completo válido, el literal permitido de `pago.metodoPago` y los detalles de recuperación dependientes del contrato G5. Para reproducir la solicitud tras una recarga, G1 debe decidir entre almacenamiento transitorio protegido y de retención corta o reconstrucción determinista demostrada. G1 decide y revisa privacidad. No inventar métodos ni rutas. | Propuesta G1 documentada; payload, detalles G5 y decisión/privacidad de persistencia siguen pendientes. F-026 es compatible con la repetición idempotente y no se considera discrepancia. |
| M-08 — Identidad técnica y scopes | `PROPONEMOS CAMBIO` | Identidad propuesta: `client_id=modulo-marketplace`, `aud=api-productos`, JWT de servicio desde BFF; secretos fuera del navegador. Para las dos primeras rutas del 14/10 se prevé `catalogo:leer`. Grants efectivos corresponden a G7. URL base absoluta por entorno y provisión de credenciales pendientes. No afirmar permiso concedido. | Contrapropuesta G1; OpenAPI G6 informa `pending-security-registration`; G7 debe conceder/provisionar. |
| M-09 — Primer corte del 14/10 | `PROPONEMOS CAMBIO` | Obligatorio: `GET /api/v1/categorias` y `GET /api/v1/productos?canal=MARKETPLACE&q=...`. Condicional: `GET /api/v1/productos/por-slug/{slug}?canal=MARKETPLACE`. Posterior: Pricing por SKU, disponibilidad comercial, verificación de cantidades, promociones/cupones, checkout y pagos. Primera evidencia propuesta: contrato, fixture y prueba reproducible. HTTP real desde BFF y despliegue se acreditan por separado. Responsables técnicos no sustituyen aprobación formal. | Contrapropuesta G1; alcance incorporado como propuesta, sujeto a conformidad G6. |

Conteo de la respuesta: **3 `ACEPTAMOS` (M-01, M-02, M-06)** y **6 `PROPONEMOS CAMBIO` (M-03, M-04, M-05, M-07, M-08, M-09)**. No hay M-10.

**Discrepancias y límites entre fuentes:** (1) [F-014 API](https://github.com/Taller-SW-Web/G1-Marketplace-SPECS/blob/a8c3a7e21482063d71a083fd950dd8fa418b615c/SPECS/contrato-api/F-014-consultar-disponibilidad-stock.md) enumera tres estados aunque M-01 acepta `UNDETERMINED`; G1 debe actualizar su contrato API y G6 documentar conformidad. (2) [F-014 funcional](https://github.com/Taller-SW-Web/G1-Marketplace-SPECS/blob/a8c3a7e21482063d71a083fd950dd8fa418b615c/SPECS/funcional/F-014-consultar-disponibilidad-stock.md) v0.1.0, `RN-F014-02`, describe una proyección agregada sobre ubicaciones elegibles; G1 debe precisar una única fuente de cumplimiento compatible con D-INV-01 y `INDETERMINADO` si no hay resolución inequívoca. Son pendientes distintos. (3) [F-013](https://github.com/Taller-SW-Web/G1-Marketplace-SPECS/blob/a8c3a7e21482063d71a083fd950dd8fa418b615c/SPECS/contrato-api/F-013-seleccion-atributos-variante.md) incluye `status: ACTIVE` en el DTO del BFF, lo cual no contradice OpenAPI G6: la proyección G6 debe contener solo variantes elegibles y G1 transforma/valida su DTO sin añadir `status` a `VarianteComercial`. La cobertura de producto simple `sku_base` sigue pendiente. [F-026](https://github.com/Taller-SW-Web/G1-Marketplace-SPECS/blob/a8c3a7e21482063d71a083fd950dd8fa418b615c/SPECS/contrato-api/F-026-crear-orden-ventas.md) coincide con la repetición idempotente descrita en M-07; no hay contradicción entre esas fuentes. La conformidad G6 y las actualizaciones G1 indicadas aún deben quedar documentadas.

## 5. Primer corte del 14/10

Las dos rutas obligatorias y la ruta condicional constan en OpenAPI G6 `0.6.0-rc.1`. F-007 usa `page=0`/`pageSize`; G1 traduce a G6 `pagina=1`/`tamanio` mediante `pagina = page + 1` y `tamanio = pageSize`. La respuesta del lote anterior señaló una posible omisión de scope en la operación por slug; la comprobación directa del OpenAPI en la revisión de base auditada confirma que las tres operaciones declaran `x-required-scope: catalogo:leer`, `x-service-audience: api-productos`, allowlist con `modulo-marketplace` y `x-scope-registration-status: pending-security-registration`. La declaración no acredita registro/concesión efectiva de G7. URL base y credenciales por entorno siguen pendientes. G1 propone como primera evidencia contrato, fixture y prueba reproducible; la llamada HTTP real del BFF, grants y despliegue requieren evidencia distinta.

Los casos mínimos documentales incluyen categorías activas; búsqueda con producto elegible y no elegible; resultado vacío; detalle de producto simple y de dos variantes cuando corresponda; errores de autenticación 401, autorización 403 e indisponibilidad técnica 503. Son condiciones de validación; este registro no afirma que se hayan probado.

Pricing, inventario/disponibilidad, verificación por cantidad, promociones, cupones, checkout y pago quedan fuera del corte inicial. No se afirma que la ruta condicional por slug sea necesaria para el gate inicial.

## 6. Dependencias externas y desbloqueo

| Dependencia | Responsable/owner | Criterio de desbloqueo |
|---|---|---|
| Identidad de cumplimiento `fulfillment_ref` | G2/G5/G6, según origen y resolución del cumplimiento | Origen, formato, validez y mapeo acordados; mantener `INDETERMINADO` si el mapeo interno válido falta. |
| Snapshot, vigencias, beneficios, envío y total | G6/G2/G5; G1 transporta y visualiza | Contrato conjunto que defina referencias, correlación, vigencias y rechazo de referencias vencidas. |
| Checkout, estados, expiración y recuperación | G5; persistencia y privacidad G1 | G5 publica body aceptado, literal de pago, estados/casos terminales, `expires_at` y recuperación; G1 resuelve persistencia y privacidad sin inventar rutas. |
| Scopes, grants y credenciales | G7; configuración BFF G1 | Registro/concesión efectiva, credenciales y URL base por ambiente verificados. |
| Homologación y pruebas | G1/G6 y owners de capacidades | Conformidad bilateral registrada para la frontera afectada y prueba reproducible ligada a versión/commit; pruebas BFF reales/despliegue se evidencian aparte. |

Una dependencia bloquea solo la operación o frontera que necesita esa definición. Las decisiones internas G6 pueden implementarse en el alcance propio sin alterar unilateralmente contratos compartidos.

## 7. Responsables técnicos informados por G1

**G1:** Giuliano — F-006/F-007; Sebastian — F-011/F-013; Leonidas — adaptador y contratos; Jim Segovia — coordinación.

**G6:** Leonardo López — Taxonomía; Gabriel Poma — Catálogo; Gateway y Seguridad — coordinación transversal.

Estos nombres son responsables técnicos declarados, no constancia de aprobación formal del acuerdo.

## 8. Requisitos de validación contractual

- Confirmar rutas, métodos, parámetros, schemas y status contra OpenAPI G6, que gobierna HTTP.
- Para disponibilidad, probar el mapeo de cuatro estados; `INDETERMINADO` comercial no debe convertirse en agotamiento ni en error de infraestructura.
- Para SKU, validar identidad de producto simple mediante `sku_base` y producto con variantes, incluyendo DTO BFF con `status: ACTIVE` para dos variantes elegibles, sin inferir SKU ni exponer variantes no vendibles.
- Para verificación de cantidades, comprobar `binding=false`, tres resultados, comportamiento 422 frente a mapeo ausente y ausencia de reserva/saldos internos.
- No aceptar un snapshot o DTO combinado no publicado.
- Contrato, fixtures y prueba reproducible deben vincularse a revisión/versiones e incluir los casos de la sección 5. Una fixture no equivale a integración HTTP real ni E2E.

## 9. Implementación, permisos y pruebas reales

- OpenAPI `0.6.0-rc.1` es candidato; por sí solo no acredita `IMPLEMENTADA`.
- G1 prevé `catalogo:leer` en las tres rutas del corte. El OpenAPI `0.6.0-rc.1` auditado declara scope, audiencia, allowlist y `pending-security-registration` también para la ruta por slug; queda rectificada la observación anterior de posible ausencia. El grant efectivo continúa pendiente de registro/concesión por G7.
- No se acreditan URL base, credenciales de entorno, llamada HTTP real BFF→G6, despliegue ni prueba E2E en este registro.
- `IMPLEMENTADA` exige implementación identificable; `PROBADA` exige resultado reproducible asociado a versión/commit y alcance; ninguna se deduce de documentación.

## 10. Referencias normativas

- G6 [OpenAPI](../contratos/http/openapi.yaml), [DEC-F](../arquitectura/decisiones/REGISTRO_DEC_F.md), [matriz de trazabilidad](../arquitectura/decisiones/MATRIZ_TRAZABILIDAD_DEC_F.md), [SPEC-003](../requisitos/specs/SPEC-003-gestion-productos-crud.md), [SPEC-004](../requisitos/specs/SPEC-004-gestion-variantes-skus.md) y [SPEC-015](../requisitos/specs/SPEC-015-control-stock-disponibilidad.md).
- G1 `plan/DECISIONES-Y-BLOQUEOS.md`, `plan/iteraciones/S01-semanas-07-08.md` y contratos F-006/F-007/F-011/F-013/F-014/F-024/F-025/F-026, consultados en G1 `main` `a8c3a7e21482063d71a083fd950dd8fa418b615c`.
- Resumen de las nueve respuestas del 13/10 incluido en el encargo. El DOCX fuente no se encontró localmente ni se afirma haberlo inspeccionado.

## Adenda G6 — 2026-10-20

El registro fechado 2026-10-13 se conserva literalmente como evidencia histórica de lo comunicado por G1 ese día. Esta adenda no reescribe la posición histórica ni inventa una respuesta nueva de G1. El líder técnico de G6 comunicó aceptación completa de M-01–M-09 el 2026-10-20. Estado de los nueve acuerdos: `ACEPTADO_G6_COMUNICADO_G1`. La aceptación habilita trabajo propio de G6; no otorga grants G7, no decide por G2/G5 y no equivale a ratificación documental de G1. Véase el [Acuerdo G1–G6 H4](ACUERDO_G1_G6_H4_2026-10-20.md), fuente normativa vigente.
