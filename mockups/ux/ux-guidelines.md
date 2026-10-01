# UX Guidelines — Productos y Ofertas

> Reglas normativas operativas obligatorias para el diseño e implementación de mockups.
> Derivadas estrictamente de las decisiones justificadas en `mockups/ux/ux-decisions.md` y sustentadas en la Propuesta UX Integral.

## 1. Cadena de Trazabilidad Normativa

```text
Propuesta UX Integral Adoptada
          ↓
UX Decisions (UXD-001 a UXD-006)
          ↓
UX Guidelines (Reglas operativas vinculantes)
          ↓
16 Mockups Funcionales (MK-001 a MK-016)
```

Cada directriz de este documento implementa de forma directa las decisiones aprobadas en `ux-decisions.md` (`UXD-001` a `UXD-006`) o requerimientos transversales de accesibilidad y del Design System.

---

## 2. Reglas de Layout y Entorno Desktop

1. **Alcance Exclusivo:** Diseñado e implementado únicamente para Web Desktop. No se crean ni contemplan variantes responsivas móviles o tablet.
2. **Viewport Canónico de Revisión:** Las pantallas se construyen y validan sobre un viewport canónico de **1440 px de ancho** (empleado como referencia de composición, sin limitar artificialmente el diseño a un ancho rígido).
3. **Ausencia de Overflow Horizontal:** Ninguna pantalla principal ni panel modal/drawer debe generar barra de desplazamiento horizontal en el viewport canónico.
4. **Operabilidad por Teclado y Accesibilidad:** Todas las acciones primarias, controles y navegación deben ser operables mediante teclado. Foco visible obligatorio con contorno (`outline`) de contraste accesible. Ningún estado crítico dependerá únicamente del color, apoyándose siempre en texto y/o iconografía accesible.

---

## 3. Navegación y Paneles Contextuales (Derivado de UXD-001)

1. **Uso de Drawers:** Las vistas de inspección y edición rápida de productos (MK-003), variantes (MK-004), categorías (MK-008), características (MK-009) y marcas (MK-011) deben abrirse en un panel lateral derecho.
2. **Dimensionamiento de Drawers (Justificado en UXD-001):**
   - **Ancho estándar (480 px):** Empleado para formularios de edición de una sola columna o fichas descriptivas sin subtablas.
   - **Ancho extendido (640 px):** Empleado exclusivamente cuando la vista integre matrices de datos, subtablas de atributos o tablas secundarias de existencias.
3. **Persistencia de Selección:** El elemento seleccionado en la tabla o catálogo debe permanecer con estado visual activo (`selected`) mientras el panel contextual permanezca abierto.
4. **Cierre sin Pérdida Involuntaria:** El cierre del panel mediante clic exterior o tecla `Escape` debe solicitar confirmación si existen campos editados sin guardar.

---

## 4. Procesos Guiados / Wizards (Derivado de UXD-002)

1. **Indicador de Progreso (Stepper):** Todo flujo multipaso (combos en MK-002, cupones en MK-005, ofertas en MK-006, reglas de venta cruzada en MK-007, importación masiva en MK-001, tipos de producto en MK-010 y SEO en MK-012) debe incluir un stepper superior horizontal con indicación clara del paso activo, completados y pendientes.
2. **Validación Bloqueante por Paso:** El botón primario "Siguiente" o "Continuar" solo se habilitará cuando todos los campos obligatorios del paso actual sean válidos.
3. **Paso de Confirmación:** El paso final debe ser una vista previa resumen no editable con desglose de impacto antes de la confirmación definitiva.

---

## 5. Listados y Tablas Densas (Derivado de UXD-003)

1. **Cabecera Fija (Sticky Header):** Las tablas operativas densas (MK-001, MK-013, MK-014, MK-015, MK-016) deben implementar cabecera fija (`position: sticky`) para conservar el contexto de las columnas durante el desplazamiento vertical.
2. **Acciones por Lote:** La selección de checkboxes debe activar una barra flotante contextual con el conteo de elementos seleccionados y botones de acción masiva claramente diferenciados.
3. **Alineación y Formato de Datos:**
   - Textos descriptivos y nombres: alineados a la izquierda.
   - Números, existencias, precios y porcentajes: alineados a la derecha y formateados con separador de miles.
   - Estados y badges: centrados.

---

## 6. Feedback de Carga y Estados Vacíos (Derivado de UXD-004)

1. **Skeleton Loading:** Durante la recuperación de información se emplean placeholders esqueletales que replican las dimensiones y estructura de la vista esperada (tablas o formularios), prohibiendo pantallas en blanco o spinners que desorganicen el layout.
2. **Empty States Accionables:** Todo listado o tabla sin resultados debe presentar una ilustración sobria, mensaje claro indicando la causa y un botón de acción orientador (ej. "Limpiar filtros" o "Registrar nuevo").

---

## 7. Notificaciones de Respuesta del Sistema (Derivado de UXD-005)

1. **Uso de Toasts:** Las confirmaciones de éxito y advertencias no bloqueantes se comunican mediante notificaciones flotantes temporales (toasts) que no interrumpen el trabajo del Gestor Comercial.
2. **Comportamiento:** Los toasts informativos/éxito tienen una duración visible acotada (4 a 5 segundos con botón de cierre); los toasts de error grave permanecen visibles hasta que el usuario los descarte o resuelva la acción.

---

## 8. Optimización de Entradas en Formularios (Derivado de UXD-006)

1. **Debounce en Búsqueda (300 ms):** Las cajas de búsqueda en catálogos y tablas aplican un retraso controlado de 300 ms de inactividad de pulsación antes de procesar el filtro, asegurando reactividad fluida sin bloqueos de renderizado.
2. **Validación al Desenfoque (onBlur):** Los campos de entrada de formularios validan sus reglas al perder el foco (`onBlur`) o al solicitar avanzar al siguiente paso, evitando alertas de error prematuras mientras el usuario se encuentra digitando.

---

## 9. Manejo de Decisiones Locales

Cualquier particularidad de una pantalla específica que no esté cubierta por estas directrices debe documentarse en su `component-spec.md` como `LUX-XX`. Si dicha regla resulta de utilidad para más de una funcionalidad, se elevará a `mockups/ux/ux-decisions.md` y posteriormente se incorporará a este documento.
