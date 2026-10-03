# Tasks — MK-008

## 1. Identificación

- **Mockup:** MK-008 — Gestión de categorías y subcategorías
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

- [ ] **MK-008-T01 — P0:** Confirmar vigentes [propuesta-ux.md](../ux/propuesta-ux.md), [ux-guidelines.md](../ux/ux-guidelines.md) y [ux-decisions.md](../ux/ux-decisions.md). `[TODO]`
- [ ] **MK-008-T02 — P0:** Obtener la aprobación de [component-spec.md](component-spec.md) y resolver las preguntas abiertas Q-01 y Q-02. `[BLOCKED: component-spec en estado En revisión]`
- [ ] **MK-008-T03 — P0 — Preparar fixtures deterministas** `[TODO]`
  - **Entrada:** `component-spec.md` §13.
  - **Acción:** crear datasets en `prototipo/src/pantallas/MK008` para default, loading, empty, sin resultados, error, sesión, slug con y sin colisión, carrera `409`, baja pendiente, confirmada, rechazada y no concluyente, y los rechazos de jerarquía.
  - **Salida esperada:** fixtures importables por los componentes de pantalla.
  - **Verificación:** cada fixture se carga por parámetro de consulta y produce un estado distinguishable y determinista.
- [ ] **MK-008-T04 — P0:** Confirmar [DESIGN.md](../DESIGN.md) 1.0.0 y el catálogo de componentes DS-C01, DS-C02, DS-C03, DS-C05, DS-C06, DS-C12, DS-C14, DS-C17, DS-C19, DS-C21, DS-C22, DS-C24, DS-C25 y DS-C28. `[TODO]`
- [ ] **MK-008-T05 — P0:** Identificar MK-008-S01 como pantalla ancla y alinear jerarquía, densidad y microtexto con el resto del módulo. `[TODO]`

## 4. Implementación por pantalla

### MK-008-S01 — Árbol de categorías

- [ ] **MK-008-T10 — P0 — Implementar estructura de S01** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S01) y §5.
  - **Acción:** construir cabecera con migas, barra con Crear categoría y filtro, y árbol/tabla con nivel, estado y acciones por fila.
  - **Salida esperada:** ruta `/MK008/S01` renderizable y navegable directamente.
  - **Verificación:** las tres zonas obligatorias están presentes y no hay elementos inventados.
- [ ] **MK-008-T11 — P0 — Construir MK-008-C01 e integrar componentes de S01** `[TODO]`
  - **Entrada:** `component-spec.md` §8, §9 y §10 (S01).
  - **Acción:** implementar el árbol con expansión, selección, filtro y estado por nodo sobre DS-C17 y DS-C14.
  - **Salida esperada:** árbol funcional con máximo dos niveles y estado expresado con texto y color.
  - **Verificación:** default, loading, empty, sin resultados y error se reproducen desde los fixtures de T03.
- [ ] **MK-008-T12 — P0 — Implementar navegación de S01** `[TODO]`
  - **Entrada:** `component-spec.md` §6 y FLOW-008 §4.1.
  - **Acción:** conectar Crear categoría, Ver detalle, Editar y Desactivar hacia sus destinos.
  - **Salida esperada:** navegación operativa sin rutas rotas.
  - **Verificación:** el flujo es navegable de extremo a extremo sin errores en consola.
- [ ] **MK-008-T13 — P0 — Verificar coherencia integral del flujo** `[TODO]`
  - **Entrada:** FLOW-008 §4.1 a §4.4.
  - **Acción:** comprobar que todas las transiciones de §6 del component-spec son alcanzables.
  - **Salida esperada:** diagrama de flujo validado contra la implementación.
  - **Verificación:** ninguna pantalla queda huérfana y todas las variantes con sufijo tienen ruta.

### MK-008-S02 y MK-008-S02-C — Crear categoría y Confirmar slug

- [ ] **MK-008-T14 — P0 — Implementar estructura de S02 y S02-C** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S02, S02-C).
  - **Acción:** implementar el formulario de alta y el modal de confirmación de slug.
  - **Salida esperada:** rutas `/MK008/S02` y `/MK008/S02-C` renderizables directamente.
  - **Verificación:** ambas rutas existen de forma independiente y conservan el contexto que las originó.
- [ ] **MK-008-T15 — P0 — Construir MK-008-C02 y MK-008-C03** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §13.
  - **Acción:** implementar el selector de padre con candidatos deshabilitados y explicación, y el diálogo de slug con sufijo resaltado.
  - **Salida esperada:** selector y diálogo conformes a LUX-01 y LUX-02.
  - **Verificación:** los fixtures `slug-con-colision`, `slug-carrera-409` y `ciclo-rechazado` producen el comportamiento esperado.
- [ ] **MK-008-T16 — P0 — Implementar la secuencia resolver → mostrar → confirmar → crear** `[TODO]`
  - **Entrada:** SPEC-008 R1, HU-008 CA-13 y CA-14, `component-spec.md` §6.
  - **Acción:** solicitar la propuesta de slug, mostrarla y enviar `slugConfirmado` sin modificarlo en la confirmación.
  - **Salida esperada:** alta creada solo tras confirmación explícita; ante `409 SLUG_DUPLICADO` se muestra una nueva propuesta en el mismo diálogo.
  - **Verificación:** no existe creación sin confirmación previa visible y el sufijo nunca se aplica silenciosamente.

### MK-008-S03 — Editar categoría

- [ ] **MK-008-T17 — P0 — Implementar S03 con PATCH y reubicación** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S03) y SPEC-008 R3 y R7.
  - **Acción:** implementar edición de datos y cambio de categoría padre con `PATCH /api/v1/categorias/{categoriaId}` y `CategoriaUpdateRequest`.
  - **Salida esperada:** ruta `/MK008/S03` operativa con errores Reportados junto al campo afectado.
  - **Verificación:** los fixtures `ciclo-rechazado`, `padre-inactivo-al-editar`, `profundidad-excedida` y `version-conflict` se muestran sin perder el borrador.
- [ ] **MK-008-T18 — P0 — Comunicar que la reubicación no altera productos** `[TODO]`
  - **Entrada:** HU-008 CA-11 y CA-12.
  - **Acción:** incluir la ayuda de que el cambio no altera productos y el aviso de propagación eventual de `taxonomy.category.updated`.
  - **Salida esperada:** microtexto conforme a `component-spec.md` §10 (S03).
  - **Verificación:** el texto afirma que no se modifican productos ni características y que la propagación es eventual.

### MK-008-S05 — Detalle de categoría

- [ ] **MK-008-T19 — P0 — Implementar S05** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S05).
  - **Acción:** construir la ficha con nombre, descripción, padre, hijas, orden, imagen, slug y estado, y las acciones Editar, Desactivar y Reactivar.
  - **Salida esperada:** ruta `/MK008/S05` operativa con default, loading, error y no encontrada.
  - **Verificación:** el slug se muestra como URL pública cuando existe y el estado se expresa con texto.

### MK-008-S04, S04-P y S04-B — Baja lógica segura

- [ ] **MK-008-T20 — P0 — Implementar S04 como admisión** `[TODO]`
  - **Entrada:** SPEC-008 R4, HU-008 CA-06 y `component-spec.md` §10 (S04).
  - **Acción:** implementar el modal de impacto y enviar la solicitud de desactivación.
  - **Salida esperada:** ruta `/MK008/S04` operativa; la respuesta `202` conduce a S04-P y nunca se presenta como baja confirmada.
  - **Verificación:** el copy de S04 no afirma que la categoría quedó desactivada.
- [ ] **MK-008-T21 — P0 — Construir MK-008-C04 y modelar el seguimiento por operationId** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §13; AsyncAPI 0.4.0.
  - **Acción:** implementar el banner de estado con consulta a `GET /api/v1/taxonomia/operaciones/{operationId}` y los resultados pendiente, confirmado, rechazado y no concluyente.
  - **Salida esperada:** rutas `/MK008/S04-P` y `/MK008/S04-B` operativas sin reenviar la baja.
  - **Verificación:** los fixtures `baja-pendiente`, `baja-confirmada`, `baja-rechazada` y `baja-no-concluyente` reproducen cada resultado; ante ausencia de resultado se informa que no se realizó ningún cambio.
- [ ] **MK-008-T22 — P0 — Verificar precondiciones de bloqueo** `[TODO]`
  - **Entrada:** contrato API y SPEC-008 R4.
  - **Acción:** representar el rechazo por subcategorías activas y por productos activos con el mensaje correspondiente.
  - **Salida esperada:** mensajes accionables que preservan la categoría activa.
  - **Verificación:** los fixtures `subcategorias-activas` y `baja-rechazada` muestran el motivo correcto.

### MK-008-S05-R — Reactivación bloqueada

- [ ] **MK-008-T23 — P0 — Implementar S05-R** `[TODO]`
  - **Entrada:** SPEC-008 R5, HU-008 CA-07 y `component-spec.md` §10 (S05-R).
  - **Acción:** mostrar el estado de la hija y del padre, con acción para reactivar el padre.
  - **Salida esperada:** ruta `/MK008/S05-R` operativa; la hija permanece inactiva.
  - **Verificación:** el fixture `reactivacion-padre-inactivo` no ofrece reactivar la hija directamente.

## 5. Normalización

- [ ] **MK-008-T50 — P0 — Normalizar arquitectura y componentes** `[TODO]`
  - **Entrada:** código en `prototipo/src/pantallas/MK008` y convenciones del Design System.
  - **Acción:** sustituir componentes ad hoc por componentes centralizados de Mantine y el Design System.
  - **Salida esperada:** código modular sin estilos inline huérfanos.
  - **Verificación:** build exitoso sin warnings ni dependencias no autorizadas.
- [ ] **MK-008-T51 — P0:** Normalizar colores con tokens oficiales del tema. `[TODO]`
- [ ] **MK-008-T52 — P0:** Normalizar espaciados, bordes y radios según la escala del módulo. `[TODO]`
- [ ] **MK-008-T53 — P0:** Aplicar la escala tipográfica centralizada. `[TODO]`
- [ ] **MK-008-T54 — P0:** Sustituir iconos ad hoc exclusivamente por Tabler Icons. `[TODO]`
- [ ] **MK-008-T55 — P0:** Eliminar términos técnicos y nombres de base de datos visibles al usuario; el identificador interno de categoría no se muestra. `[TODO]`
- [ ] **MK-008-T56 — P0:** Revisar semántica HTML y accesibilidad básica, incluida la navegación por teclado del árbol. `[TODO]`

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-008-T60 — P0:** Validar cobertura estricta de SPEC-008 sin reglas inventadas, incluida la ausencia de eliminación física. `[TODO]`
- [ ] **MK-008-T61 — P0:** Validar los 14 criterios de aceptación de HU-008 contra la matriz de `component-spec.md` §2.1. `[TODO]`
- [ ] **MK-008-T62 — P0:** Validar correspondencia con WF-008 v0.7, pantalla por pantalla. `[TODO]`
- [ ] **MK-008-T63 — P0:** Validar transiciones completas según FLOW-008. `[TODO]`
- [ ] **MK-008-T64 — P0:** Validar cumplimiento de UX Guidelines normativas del módulo. `[TODO]`
- [ ] **MK-008-T65 — P0:** Validar aplicación de UXD-001, UXD-005, UXD-007, UXD-008, UXD-009 y UXD-011. `[TODO]`
- [ ] **MK-008-T66 — P0:** Validar justificación de LUX-01 y LUX-02. `[TODO]`
- [ ] **MK-008-T67 — P0:** Validar fidelidad al Design System y reutilización de componentes compartidos. `[TODO]`
- [ ] **MK-008-T68 — P0:** Validar las nueve rutas inventariadas, incluidas `/MK008/S02-C`, `/MK008/S04-P`, `/MK008/S04-B` y `/MK008/S05-R`, y el comportamiento en 1440 px sin overflow horizontal. `[TODO]`
- [ ] **MK-008-T69 — P0 — Registrar evidencias de autovalidación** `[TODO]`
  - **Entrada:** inspección técnica y funcional de pantallas, estados y rutas.
  - **Acción:** documentar pantallas, trazabilidad de ejecución, UI, PC y accesibilidad, siguiendo la estructura de la plantilla de `validation-report.md`.
  - **Salida esperada:** evidencias que sustentan la matriz de §2.1.
  - **Verificación:** cero hallazgos bloqueantes ni importantes requeridos abiertos.

## 7. Revisión transversal y visto bueno

- [ ] **MK-008-T70 — P0:** Confirmar que la autovalidación local está completa y cerrada. `[TODO]`
- [ ] **MK-008-T71 — P0:** Solicitar formalmente revisión transversal a Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-008-T72 — P0:** Atender y corregir todos los hallazgos bloqueantes e importantes. `[TODO]`
- [ ] **MK-008-T73 — P0:** Obtener visto bueno formal de Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-008-T74 — P0 — Registrar estado APROBADO PARA FIGMA** `[TODO]`
  - **Entrada:** visto bueno otorgado por el revisor.
  - **Acción:** registrar el estado de revisión transversal.
  - **Salida esperada:** sección de revisión transversal en estado `APROBADO PARA FIGMA`.
  - **Verificación:** confirmación formal del revisor con fecha.

## 8. Figma y cierre

- [ ] **MK-008-T75 — P0:** Trasladar fielmente a Figma la versión aprobada para Figma. `[TODO]`
- [ ] **MK-008-T76 — P0:** Verificar fidelidad punto a punto entre Figma y el prototipo aprobado. `[TODO]`
- [ ] **MK-008-T77 — P0:** Confirmar que las nueve pantallas P0 están completas en Figma. `[TODO]`
- [ ] **MK-008-T78 — P0:** Registrar el enlace canónico de Figma. `[TODO]`
- [ ] **MK-008-T79 — P0 — Cierre de Quality Gates y resultado APROBADO** `[TODO]`
  - **Entrada:** Gates A, B, C, D, E y F cumplidos.
  - **Acción:** cerrar el reporte de validación y declarar el resultado general.
  - **Salida esperada:** **Resultado general = APROBADO**.
  - **Verificación:** todos los gates cerrados y cero bloqueos abiertos.

## 9. Registro de bloqueos

| Tarea | Fecha | Causa del bloqueo | Fuente / Documento a resolver | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|---|---|
| MK-008-T02 | 2026-10-03 | El `component-spec.md` v1.1 está en estado En revisión; Q-01 y Q-02 siguen abiertas | Revisión documental del `component-spec.md` | Leonardo Lopez | Aprobación del component-spec y cierre de Q-01 (fuente authoritative del árbol administrativo) y Q-02 (consulta del resultado de la verificación) | Activo |
| MK-008-T15 | 2026-10-03 | Depende de Q-01 para definir si el selector distingue categorías inactivas | Contrato API y SPEC-008 | Leonardo Lopez con Taxonomía | Respuesta documentada a Q-01 | Activo |
| MK-008-T21 | 2026-10-03 | Depende de Q-02 para model's el seguimiento cuando el gestor abandona S04-P | AsyncAPI 0.4.0 y Contrato API | Leonardo Lopez con Taxonomía | Respuesta documentada a Q-02 | Activo |
