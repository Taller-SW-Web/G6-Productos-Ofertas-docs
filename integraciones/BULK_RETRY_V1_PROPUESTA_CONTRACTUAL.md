# Propuesta contractual BULK_RETRY_V1

**Estado:** propuesta en PR Draft; no aprobada ni habilitada. Baseline: Docs master `937b7deb4bde25a282ebb52bbfd16195ad684195`, OpenAPI/AsyncAPI `0.7.0-rc.2`; propuesta `0.7.0-rc.3`.

## Identidades y admisión

- La conciliación de admisión consulta `(owner_sub del JWT validado, correlation_id)`; no acepta propietario desde el cliente y no produce efectos. Un propietario ajeno y una intención inexistente responden igual (`404 LOTE_NO_ENCONTRADO`). Toda respuesta de conciliación lleva `Cache-Control: no-store`.
- En una importación, el `X-Correlation-Id` válido se conserva canónicamente. Si falta se mantiene el fallback histórico. Si está presente pero no es UUID, responde `400 VALIDACION`; nunca se sustituye silenciosamente.
- `batch_id` es calculado exclusivamente por Bulk y aislado por propietario/correlación.
- El `X-Correlation-Id` de reanudación es un UUID obligatorio y distinto del de admisión; identifica el intento HTTP, no cambia el `correlation_id` raíz del lote.

## Elegibilidad y estados

Solo Catalog es candidato inicial. La selección representa una familia SKU completa (`sku_base` exacto) del documento privado V3 y comando raíz originales. Todas las filas seleccionadas deben tener recibo terminal Catalog V2 del intento actual con `REJECTED`, `effect_state=NONE`, `retriable=true`, identidades y contenido verificados. El lote debe estar `COMPLETED`, conciliable y con todos los pasos terminales. No se usa `needs_reconciliation` de fila como prueba positiva o negativa.

Una fila de otra familia, un paso completado, un efecto aplicado/desconocido, un resultado ausente/ambiguo, documento o payload diferente, o un recibo histórico V1 bloquea la familia completa. Solo se reabren los pasos Catalog `FAILED` y dependencias de esa familia con `FAILED/DEPENDENCY_REJECTED`; se conservan pasos completados, filas y operaciones de otras familias. Inventory permanece apagado y Pricing/R03/R14 se mantiene `RESERVADO_NO_APLICA_BULK_V2`.

La respuesta de elegibilidad siempre contiene `motivo_bloqueo`. Con `elegible=true`, `pasos` no está vacío y `motivo_bloqueo=null`; con `elegible=false`, `pasos=[]` y el motivo público es uno de `LOTE_NO_TERMINAL`, `SIN_PASOS_REINTENTABLES`, `RESULTADO_INCIERTO` o `PROTOCOLO_DOMINIO_NO_HABILITADO`. Los diagnósticos internos específicos se mapean a esos valores y no se exponen como nuevos códigos.

## Idempotencia del POST

El hash canónico de la intención comprende `{protocolo, batch_id, owner_sub, correlation_id, motivo}`. Se busca el recibo durable `(batch_job_id, correlation_id)` bajo lock antes de examinar el estado mutable. La misma identidad y motivo devuelve el JSON 202 originalmente persistido; motivo distinto devuelve `409 IDEMPOTENCY_CONFLICT`. La transacción crea recibo, nuevos intentos, comandos Outbox y transiciones antes del 202.

`batch_id`, `batch_operation_id` y `row_operation_id` raíz se conservan. Cada comando de familia tiene nuevos `command_attempt_id`/`message_id`; `causation_id` referencia el mensaje previo. Cada fila obtiene `attempt_id` nuevo, `attempt_number+1` y `previous_attempt_id` exacto. Una reentrega conserva todas esas identidades.

## Mensajes versionados

- Solicitudes Catalog V1–V3 y resultados V1 se preservan.
- Catalog request V4 usa `catalog.bulk.upsert.requested`, conserva `batch_id`, `batch_operation_id`, `template_version=2`, `mode` y `content_ref` V3 verificado. `retry` contiene protocolo, intento de comando, número de intento, mensaje previo y las identidades de las filas de exactamente una familia; no transporta `rows` comerciales inline.
- Resultados Catalog V2 mantienen los nombres completed/rejected. Los resultados por fila incluyen `attempt_id`, número, `status`, `effect_state`, `retriable`, código y las identidades históricas. `command_attempt_id` es requerido: `null` identifica resultado inicial V3 y un UUID identifica el comando V4; además `causation_id` del sobre debe igualar el `message_id` de ese comando. Un rechazo de comando no es, por sí solo, evidencia de elegibilidad.
- El consumer de Catalog comprueba recibos terminales y ausencia de aplicación previa antes de mutar. Solo se permite `retriable=true` por indisponibilidad transitoria reconocida al adquirir identidad de servicio antes de cualquier mutación; validaciones, duplicados SKU, conflictos de versión, 401/403 y 5xx ambiguos nunca son reintentables.
- Bulk asocia el resultado al mensaje Outbox causante, persiste Inbox/recibos/estados en una transacción y no deja que un resultado tardío de intento antiguo sobrescriba el vigente.

## Errores

`400 VALIDACION`, `401 TOKEN_INVALIDO`, `403 SCOPE_INSUFICIENTE`, `404 LOTE_NO_ENCONTRADO`, `409 RETRY_PROTOCOL_NOT_APPROVED`, `409 RETRY_NOT_ELIGIBLE`, `409 IDEMPOTENCY_CONFLICT` y `503 SERVICIO_NO_DISPONIBLE` (solo indisponibilidad técnica). La conciliación por correlación usa 400/401/403/404/503 y no filtra existencia entre propietarios.

## Casos de contrato

| Caso | Resultado esperado |
|---|---|
| GET por correlación de propietario, después de admisión | 200 con lote/estado real, versión de plantilla 2 y no-store |
| GET correlación inválida / correlación ajena | 400 / 404, sin crear filas, manifests, Inbox u Outbox |
| Receipt V2 válido para toda una familia, pasos terminales y sin efecto previo | elegibilidad Catalog positiva; ninguna fila de otra familia aparece en `pasos` |
| `needs_reconciliation=false` en fila con receipt V2 válido | puede ser elegible si las demás invariantes se cumplen |
| Receipt V1, familia parcial/mixta, paso aplicado, UNKNOWN o identidad/contenido distinto | familia inelegible |
| Dos POST simultáneos, misma correlación y motivo | un recibo, un comando por familia y misma respuesta aceptada |
| Replay posterior a resultado terminal | respuesta 202 durable original; ningún Outbox o intento nuevo |
| Misma correlación con motivo distinto | 409 `IDEMPOTENCY_CONFLICT` |
| Resultado de intento previo llega tarde | no cambia filas, pasos ni estado del intento actual |
| Mensaje duplicado de intento actual | devuelve receipt previo sin mutación comercial adicional |

La aprobación de esta propuesta requiere revisión centralizada de Docs y revisión de consumidores. No concede autorización de G7, habilitación de flags, integración Azure ni despliegue.
