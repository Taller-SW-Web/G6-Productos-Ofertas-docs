# UX Decisions — Productos y Ofertas

> Registro transversal de decisiones UX justificadas para el módulo Productos y Ofertas.
> Derivadas directamente de la Propuesta UX Integral Adoptada (`mockups/ux/propuesta-ux.md`).

## 1. Reglas de Gobernanza

Una decisión se documenta bajo el identificador `UXD-XXX` cuando:
- Afecta a dos o más funcionalidades del módulo.
- Define un patrón recurrente de interacción o presentación.
- Implica un trade-off justificado entre alternativas.
- Constituye el sustento técnico y metodológico obligatorio que respalda las reglas en `ux-guidelines.md`.

---

## 2. Índice de Decisiones Transversales

| ID | Decisión | Estado | Funcionalidades Afectadas |
|---|---|---|---|
| UXD-001 | Patrón de catálogo con panel lateral de detalle/edición contextual (Drawer) | Aprobada | MK-003, MK-004, MK-005, MK-008, MK-011, MK-015 |
| UXD-002 | Vistas guiadas secuenciales (Wizards) para configuración de entidades complejas | Aprobada | MK-001, MK-002, MK-006, MK-007, MK-010 |
| UXD-003 | Grids de alta densidad con edición en lote y controles fijos de acción | Aprobada | MK-001, MK-013, MK-014, MK-015, MK-016 |

---

# UXD-001 — Catálogo con Panel Lateral Contextual (Drawer)

## Problema
La navegación hacia pantallas dedicadas de detalle para operaciones rápidas genera desorientación, pérdida de la posición en la tabla y penaliza la productividad del operador administrativo.

## Alternativas Consideradas
- **A — Pantalla completa separada para cada detalle/edición:** Requiere recarga completa de contexto y desorienta en exploraciones sucesivas.
- **B — Modal flotante central:** Bloquea totalmente la visualización de la lista de productos y satura visualmente con formularios medianos.
- **C (Seleccionada) — Panel lateral deslizable (Drawer ancho 480 px - 640 px):** Permite inspeccionar o modificar la entidad manteniendo visible el registro seleccionado en la tabla principal.

## Justificación y Trade-offs
Alineada con la Propuesta UX Integral. Permite agilidad operativa sin pérdida de contexto. Trade-off: Requiere restringir la disposición de campos en el panel a layouts verticales limpios.

## Criterios de Validación
- El operador puede abrir y cerrar detalles con tecla `Escape` o clic externo.
- La fila seleccionada en el catálogo permanece destacada mientras el panel esté activo.

---

# UXD-002 — Flujos Secuenciales Guiados (Wizards) para Entidades Complejas

## Problema
Formularios extensos monolíticos (como creación de combos con reglas de descuento, o venta cruzada) presentan tasas altas de error por abandono y validaciones tardías.

## Alternativas Consideradas
- **A — Formulario monolítico largo en una sola página:** Provoca fatiga visual y validaciones acumuladas al final.
- **B — Pestañas libres no secuenciales:** Permite guardar entidades en estados incompletos o inconsistentes.
- **C (Seleccionada) — Proceso guiado paso a paso con resumen final:** Pasos atómicos con validación obligatoria para avanzar y vista previa de confirmación.

## Justificación y Trade-offs
Reduce errores humanos en la fijación de precios y condiciones comerciales. Trade-off: Mayor número de clics totales, justificado por la alta criticidad de las reglas comerciales.

## Criterios de Validación
- Cada paso valida sus datos antes de habilitar el botón "Siguiente".
- Existe un paso final de revisión consolidada antes de la confirmación definitiva.

---

# UXD-003 — Grids de Alta Densidad con Acciones por Lote

## Problema
La administración masiva de stock, precios y auditoría requiere visualizar múltiples atributos simultáneos sin excesivo scroll vertical ni páginas excesivamente cortas.

## Alternativas Consideradas
- **A — Tarjetas visuales (Cards):** Muy poco densas, ineficientes para comparar inventarios y precios.
- **B (Seleccionada) — Tabla densa con cabecera fija, paginación configurable y barra flotante de lote:** Permite ordenar, filtrar y ejecutar cambios sobre N elementos seleccionados simultáneamente.

## Justificación y Trade-offs
Maximiza la productividad en tareas analíticas y masivas. Trade-off: Exige tipografía compacta y gestión rigurosa de anchos de columna para evitar overflow horizontal en 1440 px.

## Criterios de Validación
- La cabecera permanece fija durante el desplazamiento vertical.
- Al seleccionar una o más filas, emerge una barra contextual con acciones por lote disponibles.
