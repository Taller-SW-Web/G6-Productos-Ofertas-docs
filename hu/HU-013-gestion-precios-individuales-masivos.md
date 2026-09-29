# HU-013 — Historia de Usuario: Gestión de precios individuales y masivos

**Responsable:** Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** Spec [SPEC-013](./specs/SPEC-013-gestion-precios-individuales-masivos.md) | Flow [WF-013](./wireframes/flows/WF-013-gestion-precios-individuales-masivos.md)

## 1. Historia de usuario principal

| Parámetro | Detalle |
|---|---|
| **Como** | Gestor Comercial |
| **Quiero** | Consultar, actualizar y programar precios regulares/ofertas, consultar precios históricos y cargar archivos de precios |
| **Para** | Mantener precios oficiales consistentes, trazables y vigentes por producto/SKU, tiempo y canal |

## 2. Criterios de aceptación

| ID | Criterio |
|---|---|
| **CA-01** | Las operaciones requieren autenticación/autorización. `PRICING_READ`, `PRICING_WRITE` y `PRICING_BULK` se consideran nombres propuestos mientras Seguridad no los publique oficialmente. El contrato estable de denegación usa 401/403. |
| **CA-02** | `precio_regular > 0`; si existe oferta, `0 < precio_oferta < precio_regular`. |
| **CA-03** | Actualizar precio exige `motivo_cambio` y, cuando parte de lectura previa, `price_version`. Un conflicto de versión no sobrescribe el precio vigente. |
| **CA-04** | Una vigencia define `valid_from`, `valid_until` opcional, moneda y `channel_id` opcional; `null` significa precio global. |
| **CA-05** | No se permiten intervalos superpuestos para el mismo objetivo, tipo de precio, moneda y canal. |
| **CA-06** | `GET /api/v1/precios/skus/{sku}?at={timestamp}` devuelve el precio oficial de ese instante. `canal` es opcional; sin canal se resuelve el precio global. |
| **CA-07** | La respuesta de precio identifica regular, oferta opcional, moneda, `channel_id` efectivo o `null`, vigencia, `price_version`, `vigencia_id` y origen producto/override. |
| **CA-08** | Producto simple usa el precio de su producto; variante sin override hereda; variante con override usa el precio propio del SKU. |
| **CA-09** | La carga exclusiva de Pricing acepta CSV/XLSX y opera en modo All-or-Nothing por defecto. |
| **CA-10** | `allow_partial=true` aplica filas válidas y reporta inválidas dentro del resultado final del lote; el resultado parcial se consulta en el estado del proceso asíncrono. |
| **CA-11** | Prevalidar archivo responde 200; crear lote asíncrono responde 202 + `batch_id`; el estado final se consulta posteriormente. |
| **CA-12** | `accion_precio_oferta` usa `CONSERVAR | ESTABLECER | ELIMINAR`; blanco conserva la oferta y nunca la elimina por sí solo. |
| **CA-13** | Una oferta conservada incompatible con un nuevo regular provoca rechazo de la fila. |
| **CA-14** | Pricing publica `pricing.price.changed` solo después de persistir el cambio. |
| **CA-15** | El primer precio se registra como creación con valores previos/variación nulos. El comando Catálogo → Pricing inicial todavía debe formalizarse en AsyncAPI. |
| **CA-16** | Promociones/Cupones decide combinabilidad; Pricing no modifica ni evalúa reglas promocionales. |
| **CA-17** | La carga exclusiva de Pricing no promete atomicidad global con Catálogo/Inventario. |
| **CA-18** | 5,000 filas es benchmark de rendimiento, no límite de rechazo contractual mientras no se formalice lo contrario. |
| **CA-19** | Una variación extraordinaria puede generar advertencia reforzada; no se afirma control de margen porque Pricing no conoce costos. |

## 3. Escenarios

### Escenario 1: Actualizar precio

- **DADO** un SKU con regular S/ 120 y versión vigente
- **CUANDO** el gestor solicita S/ 150 con motivo y versión correctos
- **ENTONCES** se persiste, se incrementa versión y se publica el hecho después del commit.

### Escenario 2: Rechazar motivo ausente

- **DADO** un nuevo precio válido
- **CUANDO** falta `motivo_cambio`
- **ENTONCES** se rechaza con HTTP 400 sin modificar el precio.

### Escenario 3: Conflicto de versión

- **DADO** una lectura antigua
- **CUANDO** el gestor guarda con `price_version` obsoleta
- **ENTONCES** se rechaza con conflicto y se conserva la versión vigente.

### Escenario 4: Programación futura

- **DADO** una vigencia futura válida
- **CUANDO** el gestor confirma
- **ENTONCES** se crea una programación `SCHEDULED` sin cambiar el precio actual.

### Escenario 5: Vigencia superpuesta

- **DADO** una programación existente
- **CUANDO** otra se solapa en el mismo scope
- **ENTONCES** se rechaza y se conserva la existente.

### Escenario 6: Consulta histórica

- **DADO** un SKU con cambios de precio históricos
- **CUANDO** se invoca `GET /api/v1/precios/skus/{sku}?at={timestamp}`
- **ENTONCES** se devuelve el precio de ese instante y su `vigencia_id`.

### Escenario 7: Consulta global sin canal

- **DADO** un SKU con precio global
- **CUANDO** se consulta sin `canal`
- **ENTONCES** la respuesta puede indicar `channel_id=null`.

### Escenario 8: Fallback de canal

- **DADO** una consulta para `RETAIL`
- **Y** no existe una vigencia específica para Retail
- **CUANDO** se resuelve el precio
- **ENTONCES** se utiliza el precio global vigente.

### Escenario 9: Lote atómico con error

- **DADO** un archivo con `allow_partial=false`
- **Y** al menos una fila inválida
- **CUANDO** termina el procesamiento
- **ENTONCES** ninguna fila se aplica y el lote ofrece el reporte.

### Escenario 10: Lote tolerante

- **DADO** un archivo con `allow_partial=true`
- **Y** filas válidas e inválidas
- **CUANDO** termina el procesamiento
- **ENTONCES** se aplican las válidas y se reportan las inválidas.

### Escenario 11: Admisión asíncrona

- **DADO** un archivo prevalidado
- **CUANDO** se crea la importación
- **ENTONCES** se responde `202 Accepted` + `batch_id` y el resultado se consulta después.

### Escenario 12: Conservar oferta

- **DADO** regular S/ 200 y oferta S/ 170
- **CUANDO** la fila deja `precio_oferta` y `accion_precio_oferta` vacíos
- **ENTONCES** se conserva la oferta S/ 170.

### Escenario 13: Eliminar oferta

- **DADO** una oferta vigente
- **CUANDO** `accion_precio_oferta=ELIMINAR` y la celda de oferta está vacía
- **ENTONCES** se retira la oferta de manera explícita y auditable.

### Escenario 14: Variación extraordinaria

- **DADO** un precio vigente S/ 999
- **CUANDO** se propone S/ 9.99
- **ENTONCES** la UI muestra una advertencia reforzada antes de confirmar sin afirmar un margen comercial.

## 4. Interacción con otros módulos

| Módulo | Necesidad | Recibe | Entrega |
|---|---|---|---|
| Marketplace/Chatbot/Retail | Consultar precio vigente | SKU, canal opcional, timestamp cuando aplique | regular, oferta, moneda, vigencia y scope |
| Ventas/Postventa | Verificar precio histórico | SKU + `at` | precio oficial de ese instante |
| Seguridad | Autenticar/autorizar | token/claims | 401/403 o acceso |
| Auditoría | Registrar cambios | `pricing.price.changed` | proyección/historial de auditoría |
| Catálogo | Preparar precio base | datos de alta | confirmación de Pricing; contrato de comando todavía pendiente de AsyncAPI |

## 5. Dependencias internas

- Productos/SKU: existencia e identidad.
- Promociones/Cupones: consumen regular/oferta sin modificar Pricing.
- Auditoría: consume hechos confirmados.

## 6. Reglas resueltas

- [x] Ruta REST en español: `/api/v1/precios`.
- [x] Canal opcional y scope global expresable con `null`.
- [x] Consulta histórica con `vigencia_id`.
- [x] Resultado parcial únicamente mediante el estado final del proceso asíncrono.
- [x] Flujo masivo: prevalidación 200 → admisión 202 → estado final.
- [x] Oferta vacía conserva; eliminación solo explícita.
- [x] Permisos `PRICING_*` no se presentan como oficiales.
