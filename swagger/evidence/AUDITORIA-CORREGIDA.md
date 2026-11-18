# Corrección de auditoría del PR #116

Base de esta corrección: `poma@bd5f2ef2c8864f8c57f830fb8497316b1a8d9bf4`. Master integrado: `a7778ec1a22811c1213a94ef096ab905911342cc`. Esta evidencia identifica el contenido del commit que incorpora este archivo; el SHA y la ejecución remota final se registran en el mismo Draft PR.

## Causa y corrección del CI

En el entorno anterior, `jsonschema==4.25.1` estaba instalado sin `rfc3339-validator`: `date-time` no figuraba en `Draft202012Validator.FORMAT_CHECKER.checkers` y `checker.conforms('not-a-date', 'date-time')` devolvía `True`. El test ya pasaba FORMAT_CHECKER y el contrato ya declaraba `format: date-time`; no se requería alterar ninguno. [Documentación de dependencias opcionales](https://python-jsonschema.readthedocs.io/en/stable/validate/).

Se fijaron `rfc3339-validator==0.1.4`, `six==1.17.0` y el resto de dependencias del entorno en [requirements-validation.txt](../requirements-validation.txt), compartido por CI y ejecución local. El workflow comprueba `pip check` y ejecuta un preflight que falla si el checker no está registrado o no rechaza la fecha inválida, incluyendo la ruta real `InventoryStockChanged.data.updated_at`. No se modificaron AsyncAPI, OpenAPI, fixtures ni las 61 pruebas contractuales.

## Resultados ejecutados localmente

Python 3.14.4, Node 24.16.0. CI utiliza Python 3.12 y Node 24.

| Verificación | Resultado |
|---|---|
| Instalación del archivo fijado y `pip check` | PASS; sin dependencias rotas |
| `check-validation-environment.py` | PASS: checker registrado, fecha válida aceptada, `not-a-date` rechazada, fixture válido aceptado y `data/updated_at` inválido rechazado por `format` |
| `python -m unittest discover -s tests/contratos -v` desde raíz | **61 pruebas, 0 fallos, OK** |
| `npm run validate` | PASS: 136 operaciones, sin errores de validación estricta |
| `npm run export` | PASS; sin transformaciones nuevas; hash semántico `549fda5691c480a0c821d4bc7c60be2b97ed60c830559bff5998a0a7c37a3883` conservado |
| `npm test` | PASS: equivalencia, referencias, patrones reconocibles de secretos y coherencia editor/documentación |
| Lectura SmartBear del recurso existente | `private=true`, `published=false`, versión `0.6.0-rc.3`; 136 operaciones, 13 tags, 177 schemas. Fecha de modificación conservada `2026-11-06T00:30:00Z` |

El reporte de preflight se genera en `swagger/reports/date-time-environment.json`, incluido en el artefacto `swagger-studio-revision` de CI. Logs/Checks del HEAD final en PR #116 acreditan el resultado remoto; las ejecuciones anteriores fallidas son históricas. La detección de secretos usa patrones reconocibles y no sustituye una auditoría exhaustiva de información sensible.

## Acceso y pendientes reales

Se añadió `/apis-docs/` junto al enlace de editor; se verifican host/owner/nombre/versión según el patrón oficial, no la visualización de páginas privadas. Se documentó selección manual de **Use browser**, revisión de servidor HTTPS, CORS/preflight y uso de JWT únicamente con grant y sin proxy SmartBear.

- **Terminado en Docs:** instalación reproducible, rechazo explícito de fechas inválidas, validación/exportación/equivalencia, enlaces coherentes y procedimiento de revisión manual.
- **Gateway/infraestructura:** CORS del origen real, preflight y headers permitidos/expuestos; revisar exposición/upstream de marcas. Última sonda registrada de `/marcas`: 503; no se repitieron llamadas al backend en esta corrección.
- **G7/integración:** provisión/grants y prueba autenticada real; GET 200 sin JWT no acredita G7 ni fase activa. SHA de backend desplegado pendiente.
- **Usuario/owner de Studio:** comprobar acceso View para colaboradores, abrir documentación privada, seleccionar modo directo y verificar Try it out; no se usó automatización de navegador.

No se creó ni actualizó la API remota, no se enviaron credenciales y no se modificaron Backend, Caddy, Oracle, permisos G7 ni otros repositorios. PR #116 permanece Draft.
