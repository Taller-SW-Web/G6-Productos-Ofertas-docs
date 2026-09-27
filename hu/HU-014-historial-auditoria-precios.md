# HU-014 — Historia de Usuario: Historial de auditoría de precios

**Responsable:** Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** Spec [SPEC-014](../specs/SPEC-014-historial-auditoria-precios.md) | Flow [WF-014](../wireframes/flows/WF-014-historial-auditoria-precios.md)

---

## 1. Historia de Usuario Principal

| Parámetro | Detalle |
| :--- | :--- |
| **Rol (Como)** | Usuario autorizado para auditoría de precios (permisos asignados por Seguridad y Usuarios) |
| **Acción (Quiero)** | Registrar de forma automática e inmutable cada cambio de precio con su contrato completo y consultar o exportar el historial cronológico (en CSV o PDF) con filtros por SKU, usuario, fechas, canal y lote |
| **Beneficio (Para)** | Contar con trazabilidad de cambios de precio para control operativo, auditoría y soporte de obligaciones aplicables, sujetas a las políticas y validaciones legales correspondientes |

---

## 2. Criterios de Aceptación

| ID | Criterio |
| :---: | :--- |
| **CA-01** | **Captura Asíncrona y Desacoplada:** Toda modificación exitosa de precios (individual o masiva) debe capturarse mediante eventos asíncronos (`pricing.price.changed`). La captura y persistencia en la bitácora no debe añadir más de 50 ms a la operación de precios del microservicio emisor. |
| **CA-02** | **Contrato Completo de Auditoría:** Cada registro de auditoría debe persistir de forma mandatoria: `id_auditoria`, `sku`, `product_id`, `tipo_precio` (`REGULAR` u `OFERTA`), `precio_anterior` (nulo en CREACION), `precio_nuevo` (nulo en RETIRO_OFERTA), `variacion_porcentual` (nula en CREACION o RETIRO_OFERTA), `tipo_operacion`, `motivo_cambio`, `canal_origen` (`BACKOFFICE`, `BULK_IMPORT`, `API`), `batch_id` (obligatorio si provino de lote masivo, `null` si fue individual), `usuario_id`, `usuario_email`, `ip_origen` (evaluando `X-Forwarded-For` o `X-Real-IP`) y `timestamp` (UTC). |
| **CA-03** | **Omisión ante Operaciones Fallidas:** Si una actualización de precio es rechazada por regla de negocio, falta de motivo obligatorio o error transaccional, no se emite el evento y la auditoría no genera ningún registro. Solo se auditan cambios efectivamente persistidos. |
| **CA-04** | **Inmutabilidad Estricta (Append-Only):** El almacén de auditoría solo admite operaciones `INSERT` y `SELECT`. Todo intento de invocar `PUT`, `PATCH` o `DELETE` sobre las rutas de auditoría debe ser rechazado inmediatamente con HTTP `405 Method Not Allowed` o `403 Forbidden`. |
| **CA-05** | **Consulta y Filtrado Multicriterio:** Provee endpoints para consultar cronológicamente el log en orden descendente, permitiendo filtrar por: `sku`, rango de fechas/horas (`fecha_desde` / `fecha_hasta`), identificador o email de usuario, `canal_origen` y `batch_id`. |
| **CA-06** | **Paginación y Tiempos de Respuesta:** La consulta debe ser paginada y responder en menos de 800 ms. Si no existen registros para los filtros seleccionados, retorna HTTP `200 OK` con un arreglo vacío (`[]`) y total de elementos 0, mostrando en interfaz: "No se registraron cambios de precio bajo los criterios seleccionados". |
| **CA-07** | **Exportación de Registros (CSV y PDF):** Permite exportar los registros consultados. La exportación en formato **CSV** soporta hasta 100,000 filas para análisis masivo; la exportación en **PDF** está restringida a un máximo de 500 registros para reportes ejecutivos de control con membrete oficial. |
| **CA-08** | **Seguridad y Accesos:** La consulta/exportación requiere permisos `PRICING_AUDIT_READ` y `PRICING_AUDIT_EXPORT` según operación. Seguridad y Usuarios decide qué roles reciben esos permisos; Auditoría no crea ni administra roles propios. |
| **CA-09** | **Política de Retención y Archivado:** La retención se configura mediante `AUDIT_HOT_RETENTION_MONTHS` y `AUDIT_ARCHIVE_RETENTION_YEARS`. Para el MVP los valores iniciales son 24 meses en almacenamiento caliente y 5 años adicionales de archivo. Estos valores son configuración administrativa y no se presentan como obligación legal universal. El archivado verifica integridad/recuperabilidad antes de retirar la copia caliente. |
| CA-10 | La creación inicial de precio regular o de una nueva oferta registra `tipo_operacion=CREACION`, precio anterior y variación nulos; los cambios entre importes existentes son `MODIFICACION`. Retirar una oferta registra `RETIRO_OFERTA`, precio nuevo y variación nulos, sin confundir «sin oferta» con precio cero. |
| CA-11 | Duplicados del mismo `event_id` no producen auditorías repetidas; la bitácora nunca modifica precios. |
| CA-12 | El archivado mensual respeta los parámetros de retención configurados, verifica integridad y recuperabilidad antes del retiro y conserva evidencia de la política aplicada. Los valores MVP iniciales son 24 meses en caliente y cinco años adicionales en frío. |

## 3. Escenarios (Dado - Cuando - Entonces / Gherkin)

### Escenario 1: Registro de auditoría con contrato completo
* **Dado** que el gestor comercial autenticado con ID `usr_204`, email `gestor@tienda.com` y desde la IP `200.48.85.10` modifica en el Backoffice el precio regular del SKU `AD-ZAP-09` de S/ 200.00 a S/ 250.00 indicando el motivo "Ajuste de margen",
* **Cuando** el microservicio de precios completa la mutación con éxito,
* **Entonces** el sistema persiste en la bitácora un registro con: `sku: "AD-ZAP-09"`, `tipo_precio: "REGULAR"`, `precio_anterior: 200.00`, `precio_nuevo: 250.00`, `variacion_porcentual: +25.00%`, `motivo_cambio: "Ajuste de margen"`, `canal_origen: "BACKOFFICE"`, `batch_id: null`, `usuario_id: "usr_204"`, `usuario_email: "gestor@tienda.com"`, `ip_origen: "200.48.85.10"` y timestamp en UTC, sin demorar la respuesta al gestor en más de 50 ms.

### Escenario 2: Omisión de registro ante cambio fallido
* **Dado** que un gestor intenta ingresar un precio de oferta de S/ 100.00 cuando el regular es de S/ 90.00,
* **Cuando** la validación de negocio bloquea la solicitud y retorna HTTP 400,
* **Entonces** no se publica ningún evento y el sistema no persiste ningún registro en el historial de auditoría.

### Escenario 3: Trazabilidad de cambio masivo por lote
* **Dado** que se ejecuta una carga masiva mediante un archivo CSV generando el lote `batch_id: BATCH-3301` por el usuario `admin@tienda.com` desde la IP `190.236.14.88`,
* **Cuando** el lote es procesado y aplicado,
* **Entonces** se genera una entrada de auditoría individual por cada SKU actualizado con `canal_origen: "BULK_IMPORT"`, el motivo consignado en el archivo y el identificador `batch_id: BATCH-3301`.

### Escenario 4: Exportación de resultados a CSV
* **Dado** que un auditor comercial filtra las variaciones de precios de los últimos 6 meses obteniendo 12,400 registros,
* **Cuando** selecciona la opción "Exportar a CSV",
* **Entonces** el sistema genera de forma asíncrona el archivo `.csv` con todas las columnas del contrato de auditoría y provee el enlace de descarga correspondiente.

### Escenario 5: Exportación a PDF restringida a 500 registros
* **Dado** que un auditor aplica un filtro que arroja 650 registros e intenta exportar directamente a formato PDF,
* **Cuando** el sistema evalúa la solicitud de exportación,
* **Entonces** bloquea la generación indicando el mensaje: "La exportación en PDF admite un máximo de 500 registros. Por favor acote el rango de búsqueda o utilice la exportación en CSV".

### Escenario 6: Inmutabilidad de la bitácora
* **Dado** que un usuario intenta enviar una solicitud `DELETE` o `PUT` al endpoint `/api/v1/auditoria-precios/8f3b2d12`,
* **Cuando** el servidor de auditoría recibe la petición,
* **Entonces** deniega inmediatamente la acción con código HTTP 405 Method Not Allowed, preservando la inmutabilidad de la bitácora.

---

### Escenario 7: Registro del precio inicial
* **Dado** un producto nuevo sin precio anterior,
* **Cuando** Pricing confirma su primera inicialización,
* **Entonces** Auditoría inserta una sola entrada `CREACION` con precio anterior y variación nulos.

### Escenario 8: Archivo fallido
* **Dado** un lote elegible para archivado,
* **Cuando** la verificación del Parquet falla,
* **Entonces** no se retiran los registros operativos ni se modifica su contenido.

### Escenario adicional: Retiro auditable de oferta
* **Dado** un SKU con oferta S/ 170 vigente y un gestor autorizado que ejecuta `accion_precio_oferta=ELIMINAR`,
* **Cuando** Pricing confirma el retiro y emite `pricing.price.changed`,
* **Entonces** Auditoría inserta un único registro con `tipo_precio=OFERTA`, `tipo_operacion=RETIRO_OFERTA`, `precio_anterior=170`, `precio_nuevo=null` y `variacion_porcentual=null`, conservando intacto el histórico.

## 4. Matriz de Interacción con Otros Módulos

| Módulo | Necesidad de Interacción | Información que Recibe | Información que Entrega |
| :--- | :--- | :--- | :--- |
| **Gestión de Precios** | Disparar el registro de auditoría ante cada cambio efectivo. | Evento `pricing.price.changed` con el contrato completo de auditoría. | Confirmación de recepción / ACK en el bus de eventos. |
| **Seguridad y Usuarios** | Validar identidad y permisos `PRICING_AUDIT_READ` / `PRICING_AUDIT_EXPORT`; la asignación a roles pertenece a Seguridad. | Token JWT con claims/permisos. | Denegación o autorización de visualización/exportación. |
| **Ventas y Postventa** | Esclarecer discrepancias de precios reportadas en reclamos o auditorías de ventas. | SKU y rango de fechas de consulta. | Trazabilidad del precio vigente, motivo del cambio y actor responsable. |

---

## 5. Dependencias del Dominio (Productos y Ofertas)

* **Gestión de precios (Emisor):**
  * *Datos requeridos:* Evento con SKU, product_id, tipo de precio, precios previo y nuevo, variación %, motivo, canal, batch_id, IP y usuario.
  * *Propósito:* Garantizar el desacoplamiento de la persistencia de auditoría sin penalizar la latencia operativa.
* **Gestión de productos:**
  * *Datos requeridos:* Identificador único y SKU para validar consistencia en la búsqueda.

---

## 6. Reglas de Negocio Resueltas

- [x] **Contrato interno completo:** Resuelto. Se capturan `canal_origen`, `motivo_cambio`, `batch_id` y `variacion_porcentual` (nula en CREACION o RETIRO_OFERTA, cuando no existe importe de referencia o final); no se afirma homologación con módulos externos.
- [x] **Formatos de exportación:** Resuelto. CSV habilitado hasta 100,000 registros y PDF limitado a 500 filas para reportes ejecutivos.
- [x] **Retención y archivado:** Resuelto. Valores iniciales del MVP: 24 meses completos en base operativa (`AUDIT_HOT_RETENTION_MONTHS`), archivado mensual verificado en Parquet y cinco años adicionales (`AUDIT_ARCHIVE_RETENTION_YEARS`), sujetos a configuración administrativa.
