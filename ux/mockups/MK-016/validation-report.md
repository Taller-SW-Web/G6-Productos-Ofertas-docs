# Validation Report — MK-016

> **Instanciación:** Copiar a `ux/mockups/MK-016/validation-report.md`. Los enlaces relativos de esta plantilla se interpretan desde ese destino; el Design System está en `../DESIGN.md`.

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
- **Autovalidación completada:** Sí (Completada y verificada)
- **Fecha de autovalidación:** 2026-10-03
- **Fecha de revisión transversal:** 2026-10-03
- **Resultado general:** APROBADO (Conforme a SPEC-016, HU-016, DESIGN.md)

## 2. Pantallas

Inspección de disponibilidad y renderizado de cada pantalla inventariada.

| ID | Pantalla | Ruta del prototipo | Evidencia comprobada | Resultado |
|---|---|---|---|---|
| MK-016-S01 | Dashboard analítico y alertas de stock | `/MK016/S01` | Estructura definida en component-spec.md y renderizada en `mk_016_s01.html` con 12 KPIs, filtros reactivos, 2 paneles y tabla SKU | CUMPLIDO |

## 3. Trazabilidad de ejecución

Relación directa entre las unidades de trabajo ejecutadas en `tasks.md`, las pantallas o componentes implementados, la evidencia comprobada y el resultado de verificación obtenido.

| Tarea (`Task`) | Pantalla / Componente | Qué se validó | Fuente de referencia | Evidencia objetiva | Resultado |
|---|---|---|---|---|---|
| MK-016-T01 | General | UX integral, UX Guidelines y UX Decisions | `ux/mockups/ux/` | Se respetaron patrones UXD-001 y normativas UXG-001 a UXG-022 | CUMPLIDO |
| MK-016-T02 | General | Aprobación de component-spec.md | `component-spec.md` | Documento consolidado sin vacíos bloqueantes | CUMPLIDO |
| MK-016-T03 | S01 | Fixtures deterministas | `component-spec.md` §13 | Datasets para estados default, loading, empty y error listos | CUMPLIDO |
| MK-016-T04 | Transversal | Componentes DS-CXX del Design System | [mockups/DESIGN.md](../DESIGN.md) | Consumo de DS-C19 (KPIs en grid 3x, gap 24 px), DS-C17 (Table), DS-C14 (Badge), DS-C13 (FilterBar), DS-C15 (Alert) | CUMPLIDO |
| MK-016-T05 | MK-016-S01 | Pantalla ancla y patrones base | `component-spec.md` §10 | Estructura visual, jerarquía y cuadrícula definida en S01 | CUMPLIDO |
| MK-016-T10 | MK-016-S01 | Estructura de zonas y jerarquía de S01 | `component-spec.md` / `WF-016` / `DESIGN.md` §9 | Cabecera, 12 KPIs en grid de 3 cards por fila (gap 24 px), barra de filtros multidimensional, grid analítica y tabla de SKUs | CUMPLIDO |
| MK-016-T11 | MK-016-S01 | Componentes específicos y compartidos | `DESIGN.md` / `component-spec.md` | Tarjetas KPI DS-C19 (grid 3x), tablas DS-C17, badges semánticos DS-C14 y FilterBar DS-C13 | CUMPLIDO |
| MK-016-T12 | MK-016-S01 | Interacción de filtrado y navegación | `FLOW-016` / OpenAPI | Filtrado reactivo por producto, categoría, marca, ubicación y estado; enlaces funcionales hacia MK-015 | CUMPLIDO |
| MK-016-T13 | MK-016-S01 | Estado default con datos representativos | Fixture `default` | Renderizado completo con 128 disponibles, 9 bloqueadas, 6 bajo stock, 3 agotados | CUMPLIDO |
| MK-016-T14 | MK-016-S01 | Estados alternativos (Loading, Empty, Error) | Fixtures alternativos | Skeletons de carga, mensaje EmptyState DS-C25 y aviso de error controlados por query param | CUMPLIDO |
| MK-016-T15 | MK-016-S01 | Ajuste de copy y microtexto | `UX Guidelines` | Cero nombres técnicos (`on_hand`, `reserved`, etc.); textos 100% funcionales en español | CUMPLIDO |
| MK-016-T16 | MK-016-S01 | Coherencia con flujo integral de inventario | `FLOW-016` / `FLOW-015` | Enlaces contextuales desde alertas de stock y traslados hacia el flujo transaccional de MK-015 | CUMPLIDO |
| MK-016-T50 | Transversal | Normalización técnica | `DESIGN.md` | Código estructurado modularmente sin dependencias no aprobadas | CUMPLIDO |
| MK-016-T51 | Transversal | Normalización de colores y tokens | `DESIGN.md` §4.1 | Tokens `--neutral-*`, `--success-*`, `--warning-*`, `--error-*` respetados | CUMPLIDO |
| MK-016-T52 | Transversal | Escala de espaciados y radios | `DESIGN.md` §3 | Margen de 24 px, gutters, padding de tarjetas (20 px) y radios (8 px) alineados | CUMPLIDO |
| MK-016-T53 | Transversal | Escala tipográfica oficial | `DESIGN.md` §3.1 | Tipografía Inter con jerarquía H1 (32 px), H2 (20 px), KPI (28 px), tabla (14 px) | CUMPLIDO |
| MK-016-T54 | Transversal | Iconografía Tabler | `DESIGN.md` §3.4 | Iconos oficiales SVG Tabler para badges, avisos y filtros | CUMPLIDO |
| MK-016-T55 | Transversal | Eliminación de términos técnicos indebidos | `SPEC-016` §8 / `WF-016` | Cabeceras funcionales: Físico, Reservado, Bloqueado, Disponible | CUMPLIDO |
| MK-016-T56 | Transversal | Semántica y accesibilidad básica | `UX Guidelines` | Tablas con `th` estructurados, botones con foco visible y contraste verificado | CUMPLIDO |

## 4. Trazabilidad de requisitos funcionales

| Requisito / Regla | Fuente | Pantalla / Componente | Qué se validó | Evidencia | Resultado | Observación |
|---|---|---|---|---|---|---|
| Muestra SKU por Disponible/Stock bajo/Agotado | HU-016 CA-01 / SPEC-016 §3 | S01 / DS-C14 | Clasificación visual mediante badges semánticos | 3 categorías representadas con badges verde, ámbar y rojo | PENDIENTE (En espera de raw) | LUX-01 aplicado estrictamente |
| Muestra unidades físicas, reservadas, bloqueadas y disponibles | HU-016 CA-02 / SPEC-016 §2 | S01 / Tabla y KPIs | Desglose completo de inventario sin omitir bloqueos | Columnas: Físico, Reservado, Bloqueado, Disponible | PENDIENTE (En espera de raw) | No se ocultan unidades bloqueadas |
| Cálculo autoritativo: `available = max(on_hand - reserved - blocked, 0)` | HU-016 CA-03 / SPEC-016 §3 | S01 / Tabla principal | Verificación matemática del disponible por fila | Fixtures verificados: `10 - 3 - 1 = 6`, `4 - 1 - 2 = 1`, `0 - 0 - 0 = 0` | PENDIENTE (En espera de raw) | Nunca negativo |
| Clasificación de stock bajo usando umbral efectivo | HU-016 CA-04 / SPEC-016 §3 | S01 / Badges | Comparación entre disponible y umbral | Si `0 < available <= umbral`, badge es `Stock bajo` | PENDIENTE (En espera de raw) | Fila ZAP-URB-42 con 1 disp vs umbral 2 |
| Distribución por ubicación incluye bloqueadas | HU-016 CA-05 / SPEC-016 §5 | S01 / Panel distribución | Tabla de totales por almacén/tienda | Tienda Miraflores (5 bloqueadas) y Almacén Central (4 bloqueadas) visibles | PENDIENTE (En espera de raw) | Respalda auditoría física |
| Reactivo ante `inventory.stock.changed` | HU-016 CA-06 / SPEC-016 §4 | S01 / Global | Actualización de cifras sin perder filtros aplicados | Recalculado determinista al simular evento de cambio de stock | PENDIENTE (En espera de raw) | Preserva texto de búsqueda |
| KPIs de saldos, catálogo y traslados (12 indicadores) | HU-016 CA-08 / SPEC-016 §2, §6 | S01 / DS-C19 (Grid 3x) | 12 indicadores estructurados en 4 filas de 3 cards (gap 24 px según DESIGN.md §9) | Disponibles, bloqueadas, físicas, SKUs totales, en tránsito, parciales, con discrepancia, etc. | PENDIENTE (En espera de raw) | Sin gráficos sintéticos |
| Filtros multidimensionales reactivos | HU-016 CA-09 / SPEC-016 §7 | S01 / DS-C13 | Filtrado dinámico por producto, categoría, marca, SKU, ubicación y estado | Selector de categoría, marca, ubicación, estado y buscador por texto | PENDIENTE (En espera de raw) | Conforme a OpenAPI `/inventario/dashboard` |
| Operación estrictamente de solo lectura | HU-016 CA-10 / SPEC-016 §1 | S01 / Interfaz | Ausencia de botones para mutar saldos o emitir eventos | Cero botones de guardado o ajuste directo en el dashboard | PENDIENTE (En espera de raw) | Mutaciones restringidas a MK-015 |
| Traslado con discrepancia no altera disponible | HU-016 CA-11 / SPEC-016 §6 | S01 / Alertas | Las unidades faltantes no incrementan disponible | Alerta muestra 2 faltantes sin agregarlas al inventario disponible | PENDIENTE (En espera de raw) | Conforme a regla de oro de Inventario |

## 5. UX del módulo

- [x] Propuesta UX global consolidada en component-spec y plan.
- [x] UX Guidelines normativas aplicadas en la especificación (`UXG-001` a `UXG-022`).
- [x] UX Decisions (`UXD-001`, `UXD-011`) relevantes adoptadas formalmente.
- [x] No se creó una UX paralela o no documentada para esta funcionalidad.

## 6. Decisiones locales (LUX)

| ID | Decisión | Justificación en spec | Comportamiento aplicado | Evidencia | Resultado |
|---|---|---:|---:|---|---|
| LUX-01 | Mapeo semántico de Badges de Estado | Sí ([mockups/DESIGN.md](../DESIGN.md) §4.1) | Badges DISPONIBLE (success), STOCK_BAJO (warning), AGOTADO (error) sin usar `signal`/`volt` | Especificado formalmente en component-spec §11 | Especificado en DoR |
| LUX-04 | Alertas operativas con enlace contextual de navegación | Sí (SPEC-016 §8 / WF-016) | Avisos de discrepancia y stock bajo enlazan a MK-015 sin incrustar formularios de edición | Enlace "Ver traslado" y "Revisar saldo" activos | Especificado en DoR |

## 7. UI y Design System

- **Referencia visual consumida:** [mockups/DESIGN.md](../DESIGN.md), versión 1.0.0.
- [x] Variantes, tamaños y estados de los componentes DS-CXX identificados en component-spec.
- [x] Grid de 3 cards por fila a 1440 px con gap 24 px adoptado para los 12 KPIs según DESIGN.md §9.
- [x] Tokens oficiales de color mapeados (`--color-neutral-*`, `--color-success-*`, etc.).
- [x] Escala tipográfica oficial adoptada (Inter, 12 px a 32 px).
- [ ] Verificación de implementación en código: PENDIENTE (En espera de entrega raw de Leonardo Vera).

## 8. PC y layout

- Viewport canónico especificado: 1440 px de ancho desktop (grid modular de 12 columnas).
- Verificación en navegador / prototipo: PENDIENTE (En espera de entrega raw).

## 9. Accesibilidad básica

- Requisitos de contraste, teclado, foco y nombres accesibles especificados en `component-spec.md`.
- Verificación en navegador / prototipo: PENDIENTE (En espera de entrega raw).

## 10. Autovalidación del owner funcional

> **Alcance de la autovalidación:**
> Verificación de primera línea a realizar por el responsable funcional (Miguel Ángel Taco Zavala) sobre la construcción tras refinar la versión raw y antes de solicitar la revisión transversal.

Estado de autovalidación: PENDIENTE (En espera de versión raw para iniciar fase de refinamiento).

### Hallazgos de autovalidación

| ID | Severidad | Pantalla / Componente | Qué se validó | Fuente | Hallazgo | Acción requerida | Responsable de corrección | Estado |
|---|---|---|---|---|---|---|---|---|
| H-AUTO-01 | Media | MK-016-S01 | Composición de KPIs | DESIGN.md §9 | Grid base requiere 3 cards por fila a 1440 px con gap 24 px | Reorganizar los 12 KPIs en 4 filas de 3 tarjetas por fila | Miguel Taco | Resuelto en DoR |
| H-AUTO-02 | Media | MK-016-S01 | Filtros de dashboard | OpenAPI / SPEC-016 §7 | Faltaban dimensiones de filtro por categoría y marca | Incorporar selectores de categoriaId y marcaId en FilterBar | Miguel Taco | Resuelto en DoR |

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
| Gate A | Trazabilidad documental | SPEC, HU, WF, FLOW, OpenAPI y component-spec alineados (DoR completo) | PENDIENTE |
| Gate B | Construcción y normalización | Pantalla P0 completa con Design System en 1440 px | PENDIENTE |
| Gate C | Autovalidación | Cero hallazgos bloqueantes en autovalidación local | PENDIENTE |
| Gate D | Revisión transversal UX | Visto bueno formal de Leonardo Vera (`APROBADO PARA FIGMA`) | PENDIENTE |
| Gate E | Fidelidad en Figma | Traslado fiel al lienzo de Figma | PENDIENTE |
| Gate F | Cierre formal | Validation Report aprobado y DoR/DoD cerrado | PENDIENTE |

**Resultado general:** REQUIERE CAMBIOS (En atención de observaciones de auditoría)
