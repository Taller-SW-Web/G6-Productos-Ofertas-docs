# MK-012 — Tareas de construcción y verificación

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
| MK-012-T01 · TODO | SPEC-012, HU-012, WF-012, FLOW-012 | Verificar trazabilidad de fuentes y consistencia con OpenAPI 0.5.0 | Registro de versiones revisadas y sin contradicciones | Los 8 criterios de cobertura y operaciones `/categorias/{id}/seo*` identificados |
| MK-012-T02 · TODO | Component spec y plan | Validar inventario de 3 pantallas y 3 componentes locales | Documentación lista para ejecución | Consistencia entre nombres de vistas, rutas y DTOs |
| MK-012-T03 · TODO | `mockups/prototipo/README.md` | Configurar o verificar entorno de ejecución del prototipo y enrutador | Estructura para `/pantallas/MK012/` y rutas declaradas | El servidor del prototipo compila y resuelve rutas de prueba |
| MK-012-T04 · TODO | Spec §10 | Implementar fixtures tipados `FX-012-01` a `FX-012-06` | Archivo de fixtures con metadatos SEO y tablas de historial | Datos mock accesibles sin llamadas de red externa |
| MK-012-T05 · TODO | Plan §4 | Declarar rutas directas `/MK012/S01` a `/MK012/S03` en enrutador | Rutas registradas y accesibles por URL directa | Carga de pantallas con fallback ante ausencia de fixture |

---

## 3. Construcción de pantallas y componentes locales

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-012-T10 · TODO | S01, FX-012-01, DS-C17 | Construir listado general S01 con estado de optimización SEO | Tabla de categorías con slug actual, meta-título y badge de estado | Búsqueda por texto y filtros operativos; acceso a S02 y S03 |
| MK-012-T11 · TODO | S02, C01, FX-012-02/03, DS-C03/C05 | Construir pantalla ancla S02 con formulario y contadores 70/160 | Formulario con inputs de slug, título y descripción con contadores | Contadores dinámicos que muestran advertencia pero NO bloquean submit |
| MK-012-T12 · TODO | S02, C02, FX-012-02/03 | Implementar componente de vista previa SERP Google en tiempo real | Tarjeta reactiva simulando resultado de Google Desktop | Actualización simultánea con inputs; truncado visual de textos largos |
| MK-012-T13 · TODO | S02, FX-012-04 | Implementar regeneración asistida de slug con confirmación | Botón que resuelve slug vía API y solicita confirmación antes de aplicar | Muestra alerta si la propuesta incluye sufijo numérico incremental |
| MK-012-T14 · TODO | S02, DS-C21 | Implementar modal de confirmación por cambio de URL pública | Modal que advierte sobre la generación de redirección 301 | Explica el impacto en tráfico orgánico antes de guardar cambios |
| MK-012-T15 · TODO | S03, C03, FX-012-05/06, DS-C17 | Construir historial de redirecciones S03 con copy normativo | Tabla cronológica con `oldSlug → newSlug`, fecha y nota 301 | Muestra la leyenda obligatoria sobre Marketplace y redirección 301 |

---

## 4. Normalización UI y accesibilidad

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-012-T20 · TODO | DESIGN.md §§4–11 | Normalizar componentes con tokens de Mantine y tema corporativo | Estilos visuales consistentes con escala tipográfica y espaciados | Cero estilos inline o hacks; uso exclusivo de clases y variables DS |
| MK-012-T21 · TODO | Viewport 1440 px | Verificar ergonomía visual y ausencia de scroll horizontal involuntario | Layout responsive desktop limpio a 1440 × 900 px | Inspección visual en navegador sin desbordamientos |
| MK-012-T22 · TODO | UXG-020, UXG-021 | Auditar accesibilidad: contadores con `aria-live` y navegación por teclado | Controles accesibles para lectores de pantalla y foco visible | Tab/Shift+Tab funcional en formularios; lectores anuncian conteo de caracteres |

---

## 5. Autovalidación y revisión transversal

| ID / Estado | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-012-T30 · TODO | Criterios CA-01 a CA-08 | Ejecutar batería de pruebas de usabilidad sobre las 3 pantallas | Registro de cumplimiento punto por punto | Los 8 criterios de HU-012 satisfechos en el prototipo |
| MK-012-T31 · TODO | T30 | Capturar evidencias visuales de cada pantalla y estado de error | Capturas organizadas en carpeta de evidencias | Imágenes verificables de S01, S02, S03 |
| MK-012-T32 · TODO | T31 | Completar autovalidación de Leonardo Lopez en `validation-report.md` | Reporte de autovalidación con matriz de trazabilidad | Cero bloqueantes; solicitud formal de revisión UX enviada |
| MK-012-T33 · TODO | T32 | Someter prototipo a revisión UX transversal de Leonardo Vera Rodríguez | Visto bueno formal registrado: `APROBADO PARA FIGMA` | Dictamen de UX sin observaciones pendientes |
| MK-012-T34 · TODO | T33 | Trasladar diseño validado a Figma y verificar fidelidad visual | Frames en Figma y enlace público registrado | Coincidencia 100% de componentes, textos y jerarquía con el prototipo |
| MK-012-T35 · TODO | T34 | Cerrar `validation-report.md` con estado final APROBADO | Reporte formal cerrado con firmas y enlaces trazables | Entregable MK-012 listo para consolidación en master |
