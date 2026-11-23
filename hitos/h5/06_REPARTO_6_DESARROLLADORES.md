# Reparto y backlog de los seis desarrolladores

**Naturaleza:** asignaciones de trabajo previstas, no Issues asignados ni permisos. Corte de PRs consultado solo lectura el 22/11/2026 (Lima). Cada tarea tiene owner único; coejecutores aportan dominio/validación. No crear PRs ni implementar en esta entrega.

### Snapshot de PRs y checks (22/11/2026, Lima)

| PR | Estado y HEAD observado | CI observada | Lectura permitida |
|---|---|---|---|
| Backend #247 | Open, Ready; `fb0225b5b5aabccc818bf4d6a5330757008cdb9c` | [CI run 44616107500](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/44616107500) y [job Bulk](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/44616107643) `success` en ese SHA | checks no resuelven colisión DDL/runtime ni habilitan merge |
| Backend #243 | Open, Draft; `bbe22cc7e86ced9a38d76eaa0c7f31a325410b79` | [CI run 44563261329](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/actions/runs/44563261329) `skipped` | `skipped` no es PASS; conservar el contenido único |
| Docs #131 | Open, Draft; `b08adc32d9862366449ae9ed58b9baa94d6b0cf6` | [run 44563265845](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/runs/44563265845) `skipped` | no suplanta la validación de este PR; matriz bajo edición allí |
| Docs #133 | Open, Draft; `6e9ae43e5a06e1d78dc164c7cef43721952c0d55` | [run 45091753721](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-docs/actions/runs/45091753721) `skipped` | propuestas de contrato no son normativa hasta revisión/merge |
| Backend #252 | Open, Draft; `bab152f08af8c83af67871479d566e4117bf3e17` | no se atribuye un resultado de CI aquí | trabajo Bulk `BULK_RETRY_V1`; coordinar con Castilla |
| Backend #254 | Open, Draft; `f259df772c4f3f5473449cbe2f69eb0dde40b79e` | no se atribuye un resultado de CI aquí | receipts/consumo Bulk V4; preservar alcance propio y revisar dependencia con #252/#133 |

Los checks de #247 son propios de su SHA y no constituyen verificación de Azure real, seguridad integral ni release. Los PR #250/#251/#248/#249 de Backend y #87/#91 de Frontend fueron observados como merged en esta consulta; la fusión tampoco demuestra despliegue ni cierre H5. Revisar nuevamente antes de una acción dependiente de estado externo.

## Dueños por criterio

| Criterio | Consolidación | Owners de ejecución |
|---|---|---|
| H5-01 | Castilla | Vera Backend; López Frontend; Axel CD |
| H5-02 | Castilla | Poma Catalog; Taco Inventory; López Taxonomy; Vera Pricing/Audit; Axel Azure/transporte |
| H5-03 | Vera | Poma Frontend; Taco datos Inventory; Axel Service Bus; Castilla APIM |
| H5-04A | Castilla | Axel compatibilidad de red/CD; Infra recurso/costo |
| H5-04B | Axel | Vera R16; López/Poma R18; Poma/Vera R07; Taco R06/R11/R12/R13; Castilla lógica de dominio Bulk/Combos |

## Backlog global con entradas, salidas y gate

| ID / owner único | Coejecutores | Repo / archivos futuros | Entrada y acción concreta | Salida / prueba / gate | PR existente y propuesta |
|---|---|---|---|---|---|
| DOC-01 / Castilla | todos | Docs `hitos/h5/`, futuro `scripts/ci` | requisitos, runs/artefactos → scorecard y evidencia por SHA | validador offline, fixtures negativos; ningún PASS manual | Este PR documental; P1 futuro separado. #131 no tocar matriz |
| APIM-01/02 / Castilla | Axel, Infra, G7 | Backend `ops/azure/apim/` (crear durante la implementación futura) | inventario SKU/red/costo y rutas servidas → Bicep/policies | what-if, hash policies, pruebas APIM 200/401/403/404/429 | No PR APIM identificado; futuro draft condicionado a presupuesto |
| CLOSE-01 / Castilla | todos | Docs guion/scorecard | evidencias verificadas por dueño → scorecard/demo | reporte calculado y demo reproducible | futuro separado; no Issues asignados |
| SB-01 / Axel Cueva | López, Poma, Vera, Taco, Castilla | fork backend `trabajo/cueva/integracion-service-bus-h5`, Bicep/relay | reconciliar fork y PRs activos → transporte único por destino, mantenido por Axel | CI en HEAD final, RBAC, Inbox/Outbox, replay/DLQ y no doble relay | Fork existente `22667994…`; Backend #243 abierto Draft, #247 abierto; no duplicar PR |
| CD-01 / Axel Cueva | Vera | Backend `.github/workflows/cd-services-azure.yml`, `ops/azure` | SHA/digest, OIDC y run protegido → CD/smoke/rollback | mismo SHA y digest, aprobación y smoke HTTPS | #250 merged; ajustes futuros en PR separado si brecha verificada |
| PROM-01 / Axel Cueva | G5/G7, Castilla | Backend `promotions-svc` | contrato/rol real/grants → N01 durable | 202 solo post-commit, GET terminal, 401/403, replay idempotente | #250 merged; no activar con dev role ni grants supuestos |
| CAT-01 / Gabriel Poma | Castilla, Vera | Backend `catalog-svc` | #251 y Bulk V3 de #243 → fixes MK-003/004 y pruebas | pruebas JWT/Gateway/Postgres por SHA, preservar diferencias únicas #243 | #251 merged SHA `f1e33a3…`; #243 abierto Draft SHA `bbe22cc…`; #254 Draft es trabajo distinto de Bulk retry |
| CAT-02 / Gabriel Poma | López | Frontend Catalog | estado API real vs mock → seguimiento async/E2E | Playwright con PENDING/COMPLETED/REJECTED contractual | #87 merged SHA `6b08cf9…`; nuevo solo si gap comprobado |
| CAT-03 / Gabriel Poma | Axel, Vera | Docs/Backend | matriz #131/contratos → evidencia R18/R07 | reporte por mensaje, SHA y homologación | Docs #131 abierto Draft; no editar matriz desde este PR |
| TAX-01 / Leonardo López | Axel, Poma | Backend Taxonomy | reglas de baja y conflicto #247/fork → pruebas de dominio | correlación/resultado terminal sobre único transporte Axel | #249 merged SHA `5f4ac02…`; #247 abierto, no listo para merge |
| FESEC-01 / Leonardo López | Vera | Frontend `.github`, `scripts/h5/security` | workflow #79 vigente → SAST, secretos/SCA y negativos FE | reportes y auth/CSP/CORS verificados | #79 abierto; propuesta debe coordinar mismo workflow |
| TAXFE-01 / Leonardo López | Poma | Frontend Taxonomy | API y estado contractual → UI de bajas/SEO | E2E/accesibilidad y estados, sin endpoint inventado | #91 merged SHA `54dea7a…` |
| INV-01 / Miguel Taco | Vera | Backend Inventory | #248 y contratos → reservas/liberación/idempotencia/carreras | DB descartable, 401/403 y replay único | #248 merged SHA `9d58378…` |
| INV-02 / Miguel Taco | Axel | Frontend Inventory/Backend tests | R06/R11/R12/R13 y UI → integrar estados reales | smoke, replay y no duplicar relay | #90 abierto, SHA `3ea4a38…` |
| INV-03 / Miguel Taco | Vera | fixtures Inventory | parámetros y esquema dataset → datos sintéticos PERF-03 | checksum, semilla, perfil reproducible | No PR específico; futuro por gap comprobado |
| BESEC-01 / Leonardo Vera | Axel | Backend CI/security | workflow actual y conflictos → CodeQL/Gitleaks/SCA/Trivy/SBOM/IaC | reportes reales por SHA; revisar #250 merged primero | #250 merged; PR seguridad separado futuro |
| PERF-PLAT-01 / Leonardo Vera | Poma, Taco, Axel, Castilla | Backend scripts/k6; Docs reportes | benchmarks existentes → plataforma k6 común, comparación de los escenarios PERF en alcance y reporte H5-03 | JSON/CSV, mediana p95/RPS, configuración comparable | PR futuro independiente de #233; PERF-01 sigue siendo la prueba Catalog de Poma |
| PRIC-01 / Leonardo Vera | Axel | Backend Pricing/Price Audit | piloto R16 y #235 → validar outbox/audit/DLQ | corrida Azure actual y no doble efecto por SHA | #235 merged; #233 CSV se mantiene separado |

## Fichas por integrante y criterios de salida

**Castilla — Bulk/Combos, coordinación, APIM, P1 evidencia y cierre.** Entrada: contratos, P0, PRs #131/#133. Salida: docs, scorecard calculado en futuro, integración de APIM/guion; prueba: enlace a run y host real cuando autorizado. Excluir implementación en este PR, matriz de #131 y contratos en #133.

**Axel Cueva — owner único del transporte Service Bus, Azure CD, Promotions y frontera G5.** Entrada: fork, ADR/topología, #243/#247/#250 y rol/identidad. Salida: un relay/Outbox por destino, SB Basic, Bicep/identidad y worker; gate: revalidación del HEAD, CI, RBAC, Inbox, DLQ/recovery, permisos y aceptación de frontera. No habilitar G5 por inferencia.

**Gabriel Poma — Catalog y Frontend Catalog.** Entrada: #251 merged, #243 todavía abierto, #87 merged, Docs #131. Salida: conservar diferencias de Bulk V3, pruebas de handler Catalog e interfaz administrativa. Gate: rutas contrato verificado, Playwright contra API real para L2; no afirmar que #251 reemplaza #243.

**Leonardo López — Taxonomy y seguridad Frontend.** Entrada: #249/#91 merged, #247 abierto y fork. Salida: pruebas dominio/terminales, seguridad UI; gate: reconciliación de DDL/runtime de Axel antes de R18. No introducir segundo relay ni combinar migraciones.

**Miguel Taco — Inventory, integración y resiliencia.** Entrada: #248 merged, #90 abierto, contratos y dataset. Salida: pruebas Inventory/reservas y fixtures PERF-03. Gate: DB descartable, idempotencia/replay y negativos auth; sin duplicar transporte Axel.

**Leonardo Vera — seguridad Backend, consolidación k6, Pricing/Audit.** Entrada: workflows existentes, piloto #235, #233 separado, SHAs y datos de corrida. Salida: reportes SAST/SCA/imagen/IaC, plataforma/reporte H5-03 y prueba PERF-02/R16. Gate: coordinación de workflow/backend y baselines pareadas; no inferir de piloto previo.

## Olas de trabajo y PRs

Ola A documentación y reconciliación paralela; Ola B esquema/validadores y controles internos; Ola C ambiente autorizado para APIM/SB, DAST y carga; Ola D scorecard/demo por SHA. PRs separados por repo y propósito, todos Draft inicialmente. #133 modifica contratos/matriz en otro PR Draft; este PR solo produce Markdown autorizado. El backlog no asigna Issues de GitHub ni crea nombres como si fueran recursos existentes.

## Antiduplificación y revisión

Axel posee transporte; domain owners preservan comportamiento y pruebas. #247 no se declara listo para merge hasta resolver DDL/runtime; #243 conserva contenido único Bulk V3/relay; #250 y #251 están fusionados en esta consulta, sin implicar despliegue. Revisión cruzada propuesta: Poma↔Axel para R18; López↔Axel para Taxonomy; Taco↔Vera para Inventory/perf; Vera↔Axel para SB/CD; Castilla integra APIM/evidencias. Cada PR documenta base SHA, alcance/exclusiones, comandos reales, salida, artifacts, bloqueos, migraciones/rollback y gate.
