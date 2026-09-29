# HU-004 — Historia de Usuario: Gestión avanzada de variantes (SKUs)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** Spec [SPEC-004](./specs/SPEC-004-gestion-variantes-skus.md) | Flow [WF-004](./wireframes/flows/WF-004-gestion-variantes-skus.md)  
**Contrato HTTP:** [`./api/openapi.yaml`](./api/openapi.yaml)  
**Catálogo de errores:** [`./api/catalogo-errores.md`](./api/catalogo-errores.md)

**Versión:** v1.1 — seguridad y errores armonizados

---

## Historia de usuario principal

**Como** gestor comercial,

**quiero** definir y administrar variantes SKU de un producto según sus características distintivas, imagen y datos físicos propios,

**para** que el catálogo pueda identificar exactamente cada unidad vendible, integrarla con Pricing, Inventario y Despacho, y permitir que los canales comercialicen la variante correcta.

Esta funcionalidad aplica a productos con:

```text
tiene_variantes = true
```

Cada variante:

- pertenece a un producto padre;
- tiene `variant_id` interno e inmutable;
- tiene SKU comercial único;
- tiene atributos identificadores;
- puede tener atributos no identificadores;
- tiene imagen propia;
- puede disponer de un perfil físico asociado al SKU;
- no almacena precio ni stock como datos propios.

El perfil físico del SKU pertenece a Catálogo y contiene:

```text
pesoKg
largoCm
anchoCm
altoCm
```

Despacho consume estos datos para tomar decisiones logísticas, pero **el empaque no pertenece a Productos y Ofertas**.

---

# Criterios de aceptación

| ID | Criterio |
|---|---|
| **CA-01** | Solo un gestor comercial autorizado puede crear, editar, activar, reactivar o desactivar variantes. |
| **CA-02** | Una variante solo puede asociarse a un producto existente con `tiene_variantes=true`. |
| **CA-03** | Antes de crear la primera variante, el producto debe tener configurado un conjunto no vacío de características identificadoras `LISTA`, activas y permitidas por su `tipo_producto_id`. |
| **CA-04** | Después de crear la primera variante, el conjunto de características identificadoras queda inmutable para el CRUD ordinario. |
| **CA-05** | Cada variante debe proporcionar exactamente un `valor_id` válido por cada característica identificadora configurada. |
| **CA-06** | El sistema impide registrar dos variantes del mismo producto con la misma combinación de valores identificadores, incluso si una combinación anterior está inactiva. |
| **CA-07** | El sistema genera siempre un `variant_id` interno, estable, inmutable y separado del SKU comercial. |
| **CA-08** | El SKU comercial puede ser informado por el gestor/importación o generado automáticamente si se omite. En ambos casos debe ser único globalmente. |
| **CA-09** | Una vez publicada la identidad comercial, el SKU no puede cambiarse mediante edición ordinaria. |
| **CA-10** | Cada variante debe tener al menos una imagen propia válida. |
| **CA-11** | La imagen puede reemplazarse sin cambiar `variant_id`, SKU ni atributos identificadores. |
| **CA-12** | Los atributos identificadores son inmutables. Para corregirlos se debe desactivar la variante y crear una nueva. |
| **CA-13** | Los atributos no identificadores pueden editarse sin cambiar la identidad comercial de la variante. |
| **CA-14** | Una variante nueva inicia en estado `BORRADOR`. |
| **CA-15** | Una variante puede pasar de `BORRADOR` a `ACTIVA` cuando cumple SKU válido, atributos identificadores válidos, imagen válida, producto padre compatible, Pricing preparado e Inventario inicializado. |
| **CA-16** | Una variante `INACTIVA` puede reactivarse si vuelve a cumplir las condiciones de activación; conserva `variant_id` y SKU. |
| **CA-17** | Reactivar una variante no reactiva automáticamente al producto padre. |
| **CA-18** | Al desactivar una variante, esta deja de participar en nuevas ventas y nuevos combos, pero conserva histórico. |
| **CA-19** | Si se desactiva la última variante `ACTIVA`, el producto padre pasa a `INACTIVO` según la regla definida en Catálogo. |
| **CA-20** | Catálogo notifica o coordina la inicialización del SKU en Inventario, pero no almacena ni calcula `on_hand`, `reserved`, `available` ni `stock_version`. |
| **CA-21** | Pricing puede definir un precio específico por SKU; si no existe, aplica el fallback vigente definido por Pricing. Catálogo no persiste el precio autoritativo. |
| **CA-22** | Cada variante puede disponer de un perfil físico asociado a su SKU con `pesoKg`, `largoCm`, `anchoCm` y `altoCm`. |
| **CA-23** | Los datos físicos usan unidades contractuales fijas: peso en kilogramos y dimensiones en centímetros. |
| **CA-24** | `pesoKg`, `largoCm`, `anchoCm` y `altoCm` deben ser valores numéricos mayores que cero cuando se informen como perfil completo. |
| **CA-25** | Modificar peso o dimensiones no modifica `variant_id`, SKU ni atributos identificadores. |
| **CA-26** | El perfil físico puede editarse de forma independiente de la identidad de la variante. |
| **CA-27** | El sistema no debe inventar valores físicos faltantes ni sustituirlos por cero. |
| **CA-28** | La ausencia de perfil físico no amplía automáticamente las reglas de activación de la variante; cualquier cambio de esa regla requiere una decisión funcional explícita posterior. |
| **CA-29** | Despacho puede consultar en lote los datos físicos de varios SKU mediante el contrato publicado. |
| **CA-30** | La consulta física de Despacho devuelve únicamente información física y estado del SKU; no devuelve stock, reservas ni datos de pedido. |
| **CA-31** | Productos y Ofertas no define `tipoEmpaque`, cantidad de paquetes, dimensiones finales del paquete ni volumen logístico final. |
| **CA-32** | Despacho conserva ownership de empaque, agrupación y cálculo logístico final. |
| **CA-33** | Toda creación, edición de atributos, cambio de imagen, cambio de perfil físico y cambio de estado debe quedar trazable con actor, fecha/hora y resultado. |
| **CA-34** | Los pedidos confirmados conservan un snapshot de la variante vendida aunque esta se desactive posteriormente. |
| **CA-35** | Una variante `ACTIVA` no es vendible si su producto padre permanece `BORRADOR` o `INACTIVO`. |
| **CA-36** | Una creación masiva utiliza las mismas reglas de identidad, unicidad de SKU y atributos identificadores que una creación individual. |
| **CA-37** | Si la carga masiva incorpora perfil físico, debe utilizar los mismos campos, unidades y validaciones que esta HU; no puede crear un modelo físico alternativo. |
| **CA-38** | Una operación protegida sin token utilizable responde `401 TOKEN_INVALIDO` y no modifica la variante. |
| **CA-39** | Una identidad autenticada sin autorización suficiente responde `403 SCOPE_INSUFICIENTE` y no modifica la variante. |
| **CA-40** | `SIN_AUTORIZACION` no se utiliza en nuevos contratos ni como código de branching del frontend. |

---

# Escenarios dado-cuando-entonces

## Escenario 1 — Registrar una variante válida

- **DADO** un producto con `tiene_variantes=true` y características identificadoras Talla y Color,
- **CUANDO** el gestor registra Talla 42, Color Negro, una imagen válida y deja vacío el SKU,
- **ENTONCES** el sistema genera `variant_id`, genera un SKU comercial único, crea la variante en `BORRADOR` y conserva la asociación con el producto padre.

---

## Escenario 2 — SKU comercial proporcionado

- **DADO** una nueva variante válida,
- **CUANDO** el gestor informa el SKU `NKE-PEG-42-BLK`,
- **ENTONCES** el sistema valida formato y unicidad y conserva ese SKU si no existe colisión.

---

## Escenario 3 — Colisión de SKU

- **DADO** que `NKE-PEG-42-BLK` ya pertenece a otra unidad vendible,
- **CUANDO** se intenta registrar otra variante con ese SKU,
- **ENTONCES** el sistema rechaza la operación y no expone una variante incompleta.

---

## Escenario 4 — Rechazar combinación duplicada

- **DADO** que el producto ya tiene una variante Talla 42 + Negro,
- **CUANDO** se intenta crear otra con exactamente la misma combinación,
- **ENTONCES** el sistema rechaza el registro.

---

## Escenario 5 — Rechazar variante sin imagen propia

- **DADO** una combinación válida,
- **CUANDO** el gestor intenta crear la variante sin una imagen válida,
- **ENTONCES** el sistema impide completar el alta.

---

## Escenario 6 — Editar atributo no identificador

- **DADO** una variante existente,
- **CUANDO** el gestor modifica un atributo no identificador como material,
- **ENTONCES** el sistema guarda el cambio y conserva SKU, `variant_id` y atributos identificadores.

---

## Escenario 7 — Rechazar cambio de atributo identificador

- **DADO** una variante Talla 42 + Negro,
- **CUANDO** el gestor intenta cambiar Color a Blanco,
- **ENTONCES** el sistema rechaza la edición e indica que debe crear una nueva variante.

---

## Escenario 8 — Activar variante preparada

- **DADO** una variante `BORRADOR` con SKU, atributos, imagen, Pricing e Inventario preparados,
- **CUANDO** el gestor solicita activarla,
- **ENTONCES** la variante pasa a `ACTIVA` sin cambiar su identidad.

---

## Escenario 9 — Reactivar variante

- **DADO** una variante `INACTIVA` que vuelve a cumplir las condiciones,
- **CUANDO** el gestor solicita reactivarla,
- **ENTONCES** pasa a `ACTIVA`, conserva SKU y `variant_id`, y no reactiva automáticamente al padre.

---

## Escenario 10 — Desactivar última variante activa

- **DADO** un producto con una sola variante `ACTIVA`,
- **CUANDO** esa variante se desactiva,
- **ENTONCES** la variante pasa a `INACTIVA` y el producto padre también pasa a `INACTIVO`.

---

## Escenario 11 — Variante activa con padre borrador

- **DADO** una variante `ACTIVA` cuyo producto padre está `BORRADOR`,
- **CUANDO** un canal consulta productos elegibles para venta,
- **ENTONCES** la variante no se ofrece comercialmente.

---

## Escenario 12 — Registrar perfil físico válido

- **DADO** una variante con SKU `ZAP-RUN-42`,
- **CUANDO** el gestor registra:
  - peso: `1.4 kg`,
  - largo: `35 cm`,
  - ancho: `22 cm`,
  - alto: `13 cm`,
- **ENTONCES** el sistema guarda el perfil físico asociado a ese SKU.

---

## Escenario 13 — Editar perfil físico sin alterar identidad

- **DADO** una variante `ZAP-RUN-42` con peso `1.4 kg`,
- **CUANDO** el gestor corrige el peso a `1.35 kg`,
- **ENTONCES** se actualiza el perfil físico y se conservan el mismo SKU y `variant_id`.

---

## Escenario 14 — Rechazar peso inválido

- **DADO** una variante existente,
- **CUANDO** se intenta registrar `pesoKg=0`,
- **ENTONCES** el sistema rechaza la actualización y conserva el perfil anterior.

---

## Escenario 15 — Rechazar dimensión inválida

- **DADO** una variante existente,
- **CUANDO** se intenta registrar `altoCm=-2`,
- **ENTONCES** el sistema rechaza la actualización.

---

## Escenario 16 — Perfil físico incompleto

- **DADO** una variante sin todas sus dimensiones físicas,
- **CUANDO** Despacho consulta sus datos físicos,
- **ENTONCES** el sistema no inventa datos faltantes y reporta la condición de incompletitud según el contrato.

---

## Escenario 17 — Consulta física en lote

- **DADO** varios SKU con perfil físico completo,
- **CUANDO** `modulo-despacho` realiza una consulta en lote,
- **ENTONCES** Catálogo devuelve para cada SKU encontrado su estado, peso, dimensiones y fecha de actualización.

---

## Escenario 18 — SKU inexistente en lote

- **DADO** una consulta con un SKU válido y otro inexistente,
- **CUANDO** Despacho realiza la consulta,
- **ENTONCES** la respuesta distingue los SKU encontrados de los no encontrados.

---

## Escenario 19 — Despacho no recibe stock

- **DADO** una consulta física de Despacho,
- **CUANDO** Catálogo responde,
- **ENTONCES** la respuesta no incluye stock físico, reservado, disponible ni datos de reserva.

---

## Escenario 20 — Productos no define empaque

- **DADO** un SKU con peso y dimensiones válidos,
- **CUANDO** Despacho necesita preparar el envío,
- **ENTONCES** Despacho utiliza esos datos para decidir el empaque y Catálogo no determina caja, bolsa, cantidad de paquetes ni volumen logístico final.

---

## Escenario 21 — Creación masiva

- **DADO** una fila válida de carga masiva con producto padre y combinación identificadora,
- **CUANDO** Bulk solicita crear la variante,
- **ENTONCES** Catálogo aplica las mismas reglas de SKU, `variant_id`, combinación e identidad que en el alta individual.

---

## Escenario 22 — Token inválido

- **DADO** una operación protegida de variantes,
- **CUANDO** la petición no puede autenticarse mediante un token utilizable,
- **ENTONCES** responde `401 TOKEN_INVALIDO` y no aplica cambios.

---

## Escenario 23 — Permisos insuficientes

- **DADO** una identidad autenticada,
- **CUANDO** intenta crear, editar, activar, reactivar o desactivar sin autorización suficiente,
- **ENTONCES** responde `403 SCOPE_INSUFICIENTE`, no aplica cambios y no necesita revelar el permiso exacto faltante.

---

# Interacción con otros módulos

| Módulo | Necesidad | Información que recibe Catálogo/Variantes | Información que entrega |
|---|---|---|---|
| **Marketplace** | Mostrar la variante exacta elegible para compra. | Producto o filtros de selección. | SKU, atributos, imagen y estado; disponibilidad viene de Inventario. |
| **Chatbot** | Resolver una variante a partir de atributos mencionados. | Producto y valores como talla/color. | Variante/SKU encontrada e información comercial de Catálogo. |
| **Retail** | Seleccionar o escanear la variante correcta. | Producto o SKU. | Detalle de variante, identidad y estado. |
| **Ventas/Postventa** | Registrar el SKU exacto del pedido. | SKU del pedido. | Datos descriptivos/snapshot de la variante cuando corresponda. |
| **Despacho** | Obtener peso y dimensiones de varios SKU para preparar el despacho. | Lista de SKU. | Estado, `pesoKg`, dimensiones en cm y fecha de actualización. |
| **Seguridad y Usuarios** | Autenticar y autorizar gestión y acceso servicio-a-servicio. | Identidad, roles y permisos según contrato. | `401 TOKEN_INVALIDO` o `403 SCOPE_INSUFICIENTE` cuando corresponde. |

---

# Dependencias dentro de Productos y Ofertas

| Funcionalidad interna | Dependencia |
|---|---|
| **Gestión de Productos** | Producto padre, `sku_base`, `tiene_variantes`, categoría, marca y estado. |
| **Características** | Catálogo de características y valores. |
| **Tipo de Producto–Característica** | Define qué atributos aplican al producto. |
| **Inventario** | Inicializa y administra stock por SKU; Catálogo no guarda cantidades. |
| **Pricing** | Administra precio por producto/SKU. |
| **Combos** | Referencia componentes mediante SKU vendible. |
| **Bulk** | Puede crear variantes respetando las mismas reglas de identidad. |

---

# Reglas consolidadas

1. `variant_id` y SKU son identidades diferentes.
2. El SKU es comercial; `variant_id` es interno.
3. Una variante pertenece a un producto `tiene_variantes=true`.
4. Las características identificadoras se congelan desde la primera variante.
5. La combinación identificadora es única dentro del producto.
6. El SKU es único globalmente.
7. Imagen y atributos no identificadores son editables.
8. SKU y atributos identificadores no se editan ordinariamente.
9. Inventario es owner de stock.
10. Pricing es owner de precio.
11. Catálogo es owner del perfil físico del SKU.
12. El perfil físico utiliza kg y cm.
13. El perfil físico puede cambiar sin alterar identidad.
14. Despacho consume el perfil físico, pero es owner del empaque.
15. Catálogo no almacena ni calcula stock para Despacho.
16. La ausencia de perfil físico no se cubre con valores inventados.
17. La consulta física debe soportar múltiples SKU.
18. Los cambios relevantes deben quedar trazables.
19. `401` utiliza `TOKEN_INVALIDO`.
20. `403` utiliza `SCOPE_INSUFICIENTE`.
21. `SIN_AUTORIZACION` queda retirado de nuevos contratos.

---

# Autoridad documental

La regla funcional detallada pertenece a:

```text
SPEC-004-gestion-variantes-skus.md
```

Las rutas y schemas HTTP pertenecen a:

```text
api/openapi.yaml
```

Las decisiones de ownership y estructura pertenecen a:

```text
Arquitectura.md
Modelo_Conceptual.md
Contrato_Api.md
```

Si existe una contradicción funcional, la HU debe corregirse para alinearse con la SPEC y no mantener dos reglas distintas.

---

# Criterio de completitud de la HU

La historia se considera cubierta cuando existe evidencia de que:

- [ ] solo productos con variantes usan este flujo;
- [ ] `variant_id` es estable;
- [ ] SKU puede ser informado o autogenerado;
- [ ] SKU es único;
- [ ] la combinación identificadora es única;
- [ ] atributos identificadores son inmutables;
- [ ] imagen propia está soportada;
- [ ] BORRADOR / ACTIVA / INACTIVA funcionan;
- [ ] desactivar última variante afecta al padre según regla;
- [ ] Catálogo no persiste precio ni stock;
- [ ] el perfil físico puede registrarse;
- [ ] peso y dimensiones se validan;
- [ ] se usan kg y cm;
- [ ] editar perfil físico no cambia identidad;
- [ ] Despacho puede consultar varios SKU en lote;
- [ ] la consulta física no expone stock;
- [ ] Productos no define empaque;
- [ ] existen pruebas para validaciones físicas y consulta en lote;
- [ ] los cambios relevantes quedan auditados;
- [ ] 401 usa `TOKEN_INVALIDO`;
- [ ] 403 usa `SCOPE_INSUFICIENTE`;
- [ ] `SIN_AUTORIZACION` no se utiliza en nuevos contratos.
