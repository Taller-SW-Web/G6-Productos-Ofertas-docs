# Validación local de la automatización

Entrega del 2026-10-02, preparada en `codex/sync-environments-actions`, sobre `cueva` en `b05dd63`. La propuesta anterior del #47 tenía 24 simulaciones del diseño; los resultados siguientes corresponden al **ejecutor implementado**.

## Resultados

| Comprobación | Resultado |
| --- | --- |
| Suite Python: 27 casos de integración Git y 9 casos de configuración/CLI | 36 pruebas aprobadas |
| Contrato YAML, analizado con el paquete `yaml` de Node | 25 comprobaciones aprobadas |
| actionlint 1.7.12: sintaxis, eventos y expresiones de GitHub Actions | Sin errores |
| Workflow `sync-master.yml` frente a la base `b05dd63` | Sin modificaciones |
| Publicación o activación en el proyecto remoto | No realizada |

Python estándar y Git **2.47.1.windows.2** ejecutaron las pruebas con repositorios bare temporales. Las pruebas positivas realizaron un push real entre esos repositorios locales y verificaron el commit recibido. Las pruebas no usaron GitHub ni modificaron referencias del proyecto. El binario de actionlint se obtuvo de su release oficial y se verificó su SHA256 contra el archivo de checksums publicado. ShellCheck y Pyflakes no se ejecutaron; el comando de actionlint los deshabilita explícitamente.

La suite inicial de 31 pruebas pasó completa después de corregir la eliminación de entradas en índices bare; después pasaron los 9 casos de configuración/CLI (incluyen 4 adicionales) y el caso adicional de una base sin archivos operativos. Total: **36 casos distintos**. No se cuenta la repetición de pruebas como cobertura adicional.

## Cobertura

- Configuración estricta: seis pares exactos, piloto, claves duplicadas/desconocidas, tipos, exclusión de rutas fuera del contrato, dirección inversa y owners deshabilitados.
- Selección por push, finalización del workflow anterior, programación y despacho manual; salida `matrix`/`has_work` del planificador.
- Origen ya incorporado, simulación sin publicación, push correcto e idempotencia de una segunda ejecución.
- README operativo preservado, incluso con CRLF; reglas oficiales nuevas, ausencia de salto final, eliminación de `.gitignore` oficial y base sin archivos operativos.
- Cambios funcionales compatibles de ambas ramas; conflicto funcional y conflicto en reglas de `.gitignore` bloqueantes.
- Ramas inexistentes, historias ajenas, múltiples bases, README inválido o symlink, contenido operativo versionado y regla local contaminando el origen.
- Incorporación de un merge proveniente de master y detección de una reescritura posterior de la fuente.
- Cambios concurrentes de la fuente o destino antes de publicar; avances, retrocesos y borrado del destino después de la comprobación previa y antes del anuncio de push.
- Hook que rechaza publicación inversa, más de un destino o creación de una rama ausente.
- Confirmación por relectura cuando el push fue aceptado pero el cliente informa un error; credencial ausente de la configuración persistente.
- Publicación por CLI bloqueada fuera de Actions; eventos automáticos condicionados por una variable inicialmente ausente y prueba manual en simulación por defecto.

## Alcance pendiente

La validación local acredita la lógica, el contrato del workflow y los pushes contra fixtures. No acredita todavía una ejecución alojada en GitHub, sus eventos, disponibilidad, permisos de `GITHUB_TOKEN` ni reglas de protección de `lab/cueva`. Tampoco activa los otros cinco pares. El [procedimiento de activación](sincronizacion.md) permite comprobar el piloto antes de encender los eventos automáticos. La entrega sigue siendo local, conforme a la instrucción del usuario.
