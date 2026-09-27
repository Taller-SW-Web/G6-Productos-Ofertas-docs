# SPEC-009 — Especificación: Gestión de características y sus valores

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** HU [HU-009](../hu/HU-009-gestion-caracteristicas.md) | Wireframe [WF-009](../wireframes/flows/WF-009-gestion-caracteristicas.md)

## 1. Contexto
Los productos requieren atributos como color, talla o material (características) y su clasificación por marcas. Este documento es dueño únicamente de las características y sus valores. La asociación **Tipo de producto–Característica** y Marcas se especifican por separado, evitando confundir categorías de navegación con esquemas de datos.

## 2. Propósito
Permitir al gestor mantener características tipadas y sus valores, con identidades estables que puedan consumir Asociación y Catálogo.

## 3. Alcance
- CRUD de Características (Texto, Número, Lista).
- Consulta de características y valores por ID y estado para su uso por Asociación y Catálogo.

Fuera de alcance normativo: `SPEC-011-gestion-marcas.md` y `SPEC-010-asociacion-tipo-producto-caracteristica.md` son las únicas fuentes de sus respectivas reglas.

## 4. Requisitos

### Requisito 1: Creación y límites de características
El sistema DEBE permitir crear características. Si es `TEXTO`, se aplica `MAX_TEXT_ATTRIBUTE_LENGTH` (valor inicial del MVP: 100 caracteres). Si es `NUMERO`, se exige unidad de medida y se valida que el input final solo acepte formatos numéricos. Estos límites son configuración operativa y no una propiedad conceptual inmutable del dominio.

### Requisito 2: Gestión de valores para tipo LISTA
El sistema DEBE aplicar `MAX_ACTIVE_LIST_VALUES` a los valores activos de una característica `LISTA` (valor inicial del MVP: 50). El límite se configura para proteger usabilidad y rendimiento y puede evolucionar sin migrar el modelo de datos.

*Impacto al renombrar:* Al renombrar un valor en uso, el nuevo nombre se refleja en las consultas actuales de productos asociados por su ID estable cuando sus proyecciones se actualizan; no se reescriben snapshots de pedidos ni los códigos SKU existentes.

### Requisito 3: Contratos de consulta y cambios
La funcionalidad DEBE exponer identificadores, tipo, unidad cuando aplica, estado y valores permitidos con IDs estables. Renombrar un valor LISTA conserva su ID y publica un evento versionado de cambio para actualizar las proyecciones de Catálogo; no reescribe los valores históricos ni modifica los atributos identificadores inmutables de SKUs ya creados. La creación de nuevos SKUs utiliza el catálogo actualizado.

### Requisito 4: Autoridad normativa
Las reglas de asociación entre `tipo_producto_id` y características, obligatoriedad y límite operativo configurable se rigen exclusivamente por `SPEC-010-asociacion-tipo-producto-caracteristica.md`; las categorías permanecen como taxonomía de navegación. Las reglas y unicidad de Marcas se rigen por `SPEC-011-gestion-marcas.md`.

### Requisito 5: Tipo inmutable y baja segura de valores LISTA
El `tipo` de característica (`TEXTO`, `NUMERO`, `LISTA`) se fija al crear y **no se modifica**; para otro tipo se crea una nueva característica con ID distinto. Los valores LISTA se desactivan lógicamente y conservan ID e histórico. Se rechaza la baja si el valor integra la identidad de cualquier SKU ACTIVO o es usado como valor requerido por un producto ACTIVO; una solicitud de baja inicia verificación asíncrona correlacionada en Catálogo y se mantiene pendiente y no seleccionable para nuevos registros mientras se instala la barrera de escritura, análoga a la baja segura de entidades maestras. Ante error, timeout o falta de confirmación se rechaza la baja y se levanta la barrera; el valor vuelve a su estado anterior. Los productos inactivos y pedidos históricos conservan referencias/snapshots; no se borran ni sustituyen atributos. La creación/activación de productos y variantes no puede vincular valores bajo barrera de desactivación. El cambio de etiqueta de un valor sigue permitido y no equivale a su baja.

## 5. Requisitos no funcionales
- Consistencia por ID para permitir renombre de valores sin romper histórico.
- Respuestas de API < 500 ms al listar características y valores.
