# SPEC-014 — Especificación: Historial de auditoría de precios

**Responsable:** Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** HU [HU-014](../hu/HU-014-historial-auditoria-precios.md) | Wireframe [WF-014](../wireframes/flows/WF-014-historial-auditoria-precios.md)

## 1. Contexto
La plataforma necesita una bitácora inmutable de cada cambio de precio confirmado para trazabilidad, control y análisis posterior.

## 2. Propósito
Registrar de forma automática quién realizó un cambio, cuándo, precio anterior/nuevo, variación, motivo, canal, lote e información de origen; permitir consulta/exportación y aplicar retención configurable.

## 3. Alcance
- Consumir `pricing.price.changed` después del commit.
- Persistir contrato completo: `id_auditoria`, `sku`, `product_id`, `tipo_precio`, `precio_anterior`, `precio_nuevo`, `variacion_porcentual`, `tipo_operacion`, `canal_origen`, `motivo_cambio`, `batch_id`, `usuario_id`, `usuario_email`, `ip_origen`, `timestamp`.
- Filtros y paginación.
- CSV hasta 100,000 filas.
- PDF hasta 500 filas.
- Retención configurable: valores iniciales MVP 24 meses en caliente y 5 años adicionales en archivo.
- Append-only.

## 4. Requisitos

### Requisito 1: Registro asíncrono
Solo mutaciones persistidas generan `pricing.price.changed`. Auditoría consume el hecho de forma desacoplada y deduplica por identidad del mensaje/evento.

### Requisito 2: Consulta/exportación
Filtros: SKU, fechas, usuario, canal y `batch_id`. Orden descendente. CSV asíncrono; PDF máximo 500.

La consulta individual por `auditId` devuelve HTTP `404` con `AUDITORIA_PRECIO_NO_ENCONTRADA` cuando el registro no existe.

La solicitud de exportación valida la cantidad de registros antes de crear el trabajo:
- CSV: máximo 100,000 filas;
- PDF: máximo 500 filas.

Si el resultado supera el máximo del formato solicitado, responde HTTP `422` con `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO` y **no crea** `export_id` ni trabajo asíncrono. El límite representa una regla funcional sobre el resultado, no tamaño del request.

### Requisito 3: Inmutabilidad
No existen operaciones funcionales de edición/borrado. `PUT`, `PATCH` y `DELETE` no forman parte de la superficie válida del recurso histórico.

### Requisito 4: Semántica de valores nulos
- `CREACION`: `precio_anterior=null`, `variacion_porcentual=null`.
- `MODIFICACION`: precios anterior/nuevo no nulos y variación calculada.
- `RETIRO_OFERTA`: `precio_nuevo=null`, `variacion_porcentual=null`.

En consulta/exportación:
- `precio_anterior=null` → `Sin precio anterior`;
- `precio_nuevo=null` por retiro → `Sin oferta`;
- variación nula → `No aplicable`.

Nunca se representa un valor inexistente como `0`.

### Requisito 5: Archivo verificable
`AUDIT_HOT_RETENTION_MONTHS` y `AUDIT_ARCHIVE_RETENTION_YEARS` son configuración administrativa. Valores iniciales MVP: 24 meses y 5 años adicionales. Antes de retirar la copia caliente se valida conteo/checksum/recuperabilidad. Fallo conserva originales.

### Requisito 6: Autorización de consulta/exportación
La autenticación y el rol humano global provienen de **Seguridad y Usuarios**. El acceso administrativo a esta capacidad requiere `GESTOR_COMERCIAL`.

Los identificadores `PRICING_AUDIT_READ` y `PRICING_AUDIT_EXPORT`, si se conservan, son **capacidades internas de Productos y Ofertas** asociadas al usuario autenticado; no se modelan como roles globales adicionales ni como scopes externos que Seguridad deba publicar.

Reglas:
- Seguridad valida identidad y publica el rol global `GESTOR_COMERCIAL`.
- Productos y Ofertas aplica la granularidad interna necesaria para lectura y exportación de auditoría.
- La UI solo muestra mensajes genéricos de acceso restringido y no expone nombres internos de capacidades.
- Consulta y exportación no modifican precios; la introspección de cambios sensibles de Pricing se trata en la funcionalidad de gestión de precios.

## 5. Requisitos no funcionales
- Consulta <800 ms de referencia.
- Captura asíncrona sin penalizar flujo de Pricing.
- DB habitual de Auditoría con INSERT/SELECT.
- Política de retención no se presenta como obligación legal universal.
- Datos sensibles como IP/email visibles únicamente a usuarios autorizados.

## 6. Fuera de alcance
Auditoría de autenticación, bitácora de catálogo, rollback de precios y edición/borrado del histórico.

## Criterio de completitud
La bitácora es append-only, representa correctamente valores nulos, exporta dentro de límites, distingue un registro inexistente mediante `AUDITORIA_PRECIO_NO_ENCONTRADA`, rechaza excesos con `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO` sin crear un trabajo y autoriza consulta/exportación bajo el rol global `GESTOR_COMERCIAL` con granularidad interna del módulo cuando corresponda.
