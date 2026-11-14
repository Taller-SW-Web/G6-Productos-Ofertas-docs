# Plan de Mockup — MK-003

> **Propósito y rol documental:** estrategia para construir Gestión de productos: fases, orden, restricciones y Quality Gates. Consume [component-spec.md](component-spec.md), que define el resultado esperado, y se descompone en [tasks.md](tasks.md). No redefine las pantallas ni la UX transversal.

## 1. Identificación

- **Mockup:** MK-003.
- **Funcionalidad:** Gestión de productos (CRUD principal) — `productos_crud`.
- **Responsable:** Gabriel Poma Gutierrez · **Rama:** `poma`.
- **Versión:** v0.2 · **Fecha:** 2026-10-03.
- **Estado:** Borrador; ejecución completa condicionada al Gate 0 y los hallazgos del component-spec §14.
- **Versiones consumidas:** UX 2.0, [Design System](../DESIGN.md) 1.0.0, OpenAPI HTTP 0.5.0, AsyncAPI 0.4.0.
- **Plataforma:** Web desktop, viewport canónico 1440 px.

## 2. Contrato de ejecución

### Entradas

- [Component Spec MK-003](component-spec.md), incluidas Q-01–Q-06, LUX-01–03 y fixtures con su clase de evidencia.
- [Propuesta UX](../ux/propuesta-ux.md), [UX Decisions](../ux/ux-decisions.md) y [UX Guidelines](../ux/ux-guidelines.md), v2.0.
- [SPEC-003](..\..\..\requisitos\specs\SPEC-003-gestion-productos-crud.md), [HU-003](..\..\..\requisitos\hu\HU-003-gestion-productos-crud.md), [WF-003](../../wireframes/flows/WF-003-gestion-productos-crud.md), [FLOW-003](..\..\..\requisitos\flujos\FLOW-003-gestion-productos-crud.md).
- [SPEC-004](..\..\..\requisitos\specs\SPEC-004-gestion-variantes-skus.md), [FLOW-004](..\..\..\requisitos\flujos\FLOW-004-gestion-variantes-skus.md), [Component Spec MK-004](../MK-004/component-spec.md): ciclo padre/hijos.
- [SPEC-009](..\..\..\requisitos\specs\SPEC-009-gestion-caracteristicas.md) y [SPEC-010](..\..\..\requisitos\specs\SPEC-010-asociacion-tipo-producto-caracteristica.md): esquema tipado del tipo y corrección ordinaria de `tipo_producto_id` bajo las condiciones de §4, Requisito 10.
- [OpenAPI](..\..\..\contratos\http\openapi.yaml), [AsyncAPI](..\..\..\contratos\eventos\asyncapi.yaml), [catálogo de errores](..\..\..\contratos\http\catalogo-errores.md), [catálogo de eventos](..\..\..\contratos\eventos\catalogo-eventos.md), [Contrato API](..\..\..\contratos\http\Contrato_Api.md) §§31.6–31.7 y extensión HTTP 0.5.0, [kit](..\..\..\contratos\http\kit-integracion.md).
- [Arquitectura](..\..\..\arquitectura\Arquitectura.md), [Modelo Conceptual](..\..\..\arquitectura\Modelo_Conceptual.md), [Design System](../DESIGN.md), [entorno de prototipado](../prototipo/README.md) y [pipeline](../README.md).

Los ejemplos MK-001/MK-002 orientan organización y nivel de detalle. No transfieren sus reglas, endpoints, estados de lote ni supuestos monetarios a Productos.

### Salidas esperadas

- S01–S07 implementadas conforme al component-spec; cada una accesible directamente en `/MK003/SXX`, incluidos diálogos.
- Código específico en `mockups/prototipo/src/pantallas/MK003/`, modular y tipado, consumiendo tema/componentes/routing comunes.
- Fixtures HTTP/UI separados de evidencia de escenarios funcionales; todos los estados P0 reproducibles sin backend real, una vez alineadas las capacidades faltantes.
- Navegación de alta, preparación, edición y cambios de estado; vínculo con MK-004 preservando padre/contexto.
- Autovalidación documentada en `mockups/MK-003/validation-report.md`, creado posteriormente desde [su plantilla](../_plantillas/mockup/validation-report.template.md).
- Revisión transversal, correcciones, visto bueno **APROBADO PARA FIGMA**, traslado fiel a Figma y cierre con resultado general **APROBADO** cuando todos los gates se cumplan.

La entrega documental actual especifica estas salidas futuras; no declara código, Figma ni validación ya realizados.

### Restricciones de ejecución

- No modificar fuentes oficiales, UX/DS u otros MK para eliminar un bloqueo sin la corrección documental correspondiente.
- No completar GET comercial con estado/versión/físico administrativos supuestos. Alinear Q-01 antes de simular una lectura administrativa como publicada.
- No derivar pendiente/rechazo de booleano false; no añadir detalle de preparación por hijo sin fuente; no conectar navegador a RabbitMQ.
- No inventar comando HTTP de reintento ni utilizar un PATCH/alta como sustituto. Conservar operaciones y omitir dependencias completadas conforme al contrato que resuelva Q-03.
- No convertir el precio inicial en editor de precio vigente ni inventar moneda/default de canal, barcode o campos fiscales.
- No exigir imagen/características/físico completo al alta en borrador; sí validar valores físicos informados positivos.
- No recodificar SKU base, cambiar modelo en edición, sustituir producto o crear variantes desde PATCH del padre. El tipo admite corrección ordinaria según SPEC-010 solo en BORRADOR, sin variantes y sin identidad comercial publicada; no fijar read-only universal ni enviar `tipoProductoId` hasta resolver Q-06. Con variantes o identidad publicada, la migración queda fuera de alcance.
- No imponer compatibilidad fija categoría→tipo del índice ilustrativo, ni checkbox obligatorio de declaración de identidad.
- No exigir preparación de hijos no activos para activar padre; todas las activas sí deben cumplir SPEC-004. No representar saldo/perfil del padre.
- No desactivar por edición inválida ni reactivar hijos automáticamente; no asumir exposición universal por `ACTIVO`.
- No repetir escrituras con resultado desconocido, inventar rollback distribuido, porcentaje, timestamps o acciones masivas.
- No crear aplicación/tema/router propio por MK ni añadir dependencias sin justificación y acuerdo técnico del entorno compartido.
- No implementar mobile/tablet ni copiar foundations de baja fidelidad del índice WF.

### Condiciones de parada / escalamiento

Marcar la tarea afectada `BLOCKED` y registrar causa, fuente, responsable y condición de resolución en tasks §9 cuando:

1. Haya contradicción funcional/contractual que obligue a inventar datos/comandos o a cambiar una regla de negocio.
2. Se pretenda aprobar estados afectados por lectura administrativa, preparación, reintento, moneda, físico parcial o corrección del tipo con sus Q-01–Q-06 sin resolver.
3. Falte baseline común de React/TypeScript/Mantine, tema, routing o componentes y continuar exija infraestructura paralela.
4. No pueda comprobarse una precondición, versión o resultado requerido para una acción segura.
5. Un gate carezca de evidencia verificable, exista hallazgo requerido abierto o Figma no pueda corresponder a la versión con visto bueno.

El bloqueo se limita al trabajo dependiente. Puede continuar análisis documental, trazabilidad y definición de estados con límites explícitos. No se declara completa una funcionalidad P0 parcialmente alineada.

## 3. Entradas obligatorias

| Entrada | Referencia | Estado requerido |
|---|---|---|
| Propuesta UX / UXD / UXG | Documentos enlazados en §2, v2.0 | Vigentes y gate #59+#60 disponible en base compartida |
| Component Spec | [component-spec.md](component-spec.md) | Aprobado para el alcance a implementar; Q bloqueantes resueltas |
| SPEC/HU | SPEC-003 / HU-003; dependencia SPEC-004 | Vigentes, reglas padre/hijos coherentes |
| WF / Flow | WF-003 / FLOW-003 | Vigentes; inventario y transiciones sincronizados |
| Taxonomía | SPEC-009/010 y OpenAPI | Esquema del tipo y IDs/valores disponibles |
| HTTP / mensajería | OpenAPI 0.5.0 / AsyncAPI 0.4.0 | Operaciones/esquemas vigentes; versiones independientes |
| DS | [DESIGN.md](../DESIGN.md) 1.0.0 | Vigente, componentes/tokens mapeados a pantallas |
| Baseline prototipo | [prototipo/README.md](../prototipo/README.md) | Aplicación común y mecanismo de fixtures/rutas disponibles |
| Revisión y cierre | [Pipeline](../README.md), plantilla validation-report | Flujo owner→Leonardo Vera→Figma definido |

### Gate 0 — Ready for Implementation

- Confirmar baseline de fuentes, revisión de LUX y versión aprobada del component-spec.
- Resolver lectura administrativa, preparación, reintento, moneda del alta y representación del físico parcial: Q-01–Q-05.
- Para S03, resolver Q-06 mediante MK-003-T27: SPEC-010 permite corregir `tipo_producto_id` en BORRADOR, sin variantes y sin identidad comercial publicada, pero `ProductoUpdateRequest` de OpenAPI 0.5.0 no expone `tipoProductoId`. Acordar oficialmente si se amplía el request o se ajusta SPEC-010 y verificar la fuente de las tres precondiciones junto a Q-01 antes de construir/aprobar la corrección del tipo. BORRADOR por sí solo no acredita elegibilidad; no desbloquear restringiendo siempre el tipo a lectura.
- Confirmar integración documental con MK-004 para las mismas identidades y estados.
- Verificar tema y componentes comunes, router y versiones reales de dependencias/lockfile. Actualmente `mockups/prototipo/` contiene su README, sin aplicación implementada; no se declara baseline ejecutable disponible.
- Identificar ruta, fixture y evidencia de verificación para cada estado P0.

**Situación de esta versión:** documentación desarrollada para revisión; Gate 0 pendiente. Ni la existencia de estos documentos ni el cierre transversal de #59/#60 aprueban automáticamente los estados afectados. La creación del entorno común es una dependencia de la futura construcción, no un entregable de este plan funcional.

## 4. Objetivo

Construir un prototipo de Productos que permita demostrar el alta en borrador, la preparación independiente de precio/unidades vendibles, edición conservando identidad, activación/reactivación válida y baja lógica, con fallos recuperables y sin capacidades contractuales ficticias. Las siete rutas y sus estados deben ser inspeccionables de forma controlada y directa en desktop.

## 5. Pantallas

El orden constructivo prioriza requisitos del producto y no coincide con el recorrido del usuario. El detalle de cada vista reside en component-spec §10.

| ID | Nombre | Prioridad | Orden |
|---|---|---|---:|
| MK-003-S02 | Crear producto | P0 | 1 |
| MK-003-S03 | Editar producto | P0 | 2 |
| MK-003-S04 | Detalle del producto | P0 | 3 |
| MK-003-S06 | Preparación del producto | P0 | 4 |
| MK-003-S05 | Confirmar activación/reactivación | P0 | 5 |
| MK-003-S07 | Confirmar desactivación | P0 | 6 |
| MK-003-S01 | Productos | P0 | 7 |

## 6. Pantalla ancla

- **Pantalla:** MK-003-S02 — Crear producto.
- **Motivo:** establece las diferencias simple/padre, la jerarquía de datos mínimos y requisitos adicionales, y los grupos que se reutilizan en edición/detalle.
- **Qué debe establecer:** formulario completo, controles de maestros/tipo, modelo de venta, físico condicional, imagen por referencia, errores locales, guardado de borrador y conservación de entradas.
- **Caso inicial:** `create-simple-draft`; contraste inmediato con `create-variant-parent` y `create-partial-physical`.

La pantalla aplica UXD-001/002 y DESIGN; no crea otro lenguaje visual ni un wizard independiente.

## 7. Estrategia

1. **Preparar contexto:** contrastar fuentes y hallazgos, cerrar Gate 0 del alcance dependiente, identificar DS-C y documentar versiones del entorno común. Salida: mapa de trazabilidad aprobado y dependencias disponibles.
2. **Preparar fixtures:** separar requests/responses HTTP, estados UI y evidencia funcional. Resolver representaciones pendientes antes de promover escenarios a simulación de operaciones publicadas. Salida: escenarios de component-spec §13 con entrada/ruta/resultado verificable.
3. **Construir ancla S02:** C01–C03, alta simple/padre, errores, guardando y `201 BORRADOR`. Validar mínimos y conservar valores. Salida: ancla funcional y visualmente coherente, sin activación automática.
4. **Construir S03/S04:** reutilizar grupos, aplicar restricciones de identidad y lectura administrativa alineada; conflicto de versión y edición activa inválida. La corrección del tipo requiere Q-06/T27 resuelta y evidencia de elegibilidad según la regla oficialmente alineada; comprobar también casos no elegibles y no verificables. Salida: lectura/edición del mismo producto con propuestas y persistido distinguibles, sin migración de tipo desde el CRUD ordinario.
5. **Construir S06:** C04 con dependencias independientes; true/false/ausente y estados detallados solo con fuente acordada; reintento exclusivamente publicado. Salida: seguimiento verificable, sin saldo del padre ni rollback.
6. **Construir S05/S07:** C05, requisitos e impacto; resultado `200`, rechazo y timeout; misma identidad en reactivación. Salida: cambio confirmado solo tras respuesta y cancelación sin efectos.
7. **Construir S01 e integrar MK-004:** reutilizar estado/acciones del detalle, parámetros admitidos y paginación; enlazar por padre válido, conservar contexto. Salida: recorrido completo y todas las rutas accesibles directamente.
8. **Normalizar:** usar tema central y DS, TypeScript, Mantine y Tabler; quitar estilos huérfanos, dependencias locales y texto técnico visible. Verificar condiciones desktop y teclado.
9. **Autovalidar:** comprobar SPEC/HU/WF/FLOW/contratos, fixture por estado y Gate A–D; completar validation-report con hallazgos y evidencia. No declarar PASS con un escenario pendiente de contrato.
10. **Revisión transversal:** entregar evidencias a Leonardo Vera Rodríguez, corregir bloqueantes/importantes requeridos y registrar visto bueno **APROBADO PARA FIGMA**.
11. **Figma y cierre:** reflejar exactamente la versión con visto bueno, comparar pantallas/estados/componentes, registrar enlace y cerrar Gate F. Solo entonces registrar resultado general **APROBADO**.

## 8. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| Shell, tema, breadcrumbs, routing y selector de escenarios | Baseline común; DESIGN §§4–5/15; prototipo README | Todas | Consumir mecanismo acordado; no crear infraestructura MK003 |
| Controles de datos/maestros/atributos | DS-C03–06/09 | S02/S03 | Componer en C01/C02; mismos controles para lectura/edición permitida |
| NumberInput con unidad | DS-C04; DESIGN §8 | S02/S03/S04/S05 | Componer perfil simple, sin redefinir control ni copiar UI de logística |
| Tabla, filtros y paginación | DS-C12/13/17/18 | S01/S04/S06 | Reutilizar solo acciones/parámetros admitidos |
| Feedback/preparación | DS-C14/19/22/24/25 | S04/S05/S06 | C04 con evidencia por dependencia; no copiar estados de lote MK-001 |
| Dialog de confirmación | DS-C21 y DS-C01 | S05/S07 | C05 con contenido/acción del producto y gestión común de foco |
| Navegación hacia unidades vendibles | Contrato documental MK-004 | S04/S06 | Enlace y contexto compartido; sin implementar ni modificar variantes dentro de MK003 |

## 9. Normalización

- React + TypeScript + Mantine + Tabler Icons del entorno común, registrando versiones instaladas; DESIGN no equivale a un package/lockfile.
- Código de pantallas/composiciones/fixtures bajo `mockups/prototipo/src/pantallas/MK003/`; componentes transversales y tokens en las carpetas comunes previstas.
- Theme único con tokens de DESIGN 1.0.0, Oswald para headings e Inter operativa; no defaults divergentes ni límites de campos impuestos por diseño.
- Lecturas comerciales y administrativas tipadas separadamente; validación de requests por sus nombres reales y mapeo explícito snake_case↔camelCase cuando corresponda.
- El mapeo `tipo_producto_id`↔`tipoProductoId` no habilita su envío en edición: falta la propiedad publicada en `ProductoUpdateRequest` 0.5.0. Q-06 debe alinear regla/request; `additionalProperties` no sustituye esa resolución.
- `catalogVersion` del PATCH proviene de lectura; identidad de reintento solo de la operación formalizada. No inventar claves HTTP de idempotencia de altas que el contrato no publique.
- Estado funcional, preparación, carga UI y error de consulta separados; proyección confirmada no se modifica antes de respuesta.
- Accesibilidad de labels/errores, regiones anunciables, foco y teclado; revisión desktop con contenido largo y mensajes completos.
- Comprobación explícita de S01–S07 y sus estados mediante ruta/fixture, independientemente del recorrido previo.

## 10. Estados

Cada fila corresponde al inventario de fixtures de component-spec §13; no introduce estados funcionales adicionales.

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---|---|---|
| Default/lista | S01 | P0 | `list-default` | Lectura administrativa alineada Q-01; tabla/acciones coherentes |
| Loading/empty/error | S01 | P0 | `list-loading`, `list-empty`, `list-no-results`, `list-error` | Región y filtros distinguibles; sin falso estado/stock |
| Alta simple/padre | S02 | P0 | `create-simple-draft`, `create-variant-parent` | BORRADOR con mínimos; físico/inventario solo unidad simple |
| Físico parcial/inválido | S02/S03 | P0 | `create-partial-physical`, `create-invalid-physical` | Borrador admite ausencia; dato informado positivo; lectura parcial Q-05 |
| Guardando/error/duplicado | S02 | P0 | `saving`, `create-duplicate-sku`, `create-invalid-master` | Entradas preservadas y un solo envío |
| Edición/conflicto/rechazo activo | S03 | P0 | `edit-default`, `edit-version-conflict`, `edit-active-rejected`, `category-change` | Misma identidad y estado; versión revisada; categoría no redefine esquema |
| Corrección del tipo elegible/no elegible/no verificable | S03 | P0 | `edit-type-correction-eligible`, `edit-type-correction-ineligible`, `edit-type-correction-unverifiable` | FUNCIONAL, Q-06/T27; tres condiciones verificadas antes de habilitar; sin campo de PATCH inventado ni migración ordinaria |
| Detalle/no encontrado | S03/S04 | P0 | `detail-simple-active`, `detail-parent-inactive`, `product-not-found` | Modelo/estado/físico trazables; Q-01 para relectura |
| Preparación conocida/ausente/parcial | S06 | P0 | `prep-confirmed`, `prep-unconfirmed`, `prep-unavailable`, `prep-partial` | Booleanos sin causa inventada; lo confirmado se conserva |
| Pendiente/rechazada/reintento | S06 | P0 | `prep-pending`, `prep-rejected` | Fuente de estado Q-02 y comando Q-03 resueltos; no repetir completada |
| Requisitos padre | S05/S06 | P0 | `parent-no-active-variants`, `parent-active-and-draft-child` | Al menos una activa; hijos no activos no bloquean; detalle Q-02 |
| Activar/reactivar | S05 | P0 | `activate-missing-requirements`, `activate-success`, `reactivate-parent` | Rechazo conserva estado; éxito `200`; no reactivación de hijos |
| Desactivar/cancelar | S07/S05 | P0 | `deactivate-parent`, `cancel-confirmation` | Confirmación de impacto; cancelar no muta |
| Resultado desconocido | S02/S03/S05/S07 | P0 | `write-unknown` | Sin segundo envío automático; recuperación según fuente disponible |

Loading/error se verifican también en lecturas de detalle, maestros y grupos; se usa mecanismo común de escenarios sin una ruta nueva por cada variante visual.

## 11. Orden de ejecución

| Fase | Salida | Actor / revisor | Gate |
|---|---|---|---|
| Contexto y alineación | Fuentes, hallazgos y baseline confirmados | Gabriel Poma + owners de integración | Gate 0 |
| Fixtures | Datos y escenarios reproducibles, clases de evidencia separadas | Gabriel Poma | Esquemas/operaciones sin invenciones |
| Ancla | S02 validada | Gabriel Poma | Cobertura estructural y mínimos |
| Edición/detalle | S03/S04 | Gabriel Poma | Identidad y lectura administrativa verificables; Q-06/T27 resuelta para la corrección del tipo |
| Preparación | S06 y C04 | Gabriel Poma + Pricing/Inventario | Fuente y reintento formalizados |
| Confirmaciones/lista/navegación | S05/S07/S01 y vínculo MK-004 | Gabriel Poma | Cobertura funcional y rutas |
| Normalización/estados/accesibilidad | Código DS y estados operables | Gabriel Poma | Gates A–D |
| Autovalidación | validation-report y evidencias | Gabriel Poma | Cero hallazgos requeridos abiertos |
| Revisión transversal/correcciones | Visto bueno registrado | Leonardo Vera Rodríguez / Gabriel Poma | Gate E: APROBADO PARA FIGMA |
| Figma y fidelidad | Frames y enlace de versión aprobada | Gabriel Poma | Gate F |
| Cierre | validation-report APROBADO | Gabriel Poma | Todos los gates cerrados |

## 12. Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R-01 | GET comercial usado como lectura administrativa completa | Alta | Alto | Q-01; tipos/fixtures separados, sin completar datos ausentes |
| R-02 | Booleano false convertido en rechazo o preparación del padre inferida de hijos incompletos | Alta | Alto | Q-02, C04; evidencia por dependencia y solo variantes activas |
| R-03 | Reintento inventado o duplicación de alta/precio/inventario | Alta | Alto | Q-03; no reenviar escritura desconocida; mantener identidad formalizada |
| R-04 | Moneda/semántica tributaria impuesta por fixture | Media | Alto | Q-04; PEN solo demostración; sin campos fiscales/default no oficial |
| R-05 | Perfil parcial forzado a respuesta física completa | Alta | Alto | Q-05; inputs separados de resultados completos |
| R-06 | Rechazo de edición inactiva automáticamente producto o cambio de categoría redefine atributos | Media | Alto | Fixtures `edit-active-rejected`/`category-change`; SPEC-003/010 |
| R-07 | Baseline común inexistente provoca aplicación/tema por funcionalidad | Alta | Alto | Verificar entorno y coordinar dependencia transversal; no crear infraestructura paralela |
| R-08 | Desactivar/reactivar padre modifica estados de hijos o garantiza visibilidad por canal | Media | Alto | Validación integrada SPEC-003/004 con escenarios padre/hijos |
| R-09 | Tabla/footer/dialog ocultan foco o producen overflow | Media | Medio | Inspección 1440, texto largo, teclado y tokens DS |
| R-10 | Tipo declarado siempre read-only pese a la excepción de SPEC-010, o corrección enviada sin `tipoProductoId` publicado en OpenAPI 0.5.0 | Alta | Alto | Q-06/T27 como condición de Gate 0 para S03; alinear request o SPEC, verificar BORRADOR/sin variantes/sin identidad publicada y escenarios no elegibles/no verificables |

## 13. Quality Gates

### Gate A — Funcional

- HU-003 CA-01–15 y SPEC-003 §§1–8/extensión cubiertos, con dependencia SPEC-004.
- Lectura administrativa, preparación detallada, reintento, moneda, físico parcial y corrección del tipo alineados (Q-01–Q-06); ninguna Q bloqueante ni capacidad inventada.
- S01–S07 tienen rutas directas estables y todos los estados P0 reproducibles; cada evidencia identifica fixture, fuente, acción y resultado.
- Alta/edición/cambio de estado respetan requests/responses; `201` confirma borrador y `200` confirma mutación, sin equiparar alta y preparación.
- SKU/modelo/identidad preservados, padre sin saldo/físico, edición inválida sin desactivación y efectos padre/hijos correctos.
- Corrección del tipo conforme a SPEC-010 §4, Requisito 10 y la resolución oficial de Q-06; caso elegible, no elegible y no verificable demostrados, sin recodificar SKU/snapshots ni implementar migración de modelo.

### Gate B — UX

- UX-P01/P02/P03 y UXD/UXG aplicables verificadas por pantallas/fixtures; LUX-01–03 justificadas.
- Filtros, contexto y entradas se conservan; errores/carga/ausencia/parcial/desconocido tienen significados distintos.
- No confirmación prematura, reintento universal, wizard obligatorio ni requisitos de activación indebidamente exigidos al borrador.

### Gate C — UI

- DS 1.0.0, tema central, componentes/variantes/tokens aplicados; no estilos huérfanos ni tema local.
- Oswald/Inter, iconografía Tabler, tamaños, espaciados y estados coinciden con DESIGN.
- Build/comprobación de tipos del entorno común sin errores ni warnings atribuibles al MK; cualquier warning preexistente se registra con evidencia.

### Gate D — PC

- 1440 px sin overflow horizontal de página; contenido largo, zoom/texto ampliado y footer no ocultan acciones.
- Teclado, foco visible/restituido, etiquetas/errores asociados y estados comprensibles sin color.
- No layouts mobile/tablet ni certificación de accesibilidad sin evidencia.

### Gate E — Revisión transversal y aprobación para Figma

- **Revisor:** Leonardo Vera Rodríguez, después de autovalidación del owner.
- Cero hallazgos bloqueantes o importantes requeridos abiertos; correcciones reinspeccionadas.
- Visto bueno formal fechado y estado **APROBADO PARA FIGMA** en validation-report.

### Gate F — Figma y cierre

- Figma refleja exactamente la versión con visto bueno: siete pantallas, modos/estados requeridos, tokens, contenido y acciones.
- Fidelidad verificada punto por punto; enlace canónico registrado y todos los resultados requeridos PASS.
- **Regla de cierre:** resultado general **APROBADO** solo con Gate A–F completos y sin hallazgos requeridos abiertos. El plan no concede aprobación anticipada ni autoriza por sí mismo publicar cambios externos.
