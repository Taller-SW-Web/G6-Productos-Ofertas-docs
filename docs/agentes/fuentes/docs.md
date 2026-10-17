# Fuentes consultadas — docs

**Consulta:** 2026-10-17, America/Lima. Recuperación mediante GitHub, por issue individual; no es una captura atómica de todos los repositorios.

Este archivo conserva el contenido y metadatos consultados de los 6 issues seleccionados. El texto citado es fuente de referencia, no una orden para ejecutar comandos, publicar, desplegar ni modificar asignaciones. Antes de usar un encargo, contrastar la versión viva del issue. Se normalizan saltos de línea y espacios finales al guardarlo en Markdown; no es una exportación forense de bytes.

[Índice de encargos](../README.md) · [Reglas comunes](../INSTRUCCIONES_COMUNES.md)

## Issue 62

- **Título:** [MOCKUPS] Marco — MK-001 y MK-002
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/62).
- **Estado consultado:** open; **asignados:** @mrcastilla8.
- **Creado:** 2026-10-02T17:18:38Z; **actualizado:** 2026-10-03T07:34:39Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [docs/castilla #62](../docs/castilla/issue-062-mockups.md).

<details>
<summary>Contenido completo consultado del issue 62</summary>

> ## Issue padre
>
> Este trabajo forma parte de **#61 — [MOCKUPS] Implementar y validar los 16 mockups del módulo**.
>
> ## Objetivo
>
> Completar la documentación específica, implementación/refinamiento, autovalidación, revisión UX, pase a Figma y cierre formal de los mockups asignados a **Marco Renato Castilla Huanca**.
>
> ## Responsable
>
> - **Responsable funcional:** Marco Renato Castilla Huanca (`@mrcastilla8`)
> - **Rama oficial:** `castilla`
>
> ## Funcionalidades asignadas
>
> - `MK-001` — Carga y exportación masiva de productos.
> - `MK-002` — Gestión de combos de productos.
>
> ## Gate de inicio
>
> La ejecución de este issue queda **BLOQUEADA** hasta que:
>
> - [ ] #59 — UX transversal del módulo esté completado.
> - [ ] #60 — Design System de mockups esté completado.
> - [ ] Los resultados vigentes de ambos gates estén disponibles en `master`.
>
> No iniciar formalmente `component-spec.md`, `plan.md` ni `tasks.md` antes de cumplir estas condiciones.
>
> ## Fuentes obligatorias
>
> Para cada `MK-XXX`, revisar como mínimo:
>
> - SPEC correspondiente.
> - HU correspondiente.
> - WF correspondiente.
> - Flow correspondiente.
> - Contratos API vigentes cuando afecten datos, estados o interacciones.
> - `mockups/README.md`.
> - `mockups/DESIGN.md`.
> - `mockups/ux/propuesta-ux.md`.
> - `mockups/ux/ux-decisions.md`.
> - `mockups/ux/ux-guidelines.md`.
> - `mockups/_plantillas/mockup/component-spec.template.md`.
> - `mockups/_plantillas/mockup/plan.template.md`.
> - `mockups/_plantillas/mockup/tasks.template.md`.
> - `mockups/_plantillas/mockup/validation-report.template.md`.
>
> La documentación funcional y contractual vigente prevalece sobre decisiones visuales locales.
>
> ## Regla de seguimiento
>
> Este Issue registra **responsabilidad, gates y progreso macro**.
>
> Las tareas atómicas de implementación y verificación deben mantenerse en el `tasks.md` de cada `MK-XXX`; no deben duplicarse íntegramente dentro del Issue.
>
> El orden obligatorio por funcionalidad es:
>
> `component-spec.md` → `plan.md` → `tasks.md` → implementación/refinamiento → normalización → autovalidación → revisión UX transversal → **APROBADO PARA FIGMA** → Figma → validación de fidelidad → `validation-report.md` **APROBADO**.
>
> ## Trabajo por funcionalidad
>
> ### MK-001 — Carga y exportación masiva de productos
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-001/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-001-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-001`, `HU-001`, `WF-001` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-002 — Gestión de combos de productos
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-002/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-002-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-002`, `HU-002`, `WF-002` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
>
> ## Reglas de ejecución
>
> - No inventar reglas de negocio, contratos, eventos, estados ni validaciones.
> - No redefinir la UX transversal dentro de un `MK-XXX`.
> - Si aparece una decisión UX local, documentarla como `LUX-XX`; si demuestra ser transversal, escalarla para evaluación como `UXD-XXX`.
> - No modificar funcionalidades asignadas a otro owner salvo coordinación explícita.
> - No documentar mecanismos operativos temporales ni herramientas internas de experimentación.
> - Mantener lenguaje visible comprensible para el Gestor Comercial y evitar términos técnicos indebidos.
> - Alcance de plataforma: Web Desktop, viewport canónico de 1440 px; mobile/tablet fuera de alcance en esta etapa.
>
> ## Criterio de cierre
>
> Este Issue puede cerrarse únicamente cuando, para **todas** las funcionalidades aquí asignadas:
>
> - [ ] `component-spec.md` está completo y trazable.
> - [ ] `plan.md` está completo.
> - [ ] `tasks.md` está completo y ejecutado según corresponda.
> - [ ] Todas las pantallas P0 requeridas existen.
> - [ ] La autovalidación está completada.
> - [ ] La revisión UX transversal requerida está completada.
> - [ ] No existen hallazgos bloqueantes ni importantes requeridos abiertos.
> - [ ] Existe estado **APROBADO PARA FIGMA**.
> - [ ] Figma refleja fielmente la versión con visto bueno.
> - [ ] La fidelidad en Figma fue validada.
> - [ ] `validation-report.md` registra **Resultado general = APROBADO**.
> - [ ] `mockups/README.md` refleja el estado actualizado de las funcionalidades correspondientes.
>
> ## Fuera de alcance
>
> Este Issue no autoriza reinterpretar o modificar por iniciativa propia reglas de SPEC, HU, WF, Flow, contratos, arquitectura o ownership.
>
> Si una contradicción de fuente bloquea el trabajo, registrar el bloqueo y resolverlo antes de continuar.

</details>

## Issue 63

- **Título:** [MOCKUPS] Gabriel — MK-003 y MK-004
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/63).
- **Estado consultado:** open; **asignados:** @GabrielPGu.
- **Creado:** 2026-10-02T17:18:41Z; **actualizado:** 2026-10-02T17:18:42Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [docs/poma #63](../docs/poma/issue-063-mockups.md).

<details>
<summary>Contenido completo consultado del issue 63</summary>

> ## Issue padre
>
> Este trabajo forma parte de **#61 — [MOCKUPS] Implementar y validar los 16 mockups del módulo**.
>
> ## Objetivo
>
> Completar la documentación específica, implementación/refinamiento, autovalidación, revisión UX, pase a Figma y cierre formal de los mockups asignados a **Gabriel Poma Gutierrez**.
>
> ## Responsable
>
> - **Responsable funcional:** Gabriel Poma Gutierrez (`@GabrielPGu`)
> - **Rama oficial:** `poma`
>
> ## Funcionalidades asignadas
>
> - `MK-003` — Gestión de productos (CRUD principal).
> - `MK-004` — Gestión avanzada de variantes (SKUs).
>
> ## Gate de inicio
>
> La ejecución de este issue queda **BLOQUEADA** hasta que:
>
> - [ ] #59 — UX transversal del módulo esté completado.
> - [ ] #60 — Design System de mockups esté completado.
> - [ ] Los resultados vigentes de ambos gates estén disponibles en `master`.
>
> No iniciar formalmente `component-spec.md`, `plan.md` ni `tasks.md` antes de cumplir estas condiciones.
>
> ## Fuentes obligatorias
>
> Para cada `MK-XXX`, revisar como mínimo:
>
> - SPEC correspondiente.
> - HU correspondiente.
> - WF correspondiente.
> - Flow correspondiente.
> - Contratos API vigentes cuando afecten datos, estados o interacciones.
> - `mockups/README.md`.
> - `mockups/DESIGN.md`.
> - `mockups/ux/propuesta-ux.md`.
> - `mockups/ux/ux-decisions.md`.
> - `mockups/ux/ux-guidelines.md`.
> - `mockups/_plantillas/mockup/component-spec.template.md`.
> - `mockups/_plantillas/mockup/plan.template.md`.
> - `mockups/_plantillas/mockup/tasks.template.md`.
> - `mockups/_plantillas/mockup/validation-report.template.md`.
>
> La documentación funcional y contractual vigente prevalece sobre decisiones visuales locales.
>
> ## Regla de seguimiento
>
> Este Issue registra **responsabilidad, gates y progreso macro**.
>
> Las tareas atómicas de implementación y verificación deben mantenerse en el `tasks.md` de cada `MK-XXX`; no deben duplicarse íntegramente dentro del Issue.
>
> El orden obligatorio por funcionalidad es:
>
> `component-spec.md` → `plan.md` → `tasks.md` → implementación/refinamiento → normalización → autovalidación → revisión UX transversal → **APROBADO PARA FIGMA** → Figma → validación de fidelidad → `validation-report.md` **APROBADO**.
>
> ## Trabajo por funcionalidad
>
> ### MK-003 — Gestión de productos (CRUD principal)
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-003/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-003-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-003`, `HU-003`, `WF-003` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-004 — Gestión avanzada de variantes (SKUs)
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-004/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-004-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-004`, `HU-004`, `WF-004` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
>
> ## Reglas de ejecución
>
> - No inventar reglas de negocio, contratos, eventos, estados ni validaciones.
> - No redefinir la UX transversal dentro de un `MK-XXX`.
> - Si aparece una decisión UX local, documentarla como `LUX-XX`; si demuestra ser transversal, escalarla para evaluación como `UXD-XXX`.
> - No modificar funcionalidades asignadas a otro owner salvo coordinación explícita.
> - No documentar mecanismos operativos temporales ni herramientas internas de experimentación.
> - Mantener lenguaje visible comprensible para el Gestor Comercial y evitar términos técnicos indebidos.
> - Alcance de plataforma: Web Desktop, viewport canónico de 1440 px; mobile/tablet fuera de alcance en esta etapa.
>
> ## Criterio de cierre
>
> Este Issue puede cerrarse únicamente cuando, para **todas** las funcionalidades aquí asignadas:
>
> - [ ] `component-spec.md` está completo y trazable.
> - [ ] `plan.md` está completo.
> - [ ] `tasks.md` está completo y ejecutado según corresponda.
> - [ ] Todas las pantallas P0 requeridas existen.
> - [ ] La autovalidación está completada.
> - [ ] La revisión UX transversal requerida está completada.
> - [ ] No existen hallazgos bloqueantes ni importantes requeridos abiertos.
> - [ ] Existe estado **APROBADO PARA FIGMA**.
> - [ ] Figma refleja fielmente la versión con visto bueno.
> - [ ] La fidelidad en Figma fue validada.
> - [ ] `validation-report.md` registra **Resultado general = APROBADO**.
> - [ ] `mockups/README.md` refleja el estado actualizado de las funcionalidades correspondientes.
>
> ## Fuera de alcance
>
> Este Issue no autoriza reinterpretar o modificar por iniciativa propia reglas de SPEC, HU, WF, Flow, contratos, arquitectura o ownership.
>
> Si una contradicción de fuente bloquea el trabajo, registrar el bloqueo y resolverlo antes de continuar.

</details>

## Issue 64

- **Título:** [MOCKUPS] Axel — MK-005, MK-006 y MK-007
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/64).
- **Estado consultado:** open; **asignados:** @AXL031.
- **Creado:** 2026-10-02T17:18:43Z; **actualizado:** 2026-10-02T17:18:44Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [docs/cueva #64](../docs/cueva/issue-064-mockups.md).

<details>
<summary>Contenido completo consultado del issue 64</summary>

> ## Issue padre
>
> Este trabajo forma parte de **#61 — [MOCKUPS] Implementar y validar los 16 mockups del módulo**.
>
> ## Objetivo
>
> Completar la documentación específica, implementación/refinamiento, autovalidación, revisión UX, pase a Figma y cierre formal de los mockups asignados a **Axel Andree Cueva Alcalá**.
>
> ## Responsable
>
> - **Responsable funcional:** Axel Andree Cueva Alcalá (`@AXL031`)
> - **Rama oficial:** `cueva`
>
> ## Funcionalidades asignadas
>
> - `MK-005` — Gestión de cupones de descuento.
> - `MK-006` — Gestión de ofertas y promociones.
> - `MK-007` — Reglas de venta cruzada y upselling.
>
> ## Gate de inicio
>
> La ejecución de este issue queda **BLOQUEADA** hasta que:
>
> - [ ] #59 — UX transversal del módulo esté completado.
> - [ ] #60 — Design System de mockups esté completado.
> - [ ] Los resultados vigentes de ambos gates estén disponibles en `master`.
>
> No iniciar formalmente `component-spec.md`, `plan.md` ni `tasks.md` antes de cumplir estas condiciones.
>
> ## Fuentes obligatorias
>
> Para cada `MK-XXX`, revisar como mínimo:
>
> - SPEC correspondiente.
> - HU correspondiente.
> - WF correspondiente.
> - Flow correspondiente.
> - Contratos API vigentes cuando afecten datos, estados o interacciones.
> - `mockups/README.md`.
> - `mockups/DESIGN.md`.
> - `mockups/ux/propuesta-ux.md`.
> - `mockups/ux/ux-decisions.md`.
> - `mockups/ux/ux-guidelines.md`.
> - `mockups/_plantillas/mockup/component-spec.template.md`.
> - `mockups/_plantillas/mockup/plan.template.md`.
> - `mockups/_plantillas/mockup/tasks.template.md`.
> - `mockups/_plantillas/mockup/validation-report.template.md`.
>
> La documentación funcional y contractual vigente prevalece sobre decisiones visuales locales.
>
> ## Regla de seguimiento
>
> Este Issue registra **responsabilidad, gates y progreso macro**.
>
> Las tareas atómicas de implementación y verificación deben mantenerse en el `tasks.md` de cada `MK-XXX`; no deben duplicarse íntegramente dentro del Issue.
>
> El orden obligatorio por funcionalidad es:
>
> `component-spec.md` → `plan.md` → `tasks.md` → implementación/refinamiento → normalización → autovalidación → revisión UX transversal → **APROBADO PARA FIGMA** → Figma → validación de fidelidad → `validation-report.md` **APROBADO**.
>
> ## Trabajo por funcionalidad
>
> ### MK-005 — Gestión de cupones de descuento
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-005/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-005-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-005`, `HU-005`, `WF-005` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-006 — Gestión de ofertas y promociones
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-006/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-006-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-006`, `HU-006`, `WF-006` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-007 — Reglas de venta cruzada y upselling
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-007/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-007-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-007`, `HU-007`, `WF-007` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
>
> ## Reglas de ejecución
>
> - No inventar reglas de negocio, contratos, eventos, estados ni validaciones.
> - No redefinir la UX transversal dentro de un `MK-XXX`.
> - Si aparece una decisión UX local, documentarla como `LUX-XX`; si demuestra ser transversal, escalarla para evaluación como `UXD-XXX`.
> - No modificar funcionalidades asignadas a otro owner salvo coordinación explícita.
> - No documentar mecanismos operativos temporales ni herramientas internas de experimentación.
> - Mantener lenguaje visible comprensible para el Gestor Comercial y evitar términos técnicos indebidos.
> - Alcance de plataforma: Web Desktop, viewport canónico de 1440 px; mobile/tablet fuera de alcance en esta etapa.
>
> ## Criterio de cierre
>
> Este Issue puede cerrarse únicamente cuando, para **todas** las funcionalidades aquí asignadas:
>
> - [ ] `component-spec.md` está completo y trazable.
> - [ ] `plan.md` está completo.
> - [ ] `tasks.md` está completo y ejecutado según corresponda.
> - [ ] Todas las pantallas P0 requeridas existen.
> - [ ] La autovalidación está completada.
> - [ ] La revisión UX transversal requerida está completada.
> - [ ] No existen hallazgos bloqueantes ni importantes requeridos abiertos.
> - [ ] Existe estado **APROBADO PARA FIGMA**.
> - [ ] Figma refleja fielmente la versión con visto bueno.
> - [ ] La fidelidad en Figma fue validada.
> - [ ] `validation-report.md` registra **Resultado general = APROBADO**.
> - [ ] `mockups/README.md` refleja el estado actualizado de las funcionalidades correspondientes.
>
> ## Fuera de alcance
>
> Este Issue no autoriza reinterpretar o modificar por iniciativa propia reglas de SPEC, HU, WF, Flow, contratos, arquitectura o ownership.
>
> Si una contradicción de fuente bloquea el trabajo, registrar el bloqueo y resolverlo antes de continuar.

</details>

## Issue 65

- **Título:** [MOCKUPS] Leonardo Lopez — MK-008 a MK-012
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/65).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-02T17:18:46Z; **actualizado:** 2026-10-02T17:18:47Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [docs/lopez #65](../docs/lopez/issue-065-mockups.md).

<details>
<summary>Contenido completo consultado del issue 65</summary>

> ## Issue padre
>
> Este trabajo forma parte de **#61 — [MOCKUPS] Implementar y validar los 16 mockups del módulo**.
>
> ## Objetivo
>
> Completar la documentación específica, implementación/refinamiento, autovalidación, revisión UX, pase a Figma y cierre formal de los mockups asignados a **Leonardo Lopez**.
>
> ## Responsable
>
> - **Responsable funcional:** Leonardo Lopez (`@VicuzS`)
> - **Rama oficial:** `lopez`
>
> ## Funcionalidades asignadas
>
> - `MK-008` — Gestión de categorías y subcategorías.
> - `MK-009` — Gestión de características y sus valores.
> - `MK-010` — Asociación entre tipos de producto y características.
> - `MK-011` — Gestión de marcas.
> - `MK-012` — Gestión de SEO y metadatos.
>
> ## Gate de inicio
>
> La ejecución de este issue queda **BLOQUEADA** hasta que:
>
> - [ ] #59 — UX transversal del módulo esté completado.
> - [ ] #60 — Design System de mockups esté completado.
> - [ ] Los resultados vigentes de ambos gates estén disponibles en `master`.
>
> No iniciar formalmente `component-spec.md`, `plan.md` ni `tasks.md` antes de cumplir estas condiciones.
>
> ## Fuentes obligatorias
>
> Para cada `MK-XXX`, revisar como mínimo:
>
> - SPEC correspondiente.
> - HU correspondiente.
> - WF correspondiente.
> - Flow correspondiente.
> - Contratos API vigentes cuando afecten datos, estados o interacciones.
> - `mockups/README.md`.
> - `mockups/DESIGN.md`.
> - `mockups/ux/propuesta-ux.md`.
> - `mockups/ux/ux-decisions.md`.
> - `mockups/ux/ux-guidelines.md`.
> - `mockups/_plantillas/mockup/component-spec.template.md`.
> - `mockups/_plantillas/mockup/plan.template.md`.
> - `mockups/_plantillas/mockup/tasks.template.md`.
> - `mockups/_plantillas/mockup/validation-report.template.md`.
>
> La documentación funcional y contractual vigente prevalece sobre decisiones visuales locales.
>
> ## Regla de seguimiento
>
> Este Issue registra **responsabilidad, gates y progreso macro**.
>
> Las tareas atómicas de implementación y verificación deben mantenerse en el `tasks.md` de cada `MK-XXX`; no deben duplicarse íntegramente dentro del Issue.
>
> El orden obligatorio por funcionalidad es:
>
> `component-spec.md` → `plan.md` → `tasks.md` → implementación/refinamiento → normalización → autovalidación → revisión UX transversal → **APROBADO PARA FIGMA** → Figma → validación de fidelidad → `validation-report.md` **APROBADO**.
>
> ## Trabajo por funcionalidad
>
> ### MK-008 — Gestión de categorías y subcategorías
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-008/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-008-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-008`, `HU-008`, `WF-008` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-009 — Gestión de características y sus valores
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-009/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-009-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-009`, `HU-009`, `WF-009` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-010 — Asociación entre tipos de producto y características
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-010/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-010-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-010`, `HU-010`, `WF-010` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-011 — Gestión de marcas
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-011/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-011-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-011`, `HU-011`, `WF-011` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-012 — Gestión de SEO y metadatos
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-012/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-012-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-012`, `HU-012`, `WF-012` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
>
> ## Reglas de ejecución
>
> - No inventar reglas de negocio, contratos, eventos, estados ni validaciones.
> - No redefinir la UX transversal dentro de un `MK-XXX`.
> - Si aparece una decisión UX local, documentarla como `LUX-XX`; si demuestra ser transversal, escalarla para evaluación como `UXD-XXX`.
> - No modificar funcionalidades asignadas a otro owner salvo coordinación explícita.
> - No documentar mecanismos operativos temporales ni herramientas internas de experimentación.
> - Mantener lenguaje visible comprensible para el Gestor Comercial y evitar términos técnicos indebidos.
> - Alcance de plataforma: Web Desktop, viewport canónico de 1440 px; mobile/tablet fuera de alcance en esta etapa.
>
> ## Criterio de cierre
>
> Este Issue puede cerrarse únicamente cuando, para **todas** las funcionalidades aquí asignadas:
>
> - [ ] `component-spec.md` está completo y trazable.
> - [ ] `plan.md` está completo.
> - [ ] `tasks.md` está completo y ejecutado según corresponda.
> - [ ] Todas las pantallas P0 requeridas existen.
> - [ ] La autovalidación está completada.
> - [ ] La revisión UX transversal requerida está completada.
> - [ ] No existen hallazgos bloqueantes ni importantes requeridos abiertos.
> - [ ] Existe estado **APROBADO PARA FIGMA**.
> - [ ] Figma refleja fielmente la versión con visto bueno.
> - [ ] La fidelidad en Figma fue validada.
> - [ ] `validation-report.md` registra **Resultado general = APROBADO**.
> - [ ] `mockups/README.md` refleja el estado actualizado de las funcionalidades correspondientes.
>
> ## Fuera de alcance
>
> Este Issue no autoriza reinterpretar o modificar por iniciativa propia reglas de SPEC, HU, WF, Flow, contratos, arquitectura o ownership.
>
> Si una contradicción de fuente bloquea el trabajo, registrar el bloqueo y resolverlo antes de continuar.

</details>

## Issue 66

- **Título:** [MOCKUPS] Leonardo Vera — MK-013 y MK-014
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/66).
- **Estado consultado:** open; **asignados:** @LeonardoVera.
- **Creado:** 2026-10-02T17:18:48Z; **actualizado:** 2026-10-03T01:43:53Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [docs/vera #66](../docs/vera/issue-066-mockups.md).

<details>
<summary>Contenido completo consultado del issue 66</summary>

> ## Issue padre
>
> Este trabajo forma parte de **#61 — [MOCKUPS] Implementar y validar los 16 mockups del módulo**.
>
> ## Objetivo
>
> Completar la documentación específica, implementación/refinamiento, autovalidación, revisión UX, pase a Figma y cierre formal de los mockups asignados a **Leonardo Vera Rodríguez**.
>
> ## Responsable
>
> - **Responsable funcional:** Leonardo Vera Rodríguez (`@LeonardoVera`)
> - **Rama oficial:** `vera`
>
> ## Funcionalidades asignadas
>
> - `MK-013` — Gestión de precios individuales y masivos.
> - `MK-014` — Historial de auditoría de precios.
>
> ## Gate de inicio
>
> La ejecución de este issue queda **BLOQUEADA** hasta que:
>
> - [x] #59 — UX transversal del módulo esté completado.
> - [x] #60 — Design System de mockups esté completado.
> - [ ] Los resultados vigentes de ambos gates estén disponibles en `master`.
>
> No iniciar formalmente `component-spec.md`, `plan.md` ni `tasks.md` antes de cumplir estas condiciones.
>
> ## Fuentes obligatorias
>
> Para cada `MK-XXX`, revisar como mínimo:
>
> - SPEC correspondiente.
> - HU correspondiente.
> - WF correspondiente.
> - Flow correspondiente.
> - Contratos API vigentes cuando afecten datos, estados o interacciones.
> - `mockups/README.md`.
> - `mockups/DESIGN.md`.
> - `mockups/ux/propuesta-ux.md`.
> - `mockups/ux/ux-decisions.md`.
> - `mockups/ux/ux-guidelines.md`.
> - `mockups/_plantillas/mockup/component-spec.template.md`.
> - `mockups/_plantillas/mockup/plan.template.md`.
> - `mockups/_plantillas/mockup/tasks.template.md`.
> - `mockups/_plantillas/mockup/validation-report.template.md`.
>
> La documentación funcional y contractual vigente prevalece sobre decisiones visuales locales.
>
> ## Regla de seguimiento
>
> Este Issue registra **responsabilidad, gates y progreso macro**.
>
> Las tareas atómicas de implementación y verificación deben mantenerse en el `tasks.md` de cada `MK-XXX`; no deben duplicarse íntegramente dentro del Issue.
>
> El orden obligatorio por funcionalidad es:
>
> `component-spec.md` → `plan.md` → `tasks.md` → implementación/refinamiento → normalización → autovalidación → revisión UX transversal → **APROBADO PARA FIGMA** → Figma → validación de fidelidad → `validation-report.md` **APROBADO**.
>
> > Para `MK-013` y `MK-014`, aplicar la gobernanza de revisión vigente sin introducir un revisor alternativo no documentado.
>
> ## Trabajo por funcionalidad
>
> ### MK-013 — Gestión de precios individuales y masivos
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-013/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-013-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-013`, `HU-013`, `WF-013` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Completar y registrar la revisión UX transversal conforme a la gobernanza vigente.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-014 — Historial de auditoría de precios
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-014/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-014-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-014`, `HU-014`, `WF-014` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Completar y registrar la revisión UX transversal conforme a la gobernanza vigente.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
>
> ## Reglas de ejecución
>
> - No inventar reglas de negocio, contratos, eventos, estados ni validaciones.
> - No redefinir la UX transversal dentro de un `MK-XXX`.
> - Si aparece una decisión UX local, documentarla como `LUX-XX`; si demuestra ser transversal, escalarla para evaluación como `UXD-XXX`.
> - No modificar funcionalidades asignadas a otro owner salvo coordinación explícita.
> - No documentar mecanismos operativos temporales ni herramientas internas de experimentación.
> - Mantener lenguaje visible comprensible para el Gestor Comercial y evitar términos técnicos indebidos.
> - Alcance de plataforma: Web Desktop, viewport canónico de 1440 px; mobile/tablet fuera de alcance en esta etapa.
>
> ## Criterio de cierre
>
> Este Issue puede cerrarse únicamente cuando, para **todas** las funcionalidades aquí asignadas:
>
> - [ ] `component-spec.md` está completo y trazable.
> - [ ] `plan.md` está completo.
> - [ ] `tasks.md` está completo y ejecutado según corresponda.
> - [ ] Todas las pantallas P0 requeridas existen.
> - [ ] La autovalidación está completada.
> - [ ] La revisión UX transversal requerida está completada.
> - [ ] No existen hallazgos bloqueantes ni importantes requeridos abiertos.
> - [ ] Existe estado **APROBADO PARA FIGMA**.
> - [ ] Figma refleja fielmente la versión con visto bueno.
> - [ ] La fidelidad en Figma fue validada.
> - [ ] `validation-report.md` registra **Resultado general = APROBADO**.
> - [ ] `mockups/README.md` refleja el estado actualizado de las funcionalidades correspondientes.
>
> ## Fuera de alcance
>
> Este Issue no autoriza reinterpretar o modificar por iniciativa propia reglas de SPEC, HU, WF, Flow, contratos, arquitectura o ownership.
>
> Si una contradicción de fuente bloquea el trabajo, registrar el bloqueo y resolverlo antes de continuar.

</details>

## Issue 67

- **Título:** [MOCKUPS] Miguel — MK-015 y MK-016
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/67).
- **Estado consultado:** open; **asignados:** @MiguelTacoZavala.
- **Creado:** 2026-10-02T17:18:51Z; **actualizado:** 2026-10-02T17:18:51Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [docs/taco #67](../docs/taco/issue-067-mockups.md).

<details>
<summary>Contenido completo consultado del issue 67</summary>

> ## Issue padre
>
> Este trabajo forma parte de **#61 — [MOCKUPS] Implementar y validar los 16 mockups del módulo**.
>
> ## Objetivo
>
> Completar la documentación específica, implementación/refinamiento, autovalidación, revisión UX, pase a Figma y cierre formal de los mockups asignados a **Miguel Ángel Taco Zavala**.
>
> ## Responsable
>
> - **Responsable funcional:** Miguel Ángel Taco Zavala (`@MiguelTacoZavala`)
> - **Rama oficial:** `taco`
>
> ## Funcionalidades asignadas
>
> - `MK-015` — Control de stock y disponibilidad.
> - `MK-016` — Dashboard analítico y alertas de stock.
>
> ## Gate de inicio
>
> La ejecución de este issue queda **BLOQUEADA** hasta que:
>
> - [ ] #59 — UX transversal del módulo esté completado.
> - [ ] #60 — Design System de mockups esté completado.
> - [ ] Los resultados vigentes de ambos gates estén disponibles en `master`.
>
> No iniciar formalmente `component-spec.md`, `plan.md` ni `tasks.md` antes de cumplir estas condiciones.
>
> ## Fuentes obligatorias
>
> Para cada `MK-XXX`, revisar como mínimo:
>
> - SPEC correspondiente.
> - HU correspondiente.
> - WF correspondiente.
> - Flow correspondiente.
> - Contratos API vigentes cuando afecten datos, estados o interacciones.
> - `mockups/README.md`.
> - `mockups/DESIGN.md`.
> - `mockups/ux/propuesta-ux.md`.
> - `mockups/ux/ux-decisions.md`.
> - `mockups/ux/ux-guidelines.md`.
> - `mockups/_plantillas/mockup/component-spec.template.md`.
> - `mockups/_plantillas/mockup/plan.template.md`.
> - `mockups/_plantillas/mockup/tasks.template.md`.
> - `mockups/_plantillas/mockup/validation-report.template.md`.
>
> La documentación funcional y contractual vigente prevalece sobre decisiones visuales locales.
>
> ## Regla de seguimiento
>
> Este Issue registra **responsabilidad, gates y progreso macro**.
>
> Las tareas atómicas de implementación y verificación deben mantenerse en el `tasks.md` de cada `MK-XXX`; no deben duplicarse íntegramente dentro del Issue.
>
> El orden obligatorio por funcionalidad es:
>
> `component-spec.md` → `plan.md` → `tasks.md` → implementación/refinamiento → normalización → autovalidación → revisión UX transversal → **APROBADO PARA FIGMA** → Figma → validación de fidelidad → `validation-report.md` **APROBADO**.
>
> ## Trabajo por funcionalidad
>
> ### MK-015 — Control de stock y disponibilidad
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-015/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-015-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-015`, `HU-015`, `WF-015` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
> ### MK-016 — Dashboard analítico y alertas de stock
>
> #### Documentación específica
>
> - [ ] Crear `mockups/MK-016/`.
> - [ ] Elaborar `component-spec.md` a partir de las fuentes vigentes.
> - [ ] Inventariar todas las pantallas P0 (`MK-016-SXX`) requeridas.
> - [ ] Registrar decisiones locales `LUX-XX` solo cuando sean realmente específicas de esta funcionalidad.
> - [ ] Elaborar `plan.md` derivado del `component-spec.md`.
> - [ ] Elaborar `tasks.md` derivado del `component-spec.md` y `plan.md`.
> - [ ] Confirmar que el `MK` cumple la Definition of Ready de `mockups/README.md`.
>
> #### Implementación y refinamiento
>
> - [ ] Implementar/refinar todas las pantallas P0 definidas.
> - [ ] Normalizar el código contra React, TypeScript, Mantine, Tabler Icons, tema central y Design System.
> - [ ] Implementar estados requeridos, semántica y accesibilidad.
> - [ ] Validar Web Desktop en viewport canónico de 1440 px.
> - [ ] Mantener trazabilidad con `SPEC-016`, `HU-016`, `WF-016` y Flow correspondiente.
>
> #### Validación y cierre
>
> - [ ] Completar la autovalidación local y registrar hallazgos.
> - [ ] Solicitar y completar la revisión UX transversal de Leonardo Vera Rodríguez.
> - [ ] Resolver todos los hallazgos bloqueantes e importantes requeridos.
> - [ ] Obtener/registrar el estado **APROBADO PARA FIGMA**.
> - [ ] Reflejar fielmente la versión con visto bueno en Figma.
> - [ ] Validar fidelidad entre Figma y la versión aprobada para Figma.
> - [ ] Registrar el enlace de Figma.
> - [ ] Completar `validation-report.md` con **Resultado general = APROBADO**.
>
>
> ## Reglas de ejecución
>
> - No inventar reglas de negocio, contratos, eventos, estados ni validaciones.
> - No redefinir la UX transversal dentro de un `MK-XXX`.
> - Si aparece una decisión UX local, documentarla como `LUX-XX`; si demuestra ser transversal, escalarla para evaluación como `UXD-XXX`.
> - No modificar funcionalidades asignadas a otro owner salvo coordinación explícita.
> - No documentar mecanismos operativos temporales ni herramientas internas de experimentación.
> - Mantener lenguaje visible comprensible para el Gestor Comercial y evitar términos técnicos indebidos.
> - Alcance de plataforma: Web Desktop, viewport canónico de 1440 px; mobile/tablet fuera de alcance en esta etapa.
>
> ## Criterio de cierre
>
> Este Issue puede cerrarse únicamente cuando, para **todas** las funcionalidades aquí asignadas:
>
> - [ ] `component-spec.md` está completo y trazable.
> - [ ] `plan.md` está completo.
> - [ ] `tasks.md` está completo y ejecutado según corresponda.
> - [ ] Todas las pantallas P0 requeridas existen.
> - [ ] La autovalidación está completada.
> - [ ] La revisión UX transversal requerida está completada.
> - [ ] No existen hallazgos bloqueantes ni importantes requeridos abiertos.
> - [ ] Existe estado **APROBADO PARA FIGMA**.
> - [ ] Figma refleja fielmente la versión con visto bueno.
> - [ ] La fidelidad en Figma fue validada.
> - [ ] `validation-report.md` registra **Resultado general = APROBADO**.
> - [ ] `mockups/README.md` refleja el estado actualizado de las funcionalidades correspondientes.
>
> ## Fuera de alcance
>
> Este Issue no autoriza reinterpretar o modificar por iniciativa propia reglas de SPEC, HU, WF, Flow, contratos, arquitectura o ownership.
>
> Si una contradicción de fuente bloquea el trabajo, registrar el bloqueo y resolverlo antes de continuar.

</details>
