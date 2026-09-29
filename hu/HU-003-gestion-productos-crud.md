# HU-003 — Historia de Usuario: Gestión de productos (CRUD principal)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** `poma`  
**Trazabilidad:** Spec [SPEC-003](./specs/SPEC-003-gestion-productos-crud.md) | Flow [WF-003](./wireframes/flows/WF-003-gestion-productos-crud.md)  
**Contrato HTTP:** [`./api/openapi.yaml`](./api/openapi.yaml)  
**Catálogo de errores:** [`./api/catalogo-errores.md`](./api/catalogo-errores.md)

**Versión:** v1.1 — seguridad y errores armonizados

---

# Historia de usuario principal

**Como** gestor comercial,

**quiero** registrar, consultar, actualizar, activar, desactivar y reactivar productos, incluyendo los datos físicos de las unidades simples cuando corresponda,

**para** mantener un catálogo central consistente que pueda ser consumido por los canales de venta, Inventario, Pricing y Despacho sin mezclar responsabilidades.

Un producto atraviesa:

```text
BORRADOR -> ACTIVO -> INACTIVO
```

Un producto simple utiliza:

```text
sku_base = SKU vendible
```

y puede tener peso y dimensiones propias.

Un producto con variantes administra sus unidades vendibles en HU-004; el producto padre no representa una única unidad física.

---

# Criterios de aceptación

| ID | Criterio |
|---|---|
| **CA-01** | Solo un gestor comercial autorizado puede crear, modificar, activar, desactivar o reactivar productos. |
| **CA-02** | Para crear un producto en `BORRADOR` se requiere nombre, descripción, categoría, tipo de producto, marca, precio base inicial, `sku_base` y definición de si manejará variantes. |
| **CA-03** | Guardar un borrador no exige todavía imagen, completar todas las características obligatorias ni completar datos físicos. |
| **CA-04** | Categoría, tipo de producto y marca deben existir y encontrarse disponibles según las reglas de Catálogo/Taxonomía. |
| **CA-05** | La categoría sirve para clasificación; el tipo de producto define el esquema de características. |
| **CA-06** | `sku_base` es único globalmente y un duplicado bloquea la creación. |
| **CA-07** | Una coincidencia normalizada de nombre + marca genera advertencia de posible duplicado, pero permite continuar explícitamente si el SKU es distinto. |
| **CA-08** | La decisión simple/con variantes no se cambia mediante edición ordinaria una vez publicada la identidad correspondiente. |
| **CA-09** | Para un producto simple, `sku_base` funciona como SKU vendible. |
| **CA-10** | Para un producto con variantes, el padre no posee stock propio y sus unidades vendibles se administran en HU-004. |
| **CA-11** | Para activar un producto se validan categoría, tipo, marca, características obligatorias, al menos una imagen, preparación de Pricing e inicialización de Inventario. |
| **CA-12** | Si el producto maneja variantes, además necesita al menos una variante `ACTIVA` válida. |
| **CA-13** | Si el tipo de producto no tiene características obligatorias, el sistema no exige inventar una para activar. |
| **CA-14** | Una edición válida actualiza el producto y conserva trazabilidad. |
| **CA-15** | Si una edición de un producto activo rompe una condición de activación, el guardado se rechaza y se conserva la última versión válida. |
| **CA-16** | El producto activo puede desactivarse mediante baja lógica; no se elimina físicamente ni se pierden snapshots históricos. |
| **CA-17** | Un producto inactivo solo se reactiva después de volver a validar las condiciones de activación. |
| **CA-18** | El slug es mantenido por Catálogo. |
| **CA-19** | El precio base inicial se prepara en Pricing; posteriores cambios de precio no se editan desde este CRUD. |
| **CA-20** | Inventario es owner de `on_hand`, `reserved`, `available`, reservas y movimientos. Catálogo no persiste esas cantidades. |
| **CA-21** | Si se desactiva la última variante activa de un producto con variantes, el producto padre pasa también a `INACTIVO`. |
| **CA-22** | Para un producto simple, el gestor puede registrar un perfil físico asociado a su `sku_base`. |
| **CA-23** | El perfil físico utiliza Peso en kg y Largo/Ancho/Alto en cm. |
| **CA-24** | Los valores físicos informados deben ser numéricos mayores que cero. |
| **CA-25** | El perfil físico puede quedar sin registrar o incompleto en un borrador; el sistema no inventa valores cero. |
| **CA-26** | Modificar peso o dimensiones de un producto simple no modifica `sku_base`, slug ni identidad comercial. |
| **CA-27** | El perfil físico no se añade por sí solo como nueva condición de activación en esta versión. |
| **CA-28** | Para un producto con variantes, el CRUD principal no registra un perfil físico del padre; la UI dirige a la gestión de variantes. |
| **CA-29** | Despacho puede consultar en lote datos físicos de SKU simples y SKU de variantes mediante el mismo contrato externo. |
| **CA-30** | La consulta física para Despacho no devuelve stock, reservas, pedidos ni datos de pago. |
| **CA-31** | Productos y Ofertas no administra tipo de empaque, cantidad de paquetes, dimensiones finales del paquete ni volumen logístico final. |
| **CA-32** | Despacho es owner del empaque y de los cálculos logísticos finales. |
| **CA-33** | Cambios en perfil físico quedan trazables igual que otras ediciones relevantes del producto. |
| **CA-34** | Las barreras de baja segura de categoría, marca o valores relevantes impiden nuevas asociaciones mientras se verifica la operación. |
| **CA-35** | Los canales comerciales reciben únicamente productos elegibles según sus contratos; el backoffice puede consultar borradores e inactivos. |
| **CA-36** | Una operación protegida sin token utilizable responde `401 TOKEN_INVALIDO` y no modifica el producto. |
| **CA-37** | Una identidad autenticada sin autorización suficiente responde `403 SCOPE_INSUFICIENTE` y no modifica el producto. |
| **CA-38** | `SIN_AUTORIZACION` no se utiliza en nuevos contratos ni como código de branching del frontend. |

---

# Escenarios dado-cuando-entonces

## Escenario 1 — Registrar producto simple

- **DADO** un gestor autorizado,
- **CUANDO** registra un producto válido con `tiene_variantes=false`,
- **ENTONCES** el sistema lo crea en `BORRADOR`, genera su slug y trata `sku_base` como SKU vendible.

---

## Escenario 2 — Registrar producto con variantes

- **DADO** un gestor autorizado,
- **CUANDO** registra `tiene_variantes=true`,
- **ENTONCES** crea el producto padre en `BORRADOR`, pero no lo trata como una unidad física vendible.

---

## Escenario 3 — SKU base duplicado

- **DADO** un producto existente con SKU `BOT-750`,
- **CUANDO** se intenta crear otro producto con ese mismo SKU,
- **ENTONCES** se rechaza el registro.

---

## Escenario 4 — Posible duplicado por nombre y marca

- **DADO** un producto llamado “Botella térmica 750 ml” de marca “UrbanFit”,
- **CUANDO** se intenta crear otra referencia con igual nombre y marca pero SKU distinto,
- **ENTONCES** se muestra una advertencia y el gestor puede confirmar que es una referencia diferente.

---

## Escenario 5 — Guardar borrador incompleto para publicación

- **DADO** un producto con los datos mínimos de creación,
- **CUANDO** todavía no tiene imágenes, algunas características obligatorias o perfil físico,
- **ENTONCES** puede guardarse como `BORRADOR`.

---

## Escenario 6 — Activar producto completo

- **DADO** un borrador con categoría, tipo y marca válidos, características obligatorias completas, imagen, Pricing preparado e Inventario inicializado,
- **Y** una variante activa si corresponde,
- **CUANDO** el gestor solicita activarlo,
- **ENTONCES** pasa a `ACTIVO`.

---

## Escenario 7 — Rechazar activación incompleta

- **DADO** un producto que incumple una condición de activación,
- **CUANDO** se solicita activarlo,
- **ENTONCES** permanece en `BORRADOR` y se muestran los requisitos pendientes.

---

## Escenario 8 — Editar producto activo válidamente

- **DADO** un producto activo,
- **CUANDO** se modifica una descripción o dato permitido sin romper condiciones,
- **ENTONCES** se guarda y se registra trazabilidad.

---

## Escenario 9 — Rechazar edición que invalida producto activo

- **DADO** un producto activo,
- **CUANDO** una edición lo dejaría sin una condición obligatoria,
- **ENTONCES** se rechaza el cambio completo.

---

## Escenario 10 — Desactivar producto

- **DADO** un producto activo,
- **CUANDO** el gestor confirma su desactivación,
- **ENTONCES** pasa a `INACTIVO`, deja de ofrecerse para nuevas ventas y conserva histórico.

---

## Escenario 11 — Reactivar producto

- **DADO** un producto inactivo,
- **CUANDO** el gestor solicita reactivarlo,
- **ENTONCES** se revalidan todas las condiciones antes de volver a `ACTIVO`.

---

## Escenario 12 — Registrar perfil físico de producto simple

- **DADO** el producto simple `BOT-750`,
- **CUANDO** el gestor registra:
  - Peso `0.42 kg`;
  - Largo `8 cm`;
  - Ancho `8 cm`;
  - Alto `27 cm`,
- **ENTONCES** el sistema conserva esas propiedades para el SKU `BOT-750`.

---

## Escenario 13 — Perfil físico incompleto

- **DADO** un producto simple en borrador,
- **CUANDO** solo se conoce el peso,
- **ENTONCES** puede conservarse ese dato, se informa que el perfil está incompleto y no se rellenan dimensiones con cero.

---

## Escenario 14 — Rechazar físico inválido

- **DADO** un producto simple,
- **CUANDO** se registra peso o dimensión `<= 0`,
- **ENTONCES** el sistema rechaza ese dato y conserva el último perfil válido.

---

## Escenario 15 — Editar físico sin cambiar SKU

- **DADO** un producto simple con SKU `BOT-750`,
- **CUANDO** se corrige su peso,
- **ENTONCES** `BOT-750` no cambia y el perfil queda actualizado.

---

## Escenario 16 — Producto con variantes no usa físico del padre

- **DADO** un producto que maneja variantes,
- **CUANDO** el gestor abre su detalle o edición,
- **ENTONCES** no aparecen campos físicos del producto padre y se ofrece gestionar las variantes.

---

## Escenario 17 — Consulta física uniforme

- **DADO** que Despacho solicita un SKU simple y un SKU de variante,
- **CUANDO** realiza la consulta física en lote,
- **ENTONCES** recibe ambos mediante el mismo contrato externo sin conocer la estructura interna del catálogo.

---

## Escenario 18 — Despacho define empaque

- **DADO** un SKU con peso y dimensiones,
- **CUANDO** se prepara una entrega,
- **ENTONCES** Productos entrega únicamente propiedades físicas y Despacho decide empaque, agrupación y dimensiones finales.

---

## Escenario 19 — Token inválido

- **DADO** una operación protegida del CRUD,
- **CUANDO** la petición no puede autenticarse mediante un token utilizable,
- **ENTONCES** responde `401 TOKEN_INVALIDO` y no aplica cambios.

---

## Escenario 20 — Permisos insuficientes

- **DADO** una identidad autenticada,
- **CUANDO** intenta crear, editar, activar, desactivar o reactivar sin autorización suficiente,
- **ENTONCES** responde `403 SCOPE_INSUFICIENTE`, no aplica cambios y no necesita revelar el permiso exacto faltante.

---

# Interacción con otros módulos

| Módulo | Necesidad | Recibe Catálogo | Entrega Catálogo |
|---|---|---|---|
| **Marketplace** | Mostrar catálogo activo | Filtros/producto solicitado | Información comercial de productos elegibles |
| **Chatbot** | Buscar y describir productos | Criterios de búsqueda | Productos, atributos e identidad comercial |
| **Retail** | Consulta asistida de catálogo | SKU/producto/filtros | Detalle comercial y estado |
| **Ventas/Postventa** | Registrar el artículo vendido | Identidad de producto/SKU | Información de catálogo necesaria para snapshot |
| **Despacho** | Obtener características físicas de SKU | Lista de SKU | Peso, dimensiones y estado conforme a contrato |
| **Seguridad** | Autenticar y autorizar operaciones | Identidad/roles/permisos según contrato | `401 TOKEN_INVALIDO` o `403 SCOPE_INSUFICIENTE` cuando corresponde |

---

# Dependencias internas

| Componente | Relación |
|---|---|
| **Taxonomía** | Categorías, marcas, tipos y características |
| **Variantes / HU-004** | Unidades vendibles de productos con variantes |
| **Pricing** | Preparación del precio inicial y ownership posterior |
| **Inventario / HU-015** | Inicialización y saldo de SKU |
| **Bulk** | Puede crear/editar respetando las mismas reglas |
| **SEO** | Metadatos adicionales; Catálogo conserva el slug |

---

# Reglas consolidadas

1. Los productos se crean en `BORRADOR`.
2. `sku_base` es único.
3. Nombre+marca solo produce advertencia.
4. Categoría y tipo tienen responsabilidades diferentes.
5. `tiene_variantes` no se cambia ordinariamente.
6. Producto simple: `sku_base` es SKU vendible.
7. Producto con variantes: cada variante es unidad vendible.
8. Inventario es owner de stock.
9. Pricing es owner de precio vigente.
10. Catálogo es owner del perfil físico del SKU.
11. Producto simple registra perfil físico aquí.
12. Producto con variantes registra físico en HU-004.
13. kg y cm son las unidades contractuales.
14. Editar físico no cambia identidad.
15. Perfil físico no bloquea por sí solo la activación actual.
16. Despacho es owner del empaque.
17. Catálogo no expone stock mediante la consulta física.
18. Todas las operaciones relevantes son trazables.
19. `401` utiliza `TOKEN_INVALIDO`.
20. `403` utiliza `SCOPE_INSUFICIENTE`.
21. `SIN_AUTORIZACION` queda retirado de nuevos contratos.

---

# Criterio de completitud
- creación y edición funcionan;
- borrador no exige requisitos de publicación;
- activación valida requisitos;
- desactivación/reactivación funcionan;
- `sku_base` es único;
- posible duplicado nombre+marca es advertencia;
- producto simple usa `sku_base` como SKU vendible;
- producto con variantes delega a HU-004;
- producto simple permite registrar peso y dimensiones;
- valores físicos inválidos se rechazan;
- valores desconocidos no se sustituyen por cero;
- editar físico conserva SKU;
- la UI no ofrece físico del padre con variantes;
- Despacho puede consumir físico de SKU simples y variantes;
- Productos no administra empaque;
- stock y precio mantienen ownership correcto;
- trazabilidad incluye cambios físicos;
- 401 usa `TOKEN_INVALIDO`;
- 403 usa `SCOPE_INSUFICIENTE`;
- `SIN_AUTORIZACION` no se utiliza en nuevos contratos.
