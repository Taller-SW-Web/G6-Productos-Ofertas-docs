# SPEC-009 — Especificación: Gestión de características y sus valores

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** HU [HU-009](./hu/HU-009-gestion-caracteristicas.md) | Wireframe [WF-009](./wireframes/flows/WF-009-gestion-caracteristicas.md)

## 1. Contexto
Los productos requieren características como color, talla o material. Esta capacidad es propietaria únicamente del catálogo de características y sus valores. La asociación Tipo de Producto–Característica se define en SPEC-010 y Marcas en SPEC-011.

## 2. Propósito
Mantener características tipadas y valores con IDs estables para consumo de Asociación y Catálogo.

## 3. Alcance
- CRUD lógico de características `TEXTO`, `NUMERO`, `LISTA`.
- Consulta por ID/estado.
- Valores LISTA.
- Renombrado por ID.
- Baja lógica segura de valores.
- Tipo inmutable.

## 4. Requisitos

### Requisito 1: Creación y límites
`TEXTO`: `MAX_TEXT_ATTRIBUTE_LENGTH`, valor inicial 100.  
`NUMERO`: unidad obligatoria y formato numérico.  
Los límites son configurables.

### Requisito 2: LISTA
`MAX_ACTIVE_LIST_VALUES`, valor inicial 50 activos. Renombrar un valor conserva su ID y actualiza las consultas actuales tras propagación.

### Requisito 3: Contratos de consulta/cambios
La consulta expone ID, tipo, unidad, estado y valores con IDs estables.

Un renombrado confirmado de valor LISTA DEBE publicar el hecho interno versionado `taxonomy.characteristic-value.updated` hacia Catálogo para actualizar sus proyecciones. El payload conserva `caracteristica_id` y `valor_id`, publica la etiqueta vigente (`nombre`), `change_type=RENAMED` y `updated_at`. La identidad del valor no cambia y la entrega se procesa con la política de deduplicación del envelope AsyncAPI.

No se reescriben snapshots históricos ni SKU existentes.

### Requisito 4: Autoridad normativa
Obligatoriedad y asociación con tipos de producto pertenecen exclusivamente a SPEC-010. Categorías son navegación. Marcas se rige por SPEC-011.

### Requisito 5: Tipo inmutable
El tipo `TEXTO | NUMERO | LISTA` se fija al crear. Para cambiarlo se crea una nueva característica.

### Requisito 6: Baja segura de un valor LISTA
La baja es lógica.

Si el valor:
- integra la identidad de un SKU ACTIVO; o
- es requerido por un producto ACTIVO,

debe rechazarse.

La solicitud inicia una verificación asíncrona correlacionada con Catálogo y una barrera que evita nuevos vínculos mientras se decide.

Secuencia:
1. solicitud recibida;
2. valor queda temporalmente no seleccionable para nuevas altas;
3. Catálogo verifica uso;
4. resultado seguro sin uso → baja confirmada;
5. uso activo → rechazo y restauración del estado previo;
6. error/timeout/falta de confirmación → no se confirma la baja y el valor vuelve al estado anterior.

**Estado contractual:** la baja segura de `CHARACTERISTIC_VALUE` utiliza el contrato transversal publicado en AsyncAPI: `taxonomy.master.deactivation.check.requested` → `catalog.master.deactivation.checked` → `taxonomy.master.deactivated | taxonomy.master.deactivation.rejected`. El `202 Accepted` representa admisión de la solicitud, no finalización.

### Requisito 7: Baja/reactivación de característica
La característica puede desactivarse lógicamente y reactivarse sin cambiar su ID. Una característica inactiva no se ofrece para nuevas asociaciones.

## 5. NFR
- IDs estables.
- Consulta <500ms de referencia.
- Fallo cerrado en baja segura.
- Sin borrado físico.

## 6. Fuera de alcance
- Marcas.
- Asociación Tipo Producto–Característica.
- Captura de valores en un producto.
- Definir obligatoriedad.
- Definir unilateralmente nuevos mensajes fuera del AsyncAPI canónico.

## Criterio de completitud
Se cumplen tipos, límites, IDs estables, tipo inmutable y baja segura asíncrona de valores.
