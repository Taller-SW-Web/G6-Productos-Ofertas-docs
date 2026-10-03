# MK-012 — Plan de construcción

## 1. Identificación

**Funcionalidad:** Gestión de SEO y metadatos.  
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
| **Entradas obligatorias** | [SPEC-012](../../specs/SPEC-012-seo-metadatos.md), [HU-012](../../hu/HU-012-seo-metadatos.md), [WF-012](../../wireframes/flows/WF-012-seo-metadatos.md), [FLOW-012](../../flujos/FLOW-012-seo-metadatos.md), [OpenAPI 0.5.0](../../api/openapi.yaml), [Contrato API](../../Contrato_Api.md), [Propuesta UX](../ux/propuesta-ux.md), [UX Decisions](../ux/ux-decisions.md), [UX Guidelines](../ux/ux-guidelines.md), [Design System](../DESIGN.md) v1.0.0. |
| **Salidas esperadas** | Tres pantallas directas (`MK-012-S01` a `S03`), componentes locales `MK-012-C01..C03`, fixtures tipados `FX-012-01..06`, autovalidación de Leonardo Lopez, revisión UX de Leonardo Vera y traslado fiel a Figma. |
| **Restricciones técnicas** | Web Desktop (1440 px), React + TypeScript + Mantine, contadores 70/160 son advertencias (no bloqueos), sin simulador de endpoint 301 en backoffice, vista previa SERP reactiva. |
| **Condición de parada** | Si se introduce un simulador de endpoint 301 o validaciones bloqueantes para textos de más de 70/160 caracteres, se detiene la tarea por violación del contrato funcional. |
| **Quality Gates** | Gate A (Documental), Gate B (Construcción/Interacción), Gate C (Normalización UI), Gate D (Autovalidación), Gate E (Revisión UX transversal), Gate F (Figma). |

---

## 3. Entradas obligatorias y readiness

| Entrada | Disponible | Estado de lectura / Requisito |
|---|---|---|
| SPEC-012 y HU-012 | Sí | Normalización de slug, contadores no bloqueantes e historial 301 |
| WF-012 y FLOW-012 | Sí | Flujo de S01 a S03, preview SERP y exclusión de simulador 301 |
| OpenAPI 0.5.0 | Sí | Endpoints `/categorias/{id}/seo*` y `/seo/categorias/slug/resolver` confirmados |
| Design System y UX | Sí | Tokens, componentes DS-C y lineamientos UXD-001/002/003/005/007/012 vigentes |
| Component Spec | Sí | Redactado en [component-spec.md](component-spec.md) con 3 vistas inventariadas |

---

## 4. Objetivo constructivo y orden de desarrollo

La pantalla ancla es **MK-012-S02 (Configuración y edición de SEO de categoría)**, ya que concentra la interactividad de mayor valor y complejidad: contadores dinámicos de caracteres, cálculo reactivo del snippet SERP de Google y regeneración asistida de slug con pre-resolución SEO.

| Orden | Pantalla | Dependencia | Salida constructiva |
|---|---|---|---|
| 1 | `MK-012-S01` | Fixtures `FX-012-01` | Listado general de categorías con estado de optimización SEO y acciones |
| 2 | `MK-012-S02` | S01, componentes `C01`, `C02`, `FX-012-02/03/04` | Pantalla ancla: formulario con slug, meta-título, meta-descripción, contadores 70/160 y preview SERP |
| 3 | `MK-012-S03` | S02, componente `C03`, `FX-012-05/06` | Historial de redirecciones con flechas de trazabilidad y copy normativo sobre el 301 |

---

## 5. Estrategia técnica de implementación

1. **Fixtures tipados:** Implementar `FX-012-01` a `FX-012-06` con metadatos completos, textos que sobrepasen recomendaciones para probar advertencias, regeneración de slug y tablas de historial.
2. **Rutas directas del prototipo:** Registrar en el router `/MK012/S01`, `/MK012/S02`, `/MK012/S03`, permitiendo acceso determinista con `?fixture=`.
3. **Componentes locales:** Diseñar `ContadorCaracteres` con feedback visual suave, `VistaPreviaSerpGoogle` reactiva y `TablaHistorialRedirecciones`.
4. **Normalización Mantine:** Aplicar estrictamente tokens corporativos, tipografía y componentes compartidos del Design System.
5. **Autovalidación y revisión UX:** Ejecutar autovalidación sobre los 8 criterios de cobertura HU-012 y solicitar revisión transversal a Leonardo Vera.

---

## 6. Riesgos y mitigación

| Riesgo identificado | Estrategia de mitigación |
|---|---|
| Bloqueo involuntario de guardado por textos largos | Diseñar los contadores con estilos de advertencia (color ámbar) sin deshabilitar el botón de submit. |
| Inclusión de simulador de endpoint 301 en backoffice | Excluir explícitamente cualquier herramienta o botón de prueba 301; remitir al historial informativo. |
| Modificación no deseada de URL pública | Modal de confirmación en S02 advirtiendo que el cambio de slug creará una redirección 301. |
| Falsa creencia de regeneración síncrona destructiva | Botón de regenerar muestra propuesta en badge y requiere confirmación previa al reemplazo. |

---

## 7. Fases y Quality Gates

* **Gate A — Preparación:** Component spec, plan y tasks aprobados; fuentes consolidadas.
* **Gate B — Construcción:** 3 vistas implementadas en `prototipo/src/pantallas/MK012/`.
* **Gate C — Normalización:** Cumplimiento de tokens Mantine, accesibilidad de contadores y viewport 1440 px.
* **Gate D — Autovalidación:** Owner verifica 8 criterios HU-012 y registra evidencias.
* **Gate E — Revisión UX transversal:** Visto bueno de Leonardo Vera (`APROBADO PARA FIGMA`).
* **Gate F — Figma y Cierre:** Fidelidad validada y `validation-report.md` emitido.
