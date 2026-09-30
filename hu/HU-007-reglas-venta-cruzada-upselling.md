# HU-007 — Historia de Usuario: Reglas de venta cruzada y upselling

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** Spec [SPEC-007](./specs/SPEC-007-reglas-venta-cruzada-upselling.md) | Flow [WF-007](./wireframes/flows/WF-007-reglas-venta-cruzada-upselling.md)

**Como** gestor comercial, **quiero** configurar relaciones manuales de Cross-sell y Upsell, **para** que los canales presenten complementos o alternativas superiores.

## Reglas
- Cross-sell = complemento.
- Upsell = alternativa clasificada manualmente.
- Criterio obligatorio; justificación opcional.
- Prioridad ascendente, luego orden ascendente.
- Deduplicar conservando la primera aparición.
- No existe pantalla administrativa de prueba.

## Criterios de aceptación
| ID | Criterio |
|---|---|
| CA-01 | Solo usuario autorizado administra reglas. |
| CA-02 | Nombre, tipo, origen, prioridad, vigencia, estado y al menos un recomendado. |
| CA-03 | Origen producto o categoría. |
| CA-04 | Productos existentes/activos, sin origen ni duplicados internos. |
| CA-05 | Cada Upsell exige criterio; justificación opcional. |
| CA-06 | Criterios: `MAYOR_RENDIMIENTO`, `MEJOR_MATERIAL`, `MAYOR_CAPACIDAD`, `FUNCIONALIDAD_ADICIONAL`. |
| CA-07 | Precio mayor no demuestra superioridad. |
| CA-08 | Orden interno configurable. |
| CA-09 | Solo regla activa/vigente/coincidente participa. |
| CA-10 | Excluir inactivos/sin stock y deduplicar. |
| CA-11 | API incluye producto, tipo, prioridad, orden, precio y disponibilidad. |
| CA-12 | No agrega/reemplaza productos ni incorpora simulador administrativo. |

## Escenarios
1. Cross-sell válido: guarda complemento.
2. Upsell válido: guarda criterio controlado.
3. Upsell sin criterio: bloquea y conserva datos.
4. Regla por categoría: aplica a producto de esa categoría.
5. Vencida: no participa.
6. Dos reglas: respeta prioridad/orden y deduplica.

## Frontera Chatbot
Productos y Ofertas entrega candidatos; Chatbot interpreta lenguaje natural y necesidades.
