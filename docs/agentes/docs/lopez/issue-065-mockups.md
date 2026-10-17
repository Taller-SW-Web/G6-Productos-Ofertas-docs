# Encargo para agente — docs #65

**Tipo:** instrucciones retrospectivas derivadas de un issue real; no prompt histórico original ni prueba de ejecución.

## 1. Identificación y fuente

| Campo | Valor |
|---|---|
| Issue | [[MOCKUPS] Leonardo Lopez — MK-008 a MK-012](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/65) |
| Proyecto destino | G6-Productos-Ofertas-docs |
| Asignados de GitHub al consultar | @VicuzS |
| Estado GitHub al consultar | open |
| Última actualización del issue | 2026-10-02T17:18:47Z |
| Consulta/preparación del encargo | 2026-10-17, America/Lima; corte documental del 17 de octubre |
| Carpeta/rama convencional de referencia | `lopez` — Leonardo Lopez |
| Modo de uso | Encargo documental preparado; ejecución pendiente de una sesión autorizada y de comprobar gates/fuentes vigentes. |
| Fuente conservada | [Contenido consultado del issue](../../fuentes/docs.md#issue-65) |

Los caminos `mockups/` del issue son referencias del repositorio fuente. En el checkout documental consultado la ruta existente es `ux/mockups/`; los enlaces de esta ficha apuntan a esa ruta. La diferencia se conserva explícita y no cambia el contenido funcional del issue.

## 2. Instrucción al agente

Actúa sobre el issue enlazado, siguiendo las [instrucciones comunes](../../INSTRUCCIONES_COMUNES.md). Antes de ejecutar cambios, contrasta el issue vigente y AGENTS.md del destino. El alcance consultado establece:

> Completar la documentación específica, implementación/refinamiento, autovalidación, revisión UX, pase a Figma y cierre formal de los mockups asignados a **Leonardo Lopez**.

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
- Funcionalidad 008: [SPEC](../../../../requisitos/specs/SPEC-008-gestion-categorias.md), [HU](../../../../requisitos/hu/HU-008-gestion-categorias.md), [FLOW](../../../../requisitos/flujos/FLOW-008-gestion-categorias.md) y [WF](../../../../ux/wireframes/flows/WF-008-gestion-categorias.md).
- MK-008: [Component Spec](../../../../ux/mockups/MK-008/component-spec.md), [Plan](../../../../ux/mockups/MK-008/plan.md), [Tasks](../../../../ux/mockups/MK-008/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.
- Funcionalidad 009: [SPEC](../../../../requisitos/specs/SPEC-009-gestion-caracteristicas.md), [HU](../../../../requisitos/hu/HU-009-gestion-caracteristicas.md), [FLOW](../../../../requisitos/flujos/FLOW-009-gestion-caracteristicas.md) y [WF](../../../../ux/wireframes/flows/WF-009-gestion-caracteristicas.md).
- MK-009: [Component Spec](../../../../ux/mockups/MK-009/component-spec.md), [Plan](../../../../ux/mockups/MK-009/plan.md), [Tasks](../../../../ux/mockups/MK-009/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.
- Funcionalidad 010: [SPEC](../../../../requisitos/specs/SPEC-010-asociacion-tipo-producto-caracteristica.md), [HU](../../../../requisitos/hu/HU-010-asociacion-tipo-producto-caracteristica.md), [FLOW](../../../../requisitos/flujos/FLOW-010-asociacion-tipo-producto-caracteristica.md) y [WF](../../../../ux/wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md).
- MK-010: [Component Spec](../../../../ux/mockups/MK-010/component-spec.md), [Plan](../../../../ux/mockups/MK-010/plan.md), [Tasks](../../../../ux/mockups/MK-010/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.
- Funcionalidad 011: [SPEC](../../../../requisitos/specs/SPEC-011-gestion-marcas.md), [HU](../../../../requisitos/hu/HU-011-gestion-marcas.md), [FLOW](../../../../requisitos/flujos/FLOW-011-gestion-marcas.md) y [WF](../../../../ux/wireframes/flows/WF-011-gestion-marcas.md).
- MK-011: [Component Spec](../../../../ux/mockups/MK-011/component-spec.md), [Plan](../../../../ux/mockups/MK-011/plan.md), [Tasks](../../../../ux/mockups/MK-011/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.
- Funcionalidad 012: [SPEC](../../../../requisitos/specs/SPEC-012-seo-metadatos.md), [HU](../../../../requisitos/hu/HU-012-seo-metadatos.md), [FLOW](../../../../requisitos/flujos/FLOW-012-seo-metadatos.md) y [WF](../../../../ux/wireframes/flows/WF-012-seo-metadatos.md).
- MK-012: [Component Spec](../../../../ux/mockups/MK-012/component-spec.md), [Plan](../../../../ux/mockups/MK-012/plan.md), [Tasks](../../../../ux/mockups/MK-012/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.

Los enlaces relativos parten de este documento en Docs. En una sesión de otro repositorio, localizar el checkout de Docs y registrar su SHA; no asumir que una carpeta hermana se llama literalmente `docs`. Base documental de este catálogo: `ba0e47cf553b306544c8fc1d3207f5bc51dd6c6a`.

## 4. Archivos y límites

- Artefactos de `ux/mockups/MK-008/` y código de prototipado correspondiente que el encargo autorice.
- Artefactos de `ux/mockups/MK-009/` y código de prototipado correspondiente que el encargo autorice.
- Artefactos de `ux/mockups/MK-010/` y código de prototipado correspondiente que el encargo autorice.
- Artefactos de `ux/mockups/MK-011/` y código de prototipado correspondiente que el encargo autorice.
- Artefactos de `ux/mockups/MK-012/` y código de prototipado correspondiente que el encargo autorice.
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

Aplicar también los criterios detallados del [issue conservado](../../fuentes/docs.md#issue-65); el extracto no reemplaza la fuente completa.

## 6. Prerrequisitos y dependencias

El gate de inicio #59/#60 exige comprobar resultados vigentes en master antes de ejecutar el pipeline formal. Esta recopilación no declara esos gates superados.

## 7. Validación y salida esperadas

- Enlaces relativos, trazabilidad de cada pantalla con requisito/tarea y git diff --check.
- Inspección de estados y recorrido de escritorio, con capturas reales si se ejecuta el prototipo.
- Revisión UX y fidelidad en Figma como gates independientes; su preparación no es aprobación.

Entregar una relación criterio → archivo/diff → prueba → resultado, los ajustes humanos identificados y los pendientes con owner/operación/condición de desbloqueo. Respetar el formato final del AGENTS.md destino.

**Estado de ejecución de esta ficha:** NO EJECUTADA en esta recopilación. Sesión de implementación, cambios, pruebas y revisión humana se incorporan cuando existan mediante la [plantilla de intervención](../../../uso-ia/plantilla-intervencion.md).

[Volver al índice](../../README.md).
