# Instrucciones comunes para los encargos de IA

**Preparado:** 2026-10-17, America/Lima. Este documento acompaña las fichas; las instrucciones vigentes del repositorio destino siguen aplicando.

## 1. Uso de estos documentos

Cada ficha es un encargo retrospectivo derivado de un issue real y puede usarse como contexto para una nueva sesión autorizada. Su redacción actual no afirma que este texto fuera el prompt original. La creación de esta carpeta documenta la preparación de encargos; la ejecución se acredita con sesión, diff, revisión y resultados.

Este catálogo no ejecuta las tareas, no reasigna personas y no activa trabajo POSTDEMO. La copia del issue registra la versión consultada; antes de ejecutar, comparar el issue y AGENTS.md vigentes.

## 2. Inicio de una sesión

1. Identificar repositorio, rama y estado del árbol; preservar cambios preexistentes.
2. Leer AGENTS.md y README.md del destino, el issue completo y los criterios de aceptación.
3. Comparar asignados actuales con ownership funcional; registrar cualquier diferencia antes de cambiar un área conflictiva.
4. Leer SPEC, HU, FLOW y WF aplicables. Luego registro DEC-F, matriz y ADR pertinentes; revisar OpenAPI/AsyncAPI, guías, acuerdos e implementación afectada.
5. En frontend o mockups leer UX transversal, DESIGN.md, component-spec, plan y tasks; leer validation-report solo cuando exista. En backend revisar arquitectura, modelo conceptual, persistencia y pruebas relacionadas.
6. Enumerar archivos concretos previstos para cambiar. Las rutas de una ficha son límites del encargo, no prueba de que todo ese código exista.
7. Separar prerrequisitos para programar, dependencias de pruebas integradas y condiciones de despliegue. Clasificar el trabajo autorizado según IMPLEMENTAR_AHORA, IMPLEMENTAR_PARCIAL o BLOQUEADO_ESPECÍFICO y citar la fuente.

Una contradicción detiene solo el cambio dependiente. Registrar ambas fuentes, estados, owner que debe resolver y condición verificable de desbloqueo. Continuar partes independientes.

## 3. Ejecución acotada

- Aplicar DEC-F-001 a DEC-F-015 dentro de su alcance; no crear decisiones posteriores ni completar interfaces por intuición.
- Conservar ownership de los ocho bounded contexts y responsabilidades externas. Seguridad concede permisos; una ficha no acredita grants ni homologación.
- No reescribir migraciones aplicadas. Toda escritura SQL en Supabase conserva los requisitos expresos de Marco, alcance y despliegue aprobado; este catálogo no los concede.
- Los ejemplos backend se limitan al servicio y sus pruebas; Gateway requiere el issue transversal específico. Dependencias y configuración global solo con alcance explícito.
- Frontend usa componentes, tema y adapters existentes; leer package.json para elegir las pruebas reales de la versión. En modo API no convertir fallos en mocks exitosos.
- Mantener código de prototipo y frontend productivo como entregables distintos.
- Conservar la política de ramas del destino. El nombre de una subcarpeta solo organiza ejemplos: no crea ni selecciona una rama.
- Este catálogo no autoriza commit, push, apertura de PR, merge, mensajes externos ni despliegue. Si el issue los menciona, conservarlo como requisito del flujo sujeto al encargo humano vigente.

## 4. Evidencia que debe producir la sesión

Vincular issue → instrucción → fuentes/SHAs → archivos/diff → ajustes humanos → pruebas → revisión. Usar la [plantilla de intervención](../uso-ia/plantilla-intervencion.md) para documentar una sesión ejecutada.

Registrar herramienta y modelo cuando se conozcan, fecha real, ID/exportación de sesión, propuestas incorporadas o descartadas y responsable humano. No inferir autoría de IA por estilo de código ni calcular porcentajes sin método/evidencia.

Informar comandos, resultado, entorno y SHA/árbol probado. Distinguir NO EJECUTADO y pruebas omitidas; separar resultados históricos de ejecuciones nuevas. No convertir issue cerrado, documentación, mock o contrato YAML en evidencia de E2E/despliegue.

## 5. Reporte de salida

Respetar el formato obligatorio de AGENTS.md del destino e incluir:

- Issue, rama y versión de cada repositorio consultado.
- Archivos cambiados y relación con los criterios de aceptación.
- Qué aportó la IA y qué decidió o ajustó la persona.
- Pruebas y evidencias efectivas; estado de integración y aprobación humana por separado.
- Pendientes con operación afectada, owner y condición concreta de cierre.

Volver al [índice](README.md).
