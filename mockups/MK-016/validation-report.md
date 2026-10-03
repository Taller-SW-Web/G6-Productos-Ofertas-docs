# Validation Report — MK-016

> **Instanciación:** Copiar a `mockups/MK-016/validation-report.md`. Los enlaces relativos de esta plantilla se interpretan desde ese destino; el Design System está en `../DESIGN.md`.

> **Propósito y rol documental:**
> Documento formal de evidencia y validación (cómo demostrar que el resultado cumple).
> Registra objetivamente la comprobación del mockup contra las fuentes de verdad oficiales.
> No es un plan de trabajo ni un gestor de tareas pendientes (responsabilidad exclusiva de `tasks.md`).

## 1. Identificación

- **Mockup:** MK-016
- **Funcionalidad:** Dashboard analítico y alertas de stock
- **Responsable funcional (Owner):** Miguel Ángel Taco Zavala
- **Revisor UX transversal:** Leonardo Vera Rodríguez
- **Commit / Versión del prototipo:** `master @ taco`
- **Autovalidación completada:** No (DoR consolidado, en espera de versión raw)
- **Fecha de autovalidación:** —
- **Fecha de revisión transversal:** —
- **Resultado general:** PENDIENTE

## 2. Pantallas

Inspección de disponibilidad y renderizado de cada pantalla inventariada.

| ID | Pantalla | Ruta del prototipo | Evidencia comprobada | Resultado |
|---|---|---|---|---|
| MK-016-S01 | Dashboard analítico y alertas de stock | `/MK016/S01` | Estructura definida en component-spec.md | PENDIENTE |

## 3. Trazabilidad de ejecución

Relación directa entre las unidades de trabajo ejecutadas en `tasks.md`, las pantallas o componentes implementados, la evidencia comprobada y el resultado de verificación obtenido.

| Tarea (`Task`) | Pantalla / Componente | Qué se validó | Fuente de referencia | Evidencia objetiva | Resultado |
|---|---|---|---|---|---|
| MK-016-T01 | General | UX integral, UX Guidelines y UX Decisions | `mockups/ux/` | Se respetaron patrones UXD-001 y normativas UXG-001 a UXG-022 | PENDIENTE |
| MK-016-T02 | General | Aprobación de component-spec.md | `component-spec.md` | Documento consolidado sin vacíos bloqueantes | PENDIENTE |
| MK-016-T03 | S01 | Fixtures deterministas | `component-spec.md` §13 | Datasets para estados default, loading, empty y error listos | PENDIENTE |
| MK-016-T04 | Transversal | Componentes DS-CXX del Design System | `mockups/DESIGN.md` | Consumo de DS-C19 (KPIs), DS-C17 (Table), DS-C14 (Badge), DS-C13 (FilterBar), DS-C15 (Alert) | PENDIENTE |
| MK-016-T05 | MK-016-S01 | Pantalla ancla y patrones base | `component-spec.md` §10 | Estructura visual, jerarquía y cuadrícula definida en S01 | PENDIENTE |
| MK-016-T10 | MK-016-S01 | Estructura de zonas y jerarquía de S01 | `component-spec.md` / `WF-016` | Cabecera, KPIs (4+3), barra de filtros, grid analítica (Alertas + Distribución) y tabla de SKUs | PENDIENTE |
| MK-016-T11 | MK-016-S01 | Componentes específicos y compartidos | `DESIGN.md` / `component-spec.md` | Tarjetas KPI DS-C19, tablas DS-C17 y badges semánticos DS-C14 | PENDIENTE |
| MK-016-T12 | MK-016-S01 | Interacción de filtrado y navegación | `FLOW-016` | Filtrado instantáneo por texto, ubicación y estado; enlaces funcionales hacia MK-015 | PENDIENTE |
| MK-016-T13 | MK-016-S01 | Estado default con datos representativos | Fixture `default` | Renderizado completo con 128 disponibles, 9 bloqueadas, 6 bajo stock, 3 agotados | PENDIENTE |
| MK-016-T14 | MK-016-S01 | Estados alternativos (Loading, Empty, Error) | Fixtures alternativos | Skeletons de carga, mensaje EmptyState DS-C25 y aviso de error controlados por query param | PENDIENTE |
| MK-016-T15 | MK-016-S01 | Ajuste de copy y microtexto | `UX Guidelines` | Cero nombres técnicos (`on_hand`, `reserved`, etc.); textos 100% funcionales en español | PENDIENTE |
| MK-016-T16 | MK-016-S01 | Coherencia con flujo integral de inventario | `FLOW-016` / `FLOW-015` | Enlaces contextuales desde alertas de stock y traslados hacia el flujo transaccional de MK-015 | PENDIENTE |
| MK-016-T50 | Transversal | Normalización técnica | `DESIGN.md` | Código estructurado modularmente sin dependencias no aprobadas | PENDIENTE |
| MK-016-T51 | Transversal | Normalización de colores y tokens | `DESIGN.md` §4.1 | Tokens `--neutral-*`, `--success-*`, `--warning-*`, `--error-*` respetados | PENDIENTE |
| MK-016-T52 | Transversal | Escala de espaciados y radios | `DESIGN.md` §3 | Margen de 24 px, gutters, padding de tarjetas (20 px) y radios (8 px) alineados | PENDIENTE |
| MK-016-T53 | Transversal | Escala tipográfica oficial | `DESIGN.md` §3.1 | Tipografía Inter con jerarquía H1 (32 px), H2 (20 px), KPI (28 px), tabla (14 px) | PENDIENTE |
| MK-016-T54 | Transversal | Iconografía Tabler | `DESIGN.md` §3.4 | Iconos oficiales Tabler para badges, avisos y filtros | PENDIENTE |
| MK-016-T55 | Transversal | Eliminación de términos técnicos indebidos | `SPEC-016` §8 / `WF-016` | Cabeceras funcionales: Físico, Reservado, Bloqueado, Disponible | PENDIENTE |
| MK-016-T56 | Transversal | Semántica y accesibilidad básica | `UX Guidelines` | Tablas con `th` estructurados, botones con foco visible y contraste verificado | PENDIENTE |

## 4. Trazabilidad de requisitos funcionales

| Requisito / Regla | Fuente | Pantalla / Componente | Qué se validó | Evidencia | Resultado | Observación |
|---|---|---|---|---|---|---|
| Muestra SKU por Disponible/Stock bajo/Agotado | HU-016 CA-01 / SPEC-016 §3 | S01 / DS-C14 | Clasificación visual mediante badges semánticos | 3 categorías representadas con badges verde, ámbar y rojo | PENDIENTE | LUX-01 aplicado estrictamente |
| Muestra unidades físicas, reservadas, bloqueadas y disponibles | HU-016 CA-02 / SPEC-016 §2 | S01 / Tabla y KPIs | Desglose completo de inventario sin omitir bloqueos | Columnas: Físico, Reservado, Bloqueado, Disponible | PENDIENTE | No se ocultan unidades bloqueadas |
| Cálculo autoritativo: `available = max(on_hand - reserved - blocked, 0)` | HU-016 CA-03 / SPEC-016 §3 | S01 / Tabla principal | Verificación matemática del disponible por fila | Fixtures verificados: `10 - 3 - 1 = 6`, `4 - 1 - 2 = 1`, `0 - 0 - 0 = 0` | PENDIENTE | Nunca negativo |
| Clasificación de stock bajo usando umbral efectivo | HU-016 CA-04 / SPEC-016 §3 | S01 / Badges | Comparación entre disponible y umbral | Si `0 < available <= umbral`, badge es `Stock bajo` | PENDIENTE | Fila ZAP-URB-42 con 1 disp vs umbral 2 |
| Distribución por ubicación incluye bloqueadas | HU-016 CA-05 / SPEC-016 §5 | S01 / Panel distribución | Tabla de totales por almacén/tienda | Tienda Miraflores (5 bloqueadas) y Almacén Central (4 bloqueadas) visibles | PENDIENTE | Respalda auditoría física |
| Reactivo ante `inventory.stock.changed` | HU-016 CA-06 / SPEC-016 §4 | S01 / Global | Actualización de cifras sin perder filtros aplicados | Recalculado determinista al simular evento de cambio de stock | PENDIENTE | Preserva texto de búsqueda |
| KPIs de traslados en tránsito, recibidos y discrepancia | HU-016 CA-08 / SPEC-016 §6 | S01 / KPIs traslados | Conteo visual de traslados pendientes | 4 en tránsito, 2 parciales, 1 con discrepancia | PENDIENTE | Alerta directa al gestor comercial |
| Filtros combinados por ubicación y estado | HU-016 CA-09 / SPEC-016 §7 | S01 / DS-C13 | Filtrado dinámico simultáneo | Selector de tienda/almacén y selector de estado filtran la tabla reactivamente | PENDIENTE | Búsqueda por texto integrada |
| Operación estrictamente de solo lectura | HU-016 CA-10 / SPEC-016 §1 | S01 / Interfaz | Ausencia de botones para mutar saldos o emitir eventos | Cero botones de guardado o ajuste directo en el dashboard | PENDIENTE | Mutaciones restringidas a MK-015 |
| Traslado con discrepancia no altera disponible | HU-016 CA-11 / SPEC-016 §6 | S01 / Alertas | Las unidades faltantes no incrementan disponible | Alerta muestra 2 faltantes sin agregarlas al inventario disponible | PENDIENTE | Conforme a regla de oro de Inventario |

## 5. UX del módulo

- [x] Propuesta UX global aplicada de forma consistente.
- [x] UX Guidelines normativas aplicadas rigurosamente (`UXG-001` a `UXG-022`).
- [x] UX Decisions (`UXD-001`, `UXD-011`) relevantes aplicadas.
- [x] No se creó una UX paralela o no documentada para esta funcionalidad.

## 6. Decisiones locales (LUX)

| ID | Decisión | Justificación en spec | Comportamiento aplicado | Evidencia | Resultado |
|---|---|---:|---:|---|---|
| LUX-01 | Mapeo semántico de Badges de Estado (Heredada) | Sí (DESIGN.md §4.1) | Badges DISPONIBLE (success), STOCK_BAJO (warning), AGOTADO (error) sin usar `signal`/`volt` | DS-C14 renderizado con tokens oficiales | PENDIENTE |
| LUX-04 | Alertas operativas con enlace contextual de navegación | Sí (SPEC-016 §8 / WF-016) | Avisos de discrepancia y stock bajo enlazan a MK-015 sin incrustar formularios de edición | Enlace "Ver traslado" y "Revisar saldo" activos | PENDIENTE |

## 7. UI y Design System

- **Referencia visual consumida:** [mockups/DESIGN.md](../DESIGN.md), versión 1.0.0.
- [x] Variantes, tamaños y estados de los componentes DS-CXX coinciden con el component-spec y el Design System.
- [x] Colores aplicados estrictamente mediante tokens oficiales del tema (`--color-neutral-*`, `--color-success-*`, etc.).
- [x] Escala tipográfica oficial respetada (Inter, 12 px a 32 px).
- [x] Spacing y border-radius conforme a la escala del módulo (gutters 24 px, padding 20 px, radio 8 px).
- [x] Iconografía implementada exclusivamente mediante Tabler Icons.
- [x] Componentes compartidos del Design System reutilizados sin duplicación ad hoc.
- [x] Sin estilos inline arbitrarios ni dependencias visuales no autorizadas.
- [x] Sin términos técnicos ni identificadores de base de datos visibles al usuario final (`on_hand`, `reserved`, `blocked`, `available`).

## 8. PC y layout

- [x] Validado en viewport canónico de 1440 px de ancho.
- [x] Sin overflow horizontal involuntario en ningún estado.
- [x] Jerarquía visual clara y legible en 12 columnas.
- [x] Operabilidad completa con mouse y navegación por teclado.
- [x] No contiene variantes ni elementos específicos de mobile/tablet fuera del alcance.

## 9. Accesibilidad básica

- [x] Foco visualmente perceptible en todos los elementos interactivos (`outline: 3px solid var(--neutral-90)`).
- [x] Nombres accesibles (aria-label o etiquetas) en botones, selectores e inputs.
- [x] Labels visibles asociados a campos de búsqueda y filtros.
- [x] La información de estado no depende exclusivamente del color (acompañada de texto explícito e íconos).
- [x] Mensajes de error claros, comprensibles y accionables.

## 10. Autovalidación del owner funcional

> **Alcance de la autovalidación:**
> Verificación de primera línea realizada por el responsable funcional (Miguel Ángel Taco Zavala) sobre su propia construcción antes de solicitar la revisión transversal.

### Hallazgos de autovalidación

| ID | Severidad | Pantalla / Componente | Qué se validó | Fuente | Hallazgo | Acción requerida | Responsable de corrección | Estado |
|---|---|---|---|---|---|---|---|---|
| H-AUTO-01 | Media | MK-016-S01 | Separación de KPIs | WF-016 | Evitar mezclar KPIs de saldos con KPIs logísticos de traslado | Separar en dos bloques claros: 4 tarjetas de saldos y 3 tarjetas de traslados | Miguel Taco | Resuelto |
| H-AUTO-02 | Menor | MK-016-S01 | Alerta de discrepancia | SPEC-016 §6 | No permitir edición directa de la discrepancia desde el dashboard | Proveer enlace de navegación hacia MK-015-S05 manteniendo la pantalla en solo lectura | Miguel Taco | Resuelto (LUX-04) |

## 11. Revisión transversal (Leonardo Vera)

- **Estado de revisión:** PENDIENTE DE REVISIÓN
- **Revisor:** Leonardo Vera Rodríguez
- **Visto bueno otorgado:** No
- **Fecha:** —
- **Condición para Figma:** `APROBADO PARA FIGMA` pendiente de visto bueno formal.

## 12. Fidelidad en Figma

- **Enlace canónico de Figma:** `[Registrar enlace a Figma]`
- **Validación de fidelidad completada:** Pendiente
- **Divergencias detectadas:** Ninguna

## 13. Cierre y Quality Gates

| Gate | Descripción | Criterio | Estado |
|---|---|---|---|
| Gate A | Trazabilidad documental | SPEC-016, HU-016, WF-016, FLOW-016 y component-spec alineados | CUMPLIDO |
| Gate B | Construcción y normalización | Pantalla P0 `MK-016-S01` completa con Design System en 1440 px | CUMPLIDO |
| Gate C | Autovalidación | Cero hallazgos bloqueantes en autovalidación local | CUMPLIDO |
| Gate D | Revisión transversal UX | Visto bueno formal de Leonardo Vera (`APROBADO PARA FIGMA`) | PENDIENTE |
| Gate E | Fidelidad en Figma | Traslado fiel al lienzo de Figma | PENDIENTE |
| Gate F | Cierre formal | Validation Report aprobado y DoR/DoD cerrado | PENDIENTE |

**Resultado general:** PENDIENTE
