# HU-012 — Historia de Usuario: Gestión de SEO y metadatos

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** Spec [SPEC-012](../specs/SPEC-012-seo-metadatos.md) | Flow [WF-012](../wireframes/flows/WF-012-seo-metadatos.md)

**Como** gestor comercial, **quiero** configurar slug y metadatos SEO de cada categoría, **para** mejorar el posicionamiento del Marketplace.

## Criterios
CA-01 slug normalizado automático.  
CA-02 sufijo automático visible antes de confirmar.  
CA-03 duplicado manual rechazado.  
CA-04 advertencias 70/160 sin bloquear.  
CA-05 Productos y Ofertas conserva resolución; Marketplace ejecuta 301.  
CA-06 endpoint público por slug activo.  
CA-07 resolución administrativa `POST /api/v1/seo/categorias/slug/resolver` devuelve la propuesta final antes de crear.  
CA-08 si la propuesta confirmada deja de estar disponible antes del commit, la creación, que envía el valor como `slugConfirmado`, responde `SLUG_DUPLICADO` y exige una nueva resolución/confirmación; no cambia el slug silenciosamente.  
CA-09 SEO solo resuelve y proporciona la propuesta: no crea la categoría ni persiste su slug.  
CA-10 quien crea y revalida la unicidad es Categorías, mediante `slugConfirmado` en `POST /api/v1/categorias`.  

## Escenarios
1. Duplicado automático `futbol` → propuesta `futbol-2` visible antes de confirmar.
2. Duplicado manual → “El slug indicado ya está en uso”.
3. Título 75/descripción 170 → advertencias, guardado permitido.
4. Cambio `zapatillas -> zapatillas-deportivas`: Marketplace consulta `zapatillas`; Productos y Ofertas devuelve la resolución permanente; **Marketplace responde 301 al cliente**.
5. Propuesta `futbol-2` confirmada pero ocupada antes del commit → `SLUG_DUPLICADO`; se vuelve al resolver de SEO, se propone otro slug, se muestra y se confirma de nuevo.
6. En ningún caso SEO guarda por su cuenta un slug distinto al confirmado.

## Reglas resueltas
Creación usa una resolución previa visible; `POST /categorias` persiste exactamente el slug confirmado o rechaza la carrera con `SLUG_DUPLICADO`; edición manual rechaza; la capa web pública pertenece a Marketplace.
