# Ejecución N01 Azure — 23/11/2026

## Estado

`PROBADO_EN_AZURE: PASS` para N01, aislado en el grupo `rg-g6-sb-h5-int-fork`, región Brazil South. Esta ejecución es nueva; no reutiliza el smoke histórico ni usa el Azure compartido de Chile. El ACI y PostgreSQL descartable se eliminaron al finalizar. La prueba no certifica homologación G5, autorización G7 del endpoint de evidencia, APIM ni despliegue de las cinco ACA.

## Código e infraestructura de la prueba

- Backend oficial `master`: SHA `fcf3dd983f5436221670e8c6a113fdd15cb76de9`.
- CI del evento `push`: run [45231779818](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45231779818), conclusión `success`.
- Namespace: `g6-sb-h5-int-32cdqgbnlk7ow`; cola: `g6.promotions.commands` (Basic).
- UAMI: `g6-h5-int-promotions`, con permisos Data Sender y Data Receiver comprobados sobre la cola.
- Ejecutor: ACI Linux temporal, sin IP ni puertos publicados, con PostgreSQL en `127.0.0.1` y la UAMI Promotions. Imágenes fijadas: `node:24.15.0-bookworm-slim@sha256:4e6b70dd6cbfc88c8157ba19aa3d9f9cce6ba4703576d55459e45efcbc9c5f5d` y `postgres:17.6-alpine@sha256:ef257d85f76e48da1c64832459b59fcaba1a4dac97bf5d7450c77753542eee94`.
- Se ejecutó sin modificar `apps/promotions-svc/h5/smoke-azure-restauracion.mjs`: `G6_H5_AZURE_SMOKE=isolated-restoration`, SHA exacto y cliente UAMI. El proyecto instaló dependencias, auditó 0 vulnerabilidades altas/críticas y compiló `promotions-svc` dentro del runner.
- El `what-if` ACI reportó una creación (el grupo temporal esperado) y 14 recursos existentes como `Ignore`.

## Resultado de Service Bus y PostgreSQL

| Comprobación | Resultado observado |
|---|---|
| Admisión durable | `ACCEPTED`; Outbox registrada |
| MessageId | `d99fa6f0-a773-4eaa-bc4a-a88ad04d96fc` |
| Correlation ID | `db020a65-f1f6-4bd5-bf4e-2bc480a0e521` |
| Operation ID | `c252a019-2954-4d03-bd0e-ab6f7f0e5b88` |
| Reinicio del worker | 1 |
| Fallo transitorio / abandono | 1 |
| Entregas / settlements | 2 |
| Resultado terminal | `REJECTED/COUPON_IDENTITY_MISMATCH` (esperado para restauración sin consumo previo) |
| Outbox SQL | `attempts=1`, `sent_at` presente |
| Inbox SQL | 1 fila completada |
| Recibo SQL | 1 |
| Efectos de cupón SQL | 0 |
| Mensajes activos posteriores | 0 |
| Mensajes DLQ posteriores | 0 |
| Exit code runner / PostgreSQL | 0 / 0 |

El ACI observado terminó ambos contenedores. Los logs se consultaron con `az container logs` antes de eliminar exclusivamente ese grupo. Se verificó que la lista de ACI del resource group quedó vacía y que la cola permaneció drenada.

## Evidencia recuperable

El resumen sanitizado y los logs originales recuperados de Azure quedaron localmente en `%LOCALAPPDATA%\G6-H5\evidence\2026-11-23\n01` (`summary.json`, `runner.log`, `postgres.log`). Este documento preserva los resultados no secretos y las claves de correlación para revisión; no contiene credenciales, connection strings, subscription IDs ni tenant IDs.

## Preparación ACA y estado de artefactos

- `IMPLEMENTADO`: módulo Bicep específico para cinco ACA privadas, con digest como parámetro, Caddy, probes, límites y flags G7/G5 cerrados por defecto. Bicep compila.
- `DESPLEGADO`: 0/5. Azure CLI no encontró Container Apps en el grupo; el Environment aislado existente está en Brazil South.
- `PROBADO_EN_AZURE`: solo N01. No se ejecutó `what-if` ACA ni se desplegaron apps.
- `PROBADO_CON_G7`: `BLOCKED`; no hay configuración/credenciales G7 autorizadas para el runtime HTTP y Gateway.
- `HOMOLOGADO_G5`: `BLOCKED`; siguen pendientes el endpoint G5 de evidencia de cupón y su concesión G7 correspondiente.
- La punta oficial de master avanzó a `fcf3dd983f5436221670e8c6a113fdd15cb76de9`. El inventario GHCR observó los cinco digests previos asociados a la etiqueta `9e4ac0af2a3ea882784413401bd5016ff611caa2`, pero no artefactos etiquetados con la punta actual. No se desplegaron imágenes de una SHA anterior como si correspondieran a la actual.
- El GitHub Environment `azure-h5` conserva `required_reviewers` y branch policy; hay dos revisores requeridos. El runner organizacional `azure-h5-smoke` existe, pero estaba `offline`. El Container Apps Job Azure con el mismo nombre está `Succeeded`; no se confunde con un runner registrado en GitHub.
- APIM no fue parte de esta ejecución N01; esta evidencia no acredita H5-04A.

## Bloqueos y clasificación

- `BLOCKED_IMAGE_SHA`: no existen digests de las cinco imágenes oficiales para el HEAD actual; responsable: pipeline oficial de publicación Backend; desbloqueo: publicar cada servicio mediante el mecanismo oficial para el SHA actual y verificar tag OCI más digest.
- `BLOCKED_G7_RUNTIME_CONFIG`: no hay configuración G7 autorizada suministrada para los servicios; responsable: Seguridad G7 / responsable de configuración del entorno; desbloqueo: issuer, JWKS, audiencia y concesiones oficiales probados sin exponer secretos.
- `BLOCKED_RUNNER_OFFLINE`: runner GitHub `azure-h5-smoke` figura `offline`; responsable: administrador del runner; desbloqueo: registrar y dejar online el runner privado con acceso a ACA, sin revelar token.
- `BLOCKED_PR_CREATE`: la creación del Draft PR mediante integración GitHub respondió HTTP 403 `Resource not accessible by integration`; el inicio de `gh pr create` fue bloqueado por política local antes de llegar a GitHub. No se hizo merge ni se alteró una protección.

## Correcciones locales posteriores (sin nueva ejecución Azure)

- Backend rama `trabajo/castilla/h5-g5-azure-despliegue-integral`, commit `51f8441a2adb2e0484b2a2d3072617908f9672dc`: validador de configuración efectiva por servicio, SHA exacto, digests OCI y credenciales de lectura GHCR; prueba las etiquetas OCI contra el SHA y verifica el SHA actual de `master` junto con el workflow oficial `ci.yml` exitoso en `push` a `master` antes del `what-if`.
- El `what-if` ACA y N01 ahora consumen JSON de Azure y validan `resourceId`/`changeType`; la plantilla deriva dominio del Environment y recibe su región desde el preflight de Azure. El runner N01 recibe SHA por ejecución, lo contrasta con `master` y CI `push`, y conserva la vinculación SQL/resultado terminal junto con la limpieza que informa errores sin ocultar el error principal.
- Pruebas locales con respuestas simuladas: seis pruebas Node del validador (incluidos GitHub y GHCR privados), pruebas PowerShell de procedencia y JSON what-if (incluidos alcance y región), pruebas de cleanup N01, compilación de ambas plantillas Bicep, análisis sintáctico PowerShell y `git diff --check`: PASS.
- No se repitió N01, no se ejecutó `what-if` ACA, no se publicaron imágenes y no se crearon ACA. El `PASS` de N01 documentado arriba permanece evidencia histórica de la ejecución real original; estas correcciones no lo amplían ni acreditan ACA, G5, G7, APIM o CD.
- Inspección Azure CLI posterior: el RG `rg-g6-sb-h5-int-fork` informa `chilecentral`; el Environment `env-g6-h5-int` informa `Brazil South`, `publicNetworkAccess=Disabled`, sin subnet VNet configurada y `internal` sin valor. No hay ACA en el grupo. El runner/cliente externo no tiene una ruta privada acreditada hacia el Environment; Gateway y los cuatro servicios permanecen con ingress interno. No se habilita `external: true`; se requiere conectividad privada aprobada antes de una prueba HTTP desde fuera del Environment.
