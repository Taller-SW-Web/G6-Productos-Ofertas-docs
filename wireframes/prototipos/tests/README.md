# Validación local de WF-005, WF-006 y WF-007

`validate-005-007.cjs` recorre los HTML de demostración con Playwright en 1440×900. Comprueba gestión, validaciones, conservación de datos, límites, cambio de modalidad, alcance por producto/SKU y estados de carga/acceso. Usa datos en memoria y no consulta servicios externos.

`validate-contracts.cjs` analiza OpenAPI/AsyncAPI, comprueba referencias locales y valida los schemas administrativos afectados con YAML, AJV 2020 y ajv-formats.

Requisitos: Node.js, Playwright y un navegador Chromium; para contratos, `yaml`, `ajv` y `ajv-formats`. Pueden estar instalados fuera del repositorio. Los scripts aceptan rutas a módulos mediante `PLAYWRIGHT_MODULE`, `YAML_MODULE`, `AJV_MODULE` y `AJV_FORMATS_MODULE`; `CHROME_PATH` permite usar Chrome instalado. No es necesario incorporar esas dependencias al prototipo.

Desde la raíz del repositorio:

```text
node wireframes/prototipos/tests/validate-005-007.cjs
node wireframes/prototipos/tests/validate-contracts.cjs
```

`VALIDATION_OUTPUT` y `CONTRACT_VALIDATION_OUTPUT` permiten guardar los resultados JSON en rutas elegidas por el ejecutor. Un fallo termina con código distinto de cero.

Estas pruebas no acreditan backend, persistencia, integración con Ventas ni despliegue en Supabase. Los fixtures se reinician al recargar y la información comercial de recomendaciones permanece ausente hasta resolver D-REC-01/02.
