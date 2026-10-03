# MK-010 — Tareas de construcción y verificación

## 1. Control de ejecución

**Owner:** Leonardo Lopez (`lopez`).  
**Rama:** `lopez`.  
**Coordinación:** Issue #61 (mockups transversales).  
**Versión:** 1.0.0, 2026-10-03.  
**Estado general:** Planificación en revisión; prototipo no iniciado.  
**Entradas rectoras:** [component-spec.md](component-spec.md) y [plan.md](plan.md).  
**Prioridad:** P0 (obligatorio para entrega del hito).  
**Estados permitidos:** `TODO`, `DOING`, `BLOCKED`, `REVIEW`, `DONE`.

---

## 2. Preparación y configuración inicial

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-010-T01 · TODO | SPEC-010, HU-010, WF-010, FLOW-010 | Verificar trazabilidad de fuentes y consistencia con OpenAPI 0.5.0 | Registro de versiones revisadas y sin contradicciones | Los 8 criterios de cobertura y operaciones `/tipos-producto/*` identificados |
| MK-010-T02 · TODO | Component spec y plan | Validar inventario de 7 pantallas y 3 componentes locales | Documentación lista para ejecución | Consistencia entre nombres de vistas, rutas y DTOs |
| MK-010-T03 · TODO | `mockups/prototipo/README.md` | Configurar o verificar entorno de ejecución del prototipo y enrutador | Estructura para `/pantallas/MK010/` y rutas declaradas | El servidor del prototipo compila y resuelve rutas de prueba |
| MK-010-T04 · TODO | Spec §10 | Implementar fixtures tipados `FX-010-01` a `FX-010-07` | Archivo de fixtures con esquemas y respuestas simuladas | Datos mock accesibles sin llamadas de red externa |
| MK-010-T05 · TODO | Plan §4 | Declarar rutas directas `/MK010/S01` a `/MK010/S07` en enrutador | Rutas registradas y accesibles por URL directa | Carga de pantallas con fallback ante ausencia de fixture |

---

## 3. Construcción de pantallas y componentes locales

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-010-T10 · TODO | S01, FX-010-01, DS-C17 | Construir listado general S01 con conteo de características y versión de esquema | Tabla de tipos de producto con estado y accesos directos a configuración | Badges de versión visibles; botón de configuración navegable a S03 |
| MK-010-T11 · TODO | S02, DS-C01/C03 | Implementar formulario ligero de creación S02 | Formulario simple de nombre con redirección post-creación a S03 | Valida nombre obligatorio y deriva a S03 con feedback de éxito |
| MK-010-T12 · TODO | S03, C01, FX-010-02, DS-C10 | Construir pantalla ancla S03 con tabla de esquema y switches de obligatoriedad | Ficha de tipo con características asociadas y toggle obligatoria | Switches actualizan versión de esquema y muestran toast con deshacer |
| MK-010-T13 · TODO | S03, S04, C02, FX-010-03/04 | Implementar modal de asociación S04 con control de límite de características | Modal con selector de características maestras activas y contador X/N | Bloquea la acción cuando se alcanza el límite máximo permitido |
| MK-010-T14 · TODO | S05, C03, FX-010-05/06 | Implementar diálogo de desasociación segura S05 con estados transitorios | Diálogo que informa verificación con Catálogo y maneja rechazo | Muestra feedback 202 y alerta descriptiva si hay productos en uso |
| MK-010-T15 · TODO | S06, FX-010-07, DS-C21 | Construir diálogo de desactivación de tipo de producto S06 | Modal de confirmación de baja lógica con advertencia de impacto | No desactiva si existen productos activos vinculados |
| MK-010-T16 · TODO | S07, DS-C21 | Construir confirmación de reactivación de tipo de producto S07 | Modal de reactivación síncrona | Reactiva el tipo y lo vuelve a habilitar para nuevos productos |

---

## 4. Normalización UI y accesibilidad

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-010-T20 · TODO | DESIGN.md §§4–11 | Normalizar componentes con tokens de Mantine y tema corporativo | Estilos visuales consistentes con escala tipográfica y espaciados | Cero estilos inline o hacks; uso exclusivo de clases y variables DS |
| MK-010-T21 · TODO | Viewport 1440 px | Verificar ergonomía visual y ausencia de scroll horizontal involuntario | Layout responsive desktop limpio a 1440 × 900 px | Inspección visual en navegador sin desbordamientos |
| MK-010-T22 · TODO | UXG-020, UXG-021 | Auditar accesibilidad: navegación por teclado, switches y modales | Controles accesibles (`aria-checked` en switches, focus trap) | Tab/Shift+Tab funcional en modales; lectores anuncian estado de switch |

---

## 5. Autovalidación y revisión transversal

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-010-T30 · TODO | Criterios CA-01 a CA-08 | Ejecutar batería de pruebas de usabilidad sobre las 7 pantallas | Registro de cumplimiento punto por punto | Los 8 criterios de HU-010 satisfechos en el prototipo |
| MK-010-T31 · TODO | T30 | Capturar evidencias visuales de cada pantalla y estado de error | Capturas organizadas en carpeta de evidencias | Imágenes verificables de S01, S02, S03, S04, S05, S06, S07 |
| MK-010-T32 · TODO | T31 | Completar autovalidación de Leonardo Lopez en `validation-report.md` | Reporte de autovalidación con matriz de trazabilidad | Cero bloqueantes; solicitud formal de revisión UX enviada |
| MK-010-T33 · TODO | T32 | Someter prototipo a revisión UX transversal de Leonardo Vera Rodríguez | Visto bueno formal registrado: `APROBADO PARA FIGMA` | Dictamen de UX sin observaciones pendientes |
| MK-010-T34 · TODO | T33 | Trasladar diseño validado a Figma y verificar fidelidad visual | Frames en Figma y enlace público registrado | Coincidencia 100% de componentes, textos y jerarquía con el prototipo |
| MK-010-T35 · TODO | T34 | Cerrar `validation-report.md` con estado final APROBADO | Reporte formal cerrado con firmas y enlaces trazables | Entregable MK-010 listo para consolidación en master |
