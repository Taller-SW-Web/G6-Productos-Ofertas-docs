# Transición de RabbitMQ

**Proyecto:** G6 — Productos y Ofertas  
**Estado:** plan de transición para revisión; **no ejecutado, no homologado**  
**Objetivo inmediato:** vhost `g6-productos-ofertas`, seguridad y operación reproducible  
**Alcance diferido:** traducción contractual de exchanges, colas y routing keys.

## 1. Por qué se necesita una transición

Existen **tres nombres y estados diferentes**:

| Estado | Nombre | Significado |
|---|---|---|
| Infraestructura observada (14-10-2026) | `g6` | Vhost realmente existente en Oracle, sin topología de negocio observada |
| Contrato vigente candidato `0.6.0-rc.1` | `/marketplace` | Vhost declarado por [AsyncAPI](../contratos/eventos/asyncapi.yaml) y la [topología](../contratos/eventos/rabbitmq-topologia.md) |
| Diseño objetivo elegido por G6 | `g6-productos-ofertas` | Nombre nuevo que deberá incorporarse a una versión de contrato y desplegarse tras aprobar el cambio |

Un vhost es un espacio lógico aislado. Crear `g6-productos-ofertas` no traslada automáticamente usuarios, colas, bindings, mensajes ni consumidores desde `g6` o `/marketplace`.

La auditoría observó **cero colas y cero conexiones** en el vhost `g6`, pero no permite afirmar que nadie preparará dependencias antes de la migración. Debe repetirse la verificación antes de modificar o eliminar recursos.

## 2. Principios de cambio

1. **No cambiar todo a la vez.** Priorizar cambio de vhost y endurecimiento de seguridad; tratar la traducción de nombres físicos y routing keys como decisión contractual separada.
2. **Una fuente ejecutable a la vez.** Cada entorno desplegado debe declarar exactamente qué versión de AsyncAPI/topología sigue; no mezclar exchanges en español con productores que solo publican en inglés.
3. **Contratos externos antes de consumidores externos.** G5 debe conocer y aceptar las propiedades de conexión y los eventos/colas que le afecten antes de una migración incompatible.
4. **Sin pasos destructivos automáticos.** No eliminar `g6`, no purgar colas, no recrear colas con tipo diferente ni rotar credenciales en uso sin un plan probado.
5. **Declarar estados por separado.** Propuesto, adoptado internamente, homologado, implementado, probado y desplegado no significan lo mismo.

## 3. Alcance del primer lote documental

Los documentos de esta entrega son:

- [Decisiones de RabbitMQ](../arquitectura/decisiones/rabbitmq.md): estándar objetivo, nomenclatura española, seguridad, fiabilidad, continuidad y observabilidad.
- [Operación de RabbitMQ](../arquitectura/operacion-rabbitmq.md): inventario, permisos, aprovisionamiento, recuperación y monitoreo.
- **Este plan:** secuencia de homologación y despliegue.

**No se modifica en este lote** el archivo `contratos/eventos/asyncapi.yaml`, la topología `rabbitmq-topologia.md`, los handlers de microservicios, CI/CD ni ningún recurso de la VM. Tampoco se presume que el PR de Inventory esté desplegado por existir código o pruebas locales.

## 4. Impactos y coordinación

| Parte | Afectación | Responsable de revisión |
|---|---|---|
| `inventory-svc` | Variable `RABBITMQ_URL`, usuario, exchanges/colas, outbox y eventos | G6 Inventario + infraestructura |
| Los otros siete microservicios de negocio | Publicación/consumo conforme a sus bindings en AsyncAPI | Owners G6 |
| `api-gateway` | Proyecciones por su cola; acceso sin administrador | Arquitectura G6 |
| G5 Ventas | Conexión, credencial de servicio, consumo `po.sales.q` y comandos acordados | G6 + G5 |
| G1 Marketplace | HTTP, sin cola directa en P2 | Informar solo si cambia una integración vigente |
| G3 Chatbot | HTTP; consumo directo de eventos excluido en P2 | Informar solo si cambia una integración vigente |
| G4 Retail | HTTP y conciliación offline aún con discrepancias documentales específicas | Resolver su homologación HTTP por su propio alcance |
| G2 Despacho | Consultas HTTP de datos físicos | Sin cambio RabbitMQ inferido |
| G7 Seguridad | Identidades/autorizaciones HTTP/JWT y acuerdos de seguridad | No confundir tokens HTTP con cuentas RabbitMQ |

No se atribuirá a G5 conformidad hasta contar con evidencia de aprobación. La topología candidata incluye **diez colas principales** (nueve aplicaciones G6 y G5 Ventas), además de colas de reintentos, fallidos y mensajes sin ruta.

## 5. Lotes de ejecución previstos

### Lote A — Acuerdo interno y documentación

**Objetivo:** fijar nombre de vhost, política de identidades, aprovisionamiento y operación. **Este ZIP constituye la propuesta documental de ese lote.**

**Pendientes:** revisión de coordinación de G6, corrección de posibles incompatibilidades, adopción documentada y definición del alcance exacto del cambio contractual.

**Criterio de salida:** documentos revisados, estado correcto y decisión explícita de si se cambia **solo el vhost** o también nombres físicos/keys en esta etapa.

### Lote B — Contrato de vhost y homologación

**Objetivo mínimo recomendado:** cambiar **solo** el vhost a `g6-productos-ofertas`, conservando temporalmente los nombres actuales de exchanges, colas y routing keys. Así se reduce el alcance de ruptura.

- Preparar una versión candidata de [AsyncAPI](../contratos/eventos/asyncapi.yaml), editando sus declaraciones de servidor y topología para un único nombre consistente.
- Actualizar [topología RabbitMQ](../contratos/eventos/rabbitmq-topologia.md) y sección RabbitMQ de [Arquitectura](../arquitectura/Arquitectura.md).
- Buscar referencias literales a `/marketplace` y corregir las que describan el vhost de mensajería; no tocar usos legítimos del término Marketplace como canal G1.
- Revisar las matrices de integración y el kit afectado, sin modificar otras decisiones funcionales.
- Comunicar a G5 la configuración acordada, red, cuenta, permisos y si cambian exchanges/colas/keys; recopilar su respuesta antes de declarar homologación.
- Validar esquemas AsyncAPI y consistencia exacta de colas, exchanges, bindings, retry y DLQ.

**Criterio de salida:** PR contractual revisado, consumidores advertidos y compatibilidad demostrable. El merge de documentos no acredita un broker en funcionamiento.

### Lote C — Infraestructura y piloto Inventory ↔ G5

**Objetivo:** desplegar lo autorizado en Oracle sin destruir la instalación existente.

- Verificar/exportar definiciones, localizar respaldos anteriores JSON/GPG, proteger copias y realizar ensayo de restauración.
- Inspeccionar acceso de red Docker y la necesidad real de conectividad externa para G5; acordar red privada o AMQPS/TLS.
- Crear el nuevo vhost, topología y usuarios mediante definiciones/scripts idempotentes.
- Aplicar matriz de permisos mínimos, con pruebas negativas y positivas.
- Configurar Inventory sin compartir contraseñas; comprobar conexión, confirmaciones y comportamiento de los consumidores.
- Probar entrega y consumo de resultados con G5 en un ambiente/ventana coordinados. Los contratos de reservas HTTP con resultado asíncrono requieren correlación e idempotencia; un `202` no implica éxito de negocio.
- Comprobar mensajes sin ruta, reintentos, DLQ, observabilidad y recuperación.

**Criterio de salida:** evidencia reproducible asociada a versión, fecha y entorno; G5 confirma recepción y tratamiento correcto de eventos. Si G5 no puede participar, estado **parcial**, nunca integración E2E aprobada.

### Lote D — Adopción completa y eventual traducción de nombres

**Objetivo:** incorporar progresivamente los demás productores y consumidores. Traducir exchanges, colas y routing keys **solo si se aprueba una migración adicional**.

- Inventariar todas las claves exactas de AsyncAPI, bindings, clientes y pruebas.
- Publicar versión de contrato y estrategia de compatibilidad.
- Definir si procede corte coordinado, convivencia temporal de recursos, adaptadores o doble publicación supervisada; ninguna estrategia es inocua por defecto.
- Considerar duplicados, orden y riesgos de mensajes pendientes durante coexistencia.
- Ejecutar pruebas contractuales y funcionales por consumidor.
- Retirar recursos antiguos únicamente tras demostrar que no tienen dependencias ni mensajes pendientes.

**Criterio de salida:** usuarios y servicios migrados con pruebas; no quedan publicaciones o consumidores apuntando a recursos retirados.

## 6. Verificaciones previas a todo corte

- [ ] Vhost antiguo realmente sin usuarios, conexiones, colas pendientes y publicadores en tránsito, o plan explícito para su drenaje.
- [ ] Definiciones anteriores respaldadas y restauración verificada.
- [ ] Matriz de usuarios y permisos validada; no publicar secretos.
- [ ] Variables de entorno de aplicaciones con procedencia y owner identificados.
- [ ] G5 informado y aceptación registrada para su integración afectada.
- [ ] Ruta privada/AMQPS y reglas OCI verificadas desde orígenes reales.
- [ ] Mensajes de prueba idempotentes, correlacionados y con evidencia.
- [ ] Plan de observabilidad y persona responsable de la ventana de cambio.
- [ ] Procedimiento de reversión y criterios de interrupción aprobados.

## 7. Reversión y límites

Si falla una etapa, suspender **productores nuevos** para evitar escrituras cruzadas, estabilizar consumidores y evaluar mensajes confirmados, no confirmados, pendientes y reintentos. Después podrá revertirse la conexión al vhost anterior **solo si** las colas y productores siguen siendo compatibles y existe un procedimiento para no perder ni duplicar efectos funcionales.

Restaurar definiciones no mueve mensajes entre vhosts. Reimportar JSON **no** reconstituye contenidos de colas. Revertir credenciales o borrar el nuevo vhost sin comprobar sesiones y mensajes puede provocar pérdida de eventos. Por tanto, la reversión deberá apoyarse en un ensayo real y en un criterio de consistencia de Inventario/Ventas.

## 8. Registro de decisiones y dependencias pendientes

| ID local de seguimiento | Tema | Estado inicial |
|---|---|---|
| NOMBRE | Vhost `g6-productos-ofertas` | Elegido internamente; contrato pendiente |
| IDIOMA | Traducir nombres de exchanges, colas y routing keys | Propuesta; plan de compatibilidad pendiente |
| PERMISOS | Usuarios separados, ACL estrictas y permisos de tópico | Diseño; sin despliegue acreditado |
| CONFIABILIDAD | Tres reintentos, 30 s, DLQ, publisher confirms, Outbox/Inbox | Contrato documentado; pruebas operativas pendientes |
| SEGURIDAD | Red privada/TLS para consumidores externos | Diseño y acuerdo con G5 pendientes |
| CONTINUIDAD | Backups y recuperación probada | Sin evidencia suficiente en auditoría |
| MONITOREO | Métricas y alertas de RabbitMQ | Diseño; instrumentación pendiente |
| HA | Nodo único sin tolerancia a caída del host | Limitación aceptada para etapa inicial, pendiente de objetivos formales |

Estas claves son **marcadores de seguimiento del documento**, no nuevos códigos oficiales DEC-F.

## 9. Fuentes y responsables de actualización

- [Decisiones de RabbitMQ](../arquitectura/decisiones/rabbitmq.md): coordinación G6.
- [Operación de RabbitMQ](../arquitectura/operacion-rabbitmq.md): infraestructura G6.
- [AsyncAPI](../contratos/eventos/asyncapi.yaml) y [topología](../contratos/eventos/rabbitmq-topologia.md): contrato ejecutable y topología física.
- [Arquitectura](../arquitectura/Arquitectura.md): descripción de decisiones y límites de componentes.
- [Matriz intermodular backend](./MATRIZ_INTERMODULAR_BACKEND.md): estado de acuerdos con cada grupo.

Las aprobaciones deben dejar constancia del documento/commit, fecha, alcance, owners y diferencias que sigan abiertas. No se deducen de un enlace a GitHub ni de un estado `merged`.
