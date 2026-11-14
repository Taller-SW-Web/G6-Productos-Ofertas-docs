# Tasks — MK-010

## 1. Identificación

- **Mockup:** MK-010 — Asociación de características a tipos de producto
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

- [ ] **MK-010-T01 — P0:** Confirmar vigentes [propuesta-ux.md](../ux/propuesta-ux.md), [ux-guidelines.md](../ux/ux-guidelines.md) y [ux-decisions.md](../ux/ux-decisions.md). `[TODO]`
- [ ] **MK-010-T02 — P0:** Obtener la aprobación de [component-spec.md](component-spec.md) y resolver las preguntas abiertas Q-01 y Q-02. `[BLOCKED: component-spec en estado En revisión]`
- [ ] **MK-010-T03 — P0 — Preparar fixtures deterministas** `[TODO]`
  - **Entrada:** `component-spec.md` §13.
  - **Acción:** crear datasets en `prototipo/src/pantallas/MK010` para default, loading, vacío, sin resultados, error, sesión, sin permisos, esquema vacío y completo, límite de 20 asociaciones, asociación inválida y duplicada, obligatoriedad aplicada, versión incrementada, verificación pendiente, confirmada, rechazada y no concluyente, y estado inactivo con reactivación.
  - **Salida esperada:** fixtures importables por los componentes de pantalla.
  - **Verificación:** cada fixture se carga por parámetro de consulta y produce un estado distinguishable y determinista.
- [ ] **MK-010-T04 — P0:** Confirmar [DESIGN.md](../DESIGN.md) 1.0.0 y el catálogo de componentes DS-C01, DS-C02, DS-C03, DS-C06, DS-C10, DS-C14, DS-C17, DS-C19, DS-C21, DS-C22, DS-C24, DS-C25 y DS-C28. `[TODO]`
- [ ] **MK-010-T05 — P0:** Identificar MK-010-S02 como pantalla ancla y alinear jerarquía, densidad y microtexto con el resto del módulo. `[TODO]`

## 4. Implementación por pantalla

### MK-010-S02 — Esquema del tipo

- [ ] **MK-010-T10 — P0 — Implementar estructura de S02** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S02), §7 y WF-010 §10.
  - **Acción:** construir la cabecera con nombre, estado, contador y acciones, el indicador de versión y la tabla con Característica, Tipo de dato, Condición y Acciones.
  - **Salida esperada:** ruta `/MK010/S02` renderizable y navegable directamente.
  - **Verificación:** no existe acción de reordenar ni columna `tipo_producto_id`.
- [ ] **MK-010-T11 — P0 — Construir MK-010-C01 e implementar la tabla de asociaciones** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §10 (S02).
  - **Acción:** implementar las filas con switch de condición, acción de desasociar y retención de la fila afectada durante la verificación.
  - **Salida esperada:** tabla funcional con default, vacío, límite alcanzado, verificación pendiente y tipo inactivo.
  - **Verificación:** los fixtures `esquema-vacio`, `esquema-completo`, `limite-20` y `tipo-inactivo` reproducen cada estado.
- [ ] **MK-010-T12 — P0 — Construir MK-010-C03 y el indicador de versión** `[TODO]`
  - **Entrada:** LUX-02 y HU-010 CA-07 y CA-14.
  - **Acción:** mostrar la versión vigente junto al nombre del tipo y, tras cada cambio confirmado, el aviso de incremento y propagación a los canales.
  - **Salida esperada:** indicador actualizado y aviso sin nombres de eventos.
  - **Verificación:** el fixture `schema-version-incrementada` refleja el incremento y la propagación declarada como eventual.

### MK-010-S01, S01-E y S01-N — Tipos de producto

- [ ] **MK-010-T13 — P0 — Implementar S01 con su estado vacío y de error** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S01, S01-E) y WF-010 §9.
  - **Acción:** construir la tabla con nombre, estado, `X de N características` y acción Abrir, además de las pantallas de vacío, sin resultados y error.
  - **Salida esperada:** rutas `/MK010/S01` y `/MK010/S01-E` operativas.
  - **Verificación:** los fixtures `default`, `empty`, `sin-resultados` y `error` reproducen cada estado con su acción correspondiente.
- [ ] **MK-010-T14 — P0 — Implementar S01-N con alta ligera** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S01-N) y FLOW-010 Flujo B.
  - **Acción:** implementar el formulario de nombre requerido y la acción Crear y configurar esquema.
  - **Salida esperada:** ruta `/MK010/S01-N` operativa; tras la confirmación navega a S02 del tipo creado.
  - **Verificación:** el fixture `esquema-vacio` representa el tipo recién creado y no hay datos inventados.

### MK-010-S03 — Asociar característica

- [ ] **MK-010-T15 — P0 — Construir MK-010-C02 y controlar el límite operativo** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §13; HU-010 CA-01, CA-02 y CA-03; WF-010 §11 y §18.
  - **Acción:** implementar el selector de características activas no asociadas, el control de condición y el bloqueo del guardado al alcanzar `MAX_PRODUCT_TYPE_ATTRIBUTES` con valor inicial 20.
  - **Salida esperada:** ruta `/MK010/S03` operativa; las candidatas ya asociadas no se ofrecen y el límite se explica antes de guardar.
  - **Verificación:** los fixtures `limite-20`, `asociar-activa`, `asociar-invalida` y `asociacion-duplicada` reproducen cada caso.
- [ ] **MK-010-T16 — P0 — Registrar la asociación y su versión** `[TODO]`
  - **Entrada:** HU-010 CA-01, CA-02 y CA-07.
  - **Acción:** enviar la asociación por HTTP y reflecting la versión vigente al volver a S02.
  - **Salida esperada:** fila asociada con condición correcta y versión incrementada.
  - **Verificación:** tras asociar, la tabla de S02 muestra la nueva fila y el indicador de versión refleja el incremento.

### MK-010-S04 y S05 — Confirmaciones de baja segura

- [ ] **MK-010-T17 — P0 — Implementar S04 y S05 como admisión** `[TODO]`
  - **Entrada:** SPEC-010 R6, HU-010 CA-08 y CA-15, WF-010 §12 y §13.
  - **Acción:** implementar los diálogos de desasociación y de desactivación con el copy normativo y la solicitud de verificación segura.
  - **Salida esperada:** rutas `/MK010/S04` y `/MK010/S05` operativas; ambas conducen a S02-P ante `202`.
  - **Verificación:** ningún diálogo afirma que el cambio ya se aplicó y la fila afectada se retiene.
- [ ] **MK-010-T19 — P0 — Modelar la verificación segura de `PRODUCT_TYPE`** `[TODO]`
  - **Entrada:** HU-010 CA-11 y CA-15; AsyncAPI 0.4.0.
  - **Acción:** implementar el seguimiento de la desactivación del tipo con la misma regla de fallo cerrado que la desasociación.
  - **Salida esperada:** la desactivación solo se refleja en S02 tras resultado confirmado.
  - **Verificación:** el fixture `desactivacion-pendiente` mantiene el tipo activo hasta el resultado.

### MK-010-S02-P y S02-R — Seguimiento y rechazo

- [ ] **MK-010-T18 — P0 — Construir MK-010-C04 y modelar el seguimiento por operationId** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §13; HU-010 CA-08, CA-09, CA-10 y CA-14.
  - **Acción:** implementar la consulta a `GET /api/v1/taxonomia/operaciones/{operationId}` y los resultados pendiente, confirmada, rechazada y no concluyente.
  - **Salida esperada:** rutas `/MK010/S02-P` y `/MK010/S02-R` operativas sin reenviar la solicitud.
  - **Verificación:** el fixture `desasociacion-confirmada` retira la fila e incrementa la versión; `desasociacion-rechazada` la conserva; `verificacion-no-concluyente` informa que no se realizó ninguna modificación.
- [ ] **MK-010-T20 — P0 — Cambiar la condición con PATCH y comunicar su efecto** `[TODO]`
  - **Entrada:** HU-010 CA-06 y CA-07; SPEC-010 R4.
  - **Acción:** enviar el cambio de condición por `PATCH /api/v1/tipos-producto/{tipoProductoId}/caracteristicas/{caracteristicaId}` y mostrar el aviso de exigencia futura.
  - **Salida esperada:** condición actualizada sin desactivar productos y con versión incrementada.
  - **Verificación:** el fixture `obligatoria-aplicada` muestra «Se exigirá al volver a guardar o activar los productos que correspondan.» y el método utilizado es `PATCH`.
- [ ] **MK-010-T21 — P0 — Implementar la reactivación conservando la identidad** `[TODO]`
  - **Entrada:** HU-010 CA-12 y CA-13, `component-spec.md` §10 (S02).
  - **Acción:** habilitar Reactivar tipo sobre un tipo inactivo y reflejar el cambio en el mismo esquema.
  - **Salida esperada:** el tipo vuelve a estar disponible para nuevas altas con su identidad y esquema.
  - **Verificación:** el fixture `reactivacion-ok` reproduce el comportamiento y no se ofrecen tipos inactivos para nuevas altas.

## 5. Normalización

- [ ] **MK-010-T50 — P0 — Normalizar arquitectura y componentes** `[TODO]`
  - **Entrada:** código en `prototipo/src/pantallas/MK010` y convenciones del Design System.
  - **Acción:** sustituir componentes ad hoc por componentes centralizados de Mantine y el Design System.
  - **Salida esperada:** código modular sin estilos inline huérfanos.
  - **Verificación:** build exitoso sin warnings ni dependencias no autorizadas.
- [ ] **MK-010-T51 — P0:** Normalizar colores con tokens oficiales del tema. `[TODO]`
- [ ] **MK-010-T52 — P0:** Normalizar espaciados, bordes y radios según la escala del módulo. `[TODO]`
- [ ] **MK-010-T53 — P0:** Aplicar la escala tipográfica centralizada. `[TODO]`
- [ ] **MK-010-T54 — P0:** Sustituir iconos ad hoc exclusivamente por Tabler Icons. `[TODO]`
- [ ] **MK-010-T55 — P0:** Eliminar términos técnicos, nombres de base de datos y nombres de eventos o tópicos visibles al usuario. `[TODO]`
- [ ] **MK-010-T56 — P0:** Revisar semántica HTML y accesibilidad básica, incluido el switch de condición con `aria-checked` y el `aria-live` de resultados asíncronos. `[TODO]`

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-010-T60 — P0:** Validar cobertura estricta de SPEC-010 sin reglas inventadas, incluida la ausencia de acción de reordenar, de columna `tipo_producto_id` y de migración de `tipo_producto_id`. `[TODO]`
- [ ] **MK-010-T61 — P0:** Validar los 17 criterios de aceptación de HU-010 contra la matriz de `component-spec.md` §2.1. `[TODO]`
- [ ] **MK-010-T62 — P0:** Validar correspondencia con WF-010, incluidos §9, §10, §11, §12, §13, §14 y el microcopy de §18. `[TODO]`
- [ ] **MK-010-T63 — P0:** Validar los flujos A a G de FLOW-010. `[TODO]`
- [ ] **MK-010-T64 — P0:** Validar cumplimiento de UX Guidelines normativas del módulo. `[TODO]`
- [ ] **MK-010-T65 — P0:** Validar aplicación de UXD-003, UXD-005, UXD-009, UXD-014 y UXD-016. `[TODO]`
- [ ] **MK-010-T66 — P0:** Validar justificación de LUX-01, LUX-02 y LUX-03. `[TODO]`
- [ ] **MK-010-T67 — P0:** Validar fidelidad al Design System y reutilización de componentes compartidos. `[TODO]`
- [ ] **MK-010-T68 — P0:** Validar las nueve rutas inventariadas, incluidas `/MK010/S01-E`, `/MK010/S01-N`, `/MK010/S02-P` y `/MK010/S02-R`, y el comportamiento en 1440 px sin overflow horizontal. `[TODO]`
- [ ] **MK-010-T69 — P0 — Registrar evidencias de autovalidación** `[TODO]`
  - **Entrada:** inspección técnica y funcional de pantallas, estados y rutas.
  - **Acción:** documentar pantallas, trazabilidad de ejecución, UI, PC y accesibilidad, siguiendo la estructura de la plantilla de `validation-report.md`.
  - **Salida esperada:** evidencias que sustentan la matriz de §2.1.
  - **Verificación:** cero hallazgos bloqueantes ni importantes requeridos abiertos.

## 7. Revisión transversal y visto bueno

- [ ] **MK-010-T70 — P0:** Confirmar que la autovalidación local está completa y cerrada. `[TODO]`
- [ ] **MK-010-T71 — P0:** Solicitar formalmente revisión transversal a Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-010-T72 — P0:** Atender y corregir todos los hallazgos bloqueantes e importantes. `[TODO]`
- [ ] **MK-010-T73 — P0:** Obtener visto bueno formal de Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-010-T74 — P0 — Registrar estado APROBADO PARA FIGMA** `[TODO]`
  - **Entrada:** visto bueno otorgado por el revisor.
  - **Acción:** registrar el estado de revisión transversal.
  - **Salida esperada:** sección de revisión transversal en estado `APROBADO PARA FIGMA`.
  - **Verificación:** confirmación formal del revisor con fecha.

## 8. Figma y cierre

- [ ] **MK-010-T75 — P0:** Trasladar fielmente a Figma la versión aprobada para Figma. `[TODO]`
- [ ] **MK-010-T76 — P0:** Verificar fidelidad punto a punto entre Figma y el prototipo aprobado. `[TODO]`
- [ ] **MK-010-T77 — P0:** Confirmar que las nueve pantallas P0 están completas en Figma. `[TODO]`
- [ ] **MK-010-T78 — P0:** Registrar el enlace canónico de Figma. `[TODO]`
- [ ] **MK-010-T79 — P0 — Cierre de Quality Gates y resultado APROBADO** `[TODO]`
  - **Entrada:** Gates A, B, C, D, E y F cumplidos.
  - **Acción:** cerrar el reporte de validación y declarar el resultado general.
  - **Salida esperada:** **Resultado general = APROBADO**.
  - **Verificación:** todos los gates cerrados y cero bloqueos abiertos.

## 9. Registro de bloqueos

| Tarea | Fecha | Causa del bloqueo | Fuente / Documento a resolver | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|---|---|
| MK-010-T02 | 2026-10-03 | El `component-spec.md` v1.1 está en estado En revisión; Q-01 y Q-02 siguen abiertas | Revisión documental del `component-spec.md` | Leonardo Lopez | Aprobación del component-spec y cierre de Q-01 (exposición del límite) y Q-02 (detalle del resultado de verificación) | Activo |
| MK-010-T15 | 2026-10-03 | Depende de Q-01 para determinar si el límite se consulta del contrato o permanece como constante configurable | SPEC-010 y Contrato API | Leonardo Lopez con Taxonomía | Respuesta documentada a Q-01 | Activo |
| MK-010-T18 | 2026-10-03 | Depende de Q-02 para representar el motivo de rechazo | AsyncAPI 0.4.0 y Contrato API | Leonardo Lopez con Taxonomía | Respuesta documentada a Q-02 | Activo |
