# Plantilla de especificación para wireframe detallado y anotado

> Duplica este archivo por cada flujo funcional y reemplaza todos los valores
> entre `{{...}}`. Un flujo puede contener varias pantallas relacionadas. No
> crees un archivo distinto para acciones menores de una misma pantalla, como
> buscar, filtrar, ordenar o paginar.

---

## 0. Instrucciones para el agente

Genera un **wireframe detallado y anotado** del flujo descrito en este archivo.

Antes de diseñar:

1. Consulta `SPEC.md` para reglas de negocio, alcance y comportamiento global.
2. Consulta las historias de usuario o el backlog relacionados con los IDs
   indicados en la sección **Trazabilidad**.
3. Consulta `DESIGN.md` para identidad visual, tokens y reglas compartidas.
4. Usa este archivo como fuente del comportamiento específico del flujo.

Prioridad de las fuentes:

1. `SPEC.md`: reglas de negocio y restricciones globales.
2. Historia de usuario/backlog: alcance y criterios de aceptación del incremento.
3. Este archivo: detalle de interacción y composición del flujo.
4. `DESIGN.md`: aplicación visual.

Si dos fuentes se contradicen, **no inventes una resolución**. Registra la
contradicción en **Preguntas y decisiones pendientes** y señala qué parte del
wireframe queda afectada.

Reglas de producción:

- No agregues funciones, campos, permisos o reglas que no estén documentados.
- No elijas una librería de UI o estrategia CSS. Esa decisión está pendiente.
- Usa nombres neutrales para los componentes: botón, diálogo, tabla, selector,
  campo de texto, pestañas, etc.
- No generes código React salvo que se solicite expresamente en otra tarea.
- No sustituyas el wireframe visual por arte ASCII.
- Distingue con claridad datos confirmados, supuestos y preguntas abiertas.
- Representa todos los estados obligatorios definidos en este archivo.
- Numera las anotaciones como `A-01`, `A-02`, `A-03`, etc.
- Mantén el foco en jerarquía, contenido, interacción y comportamiento. El
  acabado visual de alta fidelidad no forma parte de este entregable.

### Entregables esperados

1. Wireframe de cada pantalla y variante obligatoria.
2. Anotaciones numeradas asociadas a elementos visibles.
3. Mapa breve de navegación entre pantallas.
4. Tabla de estados de interfaz.
5. Tabla de comportamiento responsivo.
6. Lista de preguntas, riesgos y supuestos pendientes.
7. Comprobación final contra los criterios de aceptación.

---

# {{WF-00 — Nombre del flujo}}

## 1. Metadatos

| Campo | Valor |
|---|---|
| ID del wireframe | `{{WF-00}}` |
| Nombre del flujo | {{Nombre}} |
| Versión | {{0.1}} |
| Estado | {{Borrador / En revisión / Aprobado}} |
| Responsable | {{Nombre o equipo}} |
| Fecha | {{AAAA-MM-DD}} |
| Última actualización | {{AAAA-MM-DD}} |

## 2. Trazabilidad

| Fuente | Identificador o sección | Qué aporta al flujo |
|---|---|---|
| `SPEC.md` | {{Sección o enlace}} | {{Reglas o alcance}} |
| Historia de usuario | {{US-000}} | {{Necesidad cubierta}} |
| Backlog | {{FUN-00 / EPIC-00}} | {{Funcionalidad cubierta}} |
| `DESIGN.md` | {{Sección aplicable}} | {{Reglas visuales relevantes}} |

### Funcionalidades incluidas

- `{{FUN-00}}`: {{Descripción breve}}.
- `{{FUN-00}}`: {{Descripción breve}}.

### Fuera de alcance

- {{Funcionalidad o comportamiento excluido}}.
- {{Funcionalidad que corresponde a otro flujo}}.

## 3. Usuario objetivo

| Aspecto | Definición |
|---|---|
| Persona | {{Nombre o tipo de persona}} |
| Rol en el sistema | {{Rol}} |
| Nivel técnico | {{Básico / Intermedio / Avanzado}} |
| Contexto de uso | {{Dónde, cuándo y con qué frecuencia usa el sistema}} |
| Necesidad principal | {{Problema que intenta resolver}} |
| Permisos relevantes | {{Qué puede y qué no puede hacer}} |
| Dispositivo principal | {{Escritorio / Tablet / Móvil / Mixto}} |

## 4. Objetivo del flujo

**El usuario debe poder** {{realizar una acción concreta}} **para**
{{obtener un resultado verificable}}.

### Resultado exitoso

{{Describe qué cambia en el sistema y qué confirmación recibe el usuario.}}

### Indicador de finalización

{{Define cómo sabe el usuario que terminó correctamente: mensaje, cambio de
estado, redirección, registro creado, descarga iniciada, etc.}}

## 5. Precondiciones y disparador

### Precondiciones

- {{Sesión, permiso, dato previo o configuración necesaria}}.
- {{Otra condición necesaria}}.

### Punto de entrada

- Ruta o ubicación: `{{/ruta}}`.
- Elemento que inicia el flujo: {{botón, enlace, menú, evento}}.
- Contexto conservado al entrar: {{filtros, selección, página anterior, ninguno}}.

### Salidas del flujo

| Resultado | Destino o comportamiento |
|---|---|
| Éxito | {{Ruta, actualización o confirmación}} |
| Cancelación | {{Retorno y datos que se conservan}} |
| Error recuperable | {{Permanencia, reintento o corrección}} |
| Error no recuperable | {{Salida segura o contacto de soporte}} |

## 6. Secuencia principal

1. {{El usuario inicia el flujo}}.
2. {{El sistema muestra información o solicita datos}}.
3. {{El usuario completa la acción principal}}.
4. {{El sistema valida y procesa}}.
5. {{El sistema confirma el resultado}}.

### Flujos alternativos

| ID | Condición | Comportamiento esperado | Retorno al flujo principal |
|---|---|---|---|
| `ALT-01` | {{Condición}} | {{Respuesta de la interfaz}} | {{Paso o pantalla}} |
| `ALT-02` | {{Condición}} | {{Respuesta de la interfaz}} | {{Paso o pantalla}} |

## 7. Inventario de pantallas y variantes

| ID | Pantalla o variante | Propósito | Ruta o presentación | Obligatoria |
|---|---|---|---|---|
| `S-01` | {{Nombre}} | {{Propósito}} | `{{/ruta}}` | Sí |
| `S-02` | {{Nombre}} | {{Propósito}} | {{Modal / panel / ruta}} | Sí |
| `S-01-E` | {{Estado vacío de S-01}} | {{Propósito}} | Misma ruta | {{Sí / No}} |

> Añade una variante cuando cambien sustancialmente la información, las
> acciones disponibles o la recuperación ante un estado. No dupliques una
> pantalla solo por un cambio visual menor.

## 8. Especificación por pantalla

> Repite esta sección completa por cada pantalla o variante del inventario.

### `{{S-01}}` — {{Nombre de pantalla}}

#### Propósito

{{Qué debe comprender o completar el usuario en esta pantalla.}}

#### Jerarquía de contenido

1. **Nivel primario:** {{Título, dato o acción más importante}}.
2. **Nivel secundario:** {{Información de apoyo}}.
3. **Nivel terciario:** {{Metadatos, ayuda o acciones de baja prioridad}}.

#### Regiones y componentes

| Región | Componente neutral | Contenido | Comportamiento |
|---|---|---|---|
| {{Encabezado}} | {{Título + acción}} | {{Contenido}} | {{Reglas}} |
| {{Contenido principal}} | {{Formulario / tabla / tarjetas}} | {{Contenido}} | {{Reglas}} |
| {{Acciones}} | {{Botones / menú}} | {{Etiquetas}} | {{Reglas}} |
| {{Ayuda o estado}} | {{Alerta / texto / indicador}} | {{Mensaje}} | {{Reglas}} |

#### Acciones

| Prioridad | Acción | Etiqueta visible | Disponibilidad | Resultado |
|---|---|---|---|---|
| Primaria | {{Acción}} | “{{Etiqueta}}” | {{Condición}} | {{Resultado}} |
| Secundaria | {{Acción}} | “{{Etiqueta}}” | {{Condición}} | {{Resultado}} |
| Destructiva | {{Acción}} | “{{Etiqueta}}” | {{Condición}} | {{Confirmación requerida}} |

#### Datos mostrados

| Dato | Fuente o contrato | Formato | Prioridad | Ausencia del dato |
|---|---|---|---|---|
| {{Dato}} | {{OpenAPI / estado local / cálculo}} | {{Formato}} | {{Alta / Media / Baja}} | {{Placeholder u ocultamiento}} |

#### Formulario y validaciones

> Elimina esta subsección si la pantalla no contiene un formulario.

| Campo | Tipo | Obligatorio | Valor inicial | Validación | Mensaje de error |
|---|---|---|---|---|---|
| {{Campo}} | {{Texto / selector / fecha / etc.}} | {{Sí / No}} | {{Valor}} | {{Regla de Zod o regla funcional}} | “{{Mensaje}}” |

- Momento de validación: {{al salir del campo / al enviar / otro}}.
- Conservación de datos tras error: {{comportamiento}}.
- Prevención de envío duplicado: {{comportamiento}}.
- Cambios sin guardar: {{advertencia, descarte o autoguardado}}.

#### Navegación y foco

- Orden de foco: {{secuencia esperada}}.
- Foco inicial: {{elemento}}.
- Foco después de error: {{primer campo inválido / resumen / otro}}.
- Foco al cerrar modal o panel: {{elemento que lo abrió}}.
- Atajo o comportamiento de teclado: {{si aplica}}.

#### Anotaciones del wireframe

| ID | Elemento | Anotación |
|---|---|---|
| `A-01` | {{Elemento visible}} | {{Regla, interacción o razón de UX}} |
| `A-02` | {{Elemento visible}} | {{Regla, interacción o razón de UX}} |

## 9. Estados de interfaz

Define los estados aplicables. Marca como `N/A` únicamente cuando exista una
razón clara.

| Estado | ¿Aplica? | Representación | Acciones disponibles | Recuperación |
|---|---|---|---|---|
| Inicial | {{Sí/No}} | {{Qué se muestra}} | {{Acciones}} | N/A |
| Cargando inicial | {{Sí/No}} | {{Skeleton, indicador o bloqueo}} | {{Acciones}} | {{Tiempo de espera}} |
| Actualizando en segundo plano | {{Sí/No}} | {{Indicador no bloqueante}} | {{Acciones}} | {{Reintento}} |
| Con datos | {{Sí/No}} | {{Contenido normal}} | {{Acciones}} | N/A |
| Vacío inicial | {{Sí/No}} | {{Mensaje y orientación}} | {{CTA}} | {{Cómo crear/agregar}} |
| Sin resultados por filtros | {{Sí/No}} | {{Mensaje contextual}} | {{Limpiar filtros}} | {{Acción}} |
| Error recuperable | {{Sí/No}} | {{Mensaje}} | {{Reintentar}} | {{Acción}} |
| Error de validación | {{Sí/No}} | {{Resumen y campos}} | {{Corregir}} | {{Conservar datos}} |
| Sin conexión | {{Sí/No}} | {{Mensaje}} | {{Reintentar}} | {{Comportamiento}} |
| Sin permisos | {{Sí/No}} | {{Explicación segura}} | {{Volver/solicitar acceso}} | {{Destino}} |
| Sesión expirada | {{Sí/No}} | {{Aviso}} | {{Iniciar sesión}} | {{Retorno al flujo}} |
| Éxito | {{Sí/No}} | {{Toast, mensaje o pantalla}} | {{Siguiente acción}} | N/A |
| Conflicto o dato desactualizado | {{Sí/No}} | {{Aviso}} | {{Recargar/conciliar}} | {{Acción}} |

### Reglas para datos remotos

- Datos que pueden mostrarse desde caché: {{lista o ninguno}}.
- Datos que deben refrescarse: {{momento o evento}}.
- Reintentos visibles para el usuario: {{comportamiento}}.
- Acciones optimistas: {{acción y reversión, o ninguna}}.
- Pérdida de contexto tras recarga: {{qué debe preservarse}}.

## 10. Comportamiento responsivo

No fijes breakpoints nuevos si `DESIGN.md` ya los define.

| Aspecto | Escritorio | Tablet | Móvil |
|---|---|---|---|
| Navegación | {{Comportamiento}} | {{Comportamiento}} | {{Comportamiento}} |
| Distribución | {{Columnas/regiones}} | {{Reorganización}} | {{Apilado}} |
| Tabla o listado | {{Vista completa}} | {{Prioridades}} | {{Tarjetas/scroll/detalle}} |
| Formulario | {{Ancho/columnas}} | {{Ajuste}} | {{Una columna}} |
| Acciones | {{Ubicación}} | {{Ubicación}} | {{Ubicación persistente o menú}} |
| Contenido omitido | {{Ninguno o detalle}} | {{Detalle}} | {{Detalle}} |

### Resoluciones o condiciones críticas

- {{Ancho mínimo o escenario que debe verificarse}}.
- {{Contenido largo, zoom, teclado móvil u orientación}}.

## 11. Accesibilidad

- Nivel objetivo: **WCAG 2.2 AA**, salvo que el proyecto establezca otro.
- Nombre accesible de la pantalla: {{título}}.
- Encabezado principal único: {{texto esperado}}.
- Regiones o landmarks necesarios: {{lista}}.
- Etiquetas de campos: {{regla}}.
- Errores asociados programáticamente a sus campos: {{sí / detalle}}.
- Anuncio de cambios dinámicos: {{éxito, error, carga, resultados}}.
- Uso sin ratón: {{recorrido esperado}}.
- Controles que no dependen solo del color o icono: {{lista}}.
- Texto alternativo para imágenes informativas: {{regla}}.
- Tratamiento de imágenes decorativas: {{regla}}.
- Zoom y reflow: {{consideraciones}}.
- Movimiento o actualización automática: {{control para pausar, o N/A}}.

## 12. Tono visual y contenido

Aplica `DESIGN.md` como única fuente de identidad visual compartida.

### Consideraciones específicas de este flujo

- Densidad: {{Baja / Media / Alta y justificación}}.
- Sensación buscada: {{Confiable, rápida, técnica, calmada, etc.}}.
- Elemento que debe dominar visualmente: {{elemento}}.
- Elementos que deben permanecer discretos: {{elementos}}.

### Microcopy crítica

| Contexto | Texto propuesto | Observación |
|---|---|---|
| Acción primaria | “{{Texto}}” | {{Por qué es claro}} |
| Confirmación | “{{Texto}}” | {{Qué confirma}} |
| Error | “{{Texto}}” | {{Cómo ayuda a recuperarse}} |
| Estado vacío | “{{Texto}}” | {{Siguiente paso ofrecido}} |

## 13. Restricciones técnicas relevantes para el wireframe

- Aplicación web SPA construida con **React**, **TypeScript** y **Vite**.
- Navegación mediante **React Router**; documentar rutas y retorno de contexto.
- Estado remoto mediante **TanStack Query**; representar carga, error,
  revalidación, caché y reintentos cuando sean visibles para el usuario.
- Estado de interfaz compartido mediante **Zustand**, solo cuando sea necesario.
- Formularios mediante **React Hook Form** y validación tipada con **Zod**.
- Contratos HTTP documentados con **OpenAPI/Swagger**.
- La librería de componentes y la estrategia CSS están **pendientes**. No
  prescribir MUI, shadcn/ui, Tailwind ni otra alternativa desde el wireframe.
- Las interacciones críticas deben poder verificarse posteriormente con
  **React Testing Library** y **Playwright**.

### Dependencias o contratos del flujo

| Tipo | Referencia | Impacto visible |
|---|---|---|
| Endpoint | `{{método /ruta}}` | {{Datos, espera o error}} |
| Evento | `{{nombre del evento AsyncAPI}}` | {{Actualización visible, si aplica}} |
| Permiso | `{{permiso o guard}}` | {{Acciones o contenido condicionado}} |

> NestJS, Prisma, PostgreSQL/Supabase, RabbitMQ, Valkey, Traefik y la
> observabilidad forman parte de la arquitectura, pero solo deben aparecer en
> esta especificación cuando produzcan un comportamiento perceptible en la UI.

## 14. Privacidad, seguridad y acciones sensibles

- Datos sensibles visibles: {{lista o ninguno}}.
- Datos que deben ocultarse o enmascararse: {{lista}}.
- Confirmación requerida para acciones destructivas: {{regla}}.
- Reautenticación requerida: {{condición o N/A}}.
- Prevención de exposición por mensajes de error: {{regla}}.
- Registro o trazabilidad visible para el usuario: {{si aplica}}.

## 15. Criterios de aceptación del wireframe

- [ ] Se representa la secuencia principal completa.
- [ ] Se representan los flujos alternativos relevantes.
- [ ] Cada pantalla tiene una acción primaria inequívoca.
- [ ] Todos los campos, columnas y acciones tienen una fuente documentada.
- [ ] Se incluyen carga, vacío, error, éxito y permisos cuando aplican.
- [ ] Las anotaciones explican comportamiento, no solo apariencia.
- [ ] La navegación y el retorno de contexto están definidos.
- [ ] El comportamiento de escritorio, tablet y móvil está definido.
- [ ] El flujo puede completarse mediante teclado.
- [ ] Los mensajes permiten reconocer y corregir errores.
- [ ] No se eligió una librería de UI aún no aprobada.
- [ ] El resultado es consistente con `DESIGN.md`.
- [ ] El resultado satisface los criterios de la historia de usuario/backlog.

### Criterios específicos del flujo

- [ ] {{Criterio verificable}}.
- [ ] {{Criterio verificable}}.
- [ ] {{Criterio verificable}}.

## 16. Supuestos

| ID | Supuesto | Motivo | Impacto si es incorrecto | Requiere validación |
|---|---|---|---|---|
| `SUP-01` | {{Supuesto}} | {{Motivo}} | {{Impacto}} | {{Sí / No}} |

## 17. Preguntas y decisiones pendientes

| ID | Pregunta o decisión | Responsable | Bloquea el wireframe | Fecha objetivo | Estado |
|---|---|---|---|---|---|
| `Q-01` | {{Pregunta concreta}} | {{Persona/equipo}} | {{Sí / No}} | {{AAAA-MM-DD}} | Abierta |
| `D-01` | Selección de librería UI y estrategia CSS | {{Equipo}} | No para wireframe; sí para implementación | {{AAAA-MM-DD}} | Pendiente |

## 18. Registro de revisiones

| Versión | Fecha | Autor | Cambio | Aprobado por |
|---|---|---|---|---|
| 0.1 | {{AAAA-MM-DD}} | {{Autor}} | Borrador inicial | — |

---

## Lista de control antes de entregar al agente

- [ ] Se reemplazaron los marcadores esenciales `{{...}}`.
- [ ] Los IDs de SPEC, historias y backlog son localizables.
- [ ] El alcance y lo que queda fuera están claros.
- [ ] Las pantallas necesarias están inventariadas.
- [ ] Las reglas de negocio críticas no dependen de interpretación.
- [ ] Las preguntas abiertas están registradas.
- [ ] El agente tiene acceso a `SPEC.md`, backlog/historias y `DESIGN.md`.
