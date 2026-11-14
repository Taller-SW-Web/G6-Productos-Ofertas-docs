# Plan de Mockup — MK-012

## 1. Identificación

- **Mockup:** MK-012 — SEO y metadatos de categorías
- **Funcionalidad:** Taxonomía de metadatos (slug, metatítulos y metadescripciones por categoría, con historial de cambios)
- **Responsable:** Leonardo Lopez (rama `lopez`)
- **Versión:** 1.1 — 2026-10-03
- **Estado:** **En revisión** — aprobación documental pendiente. No habilita implementación ni Figma.

## 2. Contrato de ejecución

### Entradas

- `component-spec.md` (resultado esperado, subordinado a las fuentes oficiales).
- UX transversal: [ux-guidelines.md](../ux/ux-guidelines.md), [ux-decisions.md](../ux/ux-decisions.md), [propuesta-ux.md](../ux/propuesta-ux.md).
- Wireframe oficial [WF-012](../../wireframes/flows/WF-012-seo-metadatos.md) v0.5.
- Flujo oficial [FLOW-012](..\..\..\requisitos\flujos\FLOW-012-seo-metadatos.md).
- Design System [DESIGN.md](../DESIGN.md) 1.0.0.
- Contratos: [api/openapi.yaml](..\..\..\contratos\http\openapi.yaml) 0.5.0, [Contrato_Api.md](..\..\..\contratos\http\Contrato_Api.md).

### Salidas esperadas

- Las 3 pantallas P0 de §5 implementadas y operativas.
- Una ruta individual y directa por pantalla: `/MK012/S01`, `/MK012/S02`, `/MK012/S03`.
- Código normalizado y modular en `prototipo/src/pantallas/MK012`.
- Estados P0 deterministas: default, loading, empty, error y los negativos de `component-spec.md` §13.
- Autovalidación del owner con evidencias en `validation-report.md` (aún no emitido).

### Restricciones de ejecución

- No modificar SPEC, HU, WF, FLOW, contrato API ni Design System sin corrección documental aprobada.
- No inventar reglas de negocio, campos, acciones ni estados ausentes de `component-spec.md`.
- No redefinir el contenido de pantallas en este plan.
- No crear patrones UX transversales nuevos; toda excepción local se registra como `LUX-01`, `LUX-02` o `LUX-03`.
- No modificar otros MK.
- No introducir dependencias, librerías ni utilidades ad hoc sin aprobación técnica.
- Esta interfaz no crea categorías ni persiste slugs: solo resuelve propuestas y edita metadatos por `PATCH /api/v1/categorias/{categoriaId}/seo`.
- No se implementa un simulador de endpoint público de backoffice.
- La vista previa se declara como aproximación y no como réplica del resultado de un buscador.
- Las advertencias de longitud no bloquean el guardado.

### Condiciones de parada / escalamiento

Detener la tarea, marcarla `BLOCKED` y escalar cuando:
- Exista contradicción irreconciliable entre fuentes de verdad.
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
| SPEC/HU | [SPEC-012](..\..\..\requisitos\specs\SPEC-012-seo-metadatos.md), [HU-012](..\..\..\requisitos\hu\HU-012-seo-metadatos.md) | Vigentes |
| WF | [WF-012](../../wireframes/flows/WF-012-seo-metadatos.md) v0.5 | Vigente |
| Flow | [FLOW-012](..\..\..\requisitos\flujos\FLOW-012-seo-metadatos.md) | Vigente |
| Design System | [DESIGN.md](../DESIGN.md) 1.0.0 | Vigente y coherente con el component-spec |

## 4. Objetivo

Construir la edición de metadatos de las categorías —resolución de slug con colisión visible, metatítulo, metadescripción y historial de cambios— de modo que el gestor comercial mantenga las URLs públicas del Marketplace con trazabilidad y sin asumir responsabilidades de otros módulos.

## 5. Pantallas

| ID | Nombre | Prioridad | Ruta | Orden |
|---|---|---|---|---:|
| MK-012-S01 | SEO por categoría | P0 | `/MK012/S01` | 1 |
| MK-012-S02 | Configurar o editar metadatos | P0 | `/MK012/S02` | 2 |
| MK-012-S03 | Historial de slugs | P0 | `/MK012/S03` | 3 |

El orden es constructivo y coincide con el recorrido real del módulo. No hay pantallas de variante con sufijo: la resolución administrativa de slug se consume desde MK-008 según WF-012 §8 y no se representa aquí como pantalla adicional.

## 6. Pantalla ancla

- **Pantalla:** MK-012-S02 — Configurar o editar metadatos.
- **Motivo:** concentra el patrón más específico del módulo: propuesta de slug con colisión visible, contadores no bloqueantes junto al campo, vista previa declarada como aproximación y recuperación ante conflicto de disponibilidad.
- **Qué debe establecer:** patrón de cards del formulario, tratamiento del slug como dato derivado, microtexto de advertencias y de la frontera con Categorías.

La pantalla ancla no crea una UX independiente; aplica la UX global del módulo.

## 7. Estrategia

1. Preparar contexto y fixtures deterministas de `component-spec.md` §13.
2. Implementar y refinar MK-012-S02 conforme al `component-spec.md`.
3. Validar S02 contra SPEC-012, HU-012, WF-012, FLOW-012 y UX transversal.
4. Implementar MK-012-S01 aplicando los patrones de listado del módulo.
5. Implementar MK-012-S03 como vista de solo lectura del historial.
6. Verificar la frontera con MK-008: la resolución de slug no se duplica como pantalla.
7. Normalizar código, tokens, layout y tipografía, y verificar el acceso directo de las 3 rutas inventariadas.
8. Implementar estados interactivos y accesibilidad con reproducción determinista.
9. Realizar autovalidación por el responsable funcional.
10. Someter a revisión transversal de Leonardo Vera Rodríguez.
11. Corregir hallazgos hasta obtener visto bueno.
12. Registrar el visto bueno y el estado APROBADO PARA FIGMA en `validation-report.md`.
13. Reflejar fielmente la versión con visto bueno en Figma.
14. Validar la fidelidad entre Figma y la versión aprobada.
15. Registrar el resultado general APROBADO cuando todos los gates estén cerrados.

## 8. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| DS-C01 Button / DS-C02 ActionIcon | Design System / shared | S01–S03 | Reutilizar sin variantes nuevas |
| DS-C03 TextInput / DS-C05 Textarea | Design System / shared | S01, S02 | Reutilizar |
| DS-C12 Search | Design System / shared | S01 | Reutilizar |
| DS-C14 Badge | Design System / shared | S01 | Reutilizar para estado de metadatos |
| DS-C17 Table | Design System / shared | S01, S03 | Reutilizar |
| DS-C19 Card | Design System / shared | S01, S02, S03 | Reutilizar para las tres secciones del formulario |
| DS-C22 Alert | Design System / shared | S02, S03 | Reutilizar para advertencias y conflicto |
| DS-C24 Skeleton / DS-C25 EmptyState | Design System / shared | S01, S02, S03 | Reutilizar |
| MK-012-C01 Resolvedor visual de slug | Component spec §9 | S02 | Construir específico |
| MK-012-C02 Metadatos con contadores | Component spec §9 | S02 | Construir específico |
| MK-012-C03 Vista previa de resultado | Component spec §9 | S02 | Construir específico |
| MK-012-C04 Historial de cambios | Component spec §9 | S03 | Construir específico |

## 9. Normalización

La implementación final debe alinearse a React, TypeScript, Mantine, tema central del módulo, Tabler Icons, Design System, UX Guidelines, accesibilidad (teclado, foco y contraste) y PC/desktop únicamente. Se verifican de forma explícita las tres rutas inventariadas: `/MK012/S01`, `/MK012/S02` y `/MK012/S03`.

## 10. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---|---|---|
| Default | S01 | P0 | `default` | Listado con slug y presencia de metadatos |
| Loading | S01 | P0 | `loading` | Skeleton de filas |
| Vacío | S01 | P0 | `empty` | EmptyState explicativo |
| Sin resultados | S01 | P0 | `sin-resultados` | EmptyState con acción Limpiar filtro |
| Error | S01, S02 | P0 | `error` | Mensaje accionable con reintento |
| Sesión y permisos | Todas | P0 | `sesion` | Estados `401` y `403` sin datos inventados |
| Slug normalizado | S02 | P0 | `slug-normalizado` | URL pública legible sin colisión |
| Colisión resuelta | S02 | P0 | `slug-con-colision` | Sufijo resaltado con explicación |
| Advertencias de longitud | S02 | P0 | `advertencias-activas` | Contadores y avisos con guardado habilitado |
| Conflicto de disponibilidad | S02 | P0 | `slug-carrera-409` | Alerta persistente y nueva propuesta |
| Historial con cambios | S03 | P0 | `historial-slugs` | Filas con slug anterior, actual y fecha |
| Historial inicial | S03 | P0 | `historial-inicial` | Fila con la primera asignación |
| Historial vacío | S03 | P0 | `historial-vacio` | EmptyState explicativo |

## 11. Orden de ejecución

| Fase | Salida | Actor / Revisor | Gate |
|---|---|---|---|
| Preparación | Contexto y fixtures | Responsable | Entradas vigentes |
| Pantalla ancla | S02 refinada | Responsable | Cobertura estructural |
| Listado | S01 completa | Responsable | Patrón de tabla aplicado |
| Historial | S03 completa | Responsable | Solo lectura y campos contractuales |
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
| R-01 | Presentar la vista previa como resultado exacto de un buscador | Media | Alto | LUX-03 exige la advertencia de aproximación; verificado en T15 |
| R-02 | Sustituir el slug en silencio ante `409 SLUG_DUPLICADO` | Media | Alto | T13 exige nueva propuesta visible y confirmación explícita |
| R-03 | Añadir un simulador de endpoint público de backoffice | Media | Alto | Eliminado por WF-012 §4; verificado en T60 |
| R-04 | Duplicar en este MK la pantalla de resolución de slug de MK-008 | Media | Medio | §4 y §6 declaran la frontera; verificado en T60 |
| R-05 | Bloquear el guardado por superar los umbrales de longitud | Media | Alto | LUX-02 y T12 exigen guardado habilitado con advertencias |
| R-06 | Mostrar información de responsable o autor en el historial | Media | Medio | El contrato no expone esos campos; verificado en T14 |
| R-07 | Exponer `POST /api/v1/categorias` desde esta interfaz | Baja | Alto | §4 lo excluye; verificado en T60 |

## 13. Quality Gates

### Gate A — Funcional
- SPEC-012, HU-012 (10 CA), WF-012 v0.5 y FLOW-012 cubiertos sin reglas inventadas.
- Las 3 pantallas inventariadas disponen de ruta directa, estable y reproducible (`/MK012/SXX`).
- Los estados P0 requeridos se reproducen de manera determinista.
- La edición de metadatos se ejecuta por `PATCH /api/v1/categorias/{categoriaId}/seo`.

### Gate B — UX
- Propuesta UX del módulo aplicada rigurosamente.
- UXD-004, UXD-007, UXD-013 y UXD-015 aplicadas donde corresponda.
- Decisiones locales LUX-01, LUX-02 y LUX-03 justificadas en `component-spec.md`.

### Gate C — UI
- Design System respetado, sin tokens arbitrarios ni estilos inline huérfanos.
- Componentes compartidos reutilizados del catálogo DS.

### Gate D — PC
- Sin overflow horizontal en viewport canónico de 1440 px.
- Jerarquía visual clara y estado nunca comunicado solo por color.
- Teclado, foco y contadores asociados a su campo.

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
