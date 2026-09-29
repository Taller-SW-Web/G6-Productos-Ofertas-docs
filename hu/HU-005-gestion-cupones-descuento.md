# HU-005 — Historia de Usuario: Gestión de cupones de descuento

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** Spec [SPEC-005](./specs/SPEC-005-gestion-cupones-descuento.md) | Flow [WF-005](./wireframes/flows/WF-005-gestion-cupones-descuento.md)

## Historia
**Como** gestor comercial, **quiero** crear cupones con código único, condiciones y límites opcionales asociados a una promoción `CUPON`, **para** habilitar beneficios mediante código sin duplicar la definición de la promoción.

## Criterios de aceptación
| ID | Criterio |
|---|---|
| CA-01 | Solo un usuario autorizado administra cupones. |
| CA-02 | Código normalizado único y promoción modalidad `CUPON`. |
| CA-03 | Duplicado rechazado con `CUPON_DUPLICADO`. |
| CA-04 | Descuento, alcance y vigencia provienen de la promoción. |
| CA-05 | Monto mínimo opcional; si existe, > 0. |
| CA-06 | Límites global y por cliente opcionales; enteros positivos cuando existan. |
| CA-07 | No se reducen por debajo de consumos existentes. |
| CA-08 | Si ambos existen, límite cliente <= límite global. |
| CA-09 | `Sin límite` se distingue de un valor numérico; vacío no se convierte en 1. |
| CA-10 | Validar no consume. |
| CA-11 | Consumir depende del beneficio final y confirmación contractual de Ventas/Postventa. |
| CA-12 | Reintento del mismo `order_id + cupon_id` no duplica consumo. |
| CA-13 | La concurrencia no supera límites. |
| CA-14 | La cancelación homologada restituye o conserva según política. |
| CA-15 | Combinabilidad heredada de la promoción. |
| CA-16 | Los resultados publicados son `promotions.coupon.consumption.completed|rejected`; el comando iniciador sigue pendiente. |

## Escenarios
### 1. Crear
DADO una promoción `CUPON`, CUANDO se registra un código único y condiciones válidas, ENTONCES se crea el cupón.

### 2. Duplicado normalizado
DADO `DEPORTE10`, CUANDO se intenta ` deporte10 `, ENTONCES se normaliza, se rechaza y el error usa `CUPON_DUPLICADO`.

### 3. Validación
DADO un cupón aplicable, CUANDO se valida, ENTONCES devuelve el beneficio sin consumir.

### 4. Sin límite por cliente
DADO `max_usos_por_cliente=null`, CUANDO se consulta o edita, ENTONCES la interfaz muestra `Sin límite` y no fuerza `1`.

### 5. Consumo idempotente
DADO un cupón seleccionado, CUANDO la misma confirmación se reprocesa, ENTONCES se registra un solo uso.

### 6. Último uso concurrente
DADO un único uso restante, CUANDO dos pedidos compiten, ENTONCES como máximo uno lo consume.

### 7. Cancelación
DADO política `RESTAURAR_EN_CANCELACION`, CUANDO Ventas/Postventa comunica una cancelación homologada, ENTONCES se restaura una sola vez.

## Interacción
Marketplace, Chatbot y Retail validan; Ventas/Postventa consolida/restituye; Seguridad autoriza administración.

## Dependencias internas
Promociones aporta beneficio/vigencia/combinabilidad; Productos identifica ítems; Pricing aporta base monetaria.
