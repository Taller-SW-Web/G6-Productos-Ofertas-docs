# UX Guidelines — Productos y Ofertas

**Versión:** 2.0 · **Fecha:** 2026-10-02 · **Responsable:** Leonardo Vera Rodríguez.
**Estado:** reglas operativas consolidadas para #59; reemplazan íntegramente el borrador.

## 1. Aplicación

Estas reglas derivan de [UX Decisions](ux-decisions.md) y de la [propuesta integral](propuesta-ux.md#9-propuesta-ux-integral-adoptada). «Debe» aplica cuando se cumple la condición de la regla; no obliga a introducir un patrón irrelevante.

La matriz de [aplicabilidad](propuesta-ux.md#6-matriz-de-aplicabilidad) y la tabla de [fuentes](propuesta-ux.md#7-trazabilidad-de-las-16-funcionalidades) orientan al owner. SPEC/HU y contratos prevalecen sobre recomendaciones UX. Cada estado del component-spec debe citar su fuente y UXD/UXG; la elección local de composición se justifica como `LUX-XX`.

Web desktop con revisión canónica a 1440 px. Se debe poder operar con teclado y mouse sin overflow horizontal involuntario de página. Una tabla que necesita desplazamiento lo limita a su región. El #60 definirá los tokens y variantes de componentes; este documento no fija tipografía, anchos, colores, duración de toast ni latencias.

## 2. Reglas verificables

### Contexto, configuración y consulta

| Regla | Decisión | Condición y comportamiento obligatorio | Evidencia de cumplimiento |
|---|---|---|---|
| UXG-001 | [UXD-001](ux-decisions.md#uxd-001) | Al abrir detalle y regresar, conservar filtros, página y contexto SKU/ubicación válidos. Elegir panel o vista según complejidad y WF/FLOW, sin drawer universal | Recorrido listado → detalle → regreso con el mismo contexto |
| UXG-002 | [UXD-001](ux-decisions.md#uxd-001) | Con entradas sin guardar, cerrar/navegar debe permitir seguir editando o descartar explícitamente; conservar entradas ante fallo corregible | Salida cancelada y fallo de guardado mantienen valores |
| UXG-003 | [UXD-002](ux-decisions.md#uxd-002) | Mostrar campos pertinentes al tipo/modalidad/alcance; los requisitos de borrador y activación se distinguen. Cambio que descarta valores debe advertirse | Fixtures de contextos diferentes y requisitos de cada acción |
| UXG-004 | [UXD-002](ux-decisions.md#uxd-002) | Pasos solo con dependencia real. Si existen, permitir revisar/corregir y conservar avance válido. Formularios breves no reciben wizard por pertenecer a un MK | Justificación LUX del contenedor/pasos y recorrido con corrección |
| UXG-005 | [UXD-003](ux-decisions.md#uxd-003) | Tabla con identificador de negocio, unidades y estados legibles. Selección/acción masiva requiere capacidad funcional y contractual. Auditoría y Dashboard no mutan datos | Inventario de acciones y sus operaciones admitidas; ausencia de controles de mutación en 014/016 |
| UXG-006 | [UXD-006](ux-decisions.md#uxd-006) | Búsquedas/filtros respetan parámetros admitidos e ignoran respuestas obsoletas. Validar al interactuar o intentar guardar/continuar según campo. Error explica requisito; deshabilitación tiene motivo visible | Respuesta tardía, filtro aplicado y envío inválido sin pérdida de valores; aviso SEO no bloquea |

### Carga, seguimiento y feedback

| Regla | Decisión | Condición y comportamiento obligatorio | Evidencia de cumplimiento |
|---|---|---|---|
| UXG-007 | [UXD-004](ux-decisions.md#uxd-004) | Lectura inicial sin datos: skeleton si se conoce estructura; si no, estado de carga comprensible. Acción breve: indicador localizado. No añadir espera artificial | Fixture inicial y guardado localizado |
| UXG-008 | [UXD-004](ux-decisions.md#uxd-004) | Al actualizar, conservar datos previos cuando sea seguro y marcar actualización/antigüedad. Mostrar porcentaje únicamente con medición suficiente; de otro modo estado/etapas reales | Refresco sin vaciar secciones independientes; origen de cada contador |
| UXG-009 | [UXD-007](ux-decisions.md#uxd-007) | Una admisión asíncrona se presenta como solicitud recibida, no éxito terminal. Mantener referencia y seguimiento que el contrato permita; descarga/activación solo tras confirmación pertinente | Fixture aceptado, procesando y terminal; no descarga anticipada |
| UXG-010 | [UXD-007](ux-decisions.md#uxd-007) | Diferenciar comprobación pendiente, rechazo y ausencia de resultado; no deducir baja exitosa del silencio. Las acciones síncronas confirmadas no reciben espera inventada | Baja pendiente/rechazada/inconclusa y respuesta síncrona diferenciadas |
| UXG-011 | [UXD-005](ux-decisions.md#uxd-005) | Error de campo junto al campo; error de sección junto a ella; parcial/crítico persistente. Toast solo complementa. Indicar ocurrido, conservado y acción disponible | Error localizable después de desaparecer cualquier notificación |
| UXG-012 | [UXD-008](ux-decisions.md#uxd-008) | Fallo parcial conserva lo confirmado y señala el alcance fallido. Último dato conocido no se presenta como actual. Degradar por sección solo con independencia real de fuentes | Reporte por fila/dominio o secciones; fecha/origen conocido o ausencia explícita |

### Recuperación y significado de los resultados

| Regla | Decisión | Condición y comportamiento obligatorio | Evidencia de cumplimiento |
|---|---|---|---|
| UXG-013 | [UXD-009](ux-decisions.md#uxd-009) | Resultado desconocido de escritura: consultar/reconciliar antes de repetir. Mantener identidad y versión requeridas; «Reintentar» solo si la operación admite hacerlo con seguridad | Timeout sin doble efecto; acción trazada a contrato |
| UXG-014 | [UXD-009](ux-decisions.md#uxd-009) | Conflicto de precio: conservar intención, releer/revisar y confirmar. Slug de categoría: resolver de nuevo y confirmar propuesta; slug manual SEO: corregir sin renombrado silencioso | Fixtures de conflicto y revisión de valores |
| UXG-015 | [UXD-009](ux-decisions.md#uxd-009) | Carga general reanuda el mismo lote según contrato; Pricing corrige e importa nuevo intento, sin reanudación inventada. No prometer rollback entre dominios | Resultado parcial y recuperación específica de 001 frente a 013 |
| UXG-016 | [UXD-009](ux-decisions.md#uxd-009) | Exportación rechazada por límites conserva filtros y explica reducción. Cambiar PDF a CSV solo dentro del límite CSV; un rechazo sin trabajo creado no se muestra como trabajo fallido | Exceso PDF, exceso CSV y admisión correcta |
| UXG-017 | [UXD-010](ux-decisions.md#uxd-010) | Diferenciar vacío, filtro sin coincidencias, null, cero e indisponibilidad. Moneda/unidad/fecha solo con fuente. Acción del vacío solo si está permitida | Vacío, null, cero confirmado y error de consulta distinguibles |
| UXG-018 | [UXD-011](ux-decisions.md#uxd-011) | Antes de acción crítica, explicar entidad, alcance e impacto conforme al flujo. Confirmación no omite precondiciones; no cambiar estado funcional definitivo antes de resultado | Confirmación, rechazo y resultado confirmado separados |
| UXG-019 | [UXD-011](ux-decisions.md#uxd-011) | Recepción de transferencia identifica ubicación, recibido, pendiente y disposición. La final advierte faltantes no acreditados; respuesta desconocida no permite duplicar recepción | Parcial, final con faltantes y consulta tras timeout |

### Comprensión, acceso y evidencia

| Regla | Decisión | Condición y comportamiento obligatorio | Evidencia de cumplimiento |
|---|---|---|---|
| UXG-020 | [UXD-012](ux-decisions.md#uxd-012) | Usar nombres, SKU y ubicación; estados en texto y acciones comprensibles. Referencia técnica en detalle solo si ayuda a seguimiento. No inventar permisos/roles ni acciones de otros módulos | Mensajes entendibles y acciones según capacidad real |
| UXG-021 | [UXD-012](ux-decisions.md#uxd-012) | Controles con etiqueta, foco visible y orden de teclado; diálogos/paneles gestionan y restituyen foco. Error asociado al campo y sección abierta; estado anunciable sin tomar foco innecesario | Recorrido por teclado, foco al abrir/cerrar y error perceptible sin color |
| UXG-022 | [UXD-012](ux-decisions.md#uxd-012) | Cada pantalla/estado cita fuente y reglas aplicables; datos ficticios se etiquetan como fixtures. Una capacidad ausente no se presenta como publicada. Excepción local se justifica sin cambiar negocio | Matriz fuente → UXD/UXG → pantalla → fixture → resultado y hallazgos pendientes |

## 3. Casos de control por funcionalidad

Los escenarios siguientes son criterios mínimos para especificación y validación posterior; no certifican un prototipo aún no construido.

| MK | Caso que debe poder representarse y verificarse | Reglas prioritarias |
|---|---|---|
| 001 | Archivo inválido sin efectos; lote recibido/procesando; resultado con dominios confirmados y pendientes; reanudación sin repetir lo aplicado; exportación solo descargable al completar | 007–009, 011–013, 015 |
| 002 | Mínimo dos SKUs vendibles directos, sin duplicados/combos anidados; comparación de precio y disponibilidad estimada informativas. Componente no elegible mantiene definición y evita una activación inválida | 003, 006, 011, 017, 018 |
| 003 | Guardar borrador con sus requisitos propios; activación con requisitos adicionales; preparación conocida/incompleta/desconocida sin borrar borrador. SKU base y modalidad de variantes no cambian indebidamente después de publicación | 002, 003, 009, 011, 012, 017, 018 |
| 004 | Atributos y datos físicos por SKU; inventario inicializado antes de publicación. Variante sin override no exige precio propio. Baja de última variante activa tiene el efecto previsto en el padre | 003, 009–012, 017, 018 |
| 005 | Límite opcional «Sin límite», vigencia y restitución explícitas; error de código duplicado preserva entradas. No controles de consumo/restauración propios de Ventas | 003, 006, 011, 020 |
| 006 | Modalidad automática/cupón y porcentaje/monto con campos pertinentes; cambio de modalidad solo bajo restricciones documentadas. No simulador de checkout agregado | 002–004, 006, 011, 020 |
| 007 | Cross-sell distinto de upselling; criterio de superioridad obligatorio, sin inferencia por precio ni selección automática de variante. No «Probar compra» inventado | 003, 006, 011, 020, 022 |
| 008 | Propuesta de slug visible/confirmable, conflicto concurrente y nueva confirmación; baja con comprobación pendiente/rechazada/inconclusa y sin éxito prematuro | 006, 009–011, 013, 014, 018 |
| 009 | Tipo inmutable; NUMERO exige unidad; LISTA muestra valores. Baja de valor pendiente no habilita selección y requiere resultado; baja de característica completa usa su flujo síncrono | 003, 006, 009–011, 018 |
| 010 | Crear tipo breve sin wizard forzado; seleccionar características activas sin duplicados; límite configurable y obligatoriedad explícitos. Conflicto de esquema no pierde configuración; cambio opcional → obligatorio no desactiva automáticamente productos previos | 003, 004, 006, 010, 011, 013, 018 |
| 011 | Formulario corto; logo opcional con formatos/tamaño permitidos y país opcional; duplicado incluye inactivas. Baja pendiente/rechazada conserva estado y distingue creación/edición/reactivación síncronas | 001, 006, 009–011, 018 |
| 012 | Edición directa y vista previa de contenido; avisos por título >70/descripción >160 no bloquean guardado; slug manual duplicado rechazado sin cambio automático. Historial consultable; redirección 301 pertenece al consumidor Marketplace | 001–004, 006, 011, 014 |
| 013 | Precio producto y override SKU diferenciados con herencia; canal/vigencia explícitos; edición con versión vigente; programación con sus propios campos; importación parcial corregible sin botón de reanudación de Catálogo | 003, 006, 009, 011–015, 017, 018 |
| 014 | Solo lectura; filtros/detalle/retorno; null distinto de cero. PDF >500 o CSV >100000 registros produce rechazo sin export_id; ambas exportaciones admitidas se generan asíncronamente | 001, 005, 006, 009, 011, 016, 017 |
| 015 | Saldos por SKU/ubicación; recibido parcial mantiene pendiente y final con faltantes no los acredita. No controles internos de reserva, consumo, conciliación offline o merma fuera del flujo autorizado de recepción | 001, 009, 011–013, 017–020 |
| 016 | Dashboard de lectura; filtros preservados al ir a detalle; actualización fallida conserva solo último resultado identificado. Sin fuente de bloqueados, no mostrar cero ni valor inventado; acciones operativas se abren en MK-015 | 001, 005, 007, 008, 011, 012, 017, 020, 022 |

El owner también debe verificar las demás reglas que correspondan a sus pantallas; esta tabla no exime de requisitos de SPEC/HU ni limita escenarios de aceptación.

## 4. Reglas contractuales que evitan falsas promesas UX

- **Preparación de catálogo:** `pricing_preparado` e `inventario_inicializado` opcionales no describen causa ni todo el ciclo. Ausente significa desconocido; `false` no permite afirmar rechazo. Variante no publica detalle equivalente. No especificar «Reintentar inicialización» sin una operación disponible.
- **Carga general:** `COMPLETED` con filas fallidas/reconciliación puede presentarse «Completado con observaciones». Estados de fila y dominios aplicados se toman del reporte. No inventar endpoint de prevalidación de negocio equivalente al de Pricing.
- **Bajas de maestros:** comprobación pendiente, rechazada o sin respuesta no confirma baja. No generalizar esa comprobación a todas las ediciones ni interpretar timeout como permiso.
- **Precios:** edición PATCH utiliza la versión leída; programación tiene su propio contrato. Importación de precios puede terminar `PARTIAL`, `FAILED` o `COMPLETED`; no comparte la reanudación de carga general. Herencia no equivale a crear un precio ficticio por variante.
- **Auditoría:** CSV hasta 100000 y PDF hasta 500 registros; superar límite devuelve rechazo `422` sin crear trabajo. Ambas admisiones devuelven `202`. No editar, borrar ni revertir registros.
- **Inventario:** saldo vendible pertenece a SKU/ubicación, no al producto padre con variantes. Recepción devuelve `200` al aplicar; requiere cantidad positiva. Pendiente/faltante no es saldo recibido. No deducir totales bloqueados de Dashboard que no publica esos campos.
- **Fuentes abiertas:** no completar por UX decisiones comerciales o agregados todavía pendientes en HTTP 0.5.0. Consultar los [hallazgos](propuesta-ux.md#10-hallazgos-de-fuentes-y-límites) y registrar el estado bloqueado en el documento funcional.

## 5. Evidencia y condiciones de consumo

En el component-spec se inventarían pantallas, estados y fixtures con referencias específicas. La secuencia **component-spec → plan → tasks** permanece a cargo del owner. Los fixtures ilustran datos y respuestas contractuales; no sirven para inventar un endpoint, permisos o confirmación faltante.

Para validar un estado, registrar:

| Fuente y apartado | UXD / UXG | Pantalla o componente | Fixture / recorrido | Resultado / hallazgo |
|---|---|---|---|---|
| Referencia funcional y contrato aplicable | IDs vigentes de esta versión | MK-XXX-SXX / CXX | Entrada, acción y estado esperado verificables | Conforme o pendiente con motivo y responsable |

Debe poder comprobarse la experiencia en sus caminos pertinentes: inicial, vacío/sin coincidencias, operación simple, admisión/procesamiento, resultado, error corregible, conflicto y fallo parcial. No todos los MK necesitan todos los estados ni un proceso asíncrono.

Esta documentación no exige aprobar anticipadamente un prototipo inexistente. La habilitación documental se produce cuando se cumplan las condiciones del [gate UX](propuesta-ux.md#11-validación-y-habilitación), incluida la alineación de fuentes, y se adopte el cambio en la base compartida. El #60 proporciona el Design System y completa el gate transversal con #59; el #61 organiza la ejecución general de los mockups. El #66 corresponde únicamente a la asignación individual de MK-013 y MK-014. Los hallazgos funcionales/contractuales se resuelven antes de aprobar los estados afectados.
