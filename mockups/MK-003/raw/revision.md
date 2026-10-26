# Revisión de MK-003-S02 — Crear producto

**Fecha:** 2026-10-03. **Archivo revisado:** [S02.html](S02.html).

**Resultado: NO CONFORME con el alcance completo de S02.** La base visual es reutilizable, pero faltan contenido, comportamiento y estados P0. Esta revisión de la entrega HTML no constituye aprobación del MK, autovalidación completa, revisión transversal de Vera ni visto bueno para Figma.

## Fuentes y método

- [Component Spec](../component-spec.md) §§2, 4, 8–10, 12–15; [plan](../plan.md) §§2–3, 6–10, 13; [tasks](../tasks.md) T10–T12, T40–T43, T50–T69.
- [SPEC-003](../../../specs/SPEC-003-gestion-productos-crud.md) §§2–6; [HU-003](../../../hu/HU-003-gestion-productos-crud.md); [WF-003](../../../wireframes/flows/WF-003-gestion-productos-crud.md); [FLOW-003](../../../flujos/FLOW-003-gestion-productos-crud.md) §4.1.
- [OpenAPI](../../../api/openapi.yaml): `ProductoCreateRequest`, `PerfilFisicoInput` y respuestas de alta.
- [Propuesta UX](../../ux/propuesta-ux.md), [UX Decisions](../../ux/ux-decisions.md), [UX Guidelines](../../ux/ux-guidelines.md) y [Design System](../../DESIGN.md) §§4–5, 7–8, 12–13, 15.
- Inspección del HTML y del DOM renderizado; comprobaciones en navegador a 1440 × 900 px con fixtures originales. Prueba de precio negativo, peso cero, selección del modelo con variantes y botón Guardar borrador. Las entradas de prueba se restauraron al terminar.

## Cambio de marca realizado

Se incorporó el logo suministrado por el usuario a la izquierda de «Inka Athletics», conservando el nombre, el punto naranja y el contexto del módulo. Ambas vistas usan el mismo [PNG](../../assets/inka-athletics-logo.png) y la misma [hoja de marca](../../assets/brand-header.css).

El PNG se conserva byte a byte, sin redibujarlo ni cambiar sus colores. Se escala proporcionalmente; el contenedor recorta únicamente márgenes blancos del archivo, sin cortar el símbolo. El fondo blanco mantiene visible el logo negro sobre el header oscuro. La imagen es decorativa para el lector de pantalla porque el nombre está escrito al lado.

**Verificación:** activo cargado, dimensiones originales 1214 × 910; región visible 96 × 40; header de 64 px; sin desbordamiento horizontal de página a 1440 px. Capturas: [vista completa](evidencias/S02-1440.jpg) y [cabecera](evidencias/S02-cabecera.jpg).

## Hallazgos

P0 identifica requisitos funcionales o de validación que impiden acreditar S02 completa. P1 identifica correcciones visuales y de contenido requeridas. Las prioridades no sustituyen las de `tasks.md`.

| ID | Prioridad | Evidencia encontrada | Requisito / fuente | Corrección necesaria |
|---|---|---|---|---|
| R003-01 | P0 | No existe selector de tipo de producto | Component Spec C01/S02; SPEC-003 §2; FLOW-003 §4.1; `ProductoCreateRequest.tipoProductoId` requerido | Incorporar tipo válido, independiente de categoría; disponer de lectura/errores del esquema de sus características. Q-06 afecta la edición en S03, no impide este campo contractual de alta |
| R003-02 | P0 | Solo nombre, SKU y precio tienen `required`; descripción, categoría y marca no lo tienen. Las opciones de maestros no identifican entidades contractuales | Datos mínimos de SPEC-003; Component Spec C01; `ProductoCreateRequest` | Validar mínimos no vacíos y maestros mediante IDs, con mensajes asociados. No basta el asterisco visual |
| R003-03 | P0 | No hay captura de URL/imagen ni características del tipo; el panel deriva la imagen a una futura ficha | Component Spec C02/S02, incluidos sus componentes y grupos | Incluir imagen por referencia y características tipadas, opcionales al guardar borrador, sin exigir carga de archivos ni atributos completos para el alta |
| R003-04 | P0 | Precio `-1` y peso `0` tienen `validity.valid=true`; no existe validación adicional. `step=0.10` introduce una granularidad que la SPEC no exige | Precio inicial y valores físicos informados mayores que cero; Component Spec C01/C03; HU-003 CA-11; `PerfilFisicoInput` | Rechazar cero/negativos con error de campo; admitir perfil parcial y ausencia. No imponer incrementos de diez céntimos como regla comercial |
| R003-05 | P0 | Al seleccionar variantes, el radio cambia pero siguen visibles el físico del padre, la inicialización de inventario del simple y el distintivo «Seleccionado» del simple | SPEC-003 §§3–4; Component Spec C01/C03; UXD-002, UXG-003 | Actualizar visualmente el modelo; mostrar físico solo para simple y preparación por variantes para padre. Advertir antes de descartar valores incompatibles |
| R003-06 | P0 | Se muestra «Fórmula aforada estándar Courier Nacional (L × An × Al / 5000)» y peso volumétrico estático de 1.69 kg | Component Spec C03/§4: volumen de ayuda largo × ancho × alto en cm³; sin empaque, pedido ni reglas de flete | Retirar divisor y cálculo de flete no documentados. Si se muestra volumen, derivarlo de las medidas en cm³ y actualizarlo al cambiar entradas |
| R003-07 | P0 | «Moneda oficial: PEN» presenta como definitiva la moneda del ejemplo | Component Spec Q-04/§13; plan §2; UXG-017/022 | Mantener PEN como dato de fixture en evidencia o mostrar moneda solo con configuración/fuente contractual confirmada; no declarar una moneda oficial desde la pantalla |
| R003-08 | P0 | Guardar borrador no produce resultado ni navegación: `onsubmit` solo ejecuta `event.preventDefault()`. Cancelar no tiene acción y Volver usa `href="#"` | Component Spec S02/§6; FLOW-003 §4.1; tasks T12/T40–T43; UXG-002/009/013 | Implementar simulación contractual del guardado y `201 BORRADOR`, navegación/aviso de salida, guardando sin doble envío y recuperación ante resultado desconocido |
| R003-09 | P0 | Requisitos completos se afirman con checks estáticos aunque el formulario puede alterarse. El texto final reduce la activación a «ambas preparaciones» | SPEC-003 §5; Component Spec S02/S05; UXG-003/009/011 | Vincular el resumen a los valores y al modelo; distinguir datos locales de preparación confirmada. Explicar también imagen, atributos y físico completo, y conservar activación como acción posterior explícita |
| R003-10 | P0 | Solo existe un formulario precargado: sin default vacío, carga/error de maestros, guardando, SKU duplicado, error de guardado o resultado desconocido reproducibles | Component Spec S02/§13; plan §10; UXG-007/011/013/022 | Añadir escenarios deterministas con fuente y resultado por estado. No simular como HTTP publicado aquello que continúa bloqueado |
| R003-11 | P1 | H1 «NUEVO PRODUCTO», ID MK visible, «Motor MK-003 v2.4», «Producción PE-CENTRAL», «Admin Catálogo», Pricing y detalles de sincronización sin fuente de sesión/entorno | Component Spec microtexto S02; DESIGN §13; UXG-020/022 | Usar «Crear producto» y lenguaje de negocio. Quitar identificadores de documentación/motor del producto visible; etiquetar datos de demostración en evidencia. Acciones de sesión/roles requieren contexto real |
| R003-12 | P1 | Material Symbols, JetBrains Mono, sombras de cards, campos de borde decorativo, ayudas/labels de 12 px, foco naranja y formulario centrado con `mx-auto` | DESIGN §§4–5, 7–8, 12; Component Spec §12; tasks T51–T56 | Normalizar a Tabler, Inter operativa, tokens/radios/bordes y foco signal; cards sin sombra, formulario alineado a izquierda, tamaños y espaciados del DS |
| R003-13 | P0 | No hay resumen de errores ni regiones anunciables; radios ocultos sin foco visual equivalente y salida con cambios sin aviso | Component Spec C01/S02; DESIGN §12; UXG-002/021 | Asociar ayuda/error, explicar asteriscos, dar foco visible a selección y errores, anunciar resultado y gestionar confirmación de descarte |

## Cobertura observada

| Aspecto | Resultado | Evidencia / límite |
|---|---|---|
| Marca solicitada | Conforme al cambio solicitado | Logo compartido visible a izquierda, sin sustitución por letras IA |
| Shell desktop | Parcial | Header 64, sidebar 240, formulario 880; sin overflow horizontal a 1440. Alineación, tokens, navegación y controles aún requieren normalización |
| Formulario completo sin wizard | Parcial | Nombre/SKU/categoría/marca/precio/descripción/modelo/físico están presentes; faltan tipo, imagen y características |
| Alta independiente de activación | Parcial | CTA «Guardar borrador», sin botón de activar en el alta; el guardado no está implementado |
| Físico opcional en borrador, unidades kg/cm | Parcial | Texto y cuatro entradas presentes; validación positiva y condición simple/padre fallan |
| Carga, errores y recuperación | No conforme | Sin escenarios y sin comportamiento asociado |
| Accesibilidad y DS completos | No acreditados | Hallazgos R003-12/13; no se certifica cumplimiento integral por una captura |
| Normalización del prototipo | Pendiente | HTML con Tailwind CDN; no acredita React/TypeScript/Mantine, tema y componentes comunes ni ruta `/MK003/S02` |

## Alcance de la revisión y seguimiento

Solo se recibió S02 de las siete vistas de MK-003. S01/S03/S04/S05/S06/S07 no se acreditan por esta entrega. No se ha implementado la corrección del tipo de S03 ni se ha resuelto Q-06/T27; permanecen vigentes todas las preguntas contractuales y dependencias registradas.

Los hallazgos funcionales corresponden principalmente a T10–T12/T40–T43; normalización a T50–T56; su cierre requiere T60–T69 y evidencia nueva. Esta revisión no cambia ninguna tarea a DONE, no sustituye `validation-report.md` y no decide los contratos abiertos. El cambio aplicado en esta solicitud es la marca; los demás hallazgos quedan documentados para corrección.
