# Uso de inteligencia artificial en Productos y Ofertas

- **Fecha de documentación:** 2026-10-17, America/Lima.
- **Estado:** registro retrospectivo inicial, con evidencia localizada y pendientes identificados.

## 1. Propósito y alcance

El equipo confirma que utilizó inteligencia artificial durante el desarrollo. Esta documentación reúne el uso identificado en backend, frontend y revisión documental, relacionándolo con instrucciones, código, correcciones y validaciones existentes. Se prepara después de las intervenciones; la fecha de este registro no es la fecha de creación de los artefactos anteriores.

La IA participa como asistente de implementación, revisión y documentación. Las instrucciones y criterios de aceptación corresponden a las personas; la aceptación técnica, funcional y UX conserva los responsables definidos en [Equipo y responsabilidades](../../EQUIPO_Y_RESPONSABILIDADES.md). Una respuesta de IA no concede aprobación humana.

## 2. Documentos de esta entrega

| Documento | Contenido |
|---|---|
| [Encargos Markdown para agentes](../agentes/README.md) | 31 ejemplos derivados de issues reales de Docs, backend y frontend, organizados por proyecto y rama convencional. |
| [Backend](backend.md) | Caso recuperado de Codex: correcciones y prueba de restauración de cupones; fuentes y commits. |
| [Frontend](frontend.md) | Implementación identificada de React, reportes existentes y revisión asistida de integración; límites de atribución. |
| [Matriz de trazabilidad](matriz-trazabilidad.md) | Entradas documentales para las 16 funcionalidades y cobertura de evidencia de IA localizada. |
| [Plantilla de intervención](plantilla-intervencion.md) | Registro de herramienta, instrucción, archivos, intervención humana, resultado y pruebas por tarea. |

## 3. Qué está identificado

| ID de registro | Uso | Base de la afirmación | Pendiente |
|---|---|---|---|
| IA-BE-001 | Codex asistió en la corrección y prueba de restauración única de cupones y actualización de evidencias. | Conversación recuperada, commit y archivos relacionados; detalle en [backend](backend.md). | Revisión humana del registro retrospectivo y exportación de la conversación si se necesita evidencia fuera de la aplicación. |
| IA-FE-001 | Desarrollo de Foundation/Pricing y pantallas de cupones, promociones y recomendaciones con uso de IA declarado por el equipo. | Código y reportes identificados; la declaración general del equipo no identifica cada intervención. | Recuperar las conversaciones de generación y concretar herramienta, instrucciones y contribuciones por archivo. |
| IA-FE-002 | Codex revisó la integración frontend–backend. | Conversación de revisión recuperada y contraste con la composición mock de la revisión local; detalle en [frontend](frontend.md). | Mantener la conclusión asociada a la versión revisada, sin extrapolar a versiones posteriores. |
| IA-DOC-001 | Revisión de modelos físicos atribuida a ChatGPT en documentos existentes. | [Combos, sección 28](../../datos/combos/physical-model.md) y [Bulk, sección 28](../../datos/bulk/physical-model.md), ambos con fecha declarada 2026-10-03. | Recuperar conversaciones y cambios asociados. Estas menciones acreditan una atribución documental de revisión, no generación de todo el backend. |

La herramienta identificada en las conversaciones recuperadas es Codex; los dos modelos físicos citan ChatGPT. El modelo exacto y las demás herramientas históricas quedan por confirmar. No se asignan porcentajes de código generado.

## 4. Cómo conectar documentación y código

Para cada intervención, completar la [plantilla](plantilla-intervencion.md) con esta secuencia:

1. **Necesidad:** tarea o issue, responsable y criterio de aceptación.
2. **Contexto entregado:** documentos y revisiones que efectivamente se proporcionaron a la IA. La matriz permite ubicarlos; su existencia no demuestra que se usaron en una sesión concreta.
3. **Instrucción:** prompt original cuando se conserva. Si solo se recuerda el propósito, registrar un resumen retrospectivo e indicar quién lo confirmó.
4. **Aporte de IA:** distinguir generación de código, modificación, explicación, revisión, pruebas y documentación.
5. **Intervención humana:** criterios dados, decisiones, cambios manuales y aceptación o rechazo de propuestas. Conservar como pendiente lo que no pueda identificarse.
6. **Resultado incorporado:** repositorio, SHA y archivos. Separar propuestas descartadas y cambios aceptados; un commit identifica una versión, pero por sí solo no identifica autoría de IA.
7. **Validación:** comando, entorno, versión probada, resultado y evidencia. Separar resultados históricos consultados de nuevas ejecuciones.

Un prompt reconstruido puede explicar el proceso, pero debe identificarse como reconstrucción. Un prompt nuevo sirve para una intervención nueva y recibe su propia fecha. Las capturas y exportaciones son complementos cuando hacen falta; los enlaces a código y resultados evitan duplicar archivos completos en Markdown. Retirar credenciales y datos privados de cualquier evidencia compartida.

## 5. Fuentes que gobiernan el trabajo

El registro de IA describe el proceso y no modifica reglas funcionales ni contratos. Se conserva la jerarquía de [AGENTS.md](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/AGENTS.md), [registro DEC-F](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/REGISTRO_DEC_F.md), [trazabilidad DEC-F](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/MATRIZ_TRAZABILIDAD_DEC_F.md) y [ADR B1–B4](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/ADR-DEC-F-BLOQUEANTES.md).

Para backend, consultar SPEC/HU/FLOW aplicables, [Arquitectura](../../arquitectura/Arquitectura.md), [Modelo conceptual](../../arquitectura/Modelo_Conceptual.md), [OpenAPI](../../contratos/http/openapi.yaml), [AsyncAPI](../../contratos/eventos/asyncapi.yaml), persistencia y [pruebas de contrato](../../contratos/pruebas/pruebas-contrato.md). Para frontend se añaden [DESIGN.md](../../ux/mockups/DESIGN.md), [UX Guidelines](../../ux/mockups/ux/ux-guidelines.md), [UX Decisions](../../ux/mockups/ux/ux-decisions.md) y los artefactos del MK.

Registrar por separado los estados internos, externos, de implementación y de pruebas. Cuando una intervención implique desarrollo, conservar su clasificación `IMPLEMENTAR_AHORA`, `IMPLEMENTAR_PARCIAL` o `BLOQUEADO_ESPECÍFICO` según la fuente aplicable. La falta de homologación de una frontera no acredita bloqueo de todo el servicio.

## 6. Qué falta para completar el historial

- Recuperar las sesiones de generación del frontend y de los demás servicios; completar un registro por intervención relevante, sin atribuir a cada integrante herramientas no confirmadas.
- Vincular los prompts o resúmenes confirmados con el diff y la revisión humana correspondiente.
- Revisar los registros con el owner de cada artefacto y enlazar evidencia de aceptación cuando exista.
- Ampliar la matriz cuando se identifiquen nuevas versiones y resultados. Su cobertura inicial es un inventario documental, no una auditoría funcional de las 16 capacidades.

Esta entrega modifica únicamente documentación en Docs. Backend y frontend se consultaron para identificar evidencia; no se ejecutaron suites de aplicación, despliegues ni acciones sobre bases de datos durante esta recopilación.

## 7. Comprobaciones de la recopilación inicial

- Revisados los cinco documentos nuevos y el cambio de navegación en el README general.
- Verificadas 155 referencias locales o a archivos/carpetas de commits de backend y frontend mediante los objetos Git disponibles; sin referencias faltantes. Esto no comprueba disponibilidad remota ni permisos de acceso de un evaluador.
- `git diff --check` y comprobación equivalente de los documentos nuevos: sin errores de espacios en blanco.
- Alcance comprobado: únicamente el README general y `docs/uso-ia/*.md`; contratos ejecutables, migraciones, código y pruebas existentes sin cambios por esta entrega.

Estos controles validan la documentación recopilada. Los resultados de aplicación citados en backend/frontend conservan su carácter de evidencia histórica consultada.
