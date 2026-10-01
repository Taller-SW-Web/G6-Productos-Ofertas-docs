# SPEC-007 — Especificación: Reglas de venta cruzada y upselling

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** HU [HU-007](../hu/HU-007-reglas-venta-cruzada-upselling.md) | Wireframe [WF-007](../wireframes/flows/WF-007-reglas-venta-cruzada-upselling.md)

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
Inicio < fin; `ACTIVA | INACTIVA`; solo activas/vigentes participan.

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
