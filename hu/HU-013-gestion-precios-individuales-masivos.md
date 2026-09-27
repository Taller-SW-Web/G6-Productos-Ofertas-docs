# HU-013 — Historia de Usuario: Gestión de precios individuales y masivos

**Responsable:** Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** Spec [SPEC-013](../specs/SPEC-013-gestion-precios-individuales-masivos.md) | Flow [WF-013](../wireframes/flows/WF-013-gestion-precios-individuales-masivos.md)

---

## 1. Historia de Usuario Principal

| Parámetro | Detalle |
| :--- | :--- |
| **Rol (Como)** | Gestor Comercial |
| **Acción (Quiero)** | Actualizar y programar precios regulares y de oferta de productos (individualmente o mediante carga masiva de archivos CSV/XLSX), indicando obligatoriamente el motivo del cambio y consultando precios en fechas históricas |
| **Beneficio (Para)** | Mantener controlados los precios base y ofertas directas por contexto de venta, garantizando trazabilidad temporal, evitando valores inválidos y reduciendo errores operativos de cambios extraordinarios sin afirmar control de margen cuando no existe información de costo |

---

## 2. Criterios de Aceptación

| ID | Criterio |
| :---: | :--- |
| **CA-01** | **Seguridad y Permisos:** Los endpoints requieren autenticación y permisos de capacidad (`PRICING_READ`, `PRICING_WRITE`, `PRICING_BULK` según operación). La asignación de esos permisos a roles concretos pertenece a Seguridad y Usuarios. Peticiones no autorizadas responden `401`/`403`. |
| **CA-02** | **Modelo de Precios y Validaciones:** Cada producto gestiona `precio_regular` y opcionalmente `precio_oferta`. El sistema valida que: (a) el `precio_regular` sea un valor numérico estrictamente mayor a 0.00, y (b) si se define `precio_oferta`, este debe ser estrictamente mayor a 0.00 y menor al `precio_regular` (`precio_oferta < precio_regular`). |
| **CA-03** | **Actualización Individual y Motivo Obligatorio:** Permite modificar el precio regular u oferta enviando SKU, nuevos valores y el campo obligatorio `motivo_cambio`. Ante datos válidos, persiste los cambios en la tabla operativa, actualiza la fecha de modificación, responde en menos de 300 ms con HTTP `200 OK` y emite el evento asíncrono `pricing.price.changed`. Si falta el motivo, rechaza con HTTP `400 Bad Request`. |
| **CA-04** | **Programación y alcance:** Cada vigencia define `valid_from`, `valid_until` opcional, moneda y `channel_id` opcional (`null` = precio global). No se admiten intervalos superpuestos para el mismo SKU + canal + moneda + tipo de precio. Una vigencia futura queda `SCHEDULED` y se activa automáticamente cuando corresponde. |
| **CA-05** | **Consulta de Precio Histórico (As-Of):** Provee el endpoint `GET /api/v1/pricing/skus/{sku}/price?at={timestamp}` y una pantalla administrativa que consume ese contrato para retornar el precio oficial que tenía un SKU en una fecha y hora determinada del pasado basándose en la tabla de vigencias temporales. La consulta es de solo lectura. |
| **CA-06** | **Carga Masiva Atómica por Defecto (All-or-Nothing):** Permite CSV/XLSX con `sku`, `precio_regular`, `motivo_cambio` y opcionales `precio_oferta`, `channel_id`, vigencias y `price_version`. Si una fila es inválida, tiene versión obsoleta o genera solapamiento de vigencias, el lote se descarta en Pricing salvo modo parcial explícito. |
| **CA-07** | **Modo Tolerante Opcional en Carga Masiva:** Si la solicitud de carga masiva incluye el parámetro explícito `allow_partial=true`, el sistema persiste todas las filas válidas en una única transacción, descarta las filas inválidas, responde HTTP `207 Multi-Status` solo si el resultado se entrega en esa solicitud; el flujo asíncrono responde inicialmente HTTP `202` y expone éxito parcial y el reporte al finalizar con las filas rechazadas y su motivo de error. |
| **CA-08** | **Delimitación frente a Promociones:** Pricing es dueño de precios regulares/ofertas y sus scopes; Promociones decide combinabilidad de beneficios sin sobrescribir precios maestros. Combos recibe regular y precio público efectivo vigente para validar que el paquete siga siendo comercialmente conveniente. |
| **CA-09** | **Precio efectivo por SKU y canal:** el producto define precio base y una variante puede tener override. La resolución selecciona la vigencia aplicable al `channel_id` solicitado y, si no existe, usa el precio global (`channel_id=null`) según la regla definida. La consulta devuelve regular, oferta opcional, moneda, scope y vigencia por separado. |
| **CA-10** | La creación del precio base por Catálogo es idempotente; Pricing emite `pricing.price.changed` tras persistirla con `tipo_operacion=CREACION`, `precio_anterior=null` y `variacion_porcentual=null`. |
| **CA-11** | Pricing devuelve precio regular y precio de oferta separadamente junto con moneda, canal efectivo y vigencia; Promociones y Cupones evalúan las combinaciones expresamente permitidas por su política comercial sin que Pricing decida exclusividad; Combos recibe precio regular y precio público efectivo vigente para validar que el combo no sea más costoso que la compra individual de sus componentes. |
| **CA-12** | La importación exclusiva de Pricing aplica All-or-Nothing dentro de Pricing, sin prometer atomicidad global con Catálogo o Inventario; `pricing.price.changed` es un evento posterior al commit, no un comando. |
| **CA-13** | Una carga asíncrona devuelve inicialmente HTTP 202 y `batch_id`; HTTP 422/207 solo corresponde a un resultado de validación o procesamiento devuelto sincrónicamente. |
| CA-14 | La carga exclusiva de Pricing admite `accion_precio_oferta=CONSERVAR | ESTABLECER | ELIMINAR` y `price_version` para concurrencia optimista. Blanco no elimina oferta. Si el regular nuevo invalida una oferta conservada se rechaza la fila. El sistema calcula la variación porcentual respecto del precio vigente y muestra una advertencia reforzada cuando supera un umbral configurable de cambio extraordinario; la advertencia no sustituye reglas de aprobación externas si la empresa las incorpora. |
| CA-15 | Una actualización con `price_version` obsoleta se rechaza con conflicto y devuelve la versión vigente; no se sobrescribe silenciosamente un precio modificado después de la lectura/exportación. |

## 3. Escenarios (Dado - Cuando - Entonces / Gherkin)

### Escenario 1: Actualización exitosa de precio individual con motivo
* **Dado** que el gestor comercial autenticado visualiza el producto con SKU `NK-DEP-001` con precio regular de S/ 120.00,
* **Cuando** ingresa un nuevo precio regular de S/ 150.00 junto con el motivo "Ajuste tarifario proveedor",
* **Entonces** el sistema persiste el nuevo precio en el almacén operativo de Pricing, emite el evento asíncrono de cambio de precio conteniendo el motivo y retorna HTTP 200 con el mensaje "Precio actualizado exitosamente".

### Escenario 2: Rechazo por omisión de motivo obligatorio
* **Dado** que el gestor comercial intenta actualizar el precio del SKU `NK-DEP-001` a S/ 150.00,
* **Cuando** envía la solicitud dejando el campo de motivo vacío o nulo,
* **Entonces** el sistema rechaza la operación con código HTTP 400 Bad Request y no altera el precio en la base de datos.

### Escenario 3: Programación de precio con vigencia futura
* **Dado** que la fecha actual es `2026-10-15T09:00:00Z` y el gestor comercial programa para el SKU `AD-RUN-01` un precio de oferta de S/ 199.00 con inicio de vigencia `2026-11-20T00:00:00Z` y motivo "Campaña Cyber Days",
* **Cuando** confirma la operación,
* **Entonces** el sistema guarda el registro como `SCHEDULED` en la tabla de vigencias sin alterar el precio de venta actual y responde HTTP 201 Created.
* **Y cuando** el reloj del sistema alcanza `2026-11-20T00:00:00Z`, el worker activa el nuevo precio en la tabla operativa y notifica al bus de eventos.

### Escenario 4: Consulta de precio oficial en fecha pasada (As-Of)
* **Dado** que un cliente presenta un reclamo sobre una compra realizada el `2026-08-10T15:30:00Z` respecto al SKU `NK-DEP-001`,
* **Cuando** el gestor o servicio invoca `GET /api/v1/pricing/skus/NK-DEP-001/price?at=2026-08-10T15:30:00Z`,
* **Entonces** el sistema consulta el histórico de vigencias temporales y retorna HTTP 200 con el precio exacto vigente en ese instante (S/ 120.00) y su identificador de vigencia.

### Escenario 5: Carga masiva atómica rechazada por error puntual (All-or-Nothing)
* **Dado** que se carga un archivo de 500 filas en modo predeterminado (`allow_partial=false`), donde la fila 312 posee un precio de oferta mayor al regular,
* **Cuando** el sistema procesa el lote masivo,
* **Entonces** cancela la transacción completa, no actualiza ninguno de los otros 499 productos y genera un reporte detallando: "Fila 312: El precio de oferta no puede ser mayor o igual al regular".

### Escenario 6: Carga masiva con tolerancia a fallos (`allow_partial=true`)
* **Dado** un archivo de 100 filas con `allow_partial=true`, 98 válidas y 2 inválidas,
* **Cuando** se procesa mediante el flujo asíncrono de carga,
* **Entonces** la admisión responde HTTP `202` con `batch_id`; al finalizar, el lote queda en estado de éxito parcial, aplica las 98 filas válidas dentro de Pricing y expone un reporte de las 2 rechazadas. (Si existiese una variante síncrona del contrato que complete la operación dentro de la misma solicitud, puede responder HTTP `207 Multi-Status`).

---

### Escenario adicional: Primer precio sin valor anterior
* **Dado** un producto borrador sin precio histórico,
* **Cuando** Pricing procesa su inicialización autorizada,
* **Entonces** persiste el precio, emite el hecho confirmado con `tipo_operacion=CREACION` y valores previos/variación nulos, y confirma a Catálogo.

### Escenario adicional: Oferta como beneficio alternativo
* **Dado** un SKU con precio regular S/ 200 y oferta vigente S/ 180,
* **Cuando** una promoción automática del 15 % produciría S/ 170 sobre el regular,
* **Entonces** se selecciona S/ 170 sin descontar nuevamente sobre S/ 180.

### Escenario adicional: Eliminar oferta solo con acción explícita
* **Dado** un SKU con oferta S/ 170 y regular S/ 200,
* **Cuando** una carga exclusiva incluye `accion_precio_oferta=ELIMINAR` y `precio_oferta` vacío,
* **Entonces** Pricing retira la oferta, registra el cambio y publica el hecho solo después de persistir; si la acción se omite, conserva la oferta.

### Escenario adicional: Vigencias solapadas en el mismo canal
* **Dado** un precio programado para `MARKETPLACE` del 1 al 30 de noviembre,
* **Cuando** el gestor intenta registrar otra vigencia del mismo SKU, moneda y tipo de precio del 15 al 25 de noviembre,
* **Entonces** Pricing rechaza la superposición e indica el intervalo en conflicto.

### Escenario adicional: Variación extraordinaria de precio
* **Dado** un SKU con precio vigente S/ 999.00,
* **Cuando** el gestor propone S/ 9.99,
* **Entonces** el sistema muestra la variación porcentual y una advertencia reforzada antes de confirmar; no afirma que exista margen positivo porque Pricing no administra costos.

## 4. Matriz de Interacción con Otros Módulos

| Módulo | Necesidad de Interacción | Información que Recibe | Información que Entrega |
| :--- | :--- | :--- | :--- |
| **Canales de Venta (Marketplace, Chatbot, Retail)** | Consultar precios vigentes según el canal de la operación. | SKU/lista de SKUs, `channel_id`, moneda y timestamp de evaluación cuando corresponda. | Precio regular, oferta opcional, scope, vigencia y moneda. |
| **Ventas y Postventa** | Consultar precio histórico oficial para validación de órdenes o reclamos. | SKU del producto y fecha/hora exacta (`at`). | Precio oficial vigente en dicho instante temporal y regla que lo respaldaba. |
| **Seguridad y Usuarios** | Validar identidad y permisos de Pricing (`PRICING_READ`, `PRICING_WRITE`, `PRICING_BULK`); la asignación a roles concretos pertenece a Seguridad. | Token JWT de autenticación con claims/permisos. | Respuesta de autorización o denegación de acceso. |
| **Historial de Auditoría** | Registrar de forma asíncrona cada mutación de precio aplicada. | Evento con SKU, precios previos/nuevos, variación %, motivo, canal, batch_id, IP y usuario. | Confirmación de evento recibido. |

---

## 5. Dependencias del Dominio (Productos y Ofertas)

* **Gestión de productos:**
  * *Datos requeridos:* Validación de existencia activa del SKU en el catálogo.
  * *Propósito:* Evitar fijación de precios a artículos inexistentes.
* **Gestión de ofertas, promociones y cupones:**
  * *Datos requeridos:* `precio_regular` y `precio_oferta` actuales.
  * *Propósito:* Servir de base oficial sobre la cual se calculan descuentos adicionales de campañas o cupones.

---

## 6. Reglas de Negocio Resueltas

- [x] **Política de carga masiva:** Resuelta. Por defecto opera en modo atómico estricto (*All-or-Nothing*); solo permite actualización parcial si se provee el parámetro explícito `allow_partial=true`.
- [x] **Motivo de cambio:** Resuelto. El motivo es formalmente obligatorio en actualizaciones individuales y como columna requerida en cargas masivas.
