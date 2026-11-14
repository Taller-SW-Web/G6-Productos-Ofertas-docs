# SPEC-007 — Especificación: Reglas de venta cruzada y upselling

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** HU [HU-007](../hu/HU-007-reglas-venta-cruzada-upselling.md) | Wireframe [WF-007](..\..\ux\wireframes\flows\WF-007-reglas-venta-cruzada-upselling.md)

## 1. Contexto
Esta capacidad configura manualmente candidatos comerciales Cross-sell y Upsell para Marketplace, Chatbot y Retail. No sustituye la interpretación conversacional ni la personalización propia del canal.

## 2. Propósito
Definir recomendaciones por producto/categoría, ordenarlas de forma determinista y exponer solo candidatos vigentes y disponibles.

## 3. Alcance
Registrar Cross-sell/Upsell; origen por producto/categoría; recomendados; prioridad; orden; vigencia; estado; criterio de superioridad; justificación opcional; filtro de disponibilidad; deduplicación; consulta API.

## 4. Prioridad y orden
Prioridad `1` es la mayor. La salida se ordena por prioridad ascendente y luego por orden ascendente. Duplicados conservan la primera aparición.

El precio es informativo (regular u oferta pública vigente de Pricing) y no congela el precio del pedido ni reserva stock.

## 5. Requisitos
### Requisito 1: Cross-sell
Relacionar un origen con uno o más productos complementarios.

### Requisito 2: Upsell
Cada recomendado `UPSELL` requiere un `criterio_superioridad` controlado. Catálogo inicial:

```text
MAYOR_RENDIMIENTO
MEJOR_MATERIAL
MAYOR_CAPACIDAD
FUNCIONALIDAD_ADICIONAL
```

`justificacion_comercial` es opcional. El sistema no infiere superioridad ni usa precio mayor como criterio suficiente.

### Requisito 3: Productos válidos
Origen y recomendados existen y están activos. No se recomienda el propio origen ni se repite un producto en una regla.

### Requisito 4: Prioridad y orden
Enteros positivos.

### Requisito 5: Vigencia/estado
Inicio < fin; `ACTIVO | INACTIVO` según `EstadoEntidad` de OpenAPI 0.5.0; solo reglas activas/vigentes participan.

### Requisito 6: Coincidencia
Origen por producto específico o categoría.

### Requisito 7: Disponibilidad
Excluir inexistentes, inactivos y sin stock.

### Requisito 8: Deduplicación
Una sola aparición por producto, respetando prioridad/orden.

### Requisito 9: API
Devuelve producto, tipo, prioridad, orden, precio vigente y disponibilidad; lista vacía si no hay resultados.

### Requisito 10: Backoffice
Muestra configuración, criterio y justificación. **No existe una pantalla administrativa “Probar recomendaciones”.**

## 6. NFR
Administración autorizada; auditoría de creación/modificación; respuesta apta para interacción en tiempo real.

## 7. Fuera de alcance
IA/ML, lenguaje natural, personalización histórica, verificación automática de superioridad, reemplazo automático de productos y simulador administrativo.

## Criterio de completitud
Se cumplen origen, criterio, prioridad, orden, vigencia, filtrado y deduplicación sin añadir simulación administrativa.

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Extensión 0.5.0 — recomendaciones multicanal

Marketplace, Chatbot y Retail son consumidores de la consulta contractual.

Origen y recomendados deben existir, estar activos y ser comercialmente elegibles para el canal consultado. La capacidad usa disponibilidad **comercial**, nunca la composición del saldo.

La recomendación sigue a nivel:

```text
product_id
```

y no selecciona automáticamente SKU/variante.

`availability`, si se expone, reutiliza:

```text
DISPONIBLE
STOCK_BAJO
AGOTADO
```

El texto histórico anterior sobre `D-REC-01/02` como abiertas queda sustituido por el acuerdo interno G6 H4 (2026-11-01), sin borrar su trazabilidad: la decisión ya está aprobada internamente, aunque el contrato/runtime y las pruebas siguen sujetos a su estado documental y operativo.

### Addendum G6 H4 — DEC-G6-INT-02/03

Cada recomendación sigue a nivel `product_id`, sin elegir ni reservar SKU. Solo se agregan variantes elegibles por canal; no se suman ubicaciones. Si cualquier SKU tiene `DISPONIBLE`, el producto queda disponible; si no y alguno tiene `STOCK_BAJO`, queda bajo; si todos `AGOTADO`, se excluye. Si no hay disponibilidad positiva demostrada y queda `INDETERMINADO` o información inconsistente, también se excluye sin traducirlo a agotado. Un fallo global de Inventory o respuesta inválida/autorización/timeout es error técnico de la consulta completa, no lista vacía.

`current_price` es el mínimo precio efectivo entre SKU elegibles con disponibilidad positiva demostrada en el mismo canal e instante `at` UTC; Pricing resuelve oferta vigente, regular, herencia y override. Debe haber moneda homogénea. SKU sin precio no participa; sin precio/disponibilidad positiva no se recomienda el producto. Fallo de Pricing hace fallar la operación. No se agrega SKU al DTO y el valor no garantiza precio de cada variante ni disponibilidad de checkout. Ver la descripción contractual en [OpenAPI](../../contratos/http/openapi.yaml).
<!-- HOMOLOGACION-HTTP-0.5.0:END -->

> **Integración G1 Marketplace H4 (2026-10-20):** G6 aceptó y comunicó M-01–M-09 (`ACEPTADO_G6_COMUNICADO_G1`). Esta SPEC gobierna reglas funcionales de su dominio; operaciones HTTP se verifican en [OpenAPI](../../contratos/http/openapi.yaml), el reparto/estado operativo en [Acuerdo G1–G6 H4](../../integraciones/ACUERDO_G1_G6_H4_2026-10-20.md) y [alineación](../../integraciones/ALINEACION_MARKETPLACE.md). No declarar runtime, grants G7, despliegue o E2E por esta referencia. Las dependencias de otros owners se limitan a la operación que les corresponde.
