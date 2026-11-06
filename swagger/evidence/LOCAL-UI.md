# Evidencia de Swagger UI local

Base: `poma@61cf5441345b236d78d2e7d05afcedf70dc4425c`, con CI SUCCESS de las correcciones de auditoría. Recuperación selectiva desde `2f1346f`: HTML/JS/CSS del visor, estructura de build/servidor y pruebas Playwright; adaptados al contrato estricto y a la convivencia con Swagger Studio.

## Ejecución local comprobada

- Comando real desde raíz: `npm --prefix swagger run swagger:local`.
- URL comprobada: `http://localhost:8080`; respuesta de `/manifest.json`: HTTP 200, versión `0.6.0-rc.3`, 136 operaciones, 13 tags, 177 schemas.
- Socket observado con `netstat`: `127.0.0.1:8080 LISTENING`. El intento de inspección CIM no tuvo permisos; se usó la tabla TCP sin cambiar permisos ni configuración.
- Build local conserva igualdad completa con el YAML oficial y no aplica transformaciones Studio. Hash del origen local Windows: `3654df676144c47b3c59b1f4034ad87194ab3cd7d9e630c4d3868ee3fa6bcc2b`. Hash semántico de exportación Studio conservado: `549fda5691c480a0c821d4bc7c60be2b97ed60c830559bff5998a0a7c37a3883`.

## Pruebas ejecutadas

| Comprobación | Resultado local |
|---|---|
| Parser/validación OpenAPI estricta | PASS, 136 operaciones |
| Exportación Studio y build local | PASS; misma fuente, sin transformaciones adicionales |
| `npm test` | 2 pruebas PASS: equivalencia/exportación Studio y visor local, assets, hashes, referencias y URL |
| `npm run test:browser` | 2 pruebas PASS con Chromium aislado: carga/navegación y servidor estático |
| Peticiones externas | En la prueba de navegador se bloquean todas las URL fuera de `http://localhost:8080`; cero intentos externos observados. No se desconectó físicamente Internet del equipo |
| Operaciones y schemas en navegador | Se abrieron 13 grupos, 136 operaciones; definición cargada idéntica al JSON local completo, 177 schemas; ejemplos, parámetros, request body y respuestas visibles |
| Seguridad local | `serviceBearer` y `userBearer` visibles como referencia de solo lectura; sin Authorize, formulario de contraseña, Try it out ni Execute. Interceptor rechaza peticiones API |
| Servidor local | GET/HEAD de assets PASS; ruta API y traversal 404; POST a documentación 405 |
| Preflight de fecha inválida | PASS; `not-a-date` rechazado por `format` en `data/updated_at` |
| Regresión contractual original | **61 pruebas, OK**; requisitos Python y expectativas conservados |
| Instalación npm | Dependencias fijadas Swagger UI 5.34.1 y Playwright 1.65.0; instalación informó cero vulnerabilidades |

Capturas reales generadas y revisadas visualmente: `swagger/test-results/local-overview.png`, `local-security.png` y `local-endpoint.png`. El workflow existente adjunta estas imágenes y el reporte Playwright al artefacto `swagger-studio-revision`, junto con las dos construcciones; no se publica un sitio.

## Alcance y límites

La consulta local requiere Internet solo al instalar dependencias. El inicio/build posterior lee archivos locales; no hay CDN, llamada al validador externo ni dependencia de SmartBear. No se ingresaron ni enviaron credenciales y no se realizaron solicitudes al Gateway real.

La ejecución aislada de Chromium solo controla este visor en localhost. No controla Chrome del usuario ni verifica My APIs, páginas privadas, CORS, JWT G7 o Try it out de Studio. La API privada y la integración previamente configurada se conservan; no hubo escrituras SmartBear. OpenAPI, AsyncAPI, migraciones y las 61 pruebas originales no se modifican.

El resultado remoto del SHA publicado y el enlace al CI se registran en el mismo Draft PR #116. Esta evidencia local no sustituye el run remoto ni afirma despliegue de APIs.
