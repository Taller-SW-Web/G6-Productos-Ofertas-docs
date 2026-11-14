# WF-015 — Control de stock y disponibilidad

## Usuario objetivo
Gestor comercial (`GESTOR_COMERCIAL`) con capacidades de gestión de inventario.

## Objetivo
Consultar saldos por SKU/ubicación y entender qué parte está física, reservada, bloqueada y disponible.

## Fórmula funcional

```text
Disponible = max(Físico - Reservado - Bloqueado, 0)
```

## Pantallas
- S-01 Control de stock.
- S-01-L Cargando.
- S-01-E Error.
- S-01-V Vacío.
- S-01-U Actualización recibida.
- S-02 Configuración de umbrales.
- S-03 Detalle del saldo.

## Columnas visibles

| Columna | Significado |
|---|---|
| SKU | Identidad vendible |
| Producto | Nombre |
| Ubicación | Tienda/almacén |
| Físico | Unidades contabilizadas |
| Reservado | Comprometidas en pedidos |
| Bloqueado | En cuarentena/no vendibles temporalmente |
| Disponible | Puede venderse |
| Umbral | Alerta configurada |
| Estado | Disponible / Stock bajo / Agotado |

## Detalle de saldo

Ejemplo:

```text
Físico      10
Reservado    3
Bloqueado    1
Disponible   6
```

Texto auxiliar:

> Las unidades reservadas están comprometidas en pedidos. Las bloqueadas permanecen físicamente en la ubicación, pero temporalmente no se ofrecen para venta.

## Actualizaciones automáticas
La UI refleja:
- reserva/consumo/liberación;
- incidencias físicas;
- rehabilitación/merma;
- reintegro;
- conciliación offline;
- inicialización de nuevos SKU.

No incluir botones visibles para ejecutar esas operaciones.

## No mostrar
`on_hand`, `reserved`, `blocked`, `available`, `operation_id`, eventos, endpoint, pedido o cliente.

## Recepción de traslados

Esta sección es accesible únicamente para un Gestor Comercial con la capacidad local de recepción de inventario correspondiente. No se modela un rol independiente de Operador de inventario.

### S-04 — Traslados pendientes
- SKU.
- Origen.
- Destino.
- Cantidad enviada.
- Cantidad recibida.
- Pendiente.
- Estado.
- Acción “Registrar recepción”.

### S-05 — Registrar recepción
Campos:
- Cantidad recibida.
- Disposición:
  - Reingresar como disponible.
  - Mantener bloqueado.
  - Confirmar merma.
- Marcar “Esta es la recepción final”.
- Nota opcional.

Si la recepción final deja faltantes, mostrar confirmación explícita:

> El traslado se cerrará con una discrepancia. Las unidades faltantes no se agregarán al inventario.

No mostrar:
- `operation_id`;
- capability interna;
- nombres de endpoint;
- `on_hand`, `blocked` o códigos de error.
