# WF-012 — Gestión de SEO y metadatos

> Fuentes: SPEC-012, HU-012, DESIGN.md, INDEX.md.

## 0. Producción
- Normalizar slug.
- Sufijo automático visible en creación/regeneración.
- Edición manual duplicada bloqueada.
- Advertencias 70/160, no bloqueo.
- Historial de resoluciones.
- Marketplace ejecuta el 301.
- El endpoint público es contrato de integración: **no existe pantalla administrativa para probarlo**.

## 1. Metadatos
| Campo | Valor |
|---|---|
| ID | WF-012 |
| Versión | 0.5 |
| Estado | Alineado |
| Responsable | Leonardo Lopez |
| Última actualización | 2026-09-29 |

## 2. Pantallas
S-01 SEO por categoría; S-02 Configurar/Editar; S-03 Historial de slugs.

## 3. S-02
Slug, regeneración, meta-título, meta-descripción, contadores y vista previa.

## 4. S-03
Mostrar `slug anterior → slug actual` y fecha. Copy: **“Marketplace utiliza esta resolución para responder la redirección permanente en la URL pública.”**

Se elimina el simulador de endpoint del backoffice.

## 5. Contratos HTTP

### Resolución administrativa para creación
`POST /api/v1/seo/categorias/slug/resolver` recibe el nombre y devuelve `slug` y `colisionResuelta`. WF-008 consume esta operación antes de crear la categoría y muestra `slug` al gestor. Esta operación no reserva la categoría ni se presenta como una pantalla adicional de WF-012.

Si posteriormente `POST /api/v1/categorias` devuelve `SLUG_DUPLICADO`, WF-008 vuelve a solicitar una propuesta y exige otra confirmación; no se sustituye el slug de forma silenciosa.

### Contrato público
La lectura por slug activo/histórico se documenta como integración; no como UI administrativa.

## 6. Responsividad/accesibilidad
320 px, foco, contadores próximos al campo, estados textuales.

## 7. Registro
v0.5 publica el handoff HTTP con WF-008 y la recuperación explícita ante una carrera de slug.  
v0.4 corrige frontera del 301 y elimina el simulador no exigido.

## 8. Integración con WF-008
WF-008 consume `/api/v1/seo/categorias/slug/resolver` para mostrar el slug final. Tras confirmarlo, `POST /api/v1/categorias` envía ese valor como `slugConfirmado`. Este flujo no añade una pantalla SEO adicional en WF-012.

## 9. Registro adicional
v0.5 formaliza el contrato interno de resolución previa para la creación de categorías.
