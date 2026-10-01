# SPEC-011 — Especificación: Gestión de marcas

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** HU [HU-011](../hu/HU-011-gestion-marcas.md) | Wireframe [WF-011](../wireframes/flows/WF-011-gestion-marcas.md)

## 1. Contexto
Las marcas clasifican productos y alimentan filtros de navegación. Se gestionan en Taxonomía de forma separada de Categorías, Características y Asociación Tipo de Producto–Característica.

## 2. Propósito
Crear, consultar, actualizar, desactivar y reactivar marcas, incluyendo logo y país de origen opcional.

## 3. Alcance
Alta, listado/consulta, edición, baja lógica/reactivación, lectura de marcas activas y baja segura coordinada con Catálogo.

## 4. Requisitos

### Requisito 1: Creación
Nombre globalmente único tras `trim` y comparación sin distinción de mayúsculas/minúsculas, **incluyendo marcas inactivas**.

Logo: PNG, JPG/JPEG o WebP, máximo 5 MB.  
País: opcional, código ISO 3166-1.

### Requisito 2: Actualización
Nombre, descripción, logo y país son editables. Renombrar revalida unicidad global. Reemplazar logo no afecta productos asociados.

La actualización es persistencia y consulta HTTP ordinarias. **No existe un evento de marca publicado** en AsyncAPI 0.4.0: en particular no hay un «evento de actualización de marca» ni un «evento de estado de marca». No se inventan mensajes genéricos para representar esta operación.

```text
PATCH /api/v1/marcas/{marcaId}
GET   /api/v1/marcas
```

La propagación hacia canales se produce por la nueva disponibilidad en `GET /api/v1/marcas`, no por mensajería.

### Requisito 3: Desactivación/reactivación
La baja es lógica. Si existen productos activos, no se confirma.

La baja usa **únicamente el protocolo transversal publicado** para la entidad maestra `BRAND`:

```text
taxonomy.master.deactivation.check.requested
catalog.master.deactivation.checked
taxonomy.master.deactivated
taxonomy.master.deactivation.rejected
```

Taxonomía mantiene la marca activa mientras verifica. Solo `CLEAR` vigente confirma la baja. Error, timeout o ausencia de respuesta no autorizan la desactivación.

```text
POST /api/v1/marcas/{marcaId}/desactivar      -> 202 Accepted (solo admisión)
POST /api/v1/marcas/{marcaId}/reactivar
GET  /api/v1/taxonomia/operaciones/{operationId}
```

La especificación **no fija un tiempo de espera HTTP ni un cronómetro visible** como regla funcional.

La reactivación conserva ID/nombre, respeta la unicidad global y es una operación síncrona sobre el recurso: no publica ningún mensaje.

### Requisito 4: Unicidad global
Una marca inactiva también reserva su nombre normalizado.

## 5. Contratos de mensajería

| Operación | Mensaje |
|---|---|
| Baja segura de marca | protocolo transversal de entidad maestra (`BRAND`) |

Cualquier otra operación de Marcas se representa por HTTP, sin mensajería.

## 5. Requisitos no funcionales
- Listado activo <500 ms de referencia.
- Escrituras autenticadas/autorizadas.
- Seguridad y Usuarios decide roles/permisos; Marcas no declara un rol global como contrato oficial.
- Auditoría de creación/modificación.
- Sin transacción distribuida.
- Logo y país validados en backend.

## 6. Fuera de alcance
Categorías/características, asociación producto-marca y almacenamiento físico del archivo de logo.

## 7. Fuera de alcance contractual
Definir mensajes propios de esta capacidad. No existen eventos genéricos de «actualización» ni de «estado» de marca en AsyncAPI 0.4.0.

## Criterio de completitud
Unicidad global, tipos de logo, país ISO, baja segura —únicamente por el protocolo transversal—, reactivación y ausencia de mensajería inventada quedan alineados sin timeout ni rol inventado.
