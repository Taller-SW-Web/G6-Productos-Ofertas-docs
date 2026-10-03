# Tasks — MK-012

## 1. Identificación

- **Mockup:** MK-012 — SEO y metadatos de categorías
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

- [ ] **MK-012-T01 — P0:** Confirmar vigentes [propuesta-ux.md](../ux/propuesta-ux.md), [ux-guidelines.md](../ux/ux-guidelines.md) y [ux-decisions.md](../ux/ux-decisions.md). `[TODO]`
- [ ] **MK-012-T02 — P0:** Obtener la aprobación de [component-spec.md](component-spec.md) y resolver las preguntas abiertas Q-01 y Q-02. `[BLOCKED: component-spec en estado En revisión]`
- [ ] **MK-012-T03 — P0 — Preparar fixtures deterministas** `[TODO]`
  - **Entrada:** `component-spec.md` §13.
  - **Acción:** crear datasets en `prototipo/src/pantallas/MK012` para default, loading, empty, sin resultados, error, sesión, slug normalizado, slug con colisión, advertencias de longitud, conflicto `409` e historial con cambios, inicial y vacío.
  - **Salida esperada:** fixtures importables por los componentes de pantalla.
  - **Verificación:** cada fixture se carga por parámetro de consulta y produce un estado distinguishable y determinista.
- [ ] **MK-012-T04 — P0:** Confirmar [DESIGN.md](../DESIGN.md) 1.0.0 y el catálogo de componentes DS-C01, DS-C02, DS-C03, DS-C05, DS-C12, DS-C14, DS-C17, DS-C19, DS-C22, DS-C24, DS-C25 y DS-C28. `[TODO]`
- [ ] **MK-012-T05 — P0:** Identificar MK-012-S02 como pantalla ancla y alinear jerarquía, densidad y microtexto con el resto del módulo. `[TODO]`
- [ ] **MK-012-T06 — P0:** Confirmar la frontera con MK-008: la resolución de slug se consume desde Categorías y no se representa como pantalla adicional. `[TODO]`

## 4. Implementación por pantalla

### MK-012-S02 — Configurar o editar metadatos

- [ ] **MK-012-T11 — P0 — Implementar estructura de S02** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S02) y WF-012 §3.
  - **Acción:** construir la Card de slug con URL pública y regeneración, la Card de metatítulo y metadescripción con contadores, la Card de vista previa y la barra de acciones.
  - **Salida esperada:** ruta `/MK012/S02` renderizable y navegable directamente.
  - **Verificación:** las tres cards obligatorias están presentes y no hay campos inventados.
- [ ] **MK-012-T12 — P0 — Construir MK-012-C01 y MK-012-C02 con advertencias no bloqueantes** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §13; HU-012 CA-01, CA-02 y CA-04.
  - **Acción:** implementar el slug como dato derivado con opción de regenerar, el sufijo resaltado en colisión y los contadores de 70 y 160 caracteres junto a su campo.
  - **Salida esperada:** ruta `/MK012/S02` operativa; el guardado permanece habilitado con advertencias activas.
  - **Verificación:** los fixtures `slug-normalizado`, `slug-con-colision` y `advertencias-activas` reproducen cada caso y el guardado es posible en el último.
- [ ] **MK-012-T13 — P0 — Manejar el conflicto de disponibilidad del slug** `[TODO]`
  - **Entrada:** HU-012 CA-03, CA-07, CA-08 y CA-10; WF-012 §5 y §8.
  - **Acción:** ante `409 SLUG_DUPLICADO`, mostrar una alerta persistente y solicitar una nueva propuesta, sin sustituir el slug en silencio y sin reenviar la confirmación automáticamente.
  - **Salida esperada:** el gestor debe volver a confirmar la propuesta vigente.
  - **Verificación:** el fixture `slug-carrera-409` muestra la nueva propuesta y el bloqueo queda registrado.
- [ ] **MK-012-T15 — P0 — Construir MK-012-C03 con la advertencia de aproximación** `[TODO]`
  - **Entrada:** LUX-03, SPEC-012 R4 y WF-012 §3.
  - **Acción:** implementar la vista previa informativa con la advertencia de que es una aproximación y no una réplica del resultado de un buscador.
  - **Salida esperada:** vista previa visible y declarada como aproximación.
  - **Verificación:** la advertencia está presente en el texto de S02 y no se presenta como resultado real.
- [ ] **MK-012-T16 — P0 — Guardar los metadatos por PATCH** `[TODO]`
  - **Entrada:** contrato API y A-02 del `component-spec.md`.
  - **Accion:** enviar la edicion por `PATCH /api/v1/categorias/{categoriaId}/seo` y reflejar los valores aplicados en S01.
  - **Salida esperada:** guardado correcto y retorno al listado.
  - **Verificación:** el método utilizado es `PATCH` y los errores aparecen junto al campo afectado.

### MK-012-S01 — SEO por categoría

- [ ] **MK-012-T10 — P0 — Implementar S01** `[TODO]`
  - **Entrada:** `component-spec.md` §10 (S01) y §5.
  - **Acción:** construir el listado con nombre, slug, presencia de metadatos, filtro y acciones por fila.
  - **Salida esperada:** ruta `/MK012/S01` operativa con default, loading, empty, sin resultados y error.
  - **Verificación:** los fixtures `default`, `empty` y `sin-resultados` reproducen cada estado.
- [ ] **MK-012-T17 — P0 — Verificar la navegación del módulo** `[TODO]`
  - **Entrada:** `component-spec.md` §6.
  - **Acción:** conectar Configurar o editar hacia S02 y Ver historial hacia S03, y el retorno desde S03.
  - **Salida esperada:** navegación operativa entre las tres rutas sin rutas rotas.
  - **Verificación:** el flujo es navegable de extremo a extremo sin errores en consola.

### MK-012-S03 — Historial de slugs

- [ ] **MK-012-T14 — P0 — Construir MK-012-C04 con los campos contractuales** `[TODO]`
  - **Entrada:** `component-spec.md` §9 y §10 (S03); HU-012 CA-05; WF-012 §4; contrato del historial de slug.
  - **Acción:** implementar la tabla con slug anterior, slug actual y fecha de cambio, más la nota de integración con Marketplace.
  - **Salida esperada:** ruta `/MK012/S03` operativa en modo de solo lectura.
  - **Verificación:** los fixtures `historial-slugs` y `historial-inicial` reproducen cada caso; no se muestra información de responsable ni autor; no existe acción de reversión.

## 5. Normalización

- [ ] **MK-012-T50 — P0 — Normalizar arquitectura y componentes** `[TODO]`
  - **Entrada:** código en `prototipo/src/pantallas/MK012` y convenciones del Design System.
  - **Acción:** sustituir componentes ad hoc por componentes centralizados de Mantine y el Design System.
  - **Salida esperada:** código modular sin estilos inline huérfanos.
  - **Verificación:** build exitoso sin warnings ni dependencias no autorizadas.
- [ ] **MK-012-T51 — P0:** Normalizar colores con tokens oficiales del tema. `[TODO]`
- [ ] **MK-012-T52 — P0:** Normalizar espaciados, bordes y radios según la escala del módulo. `[TODO]`
- [ ] **MK-012-T53 — P0:** Aplicar la escala tipográfica centralizada. `[TODO]`
- [ ] **MK-012-T54 — P0:** Sustituir iconos ad hoc exclusivamente por Tabler Icons. `[TODO]`
- [ ] **MK-012-T55 — P0:** Eliminar términos técnicos y nombres de base de datos visibles al usuario. `[TODO]`
- [ ] **MK-012-T56 — P0:** Revisar semántica HTML y accesibilidad básica, incluidos los contadores asociados por descripción a su campo. `[TODO]`

## 6. Autovalidación local (Owner funcional)

- [ ] **MK-012-T60 — P0:** Validar cobertura estricta de SPEC-012 sin reglas inventadas, incluida la ausencia de creación de categorías, de persistencia de slugs, de simulador de endpoint público y de pantalla duplicada de resolución. `[TODO]`
- [ ] **MK-012-T61 — P0:** Validar los 10 criterios de aceptación de HU-012 contra la matriz de `component-spec.md` §2.1. `[TODO]`
- [ ] **MK-012-T62 — P0:** Validar correspondencia con WF-012 v0.5, incluidas §4, §5 y §8. `[TODO]`
- [ ] **MK-012-T63 — P0:** Validar transiciones completas según FLOW-012. `[TODO]`
- [ ] **MK-012-T64 — P0:** Validar cumplimiento de UX Guidelines normativas del módulo. `[TODO]`
- [ ] **MK-012-T65 — P0:** Validar aplicación de UXD-004, UXD-007, UXD-013 y UXD-015. `[TODO]`
- [ ] **MK-012-T66 — P0:** Validar justificación de LUX-01, LUX-02 y LUX-03. `[TODO]`
- [ ] **MK-012-T67 — P0:** Validar fidelidad al Design System y reutilización de componentes compartidos. `[TODO]`
- [ ] **MK-012-T68 — P0:** Validar las tres rutas inventariadas (`/MK012/S01`, `/MK012/S02`, `/MK012/S03`) y el comportamiento en 1440 px sin overflow horizontal. `[TODO]`
- [ ] **MK-012-T69 — P0 — Registrar evidencias de autovalidación** `[TODO]`
  - **Entrada:** inspección técnica y funcional de pantallas, estados y rutas.
  - **Acción:** documentar pantallas, trazabilidad de ejecución, UI, PC y accesibilidad, siguiendo la estructura de la plantilla de `validation-report.md`.
  - **Salida esperada:** evidencias que sustentan la matriz de §2.1.
  - **Verificación:** cero hallazgos bloqueantes ni importantes requeridos abiertos.

## 7. Revisión transversal y visto bueno

- [ ] **MK-012-T70 — P0:** Confirmar que la autovalidación local está completa y cerrada. `[TODO]`
- [ ] **MK-012-T71 — P0:** Solicitar formalmente revisión transversal a Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-012-T72 — P0:** Atender y corregir todos los hallazgos bloqueantes e importantes. `[TODO]`
- [ ] **MK-012-T73 — P0:** Obtener visto bueno formal de Leonardo Vera Rodríguez. `[TODO]`
- [ ] **MK-012-T74 — P0 — Registrar estado APROBADO PARA FIGMA** `[TODO]`
  - **Entrada:** visto bueno otorgado por el revisor.
  - **Acción:** registrar el estado de revisión transversal.
  - **Salida esperada:** sección de revisión transversal en estado `APROBADO PARA FIGMA`.
  - **Verificación:** confirmación formal del revisor con fecha.

## 8. Figma y cierre

- [ ] **MK-012-T75 — P0:** Trasladar fielmente a Figma la versión aprobada para Figma. `[TODO]`
- [ ] **MK-012-T76 — P0:** Verificar fidelidad punto a punto entre Figma y el prototipo aprobado. `[TODO]`
- [ ] **MK-012-T77 — P0:** Confirmar que las tres pantallas P0 están completas en Figma. `[TODO]`
- [ ] **MK-012-T78 — P0:** Registrar el enlace canónico de Figma. `[TODO]`
- [ ] **MK-012-T79 — P0 — Cierre de Quality Gates y resultado APROBADO** `[TODO]`
  - **Entrada:** Gates A, B, C, D, E y F cumplidos.
  - **Acción:** cerrar el reporte de validación y declarar el resultado general.
  - **Salida esperada:** **Resultado general = APROBADO**.
  - **Verificación:** todos los gates cerrados y cero bloqueos abiertos.

## 9. Registro de bloqueos

| Tarea | Fecha | Causa del bloqueo | Fuente / Documento a resolver | Responsable de resolución | Condición de desbloqueo | Estado |
|---|---|---|---|---|---|---|
| MK-012-T02 | 2026-10-03 | El `component-spec.md` v1.1 está en estado En revisión; Q-01 y Q-02 siguen abiertas | Revisión documental del `component-spec.md` | Leonardo Lopez | Aprobación del component-spec y cierre de Q-01 (umbrales de longitud) y Q-02 (permisos de regeneración) | Activo |
| MK-012-T12 | 2026-10-03 | Depende de Q-01 para distinguir umbrales configurables de constantes del MVP | SPEC-012 y Contrato API | Leonardo Lopez con Taxonomía | Respuesta documentada a Q-01 | Activo |
