# Acta de aprobación interna G6 — contratos y decisiones H5

**Estado normativo:** `APPROVED_G6`
**Autoridad que decide:** líder/coordinación de G6 Productos y Ofertas, dentro de la autoridad del módulo.
**Fecha de decisión:** 22/11/2026, zona `America/Lima`.
**SHA de `master` auditado como base:** `4404b7c7d3cd9254ddc6932532ab3a9ba1a52f78`.

## Resolución

Quedan aprobadas internamente las decisiones técnicas, reglas funcionales y contratos G6 vigentes y definidos en el SHA de `master` indicado arriba, dentro de la competencia de G6. No se requiere ratificación jerárquica interna adicional para que sus responsables implementen y verifiquen trabajo compatible con esas fuentes. Esta aprobación incluye Bulk, Combos, Catalog, Promotions, Pricing, Price Audit, Inventory, Taxonomy y decisiones transversales H5 de Azure Service Bus Basic, APIM/Gateway, seguridad, integración, CI/CD y performance, en cuanto estén especificadas en los artefactos normativos de ese corte.

El registro DEC-F-001–DEC-F-015 y las decisiones internas complementarias ya adoptadas conservan su estado. Esta acta consolida la autoridad y cierra aprobaciones internas pendientes sobre decisiones existentes; no crea DEC-F, no adopta propuestas futuras no resueltas y no modifica la semántica de los contratos enumerados. La [matriz de aprobaciones y dependencias](MATRIZ-APROBACIONES-Y-DEPENDENCIAS-G6-H5.md) identifica fuentes, owners, implementación y condiciones de siguiente acción.

## Alcance documental

El corte cubre el contenido normativo versionado en el SHA base, incluidos el registro y trazabilidad DEC-F, ADR H5 y ADR de bloqueantes, contratos canónicos OpenAPI y AsyncAPI, topología Service Bus Basic, planes y matrices H5, decisiones por bounded context, SPEC aplicables, seguridad, integración, puertas CI/CD, performance y documentación de APIM/Gateway. Los acuerdos bilaterales firmados y snapshots/fixtures históricos conservan sus estados propios. Los cambios de esta rama actualizan referencias y metadatos normativos derivados, sin reescribir evidencia histórica.

Para `BULK_RETRY_V1`, la decisión aprobada es `0.7.0-rc.3: APPROVED_G6`, en consonancia con Docs #133 fusionado en el SHA base y Backend #252 (`9e4ac0af2a3ea882784413401bd5016ff611caa2`). Se conservan schemas, rutas, mensajes, identidades, reglas de idempotencia y la condición de no habilitación hasta completar las condiciones operativas.

## Responsabilidad y gobierno

Los owners de cada microservicio implementan y verifican las decisiones de su bounded context. Una revisión técnica del owner valida diseño, compatibilidad, calidad y evidencia; no es una aprobación jerárquica pendiente del líder G6. Las dependencias externas conservan el owner y mecanismo de aceptación que les corresponden.

La aprobación normativa no constituye implementación, prueba, homologación externa, concesión de grants, aprovisionamiento, habilitación, despliegue ni autorización de release. La activación operativa requiere implementación compatible, pruebas reproducibles, seguridad y permisos efectivos, infraestructura disponible y autorización de release aplicable.

Todo cambio posterior que modifique semántica contractual debe versionarse y pasar nuevamente por la autoridad G6. Esta acta no aprueba diseños futuros todavía inexistentes, alternativas nuevas, cambios incompatibles no especificados ni ampliaciones de alcance.

## Estados que permanecen separados

- `APPROVED_G6`: aprobación contractual o de decisión dentro de la autoridad G6.
- `PENDIENTE_HOMOLOGACION_EXTERNA`: falta aceptación verificable del otro equipo cuando aplique.
- `PENDIENTE_GRANT_G7`: falta comprobar o conceder permisos efectivos por G7.
- `PENDIENTE_INFRAESTRUCTURA`: falta aprovisionamiento o configuración operativa.
- `PENDIENTE_IMPLEMENTACION`, `PENDIENTE_INTEGRACION`, `PENDIENTE_PRUEBAS`, `PENDIENTE_DESPLIEGUE` y `PENDIENTE_EVIDENCIA`: trabajo o verificación aún no acreditados.

Ninguno de esos estados externos u operativos se convierte en `PASS` por esta acta.
