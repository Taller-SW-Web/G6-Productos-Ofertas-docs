# WF-016 — Dashboard analítico y alertas de stock

> **Fuentes normativas:** SPEC individual de esta funcionalidad (`../../specs/SPEC-016-dashboard-alertas-stock.md`), HU individual de esta funcionalidad (`../../hu/HU-016-dashboard-alertas-stock.md`), `../DESIGN.md` y `../INDEX.md`. Ante contradicción, prevalece SPEC → HU → WF. Los reportes y rankings de ventas por producto/canal pertenecen exclusivamente a Ventas/Postventa. Este dashboard se enfoca en el monitoreo del inventario, alertas de stock bajo/agotado y distribución operativa por ubicación. Las anotaciones, supuestos, preguntas y referencias técnicas permanecen en este documento y no se muestran como elementos de la interfaz simulada.

## 0. Instrucciones para el agente

Genera un wireframe detallado, anotado y navegable para el dashboard analítico y
las alertas de stock descritas en este archivo.

Antes de diseñar:

1. Consulta ../../specs/SPEC-016-dashboard-alertas-stock.md.
2. Consulta ../../hu/HU-016-dashboard-alertas-stock.md.
3. Consulta ../DESIGN.md.
4. Consulta ../INDEX.md.
5. Usa este documento para la composición, interacción y estados del flujo.

Prioridad de fuentes:

1. La especificación define reglas de negocio y restricciones globales.
2. La historia de usuario define criterios de aceptación y escenarios.
3. Este documento define navegación y comportamiento de interfaz.
4. DESIGN.md define la representación visual.

Si las fuentes se contradicen o no resuelven una decisión, no inventes una
regla. Registra la cuestión en Preguntas y decisiones pendientes e identifica
la pantalla afectada.

Reglas de producción:

- La unidad primaria de inventario es el **SKU vendible** (incluyendo `sku_base` en producto simple). El producto es solo un agrupador comercial y no tiene stock independiente.
- Los indicadores mínimos son: total de SKUs vendibles, total de unidades disponibles (`available`) y cantidad de SKUs por estado (Disponible, Stock bajo, Agotado).
- El estado de cada SKU en cada ubicación se calcula con reglas deterministas usando el `umbral_efectivo` (`override SKU ?? umbral_global`):
  `0 < available <= umbral_efectivo → Stock bajo` (alerta);
  `available = 0 → Agotado` (alerta).
- Las alertas se generan para SKUs en estado Stock bajo o Agotado.
- El dashboard se actualiza de forma **reactiva** ante el evento `inventory.stock.changed`; no usa intervalos fijos ni polling en tiempo real.
- Después de un consumo, el estado mostrado debe reflejar el estado calculado resultante (Disponible → Stock bajo, o Stock bajo → Agotado).
- La distribución operativa de stock por ubicación muestra unidades `on_hand`, `reserved` y `available` y cantidad de SKUs con stock bajo/agotados por `location_id`.
- Este dashboard **no calcula ni muestra rankings de ventas, Top de productos más vendidos, ni métricas comerciales**; esas corresponden al módulo de Ventas/Postventa.
- Filtros permitidos: producto, categoría, marca, SKU, ubicación (`location_id`) y estado de inventario.
- No elijas una librería de UI ni una estrategia CSS.
- Usa datos ficticios y no consumas APIs reales.
- Numera las anotaciones como A-01, A-02, A-03, etc.
- No agregues gráficos de librerías externas; usa barras neutrales en escala de grises para la representación de datos.

### Formato del entregable

Genera un prototipo navegable con HTML, CSS y JavaScript estáticos:

- El punto de entrada debe ser index.html.
- Debe funcionar sin proceso de compilación.
- Usa rutas y recursos relativos.
- No uses React ni dependencias del frontend productivo.
- No requieras conexión a servicios externos.
- Simula únicamente las interacciones necesarias para validar el flujo.
- Implementa un diseño responsivo real para escritorio, tablet y móvil mediante CSS y cambios de viewport; no agregues controles internos de dispositivo.
- Documenta las anotaciones A-xx fuera de la interfaz simulada; no las renderices en el prototipo.
- Aplica el estilo monocromático y de baja fidelidad de DESIGN.md.

### Entregables esperados

1. Tarjetas de indicadores de inventario (SKUs vendibles, unidades disponibles `available` y SKUs por estado).
2. Tabla o listado de variantes/SKUs con su estado y alertas de stock bajo y agotado.
3. Distribución operativa de stock por ubicación (`location_id`, `on_hand`, `reserved`, `available`).
4. Actualización reactiva de indicadores y alertas ante `inventory.stock.changed`.
5. Filtros por producto, categoría, marca, SKU, ubicación y estado.
6. Estados de carga, vacío, error, permisos y sesión.
7. Navegación funcional entre los estados simulados.

---

## 1. Metadatos

| Campo | Valor |
|---|---|
| ID del wireframe | WF-016 |
| Nombre del flujo | Dashboard analítico y alertas de stock |
| Versión | 0.5 |
| Estado | Borrador |
| Responsable | Miguel Ángel Taco Zavala |
| Fecha | 2026-09-17 |
| Última actualización | 2026-09-30 |

## 2. Trazabilidad

| Fuente | Identificador o sección | Aporte al flujo |
|---|---|---|
| Spec | SPEC-016-dashboard-alertas-stock.md, secciones 1–5 | Indicadores, alertas, distribución por ubicación y actualización reactiva |
| Historia de usuario | HU-016-dashboard-alertas-stock.md, CA-01 a CA-10 | Criterios y escenarios |
| Diseño | DESIGN.md | Lenguaje visual monocromático de baja fidelidad |
| Backlog | No proporcionado | No se asignan IDs de backlog |

### Funcionalidades incluidas

- Mostrar indicadores generales del inventario a nivel de SKU vendible.
- Mostrar cantidad de variantes por estado (Disponible, Stock bajo, Agotado).
- Identificar SKUs con stock bajo según el `umbral_efectivo` (`override SKU ?? umbral_global`).
- Mostrar alertas para SKUs en Stock bajo o Agotado.
- Mostrar la distribución operativa de stock por ubicación (`location_id`), con desglose de `on_hand`, `reserved` y `available`.
- Filtrar por producto, categoría, marca, SKU, ubicación (`location_id`) y estado de inventario.
- Actualizar indicadores y alertas de forma reactiva ante `inventory.stock.changed`.
- Agrupar la información por producto cuando se requiera una vista comercial.

### Fuera de alcance

- Reportes o rankings de ventas (Top productos vendidos, ventas por canal/vendedor): pertenecen a Ventas/Postventa.
- Registro o edición de stock, consumos y ajustes: WF-015 (Gestión de inventario).
- Operaciones masivas de inventario: WF-001.
- Generación de SKUs y variantes: WF-004.
- Precios y auditoría: WF-013, WF-014.
- Ofertas, cupones y promociones: WF-005, WF-006, WF-007.
- Definición de categorías, marcas y SEO: WF-008 a WF-012.

## 3. Usuario objetivo

| Aspecto | Definición |
|---|---|
| Persona | Responsable de inventario del marketplace |
| Rol en el sistema | Gestor autenticado con permisos de consulta analítica de inventario |
| Nivel técnico | Operativo básico/intermedio |
| Contexto de uso | Monitoreo periódico del estado del inventario y detección de reposición |
| Necesidad principal | Detectar variantes con bajo stock o agotadas y monitorear existencias por almacén |
| Permisos relevantes | Consultar el dashboard de inventario y sus alertas; códigos pendientes |
| Dispositivo principal | Escritorio como hipótesis; consulta adaptada a tablet/móvil |

## 4. Objetivo del flujo

El responsable de inventario debe poder visualizar indicadores consolidados,
niveles de stock, distribución operativa por ubicación y alertas sobre el inventario,
para identificar oportunamente las variantes que requieren reposición o redistribución física.

### Resultado exitoso

La pantalla muestra los indicadores de inventario, el listado de SKUs con su
estado y alertas calculadas según el umbral efectivo (`0 < available <= umbral_efectivo` y `available = 0`), y la distribución operativa de existencias por ubicación. Ante cada `inventory.stock.changed`, los indicadores y alertas se recalculan con el saldo y estado vigentes.

### Indicadores de finalización

- Indicadores, alertas y distribución de stock por ubicación visibles y coherentes con los saldos vigentes.
- Cambio de stock notificado reflejado reactivamente en los valores del dashboard.

## 5. Precondiciones y disparador

### Precondiciones

- El usuario tiene una sesión válida y permiso de consulta de inventario.
- Existen SKUs vendibles con stock controlado (WF-015).
- Se encuentra definido el umbral global o overrides por SKU (`umbral_efectivo`).

### Puntos de entrada

- Ruta propuesta: `/inventario/dashboard`.
- Entrada propuesta: opción Dashboard dentro del módulo de Inventario / Productos y ofertas.
- Filtros por ubicación y estado: controles sobre la propia pantalla.

Las rutas y ubicación exactas son propuestas de wireframe y deben confirmarse.

### Salidas del flujo

| Resultado | Destino o comportamiento |
|---|---|
| Consulta exitosa | Panel con indicadores, alertas y distribución por ubicación |
| Filtro aplicado | Panel recalculado según el filtro |
| Ubicación seleccionada | Panel enfocado en la ubicación elegida |
| Evento de stock | Panel recalculado de forma reactiva (`inventory.stock.changed`) |
| Error recuperable | Permanece en la pantalla y conserva los filtros |
| Sin permisos | Bloquea la consulta y ofrece retorno seguro |

## 6. Secuencia principal

1. El responsable entra al dashboard de inventario.
2. El sistema carga los indicadores, las alertas de stock bajo/agotado y la distribución por ubicación.
3. El responsable aplica filtros (producto, categoría, marca, SKU, ubicación, estado) según requiera.
4. El sistema recalcula y actualiza las secciones según los filtros aplicados.
5. Ante un evento `inventory.stock.changed`, el sistema actualiza indicadores, alertas y saldos de forma reactiva.

### Flujos alternativos

| ID | Condición | Comportamiento esperado | Retorno |
|---|---|---|---|
| ALT-01 | Sin SKUs con inventario | Estado vacío con orientación | Panel con mensaje |
| ALT-02 | Filtro sin resultados | Mensaje contextual y opción de limpiar | Panel filtrado |
| ALT-03 | Error al cargar indicadores o alertas | Error con reintento | Estado de carga |
| ALT-04 | Ubicación única (`DEFAULT`) | Muestra vista única sin forzar selector | Panel normal |
| ALT-05 | Usuario sin permiso | Explicación segura | Estado global |
| ALT-06 | Evento `inventory.stock.changed` | Recalcular indicadores y alertas reactivamente | Panel actualizado |
| ALT-07 | Sesión expirada | Aviso de autenticación | Retorno al flujo |

## 7. Inventario de pantallas y variantes

| ID | Pantalla o variante | Propósito | Ruta/presentación | Obligatoria |
|---|---|---|---|---|
| S-01 | Dashboard analítico y alertas | Panel con indicadores, alertas y distribución por ubicación | `/inventario/dashboard` propuesta | Sí |
| S-01-E | Vacío o error del panel | Diferenciar ausencia de datos de fallo de carga | Variante de S-01 | Sí |

## 8. Mapa de navegación

~~~mermaid
flowchart TD
    A["S-01 Dashboard y Alertas"] --> F["Filtros (SKU, Ubicación, Estado)"]
    A --> U["Distribución por Ubicación"]
    A --> E["Evento inventory.stock.changed"]
    E --> A
    A --> V["S-01-E Vacío / Error"]
~~~

## 9. Especificación por pantalla

### S-01 — Dashboard analítico y alertas

#### Propósito

Mostrar una visión general del inventario, la distribución por ubicación y facilitar la identificación de variantes que requieren atención operativa.

#### Jerarquía de contenido

1. Título: Dashboard de inventario.
2. Filtros de búsqueda (Producto, Categoría, Marca, SKU, Ubicación, Estado).
3. Tarjetas de indicadores consolidados (SKUs vendibles, unidades disponibles, SKUs por estado).
4. Alertas de stock (Stock bajo y Agotado) según umbral efectivo.
5. Distribución operativa de stock por ubicación (`location_id`, `on_hand`, `reserved`, `available`).

#### Regiones y componentes

| Región | Componente neutral | Contenido | Comportamiento |
|---|---|---|---|
| Encabezado | Título + resumen | Dashboard de inventario | Información general |
| Filtros | Selectores | Producto, categoría, marca, SKU, ubicación (`location_id`), estado | Recalcula el panel |
| Indicadores | Tarjetas | SKUs vendibles, unidades disponibles (`available`), SKUs por estado | Valores vigentes consolidados |
| Alertas | Listado/tabla | SKUs con Stock bajo (`0 < available <= umbral`) o Agotado (`available = 0`) | Permite filtrar y ordenar |
| Distribución | Tabla/tarjetas | Ubicación (`location_id`), `on_hand`, `reserved`, `available`, SKUs en alerta | Resumen operativo por almacén |

#### Acciones

| Prioridad | Acción | Etiqueta | Disponibilidad | Resultado |
|---|---|---|---|---|
| Primaria | Limpiar filtros | Limpiar | Filtros activos | Resetea el panel |
| Secundaria | Filtrar ubicación | Selector de ubicación | Múltiples ubicaciones | Filtra métricas por almacén |
| Secundaria | Actualizar | Actualizar (simulado) | Solo prototipo | Emite un `inventory.stock.changed` de prueba |

#### Datos mostrados

| Dato | Fuente | Formato | Prioridad | Ausencia |
|---|---|---|---|---|
| Total SKUs vendibles | Inventario | Entero | Alta | 0 o No disponible |
| Total unidades disponibles (`available`) | Inventario | Entero | Alta | No disponible |
| SKUs disponibles | Inventario | Entero | Alta | 0 |
| SKUs con stock bajo | Inventario | Entero | Alta | 0 |
| SKUs agotados | Inventario | Entero | Alta | 0 |
| Variantes con alerta | Inventario | Listado (SKU, producto, available, umbral, ubicación) | Alta | Vacío |
| Distribución por ubicación | Inventario | `location_id`, `on_hand`, `reserved`, `available` | Alta | Vista DEFAULT única |

#### Anotaciones

| ID | Elemento | Anotación |
|---|---|---|
| A-01 | Indicadores | Unidad primaria: SKU vendible; el producto es agrupador comercial |
| A-02 | Estado | Calculado con `available` y `umbral_efectivo` (`override SKU ?? umbral_global`) |
| A-03 | Alertas | Para estados Stock bajo (`0 < available <= umbral`) y Agotado (`available = 0`) |
| A-04 | Reactividad | Se recalcula reactivamente ante `inventory.stock.changed`, sin polling fijo |
| A-05 | Distribución | Desglose operativo por `location_id` (`on_hand`, `reserved`, `available`) |
| A-06 | Filtros | Por producto, categoría, marca, SKU, ubicación y estado |
| A-07 | Sin inventario | La ausencia de SKUs no debe presentarse como error |

### S-01-E — Vacío o error del panel

- Vacío: Aún no hay variantes con inventario. El dashboard mostrará indicadores en cero y orientará a registrar inventario en WF-015.
- Error: No pudimos cargar el dashboard. Acción: Reintentar.

#### Anotaciones

| ID | Elemento | Anotación |
|---|---|---|
| A-08 | Vacío | Depende de Gestión de variantes e Inventario |
| A-09 | Error | Recuperación sin detalles técnicos internos |

## 10. Estados de interfaz

| Estado | Aplica | Representación | Acciones | Recuperación |
|---|---|---|---|---|
| Cargando inicial | Sí | Skeleton/indicador | Esperar | Reintento si falla |
| Con datos | Sí | Panel normal con indicadores, alertas y distribución | Filtrar, cambiar ubicación | N/A |
| Vacío inicial | Sí | Indicadores en cero + mensaje informativo | Reintentar / registrar | Ir a WF-015 |
| Sin resultados por filtros | Sí | Mensaje contextual | Limpiar filtros | N/A |
| Error recuperable | Sí | Mensaje aislado de fallo | Reintentar | Acción de recarga |
| Actualización reactiva | Sí | Valores recalculados ante evento | N/A | N/A |
| Sin permisos | Sí | Explicación segura de acceso | Volver / solicitar acceso | Destino seguro |
| Sesión expirada | Sí | Aviso de autenticación | Iniciar sesión | Retorno al flujo |

### Reglas para datos remotos

- Refrescar indicadores, alertas y distribución al recibir el evento `inventory.stock.changed`.
- No aplicar actualización optimista; el panel refleja estados confirmados de inventario.
- Distinguir ausencia de SKUs de fallo de carga de red.

## 11. Comportamiento responsivo

DESIGN.md define 12 columnas en escritorio y 4 en móvil. El prototipo demuestra
adaptación sin fijar breakpoints definitivos.

| Aspecto | Escritorio | Tablet | Móvil |
|---|---|---|---|
| Navegación | Completa | Condensada | Patrón global móvil |
| Indicadores | Tarjetas en fila | 2 columnas | Apiladas en una columna |
| Filtros | Selectores en línea | Apilados | Apilados |
| Alertas | Tabla con columnas completas | Tabla reducida | Tarjetas apiladas |
| Distribución | Tabla de ubicaciones | Tarjetas por ubicación | Tarjetas apiladas |
| Anotaciones | Panel lateral | Debajo | Lista/colapsable |
| Contenido omitido | Ninguno | Ninguno | Ninguno; reorganizar |

### Condiciones críticas

- Verificar 320 px sin desplazamiento horizontal.
- Los SKU largos deben envolver o truncarse con acceso al valor completo.
- Los selectores deben funcionar correctamente con zoom de 200%.

## 12. Accesibilidad

- Objetivo WCAG 2.2 AA.
- Encabezado principal único por pantalla.
- Los estados (Disponible, Stock bajo, Agotado) se expresan con texto e icono, no solo con color.
- Gráficos o barras neutrales con valor textual asociado.
- Cambios dinámicos (evento de stock) se anuncian mediante `aria-live` a usuarios de lectores de pantalla.
- Anotaciones excluidas del árbol accesible.
- Acciones móviles de mínimo 44 por 44 px.

## 13. Tono visual y contenido

Aplicar DESIGN.md como única fuente de representación visual.

### Consideraciones específicas

- Densidad: media.
- Sensación buscada: monitoreo claro y oportuno del inventario.
- Elemento dominante en S-01: indicadores consolidados, tabla de alertas y distribución por ubicación.

### Microcopy crítica

| Contexto | Texto propuesto | Observación |
|---|---|---|
| Acción principal | Actualizar | Simulación reactiva para prototipo |
| Alerta stock bajo | Este SKU requiere atención por bajo stock (disponible <= umbral). | CA-04 |
| Alerta agotado | SKU agotado (0 unidades disponibles). | CA-04 |
| Ubicación | Distribución operativa de stock por ubicación. | CA-05 |
| Vacío | Aún no hay variantes con inventario registrado. | Orientación |
| Error | No pudimos cargar la información del inventario. | Reintento seguro |

## 14. Restricciones técnicas relevantes

- Aplicación objetivo: React, TypeScript y Vite.
- Navegación: React Router.
- Estado remoto: TanStack Query.
- Contratos HTTP: OpenAPI/Swagger.
- Eventos: AsyncAPI (`inventory.stock.changed` emitido por Inventario).
- El prototipo es HTML/CSS/JS estático monocromático.

### Dependencias o contratos

| Tipo | Operación o referencia | Impacto visible |
|---|---|---|
| HTTP | Indicadores, alertas y distribución (inventario); pendiente | S-01 |
| Evento | `inventory.stock.changed` (inventario) | Recalcular indicadores, alertas y distribución |
| Permiso | Consultar dashboard de inventario; código pendiente | Acceso condicionado |

## 15. Privacidad, seguridad y acciones sensibles

- El dashboard es estrictamente de consulta analítica; las mutaciones de stock ocurren en el módulo de Inventario (WF-015).
- No exponer en mensajes de error detalles técnicos de contratos o servicios internos.
- No permitir que los filtros revelen datos fuera del ámbito autorizado.
- El documento no exige reautenticación para la consulta.

## 16. Criterios de aceptación del wireframe

- [x] Muestra los indicadores mínimos (SKUs vendibles, unidades disponibles `available` y SKUs por estado).
- [x] Identifica SKUs con stock bajo según el umbral efectivo (`0 < available <= umbral_efectivo`).
- [x] Muestra alertas para SKUs en Stock bajo o Agotado.
- [x] Muestra la distribución operativa de inventario por ubicación (`location_id`, `on_hand`, `reserved`, `available`).
- [x] No calcula rankings de ventas, Top 5 productos ni métricas de ventas.
- [x] Los indicadores y alertas se actualizan de forma reactiva con `inventory.stock.changed`.
- [x] Expone filtros por producto, categoría, marca, SKU, ubicación y estado.
- [x] Incluye estados de carga, vacío, error, permisos y sesión.
- [x] Funciona con teclado y no depende únicamente del color.
- [x] Funciona con HTML/CSS/JS estáticos bajo DESIGN.md.

### Cobertura de la historia de usuario

| Criterio | Cobertura |
|---|---|
| CA-01 | S-01, sección de indicadores de estados |
| CA-02 | S-01, tarjetas de indicadores consolidados |
| CA-03 | S-01, cálculo de stock bajo con `available` y `umbral_efectivo` |
| CA-04 | S-01, sección de alertas de stock |
| CA-05 | S-01, sección de distribución operativa por ubicación (`location_id`) |
| CA-06 | S-01, estados calculados en tiempo real |
| CA-07 | S-01, reactividad ante `inventory.stock.changed` (A-04) |
| CA-08 | S-01, transición de estados tras consumo |
| CA-09 | S-01, filtro por `location_id` y vista DEFAULT |
| CA-10 | S-01, dashboard estrictamente de lectura (reactivo a `inventory.stock.changed` sin republicarlo ni mutar stock) |

## 17. Supuestos

| ID | Supuesto | Motivo | Impacto si es incorrecto | Validar |
|---|---|---|---|---|
| SUP-01 | WF-016 es el ID asignado en INDEX.md | Asignación de la rama `taco` | Renombrar archivo/referencias | Sí |
| SUP-02 | La ruta será /inventario/dashboard | No se entregó mapa de navegación | Cambiar rutas/entrada | Sí |
| SUP-03 | Escritorio es el dispositivo principal | Gestión operativa y administrativa | Cambiar prioridad responsive | Sí |
| SUP-04 | La distribución por ubicación muestra DEFAULT si no hay multialmacén | Regla de HU-016 (CA-09) | Ajustar vista | Sí |

## 18. Preguntas y decisiones pendientes

| ID | Pregunta o decisión | Responsable | Bloquea wireframe | Estado |
|---|---|---|---|---|
| Q-01 | ¿La vista comercial por producto es una agrupación alterna o la predeterminada? | Producto | No para wireframe base | Abierta |
| Q-02 | ¿Existe exportación de alertas a CSV/PDF en el dashboard? | Producto | No para MVP inicial | Abierta |
| D-01 | Selección de librería UI y estrategia CSS | Frontend | No para wireframe; sí para implementación | Pendiente |

### Alineación definitiva del Dashboard

- Contar como unidad operativa cada **SKU vendible** (incluido `sku_base` para producto simple), sin duplicar saldo a nivel producto.
- El dashboard monitorea disponibilidad operativa (`on_hand`, `reserved`, `available`) y alertas (`0 < available <= umbral_efectivo` para Stock bajo; `available = 0` para Agotado).
- No se calculan métricas de ventas ni Top 5 productos, pues corresponden exclusivamente a Ventas/Postventa.
- Actualizar indicadores/alertas al recibir `inventory.stock.changed` de forma reactiva y eventualmente consistente.

## 19. Registro de revisiones

| Versión | Fecha | Autor | Cambio | Aprobado por |
|---|---|---|---|---|
| 0.1 | 2026-09-17 | Asistente | Borrador inicial basado en spec, HU, template y DESIGN.md | Pendiente |
| 0.3 | 2026-09-18 | Asistente | Alineación de wireframe con Specs/HU definitivos y contratos externos provisionales | Pendiente de revisión del equipo |
| 0.4 | 2026-09-21 | Asistente | Purgado de Top 5 productos más vendidos, ventas confirmadas y selectores de período; incorporación de distribución operativa por ubicación y fórmula de umbral efectivo | Aprobado |
| 0.5 | 2026-09-30 | Asistente | Incorporación de CA-10 (dashboard estrictamente de lectura: consume `inventory.stock.changed`, no lo republica ni muta stock) y trazabilidad actualizada | Pendiente de revisión del equipo |

---

## Lista de control antes de generar el HTML

- [x] Las fuentes funcionales están identificadas.
- [x] El alcance y fuera de alcance están claros.
- [x] Las pantallas y variantes están inventariadas.
- [x] Los criterios CA-01 a CA-10 están cubiertos.
- [x] La distribución por ubicación, los filtros y la reactividad están documentados.
- [x] Se eliminaron rankings de ventas y Top 5 según SPEC-016 y HU-016.
- [x] Los supuestos y preguntas están registrados.
- [x] El formato HTML está definido.
- [ ] Confirmar el ID WF-016 contra INDEX.md.
- [ ] Confirmar rutas y permisos antes de implementar el frontend.

---
