# Encargo para agente — frontend #11

**Tipo:** instrucciones retrospectivas derivadas de un issue real; no prompt histórico original ni prueba de ejecución.

## 1. Identificación y fuente

| Campo | Valor |
|---|---|
| Issue | [[FRONTEND][MK-009] Implementar Características y valores permitidos en React](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/11) |
| Proyecto destino | G6-Productos-Ofertas-frontend |
| Asignados de GitHub al consultar | @VicuzS |
| Estado GitHub al consultar | open |
| Última actualización del issue | 2026-10-17T08:08:16Z |
| Consulta/preparación del encargo | 2026-10-17, America/Lima; corte documental del 17 de octubre |
| Carpeta/rama convencional de referencia | `lopez` — Leonardo Lopez |
| Modo de uso | Encargo documental preparado; ejecución pendiente de una sesión autorizada y de comprobar gates/fuentes vigentes. |
| Fuente conservada | [Contenido consultado del issue](../../fuentes/frontend.md#issue-11) |

Aplicar el modo de datos y criterios vigentes del issue. La asignación identifica al implementador del encargo y no modifica por sí sola el ownership de negocio de Docs.

## 2. Instrucción al agente

Actúa sobre el issue enlazado, siguiendo las [instrucciones comunes](../../INSTRUCCIONES_COMUNES.md). Antes de ejecutar cambios, contrasta el issue vigente y AGENTS.md del destino. El alcance consultado establece:

> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-009 características y valores permitidos Mantener configuración/providers compartidos fuera de esta feature.

1. Inventariar las pantallas y estados de MK-009 contra los documentos enlazados; identificar componentes reutilizables.
2. Contrastar HTML con DESIGN/UX y reglas funcionales; registrar diferencias sin copiar defectos ni convertir el HTML en un componente monolítico.
3. Separar página, presentación, hooks, puertos/servicios, adapters y fixtures dentro de taxonomy.
4. Preparar o revisar adapters mock tipados y escenarios deterministas del alcance. Una interacción simulada no prueba escritura o integración HTTP real.
5. Cubrir navegación, validación por campo, carga, vacío, error y resultado incierto cuando correspondan; conservar borradores y proteger doble envío según las fuentes.
6. Implementar únicamente cuando la asignación, fuentes y alcance estén resueltos; registrar límites contractuales por operación.

## 3. Fuentes que debes leer

- [AGENTS.md del destino consultado](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/97bdd1631238943d783e6effabb0cad9efc9ff1b/AGENTS.md) y [README.md](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/blob/97bdd1631238943d783e6effabb0cad9efc9ff1b/README.md); contrastar con la revisión real al ejecutar.
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
- [Pipeline de mockups](../../../../ux/mockups/README.md).
- [Design System](../../../../ux/mockups/DESIGN.md).
- [Propuesta UX](../../../../ux/mockups/ux/propuesta-ux.md).
- [UX Decisions](../../../../ux/mockups/ux/ux-decisions.md).
- [UX Guidelines](../../../../ux/mockups/ux/ux-guidelines.md).
- Funcionalidad 009: [SPEC](../../../../requisitos/specs/SPEC-009-gestion-caracteristicas.md), [HU](../../../../requisitos/hu/HU-009-gestion-caracteristicas.md), [FLOW](../../../../requisitos/flujos/FLOW-009-gestion-caracteristicas.md) y [WF](../../../../ux/wireframes/flows/WF-009-gestion-caracteristicas.md).
- MK-009: [Component Spec](../../../../ux/mockups/MK-009/component-spec.md), [Plan](../../../../ux/mockups/MK-009/plan.md), [Tasks](../../../../ux/mockups/MK-009/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.

Los enlaces relativos parten de este documento en Docs. En una sesión de otro repositorio, localizar el checkout de Docs y registrar su SHA; no asumir que una carpeta hermana se llama literalmente `docs`. Base documental de este catálogo: `ba0e47cf553b306544c8fc1d3207f5bc51dd6c6a`.

## 4. Archivos y límites

- Feature `src/features/taxonomy/` y sus pruebas existentes, con archivos concretos identificados antes de editar.
- Rutas, navegación y composición global solo con coordinación y alcance explícito; conservar las features y componentes de otros owners.
- Docs y Backend se consultan para lectura; este encargo frontend no modifica esos repositorios.

No ejecutar commit, push, PR, merge, mensajes externos o despliegue como consecuencia de abrir esta ficha.

## 5. Criterios de aceptación de la fuente

> Flujos y validaciones mock funcionales; no exigir CRUD Taxonomy API. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.

Aplicar también los criterios detallados del [issue conservado](../../fuentes/frontend.md#issue-11); el extracto no reemplaza la fuente completa.

## 6. Prerrequisitos y dependencias

**Para programar, según el issue:**

> - Ninguno para esta fase.

**Para pruebas integradas, según el issue:**

> - Ninguno para esta fase.

**Para despliegue, según el issue:**

> - Incluir en la liberación híbrida coordinada por Frontend #33, que consume esta feature; este release no es prerrequisito para programarla ni probarla.
> - El issue por sí solo no acredita homologación, implementación, pruebas ejecutadas ni despliegue.

Revalidar dependencias al ejecutar; un texto «ninguno para esta fase» no concede permisos ni acredita disponibilidad de servicios externos.

## 7. Validación y salida esperadas

- Typecheck, build y lint mediante los scripts del package.json de la revisión real.
- Suite enfocada y regresión pertinente: verificar si npm test y test:e2e separan Vitest/Playwright; no asumir el runner por un reporte histórico.
- Recorrido funcional y capturas de las vistas/estados requeridos a 1440 px, teclado, foco y ausencia de recortes.
- En modo API, errores del provider visibles y sin fallback silencioso; en modo mock, identificar la simulación. Aprobación UX independiente.

Entregar una relación criterio → archivo/diff → prueba → resultado, los ajustes humanos identificados y los pendientes con owner/operación/condición de desbloqueo. Respetar el formato final del AGENTS.md destino.

**Estado de ejecución de esta ficha:** NO EJECUTADA en esta recopilación. Sesión de implementación, cambios, pruebas y revisión humana se incorporan cuando existan mediante la [plantilla de intervención](../../../uso-ia/plantilla-intervencion.md).

[Volver al índice](../../README.md).
