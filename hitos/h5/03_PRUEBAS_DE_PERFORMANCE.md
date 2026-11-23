# H5-03 — Pruebas de performance reproducibles

**Estado documental:** planificado; no se ejecuta carga. La exigencia docente es evidencia de performance. VUs, escenarios y umbrales siguientes son criterios internos G6, no umbrales atribuidos al profesor.

## Herramientas, baseline y candidato

Reutilizar benchmarks pareados en Backend `performance-g6.yml` y benchmarks/UI de Frontend; k6 mide recorrido sistémico APIM→Gateway→servicio. Playwright mide interacción de navegador. Benchmark de función aislada no equivale a throughput del sistema. Antes de una corrida, fijar baseline y candidato con SHAs exactos, digest de imagen, contrato Docs, configuración, SKU/red, réplicas, pool DB, región, versión de k6, dataset no sensible, tasa objetivo y thresholds. Comparar configuraciones idénticas; alternar orden cuando sea viable y registrar dispersión.

## Matriz PERF-01 a PERF-08

| ID / owner | Escenario | Harness, datos y métricas | Comparación/evidencia |
|---|---|---|---|
| PERF-01 — Poma | GET catálogo paginado por canal | k6 + API; catálogo sintético; p50/p95/p99, RPS, errores | tres corridas baseline/candidato, config y JSON/CSV |
| PERF-02 — Vera | GET detalle SKU y precio | k6 + telemetry DB/downstream | percentiles, RPS, error y recursos por SHAs |
| PERF-03 — Taco | GET disponibilidad comercial | k6, ubicaciones/SKU sintéticos | p95, errores; 429 esperados separados |
| PERF-04 — Axel | POST admisión idempotente en entorno descartable | k6 + Outbox/cola; respuesta 202, throughput y backlog | una operación por idempotency key; nunca escritura comercial |
| PERF-05 — Axel | Service Bus mensajes sintéticos | productor/worker de test, lag, backlog, redelivery, DLQ | tiempo publicación→resultado; corrida Azure autorizada y sin payload real |
| PERF-06 — Poma | flujo administrativo Frontend | Playwright trace y browser metrics | duración interacción, solicitudes/bytes y estados UI |
| PERF-07 — Castilla | Bulk import controlada | dataset fijo no sensible, filas/s, duración, error y recuperación | tamaños/digest de entrada, estado terminal e idempotencia |
| PERF-08 — Castilla | APIM vs ruta privada equivalente autorizada | k6 a hostname APIM y control privado equivalente | overhead p50/p95/p99; ambos mismos servicio/datos/config |

## Dataset y ambiente comparables

Staging autorizado, sin usuarios reales; dataset sintético versionado y restaurable. Registrar SHAs Backend/Frontend/Docs, digest OCI, SKU APIM, topología/red/DNS, réplicas/CPU/memoria, DB/pool, región, k6/browser, semilla y checksum de dataset. Calentar antes; excluir el calentamiento del intervalo medido. Los escenarios de escritura usan base desechable y claves únicas/reproducibles. Si falta un sujeto, cambia la infraestructura o el tráfico externo no se controla, clasificar `INCONCLUSIVE`.

## Protocolo 1/5/20 VU con tres repeticiones

Ejecutar 1 VU por 60 s (smoke), 5 VU por 3 min (normal) y 20 VU por 5 min (carga); estrés mayor requiere ejecución opt-in y autorización de recursos. Hacer mínimo tres repeticiones de baseline y tres de candidato por escenario, con la misma configuración y dataset. Registrar orden y pausas. No correr estrés en producción ni emitir efectos reales. Propuesta de comandos futuros: `k6 run --vus 1 --duration 60s <script>`, `k6 run --vus 5 --duration 3m <script>`, `k6 run --vus 20 --duration 5m <script>`; el script definitivo debe fijar checks, IDs y variables sin secretos. Estos comandos son diseño, no ejecución de esta tarea.

## Umbrales y clasificación

| Métrica interna | Gate antes de candidato | Tratamiento |
|---|---|---|
| Corrección semántica | 100% de invariantes/checks críticos | incumplimiento funcional = FAIL |
| Errores inesperados | `<1%` solo en escenarios cuyo resultado esperado sea 2xx | 401/403/409/429 esperados se separan; no contar como éxito 2xx |
| p95 | mediana de p95 de tres corridas candidato ≤ `1.10 ×` mediana baseline | configuración/muestra distinta o corrida faltante = INCONCLUSIVE |
| RPS | mediana de tres corridas candidato ≥ `0.90 ×` mediana baseline | baseline ausente o cuota externa distinta = INCONCLUSIVE |
| Mensajería | tras detener productor sintético, ventana de observación de 5 min; backlog de ese ensayo llega a 0 y DLQ no aumenta | pendientes bajo reintento válido = INCONCLUSIVE; inspeccionar, nunca purgar automáticamente |
| Integridad de medición | p50/p95/p99, RPS, tasa de error, CPU/RAM, conexiones DB, tamaño de cola, DLQ y E2E | métrica incompleta, 429 no segregado o variación de carga = INCONCLUSIVE |

Umbrales no son SLA productivo ni exigencia docente. Cambio requiere aprobación previa a corrida y motivo registrado. Para usar PASS H5-03 se necesita baseline/candidato, tres repeticiones, ruta APIM real, perfiles autorizados y artefactos completos; perfil parcial se reporta parcial/inconcluso.

## Responsables, reportes y aceptación

Vera es owner de PERF-01–05/07/08 y consolidación de k6; Poma PERF-01/06, Taco dataset PERF-03, Axel compatibilidad de SB PERF-04/05, Castilla APIM y PERF-07/08. Salidas previstas: `performance-plan.yaml`, `baseline.json`, `candidate.json`, `comparison.json`, CSV, `performance-report.md` con dispersión y rótulo `ISOLATED`, `STAGING_APIM`, `STAGING_DIRECT` o `FRONTEND_BROWSER`. Verificar SHA, artifact digest, fecha, entorno, versión herramientas y config. Véanse [H5-04A](04_API_MANAGEMENT.md), [mensajería](05_MENSAJERIA_ASINCRONA.md) y [matriz de trazabilidad](07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md).
