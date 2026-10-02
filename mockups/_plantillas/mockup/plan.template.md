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
9. Corregir hallazgos detectados hasta obtener visto bueno.
10. Registrar el visto bueno y el estado APROBADO PARA FIGMA en `validation-report.md`.
11. Reflejar fielmente la versión con visto bueno en Figma.
12. Validar la fidelidad entre Figma y la versión aprobada para Figma.
13. Registrar el resultado general APROBADO en `validation-report.md` cuando todos los gates estén cerrados.

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
| Revisión transversal | Reporte de observaciones | Leonardo Vera Rodríguez | Cero hallazgos bloqueantes ni importantes requeridos abiertos |
| Correcciones | Hallazgos solventados | Responsable | Re-inspección aprobatoria |
| Aprobación para Figma | Visto bueno formal | Leonardo Vera Rodríguez | APROBADO PARA FIGMA |
| Figma | Diseño sincronizado | Responsable | Fiel a versión con visto bueno |
| Validación Figma | Fidelidad comprobada | Responsable | Todas las verificaciones PASS |
| Cierre | Validation Report APROBADO | Responsable | Todos los gates cerrados |

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

### Gate E — Revisión Transversal y Aprobación para Figma
- **Revisor:** Leonardo Vera Rodríguez.
- Revisión transversal completada.
- Todos los hallazgos bloqueantes e importantes requeridos están cerrados.
- Visto bueno formal otorgado.
- Estado de revisión transversal: **APROBADO PARA FIGMA**.

### Gate F — Figma y Cierre
- La versión con visto bueno fue reflejada en Figma.
- Figma coincide fielmente con la versión aprobada para Figma.
- Todas las pantallas P0 requeridas están presentes.
- El enlace de Figma está registrado.

**Regla de cierre:** Una vez completados satisfactoriamente el Gate E y el Gate F, y sin hallazgos bloqueantes ni importantes requeridos abiertos, `validation-report.md` puede registrar el **Resultado general = APROBADO**.
