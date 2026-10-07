# Plan de Mockup — MK-011

## 1. Identificación

- **Mockup:** MK-011 — Gestión de marcas
- **Funcionalidad:** Taxonomía de marcas del catálogo (alta, edición, baja lógica segura y reactivación de marcas)
- **Responsable:** Leonardo Lopez (rama `lopez`)
- **Versión:** 1.1 — 2026-10-03
- **Estado:** **En revisión** — aprobación documental pendiente. No habilita implementación ni Figma. La pregunta Q-01 (obligatoriedad del logo) permanece abierta y bloquea la construcción del formulario.

## 2. Contrato de ejecución

### Entradas

- `component-spec.md` (resultado esperado, subordinado a las fuentes oficiales).
- UX transversal: [ux-guidelines.md](../ux/ux-guidelines.md), [ux-decisions.md](../ux/ux-decisions.md), [propuesta-ux.md](../ux/propuesta-ux.md).
- Wireframe oficial [WF-011](../../wireframes/flows/WF-011-gestion-marcas.md) v0.5.
- Flujo oficial [FLOW-011](..\..\..\requisitos\flujos\FLOW-011-gestion-marcas.md).
- Design System [DESIGN.md](../DESIGN.md) 1.0.0.
- Contratos: [api/openapi.yaml](..\..\..\contratos\http\openapi.yaml) 0.5.0, [Contrato_Api.md](..\..\..\contratos\http\Contrato_Api.md), [asyncapi/asyncapi.yaml](..\..\..\contratos\eventos\asyncapi.yaml) 0.4.0.

### Salidas esperadas

- Las 8 pantallas P0 de §5 implementadas y operativas.
- Una ruta individual y directa por pantalla: `/MK011/S01`, `/MK011/S02`, `/MK011/S03`, `/MK011/S04`, `/MK011/S04-P`, `/MK011/S04-B`, `/MK011/S04-E`, `/MK011/S05`.
- Código normalizado y modular en `prototipo/src/pantallas/MK011`.
- Estados P0 deterministas: default, loading, empty, error y los negativos de `component-spec.md` §13.
- Autovalidación del owner con evidencias en `validation-report.md` (aún no emitido).

### Restricciones de ejecución

- No modificar SPEC, HU, WF, FLOW, contrato API ni Design System sin corrección documental aprobada.
- No inventar reglas de negocio, campos, acciones ni estados ausentes de `component-spec.md`.
- No redefinir el contenido de pantallas en este plan.
- No crear patrones UX transversales nuevos; toda excepción local se registra como `LUX-01`, `LUX-02` o `LUX-03`.
- No modificar otros MK.
- No introducir dependencias, librerías ni utilidades ad hoc sin aprobación técnica.
- El alta y la edición se envían como multipart; la edición usa `PATCH` con `MarcaUpdateMultipart`.
- La interfaz no muestra nombres de mensajes ni inventa mensajería de creación, edición o estado de marca.
- La interfaz no declara un rol ni nombres de permiso granular como contrato propio.
- La admisión `202` no se representa como baja confirmada.
- Mientras Q-01 no se resuelva, la obligatoriedad del logo no se implementa por decisión unilateral.

### Condiciones de parada / escalamiento

Detener la tarea, marcarla `BLOCKED` y escalar cuando:
- Exista contradicción irreconciliable entre fuentes de verdad (caso vigente: obligatoriedad del logo entre SPEC/HU/WF y OpenAPI).
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
| Component Spec | [component-spec.md](component-spec.md) v1.1 | **En revisión** (aún no aprobado; Q-01 abierta) |
| SPEC/HU | [SPEC-011](..\..\..\requisitos\specs\SPEC-011-gestion-marcas.md), [HU-011](..\..\..\requisitos\hu\HU-011-gestion-marcas.md) | Vigentes |
| WF | [WF-011](../../wireframes/flows/WF-011-gestion-marcas.md) v0.5 | Vigente |
| Flow | [FLOW-011](..\..\..\requisitos\flujos\FLOW-011-gestion-marcas.md) | Vigente |
| Design System | [DESIGN.md](../DESIGN.md) 1.0.0 | Vigente y coherente con el component-spec |

## 4. Objetivo

Construir la administración de marcas con logo y país, su baja lógica segura y su reactivación, de modo que el gestor comercial mantenga la información de marcas que consumen Catálogo y los demás canales sin riesgo de afectar productos activos.

## 5. Pantallas

| ID | Nombre | Prioridad | Ruta | Orden |
|---|---|---|---|---:|
| MK-011-S01 | Listado de marcas | P0 | `/MK011/S01` | 1 |
| MK-011-S02 | Crear marca | P0 | `/MK011/S02` | 2 |
| MK-011-S03 | Editar marca | P0 | `/MK011/S03` | 3 |
| MK-011-S05 | Detalle de marca | P0 | `/MK011/S05` | 4 |
| MK-011-S04 | Confirmar baja | P0 | `/MK011/S04` | 5 |
| MK-011-S04-P | Verificando baja | P0 | `/MK011/S04-P` | 6 |
| MK-011-S04-B | Baja bloqueada | P0 | `/MK011/S04-B` | 7 |
| MK-011-S04-E | Baja no concluyente | P0 | `/MK011/S04-E` | 8 |

El orden es constructivo: el listado fija el patrón de tabla con logo, el alta y la edición comparten el formulario multipart, el detalle consolida la ficha y las tres variantes de baja introducen los resultados bloqueado y no concluyente, que no existen en los demás módulos.

## 6. Pantalla ancla

- **Pantalla:** MK-011-S02 — Crear marca.
- **Motivo:** concentra el patrón más específico del módulo: envío multipart, validación de archivo, previsualización de logo, unicidad normalizada frente a marcas inactivas y país ISO opcional.
- **Qué debe establecer:** patrón del formulario con carga de archivo, tratamiento visual del logo, microtexto de formatos y tamaño, y patrón de errores de validación por campo.

La pantalla ancla no crea una UX independiente; aplica la UX global del módulo.

## 7. Estrategia

1. Resolver Q-01 (obligatoriedad del logo) antes de construir el formulario; es condición de parada.
2. Preparar contexto y fixtures deterministas de `component-spec.md` §13.
3. Implementar y refinar MK-011-S02 conforme al `component-spec.md`.
4. Validar S02 contra SPEC-011, HU-011, WF-011, FLOW-011 y UX transversal.
5. Implementar MK-011-S01 y S03 aplicando los patrones de S02 y de los listados del módulo.
6. Implementar MK-011-S05 como ficha con acción Reactivar.
7. Implementar MK-011-S04 y S04-P, que introducen el patrón de verificación segura de marca.
8. Implementar MK-011-S04-B y S04-E para los resultados bloqueado y no concluyente.
9. Normalizar código, tokens, layout y tipografía, y verificar el acceso directo de las 8 rutas inventariadas.
10. Implementar estados interactivos y accesibilidad con reproducción determinista.
11. Realizar autovalidación por el responsable funcional.
12. Someter a revisión transversal de Leonardo Vera Rodríguez.
13. Corregir hallazgos hasta obtener visto bueno.
14. Registrar el visto bueno y el estado APROBADO PARA FIGMA en `validation-report.md`.
15. Reflejar fielmente la versión con visto bueno en Figma.
16. Validar la fidelidad entre Figma y la versión aprobada.
17. Registrar el resultado general APROBADO cuando todos los gates estén cerrados.

## 8. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| DS-C01 Button / DS-C02 ActionIcon | Design System / shared | S01–S05 | Reutilizar sin variantes nuevas |
| DS-C03 TextInput / DS-C05 Textarea | Design System / shared | S01, S02, S03, S05 | Reutilizar |
| DS-C12 Search | Design System / shared | S01 | Reutilizar |
| DS-C14 Badge | Design System / shared | S01, S05 | Reutilizar para estado |
| DS-C17 Table | Design System / shared | S01 | Reutilizar con columna de logo |
| DS-C19 Card | Design System / shared | S01, S02, S03, S05 | Reutilizar |
| DS-C21 Modal | Design System / shared | S04, S04-B, S04-E | Reutilizar a 480 px |
| DS-C22 Alert | Design System / shared | S02, S03, S04-P, S04-B, S04-E | Reutilizar para errores y resultado |
| DS-C24 Skeleton / DS-C25 EmptyState | Design System / shared | S01, S05, S04-P | Reutilizar |
| MK-011-C01 Listado de marcas | Component spec §9 | S01 | Construir específico |
| MK-011-C02 Formulario con logo | Component spec §9 | S02, S03 | Construir específico |
| MK-011-C03 Seguimiento de verificación | Component spec §9 | S04-P, S04-B, S04-E | Construir específico; reutilizable en otros MK con verificación asíncrona |

## 9. Normalización

La implementación final debe alinearse a React, TypeScript, Mantine, tema central del módulo, Tabler Icons, Design System, UX Guidelines, accesibilidad (teclado, foco y contraste) y PC/desktop únicamente. Se verifican de forma explícita las ocho rutas inventariadas, incluidas las variantes con sufijo `/MK011/S04-P`, `/MK011/S04-B` y `/MK011/S04-E`.

## 10. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---|---|---|
| Default | S01 | P0 | `listado-marcas` | Listado con logo, nombre, país y estado |
| Loading | S01 | P0 | `loading` | Skeleton de filas |
| Empty | S01 | P0 | `empty` | EmptyState con acción Crear marca |
| Sin resultados | S01 | P0 | `sin-resultados` | EmptyState con acción Limpiar filtro |
| Error | S01, S03 | P0 | `error` | Mensaje accionable con reintento |
| Sesión y permisos | Todas | P0 | `sesion`, `sin-permisos` | Estados `401` y `403` sin datos inventados |
| Alta mínima | S02 | P0 | `crear-minimo` | Solo nombre requerido |
| Alta completa | S02 | P0 | `crear-con-logo` | Logo con previsualización y país ISO |
| Formato inválido | S02 | P0 | `logo-formato-invalido` | Error junto al selector de archivo |
| Tamaño excedido | S02 | P0 | `logo-excede-limite` | Error con el límite de 5 MB |
| Nombre duplicado | S02 | P0 | `nombre-duplicado` | `409 MARCA_DUPLICADA` |
| País no precargado | S02, S03 | P0 | `pais-no-precargado` | Selector vacío sin valor por defecto |
| País inválido | S02 | P0 | `pais-invalido` | `422 PAIS_INVALIDO` |
| Duplicado frente a inactiva | S03 | P0 | `nombre-duplicado-inactiva` | Rechazo también frente a marcas inactivas |
| Edición completa | S03 | P0 | `editar-marca` | Cambios de nombre, descripción, logo y país |
| Verificación pendiente | S04-P | P0 | `baja-pendiente` | Marca activa con indicador de verificación |
| Verificación confirmada | S04-P | P0 | `baja-confirmada` | Marca inactiva tras `CLEAR` |
| Baja bloqueada | S04-B | P0 | `baja-bloqueada` | Motivo de productos activos |
| Rechazo de verificación | S04-B | P0 | `baja-rechazada` | Rechazo sin cambio de estado |
| Baja no concluyente | S04-E | P0 | `baja-no-concluyente` | Aviso de que no se realizó ningún cambio |
| Reactivación correcta | S05 | P0 | `reactivacion-ok` | Mismo identificador y mismo nombre |

## 11. Orden de ejecución

| Fase | Salida | Actor / Revisor | Gate |
|---|---|---|---|
| Resolución de bloqueo | Q-01 cerrada documentalmente | Leonardo Lopez con Seguridad y Taxonomía | Fuente authoritative del logo |
| Preparación | Contexto y fixtures | Responsable | Entradas vigentes |
| Pantalla ancla | S02 refinada | Responsable | Cobertura estructural |
| Listado y edición | S01 y S03 completas | Responsable | Patrones de tabla y multipart aplicados |
| Detalle | S05 completa | Responsable | Reactivación disponible |
| Baja segura | S04 y S04-P completas | Responsable | `202` tratado como admisión |
| Resultados de baja | S04-B y S04-E completas | Responsable | Bloqueo y no concluyente diferenciados |
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
| R-01 | Resolver unilateralmente la obligatoriedad del logo | Media | Alto | Q-01 es condición de parada; el bloqueo queda registrado en `tasks.md` §9 |
| R-02 | Tratar la admisión `202` como baja confirmada | Media | Alto | LUX-03 mantiene la marca activa y T17/T18 exigen seguimiento por `operationId` |
| R-03 | Precargar un país por defecto | Media | Medio | LUX-02 y verificación en T14 y T15 |
| R-04 | Inventar mensajería de creación, edición o estado de marca | Media | Alto | Prohibido por WF-011 §5 y HU-011 CA-15 y CA-16; verificado en T60 |
| R-05 | Declarar un rol o permiso granular como contrato | Media | Alto | Prohibido por HU-011 CA-14; verificado en T60 |
| R-06 | Enviar la edición como JSON en lugar de multipart | Media | Alto | T15 exige `PATCH` multipart con `MarcaUpdateMultipart` |
| R-07 | Mostrar un error visual cuando la marca no tiene logo | Baja | Medio | A-03 define un marcador neutro; verificado en T13 |
| R-08 | Rutas de variante inconsistentes con el identificador de pantalla | Media | Alto | Verificación explícita de las ocho rutas en Gate A |

## 13. Quality Gates

### Gate A — Funcional
- SPEC-011, HU-011 (16 CA), WF-011 v0.5 y FLOW-011 cubiertos sin reglas inventadas.
- Las 8 pantallas inventariadas disponen de ruta directa, estable y reproducible (`/MK011/SXX`, incluidas variantes con sufijo).
- Los estados P0 requeridos se reproducen de manera determinista.
- El alta y la edición se envían como multipart y la edición usa `PATCH`.

### Gate B — UX
- Propuesta UX del módulo aplicada rigurosamente.
- UXD-007, UXD-010, UXD-011, UXD-017 y UXD-019 aplicadas donde corresponda.
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
