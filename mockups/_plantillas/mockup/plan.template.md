# Plan de Mockup — MK-XXX

> Define cómo ejecutar el Component Spec. No redefine la UX del módulo.

## 1. Identificación

- **Mockup:** MK-XXX
- **Funcionalidad:** [Nombre]
- **Responsable:** [Nombre]
- **Versión:** [vX.Y]
- **Estado:** Borrador | Aprobado | En ejecución | Completado | Bloqueado

## 2. Entradas obligatorias

| Entrada | Referencia | Estado requerido |
|---|---|---|
| Propuesta UX módulo | `mockups/ux/propuesta-ux.md` | Vigente |
| UX Decisions | `mockups/ux/ux-decisions.md` | Vigente |
| UX Guidelines | `mockups/ux/ux-guidelines.md` | Vigente |
| Component Spec | `component-spec.md` | Aprobado |
| SPEC/HU | [Refs] | Vigentes |
| WF | [Ref] | Vigente |
| Flow | [Ref] | Vigente |
| Design System | [Ref] | Vigente |

## 3. Objetivo

[Resultado final.]

## 4. Pantallas

| ID | Nombre | Prioridad | Orden |
|---|---|---|---:|
| MK-XXX-S01 | [Nombre] | P0 | 1 |
| MK-XXX-S02 | [Nombre] | P0 | 2 |

## 5. Pantalla ancla

- **Pantalla:** [MK-XXX-SXX]
- **Motivo:** [Por qué fija mejor el lenguaje de esta funcionalidad].
- **Qué debe establecer:** [Jerarquía, patrones, componentes recurrentes].

La pantalla ancla no crea una UX independiente; aplica la UX global del módulo a esta funcionalidad.

## 6. Estrategia

1. Preparar contexto y fixtures.
2. Implementar pantalla ancla.
3. Validarla contra fuentes.
4. Implementar pantallas restantes conservando coherencia.
5. Normalizar código.
6. Implementar estados.
7. Validar.
8. Corregir.
9. Preparar Figma.

## 7. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| [Componente] | Design System/shared | [S01,S02] | Reutilizar |

## 8. Normalización

La implementación final debe alinearse a:

- React.
- TypeScript.
- Mantine.
- Tema central.
- Tabler Icons.
- Design System.
- UX Guidelines.
- Accesibilidad.
- PC/desktop únicamente.

## 9. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia |
|---|---|---|---|---|
| Default | S01 | P0 | default | Render |
| Loading | S01 | P0 | loading | Render |
| Error | S01 | P0 | error | Render |

## 10. Orden de ejecución

| Fase | Salida | Gate |
|---|---|---|
| Preparación | Contexto | Entradas vigentes |
| Pantalla ancla | SXX | Cobertura estructural |
| Resto de pantallas | P0 completas | Cobertura funcional |
| Normalización | Código alineado | UI |
| Estados | Casos requeridos | UX |
| Validación | Reporte | Sin bloqueantes |
| Figma | Entregable | Aprobado |

## 11. Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R-01 | [Riesgo] | Baja/Media/Alta | Bajo/Medio/Alto | [Acción] |

## 12. Quality Gates

### Gate A — Funcional
- SPEC/HU/WF/Flow cubiertos.
- Sin reglas inventadas.

### Gate B — UX
- Propuesta UX del módulo aplicada.
- UX Decisions relevantes aplicadas.
- Decisiones locales justificadas.

### Gate C — UI
- Design System respetado.
- Sin tokens arbitrarios.
- Componentes reutilizados.

### Gate D — PC
- Sin overflow horizontal.
- Jerarquía clara en viewport canónico de 1440 px.
- Teclado y foco funcionales.

### Gate E — Cierre
- Validation Report aprobado.
- Figma corresponde al resultado aprobado.
