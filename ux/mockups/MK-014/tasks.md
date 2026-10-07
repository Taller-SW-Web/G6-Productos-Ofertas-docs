# MK-014 — Tareas de construcción y verificación

## 1. Control de ejecución

**Owner:** Leonardo Vera Rodríguez. **Rama:** `vera`. **Issue:** #66, dentro de #61. **Versión:** 1.0.0, 2026-10-02. **Estado:** planificación En revisión; prototipo y evidencias aún no creados.

Entradas: [Component Spec](component-spec.md), [Plan](plan.md), [DESIGN](../DESIGN.md), [UX Guidelines](../ux/ux-guidelines.md), [pipeline](../README.md) y [plantilla Tasks](../_plantillas/mockup/tasks.template.md).

Estados: `TODO`, `DOING`, `BLOCKED`, `REVIEW`, `DONE`. Todas las tareas son P0. DONE exige salida comprobable, revisión Git y evidencia; no se marca implementación por describirla. T06 está BLOCKED por Q-014-01: se puede avanzar estructura/estados conocidos, sin aprobar unidad monetaria ficticia ni gates finales.

Cada fila incluye Entrada → Acción → Salida → Verificación. Dependencias abreviadas refieren tareas del mismo MK (`MK-014-TXX`), salvo T03 que también puede consumir base común creada por el equipo/MK-013. Nuevos hallazgos bloquean únicamente trabajo dependiente con referencia y owner.

## 2. Preparación

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-014-T01 · TODO · — | Fuentes spec §2 y plan §3 | Confirmar revisión y disponibilidad #59/#60 en base compartida | Registro de versiones y cambios desde ea9c4f1 | Fuentes existentes y diferencias identificadas; gate de módulo no sustituye aprobación del MK |
| MK-014-T02 · TODO · T01 | Spec/plan/tasks y gobernanza | Revisar inventario, DTOs, LUX, estados y alcance conocido | Revisión documental con hallazgo y tareas dependientes | Cinco pantallas, 18 fixtures, quince campos y HU trazados; Q-014-01 no se declara resuelto sin fuente |
| MK-014-T03 · TODO · T01 | Prototipo README y base del equipo/MK-013 | Reutilizar runtime React/TS/Mantine/Tabler y tema común, o completar base mínima si falta | Entorno ejecutable compartido con comando de arranque | Arranque/build/typecheck reales, un tema y shell; sin otra aplicación por MK ni versiones incompatibles |
| MK-014-T04 · TODO · T02,T03 | Schemas y spec §12 | Materializar DTOs/fixtures FX-014-01 a 18 y adaptador local | Datos tipados, reloj fijo y respuestas deterministas | Required/nulos correctos; sin moneda añadida ni arrays de 100 000 objetos; datos personales ficticios |
| MK-014-T05 · TODO · T03,T04 | Inventario spec §4 | Registrar rutas y selector de fixture | S01–S05 directas; S02/S03 con fondo y contexto fixture | Abrir/recargar cada ruta sin recorrido; foco definido, sin hostname/puerto fijo ni escritura real |
| MK-014-T06 · BLOCKED · T01 | Q-014-01 y RegistroAuditoriaPrecio | Obtener definición revisada de moneda histórica/unidad garantizada y actualizar cadena documental | Fuente revisada, spec/plan/tasks/fixtures monetarios alineados | Moneda/unidad con respaldo oficial; no copiar PEN del vigente ni agregar dato solo al fixture |

## 3. Pantallas y comportamiento

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-014-T10 · TODO · T02,T04,T05 | S01, C01/C02, filtros y PageMeta | Construir pantalla ancla: listado, filtros aplicados y paginación | Tabla solo lectura, seis filtros y acciones CSV/PDF | Query sku/desde/hasta/usuarioId/canal/batchId/pagina/tamanio; no email ni ordenamiento/selección masiva inventados |
| MK-014-T11 · TODO · T10 | C04, FX-014-01 a 05/17 | Implementar valores/operaciones y vacíos contextualizados | Labels humanos y null/cero diferenciados | CREACION anterior null; RETIRO nuevo null; cero recibido sigue cero; moneda ausente no se rellena; sin crear asiento |
| MK-014-T12 · TODO · T10 | FX-014-06 a 08/15 | Añadir rango, reset página, respuesta tardía y errores de consulta | Contexto aplicado coherente y estados seguros | Página 2 conserva filtros; rango invertido no envía; respuesta vieja ignorada; 403 retira datos protegidos; 503 no es vacío |
| MK-014-T13 · TODO · T10,T11 | S02, C03/C04, quince campos | Construir detalle read-only en modal 640 px | Detalle agrupado con datos autorizados y retorno | Campos con destino, motivo completo, referencias seleccionables, null opcional explicado; sin editar/borrar/restaurar |
| MK-014-T14 · TODO · T13 | FX-014-06/08/15, reglas de foco | Añadir carga/error/permisos y cerrar/retornar detalle | Modal accesible que conserva contexto seguro | Tab contenido/Escape/cerrar/foco de retorno; directo devuelve a título; filtros/página sin cambios; 403 sin datos personales |
| MK-014-T15 · TODO · T13 | S03, FX-014-09 | Construir detalle inexistente con respuesta 404 | Copy «No encontramos este registro de auditoría» y retorno | No asiento ficticio ni código técnico visible; 404 distinto de 403/503 y de listado vacío |
| MK-014-T16 · TODO · T10,T04,T05 | S04, C05, ExportacionAuditoriaRequest | Construir revisión y solicitud CSV del conjunto filtrado | Resumen de filtros/límite y POST fixture separado del estado de trabajo | Body formato CSV + seis filtros aplicados, sin pagina/tamanio; alcanza todo el resultado, no filtros sin aplicar |
| MK-014-T17 · TODO · T16 | FX-014-10/11/14/16/18 | Implementar CSV admitido, seguimiento, descarga, límites y ambigüedad | 202→QUEUED→PROCESSING→COMPLETED; 422 sin job y fallos separados | 100 000 admite/100 001 rechaza; no descarga anticipada ni porcentaje; timeout sin ID no reenvía; fallo archivo conserva generación |
| MK-014-T18 · TODO · T16,T17 | S05 y C05; formato PDF/límite 500 | Reutilizar flujo de exportación con configuración PDF | Pantalla PDF directa y estados propios de formato | POST solo PDF, no XLSX; mismos filtros/seguimiento sin duplicar lógica ni límite CSV |
| MK-014-T19 · TODO · T18 | FX-014-12/13/15/18 | Implementar fronteras PDF y cambio de formato permitido | PDF 500 admite; 501 rechazo sin ID; CSV condicionado al total conocido | Mantiene filtros al ir S04; total 100 001 no sugiere CSV como suficiente; conteo 500 previo y 422 nuevo se manejan sin falsa admisión |

T11 representa números con «Moneda no informada» para revisión mientras Q-014-01 siga abierto; no valida formato monetario final. T06 habilita actualización y verificación definitiva de esos valores, no autoriza asumir el cambio de contrato por cuenta del prototipo.

## 4. Normalización del código

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-014-T50 · TODO · T11,T12,T14,T15,T17,T19 | Cinco pantallas y DESIGN | Normalizar Mantine/Tabler y extraer componentes DS compartidos | Código en `prototipo/src/pantallas/MK014/`, tema/shell comunes | Tokens/dimensiones/tipografías coherentes, sin estilo monocromático heredado ni controles de mutación por defaults |
| MK-014-T51 · TODO · T50 | Spec §11, DESIGN §5/9 | Revisar todas las rutas/estados a 1440 × 900 px | Tabla/filtros/modal/exportación legibles | Header 64/sidebar 240/padding 32, ancho útil 1136; tablas no ensanchan página, modal con scroll y salida visible |
| MK-014-T52 · TODO · T50 | UXG-001/021 y rutas modal | Verificar labels, headers, foco, teclado y live regions | Controles accesibles, foco contenido y retorno estable | Tab/Shift+Tab/Enter/Escape, paginación/filas etiquetadas, estado no solo color, lectura read-only con contraste y movimiento reducido |
| MK-014-T53 · TODO · T50 | Enums, WF y UXG-005/016/017/020 | Auditar copy, null, límites y permisos visibles | Vocabulario operativo y acciones permitidas | Sin scopes/AUDITOR_COMERCIAL/XLSX/crear/editar/borrar/archivar; 422 distinto de FAILED_GENERAL, cero distinto de null |
| MK-014-T54 · TODO · T06,T11,T17,T19 | Fuente resuelta de moneda y escenarios afectados | Actualizar representación monetaria y fixtures dependientes | Importes/unidad coherentes con fuente revisada | Tabla/detalle/exportación no infieren moneda por SKU actual; cálculos/formato preservan significado histórico |

## 5. Autovalidación del owner

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-014-T60 · TODO · T50,T52,T53,T54 | Fixtures sensibles y contrato | Ejecutar verificaciones de filtros/página/null, límites, jobs/descarga y checks del entorno | Resultados de interacción y build/typecheck; pruebas sensibles donde corresponda | 500/501 y 100 000/100 001, filtro aplicado serializado, 422 sin ID, 202 sin descarga, respuestas obsoletas ignoradas, sin doble POST |
| MK-014-T61 · TODO · T51,T52,T60 | Cinco rutas y FX-014-01 a 18 | Capturar evidencia con revisión, fixture y viewport | Archivos en `mockups/MK-014/evidencias/` o ubicación acordada vinculada | Esperado/observado por caso; secuencias para filtros/retorno/exportación, sin datos personales reales |
| MK-014-T62 · TODO · T06,T61 | Spec §14 y plantilla validation-report | Registrar autovalidación y matriz Task→Pantalla→Fixture→Evidencia→Resultado | `validation-report.md` con estado honesto y pendientes de revisión | HU backend no se declara probada por UI; cero bloqueantes antes de visto bueno; no aprobación final anticipada |

## 6. Revisión transversal y Figma

| ID / estado / dependencias | Entrada | Acción | Salida esperada | Verificación para DONE |
|---|---|---|---|---|
| MK-014-T70 · TODO · T62 | Autovalidación y versión candidata | Leonardo revisa transversalmente en rol UI/UX, después del owner | Registro de revisión con hallazgos/decisión separado de autovalidación | Cinco pantallas/estados y LUX/DS verificados; no firmar automáticamente ni inventar revisor alternativo |
| MK-014-T71 · TODO · T70 | Hallazgos de revisión | Corregir hallazgos y repetir checks afectados | Referencias de corrección/evidencias; registrar si no hubo hallazgos | Cero bloqueantes/importantes requeridos abiertos, mismo alcance/revisión candidato |
| MK-014-T72 · TODO · T71 | Candidato corregido | Registrar decisión humana APROBADO PARA FIGMA | Responsable, fecha, revisión y alcance aprobado | No inferir aprobación de generación, commit, build o cierre de issues transversales |
| MK-014-T75 · TODO · T72 | Versión aprobada y DESIGN | Trasladar cinco pantallas y estados exigidos a Figma | Frames/componentes y enlaces reales | Labels/null/límites/estados y readonly fieles, sin rediseño silencioso ni paso anterior al visto bueno |
| MK-014-T76 · TODO · T75 | Prototipo candidato y frames | Verificar/corregir fidelidad funcional y visual | Comparación trazable y resultados revisados | Layout, estados, filtros/detalle/exportación y componentes coinciden; cambio de alcance vuelve al gate afectado |
| MK-014-T77 · TODO · T76 | Evidencias y decisiones finales | Completar validation-report e índice del README | Reporte APROBADO con enlaces reales y estado de entrega actualizado | Gates A–F satisfechos, revisión/fecha/roles verificables, cero placeholders de aprobación |

## 7. Seguimiento y cierre

Al ejecutar cada tarea, registrar estado, revisión, evidencia, esperado/observado, hallazgo y actor/fecha. Ninguna tarea de implementación está completada en esta entrega documental. Las tareas se mantienen aquí; #66 solo resume hitos y enlaces, sin repetir el desglose. El cierre del issue exige también completar MK-013 y sus gates.
