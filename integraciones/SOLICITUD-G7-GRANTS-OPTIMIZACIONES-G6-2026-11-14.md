# Solicitud preparada para owner de G7 — grants de optimizaciones G6

**Estado:** solicitud preparada para revisión/envío por el owner G6. No enviada por esta automatización ni aplicada a Seguridad. La aprobación interna G6 no concede permisos G7.

## 1. Identidad técnica de Pricing hacia Catálogo

- Cliente: `modulo-productos` (`tipo=servicio`).
- Audience: `api-productos`.
- Scope mínimo: `catalogo:leer`.
- Operación permitida: únicamente `POST /api/v1/productos/skus/contexto/lote` y compatibilidad existente `GET /api/v1/productos/skus/{sku}/contexto`, desde Pricing hacia la red privada de Catálogo.
- No permitir ni enrutar estas operaciones en el Gateway público. No emitir esta identidad para navegador ni conceder otros endpoints por herencia amplia.
- Solicitud: confirmar issuer/client registration, grant activo y provisioning seguro de credenciales para el workload Pricing, con evidencia sin token (versión/configuración aprobada y pruebas 200/401/403).

## 2. Consultas técnicas a Pricing desde Catálogo

- Cliente: `modulo-productos`, audience `api-productos`.
- Confirmar/provisionar `precios:leer` solamente para la operación comercial batch que Catálogo utiliza al evaluar `precioMin`/`precioMax`, si el provider requiere ese scope y el registro actual no lo acredita.
- No conceder acceso a escrituras, endpoints administrativos ni tablas de Pricing.
- Criterio de desbloqueo: operación exacta registrada en allowlist de Pricing, token emitido por G7 para workload autorizado y pruebas 200/401/403 con logs sin secretos.

## 3. JWT humano de administración G6

- Cliente: usuario humano G6; no `client_credentials`, sin audience o scopes técnicos inventados.
- Rol solicitado a confirmar/provisionar: `GESTOR_COMERCIAL` en los JWT humanos de usuarios autorizados.
- Operaciones de G6: `POST /api/v1/productos/administracion/skus/resolver`, `GET /api/v1/auditoria-precios/administracion`, `GET /api/v1/auditoria-precios/administracion/{auditId}` y `POST /api/v1/combos/administracion` (las dos últimas no alteran su autorización por la sola publicación OpenAPI).
- Criterio de desbloqueo: owner confirma política/claim de roles; emitir token de usuario autorizado para pruebas y acreditar 200, 401 y 403 para las operaciones de administración, incluyendo rol ausente.

## Evidencia consultada y limitación

El repositorio consultable de Seguridad contiene políticas/implementación de JWT humano con `tipo=acceso` y validación de `roles`; el seed inspeccionado contiene el rol `GESTOR_COMERCIAL`, pero no se encontró ahí una concesión de permisos que pruebe su grant runtime. Tampoco se encontró en el código accesible un issuer/grant técnico verificable para la combinación cliente/audience/scope solicitada. Esto es evidencia del repositorio público consultado, **no prueba de ausencia en configuración privada o ambiente**. No se accedió a bases de Seguridad, credenciales ni tokens productivos. La solicitud se desbloquea únicamente con confirmación verificable del owner G7 y evidencia de emisión/autorización no secreta.
