# Alineación H4: G1 Marketplace ↔ G6 Productos y Ofertas

**Vigencia documental:** 2026-10-20. **Estado G6:** `ACEPTADO_G6_COMUNICADO_G1` para M-01–M-09. Esta aceptación interna fue comunicada a G1. No acredita ratificación escrita adicional de G1, grants G7, despliegue ni E2E. La fuente normativa es el [Acuerdo G1–G6 H4](ACUERDO_G1_G6_H4_2026-10-20.md); el contrato HTTP es el [OpenAPI G6](../contratos/http/openapi.yaml), `0.6.0-rc.1` candidato.

## Frontera y ownership

```text
Navegador Marketplace → Frontend G1 → BFF G1 (sesión/cliente técnico) → Gateway G6 → servicio owner
```

G1 conserva presentación, DTO BFF, filtros de experiencia, carrito, favoritos, checkout, pedido, retries e idempotencia de pedido. G6 conserva producto/variante/SKU/elegibilidad (Catalog), categorías/marcas (Taxonomy), precios/vigencias (Pricing), inventario (Inventory) y reglas/beneficios (Promotions). G2 conserva envío y su contexto; G5 pedido, pago, snapshot durable, reserva confirmada y consumo/restauración; G7 identidad, grants y emisión de token. No hay acceso directo de G1 a persistencia G6.

## Alcance G1 dependiente de datos G6

La fuente G1 SPECS `main@d87ebb4` declara 23 funciones con datos actuales de G6 (F-006–F-017, F-019–F-021, F-023–F-026, F-031, F-036–F-037, F-039) y dos dependencias indirectas/condicionales (F-018/F-038), universo de 25 F; no son 25 llamadas externas. Se revisaron además `plan/ALCANCE-H4-PRODUCTOS-SEGURIDAD.md` v0.7.0 y `plan/DECISIONES-Y-BLOQUEOS.md` v0.7.0. Las funciones principales de G1 no son responsabilidad exclusiva de G6.

| F G1 | Dependencia/owner | Correspondencia contractual G6 / adaptación |
|---|---|---|
| F-006 destacados | G1 compone `featuredProducts[]`; Catalog entrega candidatos elegibles | `listarProductos`; no existe endpoint G6 de curaduría |
| F-007 búsqueda, F-008 filtros, F-009 orden, F-010 paginación | G1 define UX/BFF; Catalog dueño de catálogo, Pricing de precio | `listarProductos`; `pagina` es base 1 en G6 (traducir `page + 1` de G1); sort G1 `NAME_ASC/DESC` a G6 `NOMBRE_ASC/DESC`. OpenAPI actual solo publica categoriaId/marcaId individuales; filtros múltiples/precio son brecha sin paridad. No filtrar una página parcial como si fuera global. |
| F-011 detalle/galería | G1 DTO; Catalog owner | `obtenerProductoPorSlug`; detalle comercial del OpenAPI. Revisar capacidades reales de imágenes en schema; no inventar campos. |
| F-012 precio | Pricing | `consultarPrecios` / `obtenerPrecioSku`; contexto SKU, canal y vigencia según schema. |
| F-013 variantes | Catalog | `obtenerProductoPorSlug`; `product_id`, `slug`, `variant_id`, `sku`, `sku_base` distintos; opciones elegibles; G1 puede mapear su `status` propio. |
| F-014 disponibilidad | Inventory | `consultarDisponibilidadComercial`; cuatro estados, incluido `INDETERMINADO` = HTTP 200 comercial. D-INV-01: una fuente ejecutable, sin suma de ubicaciones. G1 PR SPECS #8 abierto; su texto no prueba merge/homologación. |
| F-015 recomendaciones | Promotions/Cross-sell; composición G1 | `obtenerRecomendaciones`, permitido a `modulo-marketplace` en OpenAPI; enriquecimiento de precio/disponibilidad sigue condicionado por D-REC-01/02 y schema. |
| F-016/F-017 carrito, cantidades, concurrencia | Carrito G1; validación de cantidad Inventory G6 | `verificarCantidadComercial` para validación no vinculante; `binding=false`, sin reserva. Errores/concurrencia del carrito los resuelve G1. |
| F-018/F-038 borrar/deshacer | Persistencia/Deshacer G1; elegibilidad G6 indirecta al restaurar | `NO_APLICA_G6_DIRECTO`; revalidar por operaciones comerciales de origen. |
| F-019–F-021 carrito | G1 persiste carrito, beneficios seleccionados y estado | G6 provee consultas/evaluación; no crea carrito ni consume beneficio con evaluación. |
| F-023–F-026 checkout | G1 experiencia; G5 pedido/pago/snapshot; G2 envío | `NO_APLICA_G6_DIRECTO` para pedido/pago. Consume indirectamente catálogo, precio, inventario y promociones. `PAGADO` solo por confirmación G5. |
| F-031 recompra | G1 flujo; G5 historial/pedido; G6 revalida catálogo comercial actual | `NO_APLICA_G6_DIRECTO` para pedido; usar operaciones actuales de catálogo/precio/disponibilidad/promoción cuando corresponda. |
| F-036/F-037/F-039 favoritos y recomendaciones | Persistencia y UX G1; G6 ofrece catálogo actual/elegibilidad | `listarProductos`, detalle/recomendaciones según contrato. No crear favoritos en G6. |

## Operaciones G6, identidad y semántica

- `listarCategorias` — `GET /api/v1/categorias`, Taxonomy.
- `listarProductos` — `GET /api/v1/productos`, Catalog; filtros/sort solo los del contrato.
- `obtenerProductoPorSlug` — `GET /api/v1/productos/por-slug/{slug}`, Catalog.
- `consultarPrecios` — `GET /api/v1/precios`; `obtenerPrecioSku` — `GET /api/v1/precios/skus/{sku}`, Pricing.
- `listarPromociones` — `GET /api/v1/promociones`; `evaluarPromociones` — `POST /api/v1/promociones/evaluar`; `validarCupon` — `POST /api/v1/cupones/validar`, Promotions. Evaluar/validar no consume; endpoint HTTP solo se considera implementado con handler probado.
- `obtenerRecomendaciones` — `GET /api/v1/recomendaciones`, Promotions.
- `consultarDisponibilidadComercial` — `GET /api/v1/inventario/disponibilidad/comercial`; `verificarCantidadComercial` — `POST /api/v1/inventario/disponibilidad/comercial/verificar`, Inventory. No se exponen saldos/ubicaciones.

Usar scopes/audiencia/allowlist publicados por operación en OpenAPI; cliente de servicio `modulo-marketplace`, audiencia `api-productos`. Los scopes de recomendaciones solo aplican donde autoriza el OpenAPI. G1 BFF mantiene credenciales servidor-servidor; jamás en navegador. G7 debe acreditar grant y JWT real. Claims inválidos/expirados o firma inválida → 401 según contrato; audiencia/scope/allowlist no autorizados → 403. `DEMO_NO_AUTH` no es evidencia H4. El `customer_ref`, si la regla lo exige, es del comprador y no del token técnico BFF.

## Brechas y reglas de compatibilidad

1. **Filtros F-008:** contrato G6 actual conserva categoría y marca individuales. G1/owner Catalog-Poma y Pricing-Vera deben solicitar/evolucionar contrato si requieren múltiples/precio; no declarar implementación sin Provider y no hacer filtrado global sobre página parcial.
2. **Orden/paginación:** adaptar enum y base de página en BFF; no alterar contratos G6 documentalmente.
3. **F-014:** referenciar el mapeo de cuatro estados y fuente única D-INV-01. `INDETERMINADO` no es error de red.
4. **Producto simple/variante:** probar `sku_base` y par `variant_id`/`sku`; nunca inferir SKU.
5. **Contexto fulfilment:** G2/G5/G6 acuerdan origen y semántica de `fulfillment_ref`; omitido/ambiguo sin fuente única produce indeterminado; entrada semánticamente inválida puede ser 422.
6. **Snapshot:** Pricing + Promotions G6, envío G2, snapshot/pedido/resultado G5 y composición G1. Las versiones/vigencias se refieren según contratos vigentes; no se fabrica un DTO único.
7. **Carrito, Deshacer, pedido y pago:** son G1/G5. Evaluación de cupón no es consumo; verificación cantidad no es reserva. Mantener `Idempotency-Key`, fingerprint, correlación y recuperación bajo ownership G1/G5 para pedidos.

Toda condición pendiente debe escribirse como `OWNER + OPERACION + ENTRADA/SALIDA + CONDICION_DE_CIERRE`. Una prueba mock, fixture, YAML, CI de otro SHA o HTTP 200 aislado no acredita Provider real, grant, despliegue ni E2E.

## Dataset y evidencias

Etiquetar por separado (a) ejemplos contractuales, (b) fixtures aisladas, (c) datos Supabase, (d) datos Oracle desplegados, (e) respuestas BFF G1 y (f) pruebas mock. Publicar versión/SHA y procedencia; nunca presentar ejemplos o mocks como datos reales.

Cierre por operación: contrato estático; Provider con casos positivos, no elegible, vacío, inválido y error; Consumer/Provider para mapeos BFF; seguridad con token real y negativos; despliegue identificado por digest/ambiente; y E2E solo con request/response real, dataset, credencial, correlación y commit. Atributos independientes: `CONTRATO_DEFINIDO`, `IMPLEMENTADO`, `CI_VERIFICADA`, `DESPLEGADO`, `AUTORIZACION_VERIFICADA`, `E2E_VERIFICADO`.

## Referencias

- [Acuerdo G1–G6 H4](ACUERDO_G1_G6_H4_2026-10-20.md)
- [Matriz intermodular](MATRIZ_INTERMODULAR_BACKEND.md)
- [Kit de integración](../contratos/http/kit-integracion.md)
- [Pruebas de contrato](../contratos/pruebas/pruebas-contrato.md)
- [Contrato HTTP narrativo](../contratos/http/Contrato_Api.md)
- [OpenAPI](../contratos/http/openapi.yaml)
- G1: [alcance H4](https://github.com/Taller-SW-Web/G1-Marketplace-SPECS/blob/main/plan/ALCANCE-H4-PRODUCTOS-SEGURIDAD.md), [decisiones y bloqueos](https://github.com/Taller-SW-Web/G1-Marketplace-SPECS/blob/main/plan/DECISIONES-Y-BLOQUEOS.md), [PR F-014 #8](https://github.com/Taller-SW-Web/G1-Marketplace-SPECS/pull/8).
