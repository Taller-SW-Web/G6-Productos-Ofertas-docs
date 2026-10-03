# MK-008 — Plan de construcción

## 1. Identificación

**Funcionalidad:** Gestión de categorías y subcategorías.  
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
| **Entradas obligatorias** | [SPEC-008](../../specs/SPEC-008-gestion-categorias.md), [HU-008](../../hu/HU-008-gestion-categorias.md), [WF-008](../../wireframes/flows/WF-008-gestion-categorias.md), [FLOW-008](../../flujos/FLOW-008-gestion-categorias.md), [OpenAPI 0.5.0](../../api/openapi.yaml), [AsyncAPI](../../asyncapi/asyncapi.yaml), [Propuesta UX](../ux/propuesta-ux.md), [UX Decisions](../ux/ux-decisions.md), [UX Guidelines](../ux/ux-guidelines.md), [Design System](../DESIGN.md) v1.0.0. |
| **Salidas esperadas** | Nueve pantallas directas (`MK-008-S01` a `S05R`), componentes locales `MK-008-C01..C04`, fixtures tipados `FX-008-01..07`, autovalidación del owner, revisión UX de Leonardo Vera y traslado fiel a Figma. |
| **Restricciones técnicas** | Prototipado Web Desktop (1440 px), React + TypeScript + Mantine, apego estricto a tokens de DESIGN.md. No inventar endpoints ni roles de usuario. Las categorías no tocan atributos ni características de producto. |
| **Condición de parada** | Ante discrepancia entre la SPEC y el contrato OpenAPI sobre el payload de creación o slug, se detiene la tarea afectada y se escala según gobernanza; no se inventan campos en el prototipo. |
| **Quality Gates** | Gate A (Documental), Gate B (Construcción/Interacción), Gate C (Normalización UI), Gate D (Autovalidación), Gate E (Revisión UX transversal), Gate F (Figma). |

---

## 3. Entradas obligatorias y readiness

| Entrada | Disponible | Estado de lectura / Requisito |
|---|---|---|
| SPEC-008 y HU-008 | Sí | Regla recursiva, `MAX_CATEGORY_DEPTH=2`, resolución previa de slug obligatoria |
| WF-008 y FLOW-008 | Sí | Flujo de S01 a S05R con interacción de diálogo de slug y dependencias asíncronas |
| OpenAPI 0.5.0 | Sí | Endpoints `/categorias`, `/categorias/arbol` y `/seo/categorias/slug/resolver` confirmados |
| Design System y UX | Sí | Tokens, componentes DS-C y lineamientos UXD-001/005/007/008/009/011 vigentes |
| Component Spec | Sí | Redactado en [component-spec.md](component-spec.md) con 9 vistas inventariadas |

---

## 4. Objetivo constructivo y orden de desarrollo

La pantalla ancla es **MK-008-S01 (Árbol y listado jerárquico)**, ya que establece el layout de navegación, el estado del catálogo, la carga de datos y las acciones disparadoras hacia creación, edición y baja.

| Orden | Pantalla | Dependencia | Salida constructiva |
|---|---|---|---|
| 1 | `MK-008-S01` | Fixtures de árbol `FX-008-01` | Pantalla ancla: árbol renderizado, nodos hijos indentados, selector de estado y acciones |
| 2 | `MK-008-S02` y `S02-C` | S01 y endpoint de resolución de slug | Formulario de alta + modal de confirmación con URL y manejo de colisiones |
| 3 | `MK-008-S03` | S01 y selector padre | Formulario de edición con validación de profundidad máxima y prevención de ciclos |
| 4 | `MK-008-S04`, `S04-P`, `S04-B` | S01 y simulación de baja 202 | Diálogo de solicitud de desactivación, vista transitoria 202 y feedback de rechazo |
| 5 | `MK-008-S05` y `S05-R` | S01 | Detalle completo de categoría y validación de reactivación condicionada al padre |

---

## 5. Estrategia técnica de implementación

1. **Fixtures tipados:** Implementar `FX-008-01` a `FX-008-07` en el módulo de prototipado sin depender de red real, cubriendo árbol de 2 niveles, resolución con y sin colisión, carrera 409 y respuestas 202/409 de baja.
2. **Rutas directas del prototipo:** Registrar en el enrutador `/MK008/S01`, `/MK008/S02`, `/MK008/S02C`, `/MK008/S03`, `/MK008/S04`, `/MK008/S04P`, `/MK008/S04B`, `/MK008/S05`, `/MK008/S05R`, accesibles directamente con parámetro `?fixture=` para revisión independiente.
3. **Componentes locales:** Construir `ArbolCategorias` accesible con roles WAI-ARIA, `SelectorPadreJerarquico` con restricción de nivel y `ConfirmacionSlugModal` con visualización destacada de sufijos.
4. **Normalización Mantine:** Asegurar uso de tokens de espaciado, colores del tema corporativo y tipografía según `DESIGN.md`.
5. **Autovalidación y revisión UX:** Completar autovalidación de Leonardo Lopez y solicitar revisión a Leonardo Vera Rodríguez para obtener visto bueno previo a Figma.

---

## 6. Riesgos y mitigación

| Riesgo identificado | Estrategia de mitigación |
|---|---|
| Creación de subcategorías con más de 2 niveles | El selector desactiva categorías de nivel 2 y muestra aviso `LUX-08-01`. |
| Slug persistido sin confirmación del gestor | El botón de confirmación en S02-C es el único emisor del request `POST /categorias` con `slugConfirmado`. |
| Carrera concurrente en slug genera inconsistencia | Manejar respuesta `409` re-invocando el resolver de SEO y volviendo a pedir confirmación en S02-C. |
| Falsa sensación de borrado inmediato en baja | El botón de baja dispara mensaje 202 `Verificando dependencias`, aclarando que la desactivación depende de Catálogo. |

---

## 7. Fases y Quality Gates

* **Gate A — Preparación:** Component spec, plan y tasks aprobados; fuentes consolidadas.
* **Gate B — Construcción:** 9 vistas implementadas en `prototipo/src/pantallas/MK008/` con fixtures.
* **Gate C — Normalización:** Cumplimiento de tokens Mantine, accesibilidad de árbol y viewport 1440 px.
* **Gate D — Autovalidación:** Owner verifica 8 criterios HU-008 y genera evidencias.
* **Gate E — Revisión UX transversal:** Visto bueno de Leonardo Vera (`APROBADO PARA FIGMA`).
* **Gate F — Figma y Cierre:** Fidelidad validada y `validation-report.md` emitido.
