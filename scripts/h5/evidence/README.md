# Evidencias H5 v1 — herramientas offline

Utilidades Node.js nativas (`node:fs`, `node:crypto`, `node:test`) para validar evidencia y generar cobertura derivada sin dependencias productivas. El recolector opera offline y no ejecuta builds. No se ha ejecutado ningún test en esta entrega.

## Comandos

```powershell
node scripts/h5/evidence/validate-evidence.mjs <records.json>
node scripts/h5/evidence/validate-release-manifest.mjs <release-manifest.json> <bundle-root>
node scripts/h5/evidence/verify-artifact.mjs <relative-uri> <bundle-root> <sha256> <source-sha> <provenance.json>
node scripts/h5/evidence/scan-repositories.mjs <repos.json> <inventory.json> [--gh-readonly]
node scripts/h5/evidence/verify-link.mjs <https-url> --network --allow-host=<exact-host>
node scripts/h5/evidence/scorecard.mjs <records.json> <release-manifest.json> <scorecard.json> <scorecard.md>
node scripts/h5/evidence/verify-release.mjs <release-manifest.json> <records.json>
node --test scripts/h5/evidence/test/*.test.mjs
```

Los comandos son guías; `node --test` está intencionalmente pendiente de la auditoría externa. Primero adaptar el bundle de evidencias que aporten los owners. No usar `SYNTHETIC_NOT_RELEASE_EVIDENCE` en el manifest de release.

## Seguridad y límites

- Scanner filesystem/Git de solo lectura; no invoca npm, builds, workflows, Azure mutante, SQL ni carga.
- El scanner no consulta GitHub por defecto. `--gh-readonly` usa `gh run view` de solo lectura para runs enumerados en el config; nunca descarga artifacts ni afirma checksum. Registra run/job, artifact, SHA y revisión manual como campos distintos.
- `verify-artifact.mjs` no hace requests remotos; las URI remotas permanecen no verificadas hasta descargar bytes por un proceso autorizado/allowlisted y verificar hash. No acepta `sandbox:` ni rutas absolutas/traversal.
- `verify-link.mjs` solo se activa con `--network`; acepta HTTPS/443 y host exacto allowlisted, resuelve y bloquea direcciones privadas/reservadas, fija el resultado DNS del salto, limita timeout/cuerpo/redirecciones y no envía cookies, Authorization ni JWT. Revisa accesibilidad sin calcular hash remoto; checksum solo después de obtener bytes completos por una descarga autorizada.
- Un SHA de repositorio puede diferir entre Backend, Frontend y Docs; dentro de un release un repositorio no puede mezclar SHAs.
- `run_success`, `job_success`, `artifact_verified`, `sha_matches` y `manual_review` se conservan como valores independientes en adaptador GitHub.
- `L0/STATIC`, `L1/ISOLATED`, `L2/LAB_AZURE` y `L3/INTERGROUP` aceptan alias documentados sin elevar nivel. L2 requiere identidad/recurso; L3 requiere acta bilateral.
- `PASS` exige artefacto local accesible y SHA-256 correcto; la procedencia es commit Git existente revisado localmente o metadata de GitHub con run/job/SHA/artefact verificables y revisión humana completa. `NOT_RUN`/`BLOCKED_*` no fabrican artefactos.
- `R03` y `R14` son reservados y siempre excluidos. `R16` y `R18` son flujo mínimo; R07 solo reemplaza R18 con decisión explícita.

## Archivos

`schema.v1.json`, `release-manifest.schema.v1.json`, validadores semánticos, adaptadores SARIF/SBOM/vulnerabilidades/k6/JUnit/GitHub, matriz fija de casos, fixtures positivos/negativos y tests no ejecutados. El diagnóstico está aislado bajo `hitos/h5/evidencias/castilla-*`.
