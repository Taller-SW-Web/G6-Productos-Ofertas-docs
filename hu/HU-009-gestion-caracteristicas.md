# HU-009 — Historia de Usuario: Gestión de características y sus valores

**Responsable:** Leonardo Lopez  
**Rama:** lopez  
**Trazabilidad:** Spec [SPEC-009](../specs/SPEC-009-gestion-caracteristicas.md) | Flow [WF-009](../wireframes/flows/WF-009-gestion-caracteristicas.md)

**Como** gestor comercial, **quiero** administrar características tipadas y valores identificados por ID, **para** contar con un catálogo de atributos estandarizado.

## Criterios de aceptación
| ID | Criterio |
|---|---|
| CA-01 | TEXTO respeta límite configurable, inicial 100. |
| CA-02 | NUMERO exige unidad y formato numérico. |
| CA-03 | LISTA respeta límite configurable, inicial 50 activos. |
| CA-04 | Renombrar valor conserva ID y propaga el nombre actualizado sin reescribir SKU/snapshots. |
| CA-05 | Consulta entrega ID, tipo, estado, unidad y valores permitidos con IDs estables. |
| CA-06 | El cambio confirmado de etiqueta publica `taxonomy.characteristic-value.updated` hacia Catálogo, conservando IDs estables y la etiqueta vigente. |
| CA-07 | Asociación/obligatoriedad pertenecen a HU-010; categorías no heredan características; marcas a HU-011. |
| CA-08 | El tipo es inmutable. |
| CA-09 | Baja de valor LISTA usa únicamente la verificación asíncrona transversal de `CHARACTERISTIC_VALUE`; uso activo o falta de confirmación bloquea la baja. |
| CA-10 | Durante la verificación, el valor no se asigna a nuevos productos/variantes y el `202 Accepted` se interpreta solo como admisión, no como baja completada. |
| CA-11 | Una característica puede desactivarse/reactivarse lógicamente sin cambiar su ID; la reactivación restituye la misma identidad con su tipo y sus valores. |
| CA-12 | Una característica inactiva no se ofrece para nuevas asociaciones ni para nuevas capturas de valor, y no altera las asociaciones históricas. |

## Escenarios
1. Renombrar valor: conserva ID y actualiza proyecciones mediante `taxonomy.characteristic-value.updated`.
2. Límite LISTA: al alcanzar el configurado se bloquea alta adicional.
3. Cambio de tipo: se rechaza.
4. Valor usado por SKU activo: baja rechazada.
5. Valor libre: solicitud pasa a “Comprobando uso” y solo se desactiva tras resultado seguro.
6. Verificación no concluyente: conserva el valor activo.
7. Desactivar una característica completa: pasa a inactiva con el mismo ID y desaparece de la oferta de nuevas asociaciones.
8. Reactivar esa característica: vuelve a estar activa con el mismo ID, sin perder sus valores.

## Dependencias
HU-010 define asociación por tipo de producto; HU-011 define marcas; Catálogo verifica uso de valores.
