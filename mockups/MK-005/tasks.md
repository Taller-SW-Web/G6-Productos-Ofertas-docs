# Tasks — MK-005

## 1. Identificación

Gestión de cupones de descuento · Axel Cueva · [plan](plan.md) / [component-spec](component-spec.md) · #64 · versión1.1 · 2026-10-03. Documentos preparados en `cueva`; raw pendiente; implementación futura en `lab/cueva`.

## 2. Convenciones y reglas de ejecución

P0 obligatorio. Estados TODO/DOING/BLOCKED/REVIEW/DONE; checkbox marcado solo cuando la verificación es comprobable. Una tarea de documentos DONE no acredita una pantalla. Cada tarea tiene Entrada/Acción/Salida esperada/Verificación. Registrar causa y desbloqueo de BLOCKED en §9. IDs estables: T01–05 preparación, T11–17 pantallas según inventario, T50–52 normalización, T60–62 autovalidación, T70–74 revisión, T75–79 promoción/Figma/cierre. No crear un issue por cada tarea.

## 3. Preparación
- [x] **MK-005-T01 — P0 — Preparar fuentes e inventario documental** `[DONE]`
  - **Entrada:** Fuentes enlazadas en component-spec §2 y reglas de SPEC/HU/WF/FLOW.
  - **Acción:** Cotejar campos/operaciones e inventariar pantallas, estados y límites sin inventar comportamiento.
  - **Salida esperada:** Component-spec versión1.1 con fuentes, P0 y casos específicos.
  - **Verificación:** Enlaces locales existentes, secciones1–15, IDs/rutas únicas y campos contractualizados; no es aprobación UX.
- [x] **MK-005-T02 — P0 — Documentar ejecución y escenarios** `[DONE]`
  - **Entrada:** Component-spec §5/9/13 y plantillas canónicas.
  - **Acción:** Definir plan/gates y unidades ejecutables; separar fases y resultados.
  - **Salida esperada:** Plan1–13 y tasks1–9; escenarios de datos/errores documentados, todavía no código de fixtures.
  - **Verificación:** Plan referencia las mismas pantallas/rutas; tareas con cuatro campos y bloqueos explícitos.
- [ ] **MK-005-T03 — P0 — Recibir y registrar la base raw de Vera** `[BLOCKED]`
  - **Entrada:** Component-spec/plan de cueva entregables para Vera.
  - **Acción:** Recibir raw de Stitch, ubicación, ancla, pantallas creadas, supuestos y dudas.
  - **Salida esperada:** Entrega identificable para comparación; ninguna aprobación deducida.
  - **Verificación:** Registro del enlace/rama/archivos y origen Vera; contrastar con §5/9 antes de T11.
- [ ] **MK-005-T04 — P0 — Alinear laboratorio y preparar fixtures de implementación** `[BLOCKED]`
  - **Entrada:** Base identificada T03, documentación vigente de cueva.
  - **Acción:** Alinear lab/cueva, resolver contradicciones contra fuentes y convertir §13 en datos/estados deterministas.
  - **Salida esperada:** Laboratorio coherente, fixtures de este MK listos para sus rutas.
  - **Verificación:** Diff limitado al MK/compartidos necesarios; valores/IDs estables, nada de otro owner ni contrato inventado.
- [x] **MK-005-T05 — P0 — Registrar límites funcionales específicos** `[DONE]`
  - **Entrada:** SPEC/contratos y component-spec §4/9/14.
  - **Acción:** Conservar restricciones propias y representar datos desconocidos honestamente.
  - **Salida esperada:** Límites y casos específicos dentro de component-spec/plan.
  - **Verificación:** No checkout, permisos nuevos ni constantes técnicas visibles; capacidad/modalidad y D-REC tratados donde corresponde.

## 4. Implementación por pantalla

### MK-005-S01 — Listado de cupones

- [ ] **MK-005-T11 — P0 — Implementar S01** `[BLOCKED]`
  - **Entrada:** Raw T03/T04 y component-spec §10 MK-005-S01.
  - **Acción:** Refinar estructura, campos, acción «Crear cupón», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK005, ruta `/MK005/S01` y fixtures de §13.
  - **Verificación:** Entrada directa1440; Sidebar o ruta directa. S02 o S03/S04 del registro elegido.; estados negativos y controles conservan entidad/contexto; captura y evidencia propia.

### MK-005-S02 — Crear cupón

- [ ] **MK-005-T12 — P0 — Implementar S02** `[BLOCKED]`
  - **Entrada:** Raw T03/T04 y component-spec §10 MK-005-S02.
  - **Acción:** Refinar estructura, campos, acción «Crear cupón», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK005, ruta `/MK005/S02` y fixtures de §13.
  - **Verificación:** Entrada directa1440; S01 / Crear cupón. S04 del cupón creado solo tras guardado confirmado; cancelar vuelve a S01.; estados negativos y controles conservan entidad/contexto; captura y evidencia propia.

### MK-005-S03 — Editar cupón

- [ ] **MK-005-T13 — P0 — Implementar S03** `[BLOCKED]`
  - **Entrada:** Raw T03/T04 y component-spec §10 MK-005-S03.
  - **Acción:** Refinar estructura, campos, acción «Guardar cambios», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK005, ruta `/MK005/S03` y fixtures de §13.
  - **Verificación:** Entrada directa1440; S01 o S04 con cuponId. S04 del mismo cupón; cancelar conserva registro anterior.; estados negativos y controles conservan entidad/contexto; captura y evidencia propia.

### MK-005-S04 — Detalle de cupón

- [ ] **MK-005-T14 — P0 — Implementar S04** `[BLOCKED]`
  - **Entrada:** Raw T03/T04 y component-spec §10 MK-005-S04.
  - **Acción:** Refinar estructura, campos, acción «Editar cupón», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK005, ruta `/MK005/S04` y fixtures de §13.
  - **Verificación:** Entrada directa1440; S01 o guardado confirmado. S03; Límites y uso a S05; Cambiar estado a S06; volver a S01.; estados negativos y controles conservan entidad/contexto; captura y evidencia propia.

### MK-005-S05 — Límites y uso

- [ ] **MK-005-T15 — P0 — Implementar S05** `[BLOCKED]`
  - **Entrada:** Raw T03/T04 y component-spec §10 MK-005-S05.
  - **Acción:** Refinar estructura, campos, acción «Volver al detalle», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK005, ruta `/MK005/S05` y fixtures de §13.
  - **Verificación:** Entrada directa1440; S04 / Límites y uso. S04 del mismo cupón.; estados negativos y controles conservan entidad/contexto; captura y evidencia propia.

### MK-005-S06 — Cambiar estado

- [ ] **MK-005-T16 — P0 — Implementar S06** `[BLOCKED]`
  - **Entrada:** Raw T03/T04 y component-spec §10 MK-005-S06.
  - **Acción:** Refinar estructura, campos, acción «Activar cupón / Desactivar cupón», retorno y estados aplicables de esta pantalla.
  - **Salida esperada:** Vista normalizada en MK005, ruta `/MK005/S06` y fixtures de §13.
  - **Verificación:** Entrada directa1440; S04 / Cambiar estado; entrada directa reproduce detalle + diálogo. Confirmado: S04 con nuevo estado; cancelar/rechazo conserva el anterior.; estados negativos y controles conservan entidad/contexto; captura y evidencia propia.

## 5. Normalización

- [ ] **MK-005-T50 — P0 — Normalizar tema/componentes/stack** `[TODO]`
  - **Entrada:** Pantallas construidas, DESIGN §4–15 y entorno compartido vigente.
  - **Acción:** Aplicar tokens y componentes compartidos React/TS/Mantine/Tabler; verificar/fijar versiones al construir.
  - **Salida esperada:** Código modular, tema único y build reproducible.
  - **Verificación:** Build sin errores y comparación de tamaños/colores/tipografía con DS; sin versiones de biblioteca declaradas a ciegas.
- [ ] **MK-005-T51 — P0 — Revisar copy y representación de datos** `[TODO]`
  - **Entrada:** Component-spec §9/10/13, UXG-020/022.
  - **Acción:** Humanizar etiquetas y separar datos conocidos/ausentes; corregir botones/nombres del registro.
  - **Salida esperada:** Copy comprensible y datos fieles a fixtures/contratos.
  - **Verificación:** No UUID, nombres de eventos, criterios constantes o cero ficticio; ningún botón de otro proceso.
- [ ] **MK-005-T52 — P0 — Normalizar teclado y capas** `[TODO]`
  - **Entrada:** Pantallas/interacciones, UXG-021 y DESIGN accesibilidad.
  - **Acción:** Labels, foco visible, orden tab, errores asociados y focus trap/retorno de diálogos.
  - **Salida esperada:** Interacción accesible con teclado/mouse.
  - **Verificación:** Recorridos sin ratón, Escape, seguir editando/descartar y foco al primer error; estado no solo color.

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-005-T60 — P0 — Probar reglas y flujos propios del MK** `[TODO]`
  - **Entrada:** Component-spec §10/13, SPEC/HU/WF/FLOW.
  - **Acción:** Ejecutar todos los casos positivos/negativos y retorno/contexto en el mockup construido.
  - **Salida esperada:** Resultados por Task/Pantalla/Fixture/Evidencia, hallazgos propios.
  - **Verificación:** No reutilizar PASS de wireframes/SQL como PASS visual; entradas de segundo registro y errores corregibles verificadas.
- [ ] **MK-005-T61 — P0 — Verificar viewport y estados** `[TODO]`
  - **Entrada:** Rutas del inventario y estados requeridos de §10.
  - **Acción:** Inspeccionar1440×900, medir overflow/dimensiones y capturar cada estado relevante.
  - **Salida esperada:** Capturas trazables y reporte de teclado/layout.
  - **Verificación:** Sin overflow de página; estado reproducible, sin éxito prematuro ni placeholder técnico.
- [ ] **MK-005-T62 — P0 — Registrar la autovalidación real** `[TODO]`
  - **Entrada:** Resultados T60/T61 y plantilla validation-report.
  - **Acción:** Crear validation-report solo con pruebas realizadas; corregir hallazgos bloqueantes/importantes.
  - **Salida esperada:** Reporte propio con versión/capturas/resultado y trazabilidad.
  - **Verificación:** Las casillas DONE remiten a evidencia; revisión de Vera/Figma aún pendientes si no ocurrieron.

## 7. Revisión transversal y visto bueno

- [ ] **MK-005-T70 — P0 — Preparar paquete para revisión UX de Vera** `[TODO]`
  - **Entrada:** Mockup autovalidado T62 y fuentes vigentes.
  - **Acción:** Preparar versión/rutas/estados/reporte para que Vera revise; el envío se coordina con Axel.
  - **Salida esperada:** Paquete concreto y revisión transversal de Vera.
  - **Verificación:** Revisor, versión, fecha y observaciones verificables; no suplantar la revisión.
- [ ] **MK-005-T71 — P0 — Corregir hallazgos de Vera** `[TODO]`
  - **Entrada:** Observaciones de revisión T70.
  - **Acción:** Corregir hallazgos, repetir pruebas afectadas y obtener verificación de cierre.
  - **Salida esperada:** Hallazgos bloqueantes/importantes cerrados.
  - **Verificación:** Evidencia antes/después y confirmación del revisor; no autoaprobar hallazgos externos.
- [ ] **MK-005-T74 — P0 — Registrar el visto bueno formal** `[TODO]`
  - **Entrada:** Revisión final de Vera sobre versión concreta.
  - **Acción:** Registrar APROBADO PARA FIGMA cuando realmente lo otorgue.
  - **Salida esperada:** Gate E verificable; habilitación de promoción consolidada y Figma.
  - **Verificación:** Nombre/fecha/versión y ausencia de hallazgos bloqueantes/importantes pendientes.

## 8. Promoción, Figma y cierre

- [ ] **MK-005-T75 — P0 — Promover artefactos consolidados a cueva** `[TODO]`
  - **Entrada:** Visto bueno T74, diff de lab/cueva.
  - **Acción:** Trasladar únicamente documentos/código normalizado de este MK y compartidos necesarios; retirar raw/experimentos.
  - **Salida esperada:** Entrega consolidada en la rama oficial existente, sin merge indiscriminado de lab.
  - **Verificación:** Diff revisable sin archivos temporales/guías privadas/trabajo ajeno; no presentar promoción como Figma terminado.
- [ ] **MK-005-T76 — P0 — Trasladar la versión aprobada a Figma** `[TODO]`
  - **Entrada:** Versión exacta aprobada por Vera y ya consolidada.
  - **Acción:** Reproducir pantallas/estados con tokens/componentes y rutas identificables.
  - **Salida esperada:** Archivo/enlaces de Figma y frames trazables.
  - **Verificación:** No trasladar raw ni declarar aprobación antes de T74; enlaces/versiones verificables.
- [ ] **MK-005-T78 — P0 — Verificar fidelidad en Figma** `[TODO]`
  - **Entrada:** Mockup aprobado y frames T76.
  - **Acción:** Comparar pantalla/estado, copy/datos, medidas/tokens/interacciones representables.
  - **Salida esperada:** Evidencia de fidelidad y correcciones.
  - **Verificación:** Comparación punto a punto1440 con hallazgos cerrados; Figma no redefine fuentes.
- [ ] **MK-005-T79 — P0 — Cerrar reporte e índice del entregable** `[TODO]`
  - **Entrada:** Gates A–F, T75/T76/T78 y evidencias.
  - **Acción:** Actualizar validation-report e índice solo con resultado real; revisar criterios de #64 completos.
  - **Salida esperada:** Resultado APROBADO con Figma/evidencia si todos los criterios se cumplen.
  - **Verificación:** Cada P0/estado y revisión/fidelidad verificable; no cerrar #64 por preparar estos documentos.

## 9. Registro de bloqueos

| ID / tareas | Causa / fuente | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|
| B-RAW — T03/T04/T11–T16 | Base raw aún no entregada; secuencia de plan §7 confirmada por Axel. | Leonardo Vera prepara base; Axel identifica recepción. | Base con ancla/inventario/enlace o archivos y supuestos; contraste funcional realizado. | BLOCKED |
| B-UX — T70/T71/T74 | Revisión transversal exige versión autovalidada; no existe todavía. | Vera / owner. | T62 completada y revisión/visto bueno real sobre versión concreta. | Pendiente de fase |
| B-PROM — T75/T76/T78/T79 | Gate E sin aprobación; no promover código experimental ni Figma. | Owner / revisor. | APROBADO PARA FIGMA, luego promoción/fidelidad verificadas. | Pendiente de fase |
