# Design System de mockups — Productos y Ofertas

**Versión:** 1.1.0 · **Fecha:** 2026-10-02 · **Responsable:** Leonardo Vera Rodríguez (`LeonardoVera`).
**Estado:** vigente para la especificación visual de mockups. Consolidación documental del [issue #60](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/issues/60), contrastada con la UX 2.0 del #59. La versión 1.1.0 incorpora gobernanza cromática y austeridad visual.

## 1. Propósito, alcance y fuentes

Este documento define foundations, componentes, variantes, estados y composición comunes a **MK-001 a MK-016**. Es la referencia visual del prototipo React y de su posterior representación en Figma. Cada owner consume estos valores en su `component-spec.md`; no vuelve a elegir una paleta o un sistema de controles para su funcionalidad.

Plataforma: **web desktop**, tema claro, viewport canónico de **1440 px de ancho**, mouse y teclado. La altura de revisión inicial es 900 px, como referencia de composición, sin exigir que todo el contenido entre en una pantalla. La página permite desplazamiento vertical. No se incluyen variantes mobile/tablet ni un tema oscuro; usar ink en una zona de navegación no constituye un modo oscuro.

| Fuente | Función y precedencia |
|---|---|
| [Propuesta UX](ux/propuesta-ux.md), [UX Decisions](ux/ux-decisions.md), [UX Guidelines](ux/ux-guidelines.md) | Definen interacción y sus condiciones. Este documento representa esas decisiones sin reemplazar su justificación |
| [Índice y fuentes de las 16 funcionalidades](ux/propuesta-ux.md#7-trazabilidad-de-las-16-funcionalidades), [wireframes/INDEX](../wireframes/INDEX.md) | SPEC/HU definen negocio; WF/FLOW definen estructura y recorridos. Una regla visual no agrega operaciones, permisos o campos |
| [OpenAPI](../api/openapi.yaml), [AsyncAPI](../asyncapi/asyncapi.yaml), [Contrato API](../Contrato_Api.md) | Determinan datos, comandos y resultados disponibles. Un fixture no publica una capacidad |
| [wireframes/DESIGN.md](../wireframes/DESIGN.md) | Antecedente de baja fidelidad, auditado en §3; no es el Design System de mockups |
| Guía UX UI del Marketplace Multicanal, adjunta por el usuario | Referencia de marca Inka Athletics: colores, Oswald/Inter, espaciado, radios, iconos y lenguaje. Sus instrucciones de edición/publicación, ejemplos de compra y placeholders no son una autorización para actuar en Figma ni requisitos funcionales de este módulo |
| [Pipeline](README.md), [component-spec](_plantillas/mockup/component-spec.template.md), [plan](_plantillas/mockup/plan.template.md), [tasks](_plantillas/mockup/tasks.template.md), [prototipo](prototipo/README.md) | Definen separación documental, ejecución y validación posterior |

La guía identifica un [archivo central de Figma](https://www.figma.com/design/rKPdRQHLLUkYk5VdiEErqZ/Sistema-De-Dise%C3%B1o?node-id=57-15). Se adoptan los valores escritos en la guía, no se afirma haber inspeccionado o publicado su biblioteca. Los organismos incompletos de la guía se concretan aquí para el backoffice. Ante una actualización del sistema central, se revisa su impacto y se versiona este documento.

El #59 está cerrado en GitHub al momento de esta revisión. Sus documentos aún registran hallazgos funcionales/contractuales; su cierre no acredita que esas fuentes hayan cambiado. Este Design System no los resuelve mediante estados visuales ficticios ni vuelve a abrir la selección UX.

## 2. Relación con UX transversal

La visión adoptada es **estado verificable, complejidad pertinente y recuperación segura**. La representación visual se concreta así:

| UXD | UXG | Representación consistente en este Design System |
|---|---|---|
| [UXD-001](ux/ux-decisions.md#uxd-001) | 001–002 | Shell estable, detalle contextual o vista completa, retorno con filtros; aviso de cambios sin guardar (§5, §7, §8) |
| [UXD-002](ux/ux-decisions.md#uxd-002) | 003–004 | Grupos de formulario y campos condicionales; stepper solo con dependencia real (§7, §8) |
| [UXD-003](ux/ux-decisions.md#uxd-003) | 005 | Tabla legible, toolbar solo para operaciones permitidas; 014/016 en lectura (§9) |
| [UXD-004](ux/ux-decisions.md#uxd-004) | 007–008 | Skeleton inicial, loader localizado, actualización conservando contexto (§10) |
| [UXD-005](ux/ux-decisions.md#uxd-005) | 011 | Error junto al campo, alert persistente, toast complementario (§11) |
| [UXD-006](ux/ux-decisions.md#uxd-006) | 006 | Filtros con estado aplicado, validación proporcional y avisos SEO no bloqueantes (§8) |
| [UXD-007](ux/ux-decisions.md#uxd-007) | 009–010 | Badge de admisión/procesamiento distinto de éxito; panel de seguimiento (§10) |
| [UXD-008](ux/ux-decisions.md#uxd-008) | 012 | Bloque parcial con resultados confirmados y pendientes; fecha conocida (§10) |
| [UXD-009](ux/ux-decisions.md#uxd-009) | 013–016 | Recuperación localizada y comparación de conflicto; acción específica respaldada (§11) |
| [UXD-010](ux/ux-decisions.md#uxd-010) | 017 | Vacío, null, cero y no disponible con textos diferentes (§9, §10) |
| [UXD-011](ux/ux-decisions.md#uxd-011) | 018–019 | Confirmación con entidad e impacto; recepción final con resumen de faltantes (§7, §11) |
| [UXD-012](ux/ux-decisions.md#uxd-012) | 020–022 | Texto de negocio, controles etiquetados, foco, teclado y trazabilidad (§12–§15) |

Un componente disponible no obliga a usarlo. Un drawer, wizard, toast o checkbox de selección no se introduce por el número del MK. El component-spec decide cuáles corresponden según estas condiciones y sus fuentes.

## 3. Auditoría de transición desde wireframes y guía multicanal

| Grupo / regla previa | Tratamiento | Regla de mockups |
|---|---|---|
| Color: escala exclusivamente gris y primary casi negro | Reemplazar | Roles de marca y estado de §4.1; neutros para lectura y acentos funcionales |
| Tipografía: Inter general, display de 48 px y anotaciones Roboto Mono | Adaptar / retirar anotación visible | Oswald H1–H3 e Inter para operación; escala de §4.2, sin notas técnicas en UI |
| Espaciado: múltiplos de 8 y tokens 4/8/16/32/64 | Adaptar | Escala 4/8/16/24/32 de la guía; gap y padding con roles explícitos |
| Layout y grid: 12 columnas desktop, 4 mobile | Conservar desktop / retirar mobile | Shell administrativo de 1440 px y grid interior de 12 columnas; no heredar el container de storefront |
| Bordes: todos los contenedores delimitados con neutral-30 | Adaptar | Divisor decorativo tenue; borde identificable de controles más fuerte y foco propio |
| Radios: 0/4/8/full y predominio de 4 | Reemplazar | 4/8/12/16/full por rol, conforme a guía (§4.4) |
| Elevación: prohibición absoluta de sombras | Retirar prohibición | Sombras solo para capas flotantes; cards/listados planos y overlay medido (§4.5) |
| Componentes: bloques neutros sin variantes completas | Adaptar | Catálogo con dimensiones, variantes y estados; reutilización sin inventar capacidades |
| Iconografía: figuras genéricas y círculos | Reemplazar | Tabler Icons, 16/20/24 px, stroke 2, currentColor |
| Accesibilidad: contraste máximo afirmado y referencia táctil mobile 44 px | Adaptar | Contrastes calculados para pares reales; controles desktop 32/40/48 px y teclado. No declarar AAA global por la paleta |
| Estados: estructura estática de wireframe | Ampliar | Estados de interacción y sistema separados, parciales y desconocidos incluidos |
| Contenido: placeholders visuales y texto simulado | Adaptar | Fixtures realistas, copy operativo y fotografías/activos autorizados cuando aportan información |
| Restricciones: sin fotografía ni logo final | Deja de aplicar | Usar activos disponibles con proporción conservada; no inventar logotipos o productos reales |
| Guía: naranja/volt/signal y semánticos | Conservar / completar | Mantener roles; añadir tonos de texto semántico y borde fuerte para contraste |
| Guía: responsive y variantes de compra/pago | No aplicar al alcance | Desktop y Gestor Comercial; sin carrito, compra ni checkout por conveniencia visual |
| Guía: longitudes sugeridas de campos y badges | No adoptar como negocio | Longitudes provienen de SPEC/contrato. Badge breve por composición, sin recortar estados críticos |
| Guía: tema de ejemplo con tonalidades «...» | Reemplazar ejemplo incompleto | Tokens completos por rol en §4.1 y correspondencia con tema central en §15; ningún owner rellena paletas por su cuenta |
| Guía: motivos diagonales, hero, alternancia emocional de fondos | No aplicar al backoffice | Shell claro y navegación estable; sin decoración de campaña en tareas administrativas |

## 4. Foundations

### 4.1 Color y roles

Los nombres con `/` son nombres canónicos de variables en documentación/Figma. El código puede exponerlos mediante un objeto tipado y variables CSS. Los HEX son definitivos para esta versión; no sustituirlos por una tonalidad «aproximada» del framework.

| Token | HEX | Uso |
|---|---|---|
| color/surface/cloud | #F7F5F0 | Fondo de la página |
| color/surface/default | #FFFFFF | Cards, formularios, campos y capas flotantes |
| color/surface/cloud-subtle | #EDEAE2 | Header de tabla, hover neutro, zonas de lectura secundarias |
| color/surface/ink | #1B1812 | Zona de marca del header; texto principal por alias |
| color/text/primary | #1B1812 | Texto normal, cifras y etiquetas |
| color/text/secondary | #495057 | Ayudas, placeholders, metadatos y explicaciones |
| color/text/inverse | #F7F5F0 | Texto sobre ink y botón primario hover/active |
| color/text/on-signal | #FFFFFF | Texto sobre signal |
| color/text/disabled | #868E96 | Solo contenido de controles realmente deshabilitados; no para información secundaria necesaria |
| color/border/default | #DEE2E6 | Divisores decorativos y bordes de card; no única delimitación de un input |
| color/border/control | #868E96 | Delimitación de inputs/checks sobre blanco o cloud |
| color/border/hover | #495057 | Borde de control al hover |
| color/action/primary | #F76707 | Fondo del botón principal, con texto ink |
| color/action/primary-hover | #C2410C | Hover/active del botón principal, borde de acción y enlaces |
| color/action/primary-soft | #FCE3D0 | Selección/filtro activo con texto ink |
| color/selection/background | #FCE3D0 | Alias de primary-soft |
| color/selection/indicator | #C2410C | Borde/check/indicador de selección; texto de selección usa ink |
| color/focus/default | #4361EE | Alias de signal; anillo de foco |
| color/accent/signal | #4361EE | Acento de marca; no equivale a éxito o información |
| color/accent/signal-soft | #E1E6FB | Fondo complementario de marca; texto ink |
| color/accent/volt | #C3E504 | Distintivo promocional discreto con texto ink, cuando existe dato de promoción |
| color/accent/volt-soft | #EEF7B0 | Variante suave de promoción; no representa stock confirmado |
| color/success/default | #2F9E44 | Icono/borde de confirmación |
| color/success/background | #EBFBEE | Fondo suave de resultado confirmado |
| color/success/text | #1C6B30 | Texto corto de éxito cuando se requiere color semántico |
| color/warning/default | #F08C00 | Acento decorativo de advertencia, acompañado por texto/icono oscuros |
| color/warning/background | #FFF9DB | Fondo suave de advertencia/parcial |
| color/warning/text | #8A4B00 | Icono, borde significativo y texto corto de advertencia |
| color/error/default | #E03131 | Borde/icono de error sobre blanco o error-background |
| color/error/background | #FFF5F5 | Fondo suave de error |
| color/error/text | #B42318 | Mensaje de error y texto de validación |
| color/error/strong | #B42318 | Botón destructivo con texto blanco; coincide con error-text |
| color/info/default | #1971C2 | Texto/icono/borde informativo |
| color/info/background | #E7F5FF | Fondo suave de información o seguimiento |
| color/disabled/background | #EDEAE2 | Fondo de control deshabilitado |
| color/disabled/border | #DEE2E6 | Borde de control deshabilitado |

La paleta de marca y fondos proviene de la guía. Blanco para superficies, borde de controles y tonos success-text/warning-text/error-text/strong son extensiones operativas documentadas para legibilidad. No se cambia el significado de los semánticos.

Texto de alerts/badges usa ink; el texto corto semántico puede usar su token `text`. **No usar naranja vivo para enlaces o texto pequeño, blanco sobre primary/volt, ni warning-default como único icono significativo.** No aplicar opacity global a un contenido legible para simular disabled. Sobre fondos suaves, el indicador de selección se acompaña por check/borde y texto ink, no texto naranja oscuro de contraste insuficiente. Un control sobre cloud-subtle usa border-hover como delimitación; border-control está validado sobre blanco/cloud y no se generaliza a cualquier fondo.

#### Pares verificados

Ratios calculados con luminancia relativa sRGB, usando colores sólidos; las decisiones de aprobación usan el resultado sin redondear. El ratio publicado se redondea a dos decimales. La implementación debe verificar también estilos efectivos, estados y overlays.

| Texto / indicador | Fondo | Contraste | Uso admitido |
|---|---|---|---|
| #1B1812 | #F7F5F0 | 16.25:1 | Texto principal de página |
| #495057 | #F7F5F0 | 7.50:1 | Ayudas y texto secundario |
| #495057 | #FFFFFF | 8.18:1 | Placeholder, ayuda y cuerpo secundario |
| #1B1812 | #F76707 | 5.82:1 | Etiqueta de botón primario default |
| #F7F5F0 | #C2410C | 4.75:1 | Etiqueta de botón primario hover/active |
| #FFFFFF | #4361EE | 5.02:1 | Distintivo de marca signal |
| #4361EE | #F7F5F0 | 4.61:1 | Anillo de foco sobre cloud |
| #868E96 | #FFFFFF | 3.32:1 | Borde identificable del input |
| #868E96 | #F7F5F0 | 3.05:1 | Borde identificable sobre página |
| #1C6B30 | #EBFBEE | 6.12:1 | Texto de éxito |
| #8A4B00 | #FFF9DB | 6.42:1 | Texto/icono de advertencia |
| #1971C2 | #E7F5FF | 4.52:1 | Texto informativo |
| #B42318 | #FFF5F5 | 6.15:1 | Texto de error |
| #FFFFFF | #B42318 | 6.57:1 | Etiqueta de botón destructivo |
| #1B1812 | #C3E504 | 12.25:1 | Distintivo de promoción |

El error usa el tono más oscuro en texto y botón destructivo; sus pares con blanco/error-background se verifican junto a los anteriores. Un borde tenue es decorativo y no acredita contraste de un control. Referencias de umbral: [WCAG contraste de texto](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) y [contraste no textual](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).

#### 4.1.1 Política de austeridad cromática y presupuesto visual

Los tokens disponibles no constituyen una paleta decorativa. La existencia de un color en el sistema no autoriza a utilizarlo para diferenciar categorías, módulos, tipos de entidad o bloques visuales.

La composición normal del backoffice debe estar dominada por superficies y contenido neutros: surface/cloud, surface/default, surface/cloud-subtle, text/primary, text/secondary y border/default/control.

El color se introduce únicamente cuando comunica una de estas funciones:
1. acción primaria;
2. selección o navegación activa;
3. foco;
4. estado semántico confirmado;
5. información/promoción cuando la semántica lo justifica.

Ante la duda sobre qué color corresponde a un elemento, usar la variante neutral. Nunca crear un nuevo significado cromático local.

Reglas obligatorias de uso por token:

- **Naranja primary #F76707:** usar como fondo de la acción primaria y en elementos de marca autorizados. No utilizar como color genérico de iconos, métricas, labels, encabezados, SKU, estados o decoración.
- **Primary-hover #C2410C:** puede utilizarse para enlaces y estados hover/active conforme a este documento. Los enlaces deben seguir siendo reconocibles mediante subrayado en hover/focus cuando corresponda. No convertir todos los textos interactivos en naranja.
- **Focus:** TODO foco interactivo de controles debe utilizar `color/focus/default` #4361EE. Está prohibido utilizar naranja como sustituto del anillo de foco. Error y foco pueden coexistir: borde error + ring focus.
- **Selection:** usar `color/selection/background` #FCE3D0 + `color/selection/indicator` #C2410C + texto ink (#1B1812). No usar fondo naranja vivo para representar selección.
- **Success:** únicamente para resultados realmente confirmados, disponibles o completados cuando esa semántica corresponde. No utilizar verde para representar simplemente una categoría, un tipo de entidad o «algo positivo visualmente».
- **Warning:** únicamente para advertencias, resultados parciales o situaciones que requieren atención. No utilizar amarillo/ámbar para diferenciar una categoría arbitraria.
- **Error:** únicamente para errores, estados críticos o acciones destructivas. No utilizar rojo para jerarquía visual ordinaria.
- **Info:** únicamente para información, seguimiento o estado informativo. No utilizar azul para diferenciar un tipo de producto, regla o entidad.
- **Volt:** únicamente para contenido promocional real. No utilizar volt/lime para identificar categorías, taxonomías, estados de inventario u otras entidades.

Está prohibido introducir directamente escalas cromáticas del framework o valores locales cuando existe un token de este Design System.

Ejemplos prohibidos:
- emerald-50 / emerald-600 / emerald-800;
- green-*;
- amber-*;
- yellow-*;
- rose-*;
- red-*;
- blue-*;
- orange-*;
- lime-*;
- colores HEX nuevos definidos directamente por cada owner.

Los nombres anteriores son ejemplos, no una lista exhaustiva.

Si un estado necesita success, warning, error o info, debe utilizar los tokens correspondientes de §4.1. Si no existe una semántica correspondiente, utilizar neutros. Tailwind/Mantine puede implementar internamente los estilos, pero el valor visual final debe corresponder a los tokens del DESIGN.md.

Los owners no pueden introducir colores HEX locales ni familias cromáticas fuera de los tokens vigentes de este Design System.

Si aparece una necesidad cromática transversal que no puede representarse correctamente con los tokens existentes, NO se resuelve agregando un HEX directamente en un MK. La necesidad debe proponerse primero como una modificación versionada de DESIGN.md, con:
- propósito semántico;
- casos de uso;
- contraste;
- componentes afectados;
- MK afectados;
- justificación de por qué los tokens actuales no son suficientes.

Solo después de aprobar y versionar esa modificación puede utilizarse el nuevo token.

**Iconografía y color**

- Los iconos sin significado semántico usan por defecto:
  - `color/text/primary`; o
  - `color/text/secondary`.
- No utilizar primary, signal, success, warning, error, info o volt en un icono únicamente para:
  - decorar;
  - diferenciar cards;
  - aportar variedad;
  - «hacer más visual» una tabla;
  - hacer que cada KPI parezca distinto.
- Un icono puede usar un color semántico únicamente cuando ese icono comunica el mismo estado semántico que el componente.

Ejemplos:
- **PERMITIDO:**
  - `IconAlertTriangle` con warning dentro de un Alert de advertencia.
  - `IconCircleCheck` con success dentro de un resultado confirmado.
  - `IconAlertCircle` con error dentro de un mensaje de error.
- **NO PERMITIDO:**
  - icono azul para «Producto»;
  - icono naranja para «Combo»;
  - icono verde para «Inventario»;
  - un icono de diferente color en cada KPI únicamente por decoración.

Si el color del icono desaparece y se pierde información necesaria, debe existir además texto, label o símbolo que comunique el significado.

**Regla contra propagación de color:**

Un mismo estado no debe colorear innecesariamente toda una región.

Por defecto, comunicar un estado mediante un componente localizado:
- Badge;
- Alert;
- icono;
- indicador/borde;
- texto semántico cuando realmente sea necesario.

Evitar utilizar simultáneamente para el mismo mensaje:
- fondo de card coloreado;
- borde de card coloreado;
- icono coloreado;
- título coloreado;
- cifra coloreada;
- badge coloreado.

Elegir la mínima cantidad de señales suficiente para reconocer el estado. Esto no impide que un Alert utilice su fondo semántico completo, porque ese componente está específicamente diseñado para feedback.

### 4.2 Tipografía

Familia operativa: `Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`. Títulos H1–H3: `Oswald, "Segoe UI", sans-serif`. Usar pesos 400/500/600/700; cargar solo los usados. H1–H3 se representan en mayúsculas mediante estilo, sin modificar el texto almacenado. El resto usa mayúscula inicial normal.

| Token | Familia | Tamaño / línea | Peso | Uso |
|---|---|---|---|---|
| type/heading/h1 | Oswald | 32 / 40 px | 700 | Un título por página |
| type/heading/h2 | Oswald | 28 / 36 px | 700 | Sección principal |
| type/heading/h3 | Oswald | 24 / 32 px | 700 | Subsección |
| type/heading/h4 | Inter | 20 / 28 px | 700 | Título de card, drawer o modal |
| type/subtitle | Inter | 18 / 26 px | 600 | Introducción o subcabecera |
| type/body | Inter | 16 / 24 px | 400 | Texto principal y valores de formulario |
| type/body/small | Inter | 14 / 20 px | 400 | Tabla, filtros y contenido compacto |
| type/label | Inter | 14 / 20 px | 600 | Labels y botones; encabezados de tabla |
| type/help | Inter | 14 / 20 px | 400 | Ayuda y validación necesaria para completar la tarea |
| type/auxiliary | Inter | 12 / 16 px | 400 | Metadatos complementarios y timestamp secundario |
| type/kpi | Inter | 28 / 36 px | 600 | Cifra principal de KPI con unidad/etiqueta |

Letter-spacing 0 en todos los estilos. Se adapta la ayuda de 12 px de la guía a 14 px cuando es necesaria para operar. Acciones y contenido principal no usan 12 px. Los números comparables usan cifras tabulares (`tabular-nums`); SKU sigue siendo texto operativo legible y copiable, sin fuente monoespaciada obligatoria. Oswald no se usa en inputs, tablas, badges o labels.

Si las fuentes no cargan, los fallbacks conservan legibilidad; el prototipo debe validar de nuevo saltos de línea y alturas tras cargarlas. La distribución oficial de fuentes se define al implementar el entorno, sin exigir acceso a Google Fonts en cada sesión de revisión.

### 4.3 Espaciado

| Token | Valor | Aplicación |
|---|---|---|
| spacing/xs | 4 px | Label–control y valor–mensaje cercano |
| spacing/sm | 8 px | Icono–texto, botones relacionados, padding vertical compacto |
| spacing/control-inset | 12 px | Extensión de composición (xs + sm): padding interno horizontal de inputs y textarea; no sustituye gaps estándar |
| spacing/md | 16 px | Gap entre campos, padding de celda horizontal, grupo de controles |
| spacing/lg | 24 px | Padding de card/drawer/modal y separación de bloques |
| spacing/xl | 32 px | Margen del contenido y separación entre secciones principales |

Se combinan tokens para dimensiones de layout; no se confunden alturas de control o tamaños de icono con gaps. Formulario: 16 px entre campos y 24 px entre grupos. Encabezado: 8 px entre título y descripción, 24 px hasta filtros/contenido. Actions: 8 px entre botones. No introducir gaps locales arbitrarios.

### 4.4 Bordes, radios y foco

| Token | Valor | Uso |
|---|---|---|
| border/default | 1 px solid | Divisor/card con border-default, control con border-control |
| border/emphasis | 2 px solid | Indicador activo de tab y error resaltado sin alterar caja |
| radius/none | 0 px | Borde del shell y drawer pegado al viewport |
| radius/xs | 4 px | Checkbox y control compacto |
| radius/sm | 8 px | Botón, input, select, menú |
| radius/md | 12 px | Cards y bloques de resultado |
| radius/lg | 16 px | Modal |
| radius/full | 999 px | Badge/chip y radio |
| focus/width | 2 px | Outline visible en signal |
| focus/offset | 2 px | Separación del outline respecto del control |

El anillo externo se aplica sobre blanco/cloud; dentro del header ink se añade separación clara de 2 px antes del anillo signal, evitando perder foco sobre superficie oscura. Foco y error pueden coexistir: conservar borde rojo y anillo signal. El grosor de hover/active no desplaza contenido; usar outline/inset o box-sizing estable.

### 4.5 Elevación, capas y movimiento

| Token | Valor CSS / orden | Uso |
|---|---|---|
| elevation/none | none | Página, cards, formulario y tabla |
| elevation/floating | 0 4px 12px rgba(27,24,18,0.12) | Menú, select, tooltip y popover |
| elevation/dialog | 0 12px 32px rgba(27,24,18,0.18) | Modal y drawer |
| overlay/default | rgba(27,24,18,0.40) | Bloquea interacción de fondo en dialog modal |
| layer/sticky | 100 | Header, cabeceras de tabla y footer de formulario |
| layer/floating | 200 | Menú/tooltip en página |
| layer/overlay | 300 | Overlay del dialog |
| layer/dialog | 310 | Modal/drawer |
| layer/dialog-floating | 320 | Select/menú/tooltip dentro del dialog |
| layer/notification | 400 | Notificación sin tapar controles requeridos |
| motion/feedback | 120 ms ease-out | Cambio suave de fondo/borde |
| motion/panel | 160 ms ease-out | Apertura/cierre de capas |

No encadenar modales. Los menús dentro de un dialog respetan su capa y contexto de foco. Preferencia de movimiento reducido: sin transición de panel ni shimmer, manteniendo texto de estado. No animar números o porcentajes para aparentar progreso; estos tiempos describen animación visual, no duración del backend.

### 4.6 Iconografía y activos

Tabler Icons es el set único: 16 px en tabla/badge compacto, 20 px en control estándar, 24 px en navegación o empty state; stroke 2 y `currentColor`. Icono–texto: 8 px. Iconos decorativos no reciben foco ni anuncio separado; acciones solo-icono usan control con etiqueta accesible.

Ejemplos: búsqueda `IconSearch`, agregar `IconPlus`, editar `IconPencil`, detalle `IconEye`, descarga `IconDownload`, cerrar `IconX`, advertencia `IconAlertTriangle`, error `IconAlertCircle`, éxito `IconCircleCheck`, información `IconInfoCircle`, actualizar `IconRefresh`. La etiqueta determina la acción, no el icono por sí solo. Referencia: [Tabler para React](https://docs.tabler.io/icons/libraries/react).

Los logotipos conservan proporción y colores autorizados; no se redibujan. El shell puede usar texto «Inka Athletics» hasta disponer del activo oficial verificado. Las imágenes de catálogo se muestran con `object-fit: contain`, sin inferir variantes ni estado del producto. Imagen ausente usa icono y «Sin imagen»; no una X de wireframe. Miniatura común: 48 × 48 px; imagen de detalle: región cuadrada de 240 px, ampliable dentro del espacio disponible.

## 5. Layout desktop

### 5.1 Shell canónico

| Región / token | Valor y composición |
|---|---|
| layout/header-height | 64 px, fijo arriba; ink y texto inverse. Marca a izquierda, contexto del módulo, acciones de sesión solo si la aplicación las provee |
| layout/sidebar-width | 240 px, bajo header, superficie default, borde derecho decorativo, scroll propio si es necesario |
| layout/page-padding | 32 px a cada lado y arriba/abajo del área principal |
| layout/content-width | A 1440 px: 1440 − 240 − 64 = **1136 px** útiles antes del espacio de scrollbar |
| layout/grid-columns | 12 columnas dentro del área útil, gutter 24 px; ancho de columna de referencia (1136 − 11×24)/12 = 72.67 px |
| layout/form-max-width | 880 px; formulario breve hasta 640 px; alineado a izquierda, sin cambiar márgenes del shell |
| layout/field-two-columns | Dos campos equivalentes con gap 24 px; cada uno recibe la mitad del ancho disponible |
| layout/section-gap | 32 px entre secciones principales; 24 px entre bloques relacionados |

El área principal tiene `min-width: 0`; columnas y toolbar pueden envolver sin ensanchar la página. El grid es una regla de composición, no una obligación de poner todos los controles en 12 columnas visibles. A anchos desktop mayores, shell estable y contenido fluido; respetar max-width de formularios. No usar el container storefront de 1320 px dentro de un área que solo dispone de 1136 px.

Orden vertical: breadcrumbs → título/descripcion y acción primaria → filtros si aplican → resumen/estado → contenido → paginación/acciones finales. La cabecera de página alinea título a izquierda y acciones a derecha. Si los textos no caben, las acciones pasan a la siguiente línea; no se truncan botones ni el título.

### 5.2 Navegación

Sidebar organizada por **Catálogo**, **Promociones**, **Clasificación y SEO**, **Precios**, **Inventario**, mostrando las funcionalidades que correspondan al acceso real. Grupos nombran tareas, sin números WF/MK visibles. El orden exacto de pantallas y enlaces respeta WF/FLOW; no se añade acceso a checkout o funciones de otros módulos.

Ítem de sidebar: altura mínima 40 px, padding horizontal 16 px, icono 20 px y label Inter 14/20. Activo: fondo primary-soft, texto ink, indicador vertical de 2 px primary-hover y estado actual accesible. Hover neutro cloud-subtle; foco independiente. Los grupos no requieren iconos adicionales decorativos.

Breadcrumbs Inter 14/20, gap 8 px, enlaces subrayables en primary-hover; último elemento no interactivo con texto primary. No más jerarquía que la navegación real; texto largo envuelve. Un vínculo «Volver a…» conserva contexto, sin depender solo del historial del navegador. Mantener una salida visible de detalles/paneles.

## 6. Estados comunes de componentes

Los estados de interacción no son enums de negocio. Un campo puede estar seleccionado y enfocado, o tener error y foco. En Figma/modelo usar propiedades separadas para selección, validez e interacción, sin multiplicar combinaciones que no existen.

| Estado | Representación y comportamiento |
|---|---|
| default | Superficie, tipografía y borde según componente |
| hover | Fondo/borde definido; ningún texto pierde contraste, no cambia el tamaño |
| focus | Anillo de §4.4; visible al usar teclado y no oculto bajo sticky/capa |
| active / pressed | Botón primario usa primary-hover e inverse; control terciario usa cloud-subtle. Sin desplazamiento de caja |
| selected / checked | Check, punto, indicador o subrayado más fondo/contraste; no solo color |
| disabled | Fondo disabled, borde disabled y texto disabled; causa visible en ayuda próxima cuando importa. Sin acciones ni hover activo |
| read-only | Valor legible en primary, seleccionable/copiable cuando corresponde; no se representa con texto disabled |
| loading | Indicador cercano y etiqueta estable; bloquear repetición incompatible, conservar anchura y contexto |
| success | Texto de resultado y check con tokens success; solo al confirmarse lo pertinente |
| warning | Texto explicativo y triángulo warning-text, fondo warning-background; no bloquea salvo requisito funcional |
| error | Borde error, mensaje error-text y explicación accionable; abrir sección afectada |

Un badge informativo tiene variante semántica, no estados hover/focus/pressed. El error de una operación se presenta asociado a la tarea; no se inventa un estado rojo del botón de guardar. Tooltips no son el único canal para explicar disabled o requisitos.

## 7. Catálogo de componentes compartidos

Nombres `PO/…` identifican componentes en documentación/Figma, sin aparecer en la interfaz. Medidas a escala 1×; tipografía y tokens anteriores son comunes.

| ID / componente | Variantes y dimensiones | Uso / estados y límites |
|---|---|---|
| DS-C01 PO/Button | sm: 32 px alto, md: 40, lg: 48; Inter 14/20 600; padding horizontal 16/24/24; radio 8; icono 16/20/20; gap 8 | Filled primary, outline secondary, subtle tertiary, destructive. Default/hover/focus/pressed/disabled/loading. md por defecto, lg solo si hay uso justificado; ancho por contenido, mínimo 96 px para botón con texto |
| DS-C02 PO/ActionIcon | Área 32×32 o 40×40, icono 16/20, radio 8 | Acciones de fila/cerrar; nombre accesible, tooltip opcional y label visible cuando la acción es crítica. No icono con click suelto |
| DS-C03 PO/TextInput | sm 32 px, md 40; padding horizontal 12 px, radio 8, label arriba | Valor md 16/24, compacto 14/20. Default/hover/focus/filled/disabled/read-only/error; loading solo si consulta/validación realmente en curso |
| DS-C04 PO/NumberInput | Medidas de TextInput; unidad visible junto al label o sufijo | Precio, cantidad, límites, peso/dimensiones según SPEC. No usar formato visual como validación de negocio; precisión/min/max provienen de fuente |
| DS-C05 PO/Textarea | md, altura inicial 104 px, padding 12 px, radio 8; crecimiento con contenido | Descripción y notas. Label/ayuda/error; sin máximo universal de caracteres ni resize que ensanche la página |
| DS-C06 PO/Select | sm 32 / md 40; lista al ancho del control; opciones mínimo 36 px, máximo visible 288 px con scroll | Valor de entidad/tipo conocido; búsqueda si lista extensa. Default/focus/open/selected/disabled/loading/error; no creación de maestros desde texto libre sin capacidad |
| DS-C07 PO/MultiSelect | Altura mínima 40 px, pills envuelven, radio 8; dropdown como Select | Múltiples valores solo si fuente permite cardinalidad; remover con nombre accesible. No aplicar al producto con una categoría por conveniencia |
| DS-C08 PO/Checkbox | Caja 18 px sm / 20 md; label clicable, área conjunta mínimo 32 px alto; gap 8 | Selección independiente/múltiple; unchecked/checked/indeterminate y hover/focus/disabled/error. Seleccionado primary + check ink y borde primary-hover |
| DS-C09 PO/RadioGroup | Círculo 20 px, label clicable, filas mínimo 32 px, gap 8; separación de opciones 16 | Opciones mutuamente excluyentes; punto ink sobre primary, borde primary-hover; grupo con nombre, teclado y ayuda/error |
| DS-C10 PO/Switch | Track 40×24 px, área etiquetada mínimo 32 px alto; on con primary-hover y thumb blanco | Solo cambio binario directo permitido. Si activación exige comprobación, usar acción explícita y seguimiento, sin fingir cambio inmediato |
| DS-C11 PO/DateField | md 40 px; calendario en popover con padding 16, días con área mínimo 32×32 | Fecha/rango y hora cuando contrato lo requiera; formato legible, zona horaria indicada si afecta vigencia. No fijar fechas límite por diseño |
| DS-C12 PO/Search | TextInput con IconSearch 20 y limpiar 32×32; label de tarea | Búsqueda soportada; loader localizado, sin resultados y error distinguibles; no timeout/debounce universal |
| DS-C13 PO/FilterBar | Card plana, padding 16, gaps 16; filtros sm/md, acciones gap 8; fila de pills abajo con gap 8 | «Aplicar filtros» cuando corresponda, «Limpiar filtros», cantidad conocida. Envuelve sin overflow; parámetros y orden admitidos |
| DS-C14 PO/Badge | sm mínimo 24 px alto / md 28, padding horizontal 8/12, texto Inter 14/20 500, radio full | Neutral/info/success/warning/error/promotion; estado en palabras e icono si ayuda. No botón ni truncamiento de estado crítico. Que un valor sea un estado de negocio no significa automáticamente que sea un estado semántico. Estados de negocio que NO requieren necesariamente color semántico: «Activo», «Inactivo», «Borrador», «Publicado», «Archivado», «Individual», «Masivo», «Automática», «Cupón», «Producto», «Categoría». Estos valores pueden presentarse con Badge neutral cuando no representan éxito, riesgo, error, advertencia, seguimiento o atención requerida. `Activo` NO debe mapearse automáticamente a success/verde en todos los MK; si «Activo» es simplemente el estado ordinario y esperado de una entidad, puede y preferentemente debe representarse de forma neutral. `Inactivo` NO debe mapearse automáticamente a error o warning. `Disponible` solo debe usar success cuando la disponibilidad constituye un resultado semántico relevante para la tarea actual; en una tabla donde es simplemente un estado ordinario, puede utilizar neutral. `Procesando` puede utilizar info cuando representa seguimiento de una operación en curso. `Stock bajo` sí puede utilizar warning porque requiere atención. `Agotado` puede utilizar error/warning según la severidad definida por la tarea, pero no debe asumirse automáticamente sin contexto. Las variantes semantic no se utilizan para diferenciar categorías visualmente («Venta cruzada» vs «Upselling», «Producto» vs «Categoría», «Individual» vs «Masivo» y diferentes tipos de catálogo deben utilizar por defecto una presentación neutral, salvo semántica transversal documentada) |
| DS-C15 PO/Chip y PO/Pill | Chip mínimo 32 px alto, pill 32 si removible; padding 12, gap 8, radio full | Chip seleccionable con indicador; pill de filtro aplicado con remover nombrado y área 24×24 dentro. No convertir badge en control |
| DS-C16 PO/Tooltip | Padding 8, máximo 280 px ancho, fondo ink/texto inverse, radio 8 | Complemento breve visible por hover/foco; nunca contiene acción, requisito o error como única fuente; no sobre control nativo disabled inaccesible |
| DS-C17 PO/Table | Header mínimo 40 px; fila default mínimo 48 / compacta 40; padding horizontal 16 | Comparación administrativa con reglas §9. Tabla semántica; selección/ordenamiento solo si permitidos. Carga/error/empty corresponden a región, no valores inventados |
| DS-C18 PO/Pagination | Botones 32×32, gap 8, texto 14/20; footer padding 16 | Página actual con fondo seleccionado y numeral visible. Contador/tamaño de página según contrato; no imponer total o «ir al final» si no existe |
| DS-C19 PO/Card y PO/Kpi | Padding 24, radio 12, borde decorativo, sin sombra; KPI etiqueta 14/20, cifra 28/36 | Agrupar información relacionada; no card clicable sin destino explícito. Card y KPI son neutros por defecto. Un KPI no recibe un color distinto solo para distinguirse de otro KPI. La composición base debe utilizar superficie blanca, borde neutral, título secondary, valor primary e icono neutral cuando no existe estado. Un estado semántico puede introducir un indicador localizado. No utilizar una paleta diferente para cada KPI de un dashboard. No colorear simultáneamente cifra, icono, borde y fondo salvo que el componente represente explícitamente un Alert/Result y no un KPI ordinario. Estado parcial/antigüedad por sección; unidad y fuente del dato |
| DS-C20 PO/Drawer | Derecha; ancho 480 px breve / 640 px con detalle ampliado; padding 24, sin radio en unión al viewport, sombra dialog | Elegido según UXD-001, no obligatorio. Header con título y cerrar 40×40, body scroll, footer de acciones; modal si bloquea fondo. Foco/retorno y cambios sin guardar |
| DS-C21 PO/Modal | Ancho 480 px confirmación / 640 formulario breve; max-height calc(100vh − 64px); padding 24, radio 16 | Título, contenido, impacto, cancelar y acción específica. Overlay y foco contenido; Escape/cierre no descarta trabajo sin aviso. Usar vista completa para configuración extensa |
| DS-C22 PO/Alert y PO/Result | Padding 16 para alert / 24 resultado; icono 20, gap 8, radio 12; texto 16/24 o 14/20 contextual | Info/success/warning/error, título opcional 14/20 600. Persistente para parcial/crítico; acciones localizadas y contenido confirmado separado del pendiente |
| DS-C23 PO/Toast | Ancho 360 px máximo, padding 16, radio 12, texto 14/20; esquina superior derecha a 24 px, debajo del header | Confirmación simple complementaria; máximo 3 visibles, sin desplazar foco. Temporizador por defecto 6 s con pausa en interacción; no única evidencia de error/async. Cierre accesible |
| DS-C24 PO/Skeleton y PO/Loader | Líneas de 16/20/24 px según destino, radios 4/8; loader 16/20, siempre con texto de estado accesible | Skeleton aproximado a estructura; loader localizado. Sin shimmer con movimiento reducido; jamás porcentaje ficticio |
| DS-C25 PO/EmptyState | Padding 32, icono 24 opcional, título Inter 18/26 600, cuerpo 14/20, gap 8, acción a 16 px | Vacío/sin coincidencias/no disponible diferenciados; en región de contenido, no modal; acción solo si existe capacidad |
| DS-C26 PO/Stepper | Indicador 32 px, título Inter 14/20 600, gap 16 entre etapas; detalle 14/20 | Pasos existentes y revisión/corrección, estado actual/completado/error con texto/símbolo. Sin wizard obligatorio ni número de pasos inferido |
| DS-C27 PO/Tabs | Altura mínima 40 px, padding horizontal 16; texto 14/20, indicador activo 2 px primary-hover | Secciones hermanas consultables; selección más aria/teclado. No sustituye transición de negocio ni oculta requisito/error |
| DS-C28 PO/Breadcrumbs | Texto 14/20, gap 8, separación de título 8 | Jerarquía y retorno real; actual no enlace, anteriores con foco y contraste |
| DS-C29 PO/Menu y PO/Popover | Ancho 224 px o contenido hasta 320; padding 8/16, item mínimo 36 px, radio 8, sombra floating | Menú de acciones autorizadas, popover para contenido breve. Abrir por teclado, Escape y retorno; si no cabe, reposicionar dentro de viewport. Nunca añadir acción para llenar menú |

### 7.1 Variantes de acciones

- **Primaria:**
  - fondo: #F76707 (`color/action/primary`);
  - texto: #1B1812 (`color/surface/ink` / `color/text/primary`);
  - borde: #C2410C (`color/action/primary-hover`) de 1 px si corresponde;
  - hover/pressed: #C2410C (`color/action/primary-hover`);
  - texto hover/pressed: #F7F5F0 (`color/text/inverse`);
  - foco: #4361EE (`color/focus/default`).
  Está prohibido representar el botón primary default como #F76707 con texto blanco. Una acción primaria por grupo de tarea; no todos los botones del header son filled.
- **Secundaria:** fondo neutral/blanco (`color/surface/default`), borde y texto #C2410C (`color/action/primary-hover`). Hover: `color/surface/cloud-subtle`, manteniendo texto. Mantener fondo neutral/blanco; no convertirla en un segundo CTA naranja. No usar `color/action/primary-soft` como fondo con texto `primary-hover` porque ese par no alcanza 4.5:1.
- **Terciaria:** sin fondo/borde visible, texto #C2410C (`color/action/primary-hover`); hover `color/surface/cloud-subtle`. Mantener tratamiento discreto. No utilizar naranja vivo #F76707 para todos los enlaces de texto. Un enlace de texto se subraya, al menos en hover/foco; los enlaces dentro de párrafo permanecen subrayados.
- **Destructiva:** fondo `color/error-strong` (#B42318) y texto blanco (#FFFFFF); hover/pressed mantiene ese par y añade borde ink. Solo rojo cuando la acción realmente es destructiva; no usar rojo para «Volver» o un cierre sin efecto.
- **Disabled:** tokens disabled, causa legible al lado cuando es necesaria.
- **Loading:** conservar etiqueta y ancho, añadir loader 16/20; explicar estado junto a la tarea.

En este backoffice una confirmación no cambia automáticamente a signal: el primario naranja conserva la jerarquía. Signal se reserva principalmente para foco y acentos de marca; no sustituye info/success.

### 7.2 Antipatrones cromáticos

Casos explícitos de implementación visual incorrecta y su corrección normativa:

- **PROHIBIDO:** `bg-[#F76707] + text-white`
  **CORRECTO:** `bg-[#F76707] + text-[#1B1812]`

- **PROHIBIDO:** `focus:ring-[#F76707]` o `focus:border-[#F76707]` usado como única indicación de foco.
  **CORRECTO:** `focus:ring-[#4361EE]`, manteniendo el borde semántico correspondiente cuando exista.

- **PROHIBIDO:**
  - `bg-emerald-100 text-emerald-800`
  - `bg-blue-50 text-blue-700`
  - `bg-amber-100 text-amber-900`
  - `bg-rose-50 text-rose-800`
  **CORRECTO:** tokens `success`/`info`/`warning`/`error` definidos en §4.1.

- **PROHIBIDO:** Asignar un color diferente a cada KPI.
  **CORRECTO:** KPI neutrales y color localizado solamente para estados que necesitan atención.

- **PROHIBIDO:**
  - azul = tipo A
  - naranja = tipo B
  - verde = tipo C
  sin que esos significados existan en el Design System.
  **CORRECTO:** variantes neutrales distinguidas mediante texto, icono, label o composición.

## 8. Formularios y revelación progresiva

Labels arriba, gap 4 px hasta control; ayuda/error abajo con gap 4 px. Texto required como asterisco explicado por «* Campo obligatorio» y semántica requerida real. Un placeholder no es un label ni contiene una instrucción esencial. Ayuda y error son Inter 14/20.

Formulario breve: una columna de hasta 640 px. Formulario amplio: hasta 880 px, dos columnas solo para campos equivalentes de contexto conocido; descripción, tabla de componentes, selección extensa y resultados ocupan todo el ancho. Campo estándar md 40 px; filtros compactos sm 32 px sin convertir todo el formulario a compacto.

Grupos con título Inter 18/26 o H3 según jerarquía, descripción si necesaria y gap 16. Campos condicionales aparecen dentro del grupo que los determina. Una sección puede plegarse si sus opciones no son necesarias para la decisión actual; su resumen informa la configuración y la presencia de errores. Al validar, abrir la sección afectada y llevar foco al primer error o al resumen de errores accesible.

Cambiar modalidad que invalida entradas advierte y conserva datos compatibles. No limitar todos los nombres a 100 caracteres por la guía: solo límites de SPEC/contrato. En SEO, avisos por título >70 y descripción >160 usan warning y permiten guardar según fuente.

Acciones al final, alineadas a derecha del formulario: cancelar/volver primero, guardar/continuar al extremo derecho. En formulario largo, footer sticky de 64 px mínimo, fondo default y borde decorativo; padding 16/24, gap 8, crece si las acciones envuelven. Reservar espacio equivalente al footer y asegurar que no cubra campo/error/foco. Si el footer no puede mantener contenido visible, usar acciones en flujo normal.

En un wizard real, stepper arriba; atrás/continuar abajo, resumen final editable mediante retorno a etapas. «Guardar borrador» y «Activar» muestran requisitos diferenciados en MK-003. No esconder activación incompleta tras un botón deshabilitado sin explicación.

## 9. Tablas, filtros y visualización de datos

Tablas con header cloud-subtle, labels Inter 14/20 600, contenido Inter 14/20, borde horizontal decorativo y sin líneas verticales por defecto. Filas mínimas de 48 px; variante compacta de 40 px solo para valores breves, sin miniaturas ni mensajes largos. Las filas crecen al envolver texto y no cortan controles.

Texto/identidad/fechas a izquierda; cantidades y precios a derecha con cifras tabulares y unidad en encabezado o valor. Estado en badge textual. SKU y ubicación son identidad operativa; no confundir `variant_id` con SKU. Moneda y precisión provienen de la fuente; no asumir soles ni convertir null en 0.

| Elemento | Regla transversal |
|---|---|
| Ancho de columnas | Checkbox si procede 48 px; miniatura 72; acción 80–120; número 112–144; estado 160–200. Identidad descriptiva recibe espacio restante. Son tamaños de composición, no obligación de incluir columnas |
| Truncamiento | Nombre descriptivo puede usar máximo 2 líneas y detalle para texto completo. No truncar importe, estado crítico, SKU necesario ni mensaje de error; columna flexible o detalle accesible |
| Overflow | Reordenar jerarquía visual y mover información complementaria a detalle sin omitir datos esenciales; si la tabla aún requiere ancho, scroll horizontal solo en su región etiquetada, operable por teclado. La página no se ensancha |
| Sticky | Header de tabla sticky dentro de región de tabla si hay scroll propio; nunca cubre título/error/foco. No combinar dos contenedores de scroll vertical anidados sin necesidad |
| Ordenamiento | Solo columnas y criterio soportados; header con control y dirección textual/accesible. Sin orden local sobre una página presentado como orden global del resultado |
| Selección | Solo para operación respaldada; mostrar alcance explícito «Seleccionados en esta página» y cantidad. «Todo el resultado» requiere soporte, no se infiere de checkbox del header |
| Acciones por fila | Detalle/editar si están permitidos. Acción frecuente visible; acciones adicionales en menú. No hacer clicable toda la fila si contiene otros controles sin destino claro |
| Toolbar masiva | Aparece al seleccionar si hay operación aplicable; etiqueta de cantidad y acciones concretas. Sin toolbar mutante en Auditoría/Dashboard |
| Paginación | Footer con rango/total solo si conocidos, página actual y controles admitidos. Se preserva al abrir detalle; al cambiar filtros se aplica la navegación coherente con consulta |
| Filtros | Arriba del resultado, selección aplicada visible y limpiable. No filtros nuevos solo porque hay espacio libre |
| Error parcial | Alert de región y detalle por fila si existe resultado. No toda fila roja ni desaparición de confirmados |

KPI en card: etiqueta, cantidad y unidad, contexto/fecha si disponibles; no confundir suma de unidades con cantidad de SKUs. Grid de 3 cards por fila a 1440 px como composición base, gap 24; si el contenido demanda mayor ancho, 2 o 1, sin modificar datos. Dashboard representa solo lectura y enlaces autorizados a MK-015.

### Disciplina cromática en tablas y dashboards

Las filas y celdas normales permanecen neutrales.

Los colores no representan categorías arbitrarias. Un Badge puede representar el estado de una fila, pero ese estado no debe extender su color al resto de la fila.

En dashboards:
- las cards permanecen neutrales por defecto;
- success/warning/error/info indican situaciones semánticas reales;
- los colores no se reparten entre métricas simplemente para hacerlas visualmente diferentes;
- si todas las métricas llaman la atención, ninguna tiene jerarquía.

La jerarquía se obtiene primero mediante:
1. tipografía;
2. espacio;
3. tamaño;
4. posición;
5. agrupación;
6. peso visual neutral;
y solo después mediante color cuando exista significado.

No introducir gráficos para llenar el Dashboard ni series temporales inexistentes. Si una fuente exige un gráfico, debe tener leyenda textual, unidades y tabla/valores accesibles; las series no se distinguen solo por color. La elección y los datos de ese gráfico pertenecen al component-spec.

## 10. Estados del sistema y percepción de progreso

Los nombres siguientes son etiquetas de presentación, **no nuevos estados contractuales**.

| Situación | Composición visual | Restricción |
|---|---|---|
| Carga inicial | Skeleton de shell interior/región esperada y texto accesible «Cargando…» | Sidebar/título existentes permanecen; no loader decorativo deliberadamente prolongado |
| Guardado/consulta breve | Loader en acción/región y etiqueta estable | Bloquear repetición incompatible; otras consultas independientes pueden continuar |
| Actualización | Datos anteriores identificados, indicador localizado; fecha si existe | Si falla, texto «No se pudo actualizar; se muestra la última consulta»; no afirmar saldo actual |
| Solicitud aceptada | Badge info «Solicitud recibida» y referencia/seguimiento disponible | No éxito terminal por `202`, ni descarga habilitada prematuramente |
| Procesando | Panel persistente info con estado/etapas publicadas | Porcentaje solo con numerador/denominador fiable; sin dato, mostrar estado real |
| Éxito confirmado | Resultado success con resumen y siguiente acción permitida | Solo lo confirmado por la operación; toast no sustituye resultado de lote |
| Completado con observaciones | Resultado warning, resumen confirmado y tabla/detalle de pendientes | En carga general deriva de COMPLETED más reporte; no añade enum ni rollback global |
| Error corregible | Error junto a campo/sección y entradas preservadas | Acción de corrección específica; no exigir reiniciar todo el formulario |
| Resultado desconocido | Alert info/warning «No se pudo confirmar el resultado», contexto conservado | Consultar/reconciliar antes de repetir escritura; no presentarlo como rechazo definitivo |
| Sin registros | EmptyState neutral con motivo y acción permitida | Auditoría no ofrece crear un registro |
| Sin coincidencias | EmptyState con filtros visibles y «Limpiar filtros» | No confundir con ausencia global de datos |
| Dato ausente / null | Etiqueta contextual de §13 | No cero ficticio |
| Sección no disponible | Alert localizada y acción de consulta si existe | Degradar secciones solo si sus fuentes son independientes; no simular datos confirmados |

Aplicación a funcionalidades críticas: lote MK-001 mantiene detalle por fila/dominio; producto/variante conserva borrador ante preparación incompleta; bajas de maestros permanecen pendientes hasta resultado; importación de Pricing no recibe reanudación de Catálogo; Auditoría conserva filtros y explica límites; recepción distingue recibido/pendiente/faltante y se confirma conforme a su respuesta; Dashboard no inventa bloqueados ni actualidad.

## 11. Feedback, errores y acciones críticas

Alert de región después del título/filtros y antes del contenido afectado, sin desplazar inesperadamente la pantalla. Error de campo junto al control; error de sección en su cabecera y contenido. Los resultados parciales/críticos persisten hasta corrección, nueva consulta válida o salida explícita; no desaparecen por un temporizador.

Mensajes siguen «qué ocurrió → qué se conserva → qué se puede hacer». Ejemplo: «No se pudo confirmar la preparación de inventario. El borrador se conserva. Consulta nuevamente su estado», solo si la consulta existe. No prometer «Reintentar inicialización» si la operación administrativa no está publicada.

Conflicto de precio: bloque de comparación con valor leído/actual y propuesta del usuario, únicamente con datos disponibles; permitir revisar antes de confirmar nueva intención. Slug de categoría: nueva propuesta visible y confirmable, sin sufijo silencioso. Un rechazo de exportación por límite conserva filtros y ofrece reducir consulta; CSV solo si su límite lo admite.

Confirmación crítica en modal breve cuando el FLOW lo exige: nombre/SKU/ubicación, impacto, información relevante, «Cancelar» y acción específica. En recepción final, mostrar recibido y faltante no acreditado; no redibujar una recepción cero si el contrato exige cantidad positiva. Foco inicial en título/contenido o alternativa segura según tarea; no enfocar automáticamente una acción irreversible. El confirm dialog no sustituye verificación de uso ni convierte un timeout en autorización.

Toast: simple complemento de guardado confirmado, cierre accesible y sin acciones imprescindibles. El temporizador de 6 s es un valor visual inicial; nunca afecta a persistencia de resultados, negocio o seguridad. Su ubicación no debe tapar acciones o foco; si lo hace, reubicar la pila a esquina inferior derecha con el mismo margen y sin ocultar footer.

## 12. Accesibilidad mínima y verificación posterior

Objetivo: reglas compatibles con WCAG 2.2 AA pertinentes a esta UI. Este documento no certifica conformidad del prototipo futuro.

- Texto normal: contraste mínimo 4.5:1; texto grande según definición WCAG: 3:1. Este sistema verifica el cuerpo/labels con 4.5:1 aunque algunos títulos admitan el umbral grande. [Referencia](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).
- Indicadores necesarios para reconocer controles/estado: 3:1 con fondos adyacentes. Bordes decorativos y controles inactivos tienen tratamiento distinto; no usar ese margen para ocultar información necesaria. [Referencia](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).
- Controles estándar de 40 px, compactos de 32; áreas de acciones removibles al menos 24×24 y separación mínima de 8 px respecto de acciones distintas. El icono puede ser menor que su área. [Referencia de tamaño mínimo](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html).
- Labels visibles y nombres accesibles; ayudas/errores asociados a control. Grupos radio/checkbox tienen leyenda. No usar placeholder o tooltip como etiqueta exclusiva.
- Foco perceptible y no cubierto por header/footer sticky, tabla o notificación; desplazamiento al campo debe reservar espacio para capas fijas. [Referencia](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html).
- Orden natural de teclado, activación por teclas pertinentes y salida de menús/dialogs. Dialog modal contiene foco y lo devuelve al activador; la pantalla de fondo no acepta interacción. No trampas de teclado en tablas o dropdowns.
- Estado se comunica con texto y símbolo; mensajes de estado pueden anunciarse sin trasladar foco. Errores críticos no se anuncian repetidamente por polling. Respetar movimiento reducido.
- Semántica de enlaces, botones, headings y tabla; header de columna y dirección de orden accesibles. Solo-icono usa nombre que identifica acción y entidad cuando corresponde.
- Texto ampliado debe envolver sin cortar mensajes ni esconder acciones; alturas indicadas son mínimas. La verificación desktop no justifica recortar contenido al aumentar texto/zoom.

La autovalidación de cada owner prueba teclado, foco, contenido largo, errores y contraste de todos los estados que implementa; medir tokens ahora no reemplaza esa revisión.

## 13. Contenido y terminología

Tono claro, operativo y respetuoso, sin lenguaje de campaña en administración. Botones en mayúscula inicial: «Guardar cambios», «Crear producto», «Aplicar filtros», «Descargar reporte», «Consultar estado», «Confirmar recepción». Usar el mismo verbo para la misma acción; «Aceptar» no describe una mutación crítica.

| Contexto | Presentación | Evitar |
|---|---|---|
| Identidad | Nombre y SKU vendible, ubicación cuando aplica | WF-XXX, SPEC-XXX, MK-XXX como título visible; variant_id presentado como SKU |
| Campo requerido | «Ingresa…» / «Selecciona…» con requisito específico | «Campo inválido» sin corrección |
| Admisión | «Solicitud recibida» / «Comprobación en curso» | «Completado» o «Inactivo» sin resultado |
| Precio anterior null | «Sin precio anterior» | 0 o guion ambiguo |
| Oferta null | «Sin oferta» | 0 como descuento/precio |
| Valor no pertinente | «No aplicable» | Dato inventado para completar tabla |
| Consulta fallida | «No disponible» y motivo/recuperación | «Agotado», cero o «Sin registros» inferidos del fallo |
| Preparación sin detalle | «Estado de preparación no disponible» | Deducir pendiente/rechazado de false o de dato ausente |
| Cupón sin límite opcional | «Sin límite» | Cero como ilimitado sin regla contractual |

No inventar moneda, canal, usuario, fecha de generación ni referencia técnica. Fechas legibles con zona horaria cuando interviene en vigencia; la transformación de formato no cambia el instante. Un error técnico puede incluir referencia de seguimiento en detalle si ayuda a soporte, sin exponer stack trace ni convertir el código en el mensaje principal.

Fixtures realistas sin datos personales reales, etiquetados como fixtures en la documentación de revisión. No usar Lorem Ipsum para títulos/acciones. No definir validaciones funcionales mediante límites visuales de nombres o longitud del badge.

## 14. Cobertura funcional y decisiones locales

| MK | Composición reutilizable y componentes representativos | Límite funcional a conservar |
|---|---|---|
| 001 | Archivo/validación, Table, Stepper si corresponde, Result y seguimiento | Resultado por dominio/fila y reanudación contractual, sin rollback distribuido |
| 002 | Select, NumberInput, tabla de componentes y Card de comparación | Precio/disponibilidad informativos; sin reserva o checkout administrativo |
| 003 | Formulario por grupos, imagen, Badge/Result de preparación | Guardar borrador distinto de activar; estados de preparación solo con evidencia |
| 004 | Tabla/detalle de variantes, atributos y datos físicos | SKU vendible y preparación por variante; padre sin saldo físico |
| 005 | Radio/Select, límites opcionales, fechas y errores locales | Sin consumo/restauración de cupón desde administración |
| 006 | Campos condicionales, alcance, beneficio y vigencia | Restricciones de modalidad/beneficio; sin simulador de compra |
| 007 | Tipo de regla, selección y criterio explícito | Sin inferencia de superioridad ni selección automática de variante |
| 008 | Formulario breve, propuesta de slug, Alert y confirmación | Conflicto concurrente; baja pendiente no es confirmación |
| 009 | Select tipo y campos condicionales, tabla de valores | Tipo inmutable; baja de valor diferente de baja de característica |
| 010 | Formulario breve y tabla de asociaciones, mensajes de esquema | No baja sin comprobación satisfactoria; conservar ante conflicto |
| 011 | Formulario breve, logo/país opcionales, resultado de comprobación | Sin wizard artificial; baja asíncrona distinta de alta/edición/reactivación |
| 012 | Formulario directo, preview de contenido e historial | Avisos 70/160 no bloqueantes; slug manual sin renombrado silencioso |
| 013 | Tabla, alcance/precio/fechas, comparación de conflicto y resultado de lote | Herencia de precio, versión/vigencia y recuperación propia de Pricing |
| 014 | FilterBar, Table, detalle y seguimiento de exportación | Solo lectura; rechazo por límites sin trabajo creado |
| 015 | Tabla por ubicación, transferencia y formulario de recepción con resumen | Distinguir recibido/pendiente/faltante; comandos internos no son controles administrativos |
| 016 | Kpi/Card, filtros, tabla/detalle y alert de actualización | Lectura; no cifras de bloqueados ni actualidad inventadas |

Una necesidad exclusiva se registra como `LUX-XX` en component-spec: problema, fuente, variante elegida, alternativa y verificación. Si se reutiliza en varios MK, se propone actualización transversal al responsable; un cambio visual se registra aquí y una nueva decisión de interacción en UX Decisions/Guidelines. No duplicar un componente solo para cambiar un color, ni reinterpretar un requisito funcional como excepción de diseño.

Los [hallazgos de fuentes del #59](ux/propuesta-ux.md#10-hallazgos-de-fuentes-y-límites) siguen trazables. Los estados afectados requieren alineación por sus owners antes de validación funcional; el diseño aquí dispone una representación honesta de ausencia/inconclusión, no una solución ficticia.

## 15. Correspondencia con React, TypeScript y Mantine

La referencia del prototipo es React + TypeScript + Mantine + Tabler Icons, con un tema común en `mockups/prototipo/src/tema/` y componentes compartidos en `src/componentes/`. Esas rutas son las previstas por [prototipo/README](prototipo/README.md), no archivos de implementación creados por este issue.

La guía menciona Mantine 9.6.2. Este repositorio aún no fija dependencias de prototipo mediante package/lockfile; este documento no instala ni cambia versiones. La implementación debe registrar la versión elegida y mantener los valores de este sistema, sin aceptar defaults que cambien dimensiones o colores.

| Regla de diseño | Referencia de implementación |
|---|---|
| Familia, tamaños, espaciado, radios y sombras | Tema común; headings H1–H3 Oswald, H4 Inter mediante configuración de componente, no uppercase global |
| Roles semánticos y colores exactos | Objeto de tokens tipado y variables CSS comunes; adaptación por variantes/Styles API. Una familia Mantine completa requiere al menos diez tonos: no entregar arrays con «...» ni exigir que cada owner improvise una familia |
| Botón primario y hover con distinto texto | Configuración central de variantes/estilos. `autoContrast` es auxiliar y no reemplaza los pares explícitos de §4.1 |
| Tamaños y estados del catálogo | Button/ActionIcon/TextInput/NumberInput/Textarea/Select/MultiSelect/Checkbox/Radio/Switch y equivalentes configurados centralmente |
| Fecha/hora | Componentes de `@mantine/dates` si forman parte del entorno acordado; formato y zona según fuente |
| Tabla y paginación | Table, región de desplazamiento y Pagination configuradas según operación; no asumir una librería adicional de datagrid |
| Drawer/Modal y capas | Componentes accesibles de capa con estilos/tamaños/foco consistentes; seleccionar la modalidad según tarea |
| Badge/Chip/Pill, alert/notification y feedback | Componentes base o composición común para Result/EmptyState; reglas de permanencia explícitas |
| Stepper/Tabs/Breadcrumbs/Menu/Popover/Tooltip | Usarlos bajo las condiciones de §7, sin crear flujos por disponer del componente |
| Shell y grid | AppShell/Grid u organización equivalente; padding/ancho del contenido y z-index según §5/§4.5 |

Se permite adaptar componentes mediante tema, variables y Styles API documentadas; no modificar internos de Mantine ni crear un tema por MK. Las referencias a componentes son correspondencias conceptuales, no código que se declara compilado.

Mantine no es fuente de verdad cromática. No utilizar colores predeterminados como `color='green'`, `color='blue'`, `color='orange'`, `color='red'` o `color='lime'` solo porque el componente los ofrezca. Las variantes Mantine deben mapearse a tokens de este Design System. El theme común debe controlar los valores finales. Un owner no puede elegir una familia Mantine distinta para su MK. Los defaults visuales de Mantine se aceptan únicamente cuando coinciden con los tokens, dimensiones y estados definidos aquí.

Las propiedades `color` de Mantine no deben derivarse directamente del nombre de un estado de negocio.
- Ejemplo incorrecto: `estado === 'ACTIVO' → color='green'`
- Ejemplo correcto: `estado === 'ACTIVO' →` determinar primero si el estado requiere semántica visual según la tarea; si no, usar variante neutral.

Los iconos de Tabler heredan `currentColor`. Su color debe provenir de los tokens del componente o de text/primary/text/secondary; no asignar una familia cromática distinta por icono. Referencias: [tema Mantine](https://mantine.dev/theming/theme-object/) y [Styles API](https://mantine.dev/styles/styles-api/).

Cada component-spec registra ID DS-C, variante, size, estados y tokens aplicables. El plan consume la versión y prevé reutilización; tasks verifica UI y accesibilidad. Todo estado inventariado debe ser reproducible por ruta/fixture según el pipeline, sin mostrar identificadores de documentación al Gestor Comercial.

## 16. Relación con Figma

Este issue documenta correspondencia; no importa pantallas ni publica una Team Library. Variables: nombres de §4 con valores exactos, modos solo claros de esta versión; estilos de texto según `type/…`; efectos según `elevation/…`.

Componentes con nombres `PO/Button`, `PO/TextInput`, `PO/Table`, etc., y referencia al ID DS-C en descripción. Propiedades compartidas: `variant`, `size`, `intent` cuando aplica, `disabled`, `loading`, `selected/checked`, `validation`, `interaction`, `icon` y `label`. No crear propiedades de selección para componentes informativos.

Valores: Button variant filled/outline/subtle, intent primary/destructive, size sm/md/lg; TextInput size sm/md, validation none/error/warning cuando aplica; Badge semantic neutral/info/success/warning/error/promotion, size sm/md. Los estados simultáneos se componen y no se pierden al elegir una variante.

Frames de revisión desktop 1440×900, altura ampliable con scroll. Auto Layout usa paddings/gaps de §4.3, anchura fill para región y hug para botones según contenido, y alturas mínimas del catálogo. Las fuentes, layer order, radio, sombra y posición sticky se describen en componentes/frames, sin reinterpretarlos por módulo.

Si la biblioteca central ya dispone del componente compatible, se consume su instancia. Una diferencia con esta versión se registra y coordina antes de aprobar fidelidad; no desprender instancias para ocultar divergencias. No se identifica ni inventa aquí el responsable de publicación de la biblioteca global.

Checklist de fidelidad posterior: mismos tokens y familias, tamaños/paddings, jerarquía, labels, estados pertinentes, iconos, contenido/fixtures y acciones que la versión de código aprobada. La aprobación para Figma y su validación siguen el pipeline, sin atribuir aprobación a una exportación automática.

## 17. Do / Don't

| Hacer | Evitar |
|---|---|
| Naranja con texto ink; hover oscuro con inverse | Blanco sobre naranja vivo o volt |
| Fondos semánticos con texto legible y símbolo | Volt/signal como sustitutos de error, éxito o stock confirmado |
| Labels/error visibles y foco independiente | Placeholder como label o error solo en tooltip/toast |
| Drawer para detalle breve y pantalla completa para configuración extensa | Drawer o wizard universal por MK |
| Conservar contexto y resultado parcial | Vaciar toda la página ante fallo de una sección |
| Tabla de lectura y acción permitida por contrato | Selección masiva para Auditoría/Dashboard |
| Estado recibido/procesando/confirmado diferenciado | Badge verde «Completado» al recibir 202 |
| Datos y tiempos disponibles identificados | Cero, timestamp o porcentaje inventados |
| Reutilizar tokens/variantes centrales | Defaults divergentes de Mantine o valores arbitrarios por owner |
| Confirmar impacto y seguir comprobaciones funcionales | Usar confirm modal para saltar validaciones |
| Usar neutros como estado visual por defecto | Utilizar todos los colores disponibles porque existen como tokens |
| Reservar semánticos para estados que realmente significan success/warning/error/info | Utilizar semánticos para distinguir categorías |
| Usar focus/default en todos los controles | Utilizar primary como ring de foco |
| Usar un indicador semántico localizado en KPI/card | Colorear fondo + borde + icono + cifra + badge para el mismo estado |
| Utilizar únicamente los tokens de §4.1 | Agregar colores emerald/blue/amber/rose o HEX locales |
| Usar iconos neutrales cuando no representan un estado | Dar un color diferente a cada icono para decorar |
| Separar estado de negocio de estado semántico | Mapear automáticamente Activo=verde, Inactivo=rojo o cada enum a un color |
| Permitir nuevos tokens solo mediante una actualización versionada del Design System | Crear un HEX local dentro de un MK porque falta un color |
| Evaluar la jerarquía de la pantalla completa | Validar cada componente de forma aislada y terminar con una pantalla cromáticamente saturada |

## 18. Validación documental y habilitación

La versión 1.1.0 incorpora gobernanza cromática y austeridad visual, manteniendo la cobertura documental de los criterios de #60: auditoría de wireframes, foundations completos, layout desktop, catálogo/estados, formularios/tablas, feedback, contenido, accesibilidad, correspondencia con prototipo y Figma. La tabla de §2 contrasta las 12 UXD y las 22 UXG del resultado definitivo de #59; no cambia sus condiciones de interacción ni requisitos funcionales.

| Criterio de #60 | Evidencia |
|---|---|
| Transición explícita de todas las categorías de wireframes | §3 |
| Color, tipografía, espacio, bordes, radios, elevación e iconos definidos | §4, con pares de contraste calculados |
| Desktop 1440, mouse/teclado y layout/nav coherentes | §5, §12 |
| Componentes y variantes suficientes, con estados pertinentes | §6–§7 y cobertura MK-001–016 en §14 |
| Formularios, tablas/densidad, feedback, vacío y parcial | §8–§11 |
| Accesibilidad y terminología de Gestor Comercial | §12–§13 |
| Coherencia con propuesta, UXD y UXG | §2 y condiciones explícitas en §7–§11 |
| Consumo por plantillas y compatibilidad conceptual Mantine/TypeScript | §15 y referencias actualizadas del pipeline |
| Traslado posterior a Figma sin foundations nuevos | §16 |
| Documento vigente, sin cambiar fuentes funcionales | Encabezado, §1, §14 |

### Checklist de revisión cromática previa a la aprobación de un MK

Antes de aprobar un MK se debe verificar:
- no existen colores no definidos por DESIGN.md;
- primary default no usa texto blanco;
- todos los focus rings usan focus/default;
- success/warning/error/info tienen una justificación semántica real;
- volt solo representa promoción;
- ninguna categoría fue diferenciada únicamente mediante color;
- cards y KPI son neutrales por defecto;
- no existe un «rainbow dashboard»;
- los estados están localizados y no colorean regiones innecesarias;
- el color no reemplaza texto, icono o etiqueta de estado;
- la pantalla conserva una jerarquía visual comprensible si se ignoran los colores;
- al observar la pantalla completa durante 3–5 segundos, los elementos que primero atraen la atención deben corresponder a:
  1. título/jerarquía principal;
  2. acción primaria;
  3. estado o riesgo que realmente necesita atención;
- una colección de badges, iconos o cards de diferentes colores NO debe dominar la percepción inicial;
- si varios elementos de una misma jerarquía compiten por atención únicamente debido al color, neutralizar los elementos que no tengan prioridad semántica;
- si una pantalla sigue siendo comprensible pero pierde jerarquía al pasar mentalmente los colores a neutros, revisar si se está usando color para sustituir estructura;
- revisar que el color refuerza una jerarquía ya creada mediante espacio, tamaño, posición, tipografía y agrupación, y no que intente crear por sí solo la jerarquía.

Un reviewer debe poder responder claramente: «¿Cuál es la acción principal y qué estado requiere mi atención?» sin que múltiples regiones de igual jerarquía compitan visualmente mediante colores diferentes.

Validación realizada: revisión documental, comprobación de referencias/IDs/tablas y cálculo de contrastes de pares sólidos. **No se declara implementado ni certificado el prototipo, ni validada visualmente una biblioteca Figma inaccesible.** Estas comprobaciones de código/pantalla corresponden a la ejecución de cada MK.

Comprobación de esta revisión: 36 tokens de color sin duplicados, 15 pares de contraste dentro de sus umbrales, 29 componentes DS-C, cobertura de las 12 UXD y 22 UXG, y matriz de las 16 funcionalidades. Se verificaron los enlaces/anchors incorporados, la estructura de tablas Markdown, la geometría de 1136 px útiles y la ausencia de errores de whitespace mediante `git diff --check`.

Con el #59 cerrado y este Design System adoptado en la base compartida, los owners disponen de las entradas transversales para `component-spec.md` → `plan.md` → `tasks.md`. El gate transversal corresponde a #59 + #60; el #61 organiza la ejecución general de los mockups. El #66 es la asignación individual de Leonardo Vera para MK-013 y MK-014, no un gate de consolidación transversal. Antes de aprobar una pantalla se resuelven sus hallazgos funcionales/contractuales; no se bloquea la elección de tokens por esa causa ni se declara resuelto un hallazgo ajeno por crear DESIGN.md.

El cierre del issue y la integración del cambio son acciones separadas del entregable documental. Un cambio futuro registra versión, fecha, motivo y componentes/MK afectados; un cambio incompatible debe indicar migración y evitar mantener dos reglas vigentes contradictorias. La versión 1.1.0 formaliza el control normativo de austeridad visual y gobernanza cromática.
