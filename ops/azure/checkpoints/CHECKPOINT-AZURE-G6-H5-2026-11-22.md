# Checkpoint de infraestructura Azure G6 — Hito 5

## 1. Identificación y método

Corte histórico: **22/11/2026, America/Lima** (la evidencia previa solo preserva la fecha, no la hora de cada comando). Revalidación: **22/11/2026 21:45:26, America/Lima**. Azure for Students, Enabled; CLI 2.93.0; GitHub CLI autenticado. Se omiten IDs de suscripción/tenant.

SHAs remotos: Docs master 166482e73bafc099b1f3fdf1cc982e7ba8b268f5; Backend b4abb3acd866637edc603f1900a0bc77965f0d49; Frontend ba0b8d0ed6a0530a3c7cca4fb72d14814746800d; fork Axel Backend 8bf6b6ecf3e60730c945fe707769f95ffa450a8e.

Evidencia: AZURE_OBSERVADO, GITHUB_VERIFICADO, EVIDENCIA_HISTORICA, DOCUMENTADO_NO_EJECUTADO, PROPUESTA, NO_VERIFICADO. Plataforma Running no prueba salud funcional; PR mergeado no prueba deployment; GHCR publish no prueba uso por ACA; cola no prueba consumidor; laboratorio no es producción.

## 2. Resumen ejecutivo

**H5 PARTIAL.** Ninguno de los cuatro criterios está certificado. H5-04 se separa en H5-04A APIM y H5-04B Service Bus. Nueve apps shared reportan Running, pero no hay health funcional individual. En el corte solo Gateway /health=200; productos GET=400 y ruta G5 sintética GET=404, respuestas que no prueban indisponibilidad general ni fallo de auth.

OCI labels de las nueve imágenes declaran SHA 4c40b31b8a12335d4018861ab6d94cfd69536d7b; master estaba 110 commits adelante. No se encontró run que publicó esos digests ni run del CD oficial. APIM no existe. Service Bus acredita piloto R16, no migración global. No están las cuatro apps aisladas de G5; runner GitHub offline.

Revalidación 21:45:26: nueve ACA Succeeded/Running; Gateway 100% al revision del 14/11, nueva del 19/11 al 0%; ambas cero réplicas reportadas. No se hizo GET que pudiera activar escala a cero. Las cuatro apps aisladas siguen ausentes; APIM vacío, runner offline y VM deallocated.

## 3. Inventario Azure

| Resource Group | Recursos/región | Estado y finalidad |
|---|---|---|
| rg-g6-productos-azure | Chile Central; vm-g6-backend, disco, NIC, IP, VNet, NSG | VM deallocated; disco/IP quedan; dependencias y costo residual desconocidos. No retirar sin verificar. |
| rg-g6-aca-chile | env-g6-phase1-chile y 9 ACA, Chile Central | Runtime shared; Gateway externo, 8 internas; identity None; sin VNet/log destination/SB shared acreditado. |
| rg-g6-sb-pilot-261116 | g6-sb-test-261116-axl01, Chile Central | SB Basic, una cola R16, 3 identidades, RBAC por cola y 2 alertas; piloto aislado. |
| rg-g6-sb-h5-int-fork | g6-sb-h5-int-32cdqgbnlk7ow, identidades/alertas, env-g6-h5-int y Job; Chile Central/Brazil South | 19 colas; ninguna de las 4 ACA G5 existe. Job no es runner. |

NetworkWatcherRG y rg-eventos-fisi no se atribuyen a G6. APIM: lista vacía. No se halló Log Analytics. COSTO_REAL_NO_VERIFICADO; no inferir costo cero para VM deallocated. ACA shared: publicNetworkAccess Enabled, VNet null, logs destination null, mTLS/peer encryption deshabilitados; apps de dominio usan ingress interno. Config observada, no vulnerabilidad automáticamente demostrada.

## 4. Nueve ACA y digest del corte

OCI labels de todas las imágenes declaran backend oficial y revisión 4c40b31b8a12335d4018861ab6d94cfd69536d7b. Es metadata de imagen, no attestación independiente. Límites del corte: 0.25 vCPU, 0.5 GiB, máximo 1 réplica; no hay evidencia de cuello de botella. Revisión y digest son históricos; digest de 8 servicios no se reconstruyó en revalidación.

| Servicio | Revisión que servía | Digest OCI SHA-256 | Salud funcional |
|---|---|---|---|
| api-gateway | api-gateway--http-4c40b31b-mwgil3mw | 2ec4f28ee02c222f5e407caf5ecbd2aae13a158ed3ab1b9509cc6dedb778eed3 | /health 200; otros GET no concluyentes |
| bulk-svc | bulk-svc--http-4c40b31b-mwgil3mw | 19ecb55d61c55c7fdaffd2663a1302c5c708359d30b243e1284573ab9b5dcc03 | No verificada |
| catalog-svc | catalog-svc--http-4c40b31b-mwgil3mw | 063344cb07f8db8bb5dcc89318b16aca9b7035077dfec395c0ad0e01b5573499 | No verificada |
| combos-svc | combos-svc--http-4c40b31b-mwgil3mw | b032f5ab652a820b131e60c15b89d0081431ef2e540727e43853c6aa39436c9f | No verificada |
| inventory-svc | inventory-svc--http-4c40b31b-mwgil3mw | d41a9d0a3b91f8619731c7099af6dd4521ddbf97fa088baa9039b09b03143ab6 | No verificada |
| price-audit-svc | price-audit-svc--http-4c40b31b-mwgil3mw | c0f4170eaf3063a1dfe9a72c4dad2b20c3f0d6a52f2254ca56a84243e5d745a9 | No verificada |
| pricing-svc | pricing-svc--http-4c40b31b-mwgil3mw | a56ab62f9e159da6823baea6acb1d46fa030d778b17995648c5e79ea85095fda | No verificada |
| promotions-svc | promotions-svc--http-4c40b31b-mwgil3mw | 82c272907449ab290ff7d4239b0a5805e54ed04908bd756479ed899cbd61d143 | No verificada |
| taxonomy-svc | taxonomy-svc--http-4c40b31b-mwgii22g | 9226c8098b2be7afe9ab751950526a72df6bb2d720389ea6b626e822027eb4be | No verificada |

Revalidación ACA listó nueve apps Succeeded/Running, identity None, gateway externo y demás internos; latest revisions mantienen familia 4c40. Gateway latest auth-d3, ambas revisiones con 0 réplicas. No se declara una réplica atendiendo para cada app.

## 5. Gateway/G7

| Revision | Fecha | Tráfico | Diferencia |
|---|---|---:|---|
| api-gateway--http-4c40b31b-mwgil3mw | 14/11 | 100% | secret refs para modo/allowlist; valores no leídos |
| api-gateway--auth-d3-20261119 | 19/11 | 0% | modo G7_AUTHENTICATED y allowlist vacía explícitos |

Mismos digests Gateway/Caddy y probes. Activity Log registra actualización humana 19/11, no razón del 0 ni CD oficial. La revisión antigua sirve tráfico, aunque latest es auth-d3. No está demostrado que antigua carezca de auth. Código master verifica JWT/JWKS, issuer, audience, scopes; no hubo JWT G7 real. Rutas G5 #250 son posteriores a imagen. No cambiar tráfico sin smoke aislado y rollback: health/readiness, GET contractual, 401 sin token, token válido/scope, 401/403 inválido, respuesta, correlación, digest/revision y retorno a la versión previa si falla.

## 6. Trazabilidad GitHub–GHCR–Azure

Las nueve OCI labels indican SHA 4c40…6d7b, ancestro del master +110 commits. PRs mergeados posteriores #233/#235/#240/#250/#251 no quedan acreditados en runtime; PRs abiertos son candidatos. Run original de publicación no encontrado. CD Azure oficial sin runs. Cuatro publicaciones manuales recientes prueban publish, no deploy.

| Servicio | Digest del corte |
|---|---|
| Gateway | 2ec4f28ee02c222f5e407caf5ecbd2aae13a158ed3ab1b9509cc6dedb778eed3 |
| Bulk | 19ecb55d61c55c7fdaffd2663a1302c5c708359d30b243e1284573ab9b5dcc03 |
| Catalog | 063344cb07f8db8bb5dcc89318b16aca9b7035077dfec395c0ad0e01b5573499 |
| Combos | b032f5ab652a820b131e60c15b89d0081431ef2e540727e43853c6aa39436c9f |
| Inventory | d41a9d0a3b91f8619731c7099af6dd4521ddbf97fa088baa9039b09b03143ab6 |
| Price Audit | c0f4170eaf3063a1dfe9a72c4dad2b20c3f0d6a52f2254ca56a84243e5d745a9 |
| Pricing | a56ab62f9e159da6823baea6acb1d46fa030d778b17995648c5e79ea85095fda |
| Promotions | 82c272907449ab290ff7d4239b0a5805e54ed04908bd756479ed899cbd61d143 |
| Taxonomy | 9226c8098b2be7afe9ab751950526a72df6bb2d720389ea6b626e822027eb4be |

Cerrar cadena run→SHA→digest→revision→smoke con provenance, digest inmutable y artefacto ligado a SHA.

## 7. Service Bus

Ambos Basic, Chile Central, TLS mínimo 1.2, local auth disabled, red pública enabled, TTL P14D, lock PT1M, maxDelivery 10. Basic no soporta Topics/Subscriptions, sessions, duplicate detection nativa ni exactly-once.

| Namespace | Detalle |
|---|---|
| g6-sb-test-261116-axl01 | Cola g6.price-audit.from.pricing; MIs pilot Pricing/Audit/Release; sender/receiver por cola, 2 alertas, conteos 0, DLQ expiry false. #235 acredita R16 aislado. |
| g6-sb-h5-int-32cdqgbnlk7ow | 19 colas; 8 MIs runtime + g6-h5-int-github-cd; RBAC por cola reportado, 2 alertas; conteos active/dead/scheduled 0; DLQ expiry false solo promotions.commands. |

Identidades de integración por nombre: g6-h5-int-inventory, g6-h5-int-promotions, g6-h5-int-catalog, g6-h5-int-pricing, g6-h5-int-taxonomy, g6-h5-int-price-audit, g6-h5-int-combos, g6-h5-int-bulk y g6-h5-int-github-cd. El inventario mostró roles scoped a colas; no asumir asignación a apps shared.

Colas de integración observadas: g6.bulk.from.catalog, g6.bulk.from.inventory, g6.bulk.from.pricing; g6.catalog.from.bulk, g6.catalog.from.inventory, g6.catalog.from.pricing, g6.catalog.from.taxonomy; g6.combos.from.catalog, g6.combos.from.inventory; g6.inventory.from.bulk, g6.inventory.from.catalog; g6.price-audit.from.pricing; g6.pricing.from.bulk, g6.pricing.from.catalog; g6.promotions.commands, g6.promotions.from.catalog, g6.promotions.from.inventory, g6.promotions.from.pricing; g6.taxonomy.from.catalog. Todas con conteos 0; no se leyeron mensajes.

| Ruta | Productor→consumidor | Estado |
|---|---|---|
| R01 | Bulk→Catalog | Candidata, no runtime demostrado |
| R02 | Bulk→Inventory | Candidata |
| R03 | Bulk→Pricing | Candidata |
| R04 | Catalog→Bulk | Candidata en PR abierto |
| R05 | Catalog→Combos | Candidata |
| R06 | Catalog→Inventory | Candidata |
| R07 | Catalog→Pricing | Candidata |
| R08 | Catalog→Promotions | Candidata |
| R09 | Catalog→Taxonomy | Candidata |
| R10 | Inventory→Bulk | Candidata |
| R11 | Inventory→Catalog | Candidata |
| R12 | Inventory→Combos | Candidata |
| R13 | Inventory→Promotions | Candidata |
| R14 | Pricing→Bulk | Candidata |
| R15 | Pricing→Catalog | Candidata |
| R16 | Pricing→Price Audit | Piloto histórico aislado |
| R17 | Pricing→Promotions | Candidata |
| R18 | Taxonomy→Catalog | Candidata |

Cola no prueba handler. Se requiere Outbox por destinatario, Inbox/idempotencia, correlación, redelivery, recuperación y DLQ. G5 integra HTTP autenticado, no colas. Mantener piloto para R16 y fork para pruebas aisladas; no crear tercer namespace ni consolidar sin validar RBAC/aislamiento/consumidores. RabbitMQ solo regresión H4.

## 8. G5–G6 y 20 casos

Fuente: [PRUEBA_CONJUNTA_G5.md](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/b4abb3acd866637edc603f1900a0bc77965f0d49/apps/promotions-svc/h5/PRUEBA_CONJUNTA_G5.md), Backend #250. env-g6-h5-int en Brazil South, public access disabled; DNS/ruta privada no acreditada. No existen allí Gateway, Promotions, Inventory, Catalog como ACA. Environment azure-h5 protegido, FIC configurada; verificar RBAC efectivo. Runner group limitado a CD master; azure-h5-smoke offline. Job Azure homónimo manual y no es runner. CD acepta servicio individual o all de nueve, no selector de cuatro: ejecutar cuatro dispatches individuales aprobados con SHA master/CI exactos, no all.

| # | Caso | Estado/bloqueo |
|---|---|---|
| 01 | Reserva/terminal | BLOCKED: app aislada, G7 |
| 02 | Rechazo reserva/no continuar cupón-pago | BLOCKED: fixture G5 |
| 03 | Confirmar consumo | BLOCKED: bilateral |
| 04 | Liberación cancelación | BLOCKED: bilateral |
| 05 | Cupón/GET terminal/snapshot/constancia | BLOCKED: evidencia G5 |
| 06 | Restaurar consumo | BLOCKED: bilateral |
| 07 | POST respuesta perdida/retry misma key | BLOCKED: solo local |
| 08 | Misma key, payload distinto=409 | BLOCKED: solo local |
| 09 | Reinicio G5 y consulta | BLOCKED: ambiente |
| 10 | Expiración antes de sweep | BLOCKED: fixture/datos |
| 11 | Expiración entre sweeps | BLOCKED: reloj controlado |
| 12 | Carrera pago/cancelación/expiración | BLOCKED: bilateral |
| 13 | Pedido/cliente ajeno=404 | BLOCKED: identidad/datos test |
| 14 | JWT válido/ausente/vencido/audience/scope | BLOCKED: G7 real |
| 15 | Reinicio broker/worker | Parcial histórico; efecto G5 pendiente |
| 16 | Duplicado/settlement perdido | Parcial histórico; efecto único no probado |
| 17 | Devolución parcial M2/balances | BLOCKED: G5 fixture |
| 18 | Reemplazo CAMBIO | BLOCKED: G5/G2 |
| 19 | Corte/reversión/conciliación | BLOCKED: bilateral/infra |
| 20 | Mapa destinos SB | Parcial: colas sí, workload no |

Secuencia: Axel verifica OIDC/RBAC, runner, red y destinos; cuatro CD aislados; G7 aporta JWT/grants de prueba, G5 pedidos/snapshots/constancias, owner de datos SQL aislado; smoke/auth; casos 01–08, recuperación 15–16, resto por fixtures. Guardar SHA de ambos lados, revisión/digest, run, correlación y resultado.

## 9. H5, APIM, performance y observabilidad

| Requisito | Estado | Evidencia/falta |
|---|---|---|
| H5-01 CI/CD seguridad | EVIDENCIA_PARCIAL | CI y environment; no CD run, deploy/smoke/rollback. No SAST/OCI scan encontrado. |
| H5-02 Integración | EVIDENCIA_PARCIAL | #250 y piloto; 20 casos sin homologación |
| H5-03 Performance | EVIDENCIA_PARCIAL | Benchmark histórico Pricing; workflow actual sin run |
| H5-04A APIM | NO_IMPLEMENTADO_EN_SUSCRIPCION_AUDITADA | Inventario vacío; faltan API/policies/tráfico |
| H5-04B async | PARCIAL_PILOTO | R16; demás flujos sin runtime probado |

APIM Consumption Brazil South es PROPUESTA_NO_DESPLEGADA. Estimación previa no es gasto; crédito, egress, ruta privada sin verificar. No introducir subscription key en G5 sin aceptación. Antes de crear, validar región/SKU/costo/red y mantener servicios internos no publicados.

Performance workflow manual sin runs. [Run histórico 43644256265](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/43644256265), SHA e572723c7e4cc278fd4405b8bfeef050de3eed7e, success para Pricing/Postgres desechable, fixture Catalog loopback; no es Azure. Plan no ejecutado: candidato b4abb3…, baseline 4c40… con mismo harness; Pricing/Catalog, Gateway-Inventory, Promotions, Combos, Bulk, Taxonomy y Price Audit; p50/p95/p99, throughput, errores, concurrencia, CPU/memoria y artifacts. Etiquetar RabbitMQ heredado. No cargar producción.

ACA shared sin destino logs/Log Analytics identificado, VNet null, public network enabled, mTLS false. Apps 0.25 CPU/0.5Gi y max1: capacidad no medida, no cambiar sin benchmark. VM deallocated con disco/IP aún asignados; dependencias/costo no verificados.

## 10. Hallazgos G6

| ID | Prioridad/estado | Causa y aceptación | Owner |
|---|---|---|---|
| G6-01 | P1 confirmado; motivo 0 desconocido | Smoke G7/G5 aislado, aprobación/rollback | Axel+Marco |
| G6-02 | P1 MI shared ausente | MI/RBAC mínimo y test por cola | Axel+owners |
| G6-03 | P1 APIM ausente | SKU/costo/red, API/policies y tráfico | Axel+Marco |
| G6-04 | P1 parcial corregido | SHA OCI conocido, falta run→digest→revision | Axel |
| G6-05 | P1 evidencia parcial | Benchmarks actuales por SHA | Marco+owners |
| G6-06 | P2 logs no centralizados | Workspace/retención/redacción probados | Axel |
| G6-07 | P2 control no verificado, sin vuln probada | Validar rutas/controles compensatorios | Axel |
| G6-08 | P2 VM deallocated | Mapear dependencias antes de retiro | Axel+Marco |
| G6-09 | P2 sin falla probada | Benchmark antes de escala/SKU | Axel+owners |
| G6-10 | P1 G5, P2 consolidación | Mantener namespaces separados, validar consumers/RBAC | Axel+Vera+Marco |

## 11. Handoff

Leer [índice Azure](../README.md), [AGENTS.md](../../../AGENTS.md), [Hito 5](../../../hitos/HITO_5.md), [índice H5](../../../hitos/h5/README.md), ADR, topología y matriz. Distinguir shared vs entorno G5, piloto vs fork, Gateway vs APIM, runner vs Azure Job, publish vs revisión activa, historia vs revalidación.

Comandos de partida de solo lectura: az version/account show/group list; containerapp list/show/revision list con campos filtrados; servicebus namespace/queue list; apim list; vm get-instance-view; gh auth status, gh api commits/master, gh run list y gh api orgs/.../actions/runners. No imprimir secretos ni leer/manipular mensajes. Error de comando no prueba ausencia.

Siguiente corte: nuevo archivo fechado, revalidar, preservar hechos de este snapshot y actualizar índice. No operar Azure basándose solo en él.

## 12. Referencias y seguridad

Estado de PR al corte consultado: Backend #212/#216/#233/#235/#240/#250/#251 MERGED; #243 Draft (bbe22cc), #247 abierto (fb0225), #252 Draft (537f183), #253 abierto (2b4c06), #254 Draft (f259df), #255 abierto (04e398). Son candidatos, no despliegues. Frontend #87 MERGED; #92 abierto (818279), #93 Draft (2d0207), #94 abierto (de4b23). Docs #131/#133 OPEN Draft. SHAs cortos identifican las cabezas consultadas al corte.

[Docs master](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/commit/166482e73bafc099b1f3fdf1cc982e7ba8b268f5); [Backend](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/commit/b4abb3acd866637edc603f1900a0bc77965f0d49); [Frontend](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/commit/ba0b8d0ed6a0530a3c7cca4fb72d14814746800d); [fork](https://github.com/AXL031/G6-Productos-Ofertas-backend/commit/8bf6b6ecf3e60730c945fe707769f95ffa450a8e). Backend PRs #212/#216/#233/#235/#240/#250/#251. Docs #131/#133 OPEN Draft; paths revisadas y no modificadas. [CD workflow](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/b4abb3acd866637edc603f1900a0bc77965f0d49/.github/workflows/cd-services-azure.yml), [publish-only workflow](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/b4abb3acd866637edc603f1900a0bc77965f0d49/.github/workflows/publish-only-images.yml), [CI workflow](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/b4abb3acd866637edc603f1900a0bc77965f0d49/.github/workflows/ci.yml), [OIDC H5 configuration](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/b4abb3acd866637edc603f1900a0bc77965f0d49/ops/azure/container-apps/CONFIGURACION_OIDC_H5.md), [performance workflow](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/b4abb3acd866637edc603f1900a0bc77965f0d49/.github/workflows/performance-g6.yml), [nota VM](../../../ops/RETIRO-INFRAESTRUCTURA-ORACLE-VM.md).

Revalidación 21:45:26: Azure CLI account/groups, ACA list/Gateway show/revisions, SB namespaces/queues, APIM, VM; GitHub runner list y CD runs. Resultado saneado: nueve apps Running; Gateway 100/0 y cero réplicas; dos namespaces Basic, 19+1 colas con conteos cero; sin APIM; VM deallocated; runner offline; CD sin runs. No secretos ni mensajes leídos. Se omiten IDs sensibles, IP pública, tokens, JWT, connection strings y datos personales. Costos reales no verificados.
