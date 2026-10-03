# MK-008 — Tareas de construcción y verificación

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
| MK-008-T01 · TODO | SPEC-008, HU-008, WF-008, FLOW-008 | Verificar trazabilidad de fuentes y consistencia con OpenAPI 0.5.0 | Registro de versiones revisadas y sin contradicciones | Los 8 criterios de aceptación y operaciones `/categorias/*` identificados |
| MK-008-T02 · TODO | Component spec y plan | Validar inventario de 9 pantallas y 4 componentes locales | Documentación lista para ejecución | Consistencia entre nombres de pantallas, rutas y DTOs |
| MK-008-T03 · TODO | `mockups/prototipo/README.md` | Configurar o verificar entorno de ejecución del prototipo y enrutador | Estructura para `/pantallas/MK008/` y rutas declaradas | El servidor del prototipo compila y resuelve rutas de prueba |
| MK-008-T04 · TODO | Spec §10 | Implementar fixtures tipados `FX-008-01` a `FX-008-07` | Archivo de fixtures con árbol de categorías y respuestas SEO | Datos mock accesibles sin llamadas de red externa |
| MK-008-T05 · TODO | Plan §4 | Declarar rutas directas `/MK008/S01` a `/MK008/S05R` en enrutador | Rutas registradas y accesibles por URL directa | Carga de pantallas con fallback ante ausencia de fixture |

---

## 3. Construcción de pantallas y componentes locales

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-008-T10 · TODO | S01, FX-008-01, DS-C17 | Construir pantalla ancla S01 con árbol jerárquico (`MK-008-C01`) | Vista de árbol con 2 niveles, badges de estado y botones de acción | Expandir/colapsar nodos funciona; visualización clara de jerarquía |
| MK-008-T11 · TODO | S02, C02, DS-C03/C05/C06 | Implementar formulario de creación S02 con selector padre restringido | Formulario con validación de campos obligatorios y orden | No permite seleccionar subcategorías como padre (máx 2 niveles) |
| MK-008-T12 · TODO | S02-C, FX-008-02/03, C03 | Construir modal de confirmación de slug S02-C con preview de URL | Diálogo modal que resalta sufijo si `colisionResuelta: true` | URL `/categoria/{slug}` visible; botones Confirmar y Volver funcionales |
| MK-008-T13 · TODO | S02-C, FX-008-04 | Implementar manejo de carrera concurrente (409) en confirmación de slug | Mensaje de advertencia, re-resolución a nuevo slug y nueva confirmación | No se persiste slug sin confirmación del usuario |
| MK-008-T14 · TODO | S03, C02, DS-C03/C05/C06 | Construir formulario de edición S03 con prevención de ciclos | Formulario precargado con datos de categoría y padre editable | Deshabilita la categoría actual y sus hijas como opciones de padre |
| MK-008-T15 · TODO | S04, S04-P, C04, DS-C21/C22 | Construir diálogo de baja S04 y vista transitoria S04-P (202 Accepted) | Flujo de baja segura con aviso de verificación con Catálogo | S04-P muestra "Verificando dependencias en productos" sin timeout ficticio |
| MK-008-T16 · TODO | S04-B, FX-008-06, DS-C22 | Implementar estado de baja rechazada S04-B | Diálogo de rechazo con conteo de productos asociados | Explica claramente el motivo del bloqueo sin alterar el estado activo |
| MK-008-T17 · TODO | S05, S05-R, FX-008-07, DS-C19 | Construir vista de detalle S05 y validación de reactivación S05-R | Ficha técnica de categoría y bloqueo de reactivación si padre inactivo | Botón de reactivar deshabilitado con alerta contextual explicativa |

---

## 4. Normalización UI y accesibilidad

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-008-T20 · TODO | DESIGN.md §§4–11 | Normalizar componentes con tokens de Mantine y tema corporativo | Estilos visuales consistentes con escala tipográfica y espaciados | Cero estilos inline o hacks; uso exclusivo de clases y variables DS |
| MK-008-T21 · TODO | Viewport 1440 px | Verificar ergonomía visual y ausencia de scroll horizontal involuntario | Layout responsive desktop limpio a 1440 × 900 px | Inspección visual en navegador sin desbordamientos |
| MK-008-T22 · TODO | UXG-020, UXG-021 | Auditar accesibilidad: navegación por teclado, focus trap y contraste | Modales y árbol navegables con Tab/Enter/Escape | Focus trap en modales; `aria-expanded` en nodos de árbol |

---

## 5. Autovalidación y revisión transversal

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-008-T30 · TODO | Criterios CA-01 a CA-08 | Ejecutar batería de pruebas de usabilidad sobre las 9 pantallas | Registro de cumplimiento punto por punto | Los 8 criterios de HU-008 satisfechos en el prototipo |
| MK-008-T31 · TODO | T30 | Capturar evidencias visuales de cada pantalla y estado de error | Capturas organizadas en carpeta de evidencias | Imágenes verificables de S01, S02, S02C, S03, S04, S04P, S04B, S05, S05R |
| MK-008-T32 · TODO | T31 | Completar autovalidación de Leonardo Lopez en `validation-report.md` | Reporte de autovalidación con matriz de trazabilidad | Cero bloqueantes; solicitud formal de revisión UX enviada |
| MK-008-T33 · TODO | T32 | Someter prototipo a revisión UX transversal de Leonardo Vera Rodríguez | Visto bueno formal registrado: `APROBADO PARA FIGMA` | Dictamen de UX sin observaciones pendientes |
| MK-008-T34 · TODO | T33 | Trasladar diseño validado a Figma y verificar fidelidad visual | Frames en Figma y enlace público registrado | Coincidencia 100% de componentes, textos y jerarquía con el prototipo |
| MK-008-T35 · TODO | T34 | Cerrar `validation-report.md` con estado final APROBADO | Reporte formal cerrado con firmas y enlaces trazables | Entregable MK-008 listo para consolidación en master |
