# FLOW-007 — Reglas de venta cruzada y upselling

## 1. Identificación

- **Código:** FLOW-007
- **Funcionalidad:** Reglas de venta cruzada y upselling
- **Relacionado con:** [SPEC-007](../specs/SPEC-007-reglas-venta-cruzada-upselling.md) / [HU-007](../hu/HU-007-reglas-venta-cruzada-upselling.md) / [WF-007](../wireframes/flows/WF-007-reglas-venta-cruzada-upselling.md)
- **Responsable:** Axel Andree Cueva Alcalá
- **Última actualización:** 2026-10-02
- **Contratos consultados:** [OpenAPI 0.5.0](../api/openapi.yaml), [AsyncAPI 0.4.0](../asyncapi/asyncapi.yaml), [catálogo de eventos](../api/catalogo-eventos.md) y [Arquitectura, §35 y extensión HTTP 0.5.0](../Arquitectura.md).

## 2. Objetivo del flujo

Representar la creación, edición y cambio de estado de reglas manuales de Cross-sell (complementos) y Upsell (alternativas superiores clasificadas por el gestor), y la consulta de candidatos válidos por producto/categoría para un canal. Las recomendaciones se filtran y ordenan usando proyecciones locales actualizadas por eventos; no agregan ni reemplazan productos automáticamente.

## 3. Actores participantes

- **Gestor comercial:** configura y consulta reglas con autorización de Seguridad.
- **Canal de venta:** Marketplace, Chatbot o Retail; consulta candidatos para un producto y canal.
- **Promociones/Recomendaciones (`promotions-svc`):** administra reglas, selecciona candidatos y mantiene las proyecciones requeridas.
- **Servicios publicadores:** Catálogo, Inventario y Pricing publican cambios confirmados para actualizar estado, disponibilidad e información de precio.

Chatbot interpreta necesidades y lenguaje natural; Productos y Ofertas entrega candidatos comerciales y no realiza esa interpretación.

## 4. Diagramas de flujo

Los subflujos extensos usan orientación `TB` para conservar la legibilidad al renderizar en GitHub; el flujo independiente de proyecciones usa `LR`. Se mantienen actores separados, decisiones etiquetadas e inicio y fin explícitos conforme a [FLOW_TEMPLATE](FLOW_TEMPLATE.md).

### 4.1 Creación y edición de reglas

```mermaid
flowchart TB
    subgraph G["Gestor comercial"]
        direction TB
        I(("Gestión abierta"))
        G1["Consultar listado y detalle y elegir crear o editar regla"]
        G2["Definir nombre, tipo, origen producto o categoría, prioridad, vigencia y estado"]
        G3["Seleccionar recomendados activos y asignar orden"]
        G4["Asignar criterio a cada Upsell y justificación opcional"]
        G5["Corregir los datos conservados"]
        G6["Consultar regla guardada"]
        F((("Guardada")))
    end
    subgraph P["Promociones/Recomendaciones"]
        direction TB
        D1{"¿Sesión y permisos válidos?"}
        P1["Ofrecer productos activos excluyendo origen específico y ya añadidos"]
        D2{"¿Tipo UPSELL?"}
        P2["Validar origen, recomendados, prioridad, orden, vigencia y estado"]
        D3{"¿Configuración válida y criterio completo cuando es Upsell?"}
        P3["Guardar regla y registrar auditoría de creación o modificación"]
        P4["Informar errores sin guardar"]
        X((("Sin acceso")))
    end
    I --> G1 --> D1
    D1 -->|"No"| X
    D1 -->|"Sí"| G2 --> P1 --> G3 --> D2
    D2 -->|"Sí"| G4 --> P2
    D2 -->|"No: CROSS_SELL"| P2
    P2 --> D3
    D3 -->|"Sí"| P3 --> G6 --> F
    D3 -->|"No"| P4 --> G5 --> G2
```

Validaciones (SPEC-007 §5; HU-007 CA-01–08):

- Origen por producto o categoría existente/activo; al menos un producto recomendado existente y activo.
- No recomendar el propio origen específico ni duplicar productos en la misma regla. En consulta también se excluye el producto solicitado cuando coincide con una regla de categoría.
- Prioridad y orden son enteros positivos; prioridad `1` es la mayor. Inicio < fin; la regla está funcionalmente activa o inactiva. SPEC-007 denomina esos estados `ACTIVA | INACTIVA`; el campo administrativo `estado` usa los valores contractuales `ACTIVO | INACTIVO` de `EstadoEntidad` en OpenAPI. El FLOW conserva la misma regla funcional sin cambiar el enum HTTP.
- Cada recomendado Upsell exige un criterio controlado: `MAYOR_RENDIMIENTO`, `MEJOR_MATERIAL`, `MAYOR_CAPACIDAD` o `FUNCIONALIDAD_ADICIONAL`. La justificación comercial es opcional; no sustituye el criterio.
- Cross-sell configura complementos; Upsell configura alternativas clasificadas manualmente. El sistema no verifica automáticamente superioridad ni deduce que un precio mayor sea suficiente.

La administración usa `GET /api/v1/recomendaciones/reglas`, `POST /api/v1/recomendaciones/reglas`, `GET /api/v1/recomendaciones/reglas/{reglaId}` y `PATCH /api/v1/recomendaciones/reglas/{reglaId}`. El selector y detalle siguen WF-007; los criterios se muestran con etiquetas humanas y los payloads permanecen en OpenAPI.

### 4.2 Activación y desactivación

```mermaid
flowchart TB
    subgraph G["Gestor comercial"]
        direction TB
        I(("Cambio solicitado"))
        G1["Seleccionar regla y confirmar activación o desactivación"]
        G2["Consultar estado actualizado"]
        F((("Actualizado")))
    end
    subgraph P["Promociones/Recomendaciones"]
        direction TB
        P1["Validar autorización, existencia y solicitud"]
        D1{"¿Solicitud válida?"}
        P2["Activar o desactivar regla"]
        P3["Informar rechazo sin modificar la regla"]
        X((("Rechazado")))
    end
    I --> G1 --> P1 --> D1
    D1 -->|"Sí"| P2 --> G2 --> F
    D1 -->|"No"| P3 --> X
```

Se utilizan `POST /api/v1/recomendaciones/reglas/{reglaId}/activar` y `POST /api/v1/recomendaciones/reglas/{reglaId}/desactivar`. Solo reglas activas, vigentes y coincidentes participan en la consulta (HU-007 CA-09).

### 4.3 Consulta de recomendaciones del canal

```mermaid
flowchart TB
    subgraph C["Canal de venta"]
        direction TB
        I(("Recomendaciones solicitadas"))
        C1["Enviar productoId y canal a GET /api/v1/recomendaciones"]
        C2["Presentar candidatos sin agregarlos ni reemplazar productos automáticamente"]
        F((("Respondida")))
    end
    subgraph P["Promociones/Recomendaciones"]
        direction TB
        P1["Validar solicitud y autorización del canal"]
        D1{"¿Solicitud válida?"}
        P2["Leer proyecciones locales de catálogo, disponibilidad y precio"]
        D2{"¿Origen existente, activo y elegible para el canal?"}
        P3["Seleccionar reglas activas, vigentes y coincidentes por producto o categoría"]
        P4["Excluir origen solicitado, inexistentes, inactivos, no elegibles y sin disponibilidad"]
        P5["Ordenar por prioridad ascendente y luego orden ascendente"]
        P6["Deduplicar por producto conservando la primera aparición"]
        P7["Responder producto, tipo, prioridad, orden y enriquecimientos informativos contractuales"]
        P8["Responder recommendations vacío sin candidatos válidos"]
        P9["Responder error contractual"]
        X((("Rechazada")))
        D3{"¿Quedan candidatos válidos?"}
    end
    I --> C1 --> P1 --> D1
    D1 -->|"No"| P9 --> X
    D1 -->|"Sí"| P2 --> D2
    D2 -->|"No"| P8
    D2 -->|"Sí"| P3 --> P4 --> P5 --> P6 --> D3
    D3 -->|"Sí"| P7 --> C2
    D3 -->|"No"| P8 --> C2
    C2 --> F
```

La ruta es `GET /api/v1/recomendaciones?productoId=...&canal=...`. La respuesta contractual es un objeto `RecomendacionesResponse`: sin candidatos, `recommendations: []`; el FLOW no sustituye ese objeto por un array raíz.

La salida se mantiene a nivel `product_id`, sin seleccionar SKU/variante ni exponer saldos internos. Cada producto aparece una sola vez y conserva la prioridad y orden de su primera aparición. El precio es informativo, regular u oferta pública vigente de Pricing; no congela precio de pedido, no demuestra superioridad y no reserva stock. La resolución definitiva del SKU elegido corresponde al proceso posterior del canal.

**Límites provisionales vigentes:** la consulta está publicada como `provisional` en OpenAPI 0.5.0. `D-REC-01` (disponibilidad por producto con múltiples SKU) y `D-REC-02` (significado de `current_price` con variantes/overrides) siguen abiertas en SPEC/HU-007. El FLOW representa el filtrado comercial requerido, sin definir una agregación nueva de stock ni seleccionar un precio de variante. Los enriquecimientos `availability` y `current_price` conservan ese carácter provisional. Si se expone disponibilidad, utiliza los estados contractuales `DISPONIBLE`, `STOCK_BAJO`, `AGOTADO`.

No existe simulador administrativo ni pantalla «Probar recomendaciones». La consulta de canal no incorpora IA/ML, personalización histórica o reemplazo automático de productos.

### 4.4 Actualización automática de elegibilidad e información comercial

```mermaid
flowchart LR
    subgraph S["Servicios propietarios"]
        direction TB
        I(("Cambio confirmado"))
        S1["Publicar el evento contractual del cambio"]
    end
    subgraph P["Promociones: proyecciones de recomendaciones"]
        direction TB
        D1{"¿Qué evento se recibió?"}
        P1["Actualizar estado local y excluir producto o SKU desactivado de nuevas recomendaciones"]
        P2["Actualizar disponibilidad usada para filtrar candidatos"]
        P3["Actualizar solo información comercial de precio mostrada"]
        P4["Conservar definición histórica y comercial de las reglas"]
        F((("Actualizada")))
    end
    I --> S1 --> D1
    D1 -->|"catalog.product.deactivated"| P1
    D1 -->|"catalog.sku.deactivated"| P1
    D1 -->|"inventory.stock.changed"| P2
    D1 -->|"pricing.price.changed"| P3
    P1 --> P4
    P2 --> P4
    P3 --> P4 --> F
```

Los cuatro consumidores de `promotions-svc` existen en AsyncAPI/catálogo 0.4.0. Las proyecciones son locales y reconstruibles mediante los eventos publicados; Catálogo, Inventario y Pricing conservan ownership. No hay llamadas síncronas permanentes ni joins sobre sus schemas para estos datos proyectados.

Un producto/SKU desactivado deja de ser elegible sin editar manualmente reglas históricas. Stock confirmado modifica la elegibilidad de salida, sin alterar la definición comercial. Precio confirmado actualiza la información mostrada, sin redefinir Cross-sell/Upsell ni su criterio. El efecto product-level de cambios por SKU sigue sujeto a `D-REC-01/02`; la recepción del evento no resuelve esas decisiones abiertas.

Estos eventos actualizan proyecciones internas: no equivalen a crear/editar una regla por el gestor ni a comandos/resultados de consumo de cupón.

## 5. Coherencia y trazabilidad

| Reglas | Fuente | Representación |
|---|---|---|
| Administración, origen, recomendados y auditoría | SPEC-007 §§3, 5–6; HU-007 CA-01–04; WF-007 | §§4.1–4.2 |
| Upsell manual, criterio y justificación | SPEC-007 §5 req. 2; HU-007 CA-05–07; WF-007 | §4.1 |
| Prioridad, orden, vigencia, filtrado y deduplicación | SPEC-007 §§4–5; HU-007 CA-08–10 | §4.3 |
| Consulta contractual, precio informativo y ausencia de simulador | SPEC-007 §5 req. 9–10 y §7; HU-007 CA-11–12; OpenAPI | §4.3 |
| Proyecciones y preservación de reglas | Arquitectura §35 y extensión HTTP 0.5.0; AsyncAPI y catálogo 0.4.0 | §4.4 |
| Multicanal, nivel producto y decisiones abiertas | Extensiones 0.5.0 de SPEC/HU-007; OpenAPI | §§4.3–4.4 |
