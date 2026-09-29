# SPEC-011 — Especificación: Gestión de marcas

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** HU [HU-011](./hu/HU-011-gestion-marcas.md) | Wireframe [WF-011](./wireframes/flows/WF-011-gestion-marcas.md)

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

### Requisito 3: Desactivación/reactivación
La baja es lógica. Si existen productos activos, no se confirma.

Protocolo transversal:
```text
taxonomy.master.deactivation.check.requested
catalog.master.deactivation.checked
taxonomy.master.deactivated
taxonomy.master.deactivation.rejected
```

Taxonomía mantiene la marca activa mientras verifica. Solo `CLEAR` vigente confirma la baja. Error, timeout o ausencia de respuesta no autorizan la desactivación.

La especificación **no fija un tiempo de espera HTTP ni un cronómetro visible** como regla funcional.

Reactivar conserva ID/nombre y respeta la unicidad global.

### Requisito 4: Unicidad global
Una marca inactiva también reserva su nombre normalizado.

## 5. Requisitos no funcionales
- Listado activo <500 ms de referencia.
- Escrituras autenticadas/autorizadas.
- Seguridad y Usuarios decide roles/permisos; Marcas no declara un rol global como contrato oficial.
- Auditoría de creación/modificación.
- Sin transacción distribuida.
- Logo y país validados en backend.

## 6. Fuera de alcance
Categorías/características, asociación producto-marca y almacenamiento físico del archivo de logo.

## Criterio de completitud
Unicidad global, tipos de logo, país ISO, baja segura y reactivación quedan alineados sin timeout ni rol inventado.
