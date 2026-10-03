# MK-010 — Plan de construcción

## 1. Identificación

**Funcionalidad:** Asociación entre tipos de producto y características.  
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
| **Entradas obligatorias** | [SPEC-010](../../specs/SPEC-010-asociacion-tipo-producto-caracteristica.md), [HU-010](../../hu/HU-010-asociacion-tipo-producto-caracteristica.md), [WF-010](../../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md), [FLOW-010](../../flujos/FLOW-010-asociacion-tipo-producto-caracteristica.md), [OpenAPI 0.5.0](../../api/openapi.yaml), [AsyncAPI](../../asyncapi/asyncapi.yaml), [Propuesta UX](../ux/propuesta-ux.md), [UX Decisions](../ux/ux-decisions.md), [UX Guidelines](../ux/ux-guidelines.md), [Design System](../DESIGN.md) v1.0.0. |
| **Salidas esperadas** | Siete pantallas directas (`MK-010-S01` a `S07`), componentes locales `MK-010-C01..C03`, fixtures tipados `FX-010-01..07`, autovalidación de Leonardo Lopez, revisión UX de Leonardo Vera y traslado fiel a Figma. |
| **Restricciones técnicas** | Web Desktop (1440 px), React + TypeScript + Mantine, el esquema pertenece al Tipo de Producto (no categorías), sin controles de ordenamiento visual posicional, control estricto del límite de características. |
| **Condición de parada** | Si se pretende implementar reordenamiento de características o asignación de esquemas a categorías, se detiene la tarea por violación de contrato y principios arquitectónicos. |
| **Quality Gates** | Gate A (Documental), Gate B (Construcción/Interacción), Gate C (Normalización UI), Gate D (Autovalidación), Gate E (Revisión UX transversal), Gate F (Figma). |

---

## 3. Entradas obligatorias y readiness

| Entrada | Disponible | Estado de lectura / Requisito |
|---|---|---|
| SPEC-010 y HU-010 | Sí | Esquema por tipo, obligatoriedad, límite operativo y versionado |
| WF-010 y FLOW-010 | Sí | Flujo de S01 a S07, switches de obligatoriedad y desasociación con Catálogo |
| OpenAPI 0.5.0 | Sí | Endpoints `/tipos-producto/*` y modelos de asociación confirmados |
| Design System y UX | Sí | Tokens, componentes DS-C y lineamientos UXD-001/002/003/005/007/008/011 vigentes |
| Component Spec | Sí | Redactado en [component-spec.md](component-spec.md) con 7 vistas inventariadas |

---

## 4. Objetivo constructivo y orden de desarrollo

La pantalla ancla es **MK-010-S03 (Configuración y detalle del esquema del tipo de producto)**, ya que concentra el núcleo funcional de la funcionalidad: visualización de características asociadas, switches de obligatoriedad, versión del esquema y puntos de entrada a asociación y desasociación.

| Orden | Pantalla | Dependencia | Salida constructiva |
|---|---|---|---|
| 1 | `MK-010-S01` | Fixtures `FX-010-01` | Listado general de tipos de producto con conteo y versión de esquema |
| 2 | `MK-010-S02` | S01 | Formulario ligero de alta de tipo de producto |
| 3 | `MK-010-S03` | Fixtures `FX-010-02`, componente `C01` | Pantalla ancla: tabla de características, switches de obligatoriedad y barra de límites |
| 4 | `MK-010-S04` | S03, componente `C02`, `FX-010-03/04` | Modal de asociación con selector de características activas y control de tope |
| 5 | `MK-010-S05` | S03, componente `C03`, `FX-010-05/06` | Diálogo de desasociación segura con verificación asíncrona de impacto |
| 6 | `MK-010-S06` y `S07` | S01, `FX-010-07` | Diálogos de desactivación coordinada y reactivación de tipo |

---

## 5. Estrategia técnica de implementación

1. **Fixtures tipados:** Implementar `FX-010-01` a `FX-010-07` con esquemas de tipos de producto, características activas disponibles y respuestas 202/409 de desasociación.
2. **Rutas directas del prototipo:** Registrar en el router `/MK010/S01`, `/MK010/S02`, `/MK010/S03`, `/MK010/S04`, `/MK010/S05`, `/MK010/S06`, `/MK010/S07`, permitiendo inspección determinista con `?fixture=`.
3. **Componentes locales:** Diseñar `TablaEsquemaCaracteristicas` con switches accesibles y `ModalAsociarCaracteristica` con filtrado dinámico.
4. **Normalización Mantine:** Aplicar estrictamente tokens de color corporativo, tipografía y componentes DS-C.
5. **Autovalidación y revisión UX:** Ejecutar autovalidación sobre los 8 criterios de cobertura HU-010 y solicitar revisión transversal a Leonardo Vera.

---

## 6. Riesgos y mitigación

| Riesgo identificado | Estrategia de mitigación |
|---|---|
| Confusión entre tipo de producto y categorías | Separar radicalmente la navegación y explicitar en el copy que los esquemas pertenecen al tipo. |
| Superación del límite máximo de características | Barra de progreso visual y deshabilitación estricta del botón de asociación al alcanzar el tope. |
| Desasociación que destruye datos de productos | Modal S05 aclara que la operación verifica impacto y rechaza si hay productos con valores poblados. |
| Inclusión de controles de ordenamiento no contratados | Omitir deliberadamente flechas de subir/bajar o drag & drop en la tabla de características. |

---

## 7. Fases y Quality Gates

* **Gate A — Preparación:** Component spec, plan y tasks aprobados; fuentes consolidadas.
* **Gate B — Construcción:** 7 vistas implementadas en `prototipo/src/pantallas/MK010/`.
* **Gate C — Normalización:** Cumplimiento de tokens Mantine, accesibilidad de switches y viewport 1440 px.
* **Gate D — Autovalidación:** Owner verifica 8 criterios HU-010 y registra evidencias.
* **Gate E — Revisión UX transversal:** Visto bueno de Leonardo Vera (`APROBADO PARA FIGMA`).
* **Gate F — Figma y Cierre:** Fidelidad validada y `validation-report.md` emitido.
