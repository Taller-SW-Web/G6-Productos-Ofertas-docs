# Swagger UI local para G6

Alternativa de consulta a [Swagger Studio privado](README.md), basada en el mismo [OpenAPI oficial](../contratos/http/openapi.yaml). No requiere cuenta SmartBear ni un backend desplegado. Incluye 136 operaciones, 13 grupos y 177 schemas del contrato vigente, incluidos los internos; no implica disponibilidad runtime.

## Instalar e iniciar

Requiere Node 24 y npm. Una vez por checkout, desde la raíz del repositorio y con Internet para descargar dependencias:

```powershell
npm ci --prefix swagger --ignore-scripts
```

Después, iniciar siempre con **un comando**, desde la raíz:

```powershell
npm --prefix swagger run swagger:local
```

Abrir **http://localhost:8080**. Si ya estás en `swagger/`, el comando equivalente es `npm run swagger:local`. Detener con Ctrl+C. Si el puerto está ocupado se informa el error; no se elige otro puerto ni se abre una interfaz de red pública.

Cada inicio reconstruye desde el YAML oficial y sirve exclusivamente en `127.0.0.1:8080` (loopback IPv4, accesible como localhost). No usa `0.0.0.0` ni requiere cambios de firewall, Docker o infraestructura. Los demás integrantes ejecutan su propia copia local; esta URL no comparte el visor por LAN.

Swagger UI `5.34.1`, sus estilos y licencias se copian desde dependencias fijadas a `dist/`. No hay CDN, fuente visual remota, validador online ni consulta a SmartBear al iniciar. Después de instalar, construir y consultar funciona sin Internet. Las pruebas de navegador requieren instalar Chromium por separado; el uso normal del visor no lo descarga ni lo necesita.

## Consultar el contrato sin ejecutar APIs

Filtrar por tag/ruta y abrir operaciones para parámetros, request bodies, respuestas, ejemplos y códigos de error. Models muestra los schemas. La sección **Mecanismos de seguridad — solo consulta** presenta `serviceBearer`/`userBearer` y sus descripciones, sin formularios de tokens. Las extensiones de scopes, roles y clientes se conservan por operación. Los errores proceden del contrato y [catálogo](../contratos/http/catalogo-errores.md).

`supportedSubmitMethods: []` y `tryItOutEnabled: false` deshabilitan Try it out; los controles Authorize se sustituyen por la referencia de solo lectura. No se capturan ni persisten credenciales. Un interceptor rechaza intentos de solicitudes API; CSP restringe conexiones al propio origen. El servidor solo acepta GET/HEAD de una lista fija de archivos de documentación: `/api/v1/*` no se ejecuta.

`queryConfigEnabled: false`, especificación local precargada y `validatorUrl: null` evitan reemplazar el contrato por parámetros de URL o enviarlo al validador externo. El servidor devuelve `Cache-Control: no-store`. La prueba Chromium bloquea todas las conexiones fuera de localhost y comprueba que ninguna se intenta.

El JSON de visualización se genera mecánicamente del parser estricto, con igualdad completa al documento fuente: no cambia título, `servers`, seguridad ni schemas. Se conserva `/api/v1`, pero ninguna petición de API se ejecuta. `dist/openapi.yaml` es copia generada, `dist/openapi.json` su representación y `manifest.json` registra el hash. No editar/versionar esos artefactos. Para reflejar un cambio aprobado en Docs, reiniciar el comando.

## Pruebas reproducibles

Desde `swagger/`:

```powershell
npm run validate
npm run export
npm run build:local
npm test
npx playwright install chromium
npm run test:browser
```

Las dos pruebas Node comprueban equivalencia local y exportación Studio, hashes, assets locales, referencias y URLs. Chromium aislado usa el mismo comando de inicio: verifica contrato cargado completo, grupos/operaciones, schemas, seguridad de solo lectura, parámetros/body/respuestas, ausencia de Try it out/Authorize, rechazo de escrituras, bloqueo de rutas API y conexiones externas. Genera `test-results/local-overview.png`, `local-security.png` y `local-endpoint.png`.

El workflow existente añade estas comprobaciones y adjunta capturas, reporte Playwright, `dist/` y reportes contractuales. Conserva `requirements-validation.txt`, el preflight `not-a-date` y las 61 pruebas contractuales que daban SUCCESS en `61cf5441`; no se crea otro workflow. Ver [evidencia local](evidence/LOCAL-UI.md).

Los resultados del visor local no prueban My APIs, CORS de Studio, JWT G7 ni disponibilidad del Gateway. La API privada de SmartBear y sus requisitos de acceso permanecen en [su guía](README.md).
