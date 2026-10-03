# MK-013 — Tareas de construcción y verificación

## 1. Control de ejecución

**Owner:** Leonardo Vera Rodríguez. **Rama:** `vera`. **Issue:** #66, dentro de #61. **Versión:** 1.0.0, 2026-10-02. **Estado:** planificación En revisión; prototipo y evidencias aún no creados.

Entradas rectoras: [Component Spec](component-spec.md) y [Plan](plan.md). Normas comunes: [DESIGN](../DESIGN.md), [UX Guidelines](../ux/ux-guidelines.md), [pipeline](../README.md) y [plantilla Tasks](../_plantillas/mockup/tasks.template.md).

Estados permitidos: `TODO`, `DOING`, `BLOCKED`, `REVIEW`, `DONE`. Prioridad P0 para todas las tareas de esta entrega. Una tarea solo pasa a DONE con revisión Git, salida existente y resultado observado. No confundir un fixture descrito con un fixture implementado. T06 está BLOCKED por Q-013-01/02; las tareas independientes pueden avanzar, pero no se habilita confirmación con errores ni gate funcional global sin resolverlos.

Cada fila establece Entrada → Acción → Salida → Verificación. Las dependencias son IDs abreviados del mismo MK; el ID completo es `MK-013-TXX`. Cualquier tarea afectada por un nuevo hallazgo pasa a BLOCKED con referencia/owner, sin modificar fuentes ajenas ni inventar capacidades.

## 2. Preparación

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-013-T01 · TODO · — | Fuentes de spec §2 y plan §3 | Confirmar revisión de fuentes y disponibilidad del gate #59/#60 en base compartida | Registro de versiones/revisión y cambios relevantes desde ea9c4f1 | Referencias existentes; identificar diferencias de fuente antes de ejecutar, sin asumir aprobación por presencia |
| MK-013-T02 · TODO · T01 | Spec, plan, tasks y gobernanza | Revisar inventario, props, LUX y criterios del alcance contractual conocido | Revisión documental registrada, hallazgos por tarea y alcance aún bloqueado | Seis pantallas/rutas, 18 fixtures y cobertura HU identificados; Q-013-01/02 no se marcan resueltos sin fuente |
| MK-013-T03 · TODO · T01 | Prototipo README y DESIGN | Inspeccionar/reutilizar base común o preparar runtime React/TS/Mantine/Tabler mínimo | Entorno ejecutable y comando de arranque documentado, tema compartido inicial | Arranque/build/typecheck reales; sin aplicación/tema duplicados si ya existe base del equipo |
| MK-013-T04 · TODO · T02,T03 | Spec §§6,8,12 | Crear DTOs y fixtures de respuestas/contexto FX-013-01 a 18, manteniendo escenario de archivo sin bytes inventados | Datos tipados, reloj fijo y adaptador fixture sin red productiva | Payloads respetan schemas/nulos/required; contexto Catálogo separado; Q-013-01/02 bloquean únicamente variantes pendientes |
| MK-013-T05 · TODO · T03,T04 | Inventario spec §4 | Registrar seis rutas y selector fixture de revisión | Acceso directo S01–S06 y fallback explicativo ante contexto inválido | Abrir/recargar cada ruta sin recorrido previo, fixture determinista, sin dominio/puerto fijo ni mutación real |
| MK-013-T06 · BLOCKED · T01 | Q-013-01/02, multipart y PrevalidacionPrecio | Obtener definición revisada de contenido del archivo y política de admisión con errores; actualizar cadena documental | Referencia de contrato resuelto, spec/plan/tasks y fixtures de archivo coherentes | Formato/cabeceras/validaciones por fila y criterio allow_partial tienen fuente; nada se deduce de defaults o de valid=false |

## 3. Pantallas y comportamiento

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-013-T10 · TODO · T02,T04,T05 | S01, C01, FX-013-01 a 04 | Construir ancla, selección explícita y consulta/resolución de precio | S01 con precio, moneda, origen y alcance efectivo; acciones navegables | Simple/base, herencia, override y fallback se identifican desde payload; no elegir primera variante ni ofrecer reinicialización |
| MK-013-T11 · TODO · T10 | S01, FX-013-05 | Añadir carga, 404, 503 y refresco con última consulta | Estados localizados y acciones seguras de consulta | Ausencia de precio distinta de error; dato antiguo marcado, no cero ni estado preparado inventado |
| MK-013-T12 · TODO · T10 | S02, C02, PrecioUpdateRequest, FX-013-06/07 | Construir edición por objetivo con campos condicionales y confirmación de alcance | Formulario y adaptador PATCH del producto/SKU correcto | Motivo/moneda/version requeridos; oferta CONSERVAR/ESTABLECER/ELIMINAR sin cero ficticio; 200 confirma resultado |
| MK-013-T13 · TODO · T12 | C03, FX-013-08/10/17/18 | Implementar conflicto, rechazo, salida con cambios y escritura desconocida | Comparación leída/actual/propuesta y recuperación permitida | Versión 4→409→lectura 5 exige revisión/confirmación; borrador persiste; sin reenvío automático ni sobrescritura silenciosa |
| MK-013-T14 · TODO · T10 | S03, C04, schemas programaciones, FX-013-09 | Construir lista paginada y creación de vigencia | S03 con intervalos/estados y formulario separado de PATCH | Parametros pagina/tamanio, 201 «Precio programado» sin cambiar vigente; no priceVersion artificial ni cancelar programación |
| MK-013-T15 · TODO · T14 | FX-013-05/10/17/18 | Implementar fechas inválidas, superposición, vacío y fallos de programación | Estados/errores persistentes y datos conservados | Inicio futuro y fin posterior; 409 no éxito; GET fallido no fabrica lista; modal/foco/salida no pierden propuesta |
| MK-013-T16 · TODO · T04,T05,T06 | S04, C05, contrato de archivo resuelto, FX-013-11/12 | Construir selección, política explícita y prevalidación | Dos etapas con resultados vinculados al archivo/política revisados | Nuevo archivo invalida revisión; total/errors proceden de respuesta; confirmar con errores solo bajo criterio resuelto |
| MK-013-T17 · TODO · T16 | POST multipart, FX-013-12/13/17 | Implementar confirmación/admisión/rechazo de importación | Confirmación con alcance Pricing; 202 con batchId abre S05 | 400/413/422 no crean lote; política enviada explícita; timeout sin batchId no habilita duplicación automática |
| MK-013-T18 · TODO · T04,T05 | S05, C06, FX-013-13 a 15 | Construir seguimiento con referencia y contadores/filas contractuales | S05 recibido/procesando/COMPLETED/PARTIAL/FAILED | 202 no éxito; parciales 2/3 y fallo 1/3 visibles; rows ausente no se inventa; no porcentaje temporal |
| MK-013-T19 · TODO · T18,T16 | GET reporte CSV y FX-013-14/15 | Implementar descarga, fallo de refresco y corrección hacia nuevo intento | CSV disponible por ruta admitida; recuperación S04 y resultado previo conservado | Fallo no borra confirmadas; no «Reanudar»/rollback; corregir exige archivo revisado y evita reimportar confirmadas sin revisión |
| MK-013-T20 · TODO · T10 | S06, C07, Precio/at, FX-013-16 | Construir consulta as-of y retorno contextual | Precio del instante con vigencia/origen/moneda | Request SKU/canal/at; no at en GET producto ni timeline/paginación de histórico inventados |
| MK-013-T21 · TODO · T20 | FX-013-05/16 y DateField | Implementar falta de precio, error y carga histórica | 404 «No encontramos un precio…» distinto de servicio caído | Instante/zona preservados, sin mutaciones históricas ni asientos de auditoría simulados |

S04 completo espera T06. S05 puede construirse con respuestas conocidas antes de completar S04; la integración navegación/admisión de T17/T19 depende de su preparación correspondiente. No declarar todo el flujo validado por pantallas aisladas.

## 4. Normalización del código

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-013-T50 · TODO · T11,T13,T15,T17,T19,T21 | Seis pantallas, DESIGN §§4–11 | Ajustar Mantine al tema y extraer controles DS comunes | Código bajo `prototipo/src/pantallas/MK013/`, controles/tema compartidos | Colores/tipografías/radios/dimensiones DS, Tabler; no tema por MK ni estilos que alteren reglas funcionales |
| MK-013-T51 · TODO · T50 | DESIGN §5/9, spec §11 | Revisar las seis vistas/estados a 1440 × 900 px | Layout legible con desplazamiento vertical y sin overflow de página | Medición/capturas de formulario, comparación y tablas; header 64/sidebar 240/padding 32, ancho útil 1136; textos largos legibles |
| MK-013-T52 · TODO · T50 | UXG-001/002/021, fixtures de formulario/diálogo | Implementar/verificar labels, foco, teclado y anuncios | Controles accesibles, cierre/retorno y errores asociados | Tab/Shift+Tab/Enter/Escape; foco contenido en modal y restituido; error no depende solo de color; movimiento reducido |
| MK-013-T53 · TODO · T50 | UXG-009 a 018/020, contract enums | Auditar copy y estados de negocio | Labels humanos y recuperación contractual coherentes | No broker/scopes, éxito por 202, reanudación Pricing ni unidad inventada; versiones solo donde ayudan a revisar conflicto |

## 5. Autovalidación del owner

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-013-T60 · TODO · T50,T52,T53 | Formularios y fixtures sensibles | Ejecutar verificaciones de oferta/versión/programación/prevalidación/parcial/timeout y checks del entorno | Resultados de interacción y build/typecheck, pruebas sensibles cuando corresponda | Expectativas independientes: no doble envío, rechazo conserva intención, no admisión con política indefinida, respuesta no altera otro objetivo |
| MK-013-T61 · TODO · T51,T52,T60 | Seis rutas y FX-013-01 a 18 | Capturar casos requeridos con revisión, ruta, fixture y viewport | Evidencia identificable en `mockups/MK-013/evidencias/` o ubicación acordada vinculada | Cada caso tiene esperado/observado; capturas no sustituyen secuencia de conflicto/lote; sin datos reales |
| MK-013-T62 · TODO · T06,T61 | Spec §14 y plantilla validation-report | Registrar autovalidación y matriz Task→Pantalla→Fixture→Evidencia→Resultado | `validation-report.md` con autovalidación y estado honesto de gates | CA backend marcados fuera de prueba UI; cero bloqueantes para solicitar visto bueno; aún no APROBADO PARA FIGMA/APROBADO final |

## 6. Revisión UX transversal y Figma

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-013-T70 · TODO · T62 | Autovalidación y versión candidata | Leonardo realiza revisión transversal posterior en rol UI/UX | Registro de revisión distinto del de owner, con hallazgos/decisión | Seis pantallas, estados, UX/DS y LUX revisados; sin revisor alternativo inventado ni firma automática |
| MK-013-T71 · TODO · T70 | Hallazgos de revisión | Corregir cada hallazgo y repetir checks afectados | Referencias de corrección y resultados; si no hay hallazgos, registro explícito | Todos los bloqueantes/importantes requeridos cerrados por evidencia, no por editar estado del documento |
| MK-013-T72 · TODO · T71 | Revisión corregida | Registrar decisión humana APROBADO PARA FIGMA | Visto bueno con responsable, fecha, revisión y alcance | Coincide con evidencia revisada; no se deduce de commit, build, cierre #59/#60 o generación Stitch |
| MK-013-T75 · TODO · T72 | Versión aprobada y DESIGN | Trasladar fielmente seis pantallas y estados exigidos a Figma | Frames/componentes y enlaces reales de revisión | No rediseño silencioso, tokens/componentes trazables; ningún paso a Figma anterior al visto bueno |
| MK-013-T76 · TODO · T75 | Prototipo aprobado y frames | Comparar fidelidad funcional, visual y de estados; corregir diferencias | Evidencia de comparación y revisión de cambios | Inventario, layout, copy, estados y componentes coinciden; cambio de alcance vuelve al gate afectado |
| MK-013-T77 · TODO · T76 | Evidencias y decisiones finales | Completar validation-report e índice del README | Reporte APROBADO solo con criterios satisfechos; enlaces Figma/evidencias reales | Gates A–F completos, fechas/roles/revisión verificables, cero aprobaciones de placeholder |

## 7. Registro de seguimiento

Al ejecutar, añadir por tarea: estado, revisión Git, evidencia, resultado esperado/observado, hallazgo y fecha/actor. La autorización para escribir documentos no completa tareas de prototipo o revisión humana. Las tareas viven aquí; el issue #66 conserva hitos macro y enlaces a ambos MK, sin duplicar esta lista completa. Cierre del issue requiere además el pipeline de MK-014.
