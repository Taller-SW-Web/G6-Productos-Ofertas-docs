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
2. Implementar y refinar la pantalla ancla conforme al Component Spec.
3. Validarla contra fuentes y UX transversal del módulo.
4. Implementar y refinar pantallas restantes conservando coherencia.
5. Normalizar código (componentes, tokens, layout y tipografía).
6. Implementar estados interactivos y accesibilidad.
7. Realizar autovalidación por el responsable funcional.
8. Someter a revisión transversal de Leonardo Vera Rodríguez.
9. Corregir hallazgos detectados (si existen) hasta obtener visto bueno.
10. Registrar visto bueno formal y dictamen APROBADO en `validation-report.md`.
11. Reflejar fielmente el diseño aprobado en Figma.

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

| Fase | Salida | Actor / Revisor | Gate |
|---|---|---|---|
| Preparación | Contexto y fixtures | Responsable | Entradas vigentes |
| Pantalla ancla | SXX refinada | Responsable | Cobertura estructural |
| Resto de pantallas | Pantallas P0 completas | Responsable | Cobertura funcional |
| Normalización | Código alineado al DS | Responsable | UI y tokens normalizados |
| Estados | Casos requeridos interactivos | Responsable | UX y accesibilidad |
| Autovalidación | Checklists locales completos | Responsable | Cero hallazgos bloqueantes ni importantes requeridos abiertos |
| Revisión transversal | Reporte de observaciones | Leonardo Vera Rodríguez | Cero bloqueantes abiertos |
| Correcciones | Hallazgos solventados | Responsable | Re-inspección aprobatoria |
| Aprobación | Visto bueno formal | Leonardo Vera Rodríguez | Dictamen APROBADO en reporte |
| Figma | Entregable final sincronizado | Responsable | Fiel al código aprobado |

## 11. Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R-01 | [Riesgo] | Baja/Media/Alta | Bajo/Medio/Alto | [Acción] |

## 12. Quality Gates

### Gate A — Funcional
- SPEC/HU/WF/Flow cubiertos.
- Sin reglas inventadas.

### Gate B — UX
- Propuesta UX integral del módulo aplicada rigurosamente.
- UX Decisions (`UXD-XXX`) relevantes aplicadas.
- Decisiones locales (`LUX-XX`) justificadas.

### Gate C — UI
- Design System respetado.
- Sin tokens arbitrarios.
- Componentes reutilizados.

### Gate D — PC
- Sin overflow horizontal en viewport canónico de 1440 px.
- Jerarquía visual clara.
- Teclado y foco funcionales.

### Gate E — Revisión Transversal
- **Revisor:** Leonardo Vera Rodríguez.
- Revisión transversal de coherencia del módulo completada.
- Todos los hallazgos bloqueantes e importantes cerrados.
- Visto bueno formal otorgado por Leonardo Vera Rodríguez.

### Gate F — Cierre y Figma
> **Gate explícito:** No se prepara el entregable final en Figma mientras la revisión transversal tenga hallazgos bloqueantes o resultado no aprobado.
- `validation-report.md` cuenta con dictamen **APROBADO**.
- Figma corresponde fielmente al resultado aprobado.
