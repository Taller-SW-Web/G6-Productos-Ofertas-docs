# Cierre MK-001 Bulk H5 sin despliegue

**Corte:** 24/11/2026 (America/Lima)
**Alcance:** Bulk B01–B08 y F01–F06, integración requerida de Catalog H5, pruebas locales/CI y documentación.
**Estado del corte:** Backend PR [#274](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/274) permanece Draft en HEAD `2d276b3522ce09f3f7293e568251fb43aad9b24d`. La integración dedicada [run `45495393575`](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45495393575) pasó 8/8, cero omitidos, en PostgreSQL 17 y Supabase Storage local CLI 3.4.0; SHA de integración `ad30d496cad9256efdc930925a321647a648465e`, base `49bab9e2075819d922c63b06fcc6fc6ac16ce703`. Artefacto `14967813955`. CI general sigue en `skipped` por Draft. Persisten brechas de Frontend real, recuperación/reinicios, migraciones rollback, matriz de archivos y performance final. Despliegue: NO REALIZADO.
**Despliegue:** NO REALIZADO.

## 1. Resumen ejecutivo

Se cerraron mediante merge normal Frontend #93, Catalog H5 #262 y Backend Bulk V3/H5 #271. Catalog Retry V4 / resultado V2 se integró mediante PR sustituto #273 desde `master`, trasladando selectivamente la contribución histórica #254 sin fusionar su base obsoleta. #273 mergeó en `49bab9e2075819d922c63b06fcc6fc6ac16ce703` con HEAD probado `b19f2dffdd1101b179abf5f1c5011d4de0948204`; todos los checks ejecutados aplicables del PR pasaron. #254 se cerró tras verificar la fusión sustitutiva.

La evidencia de PR #274 cubre PostgreSQL 17 descartable, servicios Bulk/Catalog y Gateway reales, HTTP loopback, JWT RS256/JWKS de prueba, roles aislados y adaptador BulkStorageService contra Supabase Storage local con bucket privado. El transporte asíncrono entrega al consumidor real dentro del E2E y no homologa Service Bus. Azure, APIM, emisor/grants G7 institucionales, homologación externa y despliegue no participaron.

## 2. Estado Git y PRs

| Repo | PR | Resultado / SHA | Estado comprobado |
|---|---|---|---|
| Frontend | [#93](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/93) | merge `e322808d868bb89e2c645a1b069eb12728296d9f`; HEAD `8665ce65086bb456573f82e8146f941bb50eb617` | MERGED normal; unitarias, smoke, API y build local reportados PASS |
| Backend Catalog H5 | [#262](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/262) | merge `c73ed61c533a21787d1dab22aa79cd83ff77da14` | MERGED normal; rama reconciliada en el master utilizado para #271 |
| Backend Bulk V3/H5 | [#271](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/271) | merge `133a051acf187e0a75c074e38aa284a8ea226250`; HEAD origen `af5a6b4e0e7f4cc7a5d32fcf3694d19cb6db9660` | MERGED normal; flags apagados |
| Backend Catalog Retry V4/V2 | [#273](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/273) | merge `49bab9e2075819d922c63b06fcc6fc6ac16ce703`; HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204` | MERGED normal; CI posterior confirmada por runs `45470786170` y `45470785787` |
| Backend legado | [#254](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/254) | HEAD histórico `f259df772c4f3f5473449cbe2f69eb0dde40b79e` | CLOSED tras fusión normal de #273; contribution trasladada selectivamente, no se fusionó base `poma` |
| Backend antiguo | #243 | — | CLOSED sin merge; no se recuperó completo |

Los merge SHAs se consultaron en GitHub. `compare` confirma que el merge `49bab9e2075819d922c63b06fcc6fc6ac16ce703` es descendiente de `133a051acf187e0a75c074e38aa284a8ea226250` (`ahead 14`, `behind 0`). No hubo force push ni bypass.

## 3. Matriz de guía MK-001

Las columnas separan implementación, prueba y operación. `NO EJECUTADO` no es PASS. La guía original adjunta define los identificadores BUL-B01–B08 y BUL-F01–F06.

### Bulk Backend BUL-B01–B08

| ID original de guía | Requisito | Código | Prueba local/CI | Evidencia | Estado operativo |
|---|---|---|---|---|---|
| BUL-B01 | Plantillas CSV/XLSX y roundtrip contractual | Handler CSV/XLSX y plantillas existentes | Matriz integral CSV/XLSX: NO EJECUTADA en esta continuación | Suites previas Frontend; falta roundtrip asociado a SHA final | Implementado; validación integral pendiente |
| BUL-B02 | Admisión durable y atomicidad | Persistencia transaccional existente | Admisión HTTP PostgreSQL real; no se indujo fallo intermedio | E2E ampliado, HEAD base `49bab9e2075819d922c63b06fcc6fc6ac16ce703`; PR pendiente | Implementado; rollback por fallo no verificado |
| BUL-B03 | Idempotencia, propietario, correlación y replay | Idempotencia por owner/correlación existente | 2 POST simultáneos devuelven el mismo lote; bytes distintos con correlación igual reciben 409; retry concurrente mismo/distinto correlation, replay e Inbox/Outbox cubiertos | E2E CI `45495393575`, HEAD `2d276b3522ce09f3f7293e568251fb43aad9b24d`, integración `ad30d496cad9256efdc930925a321647a648465e`; artifact `14967813955` | Idempotencia/retry/redelivery probados en CI; timeout/reinicio pendientes |
| BUL-B04 | Estado por fila/dominio y aplicación de resultado del owner | Bulk concilia resultado V2 en persistencia propia | Catalog real aplica/rechaza; se comprueba estado terminal y efecto único | E2E Bulk-Catalog local; producto permanece propiedad de Catalog | Implementado y probado en recorrido local limitado |
| BUL-B05 | Retry selectivo, concurrencia y causación | Retry Catalog V4/resultado V2 y receipts durables existentes | Dos POST retry simultáneos, replay tras resultado V2, dos entregas simultáneas V4 y V2 | E2E Bulk-Catalog local: PASS en la ejecución combinada anterior; comandos/receipts reales en PostgreSQL 17 | Concurrencia local verificada para Catalog; no equivale a Azure |
| BUL-B06 | Reportes/exportaciones reales y permisos | Rutas HTTP y adaptador de Storage existentes | Descarga con Storage real: NO EJECUTADA; Gateway 401/403/404/503 parcial | Test de Gateway cubre seguridad de lectura/correlación, no exportación | Implementado; cobertura de artefactos pendiente |
| BUL-B07 | Claim-check V3 privado, hash/tamaño y auth Catalog | Contenido V3, guard y cliente privado presentes | Storage real Supabase local y headers de integridad/autorización; referencia inexistente, longitud/hash/documento inválidos y outage aún no acreditados como escenarios negativos | E2E CI `45495393575`, artifact `14967813955`, Storage CLI 3.4.0; escenario privado real | Storage local real probado; matriz negativa completa pendiente |
| BUL-B08 | Mantener flujos no autorizados bloqueados | R02/R03/R10/R14 no se habilitan por este cierre | CI/Runtime Azure no habilitados; flags productivos no cambiados | Código conserva gates; homologación y permisos no probados | Bloqueado correctamente; no es brecha de código demostrada |

### Bulk Frontend BUL-F01–F06

| ID original de guía | Requisito | Código | Prueba local/CI | Evidencia | Estado operativo |
|---|---|---|---|---|---|
| BUL-F01 | Adaptador HTTP real sin fallback silencioso | `httpBulkRepository` y selector API/mock existentes | Playwright API usa servidor HTTP fixture, no Backend/Gateway real | #93 y HEAD `e322808d868bb89e2c645a1b069eb12728296d9f` | Implementado; integración real no demostrada |
| BUL-F02 | Validación UX de archivo y accesibilidad | Validaciones locales de selección existentes | Suite previa; escenario real Gateway no ejecutado | Playwright mock/API previo | Implementado; criterios integrales pendientes |
| BUL-F03 | Una intención, bloqueo de doble click y recuperación | Control de admisión/idempotencia UI existente | Doble clic probado en harness/fixture, no contra Backend real | Evidencia Playwright previa de #93 | Implementado; E2E real pendiente |
| BUL-F04 | Polling, estados, recarga y snapshots | Seguimiento Bulk por batchId existente | Polling probado con respuestas fixture; reload contra backend no ejecutado | Evidencia Playwright previa | Implementado; recuperación E2E real pendiente |
| BUL-F05 | Retry solo con elegibilidad backend | Botón depende de elegibilidad y retry de Catalog | Flujo usa fixture; no se conecta a Backend/Gateway real desde navegador | Evidencia Playwright previa | Implementado; integración real pendiente |
| BUL-F06 | Blob real, seguridad y accesibilidad | Descargas Blob y sesión autenticada existentes | Descargas y seguridad con backend real: NO EJECUTADAS | Sin trace/captura de flujo Frontend→Gateway→Bulk | Implementado; verificación integral pendiente |

## 4. Implementación y contratos

- Contratos objetivo: OpenAPI y AsyncAPI H5 `0.7.0-rc.3`; Docs indica `APPROVED_G6`, que no significa homologación externa.
- #271 conserva Outbox/Inbox durable, Service Bus Basic target, claim-check V3 y flags apagados.
- #273 porta receipts durables de Catalog por comando/fila, replay de resultado V2 y V4 con correlación raíz; mantiene autenticación legacy para flujo V1/V3.
- El workflow de integración anterior armaba PR históricos mediante merges/parches temporales. Se sustituyó por `.github/workflows/bulk-catalog-retry-integration.yml` en #273, ejecutando HEAD actual en PostgreSQL 17 y aplicando migraciones con orden explícito.
- El E2E permanente `apps/bulk-svc/test/bulk-catalog-retry.e2e-spec.ts` utiliza servicios/guard Bulk y consumidor Catalog reales, HTTP loopback, JWT RS256 firmado de prueba y PostgreSQL. En HEAD `2d276b3522ce09f3f7293e568251fb43aad9b24d` incorpora admisión y retry HTTP concurrentes, conflictos 409, redelivery simultánea V4/V2, replay tras V2, resultado contradictorio tardío con receipt STALE y comprobación de efectos por correlación. Workflow `45495393575`: 8/8, cero omitidos; artifact `14967813955`. La entrega de comandos sigue siendo transporte local directo y no homologa Azure Service Bus.
- `apps/api-gateway/test/bulk-postgres.gateway.e2e-spec.ts` se ejecutó con Gateway real, JWKS local y PostgreSQL 17; siete escenarios pasaron (JWT ausente, identidad sin rol, firma inválida, expiración, issuer/audience incorrectos, recursos ajenos y proveedor no disponible). El run dedicado `45495393575` ejecutó junto a Bulk-Catalog: 8/8, cero omitidos.
- La entrega de comandos y resultados invoca el consumidor real directamente desde el E2E; no atraviesa Azure Service Bus ni acredita su transporte, ACK o topología. CI valida una matriz explícita de 11 escenarios Bulk y siete de Gateway; publica JSON/JUnit, metadatos de HEAD/base/integración y versiones. El run `45495393575` pasó 8/8, cero fallos y cero omitidos.
- En el host local, `supabase@3.4.0 start` quedó bloqueado porque Docker Engine devolvió HTTP 500; no se limpió el contenedor local parcial porque daemon no respondió. En GitHub Actions el mismo CLI inició Storage, ejecutó el adaptador real y limpió el stack con `stop --no-backup`. No se enlazó ni modificó Supabase hospedado.

## 5. Migraciones y datos

En PostgreSQL 17 descartable se aplicaron roles/esquemas separados y la secuencia Catalog base + Outbox H5 `0001` + transporte Taxonomy `0002` + retry receipts `0003`; y Bulk baseline/migraciones hasta `0008_h5_outbox_delivery.sql`. Aunque la lista histórica de MK-001 menciona Bulk 0001–0007, `0008` ya está en master y es parte del Outbox H5 vigente, por lo que se conserva y prueba. La migración candidata `0003_bulk_retry_receipts.sql` se reejecutó con salida exitosa.

Comprobaciones locales reportadas PASS: los roles `bulk_app` y `catalog_app` no pudieron leer las tablas del otro esquema; se preserva aislamiento. El workflow #273 repitió creación de roles, migraciones, denegaciones y E2E en PostgreSQL 17; run `45469317255` asociado al HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204` concluyó `success`.

Supabase compartido: solo lectura/no se ejecutó DDL/DML en esta intervención. No se recalculó aquí el inventario de migraciones compartidas; el snapshot anterior era histórico y no debe considerarse el estado vigente. Aplicación SQL futura: pendiente de ventana/proceso de release y verificación de inventario/checksums; no ejecutar desde esta evidencia local.

## 6. Pruebas reproducibles

| Comando/ejecución | SHA asociado | Resultado |
|---|---|---|
| `npm run typecheck` | #273 HEAD `b19f2dff...` | PASS |
| `npm run build:bulk-svc` | #273 HEAD `b19f2dff...` | PASS |
| `npm run build:catalog-svc` | #273 HEAD `b19f2dff...` | PASS |
| Catalog unitarias enfocadas | código retry antes de #273 final | 60/60 PASS |
| `npm run test:e2e -- apps/catalog-svc/test/postgres.persistence.e2e-spec.ts` | `dec595f995046f7f1ce17c789a2ebfd92e931e64` | 103/103 PASS en PostgreSQL descartable |
| `npm run test:e2e -- apps/catalog-svc/test/postgres.persistence.e2e-spec.ts -t "BULK"` | runtime retry | 12 PASS, 91 SKIPPED por filtro |
| `npm test -- apps/bulk-svc/src` | Backend #271 | 174 PASS, 38 SKIPPED, 1 suite skipped |
| E2E Bulk messaging/outage/app | Backend #271 | 6 PASS, 18 SKIPPED, 1 suite skipped |
| E2E conjunto en PR #273 | `b19f2dffdd1101b179abf5f1c5011d4de0948204` | 1/1 PASS; workflow run `45469317255`, integration success |
| E2E local combinado de Gateway + Bulk/Catalog | Backend base `49bab9e2075819d922c63b06fcc6fc6ac16ce703` | 6/6 PASS, cero omitidos; [JSON preservado](evidencias/mk001-bulk/bulk-catalog-retry-local-2026-11-24-base-49bab9e.json) |
| E2E local posterior a cambios adicionales | PR #274 | NO EJECUTADO; la suite de contenedores se ejecuta en Actions como entorno descartable |
| Workflow integración oficial PR #274 | PR HEAD `2d276b3522ce09f3f7293e568251fb43aad9b24d`; base `49bab9e2075819d922c63b06fcc6fc6ac16ce703`; SHA integrado `ad30d496cad9256efdc930925a321647a648465e` | 8/8 PASS, cero omitidos, run `45495393575`; artifact `14967813955`: [JSON](evidencias/mk001-bulk/run-45495393575/bulk-h5-e2e.json), [JUnit](evidencias/mk001-bulk/run-45495393575/bulk-h5-e2e.junit.xml), [escenarios](evidencias/mk001-bulk/run-45495393575/bulk-h5-scenarios.json), [metadatos](evidencias/mk001-bulk/run-45495393575/run-metadata.json) |
| Frontend `npm run test:unit:bulk` | Frontend #93 HEAD `8665ce65086bb456573f82e8146f941bb50eb617` | 98/98 PASS |
| Frontend `npm run test:e2e:smoke:bulk` | mismo HEAD | 4/4 PASS |
| Frontend `npm run test:e2e:bulk:api` | mismo HEAD | 7/7 PASS |
| Frontend build con `VITE_DATA_MODE=mock` y `api` | mismo HEAD | ambos PASS; modo no se infiere si falta la variable |
| Prettier, `git diff --check`, YAML y `bash -n` workflow | Backend #273 HEAD | PASS |

En HEAD ya integrado `49bab9e2075819d922c63b06fcc6fc6ac16ce703`, los runs post-merge `45470786170` y `45470785787` finalizaron `success`. En PR #274 los jobs generales siguen `skipped` por Draft; no se cuentan como PASS. La integración dedicada `45495393575` pasó 8/8 con cero omitidos. CD Azure requiere `workflow_dispatch`; no se ejecutó. #274 sigue Draft y no se fusionó.

## 7. Performance

Benchmark local comparable, 1000 solicitudes por combinación de concurrencia (3,000 por variante), después de 10 warmups en cada combinación; el candidato final se midió sin 503/timeouts. No es tráfico compartido ni una prueba Azure/APIM. Hardware, proceso local y método se mantuvieron comparables según los artefactos del trabajo.

| Concurrencia | Baseline p50 / p95 / p99 ms | Baseline req/s | Candidato p50 / p95 / p99 ms | Candidato req/s |
|---:|---:|---:|---:|---:|
| 1 | 34.36 / 150.95 / 222.11 | 20.57 | 34.15 / 130.85 / 207.64 | 21.10 |
| 8 | 107.22 / 234.90 / 596.48 | 59.99 | 125.16 / 367.63 / 642.74 | 51.28 |
| 32 | 669.04 / 1446.83 / 1977.64 | 41.00 | 476.38 / 1093.87 / 1245.81 | 58.30 |

Baseline SHA `c73ed61c533a21787d1dab22aa79cd83ff77da14`; candidato SHA `af5a6b4e0e7f4cc7a5d32fcf3694d19cb6db9660`. Resultado mixto: c1 p95 mejora ~13%, c8 empeora ~56%, c32 mejora ~24%; throughput c32 mejora ~42% y c8 cae ~14.5%. Por ello no se declara mejora general. Carga fue de endpoint local y no acredita tamaños XLSX máximos, memoria, ASB redelivery, APIM ni umbral acordado. Los CSV/JSON originales están adjuntos en [evidencias de performance](evidencias/mk001-bulk/performance/README.md).

## 8. Estado operativo y bloqueos concretos

| Condición | Estado |
|---|---|
| Código completo Bulk MK-001 | NO certificado todavía; permanecen brechas de integración Frontend, recuperación, migraciones y matriz de archivos enumeradas en la matriz |
| Merge | Backend/Frontend integrados: #93, #262, #271 y #273; Backend #274 y Docs #144 siguen Draft/sin merge; PR nuevo de integración real Frontend aún no está abierto |
| CI completa | HEAD #274 tiene integración dedicada 8/8 PASS; el CI general está `skipped` en Draft. Checks de los merges previos se reportan por SHA/run en §6 |
| Compatibilidad contractual | Implementación alineada con `0.7.0-rc.3` en alcance inspeccionado; no se declara homologación externa |
| PostgreSQL 17 descartable | PASS para secuencia del workflow y E2E de alcance descrito |
| Despliegue | NO REALIZADO |
| Supabase compartido modificado | NO |
| Flags compartidos/productivos activados | NO |
| Azure Service Bus compartido/real | NO probado ni modificado |

- **GitHub reviewers/branch protection | PR #274 y PR Docs de certificación | requieren revisión/aprobación aplicable y todos los checks obligatorios verdes sobre HEAD final.** No se omiten protecciones.
- **Owner Azure/arquitectura | operación Service Bus en runtime Azure | desbloquea aprovisionamiento y credenciales/identidad de prueba autorizadas, con evidencia por ambiente.** No solicitado ni ejecutado bajo la prohibición de tocar recursos.
- **Owner G7 | emitir JWT/grants reales | desbloquea E2E autenticado con identidad institucional aprobada.** La prueba actual solo valida JWT firmado de prueba.
- **G5/consumidores externos | homologación del contrato/operación que les aplique | requiere aceptación verificable; no se atribuye por silencio.**
- **Owner de release/DB | aplicar migraciones a Supabase compartido | requiere inventario vigente, procedimiento aprobado y ventana de release.** No ejecutar aquí.
- **Docker local:** no es dependencia pendiente de cierre. Las pruebas con contenedores se ejecutan en Actions y el run `45495393575` inició y eliminó sus recursos descartables.

## 9. Guía de aplicación futura (no ejecutada)

Antes de release, congelar SHA y exportar backup/point-in-time recovery conforme a política del owner; obtener migraciones/checksums exactos del master fusionado; comparar catálogo de migraciones aplicado con el remoto sin mutar; ensayar en clon PostgreSQL 17; ejecutar en transacción cuando cada migración lo permita, respetando el orden por servicio/esquema y los locks documentados; verificar constraints/índices, cuentas y ACL mínimas, conteos/duplicados, readiness y Outbox/Inbox; validar rollback/compensación según soporte real de cada DDL; registrar postflight, commit SHA y resultado; detenerse ante checksum divergente o drift. No aplicar el SQL candidato en base compartida como parte de este informe.

La habilitación posterior requiere además preparar APIM/Gateway, Azure Service Bus Basic y colas autorizadas para destinatario, identidades/grants G7, Storage privado, URLs/llaves aprobadas y variables por entorno; desplegar solo mediante proceso de release autorizado; mantener flags OFF hasta homologación, pruebas de smoke y aprobación. R02/R10 no se vuelven operativos por esta documentación; R03/R14 siguen reservados/bloqueados.

## 10. Artefactos y seguimiento

- Backend E2E CI PR: [run 45469317255](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45469317255), HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204`. CI post-merge completada: [run 45470786170](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45470786170) y [Bulk messaging run 45470785787](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45470785787), SHA `49bab9e2075819d922c63b06fcc6fc6ac16ce703`.
- Backend PR #273: https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/273.
- Backend continuación Draft #274, HEAD `2d276b3522ce09f3f7293e568251fb43aad9b24d`, run dedicado `45495393575` 8/8, artifact `14967813955`: https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/274.
- Docs PR #144, HEAD `260e1e669f7e44f93249c48cfd5f6cc6ac16e6`, Draft; guard Pages ampliado y pruebas locales 15/15: https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/pull/144.
- Evidencia íntegra del run `45495393575`: JSON, JUnit, escenarios, versiones y tres SHAs en `evidencias/mk001-bulk/run-45495393575/`.
- Frontend rama `trabajo/castilla/bulk-h5-integracion-real`, HEAD base `e322808d868bb89e2c645a1b069eb12728296d9f`; no existe aún PR ni E2E navegador contra Gateway/Bulk/Catalog reales.
- Frontend PR #93: https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/93.
- Catálogo H5 #262 y Bulk V3/H5 #271: enlaces en tabla de estado Git.
- Performance: los JSON/CSV históricos siguen en `evidencias/mk001-bulk/performance`; no se generó matriz nueva contra un baseline de operaciones equivalentes en este corte.

Este documento separa código, validación local/CI y operación. El alcance todavía no es CODE_COMPLETE ni MERGED: faltan escenarios de archivos/storage, fallos y reinicios, suite Browser→servicios reales, matriz de performance y revisión/checks generales. El estado externo permanece NOT_DEPLOYED y NOT_HOMOLOGATED_EXTERNALLY por la restricción explícita; no es un defecto de código. Los checks `skipped` no son PASS.
