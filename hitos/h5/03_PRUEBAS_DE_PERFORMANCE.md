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
| PERF-04 — Axel | POST admisión idempotente en entorno descartable, obligatorio solo si el manifest del release habilita N01 | k6 + Outbox/cola; respuesta 202, throughput y backlog | una operación por idempotency key; nunca escritura comercial; si N01 no forma parte del release, `scope=OUT_OF_SCOPE`, no resultado de ejecución |
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

Umbrales no son SLA productivo ni exigencia docente. Cambio requiere aprobación previa a corrida y motivo registrado. PERF-04 entra en el alcance obligatorio solo cuando N01 forma parte del manifest del release. Si N01 no está habilitado, registrar `scope=OUT_OF_SCOPE` y excluir PERF-04 del denominador del scorecard; no clasificarlo como PASS ni como `NOT_RUN`. Para usar PASS H5-03 se necesita baseline/candidato, tres repeticiones, ruta APIM real, perfiles autorizados y artefactos completos; perfil parcial se reporta parcial/inconcluso.

## Responsables, reportes y aceptación

Vera es owner transversal de consolidación k6 y del reporte H5-03, además de owner de PERF-02. Los owners de prueba son Poma PERF-01/06, Taco PERF-03, Axel PERF-04/05 y Castilla PERF-07/08. Salidas previstas: `performance-plan.yaml`, `baseline.json`, `candidate.json`, `comparison.json`, CSV, `performance-report.md` con dispersión y rótulo `ISOLATED`, `STAGING_APIM`, `STAGING_DIRECT` o `FRONTEND_BROWSER`. Verificar SHA, artifact digest, fecha, entorno, versión herramientas y config. Véanse [H5-04A](04_API_MANAGEMENT.md), [mensajería](05_MENSAJERIA_ASINCRONA.md) y [matriz de trazabilidad](07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md).

## Pruebas de ráfagas, límites y concurrencia (RL-01–RL-06)

Añadir estos escenarios al harness k6 existente, sin alterar ni renumerar PERF-01–PERF-08. Son pruebas futuras, no resultados. Ejecutarlas solo en entorno autorizado, aislado y con datos sintéticos; las escrituras requieren almacenamiento desechable y no pueden afectar operaciones reales. Generar concurrencia y ráfagas controladas, con perfil, duración, tasa y número de clientes fijados antes de cada corrida.

Medir solicitudes ofrecidas, admitidas y rechazadas; clasificar los `429` previstos por separado de errores inesperados (timeouts, 5xx, fallos de conexión o respuestas incorrectas). Validar `Retry-After`, que el cliente espera según la indicación y que las solicitudes se recuperan después de la ventana. Repetir con identidades/clientes distintos para comprobar aislamiento, y observar si una solicitud rechazada llegó a producir efectos. Para escrituras, contrastar claves de idempotencia y estado final para confirmar ausencia de efectos comerciales duplicados.

En cada escenario capturar p95, throughput, tasas de error y saturación del backend (CPU/memoria, conexiones/pool DB, colas o concurrencia activa disponibles). Comparar solicitudes ofrecidas/admitidas/rechazadas y su relación con telemetría de Gateway, APIM y servicio. Registrar configuración exacta de límites, SKU/política autorizados y cualquier desviación observada.

`5 solicitudes por segundo` y `60 por minuto` pueden usarse únicamente como **perfil ilustrativo de laboratorio**, sujeto a autorización del entorno; no son límites productivos aprobados ni valores que este documento atribuya a una SKU. Los contadores distribuidos de APIM pueden presentar desviaciones entre instancias/ventanas. Los criterios deben contrastarse con las garantías de la política y SKU realmente elegidos; no prometer exactitud absoluta.

| ID | Caso k6 | Criterio de aceptación futuro |
|---|---|---|
| RL-01 | Ráfaga por segundo, generación controlada de solicitudes simultáneas | El exceso esperado se rechaza con 429 dentro de la tolerancia documentada para la política/SKU; no hay errores inesperados ni efectos de solicitudes rechazadas. |
| RL-02 | Límite acumulado por ventana corta y larga (segundos/minutos) | Se separa el límite de ráfaga del volumen acumulado; admitidas/rechazadas concuerdan con la configuración dentro de su garantía documentada. |
| RL-03 | `Retry-After` y recuperación | Valor/formato de espera conforme a la política; al esperar y reintentar con backoff, cliente recupera servicio sin avalancha ni errores inesperados. |
| RL-04 | Aislamiento entre clientes autorizados | Agotar el perfil sintético de un cliente no consume el cupo de otro; cada clave corresponde a identidad validada y perfil esperado. |
| RL-05 | Solicitudes bloqueadas no llegan al backend | Conteos/trazas correlacionados demuestran que solicitudes rechazadas en el borde no invocan el microservicio y no alteran estado. |
| RL-06 | Concurrencia e idempotencia en operación crítica | Concurrencia se mantiene dentro de la capacidad acordada; reintentos de la misma operación no duplican efectos y la idempotencia sigue siendo independiente del rate limiting. |

Por cada ejecución conservar SHA completo de Docs/Backend/Frontend aplicables, run y versión del harness k6, revisión Azure atendiendo tráfico, configuración/hash de política, SKU, límites, entorno, timestamps UTC y zona local, semilla/dataset sintético, logs redactados, métricas y artefactos con hash. Una corrida sin sujeto identificable, configuración, revisión Azure o artefactos verificables es `INCONCLUSIVE`, no PASS. Véanse casos y dependencias en la [matriz de trazabilidad](07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md).

**Coordinación H5 sin duplicar responsabilidades:** Castilla es owner del diseño APIM, perfiles cliente/ruta y coordinación; Axel valida compatibilidad Gateway/CD, controles contra bypass y la revisión Azure que atiende tráfico, sin reasignar ni duplicar su transporte Service Bus; Vera mantiene el harness k6 y consolida ráfagas/concurrencia y resultados de performance. Poma valida lecturas Catalog y manejo Frontend de `429`/`Retry-After`; López valida seguridad Frontend, reintentos seguros y Taxonomy; Taco valida protección de Inventory, idempotencia y concurrencia de reservas/stock. Las pruebas RL de esta sección tienen los owners indicados en la matriz RL.
