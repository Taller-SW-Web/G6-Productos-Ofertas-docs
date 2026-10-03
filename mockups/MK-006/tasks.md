# Tasks — MK-006

## 1. Identificación

Gestión de ofertas y promociones · Axel Cueva · [plan](plan.md) / [component-spec](component-spec.md) · #64 · versión1.2 · 2026-10-03. Documentación redactada en `cueva`, EN REVISIÓN; preparación e implementación bloqueadas hasta aprobar el component-spec. Refinamiento posterior en `lab/cueva`.

## 2. Convenciones y reglas de ejecución

P0 obligatorio. Estados TODO/DOING/BLOCKED/REVIEW/DONE; checkbox marcado solo cuando la verificación es comprobable. DONE en T01/T02/T05 acredita redacción comprobada, no aprobación. T03 permanece BLOCKED hasta dictamen; la preparación no está completa y el plan/tasks puede cambiar durante la revisión. Cada tarea tiene Entrada/Acción/Salida esperada/Verificación. Registrar causa y desbloqueo de BLOCKED en §9. IDs estables: T01–05 preparación, T11–17 pantallas según inventario, T50–52 normalización, T60–62 autovalidación, T70–74 revisión, T75–79 promoción/Figma/cierre. No crear un issue por cada tarea.

## 3. Preparación

- [x] **MK-006-T01 — P0 — Preparar fuentes e inventario documental** `[DONE]`
  - **Entrada:** Fuentes enlazadas en component-spec §2 y reglas de SPEC/HU/WF/FLOW.
  - **Acción:** Cotejar campos/operaciones e inventariar pantallas, estados y límites sin inventar comportamiento.
  - **Salida esperada:** Component-spec versión1.2 con fuentes, P0 y casos específicos.
  - **Verificación:** Enlaces locales existentes, secciones1–15, IDs/rutas únicas y campos contractualizados; no es aprobación UX.
- [x] **MK-006-T02 — P0 — Documentar ejecución y escenarios** `[DONE]`
  - **Entrada:** Component-spec §5/9/13 y plantillas canónicas.
  - **Acción:** Definir plan/gates y unidades ejecutables; separar fases y resultados.
  - **Salida esperada:** Plan1–13 y tasks1–9; escenarios de datos/errores documentados, todavía no código de fixtures.
  - **Verificación:** Plan referencia las mismas pantallas/rutas; tareas con cuatro campos y bloqueos explícitos.
- [ ] **MK-006-T03 — P0 — Obtener aprobación documental del component-spec** `[BLOCKED]`
  - **Entrada:** Component-spec versión1.2 EN REVISIÓN y fuentes vigentes de §2.
  - **Acción:** Atender observaciones funcionales/documentales y presentar la versión al revisor del equipo; alinear plan/tasks si cambia.
  - **Salida esperada:** Dictamen explícito APROBADO sobre versión identificable y DoR comprobada.
  - **Verificación:** Registrar revisor, fecha, versión, dictamen y cierre de observaciones; cambiar a DONE solo con esa evidencia, nunca por existir el archivo.
- [ ] **MK-006-T04 — P0 — Alinear laboratorio y preparar fixtures de implementación** `[BLOCKED]`
  - **Entrada:** Component-spec aprobado en T03 y documentación derivada alineada en cueva.
  - **Acción:** Alinear lab/cueva, resolver contradicciones contra fuentes y convertir §13 en datos/estados deterministas.
  - **Salida esperada:** Laboratorio coherente, fixtures de este MK listos para sus rutas.
  - **Verificación:** Diff limitado al MK/compartidos necesarios; valores/IDs estables, nada de otro owner ni contrato inventado.
- [x] **MK-006-T05 — P0 — Registrar límites funcionales específicos** `[DONE]`
  - **Entrada:** SPEC/contratos y component-spec §4/9/14.
  - **Acción:** Conservar restricciones propias y representar datos desconocidos honestamente.
  - **Salida esperada:** Límites y casos específicos dentro de component-spec/plan.
  - **Verificación:** No checkout, permisos nuevos ni constantes técnicas visibles; capacidad/modalidad y D-REC tratados donde corresponde.

## 4. Implementación por pantalla

### MK-006-S01 — Listado de promociones

- [ ] **MK-006-T11 — P0 — Implementar S01** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-006-S01.
  - **Acción:** Refinar estructura, campos, acción «Crear promoción», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK006, ruta `/MK006/S01` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK006/S01`; reproducir default y sin-resultados según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Filtrar Carrera de octubre, abrir S05 y volver al listado; probar Crear promoción.
    - **Resultado:** Detalle pertenece a Carrera de octubre; Crear abre S02 y el retorno mantiene filtros.
    - **Contexto:** Conservar filtros, página y promoción seleccionada.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-006-S01 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-006-S02 — Crear promoción

- [ ] **MK-006-T12 — P0 — Implementar S02** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-006-S02.
  - **Acción:** Refinar estructura, campos, acción «Crear promoción», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK006, ruta `/MK006/S02` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK006/S02`; reproducir beneficio-invalido y canales-vacios según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Crear con porcentaje 101 y sin canales; corregir a 15 y Marketplace; abrir selector S04 y regresar.
    - **Resultado:** Valor/canales inválidos impiden guardar; selección conserva borrador; guardado confirmado abre S05 y cancelación resuelta vuelve a S01.
    - **Contexto:** Conservar nombre, fechas, beneficio, canales y política al corregir o volver del selector.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-006-S02 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-006-S03 — Editar promoción

- [ ] **MK-006-T13 — P0 — Implementar S03** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-006-S03.
  - **Acción:** Refinar estructura, campos, acción «Guardar cambios», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK006, ruta `/MK006/S03` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK006/S03`; reproducir modalidad-permitida, modalidad-bloqueada y modalidad-desconocida según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Editar Inactiva nueva e Inactiva histórica; repetir con capacidad administrativa desconocida.
    - **Resultado:** Solo capacidad=true permite cambiar modalidad; false o ausente no habilita la acción. Guardado confirmado abre S05 del mismo registro.
    - **Contexto:** Conservar promoción y datos del formulario ante bloqueo o rechazo; no deducir capacidad desde el estado visible.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-006-S03 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-006-S04 — Seleccionar alcance

- [ ] **MK-006-T14 — P0 — Implementar S04** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-006-S04.
  - **Acción:** Refinar estructura, campos, acción «Confirmar alcance», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK006, ruta `/MK006/S04` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK006/S04`; reproducir producto-con-sku-nuevo y coincidencias-alcance según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Abrir desde S02/S03, elegir producto completo y SKU específico; confirmar y luego repetir cancelando.
    - **Resultado:** Producto completo conserva productId e incluye futuros SKU; coincidencias no duplican alcance; confirmar vuelve al formulario de origen y cancelar descarta solo selección temporal.
    - **Contexto:** Conservar borrador, tipo de selección y alcance previo; el selector no cambia beneficio ni canales.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-006-S04 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-006-S05 — Detalle de promoción

- [ ] **MK-006-T15 — P0 — Implementar S05** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-006-S05.
  - **Acción:** Refinar estructura, campos, acción «Editar promoción», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK006, ruta `/MK006/S05` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK006/S05`; reproducir default y error según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Consultar Carrera de octubre; abrir Editar S03 y Cambiar estado S06; repetir con lectura fallida.
    - **Resultado:** Detalle muestra 15%, canales y alcance del registro correcto; error ofrece reintento sin mostrar datos de otra promoción.
    - **Contexto:** Conservar promoción y filtros del listado en todos los retornos.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-006-S05 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

### MK-006-S06 — Cambiar estado

- [ ] **MK-006-T16 — P0 — Implementar S06** `[BLOCKED]`
  - **Entrada:** Entradas aprobadas T03/T04 y component-spec §10 MK-006-S06.
  - **Acción:** Refinar estructura, campos, acción «Activar promoción / Desactivar promoción», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK006, ruta `/MK006/S06` y fixtures de §13.
  - **Verificación:**
    - **Ruta/fixture:** Abrir `/MK006/S06`; reproducir default y rechazo según component-spec §13, con los registros ficticios allí definidos.
    - **Recorrido:** Abrir S06 desde S05; cancelar, provocar rechazo y luego confirmar cambio de estado.
    - **Resultado:** Solo confirmación satisfactoria actualiza estado; rechazo/cancelación conserva estado y antecedente de activación.
    - **Contexto:** Conservar promoción, detalle y capacidad de modalidad; Escape devuelve foco a la acción original.
    - **Viewport/acceso:** Verificar 1440×900, sin overflow horizontal; recorrer acciones con teclado y comprobar foco/labels.
    - **Evidencia:** Al implementar, registrar fixture, pasos, resultado y capturas de MK-006-S06 en validation-report. Estado actual: sin ejecución visual ni evidencia de pantalla.

## 5. Normalización

- [ ] **MK-006-T50 — P0 — Normalizar tema/componentes/stack** `[TODO]`
  - **Entrada:** Pantallas construidas, DESIGN §4–15 y entorno compartido vigente.
  - **Acción:** Aplicar tokens y componentes compartidos React/TS/Mantine/Tabler; verificar/fijar versiones al construir.
  - **Salida esperada:** Código modular, tema único y build reproducible.
  - **Verificación:** Build sin errores y comparación de tamaños/colores/tipografía con DS; sin versiones de biblioteca declaradas a ciegas.
- [ ] **MK-006-T51 — P0 — Revisar copy y representación de datos** `[TODO]`
  - **Entrada:** Component-spec §9/10/13, UXG-020/022.
  - **Acción:** Humanizar etiquetas y separar datos conocidos/ausentes; corregir botones/nombres del registro.
  - **Salida esperada:** Copy comprensible y datos fieles a fixtures/contratos.
  - **Verificación:** No UUID, nombres de eventos, criterios constantes o cero ficticio; ningún botón de otro proceso.
- [ ] **MK-006-T52 — P0 — Normalizar teclado y capas** `[TODO]`
  - **Entrada:** Pantallas/interacciones, UXG-021 y DESIGN accesibilidad.
  - **Acción:** Labels, foco visible, orden tab, errores asociados y focus trap/retorno de diálogos.
  - **Salida esperada:** Interacción accesible con teclado/mouse.
  - **Verificación:** Recorridos sin ratón, Escape, seguir editando/descartar y foco al primer error; estado no solo color.

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-006-T60 — P0 — Probar reglas y flujos propios del MK** `[TODO]`
  - **Entrada:** Component-spec §10/13, SPEC/HU/WF/FLOW.
  - **Acción:** Ejecutar todos los casos positivos/negativos y retorno/contexto en el mockup construido.
  - **Salida esperada:** Resultados por Task/Pantalla/Fixture/Evidencia, hallazgos propios.
  - **Verificación:** No reutilizar PASS de wireframes/SQL como PASS visual; entradas de segundo registro y errores corregibles verificadas.
- [ ] **MK-006-T61 — P0 — Verificar viewport y estados** `[TODO]`
  - **Entrada:** Rutas del inventario y estados requeridos de §10.
  - **Acción:** Inspeccionar1440×900, medir overflow/dimensiones y capturar cada estado relevante.
  - **Salida esperada:** Capturas trazables y reporte de teclado/layout.
  - **Verificación:** Sin overflow de página; estado reproducible, sin éxito prematuro ni placeholder técnico.
- [ ] **MK-006-T62 — P0 — Registrar la autovalidación real** `[TODO]`
  - **Entrada:** Resultados T60/T61 y plantilla validation-report.
  - **Acción:** Crear validation-report solo con pruebas realizadas; corregir hallazgos bloqueantes/importantes.
  - **Salida esperada:** Reporte propio con versión/capturas/resultado y trazabilidad.
  - **Verificación:** Las casillas DONE remiten a evidencia; revisión de Vera/Figma aún pendientes si no ocurrieron.

## 7. Revisión transversal y visto bueno

- [ ] **MK-006-T70 — P0 — Preparar paquete para revisión UX de Vera** `[TODO]`
  - **Entrada:** Mockup autovalidado T62 y fuentes vigentes.
  - **Acción:** Preparar versión/rutas/estados/reporte para que Vera revise; el envío se coordina con Axel.
  - **Salida esperada:** Paquete concreto y revisión transversal de Vera.
  - **Verificación:** Revisor, versión, fecha y observaciones verificables; no suplantar la revisión.
- [ ] **MK-006-T71 — P0 — Corregir hallazgos de Vera** `[TODO]`
  - **Entrada:** Observaciones de revisión T70.
  - **Acción:** Corregir hallazgos, repetir pruebas afectadas y obtener verificación de cierre.
  - **Salida esperada:** Hallazgos bloqueantes/importantes cerrados.
  - **Verificación:** Evidencia antes/después y confirmación del revisor; no autoaprobar hallazgos externos.
- [ ] **MK-006-T74 — P0 — Registrar el visto bueno formal** `[TODO]`
  - **Entrada:** Revisión final de Vera sobre versión concreta.
  - **Acción:** Registrar APROBADO PARA FIGMA cuando realmente lo otorgue.
  - **Salida esperada:** Gate E verificable; habilitación de promoción consolidada y Figma.
  - **Verificación:** Nombre/fecha/versión y ausencia de hallazgos bloqueantes/importantes pendientes.

## 8. Promoción, Figma y cierre

- [ ] **MK-006-T75 — P0 — Promover artefactos consolidados a cueva** `[TODO]`
  - **Entrada:** Visto bueno T74, diff de lab/cueva.
  - **Acción:** Trasladar únicamente documentos/código normalizado de este MK y compartidos necesarios; excluir variantes y experimentos sin aprobación.
  - **Salida esperada:** Entrega consolidada en la rama oficial existente, sin merge indiscriminado de lab.
  - **Verificación:** Diff revisable sin archivos temporales/guías privadas/trabajo ajeno; no presentar promoción como Figma terminado.
- [ ] **MK-006-T76 — P0 — Trasladar la versión aprobada a Figma** `[TODO]`
  - **Entrada:** Versión exacta aprobada por Vera y ya consolidada.
  - **Acción:** Reproducir pantallas/estados con tokens/componentes y rutas identificables.
  - **Salida esperada:** Archivo/enlaces de Figma y frames trazables.
  - **Verificación:** Trasladar solo la versión con visto bueno y no declarar aprobación antes de T74; enlaces/versiones verificables.
- [ ] **MK-006-T78 — P0 — Verificar fidelidad en Figma** `[TODO]`
  - **Entrada:** Mockup aprobado y frames T76.
  - **Acción:** Comparar pantalla/estado, copy/datos, medidas/tokens/interacciones representables.
  - **Salida esperada:** Evidencia de fidelidad y correcciones.
  - **Verificación:** Comparación punto a punto1440 con hallazgos cerrados; Figma no redefine fuentes.
- [ ] **MK-006-T79 — P0 — Cerrar reporte e índice del entregable** `[TODO]`
  - **Entrada:** Gates A–F, T75/T76/T78 y evidencias.
  - **Acción:** Actualizar validation-report e índice solo con resultado real; revisar criterios de #64 completos.
  - **Salida esperada:** Resultado APROBADO con Figma/evidencia si todos los criterios se cumplen.
  - **Verificación:** Cada P0/estado y revisión/fidelidad verificable; no cerrar #64 por preparar estos documentos.

## 9. Registro de bloqueos

| ID / tareas | Causa / fuente | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|
| B-DOC — T03/T04/T11–T16 | Component-spec versión1.2 EN REVISIÓN; plan.template §3 exige APROBADO. | Axel atiende observaciones; revisor documental del equipo emite dictamen. | Aprobación registrada con revisor/fecha/versión y plan/tasks alineados; confirmar DoR. | BLOCKED |
| B-UX — T70/T71/T74 | Revisión transversal exige versión autovalidada; no existe todavía. | Vera / owner. | T62 completada y revisión/visto bueno real sobre versión concreta. | Pendiente de fase |
| B-PROM — T75/T76/T78/T79 | Gate E sin aprobación; no promover código experimental ni Figma. | Owner / revisor. | APROBADO PARA FIGMA, luego promoción/fidelidad verificadas. | Pendiente de fase |
