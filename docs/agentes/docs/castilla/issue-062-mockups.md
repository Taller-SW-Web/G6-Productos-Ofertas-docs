# Encargo para agente — docs #62

**Tipo:** instrucciones retrospectivas derivadas de un issue real; no prompt histórico original ni prueba de ejecución.

## 1. Identificación y fuente

| Campo | Valor |
|---|---|
| Issue | [[MOCKUPS] Marco — MK-001 y MK-002](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/62) |
| Proyecto destino | G6-Productos-Ofertas-docs |
| Asignados de GitHub al consultar | @mrcastilla8 |
| Estado GitHub al consultar | open |
| Última actualización del issue | 2026-10-03T07:34:39Z |
| Consulta/preparación del encargo | 2026-10-17, America/Lima; corte documental del 17 de octubre |
| Carpeta/rama convencional de referencia | `castilla` — Marco Renato Castilla Huanca |
| Modo de uso | Encargo documental preparado; ejecución pendiente de una sesión autorizada y de comprobar gates/fuentes vigentes. |
| Fuente conservada | [Contenido consultado del issue](../../fuentes/docs.md#issue-62) |

Los caminos `mockups/` del issue son referencias del repositorio fuente. En el checkout documental consultado la ruta existente es `ux/mockups/`; los enlaces de esta ficha apuntan a esa ruta. La diferencia se conserva explícita y no cambia el contenido funcional del issue.

## 2. Instrucción al agente

Actúa sobre el issue enlazado, siguiendo las [instrucciones comunes](../../INSTRUCCIONES_COMUNES.md). Antes de ejecutar cambios, contrasta el issue vigente y AGENTS.md del destino. El alcance consultado establece:

> Completar la documentación específica, implementación/refinamiento, autovalidación, revisión UX, pase a Figma y cierre formal de los mockups asignados a **Marco Renato Castilla Huanca**.

1. Comprobar en los issues #59 y #60 los gates de UX/Design System y su disponibilidad en master. El estado abierto del issue no resuelve esos gates.
2. Inventariar artefactos existentes de los MK asignados. Conservar contenido válido y registrar diferencias antes de editar.
3. Completar o corregir component-spec, plan y tasks en ese orden, sin duplicar tareas atómicas en el issue.
4. Refinar el prototipo de cada MK conforme al alcance vigente; normalizar componentes, estados, navegación y accesibilidad para escritorio de 1440 px.
5. Preparar autovalidación y hallazgos. Mantener separados visto bueno UX, APROBADO PARA FIGMA y validación final en Figma.
6. Actualizar validation-report y estado del índice solo con evidencia y dictamen efectivos; si falta aprobación, conservar el pendiente.

## 3. Fuentes que debes leer

- [AGENTS.md](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/AGENTS.md).
- [README.md](../../../../README.md).
- [Registro DEC-F](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/REGISTRO_DEC_F.md).
- [Matriz DEC-F](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/MATRIZ_TRAZABILIDAD_DEC_F.md).
- [ADR B1–B4](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/ADR-DEC-F-BLOQUEANTES.md).
- [OpenAPI](../../../../contratos/http/openapi.yaml).
- [AsyncAPI, si intervienen mensajes](../../../../contratos/eventos/asyncapi.yaml).
- [Contrato de integración](../../../../contratos/http/Contrato_Api.md).
- [Kit de integración](../../../../contratos/http/kit-integracion.md).
- [Arquitectura](../../../../arquitectura/Arquitectura.md).
- [Modelo conceptual](../../../../arquitectura/Modelo_Conceptual.md).
- [Matriz de pruebas](../../../../contratos/pruebas/pruebas-contrato.md).
- [Pipeline de mockups](../../../../ux/mockups/README.md).
- [Design System](../../../../ux/mockups/DESIGN.md).
- [Propuesta UX](../../../../ux/mockups/ux/propuesta-ux.md).
- [UX Decisions](../../../../ux/mockups/ux/ux-decisions.md).
- [UX Guidelines](../../../../ux/mockups/ux/ux-guidelines.md).
- Funcionalidad 001: [SPEC](../../../../requisitos/specs/SPEC-001-carga-exportacion-masiva-productos.md), [HU](../../../../requisitos/hu/HU-001-carga-exportacion-masiva-productos.md), [FLOW](../../../../requisitos/flujos/FLOW-001-carga-exportacion-masiva-productos.md) y [WF](../../../../ux/wireframes/flows/WF-001-carga-exportacion-masiva-productos.md).
- MK-001: [Component Spec](../../../../ux/mockups/MK-001/component-spec.md), [Plan](../../../../ux/mockups/MK-001/plan.md), [Tasks](../../../../ux/mockups/MK-001/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.
- Funcionalidad 002: [SPEC](../../../../requisitos/specs/SPEC-002-gestion-combos-productos.md), [HU](../../../../requisitos/hu/HU-002-gestion-combos-productos.md), [FLOW](../../../../requisitos/flujos/FLOW-002-gestion-combos-productos.md) y [WF](../../../../ux/wireframes/flows/WF-002-gestion-combos-productos.md).
- MK-002: [Component Spec](../../../../ux/mockups/MK-002/component-spec.md), [Plan](../../../../ux/mockups/MK-002/plan.md), [Tasks](../../../../ux/mockups/MK-002/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.

Los enlaces relativos parten de este documento en Docs. En una sesión de otro repositorio, localizar el checkout de Docs y registrar su SHA; no asumir que una carpeta hermana se llama literalmente `docs`. Base documental de este catálogo: `ba0e47cf553b306544c8fc1d3207f5bc51dd6c6a`.

## 4. Archivos y límites

- Artefactos de `ux/mockups/MK-001/` y código de prototipado correspondiente que el encargo autorice.
- Artefactos de `ux/mockups/MK-002/` y código de prototipado correspondiente que el encargo autorice.
- Cambios del índice transversal solo si el alcance humano los incluye; no modificar otros MK, fuentes funcionales, contratos ni UX transversal para hacer encajar el prototipo.

No ejecutar commit, push, PR, merge, mensajes externos o despliegue como consecuencia de abrir esta ficha.

## 5. Criterios de aceptación de la fuente

> Este Issue puede cerrarse únicamente cuando, para **todas** las funcionalidades aquí asignadas:
>
> - [ ] `component-spec.md` está completo y trazable.
> - [ ] `plan.md` está completo.
> - [ ] `tasks.md` está completo y ejecutado según corresponda.
> - [ ] Todas las pantallas P0 requeridas existen.
> - [ ] La autovalidación está completada.
> - [ ] La revisión UX transversal requerida está completada.
> - [ ] No existen hallazgos bloqueantes ni importantes requeridos abiertos.
> - [ ] Existe estado **APROBADO PARA FIGMA**.
> - [ ] Figma refleja fielmente la versión con visto bueno.
> - [ ] La fidelidad en Figma fue validada.
> - [ ] `validation-report.md` registra **Resultado general = APROBADO**.
> - [ ] `mockups/README.md` refleja el estado actualizado de las funcionalidades correspondientes.

Aplicar también los criterios detallados del [issue conservado](../../fuentes/docs.md#issue-62); el extracto no reemplaza la fuente completa.

## 6. Prerrequisitos y dependencias

El gate de inicio #59/#60 exige comprobar resultados vigentes en master antes de ejecutar el pipeline formal. Esta recopilación no declara esos gates superados.

## 7. Validación y salida esperadas

- Enlaces relativos, trazabilidad de cada pantalla con requisito/tarea y git diff --check.
- Inspección de estados y recorrido de escritorio, con capturas reales si se ejecuta el prototipo.
- Revisión UX y fidelidad en Figma como gates independientes; su preparación no es aprobación.

Entregar una relación criterio → archivo/diff → prueba → resultado, los ajustes humanos identificados y los pendientes con owner/operación/condición de desbloqueo. Respetar el formato final del AGENTS.md destino.

**Estado de ejecución de esta ficha:** NO EJECUTADA en esta recopilación. Sesión de implementación, cambios, pruebas y revisión humana se incorporan cuando existan mediante la [plantilla de intervención](../../../uso-ia/plantilla-intervencion.md).

[Volver al índice](../../README.md).
