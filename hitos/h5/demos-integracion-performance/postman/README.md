# Suite de Pruebas de Integracion HTTP con Postman y Newman — G6 Productos y Ofertas (Hito 5)

## 1. Objetivo

Complementar las pruebas existentes de G6 (Vitest, Supertest, Playwright y el harness de Azure Service Bus) mediante una suite automatizada, reproducible y segura en **Postman y Newman** orientada a validar el sistema desplegado en su capa HTTP: contratos OpenAPI `0.7.0-rc.3`, enrutamiento por Gateway/APIM, politica universal de autenticacion y autorizacion G7, interaccion entre microservicios (`Catalog -> Pricing`, `Catalog -> Inventory`, `Taxonomy`, `Promotions`, `Combos`, `Bulk` y `Price Audit`) y generacion de evidencias saneadas con integridad SHA-256.

Esta suite vive **aislada dentro del repositorio de Documentacion** (`hitos/h5/demos-integracion-performance/postman/`) y no modifica Backend, Frontend, workflows de CI/CD, contratos oficiales ni infraestructura.

## 2. Arquitectura de pruebas

```text
Cliente (Postman Desktop / Newman CLI)
   │  HTTPS + X-Correlation-Id + Bearer JWT (G7)
   ▼
Preflight & Allowlist Guard (scripts/lib/preflight-core.mjs + prerequest de coleccion)
   │  Solo hosts autorizados + metodos seguros de lectura (GET/HEAD/OPTIONS)
   ▼
Borde HTTP autorizado (API Gateway ACA Chile Central; APIM cuando este aprovisionado)
   │
   ├──► catalog-svc ──► pricing-svc (filtro por rango de precios)
   ├──► inventory-svc (disponibilidad, umbrales, dashboard, ubicaciones)
   ├──► taxonomy-svc (categorias, marcas, arbol, tipos de producto)
   ├──► promotions-svc (promociones vigentes, admin, cupones solo lectura)
   ├──► combos-svc (listado y negativo 404)
   ├──► bulk-svc (plantilla CSV v2 y negativo 404)
   └──► price-audit-svc (historial append-only)
   │
   ▼
Sanitizador Fail-Closed (allowlist de campos + deteccion de fugas)
   │
   ▼
Evidencia verificable (<run-id>/: manifest.json, newman-summary.json,
   integration-results.json, newman.junit.xml, report.md, evidence-index.json)
```

## 3. Diferencia entre Postman y Newman

- **Postman Desktop:** interfaz grafica interactiva para importar la coleccion (`g6-h5-integration.postman_collection.json`) y el entorno de ejemplo, inspeccionar solicitudes/respuestas en vivo y ejecutar el **Collection Runner** durante la demostracion ante el profesor.
- **Newman CLI:** ejecutor oficial por linea de comandos de colecciones Postman. Permite correr exactamente la **misma coleccion** desde PowerShell, capturar codigos de salida reales, automatizar preflight, sanear reportes y generar artefactos JUnit/JSON/Markdown con hashes SHA-256.

## 4. Requisitos previos

- **Windows 10/11** con PowerShell 5.1 o PowerShell 7+.
- **Node.js >= 20** (verificado en `v24.16.0`) y **npm** (verificado en `11.13.0`).
- **Git** (verificado en `2.54.0`).
- **Credenciales G7 autorizadas** (solo para casos autenticados): JWT humano (`GESTOR_COMERCIAL`) o token M2M (`serviceBearer`) emitido por G7. Nunca se versionan ni se copian credenciales de otro integrante.
- **Postman Desktop** (opcional, recomendado para la Demostracion A en vivo).

## 5. Instalacion en Windows

1. Verifique Node.js y npm:
   ```powershell
   node --version
   npm --version
   ```
2. (Opcional) Instale Postman Desktop desde la fuente oficial mediante `winget`:
   ```powershell
   winget install --id Postman.Postman --exact
   ```
3. No instale Newman de forma global; el paquete incluye su propia version exacta fijada en `package.json` y `package-lock.json`.

## 6. Instalacion de dependencias mediante `npm ci`

Situese en el directorio del paquete aislado y ejecute:

```powershell
Set-Location 'hitos/h5/demos-integracion-performance/postman'
npm ci
```

Para validar inmediatamente la coleccion y ejecutar las pruebas automatizadas del harness local (preflight, sanitizador y runner):

```powershell
npm run validate
npm test
```

## 7. Variables de entorno necesarias

| Variable PowerShell | Variable Postman | Obligatoria | Descripcion |
|---|---|---|---|
| `G6_ENV` | `environmentName` | No (`azure-apim-chile`) | Entorno destino: `azure-apim-chile` (borde autorizado), `azure-aca-chile` (ACA Modalidad B) o `local` |
| `G6_BASE_URL` | `baseUrl` | No (derivada de `G6_ENV`) | URL base autorizada (HTTPS obligatorio fuera de loopback) |
| `G6_ACCESS_TOKEN` | `accessToken` | Si (casos `userBearer`) | JWT humano G7 (`GESTOR_COMERCIAL`) |
| `G6_RESTRICTED_ACCESS_TOKEN` | `restrictedAccessToken` | Condicional (`PM-005`) | JWT autenticado sin permisos de auditoria para validar `403` estricto (si falta, `PM-005` queda `NOT_RUN`) |
| `G6_MARKETPLACE_ACCESS_TOKEN` | `marketplaceAccessToken` | Condicional (`PM-080`, `PM-081`) | Token tecnico M2M G7 de `modulo-marketplace` (si falta, quedan `NOT_RUN`) |
| `G6_VENTAS_ACCESS_TOKEN` | `ventasAccessToken` | Condicional (`PM-082`) | Token tecnico M2M G7 de `modulo-ventas` (si falta, queda `NOT_RUN`) |
| `G6_CHANNEL` | `channel` | No (`MARKETPLACE`) | Canal comercial (`MARKETPLACE`, `CHATBOT`, `RETAIL`, `VENTAS`) |
| `G6_PRICE_MIN` / `G6_PRICE_MAX` | `priceMin` / `priceMax` | No (`0` / `100`) | Rango amplio de filtro de precios |
| `G6_PRICE_MAX_NARROW` | `priceMaxNarrow` | No (`60`) | Rango acotado para validar invariante `narrow <= wide` y subconjunto de `product_id` |
| `G6_TIMEOUT_MS` | — | No (`20000`) | Timeout por solicitud en milisegundos (usar `45000` en cold start ACA/APIM) |

## 8. Configuracion segura de autenticacion

- **Nunca** pase tokens como argumentos en la linea de comandos ni los guarde en archivos versionados.
- Inyecte su token en la sesion actual de PowerShell mediante entrada oculta (`-PromptToken`):
  ```powershell
  .\scripts\run-newman.ps1 -Profile smoke -Env azure-aca-chile -PromptToken -TimeoutMs 45000
  ```
- O asignelo unicamente en memoria para la sesion activa:
  ```powershell
  $sec = Read-Host -AsSecureString 'JWT G7'
  $env:G6_ACCESS_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
  ```
- Al finalizar, limpie la variable de sesion:
  ```powershell
  Remove-Item Env:G6_ACCESS_TOKEN -ErrorAction SilentlyContinue
  Remove-Item Env:G6_SERVICE_ACCESS_TOKEN -ErrorAction SilentlyContinue
  Remove-Item Env:G6_RESTRICTED_ACCESS_TOKEN -ErrorAction SilentlyContinue
  ```
- En **Postman Desktop**, utilice un entorno local personal, marque las variables de token como tipo `secret`, escriba el valor solo en **Current Value** (nunca en Initial Value) y no sincronice credenciales en workspaces compartidos.

## 9. Importacion en Postman Desktop

1. Abra Postman Desktop.
2. En **Settings → General**, confirme **Automatically follow redirects = OFF** como defensa en profundidad (adicionalmente, las 38 solicitudes de la coleccion incluyen preventivamente `protocolProfileBehavior.followRedirects = false`).
3. Haga clic en **Import** y seleccione:
   - `g6-h5-integration.postman_collection.json`
   - `environments/apim.example.json` (borde autorizado APIM) o `environments/local.example.json`
4. Seleccione el entorno importado en la esquina superior derecha.
5. Configure localmente su `accessToken` en **Current Value** (y opcionalmente `sku` si ejecutara carpetas aisladas como `10 - Integraciones externas`).
6. Seleccione la carpeta `01 - Catalog y Pricing` o `09 - APIM, Gateway y G7` y ejecute **Run folder** en Collection Runner.

## 10. Ejecucion desde Newman

Todos los perfiles ejecutan el preflight de seguridad, crean un entorno temporal aislado en `$env:TEMP`, corren Newman local, sanean los artefactos, calculan hashes SHA-256 y eliminan los archivos temporales.

```powershell
# Preflight independiente
npm run preflight -- --env azure-aca-chile

# Preflight sin token (solo verificacion de estructura y host)
npm run preflight -- --env azure-aca-chile --allow-no-auth
```

## 11. Ejecucion APIM Edge y Smoke

Ejecuta el borde autorizado APIM (`https://apim-g6-productos-chile.azure-api.net`) con preflight, planificacion previa y reconciliacion de casos `NOT_RUN`:

```powershell
# Perfil APIM Edge (borde autorizado sobre /api/v1)
.\scripts\run-newman.ps1 -Profile apim-edge -Env azure-apim-chile -PromptToken -TimeoutMs 45000

# Perfil Smoke completo (incluye probes /health en entorno local o red autorizada)
.\scripts\run-newman.ps1 -Profile smoke -Env azure-apim-chile -PromptToken -TimeoutMs 45000
```

## 12. Ejecucion Integration

Ejecuta las 11 carpetas de lectura segura y negativos contractuales sobre los 8 microservicios y API Gateway/APIM (38 solicitudes):

```powershell
.\scripts\run-newman.ps1 -Profile integration -Env azure-apim-chile -PromptToken -TimeoutMs 45000
```

## 13. Seleccion de casos o carpetas individuales

Puede ejecutar una carpeta especifica con `-Folder`:

```powershell
# Solo Preflight publico contra Azure ACA (sin token)
.\scripts\run-newman.ps1 -Env azure-aca-chile -Folder '00 - Preflight y autenticacion' -AllowNoAuth -TimeoutMs 45000

# Solo Catalog y Pricing
.\scripts\run-newman.ps1 -Env azure-aca-chile -Folder '01 - Catalog y Pricing' -PromptToken -TimeoutMs 45000
```

## 14. Interpretacion de resultados

Cada caso se clasifica estrictamente en uno de los estados oficiales:

- `PASS`: todas las aserciones contractuales y de negocio pasaron sin error de red.
- `FAIL`: fallo una o mas aserciones o la solicitud devolvio error de transporte/timeout. El runner **preserva el codigo de salida `1`**.
- `INCONCLUSIVE`: la solicitud se completo sin aserciones ejecutadas o con evidencia incompleta.
- `NOT_RUN`: caso no ejecutado por bloqueo documentado (por ejemplo, falta de token restringido `PM-005` o falta de token M2M).
- `OUT_OF_SCOPE`: dimension separada del resultado (por ejemplo, pruebas de entrega asincrona Azure Service Bus que corresponden al harness de Backend).

Codigos de salida del runner:
- `0`: **EXCLUSIVAMENTE** cuando `overallVerdict === 'PASS'` (100% de casos planificados ejecutados y aprobados).
- `1`: al menos un fallo funcional (`FAIL`), error de transporte o estado `INCONCLUSIVE` (evidencia saneada igualmente generada).
- `2`: bloqueo de preflight (carpeta inexistente, host no autorizado, URL insegura, credenciales ausentes o secretos detectados).
- `3`: Newman local no instalado (`npm ci` pendiente).
- `4`: fallo del sanitizador (publicacion de evidencia bloqueada por posible fuga sensible).
- `5`: ejecucion parcial (`PARTIAL_NOT_COMPLETE`): uno o mas casos planificados quedaron `NOT_RUN` (`BLOCKED_AUTH` o `BLOCKED_FIXTURE`); nunca se reporta como `exitCode=0`.

## 15. Ubicacion de evidencias

Las evidencias saneadas se guardan en `evidencias/<run-id>/` (o en el directorio indicado con `-OutDir`):

- `manifest.json`
- `newman-summary.json`
- `integration-results.json`
- `newman.junit.xml`
- `report.md`
- `evidence-index.json` (hashes SHA-256 verificables)

## 16. Sanitizacion

El sanitizador (`scripts/lib/sanitizer-core.mjs`):

1. Construye las salidas a partir de una **lista explicita de campos permitidos (allowlist)**: descarta cuerpos de solicitud/respuesta y cabeceras sensibles (`Authorization`, `Set-Cookie`, etc.).
2. Elimina parametros sensibles de URLs y redacta patrones de JWT, `Bearer`, `Basic`, connection strings y secretos de runtime incluso dentro de mensajes de error.
3. Ejecuta una verificacion final fail-closed (`containsSensitiveLeak`) sobre JSON, JUnit y Markdown; si detecta una fuga, bloquea la escritura con codigo `4`.
4. Se ejecuta siempre, incluso cuando Newman reporta fallos funcionales.

## 17. Matriz de cobertura

Consulte la trazabilidad completa por caso PM, caso INT, microservicio, endpoint, scope y bloqueo en:

- [`matrices/cobertura-integracion.md`](matrices/cobertura-integracion.md)
- [`matrices/cobertura-integracion.csv`](matrices/cobertura-integracion.csv)

## 18. Solucion de problemas comunes

- **Timeout en la primera llamada a Azure ACA (`minReplicas=0`):** `api-gateway` y `pricing-svc` pueden escalar a 0 en reposo. Use `-TimeoutMs 45000` en la primera ejecucion o ejecute primero la carpeta `00 - Preflight y autenticacion`.
- **Error `PREFLIGHT` por host no autorizado:** verifique que `baseUrl` coincida exactamente con la allowlist (`api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io` en HTTPS o `127.0.0.1`/`localhost` en modo `local`).
- **HTTP 401 en todos los casos de negocio:** el JWT G7 vencio o no fue cargado en `G6_ACCESS_TOKEN`.
- **Error al cargar Newman:** ejecute `npm ci` dentro de `hitos/h5/demos-integracion-performance/postman/`.

## 19. Limitaciones conocidas

- **Borde APIM Chile live (`apim-g6-productos-chile.azure-api.net`):** Expone 145 operaciones sobre `/api/v1` (el candidato #307 añade 4 operaciones G5 hasta 149; las 5 rutas internas G6→G6 y 2 lecturas admin Pricing quedan excluidas). El acceso directo a ACA (`api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io`) permanece restringido por Modalidad B (`403 RBAC: access denied`).
- **Ejecucion parcial (`PARTIAL_NOT_COMPLETE`):** Cuando falta alguna credencial (`G6_ACCESS_TOKEN`, `G6_RESTRICTED_ACCESS_TOKEN`, `G6_MARKETPLACE_ACCESS_TOKEN`, `G6_VENTAS_ACCESS_TOKEN`), los casos dependientes se clasifican como `NOT_RUN` y el runner nunca declara aprobacion integral `PASS`.
- **Traza downstream Catalog -> Pricing:** Una respuesta HTTP 200 con filtro coherente valida el comportamiento observable, pero acreditar la llamada interna requiere correlacionar `X-Correlation-Id` en logs/telemetria Azure.
- **Mensajeria asincrona (INT-05, INT-10):** Postman/Newman solo cubre la interfaz HTTP de lectura; las entregas Service Bus Inbox/Outbox/DLQ se validan con el harness especializado del Backend.
- **Homologacion externa L3 (INT-09):** Los casos de la carpeta 10 validan la vista de proveedor G6 con tokens M2M separados (`marketplaceAccessToken` / `ventasAccessToken`); no sustituyen una homologacion bilateral con G1/G5.

## 20. Guion de demostracion en vivo (ante el profesor)

### Demostracion A — Postman Desktop (3-4 minutos)
1. Mostrar la coleccion `G6 - H5 Integration Suite` importada en Postman Desktop y el entorno configurado con `accessToken` oculto (`secret`).
2. Abrir `00 - Preflight y autenticacion` -> ejecutar `PM-001` (`/health`) mostrando HTTP 200 y `X-Correlation-Id` autogenerado.
3. Abrir `01 - Catalog y Pricing` -> ejecutar con **Collection Runner** (`PM-002` -> `PM-003A` rango S/ 0-100 -> `PM-003B` rango S/ 0-60 -> `PM-003C` detalle -> `PM-003D` precios por SKU), resaltando el encadenamiento automatico de `productId`/`sku` y la invariante `narrow <= wide`.
4. Abrir `09 - APIM, Gateway y G7` -> ejecutar `PM-004` (sin token -> `401 TOKEN_INVALIDO`) y `PM-007A` (`precioMin > precioMax` -> `400 VALIDACION`) mostrando `application/problem+json`.

### Demostracion B — Newman CLI (2-3 minutos)
1. Abrir PowerShell en `hitos/h5/demos-integracion-performance/postman`.
2. Ejecutar:
   ```powershell
   .\scripts\run-newman.ps1 -Profile smoke -Env azure-aca-chile -PromptToken -TimeoutMs 45000
   ```
3. Mostrar en consola el resumen de solicitudes, aserciones, duracion y codigo de salida.
4. Abrir `evidencias/<run-id>/report.md`, `manifest.json` y `evidence-index.json`, mostrando la ausencia total de tokens y los hashes SHA-256.

## 21. Procedimiento de ampliacion de la coleccion

1. Verificar que la nueva operacion existe en `contratos/http/openapi.yaml` (`0.7.0-rc.3`) y en `apps/api-gateway/src/routing/contract-routes.ts`.
2. Asignar un ID `PM-XXX` unico y vincularlo en `scripts/lib/constants.mjs` (`CASE_METADATA`) y en `matrices/cobertura-integracion.csv`.
3. Mantener el perfil por defecto estrictamente en solo lectura (`GET`/`HEAD`/`OPTIONS`). Cualquier prueba mutante futura debe vivir en una coleccion separada y ejecutarse solo en entornos descartables.
4. Ejecutar `npm run validate` y `npm test` antes de publicar cambios.

## 22. Consideraciones para futura integracion con CI (no implementada)

- Esta mision **no modifica** GitHub Actions para evitar conflictos con la modernizacion concurrente del CI.
- Cuando se integre en el futuro:
  - Instalar dependencias con `npm ci` dentro de `hitos/h5/demos-integracion-performance/postman/`.
  - Ejecutar `npm run validate` y `npm test` en PRs (sin credenciales).
  - Ejecutar `run-newman.mjs --profile smoke` solo en workflows con secretos gestionados por GitHub Environments y subir `evidencias/<run-id>/` como artifact saneado (nunca commitear resultados crudos).
