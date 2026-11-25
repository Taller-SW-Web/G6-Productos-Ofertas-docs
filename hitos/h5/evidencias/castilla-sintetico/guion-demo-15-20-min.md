# Guion de demostración H5 (15–20 minutos)

**Plantilla operativa; completar solo con release aprobado y evidencia real.** No mostrar tokens, datos personales, cuentas, identificadores Azure ni capturas de resultados fabricados.

| Minutos | Criterio y operador | Acción / comando al preparar release | Evidencia y decisión |
|---|---|---|---|
| 0–2 | Castilla | `git rev-parse HEAD` en Backend/Frontend/Docs; `node scripts/h5/evidence/verify-release.mjs <manifest> <evidences>` | SHAs independientes, imagen por digest, policy hashes, ambiente/dataset y aprobación. Si falta campo: INCONCLUSIVE. |
| 2–6 | Vera / López / Axel | Abrir runs de seguridad del SHA y descargar SARIF/SBOM/JUnit; revisión manual de hallazgos | Distinguir run_success, job_success, artifact_verified, sha_matches y manual_review. Sin revisión, H5-01 no pasa. |
| 6–10 | Owners de integración | Reejecutar INT de manifest mediante comandos por caso de sus harnesses | Distinguir L1 aislado, L2 recursos reales y L3 acta bilateral. Para INT-04 mostrar HTTP y R01/R04 como dimensiones separadas. |
| 10–13 | Vera / Castilla | `k6 run` únicamente en runner y ambiente autorizados; `scorecard.mjs` compara baseline/candidato por tres repeticiones | Mostrar p50/p95/p99, RPS, filas/s, errores, métricas/recursos y comparabilidad. Escenario incompleto: INCONCLUSIVE. |
| 13–16 | Castilla / Infra / G7 | APIM real: 200/401/403/404/429, CORS, rate/burst y cuota separados, dos identidades, no-bypass | APIM-T05 es caso integral en Docs. Policy hash/SKU y trazas. Sin APIM real: BLOCKED_APIM. |
| 16–19 | Axel / owners de dominio | Mostrar R16 y R18 (preferido) o R07 solo tras decisión explícita; Outbox→Basic→Inbox, redelivery/DLQ/recovery | Namespace listado no cuenta como flujo. Mostrar SHA, identidad y recurso de prueba. R03/R14 siempre reservados. |
| 19–20 | Castilla | Leer scorecard derivado y bloqueos por owner; rollback previsto por owner Azure | H5-01, H5-02, H5-03, H5-04A y H5-04B independientes. Comunicar G5/G7 pendientes. No declarar H5 cerrado por CI verde o piloto. |

## Reejecución y rollback

1. Guardar manifest firmado/aprobado, evidence bundle y hashes antes de la sesión.
2. Ejecutar únicamente comandos exactos de `test_command` de los casos `IN_SCOPE`, con el mismo SHA/revisión.
3. Si hay falla, detener el paso mutante; el owner del servicio decide rollback usando su procedimiento versionado. No restablecer políticas, colas ni datos desde este guion.
4. Para APIM/CD, seguir la aprobación y rollback del owner de infraestructura; para DB, del owner de BD; para G5/G7, detenerse y escalar al owner correspondiente.
5. Regenerar scorecard desde evidencia verificada. Mantener las cuatro dimensiones de release separadas.
