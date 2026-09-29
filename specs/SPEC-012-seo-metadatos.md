# SPEC-012 — Especificación: Gestión de SEO y metadatos

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** HU [HU-012](./hu/HU-012-seo-metadatos.md) | Wireframe [WF-012](./wireframes/flows/WF-012-seo-metadatos.md)

## 1. Contexto
Cada categoría necesita slug y metadatos unificados para SEO.

## 2. Propósito
Configurar el slug, registrar historial y exponer la resolución para que Marketplace ejecute la respuesta HTTP pública correspondiente.

## 3. Alcance
Generación/edición de slug, resolución previa para creación de categoría, historial `old_slug -> new_slug`, advertencias 70/160 y endpoint público de lectura por slug activo.

## 4. Requisitos
### Requisito 1: Metadatos
Meta-título: advertencia >70. Meta-descripción: advertencia >160. Guardado permitido.

### Requisito 2: Duplicados
Creación automática: `POST /api/v1/seo/categorias/slug/resolver` normaliza el nombre y devuelve `slug` y `colisionResuelta`. El sufijo incremental está permitido, pero `slug` debe mostrarse antes de confirmar.  
Edición manual: duplicado rechazado; sin sufijo automático.

La resolución previa no es una reserva permanente. Por ello, la creación de categoría envía el `slug` confirmado. Si ese slug queda ocupado antes del commit, `POST /api/v1/categorias` responde `409 SLUG_DUPLICADO`; debe generarse otra propuesta y volver a solicitar confirmación. Nunca se sustituye silenciosamente por otro sufijo.

### Requisito 3: Historial/redirección
Productos y Ofertas conserva `old_slug -> new_slug` y expone la resolución. **Marketplace**, propietario de la URL pública, es quien responde `301 Moved Permanently` al navegador. Este módulo no ejecuta el 301.

### Requisito 4: Endpoint público
Lectura por slug activo, sin autenticación y sin operaciones de escritura. Categoría inactiva no se devuelve como publicada.

### Requisito 5: Contrato de creación con Categorías
SEO conserva ownership sobre normalización y resolución de colisiones. Categorías consume el contrato sin habilitar edición manual de SEO en WF-008.

```text
POST /api/v1/seo/categorias/slug/resolver
  { nombre }
  -> { slug, colisionResuelta }

POST /api/v1/categorias
  { .., slugConfirmado }
```

La creación debe persistir exactamente `slugConfirmado` o responder `409 SLUG_DUPLICADO` si dejó de estar disponible. Nunca sustituye silenciosamente el valor confirmado.

## 5. Criterio de completitud
Las reglas 70/160, duplicados, historial y endpoint quedan correctas sin atribuir el HTTP 301 a Productos y Ofertas.

### Contrato administrativo publicado
`/api/v1/seo/categorias/slug/resolver` recibe `nombre` y devuelve `slug` + `colisionResuelta`. `POST /api/v1/categorias` exige ese valor como `slugConfirmado`; si deja de estar disponible antes del commit, responde `409 SLUG_DUPLICADO` sin aplicar otro sufijo automáticamente.
