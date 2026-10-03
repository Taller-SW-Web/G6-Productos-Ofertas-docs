# MK-009 — Tareas de construcción y verificación

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
| MK-009-T01 · TODO | SPEC-009, HU-009, WF-009, FLOW-009 | Verificar trazabilidad de fuentes y consistencia con OpenAPI 0.5.0 | Registro de versiones revisadas y sin contradicciones | Los 8 criterios de cobertura y operaciones `/caracteristicas/*` identificados |
| MK-009-T02 · TODO | Component spec y plan | Validar inventario de 8 pantallas y 3 componentes locales | Documentación lista para ejecución | Consistencia entre nombres de vistas, rutas y DTOs |
| MK-009-T03 · TODO | `mockups/prototipo/README.md` | Configurar o verificar entorno de ejecución del prototipo y enrutador | Estructura para `/pantallas/MK009/` y rutas declaradas | El servidor del prototipo compila y resuelve rutas de prueba |
| MK-009-T04 · TODO | Spec §10 | Implementar fixtures tipados `FX-009-01` a `FX-009-07` | Archivo de fixtures con características y valores | Datos mock accesibles sin llamadas de red externa |
| MK-009-T05 · TODO | Plan §4 | Declarar rutas directas `/MK009/S01` a `/MK009/S06` en enrutador | Rutas registradas y accesibles por URL directa | Carga de pantallas con fallback ante ausencia de fixture |

---

## 3. Construcción de pantallas y componentes locales

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-009-T10 · TODO | S01, FX-009-01, DS-C17/C18 | Construir pantalla ancla S01 con listado paginado y filtros por tipo | Tabla de características con badges de tipo (`TEXTO`, `NUMERO`, `LISTA`) | Paginación funcional; filtro por tipo y estado operativo |
| MK-009-T11 · TODO | S02, C01, DS-C03/C04/C06 | Implementar formulario de creación S02 con revelación progresiva | Campos condicionales revelados según el tipo seleccionado | `NUMERO` exige unidad obligatoria; `LISTA` anticipa carga de valores |
| MK-009-T12 · TODO | S03, C01, FX-009-03 | Construir formulario de edición S03 con inmutabilidad de tipo | Formulario con tipo bloqueado/solo lectura y edición de unidad/nombre | No es posible alterar el tipo de dato de una característica existente |
| MK-009-T13 · TODO | S04, C02, FX-009-04 | Construir gestión de valores S04 con contador de límite de 50 activos | Tabla de valores con alta, renombrado y contador `X / 50 activos` | Renombrado conserva ID; bloqueo visual al alcanzar 50 valores |
| MK-009-T14 · TODO | S04-P, S04-R, C03, FX-009-05/06 | Implementar baja segura de valor con estados S04-P (202) y S04-R (Rechazo) | Flujo de baja de valor con verificación asíncrona de impacto | S04-P muestra `Comprobando uso`; S04-R explica rechazo por productos en uso |
| MK-009-T15 · TODO | S05, FX-009-07, DS-C21 | Construir diálogo de cambio de estado de característica S05 | Modal de desactivación/reactivación con aviso de impacto | Explica que las inactivas no se ofrecen para nuevas asociaciones |
| MK-009-T16 · TODO | S06, FX-009-01/04, DS-C19 | Construir vista de detalle S06 | Ficha técnica de característica con tipo, unidad y catálogo de valores | Muestra metadatos completos y enlaces hacia edición y valores |

---

## 4. Normalización UI y accesibilidad

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-009-T20 · TODO | DESIGN.md §§4–11 | Normalizar componentes con tokens de Mantine y tema corporativo | Estilos visuales consistentes con escala tipográfica y espaciados | Cero estilos inline o hacks; uso exclusivo de clases y variables DS |
| MK-009-T21 · TODO | Viewport 1440 px | Verificar ergonomía visual y ausencia de scroll horizontal involuntario | Layout responsive desktop limpio a 1440 × 900 px | Inspección visual en navegador sin desbordamientos |
| MK-009-T22 · TODO | UXG-020, UXG-021 | Auditar accesibilidad: navegación por teclado, focus trap y contraste | Modales y tablas navegables con Tab/Enter/Escape | Focus trap en modales; etiquetas accesibles en campos condicionales |

---

## 5. Autovalidación y revisión transversal

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-009-T30 · TODO | Criterios CA-01 a CA-11 | Ejecutar batería de pruebas de usabilidad sobre las 8 pantallas | Registro de cumplimiento punto por punto | Los 8 criterios de HU-009 satisfechos en el prototipo |
| MK-009-T31 · TODO | T30 | Capturar evidencias visuales de cada pantalla y estado de error | Capturas organizadas en carpeta de evidencias | Imágenes verificables de S01, S02, S03, S04, S04P, S04R, S05, S06 |
| MK-009-T32 · TODO | T31 | Completar autovalidación de Leonardo Lopez en `validation-report.md` | Reporte de autovalidación con matriz de trazabilidad | Cero bloqueantes; solicitud formal de revisión UX enviada |
| MK-009-T33 · TODO | T32 | Someter prototipo a revisión UX transversal de Leonardo Vera Rodríguez | Visto bueno formal registrado: `APROBADO PARA FIGMA` | Dictamen de UX sin observaciones pendientes |
| MK-009-T34 · TODO | T33 | Trasladar diseño validado a Figma y verificar fidelidad visual | Frames en Figma y enlace público registrado | Coincidencia 100% de componentes, textos y jerarquía con el prototipo |
| MK-009-T35 · TODO | T34 | Cerrar `validation-report.md` con estado final APROBADO | Reporte formal cerrado con firmas y enlaces trazables | Entregable MK-009 listo para consolidación en master |
