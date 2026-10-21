# Transición de RabbitMQ

**Proyecto:** G6 — Productos y Ofertas
**Estado:** reconciliación documental candidata `0.6.0-rc.3`; homologación externa, adaptación de código y ejecución real pendientes
**Evidencia base:** auditoría histórica Oracle del 2026-10-19; no representa necesariamente el estado actual del servidor

## 1. Alcance y estados

La auditoría reportó RabbitMQ 4.2.9, vhost `g6-productos-ofertas`, cuatro exchanges base, diez colas de aplicación y una operativa, colas quorum/durables y 57 bindings. AsyncAPI `0.6.0-rc.3` alinea nombres de exchanges y colas con esa observación. La modificación es incompatible para productores y consumidores que aún usen nombres ingleses anteriores.

Esta candidata conserva 40 canales y mensajes, operaciones, productores, consumidores, payloads, esquemas, routing keys comerciales y vhost respecto de `0.6.0-rc.2`. No cambia broker, ACL, red, credenciales ni código. La observación histórica no demuestra estado actual, binding individual, homologación, conectividad, entrega, ACK, despliegue ni E2E.

La auditoría registra 57 bindings físicos y el candidato contiene 56 entradas de binding en las diez colas principales; no están disponibles definiciones físicas para comparar cada exchange/cola/clave. La correspondencia exacta se mantiene `PENDIENTE_VERIFICACION`. La cantidad diferente refuerza que no se debe afirmar equivalencia. Véase la [matriz de compatibilidad](../contratos/eventos/compatibilidad-rabbitmq-oracle.md).

## 2. Correspondencia de nombres físicos

| Candidato anterior | Nombre observado / rc.3 |
|---|---|
| `po.commands.x` | `po.comandos.x` |
| `po.events.x` | `po.eventos.x` |
| `po.results.x` | `po.resultados.x` |
| `po.unrouted.x` | `po.sin-ruta.x` |
| `po.catalog.q` | `po.catalogo.q` |
| `po.gateway.q` | `po.pasarela.q` |
| `po.promotions.q` | `po.promociones.q` |
| `po.combos.q` | `po.combos.q` |
| `po.inventory.q` | `po.inventario.q` |
| `po.pricing.q` | `po.precios.q` |
| `po.price-audit.q` | `po.auditoria-precios.q` |
| `po.sales.q` | `po.ventas.q` |
| `po.taxonomy.q` | `po.taxonomia.q` |
| `po.bulk.q` | `po.masivos.q` |
| `po.unrouted.q` | `po.sin-ruta.q` |

`po.retry.x` y `po.dlx.x` no se traducen; continúan no aprobados y no aprovisionados. Los nombres derivados `<cola>.retry`, `<cola>.dlq` y sus claves técnicas usan la nueva identidad de la cola principal solo en el diseño candidato. Las routing keys comerciales permanecen iguales.

## 3. Impacto y coordinación

| Parte | Impacto documental previsto | Estado externo / implementación |
|---|---|---|
| Ocho servicios G6 | Actualizar configuración/adaptadores al nombre físico asociado a su operación y cola | Código y runtime no acreditados; propietarios G6 deben revisar/adaptar |
| Pasarela/BFF G6 | Referencia a `po.pasarela.q` | Implementación no acreditada |
| G5 Ventas | Exchange de comandos y cola `po.ventas.q`; incompatibilidad de identidad física | Homologación específica de los nombres pendientes |
| G1 Marketplace, G3 Chatbot y G4 Retail | Sin cola directa definida por esta reconciliación | No se infiere cambio de ownership ni nueva integración |
| G2 Despacho | Sin cambio RabbitMQ inferido | Integración HTTP conserva su alcance |
| G7 Seguridad / Infraestructura | ACL, identidad y red deben validarse antes de conectar | No se amplían permisos ni se autoriza acceso por este documento |

La auditoría reportó para `g5_ventas` en `g6-productos-ofertas`: `write` sobre `po.comandos.x`, `read` sobre `po.ventas.q` y `configure` denegado. Es evidencia histórica de identidad/permisos, no prueba de conexión, entrega, consumo ni aceptación.

La homologación G5 sigue pendiente para aceptación de nombres físicos, red privada o túnel autorizado, identidad/ACL, publisher confirms, ACK, idempotencia y pruebas bilaterales reproducibles. No se atribuye aceptación por silencio.

## 4. Gate retry/DLX separado

Retry/DLX permanece **BLOQUEADO**, **NO APROBADO**, **NO APROVISIONADO** y **NO HOMOLOGADO**. No se adoptan ni implementan alternativas A/B/C, no se activan políticas ni se conceden permisos runtime. Se conserva `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`; la evidencia disponible de recuperación saturada terminó FAIL.

`0.6.0-rc.3` corresponde exclusivamente a la reconciliación base. Una adopción futura de retry/DLX requiere superar sus gates y tramitarse mediante una versión candidata posterior, cuyo número no se fija aquí.

## 5. Validación y publicación

La verificación local de la candidata debe comprobar YAML/AsyncAPI, referencias, nombres base, bindings contractuales, invariantes lógicas frente a `0.6.0-rc.2`, enlaces y diff. Estas comprobaciones documentales no acreditan broker Oracle, conectividad, homologación, recepción, ACK ni E2E.

No cambiar recursos de broker, colas con mensajes, bindings, políticas, usuarios, credenciales o redes como parte de esta transición documental. Cualquier cambio físico requiere autorización y un procedimiento propio coordinado con sus owners.

## Referencias

- [AsyncAPI](../contratos/eventos/asyncapi.yaml)
- [Topología RabbitMQ](../contratos/eventos/rabbitmq-topologia.md)
- [Matriz de compatibilidad Oracle](../contratos/eventos/compatibilidad-rabbitmq-oracle.md)
- [Decisiones de RabbitMQ](../arquitectura/decisiones/rabbitmq.md)
- [Operación de RabbitMQ](../arquitectura/operacion-rabbitmq.md)
