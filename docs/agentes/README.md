# Encargos Markdown para agentes de IA

**Preparados:** 2026-10-17, America/Lima. **Cobertura:** 31 ejemplos basados en issues reales de los tres repositorios.

Esta carpeta convierte issues del equipo en instrucciones que pueden entregarse a un agente: objetivo, contexto, fuentes, límites de archivos, criterios de aceptación y validaciones. Incluye seis casos de Docs, nueve de backend —ocho servicios y Gateway— y los dieciséis MK de frontend.

Son documentos retrospectivos preparados en esta fecha. Demuestran la preparación y trazabilidad de los encargos; para demostrar su ejecución con IA, vincular además conversación, diff, revisión humana y pruebas. La evidencia recuperada previamente está en [Uso de IA](../uso-ia/README.md).

## Cómo usar un encargo

1. Elegir proyecto y responsable en las tablas siguientes.
2. Entregar al agente la ficha junto con [INSTRUCCIONES_COMUNES.md](INSTRUCCIONES_COMUNES.md), AGENTS.md del destino y las fuentes indicadas.
3. Contrastar asignación, estado y restricciones vigentes antes de ejecutar. Los casos cerrados son ejemplos de revisión; los POSTDEMO siguen como trabajo futuro.
4. Registrar el resultado de una sesión real con la [plantilla de intervención](../uso-ia/plantilla-intervencion.md).

Las subcarpetas castilla/poma/cueva/lopez/vera/taco organizan responsables o ownership funcional, según lo indicado en cada ficha. No representan ramas creadas ni nuevas asignaciones. Consultar [ASIGNACIONES_Y_LIMITES.md](ASIGNACIONES_Y_LIMITES.md) para las diferencias encontradas.

## Documentación — seis integrantes

| Encargo | Responsable / carpeta | Issue fuente | Estado consultado |
|---|---|---|---|
| [docs #62 — MK 001/002](docs/castilla/issue-062-mockups.md) | Marco Castilla / `castilla` | [Issue #62](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/62) | open |
| [docs #63 — MK 003/004](docs/poma/issue-063-mockups.md) | Gabriel Poma / `poma` | [Issue #63](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/63) | open |
| [docs #64 — MK 005/006/007](docs/cueva/issue-064-mockups.md) | Axel Cueva / `cueva` | [Issue #64](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/64) | open |
| [docs #65 — MK 008/009/010/011/012](docs/lopez/issue-065-mockups.md) | Leonardo Lopez / `lopez` | [Issue #65](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/65) | open |
| [docs #66 — MK 013/014](docs/vera/issue-066-mockups.md) | Leonardo Vera / `vera` | [Issue #66](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/66) | open |
| [docs #67 — MK 015/016](docs/taco/issue-067-mockups.md) | Miguel Taco / `taco` | [Issue #67](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/issues/67) | open |

## Backend — ocho bounded contexts y Gateway

| Encargo | Referencia de carpeta | Asignados actuales | Estado consultado |
|---|---|---|---|
| [backend #36 — taxonomy-svc](backend/lopez/issue-036-taxonomy-svc.md) | Leonardo Lopez / `lopez` | @VicuzS | open |
| [backend #45 — catalog-svc](backend/poma/issue-045-catalog-svc.md) | Gabriel Poma / `poma` | @GabrielPGu | open |
| [backend #54 — pricing-svc](backend/vera/issue-054-pricing-svc.md) | Leonardo Vera / `vera` | @LeonardoVera | closed |
| [backend #63 — price-audit-svc](backend/vera/issue-063-price-audit-svc.md) | Leonardo Vera / `vera` | Sin asignado activo; ver ficha | open / POSTDEMO |
| [backend #72 — promotions-svc](backend/cueva/issue-072-promotions-svc.md) | Axel Cueva / `cueva` | Sin asignado activo; ver ficha | open / POSTDEMO |
| [backend #81 — combos-svc](backend/castilla/issue-081-combos-svc.md) | Marco Castilla / `castilla` | Sin asignado activo; ver ficha | open / POSTDEMO |
| [backend #90 — bulk-svc](backend/castilla/issue-090-bulk-svc.md) | Marco Castilla / `castilla` | Sin asignado activo; ver ficha | open / POSTDEMO |
| [backend #99 — inventory-svc](backend/taco/issue-099-inventory-svc.md) | Miguel Taco / `taco` | @MiguelTacoZavala | open |
| [backend #106 — api-gateway](backend/castilla/issue-106-api-gateway.md) | Marco Castilla / `castilla` | @mrcastilla8 | open |

## Frontend — dieciséis funcionalidades

| Encargo | Carpeta del asignado | Asignados actuales | Estado consultado |
|---|---|---|---|
| [frontend #3 — MK-001](frontend/castilla/issue-003-mk-001.md) | Marco Castilla / `castilla` | @mrcastilla8 | closed |
| [frontend #4 — MK-002](frontend/castilla/issue-004-mk-002.md) | Marco Castilla / `castilla` | @mrcastilla8 | open |
| [frontend #5 — MK-003](frontend/poma/issue-005-mk-003.md) | Gabriel Poma / `poma` | @GabrielPGu | open |
| [frontend #6 — MK-004](frontend/poma/issue-006-mk-004.md) | Gabriel Poma / `poma` | @GabrielPGu | open |
| [frontend #7 — MK-005](frontend/lopez/issue-007-mk-005.md) | Leonardo Lopez / `lopez` | @VicuzS | open |
| [frontend #8 — MK-006](frontend/lopez/issue-008-mk-006.md) | Leonardo Lopez / `lopez` | @VicuzS | open |
| [frontend #9 — MK-007](frontend/lopez/issue-009-mk-007.md) | Leonardo Lopez / `lopez` | @VicuzS | open |
| [frontend #10 — MK-008](frontend/lopez/issue-010-mk-008.md) | Leonardo Lopez / `lopez` | @VicuzS | closed |
| [frontend #11 — MK-009](frontend/lopez/issue-011-mk-009.md) | Leonardo Lopez / `lopez` | @VicuzS | open |
| [frontend #12 — MK-010](frontend/lopez/issue-012-mk-010.md) | Leonardo Lopez / `lopez` | @VicuzS | open |
| [frontend #13 — MK-011](frontend/lopez/issue-013-mk-011.md) | Leonardo Lopez / `lopez` | @VicuzS | open |
| [frontend #14 — MK-012](frontend/lopez/issue-014-mk-012.md) | Leonardo Lopez / `lopez` | @VicuzS | open |
| [frontend #15 — MK-013](frontend/vera/issue-015-mk-013.md) | Leonardo Vera / `vera` | @LeonardoVera | closed |
| [frontend #16 — MK-014](frontend/vera/issue-016-mk-014.md) | Leonardo Vera / `vera` | @LeonardoVera | closed |
| [frontend #17 — MK-015](frontend/taco/issue-017-mk-015.md) | Miguel Taco / `taco` | @MiguelTacoZavala | open |
| [frontend #18 — MK-016](frontend/taco/issue-018-mk-016.md) | Miguel Taco / `taco` | @MiguelTacoZavala | open |

En frontend no se crea una asignación ficticia a Cueva: los issues #7–#9 están asignados a López en la consulta. La [nota de Cueva](frontend/cueva/README.md) enlaza su contexto histórico y los encargos actuales.

## Fuentes conservadas y revisiones

- [Issues de Docs](fuentes/docs.md): #62–#67.
- [Issues de backend](fuentes/backend.md): #36, #45, #54, #63, #72, #81, #90, #99 y #106.
- [Issues de frontend](fuentes/frontend.md): #3–#18.
- Docs local: `ba0e47cf553b306544c8fc1d3207f5bc51dd6c6a`; contratos leídos: OpenAPI `0.6.0-rc.1` y AsyncAPI `0.6.0-rc.2`.
- Backend local consultado: `2970df90babf2c8caa1849b179b02918fc74a005`; frontend local consultado: `97bdd1631238943d783e6effabb0cad9efc9ff1b`. Son referencias de lectura, no afirmación de último estado remoto o despliegue.

Se seleccionaron ejemplos representativos; este índice no pretende listar todo el backlog ni certificar cierre de issues. La fuente GitHub de Docs es `Taller-SW-Web/G6-Productos-Ofertas-docs`; el checkout local se llama `Productos-y-Ofertas-docs` y su remoto configurado conserva el nombre anterior. Los enlaces a issues usan el repositorio accesible comprobado.

## Alcance de esta preparación

Solo se crean o enlazan archivos Markdown en Docs. No se ejecutan las tareas de las fichas, no se modifican asignados/estados en GitHub y no se publica código ni documentación. Las copias de issues conservan su lenguaje de ejecución como fuente citada; no conceden una autorización nueva.

Las comprobaciones y sus límites están en [VALIDACION.md](VALIDACION.md).
