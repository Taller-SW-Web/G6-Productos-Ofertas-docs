# Propuestas DEC-F para backend e integración

**Estado de las tres propuestas:** `PROPUESTA_G6`
**Aprobador:** Marco, después de auditoría independiente
**Alcance:** propuestas para evaluación; no forman parte del registro normativo y no están adoptadas, homologadas ni implementadas.

Estas propuestas no modifican contratos ejecutables. Las contradicciones indicadas deben resolverse con los owners concernidos antes de implementar cambios que dependan de ellas.

## DEC-F-013 — Conciliación offline autoritativa

**Estado:** `PROPUESTA_G6`

### Enunciado

Inventario mantiene el saldo central autoritativo. La conciliación de una venta Retail ocurrida físicamente durante una desconexión registra el efecto de esa venta sin crear una reserva retroactiva. Debe permitir aplicación parcial: aplica únicamente la cantidad admisible conforme a las invariantes vigentes y deja el resto pendiente de revisión. Nunca genera saldo negativo. Cada movimiento queda asociado al mecanismo de trazabilidad autorizado para movimientos de Inventario.

La misma venta no puede descontarse dos veces aunque una repetición técnica llegue con un identificador de reintento distinto. OpenAPI G6 ya exige `offline_sale_id` de tipo `string`; G4 v0.4 utiliza `ventaLocalUuid` para identificar una venta offline. Estos identificadores son distintos de `order_id`, que vincula el pedido, y `operation_id`, que identifica la operación de conciliación.

### Justificación

SPEC-015 y el OpenAPI G6 describen conciliación, cantidades aplicadas y no resueltas. La venta ya sucedió en el POS; por tanto, una reserva posterior no representaría el hecho comercial y no debe fabricarse. La fuente de verdad para el saldo sigue siendo Inventario central, que admite solo el descuento de cantidades disponibles según las invariantes aplicables.

### Invariantes propuestas

- El saldo autoritativo permanece en Inventario central por SKU y ubicación.
- El estado local del POS durante desconexión es provisional y no sustituye el saldo central.
- La conciliación puede ser parcial; el resultado permite distinguir cantidades aplicadas y pendientes de revisión.
- Ninguna aplicación produce saldo negativo ni consume cantidades reservadas o bloqueadas.
- La venta física no crea una reserva retroactiva.
- Repetir la misma venta no vuelve a descontar unidades, aunque cambie el identificador técnico del reintento.
- Los movimientos se registran mediante el mecanismo de trazabilidad autorizado existente; esta propuesta no define campos ni esquema.

### Límites y pendientes

Quedan pendientes el mapeo contractual entre G4 `ventaLocalUuid` y G6 `offline_sale_id`, la estabilidad de esa identidad entre reintentos y el ámbito de deduplicación. OpenAPI ya exige `offline_sale_id` como string, pero no resuelve por sí solo esa correspondencia ni esas semánticas. No se proponen índices, claves nuevas ni cambios de esquema. `order_id` identifica el pedido y `operation_id` la operación de conciliación; cumplen funciones distintas de la identidad de venta.

El OpenAPI actual permite `modulo-ventas` para la operación de conciliación y G6 mantiene documentación que sitúa a Ventas como intermediario. El antecedente comunicado de Retail llamando directamente a G6 aún requiere homologación con G4, G5 y Seguridad. Esta propuesta no determina el orden entre creación del pedido, cobro, conciliación o consumo de stock.

### Fuentes

- [SPEC-015](../../requisitos/specs/SPEC-015-control-stock-disponibilidad.md), sección de conciliación offline.
- [OpenAPI G6](../../contratos/http/openapi.yaml), `POST /inventario/conciliaciones-offline`.
- [DEC-F-002 y DEC-F-009 vigentes](REGISTRO_DEC_F.md), para autoridad de saldo, aplicación parcial e identidad/deduplicación pendiente.

## DEC-F-014 — Resolución segura de tienda a ubicación

**Estado:** `PROPUESTA_G6`

### Enunciado

Para una mutación de Inventario solicitada en contexto Retail, un identificador público de tienda debe resolverse internamente a una ubicación autorizada. Retail no elige libremente identificadores internos de ubicación. No se aplica ninguna mutación si la tienda es desconocida, la correspondencia es ambigua o la identidad técnica que invoca no está autorizada para la operación y ubicación.

### Justificación

D-INV-01 regula la proyección comercial de disponibilidad: una fuente elegible por contexto y `INDETERMINADO` cuando no se puede resolver una fuente única. Esa política de lectura no concede autoridad para mutar inventario ni acredita que una tienda pueda seleccionar una ubicación. La autorización de una mutación debe comprobarse por separado.

### Diferencia explícita frente al contrato actual

OpenAPI define `ConciliacionOfflineRequest.lines`; cada elemento referencia `LineaInventarioUbicada`, cuyo esquema exige actualmente `location_id`. Esa exigencia del contrato requiere que el request lleve la ubicación interna, mientras esta propuesta plantea resolver internamente la tienda pública a una ubicación autorizada. Existe incompatibilidad contractual pendiente de cambio aprobado y homologación con Retail y Seguridad. Esta propuesta no modifica OpenAPI ni introduce campos.

### Invariantes propuestas

- La disponibilidad comercial D-INV-01 continúa siendo una consulta sin efectos y no una autorización de escritura.
- La correspondencia entre tienda pública y ubicación interna se resuelve en G6, bajo ownership de Inventario.
- Retail no suministra una ubicación interna de libre elección para dirigir una mutación.
- La mutación falla de forma segura ante tienda desconocida, mapeo ambiguo o identidad técnica no autorizada.
- Antes de cualquier cambio contractual o de implementación se verifica compatibilidad con el contrato Retail y con las reglas de Seguridad.

### Límites y pendientes

La propuesta no fija campos, rutas, códigos de error, mecanismo de mapeo ni nuevo scope. El contrato actual y los permisos concedidos deben revisarse con los owners de Retail y Seguridad. La documentación de un scope no equivale a su aprobación, grant ni provisión efectiva.

### Fuentes

- [ADR B3 — D-INV-01](ADR-DEC-F-BLOQUEANTES.md).
- [SPEC-015](../../requisitos/specs/SPEC-015-control-stock-disponibilidad.md), política de disponibilidad comercial y conciliación.
- [OpenAPI G6](../../contratos/http/openapi.yaml), operaciones comerciales y mutaciones de Inventario.
- [Contrato G4 Retail](https://github.com/Taller-SW-Web/G4-Retail-specs/blob/main/specs/api-contracts.md), `main`, commit `99fb06d`, §§4.2–4.3.
- [Matriz de scopes G7](https://github.com/Taller-SW-Web/Modulo-de-Seguridad/blob/main/docs/integracion/matriz-scopes.md), `main`, commit `c0e0b61`.
## DEC-F-015 — Información de conciliación visible a Retail

**Estado:** `PROPUESTA_G6`

### Enunciado

El consumidor Retail debe recibir solo la información necesaria para conocer el resultado de su conciliación. Cualquier mecanismo para recuperar posteriormente una operación debe definirse aparte; esta propuesta no afirma que Retail ya tenga una operación GET autorizada para consultar conciliaciones. La respuesta no debería revelar saldos internos de Inventario que Retail no necesita.

### Justificación

El OpenAPI G6 actual define `ConciliacionOfflineResponse` con resultado y datos de inventario por línea. La visibilidad de esa respuesta debe evaluarse junto con el uso de Retail y las autorizaciones de Seguridad, bajo mínimo privilegio y sin exponer información interna innecesaria.

### Diferencia explícita frente al contrato actual

En `contratos/http/openapi.yaml`, `ConciliacionOfflineResponse` incluye `operation_id`, `order_id`, `offline_sale_id`, `status`, `lines` y `completed_at`. Cada `ConciliacionOfflineLineaResultado` requiere `sku`, `location_id`, `requested_quantity`, `applied_quantity`, `unresolved_quantity`, `on_hand`, `reserved`, `blocked`, `available` y `stock_version`. En particular, `location_id`, `stock_version` y los saldos/cantidades internas (`on_hand`, `reserved`, `blocked`, `available`) deben evaluarse para evitar exposición innecesaria a Retail.

La propuesta difiere de ese contrato existente. No lo modifica ni cambia DTO, OpenAPI, política de autorización o lista de clientes permitidos. La modificación, si Marco la adopta, requiere revisión y aprobación contractual con los módulos concernidos antes de cualquier implementación.

### Invariantes propuestas

- El resultado de la conciliación informa su estado conforme a un contrato aprobado; no se presume que incluya un medio para recuperar una operación posteriormente.
- El mecanismo de recuperación o consulta posterior, su autorización y su contrato quedan pendientes de definición y aprobación. No se afirma que exista una operación GET autorizada para Retail.
- La respuesta no expone saldos internos o ubicación interna que no sean necesarios para ese propósito.
- El contrato vigente gobierna hasta que una modificación sea aprobada y publicada; esta propuesta no autoriza ignorarlo.
- La política de autorización se coordina con G7. La presencia de `inventario:conciliar-offline` en el OpenAPI G6 y `modulo-ventas` en la allowlist no prueba que Retail tenga acceso.

### Límites y pendientes

El mínimo de información, su representación, los cambios al DTO y el consumidor autorizado quedan pendientes de acuerdo contractual. No se proponen nuevos nombres de campos, valores de estado, scopes ni códigos de error. Debe resolverse también la contradicción entre el antecedente comunicado Retail→G6 y la operación actual limitada a `modulo-ventas`.

### Fuentes

- [OpenAPI G6](../../contratos/http/openapi.yaml), `ConciliacionOfflineResponse`, `ConciliacionOfflineLineaResultado` y `POST /inventario/conciliaciones-offline`.
- [Contrato G4 Retail](https://github.com/Taller-SW-Web/G4-Retail-specs/blob/main/specs/api-contracts.md), `main`, commit `99fb06d`.
- [Matriz de scopes G7](https://github.com/Taller-SW-Web/Modulo-de-Seguridad/blob/main/docs/integracion/matriz-scopes.md), `main`, commit `c0e0b61`.
