# Plan de Mockup — MK-009

## 1. Identificación

- **Mockup:** MK-009 — Gestión de características de producto
- **Funcionalidad:** Taxonomía de atributos del catálogo (características TEXTO, NUMERO y LISTA con sus valores permitidos)
- **Responsable:** Leonardo Lopez (rama `lopez`)
- **Versión:** 1.1 — 2026-10-03
- **Estado:** **En revisión** — aprobación documental pendiente. No habilita implementación ni Figma.

## 2. Contrato de ejecución

### Entradas

- `component-spec.md` (resultado esperado, subordinado a las fuentes oficiales).
- UX transversal: [ux-guidelines.md](../ux/ux-guidelines.md), [ux-decisions.md](../ux/ux-decisions.md), [propuesta-ux.md](../ux/propuesta-ux.md).
- Wireframe oficial [WF-009](../../wireframes/flows/WF-009-gestion-caracteristicas.md).
- Flujo oficial [FLOW-009](..\..\..\requisitos\flujos\FLOW-009-gestion-caracteristicas.md).
- Design System [DESIGN.md](../DESIGN.md) 1.0.0.
- Contratos: [api/openapi.yaml](..\..\..\contratos\http\openapi.yaml) 0.5.0, [Contrato_Api.md](..\..\..\contratos\http\Contrato_Api.md), [asyncapi.yaml](..\..\..\contratos\eventos\asyncapi.yaml) 0.4.0.

### Salidas esperadas

- Las 8 pantallas P0 de §5 implementadas y operativas.
- Una ruta individual y directa por pantalla: `/MK009/S01`, `/MK009/S02`, `/MK009/S03`, `/MK009/S04`, `/MK009/S04-P`, `/MK009/S04-R`, `/MK009/S05`, `/MK009/S06`.
- Código normalizado y modular en `prototipo/src/pantallas/MK009`.
- Estados P0 deterministas: default, loading, empty, error y los negativos de `component-spec.md` §13.
- Autovalidación del owner con evidencias en `validation-report.md` (aún no emitido).

### Restricciones de ejecución

- No modificar SPEC, HU, WF, FLOW, contrato API ni Design System sin corrección documental aprobada.
- No inventar reglas de negocio, campos, acciones ni estados ausentes de `component-spec.md`.
- No redefinir el contenido de pantallas en este plan.
- No crear patrones UX transversales nuevos; toda excepción local se registra como `LUX-01`, `LUX-02` o `LUX-03`.
- No modificar otros MK.
- No introducir dependencias, librerías ni utilidades ad hoc sin aprobación técnica.
- El tipo de la característica es inmutable; ningún formulario puede ofrecer su cambio.
- Toda actualización de datos se ejecuta por `PATCH`; no se modelan rutas `PUT`.
- La admisión `202` no se representa como baja confirmada.

### Condiciones de parada / escalamiento

Detener la tarea, marcarla `BLOCKED` y escalar cuando:
- Exista contradicción irreconciliable entre SPEC, HU, WF, FLOW y contrato API.
- Falte información necesaria para una decisión funcional crítica.
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
| SPEC/HU | [SPEC-009](..\..\..\requisitos\specs\SPEC-009-gestion-caracteristicas.md), [HU-009](..\..\..\requisitos\hu\HU-009-gestion-caracteristicas.md) | Vigentes |
| WF | [WF-009](../../wireframes/flows/WF-009-gestion-caracteristicas.md) | Vigente |
| Flow | [FLOW-009](..\..\..\requisitos\flujos\FLOW-009-gestion-caracteristicas.md) | Vigente |
| Design System | [DESIGN.md](../DESIGN.md) 1.0.0 | Vigente y coherente con el component-spec |

## 4. Objetivo

Construir la administración de características de producto y sus valores permitidos, con tipo inmutable, límites visibles y baja segura de valores LISTA, de modo que el gestor comercial pueda mantener los atributos del catálogo sin perder la trazabilidad de los datos ya publicados.

## 5. Pantallas

| ID | Nombre | Prioridad | Ruta | Orden |
|---|---|---|---|---:|
| MK-009-S01 | Listado de características | P0 | `/MK009/S01` | 1 |
| MK-009-S02 | Crear característica | P0 | `/MK009/S02` | 2 |
| MK-009-S03 | Editar característica | P0 | `/MK009/S03` | 3 |
| MK-009-S06 | Detalle de característica | P0 | `/MK009/S06` | 4 |
| MK-009-S04 | Valores permitidos (LISTA) | P0 | `/MK009/S04` | 5 |
| MK-009-S04-P | Comprobando uso | P0 | `/MK009/S04-P` | 6 |
| MK-009-S04-R | Baja de valor rechazada | P0 | `/MK009/S04-R` | 7 |
| MK-009-S05 | Estado de la característica | P0 | `/MK009/S05` | 8 |

El orden es constructivo: el listado fija el patrón de tabla con badges de tipo y estado, la alta establece el revelado condicional de la unidad, el detalle consolida los identificadores estables y la gestión de valores LISTA introduce el patrón asíncrono de verificación de uso.

## 6. Pantalla ancla

- **Pantalla:** MK-009-S01 — Listado de características.
- **Motivo:** es la pantalla que melhor fija el lenguaje del módulo: jerarquía de información, densidad de tabla, badges de tipo y estado, patrón de filtro y microtexto de vacíos.
- **Qué debe establecer:** jerarquía visual del módulo, tratamiento del dato de solo lectura, patrón de acciones por fila y densidad de tabla coherente con el resto de mockups.

La pantalla ancla no crea una UX independiente; aplica la UX global del módulo.

## 7. Estrategia

1. Preparar contexto y fixtures deterministas de `component-spec.md` §13.
2. Implementar y refinar MK-009-S01 conforme al `component-spec.md`.
3. Validar S01 contra SPEC-009, HU-009, WF-009, FLOW-009 y UX transversal.
4. Implementar MK-009-S02 y S03 aplicando el patrón de revelado condicional y la inmutabilidad del tipo.
5. Implementar MK-009-S06 con los identificadores estables y el acceso a las demás acciones.
6. Implementar MK-009-S04, S04-P y S04-R, que introducen la administración de valores y el patrón de verificación asíncrona.
7. Implementar MK-009-S05 como estado de la característica completa, con la aclaración de que el identificador se conserva.
8. Normalizar código, tokens, layout y tipografía, y verificar el acceso directo de las 8 rutas inventariadas.
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
| DS-C01 Button / DS-C02 ActionIcon | Design System / shared | S01–S06 | Reutilizar sin variantes nuevas |
| DS-C03 TextInput / DS-C05 Textarea / DS-C06 Select | Design System / shared | S01–S04, S06 | Reutilizar |
| DS-C12 Search | Design System / shared | S01 | Reutilizar |
| DS-C14 Badge | Design System / shared | S01, S04, S05, S06 | Reutilizar para estado y tipo |
| DS-C17 Table | Design System / shared | S01, S04 | Reutilizar |
| DS-C19 Card | Design System / shared | S01, S02, S03, S06 | Reutilizar |
| DS-C21 Modal | Design System / shared | S03, S04, S04-R, S05 | Reutilizar a 480 px |
| DS-C22 Alert | Design System / shared | S02–S05 | Reutilizar para errores y límites |
| DS-C24 Skeleton / DS-C25 EmptyState | Design System / shared | S01, S04, S06 | Reutilizar |
| MK-009-C01 Listado por tipo | Component spec §9 | S01 | Construir específico |
| MK-009-C02 Selector de tipo y unidad | Component spec §9 | S02, S03 | Construir específico |
| MK-009-C03 Gestión de valores permitidos | Component spec §9 | S04 | Construir específico |
| MK-009-C04 Seguimiento de comprobación de uso | Component spec §9 | S04-P, S04-R | Construir específico; reutilizable en otros MK con verificación asíncrona |

## 9. Normalización

La implementación final debe alinearse a React, TypeScript, Mantine, tema central del módulo, Tabler Icons, Design System, UX Guidelines, accesibilidad (teclado, foco y contraste) y PC/desktop únicamente. Se verifican de forma explícita las ocho rutas inventariadas, incluidas las variantes con sufijo `/MK009/S04-P` y `/MK009/S04-R`.

## 10. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---|---|---|
| Default | S01 | P0 | `default` | Listado con los tres tipos y sus estados |
| Loading | S01 | P0 | `loading` | Skeleton de filas sin acciones habilitadas |
| Empty | S01 | P0 | `empty` | EmptyState con acción Crear característica |
| Sin resultados | S01 | P0 | `sin-resultados` | EmptyState con acción Limpiar filtro |
| Error | S01, S03 | P0 | `error` | Mensaje accionable con reintento |
| Sesión y permisos | Todas | P0 | `sesion` | Estados `401` y `403` sin datos inventados |
| Límite TEXTO excedido | S02 | P0 | `texto-excedido` | Error de límite junto al campo |
| NUMERO sin unidad | S02 | P0 | `numero-sin-unidad` | Error de unidad obligatoria |
| Formato numérico inválido | S02 | P0 | `numero-formato` | Error de formato |
| Límite de valores alcanzado | S04 | P0 | `lista-limite` | Contador en límite y alta deshabilitada |
| Tipo inmutable | S03 | P0 | `tipo-inmutable` | Tipo deshabilitado con aviso |
| Renombrado confirmado | S04 | P0 | `valor-renombrado` | Etiqueta actualizada con mismo identificador |
| Comprobación pendiente | S04-P | P0 | `valor-baja-pendiente` | Banner pendiente con identificador de operación |
| Comprobación confirmada | S04-P | P0 | `valor-baja-confirmada` | Resultado `CLEAR` y valor inactivo |
| Comprobación rechazada | S04-R | P0 | `valor-baja-rechazada` | Motivo de uso activo y valor intacto |
| Comprobación no concluyente | S04-P | P0 | `valor-baja-no-concluyente` | Aviso genérico sin afirmar cambio |
| Característica inactiva | S05, S06 | P0 | `caracteristica-inactiva` | Sin nuevas asociaciones ni capturas de valor |
| Reactivación correcta | S05 | P0 | `reactivacion-ok` | Misma identidad, tipo y valores |

## 11. Orden de ejecución

| Fase | Salida | Actor / Revisor | Gate |
|---|---|---|---|
| Preparación | Contexto y fixtures | Responsable | Entradas vigentes |
| Pantalla ancla | S01 refinada | Responsable | Cobertura estructural |
| Alta y edición | S02 y S03 completas | Responsable | Inmutabilidad del tipo y límites cubiertos |
| Detalle | S06 completa | Responsable | Identificadores estables visibles |
| Valores LISTA | S04 completa | Responsable | Límite de activos y renombrado por ID |
| Baja segura de valor | S04-P y S04-R completas | Responsable | `202` tratado como admisión |
| Estado de la característica | S05 completa | Responsable | Identificador conservado y bloqueo de nuevas asociaciones |
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
| R-01 | Ofrecer el cambio de tipo en la edición | Media | Alto | LUX-01 y verificación en T15; el tipo se muestra deshabilitado con aviso |
| R-02 | Modelar la admisión `202` como baja confirmada de un valor | Media | Alto | T17 exige seguimiento por `operationId`; verificar que ningún copy afirme cambio antes del resultado |
| R-03 | Ocultar el límite de 50 valores activos hasta el rechazo | Media | Medio | LUX-02 exige contador visible y alta deshabilitada en el límite |
| R-04 | Introducir asociación a tipos de producto dentro de este MK | Media | Alto | §4 lo excluye y lo delega a MK-010; verificación en T60 |
| R-05 | Renombrar un valor regenerando su identificador | Baja | Alto | T16 exige preservar el identificador y verificar la propagación del evento |
| R-06 | Afirmar que una característica inactiva no altera datos históricos sin cobertura visible | Baja | Medio | S05 muestra la restricción de nuevas asociaciones y T60 verifica que no se ofrece en otros flujos |
| R-07 | Rutas de variante inconsistentes con el identificador de pantalla | Media | Alto | Verificación explícita de las ocho rutas en Gate A |

## 13. Quality Gates

### Gate A — Funcional
- SPEC-009, HU-009 (12 CA), WF-009 y FLOW-009 cubiertos sin reglas inventadas.
- Las 8 pantallas inventariadas disponen de ruta directa, estable y reproducible (`/MK009/SXX`, incluidas variantes con sufijo).
- Los estados P0 requeridos se reproducen de manera determinista.
- Toda actualización de datos se ejecuta por `PATCH` con el DTO que corresponde al contrato.

### Gate B — UX
- Propuesta UX del módulo aplicada rigurosamente.
- UXD-002, UXD-004, UXD-006, UXD-009, UXD-012 y UXD-013 aplicadas donde corresponda.
- Decisiones locales LUX-01, LUX-02 y LUX-03 justificadas en `component-spec.md`.

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
