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

Reglas documentadas para el flujo comercial de inventario correspondiente (no son por sí solas evidencia de implementación ni homologación global):

```text
CREADO -> reservar
PAGADO -> consumir reserva
cancelación pre-consumo -> liberar
retorno físico aceptado -> reintegrar
```

### Diferencia entre la admisión interna y la respuesta de Ventas

El contrato de G5 (`specs/api/api-ventas.md`, rama `main`, consultado el 11/10/2026) contempla `201 Created` al canal una vez creados el pedido y la reserva de stock/cupón confirmados. En cambio, el contrato interno de G6 devuelve `202 Accepted` al **admitir** un comando asíncrono de reserva. Estas dos respuestas no son equivalentes:

- **G6 Inventario:** devuelve `202` con `operation_id`; el éxito posterior se acredita mediante `inventory.reservation.created` v2 (incluido `reservation_id` y `expires_at`) o resultado final recuperable por `GET /api/v1/inventario/operaciones/{operationId}`. El rechazo se publica como `inventory.reservation.rejected`.
- **G5 Ventas:** para conservar su `201 Created` externo con la promesa vigente de stock/cupón confirmados, debe orquestar la espera y procesar ambos resultados definitivos antes de responder. Si necesita contestar al canal sin esperar esas confirmaciones, **G5 debe acordar y versionar** una semántica alternativa de su API externa; G6 no la modifica unilateralmente.

**Estado del acuerdo externo:** pendiente de ratificación explícita con G5. Esta sección documenta la compatibilidad requerida, no afirma que el backend actual implemente la espera, el sondeo o el consumo de eventos.

Ventas conserva el mismo `operation_id` al reintentar un comando, trata `message_id` como identificador de entrega y no declara stock reservado después del mero `202`. La confirmación de una reserva proporciona `reservation_id` y `expires_at`; se deben respetar al continuar al pago o al liberar. Los rechazos y los tiempos de espera no deben transformarse en confirmaciones implícitas.

### Conciliación Retail offline — homologación específica pendiente

La documentación G6 vigente conserva la secuencia Retail→Ventas/Postventa→G6: la venta física ya ocurrió, Retail la sincroniza con Ventas y `modulo-ventas` invoca la conciliación. Inventario mantiene la autoridad del saldo y concilia sin reserva retroactiva, aplicando solo cantidades admisibles, sin consumir reservas/bloqueos ni producir saldos negativos. No se fija un orden nuevo entre venta, pedido, pago y conciliación.

`COMPLETED` y `REQUIRES_REVIEW` son resultados distintos. La respuesta parcial conserva `requested_quantity`, `applied_quantity` y `unresolved_quantity`. La operación puede quedar registrada con cantidad aplicada cero, pero no se crea movimiento Kardex de cantidad cero. La misma venta física no debe generar un segundo descuento: identidad estable e intención/payload semántico iguales reproducen exactamente el resultado anterior; la identidad reutilizada con contenido distinto se rechaza con `409 IDEMPOTENCY_CONFLICT`, sin nuevos efectos.

El campo contractual de identidad estable de la venta, su ámbito de unicidad y persistencia no están definidos por completo. G4 usa `ventaLocalUuid`; OpenAPI G6 contiene `offline_sale_id`, `order_id` y `operation_id`, que cumplen referencias distintas. Su correspondencia y la deduplicación entre diferentes `operation_id` siguen pendientes de homologación. La existencia de esos nombres no acredita una estrategia implementada; no se prescribe campo ni mecanismo de persistencia.

DEC-F-014 exige que Inventario resuelva internamente la referencia pública de tienda a la ubicación efectiva y autorice actor, operación y ubicación. Un mapeo ausente/ambiguo, un actor no autorizado o un permiso de lectura comercial impiden la mutación. Sin embargo, el request OpenAPI actual exige `location_id` en cada línea; esa incompatibilidad contractual permanece pendiente y no se resuelve aquí. El endpoint candidato permite actualmente solo `modulo-ventas`, con scope `inventario:conciliar-offline` cuyo registro/grant efectivo de G7 sigue pendiente; Retail no es consumidor autorizado.

DEC-F-015 no obliga a retirar campos del response contractual vigente para Ventas: actualmente incluye `location_id`, `on_hand`, `reserved`, `blocked`, `available` y `stock_version`, además de cantidades funcionales. No se afirma que Retail reciba esa respuesta. La representación futura destinada a Retail, su consumidor, scope y eventual consulta posterior requieren acuerdo G4/G7.

La alternativa comunicada Retail→G6 directo continúa **no homologada**. G4 v0.4 prohíbe esa ruta y G4/G5 describen secuencias distintas; la invocación y secuencia requieren acuerdo específico G4/G5/G6. Para ventas sincronizadas con `pago.fechaVenta` de más de 72 horas, G4/G5 todavía deben definir el tratamiento contractual.

El estado Retail `PAGADO`/`ENTREGADO` sin reserva no habilita por sí mismo consumo de cupón offline. El mecanismo documentado de consumo de Promociones conserva como precondición una reserva de Inventario confirmada; no se crea aquí una excepción ni se altera consumo/restauración.

## Addendum contractual 0.6.0-rc.1 — Cuatro bloqueantes G6

**Decisión interna aprobada; contrato candidato 0.6.0-rc.1, no implementado ni desplegado de extremo a extremo.** Las migraciones de Inventario `0002` y Promociones `0004` sí fueron aplicadas al Supabase compartido y aprobadas en el postcheck estructural y sus validadores SQL. Esto no acredita un backend funcional ni la activación de mensajería v2.

- `order_id` es la referencia textual opaca de Ventas; `operation_id` y `reservation_id` son UUID. No convertir `PED-*` a UUID.
- `POST /inventario/reservas`, `/confirmar` y `/liberar` devuelven `202` únicamente al admitir el comando; el éxito o rechazo definitivo está en el resultado persistido y el evento de negocio.
- Son contratos provisionales `GET /inventario/operaciones/{operationId}` (solo Ventas) y `POST /inventario/disponibilidad/comercial/verificar` (canales; consulta sin efectos secundarios).
- `inventory.reservation.rejected` y los resultados críticos v2 requieren identidad/correlación. El consumo de cupón exige reserva confirmada y snapshot comercial; los reintentos idénticos no generan nuevos efectos y el payload conflictivo debe rechazarse.
- `D-INV-01` adopta una sola ubicación elegible por referencia de cumplimiento mientras no exista política multi-origen verificable. Sin ruta válida, la respuesta es `INDETERMINADO`, sin divulgar saldos internos.
- La transición pago/consumo/liberación/expiración respeta la serialización y `expires_at`. Promociones no decide el estado del pedido ni del pago.

**Autorización e interoperabilidad pendientes:** G7 debe confirmar y registrar `inventario:operaciones:leer` para `modulo-ventas`; la disponibilidad efectiva del endpoint exige backend y credenciales adecuadas. No anunciar esta API como viva ni el scope como concedido antes de la evidencia. G5 debe coordinar la adaptación v1/v2 de los mensajes y el momento de la respuesta `201` al canal.
