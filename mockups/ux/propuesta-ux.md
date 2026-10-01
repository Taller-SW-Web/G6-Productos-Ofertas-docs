# Propuesta UX del Módulo — Productos y Ofertas

> Documento único y transversal para todo el módulo Productos y Ofertas.

## 1. Identificación y Objetivos del Módulo

- **Módulo:** Productos y Ofertas
- **Versión:** v1.1
- **Estado:** Aprobado
- **Actor Principal Canónico:** Gestor Comercial (con capacidades funcionales específicas según el subdominio: administración de catálogo, taxonomía, políticas de precios, ofertas y recepción/supervisión de inventario).
- **Alcance de Plataforma:** Web Desktop exclusivamente.
- **Viewport canónico de generación y revisión:** 1440 px de ancho (utilizado como estándar de verificación, sin implicar un diseño de ancho rígido).

El módulo centraliza la administración y publicación del catálogo de productos, variantes SKU, taxonomía, políticas de precios, cupones, ofertas comerciales y supervisión de existencias. Requiere un balance óptimo entre densidad de información para tareas administrativas masivas ejecutadas por el Gestor Comercial y claridad visual en la parametrización de reglas de negocio complejas.

---

## 2. Propuesta UX 1 — Enfoque Operativo y Denso en Datos

*(Preservada como evidencia académica)*

### Filosofía y Concepto
Orientada a la máxima productividad y agilidad del Gestor Comercial en operaciones masivas y auditoría de datos. Prioriza la visualización de grandes volúmenes de registros en tablas avanzadas con controles por lote, edición rápida, atajos de teclado y minimización de desplazamientos verticales.

### Fortalezas
- Agilidad superior en consultas y modificaciones de precios masivos (MK-013) y control de stock en tiempo real (MK-015).
- Eficiencia en la revisión de bitácoras extensas como el historial de auditoría de precios (MK-014) y monitoreo de importaciones masivas (MK-001).
- Aprovechamiento exhaustivo del ancho del viewport en monitores de escritorio (1440 px).
- Acceso directo a acciones operativas por lote sin navegación multinivel.

### Riesgos y Limitaciones
- Sobrecarga cognitiva si se aplica indiscriminadamente a la configuración de entidades comerciales complejas (como combos en MK-002, cupones en MK-005 o promociones en MK-006).
- Rigidez visual en formularios extensos de creación conceptual (taxonomía o asociaciones).

---

## 3. Propuesta UX 2 — Enfoque Guiado y Asistido por Pasos (Wizards)

*(Preservada como evidencia académica)*

### Filosofía y Concepto
Enfocada en la reducción sistemática de errores humanos mediante procesos guiados secuenciales (wizards) con validaciones en tiempo real, estricta separación de etapas y ayudas contextuales prominentes para la parametrización de reglas complejas.

### Fortalezas
- Alta tasa de éxito y prevención de inconsistencias en configuraciones con dependencias lógicas:
  - Carga masiva de productos y mapeo de columnas (MK-001).
  - Reglas de armado y cálculo de precios de combos (MK-002).
  - Condiciones de canje y restricciones de cupones de descuento (MK-005).
  - Mecánicas de ofertas, descuentos por volumen y promociones (MK-006).
  - Reglas de venta cruzada y upselling (MK-007).
  - Asociación entre tipos de producto y características con restricciones de obligatoriedad (MK-010).
  - Configuración estructurada de SEO y metadatos (MK-012).
- Facilidad de aprendizaje y validaciones progresivas que impiden guardar estados incompletos.

### Riesgos y Limitaciones
- Fricción y lentitud para operaciones rutinarias frecuentes del Gestor Comercial.
- Fragmentación de la información global al obligar a transitar pasos secuenciales para modificaciones menores.

---

## 4. Propuesta UX 3 — Enfoque Modular Basado en Dashboard y Paneles Contextuales

*(Preservada como evidencia académica)*

### Filosofía y Concepto
Estructura la experiencia del Gestor Comercial alrededor de centros de control visuales con paneles laterales deslizables (drawers) que permiten inspeccionar o editar detalles de entidades sin perder el contexto de la vista principal ni forzar navegación destructiva.

### Fortalezas
- Preservación permanente del contexto operativo en la administración del catálogo central:
  - Navegación y mantenimiento de productos en el CRUD principal (MK-003).
  - Edición y visualización de matrices de variantes SKU (MK-004).
  - Mantenimiento del árbol de categorías y subcategorías (MK-008).
  - Catálogo de características y sus valores (MK-009).
  - Gestión del listado de marcas (MK-011).
  - Panel analítico y alertas de existencias en el dashboard de stock (MK-016).
- Visibilidad inmediata del estado del catálogo y alertas críticas de inventario.
- Gran escalabilidad para inspeccionar detalles técnicos sin recargar pantallas.

### Riesgos y Limitaciones
- Complejidad en pantallas secundarias cuando se manejan matrices tabulares muy densas dentro de un drawer lateral.
- Saturación visual si no se delimita estrictamente la profundidad de apertura de paneles superpuestos.

---

## 5. Comparación Transversal de las Propuestas

*(Preservada como evidencia académica)*

| Criterio UX | Propuesta 1 (Operativo / Denso) | Propuesta 2 (Guiado / Wizards) | Propuesta 3 (Modular / Paneles) |
|---|---|---|---|
| **Velocidad en tareas masivas y auditoría** | Muy Alta | Baja | Media-Alta |
| **Prevención de errores en reglas complejas**| Media | Muy Alta | Alta |
| **Preservación de contexto del catálogo** | Media | Baja | Muy Alta |
| **Curva de aprendizaje para el Gestor Comercial**| Exigente | Suave | Media |
| **Mantenibilidad técnica y modularidad** | Alta | Media | Alta |
| **Aprovechamiento Desktop (1440 px)** | Excelente | Regular | Excelente |

### Análisis de Trade-offs y Cobertura Funcional
Ninguna propuesta cubre de forma aislada la totalidad de los 16 flujos del módulo:
- La **Propuesta 1** es indispensable para tareas operativas de alta densidad y auditoría: Carga masiva (MK-001), Precios individuales y masivos (MK-013), Historial de auditoría de precios (MK-014) y Control de stock y disponibilidad (MK-015). Sin embargo, resulta deficiente para configurar combos o cupones.
- La **Propuesta 2** resulta óptima para procesos comerciales guiados con validaciones preventivas: Carga masiva por lotes (MK-001), Combos de productos (MK-002), Cupones de descuento (MK-005), Ofertas y promociones (MK-006), Reglas de venta cruzada/upselling (MK-007), Asociación de tipos de producto y características (MK-010) y SEO/metadatos (MK-012). No obstante, es lenta para navegación frecuente.
- La **Propuesta 3** proporciona el marco de trabajo ideal para la gestión continua del catálogo y taxonomía: Gestión de productos CRUD (MK-003), Variantes SKU (MK-004), Categorías (MK-008), Características y valores (MK-009), Marcas (MK-011) y Dashboard analítico de alertas (MK-016).

---

## 6. Selección, Justificación y Combinación de Elementos

Se adopta una **arquitectura híbrida convergente** que integra lo mejor de cada enfoque:

1. **Marco Contenedor Contextual con Drawers (de la Propuesta 3):**
   - Vistas maestras de catálogo y taxonomía con panel lateral deslizable (drawer) para consultar detalles y ejecutar ediciones rápidas sin perder la posición en la tabla (MK-003, MK-004, MK-008, MK-009, MK-011).
   - Dashboard analítico con widgets y navegación contextual a alertas (MK-016).
2. **Tablas Densas con Operación Masiva (de la Propuesta 1):**
   - Grids de alta densidad con selección múltiple, cabecera fija y barra de acciones por lote para operaciones críticas y de auditoría (MK-001, MK-013, MK-014, MK-015).
3. **Flujos Secuenciales Guiados (de la Propuesta 2):**
   - Wizards paso a paso con validaciones previas para la creación y parametrización de entidades con lógica de negocio compuesta (MK-001, MK-002, MK-005, MK-006, MK-007, MK-010, MK-012).

---

## 7. Propuesta UX Integral Adoptada (Definición Oficial Vigente)

### 7.1. Principios Rectores
1. **Preservación del Contexto:** El Gestor Comercial nunca debe perder de vista su ubicación dentro del catálogo o listado maestro al realizar consultas o ediciones puntuales.
2. **Eficiencia Proporcional a la Complejidad:** Las tareas rutinarias y de consulta masiva se resuelven en un solo paso con alta densidad; las tareas de configuración comercial crítica se asisten mediante flujos guiados que previenen errores antes de confirmar.
3. **Claridad del Estado Comercial y Operativo:** La vigencia de precios, el estado de disponibilidad de stock, los topes de cupones y el estado de promociones deben ser evidentes de forma inmediata mediante texto, badges y soporte de accesibilidad.

### 7.2. Modelo General de Interacción y Navegación
- **Estructura Desktop:** Barra lateral izquierda colapsable de navegación modular, cabecera superior con migas de pan funcionales y área de trabajo optimizada para el viewport canónico de 1440 px.
- **Acciones Primarias:** Botones de acción principal ubicados de manera consistente en la esquina superior derecha del área de contenido.
- **Transiciones:** Empleo de drawers laterales con fondo atenuado para detalle y edición ágil; cambio a vistas completas únicamente para flujos guiados (wizards) o dashboards especializados.

### 7.3. Jerarquía de Información
1. **Nivel Primario:** Identificadores canónicos (SKU, ID, código), nombre/título de la entidad y badge de estado operativo (Activo, Inactivo, Borrador, Agotado).
2. **Nivel Secundario:** Parámetros comerciales y de negocio (precios, tipo de descuento, existencias disponibles, categorías asociadas).
3. **Nivel Complementario:** Metadatos técnicos, marcas, slug SEO, timestamps y bitácora de auditoría.

### 7.4. Patrones Transversales
- **Búsqueda y Filtros:** Búsqueda predictiva con debouncing de entrada; filtros facetados en panel colapsable con etiquetas activas fácilmente removibles.
- **Formularios:** Distribución en cuadrícula limpia de columnas agrupadas lógicamente, con validaciones al perder el foco (blur) y mensajes de asistencia visibles.
- **Feedback:** Placeholders de carga esqueletales (skeletons), estados vacíos (empty states) con instrucciones orientadoras y notificaciones flotantes (toasts) no intrusivas.

### 7.5. Derivación hacia Decisiones y Reglas
Esta Propuesta UX Integral Adoptada es la base única a partir de la cual se derivan formalmente:
1. `mockups/ux/ux-decisions.md`: Decisiones técnicas transversales justificadas (`UXD-001` a `UXD-006`).
2. `mockups/ux/ux-guidelines.md`: Reglas normativas vinculantes que implementan de forma directa dichas decisiones.
