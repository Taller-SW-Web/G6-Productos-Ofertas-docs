# Automatización H5 y puertas P0–P6

**Estado:** guía futura; esta tarea produce documentación y validación documental local solamente. P1–P6 no se ejecutan aquí. Ninguna puerta operativa convierte por sí sola este PR en Hito aprobado.

## Objetivos por fase

| Fase | Trabajo y repo/owner | Entrada → salida verificable | Gate |
|---|---|---|---|
| P0 | Auditoría diferencial ya ejecutada en ZIP; Castilla consolida | SHAs/PRs/contratos → deltas actuales y puertas pendientes | no rehacer baseline; solo confirmar estado volátil |
| P1 | Plataforma de evidencia Docs; Castilla | esquema/cobertura → validador, provenance y scorecard | offline fixtures válidos/negativos; no editar matriz #131 |
| P2 | Seguridad Backend Vera y Frontend López; CD Axel | workflows/lockfiles → escaneos y negativos | coordinar #79 y revisar ramas mergeadas; PRs Draft |
| P3 | Integración por owner de servicio; Castilla gateway | contratos + casos → L0/L1 y luego L2 con ambiente autorizado | núcleo INT y dependencias etiquetadas |
| P4 | Performance Vera; Poma/Taco datos/UI | benchmark existente → k6, pareamiento y reportes | tres corridas comparables y thresholds previos |
| P5 | APIM Castilla; transporte SB Axel | inventario/red/costo → Bicep/policies/colas aprobadas | no crear ni aplicar recurso sin gate de costo/seguridad |
| P6 | Cierre Castilla + todos | artifacts verificados → scorecard/demo | no PASS sin procedencia y revisión del SHA |

## CI Draft → Ready → merge

En Draft ejecutar pruebas focalizadas, esquema, contrato y validaciones offline sin secretos. Al pasar a Ready, CI integral debe corresponder al HEAD que se revisa; cada commit posterior invalida evidencia previa y relanza checks obligatorios. No desactivar checks ni usar `pull_request_target` con código no confiable. `skipped` no es PASS. Merge requiere checks y protección de rama; Ready no autoriza merge ni producción. La política del repositorio exige Draft durante desarrollo; esta tarea no cambia workflows.

## CLI/API, IaC y acciones humanas

Automatización futura por `git`, `gh` API de solo lectura para procedencia, `az` de solo lectura para inventario, Bicep `what-if`, GitHub Actions, k6, ZAP y PostgreSQL descartable. Acciones humanas: presupuesto/cuota, aprobación de infraestructura, grants G7, autorización de DAST activo, homologación G5, permisos de rama y decisión de merge/deploy. No usar navegador/Computer Use para administrar GitHub/Azure, no pedir secretos y no ejecutar SQL productivo.

Comandos ilustrativos para fases futuras, no ejecutados en este trabajo:

```bash
gh pr view <numero> --repo Taller-SW-Web/<repo> --json state,isDraft,headRefOid
gh run view <run-id> --repo Taller-SW-Web/<repo> --json headSha,conclusion,workflowName,jobs
az apim list --output json
az deployment group what-if --resource-group <grupo> --template-file <main.bicep>
k6 run --vus 5 --duration 3m <script>
```

Los placeholders de estos ejemplos son parámetros de un operador futuro, no decisiones de recurso. `az deployment ... create`, DAST activo, permisos y cualquier efecto requieren autorizaciones y gates descritos en sus fichas.

## Dependencias y orden de PR

1. PR documental de esta tarea; no toca matriz #131 ni contratos. 2. PR seguridad Backend/Frontend por separado, tras revisar #79 y configuración vigente. 3. pruebas de integración por flujo con owners. 4. k6 pareado. 5. APIM Bicep después de inventario/costo. 6. continuar fork de Axel para Service Bus; no abrir segundo transporte ni reimplementar #243/#247/#250. 7. cierre Docs con evidencia real. PR Docs #133 está Draft y edita OpenAPI/AsyncAPI/matriz; el plan H5 aquí no declara sus cambios normativos.

## Puertas P0-AZ/GH/G7/BD/SB

| Gate | Acción bloqueada | Owner y condición concreta para desbloquear |
|---|---|---|
| P0-AZ-01 | declarar L2/APIM/SB desplegado | Infra/Azure: inventario lectura de SKU, VNet/DNS, ACA, SB, identidades, RBAC, revisión/digest y costo |
| P0-GH-01 | afirmar CodeQL/protección efectiva o scorecard gobernado | Admin GitHub: rulesets/reglas efectivas, CodeQL setup y revisión/checks exigidos |
| P0-G7-01 | prueba positiva real JWT y grants | G7 + consumidor: client_id, audience, scope, ambiente, grant vigente y test positivo/negativo |
| P0-BD-02 | activar N01/aplicar DDL | owner BD/Infra: ledger/DDL y rol runtime real reconciliados, migración aprobada y DB descartable validada |
| P0-SB-01 | fusionar fork/#247 o declarar SB compartido | Axel + owners: un runtime/DDL, pruebas en HEAD resultante, RBAC, replay, leases y evidencia Azure destino |
| P5-BUDGET | crear APIM y carga real | autoridad de presupuesto: APIM existente compatible o Developer clásico aislado aprobado; Standard v2 solo destino productivo aprobado |

## Criterios de salida por fase

P1 tests unitarios/documentales, esquema, negativos y output inconcluso correcto. P2 reportes SAST/SCA/secretos/imagen/IaC por SHA y revisión de hallazgos. P3 núcleo L0/L1, L2 real donde exigido y condicionales según release. P4 tres pares y métricas completas. P5 `what-if`, policy hash, recursos privados, permisos y smoke autorizados. P6 todos los artifacts con verificación, scorecard calculado, demo y bloqueos exactos. Cada fase declara `PASS/FAIL/INCONCLUSIVE/NOT_RUN` por caso y no infiere homologación o despliegue.
