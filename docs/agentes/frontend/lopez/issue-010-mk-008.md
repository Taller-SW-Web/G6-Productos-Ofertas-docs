# Encargo para agente — frontend #10

**Tipo:** instrucciones retrospectivas derivadas de un issue real; no prompt histórico original ni prueba de ejecución.

## 1. Identificación y fuente

| Campo | Valor |
|---|---|
| Issue | [[FRONTEND][MK-008] Implementar Categorías y subcategorías en React](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/issues/10) |
| Proyecto destino | G6-Productos-Ofertas-frontend |
| Asignados de GitHub al consultar | @VicuzS |
| Estado GitHub al consultar | closed |
| Última actualización del issue | 2026-10-17T08:35:16Z |
| Consulta/preparación del encargo | 2026-10-17, America/Lima; corte documental del 17 de octubre |
| Carpeta/rama convencional de referencia | `lopez` — Leonardo Lopez |
| Modo de uso | Ejemplo cerrado: revisar evidencia existente; no reabrir ni repetir implementación por este documento. |
| Fuente conservada | [Contenido consultado del issue](../../fuentes/frontend.md#issue-10) |

El issue consultado está cerrado; este es un ejemplo para revisión de su entrega y evidencia. Su texto conserva referencias históricas a ramas de feature: la carpeta indica la rama convencional del responsable, no una orden de crear/cambiar de rama.

## 2. Instrucción al agente

Actúa sobre el issue enlazado, siguiendo las [instrucciones comunes](../../INSTRUCCIONES_COMUNES.md). Antes de ejecutar cambios, contrasta el issue vigente y AGENTS.md del destino. El alcance consultado establece:

> Implementar la pantalla funcional y sus estados loading/empty/error, validación, navegación y adapter según SPEC/HU/FLOW. MK-008 categorías/subcategorías jerárquicas Mantener configuración/providers compartidos fuera de esta feature.

1. Inventariar las pantallas y estados de MK-008 contra los documentos enlazados; identificar componentes reutilizables.
2. Contrastar HTML con DESIGN/UX y reglas funcionales; registrar diferencias sin copiar defectos ni convertir el HTML en un componente monolítico.
3. Separar página, presentación, hooks, puertos/servicios, adapters y fixtures dentro de taxonomy.
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
- Funcionalidad 008: [SPEC](../../../../requisitos/specs/SPEC-008-gestion-categorias.md), [HU](../../../../requisitos/hu/HU-008-gestion-categorias.md), [FLOW](../../../../requisitos/flujos/FLOW-008-gestion-categorias.md) y [WF](../../../../ux/wireframes/flows/WF-008-gestion-categorias.md).
- MK-008: [Component Spec](../../../../ux/mockups/MK-008/component-spec.md), [Plan](../../../../ux/mockups/MK-008/plan.md), [Tasks](../../../../ux/mockups/MK-008/tasks.md); localizar el prototipo y el reporte existente sin asumir aprobación.

Los enlaces relativos parten de este documento en Docs. En una sesión de otro repositorio, localizar el checkout de Docs y registrar su SHA; no asumir que una carpeta hermana se llama literalmente `docs`. Base documental de este catálogo: `ba0e47cf553b306544c8fc1d3207f5bc51dd6c6a`.

## 4. Archivos y límites

- Feature `src/features/taxonomy/` y sus pruebas existentes, con archivos concretos identificados antes de editar.
- Rutas, navegación y composición global solo con coordinación y alcance explícito; conservar las features y componentes de otros owners.
- Docs y Backend se consultan para lectura; este encargo frontend no modifica esos repositorios.

No ejecutar commit, push, PR, merge, mensajes externos o despliegue como consecuencia de abrir esta ficha.

## 5. Criterios de aceptación de la fuente

> Flujos y validaciones mock funcionales; no exigir CRUD Taxonomy API. Build/CI y pruebas de alcance con evidencia por commit. mock continúa explícito, api falla cerrado, hybrid elige provider por feature. Sin secretos/token técnico/Supabase/RabbitMQ en React.

Aplicar también los criterios detallados del [issue conservado](../../fuentes/frontend.md#issue-10); el extracto no reemplaza la fuente completa.

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
