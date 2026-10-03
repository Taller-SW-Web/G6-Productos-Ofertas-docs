# Sincronización de ramas con GitHub Actions

Implementación local de la automatización analizada en el [issue #47](https://github.com/Taller-SW-Web/Productos-y-Ofertas-docs/issues/47). La decisión posterior del equipo es usar **GitHub Actions**, sustituyendo la recomendación inicial de un supervisor externo. El cierre anterior acreditaba el análisis aprobado; no acreditaba una automatización activa. Esta entrega prepara el ejecutor y sus pruebas. La publicación y la ejecución en GitHub siguen pendientes.

## Alcance

El workflow existente `Sincronizar ramas con master` conserva su contenido. El nuevo `Sincronizar ramas de trabajo` incorpora exclusivamente cambios de una rama oficial a su laboratorio correspondiente. El piloto habilitado es **cueva → lab/cueva**.

Los pares castilla, poma, cueva, lopez, taco y vera están declarados en `.github/sync-config.json`. Solo `enabled_sources` determina cuáles se ejecutan. Ampliar el piloto requiere revisar el alcance con los otros responsables y modificar esa lista; seleccionar manualmente un par deshabilitado produce un error. Nunca se acepta una dirección inversa, un destino alternativo ni otro repositorio. No se crean ni se eliminan ramas.

## Disparadores

| Evento | Resultado |
| --- | --- |
| Push a una rama oficial habilitada | Sincronizar su laboratorio |
| Finalización exitosa de `Sincronizar ramas con master`, ejecutado sobre master | Revisar todos los pares habilitados |
| Comprobación periódica, minutos 7/22/37/52 de cada hora UTC | Recuperar cambios que no hayan sido incorporados |
| Ejecución manual | Seleccionar un par habilitado o todos; simulación predeterminada |

Los eventos automáticos solo ejecutan los jobs cuando la variable del repositorio `SYNC_WORKSPACES_ENABLED` vale exactamente `true`. Si no existe, permanecen suspendidos. La ejecución manual permite validar el piloto antes de activar esa variable.

Los push realizados con `GITHUB_TOKEN` normalmente no disparan otro workflow; por eso se utiliza también `workflow_run`. La revisión periódica cubre ejecuciones anteriores parcialmente fallidas y eventos perdidos. El horario es de respaldo: GitHub puede retrasar u omitir ejecuciones, y puede deshabilitar programaciones de repositorios públicos inactivos. No existe una garantía de sincronización en un plazo exacto. [Token de GitHub Actions](https://docs.github.com/en/actions/concepts/security/github_token), [eventos de workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows).

## Incorporación y conflictos

El ejecutor descarga las dos referencias en un repositorio temporal de objetos, sin cambiar el checkout del desarrollador ni ejecutar código de las ramas que sincroniza. El workflow descarga los scripts y la configuración desde la rama predeterminada revisada. Cada par tiene exclusión de ejecuciones simultáneas mediante `concurrency`; los errores de un par no cancelan otros pares habilitados.

Si el origen ya es ancestro del destino, termina sin crear ni publicar otro commit. En caso contrario exige una base común única y prepara un merge de tres vías. Conserva los cambios funcionales compatibles de ambos lados; cualquier conflicto funcional detiene el par y registra los SHA y archivos implicados. No usa resoluciones globales `ours` o `theirs`.

Las únicas excepciones son:

1. Preservar exactamente el blob y modo del `README.md` operativo del laboratorio. Su encabezado y referencias deben corresponder al owner. El responsable debe mantener ese archivo exclusivamente operativo; el programa verifica su estructura, no clasifica semánticamente cada párrafo.
2. Mantener la línea local `.stitch/` junto con las reglas funcionales resultantes del merge de `.gitignore`. Los conflictos sobre otras reglas siguen siendo bloqueantes. Si el origen elimina `.gitignore`, solo se conserva la exclusión operativa.
3. Rechazar contenido versionado de esa carpeta y rechazar la exclusión operativa en el origen.

Para aplicar estas excepciones se normalizan únicamente esas entradas antes del merge y se restauran después; el resto del árbol participa en la resolución normal de Git. El commit resultante tiene como padres el destino observado y el origen incorporado. La fuente nunca recibe commits de esta automatización.

Antes de publicar, el ejecutor relee ambos SHA. Un hook `pre-push` propio comprueba además la referencia y el SHA de destino anunciados por el servidor, incluso si la rama fue borrada o retrocedió después de la relectura. El push es normal, sin force. Git rechaza cambios posteriores al anuncio cuando actualiza la referencia. Un resultado ambiguo se confirma mediante lectura antes de informar éxito; no hay reintentos ciegos.

La fuente puede avanzar después de la última comprobación; la siguiente ejecución incorpora ese avance. Los commits de sincronización incluyen `Source-Branch` y `Source-Revision` para detectar reescrituras de la fuente posteriores a una sincronización. Antes de la primera incorporación no existe ese registro; una historia sin base común o con varias bases se bloquea igualmente. Una reescritura previa con base común necesita revisión humana si el equipo la conoce.

Ante conflicto, el responsable resuelve los archivos funcionales en el laboratorio incorporando el origen y conservando sus archivos operativos. Después puede repetir una ejecución manual en simulación. No se abre un PR desde el laboratorio hacia una rama oficial. Ante un cambio concurrente, repetir la simulación con las referencias actuales. Ante error de permisos, revisar Actions y las reglas de la rama; el ejecutor no las evade.

## Activación posterior

Esta etapa no publica nada. Para activarlo posteriormente:

1. Revisar y publicar los archivos de esta entrega en la rama predeterminada (`master`). Los eventos manuales, periódicos y `workflow_run` requieren que el workflow exista allí. Publicarlo solo en una rama de trabajo no completa la activación.
2. Confirmar que Actions permite el permiso `contents: write` y que las reglas de `lab/cueva` admiten el push del token del repositorio. No hace falta registrar un PAT ni un secreto nuevo para el diseño actual.
3. Ejecutar `Sincronizar ramas de trabajo` manualmente, origen `cueva`, **Preparar y comprobar sin publicar = true**, y revisar el resumen.
4. Si la simulación es correcta, ejecutar con ese valor en **false**, comprobar el commit del laboratorio y la conservación de su README y reglas.
5. Registrar la evidencia de la ejecución real y establecer `SYNC_WORKSPACES_ENABLED=true` en Settings → Secrets and variables → Actions → Variables. Es una variable de configuración, no un secreto. Esto habilita los siguientes disparadores automáticos del piloto. Las pruebas locales no acreditan permisos ni eventos reales de GitHub. Ampliar `enabled_sources` únicamente después de validar el piloto y acordar el alcance.

El token se usa como encabezado de autenticación limitado al subprocess de Git. No se escribe en URLs, configuración persistente, documentos o resúmenes. `actions/checkout` está fijado a un commit verificado de v7 y no conserva credenciales. Los resultados y conflictos quedan en los logs de Actions; las ejecuciones correctas tienen resumen JSON.

## Pruebas reproducibles

Requisitos: Python 3.10 o superior y Git con `merge-tree --write-tree --merge-base` (validado con Git 2.47.1). No se necesita un servidor, Docker ni paquetes de Python.

```text
python -B -m unittest discover -s tests/automation -v
actionlint -shellcheck= -pyflakes= .github/workflows/sync-workspaces.yml
node tests/automation/validate_workflow.cjs
```

La última comprobación requiere el paquete `yaml` de Node; puede proporcionarse con `NODE_PATH` sin instalar dependencias en el proyecto. La suite de Python crea repositorios bare temporales y realiza pushes exclusivamente entre ellos. No utiliza el remoto del proyecto. El CLI publica al proyecto solamente con `--apply`, desde Actions del repositorio esperado y con su token; por defecto prepara sin publicar.

## Suspensión y retirada

Establecer `SYNC_WORKSPACES_ENABLED=false` suspende nuevas ejecuciones automáticas y permite seguir simulando manualmente. Deshabilitar `Sincronizar ramas de trabajo` desde Actions detiene también el despacho manual; comprobar que las ejecuciones en curso hayan terminado o cancelarlas antes de considerar detenido el servicio. Retirar después el YAML y los archivos exclusivos de esta automatización mediante revisión normal. No borrar ramas, commits de sincronización ni el historial oficial. Eliminar archivos no elimina los registros históricos de GitHub; esa huella es una diferencia explícita respecto a la propuesta externa original. No se crean credenciales permanentes que revocar.
