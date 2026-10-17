# Evidencia de uso de IA en frontend

- **Registros:** IA-FE-001 e IA-FE-002.
- **Documentado retrospectivamente:** 2026-10-17.
- **Repositorio:** `Taller-SW-Web/G6-Productos-Ofertas-frontend`.
- **Revisión local identificada:** rama `cueva`, SHA `f914478b028d01cc00bd011844ebfe3ccc426df7`.

## 1. Implementación localizada: IA-FE-001

El equipo confirma el uso de IA en el desarrollo. La revisión local contiene React/TypeScript/Vite, Mantine y Tabler, con features `foundation`, `pricing` y `promotions`. Se identificaron código, commits y reportes para relacionar las intervenciones históricas que se recuperen.

| Artefacto versionado | Contenido identificado | Estado de atribución de IA |
|---|---|---|
| [Foundation, commit 95722ff](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/commit/95722ff3d1cab2d7eb8356a6ee36b2e813b5aafe) y [su reporte](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/f914478b028d01cc00bd011844ebfe3ccc426df7/docs/VALIDACION_FOUNDATION.md) | Theme, shell, componentes compartidos y piloto de precio vigente. | Uso general declarado; conversación, herramienta y aporte exacto por archivo pendientes de recuperar. |
| [Implementación de MK-005/006/007](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/commit/8135b4afb4b8664d8de20d57116e0f2f5ce9ea75) | Flujos de cupones, promociones y recomendaciones, reportados como 19 vistas de escritorio. | Código identificado; atribución detallada de generación pendiente. |
| [Corrección f914478](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/commit/f914478b028d01cc00bd011844ebfe3ccc426df7) | Composición de servicios, asociaciones, escenarios DEV y validaciones. | Código y reporte identificados; recuperar instrucciones y decisiones humanas de esta intervención. |

Los commits acreditan cambios de código. La declaración del equipo acredita el uso informado de IA. Para atribuir un componente específico a una herramienta o sesión falta unir ambas evidencias. No se completan con supuestos los prompts ni el modelo utilizado.

## 2. Cómo se relaciona con los Markdown existentes

El [reporte de Cueva](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/f914478b028d01cc00bd011844ebfe3ccc426df7/docs/AVANCE_FRONTEND_CUEVA.md) identifica como fuente Docs `be5c2db16aca6d6d18b3005a2da4205f724038e3`, las SPEC/HU/FLOW, los artefactos MK-005/006/007 y DESIGN 1.1.0. También enumera diferencias entre HTML y React, correcciones y revisión UX pendiente. El reporte de Foundation registra sus propias fuentes y correcciones FND-01–06.

Estos reportes permiten explicar el recorrido entre requisitos, mockups y código. Para cada sesión recuperada, registrar cuáles de esas fuentes se entregaron efectivamente a la IA y qué instrucciones se dieron para implementarlas. La existencia de `component-spec.md`, `plan.md` y `tasks.md` no demuestra por sí sola que fueron el prompt original.

## 3. Código y validación que se pueden mostrar

| Evidencia | Utilidad para la explicación |
|---|---|
| [promotionServices.ts](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/f914478b028d01cc00bd011844ebfe3ccc426df7/src/features/promotions/services/promotionServices.ts) | Composición central de puertos y adapters; en este SHA la instancia exportada usa `createMockPromotionServices()`. |
| [mockCouponRepository.ts](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/f914478b028d01cc00bd011844ebfe3ccc426df7/src/features/promotions/adapters/mockCouponRepository.ts) | Adaptador local que permite demostrar interacciones sin atribuirlas a una API real. |
| [Pruebas de adapters](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/f914478b028d01cc00bd011844ebfe3ccc426df7/tests/promotions-adapters.spec.ts) | Casos de sustitución de dependencias y comportamiento de composición. |
| [Pruebas visuales](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/f914478b028d01cc00bd011844ebfe3ccc426df7/tests/promotions-visual.spec.ts) | Recorrido para producir las capturas y mediciones descritas en el reporte. |

El reporte de Cueva informa typecheck, build y lint aprobados, 65 pruebas y revisión de 19 vistas a 1440 × 900 en su iteración final. Son resultados históricos consultados; esta recopilación no repitió la suite, no inspeccionó todas las capturas y no concede aprobación UX. Las escrituras de esa revisión funcionan en memoria y se reinician al recargar, según su README y reporte.

## 4. Revisión asistida recuperada: IA-FE-002

En Codex se recuperó la conversación **«Prepara PR parcial de cueva»**, ID `01a147bc-4710-7bd0-bd11-cf09c6cf4019`, proyecto backend, turno `01a147df-32e9-7073-9683-9182f5c2b7e9`.

Instrucción original del usuario:

> mi frontend está integrado con el backend? es posible? además estamos conectados a otros servicios? revisa eso

La respuesta registra revisión de código y de versiones publicadas y concluye que no había integración real en el alcance revisado. El tipo de aporte es **diagnóstico y revisión**, con cero archivos modificados según ese reporte. Esta sesión no se registra como generación original del frontend.

La conversación examinó además una revisión publicada `15afd228e4a987336fc32b4cceeb6ebfff0da967`, distinta del SHA local de esta recopilación. Se conservan ambas referencias: la revisión de integración no debe presentarse como una prueba ejecutada sobre `f914478`. El uso de mocks en el SHA local se contrastó independientemente mediante lectura de su código versionado. Las observaciones históricas de disponibilidad pública tampoco describen por sí solas el estado actual del despliegue.

## 5. Intervención humana y pendientes

El usuario definió la pregunta de integración y el equipo mantiene ownership y aprobación conforme a [Equipo y responsabilidades](../../EQUIPO_Y_RESPONSABILIDADES.md). El reporte de Cueva registra correcciones, diferencias de fuentes y aprobación UX pendiente; no permite atribuir cada edición manual a una persona sin evidencia adicional.

Para cerrar IA-FE-001 falta recuperar las sesiones originales de generación, identificar herramienta/modelo cuando se conozcan, distinguir código propuesto e incorporado y registrar cambios humanos. Para IA-FE-002 falta una exportación o referencia compartible si la evidencia se evaluará fuera de Codex. Los IDs permiten localizar la conversación dentro de la aplicación sin publicar todo su contenido.

La [matriz](matriz-trazabilidad.md) mantiene separadas la cobertura de código y la evidencia de IA; la [plantilla](plantilla-intervencion.md) permite ampliar estos casos por tarea.
