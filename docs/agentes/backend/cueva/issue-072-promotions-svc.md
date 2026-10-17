# Encargo para agente — backend #72

**Tipo:** instrucciones retrospectivas derivadas de un issue real; no prompt histórico original ni prueba de ejecución.

## 1. Identificación y fuente

| Campo | Valor |
|---|---|
| Issue | [[POSTDEMO] [BACK][promotions-svc][03] Implementar reglas de negocio](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/issues/72) |
| Proyecto destino | G6-Productos-Ofertas-backend |
| Asignados de GitHub al consultar | Sin asignado activo en la consulta |
| Estado GitHub al consultar | open |
| Última actualización del issue | 2026-10-17T08:01:48Z |
| Consulta/preparación del encargo | 2026-10-17, America/Lima; corte documental del 17 de octubre |
| Carpeta/rama convencional de referencia | `cueva` — Axel Andree Cueva Alcalá |
| Modo de uso | Ejemplo POSTDEMO: preparar análisis del alcance; implementación pendiente de repriorización y asignación. |
| Fuente conservada | [Contenido consultado del issue](../../fuentes/backend.md#issue-72) |

El issue consultado declara POSTDEMO y no tiene asignado activo. Esta subcarpeta refleja el ownership funcional del servicio en Docs; no se presenta como una asignación vigente de GitHub.

## 2. Instrucción al agente

Actúa sobre el issue enlazado, siguiendo las [instrucciones comunes](../../INSTRUCCIONES_COMUNES.md). Antes de ejecutar cambios, contrasta el issue vigente y AGENTS.md del destino. El alcance consultado establece:

> promotions-svc; MK-005/006/007 siguen mock. Este issue cubre únicamente etapa 3: Reglas/invariantes SPEC/HU. Preservar reglas de negocio/spec del bounded context y su prioridad posterior; no declararlo completado ni desplegarlo para esta demo.

1. Inspeccionar código y pruebas de promotions-svc; identificar qué parte del issue ya existe antes de proponer cambios.
2. Construir una matriz regla → fuente normativa → implementación existente → caso positivo/negativo/límite.
3. Diseñar cambios internos del dominio y pruebas dentro del servicio; aplicar solo reglas respaldadas por las fuentes leídas, sin inventar DTOs, estados ni eventos.
4. Conservar la propuesta como trabajo futuro POSTDEMO; no iniciar implementación ni despliegue por la existencia de esta ficha.
5. Registrar por separado pruebas locales, integración autenticada, homologación externa y despliegue.

## 3. Fuentes que debes leer

- [AGENTS.md del destino consultado](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/2970df90babf2c8caa1849b179b02918fc74a005/AGENTS.md) y [README.md](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/2970df90babf2c8caa1849b179b02918fc74a005/README.md); contrastar con la revisión real al ejecutar.
- [AGENTS.md](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/AGENTS.md).
- [README.md](../../../../README.md).
- [Registro DEC-F](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/REGISTRO_DEC_F.md).
- [Matriz DEC-F](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/MATRIZ_TRAZABILIDAD_DEC_F.md).
- [ADR B1–B4](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/blob/c36bd9a18f4fdb188df0d7e5158a431cf4b4ea7b/arquitectura/decisiones/ADR-DEC-F-BLOQUEANTES.md).
- [OpenAPI](../../../../contratos/http/openapi.yaml).
- [AsyncAPI, si intervienen mensajes](../../../../contratos/eventos/asyncapi.yaml).
- [Contrato de integración](../../../../contratos/http/Contrato_Api.md).
- [Kit de integración](../../../../contratos/http/kit-integracion.md).
- [Arquitectura](../../../../arquitectura/Arquitectura.md).
- [Modelo conceptual](../../../../arquitectura/Modelo_Conceptual.md).
- [Matriz de pruebas](../../../../contratos/pruebas/pruebas-contrato.md).
- [Modelo lógico](../../../../datos/promotions/logical-model.md) y [modelo físico](../../../../datos/promotions/physical-model.md).
- Funcionalidad 005: [SPEC](../../../../requisitos/specs/SPEC-005-gestion-cupones-descuento.md), [HU](../../../../requisitos/hu/HU-005-gestion-cupones-descuento.md), [FLOW](../../../../requisitos/flujos/FLOW-005-gestion-cupones-descuento.md) y [WF](../../../../ux/wireframes/flows/WF-005-gestion-cupones-descuento.md).
- Funcionalidad 006: [SPEC](../../../../requisitos/specs/SPEC-006-gestion-ofertas-promociones.md), [HU](../../../../requisitos/hu/HU-006-gestion-ofertas-promociones.md), [FLOW](../../../../requisitos/flujos/FLOW-006-gestion-ofertas-promociones.md) y [WF](../../../../ux/wireframes/flows/WF-006-gestion-ofertas-promociones.md).
- Funcionalidad 007: [SPEC](../../../../requisitos/specs/SPEC-007-reglas-venta-cruzada-upselling.md), [HU](../../../../requisitos/hu/HU-007-reglas-venta-cruzada-upselling.md), [FLOW](../../../../requisitos/flujos/FLOW-007-reglas-venta-cruzada-upselling.md) y [WF](../../../../ux/wireframes/flows/WF-007-reglas-venta-cruzada-upselling.md).

Los enlaces relativos parten de este documento en Docs. En una sesión de otro repositorio, localizar el checkout de Docs y registrar su SHA; no asumir que una carpeta hermana se llama literalmente `docs`. Base documental de este catálogo: `ba0e47cf553b306544c8fc1d3207f5bc51dd6c6a`.

## 4. Archivos y límites

- Servicio `apps/promotions-svc/` y sus pruebas aplicables, previa comprobación de archivos existentes.
- No cambiar otras apps, contratos compartidos, dependencias ni configuración global para resolver esta tarea sin alcance expreso.

No ejecutar commit, push, PR, merge, mensajes externos o despliegue como consecuencia de abrir esta ficha.

## 5. Criterios de aceptación de la fuente

> Trabajo futuro testeado por commit, sin cambiar contratos compartidos incompatibles ni atribuir runtime. POSTDEMO hasta repriorización.

Aplicar también los criterios detallados del [issue conservado](../../fuentes/backend.md#issue-72); el extracto no reemplaza la fuente completa.

## 6. Prerrequisitos y dependencias

**Para programar, según el issue:**

> - Ninguno para esta fase.

**Para pruebas integradas, según el issue:**

> - Ninguno para esta fase.

**Para despliegue, según el issue:**

> - Ninguno para esta fase.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

Revalidar dependencias al ejecutar; un texto «ninguno para esta fase» no concede permisos ni acredita disponibilidad de servicios externos.

## 7. Validación y salida esperadas

- Pruebas de dominio positivas, negativas y de límite según invariantes del issue; concurrencia/idempotencia donde la regla lo requiera.
- Pruebas enfocadas del servicio, typecheck, lint, build y demás checks exigidos por AGENTS.md, usando scripts existentes.
- Resultados asociados al SHA/árbol y entorno; E2E real solo con dependencias y autorización disponibles.

Entregar una relación criterio → archivo/diff → prueba → resultado, los ajustes humanos identificados y los pendientes con owner/operación/condición de desbloqueo. Respetar el formato final del AGENTS.md destino.

**Estado de ejecución de esta ficha:** NO EJECUTADA en esta recopilación. Sesión de implementación, cambios, pruebas y revisión humana se incorporan cuando existan mediante la [plantilla de intervención](../../../uso-ia/plantilla-intervencion.md).

[Volver al índice](../../README.md).
