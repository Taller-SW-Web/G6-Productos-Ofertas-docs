# Plan de migración H5: RabbitMQ → Service Bus Basic y G5 por HTTP

**Estado:** candidato para revisión, NO plan de despliegue aprobado. Ruta contract-first, evidencia por SHA.

## Alcance y exclusiones

Incluye: ocho servicios backend G6, Gateway/APIM, productores/consumidores del AsyncAPI, piloto G5 y seguridad G7. Excluye: reescribir lógica de negocio que ya funciona, introducir nuevos contratos de Retail/Despacho/Chatbot, activar promociones/cupones con dependencias incumplidas o declarar E2E sobre mocks.

## Fases y gates

| Fase | Owner primario | Entregable | Gate para siguiente fase |
|---|---|---|---|
| D0 Inventario y decisión | Coordinación G6 + Docs | ADR, matriz de 40 mensajes, topología, riesgos, costos | Revisión G6, clasificación por runtime, topología aprovisionable |
| D1 Contratos externos | G6 Docs, G5, G7 | OpenAPI HTTP candidato, matriz G5, estados de expiración/GET, scopes propuestos | Aceptación bilateral G5 y autorización contractual G7, sin asumir grants |
| I1 Adaptador base | G6 backend/infra | SDK, abstraction, IaC Basic, outbox_delivery, inbox | Prueba local y real de fallo/reintento/identidad |
| I2 Piloto interno | Pricing + Price Audit | `pricing.price.changed` → auditoría | CI, E2E interno, duplicados, DLQ, métricas, costo |
| I3 Comandos y resultados | Catalog, Pricing, Inventory | Inicializaciones, resultados, idempotencia | Contratos y correlaciones E2E por servicio |
| I4 Fan-out | Catalog, Inventory, Combos, Promotions | Distribución a múltiples colas; bloqueos funcionales aislados | Cada destino recibe una copia y se recupera por separado |
| I5 Bulk y Taxonomy | Bulk, Catalog, Taxonomy | Bulk 256 KB/claim-check y baja maestros | Volumen, correlación, orden por agregado y recuperación |
| I6 Frontera HTTP G5 | Promotions, Inventory, Gateway, G5 | Cupones POST/GET, reservación GET y expiraciones | G5 confirma end-to-end semántica y fallos; G7 autoriza |
| I7 Retiro de RabbitMQ | Coordinación G6 y owners | Inventario cero dependencias, rollback/drenaje, docs finales | Solo después de autorizar corte y validar datos pendientes |
| Cierre H5 | QA + DevOps | CI/CD con revisión seguridad, integración, performance, APIM y mensajería | Evidencia reproducible de los cuatro requisitos del Hito 5 |

No mezclar el cierre académico con homologación externa no obtenida. Evidencias de integración interna pueden acreditarse separadamente.

## Flujos bloqueados por código o acuerdos anteriores

| Flujo | Limitación conocida | Decisión provisional |
|---|---|---|
| Bulk→Inventory | Handler `inventory.bulk.stock.adjust.requested` marca `BLOCKED_CONTRACT` | No anunciar procesamiento masivo funcional |
| Bulk→Pricing | Consumidor registra/bloquea comando masivo; no equivale a aplicación | Implementar cuando se apruebe negocio |
| Inventory→Promotions | Runtime de cupones requiere identidad y elegibilidad aún bloqueadas | No desbloquear solo por cambiar broker |
| Catalog→Pricing/Inventory | Flujos de inicialización reales sujetos a versión/correlación | Pruebas por contrato antes de habilitar |
| Taxonomy→Catalog | Algunos mensajes declarados en bindings sin handlers completos en versión auditada | Reconciliar implementación vigente antes de crear cola |
| G5→Promotions | G5 emite schema v1 con campos obligatorios v2 faltantes | Rehacer client contract-first |
| G6 Inventory→G5 | `inventory.reservation.expired` después de operación previa | Diseñar consulta de estado actual/reserva o notificación confiable |
| G4 Retail offline | Documentos G4/G5/G6 atribuyen invocador distinto | Acuerdo intermodular separado, sin cambios implícitos |

## Estrategia de compatibilidad

- No modificar destructivamente H4 AsyncAPI/OpenAPI ni documentación Oracle: crear candidatos H5 y registrar notas de transición.
- La versión futura de AsyncAPI debe conservar nombres, schemas e IDs internos de negocio aprobados. Cambios de transporte son versionados; eliminar destinatario externo sin aprobación explícita rompe integración.
- El OpenAPI futuro incluye nuevos endpoints asíncronos de promociones solo después de cerrar estados, seguridad, DTO y owner.
- Incluir pruebas de consumidor/contract-test G5 basadas en DTO HTTP, no conservar `RabbitTemplate` en modo real cuando ocurra el corte.
- Mantener una ventana de compatibilidad clara si G5 no puede migrar al mismo tiempo; **no** ejecutar simultáneamente el mismo consumo funcional por dos canales sin deduplicación de operación verificada.

## Criterio de resultados

Separar `DOCUMENTADO`, `ADOPTADO_G6`, `HOMOLOGADO_G5`, `AUTORIZADO_G7`, `IMPLEMENTADO`, `CI_VERIFICADA`, `DESPLEGADO`, `E2E_VERIFICADO` y `PERFORMANCE_VERIFICADA`. Cada afirmación incluye commit, entorno, evidencia, versión, actor, timestamp y responsable. Una prueba en emulador o contra stub no equivale a integración externa real.

## Coordinación y cambio de ownership

G5 sigue dueño de pedido/pago/cancelación, G6 Inventory de stock y G6 Promotions de cupones. G5 debe cambiar código de `CuponesClient.java`, `ConsumidorProductos.java`, `MensajesProductosService.java`, `MensajeInventario.java`, `ProductosClient.java` y `application.yml` solo en su propio repositorio y bajo su aprobación. G6 no altera repos G5 unilateralmente.
