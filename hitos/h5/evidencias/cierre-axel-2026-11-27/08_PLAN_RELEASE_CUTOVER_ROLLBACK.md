# Plan Accionable de Release, Cutover y Rollback — G6 Hito 5 (2026-11-27)

> **Estado:** CORS de APIM e Inventory R10 aplicados y verificados. El despliegue del candidato y las pruebas L2 siguen pendientes del gate de release.

## 1. Estado auditado y preflight operativo

- **Backend #307** está Ready for Review en `de4a54ba0615836462901133169c4b0f19c0c9c9`. El CI de PR tuvo 22 jobs aprobados y un benchmark opt-in omitido. La aprobación técnica, la conformidad final de merge y la autorización de cada ejecución CD son hitos independientes. [CI exacto](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/46081541712)
- **Gateway, release general.** Usar `gateway_route_profile=standard`. Mantener Modalidad B, las restricciones IP y el destino existente de `g5-h5`. El smoke del CD valida el recibo de revisión y digest, health por origen privado autorizado, rechazo anónimo en APIM con correlación y rechazo directo HTTP 403. La ejecución privada `azure-h5-smoke-chile-8hxsolc` verificó HTTP en las revisiones vigentes. El cambio de tráfico está cubierto con fixtures. La prueba autenticada hasta el Gateway candidato se registra después del despliegue.
- **G5 específico.** El caso `g5-labelled` queda reservado a una prueba separada. Antes de usarlo, probar el health de la URL etiquetada desde el runner autorizado con Modalidad B y las restricciones IP activas. Si devuelve 403, corregir el método de smoke dentro del acceso autorizado antes de realizar la prueba etiquetada.
- **Bulk, Combos y Taxonomy.** Las seis variables del Environment quedaron verificadas. La ejecución privada `azure-h5-smoke-chile-8hxsolc` validó DNS, TLS, health y readiness HTTP 200, y rutas protegidas HTTP 401 con las revisiones vigentes.
- **Price Audit, bloqueo de su oleada.** El principal OIDC de `azure-h5-chile` carece de `Microsoft.App/containerApps/revisions/activate/action` y `Microsoft.App/containerApps/revisions/deactivate/action` sobre `price-audit-svc`. Acreditar ambos permisos antes del CD. El CI cubre corte y rollback con fixtures. La revisión vigente `price-audit-svc--0000001` recibe el 100 % y la app conserva modo Multiple y escala 1/1.
- **APIM.** El delta de #305 está incorporado una vez en `7ecee3f`. CORS permite el origen exacto de Vercel. [Evidencia](artefactos/APIM_CORS_POST_CAMBIO_2026-11-27.json).

## 2. Checklist de autorizaciones y condiciones

| Gate | Autoridad requerida | Criterio verificable antes de avanzar |
|---|---|---|
| Merge de Backend #307 | Marco Castilla | Conformidad sobre el SHA auditado y check requerido verde. Integrar solo #307. |
| Publicación de imágenes | Flujo oficial Backend | CI de evento push en el SHA exacto resultante en master. Registrar los nueve digests resultantes. |
| CD individual de Chile | Marco Castilla, Environment `azure-h5-chile` | Verificar protecciones, permisos y ventana de CD. Compartir enlace y run ID antes de cada aprobación humana. Una ejecución por servicio. |
| Price Audit | Responsable Azure RBAC / Marco Castilla | Acreditar activación y desactivación de revisiones para el principal en el recurso exacto. Verificar modo, tráfico, escala y reversión antes de la oleada. |
| Base de datos | Owners de BD y dominios | Verificar los dos historiales de R10 y los objetos equivalentes de Taxonomy en solo lectura. Usar el respaldo lógico acotado ya ensayado como evidencia del cambio R10. |
| Pruebas en integración | G6 / responsables del entorno | Usar datos sintéticos y carga gradual. Coordinar pruebas que impliquen reinicio, rollback o afectación a consumidores. |
| Revisión Frontend y Docs | Responsables de #102 y #152 | Incorporar evidencia autenticada de #102 y digests, recibos y certificación en #152 antes de su integración. |

## 3. Orden de despliegue por dependencias (Wave 0 → Wave 4)

### Wave 0 — Preflight de BD, Snapshot y Conciliación (solo lectura)
1. Ejecutar `hitos/h5/cierre-post-r2/BD_PREDEPLOY_CHECKS.sql` + las 4 consultas `READ ONLY` de diagnóstico de `catalog.outbox` (`05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md`).
2. Corroborar el respaldo lógico acotado ya verificado y el readback de R10. Cualquier cambio adicional de BD requiere un punto de recuperación adecuado y aprobación específica.
3. Guardar snapshot JSON de revisiones ACA actuales (`artefactos/azure-aca-readonly-snapshot-2026-11-27.json`) y XML de políticas APIM actuales como línea base de rollback.
4. Confirmar que las 19 colas en `g6-sb-h5-chile-261127` están `Active` con `active=0, dlq=0` y que las Managed Identities ACA tienen RBAC mínimo (`Azure Service Bus Data Sender` / `Data Receiver` por cola según matriz).

### Wave 1 — Verificación en solo lectura de esquemas ya aplicados
1. **Inventory R10 (`Taco` / Owner BD):** cambio incremental aplicado como `po_inventory_owner`. Verificar los cuatro destinos y el historial `20261127200858` en [el readback](artefactos/SUPABASE_R10_Y_CATALOG_PREFLIGHT_2026-11-27.json).
2. **Taxonomy R09/R18 (`López` / Owner BD):** verificar en solo lectura la equivalencia de `outbox_delivery`, función, trigger, eventos y ACL con [la reconciliación de esquema e historiales](05_MIGRACIONES_Y_DIAGNOSTICO_CATALOG_LEGACY.md). Conservar los dos registros H5 globales y el ledger del servicio hasta `0005`. **Queda excluida la ejecución o el registro de `0006` completa.** Ante una desviación funcional demostrada, ensayar un diferencial versionado y reversible en una transacción completa. R18 requiere el despliegue y la corrida L2.
3. **Pricing (`Vera` / Owner BD):** confirmar vía `SELECT` la entrada global `g6_h5_pricing_0003_service_bus_routes_r2` y los cuatro destinos compatibles. Si aparece una desviación, reconciliarla antes del release.
4. **Regla inmutable:** NO tocar `catalog.outbox` legacy (`RABBITMQ`) ni alterar filas de `schema_migrations` aplicadas.

### Wave 2 — Publicación y CD por digest

Tras la aprobación, integrar #307, esperar CI de push en el SHA exacto de master y publicar las nueve imágenes con `publish-only-images.yml`. Usar `cd-services-azure.yml` con `destination=chile-shared`, un servicio por run. La selección `all` queda excluida en Chile. Capturar revisión y digest previos, configuración, reglas de tráfico, baseline de colas, aprobación del Environment, recibo del run y smoke de cada servicio. Conservar flags y el tráfico pactados al desplegar.

1. Desplegar primero los servicios que superen su preflight y cuyas dependencias estén verificadas. La oleada de Price Audit permanece bloqueada hasta acreditar sus dos acciones RBAC. Mantener modo Multiple y escala 1/1. Verificar salud y digest con el tráfico fijado a la revisión previa y comprobar el consumidor único al terminar el corte.
2. Desplegar Gateway con perfil `standard` y verificar el smoke privado más los controles APIM y anti-bypass. Conservar la etiqueta y Modalidad B.
3. Con el candidato desplegado, validar Frontend #102 desde Vercel por APIM usando la sesión existente con rol `GESTOR_COMERCIAL`. Conservar los resultados Playwright previos como L1 y registrar la revisión y digest del candidato junto con el identificador de correlación de la solicitud autorizada.

### Wave 3 — Activación Progresiva de Flags Service Bus y Certificación L2 (H5-04B)
Comprobar los flags y el alcance de cada flujo contra el release. Registrar baseline y deltas de Backlog y DLQ entre pasos.
1. **Paso 3.1 — H5-04B Flujo #1 (`R16: Pricing → Price Audit`, owner Vera):**
   - Verificar `SEND` en `pricing-svc` y `RECEIVE` en `price-audit-svc` para `g6.price-audit.from.pricing`.
   - Con datos sintéticos y ventana coordinada, observar entregas antes, durante y después del corte. Durante el calentamiento dos revisiones podrían recibir aunque la candidata tenga peso HTTP 0. Conservar el mismo `message_id` para contrastar redelivery, Inbox, ACK, DLQ y un único efecto en `price_audit.price_audit_log`.
   - Verificar que la revisión anterior queda desactivada y con cero réplicas. En el ensayo supervisado de recuperación, verificar que retoma el consumo y que el candidato se retira. Conservar revisión, digest, hora, correlación y recibo del run.
2. **Paso 3.2 — H5-04B Flujo #2 (`R18: Taxonomy → Catalog`, owner López/Poma):**
   - Verificar `SEND` en Taxonomy y `RECEIVE` en Catalog para `g6.catalog.from.taxonomy`. Comprobar R09 si corresponde al release.
   - Ejecutar smoke L2 con los 6 eventos contractuales de R18 + verificación de barrera, correlación, recuperación y DLQ = 0.
   - *(Contingencia solo bajo bloqueo objetivo documentado de R18 y aprobación expresa del owner: activar `R07 Catalog → Pricing` manteniendo R18 visible en matriz.)*
3. **Paso 3.3 — Flujo Bulk (`R02 → R10`, owners Castilla/Taco):**
   - Verificar `RECEIVE` R02 y `SEND` R10 en Inventory y `RECEIVE` R10 en Bulk.
   - Ejecutar lote sintético Bulk → Inventory → Bulk confirmando estado terminal `COMPLETED`, stock aplicado una sola vez y DLQ = 0.
4. **Paso 3.4 — `N01 Promotions` (owner Cueva, si el manifest lo habilita):**
   - Confirmar grants G7/G5 y ejecutar admisión `202` → `COMPLETED` + restauración + idempotencia.

### Wave 4 — Smoke Post-Cutover, APIM-T / INT L2 y Performance Autorizada
1. Ejecutar `APIM-T01..T08` con `GESTOR_COMERCIAL` para operaciones autorizadas, `401` con identidad ausente o inválida y `403` donde el contrato permita probar una denegación legítima. Correlacionar la operación positiva hasta Gateway. Casos que requieran otros clientes o roles quedan `BLOCKED_AUTH` en L2, con cobertura sintética en L1.
2. Ejecutar `INT-01..INT-10` L2 (y L3 bilateral con G5/G1 cuando haya ventana).
3. Ejecutar los casos disponibles de `PERF-01..PERF-08` y `RL-01..RL-06` en integración autorizada, con 1, 5 y 20 usuarios virtuales, tres repeticiones comparables, cargas progresivas y detención ante degradación.

---

## 4. Criterios de Aborto y Procedimiento de Rollback

### 4.1 Criterios de aborto inmediato
Abortar avance de ola si ocurre cualquiera de las siguientes condiciones:
- Falla el health interno del Gateway o la sonda de readiness contractual de un microservicio, o se mantiene un 503 durante más de 60 s.
- Aumento no esperado de errores `5xx` (> 1%) o fugas de rutas internas en APIM (`!= 404`).
- Crecimiento de `deadLetterMessageCount > 0` en pruebas sintéticas válidas o evidencia de efecto comercial duplicado en Inbox/Kardex/Price Audit.
- Fallo de validación JWT contra JWKS de G7 (`500`/`401` con token válido confirmado).

### 4.2 Recuperación supervisada

1. Detener el avance de la oleada y la carga sintética. Preservar los recibos, Outbox, Inbox, colas y DLQ. Mantener el orden de recuperación del CD y su hash estricto de configuración. Cualquier contención de flags que cambie ese hash debe conciliarse expresamente antes de recuperar.
2. Usar `recover` del run correspondiente y la aprobación humana del Environment. Verificar el digest y la configuración según el recibo. Para Price Audit, confirmar reactivación sana de la revisión anterior cuando proceda, recuperación de HTTP y R16, y retiro del candidato. Conservar Modalidad B y la etiqueta G5 durante la recuperación del Gateway.
3. Ejecutar el smoke posterior y registrar revisión, digest, tráfico, resultado y estado de colas. Si el mecanismo detecta drift o falta evidencia del estado, conservar el recibo y escalar al responsable operativo.
4. Tratar cualquier restauración de APIM o de BD como cambio separado. En Inventory, el rollback de R10 requiere autorización específica y aborta si existen entregas hacia `g6.bulk.from.inventory`. Conservar los dos historiales de Taxonomy.

[Runbook de CD del candidato](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/de4a54ba0615836462901133169c4b0f19c0c9c9/ops/azure/container-apps/CHILE_SHARED_DEPLOYMENT.md)
