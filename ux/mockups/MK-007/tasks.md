# Tasks — MK-007

## 1. Identificación

Reglas de venta cruzada y upselling · Axel Cueva · [plan](plan.md) / [component-spec](component-spec.md) · #64 · versión1.2 · 2026-10-03. Documentación redactada en `cueva`, EN REVISIÓN; preparación e implementación bloqueadas hasta aprobar el component-spec. Refinamiento posterior en `lab/cueva`.

## 2. Convenciones y reglas de ejecución

P0 obligatorio. Estados TODO/DOING/BLOCKED/REVIEW/DONE; checkbox marcado solo cuando la verificación es comprobable. DONE en T01/T02/T05 acredita redacción comprobada, no aprobación. T03 permanece BLOCKED hasta dictamen; la preparación no está completa y el plan/tasks puede cambiar durante la revisión. Cada tarea tiene Entrada/Acción/Salida esperada/Verificación. Registrar causa y desbloqueo de BLOCKED en §9. IDs estables: T01–05 preparación, T11–17 pantallas según inventario, T50–52 normalización, T60–62 autovalidación, T70–74 revisión, T75–79 promoción/Figma/cierre. No crear un issue por cada tarea.

## 3. Preparación

- [x] **MK-007-T01 — P0 — Preparar fuentes e inventario documental** `[DONE]`
  - **Entrada:** Fuentes enlazadas en component-spec §2 y reglas de SPEC/HU/WF/FLOW.
  - **Acción:** Cotejar campos/operaciones e inventariar pantallas, estados y límites sin inventar comportamiento.
  - **Salida esperada:** Component-spec versión1.2 con fuentes, P0 y casos específicos.
  - **Verificación:** Enlaces locales existentes, secciones1–15, IDs/rutas únicas y campos contractualizados; no es aprobación UX.
- [x] **MK-007-T02 — P0 — Documentar ejecución y escenarios** `[DONE]`
  - **Entrada:** Component-spec §5/9/13 y plantillas canónicas.
  - **Acción:** Definir plan/gates y unidades ejecutables; separar fases y resultados.
  - **Salida esperada:** Plan1–13 y tasks1–9; escenarios de datos/errores documentados, todavía no código de fixtures.
  - **Verificación:** Plan referencia las mismas pantallas/rutas; tareas con cuatro campos y bloqueos explícitos.
- [ ] **MK-007-T03 — P0 — Obtener aprobación documental del component-spec** `[BLOCKED]`
  - **Entrada:** Component-spec versión1.2 EN REVISIÓN y fuentes vigentes de §2.
  - **Acción:** Atender observaciones funcionales/documentales y presentar la versión al revisor del equipo; alinear plan/tasks si cambia.
  - **Salida esperada:** Dictamen explícito APROBADO sobre versión identificable y DoR comprobada.
  - **Verificación:** Registrar revisor, fecha, versión, dictamen y cierre de observaciones; cambiar a DONE solo con esa evidencia, nunca por existir el archivo.
- [ ] **MK-007-T04 — P0 — Alinear laboratorio y preparar fixtures de implementación** `[BLOCKED]`
  - **Entrada:** Component-spec aprobado en T03 y documentación derivada alineada en cueva.
  - **Acción:** Alinear lab/cueva, resolver contradicciones contra fuentes y convertir §13 en datos/estados deterministas.
  - **Salida esperada:** Laboratorio coherente, fixtures de este MK listos para sus rutas.
  - **Verificación:** Diff limitado al MK/compartidos necesarios; valores/IDs estables, nada de otro owner ni contrato inventado.
- [x] **MK-007-T05 — P0 — Registrar límites funcionales específicos** `[DONE]`
  - **Entrada:** SPEC/contratos y component-spec §4/9/14.
  - **Acción:** Conservar restricciones propias y representar datos desconocidos honestamente.
  - **Salida esperada:** Límites y casos específicos dentro de component-spec/plan.
  - **Verificación:** No checkout, permisos nuevos ni constantes técnicas visibles; capacidad/modalidad y D-REC tratados donde corresponde.

## 4. Implementación por pantalla

### MK-007-S01 — Listado de reglas

- [ ] **MK-007-T11 — P0 — Implementar S01** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-007-S01.
  - **Acción:** Refinar estructura, campos, acción «Crear venta cruzada», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK007, ruta `/MK007/S01` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK007/S01`; reproducir default y sin-resultados según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Filtrar Completa tu carrera, abrir S06 y volver; probar Crear venta cruzada y Crear upselling.
    - **Resultado:** Las acciones abren S02/S04 respectivamente; detalle y retorno mantienen registro y filtros.
    - **Contexto:** Conservar filtros, página y regla seleccionada.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-007-S01 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-007-S02 — Crear venta cruzada

- [ ] **MK-007-T12 — P0 — Implementar S02** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-007-S02.
  - **Acción:** Refinar estructura, campos, acción «Crear regla», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK007, ruta `/MK007/S02` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK007/S02`; reproducir regla-invalida y origen-categoria según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Crear venta cruzada sin fechas/recomendados y corregir; cambiar origen a categoría Running; seleccionar candidatos en S05.
    - **Resultado:** Errores impiden guardar; el selector vuelve a S02 con borrador; guardado confirmado abre S06 y conserva tipo/ID de origen.
    - **Contexto:** Conservar nombre, origen, fechas, prioridad y candidatos al corregir o volver del selector.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-007-S02 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-007-S03 — Editar regla

- [ ] **MK-007-T13 — P0 — Implementar S03** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-007-S03.
  - **Acción:** Refinar estructura, campos, acción «Guardar cambios», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK007, ruta `/MK007/S03` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK007/S03`; reproducir cambio-tipo y guardar-error según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Editar Completa tu carrera y cambiar a UPSELL; dejar criterio vacío y luego corregir; simular rechazo de guardado.
    - **Resultado:** Cada candidato exige criterio al cambiar tipo; el rechazo mantiene borrador. Guardado confirmado vuelve a S06 de la misma regla.
    - **Contexto:** Conservar ID, candidatos, orden y justificación; advertir antes de descartar datos al cambiar origen/tipo.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-007-S03 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-007-S04 — Crear upselling

- [ ] **MK-007-T14 — P0 — Implementar S04** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-007-S04.
  - **Acción:** Refinar estructura, campos, acción «Crear regla de upselling», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK007, ruta `/MK007/S04` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK007/S04`; reproducir upsell-incompleto y regla-invalida según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Crear upselling sin criterio por candidato, con orden cero o justificación de 501 caracteres; corregir y abrir S05.
    - **Resultado:** Cada error se asocia a su fila/campo; no se asigna criterio automáticamente. S05 vuelve a S04 y guardado confirmado abre S06.
    - **Contexto:** Conservar nombre, origen, fechas y filas al corregir; cancelar solo descarta tras confirmación de cambios.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-007-S04 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-007-S05 — Seleccionar recomendado

- [ ] **MK-007-T15 — P0 — Implementar S05** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-007-S05.
  - **Acción:** Refinar estructura, campos, acción «Confirmar selección», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK007, ruta `/MK007/S05` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK007/S05`; reproducir origen-como-recomendado y duplicado-inactivo según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Abrir desde S02/S03/S04, intentar elegir producto origen, ya añadido o inactivo; confirmar candidato elegible y repetir cancelando.
    - **Resultado:** Los candidatos inválidos se excluyen; confirmar vuelve al formulario de origen sin duplicados; cancelar descarta solo selección temporal.
    - **Contexto:** Conservar formulario de retorno, borrador, candidatos anteriores y sus criterios.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-007-S05 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-007-S06 — Detalle de regla

- [ ] **MK-007-T16 — P0 — Implementar S06** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-007-S06.
  - **Acción:** Refinar estructura, campos, acción «Editar regla», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK007, ruta `/MK007/S06` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK007/S06`; reproducir default y enriquecimiento-ausente según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Consultar Mejora tu rendimiento, verificar candidatos ordenados y criterio; abrir S03/S07 y volver.
    - **Resultado:** Detalle pertenece a esa regla; precio y disponibilidad por producto muestran No disponible, sin cero ficticio ni SKU elegido para completar datos.
    - **Contexto:** Conservar regla, filtros y selección; las consultas no agregan productos al pedido.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-007-S06 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-007-S07 — Cambiar estado

- [ ] **MK-007-T17 — P0 — Implementar S07** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-007-S07.
  - **Acción:** Refinar estructura, campos, acción «Activar regla / Desactivar regla», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK007, ruta `/MK007/S07` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK007/S07`; reproducir default y rechazo según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Desde S06 abrir confirmación; cancelar con Escape, simular rechazo y luego confirmar respuesta satisfactoria.
    - **Resultado:** Rechazo/cancelación conserva estado; solo respuesta confirmada actualiza badge y vuelve a S06.
    - **Contexto:** Conservar regla y detalle de fondo; devolver foco a la acción de estado.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-007-S07 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

## 5. Normalización

- [ ] **MK-007-T50 — P0 — Normalizar tema/componentes/stack** `[TODO]`
  - **Entrada:** Pantallas construidas, DESIGN §4–15 y entorno compartido vigente.
  - **Acción:** Aplicar tokens y componentes compartidos React/TS/Mantine/Tabler; verificar/fijar versiones al construir.
  - **Salida esperada:** Código modular, tema único y build reproducible.
  - **Verificación:** Build sin errores y comparación de tamaños/colores/tipografía con DS; sin versiones de biblioteca declaradas a ciegas.
- [ ] **MK-007-T51 — P0 — Revisar copy y representación de datos** `[TODO]`
  - **Entrada:** Component-spec §9/10/13, UXG-020/022.
  - **Acción:** Humanizar etiquetas y separar datos conocidos/ausentes; corregir botones/nombres del registro.
  - **Salida esperada:** Copy comprensible y datos fieles a fixtures/contratos.
  - **Verificación:** No UUID, nombres de eventos, criterios constantes o cero ficticio; ningún botón de otro proceso.
- [ ] **MK-007-T52 — P0 — Normalizar teclado y capas** `[TODO]`
  - **Entrada:** Pantallas/interacciones, UXG-021 y DESIGN accesibilidad.
  - **Acción:** Labels, foco visible, orden tab, errores asociados y focus trap/retorno de diálogos.
  - **Salida esperada:** Interacción accesible con teclado/mouse.
  - **Verificación:** Recorridos sin ratón, Escape, seguir editando/descartar y foco al primer error; estado no solo color.

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-007-T60 — P0 — Probar reglas y flujos propios del MK** `[TODO]`
  - **Entrada:** Component-spec §10/13, SPEC/HU/WF/FLOW.
  - **Acción:** Ejecutar todos los casos positivos/negativos y retorno/contexto en el mockup construido.
  - **Salida esperada:** Resultados por Task/Pantalla/Fixture/Evidencia, hallazgos propios.
  - **Verificación:** No reutilizar PASS de wireframes/SQL como PASS visual; entradas de segundo registro y errores corregibles verificadas.
- [ ] **MK-007-T61 — P0 — Verificar viewport y estados** `[TODO]`
  - **Entrada:** Rutas del inventario y estados requeridos de §10.
  - **Acción:** Inspeccionar1440×900, medir overflow/dimensiones y capturar cada estado relevante.
  - **Salida esperada:** Capturas trazables y reporte de teclado/layout.
  - **Verificación:** Sin overflow de página; estado reproducible, sin éxito prematuro ni placeholder técnico.
- [ ] **MK-007-T62 — P0 — Registrar la autovalidación real** `[TODO]`
  - **Entrada:** Resultados T60/T61 y plantilla validation-report.
  - **Acción:** Crear validation-report solo con pruebas realizadas; corregir hallazgos bloqueantes/importantes.
  - **Salida esperada:** Reporte propio con versión/capturas/resultado y trazabilidad.
  - **Verificación:** Las casillas DONE remiten a evidencia; revisión de Vera/Figma aún pendientes si no ocurrieron.

## 7. Revisión transversal y visto bueno

- [ ] **MK-007-T70 — P0 — Preparar paquete para revisión UX de Vera** `[TODO]`
  - **Entrada:** Mockup autovalidado T62 y fuentes vigentes.
  - **Acción:** Preparar versión/rutas/estados/reporte para que Vera revise; el envío se coordina con Axel.
  - **Salida esperada:** Paquete concreto y revisión transversal de Vera.
  - **Verificación:** Revisor, versión, fecha y observaciones verificables; no suplantar la revisión.
- [ ] **MK-007-T71 — P0 — Corregir hallazgos de Vera** `[TODO]`
  - **Entrada:** Observaciones de revisión T70.
  - **Acción:** Corregir hallazgos, repetir pruebas afectadas y obtener verificación de cierre.
  - **Salida esperada:** Hallazgos bloqueantes/importantes cerrados.
  - **Verificación:** Evidencia antes/después y confirmación del revisor; no autoaprobar hallazgos externos.
- [ ] **MK-007-T74 — P0 — Registrar el visto bueno formal** `[TODO]`
  - **Entrada:** Revisión final de Vera sobre versión concreta.
  - **Acción:** Registrar APROBADO PARA FIGMA cuando realmente lo otorgue.
  - **Salida esperada:** Gate E verificable; habilitación de promoción consolidada y Figma.
  - **Verificación:** Nombre/fecha/versión y ausencia de hallazgos bloqueantes/importantes pendientes.

## 8. Promoción, Figma y cierre

- [ ] **MK-007-T75 — P0 — Promover artefactos consolidados a cueva** `[TODO]`
  - **Entrada:** Visto bueno T74, diff de lab/cueva.
  - **Acción:** Trasladar únicamente documentos/código normalizado de este MK y compartidos necesarios; excluir variantes y experimentos sin aprobación.
  - **Salida esperada:** Entrega consolidada en la rama oficial existente, sin merge indiscriminado de lab.
  - **Verificación:** Diff revisable sin archivos temporales/guías privadas/trabajo ajeno; no presentar promoción como Figma terminado.
- [ ] **MK-007-T76 — P0 — Trasladar la versión aprobada a Figma** `[TODO]`
  - **Entrada:** Versión exacta aprobada por Vera y ya consolidada.
  - **Acción:** Reproducir pantallas/estados con tokens/componentes y rutas identificables.
  - **Salida esperada:** Archivo/enlaces de Figma y frames trazables.
  - **Verificación:** Trasladar solo la versión con visto bueno y no declarar aprobación antes de T74; enlaces/versiones verificables.
- [ ] **MK-007-T78 — P0 — Verificar fidelidad en Figma** `[TODO]`
  - **Entrada:** Mockup aprobado y frames T76.
  - **Acción:** Comparar pantalla/estado, copy/datos, medidas/tokens/interacciones representables.
  - **Salida esperada:** Evidencia de fidelidad y correcciones.
  - **Verificación:** Comparación punto a punto1440 con hallazgos cerrados; Figma no redefine fuentes.
- [ ] **MK-007-T79 — P0 — Cerrar reporte e índice del entregable** `[TODO]`
  - **Entrada:** Gates A–F, T75/T76/T78 y evidencias.
  - **Acción:** Actualizar validation-report e índice solo con resultado real; revisar criterios de #64 completos.
  - **Salida esperada:** Resultado APROBADO con Figma/evidencia si todos los criterios se cumplen.
  - **Verificación:** Cada P0/estado y revisión/fidelidad verificable; no cerrar #64 por preparar estos documentos.

## 9. Registro de bloqueos

| ID / tareas | Causa / fuente | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|
| B-DOC — T03/T04/T11–T17 | Component-spec versión1.2 EN REVISIÓN; plan.template §3 exige APROBADO. | Axel atiende observaciones; revisor documental del equipo emite dictamen. | Aprobación registrada con revisor/fecha/versión y plan/tasks alineados; confirmar DoR. | BLOCKED |
| B-UX — T70/T71/T74 | Revisión transversal exige versión autovalidada; no existe todavía. | Vera / owner. | T62 completada y revisión/visto bueno real sobre versión concreta. | Pendiente de fase |
| B-PROM — T75/T76/T78/T79 | Gate E sin aprobación; no promover código experimental ni Figma. | Owner / revisor. | APROBADO PARA FIGMA, luego promoción/fidelidad verificadas. | Pendiente de fase |
| B-REC — enriquecimientos de S06 | D-REC-01/02 abiertas en SPEC-007/contrato. | Owners/integración según fuentes. | Decisiones oficiales sobre disponibilidad/precio por producto. Configuración sigue representable con No disponible. | Bloqueo parcial; no bloquea documentos ni configuración |
