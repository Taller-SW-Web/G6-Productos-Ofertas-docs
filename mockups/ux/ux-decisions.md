# UX Decisions — Productos y Ofertas

> Registro transversal de decisiones UX justificadas para el módulo Productos y Ofertas.
> Derivadas directamente de la Propuesta UX Integral Adoptada (`mockups/ux/propuesta-ux.md`).

## 1. Reglas de Gobernanza

Una decisión se documenta bajo el identificador `UXD-XXX` cuando:
- Afecta a dos o más funcionalidades del módulo.
- Define un patrón recurrente de interacción, navegación o feedback.
- Resuelve un trade-off fundamentado entre alternativas viables.
- Proporciona el sustento metodológico y técnico que respalda las normas de `mockups/ux/ux-guidelines.md`.

---

## 2. Índice de Decisiones Transversales

| ID | Decisión | Estado | Funcionalidades Afectadas |
|---|---|---|---|
| UXD-001 | Patrón de catálogo con panel lateral de detalle/edición contextual (Drawer) | Aprobado | MK-003, MK-004, MK-008, MK-009, MK-011, MK-015 |
| UXD-002 | Vistas guiadas secuenciales (Wizards) para configuración de entidades complejas | Aprobado | MK-001, MK-002, MK-005, MK-006, MK-007, MK-010, MK-012 |
| UXD-003 | Grids de alta densidad con edición en lote y controles fijos de acción | Aprobado | MK-001, MK-013, MK-014, MK-015, MK-016 |
| UXD-004 | Patrones de feedback de carga y estados vacíos formativos (Skeleton Loading & Empty States) | Aprobado | Transversal a los 16 MKs |
| UXD-005 | Notificaciones de respuesta del sistema y confirmación no intrusiva (Toast Feedback) | Aprobado | Transversal a los 16 MKs |
| UXD-006 | Mecanismos de interacción en formularios: Debounce en búsqueda y validación en evento Blur | Aprobado | Transversal a los 16 MKs |

---

# UXD-001 — Catálogo con Panel Lateral Contextual (Drawer)

## Problema
La navegación hacia pantallas dedicadas completas para tareas rápidas de inspección o edición menor provoca desorientación en el Gestor Comercial, pérdida de la posición en listas paginadas y pérdida de contexto del catálogo.

## Alternativas Consideradas
- **A — Pantalla completa separada para cada detalle/edición:** Requiere recarga completa de contexto y desorienta en exploraciones sucesivas.
- **B — Modal flotante central:** Bloquea totalmente la visualización de la lista de productos y satura visualmente con formularios medianos.
- **C (Seleccionada) — Panel lateral deslizable (Drawer ancho estándar 480 px - extendido 640 px):** Permite inspeccionar o modificar la entidad manteniendo visible el registro seleccionado en la tabla principal. La diferenciación de anchos responde al tipo de contenido: 480 px para formularios simples de una columna; 640 px para vistas que integran subtablas o múltiples atributos.

## Justificación y Trade-offs
Alineada con la Propuesta UX Integral. Maximiza la agilidad del Gestor Comercial sin pérdida de contexto. Trade-off: Requiere restringir la disposición de campos en el panel a layouts verticales limpios.

## Criterios de Validación
- El operador puede abrir y cerrar detalles con tecla `Escape` o botón de cierre.
- La fila seleccionada en el catálogo permanece destacada mientras el panel esté activo.

---

# UXD-002 — Flujos Secuenciales Guiados (Wizards) para Entidades Complejas

## Problema
Formularios extensos monolíticos (como creación de combos en MK-002, cupones en MK-005, promociones en MK-006 o reglas de venta cruzada en MK-007) presentan altas tasas de error por abandono, fatiga y validaciones tardías acumuladas.

## Alternativas Consideradas
- **A — Formulario monolítico largo en una sola página:** Provoca fatiga visual y validaciones acumuladas al final.
- **B — Pestañas libres no secuenciales:** Permite guardar entidades en estados incompletos o inconsistentes.
- **C (Seleccionada) — Proceso guiado paso a paso con stepper superior y resumen final:** Pasos atómicos con validación obligatoria para avanzar y vista previa de confirmación.

## Justificación y Trade-offs
Reduce drásticamente errores humanos en la fijación de reglas comerciales críticas. Trade-off: Mayor número de clics totales, justificado por la alta criticidad del impacto comercial.

## Criterios de Validación
- Cada paso valida sus datos antes de habilitar el botón "Siguiente".
- Existe un paso final de revisión consolidada antes de la confirmación definitiva.

---

# UXD-003 — Grids de Alta Densidad con Acciones por Lote

## Problema
La administración masiva de stock (MK-015), precios (MK-013), auditoría (MK-014) y carga de productos (MK-001) requiere visualizar múltiples atributos simultáneos sin excesivo scroll vertical ni páginas excesivamente cortas.

## Alternativas Consideradas
- **A — Tarjetas visuales (Cards):** Muy poco densas, ineficientes para comparar inventarios y precios.
- **B (Seleccionada) — Tabla densa con cabecera fija (Sticky Header), paginación y barra flotante de lote:** Permite ordenar, filtrar y ejecutar cambios sobre N elementos seleccionados simultáneamente.

## Justificación y Trade-offs
Maximiza la productividad del Gestor Comercial en tareas analíticas y masivas. Trade-off: Exige tipografía compacta y gestión rigurosa de anchos de columna para evitar overflow horizontal en el viewport canónico de 1440 px.

## Criterios de Validación
- La cabecera permanece fija durante el desplazamiento vertical.
- Al seleccionar una o más filas, emerge una barra contextual con acciones por lote disponibles.

---

# UXD-004 — Skeleton Loading y Empty States Formativos

## Problema
El uso de spinners genéricos o pantallas en blanco durante la carga de catálogos genera sensación de congelamiento y salto de contenido (layout shifts). Asimismo, listados vacíos sin orientación causan incertidumbre sobre si falló el sistema o no existen datos.

## Alternativas Consideradas
- **A — Spinners circulares centrados:** No proporcionan estructura previa y provocan saltos visuales al renderizar la tabla o grid.
- **B (Seleccionada) — Skeletons que replican la estructura y Empty States accionables:** Los placeholders esqueletales mantienen estable el layout mientras se obtienen datos. Los estados vacíos indican claramente la causa y ofrecen la acción correctiva primaria ("Limpiar filtros", "Crear nuevo").

## Justificación y Trade-offs
Proporciona una percepción de rapidez y estabilidad visual superior. Reduce la ansiedad del usuario durante operaciones de red.

## Criterios de Validación
- Durante la carga, los esqueletos ocupan las dimensiones exactas de las tablas o formularios esperados.
- Ningún listado vacío muestra únicamente un área en blanco.

---

# UXD-005 — Notificaciones No Intrusivas (Toasts) para Feedback del Sistema

## Problema
El uso de diálogos modulares intrusivos (alertas modales) para confirmar operaciones habituales (como guardar un borrador, actualizar un precio o asociar una categoría) interrumpe innecesariamente el ritmo de trabajo del Gestor Comercial.

## Alternativas Consideradas
- **A — Modales de confirmación de éxito:** Obligan a hacer clic en "Aceptar" para continuar trabajando.
- **B — Mensajes de texto estáticos en cabecera:** Pasan desapercibidos tras hacer scroll.
- **C (Seleccionada) — Toasts flotantes transitorios (duración 4 a 5 segundos con botón de cierre):** Se muestran en la esquina superior/inferior derecha informando el resultado sin bloquear la interacción con la pantalla.

## Justificación y Trade-offs
Garantiza confirmación inmediata sin interrumpir el flujo operativo del usuario.

## Criterios de Validación
- Los toasts de éxito desaparecen automáticamente tras un intervalo controlado.
- Los toasts de error no se autocierran hasta que el usuario los descarte o resuelva la acción.

---

# UXD-006 — Optimización de Entrada: Debounce en Búsqueda y Validación en Blur

## Problema
Disparar búsquedas con cada pulsación de tecla satura la interfaz con re-renders y peticiones prematuras. Por otro lado, validar formularios en cada tecla mientras el usuario escribe genera frustración por errores prematuros (ej. "correo incompleto" mientras aún se está digitando).

## Alternativas Consideradas
- **A — Búsqueda únicamente al presionar Enter:** Fricción innecesaria en la exploración de catálogos.
- **B — Validación onChange en formularios:** Mensajes de error prematuros y molestos.
- **C (Seleccionada) — Debounce controlado (300 ms) en búsqueda y validación en onBlur en formularios:**
  - El debounce de 300 ms proporciona el balance ideal entre reactividad percibida y estabilidad del input.
  - La validación al desenfocar el campo (onBlur) permite al usuario completar su entrada sin interrupciones y solo reporta inconsistencias una vez terminada la edición del campo.

## Justificación y Trade-offs
Aumenta la fluidez y reduce la fatiga visual en la captura y consulta de datos.

## Criterios de Validación
- La búsqueda en tablas y catálogos espera 300 ms de inactividad antes de procesar el filtro.
- Los mensajes de validación de campo aparecen al abandonar el control o al intentar avanzar al siguiente paso del formulario.
