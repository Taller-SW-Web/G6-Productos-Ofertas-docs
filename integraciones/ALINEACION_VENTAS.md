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

El contrato `0.6.0-rc.1` modela `consumption_operation_id` como opcional y anulable; **no se debe presentarlo todavía como obligatorio**. G5 y el owner de Promociones deben cerrar si será obligatorio en v2 o si habrá una correlación alternativa verificable por `order_id` y operación de consumo persistida. La ausencia de este dato no autoriza restaurar un consumo ambiguo ni omitir comprobaciones de identidad y política.

## Inventario

Acuerdos de inventario homologados:

```text
CREADO -> reservar
PAGADO -> consumir reserva
cancelación pre-consumo -> liberar
retorno físico aceptado -> reintegrar
venta Retail offline -> conciliar
```

### Diferencia entre la admisión interna y la respuesta de Ventas

El contrato de G5 (`specs/api/api-ventas.md`, rama `main`, consultado el 11/10/2026) contempla `201 Created` al canal una vez creados el pedido y la reserva de stock/cupón confirmados. En cambio, el contrato interno de G6 devuelve `202 Accepted` al **admitir** un comando asíncrono de reserva. Estas dos respuestas no son equivalentes:

- **G6 Inventario:** devuelve `202` con `operation_id`; el éxito posterior se acredita mediante `inventory.reservation.created` v2 (incluido `reservation_id` y `expires_at`) o resultado final recuperable por `GET /api/v1/inventario/operaciones/{operationId}`. El rechazo se publica como `inventory.reservation.rejected`.
- **G5 Ventas:** para conservar su `201 Created` externo con la promesa vigente de stock/cupón confirmados, debe orquestar la espera y procesar ambos resultados definitivos antes de responder. Si necesita contestar al canal sin esperar esas confirmaciones, **G5 debe acordar y versionar** una semántica alternativa de su API externa; G6 no la modifica unilateralmente.

**Estado del acuerdo externo:** pendiente de ratificación explícita con G5. Esta sección documenta la compatibilidad requerida, no afirma que el backend actual implemente la espera, el sondeo o el consumo de eventos.

Ventas conserva el mismo `operation_id` al reintentar un comando, trata `message_id` como identificador de entrega y no declara stock reservado después del mero `202`. La confirmación de una reserva proporciona `reservation_id` y `expires_at`; se deben respetar al continuar al pago o al liberar. Los rechazos y los tiempos de espera no deben transformarse en confirmaciones implícitas.

## Addendum contractual 0.6.0-rc.1 — Cuatro bloqueantes G6

**Decisión interna aprobada; contrato candidato 0.6.0-rc.1, no implementado ni desplegado de extremo a extremo.** Las migraciones de Inventario `0002` y Promociones `0004` sí fueron aplicadas al Supabase compartido y aprobadas en el postcheck estructural y sus validadores SQL. Esto no acredita un backend funcional ni la activación de mensajería v2.

- `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- `POST /inventario/reservas`, `/confirmar` y `/liberar` devuelven `202` únicamente al admitir el comando; el éxito o rechazo definitivo está en el resultado persistido y el evento de negocio.
- Son contratos provisionales `GET /inventario/operaciones/{operationId}` (solo Ventas) y `POST /inventario/disponibilidad/comercial/verificar` (canales; consulta sin efectos secundarios).
- `inventory.reservation.rejected` y los resultados críticos v2 requieren identidad/correlación. El consumo de cupón exige reserva confirmada y snapshot comercial; los reintentos idénticos no generan nuevos efectos y el payload conflictivo debe rechazarse.
- `D-INV-01` adopta una sola ubicación elegible por referencia de cumplimiento mientras no exista política multi-origen verificable. Sin ruta válida, la respuesta es `INDETERMINADO`, sin divulgar saldos internos.
- La transición pago/consumo/liberación/expiración respeta la serialización y `expires_at`. Promociones no decide el estado del pedido ni del pago.

**Autorización e interoperabilidad pendientes:** G7 debe confirmar y registrar `inventario:operaciones:leer` para `modulo-ventas`; la disponibilidad efectiva del endpoint exige backend y credenciales adecuadas. No anunciar esta API como viva ni el scope como concedido antes de la evidencia. G5 debe coordinar la adaptación v1/v2 de los mensajes y el momento de la respuesta `201` al canal.
