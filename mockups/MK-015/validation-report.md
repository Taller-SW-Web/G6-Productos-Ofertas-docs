# Validation Report — MK-015

> **Propósito y rol documental:**
> Documento formal de evidencia y validación (cómo demostrar que el resultado cumple).
> Registra objetivamente la comprobación del mockup contra las fuentes de verdad oficiales.
> No es un plan de trabajo ni un gestor de tareas pendientes (responsabilidad exclusiva de `tasks.md`).

## 1. Identificación

- **Mockup:** MK-015
- **Funcionalidad:** Control de stock y disponibilidad
- **Responsable funcional (Owner):** Miguel Ángel Taco Zavala
- **Revisor UX transversal:** Leonardo Vera Rodríguez
- **Versión:** 1.0.0
- **Fase actual:** DoR completado (Listo para versión raw de Leonardo Vera)
- **Autovalidación completada:** No (En espera de versión raw para refinamiento y autovalidación)
- **Fecha de autovalidación:** —
- **Fecha de revisión transversal:** —
- **Resultado general:** PENDIENTE

## 2. Pantallas

Inspección de disponibilidad y renderizado de cada pantalla inventariada.

| ID | Pantalla | Ruta del prototipo | Evidencia comprobada | Resultado |
|---|---|---|---|---|
| MK-015-S01 | Control de stock | `/MK015/S01` | Estructura definida en component-spec.md | PENDIENTE (En espera de raw) |
| MK-015-S02 | Configuración de umbrales | `/MK015/S02` | Formulario numérico definido en component-spec.md | PENDIENTE (En espera de raw) |
| MK-015-S03 | Detalle del saldo | `/MK015/S03` | Drawer lateral 640 px definido en component-spec.md | PENDIENTE (En espera de raw) |
| MK-015-S04 | Traslados pendientes | `/MK015/S04` | Listado de traslados definido en component-spec.md | PENDIENTE (En espera de raw) |
| MK-015-S05 | Registrar recepción | `/MK015/S05` | Formulario con confirmación inline definido en component-spec.md | PENDIENTE (En espera de raw) |

## 3. Trazabilidad de ejecución

Relación directa entre las unidades de trabajo ejecutadas en `tasks.md`, las pantallas o componentes implementados, la evidencia comprobada y el resultado de verificación obtenido.

| Tarea (`Task`) | Pantalla / Componente | Qué se validó | Fuente de referencia | Evidencia objetiva | Resultado |
|---|---|---|---|---|---|
| MK-015-T01 | General | UX integral, UX Guidelines y UX Decisions | `mockups/ux/` | Se respetaron patrones UXD-001 y normativas UXG-001 a UXG-022 | PENDIENTE |
| MK-015-T02 | General | Aprobación de component-spec.md | `component-spec.md` | Documento consolidado sin vacíos bloqueantes | PENDIENTE |
| MK-015-T03 | S01 - S05 | Fixtures deterministas | `component-spec.md` §13 | Datasets para estados default, loading, empty y error listos | PENDIENTE |
| MK-015-T04 | Transversal | Componentes DS-CXX del Design System | [mockups/DESIGN.md](../DESIGN.md) | Mapeo de DS-C17, DS-C14, DS-C13, DS-C20, DS-C04, DS-C15 | PENDIENTE |
| MK-015-T05 | MK-015-S01 | Pantalla ancla y patrones base | `component-spec.md` §10 | Estructura visual y jerarquía definidas en S01 | PENDIENTE |
| MK-015-T10 | MK-015-S01 | Estructura de zonas y jerarquía de S01 | `component-spec.md` / `WF-015` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T11 | MK-015-S01 / C01 | Componentes de la tabla de stock | [mockups/DESIGN.md](../DESIGN.md) / `component-spec.md` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T12 | MK-015-S01 | Navegación e interacción de S01 | `FLOW-015` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T13 | MK-015-S01 | Estado default con datos | Fixture `default` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T14 | MK-015-S01 | Estados alternativos (Loading, Empty, Error) | Fixtures alternativos | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T20 | MK-015-S02 | Estructura de configuración de umbrales | `component-spec.md` §10 | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T21 | MK-015-S02 | Componente DS-C04 NumberInput con endpoints global y por SKU | [mockups/DESIGN.md](../DESIGN.md) / `Contrato_Api.md` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T22 | MK-015-S02 | Acción de aplicar umbral y consulta GET | `SPEC-015` §12 | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T30 | MK-015-S03 | Estructura de detalle del saldo | `component-spec.md` §10 | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T31 | MK-015-S03 | Desglose de unidades y microtexto | `SPEC-015` / `WF-015` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T32 | MK-015-S03 | Drawer lateral DS-C20 de 640 px y LUX-02 | [mockups/DESIGN.md](../DESIGN.md) §5.2 / `LUX-02` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T40 | MK-015-S04 | Lista de traslados pendientes | `component-spec.md` §10 | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T41 | MK-015-S04 | Estados de traslado en tránsito/recibido | `FLOW-015` / `Contrato_Api.md` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T42 | MK-015-S04 | Enlace a recepción de traslado | `FLOW-015` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T50 | MK-015-S05 | Estructura de registro de recepción | `component-spec.md` §10 | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T51 | MK-015-S05 | Confirmación inline (LUX-03) | [mockups/DESIGN.md](../DESIGN.md) §4.5 / `LUX-03` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T52 | MK-015-S05 | Campos de recepción y texto oficial WF-015 | `WF-015` S-05 | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |
| MK-015-T53 | MK-015-S05 | Cero invención de faltantes | `SPEC-015` | En espera de entrega de base raw por Leonardo Vera | PENDIENTE |

## 4. Trazabilidad de requisitos funcionales

| Requisito / Regla | Fuente | Pantalla / Componente | Qué se validará | Criterio de verificación en prototipo | Resultado |
|---|---|---|---|---|---|
| Saldo disponible autoritativo: `max(on_hand - reserved - blocked, 0)` | SPEC-015 §2 | S01, S03 / C01 | Cálculo matemático de unidades disponibles | Fixture default: 10 - 2 - 1 = 7 disponibles. Nunca saldo negativo | PENDIENTE (En espera de raw) |
| Clasificación de estados (DISPONIBLE, STOCK_BAJO, AGOTADO) | SPEC-015 §12 | S01, S02, S03 / DS-C14 | Mapeo visual y reglas de umbral efectivo | Badges verde (`DISPONIBLE`), ámbar (`STOCK_BAJO`), rojo (`AGOTADO`) | PENDIENTE (En espera de raw) |
| Desglose físico vs reservado vs bloqueado | SPEC-015 §4 | S01, S03 | Visualización separada sin omitir `blocked` | Columnas y etiquetas claras en tabla y drawer sin términos crudos | PENDIENTE (En espera de raw) |
| Expiración y liberación no tocan bloqueadas | SPEC-015 §8 | S03 | Explicación en ficha técnica de unidades bloqueadas | Microtexto: las bloqueadas no se liberan por TTL | PENDIENTE (En espera de raw) |
| Recepción de traslados con discrepancia | SPEC-015 §15 | S05 | Recepción parcial o final con faltantes | Texto de advertencia literal de WF-015 inline (LUX-03) | PENDIENTE (En espera de raw) |
| Filtros por SKU, Producto, Ubicación y Estado | WF-015 S-01 | S01 / DS-C13 | Filtrado dinámico sin pérdida de contexto | Búsqueda por texto y selectores de ubicación/estado | PENDIENTE (En espera de raw) |

## 5. UX del módulo

- [x] Propuesta UX global consolidada en component-spec y plan.
- [x] UX Guidelines normativas aplicadas en la especificación (`UXG-001` a `UXG-022`).
- [x] UX Decisions (`UXD-001`, `UXD-011`) relevantes adoptadas formalmente.
- [x] No se creó una UX paralela o no documentada para esta funcionalidad.

## 6. Decisiones locales (LUX)

| ID | Decisión | Justificación en spec | Comportamiento especificado | Estado |
|---|---|---:|---|---|
| LUX-01 | Mapeo semántico de Badges de Estado | Sí ([mockups/DESIGN.md](../DESIGN.md) §4.1) | Badges DISPONIBLE (success), STOCK_BAJO (warning), AGOTADO (error) sin usar `signal`/`volt` | Especificado en DoR |
| LUX-02 | Detalle de saldo en Drawer 640 px | Sí (WF-015 / [mockups/DESIGN.md](../DESIGN.md) §5.2) | Drawer lateral superpuesto manteniendo tabla padre visible | Especificado en DoR |
| LUX-03 | Confirmación de recepción final inline | Sí ([mockups/DESIGN.md](../DESIGN.md) §4.5) | Alerta inline con texto literal sin modales anidados | Especificado en DoR |

## 7. UI y Design System

- **Referencia visual consumida:** [mockups/DESIGN.md](../DESIGN.md), versión 1.0.0.
- [x] Variantes, tamaños y estados de los componentes DS-CXX identificados en component-spec.
- [x] Tokens oficiales de color mapeados (`--color-neutral-*`, `--color-success-*`, etc.).
- [x] Escala tipográfica oficial adoptada.
- [ ] Verificación de implementación en código: PENDIENTE (En espera de entrega raw de Leonardo Vera).

## 8. PC y layout

- Viewport canónico especificado: 1440 px de ancho desktop.
- Verificación en navegador / prototipo: PENDIENTE (En espera de entrega raw).

## 9. Accesibilidad básica

- Requisitos de contraste, teclado, foco y nombres accesibles especificados en `component-spec.md`.
- Verificación en navegador / prototipo: PENDIENTE (En espera de entrega raw).

## 10. Autovalidación del owner funcional

> **Alcance de la autovalidación:**
> Verificación de primera línea a realizar por el responsable funcional (Miguel Ángel Taco Zavala) sobre la construcción en `lab/taco` tras refinar la versión raw de Vera y antes de solicitar la revisión transversal.

Estado de autovalidación: PENDIENTE (En espera de versión raw para iniciar fase de refinamiento).

## 11. Revisión transversal (Leonardo Vera)

- **Estado de revisión:** PENDIENTE (En espera de que el owner complete el refinamiento y autovalidación)
- **Revisor:** Leonardo Vera Rodríguez
- **Visto bueno otorgado:** No
- **Fecha:** —
- **Condición para Figma:** `APROBADO PARA FIGMA` pendiente de visto bueno formal.

## 12. Fidelidad en Figma

- **Enlace canónico de Figma:** «Enlace a Figma pendiente»
- **Validación de fidelidad completada:** Pendiente
- **Divergencias detectadas:** PENDIENTE / NO EVALUADO

## 13. Cierre y Quality Gates

| Gate | Descripción | Criterio | Estado |
|---|---|---|---|
| Gate A | Trazabilidad documental | SPEC, HU, WF, FLOW y component-spec alineados (DoR completo) | PENDIENTE |
| Gate B | Construcción y normalización | Pantallas P0 completas con Design System en 1440 px | PENDIENTE |
| Gate C | Autovalidación | Cero hallazgos bloqueantes en autovalidación local | PENDIENTE |
| Gate D | Revisión transversal UX | Visto bueno formal de Leonardo Vera (`APROBADO PARA FIGMA`) | PENDIENTE |
| Gate E | Fidelidad en Figma | Traslado fiel al lienzo de Figma | PENDIENTE |
| Gate F | Cierre formal | Validation Report aprobado y DoR/DoD cerrado | PENDIENTE |

**Resultado general:** REQUIERE CAMBIOS (En atención de observaciones de auditoría)
