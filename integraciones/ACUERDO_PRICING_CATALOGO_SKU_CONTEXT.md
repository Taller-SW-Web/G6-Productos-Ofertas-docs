# Acuerdo privado Pricing → Catálogo: `skuContext`

- **Registro documental:** 2026-10-26.
- **Aprobación interna:** Marco aprobó el diseño comunicado por Poma en esta actualización; Poma es responsable de Catálogo y Vera de Pricing.
- **Traza:** [Backend issue #24](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/24). El comentario de esta actualización registra el acuerdo y la evidencia documental, sin cerrar el issue.
- **Fuente HTTP ejecutable:** [OpenAPI](../contratos/http/openapi.yaml), operación `obtenerContextoSku`, schema de respuesta `PricingCatalogContext`.
- **Estado:** diseño aprobado por G6; contrato candidato incorporado en Docs. Confirmación de identidad y grant G7, implementación y pruebas runtime pendientes de evidencia. Este registro no crea otra DEC-F.

## Contrato aprobado

Catálogo ofrece `GET /api/v1/productos/skus/{sku}/contexto` exclusivamente como operación interna para Pricing. El SKU viaja codificado correctamente en el path, conservando su valor original, incluidos ceros iniciales; no se transforma ni se sustituye por otro identificador. La ruta no se publica como endpoint comercial para canales.

El `200 application/json` reutiliza exactamente el DTO de respuesta de `PricingCatalogContext.resolve`: `sku: string`, `productId: string`, `isVariant: boolean`, `active: boolean` y `eligible: boolean`, todos obligatorios. `active` representa el estado del SKU; `eligible`, su elegibilidad comercial según Catálogo. No se incluyen cálculos de precios ni disponibilidad de inventario. La consulta de contexto no depende de resolver precios en Pricing.

Un SKU existente se devuelve aunque esté inactivo o sea inelegible: `200` con los flags correspondientes en `false`. Esto permite distinguir existencia, estado y elegibilidad; no se reutiliza una proyección comercial que oculte esos SKU.

| Situación | Respuesta de Catálogo | Tratamiento en el adaptador de Pricing |
|---|---|---|
| SKU existente, simple o variante | `200` con el DTO de cinco campos | Entregar el contexto al puerto sin cambiar su interfaz |
| SKU existente inactivo o inelegible | `200`, con los flags correspondientes en `false` | Conservar el contexto y sus flags; no convertirlo en ausencia |
| SKU inexistente | `404 SKU_NO_ENCONTRADO` | Traducir únicamente este resultado a `null` |
| Fallo técnico o indisponibilidad | `503 SERVICIO_NO_DISPONIBLE` | Propagar como fallo; nunca devolver `null` por este motivo |
| Autenticación/autorización inválidas | `401 TOKEN_INVALIDO` / `403 SCOPE_INSUFICIENTE`, según el contrato de seguridad existente | Propagar el fallo; no tratarlo como SKU inexistente |
| Fallo de red | No hay respuesta HTTP autoritativa de Catálogo | Tratar como error técnico; no fabricar `404` ni `null` |

Los errores HTTP usan `application/problem+json` y el schema `Problem` existente, con `status` y `code`. Los códigos y restricciones por respuesta están en OpenAPI; el consumidor ramifica por `code`, no por texto humano.

## Seguridad y límite de autorización

Se reutiliza el contrato G7 `client_credentials` con identidad técnica compartida por G6: `client_id=modulo-productos`, tipo `servicio`, `aud=api-productos` y scope existente `catalogo:leer`. La allowlist de esta operación contiene únicamente `modulo-productos`; no identifica individualmente a `catalog-svc` ni `pricing-svc`. No se autoriza acceso anónimo ni `userBearer`. El token debe validar firma JWT mediante JWKS, issuer, audiencia, expiración, tipo, scope y autorización por operación. La llamada usa HTTP privado con restricción de red y la ruta no se expone en Gateway externo; cabeceras arbitrarias no prueban identidad.

La decisión está aprobada internamente por Marco. G7 debe confirmar y conceder `catalogo:leer` a `modulo-productos` y provisionar credenciales `client_credentials`; hasta entonces la integración autenticada está `BLOQUEADO_ESPECÍFICO`. La definición documental no demuestra grant ni credenciales. Las allowlists comerciales permanecen intactas y el scope de lectura no concede escritura.

## Responsabilidades y estado operativo

| Responsable | Trabajo y estado |
|---|---|
| Poma / Catálogo | PR Backend #125, HEAD `e2a5ac3a665d1cb127c98b30e65cca1e3e61e462`: reporta endpoint implementado y pruebas CI de proveedor en ese SHA. Debe adecuar allowlist de `modulo-pricing` a `modulo-productos`, confirmar exclusión del Gateway y aportar SHA/CI actualizados. |
| Vera / Pricing | Implementar el adaptador HTTP del puerto existente, preservando el mapeo `404 SKU_NO_ENCONTRADO → null` y la distinción de fallos: pendiente de evidencia; PR/issue #24 mantiene esta dependencia específica. |
| G7 / Seguridad | Confirmar y conceder `catalogo:leer` para `modulo-productos`, `aud=api-productos`, y provisionar token `client_credentials`: pendiente; no se atribuye aceptación ni credenciales concedidas. |
| Poma y Vera | Aportar pruebas de SKU existente, inexistente, variante, inactivo, inelegible, errores técnicos y autorización con SHA y alcance; registrar evidencias en issue #24. |

La documentación aprobada es `IMPLEMENTAR_AHORA`. La implementación interna de cada owner puede avanzar con su contrato; la llamada real autenticada queda `BLOQUEADO_ESPECÍFICO` hasta confirmar identidad y token con G7. No se bloquea todo Catálogo/Pricing ni se declara integración completada. Los [casos de contrato](../contratos/pruebas/pruebas-contrato.md) distinguen validación estática de proveedor, adaptador y E2E.
