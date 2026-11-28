# Guion en vivo (6 minutos)

| Tiempo | Qué mostrar | Qué decir |
|---|---|---|
| 0:00–0:45 | Matriz y caso `PERF-01`. | Medimos una lectura GET de Catálogo con IDs esperados por página. Anuncia el alcance `L1_FIXTURE_SINTETICO` o `L2_STAGING_APIM` según la corrida autorizada. |
| 0:45–1:30 | PowerShell con el preflight. | Verifica SHA, dataset, ventana, CLI y perfil. `NO_EJECUTADO` indica que todavía no hubo una corrida. Mantén fuera de pantalla secretos y configuración privada. |
| 1:30–2:45 | Ejecuta 1 VU y abre `http://127.0.0.1:5665`. | Un VU es un usuario virtual que repite la lectura. RPS son solicitudes por segundo; p95 es el tiempo por debajo del cual terminó aproximadamente el 95% de las lecturas medidas. Señala la tasa limitada, la latencia y los checks. |
| 2:45–3:45 | Cierra la pestaña del dashboard y abre el resumen saneado. | Identifica código de salida, VU medido, checks, p50/p95/p99, RPS y errores. Enseña el 401 negativo separado si usaste el fixture. La exportación HTML queda en `.local/`. |
| 3:45–4:45 | Evidencia reproducible. | Enseña SHA, hash del dataset, revisión, versión k6 y alcance. Para resultados comparables se necesitan tres repeticiones de cada sujeto y telemetría. |
| 4:45–6:00 | Pricing, Inventario y permisos pendientes. | Explica qué rutas se prepararon. Muestra los estados esperados del dataset de Inventario. Indica qué pruebas necesitan identidad, staging o acceso privado y qué quedó sin ejecutar. |

Ten listo el resumen de una ejecución local previa como respaldo si falla la demo en vivo. Preséntalo con su propia fecha y alcance. Usa el perfil de 5 VU solo con una ventana aprobada separada.
