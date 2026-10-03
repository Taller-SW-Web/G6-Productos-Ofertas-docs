# Plan de Mockup — MK-007

## 1. Identificación

Reglas de venta cruzada y upselling · Axel Cueva · issue #64 · versión 1.1 · 2026-10-03. **Preparación documental completa; construcción pendiente de base raw**. Documentos en `cueva`; iteración posterior en `lab/cueva`; sin ramas nuevas.

## 2. Contrato de ejecución

### Entradas

[component-spec](component-spec.md) completo y sus fuentes §2; SPEC/HU/WF/FLOW-007, UX2.0 y DESIGN1.0.0. Posteriormente, base raw de Vera identificada por MK/pantallas/ancla/supuestos/dudas. El raw no reemplaza ninguna fuente.

### Salidas esperadas

Ahora: component-spec, plan y tasks preparados para Vera. Después de recibir raw: 7 P0 con rutas §5, código modular en `mockups/prototipo/src/pantallas/MK007/`, fixtures/estados reproducibles y autovalidación objetiva. Finalmente revisión/visto bueno de Vera, versión consolidada promovida a `cueva`, Figma fiel y validation-report final según pipeline.

### Restricciones de ejecución

Usar ramas existentes; no iniciar implementación mientras no llegue base. Vera prepara las propuestas con MCP de Stitch; owner valida funcionalidad, refina y normaliza en lab. No integrar raw/código experimental directamente en la rama oficial. Documentación necesaria para raw sí se entrega en `cueva`. No inventar campos/operaciones/permisos, cambiar otras funcionalidades, simular servicios o declarar revisiones/Figma no realizados. Conservar el alcance y los límites de component-spec §4/9/14.

### Condiciones de parada / escalamiento

Ausencia de raw bloquea construcción, no documentación. Contradicción con fuente oficial detiene solo pantalla/estado afectado y se registra en tasks §9 con causa, owner y condición de desbloqueo. Respuesta/capacidad ausente se representa honestamente, no se infiere. Una decisión transversal nueva requiere evaluación de UXD/UXG por responsable; no imponerla desde un MK. Gate UX pendiente bloquea aprobación/promoción del código y Figma, no se suplanta con autovalidación.

## 3. Entradas obligatorias

Versiones vigentes en rama `cueva`, enlaces de component-spec §2; [prototipo/README](../prototipo/README.md) para rutas/estructura; plantillas canónicas component-spec → plan → tasks. UX2.0/DS1.0.0 disponibles, pero no acreditan aprobación de este MK. Alinear `lab/cueva` desde `cueva` antes de iterar; resolver conflictos desde fuentes oficiales, nunca escoger raw arbitrariamente.

## 4. Objetivo

El Gestor Comercial define Cross-sell/Upsell por producto o categoría, candidatos, orden, prioridad y vigencia; cada candidato Upsell conserva su criterio de superioridad explícito. Construir exclusivamente el inventario y sus estados, con evidencia trazable por pantalla. El paquete actual termina antes de construir raw; las tareas siguientes conservan estado pendiente.

## 5. Pantallas

| ID | Pantalla | Propósito | Entrada | Acción principal | Salida | Prioridad | Ruta |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MK-007-S01 | Listado de reglas | Comparar reglas y abrir configuración. | Sidebar o ruta directa. | Crear venta cruzada | S02; Crear upselling a S04; editar S03; detalle S06. | P0 | `/MK007/S01` |
| MK-007-S02 | Crear venta cruzada | Relacionar origen con productos complementarios. | S01 / Crear venta cruzada. | Crear regla | S06 tras guardado; S05 para recomendados; cancelar a S01. | P0 | `/MK007/S02` |
| MK-007-S03 | Editar regla | Editar la regla elegida y aplicar requisitos de su tipo. | S01/S06 con reglaId. | Guardar cambios | S06 del mismo registro; S05 regresa al borrador de edición. | P0 | `/MK007/S03` |
| MK-007-S04 | Crear upselling | Configurar alternativas superiores con criterio explícito por producto. | S01 / Crear upselling. | Crear regla de upselling | S06 tras guardado; S05 regresa a esta alta con borrador; cancelar a S01. | P0 | `/MK007/S04` |
| MK-007-S05 | Seleccionar recomendado | Elegir productos activos elegibles para configuración. | S02/S03/S04 con borrador; ruta directa reproduce origen de retorno. | Confirmar selección | Formulario de origen con candidatos preservados; cancelar solo descarta selección temporal. | P0 | `/MK007/S05` |
| MK-007-S06 | Detalle de regla | Leer tipo, origen, prioridad/vigencia y candidatos ordenados. | S01 o guardado confirmado. | Editar regla | S03; Cambiar estado a S07; volver a S01 con contexto. | P0 | `/MK007/S06` |
| MK-007-S07 | Cambiar estado | Confirmar participación de la regla en futuras consultas. | S06 / Cambiar estado; entrada directa reproduce detalle + diálogo. | Activar regla / Desactivar regla | S06 con estado confirmado; cancelación/rechazo no altera badge ni datos. | P0 | `/MK007/S07` |

Contenido detallado en component-spec §10; no crear rutas/nuevas vistas por una facilidad de la biblioteca.

## 6. Pantalla ancla

**MK-007-S01**: fija shell, jerarquía, filtros, tabla, estados y acciones. Vera la genera primero y conserva lenguaje visual en las restantes. Owner la contrasta con fuentes y normaliza antes de extender a formularios/selección/detalles. Una base atractiva no aprueba UX ni cambia negocio.

## 7. Estrategia

1. Entregar documentación en `cueva`: inventario/campos/estados/LUX, contrato de ejecución y tareas verificables.
2. Recibir raw de Vera: registrar entrega, ancla, pantallas, supuestos y dudas. Contrastar contra component-spec y fuentes; no dar raw por correcto.
3. Alinear laboratorio y refinar S01; luego formulario, selectores si existen, detalle y confirmación según §11.
4. Completar estados negativos/contexto, normalizar componentes/tokens/copy y accesibilidad.
5. Autovalidar en desktop1440 con fixtures, rutas y recorridos, registrando evidencia/hallazgos en validation-report.
6. Obtener revisión transversal de Vera, corregir hallazgos y registrar visto bueno real.
7. Promover únicamente artefactos consolidados de estos MK desde laboratorio a `cueva` después del visto bueno; conservar cambios de fuentes permanentes, excluir raw/variantes/herramientas temporales. No merge indiscriminado de toda lab.
8. Pasar versión aprobada a Figma, verificar fidelidad y cerrar reporte/índice. Si el equipo promueve el código antes de Figma, su estado sigue pendiente de fidelidad: no confundir promoción de rama con cierre del pipeline.

## 8. Reutilización

Shell, Breadcrumbs, FilterBar, Table/Pagination, feedback, formulario, selectors y confirmación comunes en `src/componentes`; tema único en `src/tema`. Cada MK conserva datos/copy/validación propios. Reutilizar estructura, no compartir indebidamente los límites de negocio entre cupones/promociones/reglas. No modificar el trabajo de otros owners.

## 9. Normalización

React + TypeScript + Mantine + Tabler según DESIGN §15. La guía menciona Mantine9.6.2 pero no hay package/lockfile del entorno: verificar disponibilidad/compatibilidad al construir, fijar versiones y registrar la decisión; no instalar ahora ni declarar una versión ya probada. Inter/Oswald, tokens y dimensiones exactas del DS; adaptar mediante tema/Styles API compartidos. Sin datagrid/router/patrones/dependencias extra por inercia. El mecanismo de rutas debe respetar accesos directos sin imponer puerto/host en documentación.

## 10. Estados

Component-spec §10/13 define qué estados corresponden a cada pantalla, cómo reproducirlos y qué regla justifican. Empty/sin-resultados solo colecciones; 404 del registro separado. Error de guardar conserva draft, resultado desconocido no reenvía automáticamente, 401/403 bloquea mutación, confirmación no modifica estado antes de respuesta. El HTML previo no sustituye pruebas del mockup Mantine.

## 11. Orden de ejecución

Documentos → base raw S01 y restantes por Vera → recepción/contraste → S01 normalizada → altas/edición y selección → detalle/estado → estados faltantes → normalización → autovalidación → revisión Vera → correcciones → visto bueno → promoción selectiva a `cueva` → Figma/fidelidad/reporte. Tasks §3–8 marca avance; validation-report registra pruebas reales, no sirve como lista de tareas.

## 12. Riesgos

| Riesgo | Respuesta verificable |
|---|---|
| Base todavía ausente | T03/T11 y demás construcción BLOCKED; avanzar solo documentos de entrada. |
| Raw contradice negocio | Contrastar §9/13; detener decisión afectada y corregir fuente si corresponde antes de consolidar. |
| Pérdida de entidad/contexto/draft | Probar edición del segundo registro, retorno de selector, fallo de guardar y cancelación/descarte. |
| Visual desalineado | Medir shell/formulario/DS, tokens y contraste; no aceptar defaults arbitrarios. |
| Integración/enriquecimiento ausente | Fixtures etiquetados, datos No disponible, no inventar backend/capacidad/agregación. |
| Aprobación confundida con raw o commit | Registrar revisor/fecha/resultado; gate E independiente; Figma y fidelidad verificables. |

## 13. Quality Gates

| Gate | Criterio de salida | Evidencia / responsable |
|---|---|---|
| A Funcional | Inventario, campos, contratos, navegación y casos negativos sin comportamiento inventado. | Owner, recorridos/fixtures de component-spec §13 en el MK construido. |
| B UX | UXD/UXG aplicables, contexto/errores/confirmación y LUX justificadas. | Owner y revisión transversal posterior. |
| C UI | DS/tokens/tipografía/componentes compartidos, stack normalizado y build correcto. | Código + build + comparación DS; no aplica a documentación sola. |
| D PC | 1440×900, sin overflow horizontal, teclado/foco/labels. | Capturas y recorrido accesible por estado. |
| E Revisión | Vera revisó, hallazgos bloqueantes/importantes cerrados y APROBADO PARA FIGMA verificable. | Revisor/fecha/versión; habilita promoción consolidada y Figma. |
| F Figma/cierre | Enlace, fidelidad pantalla/estado, reporte final e índice actualizado. | Owner y evidencia; solo entonces APROBADO/#64 completo. |

Los gates A–F aún no se acreditan con pantallas: el estado actual es documental y la base está pendiente. No registrar el trabajo de wireframes o BD como validación visual del MK.
