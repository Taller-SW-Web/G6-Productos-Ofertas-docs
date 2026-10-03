# Tasks — MK-006

## 1. Identificación
Axel Cueva; [plan](plan.md); estado En progreso.

## 2. Convenciones
P0 obligatorio; TODO/DOING/BLOCKED/REVIEW/DONE. DONE solo con evidencia; bloqueos en §9. Cada tarea relevante indica entrada, acción, salida y verificación. Contenido de pantalla vive en component-spec, no se duplica aquí.

## 3. Preparación, 4. Implementación, 5. Normalización y 6. Autovalidación
- [x] **MK-006-T05 — P0 — Alinear documentación con correcciones funcionales locales** `[DONE]`
  - **Entrada:** Fuentes corregidas en cueva b05dd63 e informe de validación de wireframes.
  - **Acción:** Actualizar restricciones y casos específicos de component-spec y plan.
  - **Salida:** Borradores alineados con las fuentes locales; no hay pantallas nuevas ni aprobación UX.
  - **Verificación:** Casos de §13 y [evidencia funcional previa](../../wireframes/prototipos/tests/VALIDACION-005-007.md). La implementación/autovalidación del MK conserva sus tareas pendientes.
- [ ] **MK-006-T01 — P0 — Verificar fuentes y DoR** `[REVIEW]`
  - **Entrada:** component-spec §2/14.
  - **Acción:** Contrastar gates y reglas sin contradicción funcional.
  - **Salida:** Fuentes identificadas.
  - **Verificación:** Matriz fuentes y versiones.
- [ ] **MK-006-T02 — P0 — Preparar fixtures** `[REVIEW]`
  - **Entrada:** component-spec §13.
  - **Acción:** Definir datos/casos deterministas.
  - **Salida:** Fixtures importables.
  - **Verificación:** Rutas con estado estable.
- [ ] **MK-006-T11 — P0 — Implementar MK-006-S01** `[BLOCKED]`
  - **Entrada:** component-spec §10 S01.
  - **Acción:** Construir estructura, acciones y estados especificados.
  - **Salida:** /MK006/S01.
  - **Verificación:** Ruta directa, interacción, estado y captura 1440.
- [ ] **MK-006-T12 — P0 — Implementar MK-006-S02** `[BLOCKED]`
  - **Entrada:** component-spec §10 S02.
  - **Acción:** Construir estructura, acciones y estados especificados.
  - **Salida:** /MK006/S02.
  - **Verificación:** Ruta directa, interacción, estado y captura 1440.
- [ ] **MK-006-T13 — P0 — Implementar MK-006-S03** `[BLOCKED]`
  - **Entrada:** component-spec §10 S03.
  - **Acción:** Construir estructura, acciones y estados especificados.
  - **Salida:** /MK006/S03.
  - **Verificación:** Ruta directa, interacción, estado y captura 1440.
- [ ] **MK-006-T14 — P0 — Implementar MK-006-S04** `[BLOCKED]`
  - **Entrada:** component-spec §10 S04.
  - **Acción:** Construir estructura, acciones y estados especificados.
  - **Salida:** /MK006/S04.
  - **Verificación:** Ruta directa, interacción, estado y captura 1440.
- [ ] **MK-006-T15 — P0 — Implementar MK-006-S05** `[BLOCKED]`
  - **Entrada:** component-spec §10 S05.
  - **Acción:** Construir estructura, acciones y estados especificados.
  - **Salida:** /MK006/S05.
  - **Verificación:** Ruta directa, interacción, estado y captura 1440.
- [ ] **MK-006-T16 — P0 — Implementar MK-006-S06** `[BLOCKED]`
  - **Entrada:** component-spec §10 S06.
  - **Acción:** Construir estructura, acciones y estados especificados.
  - **Salida:** /MK006/S06.
  - **Verificación:** Ruta directa, interacción, estado y captura 1440.
- [ ] **MK-006-T50 — P0 — Normalizar código y tema** `[TODO]`
  - **Entrada:** DESIGN §4–15.
  - **Acción:** Aplicar componentes/tokens/semántica.
  - **Salida:** Código modular.
  - **Verificación:** Build y medidas.
- [ ] **MK-006-T60 — P0 — Autovalidar** `[TODO]`
  - **Entrada:** SPEC/HU/WF/Flow y UXG.
  - **Acción:** Ejecutar recorridos, casos negativos y accesibilidad; repetir las regresiones de component-spec §13 en el propio MK, sin dar por suficiente la prueba del wireframe.
  - **Salida:** Evidencias/reportes.
  - **Verificación:** Checks PASS y hallazgos cerrados.

## 7. Revisión transversal y visto bueno; 8. Figma y cierre
- [ ] **MK-006-T70 — P0 — Obtener revisión UX** `[TODO]`
  - **Entrada:** validation-report autovalidación.
  - **Acción:** Entregar versión y obtener revisión de Leonardo.
  - **Salida:** Visto bueno formal.
  - **Verificación:** Revisor y fecha verificables.
- [ ] **MK-006-T71 — P0 — Resolver hallazgos de revisión** `[TODO]`
  - **Entrada:** Observaciones de Leonardo.
  - **Acción:** Corregir y volver a verificar.
  - **Salida:** Hallazgos cerrados.
  - **Verificación:** Confirmación del revisor.
- [ ] **MK-006-T74 — P0 — Registrar APROBADO PARA FIGMA** `[TODO]`
  - **Entrada:** Visto bueno formal.
  - **Acción:** Registrar resultado real.
  - **Salida:** Gate E cerrado.
  - **Verificación:** Confirmación y fecha.
- [ ] **MK-006-T75 — P0 — Trasladar a Figma** `[TODO]`
  - **Entrada:** Versión aprobada para Figma.
  - **Acción:** Reflejar composición fiel.
  - **Salida:** Pantallas Figma.
  - **Verificación:** Enlace y fidelidad punto a punto.
- [ ] **MK-006-T79 — P0 — Cerrar reporte e índice** `[TODO]`
  - **Entrada:** Gates A–F.
  - **Acción:** Actualizar resultado solo con evidencia.
  - **Salida:** Reporte APROBADO.
  - **Verificación:** Todos gates y Figma completos.

## 9. Registro de bloqueos

| Tarea | Causa / fuente | Responsable | Condición | Estado |
|---|---|---|---|---|
| T11–T17 según inventario | Base visual inicial aún no recibida, requisito previo al refinamiento | Leonardo Vera / owner | Entrega identificada y contrastada con fuentes | BLOCKED |
| T70–74 | Revisión UX independiente requerida por #64/README | Leonardo Vera | Visto bueno documentado | Pendiente |
| T75–79 | Gate E aún pendiente | Owner/revisor | APROBADO PARA FIGMA, luego traslado/fidelidad | Pendiente |
