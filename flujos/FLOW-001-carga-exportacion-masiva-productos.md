# FLOW-001 — Carga masiva de productos


```mermaid
flowchart TD
    A["Cargar CSV/XLSX"] --> B["Validar estructura y filas"]
    B --> C{"¿Archivo válido?"}
    C -->|No| X["Rechazar y generar reporte"]
    C -->|Sí| D["Persistir borradores de Catálogo"]
    D --> E["Solicitar pricing.product.initialization.requested"]
    D --> F["Solicitar inventory.sku.initialization.requested"]
    E --> G{"Resultado Pricing"}
    F --> H{"Resultado Inventario"}
    G -->|Rejected| R["Marcar error de dependencia"]
    H -->|Rejected| R
    G -->|Completed| I["Consolidar fila"]
    H -->|Completed| I
    I --> J["COMPLETADO / COMPLETADO_CON_ERRORES"]
```

## Reglas

- No existe rollback distribuido.
- Pricing se inicializa por producto.
- Inventario se inicializa por SKU vendible.
- Reintentos son idempotentes.
