# Publicación automatizada del visor Swagger

## Fuente y construcción

`contratos/http/openapi.yaml` es la fuente oficial única del contrato HTTP. El workflow `.github/workflows/swagger-docs.yml` valida el contrato y sus referencias, prepara la derivación para Swagger Studio, construye `swagger/dist`, ejecuta equivalencia y Chromium, y finalmente ejecuta la regresión contractual. El visor, `openapi.json`, `openapi.yaml` y `version.json` se generan desde el mismo archivo versionado; no hay una segunda copia mantenida a mano. Las solicitudes API, botones de autorización y almacenamiento de credenciales permanecen deshabilitados.

## Publicación

Al pasar todas las validaciones en un `push` integrado a `master`, el job de Pages puede desplegar el directorio generado en esa misma ejecución. Los PR ejecutan las validaciones y conservan el artefacto de auditoría, pero nunca publican ni modifican el sitio. `workflow_dispatch` conserva la recuperación manual y el job de publicación solo se habilita cuando el ref es `master`. El job descarga el artefacto `swagger-pages-candidate` ya probado, compara su SHA con `master` y rechaza candidatos obsoletos.

La publicación está cerrada por defecto mediante la variable de repositorio `SWAGGER_PAGES_PUBLICATION_APPROVED`, que debe ser exactamente `true` después de una autorización explícita de seguridad. No habilitarla hasta clasificar el contrato y confirmar que el acceso público es aceptable. El repositorio Docs actualmente es público, el API de Pages responde 404 (Pages no configurado) y el contrato contiene operaciones marcadas `provisional-internal`; por ello, a la fecha de esta implementación no hay URL operativa ni autorización demostrada para publicar. No se debe cambiar la visibilidad del repositorio ni activar Pages como parte de esta tarea.

Para la futura activación, un administrador deberá revisar la clasificación y aprobar expresamente la exposición, configurar Pages para desplegar mediante GitHub Actions, asegurar el entorno `github-pages` según la política del repositorio, y solo entonces establecer la variable de aprobación. La ejecución de publicación usa `actions/configure-pages`, `actions/upload-pages-artifact` y `actions/deploy-pages`, permisos de lectura para validación y `contents: read`, `pages: write`, `id-token: write` exclusivamente para el job de despliegue.

## Trazabilidad

`version.json` contiene el SHA completo y abreviado de Docs, enlace al commit, instante de generación UTC, versión `info.version` y SHA-256 del YAML fuente. El encabezado muestra estos datos; la liga al commit abre la revisión exacta de origen. La huella se calcula sobre los bytes del archivo oficial, sin cambiar su contenido.

## Recuperación

1. Revisar el job fallido y descargar el artefacto de auditoría para identificar la validación o fase de despliegue que falló.
2. Corregir el error mediante un PR normal; no editar `master`, saltar CI ni hacer force push.
3. Si el commit de `master` es válido y Pages está autorizado/configurado, ejecutar `workflow_dispatch` con la rama `master` seleccionada. La ejecución repetirá las validaciones completas antes de desplegar.
4. Confirmar que `version.json` identifica el SHA esperado y comprobar el sitio solo después de tener una URL habilitada por el administrador.

Una falla antes del despliegue conserva la última versión publicada correctamente. Si una validación falla, no se genera el candidato publicable; si `master` avanzó, el SHA se rechaza para evitar publicar una versión antigua.

## Cuando cambia Backend

Esta automatización reacciona exclusivamente a Docs. Un cambio de Backend no actualiza ni reconcilia OpenAPI automáticamente. El contrato debe evolucionar en `contratos/http/openapi.yaml` mediante su PR correspondiente; esta solución no sincroniza Backend → OpenAPI ni consulta microservicios desplegados.

## Estado actual y operación manual

No se documenta una URL pública como operativa mientras Pages no esté configurado y la publicación no se autorice. Después de la activación, la URL exacta debe registrarse aquí con evidencia de acceso. El workflow de recuperación se inicia desde **Actions → Validar contrato, Swagger Studio y visor local → Run workflow**, seleccionando `master`; una selección de rama distinta puede validar, pero el job Pages no se ejecuta.
