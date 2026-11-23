# H5-04A — Azure API Management verificable

**Estado:** planificado, APIM actual `NO_VERIFICADO`; no hay despliegue ni acceso Portal en esta tarea. La exigencia docente H5-04 incluye API Management. El inventario, SKU, políticas y casos siguientes son criterios internos G6.

## APIM y Gateway G6

APIM administra el borde HTTP externo; el API Gateway G6 conserva guards, allowlist de cliente, autorización por ruta/scope y paso al owner de dominio. El recorrido esperado es cliente HTTPS→APIM→Gateway→servicio. No publicar servicios internos directamente, ni considerar un Gateway propio equivalente a APIM. G7 es autoridad de identidad y grants; APIM puede validar JWT cuando issuer/JWKS sean compatibles, pero no reemplaza autorización del Gateway.

## Inventario de SKU, red y costo

**Primero** consultar en modo lectura si existe APIM reutilizable, SKU, región, hostname, VNet/subnet, DNS privado, TLS, conectividad a Gateway/ACA, cuotas, titularidad y costo. El ZIP P0 identifica `P0-AZ-01` como `NO_VERIFICADO`; no inferir recurso por workflow o contrato. Si no existe instancia compatible, Developer clásico con VNet es opción académica aislada no productiva y sin SLA, solo con cuota/costo y conectividad aprobados. Standard v2 se reserva para objetivo productivo con aprobación presupuestaria explícita. No usar Consumption como supuesto viable: `rate-limit-by-key` y conectividad privada requeridas no están disponibles de la misma forma. Si ninguna opción compatible se aprueba: `BLOCKED_BUDGET`; no abrir Gateway privado al público.

Owner de inventario/costo: Infra/autoridad presupuestaria; Castilla coordina evidencia. Desbloqueo: salida CLI fechada de inventario, SKU/red verificadas, presupuesto/cuota aprobados y arquitectura privada probada. No solicitar acceso al Portal en esta tarea.

## Bicep, políticas y autenticación

Plan futuro: Bicep versionado (módulo APIM, APIs/operaciones, policies, diagnostics), `az deployment group what-if`, revisión de diff y autorización operativa antes de aplicar, con rollback a revisión anterior. Importación deriva del OpenAPI canónico `0.7.0-rc.3` (`APPROVED_G6`), filtrada a rutas actualmente servidas y habilitadas; la aprobación contractual no prueba operación desplegada. No inventar URL, ruta, scope, audience o hostname.

Policies: validar JWT issuer/audience/firma/expiración si G7 autoriza JWKS; CORS con orígenes exactos; correlación `X-Correlation-Id`; redacción de logs; timeout mínimo. `rate-limit-by-key` es una opción prevista solo si está soportada y autorizada por el SKU realmente elegido; si no, evaluar una política compatible disponible en ese SKU. No asumir soporte universal entre SKUs. La clave debe basarse en identidad confiable: identidad validada/client_id para autenticados, y una IP extraída solo de la cadena de proxies confiables para públicos sin autenticación. El Gateway repite comprobaciones de cliente/scope pertinentes; no habilitar bypass por URL interna. Guardar hash del policy y versión de Bicep.

### Protección contra exceso de solicitudes

APIM-T05 es una comprobación integral: perfil por cliente, ruta y tipo de operación; rechazo de exceso; aislamiento; llegada al Gateway/backend; y convivencia con autenticación/autorización de G7 y Gateway. Configurar de forma separada el rate limiting de ráfagas, el límite acumulado/cuota por ventana y los controles de concurrencia/procesos costosos. Son controles distintos: rate limiting limita frecuencia, cuota limita volumen agregado, concurrencia limita trabajo simultáneo y WAF filtra/mitiga clases de tráfico malicioso o DDoS. Ninguno sustituye a los otros ni a JWT/grants o idempotencia.

Validar respuesta HTTP `429`, `Retry-After` cuando aplique, recuperación y backoff del cliente. Usar clientes sintéticos distintos y probar que superar el perfil de uno no bloquea a otro. Correlacionar los rechazos del borde con telemetría de Gateway/servicio para demostrar que las solicitudes rechazadas no alcanzan los microservicios. Verificar además que una ruta directa al Gateway no elude APIM: bloquear el origen alternativo mediante controles de red o autenticación de origen compatibles con la arquitectura aprobada y confirmar la denegación en prueba. APIM autentica/limita el borde según política; G7 mantiene autoridad de identidad/grants y Gateway su autorización por cliente/ruta.

`rate-limit-by-key` o política compatible se selecciona según SKU y capacidades documentadas para la instancia autorizada; no se infiere soporte universal ni se fija una configuración productiva aquí. Los contadores distribuidos pueden desviarse; documentar la garantía/tolerancia de esa política y SKU. La auditoría Azure del 22/11/2026 no encontró APIM en la suscripción revisada: H5-04A permanece `NO_VERIFICADO`/bloqueado por infraestructura. No afirmar que APIM, WAF o rate limiting están desplegados.

## Escenarios positivos, negativos y 429

| ID | Comprobación | Evidencia |
|---|---|---|
| APIM-T01 | HTTPS al hostname real llega a la ruta autorizada y owner esperado | host, fecha, ruta contractual, status y corr ID |
| APIM-T02 | Token válido autorizado alcanza Gateway; sin token/firma/iss/aud/exp inválido denegado | solicitud redactada, status y logs correlacionados |
| APIM-T03 | scope/client_id no permitido recibe 403 | política hash y resultado, con grant de prueba |
| APIM-T04 | origen CORS permitido y no permitido | headers exactos y respuesta |
| APIM-T05 | Protección integral contra exceso: límites de ráfaga y ventana por ruta/perfil; 429/`Retry-After` y recuperación; aislamiento de clientes; solicitudes rechazadas no llegan a backend; Gateway directo bloqueado; convivencia G7/Gateway | identidad/cliente sintético, operación, política y SKU/revisión Azure, ventanas y límites, respuestas y `Retry-After`, trazas correlacionadas de Gateway/backend, verificación de ruta directa, métricas de concurrencia y registro redactado |
| APIM-T06 | ruta desconocida devuelve 404, sin proxy genérico ni fuga a backend | request/response sin secreto y trazas |
| APIM-T07 | encabezado de correlación llega a Gateway/servicio sin filtrar datos | logs redactados y corr ID |
| APIM-T08 | comparación de acceso privado equivalente y rollback de config | dos rutas en entorno aislado y versión restaurada |

Las respuestas 200/401/403/404/429 se validan por separado; pruebas mutantes y DAST se limitan a ambiente descartable. Smoke aislado de Gateway sin hostname APIM no acredita H5-04A.

## Evidencias, gates y rollback

Paquete de aceptación futuro: salida `az` de lectura, recurso/SKU/host/revisión, SHA de Bicep, `what-if`, approval ID, hash de policies, status/respuestas HTTPS, logs sanitizados, SHAs Backend/Docs, digest desplegado y rollback probado. Se exige tráfico real al APIM y backend privado alcanzable. `BLOCKED_INFRA` si inventario/red incompletos; `BLOCKED_AUTH` si falta grant G7; `BLOCKED_BUDGET` si gasto no aprobado; fallos observados son FAIL. No se marca PASS por un Swagger, YAML o URL de Gateway.

## Responsable, PRs y referencias

Castilla owner APIM, catálogo de rutas y consolidación; Axel coejecuta compatibilidad de red/CD, Infra aprueba recursos/costo; G7 aprueba grants/issuer. PR futuro separado en Backend/infra; esta rama escribe solo Docs. Véanse [OpenAPI](../../contratos/http/openapi.yaml), [HITO_5](../HITO_5.md), [CI/CD](01_CI_CD_Y_SEGURIDAD.md), [automatización](08_AUTOMATIZACION_Y_PUERTAS.md) y [scorecard](07_MATRIZ_TRAZABILIDAD_Y_EVIDENCIAS.md).
