# Trazabilidad y evidencias del Hito 5

**Estado:** matriz de plan. No contiene resultados de ejecución ni scorecard calculado. Los cinco criterios H5 se registran por separado; la evidencia debe ligar caso, dueño, SHA, entorno y artefacto.

## Scorecard H5-01/02/03/04A/04B

| Criterio | Pruebas/artefactos futuros | Owner único de consolidación | Implementación | Evidencia | Verificación / homologación |
|---|---|---|---|---|---|
| H5-01 | CI/CD + CodeQL/Gitleaks/SCA/Trivy/SBOM/IaC/ZAP/negativos JWT; SARIF/JSON | Castilla | `PARCIAL_NO_CERTIFICADO` | `EVIDENCIA_PARCIAL` | no certificado; grants G7 por operación |
| H5-02 | INT-01–10, JUnit/JSON/Playwright, logs y correlación | Castilla | `PARCIAL_NO_CERTIFICADO` | `EVIDENCIA_PARCIAL` | pilot R16 parcial; L3 bilateral solo flujos externos declarados |
| H5-03 | PERF-01–08, k6/Playwright, paired JSON/CSV/report | Vera | `NO_CERTIFICADO` | `EVIDENCIA_PARCIAL` | APIM/ambiente/costo no verificados |
| H5-04A | APIM host real, Bicep, policy hash, respuestas | Castilla | `NO_VERIFICADO` | `EVIDENCIA_PARCIAL` | inventory/budget/red pendientes |
| H5-04B | R16 + R18 o R07; Inbox/Outbox/DLQ/recovery | Axel | `PARCIAL_PILOTO` | `EVIDENCIA_PARCIAL` | no global; G5/G7 independiente |

## INT-01–INT-10

| Caso | Criterio/nivel mínimo | Responsable | Dependencia/artefacto esperado |
|---|---|---|---|
| INT-01 | H5-02; L1+L2 | Poma | producto/variante/offer/stock, JUnit+JSON+corr ID |
| INT-02 | H5-02; L1+L2 condicional | Taco | consulta/reserva/release/idempotencia, DB y SQL de test |
| INT-03 | H5-02; L1+L2 tras grants | Axel | cupones y doble solicitud; permiso G7/runtime |
| INT-04 | H5-02; L1, L2 si R01 | Castilla (Poma coejecuta validación Catalog) | Bulk→Catalog, digest/receipt/result |
| INT-05 | H5-02; L2 | Vera | R16, redelivery/restart/DLQ, bundle y SQL |
| INT-06 | H5-02; L1, L2 si activo | López | Taxonomy↔Catalog; R18 si seleccionado |
| INT-07 | H5-02; L2 | Castilla | APIM/Gateway/G7, 200/401/403/404/429/CORS |
| INT-08 | H5-02; L1 Playwright + L2 | Poma | FE→APIM→Gateway→owner, tres SHAs |
| INT-09 | H5-02; L3 si se proclama homologado | Axel | G5/G6 bilateral, token/grant y alcance |
| INT-10 | H5-02; L1+L2 | Vera | caída/recovery/replay/no doble efecto |

INT-02/03/04/06/09 son condicionales al manifest de release; la selección R18 activa INT-06 y R01 activa INT-04. Poma es owner de INT-01/08; Castilla de INT-04/07, con Poma coejecutor de INT-04. E2E G5 requiere L3, no toda la aceptación académica.

## PERF-01–PERF-08

| Caso | Criterio y objetivo | Responsable | Datos/evidencia futura |
|---|---|---|---|
| PERF-01 | H5-03 catálogo paginado | Poma | dataset fijo, k6 percentiles/RPS |
| PERF-02 | detalle SKU/precio | Vera | DB/downstream y trazas |
| PERF-03 | disponibilidad comercial | Taco | SKUs/ubicaciones sintéticos, errores/429 |
| PERF-04 | admisión idempotente; obligatorio solo con N01 en manifest | Axel | 202, outbox/backlog, entorno descartable; si N01 no está habilitado, `scope=OUT_OF_SCOPE` |
| PERF-05 | Service Bus | Axel | latency, backlog, redelivery/DLQ |
| PERF-06 | UI admin | Poma | Playwright/browser, duración/bytes |
| PERF-07 | importación Bulk | Castilla | dataset/checksum, filas/s y recuperación |
| PERF-08 | APIM vs control privado | Castilla | host/APIM SKU y control comparable |

Perfiles: 1 VU/60 s, 5 VU/3 min, 20 VU/5 min; tres repeticiones baseline y candidato. Gate interno: mediana p95 candidato ≤1.10×baseline, RPS ≥0.90×baseline y errores inesperados <1% únicamente donde el escenario espera 2xx. Si N01 no está en el manifest, PERF-04 se registra con `scope=OUT_OF_SCOPE` y se excluye del denominador del scorecard; no recibe resultado de ejecución `PASS` ni `NOT_RUN`. Métricas incompletas o ambiente dispar = `INCONCLUSIVE` para escenarios dentro de alcance.

## RL-01–RL-06 — ráfagas, límites y concurrencia

Las pruebas se relacionan con H5-01 (control de seguridad), H5-03 (medición de performance) y H5-04A (APIM); son diseño pendiente, no evidencia de ejecución. Correr k6 solo en entorno autorizado, datos sintéticos y sin afectar operaciones reales. Los umbrales numéricos se acuerdan por perfil/política/SKU; 5 solicitudes por segundo y 60 por minuto son solo un perfil de laboratorio ilustrativo, nunca una configuración productiva aprobada.

| ID | Prueba | Owner |
|---|---|---|
| RL-01 | Rechazo de ráfagas por segundo | Castilla |
| RL-02 | Límite acumulado por ventana temporal | Castilla |
| RL-03 | `Retry-After` y recuperación | Vera |
| RL-04 | Aislamiento entre clientes autorizados | Castilla |
| RL-05 | Solicitudes bloqueadas no llegan al backend | Axel |
| RL-06 | Concurrencia e idempotencia de operaciones críticas | Vera |

| ID | Precondiciones | Procedimiento | Resultado esperado / aceptación | Evidencia verificable | Responsable | Dependencia / desbloqueo |
|---|---|---|---|---|---|---|
| RL-01 | Política y SKU autorizados; perfil de ruta; entorno aislado; k6 y datos sintéticos listos. | Emitir ráfaga controlada que cruza el límite por segundo; contar solicitudes ofrecidas, admitidas y rechazadas. | Exceso produce 429 dentro de la tolerancia documentada; separar 429 esperados de errores inesperados; ningún efecto de solicitud rechazada. | SHA de sujetos, revisión Azure/SKU, hash de política, config k6, timestamps, respuestas, métricas y logs redactados. | Castilla | Infra/Azure y autoridad de presupuesto: instancia APIM/ruta aprobada y accesible; desbloqueo con inventario y configuración habilitada en entorno de pruebas. |
| RL-02 | Ventanas corta/larga definidas en política autorizada; dataset sintético y límites registrados. | Mantener carga controlada por ventanas de segundos y minutos; variar la tasa para distinguir ráfaga de acumulado. | Admisión/rechazo concuerda con límites y garantías documentadas, sin prometer exactitud absoluta de contadores distribuidos. | Perfil, versión/SKU/policy hash, curva ofrecida/admitida/rechazada, p95, throughput y artefactos k6 con SHA. | Castilla | Infra/APIM: política compatible con SKU y ventana configurada; desbloqueo al observar revisión atendiendo tráfico y parámetros verificables. |
| RL-03 | `Retry-After` definido por la política; cliente k6 implementa backoff; entorno sintético. | Provocar 429, verificar cabecera, esperar según instrucción y reintentar con backoff/jitter; observar recuperación. | `Retry-After` se interpreta correctamente y servicio recupera después de ventana sin reintentos masivos ni errores inesperados. | Request/response redactada, timestamps, espera aplicada, conteos de 429/2xx/errores, reporte k6 y SHA. | Vera | Castilla/APIM y Frontend dueño del cliente: definir semántica de respuesta; desbloqueo con cabecera observable y cliente compatible en staging. |
| RL-04 | Dos o más identidades/clientes de prueba autorizados; claves derivadas de identidad validada y perfiles separados. | Saturar límite de un cliente mientras otro envía carga dentro de su propio perfil. | El exceso de un cliente no consume el cupo de otro; claves no se basan en claims no validados ni IP falsificable. | IDs sintéticos seudonimizados, política/hash, secuencia y status por cliente, trazas y configuración k6. | Castilla | G7: grants de prueba; Infra/APIM: política activa. Desbloqueo con grants autorizados y claves observables por política. |
| RL-05 | Ruta pública por APIM y telemetría correlacionable de Gateway/backend; acceso directo al Gateway incluido en el plan negativo. | Exceder límite por APIM y comparar solicitudes 429 con invocaciones en Gateway/backend; intentar acceso alternativo directo al Gateway. | Solicitudes rechazadas no alcanzan microservicios y acceso directo es denegado; no se crea un bypass de APIM. | Trazas/correlación, conteos de borde y backend, status de ruta alternativa, revisión Azure y logs redactados con SHA/timestamps. | Axel | Axel/Infra: revisión Gateway/CD y controles de red/origen; desbloqueo con configuración de ruta autorizada y telemetría de ambos saltos. |
| RL-06 | Operación crítica sintética, almacenamiento desechable, clave de idempotencia según flujo y capacidad concurrente acordada. | Lanzar solicitudes simultáneas controladas, incluyendo repeticiones con la misma clave; observar admitidas/rechazadas y estado final. | Concurrencia se mantiene en capacidad acordada; `429` esperados separados de errores; no hay efectos comerciales duplicados; idempotencia no depende del rate limit. | Config k6, estado antes/después, conteo de efectos, claves seudonimizadas, p95, throughput, saturación, SHA y timestamps. | Vera | Owner de operación/G7 y ambiente autorizado: operación sintética y grant disponibles; desbloqueo con entorno desechable, capacidad definida y estado auditable. |

Las ejecuciones futuras deben conservar timestamps, configuración, revisión Azure, límites, SKU/política, SHA de cada sujeto, artefactos k6 y métricas de p95, throughput, errores y saturación del backend. Contadores APIM distribuidos pueden desviarse: evaluar contra la garantía de la política/SKU elegidos. APIM/WAF no están declarados desplegados; el estado permanece `NO_VERIFICADO` hasta evidencia asociada a revisión que atienda tráfico.

## R01–R18/N01, owner y aceptación

| Flujo | Owner transporte / dominio | Prueba mínima específica antes de habilitar |
|---|---|---|
| R01 Bulk→Catalog | Axel / Castilla-Poma | payload límite 256 KB, Outbox/Inbox, digest/replay |
| R02 Bulk→Inventory | Axel / Castilla-Taco | contrato resuelto, handler durable y DLQ |
| R03 Bulk→Pricing | Axel / Castilla-Vera | contrato Bulk, aplicación idempotente |
| R04 Catalog→Bulk | Axel / Poma-Castilla | resultado terminal y replay único |
| R05 Catalog→Combos | Axel / Poma-Castilla | deactivación/replay y rollback |
| R06 Catalog→Inventory | Axel / Poma-Taco | ambos mensajes, persistir antes de settlement |
| R07 Catalog→Pricing | Axel / Poma-Vera | fallback de 2.º flujo, correlación/deduplicación |
| R08 Catalog→Promotions | Axel / Poma-Axel | handler H5 y rollback sin doble runtime H4 |
| R09 Catalog→Taxonomy | Axel / Poma-López | baja terminal correlacionada |
| R10 Inventory→Bulk | Axel / Taco-Castilla | ajuste/resultados causales y únicos |
| R11 Inventory→Catalog | Axel / Taco-Poma | éxito/rechazo de inicialización |
| R12 Inventory→Combos | Axel / Taco-Castilla | cambio stock replay idempotente |
| R13 Inventory→Promotions | Axel / Taco-Axel | cambio stock y regla Promotions verificada |
| R14 Pricing→Bulk | Axel / Vera-Castilla | resultado masivo durable |
| R15 Pricing→Catalog | Axel / Vera-Poma | respuesta por destino durable |
| R16 Pricing→Price Audit | Axel / Vera | republish, Inbox, auditoría y DLQ con run vigente |
| R17 Pricing→Promotions | Axel / Vera-Axel | handler Promotions y no doble efecto |
| R18 Taxonomy→Catalog | Axel / López-Poma | seis eventos, DDL reconciliado, replay/DLQ; preferente |
| N01 Promotions HTTP→worker | Axel / Axel | 202 durable, GET terminal, rol runtime y grant real |

Los nombres de mensajes y colas los rige [matriz de implementación](../../integraciones/MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md) y [topología](../../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md), que no se editan en este PR. Ningún flujo se interpreta como habilitado por aparecer en esta tabla.

## Esquema de evidencia y procedencia planeados

Cada registro futuro separa la dimensión `scope` (`IN_SCOPE` o `OUT_OF_SCOPE`, con motivo y condición de manifest) del `execution_result` (`PASS/FAIL/INCONCLUSIVE/NOT_RUN`), `evidence_level` (`STATIC/ISOLATED/LAB_AZURE/STAGING_REAL/INTERGROUP`), `deployment_state`, `verification_state` y `blocker_code`. `OUT_OF_SCOPE` no es resultado de ejecución y no suma al denominador del scorecard. Incluir case/criterion, repositorio y SHA completo por sujeto Backend/Frontend/Docs, entorno, comando saneado, run/workflow/job/artifact IDs, digest SHA-256, timestamps, fixture, versiones/dataset y owner. Verification independiente coteja API GitHub de solo lectura, SHA realmente probado, conclusión del job, artifact ID/hash y estado de expiración. `workflow_dispatch` registra SHA del runner y del código bajo prueba. L1 simulado no se etiqueta L2; artifact expirado sin copia verificable es `INCONCLUSIVE`.

## Scorecard y cierre

El scorecard futuro se deriva de cobertura fija y evidencia verificada, nunca se edita manualmente como PASS. Fixtures son pruebas del validador, no evidencias de producto. `skipped`, mock, propuesta, YAML, link sin artefacto, CI de otro SHA o piloto aislado no cierran un criterio global. Para cierre deben pasar núcleo H5, condicionales activados, security, runs requeridos, evidencia íntegra y revisiones; despliegue, homologación externa y estado de prueba siguen siendo dimensiones separadas. Véanse [niveles de integración](02_PRUEBAS_DE_INTEGRACION.md), [performance](03_PRUEBAS_DE_PERFORMANCE.md) y [automatización](08_AUTOMATIZACION_Y_PUERTAS.md).
