# MK-011 — Tareas de construcción y verificación

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
| MK-011-T01 · TODO | SPEC-011, HU-011, WF-011, FLOW-011 | Verificar trazabilidad de fuentes y consistencia con OpenAPI 0.5.0 | Registro de versiones revisadas y sin contradicciones | Los 8 criterios de cobertura y operaciones `/marcas/*` identificados |
| MK-011-T02 · TODO | Component spec y plan | Validar inventario de 8 pantallas y 3 componentes locales | Documentación lista para ejecución | Consistencia entre nombres de vistas, rutas y DTOs |
| MK-011-T03 · TODO | `mockups/prototipo/README.md` | Configurar o verificar entorno de ejecución del prototipo y enrutador | Estructura para `/pantallas/MK011/` y rutas declaradas | El servidor del prototipo compila y resuelve rutas de prueba |
| MK-011-T04 · TODO | Spec §10 | Implementar fixtures tipados `FX-011-01` a `FX-011-07` | Archivo de fixtures con marcas y respuestas simuladas | Datos mock accesibles sin llamadas de red externa |
| MK-011-T05 · TODO | Plan §4 | Declarar rutas directas `/MK011/S01` a `/MK011/S05` en enrutador | Rutas registradas y accesibles por URL directa | Carga de pantallas con fallback ante ausencia de fixture |

---

## 3. Construcción de pantallas y componentes locales

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-011-T10 · TODO | S01, FX-011-01, DS-C17 | Construir listado general S01 con tabla administrativa y miniaturas | Tabla con logotipos, nombres, países, estados y acciones | Búsqueda por nombre y filtros por estado operativos |
| MK-011-T11 · TODO | S02, C01, C02, DS-C01/C03/C05 | Implementar formulario directo de creación S02 (sin wizard) | Formulario con nombre, descripción, selector ISO y upload de logo | Valida campos requeridos y formatos en cliente |
| MK-011-T12 · TODO | S02, FX-011-03, DS-C22 | Implementar validación y feedback de nombre duplicado (409) | Alerta que explica que el nombre ya existe (incluso inactivo) | Conserva datos del formulario y destaca campo de nombre |
| MK-011-T13 · TODO | S02, C02, FX-011-04 | Implementar control de subida de logo con validación de 5 MB | Control con preview y rechazo inmediato de archivos >5 MB | Muestra alerta en rojo y bloquea botón de guardar |
| MK-011-T14 · TODO | S03, C01, C02 | Construir formulario de edición S03 con precarga | Formulario precargado con datos actuales y reemplazo de logo | Permite actualizar metadatos conservando o cambiando logo |
| MK-011-T15 · TODO | S04, S04-P, S04-B, S04-E, C03 | Construir diálogo de baja S04 y estados de verificación | Secuencia visible: confirmación → verificando → resultado | S04-P no usa cronómetros irreales; S04-E preserva estado activo |
| MK-011-T16 · TODO | S05, FX-011-01, DS-C19 | Construir vista de detalle S05 y botón de reactivación | Ficha técnica con logo en alta resolución y reactivación síncrona | Reactivación exitosa actualiza badge a `ACTIVO` |

---

## 4. Normalización UI y accesibilidad

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-011-T20 · TODO | DESIGN.md §§4–11 | Normalizar componentes con tokens de Mantine y tema corporativo | Estilos visuales consistentes con escala tipográfica y espaciados | Cero estilos inline o hacks; uso exclusivo de clases y variables DS |
| MK-011-T21 · TODO | Viewport 1440 px | Verificar ergonomía visual y ausencia de scroll horizontal involuntario | Layout responsive desktop limpio a 1440 × 900 px | Inspección visual en navegador sin desbordamientos |
| MK-011-T22 · TODO | UXG-020, UXG-021 | Auditar accesibilidad: navegación por teclado, focus trap y contraste | Modales y formularios navegables con Tab/Enter/Escape | Focus trap en modales; textos descriptivos en controles de archivo |

---

## 5. Autovalidación y revisión transversal

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-011-T30 · TODO | Criterios CA-01 a CA-08 | Ejecutar batería de pruebas de usabilidad sobre las 8 pantallas | Registro de cumplimiento punto por punto | Los 8 criterios de HU-011 satisfechos en el prototipo |
| MK-011-T31 · TODO | T30 | Capturar evidencias visuales de cada pantalla y estado de error | Capturas organizadas en carpeta de evidencias | Imágenes verificables de S01, S02, S03, S04, S04P, S04B, S04E, S05 |
| MK-011-T32 · TODO | T31 | Completar autovalidación de Leonardo Lopez en `validation-report.md` | Reporte de autovalidación con matriz de trazabilidad | Cero bloqueantes; solicitud formal de revisión UX enviada |
| MK-011-T33 · TODO | T32 | Someter prototipo a revisión UX transversal de Leonardo Vera Rodríguez | Visto bueno formal registrado: `APROBADO PARA FIGMA` | Dictamen de UX sin observaciones pendientes |
| MK-011-T34 · TODO | T33 | Trasladar diseño validado a Figma y verificar fidelidad visual | Frames en Figma y enlace público registrado | Coincidencia 100% de componentes, textos y jerarquía con el prototipo |
| MK-011-T35 · TODO | T34 | Cerrar `validation-report.md` con estado final APROBADO | Reporte formal cerrado con firmas y enlaces trazables | Entregable MK-011 listo para consolidación en master |
