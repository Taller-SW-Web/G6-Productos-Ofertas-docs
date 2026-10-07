# MK-014 — Plan de construcción

## 1. Identificación

**Funcionalidad:** historial de auditoría de precios. **Owner:** Leonardo Vera Rodríguez. **Rama:** `vera`. **Issue:** #66, coordinado por #61. **Versión:** 1.0.0, 2026-10-02. **Estado:** En revisión; ejecución no iniciada.

Entrada rectora: [component-spec.md](component-spec.md), inventario §4, contratos §6, pantallas §9, fixtures §12 y hallazgos §13. [Tasks](tasks.md) traduce este plan a acciones comprobables; no introduce otro inventario ni reglas nuevas.

## 2. Contrato de ejecución

| Elemento | Compromiso |
|---|---|
| Entradas | SPEC/HU/WF/FLOW-014 y contratos; UX 2.0/DESIGN 1.0.0; component-spec revisado |
| Salidas futuras | Cinco pantallas/rutas, fixtures tipados, lectura y exportación verificables, evidencia, revisión UX, Figma fiel y `validation-report.md` |
| Restricciones | React + TypeScript + Mantine + Tabler, tema central y desktop. Solo lectura de asientos; CSV/PDF, sin XLSX, archivo frío, mutación ni rol Auditor independiente |
| Condición de parada | Si una representación requiere un dato/capacidad ausente, registrar y bloquear tarea dependiente. Nunca inventar moneda histórica, permisos o un job ante rechazo 422 |
| Fuentes de negocio | Owner propone cambios bajo revisión correspondiente; no resolver contrato escribiendo campos adicionales en fixtures |
| Aprobación | Generación documental/pruebas UI no aprueban Figma ni cierre #66 |

El component-spec está **En revisión**. Q-014-01 bloquea validación final de moneda/unidad de los importes y formatos monetarios de exportación; puede prepararse la estructura, el formateo de null y los estados contractuales sin atribuir PEN/S/ a los registros.

## 3. Entradas obligatorias

| Entrada | Disponibilidad | Verificación antes de ejecutar |
|---|---|---|
| [SPEC](..\..\..\requisitos\specs\SPEC-014-historial-auditoria-precios.md), [HU](..\..\..\requisitos\hu\HU-014-historial-auditoria-precios.md) | Sí | Reglas append-only, 15 campos, filtros, límites inclusive y obligaciones backend |
| [WF](../../wireframes/flows/WF-014-historial-auditoria-precios.md), [FLOW](..\..\..\requisitos\flujos\FLOW-014-historial-auditoria-precios.md) | Sí | S01/S02/S02-N/CSV/PDF; mapeo a cinco IDs locales; detalle contextual |
| [OpenAPI](..\..\..\contratos\http\openapi.yaml), [AsyncAPI](..\..\..\contratos\eventos\asyncapi.yaml), [Contrato API](..\..\..\contratos\http\Contrato_Api.md) | Sí | Aliases de pagina/tamanio, estados de exportación y error sin ID; resolver Q-014-01 |
| [Propuesta UX](../ux/propuesta-ux.md), [Decisions](../ux/ux-decisions.md), [Guidelines](../ux/ux-guidelines.md), [DESIGN](../DESIGN.md) | Sí; coinciden con origin/master en base ea9c4f1 | Fuentes vigentes #59 + #60; DESIGN sustituye gris de baja fidelidad, no negocio |
| [Component Spec](component-spec.md) | Redactado, En revisión | Revisar inventario/props/fixtures y cerrar hallazgo para representación final afectada |
| [Pipeline](../README.md), [Prototipo](../prototipo/README.md), [Gobernanza](..\..\..\EQUIPO_Y_RESPONSABILIDADES.md) | Sí | Rutas directas; autovalidación y revisión transversal por separado |
| [Plantilla Plan](../_plantillas/mockup/plan.template.md), [Tasks](../_plantillas/mockup/tasks.template.md), [Validation Report](../_plantillas/mockup/validation-report.template.md) | Sí | Estructura, tarea verificable y reporte con evidencia real |

## 4. Pantalla ancla y secuencia

**MK-014-S01** es la pantalla ancla: fija shell, FilterBar, tabla de solo lectura, formateo de valores y paginación. Antes de abrir detalle/exportación debe diferenciar condiciones editadas de aplicadas, null de cero y vacío de fallo.

| Orden | Pantalla | Dependencia / resultado |
|---|---|---|
| 1 | S01 | Tema y fixtures de listado; seis filtros y meta; lectura sin mutación |
| 2 | S02 | Consulta detalle, modal 640 px y contexto S01 preservado |
| 3 | S03 | Mismo contenedor S02 con 404; sin asiento simulado |
| 4 | S04 | Filtros aplicados, estado de solicitud/trabajo y CSV hasta 100 000 |
| 5 | S05 | Reutilizar C05 de S04 con PDF hasta 500 y recuperación por límites |

Las cinco son P0. S03 tiene ruta propia aunque comparta modal. No sumar pantallas administrativas para CA de archivado/deduplicación que pertenecen al backend.

## 5. Estrategia técnica

1. Revisar fuentes y resolver Q-014-01 mediante definición oficial de moneda histórica o garantía explícita de unidad. Actualizar spec/plan/tasks dependientes, sin copiar moneda actual de MK-013.
2. Reutilizar base de `mockups/prototipo/`, tema y componentes aportados por MK-013/equipo. Si aún no existen, construir base mínima común; no crear otra aplicación ni tema por MK. Actualmente el entorno solo tiene README.
3. Tipar DTOs de listado/detalle/exportación y estados de UI por separado. Materializar FX-014-01 a 18; cantidades de exportación son meta determinista, sin fabricar arrays gigantes ni campos de progreso ausentes.
4. Resolver `/MK014/S01` a `/MK014/S05` y `?fixture=` reproducible; entradas directas S02/S03 montan fondo contextual y gestionan foco sin pedir interacción previa. No fijar dominio/puerto ni ejecutar escrituras reales al abrir ruta.
5. Construir S01 con filtro aplicado y paginación; ignorar respuestas obsoletas. Crear C01–C04 para filtro, lectura y null; comprobar los quince campos en sus destinos sin convertir todos en columnas.
6. Extender detalle y 404; luego C05 y S04/S05 con solicitud, admisión, generación, descarga y rechazos separados. Adaptador fixture devuelve respuestas del contrato: POST 422 no crea ID; POST 202 inicia seguimiento.
7. Normalizar Mantine contra DESIGN, revisar lenguaje, seguridad visible, keyboard y 1440 px. Ejecutar verificaciones sensibles, registrar autovalidación con revisión Git y evidencia.
8. Obtener revisión UX transversal posterior y resolver hallazgos. Solo después de APROBADO PARA FIGMA trasladar versión a Figma, verificar fidelidad y emitir reporte APROBADO con enlaces reales.

## 6. Reutilización y estructura prevista

| Ubicación futura | Contenido |
|---|---|
| `mockups/prototipo/src/tema/` | Tema único: tokens, tipografías y variantes de DESIGN |
| `mockups/prototipo/src/componentes/` | Shell, FilterBar, Table, Modal, Result y controles comunes sin reglas de negocio de Auditoría |
| `mockups/prototipo/src/pantallas/MK014/` | S01–S05, C01–C05, DTOs/adaptadores y fixtures locales |

Compartir presentación genérica de seguimiento con otros MK cuando corresponda, sin reutilizar estados del lote Pricing como estados de exportación. S04/S05 comparten C05: formato y límite son configuración por pantalla, no dos implementaciones divergentes. Una base de Stitch requiere normalización y revisión; no reemplaza fuentes ni verificación humana.

## 7. Estados y evidencia requerida

| Área | Fixtures | Verificación clave |
|---|---|---|
| Lectura y ausencia | FX-014-01 a 05,17 | Quince campos con destino, null correcto, cero real, moneda no inventada; solo lectura |
| Filtros/páginas | FX-014-06,07 | Retorno contextual, nombres de query correctos, rango, reset de página y respuesta tardía |
| Carga/errores/detalle 404 | FX-014-08,09 | Error diferente de vacío, detalle no encontrado diferente de permiso y servicio caído |
| Límites/asincronía | FX-014-10 a 14,18 | CSV 100 000/100 001 y PDF 500/501; límite inclusive, 422 sin job, 202 sin descarga anticipada |
| Seguridad/ambigüedad | FX-014-15,16 | Sin datos protegidos ante 403, sin reenvío de POST desconocido, consulta por ID conocido |
| Acceso y desktop | Todos los estados aplicables | Cinco rutas, modal con foco/retorno, tablas legibles y no overflow involuntario a 1440 px |

Captura/registro debe incluir revisión, ruta/fixture, viewport, fuente, resultado esperado y observado. Interacciones necesitan evidencia de secuencia, no solo imagen terminal. Pruebas UI no acreditan persistencia append-only, deduplicación por message_id, retención de 24 meses/5 años ni integridad del archivo frío.

## 8. Riesgos

| Riesgo | Mitigación y alcance |
|---|---|
| Unidad monetaria ausente | T06 BLOCKED por Q-014-01; representación de revisión honesta y revisión contractual antes de aprobación final |
| Exportar página actual o filtros aún no aplicados | Copiar seis filtros aplicados al body; excluir pagina/tamanio; mostrar alcance completo |
| Enum genérico permite XLSX | S04/S05 limitan request a CSV/PDF |
| 422 tratado como generación fallida | Separar estado de solicitud de DTO trabajo; no asignar ID ni iniciar polling |
| Fallback CSV indiscriminado | Solo ofrecer compatibilidad cuando cantidad conocida ≤100 000; servidor reevalúa al solicitar |
| Error de sesión muestra datos previos | Retirar región protegida ante 401/403, conservar únicamente contexto no sensible apropiado |
| Revisión o Figma adelantados | Gates explícitos; mismo humano owner/revisor según gobernanza, fases con evidencia separada |

## 9. Gates, roles y cierre

| Fase / gate | Responsable | Criterio de salida |
|---|---|---|
| A — Preparación funcional | Leonardo owner; Miguel en revisión técnica de cambios de contrato | Spec revisada, Q-014-01 resuelto y tareas/fixtures actualizados |
| B — Construcción UX | Leonardo owner | Cinco pantallas P0/rutas/estados; lectura, filtros, null y exportación conformes a fuentes |
| C — Normalización UI | Leonardo owner | Tema/DS/Mantine/Tabler, copy y estados comunes; build/typecheck del entorno implementado |
| D — Desktop y autovalidación | Leonardo owner | 1440 px y teclado, evidencia/tareas trazables, cero bloqueantes |
| E — Revisión transversal | Leonardo rol UI/UX, posterior y registrada por separado | Hallazgos corregidos y decisión humana APROBADO PARA FIGMA para revisión concreta |
| F — Figma/fidelidad/reporte | Leonardo owner y revisión UX conforme a gobernanza | Cinco pantallas y estados exigidos reflejados fielmente, enlaces reales y `validation-report.md` APROBADO |

Todos los gates permanecen pendientes. La coincidencia de owner y revisor no suprime pasos ni permite al generador firmar aprobaciones. #66 requiere terminar el pipeline de MK-013 y MK-014; completar documentación de preparación no lo cierra.
