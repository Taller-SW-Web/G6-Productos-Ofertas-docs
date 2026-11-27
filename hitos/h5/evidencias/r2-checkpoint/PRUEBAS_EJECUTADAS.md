# Pruebas Ejecutadas — Checkpoint G6 H5 R2

## 1. Certificación HTTP + Seguridad + Persistencia + Async (158 operaciones)
- **Archivo ejecutor:** `backend/tests/h5/certify-158-endpoints.mjs`
- **Entorno:** Laboratorio local aislado (PostgreSQL local, stack NestJS completo, API Gateway, G7 JWKS/RS256 de laboratorio, Service Bus aislado en memoria HTTP, simulador G5 HTTPS local).
- **Fecha/Hora de ejecución registrada:** `2026-11-26T18:12:26.464Z`
- **Resultado global:** **FAIL** (exit code 1)
  - `total`: `158`
  - `passed`: `154`
  - `failed`: `4` (`[32]`, `[106]`, `[109]`, `[148]`)
  - `blocked`: `0`
  - `authChecks`: `6/6 PASS` (`login_gestor`, `login_sinrol`, `login_bad_password_401`, `login_blocked_401`, `refresh_rotate_200`, `refresh_reuse_401`)
  - `n01ConsumeStatus`: `COMPLETED`
  - `bulkTerminal`: `PROCESSING` (`CATALOGO=COMPLETED`, `PRICING=COMPLETED`, `INVENTARIO=PENDING`)
- **Artefactos adjuntos en este directorio:**
  - `158_ENDPOINTS_CERTIFICATION_REPORT.json`
  - `158_ENDPOINTS_CERTIFICATION_REPORT.md`

## 2. Pruebas E2E Playwright (Frontend + Stack Real)
- **Specs:** `frontend/tests/e2e-real/eight-modules.real.spec.ts` (10), `http-contracts.real.spec.ts` (5), `transversal-flows.real.spec.ts` (1) — total `16` pruebas.
- **Última ejecución registrada (`frontend/test-results/.last-run.json`):** `2026-11-26 06:09:53` (previa a las correcciones de backend de este checkpoint).
- **Resultado registrado:** **FAIL** (`status: "failed"`, `13` pruebas listadas en `failedTests`, `3` PASS).
- **Nota:** No se re-ejecutó Playwright tras el checkpoint por instrucción de detención inmediata.

## 3. Suite aislada de 19 colas Service Bus (R01–R18, N01)
- **Archivo:** `backend/tests/h5/service-bus-19-queues.e2e-spec.ts`
- **Estado:** **NO EJECUTADA** en este ciclo.

## 4. Validaciones unitarias / build / lint globales post-checkpoint
- **Estado:** **NO EJECUTADAS** tras los últimos cambios por instrucción de checkpoint inmediato.
