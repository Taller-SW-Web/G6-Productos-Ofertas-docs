# Iteración 7 — checkpoint de ejecución en curso

Fecha: 2026-11-26 (America/Lima). Rama en los tres repositorios: `trabajo/castilla/h5-integral-r2`. SIN ISSUE nuevo. No se realiza merge ni despliegue.

HEAD inicial verificado: Backend `4f59235c0b907a9a96e91ae2e6f9efbd7b7c8c6f`; Frontend `3b07806b8d3a469e6a5459cb44353969343d3497`; Docs `597db8cc4e602d7edd96c381f2a8eb5eeeee9a1e`. Los cambios de esta iteración todavía están en el working tree; los resultados de abajo no se atribuyen a esos HEAD sin el diff.

## Causas comprobadas y correcciones

- El rechazo inicial de Catalog V4 estaba al entrar al método, por ausencia de `CATALOG_BULK_RETRY_V1_ENABLED=true` en el laboratorio, antes de adquirir identidad. Se habilitó únicamente en el stack local.
- Pricing persistía `pricing.product.initialization.completed/rejected` sin crear `outbox_delivery` a `g6.catalog.from.pricing`. Se usa el mismo helper transaccional de hechos y entregas; se conserva el timestamp SQL histórico.
- Bulk publicaba R02/R03 antes de confirmar Catalog. Ante el rechazo transitorio, un resultado Pricing tardío quedaba superseded y el retry dejaba dependencias sin concluir. Se retienen los comandos originales hasta confirmar las filas de su familia. Pricing se particiona por familia para no detener las demás.
- El verificador del umbral global consultaba una tabla incorrecta; ahora comprueba exactamente la fila global de `inventory.stock_threshold_override` y el valor enviado.
- Casos negativos: slug inexistente con canal contractual; listados de cupones y auditoría con `pagina=0`, exigiendo 400/VALIDACION.
- El fixture administrativo del certificador de mensajería usaba nombres inexistentes para imagen y perfil físico. Se corrigió y se aporta stock explícito de fixture después de inicialización. No se confunde ese stock con evidencia de recepción real.
- El cierre por señal terminaba abruptamente Node en Windows. Se solicita limpieza por IPC al dueño del stack para liberar sus propios servicios y PostgreSQL.
- Una suite unitaria abortaba en beforeAll por configurar `PUBLIC_READ_ONLY`, ya rechazado por la política de esta rama. Sus pruebas del transporte usan `SIMULATED_AUTH` explícito de test; las pruebas separadas de G7 y sus denegaciones se conservan.

## Resultados ejecutados hasta este checkpoint

- Pruebas focalizadas iniciales: 34/34 PASS.
- Pricing PostgreSQL R03/R14/R15/R16/R17: 3/3 PASS, incluidos resultado aceptado, rechazado y duplicado sin otra entrega.
- Bulk PostgreSQL: 3/3 PASS, incluida espera por Catalog, aislamiento entre familias e IDs originales al recuperar.
- Suite unitaria completa posterior a Pricing/Taxonomy: 2928 PASS, 0 FAIL, 101 SKIP, `success=true`, sin suites fallidas. Debe repetirse después del cambio posterior de Bulk.
- Typecheck y build de Backend: PASS tras las correcciones de tipos y Bulk.
- Lint Backend: exit 0. Pendiente repetir sobre el diff final.
- HTTP integral: 157/158 PASS en la primera corrida de esta iteración. Después de corregir Bulk, `--retry-only`: 1/1 PASS. Esta corrida focalizada no es 158/158.
- 19 recorridos: aún no certificados; reejecución en curso tras reparar los fixtures. Se mantienen visibles los fallos previos, sin ampliar timeouts.
- Frontend unitarias/typecheck/build/lint: en ejecución. Playwright no ejecutado por exclusión expresa.

## Preflight Azure real (solo lectura)

Namespace aislado `g6-sb-h5-int-32cdqgbnlk7ow`, Basic, activo en Chile Central, 19 colas existentes. Mensajes activos: 0 en el inventario consultado. DLQ de `g6.catalog.from.taxonomy`: 2 preexistentes, conservados. ACI del resource group: ninguno en la consulta. No se publica ningún mensaje ni se crean/modifican recursos.

DNS y TCP 5671/443 accesibles. `AzureCliCredential` obtiene token, sin registrarlo. Peek SDK por WebSocket con la identidad local: **UnauthorizedAccess**, falta claim `Listen`. No se usa el secreto de otro servicio ni se amplían roles.

Estado transporte real: **NOT_RUN_BLOCKED_INFRA** para la certificación funcional. Owner: responsable del laboratorio Azure/G6. Operación: ejecución autenticada de los 19 recorridos sobre broker real. Desbloqueo: ejecutor autorizado y accesible con identidades/permisos Sender y Receiver por servicio y cola, conservando aislamiento y sin consumir datos ajenos. La existencia de colas y un token no prueban autorización ni transporte funcional.

`CODE_AND_LAB_FUNCTIONAL_READY=false` (aún no acreditado); `LOCAL_G6_GO=false`; `AZURE_G6_GO=false`.

Pendientes: corrida integral HTTP posterior a Bulk, cierre funcional y evidencia suficiente de los 19 recorridos, regresiones en stack limpio, auditoría de paridad/scopes/matrices y cobertura frontend. Continuar el objetivo; este archivo no es cierre de certificación.
