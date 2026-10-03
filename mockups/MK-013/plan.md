# MK-013 — Plan de construcción

## 1. Identificación

**Funcionalidad:** gestión de precios individuales y masivos. **Owner:** Leonardo Vera Rodríguez. **Rama:** `vera`. **Issue:** #66, coordinado por #61. **Versión:** 1.0.0, 2026-10-02. **Estado:** En revisión; ejecución no iniciada.

Entrada rectora: [component-spec.md](component-spec.md), especialmente inventario §4, contratos §6, pantallas §9, fixtures §12 y hallazgos §13. Un cambio en esa entrada obliga a actualizar este plan y [tasks.md](tasks.md), sin rediseñar el negocio desde el código.

## 2. Contrato de ejecución

| Elemento | Compromiso |
|---|---|
| Entradas | SPEC/HU/WF/FLOW-013 y contratos referenciados por el component-spec; UX 2.0 y DESIGN 1.0.0; especificación local revisada |
| Salidas futuras | Seis pantallas directas, componentes/fixtures tipados, recorridos verificables, evidencias, revisión UX, Figma fiel y `validation-report.md` |
| Restricciones | React + TypeScript + Mantine + Tabler; tema central; solo web desktop. Ningún comando de inicialización manual, cancelación de programación, reanudación de Pricing o rollback entre dominios |
| Condición de parada | Contradicción funcional o dato requerido ausente: registrar hallazgo, bloquear tarea dependiente, continuar únicamente trabajo independiente. No completar capacidad mediante fixtures inventados |
| Cambios de fuentes | Owner propone corrección y revisión especializada según gobernanza; esta creación documental no modifica fuentes de negocio/API |
| Aprobación | Ni generación de archivos ni pruebas UI autorizan pasar automáticamente a Figma o cerrar #66 |

El `component-spec` está **En revisión**, no aprobado. Q-013-01 bloquea contrato/fixtures del contenido del archivo; Q-013-02 bloquea decidir cuándo se confirma una prevalidación con errores. Se puede preparar layout y representación de DTOs conocidos, pero no declarar S04 funcionalmente validada mientras esos hallazgos estén abiertos.

## 3. Entradas obligatorias y readiness

| Entrada | Disponible | Requisito antes del trabajo dependiente |
|---|---|---|
| [SPEC](../../specs/SPEC-013-gestion-precios-individuales-masivos.md), [HU](../../hu/HU-013-gestion-precios-individuales-masivos.md) | Sí | Confirmar versión/criterios al iniciar; no asumir aprobación nueva por presencia |
| [WF](../../wireframes/flows/WF-013-gestion-precios-individuales-masivos.md), [FLOW](../../flujos/FLOW-013-gestion-precios-individuales-masivos.md) | Sí | Mantener seis pantallas y rutas; inicialización es backend, no pantalla nueva |
| [OpenAPI](../../api/openapi.yaml), [AsyncAPI](../../asyncapi/asyncapi.yaml), [Contrato API](../../Contrato_Api.md) | Sí | Resolver Q-013-01/02 y distinguir stable/provisional-internal; aliases de paginación cuentan como parámetros |
| [Propuesta UX](../ux/propuesta-ux.md), [Decisions](../ux/ux-decisions.md), [Guidelines](../ux/ux-guidelines.md), [DESIGN](../DESIGN.md) | Sí; coincidentes con origin/master en base ea9c4f1 | Consumir versiones vigentes del gate #59 + #60; no alterar UX transversal localmente |
| [Component Spec](component-spec.md) | Redactado, En revisión | Resolver hallazgos afectados y registrar revisión antes de aprobar implementación completa |
| [Pipeline](../README.md), [Prototipo](../prototipo/README.md), [Gobernanza](../../EQUIPO_Y_RESPONSABILIDADES.md) | Sí | Separar autovalidación del owner de revisión transversal y evidenciar ambas |
| [Plantilla Plan](../_plantillas/mockup/plan.template.md), [Tasks](../_plantillas/mockup/tasks.template.md), [Validation Report](../_plantillas/mockup/validation-report.template.md) | Sí | Instanciar reporte solo con evidencia real; no copiar checks de aprobación |

## 4. Objetivo constructivo y pantalla ancla

La pantalla ancla es **MK-013-S01**: fija shell, contexto de producto/SKU, moneda, origen, fallback de canal, card/tabla y acciones. Debe mostrar correctamente simple, heredado y override antes de extender formularios. Así S02/S03/S06 consumen el mismo contexto sin deducir permisos, precios o versiones de otra entidad.

| Orden | Pantalla | Dependencia y resultado |
|---|---|---|
| 1 | S01 | Tema, fixtures de consulta y selector contextual; origen/alcance inequívocos |
| 2 | S02 | S01 y lectura del objetivo de escritura; edición, oferta y comparación de conflicto |
| 3 | S03 | Contexto S01; lista paginada y creación futura independiente de PATCH |
| 4 | S06 | Consulta SKU `at`; histórico resuelto sin timeline inventado |
| 5 | S04 | Archivo/política y respuestas de prevalidación; contrato completo requiere Q-013-01/02 resueltos |
| 6 | S05 | Referencia batchId conocida; admisión/seguimiento/resultado y reporte, sin reanudación |

S05 puede desarrollarse con respuestas publicadas mientras se resuelve el contenido de archivo; la navegación de importación completa permanece pendiente. Todas las pantallas tienen prioridad P0, aunque el orden constructivo difiera de su numeración.

## 5. Estrategia técnica

1. Verificar fuentes/gate y registrar resolución de Q-013-01/02 con cambio revisado. Actualizar spec y tareas afectadas.
2. Inspeccionar `mockups/prototipo/` antes de crear infraestructura: actualmente solo contiene README. Si el equipo ya aportó runtime/tema, reutilizarlo; de lo contrario construir una base común mínima con el stack acordado, sin fijar versiones sin revisar compatibilidad.
3. Separar DTOs contractuales, contexto de Catálogo y estado de presentación. Crear fixtures FX-013-01 a 18 deterministas, tipados y sin datos reales. Materializar bytes del archivo únicamente tras resolver su contrato.
4. Configurar un resolver de rutas `/MK013/S01` a `/MK013/S06`; `?fixture=` selecciona estados de revisión, sin hardcodear hostname/puerto. Recarga directa inicializa contexto válido, sin ejecutar mutaciones reales.
5. Construir S01 ancla, reutilizar componentes DS y crear C01–C07 solo para composición específica de Pricing. Extender pantallas en orden de §4, implementando errores y recuperación con la misma importancia que el caso feliz.
6. Simular adaptadores HTTP conforme a respuestas contractuales; una mutación local del fixture no acredita publicación de eventos ni persistencia real. Evitar waits artificiales y reenvío automático tras timeout.
7. Normalizar tema/estados, medir desktop, recorrer teclado, verificar trazabilidad y registrar autovalidación. Mantener código y evidencia vinculados a una revisión Git concreta.
8. Realizar revisión UX transversal posterior; corregir hallazgos y obtener APROBADO PARA FIGMA explícito. Recién entonces trasladar versión a Figma, validar fidelidad y emitir reporte final con enlaces reales.

## 6. Reutilización y organización prevista

| Ubicación futura | Contenido |
|---|---|
| `mockups/prototipo/src/tema/` | Tokens de DESIGN, Oswald/Inter, variantes Mantine y estados comunes; un tema para el módulo |
| `mockups/prototipo/src/componentes/` | Shell, botones, campos, tabla, diálogos, feedback y patrones DS compartidos |
| `mockups/prototipo/src/pantallas/MK013/` | Seis vistas, C01–C07, tipos/adaptadores/fixtures de Pricing y mapeo de rutas |

No duplicar Shell/Button/Alert para alterar colores de MK-013. Si MK-014 necesita el mismo estado genérico de seguimiento, reutilizar presentación DS sin mezclar DTOs de importación y exportación. Una base creada con Stitch es un borrador: debe normalizarse contra spec/DESIGN; la herramienta no otorga aprobación ni completa capacidades.

## 7. Estados, fixtures y verificaciones

| Área | Fixtures prioritarios | Evidencia exigida |
|---|---|---|
| Resolución/ancla | FX-013-01 a 05 | Simple/heredado/override/fallback; moneda y origen reales; ausencia distinta de error |
| Escritura y conflicto | FX-013-06 a 08,10,17,18 | Propuesta conservada, motivo/importe inválido no enviado, versión releída y confirmación explícita |
| Programación/histórico | FX-013-09,10,16 | 201 no cambia vigente; intervalos/páginas; consulta as-of y 404 legibles |
| Importación | FX-013-11 a 15 | Prevalidación y política respaldadas, 202 distinto de terminal, parcial y CSV; dependencias Q-013 abiertas hasta resolución |
| Seguridad/timeout | FX-013-17 | Ninguna mutación sin permiso ni escritura duplicada por respuesta desconocida |
| Navegación/desktop | Todas; FX-013-18 | Seis rutas directas, retorno contextual, teclado/foco y 1440 px sin overflow involuntario |

Capturas por pantalla/estado con revisión, ruta, fixture, viewport y resultado; registros de interacción para conflictos y asincronía. Pruebas necesarias del prototipo se concentran en decisiones sensibles (versión, oferta, prevalidación, parcial, navegación), sin confundirlas con validación backend postcommit.

## 8. Riesgos y mitigación

| Riesgo | Mitigación / límite |
|---|---|
| Archivo y política parcial incompletos | T06 BLOCKED; cerrar Q-013-01/02 antes de parser/confirmación de errores y de gate funcional |
| Precio heredado interpretado como override o canal exclusivo | Verificar origen y channel_id efectivo en S01; releer objetivo de escritura en S02 |
| Conflicto resuelto sobrescribiendo versión | Comparación conserva propuesta; nueva intención explícita y versión de lectura correcta |
| Batch parcial presentado como transacción general | Panel/filas confirmadas, recuperación mediante archivo corregido/nuevo intento; no rollback/reanudación |
| POST ambiguo sin referencia | Estado desconocido sin reenvío automático; consulta solo con referencia/capacidad disponible |
| Figma adelantado o autoaprobación de documentos | Separar fases/evidencias. Owner y revisor transversal son Leonardo según gobernanza; no inventar revisor alternativo |

## 9. Fases, responsables y Quality Gates

| Fase / gate | Responsable | Criterio de salida y evidencia |
|---|---|---|
| A — Preparación funcional | Leonardo, owner; revisión técnica de contrato por Miguel cuando corresponda | Fuentes revisadas, hallazgos resueltos, spec/plan/tasks consistentes; no pasar S04 con Q abiertos |
| B — Construcción e interacción UX | Leonardo, owner | Seis pantallas/rutas/fixtures; interacciones acordes a fuente y UX, sin operaciones inventadas |
| C — Normalización UI | Leonardo, owner | Tema central, DS, Mantine/Tabler, copy y estados; build/typecheck del entorno que se implemente |
| D — Desktop y autovalidación | Leonardo, owner | Evidencia 1440 px, teclado, estados y trazabilidad; ningún bloqueante abierto |
| E — Revisión transversal | Leonardo, rol UI/UX, posterior y registrada separadamente | Hallazgos corregidos, decisión humana explícita APROBADO PARA FIGMA sobre revisión identificada |
| F — Figma y cierre de validación | Leonardo, owner y revisión UX conforme a gobernanza | Frames de seis pantallas/estados exigidos, enlace real, comparación de fidelidad y `validation-report.md` APROBADO |

Los gates están **pendientes**. Que Leonardo asuma ambos roles no elimina ninguna etapa ni autoriza al generador a firmar por él. Un cambio posterior a la versión aprobada requiere revisar impacto y renovar evidencias/gates afectados. #66 no se cierra por terminar este plan; requiere el pipeline de ambos MK.
