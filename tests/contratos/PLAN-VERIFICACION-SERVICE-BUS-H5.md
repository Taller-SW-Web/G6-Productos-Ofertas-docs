# Matriz de pruebas H5 — mensajería interna y frontera HTTP externa

**Estado:** casos propuestos, NO ejecutados. Se agregan a `contratos/pruebas/pruebas-contrato.md` cuando se apruebe su alcance.

| ID | Caso | Verificación mínima | Tipo |
|---|---|---|---|
| H5-MSG-01 | Emisión real Pricing→Price Audit | Contrato tipado, persistencia de auditoría, correlación, cola correcta | Integración |
| H5-MSG-02 | Redelivery post-commit | `completeMessage` falla; inbox no duplica registro | Fallo |
| H5-MSG-03 | Outbox con broker caído | Aceptación en SQL, entrega diferida y reconciliación sin pérdida | Recuperación |
| H5-MSG-04 | Envío ambigüo | Timeout posterior a envío causa retry mismo MessageId sin efecto duplicado | Idempotencia |
| H5-MSG-05 | Fan-out de evento | Cada destino independiente recibe copia; caída de uno no bloquea éxito durable de otros | Integración |
| H5-MSG-06 | DLQ real | `MaxDeliveryCount` y mensaje inválido investigables, replay autorizado y trazado | Recuperación |
| H5-MSG-07 | Seguridad por entidad | Sender/receiver correctos aceptados; identidad de servicio ajena denegada | Seguridad |
| H5-MSG-08 | Tamaño límite | Mensaje >256 KB rechazado sin marcar outbox publicado; fragmentación/claim-check prueba identidad y checksum | Límites |
| H5-MSG-09 | Ordering por agregado | Eventos inversos/duplicados no generan estado obsoleto | Dominio |
| H5-MSG-10 | 202 admisión de cupones | Responde solo tras SQL de operación y outbox confirmados | Contrato HTTP |
| H5-MSG-11 | POST idempotente | Mismo operation_id/payload = mismo resultado; payload distinto = 409 | Seguridad/negocio |
| H5-MSG-12 | GET autorizado | Resultado protegido por identidad y pertenencia, 401/403/404/429 según contrato | Seguridad |
| H5-MSG-13 | Reservas G5 | G5 distingue 202 de reserva creada; consulta estado terminal | E2E |
| H5-MSG-14 | Expiración tardía | Reserva confirmada después expirada provoca reacción G5 sin evento directo | E2E bloqueante |
| H5-MSG-15 | Cupón consume | Sólo después de reserva final confirmada; G5 no cobra antes del resultado cupón | E2E bloqueante |
| H5-MSG-16 | Cupón restaura | `consumption_operation_id` + `cancelled_at` estable, no doble restauración | E2E |
| H5-MSG-17 | Ausencia de broker externo | G5 sin cadenas Service Bus ni permisos; realiza todo por HTTP | Arquitectura |
| H5-MSG-18 | APIM | JWT/audiencia/scopes, cuota compatible con tier, correlación | Seguridad |
| H5-MSG-19 | Emulador vs Azure real | Diferenciar límites: identidad, métricas, durabilidad, WebSockets; test real extra | Calidad |
| H5-MSG-20 | Performance | p95 de admisión/finalización, throughput, backlog, DLQ, costos/ops | Rendimiento |
| H5-MSG-21 | Comando HTTP a cola nueva | Solo adaptador HTTP de Promotions envía a `g6.promotions.commands`; únicamente worker Promotions consume | Arquitectura/seguridad |
| H5-MSG-22 | Admisión Promotions durable | Transacción operación+Outbox antecede 202; caída de broker conserva ambos | Persistencia/contrato HTTP |
| H5-MSG-23 | Worker Promotions idempotente | Inbox+efecto+resultado en commit; redelivery tras commit/settle no duplica efecto | Idempotencia/recuperación |
| H5-MSG-24 | Estado actual de reserva | `ACTIVA` con `expires_at <= observed_at` informa `vigencia_efectiva=VENCIDA` y no permite pago/consumo | Contrato/expiración tardía |
| H5-MSG-25 | Carrera pago vs vencimiento | Consulta vigente no sustituye validación atómica; Inventory vuelve a comprobar bajo lock y usa mecanismo `ReservationExpirationService` existente | Dominio/concurrencia |
| H5-MSG-26 | Indisponibilidad >14 días | `DefaultMessageTimeToLive` no configurable y TTL máximo/default 14 días; conservar Outbox/operación; reconciliar Inbox/resultado/efecto; replay solo autorizado, idempotente y sin resultado terminal | TTL/recuperación |
| H5-MSG-27 | TTL del mensaje separado de reserva | Un mensaje expirado/no entregable no cambia `expires_at` ni estado comercial por sí mismo | Contrato/domino |
| H5-MSG-28 | Reconciliación G5 tras expiración sin notificación | Evento/COMPLETED de creación inicia registro durable; barrido periódico y recuperación tras caída consultan pedidos y reemplazos elegibles; GET vencida aplica solo transición G5 existente; error reintenta y replay no duplica anulación | Contrato/E2E bilateral pendiente |
| H5-MSG-29 | Carrera conciliación, pago y anulación | Dos workers/concurrencia no duplican transición; pre-pago consulta vigencia; terminal pagado/anulado no se degrada; reintentos conservan clave y checkpoint | Concurrencia/G5 |
| H5-MSG-30 | Orden comercial Marketplace con cupón | Reserva efectiva creada → vigencia → consumir cupón y esperar COMPLETED → pagar → POST `/confirmar` y esperar consumo stock; ningún paso de confirmación stock se adelanta | Contract/E2E |
| H5-MSG-31 | Flujos Chatbot y reemplazo preservados | Chatbot solo consultas comerciales según acuerdo; reemplazo M1 independiente sin cobro, confirmación al sellar y resultado antes de despacho; expiración usa anulación/nueva orden existentes | Regresión contractual |
| H5-DOC-01 | Invariantes documentales candidatas | Schemas JSON en propuesta satisfacen ejemplos; topología, estado reserva y TTL Basic no contradicen el documento | Estática documental |

## Evidencia de cada prueba

Registrar `test_id`, SHA de Docs y Backend, SHA G5 cuando aplique, versión contractual, entorno, modo (`emulador`/`azure-real`), identidad/scope de prueba, procedimiento, dataset, respuesta y logs sin secretos, run CI/CD, timestamp, resultado, defectos pendientes. No etiquetar PASS casos que solo cuentan con mocks. Los escenarios de rendimiento deben tener SLO/umbrales aprobados, no números elegidos arbitrariamente.
