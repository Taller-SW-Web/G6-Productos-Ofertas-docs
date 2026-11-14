# Tasks — MK-011

## 1. Identificación

- **Mockup:** MK-011 — Gestión de marcas
- **Responsable:** Leonardo Lopez (rama `lopez`)
- **Plan de referencia:** [plan.md](plan.md) v1.1
- **Estado general:** **En revisión** — documentación redactada; preparación e implementación bloqueadas hasta la aprobación del `component-spec.md` y el cierre de Q-01 (obligatoriedad del logo).

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

- [ ] **MK-011-T01 — P0:** Confirmar vigentes [propuesta-ux.md](../ux/propuesta-ux.md), [ux-guidelines.md](../ux/ux-guidelines.md) y [ux-decisions.md](../ux/ux-decisions.md). `[TODO]`
- [ ] **MK-011-T02 — P0:** Obtener la aprobación de [component-spec.md](component-spec.md) y resolver las preguntas abiertas Q-01, Q-02 y Q-03. `[BLOCKED: component-spec en estado En revisión]`
- [ ] **MK-011-T03 — P0 — Resolver la discrepancia de obligatoriedad del logo** `[BLOCKED]`
  - **Entrada:** SPEC-011, HU-011 CA-01 y WF-011 §3 frente a `MarcaCreateMultipart` en `api/openapi.yaml` 0.5.0.
  - **Acción:** obtener la determination documentada de la fuente authoritative sobre si el logo es obligatorio en el alta.
  - **Salida esperada:** corrección documental en la fuente que prevailsa o confirmación explícita de que el contrato debe ajustarse.
  - **Verificación:** no existe contradicción abierta entre SPEC, HU, WF y OpenAPI respecto al logo.
- [ ] **MK-011-T04 — P0 — Preparar fixtures deterministas** `[TODO]`
  - **Entrada:** `component-spec.md` §13.
  - **Acción:** crear datasets en `prototipo/src/pantallas/MK011` para listado, loading, empty, sin resultados, error, sesión, sin permisos, alta mínima y completa, formato inválido, tamaño excedido, nombre duplicado activo e inactivo, país no precargado e inválido, edición, conflicto de versión, verificación pendiente, confirmada, bloqueada, rechazada y no concluyente, y reactivación.
  - **Salida esperada:** fixtures importables por los componentes de pantalla.
  - **Verificación:** cada fixture se carga por parámetro de consulta y produce un estado distinguishable y determinista.
- [ ] **MK-011-T05 — P0:** Confirmar [DESIGN.md](../DESIGN.md) 1.0.0 y el catálogo de componentes DS-C01, DS-C02, DS-C03, DS-C05, DS-C12, DS-C14, DS-C17, DS-C19, DS-C21, DS-C22, DS-C24, DS-C25 y DS-C28. `[TODO]`
- [ ] **MK-011-T06 — P0:** Identificar MK-011-S02 como pantalla ancla y alinear jerarquía, densidad y microtexto con el resto del módulo. `[TODO]`

## 4. Implementación por pantalla

### MK-011-S02 — Crear marca

- [ ] **MK-011-T13 — P0 — Implementar estructura de S02** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S02) y WF-011 §3.
  - **Acción:** construir el formulario en Card con nombre requerido, descripción, selector de logo y selector de país.
  - **Salida esperada:** ruta `/MK011/S02` renderizable y navegable directamente.
  - **Verificación:** las cuatro zonas obligatorias están presentes y no hay campos inventados.
- [ ] **MK-011-T14 — P0 — Construir MK-011-C02 y validar logo, país y unicidad** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §13; HU-011 CA-01, CA-02, CA-08 y CA-09.
  - **Acción:** implementar la previsualización del logo con formatos PNG, JPG, JPEG y WebP y límite de 5 MB, el selector de país ISO 3166-1 sin valor por defecto y la unicidad normalizada frente a marcas activas e inactivas.
  - **Salida esperada:** formulario conforme con la obligatoriedad resuelta en T03.
  - **Verificación:** los fixtures `crear-minimo`, `crear-con-logo`, `logo-formato-invalido`, `logo-excede-limite`, `nombre-duplicado` y `pais-no-precargado` reproducen cada caso.

### MK-011-S01 — Listado de marcas

- [ ] **MK-011-T10 — P0 — Implementar S01 con MK-011-C01** `[TODO]`
  - **Entrada:** `component-spec.md` §8, §9 y §10 (S01).
  - **Acción:** construir la tabla con logo, nombre, país y estado, el filtro y las acciones por fila.
  - **Salida esperada:** ruta `/MK011/S01` operativa con default, loading, empty, sin resultados y error.
  - **Verificación:** una marca sin logo muestra un marcador neutro y no un icono de error.
- [ ] **MK-011-T11 — P0 — Implementar navegación de S01** `[TODO]`
  - **Entrada:** `component-spec.md` §6 y FLOW-011.
  - **Acción:** conectar Crear marca, Ver detalle, Editar y Desactivar hacia sus destinos.
  - **Salida esperada:** navegación operativa sin rutas rotas.
  - **Verificación:** el flujo es navegable de extremo a extremo sin errores en consola.
- [ ] **MK-011-T12 — P0 — Comunicar la exposición a canales** `[TODO]`
  - **Entrada:** HU-011 CA-07.
  - **Acción:** incluir en el listado y el detalle la nota de que las marcas activas son las que ven Catálogo y los demás canales.
  - **Salida esperada:** información de exposición visible y coherente con el contrato.
  - **Verificación:** el texto no afirma sincronía ni menciona nombres de mensajes.

### MK-011-S03 — Editar marca

- [ ] **MK-011-T15 — P0 — Implementar S03 con envío multipart** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S03), HU-011 CA-03, CA-08, CA-09 y CA-10.
  - **Acción:** implementar la edición de nombre, descripción, logo y país mediante `PATCH` multipart con el DTO de actualización de marca.
  - **Salida esperada:** ruta `/MK011/S03` operativa; el logo actual se muestra como referencia.
  - **Verificación:** el método de envío es `PATCH` con formulario multipart y el fixture `nombre-duplicado-inactiva` rechaza el renombre frente a una marca inactiva.
- [ ] **MK-011-T16 — P0 — Preservar el identificador en la edición** `[TODO]`
  - **Entrada:** HU-011 CA-12.
  - **Acción:** mostrar el aviso de que el identificador no cambia y no exponerlo como campo editable.
  - **Salida esperada:** edición sin posibilidad de alterar la identidad.
  - **Verificación:** el fixture `editar-marca` confirma que el identificador permanece.

### MK-011-S05 — Detalle de marca

- [ ] **MK-011-T19 — P0 — Implementar S05 con reactivación** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S05), HU-011 CA-05 y CA-12.
  - **Acción:** construir la ficha con logo, nombre, descripción, país y estado, y habilitar Reactivar cuando la marca esté inactiva.
  - **Salida esperada:** ruta `/MK011/S05` operativa con default, loading, error y no encontrada.
  - **Verificación:** el fixture `reactivacion-ok` conserva identificador y nombre.

### MK-011-S04, S04-P, S04-B y S04-E — Baja lógica segura

- [ ] **MK-011-T17 — P0 — Modelar la baja como admisión y construir MK-011-C03** `[TODO]`
  - **Entrada:** SPEC-011 R5, HU-011 CA-11 y CA-16, WF-011 §4, `component-spec.md` §10 (S04, S04-P).
  - **Acción:** implementar la confirmación de baja y el seguimiento por `operationId` del protocolo transversal, manteniendo la marca activa mientras se verifica.
  - **Salida esperada:** rutas `/MK011/S04` y `/MK011/S04-P` operativas; solo `CLEAR` bajo barrera confirma la baja.
  - **Verificación:** el copy de S04 y S04-P no afirma baja completada antes del resultado y la marca no cambia de estado al iniciar la comprobación.
- [ ] **MK-011-T18 — P0 — Implementar los resultados bloqueado y no concluyente** `[TODO]`
  - **Entrada:** HU-011 CA-04 y CA-13, `component-spec.md` §10 (S04-B, S04-E).
  - **Acción:** implementar el aviso de productos activos y el aviso de que no se realizó ningún cambio cuando no hay resultado fiable.
  - **Salida esperada:** rutas `/MK011/S04-B` y `/MK011/S04-E` operativas con motivos diferenciados.
  - **Verificación:** los fixtures `baja-bloqueada`, `baja-rechazada` y `baja-no-concluyente` reproducen cada caso y la marca permanece activa.

## 5. Normalización

- [ ] **MK-011-T50 — P0 — Normalizar arquitectura y componentes** `[TODO]`
  - **Entrada:** código en `prototipo/src/pantallas/MK011` y convenciones del Design System.
  - **Acción:** sustituir componentes ad hoc por componentes centralizados de Mantine y el Design System.
  - **Salida esperada:** código modular sin estilos inline huérfanos.
  - **Verificación:** build exitoso sin warnings ni dependencias no autorizadas.
- [ ] **MK-011-T51 — P0:** Normalizar colores con tokens oficiales del tema. `[TODO]`
- [ ] **MK-011-T52 — P0:** Normalizar espaciados, bordes y radios según la escala del módulo. `[TODO]`
- [ ] **MK-011-T53 — P0:** Aplicar la escala tipográfica centralizada. `[TODO]`
- [ ] **MK-011-T54 — P0:** Sustituir iconos ad hoc exclusivamente por Tabler Icons. `[TODO]`
- [ ] **MK-011-T55 — P0:** Eliminar términos técnicos, nombres de base de datos y cualquier nombre de mensaje visible al usuario. `[TODO]`
- [ ] **MK-011-T56 — P0:** Revisar semántica HTML y accesibilidad básica, incluido el texto alternativo del logo y el `aria-live` de resultados asíncronos. `[TODO]`

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-011-T60 — P0:** Validar cobertura estricta de SPEC-011 sin reglas inventadas, incluida la ausencia de eliminación física, de mensajería propia de marca y de declaración de rol o permiso granular. `[TODO]`
- [ ] **MK-011-T61 — P0:** Validar los 16 criterios de aceptación de HU-011 contra la matriz de `component-spec.md` §2.1. `[TODO]`
- [ ] **MK-011-T62 — P0:** Validar correspondencia con WF-011 v0.5, incluidas §3, §4 y §5. `[TODO]`
- [ ] **MK-011-T63 — P0:** Validar transiciones completas según FLOW-011. `[TODO]`
- [ ] **MK-011-T64 — P0:** Validar cumplimiento de UX Guidelines normativas del módulo. `[TODO]`
- [ ] **MK-011-T65 — P0:** Validar aplicación de UXD-007, UXD-010, UXD-011, UXD-017 y UXD-019. `[TODO]`
- [ ] **MK-011-T66 — P0:** Validar justificación de LUX-01, LUX-02 y LUX-03. `[TODO]`
- [ ] **MK-011-T67 — P0:** Validar fidelidad al Design System y reutilización de componentes compartidos. `[TODO]`
- [ ] **MK-011-T68 — P0:** Validar las ocho rutas inventariadas, incluidas `/MK011/S04-P`, `/MK011/S04-B` y `/MK011/S04-E`, y el comportamiento en 1440 px sin overflow horizontal. `[TODO]`
- [ ] **MK-011-T69 — P0 — Registrar evidencias de autovalidación** `[TODO]`
  - **Entrada:** inspección técnica y funcional de pantallas, estados y rutas.
  - **Acción:** documentar pantallas, trazabilidad de ejecución, UI, PC y accesibilidad, siguiendo la estructura de la plantilla de `validation-report.md`.
  - **Salida esperada:** evidencias que sustentan la matriz de §2.1.
  - **Verificación:** cero hallazgos bloqueantes ni importantes requeridos abiertos.

## 7. Revisión transversal y visto bueno

- [ ] **MK-011-T70 — P0:** Confirmar que la autovalidación local está completa y cerrada. `[TODO]`
- [ ] **MK-011-T71 — P0:** Solicitar formalmente revisión transversal a Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-011-T72 — P0:** Atender y corregir todos los hallazgos bloqueantes e importantes. `[TODO]`
- [ ] **MK-011-T73 — P0:** Obtener visto bueno formal de Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-011-T74 — P0 — Registrar estado APROBADO PARA FIGMA** `[TODO]`
  - **Entrada:** visto bueno otorgado por el revisor.
  - **Acción:** registrar el estado de revisión transversal.
  - **Salida esperada:** sección de revisión transversal en estado `APROBADO PARA FIGMA`.
  - **Verificación:** confirmación formal del revisor con fecha.

## 8. Figma y cierre

- [ ] **MK-011-T75 — P0:** Trasladar fielmente a Figma la versión aprobada para Figma. `[TODO]`
- [ ] **MK-011-T76 — P0:** Verificar fidelidad punto a punto entre Figma y el prototipo aprobado. `[TODO]`
- [ ] **MK-011-T77 — P0:** Confirmar que las ocho pantallas P0 están completas en Figma. `[TODO]`
- [ ] **MK-011-T78 — P0:** Registrar el enlace canónico de Figma. `[TODO]`
- [ ] **MK-011-T79 — P0 — Cierre de Quality Gates y resultado APROBADO** `[TODO]`
  - **Entrada:** Gates A, B, C, D, E y F cumplidos.
  - **Acción:** cerrar el reporte de validación y declarar el resultado general.
  - **Salida esperada:** **Resultado general = APROBADO**.
  - **Verificación:** todos los gates cerrados y cero bloqueos abiertos.

## 9. Registro de bloqueos

| Tarea | Fecha | Causa del bloqueo | Fuente / Documento a resolver | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|---|---|
| MK-011-T02 | 2026-10-03 | El `component-spec.md` v1.1 está en estado En revisión; Q-01, Q-02 y Q-03 siguen abiertas | Revisión documental del `component-spec.md` | Leonardo Lopez | Aprobación del component-spec y cierre de las tres preguntas | Activo |
| MK-011-T03 | 2026-10-03 | SPEC-011, HU-011 CA-01 y WF-011 §3 consideran el logo opcional; `MarcaCreateMultipart` en OpenAPI 0.5.0 lo declara obligatorio | SPEC-011 / WF-011 / Contrato API | Leonardo Lopez con Seguridad y Taxonomía | Corrección documental de la fuente que prevalece o ajuste del contrato | Activo |
| MK-011-T14 | 2026-10-03 | Depende de T03 para implementar la obligatoriedad del logo en el formulario | Contrato API y SPEC-011 | Leonardo Lopez con Seguridad y Taxonomía | Cierre de Q-01 | Activo |
| MK-011-T17 | 2026-10-03 | Depende de Q-03 para modelar la consulta del resultado de la verificación | AsyncAPI 0.4.0 y Contrato API | Leonardo Lopez con Taxonomía | Respuesta documentada a Q-03 | Activo |
