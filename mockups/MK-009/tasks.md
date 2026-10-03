# Tasks — MK-009

## 1. Identificación

- **Mockup:** MK-009 — Gestión de características de producto
- **Responsable:** Leonardo Lopez (rama `lopez`)
- **Plan de referencia:** [plan.md](plan.md) v1.1
- **Estado general:** **En revisión** — documentación redactada; preparación e implementación bloqueadas hasta la aprobación del `component-spec.md`.

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
1. **Criterio de cierre:** una tarea solo puede marcarse `DONE` cuando su criterio de verificación sea comprobable con evidencia objetiva.
2. **Gestión de bloqueos:** toda tarea `BLOCKED` registra causa y fuente a resolver en §9.
3. **Estructura estándar:** entrada, acción, salida esperada y verificación.
4. **No duplicación:** este archivo gestiona unidades de trabajo; el contenido de pantallas reside en `component-spec.md`.

## 3. Preparación

- [ ] **MK-009-T01 — P0:** Confirmar vigentes [propuesta-ux.md](../ux/propuesta-ux.md), [ux-guidelines.md](../ux/ux-guidelines.md) y [ux-decisions.md](../ux/ux-decisions.md). `[TODO]`
- [ ] **MK-009-T02 — P0:** Obtener la aprobación de [component-spec.md](component-spec.md) y resolver las preguntas abiertas Q-01 y Q-02. `[BLOCKED: component-spec en estado En revisión]`
- [ ] **MK-009-T03 — P0 — Preparar fixtures deterministas** `[TODO]`
  - **Entrada:** `component-spec.md` §13.
  - **Acción:** crear datasets en `prototipo/src/pantallas/MK009` para default, loading, empty, sin resultados, error, sesión, límites de TEXTO y LISTA, errores de NUMERO, tipo inmutable, renombrado, comprobación pendiente, confirmada, rechazada y no concluyente, y estado inactivo con reactivación.
  - **Salida esperada:** fixtures importables por los componentes de pantalla.
  - **Verificación:** cada fixture se carga por parámetro de consulta y produce un estado distinguishable y determinista.
- [ ] **MK-009-T04 — P0:** Confirmar [DESIGN.md](../DESIGN.md) 1.0.0 y el catálogo de componentes DS-C01, DS-C02, DS-C03, DS-C05, DS-C06, DS-C12, DS-C14, DS-C17, DS-C19, DS-C21, DS-C22, DS-C24, DS-C25 y DS-C28. `[TODO]`
- [ ] **MK-009-T05 — P0:** Identificar MK-009-S01 como pantalla ancla y alinear jerarquía, densidad y microtexto con el resto del módulo. `[TODO]`

## 4. Implementación por pantalla

### MK-009-S01 — Listado de características

- [ ] **MK-009-T10 — P0 — Implementar estructura de S01** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S01) y §5.
  - **Acción:** construir cabecera con migas, barra con Crear característica y filtro, y tabla con nombre, tipo, estado, unidad, valores y acciones.
  - **Salida esperada:** ruta `/MK009/S01` renderizable y navegable directamente.
  - **Verificación:** las tres zonas obligatorias están presentes y no hay elementos inventados.
- [ ] **MK-009-T11 — P0 — Construir MK-009-C01 e integrar componentes de S01** `[TODO]`
  - **Entrada:** `component-spec.md` §8, §9 y §10 (S01).
  - **Acción:** implementar el listado con badges de tipo y estado sobre DS-C17 y DS-C14, y la acción Valores solo para LISTA.
  - **Salida esperada:** listado funcional y coherente con los tres tipos.
  - **Verificación:** default, loading, empty, sin resultados y error se reproducen desde los fixtures de T03.
- [ ] **MK-009-T12 — P0 — Implementar navegación de S01** `[TODO]`
  - **Entrada:** `component-spec.md` §6 y FLOW-009 §4.1 a §4.4.
  - **Acción:** conectar Crear característica, Editar, Valores, Estado y Ver detalle hacia sus destinos.
  - **Salida esperada:** navegación operativa sin rutas rotas.
  - **Verificación:** el flujo es navegable de extremo a extremo sin errores en consola.

### MK-009-S02 y MK-009-S03 — Crear y editar característica

- [ ] **MK-009-T13 — P0 — Implementar estructura de S02 y S03** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S02, S03).
  - **Acción:** implementar el formulario de alta con revelado condicional de unidad y límite, y el formulario de edición con tipo deshabilitado.
  - **Salida esperada:** rutas `/MK009/S02` y `/MK009/S03` renderizables directamente.
  - **Verificación:** ambas rutas existen de forma independiente y conservan el contexto que las originó.
- [ ] **MK-009-T14 — P0 — Construir MK-009-C02 y aplicar los límites de tipo** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §13; HU-009 CA-01, CA-02 y CA-03.
  - **Acción:** implementar la selección de tipo, la unidad obligatoria para NUMERO, el límite de 100 para TEXTO y el aviso de límite de valores para LISTA.
  - **Salida esperada:** formularios con validación coherente con los fixtures `texto-excedido`, `numero-sin-unidad` y `numero-formato`.
  - **Verificación:** ningún campo se muestra cuando no aplica y todo error aparece junto al campo afectado.
- [ ] **MK-009-T15 — P0 — Tratar el tipo como inmutable en la edición** `[TODO]`
  - **Entrada:** HU-009 CA-08 y LUX-01.
  - **Acción:** deshabilitar el selector de tipo en S03 y mostrar el aviso de inmutabilidad.
  - **Salida esperada:** no existe acción para cambiar el tipo en la edición.
  - **Verificación:** el fixture `tipo-inmutable` reproduce el comportamiento y la auditoría de código no encuentra actualización del tipo.

### MK-009-S06 — Detalle de característica

- [ ] **MK-009-T19 — P0 — Implementar S06 con identificadores estables** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S06) y HU-009 CA-05.
  - **Acción:** construir la ficha con tipo, estado, unidad, límites, valores y sus identificadores estables.
  - **Salida esperada:** ruta `/MK009/S06` operativa con default, loading, error y no encontrada.
  - **Verificación:** el fixture `detalle-caracteristica` permite distinguir identificador de característica e identificador de valor.

### MK-009-S04, S04-P y S04-R — Valores permitidos y baja segura

- [ ] **MK-009-T16 — P0 — Construir MK-009-C03 y administrar los valores LISTA** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §10 (S04); HU-009 CA-03, CA-04 y CA-06.
  - **Acción:** implementar el alta de valores, el contador de activos con límite y el renombrado en línea que conserva el identificador mediante `PATCH` del valor.
  - **Salida esperada:** ruta `/MK009/S04` operativa; el renombrado propaga `taxonomy.characteristic-value.updated` con IDs estables y etiqueta vigente.
  - **Verificación:** el fixture `valor-renombrado` mantiene el identificador y el fixture `lista-limite` deshabilita el alta.
- [ ] **MK-009-T17 — P0 — Modelar la baja segura como admisión** `[TODO]`
  - **Entrada:** SPEC-009 R7, HU-009 CA-09 y CA-10, `component-spec.md` §10 (S04-P).
  - **Acción:** implementar la confirmación previa y el seguimiento por `GET /api/v1/taxonomia/operaciones/{operationId}` para `CHARACTERISTIC_VALUE`.
  - **Salida esperada:** ruta `/MK009/S04-P` operativa; mientras se verifica, el valor no está disponible para nuevas asignaciones.
  - **Verificación:** el copy de S04 y S04-P no afirma baja completada antes del resultado y el valor no se reenvía.
- [ ] **MK-009-T18 — P0 — Implementar S04-R y los casos no concluyentes** `[TODO]`
  - **Entrada:** WF-009 §4 y §5, `component-spec.md` §10 (S04-R).
  - **Acción:** implementar el rechazo por uso activo y el aviso genérico cuando no hay resultado fiable.
  - **Salida esperada:** ruta `/MK009/S04-R` operativa con el motivo de uso activo.
  - **Verificación:** los fixtures `valor-baja-rechazada` y `valor-baja-no-concluyente` reproducen cada caso y el valor permanece intacto.

### MK-009-S05 — Estado de la característica

- [ ] **MK-009-T20 — P0 — Implementar S05 conservando la identidad** `[TODO]`
  - **Entrada:** SPEC-009 R8, HU-009 CA-11 y CA-12, WF-009 §4.1 y §5, `component-spec.md` §10 (S05).
  - **Acción:** implementar la desactivación y la reactivación de la característica completa, indicando que el identificador se conserva y que la característica inactiva no se ofrece para nuevas asociaciones.
  - **Salida esperada:** ruta `/MK009/S05` operativa; tras la operación, el listado mantiene la misma fila con el nuevo estado.
  - **Verificación:** el fixture `reactivacion-ok` restituye la misma identidad con su tipo y sus valores.

## 5. Normalización

- [ ] **MK-009-T50 — P0 — Normalizar arquitectura y componentes** `[TODO]`
  - **Entrada:** código en `prototipo/src/pantallas/MK009` y convenciones del Design System.
  - **Acción:** sustituir componentes ad hoc por componentes centralizados de Mantine y el Design System.
  - **Salida esperada:** código modular sin estilos inline huérfanos.
  - **Verificación:** build exitoso sin warnings ni dependencias no autorizadas.
- [ ] **MK-009-T51 — P0:** Normalizar colores con tokens oficiales del tema. `[TODO]`
- [ ] **MK-009-T52 — P0:** Normalizar espaciados, bordes y radios según la escala del módulo. `[TODO]`
- [ ] **MK-009-T53 — P0:** Aplicar la escala tipográfica centralizada. `[TODO]`
- [ ] **MK-009-T54 — P0:** Sustituir iconos ad hoc exclusivamente por Tabler Icons. `[TODO]`
- [ ] **MK-009-T55 — P0:** Eliminar términos técnicos y nombres de base de datos visibles al usuario. `[TODO]`
- [ ] **MK-009-T56 — P0:** Revisar semántica HTML y accesibilidad básica, incluida la edición en línea de valores. `[TODO]`

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-009-T60 — P0:** Validar cobertura estricta de SPEC-009 sin reglas inventadas, incluida la ausencia de asociación a tipos de producto, categorías o marcas. `[TODO]`
- [ ] **MK-009-T61 — P0:** Validar los 12 criterios de aceptación de HU-009 contra la matriz de `component-spec.md` §2.1. `[TODO]`
- [ ] **MK-009-T62 — P0:** Validar correspondencia con WF-009, incluidas §4, §4.1 y el copy de §5. `[TODO]`
- [ ] **MK-009-T63 — P0:** Validar transiciones completas según FLOW-009. `[TODO]`
- [ ] **MK-009-T64 — P0:** Validar cumplimiento de UX Guidelines normativas del módulo. `[TODO]`
- [ ] **MK-009-T65 — P0:** Validar aplicación de UXD-002, UXD-004, UXD-006, UXD-009, UXD-012 y UXD-013. `[TODO]`
- [ ] **MK-009-T66 — P0:** Validar justificación de LUX-01, LUX-02 y LUX-03. `[TODO]`
- [ ] **MK-009-T67 — P0:** Validar fidelidad al Design System y reutilización de componentes compartidos. `[TODO]`
- [ ] **MK-009-T68 — P0:** Validar las ocho rutas inventariadas, incluidas `/MK009/S04-P` y `/MK009/S04-R`, y el comportamiento en 1440 px sin overflow horizontal. `[TODO]`
- [ ] **MK-009-T69 — P0 — Registrar evidencias de autovalidación** `[TODO]`
  - **Entrada:** inspección técnica y funcional de pantallas, estados y rutas.
  - **Acción:** documentar pantallas, trazabilidad de ejecución, UI, PC y accesibilidad, siguiendo la estructura de la plantilla de `validation-report.md`.
  - **Salida esperada:** evidencias que sustentan la matriz de §2.1.
  - **Verificación:** cero hallazgos bloqueantes ni importantes requeridos abiertos.

## 7. Revisión transversal y visto bueno

- [ ] **MK-009-T70 — P0:** Confirmar que la autovalidación local está completa y cerrada. `[TODO]`
- [ ] **MK-009-T71 — P0:** Solicitar formalmente revisión transversal a Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-009-T72 — P0:** Atender y corregir todos los hallazgos bloqueantes e importantes. `[TODO]`
- [ ] **MK-009-T73 — P0:** Obtener visto bueno formal de Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-009-T74 — P0 — Registrar estado APROBADO PARA FIGMA** `[TODO]`
  - **Entrada:** visto bueno otorgado por el revisor.
  - **Acción:** registrar el estado de revisión transversal.
  - **Salida esperada:** sección de revisión transversal en estado `APROBADO PARA FIGMA`.
  - **Verificación:** confirmación formal del revisor con fecha.

## 8. Figma y cierre

- [ ] **MK-009-T75 — P0:** Trasladar fielmente a Figma la versión aprobada para Figma. `[TODO]`
- [ ] **MK-009-T76 — P0:** Verificar fidelidad punto a punto entre Figma y el prototipo aprobado. `[TODO]`
- [ ] **MK-009-T77 — P0:** Confirmar que las ocho pantallas P0 están completas en Figma. `[TODO]`
- [ ] **MK-009-T78 — P0:** Registrar el enlace canónico de Figma. `[TODO]`
- [ ] **MK-009-T79 — P0 — Cierre de Quality Gates y resultado APROBADO** `[TODO]`
  - **Entrada:** Gates A, B, C, D, E y F cumplidos.
  - **Acción:** cerrar el reporte de validación y declarar el resultado general.
  - **Salida esperada:** **Resultado general = APROBADO**.
  - **Verificación:** todos los gates cerrados y cero bloqueos abiertos.

## 9. Registro de bloqueos

| Tarea | Fecha | Causa del bloqueo | Fuente / Documento a resolver | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|---|---|
| MK-009-T02 | 2026-10-03 | El `component-spec.md` v1.1 está en estado En revisión; Q-01 y Q-02 siguen abiertas | Revisión documental del `component-spec.md` | Leonardo Lopez | Aprobación del component-spec y cierre de Q-01 (exposición de los límites configurables) y Q-02 (detalle de la comprobación de uso) | Activo |
| MK-009-T14 | 2026-10-03 | Depende de Q-01 para distinguir límites configurables de constantes del MVP | SPEC-009 y Contrato API | Leonardo Lopez con Taxonomía | Respuesta documentada a Q-01 | Activo |
| MK-009-T17 | 2026-10-03 | Depende de Q-02 para representar el motivo de uso activo | AsyncAPI 0.4.0 y Contrato API | Leonardo Lopez con Taxonomía | Respuesta documentada a Q-02 | Activo |
