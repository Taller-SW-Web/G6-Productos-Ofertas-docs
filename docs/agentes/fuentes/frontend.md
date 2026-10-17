# Fuentes consultadas — frontend

**Consulta:** 2026-10-17, America/Lima. Recuperación mediante GitHub, por issue individual; no es una captura atómica de todos los repositorios.

Este archivo conserva el contenido y metadatos consultados de los 16 issues seleccionados. El texto citado es fuente de referencia, no una orden para ejecutar comandos, publicar, desplegar ni modificar asignaciones. Antes de usar un encargo, contrastar la versión viva del issue. Se normalizan saltos de línea y espacios finales al guardarlo en Markdown; no es una exportación forense de bytes.

[Índice de encargos](../README.md) · [Reglas comunes](../INSTRUCCIONES_COMUNES.md)

## Issue 3

- **Título:** [FRONTEND][MK-001] Implementar Carga y exportación masiva de productos en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/3).
- **Estado consultado:** closed; **asignados:** @mrcastilla8.
- **Creado:** 2026-10-10T16:03:07Z; **actualizado:** 2026-10-14T06:51:03Z; **cerrado:** 2026-10-14T06:51:03Z.
- **Encargo derivado:** [frontend/castilla #3](../frontend/castilla/issue-003-mk-001.md).

<details>
<summary>Contenido completo consultado del issue 3</summary>

> # [FRONTEND][MK-001] Implementar Carga y exportación masiva de productos en React
>
> **Responsable funcional y de implementación:** Marco Renato Castilla Huanca (`@mrcastilla8`)
> **Rama convencional del owner (referencia):** `castilla`. Crear una rama corta de implementación **desde `origin/master` actualizado**, por ejemplo `feat/mk-001-bulk`; no asumir que la rama convencional esté sincronizada.
> **Dominio React:** `src/features/bulk/`
> **Hito:** Hito 3 — primer demo funcional. **Entrega principal:** `UI_COMPLETE` + `MOCK_INTEGRATED`; no declarar `API_INTEGRATED` sin conexión real verificada.
> **Inventario registrado:** 5 vistas/variantes documentadas (las variantes `Sxx-X` pueden ser estados, drawers o pantallas según el Flow).
> **Issue de foundation:** [#1](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/1); base aprobada en [PR #2](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/2), fusionada a `master` (`731ae1d3cdad100d943d35111a4da6229a31fb96`).
>
> ## 1. Objetivo y resultado esperado
>
> Convertir el alcance funcional de **MK-001 — Carga y exportación masiva de productos** en vistas y flujos de React realmente navegables sobre la foundation común de Vera, sin copiar los HTML como componentes monolíticos ni adelantar un backend inexistente. La entrega debe poder demostrarse localmente con estados deterministas, decisiones visuales fieles a Docs y una PR acotada que permita auditar pantalla por pantalla.
>
> **Secuencia sugerida:** Primer flujo demostrable: selección → revisión → seguimiento → resultado.
>
> ## 2. Fuentes normativas — consultar ANTES de modificar el código
>
> 1. [MK-001: `component-spec.md`, `plan.md`, `tasks.md`, `validation-report.md` y `prototipo/`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/tree/master/ux/mockups/MK-001). Revisar qué archivos/HTML existen realmente, su estado de aprobación y divergencias; la presencia de HTML **no** acredita `APROBADO`.
> 2. [Design System `ux/mockups/DESIGN.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/DESIGN.md) y [UX Guidelines](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/ux/ux-guidelines.md), [UX Decisions](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/ux/ux-decisions.md).
> 3. Documentos de negocio **SPEC-001**, **HU-001**, **FLOW-001**, **WF-001**, localizados por identificador en [`requisitos/specs/`, `requisitos/hu/`, `requisitos/flujos/`, `ux/wireframes/flows/`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs). No adivinar sufijos de archivo ni versiones.
> 4. [OpenAPI HTTP](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/contratos/http/openapi.yaml) y contratos/eventos pertinentes **solo** para delimitar comportamiento/datos; si el contrato pertenece a otro módulo, consultar su fuente oficial.
> 5. En Frontend: [`AGENTS.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/AGENTS.md), [`README.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/README.md), [`docs/GUIA_IMPLEMENTACION_FRONTEND_REACT.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/docs/GUIA_IMPLEMENTACION_FRONTEND_REACT.md) y [catálogo real de shared](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/docs/COMPONENTES_FOUNDATION.md).
>
> **Autoridad:** SPEC/HU/FLOW + contratos para negocio y datos; UX + `DESIGN.md` para apariencia; HTML como composición de referencia; arquitectura React de `master` para implementación. Registrar SHA de Docs y de Frontend usado en la PR. Ante discrepancias, **no inventar** ni cambiar Docs desde esta tarea.
>
> ## 3. Inventario exhaustivo de pantallas y criterios individuales
>
> ### MK-001-S01 — Cargar archivo (P0)
>
> - [ ] **Composición y datos:** Punto de entrada a importaciones y exportaciones; explicar formato y finalidad del flujo.
> - [ ] **Interacción y navegación:** Permitir elegir/reemplazar archivo y continuar a S02 conservando identidad del seleccionado.
> - [ ] **Estados y resultado verificable:** Sin archivo, archivo seleccionado, ayuda visible, errores de selección; no enviar aún.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-001-S02 — Revisar archivo (P0)
>
> - [ ] **Composición y datos:** Vista de prevalidación de formato/estructura y resumen de lo que será enviado.
> - [ ] **Interacción y navegación:** Corregir/reemplazar archivo invalida revisión anterior; confirmar solo un envío válido y conducir a S03 tras admisión mock.
> - [ ] **Estados y resultado verificable:** Errores localizables, decisión de confirmar/cancelar, doble envío bloqueado.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-001-S03 — Seguimiento de importación (P0)
>
> - [ ] **Composición y datos:** Separar lote admitido, iniciado, en procesamiento y verificación de estado.
> - [ ] **Interacción y navegación:** Consultar/actualizar progreso autorizado y avanzar a S04 solo con resultado terminal reconocido.
> - [ ] **Estados y resultado verificable:** Sin progreso medible, consulta fallida y reintento; nunca inventar porcentajes.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-001-S04 — Resultado del lote (P0)
>
> - [ ] **Composición y datos:** Mostrar éxitos, errores, filas afectadas y reportes si la fuente los proporciona.
> - [ ] **Interacción y navegación:** Descargar reporte disponible, volver/reanudar el mismo lote cuando haya continuidad respaldada.
> - [ ] **Estados y resultado verificable:** Completado, fallido, parcial/completado con observaciones (WF S-04-E), reporte no disponible.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-001-S05 — Descargas y exportación de catálogo (P0)
>
> - [ ] **Composición y datos:** Catálogo de plantilla y solicitud/seguimiento de exportación.
> - [ ] **Interacción y navegación:** Permitir descargar plantilla y lanzar solicitud mock de exportación, con descarga solo cuando el resultado sea disponible.
> - [ ] **Estados y resultado verificable:** Generación pendiente, lista, fallida, sin link; no fabricar archivo del servidor.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
>
> **Advertencia sobre rutas:** `/MK001/Sxx` corresponde al prototipo académico. **No usarlo automáticamente como URL del producto.** Registrar una ruta de negocio descriptiva y consistente en el router existente; los estados y diálogos pueden no exigir rutas adicionales. La trazabilidad `MK-001-Sxx` debe mantenerse en pruebas/evidencia.
>
> ## 4. Interacciones y escenarios mínimos de prueba
>
> - [ ] Archivo sin seleccionar, archivo con formato inválido y archivo candidato válido
> - [ ] Revisión corregida antes del envío; confirmar solo cuando proceda
> - [ ] Lote admitido sin progreso fiable, lote en curso y estado no consultable
> - [ ] Resultado total, parcial con observaciones, fallido y reanudable
> - [ ] Plantilla disponible, exportación solicitada, lista y fallida
>
> Para cada escenario documentar: **entrada → acción → estado visible/resultado → navegación → fuente normativa**. Debe existir al menos un camino de éxito mock y uno de error, salvo una pantalla puramente de lectura que documente su propio estado de error. La simulación local no debe afirmar transacción real.
>
> ## 5. Reglas funcionales / riesgos específicos del dominio
>
> - Diferenciar validación local del archivo, admisión del lote, procesamiento, finalización y exportación.
> - No mostrar porcentaje ni tiempo restante si no existen métricas confiables del provider.
> - Una reanudación corresponde al mismo lote: no crear un lote nuevo ni duplicar operaciones ya completadas.
> - WF-001 S-04-E es estado de S04 (completado con observaciones), no nueva pantalla.
>
> **Integración o coordinación entre dominios:** Depende del contrato de importación/estado de lotes de bulk-svc; usar adaptadores mock mientras no haya proveedor ejecutable.
>
> Si se detecta un contrato ausente, fuente no aprobada o P0 abierto: registrar `BLOCKED_CONTRACT`/`BLOCKED_DOCS`, fuente exacta, efecto en pantalla y **parte segura que sí puede implementarse**. No bloquear todo el MK por un adaptador HTTP pendiente ni marcar como terminada una acción inexistente. Las operaciones monetarias, saldo, permisos, reintentos e identidad se rigen por provider, nunca por suposiciones de JSX.
>
> ## 6. Implementación sobre la foundation aprobada
>
> **Preflight obligatorio**
> - [ ] `git fetch origin --prune`, inspeccionar `git status --short`, ramas y commit de `origin/master`; crear rama de feature nueva a partir de `origin/master`, sin destruir cambios ajenos.
> - [ ] Ejecutar `npm ci`, `npm run typecheck`, `npm run build`, `npm run lint` de `master` para establecer baseline; registrar si ya había errores antes del cambio.
> - [ ] Leer `src/app/layout/ApplicationShell.tsx`, `src/app/routes/productPages.tsx`, `productRoutes.tsx`, `src/app/navigation/navigation.ts`, `src/theme/`, `src/components/shared/index.ts` y ejemplos de `src/features/pricing/` / `src/features/foundation/`.
> - [ ] Listar qué componentes shared reutilizarás: `PageHeader`, `SectionCard`, `FilterBar`, `SearchField`, `StatusBadge`, `FeedbackAlert`, `EmptyState`, `EntityTable`, `ConfirmDialog`, `MetricCard` y `FileSelection` **según necesidad real**. No crear copias con otro nombre.
>
> **Ejecución**
> - [ ] Crear solo archivos utilizados dentro de `src/features/bulk/`: `pages/`, `components/`, `hooks/`, `services/`, `adapters/`, `mocks/` si la arquitectura lo requiere.
> - [ ] Separar **página → componentes de presentación → hook/controlador → interfaz de servicio/puerto → adapter mock → fixtures deterministas**. No acceder a HTTP desde JSX; no incrustar listas grandes de prueba en páginas.
> - [ ] Reutilizar Mantine/Tabler, tipografías Inter/Oswald y tokens de `src/theme` trazables a `DESIGN.md`; evitar colores HEX locales, `primary` alternativo, fondos sombreados innecesarios o badges multicolor por categorías.
> - [ ] Mantener modelos tipados independientes de DTO externos; no usar `any` como escape general. Estado y errores explícitos. Formularios controlados; validaciones por campo; deshabilitar doble envío.
> - [ ] Registrar vistas de producto en `src/app/routes/productPages.tsx` y `productRoutes.tsx`, navegación en `src/app/navigation/navigation.ts`. Mantener `/foundation/*` como galería separada; no destruir `/precios`.
> - [ ] Diseñar parámetros de URL/estado para persistir contexto relevante y permitir atrás/adelante cuando corresponda; no afirmar que esos parámetros son contratos API.
> - [ ] Proporcionar estados `loading`, `empty`, `error`, `success`, `disabled`, `submitting` donde apliquen; nunca convertir error de lectura en lista vacía o precio/stock cero.
> - [ ] Mantener `focus`, labels, ayudas, feedback y cancelación accesibles con teclado; verificar no superponer modales y retornar foco correctamente.
> - [ ] No modificar `src/theme/`, `src/components/shared/`, AppShell o contratos de otras features salvo necesidad transversal demostrada; coordinar primero con Vera y justificar la modificación en la PR.
>
> **Restricción de alcance:** no implementar backend, BD, autenticación real, nuevos permisos/scopes, cálculos comerciales autoritativos ni endpoints inventados; no copiar prototipos HTML de Docs al código productivo. La UI puede mostrar resultados de mocks identificados como ficticios. No imponer variantes mobile/tablet fuera del alcance normativo desktop actual.
>
> ## 7. Quality Gates: técnicos, funcionales y visuales
>
> - [ ] `npm ci`: PASS/FAIL/NO EJECUTADO, con versión de Node/npm.
> - [ ] `npm run typecheck`: PASS/FAIL/NO EJECUTADO.
> - [ ] `npm run build`: PASS/FAIL/NO EJECUTADO.
> - [ ] `npm run lint`: PASS/FAIL/NO EJECUTADO.
> - [ ] Tests existentes/pertinentes (`npm test`, Playwright u otros configurados): PASS/FAIL/NO EJECUTADO; no modificar tests ajenos para ocultar fallas.
> - [ ] Revisión desktop **1440 × 900** (ancho canónico 1440): capturas reales de cada pantalla principal y variantes clave; sin overflow involuntario, cortes, solapamientos, degradación de títulos/controles o scroll oculto.
> - [ ] Tablas largas, identificadores extensos, mensajes de error, carga y estado vacío inspeccionados; navegación por teclado, foco visible y retorno comprobados.
> - [ ] Comparación visual contra `DESIGN.md` vigente; documentar diferencias corregidas respecto del HTML y las decisiones pendientes del owner UX.
> - [ ] Verificación manual del flujo principal y al menos los escenarios de error indicados en §4; no declarar `VALIDATED` o `API_INTEGRATED` por tener capturas mock.
>
> ## 8. Evidencia y PR obligatoria
>
> La PR debe apuntar a **`master`**, tener título `feat(frontend): MK-001 — Carga y exportación masiva de productos` y vincular este issue con `Closes #N` **solo cuando el alcance completo esté resuelto** (si existen etapas pendientes, usar `Refs #N`). Los cambios de rutas compartidas entre varios owners deben resolverse sin eliminar rutas ajenas. Solicitar revisión antes de mergear.
>
> **Matriz de trazabilidad a completar en la PR** (no significa que ya esté validado):
>
> | Pantalla | Qué se debe mostrar | Prioridad | Ruta/componente React real | Evidencia y resultado |
> |---|---|---|---|---|
> | MK-001-S01 | Cargar archivo | P0 | Pendiente | Pendiente |
> | MK-001-S02 | Revisar archivo | P0 | Pendiente | Pendiente |
> | MK-001-S03 | Seguimiento de importación | P0 | Pendiente | Pendiente |
> | MK-001-S04 | Resultado del lote | P0 | Pendiente | Pendiente |
> | MK-001-S05 | Descargas y exportación de catálogo | P0 | Pendiente | Pendiente |
>
> **Reporte técnico y funcional requerido:**
> ```text
> Issue: MK-001
> Responsable / rama / SHA: ...
> Docs master SHA y versión DESIGN: ...
> Pantallas y estados implementados: ...
> Rutas productivas registradas: ...
> Shared reutilizados / shared propuestos: ...
> Modelo(s) de presentación y mocks: ...
> Flujos y escenarios probados: ...
> API real: NO (salvo integración demostrada separadamente)
> Tests y comandos (PASS/FAIL/NO EJECUTADO): ...
> Revisión visual 1440 px y capturas: ...
> Diferencias de HTML vs DESIGN: ...
> Bloqueos contractuales/documentales: ...
> Archivos creados/modificados: ...
> Deuda pendiente fuera de alcance: ...
> ```
>
> **Revisión UX:** solicitar a Leonardo Vera una revisión de fidelidad y consistencia visual; revisión funcional/técnica por otra persona cuando proceda.
>
> ## 9. Definition of Done
>
> - [ ] Cobertura completa de las pantallas P0 enumeradas arriba (P1 separado cuando esté indicado), con contexto, validaciones, estados y navegación verificables.
> - [ ] Mocks/adapters tipados sustituibles por HTTP sin reescribir JSX; código de negocio no trasladado a la UI.
> - [ ] Estilo unificado con la Foundation; sin duplicar theme, AppShell o patrones compartidos existentes.
> - [ ] Evidencias y checks reales incorporados a PR; ninguna declaración engañosa de PASS, despliegue o integración.
> - [ ] Revisión funcional y UX/técnica correspondiente, con hallazgos importantes cerrados o documentados como limitación acordada.
> - [ ] Se entrega una demo navegable por navegador local sin backend y se informa exactamente qué está simulado.
>
> **No cerrar este issue por publicar un prototipo parcial:** las pantallas sin implementar, validaciones pendientes y bloqueos permanecen explícitos hasta su resolución o replanteamiento aprobado.

</details>

## Issue 4

- **Título:** [FRONTEND][MK-002] Implementar Gestión de combos de productos en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/4).
- **Estado consultado:** open; **asignados:** @mrcastilla8.
- **Creado:** 2026-10-10T16:03:10Z; **actualizado:** 2026-10-17T08:08:01Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/castilla #4](../frontend/castilla/issue-004-mk-002.md).

<details>
<summary>Contenido completo consultado del issue 4</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: mrcastilla8. Área: src/features/combos.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-002 Combos: CRUD y composición SKU mock, consistentes e idempotentes. Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> CRUD/validación/estados mock; no usar combos-svc. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 5

- **Título:** [FRONTEND][MK-003] Implementar Gestión de productos (CRUD principal) en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/5).
- **Estado consultado:** open; **asignados:** @GabrielPGu.
- **Creado:** 2026-10-10T16:03:13Z; **actualizado:** 2026-10-17T08:09:52Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/poma #5](../frontend/poma/issue-005-mk-003.md).

<details>
<summary>Contenido completo consultado del issue 5</summary>

> ## Clasificación y owner
> DEMO_P0 · API_REAL. Owner único: GabrielPGu. Área: src/features/catalog.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-003 CRUD de productos y estados según SPEC. Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> API vía Gateway; errores 400/404/409/5xx visibles; mock solo explícito, sin fallback en api. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - [Backend #43](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/43)
> - [Backend #44](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/44)
> - [Backend #45](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/45)
> - [Backend #46](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/46)
> - [Backend #47](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/47)
> - [Backend #106](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/106)
> - [Backend #107](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/107)
> - [Backend #109](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/109)
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 6

- **Título:** [FRONTEND][MK-004] Implementar Gestión avanzada de variantes (SKU) en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/6).
- **Estado consultado:** open; **asignados:** @GabrielPGu.
- **Creado:** 2026-10-10T16:03:15Z; **actualizado:** 2026-10-17T08:09:54Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/poma #6](../frontend/poma/issue-006-mk-004.md).

<details>
<summary>Contenido completo consultado del issue 6</summary>

> ## Clasificación y owner
> DEMO_P0 · API_REAL. Owner único: GabrielPGu. Área: src/features/catalog.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-004 variantes vendibles/SKU y su relación con producto. Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> API vía Gateway; errores 400/404/409/5xx visibles; mock solo explícito, sin fallback en api. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - [Backend #43](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/43)
> - [Backend #44](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/44)
> - [Backend #45](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/45)
> - [Backend #46](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/46)
> - [Backend #47](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/47)
> - [Backend #106](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/106)
> - [Backend #107](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/107)
> - [Backend #109](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/109)
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 7

- **Título:** [FRONTEND][MK-005] Implementar Gestión de cupones de descuento en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/7).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-10T16:03:18Z; **actualizado:** 2026-10-17T08:08:08Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/lopez #7](../frontend/lopez/issue-007-mk-005.md).

<details>
<summary>Contenido completo consultado del issue 7</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: VicuzS. Área: src/features/promotions.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-005 CRUD y reglas de cupón, vigencia/estado. Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Crear/editar/activar/validar mock coherente; backend Promotions no es demo dependency. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 8

- **Título:** [FRONTEND][MK-006] Implementar Gestión de ofertas y promociones en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/8).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-10T16:03:20Z; **actualizado:** 2026-10-17T08:08:10Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/lopez #8](../frontend/lopez/issue-008-mk-006.md).

<details>
<summary>Contenido completo consultado del issue 8</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: VicuzS. Área: src/features/promotions.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-006 promociones y reglas de elegibilidad. Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Crear/editar/activar/validar mock coherente; backend Promotions no es demo dependency. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 9

- **Título:** [FRONTEND][MK-007] Implementar Reglas de venta cruzada y upselling en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/9).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-10T16:03:23Z; **actualizado:** 2026-10-17T08:08:12Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/lopez #9](../frontend/lopez/issue-009-mk-007.md).

<details>
<summary>Contenido completo consultado del issue 9</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: VicuzS. Área: src/features/promotions.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-007 cross-sell/upselling y recomendaciones vinculadas a catálogo. Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Crear/editar/activar/validar mock coherente; backend Promotions no es demo dependency. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 10

- **Título:** [FRONTEND][MK-008] Implementar Categorías y subcategorías en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/10).
- **Estado consultado:** closed; **asignados:** @VicuzS.
- **Creado:** 2026-10-10T16:03:25Z; **actualizado:** 2026-10-17T08:35:16Z; **cerrado:** 2026-10-17T08:35:16Z.
- **Encargo derivado:** [frontend/lopez #10](../frontend/lopez/issue-010-mk-008.md).

<details>
<summary>Contenido completo consultado del issue 10</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: VicuzS. Área: src/features/taxonomy.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-008 categorías/subcategorías jerárquicas Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Flujos y validaciones mock funcionales; no exigir CRUD Taxonomy API. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 11

- **Título:** [FRONTEND][MK-009] Implementar Características y valores permitidos en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/11).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-10T16:03:28Z; **actualizado:** 2026-10-17T08:08:16Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/lopez #11](../frontend/lopez/issue-011-mk-009.md).

<details>
<summary>Contenido completo consultado del issue 11</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: VicuzS. Área: src/features/taxonomy.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-009 características y valores permitidos Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Flujos y validaciones mock funcionales; no exigir CRUD Taxonomy API. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 12

- **Título:** [FRONTEND][MK-010] Implementar Tipos de producto y asociación de características en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/12).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-10T16:03:31Z; **actualizado:** 2026-10-17T08:08:18Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/lopez #12](../frontend/lopez/issue-012-mk-010.md).

<details>
<summary>Contenido completo consultado del issue 12</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: VicuzS. Área: src/features/taxonomy.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-010 tipos y asociaciones de características Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Flujos y validaciones mock funcionales; no exigir CRUD Taxonomy API. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 13

- **Título:** [FRONTEND][MK-011] Implementar Gestión de marcas en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/13).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-10T16:03:34Z; **actualizado:** 2026-10-17T08:08:20Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/lopez #13](../frontend/lopez/issue-013-mk-011.md).

<details>
<summary>Contenido completo consultado del issue 13</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: VicuzS. Área: src/features/taxonomy.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-011 marcas Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Flujos y validaciones mock funcionales; no exigir CRUD Taxonomy API. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 14

- **Título:** [FRONTEND][MK-012] Implementar SEO y metadatos por categoría en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/14).
- **Estado consultado:** open; **asignados:** @VicuzS.
- **Creado:** 2026-10-10T16:03:36Z; **actualizado:** 2026-10-17T08:08:23Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/lopez #14](../frontend/lopez/issue-014-mk-012.md).

<details>
<summary>Contenido completo consultado del issue 14</summary>

> ## Clasificación y owner
> DEMO_P0 · MOCK_FUNCIONAL. Owner único: VicuzS. Área: src/features/taxonomy.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-012 SEO/metadatos por categoría Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Flujos y validaciones mock funcionales; no exigir CRUD Taxonomy API. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - Ninguno para esta fase.
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 15

- **Título:** [FRONTEND][MK-013] Implementar Gestión de precios individuales y masivos en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/15).
- **Estado consultado:** closed; **asignados:** @LeonardoVera.
- **Creado:** 2026-10-10T16:03:39Z; **actualizado:** 2026-10-17T06:32:02Z; **cerrado:** 2026-10-17T06:32:02Z.
- **Encargo derivado:** [frontend/vera #15](../frontend/vera/issue-015-mk-013.md).

<details>
<summary>Contenido completo consultado del issue 15</summary>

> # [FRONTEND][MK-013] Implementar Gestión de precios individuales y masivos en React
>
> **Responsable funcional y de implementación:** Leonardo Vera Rodríguez (`@LeonardoVera`)
> **Rama convencional del owner (referencia):** `vera`. Crear una rama corta de implementación **desde `origin/master` actualizado**, por ejemplo `feat/mk-013-pricing`; no asumir que la rama convencional esté sincronizada.
> **Dominio React:** `src/features/pricing/`
> **Hito:** Hito 3 — primer demo funcional. **Entrega principal:** `UI_COMPLETE` + `MOCK_INTEGRATED`; no declarar `API_INTEGRATED` sin conexión real verificada.
> **Inventario registrado:** 6 vistas/variantes documentadas (las variantes `Sxx-X` pueden ser estados, drawers o pantallas según el Flow).
> **Issue de foundation:** [#1](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/1); base aprobada en [PR #2](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/2), fusionada a `master` (`731ae1d3cdad100d943d35111a4da6229a31fb96`).
>
> ## 1. Objetivo y resultado esperado
>
> Convertir el alcance funcional de **MK-013 — Gestión de precios individuales y masivos** en vistas y flujos de React realmente navegables sobre la foundation común de Vera, sin copiar los HTML como componentes monolíticos ni adelantar un backend inexistente. La entrega debe poder demostrarse localmente con estados deterministas, decisiones visuales fieles a Docs y una PR acotada que permita auditar pantalla por pantalla.
>
> **Secuencia sugerida:** Conservar S01 implementado; convertir muestras S02-S05 a pantallas reales con mocks; añadir S06.
>
> > **Preexistencia verificada:** el piloto **MK-013-S01** ya está implementado en `src/features/pricing/pages/CurrentPricePage.tsx`, publicado en `/precios`, sobre adapters mock. La galería `/foundation/pricing` contiene muestras de componentes S02–S05, **no** flujos funcionales completos. La tarea es extender e integrar, no rehacer la foundation.
>
> ## 2. Fuentes normativas — consultar ANTES de modificar el código
>
> 1. [MK-013: `component-spec.md`, `plan.md`, `tasks.md`, `validation-report.md` y `prototipo/`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/tree/master/ux/mockups/MK-013). Revisar qué archivos/HTML existen realmente, su estado de aprobación y divergencias; la presencia de HTML **no** acredita `APROBADO`.
> 2. [Design System `ux/mockups/DESIGN.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/DESIGN.md) y [UX Guidelines](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/ux/ux-guidelines.md), [UX Decisions](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/ux/ux-decisions.md).
> 3. Documentos de negocio **SPEC-013**, **HU-013**, **FLOW-013**, **WF-013**, localizados por identificador en [`requisitos/specs/`, `requisitos/hu/`, `requisitos/flujos/`, `ux/wireframes/flows/`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs). No adivinar sufijos de archivo ni versiones.
> 4. [OpenAPI HTTP](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/contratos/http/openapi.yaml) y contratos/eventos pertinentes **solo** para delimitar comportamiento/datos; si el contrato pertenece a otro módulo, consultar su fuente oficial.
> 5. En Frontend: [`AGENTS.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/AGENTS.md), [`README.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/README.md), [`docs/GUIA_IMPLEMENTACION_FRONTEND_REACT.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/docs/GUIA_IMPLEMENTACION_FRONTEND_REACT.md) y [catálogo real de shared](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/docs/COMPONENTES_FOUNDATION.md).
>
> **Autoridad:** SPEC/HU/FLOW + contratos para negocio y datos; UX + `DESIGN.md` para apariencia; HTML como composición de referencia; arquitectura React de `master` para implementación. Registrar SHA de Docs y de Frontend usado en la PR. Ante discrepancias, **no inventar** ni cambiar Docs desde esta tarea.
>
> ## 3. Inventario exhaustivo de pantallas y criterios individuales
>
> ### MK-013-S01 — Precio vigente (piloto existente) (P0)
>
> - [ ] **Composición y datos:** Auditar y conservar la página /precios y sus escenarios tipados.
> - [ ] **Interacción y navegación:** Integrar enlaces a S02, S03, S06 y S04 sin romper consulta y parámetros aplicados.
> - [ ] **Estados y resultado verificable:** Regresión de back/forward, herencia/override, fallback y loading/empty/error.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-013-S02 — Editar precio (P0)
>
> - [ ] **Composición y datos:** Mostrar objetivo producto/SKU, versión vigente y campos autorizados.
> - [ ] **Interacción y navegación:** Confirmación mock con resultado claro; ante conflicto conservar edición y explicar revisión.
> - [ ] **Estados y resultado verificable:** Validaciones, guardando, rechazo, cancelación sin mutación.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-013-S03 — Programaciones y vigencia futura (P0)
>
> - [ ] **Composición y datos:** Listar vigencias y formulario de programación con zona horaria.
> - [ ] **Interacción y navegación:** Crear una programación mock y distinguirla de precio actual.
> - [ ] **Estados y resultado verificable:** Fecha inválida, conflicto, programada pendiente y error.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-013-S04 — Carga masiva de precios (P0)
>
> - [ ] **Composición y datos:** Selección y prevalidación en dos etapas; solo controles respaldados.
> - [ ] **Interacción y navegación:** Archivo reemplazado invalida prevalidación; Q-013-01/02 bloquea acciones contractuales indefinidas.
> - [ ] **Estados y resultado verificable:** Archivo no analizable, error fila, política parcial no confirmada.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-013-S05 — Seguimiento y resultado de carga (P0)
>
> - [ ] **Composición y datos:** Lote identificado con estado verificable y reporte cuando exista.
> - [ ] **Interacción y navegación:** Permitir consultar y recuperar/corregir archivo por S04 sin duplicar lote.
> - [ ] **Estados y resultado verificable:** En cola, en proceso, parcial, total, fallido, filas no disponibles.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-013-S06 — Histórico de vigencias (P0)
>
> - [ ] **Composición y datos:** Consultar precio por SKU/canal e instante, separado de precio vigente.
> - [ ] **Interacción y navegación:** Volver a S01 con contexto aplicado e instante preservado donde proceda.
> - [ ] **Estados y resultado verificable:** Sin dato en instante, error, canal con fallback según contrato.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
>
> **Advertencia sobre rutas:** `/MK013/Sxx` corresponde al prototipo académico. **No usarlo automáticamente como URL del producto.** Registrar una ruta de negocio descriptiva y consistente en el router existente; los estados y diálogos pueden no exigir rutas adicionales. La trazabilidad `MK-013-Sxx` debe mantenerse en pruebas/evidencia.
>
> ## 4. Interacciones y escenarios mínimos de prueba
>
> - [ ] S01 precio base vs override SKU y fallback global, loading/empty/error
> - [ ] S02 edición/versionado y rechazo por conflicto
> - [ ] S03 vigencia futura creada vs efectiva
> - [ ] S04 archivo prevalidado, modificado tras prevalidar y policy bloqueada
> - [ ] S05 lote recibido/procesando/terminal con detalle ausente
> - [ ] S06 precio histórico por instante y canal con retorno contextual
>
> Para cada escenario documentar: **entrada → acción → estado visible/resultado → navegación → fuente normativa**. Debe existir al menos un camino de éxito mock y uno de error, salvo una pantalla puramente de lectura que documente su propio estado de error. La simulación local no debe afirmar transacción real.
>
> ## 5. Reglas funcionales / riesgos específicos del dominio
>
> - S01 ya está construido en master con mocks; no reconstruirlo ni mover /precios sin acuerdo.
> - Las demos de S02-S05 en /foundation/pricing no son flujos comerciales completos.
> - Q-013-01: contrato del contenido del archivo no especificado; no fijar columnas, formato ni máximo por deducción.
> - Q-013-02: semántica de admitir errores parciales incierta; no habilitar confirmación con errores sin acuerdo.
> - Programación futura no significa precio vigente; historial as-of es consulta independiente.
> - No calcular precio definitivo, descuento o vigencia en navegador.
>
> **Integración o coordinación entre dominios:** Foundation ya integra /precios como piloto MK-013-S01; reutilizar sin duplicar componentes. Contratos Q-013-01 y Q-013-02 siguen condicionando importación.
>
> Si se detecta un contrato ausente, fuente no aprobada o P0 abierto: registrar `BLOCKED_CONTRACT`/`BLOCKED_DOCS`, fuente exacta, efecto en pantalla y **parte segura que sí puede implementarse**. No bloquear todo el MK por un adaptador HTTP pendiente ni marcar como terminada una acción inexistente. Las operaciones monetarias, saldo, permisos, reintentos e identidad se rigen por provider, nunca por suposiciones de JSX.
>
> ## 6. Implementación sobre la foundation aprobada
>
> **Preflight obligatorio**
> - [ ] `git fetch origin --prune`, inspeccionar `git status --short`, ramas y commit de `origin/master`; crear rama de feature nueva a partir de `origin/master`, sin destruir cambios ajenos.
> - [ ] Ejecutar `npm ci`, `npm run typecheck`, `npm run build`, `npm run lint` de `master` para establecer baseline; registrar si ya había errores antes del cambio.
> - [ ] Leer `src/app/layout/ApplicationShell.tsx`, `src/app/routes/productPages.tsx`, `productRoutes.tsx`, `src/app/navigation/navigation.ts`, `src/theme/`, `src/components/shared/index.ts` y ejemplos de `src/features/pricing/` / `src/features/foundation/`.
> - [ ] Listar qué componentes shared reutilizarás: `PageHeader`, `SectionCard`, `FilterBar`, `SearchField`, `StatusBadge`, `FeedbackAlert`, `EmptyState`, `EntityTable`, `ConfirmDialog`, `MetricCard` y `FileSelection` **según necesidad real**. No crear copias con otro nombre.
>
> **Ejecución**
> - [ ] Crear solo archivos utilizados dentro de `src/features/pricing/`: `pages/`, `components/`, `hooks/`, `services/`, `adapters/`, `mocks/` si la arquitectura lo requiere.
> - [ ] Separar **página → componentes de presentación → hook/controlador → interfaz de servicio/puerto → adapter mock → fixtures deterministas**. No acceder a HTTP desde JSX; no incrustar listas grandes de prueba en páginas.
> - [ ] Reutilizar Mantine/Tabler, tipografías Inter/Oswald y tokens de `src/theme` trazables a `DESIGN.md`; evitar colores HEX locales, `primary` alternativo, fondos sombreados innecesarios o badges multicolor por categorías.
> - [ ] Mantener modelos tipados independientes de DTO externos; no usar `any` como escape general. Estado y errores explícitos. Formularios controlados; validaciones por campo; deshabilitar doble envío.
> - [ ] Registrar vistas de producto en `src/app/routes/productPages.tsx` y `productRoutes.tsx`, navegación en `src/app/navigation/navigation.ts`. Mantener `/foundation/*` como galería separada; no destruir `/precios`.
> - [ ] Diseñar parámetros de URL/estado para persistir contexto relevante y permitir atrás/adelante cuando corresponda; no afirmar que esos parámetros son contratos API.
> - [ ] Proporcionar estados `loading`, `empty`, `error`, `success`, `disabled`, `submitting` donde apliquen; nunca convertir error de lectura en lista vacía o precio/stock cero.
> - [ ] Mantener `focus`, labels, ayudas, feedback y cancelación accesibles con teclado; verificar no superponer modales y retornar foco correctamente.
> - [ ] No modificar `src/theme/`, `src/components/shared/`, AppShell o contratos de otras features salvo necesidad transversal demostrada; coordinar primero con Vera y justificar la modificación en la PR.
>
> **Restricción de alcance:** no implementar backend, BD, autenticación real, nuevos permisos/scopes, cálculos comerciales autoritativos ni endpoints inventados; no copiar prototipos HTML de Docs al código productivo. La UI puede mostrar resultados de mocks identificados como ficticios. No imponer variantes mobile/tablet fuera del alcance normativo desktop actual.
>
> ## 7. Quality Gates: técnicos, funcionales y visuales
>
> - [ ] `npm ci`: PASS/FAIL/NO EJECUTADO, con versión de Node/npm.
> - [ ] `npm run typecheck`: PASS/FAIL/NO EJECUTADO.
> - [ ] `npm run build`: PASS/FAIL/NO EJECUTADO.
> - [ ] `npm run lint`: PASS/FAIL/NO EJECUTADO.
> - [ ] Tests existentes/pertinentes (`npm test`, Playwright u otros configurados): PASS/FAIL/NO EJECUTADO; no modificar tests ajenos para ocultar fallas.
> - [ ] Revisión desktop **1440 × 900** (ancho canónico 1440): capturas reales de cada pantalla principal y variantes clave; sin overflow involuntario, cortes, solapamientos, degradación de títulos/controles o scroll oculto.
> - [ ] Tablas largas, identificadores extensos, mensajes de error, carga y estado vacío inspeccionados; navegación por teclado, foco visible y retorno comprobados.
> - [ ] Comparación visual contra `DESIGN.md` vigente; documentar diferencias corregidas respecto del HTML y las decisiones pendientes del owner UX.
> - [ ] Verificación manual del flujo principal y al menos los escenarios de error indicados en §4; no declarar `VALIDATED` o `API_INTEGRATED` por tener capturas mock.
>
> ## 8. Evidencia y PR obligatoria
>
> La PR debe apuntar a **`master`**, tener título `feat(frontend): MK-013 — Gestión de precios individuales y masivos` y vincular este issue con `Closes #N` **solo cuando el alcance completo esté resuelto** (si existen etapas pendientes, usar `Refs #N`). Los cambios de rutas compartidas entre varios owners deben resolverse sin eliminar rutas ajenas. Solicitar revisión antes de mergear.
>
> **Matriz de trazabilidad a completar en la PR** (no significa que ya esté validado):
>
> | Pantalla | Qué se debe mostrar | Prioridad | Ruta/componente React real | Evidencia y resultado |
> |---|---|---|---|---|
> | MK-013-S01 | Precio vigente (piloto existente) | P0 | Pendiente | Pendiente |
> | MK-013-S02 | Editar precio | P0 | Pendiente | Pendiente |
> | MK-013-S03 | Programaciones y vigencia futura | P0 | Pendiente | Pendiente |
> | MK-013-S04 | Carga masiva de precios | P0 | Pendiente | Pendiente |
> | MK-013-S05 | Seguimiento y resultado de carga | P0 | Pendiente | Pendiente |
> | MK-013-S06 | Histórico de vigencias | P0 | Pendiente | Pendiente |
>
> **Reporte técnico y funcional requerido:**
> ```text
> Issue: MK-013
> Responsable / rama / SHA: ...
> Docs master SHA y versión DESIGN: ...
> Pantallas y estados implementados: ...
> Rutas productivas registradas: ...
> Shared reutilizados / shared propuestos: ...
> Modelo(s) de presentación y mocks: ...
> Flujos y escenarios probados: ...
> API real: NO (salvo integración demostrada separadamente)
> Tests y comandos (PASS/FAIL/NO EJECUTADO): ...
> Revisión visual 1440 px y capturas: ...
> Diferencias de HTML vs DESIGN: ...
> Bloqueos contractuales/documentales: ...
> Archivos creados/modificados: ...
> Deuda pendiente fuera de alcance: ...
> ```
>
> **Revisión UX cruzada:** como Vera es owner de este MK, solicitar una segunda persona para revisión técnica/funcional independiente (por ejemplo Axel/Marco según disponibilidad); no considerar la auto-revisión una aprobación independiente.
>
> ## 9. Definition of Done
>
> - [ ] Cobertura completa de las pantallas P0 enumeradas arriba (P1 separado cuando esté indicado), con contexto, validaciones, estados y navegación verificables.
> - [ ] Mocks/adapters tipados sustituibles por HTTP sin reescribir JSX; código de negocio no trasladado a la UI.
> - [ ] Estilo unificado con la Foundation; sin duplicar theme, AppShell o patrones compartidos existentes.
> - [ ] Evidencias y checks reales incorporados a PR; ninguna declaración engañosa de PASS, despliegue o integración.
> - [ ] Revisión funcional y UX/técnica correspondiente, con hallazgos importantes cerrados o documentados como limitación acordada.
> - [ ] Se entrega una demo navegable por navegador local sin backend y se informa exactamente qué está simulado.
>
> **No cerrar este issue por publicar un prototipo parcial:** las pantallas sin implementar, validaciones pendientes y bloqueos permanecen explícitos hasta su resolución o replanteamiento aprobado.

</details>

## Issue 16

- **Título:** [FRONTEND][MK-014] Implementar Historial de auditoría de precios en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/16).
- **Estado consultado:** closed; **asignados:** @LeonardoVera.
- **Creado:** 2026-10-10T16:03:41Z; **actualizado:** 2026-10-17T06:32:03Z; **cerrado:** 2026-10-17T06:32:03Z.
- **Encargo derivado:** [frontend/vera #16](../frontend/vera/issue-016-mk-014.md).

<details>
<summary>Contenido completo consultado del issue 16</summary>

> # [FRONTEND][MK-014] Implementar Historial de auditoría de precios en React
>
> **Responsable funcional y de implementación:** Leonardo Vera Rodríguez (`@LeonardoVera`)
> **Rama convencional del owner (referencia):** `vera`. Crear una rama corta de implementación **desde `origin/master` actualizado**, por ejemplo `feat/mk-014-price-audit`; no asumir que la rama convencional esté sincronizada.
> **Dominio React:** `src/features/price-audit/`
> **Hito:** Hito 3 — primer demo funcional. **Entrega principal:** `UI_COMPLETE` + `MOCK_INTEGRATED`; no declarar `API_INTEGRATED` sin conexión real verificada.
> **Inventario registrado:** 5 vistas/variantes documentadas (las variantes `Sxx-X` pueden ser estados, drawers o pantallas según el Flow).
> **Issue de foundation:** [#1](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/1); base aprobada en [PR #2](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/2), fusionada a `master` (`731ae1d3cdad100d943d35111a4da6229a31fb96`).
>
> ## 1. Objetivo y resultado esperado
>
> Convertir el alcance funcional de **MK-014 — Historial de auditoría de precios** en vistas y flujos de React realmente navegables sobre la foundation común de Vera, sin copiar los HTML como componentes monolíticos ni adelantar un backend inexistente. La entrega debe poder demostrarse localmente con estados deterministas, decisiones visuales fieles a Docs y una PR acotada que permita auditar pantalla por pantalla.
>
> **Secuencia sugerida:** Listado y detalle primero; estados de no encontrado, exportaciones después.
>
> ## 2. Fuentes normativas — consultar ANTES de modificar el código
>
> 1. [MK-014: `component-spec.md`, `plan.md`, `tasks.md`, `validation-report.md` y `prototipo/`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/tree/master/ux/mockups/MK-014). Revisar qué archivos/HTML existen realmente, su estado de aprobación y divergencias; la presencia de HTML **no** acredita `APROBADO`.
> 2. [Design System `ux/mockups/DESIGN.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/DESIGN.md) y [UX Guidelines](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/ux/ux-guidelines.md), [UX Decisions](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/ux/mockups/ux/ux-decisions.md).
> 3. Documentos de negocio **SPEC-014**, **HU-014**, **FLOW-014**, **WF-014**, localizados por identificador en [`requisitos/specs/`, `requisitos/hu/`, `requisitos/flujos/`, `ux/wireframes/flows/`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs). No adivinar sufijos de archivo ni versiones.
> 4. [OpenAPI HTTP](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/master/contratos/http/openapi.yaml) y contratos/eventos pertinentes **solo** para delimitar comportamiento/datos; si el contrato pertenece a otro módulo, consultar su fuente oficial.
> 5. En Frontend: [`AGENTS.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/AGENTS.md), [`README.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/README.md), [`docs/GUIA_IMPLEMENTACION_FRONTEND_REACT.md`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/docs/GUIA_IMPLEMENTACION_FRONTEND_REACT.md) y [catálogo real de shared](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/master/docs/COMPONENTES_FOUNDATION.md).
>
> **Autoridad:** SPEC/HU/FLOW + contratos para negocio y datos; UX + `DESIGN.md` para apariencia; HTML como composición de referencia; arquitectura React de `master` para implementación. Registrar SHA de Docs y de Frontend usado en la PR. Ante discrepancias, **no inventar** ni cambiar Docs desde esta tarea.
>
> ## 3. Inventario exhaustivo de pantallas y criterios individuales
>
> ### MK-014-S01 — Historial y filtros (P0)
>
> - [ ] **Composición y datos:** Listado paginado de asientos inmutables con filtros oficiales.
> - [ ] **Interacción y navegación:** Aplicar filtros explícitos; abrir S02/S03 y exportaciones S04/S05 conservando contexto.
> - [ ] **Estados y resultado verificable:** Loading, vacío, error, paginación coherente.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-014-S02 — Detalle de asiento (P0)
>
> - [ ] **Composición y datos:** Modal 640 px con información completa autorizada del auditId.
> - [ ] **Interacción y navegación:** Cerrar o volver al historial sin perder filtros/página.
> - [ ] **Estados y resultado verificable:** Campo desconocido = No informado; foco contenido; sin moneda atribuida.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-014-S03 — Detalle no encontrado (P0)
>
> - [ ] **Composición y datos:** Estado 404 específico y explicación clara, sin fabricar registro.
> - [ ] **Interacción y navegación:** Volver al historial con mismos filtros.
> - [ ] **Estados y resultado verificable:** Modal accesible, recuperable y sin cambio en listado.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-014-S04 — Exportar CSV (P0)
>
> - [ ] **Composición y datos:** Solicitud y seguimiento de exportación con filtros aplicados.
> - [ ] **Interacción y navegación:** Descargar solo ante URL/contenido fixture disponible y etiquetado como mock.
> - [ ] **Estados y resultado verificable:** Pendiente, listo, error, sin permisos.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
> ### MK-014-S05 — Exportar PDF (P0)
>
> - [ ] **Composición y datos:** Mismo flujo de exportación con formato PDF.
> - [ ] **Interacción y navegación:** Conservar criterios aplicados; permitir retorno y descarga simulada únicamente si fuente mock preparada.
> - [ ] **Estados y resultado verificable:** Solicitada, procesando, completa, fallida.
> - [ ] **Evidencia:** captura desktop 1440 px y caso de prueba (manual o automatizado) que abra esta vista/variante y ejerza su acción principal.
>
> **Advertencia sobre rutas:** `/MK014/Sxx` corresponde al prototipo académico. **No usarlo automáticamente como URL del producto.** Registrar una ruta de negocio descriptiva y consistente en el router existente; los estados y diálogos pueden no exigir rutas adicionales. La trazabilidad `MK-014-Sxx` debe mantenerse en pruebas/evidencia.
>
> ## 4. Interacciones y escenarios mínimos de prueba
>
> - [ ] Listado paginado con filtros aplicados, sin registros y error
> - [ ] Detalle completo con datos autorizados y con campos nulos
> - [ ] Detalle no encontrado desde tabla y acceso directo
> - [ ] Export CSV/PDF en solicitud, generando, disponible y fallido
> - [ ] Filtros conservados al cerrar modal y volver
>
> Para cada escenario documentar: **entrada → acción → estado visible/resultado → navegación → fuente normativa**. Debe existir al menos un camino de éxito mock y uno de error, salvo una pantalla puramente de lectura que documente su propio estado de error. La simulación local no debe afirmar transacción real.
>
> ## 5. Reglas funcionales / riesgos específicos del dominio
>
> - Asientos de auditoría son inmutables: no agregar editar/eliminar/revertir.
> - Q-014-01: contrato RegistroAuditoriaPrecio no publica moneda; no atribuir divisa a importes históricos.
> - Email/IP del actor solo cuando se conozcan y estén autorizados; sin fabricar identidad.
> - Un 404 de asiento conserva filtros y no simula nuevo asiento.
> - Exportaciones son jobs/descargas declarados, no creación ficticia de PDF/CSV de backend.
>
> **Integración o coordinación entre dominios:** Read-only sobre price-audit-svc; contexto de SKU/canal debe ser compatible con MK-013 sin mezclar histórico de precios con auditoría.
>
> Si se detecta un contrato ausente, fuente no aprobada o P0 abierto: registrar `BLOCKED_CONTRACT`/`BLOCKED_DOCS`, fuente exacta, efecto en pantalla y **parte segura que sí puede implementarse**. No bloquear todo el MK por un adaptador HTTP pendiente ni marcar como terminada una acción inexistente. Las operaciones monetarias, saldo, permisos, reintentos e identidad se rigen por provider, nunca por suposiciones de JSX.
>
> ## 6. Implementación sobre la foundation aprobada
>
> **Preflight obligatorio**
> - [ ] `git fetch origin --prune`, inspeccionar `git status --short`, ramas y commit de `origin/master`; crear rama de feature nueva a partir de `origin/master`, sin destruir cambios ajenos.
> - [ ] Ejecutar `npm ci`, `npm run typecheck`, `npm run build`, `npm run lint` de `master` para establecer baseline; registrar si ya había errores antes del cambio.
> - [ ] Leer `src/app/layout/ApplicationShell.tsx`, `src/app/routes/productPages.tsx`, `productRoutes.tsx`, `src/app/navigation/navigation.ts`, `src/theme/`, `src/components/shared/index.ts` y ejemplos de `src/features/pricing/` / `src/features/foundation/`.
> - [ ] Listar qué componentes shared reutilizarás: `PageHeader`, `SectionCard`, `FilterBar`, `SearchField`, `StatusBadge`, `FeedbackAlert`, `EmptyState`, `EntityTable`, `ConfirmDialog`, `MetricCard` y `FileSelection` **según necesidad real**. No crear copias con otro nombre.
>
> **Ejecución**
> - [ ] Crear solo archivos utilizados dentro de `src/features/price-audit/`: `pages/`, `components/`, `hooks/`, `services/`, `adapters/`, `mocks/` si la arquitectura lo requiere.
> - [ ] Separar **página → componentes de presentación → hook/controlador → interfaz de servicio/puerto → adapter mock → fixtures deterministas**. No acceder a HTTP desde JSX; no incrustar listas grandes de prueba en páginas.
> - [ ] Reutilizar Mantine/Tabler, tipografías Inter/Oswald y tokens de `src/theme` trazables a `DESIGN.md`; evitar colores HEX locales, `primary` alternativo, fondos sombreados innecesarios o badges multicolor por categorías.
> - [ ] Mantener modelos tipados independientes de DTO externos; no usar `any` como escape general. Estado y errores explícitos. Formularios controlados; validaciones por campo; deshabilitar doble envío.
> - [ ] Registrar vistas de producto en `src/app/routes/productPages.tsx` y `productRoutes.tsx`, navegación en `src/app/navigation/navigation.ts`. Mantener `/foundation/*` como galería separada; no destruir `/precios`.
> - [ ] Diseñar parámetros de URL/estado para persistir contexto relevante y permitir atrás/adelante cuando corresponda; no afirmar que esos parámetros son contratos API.
> - [ ] Proporcionar estados `loading`, `empty`, `error`, `success`, `disabled`, `submitting` donde apliquen; nunca convertir error de lectura en lista vacía o precio/stock cero.
> - [ ] Mantener `focus`, labels, ayudas, feedback y cancelación accesibles con teclado; verificar no superponer modales y retornar foco correctamente.
> - [ ] No modificar `src/theme/`, `src/components/shared/`, AppShell o contratos de otras features salvo necesidad transversal demostrada; coordinar primero con Vera y justificar la modificación en la PR.
>
> **Restricción de alcance:** no implementar backend, BD, autenticación real, nuevos permisos/scopes, cálculos comerciales autoritativos ni endpoints inventados; no copiar prototipos HTML de Docs al código productivo. La UI puede mostrar resultados de mocks identificados como ficticios. No imponer variantes mobile/tablet fuera del alcance normativo desktop actual.
>
> ## 7. Quality Gates: técnicos, funcionales y visuales
>
> - [ ] `npm ci`: PASS/FAIL/NO EJECUTADO, con versión de Node/npm.
> - [ ] `npm run typecheck`: PASS/FAIL/NO EJECUTADO.
> - [ ] `npm run build`: PASS/FAIL/NO EJECUTADO.
> - [ ] `npm run lint`: PASS/FAIL/NO EJECUTADO.
> - [ ] Tests existentes/pertinentes (`npm test`, Playwright u otros configurados): PASS/FAIL/NO EJECUTADO; no modificar tests ajenos para ocultar fallas.
> - [ ] Revisión desktop **1440 × 900** (ancho canónico 1440): capturas reales de cada pantalla principal y variantes clave; sin overflow involuntario, cortes, solapamientos, degradación de títulos/controles o scroll oculto.
> - [ ] Tablas largas, identificadores extensos, mensajes de error, carga y estado vacío inspeccionados; navegación por teclado, foco visible y retorno comprobados.
> - [ ] Comparación visual contra `DESIGN.md` vigente; documentar diferencias corregidas respecto del HTML y las decisiones pendientes del owner UX.
> - [ ] Verificación manual del flujo principal y al menos los escenarios de error indicados en §4; no declarar `VALIDATED` o `API_INTEGRATED` por tener capturas mock.
>
> ## 8. Evidencia y PR obligatoria
>
> La PR debe apuntar a **`master`**, tener título `feat(frontend): MK-014 — Historial de auditoría de precios` y vincular este issue con `Closes #N` **solo cuando el alcance completo esté resuelto** (si existen etapas pendientes, usar `Refs #N`). Los cambios de rutas compartidas entre varios owners deben resolverse sin eliminar rutas ajenas. Solicitar revisión antes de mergear.
>
> **Matriz de trazabilidad a completar en la PR** (no significa que ya esté validado):
>
> | Pantalla | Qué se debe mostrar | Prioridad | Ruta/componente React real | Evidencia y resultado |
> |---|---|---|---|---|
> | MK-014-S01 | Historial y filtros | P0 | Pendiente | Pendiente |
> | MK-014-S02 | Detalle de asiento | P0 | Pendiente | Pendiente |
> | MK-014-S03 | Detalle no encontrado | P0 | Pendiente | Pendiente |
> | MK-014-S04 | Exportar CSV | P0 | Pendiente | Pendiente |
> | MK-014-S05 | Exportar PDF | P0 | Pendiente | Pendiente |
>
> **Reporte técnico y funcional requerido:**
> ```text
> Issue: MK-014
> Responsable / rama / SHA: ...
> Docs master SHA y versión DESIGN: ...
> Pantallas y estados implementados: ...
> Rutas productivas registradas: ...
> Shared reutilizados / shared propuestos: ...
> Modelo(s) de presentación y mocks: ...
> Flujos y escenarios probados: ...
> API real: NO (salvo integración demostrada separadamente)
> Tests y comandos (PASS/FAIL/NO EJECUTADO): ...
> Revisión visual 1440 px y capturas: ...
> Diferencias de HTML vs DESIGN: ...
> Bloqueos contractuales/documentales: ...
> Archivos creados/modificados: ...
> Deuda pendiente fuera de alcance: ...
> ```
>
> **Revisión UX cruzada:** como Vera es owner de este MK, solicitar una segunda persona para revisión técnica/funcional independiente (por ejemplo Axel/Marco según disponibilidad); no considerar la auto-revisión una aprobación independiente.
>
> ## 9. Definition of Done
>
> - [ ] Cobertura completa de las pantallas P0 enumeradas arriba (P1 separado cuando esté indicado), con contexto, validaciones, estados y navegación verificables.
> - [ ] Mocks/adapters tipados sustituibles por HTTP sin reescribir JSX; código de negocio no trasladado a la UI.
> - [ ] Estilo unificado con la Foundation; sin duplicar theme, AppShell o patrones compartidos existentes.
> - [ ] Evidencias y checks reales incorporados a PR; ninguna declaración engañosa de PASS, despliegue o integración.
> - [ ] Revisión funcional y UX/técnica correspondiente, con hallazgos importantes cerrados o documentados como limitación acordada.
> - [ ] Se entrega una demo navegable por navegador local sin backend y se informa exactamente qué está simulado.
>
> **No cerrar este issue por publicar un prototipo parcial:** las pantallas sin implementar, validaciones pendientes y bloqueos permanecen explícitos hasta su resolución o replanteamiento aprobado.

</details>

## Issue 17

- **Título:** [FRONTEND][MK-015] Implementar Control de stock, umbrales y traslados en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/17).
- **Estado consultado:** open; **asignados:** @MiguelTacoZavala.
- **Creado:** 2026-10-10T16:03:44Z; **actualizado:** 2026-10-17T08:09:56Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/taco #17](../frontend/taco/issue-017-mk-015.md).

<details>
<summary>Contenido completo consultado del issue 17</summary>

> ## Clasificación y owner
> DEMO_P0 · API_REAL. Owner único: MiguelTacoZavala. Área: src/features/inventory.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-015 stock/umbrales/traslados según Inventory OpenAPI. Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Errores API visibles; no ApiPendingRepository como éxito ni fallback mock. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - [Backend #97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/97)
> - [Backend #98](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/98)
> - [Backend #99](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/99)
> - [Backend #100](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/100)
> - [Backend #101](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/101)
> - [Backend #106](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/106)
> - [Backend #107](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/107)
> - [Backend #109](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/109)
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>

## Issue 18

- **Título:** [FRONTEND][MK-016] Implementar Dashboard analítico y alertas de inventario en React
- **URL:** [Issue original](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/18).
- **Estado consultado:** open; **asignados:** @MiguelTacoZavala.
- **Creado:** 2026-10-10T16:03:46Z; **actualizado:** 2026-10-17T08:09:58Z; **cerrado:** sin fecha de cierre.
- **Encargo derivado:** [frontend/taco #18](../frontend/taco/issue-018-mk-016.md).

<details>
<summary>Contenido completo consultado del issue 18</summary>

> ## Clasificación y owner
> DEMO_P0 · API_REAL. Owner único: MiguelTacoZavala. Área: src/features/inventory.
>
> ## Alcance vigente
> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-016 dashboard/alertas con respuestas autorizadas, sin revelar saldos privados. Mantener configuración/providers compartidos fuera de esta feature.
>
> ## Aceptación
> Errores API visibles; no ApiPendingRepository como éxito ni fallback mock. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.
>
> ## Prerrequisitos obligatorios para programar
> - Ninguno para esta fase.
>
> ## Dependencias para pruebas de integración
> - [Backend #97](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/97)
> - [Backend #98](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/98)
> - [Backend #99](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/99)
> - [Backend #100](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/100)
> - [Backend #106](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/106)
> - [Backend #107](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/107)
> - [Backend #109](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/109)
>
> ## Condiciones para desplegar
> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

</details>
