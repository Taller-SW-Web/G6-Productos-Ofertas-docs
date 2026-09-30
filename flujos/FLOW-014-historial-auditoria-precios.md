# FLOW-014 — Historial de auditoría de precios

## 1. Identificación

- **Código:** FLOW-014
- **Funcionalidad:** Historial de auditoría de precios
- **Relacionado con:** [HU-014](../hu/HU-014-historial-auditoria-precios.md) / [SPEC-014](../specs/SPEC-014-historial-auditoria-precios.md) / [WF-014](../wireframes/flows/WF-014-historial-auditoria-precios.md)
- **Responsable:** Leonardo Vera Rodríguez
- **Última actualización:** 2026-09-29

---

## 2. Objetivo del flujo

Representar la captura asíncrona desacoplada de eventos de cambio de precios mediante una bitácora inmutable (*Append-Only*), la consulta cronológica descendente con filtrado multicriterio, la visualización del contrato completo de auditoría, la exportación controlada en formatos CSV (hasta 100.000 filas) y PDF (hasta 500 filas con rechazo explícito por exceso) y el ciclo de vida de archivado verificado a almacenamiento en frío en formato Parquet según los parámetros configurables de retención.

---

## 3. Actores participantes

- **Auditor comercial / Gestor:** consulta registros cronológicos, aplica filtros combinables, visualiza detalles completos y solicita exportaciones en CSV o PDF.
- **Sistema de Pricing (Emisor):** procesa mutaciones operativas de precios y publica el evento desacoplado `pricing.price.changed` solo tras confirmar transacciones exitosas (las operaciones fallidas no emiten eventos).
- **Servicio de auditoría de precios:** consume eventos asíncronos del broker, deduplica por `event_id`, valida inmutabilidad estricta y expone endpoints de consulta y exportación.
- **Almacén de auditoría (Base operativa / Almacenamiento caliente):** base relacional configurada exclusivamente con permisos `INSERT` y `SELECT`, que retiene las mutaciones durante el período caliente configurado (`AUDIT_HOT_RETENTION_MONTHS`, MVP 24 meses).
- **Worker de archivado y Almacenamiento en frío:** tarea batch mensual que genera particiones Parquet, valida checksum y recuperabilidad antes del retiro, y conserva los datos en frío durante `AUDIT_ARCHIVE_RETENTION_YEARS` (MVP 5 años).

> **Autorización:** La consulta y exportación requieren acceso autorizado. `PRICING_AUDIT_READ` y `PRICING_AUDIT_EXPORT` son identificadores propuestos, pendientes de homologación con Seguridad y Usuarios; no se presentan como permisos oficiales.

---

## 4. Diagramas de flujo

### 4.1 Ingesta asíncrona de eventos y garantía de inmutabilidad (Append-Only)

```mermaid
flowchart LR

    subgraph PRICING["Sistema de Pricing (Emisor)"]
        direction TB
        INICIO_PRICING((Mutación de precio persistida))
        P1["Confirmar commit transaccional local"]
        P2["Construir payload con contrato de auditoría"]
        E1(("Publicar pricing.price.changed vía Outbox"))
    end

    subgraph AUDIT_SVC["Servicio de Auditoría"]
        direction TB
        E2(("Consumir evento pricing.price.changed"))
        A1["Verificar unicidad de event_id"]
        D1{"¿event_id ya fue procesado?"}
        A2["Descartar evento duplicado sin reinsertar"]
        A3["Clasificar según tipo_operacion"]
        D2{"¿Qué tipo de operación se audita?"}
        A4["Registrar CREACION con precio_anterior y variación nulos"]
        A5["Registrar RETIRO_OFERTA con precio_nuevo y variación nulos"]
        A6["Registrar MODIFICACION con precios y variación calculada"]
        A7["Mapear contexto: usuario, IP, motivo, canal y batch_id"]
        INICIO_MUTACION((Petición directa PUT/PATCH/DELETE))
        A8["Interceptar intento de mutación directa vía API"]
        A9["Denegar operación con HTTP 405 Method Not Allowed"]
    end

    subgraph DB_AUDIT["Almacén de Auditoría (Append-Only)"]
        direction TB
        D3["Ejecutar INSERT con credenciales de solo inserción"]
    end

    FIN_AUDIT_OK(((Registro persistido inmutablemente)))
    FIN_DUPLICADO(((Evento omitido por idempotencia)))
    FIN_BLOQUEO(((Mutación directa denegada)))

    INICIO_PRICING --> P1
    P1 --> P2
    P2 --> E1
    E1 --> E2
    E2 --> A1
    A1 --> D1
    D1 -->|"Sí"| A2
    A2 --> FIN_DUPLICADO
    D1 -->|"No"| A3
    A3 --> D2

    D2 -->|"CREACION"| A4
    D2 -->|"RETIRO_OFERTA"| A5
    D2 -->|"MODIFICACION"| A6

    A4 --> A7
    A5 --> A7
    A6 --> A7
    A7 --> D3
    D3 --> FIN_AUDIT_OK

    INICIO_MUTACION --> A8
    A8 --> A9
    A9 --> FIN_BLOQUEO
```

> **Aclaración operativa:** Si una actualización de precio es rechazada en Pricing por reglas de negocio, falta de motivo obligatorio o conflicto de concurrencia, Pricing no persiste la entidad ni emite el evento, por lo que la bitácora no genera ningún registro de operaciones no ocurridas.

---

### 4.2 Consulta cronológica, filtrado multicriterio y detalle de registro

```mermaid
flowchart LR

    subgraph AUDITOR["Auditor comercial / Gestor"]
        direction TB
        INICIO((Acceso a auditoría de precios))
        INICIO_DETALLE((Solicitud de detalle por auditId))
        U1["Consultar vista inicial paginada"]
        U2["Ingresar filtros: SKU, fechas, usuario, canal, batch_id"]
        U3["Ejecutar búsqueda"]
        U4["Revisar tabla ordenada descendentemente por timestamp"]
        U5["Solicitar detalle por auditId desde fila o enlace"]
        U6["Visualizar modal de detalle y cerrar"]
        U7["Visualizar aviso 'Sin resultados' y ajustar filtros"]
        U8["Corregir filtros inválidos"]
        U9["Visualizar detalle no encontrado"]
    end

    subgraph AUDIT_SVC["Servicio de Auditoría"]
        direction TB
        S1["Cargar registros recientes con respuesta < 800 ms"]
        S2["Validar coherencia de fechas: fecha_desde <= fecha_hasta"]
        D1{"¿Rango de fechas válido?"}
        S3["Mostrar error de validación de filtros"]
        S4["Ejecutar consulta paginada en almacén operativo"]
        D2{"¿Se encontraron registros coincidentes?"}
        S5["Retornar HTTP 200 con lista de registros y total"]
        S6["Retornar HTTP 200 con arreglo vacío y mensaje de CA-06"]
        S7["Consultar detalle por auditId"]
        D3{"¿Existe el registro solicitado?"}
        S8["Retornar HTTP 200 con contrato íntegro: id_auditoria, product_id, IP e historial"]
        S9["Retornar HTTP 404: AUDITORIA_PRECIO_NO_ENCONTRADA"]
    end

    FIN_CONSULTA_OK(((Historial consultado con resultados)))
    FIN_SIN_RESULTADOS(((Consulta sin registros coincidentes)))
    FIN_DETALLE(((Detalle de registro inspeccionado)))
    FIN_DETALLE_NO_ENCONTRADO(((Detalle inexistente)))
    FIN_FILTRO_ERROR(((Filtro corregido por el usuario)))

    INICIO --> U1
    U1 --> S1
    S1 --> U4
    U4 --> U2
    U2 --> U3
    U3 --> S2
    S2 --> D1
    D1 -->|"No"| S3
    S3 --> U8
    U8 --> FIN_FILTRO_ERROR

    D1 -->|"Sí"| S4
    S4 --> D2
    D2 -->|"Sí"| S5
    S5 --> U4
    U4 --> FIN_CONSULTA_OK

    D2 -->|"No"| S6
    S6 --> U7
    U7 --> FIN_SIN_RESULTADOS

    U4 --> U5
    INICIO_DETALLE --> U5
    U5 --> S7
    S7 --> D3
    D3 -->|"Sí"| S8
    S8 --> U6
    U6 --> FIN_DETALLE
    D3 -->|"No"| S9
    S9 --> U9
    U9 --> FIN_DETALLE_NO_ENCONTRADO
```

> **Representación de valores nulos en consulta y exportación:** En `CREACION`, `precio_anterior=null` se muestra como “Sin precio anterior” y `variacion_porcentual=null` como “No aplicable”. En `RETIRO_OFERTA`, `precio_nuevo=null` se muestra como “Sin oferta” y la variación nula como “No aplicable”. Ningún valor inexistente se muestra como `0`.

---

### 4.3 Exportación estructurada de auditoría (CSV y PDF con control de límites)

```mermaid
flowchart LR

    subgraph AUDITOR["Auditor comercial / Gestor"]
        direction TB
        INICIO((Solicitud de exportación))
        D1{"¿Qué formato de exportación solicita?"}
        G1["Seleccionar Exportar a CSV"]
        G2["Seleccionar Exportar a PDF"]
        G3["Revisar alcance de registros filtrados"]
        D2{"¿Confirma exportación CSV?"}
        G4["Cancelar exportación"]
        G5["Descargar archivo CSV generado"]
        G6["Visualizar rechazo y acotar filtros o cambiar a CSV"]
        G7["Descargar documento PDF generado"]
        G8["Visualizar rechazo y acotar filtros para CSV"]
    end

    subgraph AUDIT_SVC["Servicio de Auditoría"]
        direction TB
        S1["Contar registros filtrados para CSV antes de crear exportación"]
        D3{"¿Registros filtrados <= 100.000?"}
        S2["Crear export_id e iniciar trabajo asíncrono de CSV"]
        E1(("Generación CSV completada"))
        S3["Publicar enlace seguro de descarga del CSV"]
        S4["Contar registros filtrados para PDF antes de crear exportación"]
        D4{"¿Registros filtrados <= 500?"}
        S5["Rechazar HTTP 422: LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO; sin export_id ni trabajo"]
        S6["Crear export_id y generar PDF con membrete y marcas auditadas"]
        E2(("Generación PDF completada"))
        S7["Publicar enlace de descarga del PDF ejecutivo"]
        S8["Rechazar HTTP 422: LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO; sin export_id ni trabajo"]
    end

    FIN_CANCELADO(((Exportación cancelada por usuario)))
    FIN_CSV_OK(((Archivo CSV descargado exitosamente)))
    FIN_CSV_BLOQUEADO(((Exportación CSV bloqueada por límite)))
    FIN_PDF_OK(((Reporte ejecutivo PDF descargado)))
    FIN_PDF_BLOQUEADO(((Exportación PDF bloqueada por límite)))

    INICIO --> D1
    D1 -->|"CSV"| G1
    G1 --> G3
    G3 --> D2
    D2 -->|"No"| G4
    G4 --> FIN_CANCELADO
    D2 -->|"Sí"| S1
    S1 --> D3
    D3 -->|"> 100.000 filas"| S8
    S8 --> G8
    G8 --> FIN_CSV_BLOQUEADO
    D3 -->|"<= 100.000 filas"| S2
    S2 --> E1
    E1 --> S3
    S3 --> G5
    G5 --> FIN_CSV_OK

    D1 -->|"PDF"| G2
    G2 --> S4
    S4 --> D4
    D4 -->|"> 500 filas"| S5
    S5 --> G6
    G6 --> FIN_PDF_BLOQUEADO
    D4 -->|"<= 500 filas"| S6
    S6 --> E2
    E2 --> S7
    S7 --> G7
    G7 --> FIN_PDF_OK
```

> **Control previo de exportación:** Se valida el número de registros del resultado filtrado antes de crear `export_id` o iniciar un trabajo. CSV admite hasta 100.000 filas y PDF hasta 500, inclusive. Si se supera el límite correspondiente, la solicitud se rechaza con HTTP `422` y `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO`, sin crear `export_id` ni trabajo.

---

### 4.4 Ciclo de vida y archivado verificado a almacenamiento en frío

```mermaid
flowchart LR

    subgraph WORKER["Worker mensual de archivado"]
        direction TB
        INICIO_CRON((Disparador mensual de archivado))
        W1["Consultar registros con antigüedad >= AUDIT_HOT_RETENTION_MONTHS"]
        D1{"¿Existen particiones o registros elegibles?"}
        W2["Concluir ciclo mensual sin cambios"]
        W3["Extraer datos elegibles y generar archivo Parquet"]
        W4["Ejecutar verificación de checksum, conteo de filas y legibilidad"]
        D2{"¿Verificación de integridad y recuperabilidad superada?"}
        W5["Transferir Parquet a almacenamiento en frío"]
        W6["Purgar registros calientes con credenciales de mantenimiento"]
        W7["Abortar retiro, conservar registros calientes y emitir alerta"]
    end

    subgraph DB_HOT["Almacén caliente (Base operativa)"]
        direction TB
        B1["Mantener registros durante retención caliente (MVP 24 meses)"]
        B2["Eliminar partición archivada únicamente tras confirmación"]
    end

    subgraph COLD_STORAGE["Almacenamiento en frío (S3 / Cloud Storage)"]
        direction TB
        C1["Retener archivo Parquet durante AUDIT_ARCHIVE_RETENTION_YEARS (MVP 5 años)"]
    end

    FIN_SIN_ARCHIVAR(((Sin registros elegibles para archivar)))
    FIN_ARCHIVADO_OK(((Partición archivada e integridad verificada)))
    FIN_ARCHIVADO_FALLO(((Archivado abortado por error de integridad)))

    INICIO_CRON --> W1
    W1 --> B1
    B1 --> D1
    D1 -->|"No"| W2
    W2 --> FIN_SIN_ARCHIVAR
    D1 -->|"Sí"| W3
    W3 --> W4
    W4 --> D2
    D2 -->|"No"| W7
    W7 --> FIN_ARCHIVADO_FALLO
    D2 -->|"Sí"| W5
    W5 --> C1
    C1 --> W6
    W6 --> B2
    B2 --> FIN_ARCHIVADO_OK
```

> **Garantía de integridad de auditoría:** La conexión estándar del Servicio de Auditoría solo dispone de permisos `INSERT` y `SELECT`. El proceso de retiro a almacenamiento en frío utiliza credenciales de mantenimiento aisladas y nunca elimina registros de la base caliente si la verificación del archivo Parquet falla o no se comprueba su recuperabilidad.
