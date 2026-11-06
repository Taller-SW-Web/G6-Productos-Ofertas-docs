# Portal HTTP G6

Estado operativo: **IMPLEMENTAR_AHORA** para documentación local, construcción y pruebas. Publicación pública pendiente de autorización. Fuente única: [OpenAPI oficial](../contratos/http/openapi.yaml), OpenAPI 3.1.0, candidata `0.6.0-rc.3`. El portal muestra todas sus operaciones, incluidas las internas; no acredita disponibilidad runtime.

## Uso local

Requiere Node 24 y npm. Desde la raíz del repositorio:

```powershell
cd swagger
npm ci --ignore-scripts
npm run build
npm run serve
```

Abrir `http://127.0.0.1:8080`. El servidor escucha exclusivamente en loopback. Usar HTTP local, no abrir el HTML con `file://`. No necesita microservicios ni SmartBear. Tras cada cambio del contrato, repetir `npm run build`. `dist/` es descartable y no se versiona; contiene assets locales, licencias, YAML fuente, JSON derivado y un manifiesto con SHA-256. No hay CDN ni carga de contratos por parámetros URL.

La construcción lee automáticamente el YAML canónico. Solo para la visualización elimina claves repetidas **si sus valores son idénticos**, registrándolas en `manifest.json` y en el aviso del portal. Una repetición contradictoria detiene la construcción. No se elige silenciosamente una regla ni se modifica el contrato. El JSON no se edita ni se devuelve al YAML: es un artefacto de compilación.

## Validación y pruebas

```powershell
npm run validate
npm run build
npm test
npx playwright install chromium
npx playwright test
```

`validate` usa YAML estricto y Swagger Parser, verifica referencias, seguridad, operationId y prefijos; escribe `reports/validation.json` y devuelve código distinto de cero ante hallazgos. **Actualmente falla por una clave duplicada idéntica preexistente**: ver [hallazgos](HALLAZGOS.md). No interpretar el build como aprobación del YAML original.

Desde la raíz, la regresión existente requiere PyYAML y jsonschema:

```powershell
python -m pip install PyYAML==6.0.3 jsonschema==4.25.1
python -m unittest discover -s tests/contratos -v
```

El workflow [swagger-docs.yml](../.github/workflows/swagger-docs.yml) corre en PR a `master` y manualmente. Construye, verifica archivos/referencias, prueba Chromium, ejecuta regresión y adjunta un artefacto por siete días incluso si falla la validación estricta. El job conserva ese fallo al finalizar. No tiene permisos de Pages, no despliega y no depende de servicios SmartBear. Ejecutar `npm audit` para revisar dependencias fijadas en el lockfile.

## Navegación, seguridad y errores

Filtrar por tag o ruta; expandir una operación para parámetros, bodies, respuestas, `operationId` y extensiones `x-*`. En Schemas se encuentran los modelos y `Problem`; [catálogo de errores](../contratos/http/catalogo-errores.md) explica los códigos. `serviceBearer` y `userBearer` permanecen en la especificación y en la información de seguridad. Los scopes de JWT bearer se documentan en `x-required-scope`, no como scopes OAuth inventados. Ver [kit](../contratos/http/kit-integracion.md) para JWT, roles, audiencias y grants pendientes.

`supportedSubmitMethods: []`, `tryItOutEnabled: false`, `validatorUrl: null` y `queryConfigEnabled: false` evitan ejecución, validación remota y sustitución por query string. El portal oculta los botones de credenciales, no persiste autorización y rechaza peticiones API mediante interceptor. La CSP restringe conexiones al mismo origen. `servers[0].url=/api/v1` se conserva sin concatenarlo a los paths; no duplica el prefijo ni ejecuta peticiones al host de Pages. [Configuración oficial de Swagger UI](https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/).

## SmartBear verificado

Evaluación real del complemento Swagger, 2026-11-05; [evidencia](evidence/smartbear.json):

| Capacidad | Expuesta / resultado |
|---|---|
| Organizaciones y portales | Consultados: una organización accesible, cero portales |
| Validación estructural | Ejecutada con `validate_api`: YAML reconocido con 459 diagnósticos; JSON derivado válido, cero diagnósticos |
| Gobierno organizacional | `scan_api_standardization` ejecutado; HTTP 404, configuración inexistente |
| Búsqueda y exportación | Expuestas `search_apis_and_domains` y `get_api_definition`; sin API G6 identificada para exportar |
| Importar/diseñar/editar | Expuestas creación, actualización, edición puntual y generación IA; no utilizadas |
| Versiones | Edición puede crear versión; importación impone 1.0.0 y preserva visibilidad al actualizar. No equivale a administrar libremente la candidata G6 |
| Documentación/publicación | Expuestos portales, productos, páginas y publicación; sin espacio privado G6 verificado, no ejecutadas |
| Comparar versiones, entornos, mocks, tests runtime, sincronización Git | No hay herramientas específicas expuestas. Importación crea con automock desactivado; no prueba capacidad de gestionar mocks |

La conexión funciona; no existe integración persistente Docs–SmartBear ni sincronización automática. Solo se enviaron documentos para validación sin crear recursos. Antes de cualquier importación se debe verificar un espacio privado autorizado para G6 y su visibilidad; pertenecer a una organización de un miembro no acredita ese alcance. No usar `resolve_organization_portal` como consulta inocua: puede crear un portal. Tampoco aplicar corrección IA automática al contrato.

Flujo futuro: Docs aprobado → validación → importación privada verificada → lectura/exportación y comparación con el SHA del origen. Prohibir edición remota como fuente normativa y sincronización bidireccional. SmartBear no es una dependencia del CI. No se verificó plan, licencia ni mecanismo oficial de CI autenticado de esta cuenta; no se contrata nada ni se agregan secretos.

## Versiones y publicación futura

Cada artefacto registra versión contractual y hash del origen. No incrementar `info.version` por actualizar el visor. Para compatibilidad, proponemos evaluar [oasdiff](https://www.oasdiff.com/docs/github-action) en un cambio posterior con binario/acción fijados, sin carga de revisiones al servicio externo (`review: false`). Detecta eliminaciones de endpoints, métodos, parámetros, cambios de obligatoriedad, respuestas y seguridad; los códigos y comportamientos `x-*` propios requieren además las pruebas contractuales G6. No sustituye revisión funcional ni homologación. Comparar contra un SHA normativo aprobado e identificado por el owner; `master` candidato no implica aprobación de todos sus contratos externos. No comparar contra una exportación temporal de SmartBear ni bloquear cambios compatibles sin un diagnóstico concreto.

| Criterio | GitHub Pages | SmartBear |
|---|---|---|
| Mantenimiento/automatización | Reutiliza build y Actions del repo | Requiere identidad, configuración y revisar límites de la cuenta |
| Versiones y divergencia | Artefacto trazado a commit/hash | Copia remota con comparación obligatoria |
| Visibilidad | Repo público; revisar política de Pages y operaciones internas antes de habilitar | Privacidad de producto/API y permisos deben verificarse |
| Dependencia externa | GitHub para alojamiento; ejecución local autónoma | Cuenta/plan y servicio SmartBear |
| Preparación H4 | Artefacto estático listo para revisión | Sin portal ni espacio G6 autorizado verificado |

Se recomienda preparar el artefacto para futuro alojamiento estático controlado; **no habilitar Pages público** con el contrato interno completo. Una publicación pública requiere revisión del owner sobre visibilidad y operaciones internas y autorización explícita. No se ha creado workflow de deploy ni modificado configuración de Pages. Para SmartBear, confirmar antes cuenta/plan, espacio privado, versionado y proceso unidireccional. La documentación completa puede seguir usándose localmente.

Documentado: contrato candidato y decisiones existentes. Implementado: visor y automatización en este PR. Probado: solo comprobaciones con resultados en [evidencia local](evidence/RESULTADOS.md). Homologado: únicamente lo acreditado en acuerdos del repo. Desplegado: este trabajo no acredita despliegue ni disponibilidad de APIs.
