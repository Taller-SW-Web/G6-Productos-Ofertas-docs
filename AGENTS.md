# Instrucciones para agentes de G6 Productos y Ofertas

## Orden obligatorio de lectura

1. Leer este archivo y `README.md`.
2. Identificar el alcance y leer las `SPEC`, `HU` y `FLOW` pertinentes.
3. Leer `arquitectura/decisiones/REGISTRO_DEC_F.md`, `arquitectura/decisiones/MATRIZ_TRAZABILIDAD_DEC_F.md` y los ADR aplicables.
4. Leer los contratos ejecutables aplicables (`contratos/http/openapi.yaml` y/o `contratos/eventos/asyncapi.yaml`), sus guías y acuerdos de integración.
5. Leer arquitectura, modelo conceptual, persistencia y pruebas vinculadas antes de cambiar alguno de esos artefactos.

No omitas una fuente aplicable por haber encontrado una respuesta en un documento contextual.

## Jerarquía de fuentes normativas

- Las decisiones aceptadas y ADR gobiernan el propósito y las invariantes; no sustituyen el contrato ejecutable.
- `SPEC` gobierna reglas funcionales. `HU` y `FLOW` concretan necesidades, criterios y secuencias; cualquier conflicto se registra y escala.
- OpenAPI gobierna HTTP; AsyncAPI gobierna mensajes. La topología gobierna detalles físicos de mensajería.
- Catálogos, kit y alineaciones explican semántica e integración, sujetos a sus fuentes normativas.
- Arquitectura y modelo conceptual explican límites y conceptos; los modelos de datos, migraciones y validaciones describen persistencia.
- Pruebas y evidencia reproducible acreditan validación. Una fuente de nivel inferior no modifica silenciosamente una superior. La jerarquía no resuelve por sí sola una contradicción entre decisiones, requisitos o acuerdos externos.

## Ownership y coordinación

G6 es dueño de ocho bounded contexts: `taxonomy`, `catalog`, `pricing`, `price-audit`, `promotions`, `combos`, `inventory` y `bulk`. Ventas es dueño del pedido, pago y su orquestación; Retail, Marketplace, Chatbot, Despacho y Seguridad conservan sus propias responsabilidades. Integrarse no transfiere ownership ni autoriza acceso directo a datos de otro módulo. No atribuyas aceptación a G1–G5 o G7 sin evidencia formal.

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
- Cambia únicamente los archivos del alcance aprobado. No aproveches una tarea para normalizar documentos adyacentes.
- No hagas commit, push, publicación o merge salvo que la solicitud lo autorice expresamente. Nunca abras PR si se indicó que no.

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
