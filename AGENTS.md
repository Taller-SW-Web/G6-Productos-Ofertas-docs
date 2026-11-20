# Instrucciones para agentes de G6 Productos y Ofertas

## Objetivo vigente — Hito 5

> CI/CD incluyendo revision Seguridad — Evidencia de Pruebas de integración — Evidencia de Pruebas de performance — Uso de API Management y Mecanismo asincrónico entre Microservicios

Los cuatro criterios y sus evidencias se registran en [hitos/HITO_5.md](hitos/HITO_5.md). H4 es el hito anterior y su AsyncAPI se conserva en `contratos/historico/h4/`; los contratos canónicos H5 son `contratos/http/openapi.yaml` y `contratos/eventos/asyncapi.yaml` (`0.7.0-rc.2`, `SEMIFINAL_G6`). Mantén la norma vigente de Azure Service Bus Basic y no infieras implementación, homologación o despliegue desde la documentación.

Para tareas de mensajería H5, la matriz de implementación Service Bus es la fuente única del seguimiento por flujo: [MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md](integraciones/MATRIZ-IMPLEMENTACION-SERVICE-BUS-H5.md). Léela junto con la ADR, topología y plan H5 indicados abajo.

## Norma de mensajería H5 (obligatoria)

La arquitectura objetivo adoptada por G6 para Hito 5 es **Azure Service Bus Basic exclusivamente para mensajería interna entre bounded contexts G6**. Las integraciones externas usan HTTP autenticado a través de APIM/Gateway G6; contratos, homologación G5 y autorización G7 se verifican por separado. La adopción no demuestra recursos Azure aprovisionados, identidades/grants, implementación, pruebas runtime ni despliegue. Estados vigentes: `ADOPTADA_G6`, `PENDIENTE_APROVISIONAMIENTO_AZURE`, `PENDIENTE_IMPLEMENTACION`, `PENDIENTE_HOMOLOGACION_G5` y `PENDIENTE_AUTORIZACION_G7`. Un colaborador asumió la configuración de recursos Azure; esta asignación no es evidencia de provisión.

RabbitMQ es arquitectura heredada H4, preservada en [`contratos/historico/h4/eventos/asyncapi.yaml`](contratos/historico/h4/eventos/asyncapi.yaml). El AsyncAPI canónico [`contratos/eventos/asyncapi.yaml`](contratos/eventos/asyncapi.yaml) es la baseline semifinal H5 `0.7.0-rc.2` (`SEMIFINAL_G6`), pendiente de homologación externa donde aplique; no acredita implementación ni recursos. Service Bus Basic aplica solo a mensajería interna G6; consumidores externos usan HTTP autenticado.

La matriz de ajustes de implementación Backend se mantiene en [`COMPATIBILIDAD-BACKEND-CONTRATOS-H5.md`](integraciones/COMPATIBILIDAD-BACKEND-CONTRATOS-H5.md); sus registros son incompatibilidades a corregir, no correcciones ya aplicadas.

### Orden de lectura para mensajería H5

1. Este archivo y [`README.md`](README.md).
2. [`ADR-H5-SERVICE-BUS-BASIC.md`](arquitectura/decisiones/ADR-H5-SERVICE-BUS-BASIC.md) y [`TOPOLOGIA-SERVICE-BUS-BASIC-H5.md`](contratos/eventos/TOPOLOGIA-SERVICE-BUS-BASIC-H5.md).
3. [`PLAN-MIGRACION-MENSAJERIA-H5.md`](integraciones/PLAN-MIGRACION-MENSAJERIA-H5.md), [`MATRIZ-EXTERNOS-ASYNCAPI-H5.md`](integraciones/MATRIZ-EXTERNOS-ASYNCAPI-H5.md) y [`INVENTARIO-40-MENSAJES-H5.md`](contratos/eventos/INVENTARIO-40-MENSAJES-H5.md).
4. Use el AsyncAPI H4 histórico solo como fuente de semántica y regresión; `servers`, bindings y topología RabbitMQ no definen el transporte H5.
5. SPEC/HU/FLOW y contratos HTTP aplicables; revisar homologación externa y seguridad antes de alterar fronteras.

## Orden obligatorio de lectura

1. Leer este archivo y `README.md`.
2. Identificar el alcance y leer las `SPEC`, `HU` y `FLOW` pertinentes.
3. Leer `arquitectura/decisiones/REGISTRO_DEC_F.md`, `arquitectura/decisiones/MATRIZ_TRAZABILIDAD_DEC_F.md` y los ADR aplicables.
4. Leer los contratos ejecutables aplicables (`contratos/http/openapi.yaml` y/o `contratos/eventos/asyncapi.yaml`), sus guías y acuerdos de integración.
5. Leer arquitectura, modelo conceptual, persistencia y pruebas vinculadas antes de cambiar alguno de esos artefactos.

No omitas una fuente aplicable por haber encontrado una respuesta en un documento contextual.

## Colaboración y gestión de ramas

Las ramas personales permanentes son `castilla`, `poma`, `cueva`, `lopez`, `vera` y `taco`. Son el espacio preferente de cada integrante, pueden usarse para PRs sucesivos a `master` y nunca se eliminan como parte de la limpieza ordinaria. Antes de iniciar otro trabajo en una rama personal, sincronízala de forma segura con `master`; mantén cada PR cohesivo y no acumules cambios independientes destinados a PRs distintos.

La convención obligatoria para ramas nuevas es `trabajo/<desarrollador>/<descripcion-en-kebab-case>`, por ejemplo `trabajo/poma/correccion-azure-service-bus` o `trabajo/cueva/corregir-inventario`. Cualquier desarrollador puede crear múltiples ramas temporales sin Issue asignado. Parte de `master` actualizado salvo dependencia explícita y documentada. Cada rama debe tener un propósito identificable y cada trabajo independiente su propio PR, preferentemente dirigido a `master`. Se permite `git worktree`. No uses prefijos de herramientas o agentes (`codex/`, `claude/`, `gemini/`, `antigravity/`) ni renombres ramas históricas o alteres PRs existentes automáticamente.

Todo desarrollador puede resolver Issues asignados a otra persona o sin asignar, ayudar a un compañero o iniciar una contribución documentada sin Issue previo. Si no existe Issue, registra en el PR su objetivo, motivación, alcance, criterios de aceptación, pruebas e impactos posibles. Antes de un cambio que pueda solaparse, revisa Issues y PRs existentes y comunica la intervención cuando corresponda.

G6 y los módulos externos mantienen sus bounded contexts y responsabilidades. La coordinación y experiencia técnica identifican puntos de contacto; no establecen permisos exclusivos para editar documentación o proponer cambios. Cualquier colaborador puede preparar y presentar un PR. Esa autorización para trabajar no autoriza aprobar decisiones normativas, modificar unilateralmente contratos o decisiones arquitectónicas aceptadas, conceder permisos de seguridad, atribuir aceptación externa, fusionar cambios ni publicar contratos definitivos. Se mantienen las revisiones, aprobaciones y homologaciones aplicables, proporcionales al impacto.

No sobrescribas trabajo de otras personas ni realices `git push --force`, `git reset --hard`, ni merges destructivos. Para una tarea encargada o documentada se permiten ramas, worktrees, commits, `git push` ordinario y apertura de PRs, sujetos a CI y protecciones del repositorio. Abrir una rama o PR no constituye autorización para fusionar o publicar. Tras fusionar un PR temporal, confirma que el merge terminó y que la rama no se necesita para otro PR o trabajo dependiente; elimina la rama temporal local y remota cuando corresponda. Las temporales abandonadas se pueden eliminar tras comprobar que no tienen cambios pendientes por conservar. Nunca elimines ramas personales permanentes mediante este procedimiento ni habilites eliminación automática indiscriminada que las afecte.

## Jerarquía de fuentes normativas

- Las decisiones aceptadas y ADR gobiernan el propósito y las invariantes; no sustituyen el contrato ejecutable.
- `SPEC` gobierna reglas funcionales. `HU` y `FLOW` concretan necesidades, criterios y secuencias; cualquier conflicto se registra y escala.
- OpenAPI gobierna HTTP; AsyncAPI gobierna mensajes. La topología gobierna detalles físicos de mensajería.
- Catálogos, kit y alineaciones explican semántica e integración, sujetos a sus fuentes normativas.
- Arquitectura y modelo conceptual explican límites y conceptos; los modelos de datos, migraciones y validaciones describen persistencia.
- Pruebas y evidencia reproducible acreditan validación. Una fuente de nivel inferior no modifica silenciosamente una superior. La jerarquía no resuelve por sí sola una contradicción entre decisiones, requisitos o acuerdos externos.

## Ownership y coordinación

G6 es responsable de ocho bounded contexts: `taxonomy`, `catalog`, `pricing`, `price-audit`, `promotions`, `combos`, `inventory` y `bulk`. Ventas responde por pedido, pago y su orquestación; Retail, Marketplace, Chatbot, Despacho y Seguridad conservan sus propias responsabilidades. Estas responsabilidades indican conocimiento y contacto primarios, no restringen quién puede colaborar en un PR. Integrarse no transfiere ownership ni autoriza acceso directo a datos de otro módulo. No atribuyas aceptación a G1–G5 o G7 sin evidencia formal.

## Estados que no deben confundirse

- **Propuesto:** alternativa bajo evaluación; no es regla aceptada.
- **Adoptado:** decisión interna aceptada; no prueba aceptación externa.
- **Homologado:** acuerdo registrado con los módulos externos concernidos.
- **Implementado:** existe implementación identificable; documentación o YAML no bastan.
- **Probado:** hay resultado reproducible asociado a versión/commit y alcance; no equivale automáticamente a E2E ni despliegue.

Registra por separado el estado interno, externo y de implementación. No declares contratos implementados, homologados, desplegados o probados solo porque estén documentados.

## Implementación backend y desbloqueo selectivo

Las DEC-F-001 a DEC-F-015 adoptadas internamente se implementan en los bounded contexts de G6 cuando definen lógica e invariantes propias. La falta de homologación externa no impide desarrollar, probar o publicar esa lógica dentro del alcance autorizado; sí impide cambiar unilateralmente interfaces compartidas incompatibles, atribuir responsabilidades externas o conceder permisos de Seguridad.

Clasifica cada trabajo con uno de estos estados operativos:

- **IMPLEMENTAR_AHORA:** trabajo autónomo de G6 respaldado por decisiones y contratos aplicables; puede desarrollarse, probarse y publicarse en el alcance autorizado.
- **IMPLEMENTAR_PARCIAL:** implementar invariantes, reglas, persistencia y pruebas internas ya definidas, manteniendo aislada la frontera de integración pendiente.
- **BLOQUEADO_ESPECÍFICO:** bloquear solo la operación, contrato, autorización o secuencia dependiente de una decisión externa. Registrar qué falta, quién debe responder y el criterio concreto de desbloqueo.

Una discrepancia externa no bloquea automáticamente un microservicio completo. G6 comunica a los módulos afectados los cambios previstos, regla aplicable, impacto contractual, versión y adaptación requerida; solicita homologación si hay impacto en contratos compartidos, responsabilidad externa o comportamiento del consumidor. Esa comunicación no es una autorización para lógica interna propia. No publicar como definitivo un cambio incompatible aún no acordado ni atribuir aceptación por silencio.

## Límites de cambio

- No inventes contratos, acuerdos, rutas, scopes, campos, políticas ni decisiones. DEC-F-001 a DEC-F-015 son las decisiones internas aprobadas que constan en el registro. No crees DEC-F-016 ni posteriores sin aprobación expresa de Marco. No amplíes mediante inferencias el contenido de una decisión aprobada. Toda adopción posterior exige actualizar registro, trazabilidad e integraciones afectadas.
- No reescribas migraciones aplicadas ni sus checksums. SQL de escritura en Supabase requiere autorización expresa de Marco, alcance definido y proceso de despliegue aprobado; sin esos requisitos no se ejecuta.
- Limita cada PR a su objetivo cohesivo y cambia solo los artefactos necesarios; no incluyas normalizaciones independientes por conveniencia.
- Para una tarea encargada o documentada se permiten commits, `git push` ordinario y PRs. Nunca uses force push ni operaciones destructivas. Aprobar decisiones normativas, fusionar y publicar requieren las revisiones y autorización aplicables; abrir un PR no las concede.

## Validaciones mínimas antes del commit

1. Confirmar que el diff contiene solo archivos permitidos y revisar el diff completo.
2. Validar enlaces relativos nuevos y que las referencias citadas existan.
3. Ejecutar `git diff --check` y las validaciones específicas autorizadas por la tarea.
4. Confirmar que migraciones, contratos ejecutables y pruebas no cambiaron cuando estén fuera de alcance.
5. Informar las validaciones realizadas y sus límites; no convertir una validación documental en evidencia de runtime.

## Contradicciones no previstas

Detén el cambio que dependa de la contradicción. Conserva ambas referencias, registra qué afirma cada fuente y su estado, determina a quién corresponde resolverla y solicita aclaración al owner competente. No elijas una regla por intuición ni la presentes como homologada. Puedes continuar tareas independientes que no dependan de ella.

## Integración G1 Marketplace H4 — lectura obligatoria

Antes de implementar una integración G1, leer [`integraciones/ACUERDO_G1_G6_H4_2026-10-20.md`](integraciones/ACUERDO_G1_G6_H4_2026-10-20.md), [`integraciones/ALINEACION_MARKETPLACE.md`](integraciones/ALINEACION_MARKETPLACE.md), `contratos/http/openapi.yaml` y [`kit-integracion.md`](contratos/http/kit-integracion.md). Para ejecución Backend, también leer el [paquete operativo obligatorio](https://github.com/Taller-SW-Web/G6-Productos-Ofertas-backend/tree/castilla/integraciones/g1-marketplace). Acuerdo/guía no reemplazan SPEC, DEC-F/ADR ni contrato ejecutable.

La aceptación G6 del 2026-10-20 está documentada en el [Acuerdo G1–G6 H4](integraciones/ACUERDO_G1_G6_H4_2026-10-20.md); debe leerse antes de editar integración Marketplace, junto con el OpenAPI y la guía Backend. No utilices documentos históricos de preparación para afirmar aceptación pendiente, ni atribuyas ratificación G1 o grant G7 no acreditados.


## Flujo de CI para PR: Draft → Ready

- Abre los PR en Draft y mantenlos así durante la implementación, las pruebas focalizadas y las correcciones. Al completar la implementación, comunica el enlace del PR, el HEAD SHA, el resumen de cambios y las pruebas realizadas para dejarlo disponible para revisión.
- Mientras haya observaciones obligatorias del auditor, el PR permanece en Draft. Corrige en el mismo PR, publica los cambios y comunica que están listos para nueva revisión. Repite hasta que no queden observaciones bloqueantes. Las recomendaciones opcionales o clasificadas expresamente como no bloqueantes no impiden avanzar.
- Terminar el desarrollo o superar pruebas locales no equivale a aprobar la implementación propia. Solo pasa el PR a Ready for Review cuando se haya comunicado que la revisión terminó satisfactoriamente y exista autorización para continuar. No se exige formato, documento ni registro adicional para comunicar observaciones o autorización.
- Si después de una revisión favorable haces una corrección sustancial, comunícala antes de avanzar para determinar si requiere otra revisión. No repitas auditorías completas por cambios menores que no alteren los aspectos técnicos evaluados, salvo indicación expresa.
- No ejecutes suites locales completas de manera rutinaria; usa pruebas focalizadas para depurar. Las validaciones integrales se ejecutan en GitHub Actions al pasar el PR a Ready for Review. El PR no se considera validado hasta que todos los checks obligatorios pasen para la revisión actual.
- Si CI requiere cambios de código, vuelve a Draft durante las correcciones y solicita nueva revisión cuando corresponda. Cada commit en Ready invalida la validación anterior y genera una nueva ejecución; volver a Draft difiere nuevas suites pesadas. Toda evidencia debe corresponder al código y SHA probados.
- Una revisión técnica favorable no autoriza el merge. El merge requiere checks obligatorios satisfactorios, cumplimiento de las protecciones de GitHub y la autorización correspondiente. No se hace merge con checks pendientes o fallidos. Marcar un PR Ready no autoriza despliegues de producción.
