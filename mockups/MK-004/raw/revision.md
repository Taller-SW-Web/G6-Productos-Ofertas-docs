# Revisión de MK-004-S01 — Variantes del producto

**Fecha:** 2026-10-03. **Archivo revisado:** [S01.html](S01.html).

**Resultado: NO CONFORME con el alcance completo de S01.** El listado aporta una base visual, pero introduce capacidades/datos no respaldados y carece de acciones, paginación y estados requeridos. Esta revisión no constituye aprobación del MK, revisión transversal de Vera ni visto bueno para Figma.

## Fuentes y método

- [Component Spec](../component-spec.md) §§2, 4–10, 12–15; [plan](../plan.md) §§2–3, 6–10, 13; [tasks](../tasks.md) T02/T07, T30–T32, T40–T41, T50–T69.
- [SPEC-004](../../../specs/SPEC-004-gestion-variantes-skus.md); [HU-004](../../../hu/HU-004-gestion-variantes-skus.md); [WF-004](../../../wireframes/flows/WF-004-gestion-variantes-skus.md); [FLOW-004](../../../flujos/FLOW-004-gestion-variantes-skus.md).
- [OpenAPI](../../../api/openapi.yaml): GET de variantes, `PaginaVariantes`, `Variante`, proyección comercial del padre y cambios de estado.
- [Propuesta UX](../../ux/propuesta-ux.md), [UX Decisions](../../ux/ux-decisions.md), [UX Guidelines](../../ux/ux-guidelines.md) y [Design System](../../DESIGN.md) §§4–5, 7, 9, 12–13, 15.
- Inspección del HTML/DOM; selección de filtro Activas y botón Nueva variante. Verificación visual y capturas a 1440 × 900 px; valores originales restaurados después de las pruebas. El filtro también se comprobó a 1280 px antes de fijar el viewport canónico.

## Cambio de marca realizado

Se agregó el logo suministrado a la izquierda de «Inka Athletics», con el mismo [PNG original](../../assets/inka-athletics-logo.png) y la misma [hoja de marca](../../assets/brand-header.css) que MK-003. Se conservan proporción, colores, nombre y punto naranja; el contenedor blanco recorta solamente márgenes blancos, sin cortar el símbolo. No se muestra un cuadrado con IA.

**Verificación:** logo cargado de 1214 × 910, región de 96 × 40; página sin overflow horizontal a 1440 px. Capturas: [vista completa](evidencias/S01-1440.jpg) y [cabecera](evidencias/S01-cabecera.jpg).

## Hallazgos

P0 identifica requisitos funcionales/contractuales o de accesibilidad pendientes de cierre. P1 identifica correcciones visuales y de contenido requeridas. Estas prioridades no sustituyen `tasks.md`.

| ID | Prioridad | Evidencia encontrada | Requisito / fuente | Corrección necesaria |
|---|---|---|---|---|
| R004-01 | P0 | Búsqueda por SKU/talla/color en toolbar | Component Spec §§2.1, 8, S01; UXG-006; GET variantes admite estado/pagina/tamanio, sin `q` | Retirar búsqueda del listado; no convertir filtro local de una página en búsqueda global. El buscador del shell también debe tener una capacidad real si se conserva |
| R004-02 | P0 | Tabla de siete columnas incluye precio, físico y preparación | Component Spec S01 define SKU, Combinación identificadora, Estado y Acciones, con físico/imagen en detalle | Ajustar la tabla al inventario documentado. Mantener información amplia en S03/S04; no imponer nuevos agregados ni datos a S01 |
| R004-03 | P0 | «Hereda S/ 249.90» en todas las filas y precio del padre se presentan como lectura disponible | `Variante`/`PaginaVariantes` no publican precio; Component Spec S01/§2 y límites de Pricing | Conservar explicación conceptual de herencia, sin monto efectivo por SKU tomado de una fuente supuesta. Una futura ampliación necesita fuente/contrato y actualización documental |
| R004-04 | P0 | «Lista», «Preparando inventario», «Pendiente» y «1 en preparación» se muestran como estados consultados | Component Spec Q-01/Q-02; `Variante` no publica preparación; UXG-010/017/022 y UXG §4 | Representar ausencia de información o evidencia funcional explícitamente pendiente. No inferir preparación del estado ACTIVA ni ofrecer seguimiento operativo sin fuente alineada |
| R004-05 | P0 | «Estado del padre: Activo» se afirma sin lectura administrativa identificada | Component Spec Q-03, C01/S01; GET del padre comercial no incluye estado | Coordinar T07/Q-03 con MK-003 Q-01. No completar la proyección comercial con estado inventado; contemplar contexto administrativo no disponible |
| R004-06 | P0 | KPI dice «3 activas / 60%», pero la tabla contiene 2 Activa, 2 Borrador y 1 Inactiva | UXG-005/008/012/022; C01 impide deducir agregado global de lista parcial | Corregir inconsistencia: en las cinco filas actuales hay dos activas. Retirar KPIs no previstos o formalizar su fuente/alcance; no usar un conteo de página para afirmar un total global |
| R004-07 | P0 | «Activas (en venta)» y «catálogo disponible» equiparan estado con exposición comercial | SPEC-004; HU-004 CA-12/15; Component Spec §7/S01 | Usar «Activas» sin promesa de venta. Exposición depende del padre y de condiciones comerciales/canal, no se infiere del badge de variante |
| R004-08 | P0 | Seleccionar Activas conserva las cinco filas, incluidos Borrador/Inactiva; no hay paginación ni `meta` reproducible | Component Spec C01/S01; plan §10; tasks T31; UXG-001/006 | Implementar filtro contractual, paginación y metadatos. Mantener padre/filtro/página al volver; no fijar «5 de 5» como resultado de cualquier filtro |
| R004-09 | P0 | Nueva variante no abre formulario; enlaces Ver/Editar/Volver usan `href="#"`; Reactivar no tiene comportamiento. Las activas carecen de acción Desactivar | Component Spec S01/§6; FLOW-004; tasks T30/T40–T41; UXG-001/018 | Enlazar crear→S02, detalle→S03, editar→S02, desactivar activa→S05, reactivar inactiva→S06 y volver al padre. No cambiar estados antes de confirmación/respuesta |
| R004-10 | P0 | Solo está disponible el listado precargado; sin loading, empty, sin coincidencias, error, padre simple incompatible o contexto administrativo ausente | Component Spec S01/§13; plan §10; tasks T32; UXG-007/011/017/022 | Completar fixtures reproducibles para cada estado P0 y restringir creación a padre que admita variantes, sin exigir que esté ACTIVO |
| R004-11 | P0 | Botón Nueva variante: blanco sobre naranja `#F76707`; contraste calculado 3.04:1 con etiqueta de 14 px | DESIGN §§4.1, 7.1: primario naranja con texto ink; tasks T51/T56 | Aplicar texto ink al primario default y los pares documentados de hover/foco. No usar blanco sobre naranja vivo |
| R004-12 | P1 | Material Symbols; labels/headers/KPIs en Oswald, texto principal/badges de 12 px, sombras de cards, paleta y spacing del exportado | DESIGN §§4–5, 7, 9; tasks T51–T54 | Usar Tabler; Inter en tabla/labels/cifras; tamaños y colores semánticos del tema común; H1 32/40, tracking 0, radios/espaciados y cards sin sombra |
| R004-13 | P1 | H1 «Gestión de Variantes y SKU», CTA «Nueva variante», códigos MK en título/copy y «Motor MK-004 v2.4 / Producción PE-CENTRAL / Admin Catálogo» sin contexto fuente | Component Spec microtexto S01; DESIGN §13; UXG-020/022 | Unificar «Variantes del producto» / «Crear variante»; eliminar identificadores y estados técnicos de la UI. Herencia se explica en lenguaje de negocio, sin endpoint/servicio visible |
| R004-14 | P0 | Buscadores y filtro sin etiqueta accesible; enlaces de fila repetidos sin identificación del SKU; sin estados anunciables, gestión de foco ni navegación comprobable | Component Spec C01/S01; DESIGN §12; UXG-021 | Añadir labels, nombres de acción por SKU, foco signal perceptible, región de actualización/error anunciable y confirmaciones accesibles |

## Cobertura observada

| Aspecto | Resultado | Evidencia / límite |
|---|---|---|
| Marca solicitada | Conforme al cambio solicitado | Logo compartido visible y original conservado |
| Contexto del padre | Parcial | Nombre y SKU base visibles; estado y precio sin fuente administrativa identificada |
| Identidad y estados de variantes | Parcial | Cinco SKU y combinaciones; BORRADOR/ACTIVA/INACTIVA diferenciados en texto. KPI y semántica de venta no son coherentes |
| Tabla sin selección masiva | Conforme en estructura | No hay checkboxes ni mutación masiva; columnas y contenido requieren ajuste |
| Filtro, paginación y navegación | No conforme | Filtro no afecta filas, paginación ausente y destinos no implementados |
| Preparación y físico | No conforme para consolidación | Preparación no publicada; lectura de perfil parcial sigue Q-04. No presentar «Falta peso» como response físico completo |
| Herencia sin editor de precios | Parcial | No hay entrada de precio propio; nota conceptual correcta, montos en filas sin fuente publicada |
| Desktop 1440 | Parcial | Sin overflow horizontal de página; tabla en región. Faltan controles/estados y normalización de tipografía/contraste |
| Accesibilidad y DS completos | No acreditados | Hallazgos R004-11/12/14; no se certifica cumplimiento integral por una captura |
| Normalización del prototipo | Pendiente | HTML con Tailwind CDN; no acredita React/TypeScript/Mantine, tema/componentes comunes ni ruta `/MK004/S01` |

## Alcance de la revisión y seguimiento

Se recibió S01 de las seis vistas de MK-004. S02/S03/S04/S05/S06 no se acreditan por esta entrega; tampoco se acredita la pantalla ancla S02 del plan. El formulario del producto simple de MK-003 y este listado de otro SKU base no constituyen un recorrido padre→variantes enlazado: deben definirse fixtures de padre con variantes e identidad compartida.

T02/T07 deben resolver los datos de preparación/padre antes de aprobar los estados dependientes. T30–T32/T40–T41 cubren contenido, acciones y estados; T50–T56, normalización; T60–T69, evidencia y verificación. No se modifica ninguna tarea a DONE ni se resuelven Q-01–Q-04 mediante esta revisión. El cambio aplicado en esta solicitud es la marca; los demás hallazgos quedan documentados para corrección.
