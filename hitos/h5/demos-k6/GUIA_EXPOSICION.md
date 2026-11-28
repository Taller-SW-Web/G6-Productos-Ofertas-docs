# Guion en vivo (6 minutos)

Abre un PowerShell en la raíz de Backend, en la rama de integración de k6. Usa los [comandos de Backend](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/blob/58c2a9d2518e157c605cba2e68719659d5ba0bfa/scripts/h5/k6/README.md) para la demo local de Catálogo, con `--dashboard`. Deja el manifiesto privado y el token fuera de pantalla.

| Tiempo | Qué mostrar | Qué decir |
|---|---|---|
| 0:00–0:45 | Matriz y caso PERF-01. | Medimos una lectura GET de Catálogo con un conjunto de productos conocido. El alcance local es `L1_FIXTURE_SINTETICO`. |
| 0:45–1:30 | PowerShell con preflight. | Comprueba SHA, dataset, ventana y perfil. `NO_EJECUTADO` identifica un preflight sin medición. |
| 1:30–2:45 | Demo de 1 VU y dashboard en http://127.0.0.1:5665. | Un VU repite la lectura. RPS son solicitudes por segundo y p95 es el tiempo por debajo del cual se completó aproximadamente el 95% de las lecturas medidas. |
| 2:45–3:45 | Cierra la pestaña y abre el resumen saneado. | Enseña casos válidos, latencias y errores. El 401 de la prueba negativa aparece separado del throughput. |
| 3:45–4:45 | Evidencia. | Muestra el SHA del arnés, el hash del dataset, la versión de k6 y el alcance. El HTML exportado permite presentar la corrida después. |
| 4:45–6:00 | Pricing e Inventario. | Distingue los controladores Nest locales con fixtures del recorrido en Azure. Explica qué hace falta para comparar baseline/candidato y para correr en APIM. |

Ten listo el HTML de una corrida local previa como respaldo. El perfil de 5 VU requiere una ventana autorizada.

## Demo 4 — rate limiting y recuperación de APIM (2–3 minutos)

Este guion usa la revisión de Backend del [PR #325](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/pull/325). Ejecuta la demo remota únicamente cuando exista una ventana y un permiso firmado por Infra y G7. No cambies ni guardes políticas o límites durante la exposición. Si `Retry-After` excede los minutos disponibles, deja la recuperación para después; no acortes la ventana real para ajustar el tiempo de exposición.

### Preparación

En Backend, abre una sesión PowerShell en la raíz del repositorio. El pack `ops/azure/apim/.local/rate-limit/` debe contener el manifiesto efectivo y el permiso con la misma identidad, operación, política, revisión y ventana aprobada. La operación autorizada es exactamente el método GET y el `operationId`/path seleccionados por `manifest.effective.json` y el permiso; no sustituyas esa operación por otra ni amplíes sus límites. El token se inyecta en el entorno del proceso por el mecanismo autorizado, nunca como argumento ni como texto visible.

### Pestañas de Azure Portal

1. **API Management services → apim-g6-productos-chile → APIs → g6-productos-ofertas → operación GET autorizada → Inbound processing → Calculate effective policy.** Enseña el `rate-limit-by-key` efectivo, `calls`, `renewal-period`, clave de consumidor, revisión desplegada y hash contrastándolos con el pack preflight. La policy efectiva puede combinar varios scopes; solo muestra esa operación, sin editarla.
2. Deja preparada la pestaña **API Management services → apim-g6-productos-chile → Monitoring → Application Insights**.
3. En una tercera pestaña abre **Container Apps → api-gateway → Logs**. No cambies el muestreo o el logging durante la prueba.

### Secuencia en PowerShell y k6

Define el pack privado y valida primero, sin tráfico:

```powershell
$K6 = (Get-Command k6 -CommandType Application).Source
$PermitDir = (Resolve-Path 'ops/azure/apim/.local/rate-limit').Path
$Run = @{
    Profile = 'demo-rate-limit'
    Mode = 'remote'
    Config = Join-Path $PermitDir 'config.json'
    Manifest = Join-Path $PermitDir 'manifest.effective.json'
    Parameters = Join-Path $PermitDir 'parameters.effective.json'
    Policy = Join-Path $PermitDir 'policy.effective.xml'
    Permit = Join-Path $PermitDir 'permit-infra-g7.json'
    K6Path = $K6
}

.\scripts\h5\k6\bin\ejecutar-rate-limit.ps1 @Run -SoloValidar
```

Si el preflight informa `NOT_RUN`, no inicies la prueba hasta resolver la autorización/configuración. Con la misma identidad y el mismo pack, comienza la medición:

```powershell
.\scripts\h5\k6\bin\ejecutar-rate-limit.ps1 @Run -Dashboard
```

El dashboard nativo se sirve localmente en `http://127.0.0.1:5665`. Mantén visible el dashboard junto a las tres pestañas de Portal.

### Qué observar y cómo cerrar el ciclo

- **Normal → ráfaga:** mira usuarios virtuales, solicitudes ofrecidas/admitidas, RPS, latencias p50/p95/p99 y códigos HTTP. En la fase normal las lecturas devuelven HTTP 200.
- **Bloqueo:** identifica el momento del primer 429, los admitidos y rechazados y la cabecera `Retry-After`. La consola y `summary.json` muestran el valor observado y su formato; el cliente deja de enviar solicitudes de esa identidad durante el intervalo. Un 429 solo cuenta para RL-01/02 si coincide con la operación y política efectiva verificadas.
- **Recuperación:** tras la espera acreditada, el runner envía una sola lectura con la misma identidad y operación. Enseña el HTTP 200 posterior, el tiempo real de espera y el tiempo de recuperación.
- **APIM y Gateway:** toma los IDs de correlación de respuestas admitidas y rechazadas del resumen. En Application Insights/Gateway contrasta los requests admitidos con el backend y comprueba que las correlaciones rechazadas no tengan request/dependency de Gateway. Sin telemetría correlacionable, RL-05 queda `INCONCLUSIVE`, aunque APIM haya devuelto 429.
- **Aislamiento opcional:** ejecútalo en una corrida independiente con `-Profile aislamiento` solo si hay dos consumidores autorizados y el permiso incluye ambos. Esta fase no condiciona la demo principal.
- **HTML y resultado:** abre `scripts/h5/k6/.local/apim-rate-limit/<run-id>/dashboard.html`; junto a este están `summary.json`, `k6-summary.json` y `evidence-index.json`. `FAIL` indica que no se cumplió un comportamiento esperado; `INCONCLUSIVE` significa que falta evidencia para adjudicarlo; `NOT_RUN` significa que solo se completó validación sin tráfico. Un PASS local es una simulación, no certificación de Azure. RL-06 también necesita evidencia de idempotencia.

Si la ventana efectiva de limitación no cabe en 2–3 minutos, muestra la configuración y el inicio del bloqueo en vivo y presenta la evidencia saneada de una corrida completa previa. Nunca reduzcas `renewal-period`, frecuencia autorizada o límites desplegados para la exposición.
