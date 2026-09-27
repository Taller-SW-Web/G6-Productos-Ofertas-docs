# HU-006 — Historia de Usuario: Gestión de ofertas y promociones

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** Spec [SPEC-006](../specs/SPEC-006-gestion-ofertas-promociones.md) | Flow [WF-006](../wireframes/flows/WF-006-gestion-ofertas-promociones.md)

Responsabilidad: Persona 4 — Axel Cueva.
Versión corregida: 2026-09-15.

## Funcionalidad

Gestión de ofertas y promociones — Obligatoria.

## Historia de usuario

**Como** gestor comercial,
**quiero** configurar ofertas y promociones indicando los productos o SKUs participantes, el descuento, su vigencia y estado,
**para** ofrecer precios promocionales que los canales de venta puedan consultar y aplicar correctamente.

## Reglas de negocio consolidadas

- Una promoción puede usar descuento por **porcentaje** o por **monto fijo**.
- El porcentaje debe ser mayor que 0 y menor o igual que 100.
- El monto fijo debe ser mayor que 0 y se descuenta **una sola vez sobre el subtotal elegible de la evaluación**, nunca por unidad.
- El descuento nunca puede producir un importe resultante negativo.
- Una promoción solo participa en una evaluación si está activa, vigente y aplica a los productos evaluados.
- Cada promoción define `prioridad`, alcance de `canales` y una **política de combinabilidad**. El evaluador construye únicamente combinaciones compatibles y, entre ellas, selecciona la de menor importe final; la prioridad resuelve empates o precedencias comerciales configuradas.
- Si coinciden promoción automática, cupón u oferta de Pricing, se evalúan únicamente las **combinaciones permitidas** por sus políticas. Si son exclusivas, se compara el importe final y se selecciona la alternativa válida correspondiente; si son combinables, pueden coexistir sin aplicar dos veces el mismo beneficio.
- Un cupón solo consume un uso si finalmente fue el beneficio seleccionado y el pedido fue confirmado.
- Modificar o desactivar una promoción no altera descuentos ya registrados en pedidos confirmados.
- Al crear una promoción, el gestor debe indicar su estado inicial: **ACTIVA** o **INACTIVA**.

**Decisión de interfaz:** la evaluación de beneficios continúa siendo una capacidad de negocio consumida por canales/venta mediante API; no existe una pantalla administrativa independiente «Evaluar compra».

## Criterios de aceptación

| ID | Criterio |
| --- | --- |
| CA-01 | Solo un gestor comercial con permisos puede crear, modificar, activar o desactivar promociones. |
| CA-02 | Para registrar una promoción se debe indicar nombre, al menos un producto o SKU participante, tipo/valor de descuento, fecha y hora de inicio y fin, modalidad `AUTOMATICA` o `CUPON`, estado inicial, `prioridad`, canales aplicables y política de combinabilidad. |
| CA-03 | Los productos o SKUs seleccionados deben existir y estar activos. El inicio debe ser anterior al fin; el porcentaje debe ser mayor que 0 y hasta 100 %, y el monto fijo debe ser mayor que 0. |
| CA-04 | El gestor puede consultar el listado y el detalle de las promociones, modificar sus condiciones y activarlas o desactivarlas. |
| CA-05 | Una promoción solo se aplica si está activa, dentro de su vigencia y corresponde a los productos evaluados. |
| CA-06 | El descuento se calcula sobre la base monetaria definida para cada SKU elegible. La oferta propia de Pricing participa según la política de combinabilidad. El monto fijo se aplica una sola vez al subtotal elegible y ningún descuento puede producir un importe negativo. |
| CA-07 | Si existen varias promociones automáticas válidas, el sistema evalúa solo las combinaciones permitidas por sus políticas. Entre las combinaciones válidas selecciona la de menor importe final; la `prioridad` configurada se utiliza para desempates o precedencias definidas. |
| CA-08 | La evaluación devuelve la promoción aplicada, el importe original, el descuento y el importe resultante; si no corresponde aplicarla, informa el motivo. |
| CA-09 | Modificar o desactivar una promoción no altera los descuentos ya registrados en pedidos confirmados. |
| CA-10 | Promociones, cupones y la oferta propia de Pricing se combinan únicamente cuando sus políticas lo permiten. Una promoción puede declararse `EXCLUSIVE` o compatible con clases de beneficio específicas; el motor no aplica una regla global de no-stacking. |
| CA-11 | Una promoción puede configurarse a nivel producto (aplica a sus SKUs vendibles activos) o a nivel SKU específico. |
| CA-12 | La modalidad `AUTOMATICA` o `CUPON` es obligatoria y visible en consulta. Una promoción CUPON nunca se aplica sin código asociado validado. |
| CA-13 | La modalidad solo puede editarse en promoción inactiva nunca activada y sin cupones asociados ni usos históricos; en otros casos se crea otra promoción. |
| CA-14 | Pricing devuelve regular/oferta por SKU separadamente. La evaluación usa bases monetarias explícitas y la oferta de Pricing participa como beneficio según la política de combinabilidad, evitando descuentos duplicados o bases ambiguas. |
| CA-15 | La evaluación considera el canal solicitante (`MARKETPLACE`, `CHATBOT`, `RETAIL` u otro homologado) y excluye promociones no habilitadas para él. La validación no consume cupón; confirmaciones provisionales de Ventas generan consumo aceptado o rechazo idempotente y Ventas/Postventa resuelve el pedido. |

## Escenarios dado-cuando-entonces

### Escenario 1: Registrar una promoción válida

* **DADO** que el gestor comercial tiene permisos y existen productos activos,
* **CUANDO** registra una promoción con productos participantes, descuento válido, fechas correctas y estado inicial,
* **ENTONCES** el sistema guarda la promoción, confirma la operación y la muestra en el listado con el estado indicado.

### Escenario 2: Rechazar una configuración inválida

* **DADO** que el gestor comercial está registrando una promoción,
* **CUANDO** ingresa un porcentaje superior al 100 %, un monto fijo menor o igual a 0, una fecha final igual o anterior al inicio o no selecciona productos,
* **ENTONCES** el sistema impide guardar, identifica los errores y conserva los datos para corregirlos.

### Escenario 3: Aplicar una promoción vigente

* **DADO** que un producto cuesta S/ 200 y tiene una promoción activa y vigente del 15 %,
* **CUANDO** un canal solicita evaluar el precio para una unidad del producto,
* **ENTONCES** el sistema devuelve el precio original de S/ 200, el descuento de S/ 30 y el precio resultante de S/ 170.

### Escenario 4: Aplicar un monto fijo sin producir un importe negativo

* **DADO** que el subtotal elegible es S/ 30 y existe una promoción válida de monto fijo S/ 50,
* **CUANDO** el sistema calcula el beneficio,
* **ENTONCES** limita el descuento a S/ 30 y devuelve un importe resultante de S/ 0.

### Escenario 5: Elegir la mejor promoción

* **DADO** que para una compra existen promociones válidas con políticas de combinación conocidas,
* **CUANDO** el sistema evalúa las combinaciones permitidas,
* **ENTONCES** aplica la combinación válida de menor importe final; si son mutuamente exclusivas, conserva únicamente la alternativa ganadora.

### Escenario 6: Resolver promoción automática y cupón

* **DADO** que una promoción automática y un cupón válido participan en la misma compra,
* **CUANDO** el canal solicita evaluar ambos beneficios,
* **ENTONCES** el sistema respeta su política de combinabilidad: los acumula solo si está permitido; de lo contrario selecciona la alternativa válida de menor importe final.

### Escenario 7: Excluir una promoción fuera de vigencia

* **DADO** que una promoción todavía no inicia o ya finalizó,
* **CUANDO** un canal solicita evaluar su aplicación,
* **ENTONCES** el sistema no aplica el descuento e informa que está fuera de vigencia.

### Escenario 8: Desactivar una promoción

* **DADO** que existe una promoción activa,
* **CUANDO** el gestor comercial la desactiva,
* **ENTONCES** deja de aplicarse en nuevas evaluaciones y se conservan los descuentos de pedidos ya confirmados.

### Escenario 9: Promoción por cupón sin código
* **DADO** una promoción vigente de modalidad CUPON,
* **CUANDO** se evalúa una compra sin presentar un código válido que la referencie,
* **ENTONCES** la promoción no se aplica automáticamente.

### Escenario 10: Oferta propia de Pricing sin acumulación
* **DADO** un SKU de precio regular S/ 200 y oferta vigente S/ 180, con promoción automática del 15 %,
* **CUANDO** se comparan alternativas sobre el regular,
* **ENTONCES** se aplica S/ 170 y nunca 15 % adicional sobre S/ 180.

## Interacción con otros módulos

| Módulo | Necesidad de interacción | Información que recibe esta funcionalidad | Información que entrega esta funcionalidad |
| --- | --- | --- | --- |
| Marketplace | Mostrar ofertas y evaluar descuentos en la compra. | Productos, cantidades y, cuando corresponda, cupón presentado. | Promoción seleccionada, condiciones y desglose de importes. |
| Chatbot | Responder consultas sobre ofertas y promociones. | Productos consultados y cantidades. | Descripción de ofertas, vigencia y precios promocionales. |
| Retail | Aplicar promociones en la venta asistida. | Productos, cantidades y, cuando corresponda, cupón presentado. | Beneficio seleccionado y descuento calculado. |
| Ventas y Postventa | Validar y conservar el descuento del pedido. | Productos, cantidades, identificador del beneficio aplicado y pedido. | Resultado de validación y desglose del descuento para registrar en el pedido. |
| Seguridad y Usuarios | Autorizar la administración. | Identidad autenticada y permisos. | Solicitudes de validación cuando lo requiera el mecanismo acordado. |

## Dependencias internas

| Funcionalidad | Información necesaria |
| --- | --- |
| Gestión de Productos — Persona 2 | Identificadores, nombres y estados de los productos. |
| Gestión de Precios — Persona 3 | Precios vigentes de los productos. |
| Gestión de Cupones | Cupón válido y beneficio calculado cuando el cliente presenta un código. |

## Condiciones de integración

Las integraciones se realizan mediante APIs, de forma asíncrona y sin acceso directo a las bases de datos de otros módulos. Los contratos y mecanismos concretos se coordinan con los equipos involucrados.
