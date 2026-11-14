# Contrato HTTP candidato H5 — operaciones asíncronas de cupones

**Estado:** `PROPUESTO_NO_PUBLICADO_EN_OPENAPI`, sin homologación G5/G7 ni implementación acreditada. No sustituye `POST /api/v1/cupones/validar`, que solo valida sin consumir usos.

## Operaciones propuestas

| Método | Ruta bajo Gateway | Autoridad | Efecto |
|---|---|---|---|
| POST | `/api/v1/cupones/consumos` | Promotions | Admite consumo de cupón |
| POST | `/api/v1/cupones/restauraciones` | Promotions | Admite restauración por cancelación |
| GET | `/api/v1/cupones/operaciones/{operationId}` | Promotions | Estado y resultado durable por operación |

> Los nombres de estas rutas se proponen para discusión G5/G6; no son endpoints existentes. El GET de inventario **sí existe**: `/api/v1/inventario/operaciones/{operationId}`; se conserva sin duplicarlo.

## Seguridad

- JWT de servicio válido para `aud=api-productos`, `client_id=modulo-ventas`, scopes específicos de consumo/restauración/consulta por registrar con G7, allowlist por operación.
- Nunca interpretar `producer` del body como autorización. Obtener identidad del token validado.
- `operation_id` no es secreto: la consulta verifica además identidad autorizada y pertenencia de operación/orden; no filtrar resultados de terceros.
- No aceptar el token humano del comprador como reemplazo del token técnico. `customer_ref` del comprador es distinto del `sub` del cliente servicio.
- Política de rate limit según capacidades efectivas de APIM Consumption; `rate-limit-by-key` no está soportada en Consumption; no documentarla como protección ya aplicada.

## POST: admisión

Requisitos comunes:

- `Authorization: Bearer <token-servicio>`; `Idempotency-Key: <uuid-estable>`; `X-Correlation-ID` opcional según contrato final.
- El payload funcional conserva las invariantes de AsyncAPI v2. En consumo: `order_id`, `coupon_code`, `channel_id`, `customer_ref` cuando corresponda, `effective_at`, `reservation_id`, `commercial_snapshot_ref`; `operation_id` UUID estable del flujo.
- Restauración: `order_id`, `consumption_operation_id` del consumo realmente confirmado, `cancellation_reason`, `cancelled_at` original, `operation_id` de restauración distinto y estable.
- Antes de admitir, validar esquema, permisos, no colisión de idempotencia y precondiciones autoritativamente comprobables. Lo que requiera procesamiento posterior queda pendiente: nunca afirmar consumo final en POST.
- Persistir **atómicamente** operación aceptada y outbox en base de Promotions, antes de devolver 202. El transporte Azure puede estar temporalmente caído.

Respuesta nominal:

```http
HTTP/1.1 202 Accepted
Location: /api/v1/cupones/operaciones/{operationId}
Retry-After: 2
Content-Type: application/json

{"operation_id":"<UUID>","status":"ACCEPTED"}
```

Mismo `operation_id` + mismo contenido semántico: devolver admisión o resultado original sin nuevo efecto. Mismo `operation_id` con fingerprint distinto: `409 IDEMPOTENCY_CONFLICT`. Contrato definitivo: documentar además `400`, `401`, `403`, `404`, `422`, `429`, `500`, `503` solo donde apliquen, con catálogo estable de errores y pruebas.

## GET: consulta

```json
{
  "operation_id": "<UUID>",
  "operation_type": "CONSUMIR_CUPON",
  "status": "COMPLETED",
  "order_id": "PED-...",
  "result_code": null,
  "accepted_at": "2026-11-14T00:00:00Z",
  "completed_at": "2026-11-14T00:00:02Z"
}
```

Valores orientativos: `ACCEPTED`, `COMPLETED`, `REJECTED` (estados adicionales solo si están aprobados). El resultado definitivo debe incluir los campos de negocio relevantes (`consumption_id`, `restored`, `outcome` u otros) conforme al DTO y versión acordados. No devolver inventario, información de campañas ajenas ni mensajes internos con secretos.

- Estado pendiente: GET 200 con `status=ACCEPTED` y `Retry-After` recomendado; no `202` indefinido por costumbre.
- Estado final: resultado inmutable o versionado con historial; repetir GET no ejecuta el comando.
- Timeout/loss en POST: cliente consulta operación y/o reintenta idénticamente, nunca crea otra operación para averiguar si se completó.
- Política cliente: polling con backoff acotado, deadline funcional, estado pendiente recuperable y compensación/no-cobro según G5.

## Inventory: deuda funcional no cubierta por GET inicial

El `GET /api/v1/inventario/operaciones/{operationId}` actual recupera una operación específica, pero **no certifica que una reserva ya confirmada siga vigente** ni necesariamente refleja `inventory.reservation.expired` posteriormente. Se requiere homologar una consulta de estado de reserva por `reservation_id` o alternativa equivalente sin duplicar ownership. Mantener el evento H4 hasta resolver esta decisión de contrato y verificar G5 consumidor.

## Cambios antes de convertir la propuesta en OpenAPI canónico

1. Definir DTOs JSON Schema completos y Problem Details (códigos, estados, retención, límites).
2. Confirmar si `operation_id` aparece en body, header o ambos y las reglas de precedencia (no inventar dualidad ambigua).
3. Definir origen legítimo de `reservation_id` y permisos verificables para evitar consumir un cupón sin reserva ajena.
4. Definir endpoint/estado de reserva vigente para expiraciones tardías.
5. Completar G5/G7 bilateral y pruebas provider/consumer antes de sustituir semántica de AsyncAPI externa.
