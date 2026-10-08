# Plan de Mockup — MK-004

> **Propósito y rol documental:** estrategia para construir Gestión de variantes y SKU, con orden, restricciones, dependencias y Quality Gates. [component-spec.md](component-spec.md) define el resultado; [tasks.md](tasks.md) define las unidades ejecutables. Este plan no redefine pantallas ni UX transversal.

## 1. Identificación

- **Mockup:** MK-004.
- **Funcionalidad:** Gestión avanzada de variantes (SKUs) — `variantes_skus`.
- **Responsable:** Gabriel Poma Gutierrez · **Rama:** `poma`.
- **Versión:** v0.1 · **Fecha:** 2026-10-02.
- **Estado:** Borrador; ejecución completa condicionada por Gate 0 y component-spec §14.
- **Versiones consumidas:** UX 2.0, [Design System](../DESIGN.md) 1.0.0, OpenAPI HTTP 0.5.0, AsyncAPI 0.4.0.
- **Plataforma:** Web desktop, viewport canónico 1440 px.

## 2. Contrato de ejecución

### Entradas

- [Component Spec MK-004](component-spec.md), Q-01–Q-04, LUX-01–03, estados y fixtures por clase de evidencia.
- [Propuesta UX](../ux/propuesta-ux.md), [UX Decisions](../ux/ux-decisions.md), [UX Guidelines](../ux/ux-guidelines.md), v2.0.
- [SPEC-004](..\..\..\requisitos\specs\SPEC-004-gestion-variantes-skus.md), [HU-004](..\..\..\requisitos\hu\HU-004-gestion-variantes-skus.md), [WF-004](../../wireframes/flows/WF-004-gestion-variantes-skus.md), [FLOW-004](..\..\..\requisitos\flujos\FLOW-004-gestion-variantes-skus.md).
- [SPEC-003](..\..\..\requisitos\specs\SPEC-003-gestion-productos-crud.md), [FLOW-003](..\..\..\requisitos\flujos\FLOW-003-gestion-productos-crud.md), [Component Spec MK-003](../MK-003/component-spec.md) para padre/hijos.
- [SPEC-009](..\..\..\requisitos\specs\SPEC-009-gestion-caracteristicas.md), [SPEC-010](..\..\..\requisitos\specs\SPEC-010-asociacion-tipo-producto-caracteristica.md) y [SPEC-013](..\..\..\requisitos\specs\SPEC-013-gestion-precios-individuales-masivos.md): atributos tipados y herencia/override.
- [OpenAPI](..\..\..\contratos\http\openapi.yaml), [AsyncAPI](..\..\..\contratos\eventos\asyncapi.yaml), [errores](..\..\..\contratos\http\catalogo-errores.md), [eventos](..\..\..\contratos\eventos\catalogo-eventos.md), [Contrato API](..\..\..\contratos\http\Contrato_Api.md) §§7/31.6–31.7 y extensión HTTP 0.5.0, [kit](..\..\..\contratos\http\kit-integracion.md).
- [Arquitectura](..\..\..\arquitectura\Arquitectura.md), [Modelo Conceptual](..\..\..\arquitectura\Modelo_Conceptual.md), [DESIGN](../DESIGN.md), [prototipo README](../prototipo/README.md) y [pipeline](../README.md).

Los ejemplos MK-001/MK-002 aportan estructura de documentación/ejecución; no se copian sus capacidades, estados de lote, reservas o reglas económicas.

### Salidas esperadas

- S01–S06 completas conforme al component-spec, con acceso directo `/MK004/SXX`; S02 crear/editar y S05/S06 modales reproducibles sin recorrido previo.
- Código específico en `mockups/prototipo/src/pantallas/MK004/`, con componentes/tema/router del entorno común.
- Requests/responses de `Variante` y estados UI separados de evidencia interna de preparación/efecto sobre padre; fixtures deterministas.
- Recorridos de alta/preparación/edición/activación/baja/reactivación y retorno a MK-003, conservando producto/variante/filtros.
- Autovalidación futura en `mockups/MK-004/validation-report.md`, instanciado desde [su plantilla](../_plantillas/mockup/validation-report.template.md).
- Revisión de Leonardo Vera Rodríguez, correcciones y **APROBADO PARA FIGMA**; diseño fiel en Figma, enlace/fidelidad y cierre general **APROBADO** tras todos los gates.

Esta versión describe entregables futuros; no declara un prototipo o diseño Figma ya construido/aprobado.

### Restricciones de ejecución

- No alterar SPEC/HU/WF/FLOW, contratos, UX/DS u otro MK para resolver hallazgos sin corrección documental correspondiente.
- No inventar preparación en `Variante`; GET de variante no equivale a consultar una operación de Inventario.
- No usar `ACTIVA` para afirmar detalle/fecha/causa de preparación, saldo o disponibilidad comercial del padre/canal.
- No inventar endpoint de reintento, publicación de eventos desde navegador ni un POST de alta como recuperación técnica.
- No crear precio base por variante, pedir precio obligatorio ni editar el override; se gestiona en Pricing posteriormente.
- No exigir padre activo para preparar/activar/reactivar hijo; sí exigir que admita variantes y los demás requisitos de SPEC-004.
- No recodificar SKU, editar combinación identificadora o sustituir variante; no enviar campos no publicados en PATCH.
- No agregar body `EstadoMutationRequest` a POST de estados de variante: esas rutas publican parámetros, no ese request.
- No inferir última activa ni estado del padre desde página filtrada; la respuesta de baja de variante no confirma estado del padre.
- No inactivar padre BORRADOR/INACTIVO por baja de último hijo activo; no reactivar padre/hijos automáticamente.
- No convertir edición activa inválida en desactivación; mantener versión/propuesta ante conflicto y datos persistidos anteriores ante rechazo.
- No inventar `q`, ordenamiento, generación cartesiana, toolbar masiva, barcode, stock inicial, ubicación o campos fiscales.
- No convertir input físico parcial en respuesta física completa con fecha inventada; Q-04 gobierna su lectura.
- No crear aplicación, tema, router ni dependencias exclusivas por MK; no copiar fundamentos gráficos de baja fidelidad ni añadir mobile/tablet.

### Condiciones de parada / escalamiento

Marcar la tarea afectada `BLOCKED`, registrar causa/fuente/responsable y condición de resolución en tasks §9 si:

1. Implementar requiere datos/operaciones no publicados o modificar la identidad/reglas del SKU.
2. Q-01/Q-02 siguen abiertas para seguimiento/reintento; Q-03 para impacto concreto del padre; Q-04 para recuperar físico parcial.
3. Falta baseline común y continuar requiere crear infraestructura paralela.
4. No hay evidencia suficiente de precondición/versión/resultado y se pretende afirmar confirmación o repetir una escritura desconocida.
5. Gate carece de evidencia o existen hallazgos requeridos abiertos antes de visto bueno/Figma.

El resto del análisis documental y tareas independientes puede continuar. No se declara terminada la capacidad completa ni se aprueba un estado P0 mediante una simulación de backend inexistente.

## 3. Entradas obligatorias

| Entrada | Referencia | Estado requerido |
|---|---|---|
| Propuesta UX / UXD / UXG | Documentos v2.0 de §2 | Vigentes; gate transversal #59+#60 disponible |
| Component Spec | [component-spec.md](component-spec.md) | Aprobado para el alcance dependiente, sin Q bloqueantes abiertas |
| SPEC/HU | SPEC-004 / HU-004, dependencia SPEC-003 | Vigentes y reglas padre/hijos coherentes |
| WF / Flow | WF-004 / FLOW-004 | Vigentes, seis pantallas/modos sincronizados |
| Taxonomía/Pricing | SPEC-009/010/013 y OpenAPI | Esquema por tipo y herencia sin precio duplicado |
| HTTP / mensajería | OpenAPI 0.5.0 / AsyncAPI 0.4.0 | Esquemas/operaciones vigentes y versiones independientes |
| DS | [DESIGN](../DESIGN.md) 1.0.0 | Componentes/tokens identificados |
| Baseline | [prototipo README](../prototipo/README.md) | React/TypeScript/Mantine, tema, routing y fixtures comunes disponibles |
| Revisión y cierre | [Pipeline](../README.md), plantilla validation-report | Owner→Leonardo Vera→Figma |

### Gate 0 — Ready for Implementation

- Confirmar fuentes y component-spec aprobado; aceptar LUX-01–03.
- Resolver Q-01–Q-04 antes de ejecutar/aprobar las tareas dependientes; coordinar lectura del padre y perfil parcial con MK-003.
- Verificar operaciones vigentes de variantes, incluida reactivación `provisional-internal`, sin tratarla como endpoint ausente.
- Confirmar entorno común, versiones instaladas/lockfile y fixtures/rutas. En la revisión documental actual solo existe el README del prototipo; su estructura prevista no constituye baseline ejecutable.
- Establecer dataset padre/SKUs compartido documentalmente con MK-003, sin modificar otra funcionalidad desde la construcción MK004.

**Estado de esta versión:** documentación para revisión, Gate 0 pendiente. La ausencia de baseline y los hallazgos no impiden especificar; impiden afirmar construcción/validación completa. La baseline es una dependencia transversal, no una aplicación nueva dentro de MK004.

## 4. Objetivo

Construir un prototipo desktop que demuestre alta y mantenimiento de variantes individuales, preservación de identidad SKU/combinación, preparación de inventario, activación/reactivación válida y baja con efecto correcto sobre padre. El resultado será revisable con seis rutas y fixtures sin backend real, consumiendo operaciones oficiales y dejando resueltas las capacidades requeridas antes del cierre.

## 5. Pantallas

| ID | Nombre | Prioridad | Orden |
|---|---|---|---:|
| MK-004-S02 | Crear o editar variante | P0 | 1 |
| MK-004-S03 | Detalle de la variante | P0 | 2 |
| MK-004-S04 | Preparación de inventario | P0 | 3 |
| MK-004-S05 | Confirmar desactivación | P0 | 4 |
| MK-004-S06 | Confirmar reactivación | P0 | 5 |
| MK-004-S01 | Variantes del producto | P0 | 6 |

S02 se valida primero en alta y después en edición. Activación de BORRADOR forma parte de S03; no existe nueva pantalla ni wizard de activación.

## 6. Pantalla ancla

- **Pantalla:** MK-004-S02 — Crear o editar variante, modo crear.
- **Motivo:** reúne identidad/combinación, imagen y cuatro medidas; define diferencias con el padre y con el modo editar.
- **Qué debe establecer:** contexto del producto, captura explícita de atributos, SKU opcional/generado, imagen requerida, físico incompleto en borrador y errores por campo sin precio propio.
- **Casos iniciales:** `create-generated-sku`, `create-explicit-sku`, `create-partial-physical`; contraste con `edit-default` y `edit-active-rejected`.

Aplica UXD-001/002 y DESIGN; no crea una propuesta independiente ni convierte preparación en pasos artificiales.

## 7. Estrategia

1. **Contexto y alineación:** confirmar fuentes, Gate 0, DS y dependencias; coordinar Q con Producto/Inventario/integración. Salida: mapa de datos/operaciones y límites aprobados.
2. **Fixtures:** construir datasets de `VarianteCreateRequest`, `VarianteUpdateRequest`, `Variante`, `PaginaVariantes`, `Problem` y estados UI. Mantener evidencia interna de preparación/padre separada hasta alinear Q. Salida: escenarios deterministas auditables.
3. **Ancla S02:** C01–C03, alta con SKU explícito/omitido, combinación e imagen; físico parcial válido; modo editar read-only de identidad; error/guardado/conflicto. Salida: request correcto por modo, sin precio obligatorio ni cambio de SKU.
4. **S03:** lectura pública administrativa de variante, datos/estado/requisitos; activar con POST, conservar estado hasta `200`, relectura ante conflicto o respuesta desconocida cuando ID disponible. Salida: detalle y activación sin exigencia de padre activo.
5. **S04:** C04, alta persistida separada de inicialización; seguimiento y reintento solo con fuente/operación formalizadas. Salida: preparación por SKU, sin stock inicial ni precio base.
6. **S05/S06:** C05, impacto de baja por padre/última activa y reactivación con requisitos; cancelación, error y resultado desconocido. Salida: misma identidad, padre no reactivado automáticamente, efecto concreto respaldado por Q-03.
7. **S01 y navegación:** tabla, filtro/paginación admitidos, acciones por estado; retorno al padre/contexto; todas las rutas y modos directos. Salida: recorrido integral sin búsqueda ni ordenamiento inventados.
8. **Normalización y accesibilidad:** tema/components comunes, TypeScript/Mantine/Tabler; layout 1440, teclado, labels y foco; pruebas de contenido largo/errores y estados deterministas.
9. **Autovalidación:** revisar CA-01–15, fuentes, requests y reglas padre/hijos; completar validation-report con evidencia, hallazgos y Gates A–D.
10. **Revisión transversal:** Leonardo Vera Rodríguez revisa; owner corrige hallazgos bloqueantes/importantes; registrar **APROBADO PARA FIGMA** con fecha/versión.
11. **Figma y cierre:** trasladar versión exacta, comprobar seis pantallas/modos/estados, registrar enlace/fidelidad; resultado general **APROBADO** únicamente con Gate A–F cerrados.

## 8. Reutilización

| Componente | Origen | Pantallas | Acción |
|---|---|---|---|
| Shell/tema/breadcrumbs/router/escenarios | Baseline común; DESIGN y prototipo README | Todas | Consumir infraestructura acordada, sin app MK004 |
| Tabla/filtro/paginación | DS-C06/13/17/18 | S01 | Componer C01 con estado/página, sin añadir Search o selección masiva |
| Identidad/atributos | DS-C03/04/06 y esquema de Taxonomía | S02/S03/S06 | Componer C02 y distinguir alta/edición |
| Imagen/físico | Controles DS-C03/04/19 | S02/S03/S06 | Componer C03 por SKU; no redefinir control ni asociar medidas al padre |
| Preparación/requisitos/feedback | DS-C14/19/22/24/25 | S03/S04/S06 | C04 con fuente verificable, sin copiar estados de lote MK-001 |
| Confirmaciones/foco | DS-C21 y DS-C01 | S05/S06 | C05 con acción específica y contexto variante/padre |
| Enlace/contexto producto | Contrato documental MK-003 | S01–S06 | Reutilizar identidad del padre y retorno; no ejecutar cambios de producto desde variante |

## 9. Normalización

- React + TypeScript + Mantine + Tabler Icons con versiones/lockfile del entorno compartido; no inferir versión instalada de una mención en DESIGN.
- Código específico/fixtures bajo `mockups/prototipo/src/pantallas/MK004/`; tokens y componentes transversales comunes, sin duplicar tema o router.
- Respetar DS 1.0.0: Oswald/Inter, roles de color, tamaños, spacing, radios, capas y estados simultáneos; sin estilos huérfanos.
- Tipos HTTP separados de estados de revisión de preparación y padre; `catalog_version` de lectura mapea a `catalogVersion` solo en PATCH según contrato.
- POST de estados consume solo parámetros publicados; no copiar body/headers de otras capacidades sin fuente.
- Leer atributos identificadores por IDs; etiquetas renombradas no recodifican SKU. No convertir requerido del tipo en identificador automáticamente.
- Estado funcional/visual/consulta separados; inputs parciales no se presentan como perfil de respuesta completo; no saldo o causa supuestos.
- Rutas directas y modos reproducibles, sin dominio/puerto fijo ni dependencia de localStorage previo como único mecanismo.
- Labels, errores, regiones anunciables, teclado y foco restituidos; revisión exclusiva desktop sin overflow de página.

## 10. Estados

| Estado | Pantalla | Prioridad | Fixture | Evidencia esperada |
|---|---|---|---|---|
| Lista default/loading/empty/error | S01 | P0 | `list-default`, `list-loading`, `list-empty`, `list-no-results`, `list-error` | PaginaVariantes válida, filtro/meta y vacíos diferenciados |
| Padre incompatible/borrador | S01/S02/S03 | P0 | `parent-simple`, `parent-draft` | Simple no admite alta; borrador no bloquea activación del hijo; estado padre Q-03 |
| Alta SKU omitido/solicitado | S02 | P0 | `create-generated-sku`, `create-explicit-sku` | SKU recibido tras `201`, combinación/imagen requeridas |
| Físico incompleto/inválido | S02 | P0 | `create-partial-physical`, `create-invalid-physical` | Informados positivos; borrador parcial permitido; lectura Q-04 |
| Duplicados/atributo/imagen inválidos | S02 | P0 | `create-duplicate-sku`, `create-duplicate-combination`, `create-invalid-attribute`, `create-invalid-image` | Código correcto y entradas preservadas |
| Edición/conflicto/rechazo activo | S02 | P0 | `edit-default`, `edit-version-conflict`, `edit-active-rejected` | Identidad read-only; relectura de variante; ACTIVA persistida intacta |
| Detalle por estado/no encontrado | S03 | P0 | `detail-draft`, `detail-active`, `detail-inactive`, `variant-not-found` | Estado de Variante sin inferir exposición ni preparación detallada |
| Preparación ausente/carga/error | S04 | P0 | `prep-unavailable`, `prep-loading`, `prep-error` | Sin campo inventado ni cero ante fallo |
| Pendiente/rechazada/completada | S04 | P0 | `prep-pending`, `prep-rejected`, `prep-completed` | Fuente Q-01 y reintento Q-02 alineados; no nueva identidad |
| Activación requerida/confirmada | S03 | P0 | `activate-missing-physical`, `activate-success` | Requisitos/validación servidor, éxito `200 ACTIVA` |
| Baja con impacto por padre | S05 | P0 | `deactivate-other-active`, `deactivate-last-active-parent`, `deactivate-last-draft-parent`, `deactivate-last-inactive-parent` | Cambio de variante confirmado; efecto del padre según evidencia Q-03 |
| Impacto desconocido | S05 | P0 | `deactivate-parent-unknown` | Explicación condicional sin deducir última activa de página |
| Reactivación válida/rechazada | S06 | P0 | `reactivate-valid`, `reactivate-invalid`, `reactivate-no-parent-change` | Misma identidad, validación, no reactivación del padre |
| Guardando/cancelación/desconocido | S02/S03/S05/S06 | P0 | `saving`, `cancel-confirmation`, `write-unknown` | Sin doble envío; cancelación sin mutación; releer antes de repetir |

Cargas/errores de maestros/esquema y detalle se inspeccionan también de forma localizada. Los estados FUNCIONAL no se transforman en campos HTTP ni se marcan PASS hasta resolver Q.

## 11. Orden de ejecución

| Fase | Salida | Actor / revisor | Gate |
|---|---|---|---|
| Preparación/alineación | Fuentes, Q y baseline disponibles | Gabriel Poma + Inventario/integración | Gate 0 |
| Fixtures | Requests/respuestas/UI/escenarios separados | Gabriel Poma | Validez contractual |
| Ancla | S02 crear/editar | Gabriel Poma | Identidad/atributos/imagen/físico correctos |
| Detalle | S03 con lectura/activación | Gabriel Poma | Estado confirmado y conservación de entradas |
| Preparación | S04 | Gabriel Poma + Inventario | Fuente/comando formalizados |
| Confirmaciones | S05/S06 | Gabriel Poma | Impacto padre verificable; reactivación independiente |
| Lista/rutas | S01 y vínculo MK-003 | Gabriel Poma | Todas las rutas/modos directos, filtros conservados |
| Normalización/estados/a11y | Código DS y evidencia desktop | Gabriel Poma | Gates A–D |
| Autovalidación | Reporte sin hallazgos requeridos abiertos | Gabriel Poma | Readiness de revisión |
| Revisión/correcciones | Visto bueno fechado | Leonardo Vera Rodríguez / Gabriel Poma | Gate E: APROBADO PARA FIGMA |
| Figma/fidelidad | Frames y enlace | Gabriel Poma | Gate F |
| Cierre | Resultado general APROBADO | Gabriel Poma | Todos los gates cerrados |

## 12. Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R-01 | Preparación inventada en Variante o deducida de tiempo/estado | Alta | Alto | Q-01; separar escenario funcional y respuesta HTTP |
| R-02 | Reintento repite alta/inicialización completada | Alta | Alto | Q-02; identidad de operación y sin segundo POST automático |
| R-03 | Última activa inferida de lista paginada o baja variante acredita padre ficticiamente | Alta | Alto | Q-03; fuente administrativa completa, explicación condicional hasta resolución |
| R-04 | Precio base exigido por SKU o inicialización Pricing duplicada | Media | Alto | SPEC-004 §3; auditar ausencia de campo/preparación de precio |
| R-05 | Edición cambia SKU/combinación o desactiva automáticamente por error | Media | Alto | Read-only, PATCH exacto y fixture de activo rechazado |
| R-06 | Padre inactivo bloquea preparación/reactivación de hijo | Media | Alto | Fixtures padre borrador/inactivo; validación solo de modelo y requisitos SKU |
| R-07 | Perfil parcial del borrador devuelto como completo con fecha supuesta | Alta | Alto | Q-04; inputs y responses físicos separados |
| R-08 | Baseline ausente produce infraestructura por MK | Alta | Alto | Coordinar entorno común; bloquear tareas dependientes sin app paralela |
| R-09 | Combinaciones largas/modal/acciones ocultan foco o SKU | Media | Medio | Texto que envuelve, detalle accesible, inspección 1440/teclado |

## 13. Quality Gates

### Gate A — Funcional

- SPEC-004 §§1–7/extensión, HU-004 CA-01–15 y flujos padre/hijos cubiertos sin reglas nuevas.
- Q-01–Q-04 resueltas para los estados P0 afectados; no detalle de preparación, reintento o efecto padre ficticios.
- S01–S06, ambos modos de S02 y modales S05/S06 tienen acceso directo y estados deterministas.
- Cada acción traza operación/request/response exactos; reactivación publicada, sin body de producto agregado a variante.
- Alta sin precio propio, identidad/combinación conservadas, físico completo para activar/reactivar, padre sin saldo/perfil, efectos de baja/reactivación correctos.

### Gate B — UX

- UX-P01 Alta/P02 Media/P03 Alta aplicadas con UXD/UXG pertinentes y LUX-01–03 justificadas.
- Contexto/filtro/entradas preservados; error situado, resultado desconocido distinto de rechazo y preparación distinta de estado funcional.
- Imagen requerida al alta de variante no se omite por copiar la excepción del producto; no wizard, Search o acción masiva sin capacidad.

### Gate C — UI

- DS 1.0.0 y tema común, componentes/tokens/variantes reutilizados; tipografía, controles, badges, iconos y capas coherentes.
- Código modular/tipado sin estilos huérfanos, dependencias no acordadas ni tema local.
- Build/comprobación de tipos del entorno sin errores o warnings atribuibles a MK004; preexistentes registrados con evidencia.

### Gate D — PC

- Inspección desktop 1440 sin overflow horizontal de página; SKU/estado/errores/acciones completos y foco no oculto.
- Teclado, labels, errores asociados, diálogo con foco contenido/restaurado y estados perceptibles sin color.
- Sin mobile/tablet ni afirmación de certificación de accesibilidad sin evaluación.

### Gate E — Revisión transversal y aprobación para Figma

- Autovalidación del owner terminada; **Leonardo Vera Rodríguez** realiza revisión posterior.
- Cero hallazgos bloqueantes/importantes requeridos abiertos y correcciones reinspeccionadas.
- Visto bueno fechado, versión/evidencias registradas y **APROBADO PARA FIGMA** en validation-report.

### Gate F — Figma y cierre

- Seis pantallas, modos/estados P0, componentes y contenido reflejan exactamente versión con visto bueno.
- Fidelidad comparada punto por punto, enlace canónico registrado y todas las verificaciones requeridas PASS.
- **Regla de cierre:** resultado general **APROBADO** únicamente con Gate A–F completos, sin hallazgos requeridos abiertos. Este plan describe el pipeline; no concede aprobación anticipada ni publica cambios externos por sí mismo.
