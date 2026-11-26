# Checkpoint de continuidad para auditoría

2026-11-26, America/Lima. Trabajo detenido por orden del usuario; no continuar suites sin nueva instrucción. Rama en los tres repositorios: `trabajo/castilla/h5-integral-r2`. SIN ISSUE nuevo. Sin merge, despliegue ni cambios Azure/Supabase compartidos.

## Revisiones publicadas

- backend: anterior `4f59235c0b907a9a96e91ae2e6f9efbd7b7c8c6f` → nuevo `b75f1ff7a33c72cec33110b464697cd4a4dc191f`. Push OK.
- frontend: anterior `3b07806b8d3a469e6a5459cb44353969343d3497` → nuevo `778bd03e0180c9ec399626e6b6a417f679b90135`. Push OK.
- docs: anterior `597db8cc4e602d7edd96c381f2a8eb5eeeee9a1e` → nuevo `2c4919067bae9a87d89989a30ab329b4c31fb794`. Push OK.

El HEAD Docs indicado contiene las evidencias; el commit que agrega este archivo es su sucesor y se identifica con `git log -1 --format=%H -- hitos/h5/evidencias/r2-checkpoint-continuidad/ESTADO_PARA_AUDITORIA.md` (evita autorreferencia de SHA).

## Correcciones implementadas

- Pricing inicialización: faltaba entrega R15; helper transaccional Outbox+delivery, `pricing-initialization.ts:625`.
- Bulk: R02/R03 salían antes de Catalog, dejando retry superseded; espera durable por familia, `bulk.repository.ts:3347`, comandos Pricing por familia `bulk-import.service.ts:390`.
- Catalog: metadatos de productor ausentes y perdidos en adaptador local; `catalog-service-bus.ts:95,259`.
- Inventory: inicialización cero emitía stock.changed versión 0 inválida; se conserva saldo/version cero sin evento de movimiento, `inventory-command.service.ts:165`.
- Pricing Bulk: evento con product_id null; ahora resuelve padre por Catalog autenticado, `bulk-price-apply.service.ts:162`.
- Gateway: propagación de correlación validada, `gateway-proxy.ts:239`.
- Frontend: Authorization duplicada por casing; `authenticatedCatalogTransport.ts:19`. Regresiones G7 actualizadas y tres suites antes omitidas incluidas.
- Laboratorio: fixture físico válido, flag retry Catalog, Combos/Promotions conectados al broker común; cierre IPC y fallo receive 503 controlado.
- Verificador HTTP: umbral exacto, negativos contractuales, persistencia por ID/valor/estado. OpenAPI: claves allowlist duplicadas vacías de Combos eliminadas según DEC-02.

## Última evidencia real (sin repetir en checkpoint)

- HTTP: 158/158 PASS, 0 FAIL, 2026-11-26T23:04:37Z. Backend `tests/h5/158_ENDPOINTS_CERTIFICATION_REPORT.json`; copia Docs `r2-cierre-iteracion-7/HTTP_158_CORRIDA_1.json`. Bulk y N01 COMPLETED; 401/403 satisfactorios.
- Mensajería: 19/19 PASS, 0 FAIL, 23:06:23Z. `r2-cierre-iteracion-7/MENSAJERIA_19_RECORRIDOS.json`: publicación/recepción/completado, SQL, replay en 19 colas, tablas sin cambios; productor inválido DLQ sin efecto; cola Pricing pendiente durante receive503 y recuperación. HTTP_IN_MEMORY_NOT_AZURE; no acredita detención/reinicio de proceso consumidor ni Azure.
- Backend completa: 2941 PASS, 0 FAIL, 101 SKIP, success=true; `UNITARIAS_COMPLETAS_RESUMEN.json` incluye estados por archivo y hashes. 63 skips Inventory integración heredada requiere Docker/RabbitMQ, 38 Bulk requieren PostgreSQL17 explícito; no añadir skips ni restaurar RabbitMQ para H5.
- Backend typecheck/build PASS; lint exit0, 24 warnings existentes. Focalizadas PostgreSQL Pricing3/3 y Bulk3/3 PASS; seguridad Gateway16/16 PASS; paridad/Catalog12/12 PASS.
- Frontend npm test: 789 PASS (754 Vitest+35 Node), 0 FAIL; typecheck/lint/build PASS. Última adición de fallo controlado del broker ejecutada por mensajería, no volvió a pasar lint/build completos.
- Las corridas preceden a los commits y corresponden al working tree conservado; no son CI sobre HEAD. No se reejecutaron suites largas durante este checkpoint.

## Estados, pendientes y riesgos

G7: laboratorio RS256/JWKS y validación real; no acredita grants G7 externos ni homologación. PostgreSQL descartable real; no compartido. Frontend UI contra Gateway real aún pendiente; Playwright expresamente excluido, ninguna certificación UI asumida.

Azure: namespace Basic Chile `g6-sb-h5-int-32cdqgbnlk7ow`, 19 colas. DNS/TCP disponibles; SDK WebSocket rechazó `UnauthorizedAccess: Unauthorized access. 'Listen' claim(s) are required`. NOT_RUN_BLOCKED_INFRA. Owner laboratorio Azure/G6; desbloqueo: ejecutor legítimo con Sender/Receiver por servicio/cola y aislamiento. No se otorgaron roles ni consumieron DLQ preexistentes.

No fallo funcional conocido queda reproducido en las últimas suites, pero auditoría no concluida: faltan dos corridas integrales consecutivas limpias, ampliar semántica de lecturas/persistencia donde aún hay counts generales, actualizar matrices canónicas, reconciliar CSV80 (no84) con DEC01..06 y verificar frontend real. PARIDAD_ACCESOS_80.json es parcial: conserva etiquetas históricas PROPUESTO/POR_DEFINIR y debe interpretarse con DEC aprobadas; no acredita grants. ESTADO_EN_CURSO.md es checkpoint anterior, supersedido por este documento.

CODE_AND_LAB_FUNCTIONAL_READY=false (aceptación integral no cerrada). LOCAL_G6_GO=false. AZURE_G6_GO=false. Externos G5 son fixtures controlados, no evidencia comercial autoritativa.

Próxima acción al retomar: leer este checkpoint, verificar HEAD remotos, revisar diffs/evidencias; completar auditoría y matrices antes de ejecutar dos regresiones limpias. Mantener bloqueo Azure separado. No nuevos PR/issues, merge ni despliegue sin autorización.

## Archivos modificados

### backend

```text
apps/api-gateway/src/routing/gateway-proxy.ts
apps/bulk-svc/src/bulk-import.service.ts
apps/bulk-svc/src/persistence/bulk.repository.ts
apps/bulk-svc/test/r03-pricing-r14-bulk.postgres.e2e-spec.ts
apps/catalog-svc/src/catalog-service-bus.spec.ts
apps/catalog-svc/src/catalog-service-bus.ts
apps/catalog-svc/src/taxonomy.client.spec.ts
apps/combos-svc/src/messaging/combos-isolated-service-bus.ts
apps/combos-svc/src/messaging/combos-service-bus.spec.ts
apps/combos-svc/src/messaging/combos-service-bus.ts
apps/inventory-svc/src/inbox/inventory-command.service.ts
apps/inventory-svc/src/inbox/inventory-command.spec.ts
apps/pricing-svc/src/messaging/bulk-price-apply.service.ts
apps/pricing-svc/src/messaging/pricing-initialization.ts
apps/pricing-svc/src/messaging/r03-r14-r15-r17-r07.spec.ts
apps/pricing-svc/src/messaging/service-bus-deliveries.ts
apps/pricing-svc/test/r03-r14-r16-r17.postgres.e2e-spec.ts
apps/promotions-svc/src/coupons/coupon-h5-isolated-bus.spec.ts
apps/promotions-svc/src/coupons/coupon-h5-runtime.ts
apps/promotions-svc/src/coupons/http-lab-bus.ts
apps/promotions-svc/src/coupons/service-bus-config.ts
apps/promotions-svc/src/coupons/service-bus-events.ts
tests/h5/158_ENDPOINTS_CERTIFICATION_REPORT.json
tests/h5/158_ENDPOINTS_CERTIFICATION_REPORT.md
tests/h5/158_ENDPOINTS_CERTIFICATION_REPORT_RETRY_ONLY.json
tests/h5/158_ENDPOINTS_CERTIFICATION_REPORT_RETRY_ONLY.md
tests/h5/audit-access-matrix.py
tests/h5/certify-158-endpoints.mjs
tests/h5/certify-19-messaging-flows.mjs
```

### frontend

```text
src/features/auth/publicReads.test.ts
src/features/auth/readOnlyClient.test.ts
src/features/catalog/adapters/authenticatedCatalogTransport.ts
src/features/catalog/hooks/useCatalogStateMutation.spec.tsx
src/features/catalog/hooks/useVariantPreparation.spec.tsx
src/features/promotions/services/promotionSessionRuntime.ts
src/features/reads/readOnlyClient.ts
src/features/taxonomy/services/taxonomyGatewayRuntime.ts
tests/e2e-real/startRealStackAndVite.mjs
vitest.config.ts
```

### docs

```text
contratos/http/openapi.yaml
hitos/h5/evidencias/r2-cierre-iteracion-7/ESTADO_EN_CURSO.md
hitos/h5/evidencias/r2-cierre-iteracion-7/HTTP_158_CORRIDA_1.json
hitos/h5/evidencias/r2-cierre-iteracion-7/HTTP_ANTES_CORRECCION_BULK.json
hitos/h5/evidencias/r2-cierre-iteracion-7/MENSAJERIA_19_RECORRIDOS.csv
hitos/h5/evidencias/r2-cierre-iteracion-7/MENSAJERIA_19_RECORRIDOS.json
hitos/h5/evidencias/r2-cierre-iteracion-7/MENSAJERIA_CORRIDA_INTERMEDIA.json
hitos/h5/evidencias/r2-cierre-iteracion-7/PARIDAD_ACCESOS_80.json
hitos/h5/evidencias/r2-cierre-iteracion-7/UNITARIAS_COMPLETAS_RESUMEN.json
```

Reportes unitarios crudos preservados localmente fuera de Git en `.codex/attachments/c7e108c4-2212-4316-a860-d0a0ad2c7207/checkpoint-raw-reports`; resumen sanitizado publicado. Logs ignorados no publicados; ningún código pendiente descartado. Sin cambios fuera de alcance. Estado final PARTIAL, conservación/publicación PASS.
