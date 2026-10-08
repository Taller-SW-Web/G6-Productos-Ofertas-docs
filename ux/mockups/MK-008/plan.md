# Plan de Mockup — MK-008

## 1. Identificación

- **Mockup:** MK-008 — Gestión de categorías y subcategorías
- **Funcionalidad:** Taxonomía de navegación del catálogo (árbol recursivo de categorías y subcategorías)
- **Responsable:** Leonardo Lopez (rama `lopez`)
- **Versión:** 1.1 — 2026-10-03
- **Estado:** **En revisión** — aprobación documental pendiente. No habilita implementación ni Figma.

## 2. Contrato de ejecución

### Entradas

- `component-spec.md` (resultado esperado, subordinado a las fuentes oficiales).
- UX transversal: [ux-guidelines.md](../ux/ux-guidelines.md), [ux-decisions.md](../ux/ux-decisions.md), [propuesta-ux.md](../ux/propuesta-ux.md).
- Wireframe oficial [WF-008](../../wireframes/flows/WF-008-gestion-categorias.md) v0.7.
- Flujo oficial [FLOW-008](..\..\..\requisitos\flujos\FLOW-008-gestion-categorias.md).
- Design System [DESIGN.md](../DESIGN.md) 1.0.0 (tokens y componentes DS-C01…DS-C28).
- Contratos: [api/openapi.yaml](..\..\..\contratos\http\openapi.yaml) 0.5.0, [Contrato_Api.md](..\..\..\contratos\http\Contrato_Api.md), [asyncapi.yaml](..\..\..\contratos\eventos\asyncapi.yaml) 0.4.0.

### Salidas esperadas

- Las 9 pantallas P0 de §5 implementadas y operativas.
- Una ruta individual y directa por pantalla: `/MK008/S01`, `/MK008/S02`, `/MK008/S02-C`, `/MK008/S03`, `/MK008/S04`, `/MK008/S04-P`, `/MK008/S04-B`, `/MK008/S05`, `/MK008/S05-R`.
- Código normalizado y modular en `prototipo/src/pantallas/MK008`.
- Estados P0 deterministas: default, loading, empty, error y los negativos de `component-spec.md` §13.
- Autovalidación del owner con evidencias en `validation-report.md` (aún no emitido).

### Restricciones de ejecución

- No modificar SPEC, HU, WF, FLOW, contrato API ni Design System sin corrección documental aprobada.
- No inventar reglas de negocio, campos, acciones ni estados ausentes de `component-spec.md`.
- No redefinir el contenido de pantallas en este plan.
- No crear patrones UX transversales nuevos; toda excepción local se registra como `LUX-01` o `LUX-02`.
- No modificar otros MK.
- No introducir dependencias, librerías ni utilidades ad hoc sin aprobación técnica.
- Toda actualización de datos se ejecuta por `PATCH`; no se modelan rutas `PUT`.
- La admisión `202` no se representa como cambio confirmado.

### Condiciones de parada / escalamiento

Detener la tarea, marcarla `BLOCKED` y escalar cuando:
- Exista contradicción irreconciliable entre SPEC, HU, WF, FLOW y contrato API.
- Falte información necesaria para una decisión funcional crítica (por ejemplo, la fuente authoritative del árbol administrativo).
- Sea necesario inventar comportamiento de interfaz o flujos no especificados.
- Una dependencia externa requerida no esté definida o disponible.
- Un Quality Gate no pueda verificarse objetivamente.

## 3. Entradas obligatorias

| Entrada | Referencia | Estado requerido |
|---|---|---|
| Propuesta UX módulo | [propuesta-ux.md](../ux/propuesta-ux.md) | Vigente |
| UX Decisions | [ux-decisions.md](../ux/ux-decisions.md) | Vigente |
| UX Guidelines | [ux-guidelines.md](../ux/ux-guidelines.md) | Vigente |
| Component Spec | [component-spec.md](component-spec.md) v1.1 | **En revisión** (aún no aprobado) |
| SPEC/HU | [SPEC-008](..\..\..\requisitos\specs\SPEC-008-gestion-categorias.md), [HU-008](..\..\..\requisitos\hu\HU-008-gestion-categorias.md) | Vigentes |
| WF | [WF-008](../../wireframes/flows/WF-008-gestion-categorias.md) v0.7 | Vigente |
| Flow | [FLOW-008](..\..\..\requisitos\flujos\FLOW-008-gestion-categorias.md) | Vigente |
| Design System | [DESIGN.md](../DESIGN.md) 1.0.0 | Vigente y coherente con el component-spec |

## 4. Objetivo

Construir el árbol administrativo de categorías y su ciclo de vida completo (alta con slug confirmado, edición y reubicación, baja lógica segura y reactivación), de modo que el gestor comercial pueda administrar la jerarquía del catálogo sin riesgo de rupture de navegación ni pérdida de trazabilidad de productos.

## 5. Pantallas

| ID | Nombre | Prioridad | Ruta | Orden |
|---|---|---|---|---:|
| MK-008-S01 | Árbol de categorías | P0 | `/MK008/S01` | 1 |
| MK-008-S02 | Crear categoría | P0 | `/MK008/S02` | 2 |
| MK-008-S02-C | Confirmar slug SEO | P0 | `/MK008/S02-C` | 3 |
| MK-008-S03 | Editar categoría | P0 | `/MK008/S03` | 4 |
| MK-008-S05 | Detalle de categoría | P0 | `/MK008/S05` | 5 |
| MK-008-S04 | Solicitar desactivación | P0 | `/MK008/S04` | 6 |
| MK-008-S04-P | Verificando dependencias | P0 | `/MK008/S04-P` | 7 |
| MK-008-S04-B | Baja rechazada | P0 | `/MK008/S04-B` | 8 |
| MK-008-S05-R | Reactivación bloqueada | P0 | `/MK008/S05-R` | 9 |

El orden es constructivo, no de flujo: el árbol fija los patrones, la alta con slug establece la secuencia obligatory de confirmación y la baja introduce el modelado asíncrono que las demás pantallas reutilizarán.

## 6. Pantalla ancla

- **Pantalla:** MK-008-S01 — Árbol de categorías.
- **Motivo:** concentra el componente de jerarquía recursiva, el Badge de estado, la navegación hacia todas las acciones y el patrón de vacío que el resto del módulo reutiliza.
- **Qué debe establecer:** jerarquía visual del módulo, densidad de tabla, tratamiento del estado por texto y color, patrón de acciones por fila y microtexto de filtros y vacíos.

La pantalla ancla no crea una UX independiente; aplica la UX global del módulo.

## 7. Estrategia

1. Preparar contexto y fixtures deterministas de `component-spec.md` §13.
2. Implementar y refinar MK-008-S01 conforme al `component-spec.md`.
3. Validar S01 contra SPEC-008, HU-008, WF-008, FLOW-008 y UX transversal.
4. Implementar MK-008-S02 y S02-C de forma conjunta: la secuencia resolver → mostrar → confirmar → crear es indivisible.
5. Implementar MK-008-S03 y S05 aplicando los patrones de S01.
6. Implementar MK-008-S04, S04-P y S04-B, que introducen el patrón de seguimiento por `operationId` reutilizable en el módulo.
7. Implementar MK-008-S05-R como caso de bloqueo por precondición de negocio.
8. Normalizar código, tokens, layout y tipografía, y verificar el acceso directo de las 9 rutas inventariadas.
9. Implementar estados interactivos y accesibilidad con reproducción determinista.
10. Realizar autovalidación por el responsable funcional.
11. Someter a revisión transversal de Leonardo Vera Rodríguez.
12. Corregir hallazgos hasta obtener visto bueno.
13. Registrar el visto bueno y el estado APROBADO PARA FIGMA en `validation-report.md`.
14. Reflejar fielmente la versión con visto bueno en Figma.
15. Validar la fidelidad entre Figma y la versión aprobada.
16. Registrar el resultado general APROBADO cuando todos los gates estén cerrados.

## 8. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| DS-C01 Button / DS-C02 ActionIcon | Design System / shared | S01–S05-R | Reutilizar sin variantes nuevas |
| DS-C03 TextInput / DS-C05 Textarea / DS-C06 Select | Design System / shared | S01, S02, S03 | Reutilizar |
| DS-C12 Search | Design System / shared | S01 | Reutilizar |
| DS-C14 Badge | Design System / shared | S01, S05 | Reutilizar para estado y nivel |
| DS-C17 Table | Design System / shared | S01 | Reutilizar con indentación por nivel |
| DS-C19 Card | Design System / shared | S01, S02, S03, S05 | Reutilizar |
| DS-C21 Modal | Design System / shared | S02-C, S04, S04-B, S05-R | Reutilizar a 480 px |
| DS-C22 Alert | Design System / shared | S02-C, S04-P, S04-B, S05-R | Reutilizar para colisión, verificación y rechazo |
| DS-C24 Skeleton / DS-C25 EmptyState | Design System / shared | S01, S03, S05 | Reutilizar |
| MK-008-C01 Árbol de categorías | Component spec §9 | S01 | Construir específico |
| MK-008-C02 Selector de categoría padre | Component spec §9 | S02, S03 | Construir específico |
| MK-008-C03 Confirmación de slug | Component spec §9 | S02-C | Construir específico |
| MK-008-C04 Seguimiento de operación | Component spec §9 | S04-P, S04-B | Construir específico; reutilizable en otros MK con verificación asíncrona |

## 9. Normalización

La implementación final debe alinearse a React, TypeScript, Mantine, tema central del módulo, Tabler Icons, Design System, UX Guidelines, accesibilidad (teclado, foco y contraste) y PC/desktop únicamente. Se verifican de forma explícita las nueve rutas inventariadas, incluidas las variantes con sufijo: `/MK008/S02-C`, `/MK008/S04-P`, `/MK008/S04-B` y `/MK008/S05-R`.

## 10. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---|---|---|
| Default | S01 | P0 | `default` | Árbol de dos niveles con estado por fila |
| Loading | S01 | P0 | `loading` | Skeleton de filas sin acciones habilitadas |
| Empty | S01 | P0 | `empty` | EmptyState con acción Crear categoría |
| Sin resultados | S01 | P0 | `sin-resultados` | EmptyState con acción Limpiar filtro |
| Error | S01, S03 | P0 | `error` | Mensaje accionable con reintento |
| Sesión y permisos | Todas | P0 | `sesion` | Estados `401` y `403` sin datos inventados |
| Slug sin colisión | S02-C | P0 | `slug-sin-colision` | URL propuesta sin sufijo |
| Slug con colisión | S02-C | P0 | `slug-con-colision` | URL con sufijo resaltado y alerta |
| Carrera de slug | S02-C | P0 | `slug-carrera-409` | Aviso persistente y nueva propuesta en el mismo diálogo |
| Verificación pendiente | S04-P | P0 | `baja-pendiente` | Banner pendiente con identificador de operación |
| Verificación confirmada | S04-P | P0 | `baja-confirmada` | Resultado `CLEAR` y árbol actualizado |
| Verificación rechazada | S04-B | P0 | `baja-rechazada` | Motivo de rechazo y categoría intacta |
| Verificación no concluyente | S04-B | P0 | `baja-no-concluyente` | Aviso genérico sin afirmar cambio |
| Ciclo rechazado | S03 | P0 | `ciclo-rechazado` | `409 CICLO_CATEGORIA` junto al selector |
| Padre inactivo al editar | S03 | P0 | `padre-inactivo-al-editar` | `409 CATEGORIA_PADRE_INACTIVA` junto al selector |
| Profundidad excedida | S03 | P0 | `profundidad-excedida` | `422 PROFUNDIDAD_CATEGORIA_EXCEDIDA` |
| Padre inactivo al reactivar | S05-R | P0 | `reactivacion-padre-inactivo` | Bloqueo con acción Reactivar el padre |

## 11. Orden de ejecución

| Fase | Salida | Actor / Revisor | Gate |
|---|---|---|---|
| Preparación | Contexto y fixtures | Responsable | Entradas vigentes |
| Pantalla ancla | S01 refinada | Responsable | Cobertura estructural |
| Alta con slug | S02 y S02-C completas | Responsable | Secuencia de confirmación íntegra |
| Edición y detalle | S03 y S05 completas | Responsable | Reglas de jerarquía cubiertas |
| Baja segura | S04, S04-P y S04-B completas | Responsable | `202` tratado como admisión |
| Bloqueo de reactivación | S05-R completa | Responsable | Precondición de negocio comunicada |
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
| R-01 | Modelar la admisión `202` como baja confirmada | Media | Alto | El seguimiento por `operationId` es requisito de T15 y T16; verificar en autovalidación que ningún copy afirme cambio antes del resultado |
| R-02 | Ocultar en el selector las categorías que no pueden ser padre | Media | Medio | LUX-01 exige mostrarlas deshabilitadas con el motivo |
| R-03 | Silenciar el sufijo aplicado por colisión | Media | Alto | LUX-02 exige URL pública con sufijo resaltado y confirmación explícita |
| R-04 | Inventar un rol o permiso global no publicado | Baja | Alto | El component-spec no declara rol; los estados 401/403 se muestran genéricos |
| R-05 | Añadir edición de slug o SEO a esta interfaz | Media | Medio | §4 del component-spec lo excluye; corresponde a MK-012 |
| R-06 | Rutas de variante inconsistentes con el identificador de pantalla | Media | Alto | Verificación explícita de las nueve rutas en Gate A |
| R-07 | Añadir acción de eliminación física | Baja | Alto | Ausencia de acción en todas las pantallas y verificación en T60 |

## 13. Quality Gates

### Gate A — Funcional
- SPEC-008, HU-008 (14 CA), WF-008 y FLOW-008 cubiertos sin reglas inventadas.
- Las 9 pantallas inventariadas disponen de ruta directa, estable y reproducible (`/MK008/SXX`, incluidas variantes con sufijo).
- Los estados P0 requeridos se reproducen de manera determinista.
- Toda actualización de datos se ejecuta por `PATCH` con el DTO que corresponde al contrato.

### Gate B — UX
- Propuesta UX del módulo aplicada rigurosamente.
- UXD-001, UXD-005, UXD-007, UXD-008, UXD-009 y UXD-011 aplicadas donde corresponda.
- Decisiones locales LUX-01 y LUX-02 justificadas en `component-spec.md`.

### Gate C — UI
- Design System respetado, sin tokens arbitrarios ni estilos inline huérfanos.
- Componentes compartidos reutilizados del catálogo DS.

### Gate D — PC
- Sin overflow horizontal en viewport canónico de 1440 px.
- Jerarquía visual clara y estado nunca comunicado solo por color.
- Teclado, foco y foco atrapado en modales funcionales.

### Gate E — Revisión Transversal y Aprobación para Figma
- **Revisor:** Leonardo Vera Rodríguez.
- Revisión transversal completada.
- Hallazgos bloqueantes e importantes requeridos cerrados.
- Visto bueno formal otorgado.
- Estado de revisión transversal: **APROBADO PARA FIGMA**.

### Gate F — Figma y Cierre
- La versión con visto bueno fue reflejada en Figma.
- Figma coincide fielmente con la versión aprobada.
- Las pantallas P0 requeridas están presentes.
- El enlace de Figma está registrado.

**Regla de cierre:** Con los Gate E y Gate F cumplidos y sin hallazgos bloqueantes ni importantes requeridos abiertos, `validation-report.md` podrá registrar el **Resultado general = APROBADO**.
