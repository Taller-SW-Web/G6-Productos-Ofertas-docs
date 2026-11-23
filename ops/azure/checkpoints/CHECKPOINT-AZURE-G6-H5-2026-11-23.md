# Checkpoint Azure G6 — Hito 5 — 23/11/2026

## 1. Fecha, entorno, alcance y metodología

Corte: **23/11/2026, America/Lima**. Azure CLI consultó el contexto activo **Azure for Students**, estado Enabled, y confirmó `rg-g6-aca-chile`, región Chile Central, estado Succeeded. Se omitieron IDs de suscripción/tenant. Repositorio Backend `master`: `9e4ac0af2a3ea882784413401bd5016ff611caa2`, revalidado por `git ls-remote`; es contexto de publicación, no se usó como sustituto de la procedencia de cada imagen.

Alcance de solo lectura: nueve Azure Container Apps, sus revisiones, tráfico configurado, imágenes referenciadas, escala, publicación GHCR y workflows de Backend. No se hizo GET/HTTP contra ACA, ni cambio de configuración, tráfico, escala, imagen, secreto o recurso. El inventario refleja estado de control plane; peso de tráfico es configuración de enrutamiento, no contador de solicitudes.

Los checks de GH Actions y los digests de publicación se contrastaron con las imágenes referenciadas por Azure. La asociación SHA→digest procede de los logs verificadores del workflow (14/11 para ocho imágenes y 23/11 para Catalog y Pricing). El daemon Docker local no estaba disponible; no se hizo pull/inspección local de labels. Los digests exactos de ACA acreditan qué artefactos están configurados en Azure.

Estados usados:

- **`DESPLEGADO_VERIFICADO`**: Azure referencia el digest y revisión indicados. Este estado acredita despliegue/configuración de artefacto, no validación funcional.
- **`PUBLICADO_NO_DESPLEGADO`**: el workflow acredita publicación, sin revisión Azure que use ese digest. Ninguno de los nueve artefactos inventariados queda en esta categoría.
- **`SOLO_HISTORICO`**: resultado comunicado o snapshot previo sin evidencia reproducible actual.
- **`NO_VERIFICADO`**: el dato funcional no se probó en este corte o la evidencia requerida no está disponible.

## 2. Resumen y cobertura

**H5 sigue PARTIAL; este corte no certifica el Hito 5 completo.** Se verificó imagen, digest y revisión activa para 9/9 apps; se verificó SHA de origen enlazado a los digests en workflows para 9/9; estado de control plane Healthy y escala para 9/9. No se ejecutaron pruebas funcionales nuevas en Azure en este corte (0/9). La evidencia de filtros autenticados proviene del ensayo del 23/11 comunicado para Catalog/Pricing/Gateway y se conserva como evidencia reportada, sin afirmar que se reprodujo ahora.

## 3. Inventario actual de nueve Container Apps

Todas las imágenes de aplicación son referencias GHCR fijadas por digest. `Traffic` es peso configurado en ACA. `Healthy` es healthState del control plane, no un smoke HTTP. Los tiempos de creación están en UTC, tal como los entrega ACA.

| Servicio | SHA origen | Imagen de aplicación @ digest | Revisión efectiva / última creada | Tráfico configurado | Estado; réplicas; min/max | Creada (UTC) | Validación en este corte |
|---|---|---|---|---:|---|---|---|
| api-gateway | `4c40b31b8a12335d4018861ab6d94cfd69536d7b` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/api-gateway@sha256:2ec4f28ee02c222f5e407caf5ecbd2aae13a158ed3ab1b9509cc6dedb778eed3` | `api-gateway--warmrestore` (latest). Revisiones anteriores `api-gateway--http-4c40b31b-mwgil3mw` y `api-gateway--auth-d3-20261119` siguen active, ambas peso 0. | 100% warmrestore; 0% + 0% anteriores | Healthy; 0; 0/1 | 2026-11-23 09:25:58 | NO_VERIFICADO por HTTP; mismo digest que imagen histórica |
| bulk-svc | `4c40b31b8a12335d4018861ab6d94cfd69536d7b` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/bulk-svc@sha256:19ecb55d61c55c7fdaffd2663a1302c5c708359d30b243e1284573ab9b5dcc03` | `bulk-svc--http-4c40b31b-mwgil3mw` (latest/activa) | 100% | Healthy; 1; 1/1 | 2026-11-14 14:45:32 | NO_VERIFICADO funcionalmente |
| catalog-svc | `9e4ac0af2a3ea882784413401bd5016ff611caa2` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/catalog-svc@sha256:7bdb66c1bb94de9861f2c930eb6d7c899730b60fac3457785e1ac71ed766079e` | `catalog-svc--b80jpbt` (latest/activa) | 100% | Healthy; 1; 1/1 | 2026-11-23 06:14:21 | Ensayo de filtros autenticados reportado; no repetido en este corte |
| combos-svc | `4c40b31b8a12335d4018861ab6d94cfd69536d7b` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/combos-svc@sha256:b032f5ab652a820b131e60c15b89d0081431ef2e540727e43853c6aa39436c9f` | `combos-svc--http-4c40b31b-mwgil3mw` (latest/activa) | 100% | Healthy; 1; 1/1 | 2026-11-14 14:44:47 | NO_VERIFICADO funcionalmente |
| inventory-svc | `4c40b31b8a12335d4018861ab6d94cfd69536d7b` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/inventory-svc@sha256:d41a9d0a3b91f8619731c7099af6dd4521ddbf97fa088baa9039b09b03143ab6` | `inventory-svc--http-4c40b31b-mwgil3mw` (latest/activa) | 100% | Healthy; 1; 1/1 | 2026-11-14 14:43:52 | NO_VERIFICADO funcionalmente |
| price-audit-svc | `4c40b31b8a12335d4018861ab6d94cfd69536d7b` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/price-audit-svc@sha256:c0f4170eaf3063a1dfe9a72c4dad2b20c3f0d6a52f2254ca56a84243e5d745a9` | `price-audit-svc--http-4c40b31b-mwgil3mw` (latest/activa) | 100% | Healthy; 1; 1/1 | 2026-11-14 14:42:54 | NO_VERIFICADO funcionalmente |
| pricing-svc | `9e4ac0af2a3ea882784413401bd5016ff611caa2` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/pricing-svc@sha256:78852699924a1410382d0dd7fff83ae0ae09601aa10c8ca22f9442fd27293048` | `pricing-svc--0000002` (latest/activa) | 100% | Healthy; 0; 0/1 | 2026-11-23 09:27:22 | Ensayo de filtros autenticados reportado; no repetido en este corte |
| promotions-svc | `4c40b31b8a12335d4018861ab6d94cfd69536d7b` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/promotions-svc@sha256:82c272907449ab290ff7d4239b0a5805e54ed04908bd756479ed899cbd61d143` | `promotions-svc--http-4c40b31b-mwgj2k1j` (latest/activa) | 100% | Healthy; 0; 0/1 | 2026-11-14 14:55:48 | NO_VERIFICADO funcionalmente |
| taxonomy-svc | `4c40b31b8a12335d4018861ab6d94cfd69536d7b` | `ghcr.io/taller-sw-web/g6-productos-ofertas-backend/taxonomy-svc@sha256:9226c8098b2be7afe9ab751950526a72df6bb2d720389ea6b626e822027eb4be` | `taxonomy-svc--http-4c40b31b-mwgii22g` (latest/activa) | 100% | Healthy; 1; 1/1 | 2026-11-14 14:39:50 | NO_VERIFICADO funcionalmente |

**Sidecar separado:** Gateway también configura `caddy` con `caddy:2.11.6-alpine@sha256:d44355d3c2149dc580ce2cac735955d1c08d3d00882c30489c241aa51a5c10d9`. No se le atribuye SHA de Backend: es una imagen upstream distinta. Gateway conserva el mismo contenedor de aplicación y sidecar en `http-4c40…`, `auth-d3-20261119` y `warmrestore`.

## 4. Trazabilidad Backend → GHCR → ACA

La punta de Backend `master` al corte es `9e4ac0af2a3ea882784413401bd5016ff611caa2`. Los workflows de publicación y sus logs verificadores dan esta cadena:

| Servicio | Publicación verificada | Resultado de cadena | Estado |
|---|---|---|---|
| api-gateway | [run 43605612727](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43605612727), SHA `4c40…` | Digest del run coincide con la referencia en ACA | DESPLEGADO_VERIFICADO |
| bulk-svc | [run 43605629990](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43605629990), SHA `4c40…` | Digest del run coincide con la referencia en ACA | DESPLEGADO_VERIFICADO |
| catalog-svc | [run 45104742271](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45104742271), SHA `9e4ac0…` | El run registra digest `7bdb66…`; ACA refiere ese digest | DESPLEGADO_VERIFICADO |
| combos-svc | [run 43605623036](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43605623036), SHA `4c40…` | Digest del run coincide con la referencia en ACA | DESPLEGADO_VERIFICADO |
| inventory-svc | [run 43605619160](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43605619160), SHA `4c40…` | Digest del run coincide con la referencia en ACA | DESPLEGADO_VERIFICADO |
| price-audit-svc | [run 43605609561](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43605609561), SHA `4c40…` | Digest del run coincide con la referencia en ACA | DESPLEGADO_VERIFICADO |
| pricing-svc | [run 45104870403](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/45104870403), SHA `9e4ac0…` | El run registra digest `788526…`; ACA refiere ese digest | DESPLEGADO_VERIFICADO |
| promotions-svc | [run 43605626624](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43605626624), SHA `4c40…` | Digest del run coincide con la referencia en ACA | DESPLEGADO_VERIFICADO |
| taxonomy-svc | [run 43605615901](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43605615901), SHA `4c40…` | Digest del run coincide con la referencia en ACA | DESPLEGADO_VERIFICADO |

Los ocho runs antiguos publicaron artefactos el 14/11; los de Catalog y Pricing el 23/11. El workflow es de publicación y declara no desplegar. La observación ACA del digest exacto es la evidencia independiente de que esos artefactos sí están configurados en el runtime. No se halló run del workflow **CD Azure Container Apps H5** en la lista consultada; el cambio de revisión de Gateway no demuestra build ni código nuevo.

## 5. Diferencias frente al checkpoint del 22/11

- Catalog cambió de `catalog-svc--http-4c40b31b-mwgil3mw`, digest `063344…`, a `catalog-svc--b80jpbt`, digest `7bdb66…`, publicado para SHA `9e4ac0…`.
- Pricing cambió de `pricing-svc--http-4c40b31b-mwgil3mw`, digest `a56ab6…`, a `pricing-svc--0000002`, digest `788526…`, publicado para SHA `9e4ac0…`.
- Gateway creó `api-gateway--warmrestore` el 23/11. Recibe 100%; las revisiones anteriores quedan activas con 0%. El digest app `2ec4f28…` y sidecar `d44355…` son idénticos a los históricos. No hay evidencia de código nuevo por renombrar/recrear la revisión. La conservación de referencias G7 fue comunicada para el ensayo, pero no se inspeccionaron ni imprimieron referencias de secretos en este corte.
- Los otros seis servicios mantienen el digest y SHA `4c40…` que figuraban en el snapshot anterior.
- Estado Healthy y pesos ACA actuales se volvieron a consultar. Las réplicas observadas variaron: Gateway 0, Pricing 0 y Promotions 0 al corte; las seis apps restantes tienen 1. El checkpoint anterior contenía lecturas anteriores y no se deben interpretar como estado simultáneo actual.

## 6. Historial de revisiones nuevas

| App | Revisión nueva | Creación (UTC) | Imagen comparada con previa | Tráfico actual |
|---|---|---|---|---:|
| Catalog | `catalog-svc--b80jpbt` | 23/11 06:14:21 | Cambió digest al publicado para SHA `9e4ac0…` | 100% |
| Pricing | `pricing-svc--0000002` | 23/11 09:27:22 | Cambió digest al publicado para SHA `9e4ac0…` | 100% |
| Gateway | `api-gateway--warmrestore` | 23/11 09:25:58 | Imagen app y sidecar sin cambio frente a revisión anterior | 100% |

En las tres apps las revisiones anteriores siguen activas pero con peso 0. Las nuevas revisiones Healthy en ACA no prueban por sí solas disponibilidad HTTP.

## 7. Evidencia de filtros autenticados (ensayo comunicado del 23/11)

Los siguientes resultados fueron comunicados para el ensayo, pero no se conservaron en esta auditoría logs consultables, artefactos ni una nueva ejecución. Se registran como **EVIDENCIA_REPORTADA / SOLO_HISTORICO para este checkpoint**, no como prueba reproducida:

- Consultas de filtros de precio con JWT G7 de identidad humana `GESTOR_COMERCIAL`; HTTP 200 reportado para S/ 0–100 y S/ 0–60. Catalog participó satisfactoriamente. Se reportó configuración de referencias G7 conservada para Pricing y Gateway; no se leyeron valores ni referencias de secretos en este corte.
- En dataset anterior a la nueva carga QA, A (S/ 0–100) devolvió 12 productos y B (S/ 0–60) 2; B fue subconjunto de A.
- Correlation IDs reportados: `faaca62f-a901-4453-b951-0706190f1e6a` y `1c337e91-c3b4-4733-a9b5-74324164f009`.
- Con Gateway frío, 39.852 s para S/ 0–100. Con Gateway caliente: 3.527 s para S/ 0–100 y 1.080 s para S/ 0–60. La primera comparación corresponde a aproximadamente 91.1% menos latencia para S/ 0–100; es una observación de una corrida, no benchmark estadístico.
- Se comunicó reversión de escala para Gateway y Pricing. Azure actualmente reporta ambos 0/1 réplicas min/max y revisión Healthy; ello es consistente con escala a cero, pero el historial de actividad que probaría cada acción de reversión no se obtuvo.

No se enviaron solicitudes HTTP durante la auditoría porque podrían activar réplicas con minReplicas=0 y alterar el estado observado. Los logs de aplicación/telemetría que permitirían corroborar retrospectivamente las llamadas y latencias no quedaron disponibles para este corte.

## 8. Autenticación G7 y Marketplace

La evidencia comunicada de JWT corresponde a una identidad humana `GESTOR_COMERCIAL` contra el ensayo autenticado de filtros. **No es E2E del BFF Marketplace** y no prueba el client/module `modulo-marketplace`, su grant, scopes, mapeo BFF, ni homologación del consumidor G1. No se atribuye autorización a partir de una prueba de otra identidad.

Pendiente específico: owner de Seguridad/G7 debe confirmar grant/scopes de `modulo-marketplace` para las operaciones de filtros que invoque Marketplace; owner de integración G1/G6 debe aportar ejecución E2E autenticada BFF→Gateway→servicios con JWT de módulo, respuesta contractual y correlation ID. Desbloqueo verificable: evidencia reproducible ligada a SHA del BFF y a digest/revisión ACA, con casos válido/ausente/expirado/scope insuficiente y aceptación/homologación registrada por los módulos concernidos. Ninguna autorización o aceptación externa se infiere aquí.

## 9. Estado final de réplicas y escala

Resumen al momento de las consultas: `api-gateway` 0/1 (min/max), `bulk-svc` 1/1, `catalog-svc` 1/1, `combos-svc` 1/1, `inventory-svc` 1/1, `price-audit-svc` 1/1, `pricing-svc` 0/1, `promotions-svc` 0/1 y `taxonomy-svc` 1/1. Las nueve reportaron provisioning Succeeded; revisiones activas Healthy. Las apps con min=0 pueden estar sin réplica mientras ACA conserva estado Healthy. No se confunde `trafficWeight=100` con solicitudes servidas ni con réplicas activas.

## 10. Hallazgos pendientes y calidad de evidencia

| Hallazgo | Evidencia disponible | Falta / estado |
|---|---|---|
| Procedencia de las imágenes | Runs exitosos de publicación con SHA y digest para las nueve; digest idéntico observado en ACA | Sin inspección local de OCI labels porque Docker Engine no estaba disponible; provenance/SBOM fuera del alcance de los logs consultados |
| Despliegue | Azure enumera revisión activa, tráfico configurado y digest por contenedor | No se localizó run CD; no se acredita qué actor/operación creó las revisiones del 23/11 |
| Salud | `healthState=Healthy`, provisioning Succeeded y réplicas actuales | No hubo health/smoke HTTP independiente en esta auditoría |
| Filtros | Resultados y correlation IDs comunicados; imágenes/revisiones actuales verificadas | Logs/artifacts del ensayo no disponibles para reproducción retrospectiva; resultados quedan reportados |
| G7/Marketplace | Ensayo comunicado con JWT humano `GESTOR_COMERCIAL` | E2E con `modulo-marketplace`, grant G7 y homologación externa NO_VERIFICADO |
| H5 global | Piloto R16 y antecedentes del checkpoint 22/11 | No certifica habilitación general, todos los flujos, APIM, G5 Marketplace, CI/CD deploy ni retiro del runtime heredado |

`PUBLICADO_NO_DESPLEGADO`: una publicación nueva de candidato sin digest observado en ACA quedaría en este estado; no se observó tal caso entre las nueve referencias actuales. Las pruebas humanas reportadas se clasifican `SOLO_HISTORICO` respecto a esta auditoría, no como ausencia de despliegue.

## 11. Comandos de solo lectura utilizados (saneados)

Contexto y recursos:

```powershell
az account show --query '{name:name,state:state,isDefault:isDefault}' -o json
az group show --name rg-g6-aca-chile --query '{name:name,location:location,provisioningState:properties.provisioningState}' -o json
az containerapp list -g rg-g6-aca-chile --query "[].{name:name,latest:properties.latestRevisionName,min:properties.template.scale.minReplicas,max:properties.template.scale.maxReplicas,status:properties.runningStatus,provisioning:properties.provisioningState}" -o table
```

Por cada nombre de app de la lista solicitada, los siguientes filtros omiten variables de entorno, secretRefs y valores de configuración:

```powershell
az containerapp revision list -g rg-g6-aca-chile -n <app> --query "[].{name:name,created:properties.createdTime,active:properties.active,health:properties.healthState,replicas:properties.replicas,weight:properties.trafficWeight,min:properties.template.scale.minReplicas,max:properties.template.scale.maxReplicas,containers:properties.template.containers[].{name:name,image:image}}" -o json
```

Punta Git y workflows:

```powershell
git ls-remote https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend.git refs/heads/master
gh run list --repo Taller-SW-Web/G6-Productos-Ofertas-backend --workflow 'Publicar imágenes GHCR sin despliegue' --limit 100 --json databaseId,displayTitle,headSha,status,conclusion,createdAt,url
gh run view <run-id> --repo Taller-SW-Web/G6-Productos-Ofertas-backend --json jobs,headSha,url
gh run list --repo Taller-SW-Web/G6-Productos-Ofertas-backend --workflow 'CD Azure Container Apps H5' --limit 30 --json databaseId,displayTitle,headSha,status,conclusion,createdAt,url
```

Los logs GH consultados se filtraron localmente por `SERVICE`, `IMAGE_SHA` y `PUBLISHED_DIGEST`; no se incluyeron tokens ni configuración. El intento de pull local no pudo ejecutarse: Docker Engine no estaba disponible (`dockerDesktopLinuxEngine`); no afectó Azure.

## 12. Diferencias operativas y límites

No se cambió infraestructura. No se repitió el benchmark, smoke HTTP, ni prueba JWT para evitar convertir la auditoría de solo lectura en un evento que active réplicas. El checkpoint del 22/11 se conserva intacto y sigue siendo histórico. Revalidar nuevamente antes de cualquier operación; los resultados corresponden únicamente a este corte.
