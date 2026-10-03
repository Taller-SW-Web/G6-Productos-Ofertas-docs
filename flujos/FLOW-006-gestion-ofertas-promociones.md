# FLOW-006 — Gestión de ofertas y promociones

## 1. Identificación

- **Código:** FLOW-006
- **Funcionalidad:** Gestión de ofertas y promociones
- **Relacionado con:** [SPEC-006](../specs/SPEC-006-gestion-ofertas-promociones.md) / [HU-006](../hu/HU-006-gestion-ofertas-promociones.md) / [WF-006](../wireframes/flows/WF-006-gestion-ofertas-promociones.md)
- **Responsable:** Axel Andree Cueva Alcalá
- **Última actualización:** 2026-10-02
- **Contratos consultados:** [OpenAPI 0.5.0](../api/openapi.yaml), [AsyncAPI 0.4.0](../asyncapi/asyncapi.yaml), [catálogo de eventos](../api/catalogo-eventos.md) y [Arquitectura, §§17, 35 y extensión HTTP 0.5.0](../Arquitectura.md).

## 2. Objetivo del flujo

Representar la creación, edición y activación/desactivación de promociones y la evaluación comercial de combinaciones autorizadas para un canal. Promociones utiliza precios, estado comercial y disponibilidad de sus proyecciones locales, actualizadas mediante eventos publicados por los servicios propietarios. La evaluación conserva el precio maestro de Pricing y no ejecuta operaciones de pedido, inventario ni consumo de cupón.

## 3. Actores participantes

- **Gestor comercial:** consulta y administra configuración promocional con autorización de Seguridad.
- **Canal de venta:** Marketplace, Chatbot o Retail; consulta promociones y solicita evaluación en el proceso real de compra.
- **Promociones (`promotions-svc`):** administra promociones, evalúa beneficios y mantiene proyecciones locales reconstruibles.
- **Servicios publicadores:** Catálogo, Inventario y Pricing publican cambios confirmados que actualizan esas proyecciones. No son invocados síncronamente en los pasos de evaluación aquí representados.

La validación de cupones es una capacidad del mismo bounded context; su ciclo de consumo y restitución se representa en [FLOW-005](FLOW-005-gestion-cupones-descuento.md).

## 4. Diagramas de flujo

Los subflujos extensos usan orientación `TB` para conservar la legibilidad al renderizar en GitHub; el flujo independiente de proyecciones usa `LR`. Se mantienen actores separados, decisiones etiquetadas e inicio y fin explícitos conforme a [FLOW_TEMPLATE](FLOW_TEMPLATE.md).

### 4.1 Creación y edición

```mermaid
flowchart TB
    subgraph G["Gestor comercial"]
        direction TB
        I(("Gestión abierta"))
        G1["Consultar listado administrativo y detalle"]
        G2["Elegir crear o editar promoción"]
        G3["Ingresar alcance, descuento, vigencia, modalidad, estado, prioridad, canales y combinación"]
        G4["Corregir datos conservados o crear otra promoción"]
        G5["Consultar configuración guardada"]
        F((("Guardada")))
    end
    subgraph P["Promociones"]
        direction TB
        D1{"¿Sesión y permisos válidos?"}
        P1["Validar configuración y alcance por producto o SKU activo"]
        D2{"¿Configuración válida?"}
        D3{"¿Edición cambia modalidad?"}
        D4{"¿Inactiva, nunca activada, sin cupones ni usos históricos?"}
        P2["Guardar promoción sin alterar pedidos confirmados"]
        P3["Informar errores sin guardar"]
        P4["Bloquear cambio de modalidad y orientar a crear otra promoción"]
        X((("Sin acceso")))
    end
    I --> G1 --> G2 --> D1
    D1 -->|"Sí"| G3 --> P1 --> D2
    D1 -->|"No"| X
    D2 -->|"No"| P3 --> G4 --> G3
    D2 -->|"Sí"| D3
    D3 -->|"No"| P2
    D3 -->|"Sí"| D4
    D4 -->|"Sí"| P2 --> G5 --> F
    D4 -->|"No"| P4 --> G4
```

Validaciones (HU-006 CA-02–03, CA-11–13):

- Nombre y alcance con al menos un producto o SKU vendible activo; deduplicar coincidencias de producto completo y SKU.
- Porcentaje: `0 < valor <= 100`; monto fijo: `valor > 0`.
- Vigencia: `inicio < fin`, correspondientes a `validFrom` y `validUntil` contractuales.
- Modalidad obligatoria `AUTOMATICA` o `CUPON`; estado inicial, prioridad positiva, canales habilitados y política de combinación.
- La política controla combinación con oferta propia de Pricing, promoción automática y cupón. Por defecto no se combinan; todas las combinaciones deshabilitadas representan exclusividad.
- Cambiar modalidad solo se permite si se cumplen simultáneamente las cuatro condiciones de la decisión del diagrama. Si ya fue activada/utilizada o tiene cupones asociados, se crea una nueva promoción.

La administración usa `GET /api/v1/promociones/administracion`, `GET /api/v1/promociones/{promocionId}`, `POST /api/v1/promociones` y `PATCH /api/v1/promociones/{promocionId}`. La consulta administrativa está publicada como `provisional-internal`; no se confunde con `GET /api/v1/promociones`, que sirve la consulta del canal. Los cuerpos y errores se consultan en OpenAPI.

### 4.2 Activación y desactivación

```mermaid
flowchart TB
    subgraph G["Gestor comercial"]
        direction TB
        I(("Cambio solicitado"))
        G1["Seleccionar promoción y estado destino"]
        G2["Consultar estado actualizado"]
        F((("Actualizado")))
    end
    subgraph P["Promociones"]
        direction TB
        P1["Validar autorización, existencia y solicitud"]
        D1{"¿Solicitud válida?"}
        P2["Activar o desactivar sin modificar pedidos confirmados"]
        P3["Informar el rechazo sin cambiar el estado"]
        X((("Rechazado")))
    end
    I --> G1 --> P1 --> D1
    D1 -->|"Sí"| P2 --> G2 --> F
    D1 -->|"No"| P3 --> X
```

Se usan `POST /api/v1/promociones/{promocionId}/activar` y `POST /api/v1/promociones/{promocionId}/desactivar`. Una promoción desactivada no participa en nuevas evaluaciones; los pedidos históricos mantienen su snapshot (HU-006 CA-04, CA-09).

### 4.3 Evaluación comercial del canal

```mermaid
flowchart TB
    subgraph C["Canal de venta"]
        direction TB
        I(("Evaluación solicitada"))
        C1["Enviar cesta, channel_id, at y cupón e identidad si corresponden"]
        C2["Recibir beneficio, importes y motivo cuando no aplica"]
        F((("Evaluación respondida")))
    end
    subgraph P["Promociones"]
        direction TB
        P1["Validar solicitud y leer proyecciones locales de catálogo, precio y disponibilidad"]
        D1{"¿Solicitud válida?"}
        P2["Excluir productos o SKU desactivados y seleccionar promociones activas, vigentes y del canal"]
        P3["Resolver alcance y deduplicar coincidencias de producto y SKU"]
        D2{"¿Se presentó coupon_code?"}
        P4["Validar cupón sin consumo según FLOW-005"]
        D3{"¿Cupón válido para el contexto?"}
        P5["Incluir alternativas CUPON elegibles"]
        P6["Excluir alternativas CUPON sin código válido"]
        P7["Construir solo combinaciones autorizadas con oferta Pricing, automáticas y cupón"]
        P8["Calcular porcentaje o monto fijo sin importe negativo"]
        P9["Elegir menor importe final y aplicar desempates documentados"]
        P10["Responder error contractual"]
        X((("Rechazada")))
    end
    I --> C1 --> P1 --> D1
    D1 -->|"No"| P10 --> X
    D1 -->|"Sí"| P2 --> P3 --> D2
    D2 -->|"Sí"| P4 --> D3
    D2 -->|"No"| P6
    D3 -->|"Sí"| P5 --> P7
    D3 -->|"No: no elegible"| P6 --> P7
    D3 -->|"Error contractual"| P10
    P7 --> P8 --> P9 --> C2 --> F
```

- Ruta: `POST /api/v1/promociones/evaluar`. El esquema contractual define `lines`, `channel_id`, `at`, `coupon_code` y `customer_ref`; no se copian ni redefinen payloads en este FLOW.
- Solo participa una promoción activa, vigente en `at`, coincidente con el alcance y habilitada para el canal. La modalidad `CUPON` exige código válido; nunca se aplica automáticamente sin él.
- Pricing es propietario del regular/oferta propia. La evaluación lee la información comercial proyectada y aplica combinaciones permitidas sin sobrescribir el precio maestro ni descontar dos veces sobre beneficios incompatibles.
- El monto fijo se aplica una vez al subtotal elegible y se limita a ese subtotal; cualquier descuento deja un importe final no negativo.
- Se elige la alternativa válida de menor importe final. En empate exacto: **alternativa que no requiere consumir cupón → menor prioridad numérica → identificador estable** (HU-006). El desempate no realiza consumo; compara las alternativas.
- Se informa el motivo contractual si no aplica beneficio. La evaluación no consume cupón, no crea pedido y no reserva stock. Una alternativa ganadora con cupón debe pasar luego por el consumo atómico de FLOW-005; validar no reserva cupo.
- La información de disponibilidad usada por Promociones se actualiza desde la proyección; el FLOW no añade una regla de stock para descuentos distinta de las fuentes vigentes.

No existe pantalla administrativa «Evaluar compra» ni simulador de checkout (HU-006 CA-16; WF-006).

### 4.4 Actualización de proyecciones locales

```mermaid
flowchart LR
    subgraph S["Servicios propietarios"]
        direction TB
        I(("Cambio confirmado"))
        S1["Publicar el evento contractual del cambio"]
    end
    subgraph P["Promociones: actualización interna"]
        direction TB
        D1{"¿Qué evento se recibió?"}
        P1["Actualizar estado local de producto o SKU e invalidar su elegibilidad"]
        P2["Actualizar disponibilidad local con stock confirmado"]
        P3["Actualizar información comercial local de precio"]
        P4["Usar la proyección actualizada en nuevas evaluaciones"]
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

Los cuatro eventos están publicados en AsyncAPI/catálogo 0.4.0 con `promotions-svc` como consumidor. Las proyecciones son locales y reconstruibles a partir de los eventos publicados, sin ownership sobre las tablas de los servicios externos.

Un producto o SKU desactivado deja de ser candidato válido en nuevas evaluaciones. Stock confirmado actualiza la disponibilidad; precio confirmado actualiza el insumo comercial. Estos eventos no crean/editan promociones ni representan una operación del gestor. Tampoco son comandos/resultados de consumo de cupón. No se representa una dependencia síncrona permanente con Catálogo, Inventario o Pricing para esos datos proyectados.

## 5. Coherencia y trazabilidad

| Reglas | Fuente | Representación |
|---|---|---|
| Autorización, gestión y configuración completa | HU-006 CA-01–04; WF-006; OpenAPI | §§4.1–4.2 |
| Alcance, fechas, modalidad y restricción de cambio | HU-006 CA-03, CA-11–13 | §4.1 |
| Elegibilidad, cálculo, combinación, resultado y desempate | SPEC-006 §§2–5; HU-006 CA-05–08, CA-10, CA-14–15 y reglas consolidadas | §4.3 |
| Preservar pedidos confirmados y evitar simulador administrativo | HU-006 CA-09, CA-16–17; WF-006 | §§4.1–4.3 |
| Proyecciones y consumidores publicados | Arquitectura §35; AsyncAPI y catálogo 0.4.0 | §4.4 |

La referencia HTTP de este FLOW es OpenAPI 0.5.0 vigente en `master`; la mensajería continúa en AsyncAPI 0.4.0. La actualización del FLOW no altera contratos ni crea eventos administrativos nuevos.

### Precisiones administrativas de la corrección 2026-10-02

El alcance administrativo distingue `productIds` y `skus`; la selección por producto completo conserva esa identidad. `canalesHabilitados` requiere al menos un canal explícito y no interpreta vacío/omisión al crear como todos. El servicio publica `puedeCambiarModalidad` de solo lectura y revalida HU-006 CA-13 al modificar; la UI no infiere esa elegibilidad del estado inactivo. La activación previa permanece aunque luego se desactive. Estas precisiones no introducen rutas ni eventos nuevos.
