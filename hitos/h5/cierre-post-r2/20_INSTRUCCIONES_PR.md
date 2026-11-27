# PRs Draft y revisión

- Backend: migración candidata R10 con rollback, aislamiento de API/path/named values/logger APIM, filtro OpenAPI regenerado y 29 tests estáticos. Revisión de Taco/Inventory, arquitectura/APIM y seguridad; sin merge ni deploy.
- Frontend: los PRs existentes #90/#92/#94/#101 no se fusionaron automáticamente. Cualquier delta futuro debe reaplicarse y probarse en PR propio; esta entrega no atribuye un PR nuevo de runtime sin cambio revisable.
- Docs: baseline, estados por caso, bloqueos, runbook y atestación. No altera OpenAPI/AsyncAPI ni la matriz normativa de flujos.

Mantener Draft hasta revisión favorable y autorización; CI integral corresponde al HEAD final cuando pase a Ready. Un commit nuevo invalida los resultados anteriores. El merge y despliegue son decisiones posteriores separadas.
