# UX Guidelines — Productos y Ofertas

> Reglas normativas operativas obligatorias para el diseño e implementación de mockups.
> Derivadas estrictamente de las decisiones justificadas en `mockups/ux/ux-decisions.md` y sustentadas en la Propuesta UX Integral.

## 1. Cadena de Trazabilidad Normativa

```text
Propuesta UX Integral Adoptada
          ↓
UX Decisions (UXD-XXX)
          ↓
UX Guidelines (Reglas operativas vinculantes)
          ↓
16 Mockups Funcionales (MK-001 a MK-016)
```

Cada directriz de este documento implementa de forma directa las decisiones aprobadas (`UXD-001`, `UXD-002`, `UXD-003`).

---

## 2. Reglas de Layout y Entorno Desktop

1. **Alcance Exclusivo:** Diseñado e implementado únicamente para Web Desktop. No se crean ni contemplan variantes responsivas móviles o tablet.
2. **Viewport Canónico de Revisión:** Las pantallas se construyen y validan sobre un viewport canónico de **1440 px de ancho** (empleado como referencia de composición, sin limitar artificialmente el diseño a un ancho rígido).
3. **Ausencia de Overflow Horizontal:** Ninguna pantalla principal ni panel modal/drawer debe generar barra de desplazamiento horizontal en el viewport canónico.
4. **Operabilidad por Teclado:** Todas las acciones primarias, cierres de paneles y navegación por listas deben ser accionables mediante teclado (foco visible obligatorio con `outline` mínimo de 2 px de alto contraste).

---

## 3. Navegación y Paneles Contextuales (Derivado de UXD-001)

1. **Uso de Drawers:** Las vistas de inspección y edición rápida de productos, categorías y marcas deben abrirse en un panel lateral derecho (ancho estándar: 480 px; ancho extendido para tablas secundarias: 640 px).
2. **Persistencia de Selección:** El elemento seleccionado en la tabla o catálogo debe permanecer con estado visual activo (`selected`) mientras el panel contextual permanezca abierto.
3. **Cierre sin Pérdida Involuntaria:** El cierre del panel mediante clic exterior o tecla `Escape` debe solicitar confirmación si existen campos editados sin guardar.

---

## 4. Procesos Guiados / Wizards (Derivado de UXD-002)

1. **Indicador de Progreso:** Todo flujo de 3 o más pasos (combos, reglas de oferta, importaciones) debe incluir un stepper superior horizontal con el paso activo, pasos completados y pasos pendientes.
2. **Validación Bloqueante por Paso:** El botón primario "Siguiente" o "Continuar" solo se habilitará cuando todos los campos obligatorios del paso actual sean válidos.
3. **Paso de Confirmación:** El paso final debe ser una vista previa resumen no editable con desglose de impacto (ej. precio final del combo, productos afectados por la promoción).

---

## 5. Listados y Tablas Densas (Derivado de UXD-003)

1. **Cabecera Fija:** Las tablas con más de 15 filas deben implementar cabecera fija (`sticky header`).
2. **Acciones por Lote:** La selección de checkboxes debe mostrar una barra flotante inferior o superior con el conteo de elementos seleccionados y botones de acción masiva claramente diferenciados.
3. **Alineación de Datos:**
   - Textos descriptivos: alineados a la izquierda.
   - Números, existencias, precios y porcentajes: alineados a la derecha y formateados con separador de miles.
   - Estados y badges: centrados.

---

## 6. Feedback, Estados y Accesibilidad

1. **Estados de Carga:** Usar placeholders esqueletales (skeletons) que repliquen la estructura esperada; prohibido el uso de pantallas blancas o spinners aislados que desorganicen el layout.
2. **Empty States:** Todo listado sin resultados debe mostrar una ilustración sobria, mensaje explicativo del motivo y un botón de acción claro (ej. "Limpiar filtros" o "Crear nuevo producto").
3. **No Dependencia del Color:** Ningún indicador de estado (disponible, agotado, pausado) debe expresarse únicamente con color; debe acompañarse de texto descriptivo y/o icono accesible.

---

## 7. Manejo de Decisiones Locales

Cualquier particularidad de una pantalla específica debe documentarse en su `component-spec.md` como `LUX-XX`. Si dicha regla resulta de utilidad para más de una funcionalidad, se elevará a `ux-decisions.md` y posteriormente se incorporará a este documento.
