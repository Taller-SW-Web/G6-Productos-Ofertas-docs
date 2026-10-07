# Component Spec — MK-012

## 1. Identificación

- **Mockup:** MK-012 — SEO y metadatos de categorías
- **Funcionalidad:** Taxonomía de metadatos (slug, metatítulos y metadescripciones por categoría, con historial de cambios)
- **Responsable:** Leonardo Lopez (rama `lopez`)
- **Versión:** 1.1 — 2026-10-03
- **Estado:** **En revisión** — aprobación documental pendiente. No acredita implementación, autovalidación, revisión UX ni visto bueno para Figma.

Coordinación: ejecución general #61; entradas transversales #59 y #60. Alcance de la entrega: web desktop, viewport canónico 1440 × 900 px.

## 2. Trazabilidad

| Fuente | Referencia | Alcance |
|---|---|---|
| SPEC | [SPEC-012](..\..\..\requisitos\specs\SPEC-012-seo-metadatos.md) | Requisitos 1–10: normalización, unicidad, advertencias, comportamiento de los canales, endpoint público, resolución administrativa y frontera con Categorías |
| HU | [HU-012](..\..\..\requisitos\hu\HU-012-seo-metadatos.md) | CA-01 a CA-10 (sin redefinir ni reordenar) |
| WF | [WF-012](../../wireframes/flows/WF-012-seo-metadatos.md) v0.5 | Pantallas S-01, S-02, S-03; §4 copy del historial; §5 contratos HTTP; §8 integración con WF-008 |
| Flow | [FLOW-012](..\..\..\requisitos\flujos\FLOW-012-seo-metadatos.md) | Consulta, edición e historial |
| Propuesta UX módulo | [propuesta-ux.md](../ux/propuesta-ux.md) | UX 2.0: contadores junto al campo, vista previa de resultado |
| UX Decisions | [ux-decisions.md](../ux/ux-decisions.md) | UXD-004, UXD-007, UXD-013, UXD-015 |
| UX Guidelines | [ux-guidelines.md](../ux/ux-guidelines.md) | UXG-001 a UXG-003, UXG-006 a UXG-015, UXG-020 a UXG-022 |
| API Contract | [api/openapi.yaml](..\..\..\contratos\http\openapi.yaml) 0.5.0 · [Contrato_Api.md](..\..\..\contratos\http\Contrato_Api.md) | `POST /api/v1/seo/categorias/slug/resolver`, `PATCH /api/v1/categorias/{categoriaId}/seo`, contrato público por slug e historial con `SlugHistoryEntry` |
| Design System | [DESIGN.md](../DESIGN.md) 1.0.0 | Foundations, layout desktop, componentes DS-C01…DS-C28 aplicados en §8 |

Las fuentes funcionales prevalecen sobre los artefactos visuales. Este documento no redefine CA ni reglas de negocio; las discrepancias se registran en §14.

### 2.1 Trazabilidad de criterios de aceptación de HU-012

Los 10 CA originales se conservan sin renumerar ni reinterpretar. `Tarea` remite a [tasks.md](tasks.md) y `Evidencia` a las secciones de `validation-report.md` (aún no emitido).

| CA | Criterio original (resumen fiel) | Pantalla / estado | Fixture | Tarea | Evidencia |
|---|---|---|---|---|---|
| CA-01 | Slug normalizado automático | S02 / default | `slug-normalizado` | MK-012-T12 | VR §3, §4 |
| CA-02 | Sufijo automático visible antes de confirmar | S02 / colisión | `slug-con-colision` | MK-012-T12 | VR §3, §4 |
| CA-03 | Duplicado manual rechazado | S02 / error | `slug-carrera-409` | MK-012-T13 | VR §3, §4 |
| CA-04 | Advertencias de 70 y 160 caracteres sin bloquear | S02 / validación | `advertencias-activas` | MK-012-T12 | VR §3, §4 |
| CA-05 | Productos y Ofertas conserva la resolución; Marketplace ejecuta 301 | S03 / default | `historial-slugs` | MK-012-T14 | VR §3, §4 |
| CA-06 | Endpoint público por slug activo | §4 y §5 nota de integración | — | MK-012-T14, T60 | VR §4 |
| CA-07 | La resolución administrativa `POST /api/v1/seo/categorias/slug/resolver` devuelve la propuesta final antes de crear | S02 / integración con MK-008 | `slug-carrera-409` | MK-012-T13 | VR §3, §4 |
| CA-08 | Si la propuesta confirmada deja de estar disponible antes del commit, la creación responde `SLUG_DUPLICADO` y exige nueva resolución o confirmación; no cambia el slug silenciosamente | S02 / error | `slug-carrera-409` | MK-012-T13 | VR §3, §4 |
| CA-09 | SEO solo resuelve y proporciona la propuesta: no crea la categoría ni persiste su slug | §4 y §6 | — | MK-012-T60 | VR §4 |
| CA-10 | Quien crea y revalida la unicidad es Categorías, mediante `slugConfirmado` en `POST /api/v1/categorias` | §6 y §10 (S02) | `slug-carrera-409` | MK-012-T13, T60 | VR §3, §4 |

## 3. Objetivo funcional

- **Usuario:** Gestor Comercial responsable de los metadatos de navegación del catálogo.
- **Objetivo:** mantener el slug y los metadatos de cada categoría y consultar el historial de cambios de slug.
- **Contexto:** las URLs públicas del Marketplace dependen de estos metadatos y su cambio debe ser trazable.
- **Resultado exitoso:** cada categoría tiene un slug válido y visible, y su historial permite reconstruir qué resolutions se aplicaron.

## 4. Alcance

### Incluido
- Listado de categorías con su slug y metadatos, y acceso a la edición.
- Visualización del slug normalizado, con opción de regenerarlo y de ver la propuesta con sufijo cuando hubo colisión.
- Edición de metatítulo y metadescripción con advertencias de longitud que no bloquean el guardado.
- Historial de cambios de slug con slug anterior, slug actual y fecha.
- Estados deterministas default, loading, empty, error y los casos negativos de §13.

### Fuera de alcance
- Crear categorías desde esta interfaz: la creación pertenece a Categorías (MK-008) y exige `slugConfirmado`.
- Reserva del slug o persistencia del slug por parte de SEO: SEO solo resuelve y entrega la propuesta.
- Simulador o endpoint público de backoffice: la lectura por slug activo u histórico es integración, no interfaz administrativa.
- Configuración de redirecciones 301: la ejecución del 301 corresponde a Marketplace.
- Métricas, indexación o despliegue de sitemaps.

## 5. Inventario de pantallas

| ID | Pantalla | Propósito | Entrada | Acción principal | Salida | Prioridad | Ruta del prototipo |
|---|---|---|---|---|---|---|---|
| MK-012-S01 | SEO por categoría | Consultar categorías con su slug y metadatos | Sidebar o ruta directa | Configurar o editar | S02 de la categoría elegida | P0 | `/MK012/S01` |
| MK-012-S02 | Configurar o editar metadatos | Ajustar slug, metatítulo y metadescripción | S01 / Configurar o editar | Guardar cambios | Confirmado: S01; conflicto: permanece en S02 | P0 | `/MK012/S02` |
| MK-012-S03 | Historial de slugs | Consultar los cambios de slug con su fecha | S01 o S02 / Ver historial | Volver a la edición | S01 o S02 | P0 | `/MK012/S03` |

**Reglas de acceso y enrutamiento:**
- Toda pantalla inventariada como `MK-012-SXX` dispone de ruta individual y estable; la ruta deriva exactamente del identificador. Este módulo no tiene variantes de diálogo con sufijo.
- La ruta permite inspección directa sin recorrer el flujo previo.
- El parámetro de consulta de fixture controla la reproducción determinista de estados y no se muestra como control técnico.
- Cualquier alta, baja o renombrado de pantalla obliga a actualizar ruta en este inventario, en [plan.md](plan.md) §5, en [tasks.md](tasks.md) y en `mockups/README.md`.

## 6. Relación entre pantallas

```mermaid
flowchart LR
    S01["S01 SEO por categoría"] -->|"Configurar o editar"| S02["S02 Configurar/Editar"]
    S02 -->|"200 OK"| S01
    S01 -->|"Ver historial"| S03["S03 Historial de slugs"]
    S02 -->|"Ver historial"| S03
    S03 -->|"Volver"| S01
```

No existen caminos huérfanos: toda pantalla tiene entrada desde S01 y retorno a S01. La resolución administrativa de slug no se representa como pantalla adicional de este módulo: la consume MK-008 según WF-012 §8.

## 7. Jerarquía de información

1. **Primaria:** listado de categorías con nombre, slug y presencia de metadatos; acción Configurar o editar.
2. **Secundaria:** formulario con slug, regeneración, metatítulo, metadescripción y sus contadores.
3. **Complementaria:** historial de cambios de slug con fecha y la nota de integración con Marketplace.

Los contadores se muestran junto a su campo y las advertencias no bloquean el guardado.

## 8. Componentes compartidos

| Componente | Pantallas | Uso | Variante | Estados |
|---|---|---|---|---|
| DS-C01 Button | S01–S03 | Configurar, regenerar, guardar, volver | filled primary / outline secondary md 40 px | default, hover, focus, disabled, loading |
| DS-C02 ActionIcon | S01 | Ver historial, configurar | 32/40 px con nombre accesible | default, focus, disabled |
| DS-C03 TextInput | S01, S02 | Slug, buscador, metatítulo | md 40 px, label arriba | default, error, disabled |
| DS-C05 Textarea | S02 | Metadescripción | md, label visible | default, warning |
| DS-C12 Search | S01 | Filtro por nombre o slug | md 40 px | default, sin resultados, loading |
| DS-C14 Badge | S01 | Con o sin metadatos, con historial | sm 24 px con texto | default |
| DS-C17 Table | S01, S03 | Categorías con slug e historial de cambios | header 40 px, fila 48 px | default, loading, empty, sin resultados, error |
| DS-C19 Card | S01, S02, S03 | Formulario e historial | padding 24, radio 12 | default |
| DS-C22 Alert | S02, S03 | Advertencias de longitud y conflicto de slug | padding 16, icono 20 | info, warning, error, success |
| DS-C24 Skeleton/Loader | S01, S02, S03 | Carga inicial | líneas 16/20/24 | loading |
| DS-C25 EmptyState | S01, S03 | Sin categorías o sin historial | padding 32 | empty, sin resultados |
| DS-C28 Breadcrumbs | S01–S03 | `Inicio > Taxonomía > SEO de categorías` | 14/20 | default |

No se redefinen componentes del Design System; las particularidades viven en §9.

## 9. Componentes específicos

### MK-012-C01 — Resolvedor visual de slug

**Propósito** mostrar la propuesta de slug —incluida la indicación de colisión resuelta— sin aplicarla ni persistirla.

**Pantallas:** S02.

**Propiedades conceptuales**

| Propiedad | Tipo | Obligatoria | Regla / Restricción |
|---|---|---|---|
| `nombre` | Texto | Sí | Solo lectura; el slug no se escribe a mano |
| `slug` | Texto | Sí | Propuesta devuelta por la resolución administrativa |
| `colisionResuelta` | Booleano | Sí | Si es verdadero, explica el sufijo aplicado |
| `urlPublica` | Texto | Sí | URL pública derivada de la propuesta |
| `regenerable` | Booleano | Sí | Permite solicitar una nueva propuesta |

**Estados**

| Estado | Disparador | Representación visual | Acción permitida |
|---|---|---|---|
| Default | Propuesta sin colisión | URL pública legible | Guardar, regenerar, volver |
| Colisión resuelta | `colisionResuelta: true` | Sufijo resaltado y explicación (LUX-01) | Guardar, regenerar, volver |
| Nueva propuesta | Regeneración solicitada | Propuesta actualizada | Guardar, regenerar, volver |
| Conflicto de disponibilidad | `409 SLUG_DUPLICADO` | Alerta persistente y nueva propuesta | Regenerar o volver; nunca se sustituye en silencio |

**Interacciones**

| Acción | Respuesta | Resultado |
|---|---|---|
| Regenerar | Solicita una nueva propuesta | La propuesta se actualiza sin modificar la categoría |
| Guardar | Envía el slug confirmado | `200`: S01; `409`: permanece en S02 con nueva propuesta |

**Accesibilidad:** la URL pública es legible por lector de pantalla y el aviso de colisión se presenta como texto asociado al campo.

### MK-012-C02 — Metadatos con contadores no bloqueantes

**Propósito** editar metatítulo y metadescripción con advertencias de longitud que informan sin impedir el guardado.

**Pantallas:** S02.

**Propiedades conceptuales**

| Propiedad | Tipo | Obligatoria | Regla / Restricción |
|---|---|---|---|
| `metaTitulo` | Texto | No | Advertencia a partir de 70 caracteres |
| `metaDescripcion` | Texto | No | Advertencia a partir de 160 caracteres |
| `limiteMetaTitulo` | Número | Sí | 70 en MVP |
| `limiteMetaDescripcion` | Número | Sí | 160 en MVP |
| `bloqueaGuardado` | Booleano | Sí | Siempre falso: las advertencias no bloquean |

**Estados**

| Estado | Disparador | Representación visual | Acción permitida |
|---|---|---|---|
| Default | Ambos vacíos | Contadores en cero | Completar y guardar |
| Advertencia activa | Umbral superado | Contador con aviso junto al campo | Guardar igualmente |
| Guardando | Envío en curso | Botón en loading | Ninguna |
| Error de validación | `Problem` del servidor | Error junto al campo | Corregir y reintentar |
| Conflicto | Slug no disponible | Alerta de conflicto con nueva propuesta | Regenerar o volver |

**Interacciones**

| Acción | Respuesta | Resultado |
|---|---|---|
| Escribir metadatos | Contadores junto a los campos | El guardado nunca se deshabilita por longitud |
| Guardar | `PATCH` de metadatos | `200`: S01 con los valores aplicados |

**Accesibilidad:** contadores asociados por `aria-describedby` a su campo y avisos anunciados como texto, no solo como color.

### MK-012-C03 — Vista previa de resultado público

**Propósito** mostrar cómo se verá el resultado público a partir del slug y los metadatos, sin presentarlo como una réplica exacta de un buscador.

**Pantallas:** S02.

**Propiedades conceptuales**

| Propiedad | Tipo | Obligatoria | Regla / Restricción |
|---|---|---|---|
| `urlPublica` | Texto | Sí | URL derivada de la propuesta vigente |
| `titulo` | Texto | Sí | Meta-título o título de la categoría |
| `descripcion` | Texto | Sí | Metadescripción o descripción disponible |
| `esAproximacion` | Booleano | Sí | Siempre verdadero: la interfaz lo declara |

**Estados**

| Estado | Disparador | Representación visual | Acción permitida |
|---|---|---|---|
| Default | Propuesta vigente | Tarjeta con URL, título y descripción | Ninguna; es informativa |
| Sin metadatos | Metadatos vacíos | Título y descripción por defecto de la categoría | Completar en el mismo formulario |
| Desactualizada | La propuesta cambió tras regenerar | Aviso de que la vista previa se actualizó | Ninguna |

**Interacciones**

| Acción | Respuesta | Resultado |
|---|---|---|
| Regenerar el slug | La vista previa se recalcula | Nunca se presenta como resultado real de un buscador |

**Accesibilidad:** la vista previa se anuncia como aproximación visual y no como resultado de búsqueda; el texto alternativo describe su función, no un motor de búsqueda concreto.

### MK-012-C04 — Historial de cambios de slug

**Propósito** reconstruir la secuencia de resolutions aplicadas a una categoría con su fecha.

**Pantallas:** S03.

**Propiedades conceptuales**

| Propiedad | Tipo | Obligatoria | Regla / Restricción |
|---|---|---|---|
| `entradas` | Lista de cambio | Sí | Slug anterior, slug actual y fecha de cambio |
| `slugAnterior` | Texto | No | Vacío en la primera asignación |
| `slugActual` | Texto | Sí | Resolution vigente |
| `fechaCambio` | Fecha | Sí | Fecha del cambio, sin información adicional |

**Estados**

| Estado | Disparador | Representación visual | Acción permitida |
|---|---|---|---|
| Default | Historial con entradas | Filas con slug anterior, slug actual y fecha | Volver a la edición |
| Un solo registro | Categoría creada con slug | Fila con la asignación inicial | Volver a la edición |
| Empty | Sin historial disponible | EmptyState explicativo | Volver al listado |

**Interacciones**

| Acción | Respuesta | Resultado |
|---|---|---|
| Volver | Retorna a la pantalla de origen | S01 o S02 |
| Ninguna | La vista es de solo lectura | No existe acción de edición ni reversión |

**Accesibilidad:** la columna de fecha usa formato legible por lector de pantalla y la tabla tiene encabezados asociados.

## 10. Especificación por pantalla

### MK-012-S01 — SEO por categoría

**Propósito y objetivo** consultar las categorías con su slug y la presencia de metadatos, y elegir una sobre la que actuar.
**Estructura y layout** 1. Cabecera con migas y título. 2. Barra con filtro. 3. Tabla con nombre, slug, metadatos y acciones.
**Componentes presentes** DS-C28, DS-C12, DS-C17, DS-C14, DS-C02, DS-C24, DS-C25.
**Acción primaria** Configurar o editar hacia S02.
**Acciones secundarias** Ver historial hacia S03.
**Estados requeridos** default, loading, empty, sin resultados, error, sesión y permisos.
**Contenido clave y microtexto**

| Elemento | Texto / Patrón | Fuente de procedencia |
|---|---|---|
| Título | SEO de categorías | WF-012 §2 |
| Filtro | «Buscar por nombre o slug» | UXD-013 |
| Empty | «Todavía no hay categorías con metadatos configurables.» | UX Guidelines |

### MK-012-S02 — Configurar o editar metadatos

**Propósito y objetivo** ajustar la resolución de slug y los metadatos, viendo el resultado público aproximado antes de guardar.
**Estructura y layout** 1. Migas y título con la categoría. 2. Card de slug con URL pública, regeneración y aviso de colisión. 3. Card de metatítulo y metadescripción con contadores. 4. Card de vista previa. 5. Barra con Guardar cambios y Volver.
**Componentes presentes** DS-C28, DS-C19, DS-C03, DS-C05, DS-C22, DS-C01, DS-C24; MK-012-C01, MK-012-C02, MK-012-C03.
**Acción primaria** Guardar cambios.
**Acciones secundarias** Regenerar slug; Ver historial; Volver.
**Estados requeridos** default, loading, advertencias activas, guardando, conflicto de slug, error, salida-con-cambios, sesión y permisos.
**Contenido clave y microtexto**

| Elemento | Texto / Patrón | Fuente de procedencia |
|---|---|---|
| Slug | «El slug se genera automáticamente a partir del nombre.» | HU-012 CA-01 |
| Colisión | «La propuesta incluye un sufijo para evitar una colisión con URLs existentes.» | HU-012 CA-02 |
| Advertencias | «Supera la longitud recomendada; puedes guardar de todos modos.» | HU-012 CA-04 |
| Vista previa | «Vista previa aproximada; no es una réplica del resultado de un buscador.» | SPEC-012 R4 |
| Frontera | «SEO propone el slug; la categoría se crea desde Categorías con el valor confirmado.» | HU-012 CA-09, CA-10 |

### MK-012-S03 — Historial de slugs

**Propósito y objetivo** consultar los cambios de slug de la categoría con su fecha.
**Estructura y layout** 1. Migas y título con la categoría. 2. Card con la nota de integración. 3. Tabla con slug anterior, slug actual y fecha. 4. Acción Volver.
**Componentes presentes** DS-C28, DS-C19, DS-C17, DS-C22, DS-C25, DS-C01; MK-012-C04.
**Acción primaria** Volver a la pantalla de origen.
**Acciones secundarias** Ninguna: la vista es de solo lectura.
**Estados requeridos** default, un solo registro, empty, loading, error, sesión y permisos.
**Contenido clave y microtexto**

| Elemento | Texto / Patrón | Fuente de procedencia |
|---|---|---|
| Integración | «Marketplace utiliza esta resolución para responder la redirección permanente en la URL pública.» | WF-012 §4 |
| Relación 301 | «Productos y Ofertas conserva la resolución; Marketplace ejecuta el 301.» | HU-012 CA-05 |

## 11. Decisiones UX locales

### LUX-01 — Sufijo de slug destacado y siempre visible

**Problema** el sufijo aplicado por colisión puede pasar inadvertido y seem un cambio no solicitado.
**Alternativas consideradas** mostrar solo el slug resultante (descartada: no revela la colisión) o|Sch Nota al pie (descartada: se pasa por alto).
**Decisión adoptada** resaltar el sufijo dentro de la URL pública y acompañarlo de una explicación.
**Justificación** cumple el requisito de visibilidad antes de confirmar.
**Trade-off** la URL se lee en dos fragmentos visuales.
**Criterio de validación** en S02 el gestor distingue el sufijo aplicado antes de guardar.

### LUX-02 — Advertencias de longitud que no bloquean

**Problema** las advertencias de 70 y 160 caracteres pueden interpretarse como errores si se comunican como tales.
**Alternativas consideradas** deshabilitar el guardado al superar el umbral (descartada: contradice el CA) o no avisar (descartada: oculta una recomendación relevante).
**Decisión adoptada** contador con aviso informativo junto al campo y guardado siempre habilitado.
**Justificacion** informa sin errores y respeta la regla de negocio.
**Trade-off** el formulario permite guardar contenido más largo que la recomendación.
**Criterio de validación** con `advertencias-activas` se puede guardar y el aviso permanece visible.

### LUX-03 — Vista previa declarada como aproximación

**Problema** una vista previa puede confundirse con el resultado real de un buscador si no se declara su origen.
**Alternativas consideradas** omitir la vista previa (descartada: reduce la utilidad de la edición) o reproducir el formato de un buscador concreto (descartada: no es una réplica fiel ni está publicada en las fuentes).
**Decisión adoptada** vista previa informativa con la advertencia de que es aproximada y no una réplica del resultado de un buscador.
**Justificación** evita afirmaciones que la interfaz no puede sostener.
**Trade-off** menos impacto visual que una réplica real.
**Criterio de validación** en S02 la advertencia de aproximación está presente y visible.

## 12. Reglas de layout PC

- Entorno exclusivo web desktop con viewport canónico de 1440 px y scroll vertical.
- Shell, espaciados y tipografía según DESIGN §5; contenido alineado a la rejilla del sistema.
- Tablas con scroll limitado a su región; la página no presenta overflow horizontal en ningún estado.
- Contadores y advertencias próximos a su campo; los avisos de conflicto ocupan un Alert dentro de la Card de slug.
- Iconografía exclusivamente Tabler; tokens de color, radio y espacio del tema, sin estilos inline arbitrarios.

## 13. Fixtures

| Fixture | Caso de negocio | Pantalla / Estado | Datos representativos |
|---|---|---|---|
| `default` | Categorías con metadatos | S01 / Default | `Deportes de montaña` con slug `deportes-de-montana`; `Fútbol` sin metatítulo |
| `loading` | Consulta en curso | S01, S02, S03 / Loading | Skeleton de filas o de cards |
| `empty` | Sin categorías configurables | S01 / Empty | Colección vacía |
| `sin-resultados` | Filtro sin coincidencias | S01 / Empty | Filtro `zapat` sin coincidencias |
| `error` | Fallo controlado | S01, S02 / Error | `Problem` con `VALIDACION` o `ERROR_INTERNO` |
| `sesion` | Token inválido o sin permisos | Todas / Sesión | `401 TOKEN_INVALIDO`, `403 SCOPE_INSUFICIENTE` |
| `slug-normalizado` | Propuesta sin colisión | S02 / Default | `Deportes de montaña` → `deportes-de-montana` |
| `slug-con-colision` | Propuesta con sufijo | S02 / Colisión | `Fútbol` → `futbol-2`, `colisionResuelta: true` |
| `advertencias-activas` | Longitudes por encima del umbral | S02 / Advertencias | Metatítulo de 78 y metadescripción de 180 caracteres |
| `slug-carrera-409` | Propuesta confirmada ya no disponible | S02 / Conflicto | `409 SLUG_DUPLICADO` y nueva propuesta `futbol-3` |
| `historial-slugs` | Cambios registrados | S03 / Default | `deportes` → `deportes-montana` → `deportes-de-montana` con sus fechas |
| `historial-inicial` | Categoría recién creada | S03 / Un solo registro | Primera asignación de slug |
| `historial-vacio` | Sin historial disponible | S03 / Empty | EmptyState explicativo |
| `categoria-no-encontrada` | Identificador inexistente | S02, S03 / Error | `404 CATEGORIA_NO_ENCONTRADA`; sin datos inventados |

## 14. Preguntas y supuestos

### Preguntas abiertas

| ID | Pregunta | Bloquea ejecución | Responsable | Estado |
|---|---|---:|---|---|
| Q-01 | ¿Los umbrales de 70 y 160 caracteres se exponen como parámetro del contrato o permanecen como constantes del MVP? | No | Leonardo Lopez con Taxonomía | Abierta |
| Q-02 | ¿La regeneración de la propuesta de slug exige permisos distintos de la edición de metadatos? | No | Leonardo Lopez con Seguridad | Abierta |

### Supuestos adoptados

| ID | Supuesto | Riesgo | Condición de revisión |
|---|---|---|---|
| A-01 | La lectura pública por slug activo u histórico es integración y no se representa como pantalla administrativa | Si el alcance cambia, habría que añadir una pantalla | Al revisar SPEC-012 |
| A-02 | La edición de metadatos se ejecuta por `PATCH /api/v1/categorias/{categoriaId}/seo` | Si el contrato expusera otra ruta, la pantalla no podría guardar | Al construir S02 |
| A-03 | El historial expone únicamente slug anterior, slug actual y fecha, sin información de autor ni responsable | Si el backend entrega más campos, la vista previa del historial debería reconsiderarse | Al construir S03 |

## 15. Criterios de aceptación

- [ ] Las 3 pantallas de §5 están inventariadas con ruta directa, estable y coherente con su identificador (`/MK012/S01`, `/MK012/S02`, `/MK012/S03`).
- [ ] Los 10 CA de HU-012 están trazados en §2.1 a pantalla, estado, tarea y evidencia, sin redefinir su texto.
- [ ] Operaciones y DTO coinciden con el contrato: `POST /api/v1/seo/categorias/slug/resolver` para la propuesta y `PATCH /api/v1/categorias/{categoriaId}/seo` para los metadatos.
- [ ] El sufijo aplicado por colisión es visible antes de confirmar y un `409 SLUG_DUPLICADO` exige una nueva propuesta, sin sustitución silenciosa.
- [ ] Las advertencias de 70 y 160 caracteres no bloquean el guardado.
- [ ] El historial muestra slug anterior, slug actual y fecha, sin información de responsable ni autor.
- [ ] La vista previa se declara como aproximación visual y no como réplica del resultado de un buscador.
- [ ] La interfaz no crea categorías ni persiste slugs y no expone la lectura pública como pantalla administrativa.
- [ ] Decisiones locales LUX-01, LUX-02 y LUX-03 justificadas en §11.
- [ ] Componentes compartidos reutilizados del Design System y componentes específicos de §9 con propiedades, estados y accesibilidad definidos.
- [ ] Fixtures deterministas para default, loading, empty, error y cada caso negativo de §13.
- [ ] Reglas de layout PC a 1440 px sin overflow horizontal y con accesibilidad básica (foco, nombres, teclado, estado no solo por color).
- [ ] La documentación queda **En revisión** hasta la revisión documental; no se declara aprobación para implementación ni para Figma.
