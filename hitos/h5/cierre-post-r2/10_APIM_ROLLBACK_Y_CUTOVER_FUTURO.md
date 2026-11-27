# Rollback y cutover posterior

No hay policy ni revisión APIM que restaurar hoy. Para un candidato futuro: capturar XML y SHA256 de policy antes de aplicar, ejecutar `what-if`, aplicar solo API/ruta aislada, obtener XML real por `az rest --method get`, comparar hash y probar restauración del candidato con snapshots before/during/after independientes. No cambiar la revisión actual de otra API.

El cutover de `api/v1` y bloqueo del Gateway directo requieren autorización aparte, diseño de ingress/ACL compatible con ACA, pruebas de DNS/VNet, ventana y rollback. En esta entrega Gateway conserva `external=true` y su revisión/tráfico. Por ello `APIM-READY_FOR_CUTOVER`, `CUTOVER_DONE`, anti-bypass y H5-04A completo son **NO ACREDITADOS**.
