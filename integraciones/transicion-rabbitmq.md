# Transición de RabbitMQ

**Proyecto:** G6 — Productos y Ofertas
**Estado:** reconciliación documental candidata `0.6.0-rc.3`; homologación externa, adaptación de código y ejecución real pendientes
**Evidencia base:** auditoría histórica Oracle del 2026-10-19; no representa necesariamente el estado actual del servidor

## 1. Alcance y estados

La auditoría reportó RabbitMQ 4.2.9, vhost `g6-productos-ofertas`, cuatro exchanges base, diez colas de aplicación y una operativa, colas quorum/durables y 57 bindings. AsyncAPI `0.6.0-rc.3` alinea nombres de exchanges y colas con esa observación. La modificación es incompatible para productores y consumidores que aún usen nombres ingleses anteriores.

Esta candidata conserva 40 canales y mensajes, operaciones, productores, consumidores, payloads, esquemas, routing keys comerciales y vhost respecto de `0.6.0-rc.2`. No cambia broker, ACL, red, credenciales ni código. La observación histórica no demuestra estado actual, binding individual, homologación, conectividad, entrega, ACK, despliegue ni E2E.

El contrato contiene 56 bindings en las diez colas principales y un binding operativo de `po.sin-ruta.x` a `po.sin-ruta.q` (`#`): 57 en total. La auditoría reporta 57 físicos; las definiciones individuales no están disponibles para contrastar exchange/cola/clave, así que la correspondencia exacta continúa `PENDIENTE_VERIFICACION`. Véase la [matriz de compatibilidad](../contratos/eventos/compatibilidad-rabbitmq-oracle.md).

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

## 5. Lotes de ejecución previstos y gates

Los siguientes son gates para una transición de infraestructura futura, no tareas autorizadas por este PR ni evidencia de ejecución.

### Lote A — Contrato y coordinación

- Identificar AsyncAPI `0.6.0-rc.3` como candidata incompatible de nombres físicos; inventariar productores, consumidores, configuración, bindings y pruebas que aún usen identificadores anteriores.
- Comunicar a cada owner la versión, el mapeo, las operaciones afectadas y el plan de adaptación. No mezclar publishers con nombres de versiones distintas.
- Registrar aprobación por responsable/alcance; el silencio no constituye homologación. Para G5: aceptar nombres, red privada o túnel, identidad/ACL, confirms, ACK, idempotencia, estrategia de despliegue y prueba bilateral reproducible.
- Cerrar divergencias de contrato y permisos; distinguir observación física, contrato, implementación y pruebas.

### Lote B — Preparación de infraestructura

- Repetir inventario de solo lectura justo antes de cualquier cambio: vhost, recursos, bindings exactos, conexiones, consumidores, `ready`, `unacked`, políticas y dependencias de clientes. No asumir que el corte Oracle histórico sigue vigente.
- Exportar definiciones actuales en ubicación protegida; comprobar respaldos JSON/GPG existentes, preservar originales y ensayar restauración en ambiente aislado. Una exportación de definiciones no respalda mensajes.
- Aprobar un diff declarativo e idempotente, matriz ACL y prueba positiva/negativa. Las identidades de aplicación no administran; no habilitar `configure` runtime sin evidencia del arranque del cliente.
- Confirmar red desde ubicaciones reales, controles de firewall/OCI y TLS o transporte privado para G5. No exponer AMQP públicamente por conveniencia.
- No cambiar tipo de exchange, recrear colas con mensajes ni retirar recursos previos sin plan de drenaje, compatibilidad y reversión aprobados.

### Lote C — Piloto y homologación G5

- Solo después de aprobaciones externas e internas correspondientes, aplicar el cambio autorizado en entorno/piloto aislado mediante proceso de infraestructura con SHA, operador y ventana registrados.
- Validar publicación y routing de mensajes sintéticos, publisher confirms, `mandatory`/`basic.return`, consumo de cola propia, ACK tras persistencia/efecto idempotente y observabilidad; luego probar con G5 en ventana coordinada.
- El gate de G5 solo cierra con recepción/tratamiento confirmados por ambas partes y evidencia reproducible ligada a versión/commit/entorno. Sin participación bilateral, el estado permanece parcial, no E2E.
- Mantener Retry/DLX fuera del piloto mientras `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA` siga abierta.

### Lote D — Adopción gradual restante

- Migrar productores y consumidores por owner y versión contractual; verificar mensajes pendientes, duplicados, orden, consistencia de Outbox/Inbox y efectos funcionales por servicio.
- Definir explícitamente convivencia temporal o corte coordinado; ninguna doble publicación o alias se presume segura.
- Retirar nombres anteriores únicamente cuando el inventario demuestre ausencia de dependencias, conexiones y mensajes pendientes, exista respaldo y el plan de reversión esté probado.

## 6. Criterios de aprobación de infraestructura

- [ ] Estado de broker y bindings exportado en la ventana; mapeo exacto contrastado, no inferido por conteo.
- [ ] Homologación de cada externo afectado, en particular G5, documentada por owner.
- [ ] ACL de recurso y topic permissions revisados por separado; permisos efectivos probados con casos permitidos y denegados.
- [ ] Declaraciones de recursos realizadas por identidad de aprovisionamiento; runtime consume recursos preaprovisionados sin privilegios de administración.
- [ ] Red/TLS y permisos probados desde el origen real de cada aplicación.
- [ ] Flujo de prueba confirma publicación, ruta, persistencia/efecto, ACK e idempotencia; `basic.return` y publisher confirm se interpretan por separado.
- [ ] Métricas, alertas, responsables de ventana e incidentes verificados.
- [ ] Evidencia reproducible asociada a SHA, versión, fecha, entorno y alcance; separada de homologación y despliegue.

## 7. Respaldo, reversión y recuperación

Antes de un corte, exportar definiciones/topología de forma protegida y verificar la restauración en aislamiento. Para datos de mensajes, utilizar un procedimiento consistente con la versión e identidad del nodo y ensayarlo; importar definiciones no mueve ni reconstituye mensajes. Retención, RTO/RPO, propietario y almacenamiento externo requieren acuerdo, no se inventan aquí.

Si falla una etapa, detener nuevos publishers del lote para evitar escrituras cruzadas, estabilizar consumidores e inventariar mensajes confirmados, no confirmados, pendientes y técnicos en retry. Revertir conexiones solo si los recursos siguen siendo compatibles y el ensayo demuestra que no se pierden ni duplican efectos. No purgar, recrear colas con mensajes ni eliminar vhosts automáticamente. Recuperación funcional exige prueba aislada de topología, permisos, mensajes sintéticos, reconexión e idempotencia y evidencia con duración y limitaciones.

Retry/DLX conserva el resultado histórico **FAIL** de recuperación bajo saturación y permanece bloqueado. No es criterio cumplido ni parte de un procedimiento operativo aprobable hasta resolver `RECUPERACION_DLQ_SATURADA_NO_VERIFICADA`; las alternativas A/B/C siguen no aprobadas y no aprovisionadas.

## 8. Validación documental

La verificación de esta candidata comprueba YAML/AsyncAPI, referencias, nombres base, bindings contractuales, invariantes lógicas contra `0.6.0-rc.2`, enlaces y diff. No acredita broker Oracle, conectividad, homologación, recepción, ACK, respaldo restaurable, despliegue ni E2E.

No cambiar recursos de broker, colas con mensajes, bindings, políticas, usuarios, credenciales o redes como parte de esta transición documental. Cualquier cambio físico requiere autorización y un procedimiento propio coordinado con sus owners.

## Referencias

- [AsyncAPI](../contratos/eventos/asyncapi.yaml)
- [Topología RabbitMQ](../contratos/eventos/rabbitmq-topologia.md)
- [Matriz de compatibilidad Oracle](../contratos/eventos/compatibilidad-rabbitmq-oracle.md)
- [Decisiones de RabbitMQ](../arquitectura/decisiones/rabbitmq.md)
- [Operación de RabbitMQ](../arquitectura/operacion-rabbitmq.md)
