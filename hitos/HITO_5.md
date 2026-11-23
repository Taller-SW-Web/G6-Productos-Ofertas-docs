# Hito 5 — Objetivo oficial y criterios de aceptación

> CI/CD incluyendo revision Seguridad — Evidencia de Pruebas de integración — Evidencia de Pruebas de performance — Uso de API Management y Mecanismo asincrónico entre Microservicios

## Contexto y estado

Guía de trabajo y trazabilidad detallada: [índice integral del Hito 5](h5/README.md). La guía separa el plan documental de la ejecución y no cambia estos criterios oficiales.

Hito 4 es el hito anterior y se conserva como referencia histórica, regresión y evidencia de la demo administrativa. La meta activa es Hito 5. Esta página registra criterios y evidencias; su publicación no acredita por sí misma ejecución, aprobación, homologación ni despliegue.

Los cuatro criterios parten de `EVIDENCIA_PARCIAL`. No se declara completo el hito.

## Criterios y matriz de aceptación

| ID | Criterio | Estado inicial | Evidencia requerida para aceptación | Evidencia / pendiente conocido |
|---|---|---|---|---|
| H5-01 | CI/CD incluyendo revisión de seguridad | `EVIDENCIA_PARCIAL` | Checks CI/CD obligatorios satisfactorios para el SHA revisado; revisión de seguridad y evidencia asociada al mismo cambio. | La política y workflows documentales están versionados; registrar ejecuciones CI y revisión por SHA. |
| H5-02 | Evidencia de pruebas de integración | `EVIDENCIA_PARCIAL` | Resultados reproducibles con servicios participantes, versiones, SHA, autenticación, entorno y alcance; distinguir simulaciones de integración real. | El piloto aislado Pricing → Price Audit es parcial; faltan pruebas integrales por flujo y fronteras homologadas. |
| H5-03 | Evidencia de pruebas de performance | `EVIDENCIA_PARCIAL` | Plan, carga, entorno, métricas, umbrales acordados y resultados reproducibles identificados por SHA. | La evidencia integral de performance permanece pendiente. |
| H5-04 | Uso de API Management y mecanismo asincrónico entre microservicios | `EVIDENCIA_PARCIAL` | Evidencia separada de APIM (rutas, políticas, autenticación y pruebas) y del mecanismo asincrónico interno (Azure Service Bus Basic, configuración, entrega durable, Inbox/Outbox e idempotencia, pruebas). | El piloto Service Bus no acredita APIM. La homologación externa, grants G7, recursos compartidos y despliegue se registran independientemente. |

## Responsabilidades

- **Backend:** implementar y evidenciar APIs autenticadas, integración interna asincrónica y controles de seguridad; registrar estado por servicio y SHA.
- **Frontend:** integrar mediante Gateway/APIM, demostrar pruebas HTTP simuladas por separado de E2E con servicios reales y aportar evidencia de performance de sus flujos.
- **Docs:** mantener la definición, contratos, criterios, matrices y referencias de evidencia; no inferir ejecución a partir de documentación.

## Referencias normativas y operativas

- CI/CD y seguridad: workflows de cada repositorio, revisiones de seguridad y artefactos asociados al SHA.
- Integración: [`contratos/pruebas/pruebas-contrato.md`](../contratos/pruebas/pruebas-contrato.md) y planes H5 aplicables.
- Performance: planes y reportes reproducibles de Backend y Frontend por flujo.
- API Management: Gateway/APIM autenticado; registrar configuración y pruebas de frontera independientemente del estado de Service Bus.
- Mensajería interna: [ADR Service Bus Basic](../arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md), [topología H5](../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md) y [matriz de implementación](../integraciones/MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md).
- Contratos canónicos H5: OpenAPI y AsyncAPI `0.7.0-rc.3`, aprobación interna `APPROVED_G6`; H4 permanece en `contratos/historico/h4/`. Homologación, implementación y operación conservan sus estados separados.

## Condiciones de cierre

Cada criterio debe contar con evidencia verificable vinculada a versión/SHA, entorno, alcance y responsables. CI, pruebas locales, piloto Azure, APIM, homologación externa, grants, despliegue y performance se registran como estados separados. No se acepta un criterio por inferencia ni se declara Hito 5 completo hasta que los cuatro criterios cumplan sus evidencias y revisiones aplicables.

## Bloqueos y evidencias pendientes

- Completar y vincular ejecuciones CI/CD y revisión de seguridad para los cambios de alcance.
- Completar pruebas de integración por flujo y E2E contra servicios reales; registrar por separado las pruebas simuladas.
- Aportar resultados de performance reproducibles con umbrales y entorno identificados.
- Acreditar APIM/Gateway por separado del piloto Azure Service Bus; confirmar recursos compartidos, grants/autorización G7, homologación externa aplicable y despliegues sin inferirlos de la documentación.
