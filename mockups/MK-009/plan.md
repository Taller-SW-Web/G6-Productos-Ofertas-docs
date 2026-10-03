# MK-009 — Plan de construcción

## 1. Identificación

**Funcionalidad:** Gestión de características y sus valores.  
**Owner funcional:** Leonardo Lopez (`lopez`).  
**Rama:** `lopez`.  
**Coordinación:** Issue #61 (mockups transversales).  
**Versión:** 1.0.0, 2026-10-03.  
**Estado:** En revisión; ejecución no iniciada.  
**Entrada rectora:** [component-spec.md](component-spec.md).

---

## 2. Contrato de ejecución

| Elemento | Compromiso |
|---|---|
| **Entradas obligatorias** | [SPEC-009](../../specs/SPEC-009-gestion-caracteristicas.md), [HU-009](../../hu/HU-009-gestion-caracteristicas.md), [WF-009](../../wireframes/flows/WF-009-gestion-caracteristicas.md), [FLOW-009](../../flujos/FLOW-009-gestion-caracteristicas.md), [OpenAPI 0.5.0](../../api/openapi.yaml), [AsyncAPI](../../asyncapi/asyncapi.yaml), [Propuesta UX](../ux/propuesta-ux.md), [UX Decisions](../ux/ux-decisions.md), [UX Guidelines](../ux/ux-guidelines.md), [Design System](../DESIGN.md) v1.0.0. |
| **Salidas esperadas** | Ocho pantallas directas (`MK-009-S01` a `S06`, con `S04P` y `S04R`), componentes locales `MK-009-C01..C03`, fixtures tipados `FX-009-01..07`, autovalidación de Leonardo Lopez, revisión UX de Leonardo Vera y traslado fiel a Figma. |
| **Restricciones técnicas** | Web Desktop (1440 px), React + TypeScript + Mantine, inmutabilidad de tipos de dato en edición, tope de 50 valores activos para LISTA, unidad obligatoria para NUMERO. |
| **Condición de parada** | Si se detecta ambigüedad en la validación asíncrona de valores o en los eventos de propagación, se detiene la tarea correspondiente y se escala sin alterar el contrato OpenAPI. |
| **Quality Gates** | Gate A (Documental), Gate B (Construcción/Interacción), Gate C (Normalización UI), Gate D (Autovalidación), Gate E (Revisión UX transversal), Gate F (Figma). |

---

## 3. Entradas obligatorias y readiness

| Entrada | Disponible | Estado de lectura / Requisito |
|---|---|---|
| SPEC-009 y HU-009 | Sí | Tipos `TEXTO`, `NUMERO`, `LISTA`, inmutabilidad y límites de valores |
| WF-009 y FLOW-009 | Sí | Flujo de S01 a S06, interacción de valores de lista y baja segura |
| OpenAPI 0.5.0 | Sí | Endpoints `/caracteristicas/*` y DTOs de características y valores confirmados |
| Design System y UX | Sí | Tokens, componentes DS-C y lineamientos UXD-001/002/003/005/008/011 vigentes |
| Component Spec | Sí | Redactado en [component-spec.md](component-spec.md) con 8 vistas inventariadas |

---

## 4. Objetivo constructivo y orden de desarrollo

La pantalla ancla es **MK-009-S01 (Listado de características maestras)**, ya que establece la vista general de atributos, los filtros por tipo de dato y las acciones para derivar a creación, edición, gestión de valores o desactivación.

| Orden | Pantalla | Dependencia | Salida constructiva |
|---|---|---|---|
| 1 | `MK-009-S01` | Fixtures `FX-009-01` | Pantalla ancla: tabla paginada, badges por tipo de dato, barra de filtros y acciones |
| 2 | `MK-009-S02` | S01 y componente `C01` | Formulario de creación con revelación progresiva según tipo seleccionado |
| 3 | `MK-009-S03` | S01 y componente `C01` | Edición de característica con tipo bloqueado/inmutable y edición de unidad |
| 4 | `MK-009-S04`, `S04-P`, `S04-R` | S01 y componentes `C02`, `C03` | Vista de valores de lista, alta/edición de valores, verificación asíncrona y rechazo |
| 5 | `MK-009-S05` | S01 | Diálogo de desactivación/reactivación de la característica maestra |
| 6 | `MK-009-S06` | S01 | Ficha técnica de detalle con metadatos completos y valores asociados |

---

## 5. Estrategia técnica de implementación

1. **Fixtures tipados:** Implementar `FX-009-01` a `FX-009-07` con las tres tipologías de datos, listados de valores predefinidos y respuestas simuladas para baja segura.
2. **Rutas directas del prototipo:** Registrar en el router `/MK009/S01`, `/MK009/S02`, `/MK009/S03`, `/MK009/S04`, `/MK009/S04P`, `/MK009/S04R`, `/MK009/S05`, `/MK009/S06`, permitiendo acceso aislado vía `?fixture=`.
3. **Componentes locales:** Diseñar `FormularioTipoDato` con control de estados condicionales y `TablaValoresLista` con control visual del límite de 50 items.
4. **Normalización Mantine:** Garantizar tipografía Oswald/Inter, paleta de colores y componentes compartidos del Design System.
5. **Autovalidación y revisión UX:** Ejecutar autovalidación sobre los 8 criterios de cobertura HU-009 y solicitar revisión transversal a Leonardo Vera.

---

## 6. Riesgos y mitigación

| Riesgo identificado | Estrategia de mitigación |
|---|---|
| Modificación accidental del tipo de dato en edición | Bloquear el selector en S03 convirtiéndolo en texto solo lectura con candado explicativo. |
| Creación de número sin unidad de medida | Validación requerida de frontend y bloqueo de envío hasta especificar unidad. |
| Desborde del límite de 50 valores en lista | Contador visual en S04 y deshabilitación del botón de alta al llegar a 50 valores activos. |
| Asunción de baja inmediata de valores | Feedback 202 Accepted en S04-P aclarando que se está comprobando uso en productos. |

---

## 7. Fases y Quality Gates

* **Gate A — Preparación:** Component spec, plan y tasks aprobados; fuentes consolidadas.
* **Gate B — Construcción:** 8 vistas implementadas en `prototipo/src/pantallas/MK009/`.
* **Gate C — Normalización:** Cumplimiento de tokens Mantine, accesibilidad de tablas y viewport 1440 px.
* **Gate D — Autovalidación:** Owner verifica 8 criterios HU-009 y registra evidencias.
* **Gate E — Revisión UX transversal:** Visto bueno de Leonardo Vera (`APROBADO PARA FIGMA`).
* **Gate F — Figma y Cierre:** Fidelidad validada y `validation-report.md` emitido.
