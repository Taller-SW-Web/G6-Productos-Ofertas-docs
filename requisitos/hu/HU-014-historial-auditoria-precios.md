# HU-014 — Historia de Usuario: Historial de auditoría de precios

**Responsable:** Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** Spec [SPEC-014](../specs/SPEC-014-historial-auditoria-precios.md) | Flow [WF-014](..\..\ux\wireframes\flows\WF-014-historial-auditoria-precios.md)

**Como** gestor comercial autorizado para auditoría de precios, **quiero** consultar y exportar una bitácora inmutable, **para** contar con trazabilidad de cambios confirmados.

## Criterios
| ID | Criterio |
|---|---|
| CA-01 | Consume `pricing.price.changed` después del commit. |
| CA-02 | Persiste contrato completo de auditoría. |
| CA-03 | Operaciones fallidas no generan asiento. |
| CA-04 | Append-only, sin edición/borrado. |
| CA-05 | Filtros por SKU, fechas, usuario, canal y lote. |
| CA-06 | Paginado y sin resultados distinguido de error. |
| CA-07 | CSV <=100,000 y PDF <=500; si el resultado excede el límite, la solicitud devuelve `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO` y no crea exportación. |
| CA-08 | La auditoría se autoriza sobre el actor global `GESTOR_COMERCIAL`; cualquier granularidad adicional se resuelve mediante capacidades internas del módulo y no crea un rol humano global adicional. |
| CA-09 | Retención configurable; 24 meses + 5 años son valores iniciales MVP. |
| CA-10 | `CREACION` muestra anterior/variación nulos; `RETIRO_OFERTA` muestra nuevo/variación nulos. |
| CA-11 | Un mensaje repetido con el mismo `message_id` no produce un asiento adicional; la deduplicación del consumidor usa `message_id`. |
| CA-12 | Archivado verifica integridad antes de retirar copia caliente. |
| CA-13 | Consultar un `auditId` inexistente devuelve `AUDITORIA_PRECIO_NO_ENCONTRADA`; no se confunde con listado vacío. |

## Escenarios
1. Modificación normal → anterior/nuevo/variación.
2. Cambio rechazado → sin registro.
3. Lote → asiento por SKU con `batch_id`.
4. CSV → generación asíncrona.
5. PDF >500 → bloquear, no crear `export_id`, devolver `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO` y sugerir CSV/acotar filtros.
6. `CREACION` → “Sin precio anterior” / “No aplicable”.
7. `RETIRO_OFERTA` → precio nuevo “Sin oferta” / variación “No aplicable”.
8. Archivado fallido → conservar registros calientes.
9. Detalle inexistente → estado no encontrado asociado a `AUDITORIA_PRECIO_NO_ENCONTRADA`.

## Seguridad
El usuario humano debe estar autenticado como `GESTOR_COMERCIAL`. Si se requiere granularidad adicional para consulta o exportación, se aplican capacidades internas asociadas a su `sub`; no se introduce un rol global `AUDITOR_COMERCIAL` ni equivalente.
