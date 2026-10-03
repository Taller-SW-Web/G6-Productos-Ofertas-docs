# Component Spec — MK-006

## 1. Identificación

Funcionalidad: Gestión de ofertas y promociones. Owner: Axel Andree Cueva Alcalá. Versión 1.0. Estado: En revisión documental; construcción y revisión UX transversal pendientes. Fuentes transversales #59/#60 cerradas y en master dc8fc6d. Rama oficial cueva. La construcción seguirá el pipeline y sus gates; estos documentos todavía no acreditan pantallas implementadas.

## 2. Trazabilidad

| Fuente | Referencia | Alcance |
|---|---|---|
| SPEC | [SPEC-006](../../specs/SPEC-006-gestion-ofertas-promociones.md) | Reglas completas |
| HU | [HU-006](../../hu/HU-006-gestion-ofertas-promociones.md) | Criterios administrativos; reglas de canal explicadas sin ejecutarlas |
| WF | [WF-006](../../wireframes/flows/WF-006-gestion-ofertas-promociones.md) | Pantallas/campos/microtexto |
| Flow | [FLOW-006](../../flujos/FLOW-006-gestion-ofertas-promociones.md) | Navegación/estado, entrega #38 en cueva |
| Propuesta UX | [Versión 2.0](../ux/propuesta-ux.md) | §9–11, fuentes abiertas |
| UX Decisions | [UXD](../ux/ux-decisions.md) | 001–006, 009–012 según condición |
| UX Guidelines | [UXG](../ux/ux-guidelines.md) | 001–008, 011, 013, 017–018, 020–022 |
| API | [OpenAPI 0.5.0](../../api/openapi.yaml), [Contrato](../../Contrato_Api.md) | Administración provisional interna; no conexión backend |
| Índice/ownership | [INDEX](../../wireframes/INDEX.md), [Equipo](../../EQUIPO_Y_RESPONSABILIDADES.md) | Asignación canónica de Axel |
| Wireframe DS | [Guía de baja fidelidad](../../wireframes/DESIGN.md) | Estructura previa; colores/tipografía de mockup regidos por DESIGN1.0 |
| DS | [DESIGN 1.0.0](../DESIGN.md) | §4–13 y 15, componentes DS-C01–29 aplicables |

## 3. Objetivo funcional

Gestor comercial autorizado configura y consulta gestión de ofertas y promociones para los canales. Resultado exitoso: configuración válida guardada y estado confirmado, sin ejecutar checkout desde administración.

## 4. Alcance

Incluye pantallas P0, lectura/creación/edición/estado, fixtures deterministas y mensajes contractuales. No integra backend, pagos, pedidos ni pantallas de prueba comercial. HU CA-02–04 configuración completa, alcance no vacío y CRUD; CA-09 pedidos confirmados no cambian; CA-10 combinaciones solo autorizadas; CA-11 producto/SKU sin duplicados; CA-13 modalidad cambia únicamente si inactiva, nunca activada y sin cupones/usos. PromocionAdmin no publica todos esos antecedentes: edición bloquea modalidad conservadoramente y explica crear otra promoción; no deducir elegibilidad de INACTIVO. CA-14/16 no cambia precio maestro ni simula compra.

## 5. Inventario de pantallas

| ID | Pantalla | Propósito | Entrada | Acción principal | Salida | Prioridad | Ruta |
|---|---|---|---|---|---|---|---|
| MK-006-S01 | Listado de promociones | list | Navegación/entrada directa | Consultar / elegir / confirmar | Retorno al contexto | P0 | `/MK006/S01` |
| MK-006-S02 | Crear promoción | create | Navegación/entrada directa | Guardar | Retorno al contexto | P0 | `/MK006/S02` |
| MK-006-S03 | Editar promoción | edit | Navegación/entrada directa | Guardar | Retorno al contexto | P0 | `/MK006/S03` |
| MK-006-S04 | Seleccionar alcance | selector | Navegación/entrada directa | Consultar / elegir / confirmar | Retorno al contexto | P0 | `/MK006/S04` |
| MK-006-S05 | Detalle de promoción | detail | Navegación/entrada directa | Consultar / elegir / confirmar | Retorno al contexto | P0 | `/MK006/S05` |
| MK-006-S06 | Cambiar estado | state | Navegación/entrada directa | Consultar / elegir / confirmar | Retorno al contexto | P0 | `/MK006/S06` |

Cada ruta permite inspección directa. Estado controlado por `?estado=...`, no visible en la interfaz. Datos de muestra identificados en el entorno; no se presentan como integración real.

## 6. Relación entre pantallas

```mermaid
flowchart LR
 S01[Listado] --> S02[Crear]
 S01 --> E[Editar]
 S01 --> D[Detalle]
 S02 --> D
 E --> D
 D --> E
 D --> C[Cambiar estado]
 C --> D
 D --> S01
```

Selector vuelve al formulario con selección y borrador preservados. Uso vuelve al detalle. Upselling tiene entrada propia y criterio por item. Los alias del diagrama se resuelven a las rutas de §5; no representan pantallas adicionales.

## 7. Jerarquía de información

Primaria: tarea, entidad y estado; secundaria: configuración/alcance/vigencia; complementaria: explicación de impacto y auditoría solo cuando se dispone de ella. No usar un KPI sin fuente.

## 8. Componentes compartidos

| Componente | Uso / variante / tamaño | Estados |
|---|---|---|
| DS-C01 Button | primary filled y secondary outline, md 40 px | focus/disabled/loading, texto explícito |
| DS-C03/04/06/07 | Texto, número, select/múltiple; md 40 px; label visible | error/read-only; criterios sin default |
| DS-C08/09/11 | Combinación, elección excluyente, fecha-hora zona Lima | selected/focus/error |
| DS-C13/17/18 | Filtros padding16, tabla filas48, pagination32 | carga/vacío/sin coincidencias |
| DS-C14/19 | Estado textual semántico, cards padding24 radius12 sin sombra | informativo/read-only |
| DS-C21 | Modal 480 confirmación, padding24 radius16 | foco contenido/Escape/retorno |
| DS-C22/24/25/28 | Alert persistente, skeleton/loader, vacío y breadcrumbs | error/carga/info; retorno contextual |

## 9. Componentes específicos

### MK-006-C01 — Configuración comercial

Propósito: representar campos de MK-006 sin reglas nuevas. Pantallas crear/editar/detalle. Propiedades y restricciones: Nombre; modalidad Automática/Cupón; tipo Porcentaje/Monto fijo; valor (0,100] o >0; vigencia inicio < fin; estado; prioridad entera >=1; alcance de productos completos o SKUs activos; canales Marketplace/Chatbot/Retail/Ventas; combinación con oferta de Pricing/promoción automática/cupón, deshabilitada por defecto.

Default refleja fixture; loading anuncia espera; error inline conserva valores; permiso denegado bloquea mutación sin inventar scopes. Guardar valida y enfoca primer error. Cancelar con cambios abre aviso. Cada campo tiene label visible; criterio/error asociado y foco visible. Operaciones: GET /promociones/administracion; POST /promociones; GET/PATCH /promociones/{promocionId}; POST activar/desactivar. Filtros: estado, modalidad, pagina, tamanio. Selector consulta Catálogo; los fixtures no acreditan validación backend.

### MK-006-C02 — Colección/selección contextual

Tabla de entidades/selección con datos deterministas, estado y acciones explícitas por fila; sin acciones masivas. Colección vacía permite crear o regresar, sin coincidencias permite limpiar filtros. Consulta fallida permite reintentar lectura; tabla no sustituye ausencia con cero. Selección por botón etiquetado, teclado y retorno al formulario.

## 10. Especificación por pantalla

### MK-006-S01 — Listado de promociones

**Propósito:** listado de promociones respetando las fuentes y manteniendo contexto.

**Layout:** breadcrumbs → título/acción → contenido agrupado → acciones finales. Filtros admitidos de estado y tipo/modalidad cuando corresponda → tabla semántica (nombre/código, estado, vigencia o referencia pertinente) → paginación conocida. Crear/abrir detalle/editar, sin selección masiva.

**Componentes:** shell común, DS-C28 breadcrumbs, DS-C01 botones, DS-C19 card; tabla DS-C17 y filtros DS-C13 en consulta; DS-C03–09/11 para campos; DS-C21 para confirmación; DS-C22/24/25 para feedback.

**Acción primaria:** Crear.
**Secundarias:** Volver/Cancelar; ver detalle o editar según navegación. Retorno explícito conserva filtros y borrador si existe.

**Estados:** default, loading, error, permisos (403), sesion (401), empty, sin-resultados. Empty solo describe colección vacía, no ficha inexistente; error no presenta ceros. Carga sin progreso ficticio. Error de guardar confirmado permite corregir; resultado desconocido no reenvía automáticamente.

**Copy:** título «Listado de promociones»; «Guardar cambios», «Cancelar», «No pudimos cargar la información. Vuelve a intentarlo»; error de campo explica el requisito concreto. Fuente: WF/UXG-006/011/020/021.
### MK-006-S02 — Crear promoción

**Propósito:** crear promoción respetando las fuentes y manteniendo contexto.

**Layout:** breadcrumbs → título/acción → contenido agrupado → acciones finales. Nombre; modalidad Automática/Cupón; tipo Porcentaje/Monto fijo; valor (0,100] o >0; vigencia inicio < fin; estado; prioridad entera >=1; alcance de productos completos o SKUs activos; canales Marketplace/Chatbot/Retail/Ventas; combinación con oferta de Pricing/promoción automática/cupón, deshabilitada por defecto.

**Componentes:** shell común, DS-C28 breadcrumbs, DS-C01 botones, DS-C19 card; tabla DS-C17 y filtros DS-C13 en consulta; DS-C03–09/11 para campos; DS-C21 para confirmación; DS-C22/24/25 para feedback.

**Acción primaria:** Guardar configuración.
**Secundarias:** Volver/Cancelar; ver detalle o editar según navegación. Retorno explícito conserva filtros y borrador si existe.

**Estados:** default, loading, error, permisos (403), sesion (401), validacion, guardar-error, salida con cambios. Empty solo describe colección vacía, no ficha inexistente; error no presenta ceros. Carga sin progreso ficticio. Error de guardar confirmado permite corregir; resultado desconocido no reenvía automáticamente.

**Copy:** título «Crear promoción»; «Guardar cambios», «Cancelar», «No pudimos cargar la información. Vuelve a intentarlo»; error de campo explica el requisito concreto. Fuente: WF/UXG-006/011/020/021.
### MK-006-S03 — Editar promoción

**Propósito:** editar promoción respetando las fuentes y manteniendo contexto.

**Layout:** breadcrumbs → título/acción → contenido agrupado → acciones finales. Nombre; modalidad Automática/Cupón; tipo Porcentaje/Monto fijo; valor (0,100] o >0; vigencia inicio < fin; estado; prioridad entera >=1; alcance de productos completos o SKUs activos; canales Marketplace/Chatbot/Retail/Ventas; combinación con oferta de Pricing/promoción automática/cupón, deshabilitada por defecto. Ante fallo se conservan valores; salir con cambios requiere confirmar descarte.

**Componentes:** shell común, DS-C28 breadcrumbs, DS-C01 botones, DS-C19 card; tabla DS-C17 y filtros DS-C13 en consulta; DS-C03–09/11 para campos; DS-C21 para confirmación; DS-C22/24/25 para feedback.

**Acción primaria:** Guardar configuración.
**Secundarias:** Volver/Cancelar; ver detalle o editar según navegación. Retorno explícito conserva filtros y borrador si existe.

**Estados:** default, loading, error, permisos (403), sesion (401), validacion, guardar-error, salida con cambios. Empty solo describe colección vacía, no ficha inexistente; error no presenta ceros. Carga sin progreso ficticio. Error de guardar confirmado permite corregir; resultado desconocido no reenvía automáticamente.

**Copy:** título «Editar promoción»; «Guardar cambios», «Cancelar», «No pudimos cargar la información. Vuelve a intentarlo»; error de campo explica el requisito concreto. Fuente: WF/UXG-006/011/020/021.
### MK-006-S04 — Seleccionar alcance

**Propósito:** seleccionar alcance respetando las fuentes y manteniendo contexto.

**Layout:** breadcrumbs → título/acción → contenido agrupado → acciones finales. Selector de productos activos; en promociones también SKU vendible. Excluir ya seleccionados y origen cuando corresponda. Seleccionar conserva el borrador y vuelve al formulario; entrada directa usa fixture conocido.

**Componentes:** shell común, DS-C28 breadcrumbs, DS-C01 botones, DS-C19 card; tabla DS-C17 y filtros DS-C13 en consulta; DS-C03–09/11 para campos; DS-C21 para confirmación; DS-C22/24/25 para feedback.

**Acción primaria:** Seleccionar.
**Secundarias:** Volver/Cancelar; ver detalle o editar según navegación. Retorno explícito conserva filtros y borrador si existe.

**Estados:** default, loading, error, permisos (403), sesion (401), empty, sin-resultados. Empty solo describe colección vacía, no ficha inexistente; error no presenta ceros. Carga sin progreso ficticio. Error de guardar confirmado permite corregir; resultado desconocido no reenvía automáticamente.

**Copy:** título «Seleccionar alcance»; «Guardar cambios», «Cancelar», «No pudimos cargar la información. Vuelve a intentarlo»; error de campo explica el requisito concreto. Fuente: WF/UXG-006/011/020/021.
### MK-006-S05 — Detalle de promoción

**Propósito:** detalle de promoción respetando las fuentes y manteniendo contexto.

**Layout:** breadcrumbs → título/acción → contenido agrupado → acciones finales. Nombre; modalidad Automática/Cupón; tipo Porcentaje/Monto fijo; valor (0,100] o >0; vigencia inicio < fin; estado; prioridad entera >=1; alcance de productos completos o SKUs activos; canales Marketplace/Chatbot/Retail/Ventas; combinación con oferta de Pricing/promoción automática/cupón, deshabilitada por defecto. Valores de configuración en lectura, estado en texto y acciones Editar / Cambiar estado / Volver.

**Componentes:** shell común, DS-C28 breadcrumbs, DS-C01 botones, DS-C19 card; tabla DS-C17 y filtros DS-C13 en consulta; DS-C03–09/11 para campos; DS-C21 para confirmación; DS-C22/24/25 para feedback.

**Acción primaria:** Editar.
**Secundarias:** Volver/Cancelar; ver detalle o editar según navegación. Retorno explícito conserva filtros y borrador si existe.

**Estados:** default, loading, error, permisos (403), sesion (401). Empty solo describe colección vacía, no ficha inexistente; error no presenta ceros. Carga sin progreso ficticio. Error de guardar confirmado permite corregir; resultado desconocido no reenvía automáticamente.

**Copy:** título «Detalle de promoción»; «Guardar cambios», «Cancelar», «No pudimos cargar la información. Vuelve a intentarlo»; error de campo explica el requisito concreto. Fuente: WF/UXG-006/011/020/021.
### MK-006-S06 — Cambiar estado

**Propósito:** cambiar estado respetando las fuentes y manteniendo contexto.

**Layout:** breadcrumbs → título/acción → contenido agrupado → acciones finales. Detalle contextual bajo diálogo de 480 px con entidad, estado actual, impacto y acción Activar/Desactivar. Confirmación no cambia estado antes del resultado; rechazo conserva estado. Escape/Cancelar vuelve al detalle y restituye foco.

**Componentes:** shell común, DS-C28 breadcrumbs, DS-C01 botones, DS-C19 card; tabla DS-C17 y filtros DS-C13 en consulta; DS-C03–09/11 para campos; DS-C21 para confirmación; DS-C22/24/25 para feedback.

**Acción primaria:** Confirmar estado.
**Secundarias:** Volver/Cancelar; ver detalle o editar según navegación. Retorno explícito conserva filtros y borrador si existe.

**Estados:** default, loading, error, permisos (403), sesion (401), rechazo. Empty solo describe colección vacía, no ficha inexistente; error no presenta ceros. Carga sin progreso ficticio. Error de guardar confirmado permite corregir; resultado desconocido no reenvía automáticamente.

**Copy:** título «Cambiar estado»; «Guardar cambios», «Cancelar», «No pudimos cargar la información. Vuelve a intentarlo»; error de campo explica el requisito concreto. Fuente: WF/UXG-006/011/020/021.

## 11. Decisiones UX locales

LUX-01: composición propia de esta configuración. Alcance de promoción en selector separado según contenido producto/SKU y formulario de 880 px; evita listas extensas en un modal y conserva el borrador. Alternativa: panel breve; descartado por el contenido pertinente del WF. Trade-off: una navegación más. Verificación: entrada directa y vuelta sin pérdida. No redefine patrón transversal UXD-001/002.

## 12. Reglas de layout PC

1440×900 canónico, scroll vertical; header64/sidebar240/padding32/contenido1136; formulario 880 px alineado izquierda; gap24 y secciones32. Inter 16/24 y Oswald 32/40 uppercase en H1; tonos/radios/foco desde tema único. Sin overflow horizontal involuntario ni variantes mobile/tablet. La responsividad mobile antigua de WF-007 se subordina al alcance desktop de #64/README, sin alterar negocio.

## 13. Fixtures

Datos exclusivamente ficticios: Carrera de octubre automática, porcentaje 15, Running Essential y SKU RUN-PRO-42; Bienvenida modalidad Cupón, porcentaje 15; prioridad 1; canales Marketplace/Retail; combinaciones false.

| Fixture | Caso | Representación |
|---|---|---|
| default | Datos coherentes con schemas Admin | Entidades configuradas |
| loading | Lectura pendiente | Skeleton y texto accesible |
| empty | Colección sin registros | Vacío con acción permitida |
| sin-resultados | Filtros sin coincidencias | Limpiar filtros |
| error | Lectura fallida | Alert y reintento localizado |
| permisos / sesion | 403 / 401 contractuales | Bloqueo sin mutación; retorno |
| validacion / guardar-error | Envío inválido o rechazo confirmado | Campo/alert, entradas preservadas |
| rechazo | Cambio estado rechazado | Estado previo conservado |

Casos específicos: modalidad-bloqueada: edición sin antecedentes suficientes; porcentaje-invalido: 101; alcance-vacio: []; guardar-error: entradas conservadas.

## 14. Preguntas y supuestos

No hay pregunta funcional bloqueante para las pantallas administrativas descritas. Las rutas internas de administración son provisionales según OpenAPI, por lo que se construye mockup, no integración productiva.

Supuestos: datos de fixtures no acreditan llamadas API; usuario autorizado salvo estado explícito 401/403; no se crean nuevos permisos. Supuestos se revisan al integrar backend. Visto bueno de Leonardo y fidelidad Figma permanecen pendientes.

## 15. Criterios de aceptación

- Pantallas P0 con rutas independientes y estados reproducibles de §5/10/13.
- Campos y validaciones trazables a §2/9; navegación sin checkout añadido.
- Valores conservados en fallo/cancelación; confirmación con impacto y foco restaurado.
- Tokens/componentes compartidos y PC1440 sin overflow; controles etiquetados y errores localizables.
- Autovalidación objetiva antes de revisión UX; no declarar APROBADO PARA FIGMA ni aprobación final sin revisor/evidencia.
