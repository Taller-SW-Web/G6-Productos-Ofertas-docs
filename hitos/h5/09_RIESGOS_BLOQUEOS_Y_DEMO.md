# Riesgos, bloqueos y demostración del Hito 5

**Estado:** guía de operación y demo planificada; no hay ejecución nueva ni certificación H5. Los hallazgos P0 del paquete son un corte histórico auditado y no se reabren como auditoría general.

## Riesgos y bloqueos con owner/condición

| ID | Riesgo/impacto | Acción afectada | Owner | Condición verificable de desbloqueo |
|---|---|---|---|---|
| P0-AZ-01 | infraestructura APIM/SB/ACA y red no verificados en vivo | declarar L2 o crear/usar recurso | Infra/Azure + Castilla/APIM + Axel/SB | inventario CLI con SKU, VNet/DNS, recursos, identidad/RBAC, digest/revisión y presupuesto |
| P0-GH-01 | protección Docs/CodeQL configurados no comprobados en el P0 | scorecard confiable y checks | Admin GitHub | reglas efectivas, setup CodeQL y approvals/checks documentados con lectura autorizada |
| P0-G7-01 | grants/tokens reales no comprobados | JWT positivo, INT-07/09, N01 | G7 + owner de integración | grant exacto por cliente/audiencia/scope/entorno y test real positivo/negativo sin exponer token |
| P0-BD-02 | ledger DDL/rol Promotions producción difiere de rol dev | activar N01 o aplicar migración | owner BD/Infra + Axel | reconciliar origen/hash/ledger, identificar role runtime, migración revisada, prueba descartable con mínimo privilegio |
| P0-SB-01 | fork Axel y #247 no comparten DDL/runtime Taxonomy | integrar R18/#247 | Axel transporte; López dominio | seleccionar una migración/runtime, preservar pruebas dominio y CI/replay/lease/DLQ en SHA final |
| P5-BUDGET | APIM compatible puede no tener cuota/costo aprobado | APIM real, PERF-08 y DAST/carga en staging | autoridad presupuestaria/Infra | inventario reutilizable o tier aprobado y conectividad privada comprobada |
| DOC-PR | Docs #131 y #133 pueden editar fuentes solapadas | matriz/contratos | Poma (#131), Castilla (#133), responsable Docs | mantener este PR en archivos autorizados y coordinar conflictos antes de editar fuentes compartidas |

P0-AZ, P0-GH, P0-G7, P0-BD y P0-SB no impiden este plan documental; cada uno bloquea solo su operación. El P0 ZIP es `READ_ONLY_COMPLETED_FOR_P1`, H5 `NOT_CERTIFIED`. Esta revisión confirma estados volátiles el 22/11/2026 Lima; no afirma cambios de Azure ni DB.

## Fallbacks sin fingir PASS

Si falta Azure, presentar L0/L1 como estáticos/aislados y marcar L2 `BLOCKED_INFRA`; no llamar a eso evidencia real Azure. Si G7 no concede token, documentar casos negativos simulados como L1 y marcar positivo real `BLOCKED_AUTH`. Si falta G5, presentar solo el flujo G6 independiente y dejar L3 `BLOCKED_EXTERNAL`; owner G5/G6 debe registrar homologación bilateral antes de desbloquear. Si no hay APIM/costo, no publicar Gateway como sustituto ni ejecutar PERF-08; `BLOCKED_BUDGET`. Si R18 no puede ser reconciliado, seleccionar R07 antes del ensayo; no combinar #247 con el fork. Si runs/artefactos han expirado, copia hash-verificable o `INCONCLUSIVE`.

## Demo de 15–20 minutos por criterio

| Minuto | Criterio | Guion y evidencia real que debe estar lista |
|---|---|---|
| 0–2 | Contexto/estados | índice, cuatro exigencias docentes, división 04A/04B, estados implementación/evidencia/homologación separados |
| 2–6 | H5-01 | abrir CI del SHA, checks ejecutados, SARIF/secret/SCA/SBOM/ZAP, negativo JWT; explicar cualquier `BLOCKED_*` |
| 6–10 | H5-02 | ejecutar/reproducir INT-01/05/07/08/10 según manifest; mostrar nivel L0/L1/L2, correlación, logs y artefactos |
| 10–13 | H5-03 | abrir comparación baseline/candidato de tres runs, 1/5/20 VU, p95/RPS/error y ambiente; declarar inconclusión si no comparable |
| 13–16 | H5-04A | mostrar hostname APIM real, policy hash, ruta y 200/401/403/404/429/CORS; Gateway sola no cuenta |
| 16–19 | H5-04B | acreditar R16 y un segundo flujo R18 o R07: ejecutar uno en directo y mostrar para el otro evidencia verificable por SHA/artefacto. Cubrir Outbox→Basic→Inbox/resultado, redelivery/DLQ/recovery y ausencia de doble efecto; explicar límites Basic. Una sola ruta no satisface el criterio interno de dos flujos. |
| 19–20 | Cierre | scorecard calculado, SHAs/digests, homologación y bloqueos con owners; no declarar H5 completo si algún gate falta |

Si cualquiera de esas evidencias no existe, usar captura de plan/artefacto histórico etiquetada como tal, no recrear resultados ni afirmar PASS. El piloto #234 puede ilustrar R16 histórico, claramente como laboratorio/alcance parcial.

## Checklist de cierre y límites externos

Antes de presentar: verificar H5-01/02/03/04A/04B por SHA; guardar run ID, artifact ID/hash y subjects de cada repo; separar `PASS/FAIL/INCONCLUSIVE/NOT_RUN`, nivel, despliegue y verificación; probar links y redacción de secretos; acordar externos con owner y evidencia. G5 mantiene dueño de pedido/pago y homologación de su lado; G7 de identidad/grants; autoridad Azure de costo y recurso; owner DB de migraciones; Admin GitHub de políticas. La presencia de contrato, prueba local o run verde no equivale a aceptación externa.

Referencias: [HITO_5](../HITO_5.md), [reparto](06_REPARTO_6_DESARROLLADORES.md), [scorecard](07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md), [automatización](08_AUTOMATIZACION_Y_PUERTAS.md), [topología Basic](../../contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md) y [matriz Service Bus](../../integraciones/MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md).
