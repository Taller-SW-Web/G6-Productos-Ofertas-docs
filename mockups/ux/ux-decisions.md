# UX Decisions — Productos y Ofertas

**Versión:** 2.0 · **Fecha:** 2026-10-02 · **Responsable:** Leonardo Vera Rodríguez.
**Estado:** decisiones consolidadas mediante revisión documental de #59; sustituyen íntegramente el borrador.

## 1. Uso y trazabilidad

Estas decisiones concretan la [Propuesta UX Integral Adoptada](propuesta-ux.md#9-propuesta-ux-integral-adoptada). Las [UX Guidelines](ux-guidelines.md) contienen las verificaciones operativas. El [registro de fuentes por funcionalidad](propuesta-ux.md#7-trazabilidad-de-las-16-funcionalidades) identifica SPEC, HU, WF y FLOW; los contratos son [OpenAPI](../../api/openapi.yaml) y [AsyncAPI](../../asyncapi/asyncapi.yaml).

Los identificadores 001–006 se mantienen con contenido revisado, sin conservar su obligatoriedad anterior. Los nuevos 007–012 cubren estados, recuperación y accesibilidad. Son decisiones de interacción: el #60 debe definir sus componentes y variantes visuales. No fijan tokens, anchuras, duraciones ni presupuestos de latencia.

| Decisión | Propuesta de origen | Reglas operativas |
|---|---|---|
| UXD-001 Contexto y navegación | P02, P03 | UXG-001, UXG-002 |
| UXD-002 Complejidad pertinente | P02 | UXG-003, UXG-004 |
| UXD-003 Tablas y acciones | P02 | UXG-005 |
| UXD-004 Carga contextual | P01 | UXG-007, UXG-008 |
| UXD-005 Feedback situado | P03 | UXG-011 |
| UXD-006 Búsqueda y validación | P02 | UXG-006 |
| UXD-007 Aceptación y confirmación | P01, P03 | UXG-009, UXG-010 |
| UXD-008 Estados parciales | P01, P03 | UXG-012 |
| UXD-009 Recuperación válida | P03 | UXG-013, UXG-014, UXG-015, UXG-016 |
| UXD-010 Semántica de ausencia | P03 | UXG-017 |
| UXD-011 Acciones críticas | P03 | UXG-018, UXG-019 |
| UXD-012 Comprensión y accesibilidad | P01, P02, P03 | UXG-020, UXG-021, UXG-022 |

<a id="uxd-001"></a>
## UXD-001 — Conservar contexto y elegir contenedor según la tarea

**Problema y evidencia:** navegación desde listados de productos, variantes y maestros, historial de precios y detalle de stock puede perder filtros o trabajo en curso (WF-003/004/008–016).

**Decisión:** conservar filtros, paginación, ubicación y selección válida al consultar un detalle y volver. Un panel/drawer puede servir para detalle o edición breve; una vista completa es adecuada para configuración extensa, etapas o contenido que necesita espacio. Registrar la elección en el component-spec según WF/FLOW.

**Alternativas y motivo:** mantener el drawer obligatorio del borrador ahorra navegación, pero limita tareas complejas. Navegar siempre a una página completa pierde eficiencia en consultas breves. Se adopta una elección contextual y se conserva el estado en ambos casos.

**Límites y trade-offs:** cerrar un panel no guarda automáticamente ni confirma una operación; si hay cambios sin guardar se permite continuar o descartar expresamente. Un panel largo no debe exigir desplazamientos confusos ni esconder errores. No se fijan aquí anchos.

**Verificación:** abrir/cerrar detalle de Auditoría conserva filtros; volver a stock conserva SKU/ubicación; salir de un formulario modificado no destruye entradas sin aviso.

<a id="uxd-002"></a>
## UXD-002 — Revelar complejidad según tipo, alcance y dependencia

**Problema y evidencia:** combos, productos, cupones, promociones, recomendaciones, características, asociaciones y precios tienen configuraciones condicionales (SPEC/HU/WF-002/003/005–010/013).

**Decisión:** agrupar campos por decisión de negocio y revelar los relevantes. Usar etapas solo cuando ayudan a resolver dependencias reales y el flujo las soporta. Los requisitos para guardar un borrador y activar se presentan por separado. Los errores abren sus secciones.

**Alternativas y motivo:** todos los campos visibles aumenta carga; wizard universal añade pasos a tareas simples. Se adopta revelación contextual con revisión de lo configurado, conservando formularios directos para marca, SEO y creación simple de tipo.

**Límites y trade-offs:** cambiar contexto no oculta requisitos ni descarta datos silenciosamente. El criterio de superioridad en upselling no se infiere del precio. «Sin límite» de cupón es una decisión explícita cuando el límite es opcional. Configurar tipo/atributos no corresponde a la categoría.

**Verificación:** cambiar TEXTO/NUMERO/LISTA muestra los campos correctos en creación y no habilita cambio de tipo en edición; guardar borrador de producto no exige imágenes o requisitos de activación indebidamente; resumen de promoción identifica modalidad y alcance.

<a id="uxd-003"></a>
## UXD-003 — Tablas legibles y acciones respaldadas por la funcionalidad

**Problema y evidencia:** lotes, precios, auditoría, stock y Dashboard necesitan comparación de información, pero no tienen los mismos permisos ni operaciones (WF-001/013–016).

**Decisión:** mantener identificación de negocio, encabezados comprensibles, unidades, estados y detalle consultable. Alinear números y permitir recorrer resultados. Selección múltiple, toolbar o acciones masivas existen solo cuando hay una operación funcional/contractual correspondiente.

**Alternativas y motivo:** la tabla densa con selección universal mezcla consulta con mutación. Se conserva la comparación tabular sin imponer densidad ni inventar acciones. Auditoría y Dashboard permanecen en solo lectura; enlaces a otras funcionalidades no convierten esas pantallas en editor.

**Límites y trade-offs:** una API de importación no equivale a «editar todas las filas seleccionadas». No añadir borrar, revertir o editar auditoría. El SKU identifica el ítem vendible; no atribuir saldo al padre con variantes.

**Verificación:** MK-014/016 no presentan toolbar de mutación; una tabla distingue null, cero y dato indisponible; cada acción del listado puede trazarse a su operación admitida.

<a id="uxd-004"></a>
## UXD-004 — Ajustar la carga al alcance de la operación

**Problema y evidencia:** lectura inicial, guardados breves, preparación y lotes requieren feedback diferente (WF-001/003/004/013–016).

**Decisión:** skeleton para estructura conocida aún sin datos; indicador localizado para una acción; datos previos visibles al refrescar cuando sea seguro y señalando actualización. Procesos duraderos usan seguimiento persistente, sin depender de un spinner. Progreso numérico solo con medición real; de otro modo texto/etapas verificables.

**Alternativas y motivo:** prohibir todos los spinners no aporta claridad; loader global para cualquier acción borra contexto. Se adopta feedback proporcional sin esperas artificiales.

**Límites y trade-offs:** skeleton no informa finalización de un comando; NFR o tiempo transcurrido no acreditan porcentaje ni éxito. Bloquear únicamente acciones incompatibles con el estado, sin impedir consultar contenido independiente.

**Verificación:** refrescar una sección no vacía las demás; guardar no reinicia la página; un lote sin contador suficiente no muestra una barra ficticia.

<a id="uxd-005"></a>
## UXD-005 — Situar el feedback donde se resuelve la tarea

**Problema y evidencia:** validación de formularios, conflicto de slug, resultados de importación y recepción requieren mensajes recuperables (WF-001/008/012/013/015).

**Decisión:** error de campo junto al campo; error de sección junto a su contenido; resultado parcial o crítico en bloque persistente. Un toast puede complementar una confirmación simple, pero no ser la única evidencia de un fallo o trabajo asíncrono. Mensaje: qué ocurrió, qué se conservó y qué acción está disponible.

**Alternativas y motivo:** toast universal es fácil de perder y aleja la corrección del problema. Un banner global para todo no identifica el campo. Se combinan canales según alcance y relevancia.

**Límites y trade-offs:** no duplicar mensajes que saturan la pantalla ni revelar detalles internos innecesarios. La confirmación no dice «Guardado» si solo hubo admisión. No imponer duración universal del toast.

**Verificación:** el usuario puede localizar el error tras desaparecer una notificación; «Borrador guardado; preparación incompleta» distingue el resultado confirmado del pendiente.

<a id="uxd-006"></a>
## UXD-006 — Búsqueda y validación proporcionales a la acción

**Problema y evidencia:** maestros, productos y auditoría tienen búsquedas/filtros diferentes; SEO distingue avisos de errores (WF-003/008–014).

**Decisión:** búsqueda incremental solo cuando contrato y coste lo permiten, evitando aplicar respuestas antiguas sobre filtros nuevos. Rangos y conjuntos de filtros pueden tener «Aplicar filtros». Validar en el momento útil: formato tras interacción y requisitos al guardar/continuar; mostrar causa y corrección. No bloquear por reglas inexistentes.

**Alternativas y motivo:** debounce universal de 300 ms y validación exclusiva al blur no sirven para todas las consultas ni formularios. Una deshabilitación sin motivo tampoco explica requisitos. Se adopta validación contextual.

**Límites y trade-offs:** botones deshabilitados requieren explicación visible y accesible; se permite intentar guardar para revelar errores cuando corresponde. SEO mayor de 70/160 caracteres genera aviso, no bloqueo. No aplicar filtros no soportados a exportación de catálogo.

**Verificación:** una respuesta tardía no cambia el resultado de una búsqueda nueva; aviso de longitud SEO permite guardar; errores aparecen al intentar continuar sin borrar valores.

<a id="uxd-007"></a>
## UXD-007 — Distinguir admisión, procesamiento y resultado confirmado

**Problema y evidencia:** `202 Accepted` en importaciones/exportaciones y comandos no equivale a negocio completado; las bajas de maestros necesitan comprobación (SPEC/WF-001/008–011/013–015 y contratos).

**Decisión:** presentar «Solicitud recibida», estado conocido de procesamiento y resultado terminal cuando exista confirmación. Guardar referencia de trabajo para consulta cuando el contrato la entregue. Si no se puede confirmar resultado, decirlo y no reenviar automáticamente.

**Alternativas y motivo:** éxito inmediato simplifica la UI pero contradice procesos asíncronos. Espera sin referencia impide retomarlos. Se adopta seguimiento de la operación específica.

**Límites y trade-offs:** no todas las acciones son asíncronas: crear/editar/reactivar marca y la baja de característica completa no heredan el flujo de comprobación de sus casos especiales; recepción de transferencia tiene respuesta `200` que confirma aplicación. No inventar un endpoint común de estado ni suscripción de navegador a eventos internos.

**Verificación:** CSV y PDF de Auditoría muestran generación pendiente después de admisión; comprobación rechazada o sin respuesta nunca termina en baja exitosa; solo la consulta terminal habilita descarga.

<a id="uxd-008"></a>
## UXD-008 — Mantener resultados parciales y antigüedad identificables

**Problema y evidencia:** lote por dominios, preparación independiente y proyecciones de stock pueden tener éxito parcial (SPEC-001/003/015/016).

**Decisión:** preservar lo confirmado, aislar fallo por fila/dominio/sección y distinguir última información conocida de información actual. Usar fecha de generación/actualización solo si está disponible. Un Dashboard puede degradar por sección si la fuente permite consultas independientes; una respuesta global fallida no acredita datos nuevos de ninguna sección.

**Alternativas y motivo:** error global desperdicia información válida; aparentar éxito completo oculta pendientes. Se adopta resultado mixto explícito y persistente.

**Límites y trade-offs:** no simular transacciones distribuidas ni rollback global; no conservar información vieja como saldo actual. En Dashboard no inventar bloqueados que el esquema no publica. Los booleanos de preparación de producto no acreditan causa ni estados de variante.

**Verificación:** importación identifica dominios aplicados y reconciliación según reporte; la última consulta visible se marca si falla actualización; una tarjeta sin fuente muestra indisponibilidad, no cero.

<a id="uxd-009"></a>
## UXD-009 — Recuperar según capacidad, versión e identidad de operación

**Problema y evidencia:** reanudación de lote, conflicto de precio y slug, límites de exportación y recepción parcial tienen soluciones distintas (SPEC/WF-001/008/012–015 y contratos).

**Decisión:** recuperar de forma localizada, conservar entradas y consultar primero cuando el resultado de una escritura sea desconocido. Utilizar identidad/idempotencia y versiones exigidas por el contrato; la UI no altera esos valores para vencer un conflicto.

**Alternativas y motivo:** «Reintentar» universal puede duplicar efectos o repetir un error determinista. «Reintentar» no es una acción universal. Se adopta una acción específica:
- MK-001: reanudar el mismo lote, solo pendientes/reconciliación según operación publicada.
- MK-003: recuperación automática para fallo técnico; recuperación manual solo cuando el estado publicado la habilita (`manual_retry_allowed=true`).
- MK-004: misma política, exclusivamente para Inventario de variante.
- MK-013: corregir e importar un nuevo intento; no existe reanudación equivalente de Pricing. Conflicto de versión exige releer, revisar diferencias y confirmar intención.
- MK-008: volver a resolver slug, mostrar propuesta y confirmar; la propuesta anterior no reservó el nombre.
- MK-012: corregir slug manual rechazado, sin sufijarlo automáticamente.
- MK-014: reducir rango/filtros; cambiar a CSV solo si está dentro del límite CSV.
- MK-015: comprobar resultado previo antes de reenviar recepción y respetar la identidad del contrato.

**Límites y trade-offs:** reintento técnico no equivale a una nueva intención del usuario. «Reintentar» no es una acción universal; no se ofrece durante un `PENDING` ordinario ni se trasladan fallos técnicos transitorios al operador. `priceVersion` de lectura se usa en edición PATCH; programación futura tiene su contrato propio, sin exigirle ese campo por analogía.

**Verificación:** conflicto conserva valores propuestos y permite revisión; reanudación de carga no duplica lo confirmado; timeout de recepción no añade un segundo ingreso.

<a id="uxd-010"></a>
## UXD-010 — Diferenciar vacío, ausencia, cero e indisponibilidad

**Problema y evidencia:** auditoría, filtros y stock requieren interpretar cantidades y null correctamente (SPEC/WF-014–016 y esquemas).

**Decisión:** distinguir «Sin registros», «Sin coincidencias con estos filtros», «No disponible» y cero confirmado. Null se explica según campo: «Sin precio anterior», «Sin oferta» o «No aplicable». Acción del vacío solo si la funcionalidad la permite.

**Alternativas y motivo:** guion universal es ambiguo; cero para errores falsifica información. Se adoptan etiquetas contextuales sin exigir ilustración decorativa.

**Límites y trade-offs:** no inventar moneda, saldo, timestamp o inicialización. Sin resultado conocido no se dice «Sin stock». La auditoría vacía no ofrece «Crear registro».

**Verificación:** fallar consulta no modifica cifras a cero; retiro de oferta se lee «Sin oferta»; filtros vacíos pueden restablecerse sin perder contexto.

<a id="uxd-011"></a>
## UXD-011 — Confirmar impacto crítico y respetar bloqueos de seguridad

**Problema y evidencia:** activación/baja, cambios de precio y recepción final pueden tener efectos relevantes (SPEC/HU/WF-003/008–011/013/015).

**Decisión:** explicar entidad, alcance y consecuencia antes de acciones que necesiten confirmación según flujo. Confirmación no sustituye precondiciones. La interfaz conserva el estado funcional confirmado hasta recibir resultado definitivo; un estado pendiente se presenta separado.

**Alternativas y motivo:** confirmar todos los clics genera fatiga; omitir impacto crítico favorece errores. Se adopta confirmación proporcional basada en el flujo, sin un modal universal.

**Límites y trade-offs:** comprobación de uso fallida/inconclusa no habilita baja; no crear cuenta regresiva que autorice al vencer. Recibir parcialmente no cierra por sí solo; recepción final identifica faltantes que no se acreditarán. No inventar botón de recepción cero si el contrato exige cantidad positiva.

**Verificación:** confirmación final de transferencia distingue recibido/faltante; combo no se activa sin componentes elegibles; baja rechazada mantiene estado coherente y explicación.

<a id="uxd-012"></a>
## UXD-012 — Lenguaje de negocio, teclado y mensajes accesibles

**Problema y evidencia:** las 16 funcionalidades necesitan interpretar estados y corregir tareas sin depender de detalles técnicos o de la percepción del color.

**Decisión:** usar nombres, SKU y ubicaciones como identificadores útiles; conservar referencias técnicas solo en detalle de seguimiento cuando ayudan a soporte. Etiquetar controles, presentar estado en texto, mantener foco visible y recorrido de teclado. Anunciar mensajes de estado sin tomar foco innecesariamente; llevar el foco a errores o confirmar su ubicación cuando resulte necesario.

**Alternativas y motivo:** etiquetas como `schema_version` o códigos internos como mensaje principal obligan a interpretar implementación; el color/toast por sí solo no comunica de forma suficiente. Se adopta vocabulario consistente y señalización accesible.

**Límites y trade-offs:** no renombrar estados con pérdida de significado, inventar roles ni prometer accesibilidad certificada sin evaluación. Formularios, paneles y diálogos deben usar los componentes/variantes que defina #60.

**Verificación:** completar tarea con teclado, volver al activador al cerrar diálogo/panel, reconocer error sin color, asociar mensaje al campo y anunciar estado de actualización. Referencia: [W3C — Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html).

## 2. Aplicación y cambios posteriores

Cada owner registra UXD/UXG aplicables, fuentes y fixtures en su component-spec; justifica elección de panel, pasos o detalle como `LUX-XX`. Ningún ID convierte el patrón en obligatorio fuera de sus condiciones.

Los [hallazgos de fuentes](propuesta-ux.md#10-hallazgos-de-fuentes-y-límites) impiden aprobar los estados afectados hasta alineación. No dejan pendiente otra propuesta transversal ni se resuelven con fixtures inventados.

Una nueva regla transversal debe actualizar propuesta, decisión y guideline de forma coherente. El #60 debe mapear componentes a estos comportamientos; no cambiar requisitos de interacción por conveniencia de una librería. El resultado y condiciones de habilitación están en la [validación del #59](propuesta-ux.md#11-validación-y-habilitación).
