# Cobertura contractual MK-001 a MK-016 (H5)

Baseline auditada: `master` Docs `8355815eec26825edf7f5adac85b98638551b86e`, OpenAPI/AsyncAPI `0.7.0-rc.1`. El snapshot de controllers de Backend y los PR abiertos se consultaron en lectura; la existencia de contrato no acredita implementación o habilitación. La rama de este PR agrega 5 operaciones HTTP: 3 rutas administrativas Inventory ya implementadas según la fuente de tarea y 2 fronteras M2M pendientes.

| MK | Servicio / owner | Cobertura contractual y consumidor | Estado y trabajo requerido |
|---|---|---|---|
| MK-001 | Bulk / Castilla | Plantilla, importación, estado, reporte, reanudación, exportación y claim-check privado existentes; Catalog consume preparación. | `CONTRATO_EXISTENTE`; R02 queda tipado y `PENDIENTE_IMPLEMENTACION`; no duplicar claim-check de #243. R03 reservado para SPEC-001. |
| MK-002 | Combos / Castilla | CRUD y disponibilidad existentes; canales consultan disponibilidad. | `CONTRATO_EXISTENTE`; revisar implementación según controller y pruebas vigentes, sin añadir checkout. |
| MK-003 | Catalog / Poma | Administración, ciclo de vida, filtros y contexto SKU existentes. | `CONTRATO_EXISTENTE`; batch de SKU existente no resuelve población por producto/categoría/marca. |
| MK-004 | Catalog / Poma | Variantes, preparación diferida y ciclo de SKU cubiertos. | `CONTRATO_EXISTENTE`; conservar política de SKU simple y no crear REST de mensajería. |
| MK-005 | Promotions / Cueva | CRUD/validación de cupones y operaciones H5 existentes. | `CONTRATO_EXISTENTE`; G5 sigue `PENDIENTE_HOMOLOGACION_EXTERNA`, G7 `PENDIENTE_VERIFICACION`. |
| MK-006 | Promotions / Cueva | CRUD y evaluación de promociones existentes. | `CONTRATO_EXISTENTE`; lectura/evaluación no autoriza consumo. |
| MK-007 | Promotions / Cueva | Recomendaciones existentes; evaluación separada de mutaciones. | `CONTRATO_EXISTENTE`; no se añade evento por consultas. |
| MK-008 | Taxonomy / López | Categorías y baja asíncrona con consulta de operación existente. | `CONTRATO_EXISTENTE`; 202 no significa completado. |
| MK-009 | Taxonomy / López | Características y valores existentes. | `CONTRATO_EXISTENTE`; preservar nulls y correlación. |
| MK-010 | Taxonomy / López | Tipos y asociaciones existentes. | `CONTRATO_EXISTENTE`; mantener estado de operación y errores terminales. |
| MK-011 | Taxonomy / López | Marcas y baja asíncrona existentes. | `CONTRATO_EXISTENTE`; no crear mecanismo nuevo. |
| MK-012 | Taxonomy / López | SEO/metadatos existentes. | `CONTRATO_EXISTENTE`; sin endpoint adicional identificado. |
| MK-013 | Pricing / Vera | Precio, programación, prevalidación e importación HTTP existentes. | `CONTRATO_EXISTENTE`; #233 se mantiene como única vía de importación masiva de precios. |
| MK-014 | Price Audit / Vera | Historial, detalle y exportación append-only existentes. | `CONTRATO_EXISTENTE`; no añadir asientos ni comandos. |
| MK-015 | Inventory / Taco | Disponibilidad, reservas, incidencias, reintegros, traslados y umbrales existentes; agrega saldos de administración. | `CONTRATO_EXISTENTE` + `listarSaldosFisicosAdministracion`; GET de estado de reserva conserva allowlist `modulo-ventas`. |
| MK-016 | Inventory / Taco | Dashboard solo acepta `sku` y `locationId`; agrega alertas y ubicaciones administrativas. | Alertas/ubicaciones `CONTRATO_PROPUESTO`, backend `PENDIENTE_ENDPOINT_HTTP`. Filtros Catalog ampliados pendientes de adaptador. |

## Anexo de compatibilidad R01–R18 / N01

| ID | Compatibilidad y estado |
|---|---|
| R01 | Se conserva el flujo Catalog → Inventory de inicialización de SKU; estado runtime debe verificarse por SHA. |
| R02 | `inventory.bulk.stock.adjust.requested` pasa a schema tipado de ajuste absoluto inicial, `SEMIFINAL_G6`; runtime pendiente de handler durable, ubicación real, Inbox/Outbox y pruebas. |
| R03 / R14 | `pricing.bulk.price.apply.*` queda `RESERVADO_NO_APLICA_BULK_V2`; precio regular solo en ALTA por inicialización Catalog → Pricing; cambios masivos siguen el importador HTTP Pricing. |
| R04–R09 | Se preservan contratos y ownership existentes; no se habilita ningún flujo por existir en YAML. |
| R10 | Resultados R02 tipados completed/rejected. `inventory.stock.adjusted` permanece con semántica previa y no se duplica `inventory.stock.changed`. |
| R11–R18 | Se preservan identificadores/canales existentes sin cambiar runtime, producer/consumer o transporte. |
| N01 | Se conserva mensaje y envelope actual; `causation_id` continúa opcional donde ya es opcional. |

### Discrepancias y evidencia pendiente

* Inventory #248 describe helpers internos de alertas/ubicaciones, no endpoints HTTP; frontend #90 permanece bloqueado hasta handler, Gateway, grant G7 y prueba.
* El runtime #248 trata paginación/`soloActivas=false` y `available=NULL` con diferencias frente al contrato aquí fijado. Corregir y probar el servicio antes de activar clientes.
* Filtros `productoId`, `categoriaId` y `marcaId` del dashboard se retiran de la operación actual; el código vigente devuelve 400 a filtros no reconocidos. La etapa futura depende de `POST /interno/productos/skus/filtrar`.

Rutas en OpenAPI son relativas a `/api/v1`. Identidad de evidencia: baseline de contrato arriba; revalidar SHA exacto de Backend/Frontend y de este PR antes de declarar estados probados.
