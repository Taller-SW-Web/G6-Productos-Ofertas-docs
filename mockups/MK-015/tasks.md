# Tasks — MK-015

> **Propósito y rol documental:**
> Checklist de unidades de trabajo ejecutables (qué acciones concretas deben completarse).
> Descompone el plan de ejecución (`plan.md`) en tareas atómicas, trazables y verificables.
> No duplica la especificación de pantallas ni el diseño detallado (definidos en `component-spec.md`).

## 1. Identificación

- **Mockup:** MK-015
- **Responsable:** Miguel Ángel Taco Zavala
- **Plan de referencia:** plan.md
- **Versión:** 1.0.0
- **Estado general:** DoR completado (T01–T05 listos, T10+ en espera de base raw)

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
2. **Gestión de bloqueos:** Si una tarea queda `BLOCKED`, registrar la causa y la fuente/documento que debe resolverse en la sección 9 (Registro de bloqueos).
3. **Estructura estándar para tareas principales:** Las tareas de implementación y verificación relevantes deben estructurarse con:
   - **Entrada:** Referencia documental o insumo previo requerido.
   - **Acción:** Operación técnica o validación concreta a realizar.
   - **Salida esperada:** Artefacto o resultado medible producido.
   - **Verificación:** Criterio objetivo que confirma su cumplimiento.
4. **No duplicación:** `tasks.md` gestiona unidades de trabajo operativas; no duplica el contenido de las pantallas ni las especificaciones detalladas de `component-spec.md`.

## 3. Preparación

- [x] **MK-015-T01 — P0:** Confirmar Propuesta UX integral, UX Guidelines y UX Decisions del módulo vigentes. `[DONE]`
- [x] **MK-015-T02 — P0:** Confirmar `component-spec.md` aprobado y sin preguntas abiertas bloqueantes. `[DONE]`
- [x] **MK-015-T03 — P0 — Preparar fixtures deterministas** `[DONE]`
  - **Entrada:** `component-spec.md`, sección 13.
  - **Acción:** Crear especificación de datos de prueba deterministas.
  - **Salida esperada:** Datasets para estados default, loading, empty y error listos para consumir.
  - **Verificación:** Fixtures válidos y especificados en component-spec.
- [x] **MK-015-T04 — P0:** Confirmar versión de `../DESIGN.md` e identificar componentes DS‑CXX, variantes y tokens a reutilizar conforme al component-spec. `[DONE]`
- [x] **MK-015-T05 — P0:** Identificar pantalla ancla (`MK-015-S01`) y alinear patrones visuales comunes. `[DONE]`

## 4. Implementación por pantalla

### MK-015-S01 — Control de stock

- [ ] **MK-015-T10 — P0 — Implementar estructura de MK-015-S01** `[TODO]`
  - **Entrada:** `component-spec.md`, sección 10 (S01).
  - **Acción:** Implementar las zonas y jerarquía definidas.
  - **Salida esperada:** Ruta `/MK015/S01` renderizable y navegable directamente.
  - **Verificación:** Todas las zonas obligatorias presentes y sin elementos inventados.

- [ ] **MK-015-T11 — P0 — Implementar componentes específicos y compartidos de S01** `[TODO]`
  - **Entrada:** `component-spec.md` (secciones 8 y 9) y Design System.
  - **Acción:** Integrar componentes compartidos y construir componentes específicos requeridos.
  - **Salida esperada:** Componentes integrados en `/MK015/S01` según la jerarquía establecida.
  - **Verificación:** Coincidencia con la especificación conceptual sin componentes inventados.

- [ ] **MK-015-T12 — P0 — Implementar interacción principal y navegación de S01** `[TODO]`
  - **Entrada:** `component-spec.md` (secciones 6 y 10) y `FLOW-015`.
  - **Acción:** Conectar eventos de acción primaria y transiciones de flujo.
  - **Salida esperada:** Navegación hacia pantallas de destino y feedback operativo.
  - **Verificación:** Flujo interactivo navegable según Flow sin rutas rotas ni errores en consola.

- [ ] **MK-015-T13 — P0 — Implementar estado default con fixtures en S01** `[TODO]`
  - **Entrada:** `component-spec.md` (sección 13) y fixture `default`.
  - **Acción:** Cargar datos de prueba representativos del caso exitoso.
  - **Salida esperada:** Pantalla poblada con datos realistas consistentes con contratos API.
  - **Verificación:** Renderizado completo sin campos vacíos anómalos en viewport 1440 px.

- [ ] **MK-015-T14 — P0 — Implementar estados P0 alternativos en S01** `[TODO]`
  - **Entrada:** `component-spec.md` (sección 13) y fixtures correspondientes (`loading`, `empty`, `error`).
  - **Acción:** Configurar mecanismos deterministas para inspeccionar estados de carga, vacío y error.
  - **Salida esperada:** Estados alternativos renderizables de forma determinista.
  - **Verificación:** Mensajes de error accionables y estados vacíos conformes a UX Guidelines.

- [ ] **MK-015-T15 — P1:** Ajustar copy y microtexto conforme a UX Guidelines. `[TODO]`
- [ ] **MK-015-T16 — P0:** Verificar Flow y coherencia de navegación integral. `[TODO]`

### MK-015-S02 — Detalle del saldo

- [ ] **MK-015-T20 — P0 — Implementar estructura de MK-015-S02** `[TODO]`
  - **Entrada:** `component-spec.md`, sección 10 (S02).
  - **Acción:** Implementar las zonas y jerarquía definidas.
  - **Salida esperada:** Ruta `/MK015/S02` renderizable directamente.
  - **Verificación:** Estructura completa y ruta operativa independiente.

- [ ] **MK-015-T21 — P0 — Implementar componentes y estados de S02** `[TODO]`
  - **Entrada:** `component-spec.md` (secciones 9, 10 y 13).
  - **Acción:** Construir componentes y enlazar fixtures de estados P0 para S02.
  - **Salida esperada:** Pantalla interactiva en ruta `/MK015/S02`.
  - **Verificación:** Datos visibles y estados requeridos comprobables.

- [ ] **MK-015-T22 — P0:** Implementar drawer `DS‑C20` 640 px para detalle de saldo. `[TODO]`
- [ ] **MK-015-T23 — P0:** Implementar LUX‑02 (drawer vs vista completa). `[TODO]`

### MK-015-S03 — Configuración de umbrales

- [ ] **MK-015-T30 — P1:** Implementar estructura de MK-015-S03. `[TODO]`
- [ ] **MK-015-T31 — P1:** Implementar componente umbral `DS‑C04 NumberInput`. `[TODO]`
- [ ] **MK-015-T32 — P1:** Implementar botón “Aplicar” y validación. `[TODO]`

### MK-015-S04 — Traslados pendientes

- [ ] **MK-015-T40 — P0:** Implementar estructura de MK-015-S04. `[TODO]`
- [ ] **MK-015-T41 — P0:** Implementar lista de traslados con estados EN_TRANSITO/RECIBIDO_PARCIAL/COMPLETADO_CON_DISCREPANCIA. `[TODO]`
- [ ] **MK-015-T42 — P0:** Enlazar a recepción `POST …/traslados/{id}/recepciones`. `[TODO]`

### MK-015-S05 — Registrar recepción

- [ ] **MK-015-T50 — P0:** Implementar estructura de MK-015-S05. `[TODO]`
- [ ] **MK-015-T51 — P0:** Implementar confirmación inline (LUX‑03) sin modal anidado. `[TODO]`
- [ ] **MK-015-T52 — P0:** Implementar campos: Cantidad recibida, Disposición (Reingresar/Mantener bloqueado/Confirmar merma), Nota opcional, “Esta es la recepción final”. `[TODO]`
- [ ] **MK-015-T53 — P0:** Mostrar texto literal WF‑015: “El traslado se cerrará con una discrepancia. Las unidades faltantes no se agregarán al inventario.” `[TODO]`
- [ ] **MK-015-T54 — P0:** Verificar que no se inventen cifras de faltantes. `[TODO]`

### 5. Normalización

- [ ] **MK-015-T55 — P0:** Normalizar arquitectura de código y componentes `[TODO]`
  - **Entrada:** Código en `prototipo/src/pantallas/MK015` y convenciones del Design System.
  - **Acción:** Sustituir componentes ad hoc por componentes centralizados de Mantine / Design System.
  - **Salida esperada:** Código desacoplado, modular y limpio de estilos inline huérfanos.
  - **Verificación:** Build exitoso sin warnings ni dependencias no autorizadas.
- [ ] **MK-015-T56 — P0:** Normalizar colores con tokens oficiales del tema. `[TODO]`
- [ ] **MK-015-T57 — P0:** Normalizar espaciados, bordes y radios según escala del módulo. `[TODO]`
- [ ] **MK-015-T58 — P0:** Aplicar escala tipográfica centralizada. `[TODO]`
- [ ] **MK-015-T59 — P0:** Sustituir iconos ad hoc exclusivamente por Tabler Icons. `[TODO]`
- [ ] **MK-015-T60 — P0:** Eliminar términos técnicos indebidos o nombres de base de datos visibles al usuario. `[TODO]`
- [ ] **MK-015-T61 — P0:** Revisar semántica HTML, etiquetas y accesibilidad básica (contraste, foco). `[TODO]`

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-015-T62 — P0:** Validar cobertura estricta de SPEC sin reglas inventadas. `[TODO]`
- [ ] **MK-015-T63 — P0:** Validar criterios de aceptación de historias de usuario (HU). `[TODO]`
- [ ] **MK-015-T64 — P0:** Validar correspondencia con Wireframe (WF). `[TODO]`
- [ ] **MK-015-T65 — P0:** Validar transiciones completas según Flow. `[TODO]`
- [ ] **MK-015-T66 — P0:** Validar cumplimiento de UX Guidelines normativas del módulo. `[TODO]`
- [ ] **MK-015-T67 — P0:** Validar aplicación de UX Decisions (`UXD‑XXX`) transversales. `[TODO]`
- [ ] **MK-015-T68 — P0:** Validar justificación de decisiones locales (`LUX‑XX`) en `component-spec.md`. `[TODO]`
- [ ] **MK-015-T69 — P0:** Validar fidelidad al Design System. `[TODO]`
- [ ] **MK-015-T70 — P0:** Validar comportamiento en viewport canónico PC (1440 px) sin overflow horizontal. `[TODO]`
- [ ] **MK-015-T71 — P0 — Registrar evidencias y hallazgos de autovalidación** `[TODO]`
  - **Entrada:** Inspección técnica y funcional de pantallas y estados.
  - **Acción:** Completar secciones 2 a 10 de `validation-report.md`.
  - **Salida esperada:** Secciones de pantallas, trazabilidad de ejecución, UI, PC y accesibilidad documentadas.
  - **Verificación:** Cero hallazgos bloqueantes ni importantes requeridos abiertos en autovalidación.

## 7. Revisión transversal y visto bueno

- [ ] **MK-015-T70 — P0:** Confirmar en `validation-report.md` que la autovalidación local está completa y cerrada. `[TODO]`
- [ ] **MK-015-T71 — P0:** Solicitar formalmente revisión transversal a Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-015-T72 — P0:** Atender y corregir todos los hallazgos bloqueantes e importantes formulados en la revisión transversal. `[TODO]`
- [ ] **MK-015-T73 — P0:** Obtener visto bueno formal de Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-015-T74 — P0 — Registrar estado `APROBADO PARA FIGMA`** `[TODO]`
  - **Entrada:** Visto bueno otorgado por Leonardo Vera Rodríguez.
  - **Acción:** Registrar estado en la sección de revisión transversal de `validation-report.md`.
  - **Salida esperada:** Sección de revisión transversal en estado `APROBADO PARA FIGMA`.
  - **Verificación:** Confirmación formal del registrador con fecha.

## 8. Figma y cierre

- [ ] **MK-015-T75 — P0:** Trasladar fielmente a Figma la versión del prototipo aprobada para Figma. `[TODO]`
- [ ] **MK-015-T76 — P0:** Verificar fidelidad punto a punto entre Figma y el prototipo aprobado. `[TODO]`
- [ ] **MK-015-T77 — P0:** Confirmar que todas las pantallas P0 requeridas están completas en Figma. `[TODO]`
- [ ] **MK-015-T78 — P0:** Registrar enlace canónico de Figma en `validation-report.md`. `[TODO]`
- [ ] **MK-015-T79 — P0 — Cierre de Quality Gates y resultado APROBADO** `[TODO]`
  - **Entrada:** Gates A‑F cumplidos satisfactoriamente.
  - **Acción:** Completar sección cierre en `validation-report.md` y declarar resultado general.
  - **Salida esperada:** `validation-report.md` con **Resultado general = APROBADO**.
  - **Verificación:** Todos los gates cerrados, enlace Figma verificado y cero bloqueos abiertos.

## 9. Registro de bloqueos

Registrar cualquier tarea que pase a estado `BLOCKED`, indicando la causa, el documento afectado y la condición requerida para reanudar la ejecución.

| Tarea | Fecha | Causa del bloqueo | Fuente / Documento a resolver | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|---|---|
| [MK-015‑TXX] | [AAAA‑MM‑DD] | [Descripción de la contradicción o información faltante] | [SPEC‑015 / FLOW / Contrato API] | [Nombre / Rol] | [Acción o aclaración requerida] | Activo / Resuelto |