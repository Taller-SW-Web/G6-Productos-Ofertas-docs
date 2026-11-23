# Índice integral del Hito 5

**Corte documental:** 22/11/2026 (America/Lima). **Estado de esta entrega:** plan y asignaciones documentados; la aceptación del Hito 5 no está certificada. Los cuatro criterios parten del estado oficial `EVIDENCIA_PARCIAL` de [`../HITO_5.md`](../HITO_5.md). Este paquete no ejecuta fases técnicas.

## Requisitos confirmados y criterios G6

| ID | Exigencia docente (literal en sustancia) | Criterio interno G6 documentado | Estado de implementación | Estado de evidencia | Homologación externa |
|---|---|---|---|---|---|
| H5-01 | CI/CD incluyendo revisión de seguridad | CodeQL/SAST, Gitleaks, npm SCA, Trivy/SBOM, IaC, DAST seguro, pruebas negativas JWT/ACL, CI y CD por SHA | `PARCIAL_NO_CERTIFICADO`; inventario de workflows y PRs no prueba la cobertura integral | `EVIDENCIA_PARCIAL`; falta scorecard reproducible por SHA | No aplica a controles internos; JWT/G7 requiere grants para prueba real |
| H5-02 | Evidencia de pruebas de integración | Núcleo INT-01/05/07/08/10, más INT condicionales según manifest; niveles L0–L3 | `PARCIAL_NO_CERTIFICADO` | `EVIDENCIA_PARCIAL`; piloto #234 solo cubre R16 en laboratorio | G5/G7 se registran para cada flujo; L3 no es requisito universal |
| H5-03 | Evidencia de pruebas de performance | PERF-01–08, k6 y benchmarks/UI existentes, baseline-candidato pareado | `NO_CERTIFICADO` | `EVIDENCIA_PARCIAL`; reportes integrales comparables pendientes | Ambiente, APIM y presupuesto requieren habilitación operativa |
| H5-04A | Uso de API Management | APIM real, separado de Gateway, rutas servidas, políticas y prueba por hostname | `NO_VERIFICADO` | `EVIDENCIA_PARCIAL` | Inventario, red y presupuesto son puertas |
| H5-04B | Mecanismo asíncrono entre microservicios | Service Bus Basic solo interno G6, Outbox por destinatario, Inbox y deduplicación durable | `PARCIAL_PILOTO`; no global | `EVIDENCIA_PARCIAL` | Grants G7 y homologación G5 solo afectan las fronteras externas pertinentes |

Los criterios de seguridad, IDs de prueba, umbrales de carga, orden de PR y gates de este paquete son **`CRITERIO_INTERNO_G6`**, salvo los cuatro enunciados anteriores, que son **`EXIGENCIA_DOCENTE`**. La diapositiva SAST/DAST contextualiza profundidad; no convierte cada producto o umbral en requisito académico.

## Arquitectura, alcance y fuentes

HTTP autenticado atraviesa APIM y el Gateway G6 hacia el bounded context owner. G7 conserva autoridad de identidad y grants. Azure Service Bus Basic se usa solo entre bounded contexts G6. Entrega `at-least-once`; Basic no ofrece topics/subscriptions, sesiones, duplicate detection ni garantía `exactly-once`. El estado `202` de una admisión durable no significa procesamiento completado.

La versión del corte `origin/master` de Docs `4404b7c7d3cd9254ddc6932532ab3a9ba1a52f78` es OpenAPI y AsyncAPI `0.7.0-rc.3`, con aprobación normativa interna `APPROVED_G6` conforme al [acta](../../arquitectura/decisiones/ACTA-APROBACION-INTERNA-G6-H5-2026-11-22.md). La baseline técnica `SEMIFINAL_G6` y las dependencias externas u operativas no se convierten por ello en homologación, implementación, permisos ni despliegue. La topología y matriz conservan sus gates por flujo; PR #133 está fusionado en este corte y PR #131 no se modifica aquí.

P0 del ZIP conserva su corte histórico de 21/11/2026. Esta revisión diferencial consultó metadatos GitHub de solo lectura el 22/11/2026 (Lima): Backend master `b4abb3acd866637edc603f1900a0bc77965f0d49`; Frontend master `ba0b8d0ed6a0530a3c7cca4fb72d14814746800d`; Docs master `81645104a93356a5672ccb866f3c704974b30ced`. Los estados de PR son una instantánea, no garantizan el estado futuro.

## Estado de H5 por requisito

No hay `PASS` global ni `COMPLETADO`. El estado de implementación, resultado de prueba, nivel de evidencia, despliegue, verificación de procedencia y homologación se conserva por separado. Un run `skipped`, un esqueleto, un mock, un YAML, un PR fusionado o un reporte sin SHA/artefacto verificado no se promueve a PASS.

## Mapa de documentos

1. [CI/CD y seguridad](01_CI_CD_Y_SEGURIDAD.md)
2. [Pruebas de integración](02_PRUEBAS_DE_INTEGRACION.md)
3. [Pruebas de performance](03_PRUEBAS_DE_PERFORMANCE.md)
4. [API Management](04_API_MANAGEMENT.md)
5. [Mensajería asíncrona](05_MENSAJERIA_ASINCRONA.md)
6. [Reparto de los seis desarrolladores](06_REPARTO_6_DESARROLLADORES.md)
7. [Trazabilidad y evidencias](07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md)
8. [Automatización y puertas](08_AUTOMATIZACION_Y_PUERTAS.md)
9. [Riesgos, bloqueos y demo](09_RIESGOS_BLOQUEOS_Y_DEMO.md)

## Glosario y convenciones

**L0** contrato estático; **L1** servicios reales en entorno aislado; **L2** Azure/Gateway real de pruebas; **L3** integración intergrupal homologada. **Outbox** registra entrega dentro de la transacción del servicio; **Inbox** registra consumo/idempotencia antes de completar el mensaje. **Baseline/candidato** son versiones comparables bajo configuración emparejada. **`INCONCLUSIVE`** significa que falta comparabilidad o procedencia; **`BLOCKED_*`** identifica una dependencia operativa concreta.

Enlace normativo principal: [ADR Service Bus Basic](../../arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md), [topología](../../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md), [matriz de implementación](../../integraciones/MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md), [plan de migración](../../integraciones/PLAN-MIGRACION-MENSAJERIA-H5.md), [matriz externa](../../integraciones/MATRIZ-EXTERNOS-ASYNCAPI-H5.md), [OpenAPI](../../contratos/http/openapi.yaml) y [AsyncAPI](../../contratos/eventos/asyncapi.yaml).

## Snapshot de infraestructura Azure

Consulta el [índice Azure G6](../../ops/azure/README.md) y el [checkpoint al 22/11/2026](../../ops/azure/checkpoints/CHECKPOINT-AZURE-G6-H5-2026-11-22.md). Es evidencia histórica; revalida antes de operar. No modifica criterios ni fuentes normativas.
