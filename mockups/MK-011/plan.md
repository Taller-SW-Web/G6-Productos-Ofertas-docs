# MK-011 — Plan de construcción

## 1. Identificación

**Funcionalidad:** Gestión de marcas.  
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
| **Entradas obligatorias** | [SPEC-011](../../specs/SPEC-011-gestion-marcas.md), [HU-011](../../hu/HU-011-gestion-marcas.md), [WF-011](../../wireframes/flows/WF-011-gestion-marcas.md), [FLOW-011](../../flujos/FLOW-011-gestion-marcas.md), [OpenAPI 0.5.0](../../api/openapi.yaml), [AsyncAPI](../../asyncapi/asyncapi.yaml), [Propuesta UX](../ux/propuesta-ux.md), [UX Decisions](../ux/ux-decisions.md), [UX Guidelines](../ux/ux-guidelines.md), [Design System](../DESIGN.md) v1.0.0. |
| **Salidas esperadas** | Ocho pantallas directas (`MK-011-S01` a `S05`, con `S04P`, `S04B`, `S04E`), componentes locales `MK-011-C01..C03`, fixtures tipados `FX-011-01..07`, autovalidación de Leonardo Lopez, revisión UX de Leonardo Vera y traslado fiel a Figma. |
| **Restricciones técnicas** | Web Desktop (1440 px), React + TypeScript + Mantine, formulario directo sin wizard (UX-P02 no aplicable), nombres únicos globales, logo máx. 5 MB (PNG/JPG/WebP), país ISO 3166-1. |
| **Condición de parada** | Si se introduce un wizard multietapa o eventos inventados de mensajería para marcas, se detiene la tarea por incumplimiento normativo de UX y contratos. |
| **Quality Gates** | Gate A (Documental), Gate B (Construcción/Interacción), Gate C (Normalización UI), Gate D (Autovalidación), Gate E (Revisión UX transversal), Gate F (Figma). |

---

## 3. Entradas obligatorias y readiness

| Entrada | Disponible | Estado de lectura / Requisito |
|---|---|---|
| SPEC-011 y HU-011 | Sí | Unicidad de nombre, formatos/tamaño de archivo, selector de país ISO y baja segura |
| WF-011 y FLOW-011 | Sí | Flujo de S01 a S05 con estados de baja y formulario directo |
| OpenAPI 0.5.0 | Sí | Endpoints `/marcas/*` y DTOs confirmados |
| Design System y UX | Sí | Tokens, componentes DS-C y lineamientos UXD-001/002/003/005/008/011 vigentes |
| Component Spec | Sí | Redactado en [component-spec.md](component-spec.md) con 8 vistas inventariadas |

---

## 4. Objetivo constructivo y orden de desarrollo

La pantalla ancla es **MK-011-S01 (Listado administrativo de marcas)**, ya que establece la vista de tabla con logotipos, estados de marca, buscador y acciones hacia creación, edición, detalle y baja.

| Orden | Pantalla | Dependencia | Salida constructiva |
|---|---|---|---|
| 1 | `MK-011-S01` | Fixtures `FX-011-01` | Pantalla ancla: tabla con logotipos, nombres, países, estados y acciones |
| 2 | `MK-011-S02` | S01, componentes `C01`, `C02` | Formulario directo de creación (sin wizard) con validación de peso y país ISO |
| 3 | `MK-011-S03` | S01, componentes `C01`, `C02` | Formulario de edición con precarga de datos y reemplazo opcional de logo |
| 4 | `MK-011-S04`, `S04-P`, `S04-B`, `S04-E` | S01, componente `C03` | Diálogo de baja con estados transitorios 202, rechazo por productos y error de red |
| 5 | `MK-011-S05` | S01 | Ficha técnica de detalle con logo en alta resolución y reactivación |

---

## 5. Estrategia técnica de implementación

1. **Fixtures tipados:** Implementar `FX-011-01` a `FX-011-07` con marcas de prueba, respuestas de error de duplicado (409) y respuestas del protocolo de baja.
2. **Rutas directas del prototipo:** Registrar en el router `/MK011/S01`, `/MK011/S02`, `/MK011/S03`, `/MK011/S04`, `/MK011/S04P`, `/MK011/S04B`, `/MK011/S04E`, `/MK011/S05`, permitiendo acceso determinista con `?fixture=`.
3. **Componentes locales:** Diseñar `SelectorPaisIso` con catálogo normalizado y `FileUploadLogo` con validación de tipo MIME y peso en cliente.
4. **Normalización Mantine:** Aplicar estrictamente tokens corporativos, tipografía y componentes compartidos del Design System.
5. **Autovalidación y revisión UX:** Ejecutar autovalidación sobre los 8 criterios de cobertura HU-011 y solicitar revisión transversal a Leonardo Vera.

---

## 6. Riesgos y mitigación

| Riesgo identificado | Estrategia de mitigación |
|---|---|
| Implementación innecesaria de wizard | Mantener formulario directo en S02 según directriz UX-P02 para marcas. |
| Nombres duplicados con marcas inactivas | Mensaje de error explícito indicando que la unicidad incluye marcas inactivas. |
| Carga de archivos no soportados o pesados | Validación en el cliente con mensaje inmediato antes de intentar el envío. |
| Pérdida de estado activo ante error de red | Mantener el estado previo intacto (UX-P03) en caso de fallo no concluyente en S04-E. |

---

## 7. Fases y Quality Gates

* **Gate A — Preparación:** Component spec, plan y tasks aprobados; fuentes consolidadas.
* **Gate B — Construcción:** 8 vistas implementadas en `prototipo/src/pantallas/MK011/`.
* **Gate C — Normalización:** Cumplimiento de tokens Mantine, accesibilidad de formularios y viewport 1440 px.
* **Gate D — Autovalidación:** Owner verifica 8 criterios HU-011 y registra evidencias.
* **Gate E — Revisión UX transversal:** Visto bueno de Leonardo Vera (`APROBADO PARA FIGMA`).
* **Gate F — Figma y Cierre:** Fidelidad validada y `validation-report.md` emitido.
