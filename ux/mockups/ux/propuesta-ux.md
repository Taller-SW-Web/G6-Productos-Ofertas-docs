# Propuesta UX transversal — Productos y Ofertas

**Versión:** 2.0 · **Fecha:** 2026-10-02 · **Responsable:** Leonardo Vera Rodríguez (`LeonardoVera`).

**Resultado:** tres propuestas finales consolidadas mediante revisión documental para el [issue #59](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/issues/59). Esta versión sustituye íntegramente el borrador. No acredita pruebas con usuarios, aprobación individual de mockups ni integración en `master`.

## 1. Alcance y fuentes

Experiencia del **Gestor Comercial**, en web desktop, con viewport canónico de revisión de 1440 px y operación mediante mouse y teclado. Las propuestas resuelven problemas de interacción; no son temas visuales ni layouts alternativos.

Se revisaron las 16 SPEC, HU y WF, los 15 FLOW disponibles, los tres borradores UX, el [índice de wireframes](../../wireframes/INDEX.md), [DESIGN de baja fidelidad](../../wireframes/DESIGN.md), [Contrato API](..\..\..\contratos\http\Contrato_Api.md), [kit de integración](..\..\..\contratos\http\kit-integracion.md) y los contratos [OpenAPI](..\..\..\contratos\http\openapi.yaml) y [AsyncAPI](..\..\..\contratos\eventos\asyncapi.yaml). OpenAPI declara HTTP 0.5.0 y AsyncAPI 0.4.0; sus versiones son independientes. No existe un FLOW-007 separado en esta revisión.

SPEC y HU determinan requisitos y reglas de negocio; WF y FLOW aportan estructura, navegación y alternativas; los contratos determinan los datos y operaciones publicados. La UX no crea capacidades ausentes. Una diferencia entre fuentes se registra y coordina con el responsable, sin decidir el negocio mediante un patrón visual.

Tokens, tipografía, colores, dimensiones y componentes de alta fidelidad corresponden al **#60**. Las reglas gráficas de los wireframes no sustituyen ese Design System. La guía temporal de laboratorios aporta contexto de trabajo y no es fuente normativa de esta propuesta.

## 2. Problemas transversales encontrados

| Problema | Evidencia del módulo | Consecuencia para el usuario |
|---|---|---|
| Confusión entre solicitud recibida y resultado confirmado | Lotes, exportaciones, preparación de producto, comprobación de bajas e inventario | Puede repetir envíos o actuar sobre resultados todavía no confirmados |
| Opciones de casos diferentes presentadas juntas | Producto simple/con variantes; promoción automática/con cupón; característica por tipo; precio producto/SKU | Debe interpretar campos irrelevantes y puede configurar valores incompatibles |
| Fallo local presentado como fallo total | Importación por dominios, preparación independiente, operaciones parciales, consultas por secciones | Pierde trabajo válido o no identifica qué necesita corregir |
| Patrones prescritos sin evaluar la tarea | Wizard para SEO, acciones masivas en Auditoría/Dashboard, skeleton universal, errores en toast | La interfaz añade pasos o acciones que el flujo y contrato no requieren |

Las candidatas del issue se confirman con límites explícitos. Cada una aborda un problema diferente: **estado**, **decisión** y **recuperación**.

<a id="ux-p01"></a>
## 3. UX-P01 — Carga contextual y progreso verificable

**Problema:** conocer qué información se está recuperando, qué solicitud se recibió y qué resultado está confirmado.

**Fundamento:** visibilidad del estado del sistema y feedback cercano a la acción. Referencias: [heurísticas de Nielsen](https://www.nngroup.com/articles/ten-usability-heuristics/) y [mensajes de estado accesibles](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html). El indicador refleja información disponible, sin simular avance ni duración.

**Aplicación:** skeleton en recuperación inicial estructurada; indicador localizado al guardar/consultar; mantener datos anteriores identificados al actualizar; estado persistente y consulta del resultado de trabajos asíncronos. Etapas o porcentajes solo si existen estados o contadores suficientes. Alta en 001, 003, 004, 008, 009, 010, 011, 013, 014, 015 y 016; en las restantes aplica feedback proporcional de lectura/guardado.

**No aplicar:** reemplazar un formulario completo por skeleton al guardar un campo; barras con avance ficticio; loader deliberadamente prolongado; spinner indefinido como único seguimiento; convertir confirmaciones síncronas en espera artificial.

**Representación en MK-001:**

```text
Importación recibida → Procesando → Resultado del lote
                                    Completado con observaciones
                                    Filas procesadas: [dato del lote]
                                    [Ver detalle] [Descargar reporte]
```

«Completado con observaciones» deriva de `COMPLETED` más errores de filas o reconciliación: no añade un enum. Una exportación habilita descarga después de finalizar, no al recibir el `202`.

**Ventajas:** ayuda a decidir cuándo esperar o continuar; hace visible la preparación independiente y reduce incentivos para repetir envíos por incertidumbre.

**Riesgos y trade-offs:** exige seguimiento; un skeleton excesivo oculta contexto; avance de filas no equivale necesariamente a avance de todos los dominios. Sin detalle suficiente se informa indisponibilidad, sin deducir rechazo o porcentaje.

**Derivación:** UXD-004, 007, 008 y 012; UXG-007 a 010, 012 y 020 a 022.

<a id="ux-p02"></a>
## 4. UX-P02 — Complejidad progresiva según la decisión

**Problema:** configurar reglas diferentes sin interpretar simultáneamente opciones irrelevantes.

**Fundamento:** revelación progresiva, agrupación lógica y reconocimiento en lugar de recuerdo. Referencias: [Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/) y [heurísticas de Nielsen](https://www.nngroup.com/articles/ten-usability-heuristics/). El sistema calcula información derivada autorizada, pero no elige reglas comerciales por el usuario.

**Aplicación:** campos condicionales por tipo/modalidad/alcance; información principal separada del detalle; etapas para decisiones realmente dependientes. Alta en 001, 002, 003, 005, 006, 007, 009, 010 y 013; Media en 004, 008, 012, 014, 015 y 016. La creación simple de marca (011) no necesita esta propuesta: un formulario breve y visible basta.

**No aplicar:** esconder requisitos de activación; wizard obligatorio para SEO, marca o creación simple de tipo; error dentro de sección cerrada; selección automática de variante, criterio de superioridad o política de restitución.

**Representación en MK-009:**

```text
Nombre: [________________]
Tipo:   [Número ▼]
Unidad: [________________]  ← aparece para NUMERO

LISTA revela gestión de valores.
En edición el tipo existente no puede cambiarse.
```

En MK-003 se distinguen requisitos para **guardar borrador** de requisitos adicionales para **activar**. En MK-007 el criterio de superioridad se solicita explícitamente y no se infiere del precio.

**Ventajas:** facilita comprender la decisión actual, reduce campos incompatibles y mantiene simples las tareas breves.

**Riesgos y trade-offs:** opciones ocultas pueden ser difíciles de descubrir; cambiar modalidad puede invalidar entradas. Explicar qué cambia, conservar valores compatibles, advertir antes de descartar y abrir las secciones con errores.

**Derivación:** UXD-001, 002, 003, 006 y 012; UXG-001 a 006 y 020 a 022.

<a id="ux-p03"></a>
## 5. UX-P03 — Recuperación explícita y conservación de lo confirmado

**Problema:** un rechazo, conflicto o fallo parcial no debe borrar información válida ni habilitar una operación insegura.

**Fundamento:** reconocimiento/corrección de errores, control del usuario y estados parciales. Referencias: [mensajes de error](https://www.nngroup.com/articles/error-message-guidelines/) y [heurísticas de Nielsen](https://www.nngroup.com/articles/ten-usability-heuristics/). La degradación segura conserva lo consultable y confirmado; bloquea la acción que necesita una validación faltante.

**Aplicación:** error junto al campo/sección; resultado parcial persistente; conservar filtros y entradas; recuperar según la capacidad contractual. Alta en 001, 003, 004, 008, 009, 010, 011, 012, 013, 014, 015 y 016; Media en 002, 005, 006 y 007, principalmente por validaciones y dependencias de consulta.

**No aplicar:** repetir escrituras con resultado desconocido; dar de baja por falta de respuesta; sustituir información fallida por cero; ofrecer una recuperación no publicada; activar entidades con requisitos obligatorios incompletos.

**Representación en MK-003:**

```text
Borrador guardado
Precio:     preparación confirmada
Inventario: estado de preparación no disponible

El borrador se conserva. Su activación aún no puede confirmarse.
[Consultar nuevamente]  ← si existe consulta disponible
```

Los estados requieren evidencia. Un booleano `false` no distingue por sí solo «pendiente» de «rechazado». Un conflicto de slug en MK-008 exige obtener y confirmar otra propuesta, sin renombrar silenciosamente.

**Ventajas:** conserva trabajo, explica el siguiente paso y muestra éxitos parciales sin prometer una transacción global.

**Riesgos y trade-offs:** exige más estados y mensajes específicos; información antigua sin fecha puede parecer vigente; puede no existir recuperación automática. Reconocer esos límites y ofrecer solo acciones disponibles.

**Derivación:** UXD-001, 005, 007, 008, 009, 010, 011 y 012; UXG-002 y 009 a 022.

## 6. Matriz de aplicabilidad

**Alta:** afecta una tarea principal o resultado crítico. **Media:** mejora consultas, detalle o validación sin exigir estructura nueva. **No aplicable:** no existe una complejidad que justifique esa propuesta en la tarea revisada. Ninguna calificación obliga a usar todos sus patrones.

| WF / MK | UX-P01 | UX-P02 | UX-P03 | Evidencia y aplicación concreta |
|---|---|---|---|---|
| 001 Carga/exportación masiva | Alta | Alta | Alta | Etapas y resultado por fila/dominio; distinguir reconciliación; reanudar el mismo lote cuando procede. Exportación de catálogo activo sin filtros inventados |
| 002 Combos | Media | Alta | Media | Configurar SKUs/cantidades y comparar precio; disponibilidad estimada no reserva stock. Conservar componentes válidos ante rechazo |
| 003 Productos | Alta | Alta | Alta | Borrador y activación tienen requisitos diferentes; preparación independiente de Pricing/Inventario. Conservar borrador y mostrar solo estados conocidos |
| 004 Variantes/SKUs | Alta | Media | Alta | Atributos/datos físicos por variante e inicialización de inventario. No exigir precio propio ni stock del padre |
| 005 Cupones | Media | Alta | Media | Límites opcionales y política de restitución explícitos; «Sin límite» no es cero. No consumir/restaurar usos desde la administración |
| 006 Promociones | Media | Alta | Media | Modalidad, beneficio y alcance condicionales; preservar entradas al corregir y respetar restricciones de cambio de modalidad |
| 007 Cross-sell/upselling | Media | Alta | Media | Campos por tipo de regla y criterio explícito de superioridad; errores corregibles sin inferir criterio por precio |
| 008 Categorías | Alta | Media | Alta | Resolver/confirmar slug, conflicto concurrente y comprobación de uso antes de baja; silencio no confirma baja |
| 009 Características | Alta | Alta | Alta | TEXTO/NUMERO/LISTA y tipo inmutable; baja de valor LISTA con comprobación distinta de baja síncrona de característica |
| 010 Tipos/características | Alta | Alta | Alta | Asociaciones obligatorias/opcionales, límite configurable, esquema y comprobación de uso; conservar ante conflicto/inconclusión |
| 011 Marcas | Alta | No aplicable | Alta | Formulario corto; baja con comprobación de uso y duplicados entre inactivas. Crear/editar/reactivar no requieren la misma espera |
| 012 SEO/metadatos | Media | Media | Alta | Formulario e historial; longitudes con avisos no bloqueantes. Conflicto manual conserva datos y no renombra sin consentimiento |
| 013 Precios | Alta | Alta | Alta | Producto/SKU, canal, programación, conflicto de versión/vigencia e importación parcial; sin reanudación de MK-001 |
| 014 Auditoría | Alta | Media | Alta | Filtros/detalle de lectura; exportación asíncrona CSV/PDF y límites; conservar filtros, ausencia de oferta no es cero |
| 015 Stock | Alta | Media | Alta | SKU/ubicación y recepción parcial/final; pendiente distinto de recibido, faltantes no acreditados; sin comandos internos de reserva/merma |
| 016 Dashboard | Alta | Media | Alta | Filtros/ubicación/detalle; refresco por sección si hay consultas independientes; indisponibilidad distinta de cero y enlace a MK-015 |

La selección es cualitativa y documental; no constituye una medición de mejoras ni un ranking estadístico. P01 explica el estado, P02 organiza la decisión y P03 protege la recuperación; se complementan en una misma pantalla.

## 7. Trazabilidad de las 16 funcionalidades

Cada fila anterior se verificó con las siguientes fuentes. El owner mantiene referencias a apartados y estados concretos en su `component-spec.md`.

| MK | SPEC | HU | WF | FLOW |
|---|---|---|---|---|
| 001 | [SPEC-001](..\..\..\requisitos\specs\SPEC-001-carga-exportacion-masiva-productos.md) | [HU-001](..\..\..\requisitos\hu\HU-001-carga-exportacion-masiva-productos.md) | [WF-001](../../wireframes/flows/WF-001-carga-exportacion-masiva-productos.md) | [FLOW-001](..\..\..\requisitos\flujos\FLOW-001-carga-exportacion-masiva-productos.md) |
| 002 | [SPEC-002](..\..\..\requisitos\specs\SPEC-002-gestion-combos-productos.md) | [HU-002](..\..\..\requisitos\hu\HU-002-gestion-combos-productos.md) | [WF-002](../../wireframes/flows/WF-002-gestion-combos-productos.md) | [FLOW-002](..\..\..\requisitos\flujos\FLOW-002-gestion-combos-productos.md) |
| 003 | [SPEC-003](..\..\..\requisitos\specs\SPEC-003-gestion-productos-crud.md) | [HU-003](..\..\..\requisitos\hu\HU-003-gestion-productos-crud.md) | [WF-003](../../wireframes/flows/WF-003-gestion-productos-crud.md) | [FLOW-003](..\..\..\requisitos\flujos\FLOW-003-gestion-productos-crud.md) |
| 004 | [SPEC-004](..\..\..\requisitos\specs\SPEC-004-gestion-variantes-skus.md) | [HU-004](..\..\..\requisitos\hu\HU-004-gestion-variantes-skus.md) | [WF-004](../../wireframes/flows/WF-004-gestion-variantes-skus.md) | [FLOW-004](..\..\..\requisitos\flujos\FLOW-004-gestion-variantes-skus.md) |
| 005 | [SPEC-005](..\..\..\requisitos\specs\SPEC-005-gestion-cupones-descuento.md) | [HU-005](..\..\..\requisitos\hu\HU-005-gestion-cupones-descuento.md) | [WF-005](../../wireframes/flows/WF-005-gestion-cupones-descuento.md) | [FLOW-005](..\..\..\requisitos\flujos\FLOW-005-gestion-cupones-descuento.md) |
| 006 | [SPEC-006](..\..\..\requisitos\specs\SPEC-006-gestion-ofertas-promociones.md) | [HU-006](..\..\..\requisitos\hu\HU-006-gestion-ofertas-promociones.md) | [WF-006](../../wireframes/flows/WF-006-gestion-ofertas-promociones.md) | [FLOW-006](..\..\..\requisitos\flujos\FLOW-006-gestion-ofertas-promociones.md) |
| 007 | [SPEC-007](..\..\..\requisitos\specs\SPEC-007-reglas-venta-cruzada-upselling.md) | [HU-007](..\..\..\requisitos\hu\HU-007-reglas-venta-cruzada-upselling.md) | [WF-007](../../wireframes/flows/WF-007-reglas-venta-cruzada-upselling.md) | No publicado |
| 008 | [SPEC-008](..\..\..\requisitos\specs\SPEC-008-gestion-categorias.md) | [HU-008](..\..\..\requisitos\hu\HU-008-gestion-categorias.md) | [WF-008](../../wireframes/flows/WF-008-gestion-categorias.md) | [FLOW-008](..\..\..\requisitos\flujos\FLOW-008-gestion-categorias.md) |
| 009 | [SPEC-009](..\..\..\requisitos\specs\SPEC-009-gestion-caracteristicas.md) | [HU-009](..\..\..\requisitos\hu\HU-009-gestion-caracteristicas.md) | [WF-009](../../wireframes/flows/WF-009-gestion-caracteristicas.md) | [FLOW-009](..\..\..\requisitos\flujos\FLOW-009-gestion-caracteristicas.md) |
| 010 | [SPEC-010](..\..\..\requisitos\specs\SPEC-010-asociacion-tipo-producto-caracteristica.md) | [HU-010](..\..\..\requisitos\hu\HU-010-asociacion-tipo-producto-caracteristica.md) | [WF-010](../../wireframes/flows/WF-010-asociacion-tipo-producto-caracteristica.md) | [FLOW-010](..\..\..\requisitos\flujos\FLOW-010-asociacion-tipo-producto-caracteristica.md) |
| 011 | [SPEC-011](..\..\..\requisitos\specs\SPEC-011-gestion-marcas.md) | [HU-011](..\..\..\requisitos\hu\HU-011-gestion-marcas.md) | [WF-011](../../wireframes/flows/WF-011-gestion-marcas.md) | [FLOW-011](..\..\..\requisitos\flujos\FLOW-011-gestion-marcas.md) |
| 012 | [SPEC-012](..\..\..\requisitos\specs\SPEC-012-seo-metadatos.md) | [HU-012](..\..\..\requisitos\hu\HU-012-seo-metadatos.md) | [WF-012](../../wireframes/flows/WF-012-seo-metadatos.md) | [FLOW-012](..\..\..\requisitos\flujos\FLOW-012-seo-metadatos.md) |
| 013 | [SPEC-013](..\..\..\requisitos\specs\SPEC-013-gestion-precios-individuales-masivos.md) | [HU-013](..\..\..\requisitos\hu\HU-013-gestion-precios-individuales-masivos.md) | [WF-013](../../wireframes/flows/WF-013-gestion-precios-individuales-masivos.md) | [FLOW-013](..\..\..\requisitos\flujos\FLOW-013-gestion-precios-individuales-masivos.md) |
| 014 | [SPEC-014](..\..\..\requisitos\specs\SPEC-014-historial-auditoria-precios.md) | [HU-014](..\..\..\requisitos\hu\HU-014-historial-auditoria-precios.md) | [WF-014](../../wireframes/flows/WF-014-historial-auditoria-precios.md) | [FLOW-014](..\..\..\requisitos\flujos\FLOW-014-historial-auditoria-precios.md) |
| 015 | [SPEC-015](..\..\..\requisitos\specs\SPEC-015-control-stock-disponibilidad.md) | [HU-015](..\..\..\requisitos\hu\HU-015-control-stock-disponibilidad.md) | [WF-015](../../wireframes/flows/WF-015-control-stock-disponibilidad.md) | [FLOW-015](..\..\..\requisitos\flujos\FLOW-015-control-stock-disponibilidad.md) |
| 016 | [SPEC-016](..\..\..\requisitos\specs\SPEC-016-dashboard-alertas-stock.md) | [HU-016](..\..\..\requisitos\hu\HU-016-dashboard-alertas-stock.md) | [WF-016](../../wireframes/flows/WF-016-dashboard-alertas-stock.md) | [FLOW-016](..\..\..\requisitos\flujos\FLOW-016-dashboard-alertas-stock.md) |

## 8. Evaluación de los borradores sustituidos

| Elemento previo | Resultado | Regla vigente |
|---|---|---|
| «Operativo y Denso», «Guiado por Wizards», «Modular con Dashboard/Paneles» como propuestas | Reinterpretar | Patrones posibles dentro de P01–P03; dejan de ser alternativas UX vigentes |
| Drawer obligatorio para 003/004/008/009/011 y anchos fijos | Modificar | Panel contextual para tarea breve; vista completa para compleja. Dimensiones en #60 |
| Wizard obligatorio para 001/002/005/006/007/010/012 | Retirar obligatoriedad | Etapas solo con dependencia real; SEO, marca y creación simple de tipo no necesitan pasos artificiales |
| Densidad, checkboxes y acciones masivas universales | Modificar | Tabla legible; selección/acciones según capacidad funcional. Auditoría y Dashboard en lectura |
| Skeleton universal y prohibición de spinner | Modificar | Skeleton inicial, feedback localizado y seguimiento persistente según tarea |
| Toast como canal principal y duración universal | Modificar | Complemento de confirmación simple; errores/resultados parciales junto a la tarea y persistentes |
| Debounce fijo de 300 ms y validación universal al blur | Modificar | Búsqueda según contrato/coste; validación proporcional al campo e intento de guardar/continuar |
| Vacíos, conservación del contexto y lenguaje de negocio | Conservar y precisar | Vacío, filtro sin coincidencias, ausencia e indisponibilidad distintos; acciones permitidas |
| Gris, ausencia de sombras y tamaños de baja fidelidad | Reubicar | Permanecen en wireframes; #60 define alta fidelidad |
| Accesibilidad y consistencia | Conservar | Etiquetas, teclado, foco y estados comprensibles, sin depender solo de color |

UXD-001 a UXD-006 conservan sus identificadores **con contenido revisado**; se agregan UXD-007 a UXD-012. Una referencia antigua por ID no acredita cumplimiento: se consume esta versión.

## 9. Propuesta UX Integral Adoptada

**Operar con estado verificable, complejidad pertinente y recuperación segura.**

La pantalla conserva el contexto y presenta primero la decisión necesaria. Cada acción comunica feedback en su alcance. Lo aceptado permanece pendiente hasta confirmación. Ante fallos locales, lo confirmado sigue visible y la recuperación respeta el contrato. No se habilitan cambios cuya seguridad depende de información faltante.

La cadena es **fuente → problema → propuesta → UXD → UXG → estado/pantalla de MK**. [UX Decisions](ux-decisions.md) justifica los patrones; [UX Guidelines](ux-guidelines.md) define su verificación. Una excepción local se registra como `LUX-XX`, sin alterar negocio ni introducir una UX transversal alternativa.

## 10. Hallazgos de fuentes y límites

No dejan pendiente la selección UX. Requieren alineación funcional/contractual antes de aprobar los estados afectados; un fixture ilustrativo no acredita capacidades del backend.

| Hallazgo | Fuentes / coordinación | Tratamiento y condición del MK |
|---|---|---|
| Preparación no descrita completamente | SPEC-003/004 y `ProductoResumen`/`Variante`; Poma + Taco/integración | Booleanos opcionales no distinguen pendiente/rechazo/causa; Variante no publica detalle equivalente. No inventar estados ni reintento de inicialización; identificar fuente antes de especificarlos |
| Pantalla de prevalidación no equivale a endpoint | WF-001 y rutas de importación; Castilla + integración | Validar formato local no acredita validación completa de negocio previa. No inventar `/prevalidar` para Catálogo; Pricing sí tiene prevalidación propia |
| FLOW-007 ausente y cobertura administrativa limitada en 006 | SPEC/HU/WF-007 y WF/FLOW-006; Cueva | Trazar configuración a SPEC/HU y completar navegación local; no incorporar checkout como formulario administrativo |
| Diagrama de baja de tipo ambiguo | FLOW-010 §4.5 frente a texto y SPEC/HU-010; Lopez | Exigir comprobación satisfactoria. Rechazo/sin respuesta no termina en baja confirmada; alinear el recorrido antes de aprobar ese estado |
| Dashboard sin todos los saldos requeridos | SPEC/HU/WF-016 frente a `DashboardInventario`; Taco + integración | No declara total bloqueado ni bloqueado por ubicación. No reemplazar por cero ni derivar de otros totales; acordar fuente antes de aprobar tarjetas numéricas |
| Decisiones de HTTP 0.5.0 abiertas | Extensiones de SPEC-003/007/015, Contrato API y kit: D-CAT-01 a 06, D-REC-01/02 y D-INV-01; owners + integración | No decidir elegibilidad comercial, agregación de precio/disponibilidad con variantes, selección de variante ni agregado público multiubicación por UX; mantener detalle de backoffice y reconocer ausencia |

El owner registra fuente, responsable y estado afectado. La aprobación de ese estado espera la alineación; estos documentos no modifican SPEC ni API para satisfacer preferencias de interfaz.

## 11. Validación y habilitación

El análisis confirma **UX-P01, UX-P02 y UX-P03 finales**, con los límites descritos. Los patrones previos fueron reevaluados; no quedan decisiones UX transversales por seleccionar.

- [x] Análisis de las 16 funcionalidades y matriz.
- [x] Problemas distintos, fundamento y evidencia transversal.
- [x] Usos, no usos, ejemplos, ventajas y riesgos por propuesta.
- [x] Sustitución de borradores y coherencia propuesta → decisiones → reglas.
- [x] Reglas UX compatibles con requisitos y capacidades publicadas; diferencias de fuentes registradas sin inventar soluciones.
- [x] Capa UX consolidada para documentación funcional.
- [ ] Alineación de los hallazgos funcionales/contractuales que afectan estados exigidos, antes de declarar cumplido el gate formal.

**Gate UX de #59:** las propuestas, decisiones y reglas están consolidadas en `vera`, pero la habilitación formal queda pendiente de alinear los hallazgos de fuentes y revisar/integrar el cambio. En particular, no se declara ausencia de contradicciones mientras el recorrido de FLOW-010 siga siendo ambiguo o falten datos contractuales para estados exigidos de MK-016. No hay otra propuesta UX por seleccionar. Esto no declara completado #60 ni aprobado un mockup, y tampoco cambia el estado del issue en GitHub.

Una vez alineadas las fuentes, cumplido el gate y adoptado el cambio en la base compartida, cada owner queda habilitado para iniciar **`component-spec.md` → `plan.md` → `tasks.md`**, consumiendo SPEC, HU, WF, FLOW disponible, contratos, Design System y estos tres documentos. El gate transversal se completa con #60 y las fuentes integradas en la base compartida; el #61 organiza la ejecución general de los mockups. El #66 corresponde únicamente a MK-013 y MK-014 de Leonardo Vera, quien no asume los documentos funcionales de otros owners.

La validación posterior requiere evidencia de los estados aplicables: carga/actualización, error corregible, fallo parcial, aceptación sin confirmación, conflictos y teclado. Una futura prueba con usuarios puede medir comprensión y recuperación; aquí no se atribuyen mejoras empíricas no medidas.

## 12. Referencias de apoyo

- [Nielsen Norman Group — 10 Usability Heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/).
- [Nielsen Norman Group — Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/).
- [Nielsen Norman Group — Error Message Guidelines](https://www.nngroup.com/articles/error-message-guidelines/).
- [W3C — Understanding Status Messages, WCAG 2.2](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html).
- [build-for-good-ux-skill](https://github.com/alper-dev/build-for-good-ux-skill): recopilación secundaria práctica; no sustituye fuentes funcionales ni se incorpora como instrucciones del módulo.
