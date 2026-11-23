# H5-01 — CI/CD y revisión de seguridad

**Estado documental (22/11/2026):** controles y tareas planificados; no se ejecuta escaneo ni se certifica H5-01. La exigencia docente es CI/CD con revisión de seguridad. La selección concreta de herramientas, gates y evidencias de esta sección es `CRITERIO_INTERNO_G6`; la diapositiva SAST/DAST aporta contexto, no una lista académica obligatoria.

## Exigencia docente y criterios internos

G6 propone SAST CodeQL, búsqueda de secretos Gitleaks, SCA npm, análisis de imagen Trivy con SBOM, validación IaC, DAST OWASP ZAP y pruebas funcionales negativas de autenticación/autorización. El resultado debe referir el SHA evaluado, los jobs ejecutados y sus artefactos. Falta de ejecución, `skipped`, timeout, reporte inválido o evidencia expirada significa `NOT_RUN`, `FAIL` o `INCONCLUSIVE` según la causa; nunca PASS tácito.

## Arquitectura de pipelines y controles actuales

Inventario de nombres en los `master` consultados el 22/11/2026 (Lima): Backend (`b4abb3a…`): `ci.yml`, `cd-services-azure.yml`, `performance-g6.yml`, `bulk-h4-integration.yml`, `pricing-catalog-historico.yml`, `publish-only-images.yml`; Frontend (`ba0b8d0…`): `frontend.yml`, `verificacion-despliegue-vercel.yml`, `sync-master-developers.yml`; Docs (`8164510…`): `swagger-docs.yml`, `sync-master.yml`, `sync-workspaces.yml`. La existencia de archivos no demuestra que se ejecuten todos los escaneos requeridos ni que haya CD aprobado. Revisar el workflow y sus runs para el SHA concreto en cada release.

Secuencia futura: PR Draft usa validaciones offline y focalizadas; al pasar a Ready ejecuta CI integral en el HEAD exacto; CD protegido requiere revisión, OIDC, digest de imagen, despliegue autorizado y smoke. Ready no autoriza merge ni producción. Backend #250 está fusionado con merge `2089a43…`; su run previo no sustituye CI/CD del HEAD actual. Frontend #79 permanece abierto (SHA `d3641ae…`) y toca CI: coordinar antes de editar `frontend.yml`.

## Backlog de seguridad y ownership

| ID | Responsable único | Colaboradores | Repositorio / rutas futuras | Entrada → salida verificable | Prueba y gate |
|---|---|---|---|---|---|
| SEC-BE-01 | Leonardo Vera | Castilla | Backend `.github/workflows/`, `scripts/h5/security/` | workflows/lockfiles → CodeQL, Gitleaks, npm audit, Trivy, SBOM, Bicep checks | fixtures y reportes por SHA; no editar CI en conflicto con #250 sin revisar estado fusionado |
| SEC-FE-01 | Leonardo López | Vera | Frontend `.github/workflows/`, `scripts/h5/security/` | workflow #79/lockfile → SAST, secretos, SCA y pruebas de auth UI | PR separado tras reconciliar #79; negativos y artefactos verificables |
| SEC-CD-01 | Axel Cueva | Vera | Backend `cd-services-azure.yml`, `ops/azure/` | digest, OIDC y entorno autorizado → run CD y smoke con SHA | revisión protegida; #250 integrado, no repetir su alcance sin inspección |
| SEC-DOC-01 | Castilla | Todos | Docs `hitos/h5/` | runs y artefactos reales → scorecard calculado | este PR documenta el plan; P1 de automatización sería otro PR |

## SAST, secretos y dependencias

**CodeQL:** verificar primero en GitHub si aplica default setup; habilitar advanced setup solo si no duplica configuración existente y permisos están disponibles. Gitleaks escanea diferencias y rango histórico del PR; redactar secretos y aprobar baseline con owner, motivo, vencimiento y revisión. `npm audit` conserva el verificador existente de Backend; Frontend se añade tras correlacionar lockfile y severidad. Hallazgo nuevo crítico/alto confirmado bloquea; una excepción documenta ID, riesgo, mitigación, owner, vencimiento y aprobación humana.

## Imagen, SBOM e IaC

Trivy analiza la imagen final por digest antes de CD y produce JSON/SARIF; SBOM CycloneDX acompaña el digest y lockfiles. Bicep se valida y `what-if` se revisa antes de aplicar. Bloquear privilegios amplios, endpoints públicos no aprobados y cambios destructivos. Ningún comando de despliegue o cambio de Azure forma parte de este trabajo documental.

## DAST pasivo y activo con autorizaciones

ZAP Baseline o `zap-api-scan.py -S` solo contra instancia descartable, datos sintéticos y contrato de lectura limitado o proxy que bloquee `POST/PUT/PATCH/DELETE`; revisar logs de métodos. `-S` desactiva ataques activos, pero no vuelve inocua una ruta mutante. API Scan sin `-S` exige sandbox efímero, allowlist de host/rutas, identidad de prueba, bloqueo de efectos comerciales y autorización humana explícita. Nunca producción. Sin entorno aislado: `BLOCKED_INFRA` (owner Infra/Seguridad; desbloqueo: entorno descartable accesible y alcance/métodos revisados).

## Pruebas funcionales negativas JWT/CORS/ACL

Casos mínimos: token ausente, firma/issuer/audience/expiración inválidos → 401; JWT válido con scope o `client_id` no permitido → 403; `userBearer`/`serviceBearer` cruzados → denegación contractual; CORS origen autorizado/no autorizado; campos internos de inventario no expuestos; 429 controlado por identidad; errores/logs sin tokens, stack traces ni secretos. APIM y Gateway deben comprobarse independientemente. G7 es dueño de identidad/grants; prueba positiva real requiere token autorizado con issuer, audience, scope, cliente y entorno aprobados. No inventar scopes.

## Gates, hallazgos y excepciones

CRITICAL/HIGH confirmado: FAIL y remediación o excepción aprobada con caducidad. MEDIUM: remediación fechada; bloquea si hay bypass real o fuga sensible. LOW/INFO: registrar con triage. Herramienta omitida, fallo de infraestructura o evidencia no comparable: `INCONCLUSIVE`/`BLOCKED_*`, no PASS. CD valida SHA, digest y sujeto desplegado; CI verde no demuestra CD.

## Automatización, artefactos y aceptación

Artefactos previstos: `codeql.sarif`, `gitleaks.json` redactado, `npm-audit.json`, `trivy.json`, SBOM, `zap.html/json`, `security-summary.json`, run ID, workflow/job y hashes. Comandos de referencia para implementación futura: `npm audit --json`, `gitleaks detect --report-format json`, `trivy image --format json <imagen@digest>`, validación Bicep y workflows de ZAP limitados; no se ejecutan en este PR. PASS futuro de H5-01 requiere SHA de código/build, escaneos realmente ejecutados, DAST en app levantada autorizada, pruebas negativas reales, hallazgos cerrados/excepción formal y procedencia verificada.

## Referencias, dependencias y estados

Owners: Vera Backend, López Frontend, Axel Azure CD, Castilla consolidación. `P0-GH-01`: Admin GitHub debe acreditar CodeQL y protección efectiva de Docs; desbloqueo con lectura de reglas y configuración. `P0-G7-01`: G7 y owner consumidor entregan grant aprobado y prueba negativa/positiva por entorno. `P0-AZ-01`: Infra proporciona inventario de recursos y acceso de solo lectura; acciones de CD además necesitan aprobación. Véanse [workflows Backend](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/tree/master/.github/workflows), [Frontend](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-frontend/tree/master/.github/workflows), [Docs](../../.github/workflows/) y [matriz de evidencias](07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md).
