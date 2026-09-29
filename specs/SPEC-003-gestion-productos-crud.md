# SPEC-003 — Especificación: Gestión de productos (CRUD principal)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** `poma`  
**Trazabilidad:** HU [HU-003](./hu/HU-003-gestion-productos-crud.md) | Wireframe [WF-003](./wireframes/flows/WF-003-gestion-productos-crud.md)  
**Contrato HTTP:** [`./api/openapi.yaml`](./api/openapi.yaml)  
**Contrato de integración:** [`./Contrato_Api.md`](./Contrato_Api.md)  
**Arquitectura:** [`./Arquitectura.md`](./Arquitectura.md)  
**Modelo conceptual:** [`./Modelo_Conceptual.md`](./Modelo_Conceptual.md)  
**Catálogo de errores:** [`./api/catalogo-errores.md`](./api/catalogo-errores.md)

**Versión:** v3.1 — seguridad y códigos de error armonizados

> **Cambios principales de esta versión**
>
> - se conserva el ciclo `BORRADOR → ACTIVO → INACTIVO`;
> - `sku_base` sigue siendo identificador único del producto y, en productos simples, también el SKU vendible;
> - se incorpora el **perfil físico del SKU vendible de productos simples**;
> - se definen peso en kg y dimensiones en cm;
> - los productos con variantes delegan su perfil físico a cada SKU de variante en `SPEC-004`;
> - se explicita que Productos y Ofertas no es dueño del empaque;
> - la consulta física en lote para Despacho trata uniformemente SKU simples y SKU de variantes;
> - el perfil físico no se convierte automáticamente en una nueva condición de activación mientras no exista una decisión funcional que así lo establezca;
- la autenticación/autorización HTTP se alinea con el contrato oficial de Seguridad: `TOKEN_INVALIDO` y `SCOPE_INSUFICIENTE`.

---

# 1. Contexto

Productos y Ofertas es la fuente de verdad de la información de catálogo del Marketplace Multicanal. Los demás módulos consumen esta información mediante contratos de integración y no acceden directamente a las tablas del módulo.

El CRUD principal administra la entidad **Producto** y su ciclo de vida. Un producto puede ser:

```text
Producto simple
tiene_variantes = false
```

o:

```text
Producto con variantes
tiene_variantes = true
```

La diferencia es relevante para la identidad vendible:

### Producto simple

```text
sku_base = SKU vendible
```

El propio producto representa la unidad comercial que consumen Pricing, Inventario, Ventas y Despacho.

### Producto con variantes

```text
sku_base = identidad base/agregadora
```

El producto padre no posee stock propio. Cada variante tiene un SKU comercial y su información física se administra en `SPEC-004`.

El stock continúa siendo propiedad exclusiva de Inventario.

---

# 2. Propósito

Permitir al gestor comercial administrar el ciclo de vida completo de los productos:

- creación;
- consulta;
- edición;
- activación;
- desactivación;
- reactivación;

manteniendo integridad de catálogo, trazabilidad y separación clara de ownership entre:

- Catálogo;
- Pricing;
- Inventario;
- Variantes;
- Despacho.

Para productos simples, Catálogo también mantiene las propiedades físicas intrínsecas de su SKU vendible.

---

# 3. Alcance

Incluye:

1. creación de productos en estado `BORRADOR`;
2. nombre y descripción;
3. categoría de navegación;
4. tipo de producto;
5. marca;
6. precio base inicial para preparación en Pricing;
7. `sku_base`;
8. bandera `tiene_variantes`;
9. características y valores del producto;
10. imágenes;
11. slug;
12. activación;
13. desactivación lógica;
14. reactivación;
15. perfil físico del SKU vendible cuando el producto es simple;
16. exposición de datos físicos de SKU para Despacho;
17. coordinación con Inventario y Pricing;
18. barreras de baja segura de entidades maestras.

---

# 4. Modelo de producto y SKU vendible

## 4.1. Producto simple

Para:

```text
tiene_variantes = false
```

se cumple:

```text
sku_base = SKU vendible
```

Por tanto:

- Pricing puede asociar precio al producto/SKU según su contrato;
- Inventario mantiene saldo para `sku_base`;
- Despacho puede consultar su perfil físico;
- no se crea una variante artificial para representar el producto simple.

---

## 4.2. Producto con variantes

Para:

```text
tiene_variantes = true
```

el producto padre no constituye una unidad física vendible.

Las unidades vendibles son sus variantes.

Por tanto:

- el producto padre no posee stock;
- el producto padre no posee un perfil físico autoritativo único;
- peso y dimensiones se registran por variante en `SPEC-004`;
- Despacho consulta los SKU de variante.

---

# 5. Requisito 1 — Crear producto en borrador

El sistema DEBE permitir registrar un producto con:

- nombre;
- descripción;
- categoría de navegación;
- tipo de producto;
- marca;
- precio base inicial;
- `sku_base`;
- `tiene_variantes`.

El producto se crea en:

```text
BORRADOR
```

y recibe:

- identificador interno;
- slug;
- fecha de creación.

No se exige para guardar el borrador:

- imagen;
- completar características obligatorias;
- completar perfil físico.

---

## 5.1. `tiene_variantes`

La elección se realiza al crear.

No se modifica mediante el CRUD ordinario cuando exista identidad comercial publicada o variantes registradas.

Cambiar entre producto simple y producto con variantes es una migración estructural porque afecta:

- SKU;
- Inventario;
- Pricing;
- perfiles físicos;
- referencias externas.

---

## 5.2. SKU base

`sku_base` debe:

- existir al crear;
- cumplir el formato contractual;
- ser único globalmente;
- permanecer estable mediante edición ordinaria.

Para un producto simple es, además, el SKU vendible.

---

## Escenario — Crear producto simple

**DADO** un gestor autorizado

**CUANDO** registra un producto válido con:

```text
tiene_variantes = false
```

**ENTONCES** el sistema:

1. crea el producto en `BORRADOR`;
2. genera identificador y slug;
3. conserva `sku_base` como SKU vendible;
4. inicia la preparación de Pricing;
5. coordina la inicialización del SKU en Inventario.

---

## Escenario — Crear producto con variantes

**DADO** un gestor autorizado

**CUANDO** registra:

```text
tiene_variantes = true
```

**ENTONCES** se crea el producto padre en `BORRADOR`, pero no se crea un saldo físico del producto padre como si fuera una unidad vendible.

Las variantes se administran en `SPEC-004`.

---

# 6. Requisito 2 — Duplicados

## 6.1. SKU duplicado

Si otro producto utiliza el mismo `sku_base`, la creación se rechaza.

Código conceptual:

```text
SKU_DUPLICADO
```

---

## 6.2. Posible duplicado por nombre y marca

La combinación normalizada:

```text
(nombre, marca)
```

es una advertencia, no una clave empresarial bloqueante.

El gestor puede continuar si confirma que es una referencia distinta y el SKU es diferente.

---

# 7. Requisito 3 — Categoría y tipo de producto

La categoría se utiliza para:

```text
navegación / clasificación
```

El tipo de producto define:

```text
esquema de características
```

La categoría no hereda ni define características.

Un cambio de categoría no debe alterar automáticamente:

- características identificadoras;
- SKU;
- variantes.

Un cambio incompatible de tipo de producto después de publicar identidad requiere una migración explícita.

---

# 8. Requisito 4 — Características

Para activar un producto deben estar completos todos los valores marcados como obligatorios por su tipo de producto.

Si el tipo no tiene características obligatorias:

```text
no se inventa una característica para activar
```

Los atributos opcionales continúan siendo opcionales.

---

# 9. Requisito 5 — Imágenes

Un producto puede guardarse en `BORRADOR` sin imagen.

Para activar:

```text
al menos una imagen válida
```

La sustitución de una imagen debe mantener la anterior hasta confirmar correctamente el nuevo guardado.

---

# 10. Requisito 6 — Precio base inicial

Durante la creación, Catálogo recibe un precio base inicial para preparar Pricing.

Catálogo envía una operación idempotente a Pricing con contexto suficiente.

La creación del borrador no implica que el precio ya esté listo.

Pricing es owner de:

- precio;
- vigencia;
- historial;
- posteriores modificaciones.

El evento de cambio de precio lo publica Pricing después de persistir.

---

# 11. Requisito 7 — Inicialización de Inventario

## Producto simple

Al crear el SKU vendible:

```text
sku_base
```

Inventario puede inicializarlo idempotentemente con su estado inicial definido en `SPEC-015`.

Catálogo no almacena:

```text
on_hand
reserved
available
stock_version
```

## Producto con variantes

La inicialización ocurre por cada SKU de variante.

No se inicializa un saldo vendible independiente para el producto padre.

---

# 12. Requisito 8 — Perfil físico del producto simple

Para:

```text
tiene_variantes = false
```

Catálogo puede mantener un perfil físico asociado al `sku_base`.

Campos contractuales:

```text
pesoKg
largoCm
anchoCm
altoCm
actualizadoEn
```

Representación HTTP conceptual:

```json
{
  "sku": "BOT-750",
  "estado": "ACTIVO",
  "pesoKg": 0.42,
  "dimensionesCm": {
    "largo": 8,
    "ancho": 8,
    "alto": 27
  },
  "actualizadoEn": "2026-09-28T16:00:00Z"
}
```

La forma HTTP exacta pertenece a OpenAPI.

---

# 13. Requisito 8.1 — Unidades

Las unidades contractuales son:

```text
peso       -> kilogramos
dimensiones -> centímetros
```

No se utiliza selector de unidad en el contrato.

Los consumidores no deben inferir unidades.

---

# 14. Requisito 8.2 — Validaciones físicas

Cuando se registra un perfil completo:

```text
pesoKg > 0
largoCm > 0
anchoCm > 0
altoCm > 0
```

No se aceptan como valores físicos válidos:

- cero;
- negativos;
- texto no numérico.

Los decimales son válidos.

Ejemplo:

```text
pesoKg = 0.25
altoCm = 3.5
```

---

# 15. Requisito 8.3 — Perfil físico incompleto

Un producto puede permanecer en `BORRADOR` mientras se completan sus datos físicos.

No se deben inventar:

```text
0 kg
0 cm
```

para representar datos desconocidos.

La ausencia o incompletitud debe conservarse explícitamente.

En esta versión, el perfil físico **no se añade automáticamente como bloqueo general de activación**, porque esa regla no ha sido definida como condición funcional de publicación.

Si posteriormente se exige perfil físico obligatorio para activar, SPEC/HU/WF deberán actualizarse de forma explícita.

---

# 16. Requisito 8.4 — Edición de perfil físico

Modificar:

- peso;
- largo;
- ancho;
- alto;

NO modifica:

- `product_id`;
- `sku_base`;
- slug;
- identidad comercial;
- estado por sí mismo.

La edición debe registrar trazabilidad.

---

## Escenario — Corregir peso

**DADO** un producto simple con:

```text
peso = 0.45 kg
```

**CUANDO** el gestor corrige a:

```text
0.42 kg
```

**ENTONCES**:

- el perfil se actualiza;
- el SKU permanece igual;
- `actualizadoEn` cambia;
- futuras consultas físicas reciben el nuevo valor.

---

# 17. Requisito 8.5 — Producto con variantes

Si:

```text
tiene_variantes = true
```

el CRUD principal NO presenta un perfil físico del producto padre como si representara todas las variantes.

Debe indicar que los datos físicos se gestionan por variante.

La administración corresponde a:

```text
SPEC-004 / WF-004
```

---

# 18. Requisito 9 — Ownership del empaque

Los datos físicos de Productos representan propiedades propias de la unidad vendible.

NO representan:

- caja;
- bolsa;
- pallet;
- agrupación;
- cantidad de paquetes;
- dimensiones finales del paquete;
- volumen logístico final.

Estos conceptos pertenecen a **Despacho y Entrega**.

Productos no debe persistir:

```text
tipoEmpaque
cantidadPaquetes
volumenLogisticoFinal
```

como datos propios del SKU.

---

# 19. Requisito 10 — Consulta física para Despacho

Despacho puede consultar varios SKU en una sola solicitud.

Contrato:

```http
POST /api/v1/productos/datos-fisicos/consulta
```

La consulta trata de forma uniforme:

- `sku_base` de productos simples;
- SKU de variantes.

Consumidor previsto:

```text
modulo-despacho
```

Scope propuesto:

```text
productos:fisicos:leer
```

Su registro definitivo corresponde al acuerdo con Seguridad.

---

# 20. Requisito 10.1 — Respuesta de datos físicos

La respuesta debe permitir distinguir:

- SKU encontrados;
- SKU no encontrados.

Para un SKU con perfil utilizable puede incluir:

```text
sku
estado
pesoKg
dimensionesCm
actualizadoEn
```

La representación de un SKU existente pero con perfil incompleto debe seguir el contrato técnico publicado; la SPEC no debe inventar una forma incompatible con OpenAPI.

---

# 21. Requisito 10.2 — Sin stock ni pedidos

La consulta física NO expone:

```text
stock
reservas
on_hand
reserved
available
pedido
pago
cliente
```

Despacho consulta Inventario o los módulos correspondientes cuando otra información esté dentro de su flujo.

---

# 22. Requisito 11 — Activación

Un producto `BORRADOR` pasa a `ACTIVO` únicamente cuando se validan las condiciones funcionales vigentes:

1. datos mínimos;
2. categoría activa;
3. tipo de producto activo;
4. marca activa;
5. características obligatorias completas;
6. al menos una imagen;
7. Pricing preparado;
8. Inventario inicializado para los SKU vendibles;
9. si maneja variantes, al menos una variante `ACTIVA` válida.

El perfil físico no se agrega como condición adicional automática en esta versión.

---

# 23. Requisito 12 — Edición

El gestor puede editar los campos permitidos del producto.

Para productos simples también puede editar el perfil físico.

No se permite mediante edición ordinaria:

- cambiar `tiene_variantes` después de publicar identidad;
- recodificar `sku_base`;
- transformar estructuralmente el tipo cuando afecta identidad;
- modificar precio posterior como si Catálogo fuera owner.

Si una edición sobre un producto activo rompe una condición de activación, se rechaza la operación completa y se conserva la última versión válida.

---

# 24. Requisito 13 — Consulta

El sistema permite:

- listado administrativo;
- detalle administrativo;
- consulta por identificador;
- consulta por slug;
- filtros básicos por categoría, marca y estado.

Los canales comerciales solo reciben productos elegibles según los contratos correspondientes.

Para un producto con variantes, el detalle puede incluir las variantes/SKU según el contrato publicado.

---

# 25. Requisito 14 — Desactivación

La baja es lógica.

Al desactivar:

```text
ACTIVO -> INACTIVO
```

el producto:

- deja de ofrecerse para nuevas ventas;
- conserva su información;
- conserva referencias históricas;
- publica `catalog.product.deactivated` después del commit.

Los pedidos confirmados mantienen snapshot.

---

# 26. Requisito 15 — Reactivación

Para:

```text
INACTIVO -> ACTIVO
```

se revalidan todas las condiciones de activación.

La reactivación no es un cambio de estado incondicional.

---

# 27. Requisito 16 — Última variante activa

Si se desactiva la última variante `ACTIVA` de un producto con variantes:

- Catálogo inactiva el producto padre en la misma transacción local;
- se conservan snapshots históricos.

Para reactivar el padre debe volver a existir una variante elegible y cumplirse las demás condiciones.

---

# 28. Requisito 17 — Barreras de entidades maestras

Durante una baja segura de:

- categoría;
- marca;
- valor LISTA requerido/identificador;

Catálogo instala o respeta barreras locales.

Mientras la verificación está en curso no debe crear, activar ni reasignar nuevos productos hacia una entidad bloqueada.

Un fallo de comunicación no autoriza silenciosamente la operación.

---

# 29. Slug

Catálogo es owner del slug del producto.

El slug:

- se genera y mantiene en Catálogo;
- sirve como identidad amigable de navegación;
- no es reemplazado por Taxonomía.

Los metadatos SEO adicionales pertenecen al componente correspondiente.

---

# 30. Datos que pertenecen a Catálogo

Para Producto:

```text
product_id
nombre
descripcion
categoria_ref
tipo_producto_ref
marca_ref
sku_base
tiene_variantes
slug
estado
atributos
imagenes
```

Para un SKU simple:

```text
pesoKg
largoCm
anchoCm
altoCm
actualizadoEn
```

---

# 31. Datos que NO pertenecen a Catálogo

## Pricing

```text
precio vigente
precio oferta
vigencias
price_version
```

## Inventario

```text
on_hand
reserved
available
stock_version
reservas
Kardex
```

## Despacho

```text
tipoEmpaque
cantidadPaquetes
dimensiones finales del paquete
volumen logístico final
ruta
vehículo
repartidor
```

## Ventas/Postventa

```text
pedido
pago
reembolso
estado comercial del pedido
```

---

# 32. Integración con productos simples y variantes

La consulta física se resuelve conceptualmente así:

```text
SKU recibido
   |
   +-- corresponde a producto simple
   |      -> perfil físico del sku_base
   |
   +-- corresponde a variante
          -> perfil físico de la variante
```

El consumidor no necesita conocer internamente cuál tabla/responsabilidad local resolvió el SKU.

---

# 33. Requisitos no funcionales

## Rendimiento

- listados paginables;
- detalle eficiente;
- consulta física de Despacho en lote;
- evitar una llamada por SKU.

## Seguridad

Las mutaciones requieren una identidad autenticada y autorización de gestor comercial conforme al contrato vigente de Seguridad.

Las respuestas HTTP de autenticación/autorización se normalizan como:

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

`TOKEN_INVALIDO` se utiliza cuando la petición no puede autenticarse mediante un token utilizable.

`SCOPE_INSUFICIENTE` se utiliza cuando la identidad está autenticada pero no posee la autorización requerida para la operación.

El nombre del código `SCOPE_INSUFICIENTE` pertenece al contrato adoptado de Seguridad y no obliga a exponer en la respuesta pública el permiso/scope concreto faltante.

La consulta física servicio-a-servicio requiere identidad técnica autorizada.

Para:

```text
POST /api/v1/productos/datos-fisicos/consulta
```

el permiso propuesto continúa siendo:

```text
productos:fisicos:leer
```

hasta que Seguridad registre/homologue definitivamente ese permiso. La provisionalidad del nombre del permiso no cambia los códigos HTTP `401` y `403`.

## Auditoría

Registrar:

- creación;
- edición;
- cambio de estado;
- cambio de imágenes;
- cambio de perfil físico.

## Disponibilidad

Las APIs de lectura de catálogo son críticas para los canales.

## Escalabilidad

La implementación debe soportar crecimiento de:

- productos;
- variantes;
- SKU;
- consumidores.

---

# 34. Errores y códigos de aplicación

El catálogo canónico de códigos pertenece a:

```text
api/catalogo-errores.md
```

Códigos relevantes para esta capacidad:

```text
VALIDACION
TOKEN_INVALIDO
SCOPE_INSUFICIENTE
PRODUCTO_NO_ENCONTRADO
SKU_DUPLICADO
CATEGORIA_INVALIDA
TIPO_PRODUCTO_INVALIDO
MARCA_INVALIDA
DATOS_INCOMPLETOS
PERFIL_FISICO_INVALIDO
DATOS_FISICOS_INCOMPLETOS
CAMBIO_ESTRUCTURAL_NO_PERMITIDO
VERSION_CONFLICT
ERROR_INTERNO
SERVICIO_NO_DISPONIBLE
```

La representación HTTP pertenece a OpenAPI y utiliza:

```text
application/problem+json
```

Los consumidores deben ramificar por `code`, no por `title` ni `detail`.

El código histórico:

```text
SIN_AUTORIZACION
```

queda retirado de nuevos contratos. Su reemplazo es:

```text
SCOPE_INSUFICIENTE
```

cuando la identidad está autenticada pero carece de autorización suficiente.

---

# 35. Escenarios de perfil físico

## Escenario A — Registrar físico en producto simple

**DADO** un producto simple `BOT-750`

**CUANDO** el gestor registra:

```text
peso = 0.42 kg
largo = 8 cm
ancho = 8 cm
alto = 27 cm
```

**ENTONCES** Catálogo asocia esos valores al SKU `BOT-750`.

---

## Escenario B — Producto simple sin físico

**DADO** un borrador simple

**CUANDO** todavía no se conocen sus medidas

**ENTONCES** el sistema permite conservar el perfil sin registrar y no inventa valores cero.

---

## Escenario C — Producto con variantes

**DADO** un producto con variantes

**CUANDO** el gestor abre el CRUD del producto padre

**ENTONCES** no se muestran campos físicos del padre y se indica que se gestionan por variante.

---

## Escenario D — Peso inválido

**DADO** un producto simple

**CUANDO** se intenta registrar:

```text
peso = -0.5 kg
```

**ENTONCES** el sistema rechaza el dato físico.

---

## Escenario E — Consulta física de Despacho

**DADO** una consulta con:

```text
BOT-750
ZAP-PSX-42-NEG
```

donde el primero es producto simple y el segundo variante,

**CUANDO** Despacho consulta el lote

**ENTONCES** Catálogo resuelve ambos SKU mediante el mismo contrato externo.

---

## Escenario F — Token no válido

**DADO** una operación protegida del CRUD

**CUANDO** la petición no contiene un token utilizable según el contrato de Seguridad

**ENTONCES** la API responde:

```text
401
TOKEN_INVALIDO
```

sin ejecutar la mutación.

---

## Escenario G — Identidad sin autorización suficiente

**DADO** una identidad autenticada

**CUANDO** intenta ejecutar una operación para la que no está autorizada

**ENTONCES** la API responde:

```text
403
SCOPE_INSUFICIENTE
```

sin ejecutar la mutación y sin necesidad de revelar el permiso exacto faltante.

---

# 36. Fuera de alcance

- Gestión de variantes: `SPEC-004`.
- Stock y reservas: `SPEC-015`.
- Cambios posteriores de precio: Pricing.
- Promociones y cupones.
- Combos.
- Metadatos SEO adicionales.
- Empaque y optimización logística.
- Pedidos y pagos.
- Eliminación física.
- Conversión ordinaria entre producto simple y producto con variantes.

---

# 37. Criterio de completitud

La capacidad se considera implementada cuando:
- creación BORRADOR funciona;
- `sku_base` es único;
- nombre+marca produce advertencia y no falsa unicidad bloqueante;
- categoría, marca y tipo se validan;
- características obligatorias se validan al activar;
- imágenes se validan al activar;
- Pricing e Inventario participan conforme a ownership;
- activación, desactivación y reactivación funcionan;
- productos con variantes delegan a SPEC-004;
- productos simples usan `sku_base` como SKU vendible;
- productos simples pueden registrar perfil físico;
- perfil físico utiliza kg/cm;
- peso y dimensiones se validan;
- perfil físico no cambia identidad;
- no existe perfil físico autoritativo en el padre con variantes;
- consulta física en lote resuelve SKU simples y variantes;
- Productos no define empaque;
- stock no se persiste en Catálogo;
- trazabilidad incluye cambios físicos;
- respuestas protegidas usan `TOKEN_INVALIDO` para 401;
- respuestas protegidas usan `SCOPE_INSUFICIENTE` para 403;
- `SIN_AUTORIZACION` no se emite en contratos nuevos;
- contratos implementados coinciden con OpenAPI y `api/catalogo-errores.md`.
