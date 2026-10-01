# Propuesta UX del Módulo — Productos y Ofertas

> Documento único y transversal para todo el módulo Productos y Ofertas.

## 1. Identificación y Objetivos del Módulo

- **Módulo:** Productos y Ofertas
- **Versión:** v1.0
- **Estado:** En revisión / Aprobado
- **Alcance de Plataforma:** Web Desktop exclusivamente.
- **Viewport canónico de generación y revisión:** 1440 px de ancho (utilizado como estándar de verificación, sin implicar un diseño de ancho rígido).

El módulo centraliza la administración y publicación del catálogo de productos, taxonomía, políticas de precios, ofertas comerciales y supervisión de existencias. Requiere un balance óptimo entre densidad de información para tareas administrativas masivas y claridad visual en la parametrización de reglas de negocio.

---

## 2. Propuesta UX 1 — Enfoque Operativo y Denso en Datos

*(Preservada como evidencia académica)*

### Filosofía y Concepto
Orientada a la máxima productividad del usuario administrativo especializado. Prioriza la visualización de grandes volúmenes de registros en tablas avanzadas con edición inline rápida, accesos de teclado y minimización de desplazamientos verticales.

### Fortalezas
- Agilidad superior en consultas y modificaciones de precios y stock masivo.
- Aprovechamiento exhaustivo del ancho del viewport en monitores de escritorio.
- Acceso directo a acciones operativas sin navegación multinivel.

### Riesgos y Limitaciones
- Alta carga cognitiva inicial para usuarios no técnicos o roles comerciales casuales.
- Sobrecarga visual en formularios de alta complejidad (ej. combos y reglas de upselling).

---

## 3. Propuesta UX 2 — Enfoque Guiado y Asistido por Pasos (Wizards)

*(Preservada como evidencia académica)*

### Filosofía y Concepto
Enfocada en la reducción sistemática de errores mediante procesos guiados secuenciales (wizards) con validaciones en tiempo real y ayudas contextuales prominentes para la creación de combos, reglas SEO y configuración de ofertas.

### Fortalezas
- Alta tasa de éxito y prevención de inconsistencias en configuraciones complejas.
- Facilidad de aprendizaje y curva de incorporación suave.
- Explicación didáctica de campos y contratos de datos.

### Riesgos y Limitaciones
- Fricción y lentitud para operadores avanzados que requieren operaciones rutinarias rápidas.
- Fragmentación de la información global en múltiples vistas parciales.

---

## 4. Propuesta UX 3 — Enfoque Modular Basado en Dashboard y Paneles Contextuales

*(Preservada como evidencia académica)*

### Filosofía y Concepto
Estructura la experiencia alrededor de un centro de control con métricas clave y paneles laterales (drawers) que permiten inspeccionar o editar detalles de productos y promociones sin perder el contexto del catálogo general.

### Fortalezas
- Excelente mantenimiento del contexto operativo sin navegación destructiva.
- Visibilidad inmediata del estado de salud del inventario y ofertas activas.
- Gran escalabilidad para agregar nuevas características o integraciones modulares.

### Riesgos y Limitaciones
- Complejidad en pantallas secundarias cuando se manejan matrices densas de atributos.
- Posible saturación de paneles superpuestos si no se delimita la profundidad de navegación.

---

## 5. Comparación Transversal de las Propuestas

*(Preservada como evidencia académica)*

| Criterio UX | Propuesta 1 (Operativo / Denso) | Propuesta 2 (Guiado / Wizards) | Propuesta 3 (Modular / Paneles) |
|---|---|---|---|
| **Velocidad en tareas masivas** | Muy Alta | Baja | Media-Alta |
| **Prevención de errores** | Media | Muy Alta | Alta |
| **Preservación de contexto** | Media | Baja | Muy Alta |
| **Curva de aprendizaje** | Exigente | Suave | Media |
| **Mantenibilidad técnica** | Alta | Media | Alta |
| **Aprovechamiento Desktop (1440 px)**| Excelente | Regular | Excelente |

### Análisis de Trade-offs
Ninguna propuesta cubre de forma aislada la heterogeneidad de los 16 flujos del módulo:
- La Propuesta 1 resulta indispensable para gestión de stock, auditoría y precios masivos (MK-001, MK-013, MK-015), pero entorpece la configuración de combos (MK-002) y ofertas (MK-006).
- La Propuesta 2 es idónea para tareas complejas poco frecuentes como SEO (MK-012) o reglas de venta cruzada (MK-007), pero genera frustración en la exploración diaria.
- La Propuesta 3 ofrece el marco contenedor y la navegación contextual más robusta para el catálogo (MK-003, MK-004, MK-005) y alertas (MK-016).

---

## 6. Selección, Justificación y Combinación de Elementos

Se determina que la mejor solución de experiencia para el módulo Productos y Ofertas consiste en una **arquitectura híbrida convergente**:

1. **Marco Contenedor Contextual (de la Propuesta 3):**
   - Vistas maestras de catálogo con métricas resumidas y panel de filtros persistente.
   - Paneles laterales deslizables (drawers) para edición rápida y consulta detallada sin abandonar el listado principal.
2. **Tablas Densas con Operación Masiva (de la Propuesta 1):**
   - Grids de alta densidad con controles por lote, selección múltiple y ordenamiento columnar para flujos masivos y supervisión de stock.
3. **Flujos Secuenciales Asistidos (de la Propuesta 2):**
   - Formatos guiados dedicados exclusivamente a la configuración de entidades multipaso complejas (creación de combos, promociones condicionadas y asignación masiva de taxonomías).

---

## 7. Propuesta UX Integral Adoptada (Definición Oficial Vigente)

### 7.1. Principios Rectores
1. **Contexto Preservado:** Las acciones secundarias y detalles nunca deben desorientar al usuario respecto a su posición en el catálogo.
2. **Eficiencia Proporcional a la Complejidad:** Las tareas repetitivas se resuelven en un solo paso; las tareas complejas de alto impacto se asisten con validación preventiva.
3. **Claridad del Estado Comercial y Operativo:** El estado de disponibilidad, vigencia de precios y promociones debe ser inequívoco a primera vista sin depender exclusivamente del color.

### 7.2. Modelo General de Interacción y Navegación
- **Estructura Desktop:** Barra lateral colapsable, cabecera de contexto con migas de pan funcionales y área de trabajo optimizada para 1440 px de ancho canónico.
- **Acciones Principales:** Visibles de forma fija en la parte superior derecha de cada pantalla de trabajo.
- **Transiciones:** Despliegue de paneles laterales con fondo atenuado accesible para edición puntual; cambio de pantalla completa solo para flujos multipaso o dashboards analíticos.

### 7.3. Jerarquía de Información
1. **Nivel Primario:** Estado de la entidad (activo, borrador, sin stock), título/nombre e identificación unívoca (SKU/código).
2. **Nivel Secundario:** Parámetros comerciales (precio regular vs. precio promocional, margen, categoría principal).
3. **Nivel Complementario:** Metadatos técnicos, marcas, timestamps de auditoría e historial de cambios.

### 7.4. Patrones Transversales
- **Búsqueda y Filtros:** Búsqueda predictiva con debouncing de 300 ms; filtros facetados en panel lateral colapsable con etiquetas activas removibles.
- **Formularios:** Disposición en columnas agrupadas lógicamente con validaciones en blur y mensajes de ayuda accesibles.
- **Feedback:** Indicadores de estado de carga esqueletales (skeletons), estados vacíos (empty states) con llamadas a la acción formativas y toasts no intrusivos para confirmaciones.

### 7.5. Derivación hacia Decisiones y Reglas
Esta Propuesta UX Integral constituye la fuente rectora única a partir de la cual se derivan formalmente:
1. `mockups/ux/ux-decisions.md`: Justificación técnica y trade-offs de cada patrón (`UXD-XXX`).
2. `mockups/ux/ux-guidelines.md`: Normas operativas vinculantes derivadas directamente de las decisiones adoptadas.
