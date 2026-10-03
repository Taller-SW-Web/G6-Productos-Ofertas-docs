# Plan de Mockup — MK-005

## 1. Identificación

Gestión de cupones de descuento · Axel Cueva · issue #64 · versión 1.2 · 2026-10-03. **Documentación redactada, en revisión; preparación pendiente de aprobación del component-spec**. Documentos en `cueva`; implementación/refinamiento en `lab/cueva`.

## 2. Contrato de ejecución

### Entradas

[Component-spec](component-spec.md) **APROBADO**, fuentes vigentes de su §2 y Design System coherente. Estado actual: component-spec EN REVISIÓN; la dependencia de aprobación permanece bloqueada en T03. Plan/tasks son documentos derivados sujetos a esa revisión.

### Salidas esperadas

Después de aprobar las entradas: 6 pantallas P0 del inventario, código normalizado en `mockups/prototipo/src/pantallas/MK005/`, fixtures reproducibles, autovalidación, revisión UX de Vera y visto bueno APROBADO PARA FIGMA; después Figma, fidelidad y validation-report APROBADO. Redactar documentos no acredita estas salidas.

### Restricciones de ejecución

Seguir #61/#64 y las fuentes oficiales. No iniciar implementación con component-spec sin aprobar. Usar ramas existentes, conservar ownership y trabajar en laboratorio. No inventar campos, operaciones, permisos o reglas; no declarar aprobaciones/revisiones realizadas sin evidencia. Vera realiza la revisión UX transversal; este MK no le atribuye una obligación oficial adicional de producir una base con una herramienta determinada.

### Condiciones de parada / escalamiento

Una fuente contradictoria o aprobación documental pendiente bloquea la parte afectada. Registrar causa, responsable y condición verificable en tasks §9. Cualquier cambio del pipeline o reparto transversal de tareas necesita homologación del equipo; la coordinación de propuestas iniciales no agrega un gate oficial exclusivo a este MK.

## 3. Entradas obligatorias

| Entrada | Estado requerido | Estado actual / evidencia |
|---|---|---|
| Component Spec | APROBADO | EN REVISIÓN; T03 BLOCKED, falta dictamen sobre versión1.2. |
| SPEC/HU/WF/FLOW y contratos | Vigentes y coherentes | Referencias en component-spec §2; resolver contradicciones antes de implementar. |
| UX integral, UXD, UXG y DESIGN | Vigentes y coherentes | Fuentes disponibles; su existencia no aprueba este MK. |
| Laboratorio y entorno | Alineados con documentación aprobada | T04 pendiente de T03; usar estructura de [prototipo](../prototipo/README.md). |

## 4. Objetivo

El Gestor Comercial consulta y configura cupones, límites y política de restitución; conoce el uso global confirmado y cambia el estado sin operar un pedido. Construir exclusivamente el inventario y sus estados, con evidencia trazable por pantalla.

## 5. Pantallas

| ID | Pantalla | Propósito | Entrada | Acción principal | Salida | Prioridad | Ruta |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MK-005-S01 | Listado de cupones | Consultar estado/configuración y elegir un cupón. | Sidebar o ruta directa. | Crear cupón | S02 o S03/S04 del registro elegido. | P0 | `/MK005/S01` |
| MK-005-S02 | Crear cupón | Registrar una configuración válida. | S01 / Crear cupón. | Crear cupón | S04 del cupón creado solo tras guardado confirmado; cancelar vuelve a S01. | P0 | `/MK005/S02` |
| MK-005-S03 | Editar cupón | Modificar el cupón seleccionado sin perder identidad ni entradas. | S01 o S04 con cuponId. | Guardar cambios | S04 del mismo cupón; cancelar conserva registro anterior. | P0 | `/MK005/S03` |
| MK-005-S04 | Detalle de cupón | Leer configuración, promoción y uso confirmado. | S01 o guardado confirmado. | Editar cupón | S03; Límites y uso a S05; Cambiar estado a S06; volver a S01. | P0 | `/MK005/S04` |
| MK-005-S05 | Límites y uso | Consultar cupos derivados y política sin actuar sobre pedidos. | S04 / Límites y uso. | Volver al detalle | S04 del mismo cupón. | P0 | `/MK005/S05` |
| MK-005-S06 | Cambiar estado | Confirmar Activar o Desactivar el cupón seleccionado. | S04 / Cambiar estado; entrada directa reproduce detalle + diálogo. | Activar cupón / Desactivar cupón | Confirmado: S04 con nuevo estado; cancelar/rechazo conserva el anterior. | P0 | `/MK005/S06` |

Contenido detallado en component-spec §10; no crear rutas/nuevas vistas por una facilidad de la biblioteca.

## 6. Pantalla ancla

**MK-005-S01** fija shell, jerarquía, filtros, tabla y estados. El owner la contrasta con component-spec aprobado y DESIGN antes de extender la composición a otras pantallas. Su implementación no sustituye la revisión UX final.

## 7. Estrategia

1. Atender la revisión de component-spec y registrar aprobación documental en T03.
2. Actualizar plan/tasks si cambia el inventario, confirmar DoR y alinear laboratorio en T04.
3. Implementar/refinar S01 y las restantes pantallas según las tareas de §4.
4. Completar fixtures y casos negativos, normalizar componentes/tokens y accesibilidad.
5. Autovalidar rutas, navegación, datos y viewport; registrar evidencia real en validation-report.
6. Someter la versión autovalidada a revisión UX transversal de Vera y corregir hallazgos.
7. Con APROBADO PARA FIGMA, promover selectivamente artefactos consolidados a `cueva`; nunca fusionar toda lab hacia una rama oficial.
8. Reflejar la versión con visto bueno en Figma, verificar fidelidad y cerrar reporte/índice. Promover código no equivale al cierre de Figma.

## 8. Reutilización

Shell, Breadcrumbs, FilterBar, Table/Pagination, feedback, formulario, selectors y confirmación comunes en `src/componentes`; tema único en `src/tema`. Cada MK conserva datos/copy/validación propios. Reutilizar estructura, no compartir indebidamente los límites de negocio entre cupones/promociones/reglas. No modificar el trabajo de otros owners.

## 9. Normalización

React + TypeScript + Mantine + Tabler según DESIGN §15. La guía menciona Mantine9.6.2 pero no hay package/lockfile del entorno: verificar disponibilidad/compatibilidad al construir, fijar versiones y registrar la decisión; no instalar ahora ni declarar una versión ya probada. Inter/Oswald, tokens y dimensiones exactas del DS; adaptar mediante tema/Styles API compartidos. Sin datagrid/router/patrones/dependencias extra por inercia. El mecanismo de rutas debe respetar accesos directos sin imponer puerto/host en documentación.

## 10. Estados

Component-spec §10/13 define qué estados corresponden a cada pantalla, cómo reproducirlos y qué regla justifican. Empty/sin-resultados solo colecciones; 404 del registro separado. Error de guardar conserva draft, resultado desconocido no reenvía automáticamente, 401/403 bloquea mutación, confirmación no modifica estado antes de respuesta. El HTML previo no sustituye pruebas del mockup Mantine.

## 11. Orden de ejecución

Component Spec y aprobación de entradas → Plan/Tasks alineados → implementación/refinamiento → normalización → autovalidación → revisión UX transversal → APROBADO PARA FIGMA → Figma → fidelidad → Validation Report APROBADO. La promoción selectiva requiere visto bueno y conserva los límites del laboratorio. Tasks registra avance; validation-report registra evidencia, no intenciones.

## 12. Riesgos

| Riesgo | Respuesta verificable |
|---|---|
| Component-spec todavía en revisión | T03 y construcción BLOCKED hasta dictamen identificable; no llamar completa a la preparación. |
| Propuesta visual contradice negocio | Cotejar campos, acciones y estados contra fuentes oficiales; corregir antes de consolidar. |
| Pérdida de contexto/borrador | Ejecutar los checks específicos de cada pantalla en tasks; comparar datos antes/después. |
| Desalineación visual | Medir en 1440×900, comprobar tokens, foco y ausencia de overflow; registrar capturas. |
| Integración/enriquecimiento ausente | Fixtures identificados y No disponible donde corresponde; no inventar capacidades de otros owners. |
| Acuerdo operativo confundido con gobernanza | Homologar cambios transversales en fuentes oficiales; no imponer una herramienta o proveedor como gate local. |

## 13. Quality Gates

| Gate | Criterio de salida | Evidencia / responsable |
|---|---|---|
| A Funcional | Inventario, campos, contratos, navegación y casos negativos sin comportamiento inventado. | Owner, recorridos/fixtures de component-spec §13 en el MK construido. |
| B UX | UXD/UXG aplicables, contexto/errores/confirmación y LUX justificadas. | Owner y revisión transversal posterior. |
| C UI | DS/tokens/tipografía/componentes compartidos, stack normalizado y build correcto. | Código + build + comparación DS; no aplica a documentación sola. |
| D PC | 1440×900, sin overflow horizontal, teclado/foco/labels. | Capturas y recorrido accesible por estado. |
| E Revisión | Vera revisó, hallazgos bloqueantes/importantes cerrados y APROBADO PARA FIGMA verificable. | Revisor/fecha/versión; habilita promoción consolidada y Figma. |
| F Figma/cierre | Enlace, fidelidad pantalla/estado, reporte final e índice actualizado. | Owner y evidencia; solo entonces APROBADO/#64 completo. |

La preparación no está aprobada: falta T03. Los gates A–F todavía no se acreditan mediante pantallas; las tareas de redacción DONE únicamente acreditan documentos existentes, revisables y sujetos a cambios.
