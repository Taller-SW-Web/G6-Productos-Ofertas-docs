# Tasks — MK-016

> **Instanciación:** Copiar a `mockups/MK-016/tasks.md`. Los enlaces relativos de esta plantilla se interpretan desde ese destino; el Design System está en `../DESIGN.md`.

> **Propósito y rol documental:**
> Checklist de unidades de trabajo ejecutables (qué acciones concretas deben completarse).
> Descompone el plan de ejecución (`plan.md`) en tareas atómicas, trazables y verificables.
> No duplica la especificación de pantallas ni el diseño detallado (definidos en `component-spec.md`).

## 1. Identificación

- **Mockup:** MK-016
- **Responsable:** Miguel Ángel Taco Zavala
- **Plan de referencia:** `plan.md`
- **Estado general:** En progreso

## 2. Convenciones y reglas de ejecución

### Prioridades
- `P0`: Obligatorio y crítico para validar alcance funcional mínimo y gates.
- `P1`: Necesario para cierre formal y refinamiento.
- `P2`: Mejora incremental no bloqueante.

### Estados de tarea
- `TODO`: Tarea pendiente de inicio.
- `DOING`: Tarea en ejecución activa.
- `BLOCKED`: Tarea detenida por impedimento o condición de parada.
- `REVIEW`: Tarea completada pendiente de verificación o revisión.
- `DONE`: Tarea verificada y finalizada con evidencia comprobable.

### Reglas obligatorias de ejecución
1. **Criterio de cierre:** Una tarea solo puede marcarse `DONE` cuando su criterio de verificación sea comprobable con evidencia objetiva.
2. **Gestión de bloqueos:** Si una tarea queda `BLOCKED`, registrar la causa y la fuente/documento que debe resolverse antes de continuar en la sección 9 (Registro de bloqueos).
3. **Estructura estándar para tareas principales:** Las tareas de implementación y verificación relevantes deben estructurarse con:
   - **Entrada:** Referencia documental o insumo previo requerido.
   - **Acción:** Operación técnica o validación concreta a realizar.
   - **Salida esperada:** Artefacto o resultado medible producido.
   - **Verificación:** Criterio objetivo que confirma su cumplimiento.
4. **No duplicación:** `tasks.md` gestiona unidades de trabajo operativas; no duplica el contenido de las pantallas ni las especificaciones detalladas de `component-spec.md`.

## 3. Preparación

- [x] **MK-016-T01 — P0:** Confirmar Propuesta UX integral, UX Guidelines y UX Decisions del módulo vigentes. `[DONE]`
- [x] **MK-016-T02 — P0:** Confirmar `component-spec.md` aprobado y sin preguntas abiertas bloqueantes. `[DONE]`
- [x] **MK-016-T03 — P0 — Preparar fixtures deterministas** `[DONE]`
  - **Entrada:** `component-spec.md`, sección 13.
  - **Acción:** Crear especificación de datos de prueba estructurados para estados default, loading, empty y error.
  - **Salida esperada:** Datasets consistentes con saldos en Tienda Miraflores y Almacén Central listos para consumir.
  - **Verificación:** Fixtures válidos con `available = max(on_hand - reserved - blocked, 0)` sin valores negativos.
- [x] **MK-016-T04 — P0:** Confirmar versión de [mockups/DESIGN.md](../DESIGN.md) e identificar componentes DS-CXX, variantes y tokens a reutilizar conforme al component-spec. `[DONE]`
- [x] **MK-016-T05 — P0:** Identificar pantalla ancla (`MK-016-S01`) y alinear patrones visuales comunes. `[DONE]`

## 4. Implementación por pantalla

### MK-016-S01 — Dashboard analítico y alertas de stock

- [ ] **MK-016-T10 — P0 — Implementar estructura de MK-016-S01** `[TODO]`
  - **Entrada:** `component-spec.md`, sección 10 (S01).
  - **Acción:** Implementar cabecera, grilla de KPIs superiores (4+3), barra de filtros, panel de alertas, tabla de distribución y tabla de inventario por SKU.
  - **Salida esperada:** Ruta `/MK016/S01` renderizable y navegable directamente en 1440 px.
  - **Verificación:** Todas las zonas obligatorias presentes y sin elementos inventados.

- [ ] **MK-016-T11 — P0 — Implementar componentes específicos y compartidos de S01** `[TODO]`
  - **Entrada:** `component-spec.md` (secciones 8 y 9) y Design System.
  - **Acción:** Integrar `DS-C19` (KPIs), `DS-C17` (Table), `DS-C14` (Badge), `DS-C13` (FilterBar) y `DS-C15` (Notice/Alert).
  - **Salida esperada:** Componentes integrados en `/MK016/S01` según la jerarquía establecida.
  - **Verificación:** Coincidencia con la especificación conceptual sin componentes inventados.

- [ ] **MK-016-T12 — P0 — Implementar interacción principal y navegación de S01** `[TODO]`
  - **Entrada:** `component-spec.md` (secciones 6 y 10) y `FLOW-016`.
  - **Acción:** Conectar filtrado por texto, selectores de ubicación y estado, y enlaces contextuales hacia MK-015.
  - **Salida esperada:** Filtrado reactivo en tiempo real sin recargar página y navegación hacia MK-015 para gestión de incidencias.
  - **Verificación:** Filtrado determinista en tabla principal y enlaces operativos activos.

- [ ] **MK-016-T13 — P0 — Implementar estado default con fixtures en S01** `[TODO]`
  - **Entrada:** `component-spec.md` (sección 13) y fixture `default`.
  - **Acción:** Cargar datos de prueba representativos del caso estándar (128 disponibles, 9 bloqueadas, 6 stock bajo, 3 agotados).
  - **Salida esperada:** Pantalla poblada con datos realistas consistentes con contratos API.
  - **Verificación:** Renderizado completo sin campos vacíos anómalos en viewport 1440 px.

- [ ] **MK-016-T14 — P0 — Implementar estados P0 alternativos en S01** `[TODO]`
  - **Entrada:** `component-spec.md` (sección 13) y fixtures correspondientes (`loading`, `empty`, `error`).
  - **Acción:** Configurar parámetros deterministas (`?estado=loading`, `?estado=empty`, `?estado=error`) para inspeccionar cada estado.
  - **Salida esperada:** Skeletons de carga, mensaje de empty state con botón de reseteo de filtros y alerta de error accionable.
  - **Verificación:** Reproducción determinista y visualmente consistente de cada estado alternativo.

- [ ] **MK-016-T15 — P1:** Ajustar copy y microtexto conforme a UX Guidelines (prohibición estricta de `on_hand`, `reserved`, `blocked`, `available` en cabeceras). `[TODO]`
- [ ] **MK-016-T16 — P0:** Verificar Flow y coherencia de navegación integral con MK-015. `[TODO]`

## 5. Normalización

- [ ] **MK-016-T50 — P0:** Normalizar arquitectura de código y componentes `[TODO]`
  - **Entrada:** Código en `prototipo/src/pantallas/MK016` y convenciones del Design System.
  - **Acción:** Consolidar estructura modular alineada al Design System y convenciones del módulo.
  - **Salida esperada:** Código desacoplado, modular y limpio de estilos inline huérfanos.
  - **Verificación:** Código auditado sin advertencias ni librerías no autorizadas.
- [ ] **MK-016-T51 — P0:** Normalizar colores con tokens oficiales del tema (`--color-neutral-*`, `--color-success-*`, `--color-warning-*`). `[TODO]`
- [ ] **MK-016-T52 — P0:** Normalizar espaciados, bordes y radios según escala del módulo (`8px`, `12px`, `16px`, `24px`). `[TODO]`
- [ ] **MK-016-T53 — P0:** Aplicar escala tipográfica centralizada (Inter, 12 px, 14 px, 16 px, 20 px, 28 px, 32 px). `[TODO]`
- [ ] **MK-016-T54 — P0:** Sustituir iconos ad hoc exclusivamente por Tabler Icons. `[TODO]`
- [ ] **MK-016-T55 — P0:** Eliminar términos técnicos indebidos o nombres de base de datos visibles al usuario. `[TODO]`
- [ ] **MK-016-T56 — P0:** Revisar semántica HTML, etiquetas y accesibilidad básica (contraste, foco, nombres accesibles). `[TODO]`

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-016-T60 — P0:** Validar cobertura estricta de SPEC-016 sin reglas inventadas (solo lectura, sin mutaciones directas). `[TODO]`
- [ ] **MK-016-T61 — P0:** Validar criterios de aceptación de historias de usuario (HU-016 CA-01 a CA-11). `[TODO]`
- [ ] **MK-016-T62 — P0:** Validar correspondencia con Wireframe (WF-016). `[TODO]`
- [ ] **MK-016-T63 — P0:** Validar transiciones completas según Flow (actualización reactiva y enlaces a MK-015). `[TODO]`
- [ ] **MK-016-T64 — P0:** Validar cumplimiento de UX Guidelines normativas del módulo. `[TODO]`
- [ ] **MK-016-T65 — P0:** Validar aplicación de UX Decisions (`UXD-001`, `UXD-011`) transversales. `[TODO]`
- [ ] **MK-016-T66 — P0:** Validar justificación de decisiones locales (`LUX-01`, `LUX-04`) en `component-spec.md`. `[TODO]`
- [ ] **MK-016-T67 — P0:** Validar fidelidad al Design System. `[TODO]`
- [ ] **MK-016-T68 — P0:** Validar comportamiento en viewport canónico PC (1440 px) sin overflow horizontal. `[TODO]`
- [ ] **MK-016-T69 — P0 — Registrar evidencias y hallazgos de autovalidación** `[TODO]`
  - **Entrada:** Inspección técnica y funcional de pantallas y estados.
  - **Acción:** Completar secciones 2 a 10 de `validation-report.md`.
  - **Salida esperada:** Documento formal con evidencia de trazabilidad completa.
  - **Verificación:** Cero hallazgos bloqueantes abiertos en autovalidación.

## 7. Revisión transversal y visto bueno

- [ ] **MK-016-T70 — P0:** Confirmar en `validation-report.md` que la autovalidación local está completa y cerrada. `[TODO]`
- [ ] **MK-016-T71 — P0:** Solicitar formalmente revisión transversal a Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-016-T72 — P0:** Atender y corregir todos los hallazgos bloqueantes e importantes formulados en la revisión transversal. `[TODO]`
- [ ] **MK-016-T73 — P0:** Obtener visto bueno formal de Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-016-T74 — P0 — Registrar estado `APROBADO PARA FIGMA`** `[TODO]`
  - **Entrada:** Visto bueno otorgado por Leonardo Vera Rodríguez.
  - **Acción:** Registrar estado en la sección de revisión transversal de `validation-report.md`.
  - **Salida esperada:** Sección de revisión transversal en estado `APROBADO PARA FIGMA`.
  - **Verificación:** Confirmación formal del registrador con fecha.

## 8. Figma y cierre

- [ ] **MK-016-T75 — P0:** Trasladar fielmente a Figma la versión del prototipo aprobada para Figma. `[TODO]`
- [ ] **MK-016-T76 — P0:** Verificar fidelidad punto a punto entre Figma y el prototipo aprobado. `[TODO]`
- [ ] **MK-016-T77 — P0:** Confirmar que la pantalla P0 requerida está completa en Figma. `[TODO]`
- [ ] **MK-016-T78 — P0:** Registrar enlace canónico de Figma en `validation-report.md`. `[TODO]`
- [ ] **MK-016-T79 — P0 — Cierre de Quality Gates y resultado APROBADO** `[TODO]`
  - **Entrada:** Gates A–F cumplidos satisfactoriamente.
  - **Acción:** Completar sección cierre en `validation-report.md` y declarar resultado general.
  - **Salida esperada:** `validation-report.md` con **Resultado general = APROBADO**.
  - **Verificación:** Todos los gates cerrados, enlace Figma verificado y cero bloqueos abiertos.

## 9. Registro de bloqueos

| Tarea | Fecha | Causa del bloqueo | Fuente / Documento a resolver | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|---|---|
| — | — | Ningún bloqueo activo | — | — | — | Resuelto |
