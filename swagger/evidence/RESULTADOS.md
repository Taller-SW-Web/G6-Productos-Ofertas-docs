# Evidencia local — 2026-11-05

**Histórico del visor inicial en `2f1346f`.** El objetivo cambió a Swagger Studio oficial: visor retirado y clave duplicada corregida con autorización. Ver [resultados vigentes](RESULTADOS-STUDIO.md).

Base `master`: `a7778ec1a22811c1213a94ef096ab905911342cc`. Rama `poma`. Windows, Node `24.16.0`, npm `11.13.0`, Python `3.14.4`; dependencias npm fijadas en lockfile. Esta evidencia corresponde al contenido del commit que incorpora este archivo; no prueba runtime Backend ni despliegue.

| Comando / acción realmente ejecutada | Resultado |
|---|---|
| `npm run validate` en `swagger` | FAIL esperado: clave YAML repetida idéntica en línea 2183. Swagger Parser acepta la copia JSON y no informa otros problemas; el reporte estricto permanece rojo |
| `npm run build` | PASS: 136 operaciones, 13 tags, 177 schemas, YAML original conservado y manifiesto SHA-256 |
| `npm test` | PASS: integridad del origen, igualdad semántica de JSON, conteo, referencias locales y assets HTML |
| `npx playwright test` | PASS: 1 prueba Chromium; abre 13 grupos/136 operaciones, schemas presentes, mecanismos de seguridad intactos, base `/api/v1`, query maliciosa ignorada, ejecución bloqueada, cero errores JS y cero solicitudes externas. Captura revisada visualmente en `test-results/portal.png` |
| `npm audit --prefix swagger --omit=dev` | PASS: cero vulnerabilidades. Instalación completa final también informó cero |
| `swagger/.venv/Scripts/python -m unittest discover -s tests/contratos -v` desde raíz | 61 pruebas, 1 fallo: caso negativo `InventoryStockChanged` en `test_asyncapi_h4_event_instances.py:151`; 60 sin fallo |
| Misma prueba AsyncAPI desde copia `git archive a7778ec...` | Mismo fallo reproducido: 5 pruebas, 1 fallo. Contratos y tests existentes sin cambios |
| SmartBear `validate_api`, YAML original | Documento reconocido 3.1.0; 459 diagnósticos, con limitaciones en alias/anclas |
| SmartBear `validate_api`, JSON derivado | Válido, cero errores/advertencias; [respuesta guardada](smartbear.json) |
| SmartBear organizaciones/portales | Una organización, cero portales |
| SmartBear gobierno | HTTP 404 por configuración organizacional inexistente |

La primera ejecución Python carecía de jsonschema y sufrió restricciones de temporales; se repitió con un venv aislado y permisos adecuados. La primera prueba Chromium buscaba operaciones dentro de grupos cerrados; se corrigió la navegación del test y la ejecución final pasó. No se cambiaron reglas para obtener resultados verdes.

El workflow se prepara para reportar los dos fallos preexistentes. Su estado remoto se debe consultar en el Draft PR; esta ejecución local no demuestra GitHub Actions PASS. El portal funciona, pero el contrato original no pasa validación estricta. Owner contractual G6/Pricing debe resolver la redundancia; owner Inventario/contratos debe revisar el caso negativo AsyncAPI. Publicación pública, grants G7, gobierno SmartBear e integración persistente siguen pendientes.
