# Cierre MK-001 Bulk H5 sin despliegue

**Corte:** 24/11/2026 (America/Lima)  
**Alcance:** Bulk B01–B08 y F01–F06, integración requerida de Catalog H5, pruebas locales/CI y documentación.  
**Estado del corte:** `PARTIAL`; no se declara `CODE_COMPLETE` mientras #273 no se fusione, la CI obligatoria no concluya y resten criterios de UI/performance/integración sin evidencia integral.  
**Despliegue:** NO REALIZADO.

## 1. Resumen ejecutivo

Se cerraron mediante merge normal Frontend #93, Catalog H5 #262 y Backend Bulk V3/H5 #271. Catalog Retry V4 / resultado V2 se presenta como PR sustituto #273, desde `master`, para trasladar selectivamente la contribución histórica #254 sin fusionar su base obsoleta. Al corte, #273 está Ready for Review, HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204`, integración focalizada verde; los restantes checks requeridos todavía se ejecutan. #254 permanece Draft y abierto hasta la fusión del sustituto.

La evidencia cubre PostgreSQL 17 descartable, servicios Bulk/Catalog reales, HTTP loopback, JWT RS256 de prueba y roles aislados. Storage es un doble de borde externo; Azure Service Bus y el emisor/grants G7 reales no participaron. La prueba no acredita Azure, APIM, homologación externa ni despliegue.

## 2. Estado Git y PRs

| Repo | PR | Resultado / SHA | Estado comprobado |
|---|---|---|---|
| Frontend | [#93](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/93) | merge `e322808d868bb89e2c645a1b069eb12728296d9f`; HEAD `8665ce65086bb456573f82e8146f941bb50eb617` | MERGED normal; unitarias, smoke, API y build local reportados PASS |
| Backend Catalog H5 | [#262](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/262) | merge `c73ed61c533a21787d1dab22aa79cd83ff77da14` | MERGED normal; rama reconciliada en el master utilizado para #271 |
| Backend Bulk V3/H5 | [#271](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/271) | merge `133a051acf187e0a75c074e38aa284a8ea226250`; HEAD origen `af5a6b4e0e7f4cc7a5d32fcf3694d19cb6db9660` | MERGED normal; flags apagados |
| Backend Catalog Retry V4/V2 | [#273](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/273) | rama `trabajo/castilla/catalog-bulk-retry-integracion-final`; HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204` | OPEN, Ready; integration E2E pass, resto de gates pendiente al corte |
| Backend legado | [#254](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/254) | HEAD histórico `f259df772c4f3f5473449cbe2f69eb0dde40b79e` | OPEN Draft, no fusionar sobre base `poma`; mantener hasta #273 mergeado y trazado |
| Backend antiguo | #243 | — | CLOSED sin merge; no se recuperó completo |

Los merge SHAs se consultaron en GitHub. La prueba explícita de ancestralidad del master posterior a la fusión de #273 queda pendiente hasta que exista ese merge. No hubo force push ni bypass.

## 3. Matriz de guía MK-001

Los estados expresan evidencia de este corte; `PARTIAL` no implica que todo el criterio contractual esté cerrado.

### Bulk Backend B01–B08

| ID | Estado | Evidencia y límite |
|---|---|---|
| B01 Plantilla/roundtrip | PARTIAL | Contratos y frontend cubiertos por pruebas Bulk; falta reportar una matriz completa CSV/XLSX por contrato y roundtrip de extremo a extremo asociado al SHA fusionado. |
| B02 Admisión durable/atomicidad | PARTIAL | Backend #271 y E2E focalizado ejecutan Bulk/PostgreSQL; job #273 `integration` confirma el esquema y flujo de integración. La admisión vía Gateway y todos los escenarios de fallo aún requieren sus checks/escenarios completos. |
| B03 Idempotencia/owner/correlación | PARTIAL | Persistencia e idempotencia existentes más pruebas focalizadas. La matriz integral de concurrencia, owner ajeno, conflicto de correlación y timeouts aún no se ha ejecutado completa en un solo E2E. |
| B04 Estado por fila/dominio y resultados | PARTIAL | Durabilidad de Inbox/snapshot y resultados ejercitada en pruebas Bulk/Catalog; resultado Catalog V2 depende del merge de #273. |
| B05 Retry selectivo Catalog | PARTIAL | Implementación Catalog V4/result V2 en #273; pruebas PostgreSQL completas Catalog 103/103 en revisión corregida (HEAD previo `dec595f995046f7f1ce17c789a2ebfd92e931e64`), y E2E permanente 1/1 en HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204`. Falta merge y CI obligatoria verde; Azure ASB no probado. |
| B06 Reportes/exportaciones auténticos | PARTIAL | Frontend usa Blob real y build/API suites pasan; no se completó la auditoría navegador integral ni el E2E real de exportación con Storage. |
| B07 Claim-check V3 privado | PARTIAL | #271 integra contenido privado/autenticado; prueba #273 usa HTTP loopback y guard real con JWT de prueba. Storage sigue siendo un doble externo y faltan escenarios negativos completos del inventario contractual. |
| B08 R02/R10 / R03/R14 | PARTIAL | Flags V3 OFF y estados no habilitados se preservan; no hay autorización/homologación para declarar operativo ningún flujo externo pendiente. |

### Bulk Frontend F01–F06

| ID | Estado | Evidencia y límite |
|---|---|---|
| F01 Selección/validación/resumen | PARTIAL | Suite unitaria Bulk 98/98; Playwright smoke 4/4 y API 7/7. No se hizo auditoría manual de navegador de todos los estados CSV/XLSX/accesibilidad. |
| F02 Confirmación/admisión/recuperación | PARTIAL | Implementación fusionada; falta ejecutar el conjunto completo de doble clic, refresh, cambio de usuario y timeout antes/después de commit en un entorno conjunto. |
| F03 Seguimiento/errores | PARTIAL | Tests smoke/API y polling disponibles; no se trazaron todos los estados, cancelación/backoff y snapshot histórico bajo fallos en una auditoría completa. |
| F04 Reanudación | PARTIAL | Catalog se presenta a #273; elegibilidad UI limitada a Catalog y excluye Inventory según implementación, pero requiere CI final y E2E conjunto autenticado. |
| F05 Reportes/descargas | PARTIAL | Descarga Blob está implementada; la prueba integral de exportación autorizada, fallos de Storage, nombres saneados y accesibilidad sigue pendiente. |
| F06 Seguridad/usabilidad/accesibilidad | PARTIAL | Sin fallback silencioso a mock; builds `VITE_DATA_MODE=mock` y `api` pasan. Falta matriz de navegación/accesibilidad y auditoría de propietario/JWT en UI. |

## 4. Implementación y contratos

- Contratos objetivo: OpenAPI y AsyncAPI H5 `0.7.0-rc.3`; Docs indica `APPROVED_G6`, que no significa homologación externa.
- #271 conserva Outbox/Inbox durable, Service Bus Basic target, claim-check V3 y flags apagados.
- #273 porta receipts durables de Catalog por comando/fila, replay de resultado V2 y V4 con correlación raíz; mantiene autenticación legacy para flujo V1/V3.
- El workflow de integración anterior armaba PR históricos mediante merges/parches temporales. Se sustituyó por `.github/workflows/bulk-catalog-retry-integration.yml` en #273, ejecutando HEAD actual en PostgreSQL 17 y aplicando migraciones con orden explícito.
- El E2E permanente `apps/bulk-svc/test/bulk-catalog-retry.e2e-spec.ts` utiliza consumidores/servicios/guard Bulk y Catalog reales, HTTP loopback, JWT RS256 firmado de prueba y PostgreSQL. Storage (`put/get`) y emisión del token de prueba están aislados como bordes; no se suplanta el handler del consumidor.

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
| Frontend `npm run test:unit:bulk` | Frontend #93 HEAD `8665ce65086bb456573f82e8146f941bb50eb617` | 98/98 PASS |
| Frontend `npm run test:e2e:smoke:bulk` | mismo HEAD | 4/4 PASS |
| Frontend `npm run test:e2e:bulk:api` | mismo HEAD | 7/7 PASS |
| Frontend build con `VITE_DATA_MODE=mock` y `api` | mismo HEAD | ambos PASS; modo no se infiere si falta la variable |
| Prettier, `git diff --check`, YAML y `bash -n` workflow | Backend #273 HEAD | PASS |

Los checks obligatorios de GitHub para #273 seguían en ejecución al preparar esta revisión. Los checks que reportan `skipped` no se cuentan como PASS. Seguridad automatizada final y aprobación de revisión por SHA se registrarán tras el resultado de los checks/review.

## 7. Performance

Benchmark local comparable, 1000 solicitudes por combinación de concurrencia en baseline y 3000 muestras por combinación en candidato; el candidato se midió finalmente sin 503/timeouts. No es tráfico compartido ni una prueba Azure/APIM. Hardware, proceso local y método se mantuvieron comparables según los artefactos del trabajo.

| Concurrencia | Baseline p50 / p95 / p99 ms | Baseline req/s | Candidato p50 / p95 / p99 ms | Candidato req/s |
|---:|---:|---:|---:|---:|
| 1 | 34.36 / 150.95 / 222.11 | 20.57 | 34.15 / 130.85 / 207.64 | 21.10 |
| 8 | 107.22 / 234.90 / 596.48 | 59.99 | 125.16 / 367.63 / 642.74 | 51.28 |
| 32 | 669.04 / 1446.83 / 1977.64 | 41.00 | 476.38 / 1093.87 / 1245.81 | 58.30 |

Baseline SHA `c73ed61c533a21787d1dab22aa79cd83ff77da14`; candidato SHA `af5a6b4e0e7f4cc7a5d32fcf3694d19cb6db9660`. Resultado mixto: c1 p95 mejora ~13%, c8 empeora ~56%, c32 mejora ~24%; throughput c32 mejora ~42% y c8 cae ~14.5%. Por ello no se declara mejora general. Carga fue de endpoint local y no acredita tamaños XLSX máximos, memoria, ASB redelivery, APIM ni umbral acordado. Incorporar CSVs/JSON exactos de resultados al paquete de evidencia antes de promover este benchmark como evidencia plenamente reproducible.

## 8. Estado operativo y bloqueos concretos

| Condición | Estado |
|---|---|
| Código completo Bulk MK-001 | NO certificado en este corte; #273 pendiente de merge y la matriz B/F conserva PARTIAL |
| Merge | Parcial: #93, #262, #271 fusionados; #273 abierto |
| CI completa | NO al corte; run focalizado #273 PASS, checks restantes pendientes |
| Compatibilidad contractual | Implementación alineada con `0.7.0-rc.3` en alcance inspeccionado; no se declara homologación externa |
| PostgreSQL 17 descartable | PASS para secuencia del workflow y E2E de alcance descrito |
| Despliegue | NO REALIZADO |
| Supabase compartido modificado | NO |
| Flags compartidos/productivos activados | NO |
| Azure Service Bus compartido/real | NO probado ni modificado |

- **GitHub reviewers/branch protection | fusión de #273 | requiere revisión/aprobación aplicable y todos los checks obligatorios verdes sobre HEAD final.** No se omiten protecciones.
- **Owner Azure/arquitectura | operación Service Bus en runtime Azure | desbloquea aprovisionamiento y credenciales/identidad de prueba autorizadas, con evidencia por ambiente.** No solicitado ni ejecutado bajo la prohibición de tocar recursos.
- **Owner G7 | emitir JWT/grants reales | desbloquea E2E autenticado con identidad institucional aprobada.** La prueba actual solo valida JWT firmado de prueba.
- **G5/consumidores externos | homologación del contrato/operación que les aplique | requiere aceptación verificable; no se atribuye por silencio.**
- **Owner de release/DB | aplicar migraciones a Supabase compartido | requiere inventario vigente, procedimiento aprobado y ventana de release.** No ejecutar aquí.

## 9. Guía de aplicación futura (no ejecutada)

Antes de release, congelar SHA y exportar backup/point-in-time recovery conforme a política del owner; obtener migraciones/checksums exactos del master fusionado; comparar catálogo de migraciones aplicado con el remoto sin mutar; ensayar en clon PostgreSQL 17; ejecutar en transacción cuando cada migración lo permita, respetando el orden por servicio/esquema y los locks documentados; verificar constraints/índices, cuentas y ACL mínimas, conteos/duplicados, readiness y Outbox/Inbox; validar rollback/compensación según soporte real de cada DDL; registrar postflight, commit SHA y resultado; detenerse ante checksum divergente o drift. No aplicar el SQL candidato en base compartida como parte de este informe.

La habilitación posterior requiere además preparar APIM/Gateway, Azure Service Bus Basic y colas autorizadas para destinatario, identidades/grants G7, Storage privado, URLs/llaves aprobadas y variables por entorno; desplegar solo mediante proceso de release autorizado; mantener flags OFF hasta homologación, pruebas de smoke y aprobación. R02/R10 no se vuelven operativos por esta documentación; R03/R14 siguen reservados/bloqueados.

## 10. Artefactos y seguimiento

- Backend E2E CI: [run 45469317255](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45469317255), HEAD `b19f2dffdd1101b179abf5f1c5011d4de0948204`.
- Backend PR #273: https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/273.
- Frontend PR #93: https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/pull/93.
- Catálogo H5 #262 y Bulk V3/H5 #271: enlaces en tabla de estado Git.
- Performance: copiar y versionar en el repositorio Docs los artefactos de medición raw asociados a los SHAs antes de cerrar la evidencia PERF; este corte conserva métricas resumidas.

Este documento es una evidencia de cierre por bounded context MK-001, no certifica que Hito 5 G6 esté completo. Se actualizará el estado tras el resultado de #273 y los demás checks, sin convertir `skipped` en PASS ni pruebas locales en despliegue.

