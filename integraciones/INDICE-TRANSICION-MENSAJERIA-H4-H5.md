# Índice de transición de mensajería H4→H5

**Estado contractual actual:** OpenAPI/AsyncAPI canónicos `0.7.0-rc.1`, `SEMIFINAL_G6`; la propuesta G5 se asume solo para planificación (`ACEPTACION_G5_ASUMIDA_PARA_PLANIFICACION`), con homologación bilateral y grants G7 efectivos pendientes. H4 se verifica desde `contratos/historico/h4/` y sus hashes SHA-256. El inventario de 40 mensajes es trazabilidad H4, no conteo de H5.

**Estado:** inventario documental realizado sobre `origin/master` `f77c442`; PR #119 fusionado (`a53ed842`). La búsqueda cubre menciones textuales, variables y herramientas, colas/exchanges, túneles y fixtures en Markdown, YAML, JSON, scripts y documentación UX. AsyncAPI H4 y fixtures se preservan íntegros. Snapshots byte por byte: `contratos/historico/h4/http/openapi.yaml`, `contratos/historico/h4/eventos/asyncapi.yaml`; hashes en `contratos/historico/h4/SHA256SUMS`.

## Decisión y estados

- H5 adoptado por G6: Azure Service Bus Basic exclusivamente interno G6.
- Integraciones externas: HTTP autenticado mediante APIM/Gateway; homologación G5 y autorización G7 pendientes donde correspondan.
- Estados independientes: `PENDIENTE_APROVISIONAMIENTO_AZURE`, `PENDIENTE_IMPLEMENTACION`, `PENDIENTE_HOMOLOGACION_G5`, `PENDIENTE_AUTORIZACION_G7`. Un colaborador asumió configurar recursos Azure; esa asignación no demuestra provisión.
- RabbitMQ: legado H4 y compatibilidad transitoria del runtime existente; no crear infraestructura RabbitMQ para H5.

## Inventario exhaustivo de archivos con referencias

El rastreo encontró 76 archivos. Lista de rutas clasificada por contexto:

### Histórico H4 / procedimientos exclusivos (`LEGADO_H4`)

Contratos ejecutables, topologías, pruebas, configuración y guías operativas H4. Preservar por trazabilidad; no ejecutar como procedimiento H5.

- `arquitectura/decisiones/rabbitmq.md`
- `arquitectura/operacion-rabbitmq.md`
- `contratos/historico/h4/eventos/asyncapi.yaml`
- `contratos/eventos/compatibilidad-rabbitmq-oracle.md`
- `contratos/eventos/rabbitmq-topologia.md`
- `ops/rabbitmq/README-onboarding-rabbitmq.md`
- `tests/rabbitmq-aislamiento/README.md`
- `tests/rabbitmq-aislamiento/compose.recovery-reduced.yaml`
- `tests/rabbitmq-aislamiento/compose.yaml`
- `tests/rabbitmq-aislamiento/definitions.json`
- `tests/rabbitmq-aislamiento/run.ps1`
- `tests/rabbitmq-aislamiento/test_isolation.py`

### Compatibilidad transitoria, migración o estado H5

Referencias de transición/estado que explican el runtime H4. No autorizan acceso externo al broker ni implementación RabbitMQ H5.

- `arquitectura/Arquitectura.md`
- `arquitectura/decisiones/ACUERDOS-INTEGRACION-INTERNA-G6-H4.md`
- `arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md`
- `arquitectura/decisiones/POLITICA-SEGURIDAD-PROGRESIVA-G6.md`
- `arquitectura/decisiones/REGISTRO_DEC_F.md`
- `arquitectura/operacion-service-bus-basic-h5.md`
- `contratos/eventos/INVENTARIO-40-MENSAJES-H5.md`
- `contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md`
- `contratos/eventos/catalogo-eventos.md`
- `contratos/http/Contrato_Api.md`
- `contratos/http/PROPUESTA-OPERACIONES-CUPONES-H5.md`
- `contratos/http/kit-integracion.md`
- `contratos/http/openapi.yaml`
- `contratos/pruebas/pruebas-contrato.md`
- `integraciones/ACUERDO_G1_G6_H4_2026-10-20.md`
- `integraciones/ACUERDO_G5_G6_H4_2026-10-21.md`
- `integraciones/ALINEACION_VENTAS.md`
- `integraciones/AUDITORIA_FINAL_OPTIMIZACIONES_G6_2026-11-14.md`
- `integraciones/CATALOGO-H4-H5-AUDITORIA.md`
- `integraciones/CATALOGO-H5-CANDIDATO.md`
- `integraciones/INDICE-TRANSICION-MENSAJERIA-H4-H5.md`
- `integraciones/MATRIZ-EXTERNOS-ASYNCAPI-H5.md`
- `integraciones/REFERENCIA-G5-G6-H5-REVISION-01.md`
- `integraciones/MATRIZ_INTERMODULAR_BACKEND.md`
- `integraciones/PLAN-MIGRACION-MENSAJERIA-H5.md`
- `integraciones/transicion-rabbitmq.md`

### Referencias funcionales/UX/datos que deben independizarse del transporte

Conservar semántica/event names; las decisiones de transporte se remiten a fuentes H5. UX no debe exponer nombres de broker como interacción funcional.

- `datos/bulk/logical-model.md`
- `datos/bulk/physical-model.md`
- `datos/promotions/README.md`
- `datos/promotions/logical-model.md`
- `datos/promotions/physical-model.md`
- `datos/promotions/validation-report.md`
- `requisitos/flujos/FLOW-003-gestion-productos-crud.md`
- `requisitos/flujos/FLOW-004-gestion-variantes-skus.md`
- `requisitos/flujos/FLOW-016-dashboard-alertas-stock.md`
- `requisitos/hu/HU-003-gestion-productos-crud.md`
- `requisitos/hu/HU-004-gestion-variantes-skus.md`
- `requisitos/specs/SPEC-001-carga-exportacion-masiva-productos.md`
- `requisitos/specs/SPEC-004-gestion-variantes-skus.md`
- `requisitos/specs/SPEC-005-gestion-cupones-descuento.md`
- `ux/mockups/MK-001/component-spec.md`
- `ux/mockups/MK-001/plan.md`
- `ux/mockups/MK-002/component-spec.md`
- `ux/mockups/MK-003/component-spec.md`
- `ux/mockups/MK-003/plan.md`
- `ux/mockups/MK-003/tasks.md`
- `ux/mockups/MK-004/component-spec.md`
- `ux/mockups/MK-004/tasks.md`
- `ux/mockups/MK-016/component-spec.md`
- `ux/wireframes/_TEMPLATE.md`
- `ux/wireframes/flows/WF-001-carga-exportacion-masiva-productos.md`
- `ux/wireframes/flows/WF-003-gestion-productos-crud.md`
- `ux/wireframes/flows/WF-004-gestion-variantes-skus.md`
- `ux/wireframes/flows/WF-016-dashboard-alertas-stock.md`

### Otras coincidencias contextuales

Clasificar individualmente; no borrar evidencia técnica histórica ni coincidencias de pruebas.

- `AGENTS.md`
- `README.md`
- `ops/postgres-runtime/guia-desarrollo-local.md`
- `swagger/evidence/studio-2026-11-05.json`
- `tests/contratos/PLAN-VERIFICACION-SERVICE-BUS-H5.md`
- `tests/contratos/fixtures/asyncapi-0.6.0-rc.2-invariants.json`
- `tests/contratos/fixtures/asyncapi-0.6.0-rc.3-approved-invariants.json`
- `tests/contratos/test_asyncapi_oracle_topology.py`
- `tests/contratos/test_rabbitmq_h5_documentation.py`
- `tests/contratos/test_service_bus_h5_documentation.py`

## Índice de patrones inspeccionados

- Nombres y rutas de archivo; texto `RabbitMQ`/AMQP; variables `RABBITMQ_*`, uso de `amqplib`; exchanges, colas y routing keys físicas; túneles SSH/AMQP; comandos y fixtures Docker/Compose.
- Documentos exclusivamente RabbitMQ y procedimientos de operación/pruebas quedan etiquetados `LEGADO_H4`. AsyncAPI ejecutable H4 y fixtures contractuales permanecen inmutables.

## Contrato H4 que sigue como referencia funcional

- `contratos/historico/h4/eventos/asyncapi.yaml` y fixtures Oracle preservan semántica de eventos, mensajes, payloads, schemas e invariantes contractuales H4. El AsyncAPI canónico `contratos/eventos/asyncapi.yaml` es H5 (`0.7.0-rc.1`, `SEMIFINAL_G6`); el índice de mensajes H5 mapea qué relaciones siguen internas y qué frontera externa requiere HTTP.
- Los `servers`, bindings, `RABBITMQ_*`, `amqplib`, exchanges, routing keys físicas, nombres de colas, túneles y comandos Docker describen H4; no autorizan implementación H5.
- El AsyncAPI canónico H5 `contratos/eventos/asyncapi.yaml` está en estado `SEMIFINAL_G6`, no homologado externamente. Consultar [inventario H5](../contratos/eventos/INVENTARIO-40-MENSAJES-H5.md), [frontera externa](MATRIZ-EXTERNOS-ASYNCAPI-H5.md) y [topología Service Bus](../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md).
- Preservar acuerdos H4, semántica de negocio, ownership externo y fixtures inmutables.

## Excepciones explícitas de la prueba documental

La regresión H5 carga `tests/contratos/rabbitmq-h4-excepciones.txt`. Cada excepción queda limitada a una **línea literal exacta**, con ruta y justificación. No hay exclusiones por archivo ni por rótulos `LEGADO_H4`; la prueba siempre vuelve a examinar la línea y cualquier cambio o instrucción añadida exige revisión. La lista histórica proviene del inventario base de 75 documentos y cada referencia conserva su justificación contextual.


## Baseline semifinal H5

OpenAPI y AsyncAPI canónicos son `0.7.0-rc.1` (`SEMIFINAL_G6`), pendientes de homologación externa según cada interfaz. El snapshot H4 conserva las versiones `0.6.0-rc.5` y `0.6.0-rc.4`, referencias relativas y las pruebas RabbitMQ correspondientes. La suite H5 se ejecuta en `tests/contratos/test_h5_semifinal_contracts.py`; no acredita implementación, grants, performance, CI de despliegue ni habilitación.
