# Evidencia local

Cada invocación guarda `summary.json`, `summary.sha256` y, si hay métricas, `metrics.csv` bajo `.local/<id>/`. `runtime.json` y `dashboard.html` son artefactos internos de diagnóstico. Revisa el resumen antes de compartir y conserva archivos crudos localmente con acceso restringido. `.local/` está ignorado por Git.

El resumen contiene caso, operación, alcance, timestamp UTC, perfil, repetición, SHA de Backend/Frontend/Docs y del arnés, hashes de archivos, versión k6, dataset, revisión, digest del sujeto (staging), VU observados, duración configurada y total de proceso k6, iteraciones, códigos HTTP, percentiles de lecturas válidas, RPS sobre el intervalo medido, checks, error inesperado, resultado y código de salida. La negativa HTTP explícita tiene su propio contador. El dashboard puede incluir también preparación y cierre; usa las métricas saneadas de la medición para comparar.

Para P3, guarda en `.local/telemetria/<sha256-del-summary>.json` un registro con `summary_sha256`, `telemetry_sha256` del artefacto de telemetría, `warmup_seconds`, `cpu_peak_pct`, `memory_peak_mb` y `db_connections_peak`. El comparador vincula la referencia con el resumen, verifica la presencia de métricas y exige pausas entre ejecuciones. El responsable del entorno conserva la telemetría original con el hash registrado y valida su cobertura. No publiques hostnames, credenciales ni datos de respuesta.

Estados de ejecución. `PASS`, corrida completa con métricas y gates de ejecución satisfechos. `FAIL`, fallo explícito de k6. `INCONCLUSIVE`, evidencia incompleta o no comparable. `NOT_RUN`/`NO_EJECUTADO`, sin medición. El scope local `L1_FIXTURE_SINTETICO` no se admite como entrada para una comparación formal.
