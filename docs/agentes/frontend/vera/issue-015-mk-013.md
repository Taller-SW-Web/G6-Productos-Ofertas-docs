# Encargo para agente — frontend #15

**Tipo:** instrucciones retrospectivas derivadas de un issue real; no prompt histórico original ni prueba de ejecución.

## 1. Identificación y fuente

| Campo | Valor |
|---|---|
| Issue | [[FRONTEND][MK-013] Implementar Gestión de precios individuales y masivos en React](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/15) |
| Proyecto destino | G6-Productos-Ofertas-frontend |
| Asignados de GitHub al consultar | @LeonardoVera |
| Estado GitHub al consultar | closed |
| Última actualización del issue | 2026-10-17T06:32:02Z |
| Consulta/preparación del encargo | 2026-10-17, America/Lima; corte documental del 17 de octubre |
| Carpeta/rama convencional de referencia | `vera` — Leonardo Vera Rodríguez |
| Modo de uso | Ejemplo cerrado: revisar evidencia existente; no reabrir ni repetir implementación por este documento. |
| Fuente conservada | [Contenido consultado del issue](../../fuentes/frontend.md#issue-15) |

El issue consultado está cerrado; este es un ejemplo para revisión de su entrega y evidencia. Su texto conserva referencias históricas a ramas de feature: la carpeta indica la rama convencional del responsable, no una orden de crear/cambiar de rama.

## 2. Instrucción al agente

Actúa sobre el issue enlazado, siguiendo las [instrucciones comunes](../../INSTRUCCIONES_COMUNES.md). Antes de ejecutar cambios, contrasta el issue vigente y AGENTS.md del destino. El alcance consultado establece:

> Convertir el alcance funcional de **MK-013 — Gestión de precios individuales y masivos** en vistas y flujos de React realmente navegables sobre la foundation común de Vera, sin copiar los HTML como componentes monolíticos ni adelantar un backend inexistente. La entrega debe poder demostrarse localmente con estados deterministas, decisiones visuales fieles a Docs y una PR acotada que permita auditar pantalla por pantalla.
>
> **Secuencia sugerida:** Conservar S01 implementado; convertir muestras S02-S05 a pantallas reales con mocks; añadir S06.
>
> > **Preexistencia verificada:** el piloto **MK-013-S01** ya está implementado en `src/features/pricing/pages/CurrentPricePage.tsx`, publicado en `/precios`, sobre adapters mock. La galería `/foundation/pricing` contiene muestras de componentes S02–S05, **no** flujos funcionales completos. La tarea es extender e integrar, no rehacer la foundation.

1. Inventariar las pantallas y estados de MK-013 contra los documentos enlazados; identificar componentes reutilizables.
2. Contrastar HTML con DESIGN/UX y reglas funcionales; registrar diferencias sin copiar defectos ni convertir el HTML en un componente monolítico.
3. Separar página, presentación, hooks, puertos/servicios, adapters y fixtures dentro de pricing.
4. Preparar o revisar adapters mock tipados y escenarios deterministas del alcance. Una interacción simulada no prueba escritura o integración HTTP real.
5. Cubrir navegación, validación por campo, carga, vacío, error y resultado incierto cuando correspondan; conservar borradores y proteger doble envío según las fuentes.
6. Comparar con el código y evidencia de cierre disponibles; proponer correcciones solo mediante un nuevo alcance autorizado.

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
- Funcionalidad 013: [SPEC](../../../../requisitos/specs/SPEC-013-gestion-precios-individuales-masivos.md), [HU](../../../../requisitos/hu/HU-013-gestion-precios-individuales-masivos.md), [FLOW](../../../../requisitos/flujos/FLOW-013-gestion-precios-individuales-masivos.md) y [WF](../../../../ux/wireframes/flows/WF-013-gestion-precios-individuales-masivos.md).
- MK-013: [Component Spec](../../../../ux/mockups/MK-013/component-spec.md), [Plan](../../../../ux/mockups/MK-013/plan.md), [Tasks](../../../../ux/mockups/MK-013/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.

Los enlaces relativos parten de este documento en Docs. En una sesión de otro repositorio, localizar el checkout de Docs y registrar su SHA; no asumir que una carpeta hermana se llama literalmente `docs`. Base documental de este catálogo: `ba0e47cf553b306544c8fc1d3207f5bc51dd6c6a`.

## 4. Archivos y límites

- Feature `src/features/pricing/` y sus pruebas existentes, con archivos concretos identificados antes de editar.
- Rutas, navegación y composición global solo con coordinación y alcance explícito; conservar las features y componentes de otros owners.
- Docs y Backend se consultan para lectura; este encargo frontend no modifica esos repositorios.

No ejecutar commit, push, PR, merge, mensajes externos o despliegue como consecuencia de abrir esta ficha.

## 5. Criterios de aceptación de la fuente

> - [ ] Cobertura completa de las pantallas P0 enumeradas arriba (P1 separado cuando esté indicado), con contexto, validaciones, estados y navegación verificables.
> - [ ] Mocks/adapters tipados sustituibles por HTTP sin reescribir JSX; código de negocio no trasladado a la UI.
> - [ ] Estilo unificado con la Foundation; sin duplicar theme, AppShell o patrones compartidos existentes.
> - [ ] Evidencias y checks reales incorporados a PR; ninguna declaración engañosa de PASS, despliegue o integración.
> - [ ] Revisión funcional y UX/técnica correspondiente, con hallazgos importantes cerrados o documentados como limitación acordada.
> - [ ] Se entrega una demo navegable por navegador local sin backend y se informa exactamente qué está simulado.
>
> **No cerrar este issue por publicar un prototipo parcial:** las pantallas sin implementar, validaciones pendientes y bloqueos permanecen explícitos hasta su resolución o replanteamiento aprobado.

Aplicar también los criterios detallados del [issue conservado](../../fuentes/frontend.md#issue-15); el extracto no reemplaza la fuente completa.

## 6. Prerrequisitos y dependencias

Revalidar dependencias al ejecutar; un texto «ninguno para esta fase» no concede permisos ni acredita disponibilidad de servicios externos.

## 7. Validación y salida esperadas

- Typecheck, build y lint mediante los scripts del package.json de la revisión real.
- Suite enfocada y regresión pertinente: verificar si npm test y test:e2e separan Vitest/Playwright; no asumir el runner por un reporte histórico.
- Recorrido funcional y capturas de las vistas/estados requeridos a 1440 px, teclado, foco y ausencia de recortes.
- En modo API, errores del provider visibles y sin fallback silencioso; en modo mock, identificar la simulación. Aprobación UX independiente.

Entregar una relación criterio → archivo/diff → prueba → resultado, los ajustes humanos identificados y los pendientes con owner/operación/condición de desbloqueo. Respetar el formato final del AGENTS.md destino.

**Estado de ejecución de esta ficha:** NO EJECUTADA en esta recopilación. Sesión de implementación, cambios, pruebas y revisión humana se incorporan cuando existan mediante la [plantilla de intervención](../../../uso-ia/plantilla-intervencion.md).

[Volver al índice](../../README.md).
