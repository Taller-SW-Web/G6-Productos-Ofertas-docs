# Checkpoint para auditoría — WIP — 2026-11-26

Rama en los tres repositorios: `trabajo/castilla/h5-integral-r2`. Corte urgente; no es certificación final.

## HEAD y pushes

- Backend: inicial `de393631a5fd45d2984682fd8fcd7f4d808f734f`; final `75cae32c422ebae837f4d12cf6027dc1db791b6b`; push OK, remoto coincide.
- Frontend: inicial `8ebdc31a3983e2d80ab99041381dc036e2aaf131`; final `2f0453c1794f54a403085610d5579c4d82fecf5e`; push OK, remoto coincide.
- Docs: inicial `4294a158923cc66e34c0d691591dff62f72a0d4f`; final `8008ee21a547f11ac0cccda188bf7a5771b9b27a`; push OK, remoto coincide.

## Archivos y cambios

Backend: `apps/bulk-svc/src/persistence/bulk.repository.integration.spec.ts` corrige harness de test (proveedor BulkContentService, actor del guard y fixture content_documents); `tests/h5/run-bulk-postgres17.mjs` prepara PostgreSQL17 efímero local con migrations0001–0009 y roles separados; `tests/h5/certify-158-endpoints.mjs` endurece comprobaciones de persistencia y agrega modo focal; `tests/h5/certify-19-messaging-flows.mjs` guarda evidencia actualizada y añade recuperación tras parada/reinicio de Pricing. Informes de fallo estricto y de operación focal en tests/h5.

Frontend: `tests/e2e-real/startRealStackAndVite.mjs` incorpora control loopback de laboratorio para matar/reiniciar Pricing y esperar readiness; requiere comprobar su integración con la nueva prueba de mensajería. Antes se publicaron fixes E2E para formularios/DTO, fixture Promotions, flujo Bulk y espera de terminalidad.

Docs: `contratos/http/openapi.yaml` completa x-error-codes para dos lecturas administrativas Pricing según errores ya declarados. `MATRIZ_ACCESOS_SCOPES_MODULOS_H5_R2.csv` contiene 80 filas fuente reconciliadas mediante decisiones aprobadas; no implica grants externos. En `r2-cierre-gemini/` hay auditorías, bloqueo Azure y evidencias JSON/CSV.

## Resultados medidos en esta etapa

- HTTP completo más estricto: última corrida 157/158 PASS. Falla `crearImportacionPrecios`: job terminal FAILED, fila FAILED, código PRECIO_NO_ENCONTRADO tras cambios anteriores sobre el SKU. El caso aislado fue 1/1 PASS. Evidencia `r2-cierre-gemini/HTTP_158_ASERCIONES_ESTRICTAS_FALLO.json`; no declarar 158/158 actual.
- Mensajería: artefactos de la corrida nueva existen, pero no se confirmó su resultado final antes de interrumpir. La última cifra segura anterior es 19/19 en broker HTTP in-memory, histórica. La nueva prueba de proceso no equivale a Azure.
- Backend PG17: corrida final observada 38/38 PASS, 0 omitidas, entorno Docker local descartable. Primera corrida 36/38; se repararon dos defectos del test harness.
- Backend unitarias: 2941 PASS, 0 FAIL, 101 SKIP, HEAD previo de esta etapa; no revalidado en HEAD final. Typecheck estaba ejecutándose/sin resultado confirmado. Lint sin errores con advertencias; build:all PASS histórico en HEAD previo.
- Frontend Playwright: 16/16 PASS, 0 skip/flaky, 129.38s; React real con Gateway y ocho servicios, PostgreSQL TLS efímero, G7 RS256/JWKS local, G5 contractual local y broker HTTP in-memory. Corrida antes del commit final de frontend. Unitarias 789/789 PASS, typecheck PASS, build PASS con VITE_DATA_MODE=api. Lint PASS previo.
- Dos regresiones integrales limpias consecutivas: no realizadas. Los resultados heredados de Codex (158/158 y 19/19 previos, unitarias, gateway, build) son históricos y no deben atribuirse al HEAD final.

## Seguridad y dependencias externas

JWT, issuer/audience/scopes/roles y 401/403: verificación local; no confirma grants ni homologación de G7 real. Azure Service Bus real `NOT_RUN_BLOCKED_INFRA`: namespace Basic Chile Central,19 colas; ejecutor sin Data Sender/Receiver efectivo. Error SDK exacto: `Unauthorized access. 'Listen' claim(s) are required to perform this operation. Resource: 'sb://g6-sb-h5-int-32cdqgbnlk7ow.servicebus.windows.net/g6.catalog.from.bulk/$management'.` Consulta peek solamente; sin envío/consumo; DLQ previa preservada. No se cambió Azure, RBAC ni Supabase.

`CODE_AND_LAB_FUNCTIONAL_READY=false`, `LOCAL_G6_GO=false`, `AZURE_G6_GO=false`.

## Para retomar

Gemini: leer este checkpoint; revisar salida final de `tests/h5/messaging-process-recovery.log` y JSON/CSV de mensajería; completar typecheck; corregir causa raíz de PRECIO_NO_ENCONTRADO en suite integral; ejecutar dos regresiones solo cuando código estabilice; finalizar coherencia de matrices/documentos y comprobar pushes. No repetir suites cuyos resultados aquí son claros salvo que los cambios nuevos lo exijan.

Axel Cueva: gestionar los roles mínimos Data Sender/Receiver por identidad de productor/consumidor y cola, después ejecutar despliegue y smoke autorizados. No otorgar roles de negocio a identidad pull ACR. Despliegue no realizado.

Worktrees: `C:\Users\marec\Desktop\G6-Productos-Ofertas\_worktrees\r2-integral\{backend,frontend,docs}`. HEAD docs de este checkpoint no se validó tras una nueva suite.
