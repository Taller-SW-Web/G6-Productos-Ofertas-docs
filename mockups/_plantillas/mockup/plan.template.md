# Plan de Mockup — MK-XXX

> **Propósito y rol documental:**
> Define la estrategia de ejecución (cómo debe construirse la funcionalidad).
> Establece fases, orden constructivo, restricciones operativas y Quality Gates.
> Puede ser seguido por un desarrollador o por un agente de forma determinista.
> No redefine el contenido detallado de las pantallas (especificado en `component-spec.md`) ni la UX del módulo.

## 1. Identificación

- **Mockup:** MK-XXX
- **Funcionalidad:** [Nombre de la funcionalidad]
- **Responsable:** [Nombre del owner funcional]
- **Versión:** [vX.Y]
- **Estado:** Borrador | Aprobado | En ejecución | Completado | Bloqueado

## 2. Contrato de ejecución

Establece las condiciones formales, compromisos y límites de la ejecución técnica.

### Entradas
Referencias documentales oficiales que deben consultarse obligatoriamente antes y durante la ejecución del plan:
- `component-spec.md` (especificación principal del resultado esperado del mockup, subordinada a las fuentes oficiales).
- UX Guidelines (`mockups/ux/ux-guidelines.md`).
- UX Decisions (`mockups/ux/ux-decisions.md`).
- Propuesta UX Integral del módulo (`mockups/ux/propuesta-ux.md`).
- Wireframe oficial (`WF-XXX`).
- Flujo de navegación oficial (`FLOW-XXX`).
- Design System de mockups ([mockups/DESIGN.md](../../DESIGN.md), versión consumida, tokens y componentes DS-CXX).

*(Ver detalle de estados requeridos en la sección 3. Entradas obligatorias).*

### Salidas esperadas
Entregables concretos y verificables que deben existir al finalizar la ejecución del plan:
- Todas las pantallas prioritarias P0 implementadas y operativas.
- Una ruta individual relativa y directa por cada pantalla inventariada (`MK-XXX-SXX` accesible en `/MKXXX/SXX`).
- Código normalizado y modular en `prototipo/src/pantallas/MKXXX` alineado al Design System y Mantine.
- Estados P0 operativos y reproducibles de forma determinista (default, loading, error, empty).
- Autovalidación del owner completada con evidencias objetivas registradas en `validation-report.md`.

### Restricciones de ejecución
Reglas estrictas que gobiernan la ejecución para preservar la integridad del módulo:
- **No modificar fuentes de verdad** (SPEC, HU, WF, FLOW, API Contract, Design System) sin una corrección documental explícita y aprobada.
- **No inventar reglas de negocio** ni asumir lógicas no descritas en los documentos oficiales.
- **No inventar campos, botones, filtros ni estados funcionales** ausentes en `component-spec.md`.
- **No crear nuevos patrones UX transversales sin registrarlos** (cualquier excepción justificada debe documentarse como `LUX-XX` en `component-spec.md`).
- **No modificar otros MK** fuera del alcance asignado a esta funcionalidad (`MK-XXX`).
- **No introducir dependencias nuevas**, librerías externas ni utilidades ad hoc sin justificación y aprobación técnica.
- **No redefinir el contenido detallado de pantallas** en este plan si ya reside en `component-spec.md`.

### Condiciones de parada / escalamiento
Detener inmediatamente la ejecución, marcar la tarea como `BLOCKED` y escalar al responsable correspondiente cuando:
- Exista contradicción irreconciliable entre fuentes de verdad (ej. discrepancia entre SPEC, WF y Contrato API).
- Falte información necesaria para tomar una decisión funcional o de negocio crítica.
- Sea necesario inventar comportamiento de interfaz o flujos alternativos no especificados.
- Una dependencia externa requerida (servicio, contrato, componente compartido) no esté definida o disponible.
- Un Quality Gate no pueda verificarse objetivamente debido a ambigüedad en los criterios o bloqueos técnicos.

## 3. Entradas obligatorias

| Entrada | Referencia | Estado requerido |
|---|---|---|
| Propuesta UX módulo | `mockups/ux/propuesta-ux.md` | Vigente |
| UX Decisions | `mockups/ux/ux-decisions.md` | Vigente |
| UX Guidelines | `mockups/ux/ux-guidelines.md` | Vigente |
| Component Spec | `component-spec.md` | Aprobado |
| SPEC/HU | [Refs] | Vigentes |
| WF | [Ref] | Vigente |
| Flow | [Ref] | Vigente |
| Design System | [mockups/DESIGN.md](../../DESIGN.md), versión [versión consumida] | Vigente y coherente con el component-spec |

## 4. Objetivo

[Resultado final esperado de la construcción del mockup.]

## 5. Pantallas

Inventario de pantallas a construir con su orden de ejecución. El contenido detallado se especifica en `component-spec.md`.

| ID | Nombre | Prioridad | Orden |
|---|---|---|---:|
| MK-XXX-S01 | [Nombre] | P0 | 1 |
| MK-XXX-S02 | [Nombre] | P0 | 2 |

## 6. Pantalla ancla

- **Pantalla:** [MK-XXX-SXX]
- **Motivo:** [Por qué fija mejor el lenguaje de esta funcionalidad].
- **Qué debe establecer:** [Jerarquía, patrones, componentes recurrentes].

La pantalla ancla no crea una UX independiente; aplica la UX global del módulo a esta funcionalidad.

## 7. Estrategia

1. Preparar contexto y fixtures deterministas.
2. Implementar y refinar la pantalla ancla conforme al `component-spec.md`.
3. Validarla contra fuentes oficiales y UX transversal del módulo.
4. Implementar y refinar pantallas restantes conservando coherencia arquitectónica.
5. Normalizar código (componentes, tokens, layout y tipografía) y verificar que todas las pantallas inventariadas dispongan de acceso directo mediante su ruta registrada (`/MKXXX/SXX`).
6. Implementar estados interactivos y accesibilidad, asegurando la reproducción determinista de los estados requeridos.
7. Realizar autovalidación por el responsable funcional.
8. Someter a revisión transversal de Leonardo Vera Rodríguez.
9. Corregir hallazgos detectados hasta obtener visto bueno.
10. Registrar el visto bueno y el estado APROBADO PARA FIGMA en `validation-report.md`.
11. Reflejar fielmente la versión con visto bueno en Figma.
12. Validar la fidelidad entre Figma y la versión aprobada para Figma.
13. Registrar el resultado general APROBADO en `validation-report.md` cuando todos los gates estén cerrados.

## 8. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| [Componente] | Design System / shared | [S01, S02] | Reutilizar |

## 9. Normalización

La implementación final debe alinearse a:

- React.
- TypeScript.
- Mantine.
- Tema central del módulo.
- Tabler Icons.
- Design System.
- UX Guidelines.
- Accesibilidad (teclado, foco y contraste).
- PC / desktop únicamente.
- Verificación de rutas de prototipo: comprobación explícita de que todas las pantallas inventariadas (`MK-XXX-SXX`), independientemente de su prioridad, dispongan de acceso directo mediante su ruta registrada (`/MKXXX/SXX`), estable y determinista.

## 10. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---|---|---|
| Default | S01 | P0 | default | Render con datos representativos |
| Loading | S01 | P0 | loading | Render con feedback de carga |
| Error | S01 | P0 | error | Render con mensaje accionable |

## 11. Orden de ejecución

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

## 12. Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R-01 | [Riesgo de ejecución] | Baja / Media / Alta | Bajo / Medio / Alto | [Acción preventiva / reactiva] |

## 13. Quality Gates

### Gate A — Funcional
- SPEC/HU/WF/Flow cubiertos.
- Sin reglas inventadas.
- Todas las pantallas inventariadas disponen de una ruta directa, estable y reproducible dentro del prototipo (`/MKXXX/SXX`).
- Los estados P0 requeridos pueden reproducirse de manera determinista para validación.

### Gate B — UX
- Propuesta UX integral del módulo aplicada rigurosamente.
- UX Decisions (`UXD-XXX`) relevantes aplicadas.
- Decisiones locales (`LUX-XX`) justificadas en `component-spec.md`.

### Gate C — UI
- Design System respetado.
- Sin tokens arbitrarios ni estilos inline huérfanos.
- Componentes compartidos reutilizados.

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
