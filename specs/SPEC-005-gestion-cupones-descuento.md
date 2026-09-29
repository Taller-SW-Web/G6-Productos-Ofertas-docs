# SPEC-005 — Especificación: Gestión de cupones de descuento

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** HU [HU-005](./hu/HU-005-gestion-cupones-descuento.md) | Wireframe [WF-005](./wireframes/flows/WF-005-gestion-cupones-descuento.md)

## 1. Contexto
La gestión de cupones administra códigos que habilitan promociones configuradas con modalidad `CUPON`. El cupón no duplica descuento, alcance ni vigencia: esos datos pertenecen a la promoción asociada.

## 2. Propósito
Permitir al Gestor Comercial administrar cupones y permitir a los canales validarlos y consumirlos de forma segura.

## 3. Modelo consolidado
El cupón contiene código, estado, referencia a promoción `CUPON`, monto mínimo opcional, límite global opcional, límite por cliente opcional, política de restitución, contadores de uso y auditoría.

La promoción asociada contiene descuento, productos elegibles, vigencia y política de combinación.

## 4. Alcance
Incluye alta, consulta, modificación, activación/desactivación, validación sin consumo, consumo idempotente, límites opcionales, concurrencia segura, restitución según política y consulta de usos.

## 5. Requisitos

### Requisito 1: Registrar y normalizar código
El código se normaliza con `trim` + mayúsculas y acepta `A-Z`, `0-9`, `-`, `_`. La unicidad se evalúa sobre el valor normalizado.

Si ya existe, el backend responde conflicto en `application/problem+json` con:

```text
code = CUPON_DUPLICADO
```

Los consumidores dependen de `status` + `code`, no de `detail`.

### Requisito 2: Promoción asociada
Debe existir, estar en modalidad `CUPON`, activa, vigente y ser aplicable a los productos evaluados.

### Requisito 3: Monto mínimo
Es opcional; cuando existe debe ser mayor que 0.

### Requisito 4: Límites de uso
`max_usos_global` y `max_usos_por_cliente` son opcionales. Si se informan deben ser enteros positivos.

No se permite reducirlos por debajo de consumos existentes. Si ambos existen, `max_usos_por_cliente <= max_usos_global`. Si existe límite por cliente, la validación requiere `customer_ref`.

**La ausencia del límite por cliente significa “Sin límite”; nunca equivale automáticamente a 1.**

### Requisito 5: Validar sin consumir
La validación devuelve validez, motivo de rechazo cuando aplique, promoción/beneficio, descuento e importe resultante. No incrementa contadores.

### Requisito 6: Consumir uso
El uso se consume solo cuando el cupón forma parte del beneficio finalmente seleccionado y Ventas/Postventa confirma contractualmente la consolidación. El consumo actualiza contador global y por cliente, cuando aplique, en una transacción local.

### Requisito 7: Idempotencia
`order_id + cupon_id` identifica un consumo. Reintentos no incrementan nuevamente.

### Requisito 8: Concurrencia
La competencia por los últimos usos nunca puede superar el límite configurado.

### Requisito 9: Combinabilidad
La combinación con promociones/oferta de Pricing se rige por `politica_combinacion` de la promoción asociada. El cupón consume solo si pertenece a la alternativa ganadora.

### Requisito 10: Cancelación
`RESTAURAR_EN_CANCELACION` restituye idempotentemente el uso cuando Ventas/Postventa comunica una cancelación homologada aplicable. `NO_RESTAURAR` conserva el consumo.

Cupones no decide el estado del pedido ni procesa reembolsos.

### Requisito 11: Consulta administrativa
Debe mostrar código, promoción, estado, monto mínimo, límites, política de restitución, usos consumidos y usos disponibles cuando exista límite.

### Requisito 12: Integración asíncrona
El contrato actual publica los resultados:

```text
promotions.coupon.consumption.completed
promotions.coupon.consumption.rejected
```

El nombre/payload definitivo del comando de Ventas/Postventa que inicia el consumo sigue pendiente de homologación. La documentación anterior utilizaba un nombre provisional ligado a la confirmación del pedido; **ese nombre no se considera contrato definitivo**.

## 6. Requisitos no funcionales
- Administración autenticada/autorizada.
- Consumo atómico e idempotente.
- Errores `application/problem+json` con `code` estable y `correlationId`.
- Sin acceso directo a bases de datos de otros módulos.

## 7. Fuera de alcance
- Definir descuento, alcance o vigencia.
- Procesar pago, devolución o reembolso.
- Consumir/restaurar usos manualmente desde el backoffice.

## Criterio de completitud
La capacidad queda alineada cuando `CUPON_DUPLICADO` está formalizado, los límites son opcionales, validar no consume y el iniciador externo no se presenta como homologado hasta cerrar el contrato con Ventas/Postventa.
