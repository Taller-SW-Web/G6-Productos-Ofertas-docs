# Runbook para un release futuro — NO EJECUTAR AHORA

1. Reconciliar cada ledger/DDL con el proyecto Supabase G6 identificado y rol owner; correr preflight de solo lectura, backup y prueba de PostgreSQL 17 descartable.
2. Autorizar y aplicar migraciones incrementales por owner y orden de dependencia, incluyendo R10 solo tras handler R02/R10 listo y rollback probado. Validar estructura y grants, sin reejecutar migraciones históricas.
3. Construir imágenes de HEAD aprobado, fijar digest y SHA, CI Ready verde, revisar flags por recorrido y grants; preparar rollback de imagen/revisión antes de cambio de tráfico.
4. Desplegar en ventana autorizada, smoke autenticado/negativo, revisar Outbox/Inbox, DLQ y métricas por flujo. Revertir flags/tráfico ante error; no borrar mensajes ni saldos.
5. APIM separado: presupuesto, red, filtro efectivo, `what-if` APIM-only, candidato aislado, pruebas T/RL, luego decisión independiente de cutover y cierre de ingress con rollback.

Este documento no constituye permiso para ejecutar pasos productivos.
