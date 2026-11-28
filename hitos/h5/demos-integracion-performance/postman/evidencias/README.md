# Evidencias saneadas — Suite Postman/Newman G6 Hito 5

Cada corrida ejecutada mediante `scripts/run-newman.ps1` o `scripts/run-newman.mjs` genera una carpeta `<run-id>/` con los siguientes artefactos obligatorios, construidos mediante lista explicita de campos permitidos (allowlist) y verificacion fail-closed contra fugas de secretos:

- `manifest.json`: procedencia completa (Run ID, fecha UTC, entorno, origen autorizado, SHAs locales de Backend/Frontend/Docs, SHA-256 de la coleccion, versiones Node/Newman, contrato OpenAPI, perfil, nivel de evidencia, bloqueos y codigo de salida).
- `newman-summary.json`: totales agregados de solicitudes, estados (`PASS`, `FAIL`, `INCONCLUSIVE`, `NOT_RUN`), aserciones y duracion.
- `integration-results.json`: detalle por caso (`PM-*`, `INT-*`, microservicios, codigo HTTP, `X-Correlation-Id`, aserciones aprobadas/fallidas, estado y motivo de bloqueo).
- `newman.junit.xml`: reporte JUnit XML saneado.
- `report.md`: resumen legible en Markdown para revision tecnica y demostracion ante el profesor.
- `evidence-index.json`: indice de integridad con hashes SHA-256 de los bytes efectivamente guardados de los cinco artefactos anteriores (sin incluirse a si mismo).

## Reglas de publicacion

1. **Nunca publique reportes crudos de Newman.** Los resultados crudos y el archivo de entorno temporal se crean en un directorio privado fuera del repositorio (`$env:TEMP`) y se eliminan automaticamente al finalizar.
2. Si el sanitizador detecta un patron sensible (JWT, `Bearer`, cookies, connection strings, secretos de runtime), bloquea la publicacion y termina con codigo de salida `4`.
3. Las corridas ejecutadas contra el servidor HTTP local de pruebas (`tests/runner.test.mjs`) son validaciones del harness (`ISOLATED`), no evidencia de integracion real en Azure (`LAB_AZURE`).
