# Resumen Ejecutivo — G6 H5 R2 (Cierre Iteración 2)

- **Fecha:** 2026-11-26
- **Rama exclusiva:** `trabajo/castilla/h5-integral-r2`
- **Decisión:** `LOCAL_G6_GO = FALSE`

## Estado por bloque

1. **Operaciones funcionales positivas verificadas:** En la segunda corrida de `certify-158-endpoints.mjs`, los endpoints `[1..13]` y `[15..19]` (18 operaciones) aprobaron seguridad, funcional, negativo y persistencia. En `[20] solicitarReserva`, el helper `/__test/pg-query` falló por un error de casteo SQL (`operator does not exist: text = uuid` en `inventory.reservations.order_id`) que derribó `startRealStackAndVite.mjs`, provocando `ECONNREFUSED` en `[21..158]`.
2. **Persistencias verificadas realmente:** Se implementó `verifyPgPersistence()` contra PostgreSQL vía `/__test/pg-query` y se corrigió `NOT_VERIFIED` para impedir `PASS` sin evidencia (`ok: false`). Las mutaciones `[2]`, `[4]`, `[6]`, `[8]`, `[11]`, `[13]`, `[18]` pasaron verificación SQL real antes de la caída en `[20]`.
3. **Pruebas negativas ejecutadas:** Se eliminó el `PASS` silencioso por `NOT_RUN`; los casos ejecutados en `[1..20]` validaron `[400, 404, 409, 422]`.
4. **Operaciones asíncronas terminales:** En `certify-stack.log` previo al fallo de `[20]`, se verificó en laboratorio el flujo completo de Bulk CSV V2 + V3 claim-check (`catalog.bulk.upsert.completed`, `pricing.bulk.price.apply.completed`, `inventory.bulk.stock.adjust.completed`), el rechazo real `CATALOG_AUTH_TEMPORARY_UNAVAILABLE` vía G7 `503` para `[109]`, y `n01ConsumeStatus = "COMPLETED"`. Sin embargo, la corrida integral reportó `bulkTerminal = "PROCESSING"` al momento del diagnóstico porque la caída en `[20]` dejó el bus inaccesible en el cierre.
5. **R01–R18 / N01 certificados en laboratorio:** La suite `certify-19-messaging-flows.mjs` falló en arranque/consulta (`PG_QUERY_FAILED status=0 body=read ECONNRESET` por usar `http.request` contra `g5SeedOrigin` HTTPS); `service-bus-19-queues.e2e-spec.ts` falló al cargar en Vitest (`TypeError: Cannot read properties of undefined (reading 'config')`).
6. **Pruebas Azure reales:** `NO_EJECUTADAS` (prohibido tocar Azure Chile en este ciclo).
7. **Playwright E2E Frontend:** `EXCLUIDO` por instrucción expresa en este ciclo.
