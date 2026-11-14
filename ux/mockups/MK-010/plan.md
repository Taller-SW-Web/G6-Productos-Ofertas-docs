# Plan de Mockup — MK-010

## 1. Identificación

- **Mockup:** MK-010 — Asociación de características a tipos de producto
- **Funcionalidad:** Taxonomía de esquemas de producto (tipos de producto y sus características asociadas con condición de obligatoriedad)
- **Responsable:** Leonardo Lopez (rama `lopez`)
- **Versión:** 1.1 — 2026-10-03
- **Estado:** **En revisión** — aprobación documental pendiente. No habilita implementación ni Figma.

## 2. Contrato de ejecución

### Entradas

- `component-spec.md` (resultado esperado, subordinado a las fuentes oficiales).
- UX transversal: [ux-guidelines.md](../ux/ux-guidelines.md), [ux-decisions.md](../ux/ux-decisions.md), [propuesta-ux.md](../ux/propuesta-ux.md).
- Wireframe oficial [WF-010](../../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md).
- Flujo oficial [FLOW-010](..\..\..\requisitos\flujos\FLOW-010-asociacion-tipo-producto-caracteristica.md) (flujos A–G).
- Design System [DESIGN.md](../DESIGN.md) 1.0.0.
- Contratos: [api/openapi.yaml](..\..\..\contratos\http\openapi.yaml) 0.5.0, [Contrato_Api.md](..\..\..\contratos\http\Contrato_Api.md), [asyncapi.yaml](..\..\..\contratos\eventos\asyncapi.yaml) 0.4.0.

### Salidas esperadas

- Las 9 pantallas P0 de §5 implementadas y operativas.
- Una ruta individual y directa por pantalla: `/MK010/S01`, `/MK010/S01-E`, `/MK010/S01-N`, `/MK010/S02`, `/MK010/S02-P`, `/MK010/S02-R`, `/MK010/S03`, `/MK010/S04`, `/MK010/S05`.
- Código normalizado y modular en `prototipo/src/pantallas/MK010`.
- Estados P0 deterministas: default, loading, empty, error y los negativos de `component-spec.md` §13.
- Autovalidación del owner con evidencias en `validation-report.md` (aún no emitido).

### Restricciones de ejecución

- No modificar SPEC, HU, WF, FLOW, contrato API ni Design System sin corrección documental aprobada.
- No inventar reglas de negocio, campos, acciones ni estados ausentes de `component-spec.md`.
- No redefinir el contenido de pantallas en este plan.
- No crear patrones UX transversales nuevos; toda excepción local se registra como `LUX-01`, `LUX-02` o `LUX-03`.
- No modificar otros MK.
- No introducir dependencias, librerías ni utilidades ad hoc sin aprobación técnica.
- El límite de características se presenta con el valor inicial del MVP (20) y como configurable; no se fija un valor distinto sin respaldo documental.
- El cambio de condición se ejecuta por `PATCH`; no se modelan rutas `PUT`.
- La admisión `202` no se representa como baja confirmada y la fila afectada se retiene durante la verificación.
- No se expone `tipo_producto_id` como columna necesaria ni se ofrece acción de reordenar.
- Los nombres técnicos de eventos y tópicos no se muestran en la interfaz.

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
| SPEC/HU | [SPEC-010](..\..\..\requisitos\specs\SPEC-010-asociacion-tipo-producto-caracteristica.md), [HU-010](..\..\..\requisitos\hu\HU-010-asociacion-tipo-producto-caracteristica.md) | Vigentes |
| WF | [WF-010](../../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md) | Vigente |
| Flow | [FLOW-010](..\..\..\requisitos\flujos\FLOW-010-asociacion-tipo-producto-caracteristica.md) | Vigente |
| Design System | [DESIGN.md](../DESIGN.md) 1.0.0 | Vigente y coherente con el component-spec |

## 4. Objetivo

Construir la definición de esquemas por tipo de producto —alta de tipo, asociación de características con condición, cambio de condición, desasociación segura y desactivación segura con reactivación— de modo que Catálogo y los demás canales dispongan de un esquema versionado, coherente y verificable.

## 5. Pantallas

| ID | Nombre | Prioridad | Ruta | Orden |
|---|---|---|---|---:|
| MK-010-S01 | Tipos de producto | P0 | `/MK010/S01` | 1 |
| MK-010-S01-E | Listado vacío o con error | P0 | `/MK010/S01-E` | 2 |
| MK-010-S01-N | Crear tipo de producto | P0 | `/MK010/S01-N` | 3 |
| MK-010-S02 | Esquema del tipo | P0 | `/MK010/S02` | 4 |
| MK-010-S03 | Asociar característica | P0 | `/MK010/S03` | 5 |
| MK-010-S04 | Confirmar desasociación | P0 | `/MK010/S04` | 6 |
| MK-010-S05 | Confirmar desactivación de tipo | P0 | `/MK010/S05` | 7 |
| MK-010-S02-P | Operación en verificación | P0 | `/MK010/S02-P` | 8 |
| MK-010-S02-R | Operación rechazada | P0 | `/MK010/S02-R` | 9 |

El orden es constructivo: el listado y su estado vacío fijan los patrones de tabla y recuperación, el alta es ligera y conduce al esquema, el esquema introduce el switch de condición y el contador de límite, y las dos confirmaciones de baja comparten un único patrón asíncrono de verificación.

## 6. Pantalla ancla

- **Pantalla:** MK-010-S02 — Esquema del tipo.
- **Motivo:** concentra el patrón más exigente del módulo: tabla con control por fila, contador de límite, indicador de versión, retención de fila durante la verificación y dos acciones de salida (asociar y desasociar).
- **Qué debe establecer:** jerarquía de la cabecera del esquema, patrón de la tabla de asociaciones, tratamiento visual del límite y de la versión, y patrón de estados asíncronos.

La pantalla ancla no crea una UX independiente; aplica la UX global del módulo.

## 7. Estrategia

1. Preparar contexto y fixtures deterministas de `component-spec.md` §13.
2. Implementar y refinar MK-010-S02 conforme al `component-spec.md`.
3. Validar S02 contra SPEC-010, HU-010, WF-010, FLOW-010 y UX transversal.
4. Implementar MK-010-S01, S01-E y S01-N aplicando los patrones de S02 y de los listados del módulo.
5. Implementar MK-010-S03 reutilizando el patrón de diálogo de selección.
6. Implementar MK-010-S04 y S05, que comparten estructura y copy con verificación segura.
7. Implementar MK-010-S02-P y S02-R con el patrón de seguimiento por `operationId`.
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
| DS-C01 Button / DS-C02 ActionIcon | Design System / shared | S01–S05 | Reutilizar sin variantes nuevas |
| DS-C03 TextInput / DS-C06 Select | Design System / shared | S01, S01-N, S03 | Reutilizar |
| DS-C10 Switch | Design System / shared | S02, S03 | Reutilizar para la condición de obligatoriedad |
| DS-C14 Badge | Design System / shared | S01, S01-E, S02 | Reutilizar para estado y versión |
| DS-C17 Table | Design System / shared | S01, S02 | Reutilizar |
| DS-C19 Card | Design System / shared | S01, S01-N, S02 | Reutilizar |
| DS-C21 Modal | Design System / shared | S02-R, S03, S04, S05 | Reutilizar a 480 px |
| DS-C22 Alert | Design System / shared | S01-E, S02, S02-P, S02-R, S03, S04, S05 | Reutilizar para límite, errores y resultado |
| DS-C24 Skeleton / DS-C25 EmptyState | Design System / shared | S01-E, S02, S02-P | Reutilizar |
| MK-010-C01 Tabla de esquema | Component spec §9 | S02 | Construir específico |
| MK-010-C02 Selector de características | Component spec §9 | S03 | Construir específico |
| MK-010-C03 Aviso de versión de esquema | Component spec §9 | S02 | Construir específico |
| MK-010-C04 Seguimiento de verificación segura | Component spec §9 | S02-P, S02-R | Construir específico; reutilizable en otros MK con verificación asíncrona |

## 9. Normalización

La implementación final debe alinearse a React, TypeScript, Mantine, tema central del módulo, Tabler Icons, Design System, UX Guidelines, accesibilidad (teclado, foco y contraste) y PC/desktop únicamente. Se verifican de forma explícita las nueve rutas inventariadas, incluidas las variantes con sufijo `/MK010/S01-E`, `/MK010/S01-N`, `/MK010/S02-P` y `/MK010/S02-R`.

## 10. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---|---|---|
| Default | S01 | P0 | `default` | Listado con estado, conteo y versión |
| Loading | S01 | P0 | `loading` | Skeleton de filas |
| Vacío | S01-E | P0 | `empty` | EmptyState con acción Crear tipo |
| Sin resultados | S01-E | P0 | `sin-resultados` | EmptyState con acción Limpiar filtro |
| Error | S01-E | P0 | `error` | Mensaje accionable con reintento |
| Sesión y permisos | Todas | P0 | `sesion`, `sin-permisos` | Estados `401` y `403` sin datos inventados |
| Esquema vacío | S02 | P0 | `esquema-vacio` | EmptyState con acción Asociar característica |
| Esquema completo | S02 | P0 | `esquema-completo` | Tabla con condición, metadatos y versión |
| Límite alcanzado | S02, S03 | P0 | `limite-20` | Contador en límite con 20 asociaciones y guardado bloqueado |
| Asociación inválida | S03 | P0 | `asociar-invalida` | `409 CARACTERISTICA_INACTIVA` junto al selector |
| Asociación duplicada | S03 | P0 | `asociacion-duplicada` | `409 ASOCIACION_DUPLICADA`; la candidata no se ofrece |
| Obligatoriedad aplicada | S02 | P0 | `obligatoria-aplicada` | Condición Obligatoria y aviso de exigencia futura |
| Versión incrementada | S02 | P0 | `schema-version-incrementada` | Indicador de versión actualizado y propagación comunicada |
| Verificación pendiente | S02-P | P0 | `desasociacion-pendiente` | Banner «Verificando uso…» con fila retenida |
| Verificación confirmada | S02-P | P0 | `desasociacion-confirmada` | Fila retirada y versión incrementada |
| Verificación rechazada | S02-R | P0 | `desasociacion-rechazada` | Asociación conservada y motivo explicado |
| Verificación no concluyente | S02-P | P0 | `verificacion-no-concluyente` | Aviso de que no se realizó ninguna modificación |
| Baja del tipo en curso | S02-P | P0 | `desactivacion-pendiente` | Verificación del tipo en curso |
| Tipo inactivo | S02 | P0 | `tipo-inactivo` | Sin asociación; acción Reactivar tipo |
| Reactivación correcta | S02 | P0 | `reactivacion-ok` | Misma identidad y esquema disponible |

## 11. Orden de ejecución

| Fase | Salida | Actor / Revisor | Gate |
|---|---|---|---|
| Preparación | Contexto y fixtures | Responsable | Entradas vigentes |
| Pantalla ancla | S02 refinada | Responsable | Cobertura estructural |
| Listado y recuperación | S01, S01-E y S01-N completas | Responsable | Patrones de tabla y vacío aplicados |
| Asociación | S03 completa | Responsable | Límite y candidatas válidas cubiertos |
| Bajas seguras | S04 y S05 completas | Responsable | `202` tratado como admisión |
| Seguimiento asíncrono | S02-P y S02-R completas | Responsable | Fallo cerrado en todos los casos |
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
| R-01 | Tratar la admisión `202` como desasociación o desactivación completada | Media | Alto | LUX-03 y T17/T19 exigen retención de la fila y seguimiento por `operationId` |
| R-02 | Retirar la fila del esquema al admitir la solicitud | Media | Alto | Verificar que la fila permanece con estado de verificación hasta el resultado final |
| R-03 | Fijar el límite de características en un valor distinto del inicial del MVP | Media | Alto | T15/T16 usan el valor inicial 20 y lo declaran configurable; Q-01 queda abierta |
| R-04 | Usar `PUT` para el cambio de condición | Media | Alto | El contrato define `PATCH`; la verificación de T15 lo comprueba |
| R-05 | Mostrar `tipo_producto_id` como columna del listado | Media | Medio | Prohibido por WF-010 §9; verificado en T60 |
| R-06 | Añadir una acción de reordenar características | Media | Medio | Prohibido por WF-010 §10; verificado en T60 |
| R-07 | Exponer nombres de eventos o tópicos en la interfaz | Media | Medio | T22 y T60 verifican que solo se muestran estados operativos |
| R-08 | Afirmar que la obligatory desactiva productos existentes | Media | Alto | El aviso de S02 declara que se exige al volver a guardar o activar |
| R-09 | Modelar la migración de `tipo_producto_id` dentro de este MK | Baja | Alto | §4 la excluye; T60 verifica que no exista acción de migración |

## 13. Quality Gates

### Gate A — Funcional
- SPEC-010, HU-010 (17 CA), WF-010 y FLOW-010 cubiertos sin reglas inventadas.
- Las 9 pantallas inventariadas disponen de ruta directa, estable y reproducible (`/MK010/SXX`, incluidas variantes con sufijo).
- Los estados P0 requeridos se reproducen de manera determinista.
- Toda actualización se ejecuta por el método del contrato, incluido `PATCH` para el cambio de condición.

### Gate B — UX
- Propuesta UX del módulo aplicada rigurosamente.
- UXD-003, UXD-005, UXD-009, UXD-014 y UXD-016 aplicadas donde corresponda.
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
