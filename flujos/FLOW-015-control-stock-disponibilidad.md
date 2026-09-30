# FLOW-015 — Control de stock y disponibilidad


## Saldo

```text
available = max(on_hand - reserved - blocked, 0)
```

## Venta normal

```mermaid
flowchart TD
    A["Ventas crea CREADO"] --> B["Solicitar reserva"]
    B --> C{"Resultado"}
    C -->|created| D["reserved aumenta"]
    C -->|rejected| X["No continuar"]
    D --> E{"¿Pago?"}
    E -->|PAGADO| F["Confirmar consumo"]
    E -->|No completado| G["Liberar"]
    F --> H["on_hand y reserved disminuyen"]
    G --> I["reserved disminuye"]
```

## Incidencia física

```mermaid
flowchart TD
    A["Retail reporta daño/no ubicación"] --> B["Validar unidades disponibles"]
    B --> C["blocked aumenta"]
    C --> D["available disminuye para todos los canales"]
    D --> E{"Resolución"}
    E -->|Rehabilitado| F["blocked disminuye"]
    E -->|Merma/Faltante| G["blocked y on_hand disminuyen"]
```

## Reintegro

```mermaid
flowchart TD
    A["Postventa confirma retorno físico apto"] --> B["Ventas solicita reintegro"]
    B --> C["on_hand aumenta"]
    C --> D["Kardex + stock.changed"]
```

## Venta offline

```mermaid
flowchart TD
    A["Retail vende offline"] --> B["Sincroniza venta con Ventas"]
    B --> C["Ventas solicita conciliación"]
    C --> D["Aplicar min(requested, available)"]
    D --> E{"¿Queda unresolved?"}
    E -->|No| F["COMPLETED"]
    E -->|Sí| G["REQUIRES_REVIEW"]
```

## Inicialización de stock

```text
catalog-svc -> inventory.sku.initialization.requested
```

Solo aplica a SKU vendible.

## Traslado a almacén central

```mermaid
flowchart TD
    A["Incidencia bloqueada en Retail"] --> B["Resolver: Traslado a almacén central"]
    B --> C["Descontar Físico y Bloqueado en origen"]
    C --> D["Crear traslado En tránsito"]
    D --> E["Operador de inventario recibe unidades"]
    E --> F{"Disposición"}
    F -->|Disponible| G["Aumentar Físico y Disponible en destino"]
    F -->|Bloqueado| H["Aumentar Físico y Bloqueado en destino"]
    F -->|Merma| I["No acreditar stock"]
    G --> J{"¿Recepción final?"}
    H --> J
    I --> J
    J -->|No| K["Recibido parcial"]
    J -->|Sí, completo| L["Completado"]
    J -->|Sí, faltantes| M["Completado con discrepancia"]
```
