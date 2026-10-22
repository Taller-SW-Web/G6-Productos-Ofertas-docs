# Alineación Ventas/Postventa ↔ Productos y Ofertas

## customer_ref

El identificador intermodular del cliente debe ser el UUID de Seguridad:

```text
contacto.clienteId (Ventas) = customer_ref (Promociones) = sub del usuario autenticado
```

El canal autentica al usuario y transmite su UUID a Ventas según los acuerdos de G5 y G7. **No** se debe obtener `customer_ref` del `sub` de un token de servicio de `modulo-ventas`, `modulo-marketplace`, `modulo-chatbot` o `modulo-retail`: ese token identifica al módulo, no al comprador.

El ejemplo `CLI-8841` debe sustituirse por un UUID de Seguridad o declararse explícitamente como alias interno no utilizable como `customer_ref`. Promociones admite `customer_ref = null` solo cuando la regla del cupón no exige identidad del cliente.

## Consumo de cupón

Después de crear el pedido `CREADO` y **recibir la confirmación efectiva** de reserva de Inventario:

```text
modulo-ventas
  -> promotions.coupon.consumption.requested
```

El comando v2 incluye `order_id` textual opaco, `operation_id` UUID en el sobre, `reservation_id` UUID de reserva confirmada, `commercial_snapshot_ref` durable y los demás campos exigidos por AsyncAPI. Una respuesta `202 Accepted` de Inventario **no** satisface esta precondición.

Si el resultado es:

```text
promotions.coupon.consumption.completed
```

el checkout puede continuar al intento de pago conforme al flujo acordado con G5.

Si es:

```text
promotions.coupon.consumption.rejected
```

no se debe intentar el cobro con ese snapshot de cupón. El rechazo de negocio debe llevar causa estable y correlación en el contrato v2; no confundirlo con un fallo técnico de mensajería.

Validar un cupón mediante HTTP no consume usos. Promociones vuelve a comprobar sus invariantes al procesar el consumo.

## Cancelación

Si el pedido había consumido cupón:

```text
modulo-ventas
  -> promotions.coupon.restoration.requested
```

Promociones aplica `RESTAURAR_EN_CANCELACION` o `NO_RESTAURAR` y devuelve un resultado idempotente. La restauración no precede a un consumo confirmado.

Para H4, G5 y G6 acuerdan conservar el UUID determinista de restauración y enviar siempre `consumption_operation_id` del consumo confirmado en las nuevas restauraciones, junto con el `cancelled_at` original. Los reintentos conservan el mismo `operation_id` y contenido semántico. AsyncAPI `0.6.0-rc.3` mantiene el campo opcional/anulable en el esquema general; se conserva esa compatibilidad y no se requiere una nueva versión. La implementación y prueba de replay siguen pendientes.

## Inventario

### Homologación G5 ↔ G6: reintegro físico de Postventa (F3)

Acuerdo ratificado el 13/10/2026 en el issue [G5 #51](https://github.com/Taller-SW-Web/G5-Ventas-Postventas/issues/51), con alcance limitado a los puntos P-01–P-09 allí confirmados. Esta homologación documental no acredita implementación, despliegue ni prueba E2E.

- M2/Postventa invoca directamente `POST /api/v1/inventario/reintegros` con audiencia `api-productos`, autenticación `client_credentials` y scope `inventario:reintegrar`. La allowlist conserva `modulo-ventas` para otros motivos contractuales (`ANULACION_POST_CONSUMO`, `RETORNO_LOGISTICO`); no se infieren reglas de autorización por motivo. El grant efectivo de G7 sigue pendiente.
- La aprobación comercial no equivale a recepción. F3 solo reintegra cantidades recibidas físicamente e inspeccionadas como aptas. G5 ha documentado su propio `PATCH /api/v2/devoluciones/{devolucionId}/recepcion`; el mecanismo y evidencia finales deben quedar definidos en ESP-07/ESP-08 antes de activar el flujo real.
- M2 obtiene el SKU exacto desde `items[].sku` del pedido original de Ventas; nunca lo infiere desde `productoId`.
- Payload canónico: `operation_id`, `order_id`, `source_ref`, `reason: DEVOLUCION_ACEPTADA` y `lines[]` con `sku`, `quantity` y `location_id`. Postventa acordó recepción en Lurín, con `location_id` `9129b578-631e-1735-8427-b683fb524380` configurado por entorno. G6 aún debe acreditar que el UUID existe y corresponde a esa ubicación en catálogo/runtime.
- Reintentos idénticos reutilizan `operation_id` y payload. Una nueva recepción parcial genera otro `operation_id`; no duplica Kardex. La respuesta contractual exitosa es `200` con `status: COMPLETED`.
- Para CAMBIO, M2 consulta `GET /api/v1/inventario/disponibilidad` con `inventario:disponibilidad:leer`. Es una lectura informativa que no reserva ni garantiza stock futuro y no debe usar un `channel_id` de Marketplace, Chatbot o Retail.
- M2 no reserva, consume ni libera unidades de reemplazo. M1 crea una orden propia, nueva y sin cobro, vinculada por G5 al pedido/devolución original; usa su `pedidoId` textual como `order_id` y gestiona reserva, consumo y liberación. Scopes separados: M1 `inventario:reservar`, `inventario:consumir`, `inventario:liberar`; M2 `inventario:reintegrar`, `inventario:disponibilidad:leer`. Para crear la orden, G5 documenta `POST /api/v1/pedidos/reemplazos` con `ventas:pedidos:reemplazar` para `modulo-postventa`; G5 propuso el scope y G7 tiene pendiente registrarlo y conceder el grant efectivo ([API G5](https://github.com/Taller-SW-Web/G5-Ventas-Postventas/blob/main/specs/api/api-ventas.md), [acuerdo G7](https://github.com/Taller-SW-Web/G5-Ventas-Postventas/blob/main/integraciones/ACUERDO_G7_SEGURIDAD.md)). No se presenta como concedido.
- La reserva de reemplazo tiene TTL sin renovación. Si vence o se rechaza antes del consumo, M1 anula la orden y, si procede, crea una nueva orden con una nueva reserva. M1 solicita consumo al sellar el paquete y espera confirmación definitiva antes de solicitar despacho; `202` solo admite el comando.
- El uso real depende de Seguridad G7: `client_credentials`, audiencia `api-productos`, cliente autorizado y scope correcto. La homologación no concede el grant. G5 no comprometió una integración funcional o E2E para el 14/10/2026.

Reglas documentadas para el flujo comercial de inventario correspondiente (no son por sí solas evidencia de implementación ni homologación global):

```text
CREADO -> reservar
PAGADO -> consumir reserva
cancelación pre-consumo -> liberar
retorno físico aceptado -> reintegrar
```

### Diferencia entre la admisión interna y la respuesta de Ventas

El contrato vigente de G5 ([`api-ventas.md` v1.5.0, §1.1](https://github.com/Taller-SW-Web/G5-Ventas-Postventas/blob/main/specs/api/api-ventas.md)) usa `201 Created` para registrar efectivamente un pedido nuevo y `200 OK` para replay idempotente. El contrato indica que si Productos no confirma disponibilidad G5 responde `409 ITEM_SIN_DISPONIBILIDAD` y no registra el pedido. El `201` no acredita consumo de cupón ni el resultado de comandos G6 posteriores, como el consumo del reemplazo. G6 devuelve `202 Accepted` al **admitir** el comando de reserva. Estas respuestas tienen semánticas distintas:

- **G6 Inventario:** devuelve `202` con `operation_id`; el éxito posterior se acredita mediante `inventory.reservation.created` v2 (incluido `reservation_id` y `expires_at`) o resultado final recuperable por `GET /api/v1/inventario/operaciones/{operationId}`. El rechazo se publica como `inventory.reservation.rejected`.
- **G5 Ventas:** `201` acredita la creación efectiva del pedido conforme al contrato vigente, que devuelve `409` y no registra el pedido si Productos no confirma disponibilidad. No acredita consumo de cupón ni el resultado de comandos G6 posteriores.

**Estado externo:** G5 define `201` como creación del pedido. D-01, D-03 y D-04 fueron aceptadas documentalmente en G5 #51; D-02 está adoptada internamente por G6, con adaptación y homologación operativa G5 de los nombres españoles pendientes. No se acredita implementación.

Ventas conserva el mismo `operation_id` al reintentar un comando, trata `message_id` como identificador de entrega y no declara stock reservado después del mero `202`. La confirmación de una reserva proporciona `reservation_id` y `expires_at`; se deben respetar al continuar al pago o al liberar. Los rechazos y los tiempos de espera no deben transformarse en confirmaciones implícitas.

### Conciliación Retail offline — homologación específica pendiente

La documentación G6 vigente conserva la secuencia Retail→Ventas/Postventa→G6: la venta física ya ocurrió, Retail la sincroniza con Ventas y `modulo-ventas` invoca la conciliación. Inventario mantiene la autoridad del saldo y concilia sin reserva retroactiva, aplicando solo cantidades admisibles, sin consumir reservas/bloqueos ni producir saldos negativos. No se fija un orden nuevo entre venta, pedido, pago y conciliación.

`COMPLETED` y `REQUIRES_REVIEW` son resultados distintos. La respuesta parcial conserva `requested_quantity`, `applied_quantity` y `unresolved_quantity`. La operación puede quedar registrada con cantidad aplicada cero, pero no se crea movimiento Kardex de cantidad cero. La misma venta física no debe generar un segundo descuento: identidad estable e intención/payload semántico iguales reproducen exactamente el resultado anterior; la identidad reutilizada con contenido distinto se rechaza con `409 IDEMPOTENCY_CONFLICT`, sin nuevos efectos.

El campo contractual de identidad estable de la venta, su ámbito de unicidad y persistencia no están definidos por completo. G4 usa `ventaLocalUuid`; OpenAPI G6 contiene `offline_sale_id`, `order_id` y `operation_id`, que cumplen referencias distintas. Su correspondencia y la deduplicación entre diferentes `operation_id` siguen pendientes de homologación. La existencia de esos nombres no acredita una estrategia implementada; no se prescribe campo ni mecanismo de persistencia.

DEC-F-014 exige que Inventario resuelva internamente la referencia pública de tienda a la ubicación efectiva y autorice actor, operación y ubicación. Un mapeo ausente/ambiguo, un actor no autorizado o un permiso de lectura comercial impiden la mutación. Sin embargo, el request OpenAPI actual exige `location_id` en cada línea; esa incompatibilidad contractual permanece pendiente y no se resuelve aquí. El endpoint candidato permite actualmente solo `modulo-ventas`, con scope `inventario:conciliar-offline` cuyo registro/grant efectivo de G7 sigue pendiente; Retail no es consumidor autorizado.

DEC-F-015 no obliga a retirar campos del response contractual vigente para Ventas: actualmente incluye `location_id`, `on_hand`, `reserved`, `blocked`, `available` y `stock_version`, además de cantidades funcionales. No se afirma que Retail reciba esa respuesta. La representación futura destinada a Retail, su consumidor, scope y eventual consulta posterior requieren acuerdo G4/G7.

La alternativa comunicada Retail→G6 directo continúa **no homologada**. G4 v0.4 prohíbe esa ruta y G4/G5 describen secuencias distintas; la invocación y secuencia requieren acuerdo específico G4/G5/G6. Para ventas sincronizadas con `pago.fechaVenta` de más de 72 horas, G4/G5 todavía deben definir el tratamiento contractual.

El estado Retail `PAGADO`/`ENTREGADO` sin reserva no habilita por sí mismo consumo de cupón offline. El mecanismo documentado de consumo de Promociones conserva como precondición una reserva de Inventario confirmada; no se crea aquí una excepción ni se altera consumo/restauración.

## Consolidación Hito 4 (2026-10-21)

G6 adopta internamente D-01 a D-04. G5 aceptó el piloto local SSH (D-01), `commercial_snapshot_ref = order_id` (D-03) y UUID deterministas/restauración (D-04). Para D-02, G5 pidió nombres físicos ingleses y la decisión final de Marco fijó los españoles de rc.3; adaptación y homologación operativa G5 siguen pendientes. Se conserva la topología existente: vhost `g6-productos-ofertas`, exchanges `po.comandos.x`, `po.eventos.x`, `po.resultados.x`; colas `po.ventas.q`, `po.inventario.q`, `po.promociones.q`. G5 usa túnel SSH local `127.0.0.1:5673`; Render queda pendiente e independiente. No se crean aliases ni recursos paralelos. PR #101 está fusionado; PR #98 requiere reconciliación contra `master`.

`commercial_snapshot_ref = order_id`; `order_id` contiene el `pedidoId` textual G5. Aplica la política de confianza interservicio aprobada para H4, pero G6 no acredita verificación independiente de todas las condiciones comerciales: campañas no verificables permanecen deshabilitadas. El productor real de `inventory.reservation.rejected`, `inventory.consumption.rejected` e `inventory.reservation.expired` sigue pendiente de evidencia. Rechazo HTTP inmediato y rechazo terminal de operación admitida con `202` son distintos.

**Antecedente del corte documental `0.6.0-rc.1`; conservar como contexto histórico.** Las migraciones de Inventario `0002` y Promociones `0004` fueron aplicadas al Supabase compartido y aprobadas en el postcheck estructural y sus validadores SQL. Esto no acredita un backend funcional ni la activación de mensajería v2.

## Addendum contractual 0.6.0-rc.1 — Cuatro bloqueantes G6

- `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- `POST /inventario/reservas`, `/confirmar` y `/liberar` devuelven `202` únicamente al admitir el comando; el éxito o rechazo definitivo está en el resultado persistido y el evento de negocio.
- Son contratos provisionales `GET /inventario/operaciones/{operationId}` (solo Ventas) y `POST /inventario/disponibilidad/comercial/verificar` (canales; consulta sin efectos secundarios).
- `inventory.reservation.rejected` y los resultados críticos v2 requieren identidad/correlación. El consumo de cupón exige reserva confirmada y snapshot comercial; los reintentos idénticos no generan nuevos efectos y el payload conflictivo debe rechazarse.
- `D-INV-01` adopta una sola ubicación elegible por referencia de cumplimiento mientras no exista política multi-origen verificable. Sin ruta válida, la respuesta es `INDETERMINADO`, sin divulgar saldos internos.
- La transición pago/consumo/liberación/expiración respeta la serialización y `expires_at`. Promociones no decide el estado del pedido ni del pago.

**Autorización e interoperabilidad pendientes en ese corte:** G7 debía confirmar y registrar `inventario:operaciones:leer` para `modulo-ventas`; la disponibilidad efectiva del endpoint requiere backend y credenciales adecuadas. Para el estado vigente, G5 adapta el envelope de mensajes a v2; `201` sigue la semántica actual de creación de pedido descrita arriba y `202` G6 solo admite comandos. Ninguna de estas referencias acredita despliegue o implementación.
