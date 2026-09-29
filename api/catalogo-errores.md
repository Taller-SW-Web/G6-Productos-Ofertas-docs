# Catálogo de errores y rechazos — Productos y Ofertas

**Fuente HTTP canónica:** [`openapi.yaml`](openapi.yaml)  
**Fuente asíncrona canónica:** [`./asyncapi/asyncapi.yaml`](./asyncapi/asyncapi.yaml)  
**Catálogo de eventos:** [`catalogo-eventos.md`](catalogo-eventos.md)  
**Contrato general:** [`./Contrato_Api.md`](./Contrato_Api.md)  
**Reglas de negocio:** `./specs/`

**Versión:** `0.2.4-p0`  
**Última actualización:** `2026-09-29`

---

## 1. Propósito

Este documento centraliza los códigos estables de error y rechazo del módulo **Productos y Ofertas**.

Su objetivo es evitar que cada microservicio, SPEC o consumidor invente nombres distintos para la misma causa y permitir que:

- frontend y otros módulos ramifiquen por `code`;
- los mensajes HTTP mantengan `application/problem+json`;
- los resultados asíncronos utilicen los mismos códigos cuando representen la misma causa;
- las pruebas de contrato validen un catálogo único;
- observabilidad y soporte puedan agrupar fallos sin depender del texto humano.

La regla principal es:

```text
La máquina usa code.
La persona puede leer title/detail.
```

Nunca se debe implementar lógica de negocio comparando `title`, `detail` o mensajes visuales.

---

# 2. Modelo HTTP de error

El contrato HTTP utiliza RFC 7807 mediante:

```text
Content-Type: application/problem+json
```

Forma canónica:

```json
{
  "type": "/errores/stock-insuficiente",
  "title": "Stock insuficiente",
  "status": 409,
  "detail": "No existe disponibilidad suficiente para completar la operación.",
  "instance": "/api/v1/inventario/reservas",
  "code": "STOCK_INSUFICIENTE",
  "correlationId": "0c0d092e-6192-47c1-8d18-5ed0e2aa4518",
  "details": {
    "sku": "ZAP-PSX-42-NEG",
    "location_id": "DEFAULT",
    "requested": 3,
    "available": 2
  }
}
```

## 2.1. Campos

| Campo | Regla |
|---|---|
| `type` | URI-reference estable para la familia del problema. |
| `title` | Resumen humano relativamente estable. |
| `status` | Código HTTP de esta respuesta. |
| `detail` | Explicación humana de la ocurrencia concreta. No es contrato para branching. |
| `instance` | Referencia de la petición o recurso involucrado. |
| `code` | **Código estable de aplicación. Es el campo que consume la lógica cliente.** |
| `correlationId` | Correlación extremo a extremo para soporte y trazabilidad. |
| `details` | Datos estructurados seguros y específicos del error. |

`title`, `detail` y `details` no deben exponer:

- tokens;
- secretos;
- SQL;
- stack traces;
- nombres de tablas;
- rutas internas del servidor;
- datos personales innecesarios;
- scopes sensibles que Seguridad haya decidido no revelar.

---

# 3. Códigos en mensajería asíncrona

Cuando un `result` asíncrono es rechazado, debe reutilizar el mismo `code` si la causa semántica es la misma.

Ejemplo:

```json
{
  "kind": "result",
  "name": "inventory.consumption.rejected",
  "schema_version": 1,
  "operation_id": "e8463fc0-c4ac-4d27-b707-58495a3a20c6",
  "correlation_id": "0c0d092e-6192-47c1-8d18-5ed0e2aa4518",
  "data": {
    "order_id": "PED-001",
    "reservation_id": "res-01JXYZ",
    "operation_type": "CONFIRMAR_CONSUMO",
    "code": "RESERVA_EXPIRADA",
    "detail": "La reserva ya no se encuentra activa.",
    "rejected_at": "2026-09-28T16:20:00Z"
  }
}
```

No crear variantes como:

```text
HTTP_STOCK_INSUFICIENTE
EVENT_STOCK_INSUFICIENTE
ASYNC_STOCK_INSUFICIENTE
```

La causa es una sola:

```text
STOCK_INSUFICIENTE
```

---

# 4. Estados de este catálogo

Cada código tiene un estado contractual.

| Estado | Significado |
|---|---|
| `DOCUMENTADO` | El nombre ya aparece explícitamente en una SPEC o contrato externo adoptado. |
| `CANONICO_P0` | El fallo está definido por las reglas actuales, pero su nombre se centraliza por primera vez en este catálogo. |
| `DEPRECATED_ALIAS` | Nombre existente que no debe utilizarse en nuevos contratos. |
| `PENDIENTE` | Semántica aún no suficientemente homologada para declararla estable. |

Los códigos `CANONICO_P0` pasan a formar parte del contrato del módulo cuando este catálogo sea aceptado y publicado junto con OpenAPI/AsyncAPI.

---

# 5. Convenciones de nombres

Formato:

```text
SCREAMING_SNAKE_CASE
```

Reglas:

1. nombrar la **causa**, no la capa técnica;
2. no incluir `HTTP_`, `API_`, `DB_`, `RABBIT_` ni nombre del microservicio;
3. no reutilizar un código para causas diferentes;
4. evitar códigos excesivamente genéricos cuando el consumidor necesita distinguir la causa;
5. no codificar el status HTTP en el nombre;
6. un cambio de texto humano no cambia el `code`;
7. un código publicado no cambia de significado.

Correcto:

```text
SKU_DUPLICADO
RESERVA_EXPIRADA
VIGENCIA_SUPERPUESTA
```

Incorrecto:

```text
ERROR_409
BAD_REQUEST
DATABASE_ERROR
INVENTORY_ERROR
```

---

# 6. Semántica HTTP

| HTTP | Uso en Productos y Ofertas |
|---:|---|
| `400` | Petición mal formada, campo obligatorio ausente o validación básica del request. |
| `401` | Token ausente/inválido. |
| `403` | Identidad válida sin autorización suficiente. |
| `404` | Recurso identificable inexistente o deliberadamente no expuesto. |
| `409` | Conflicto con el estado actual, unicidad, concurrencia o transición de estado. |
| `413` | Archivo excede el límite contractual. |
| `422` | Request sintácticamente válido pero semánticamente incompatible con una regla del dominio. |
| `500` | Fallo inesperado del servicio. |
| `503` | Servicio o dependencia necesaria temporalmente no disponible. |

No se debe usar `500` para una regla de negocio conocida.

---

# 7. Errores transversales

| Code | HTTP | Estado | Cuándo usarlo |
|---|---:|---|---|
| `VALIDACION` | 400 | `DOCUMENTADO` | Falta un campo, tipo/formato básico incorrecto o valor fuera de un catálogo cerrado del request. Adoptado del contrato de Seguridad. |
| `TOKEN_INVALIDO` | 401 | `DOCUMENTADO` | Token ausente, inválido o no utilizable para autenticar. |
| `SCOPE_INSUFICIENTE` | 403 | `DOCUMENTADO` | Token válido sin scope/permiso suficiente. No revelar necesariamente el scope faltante. |
| `VERSION_CONFLICT` | 409 | `DOCUMENTADO` | La versión esperada ya no coincide con la vigente. Se utiliza en Catálogo, Pricing e Inventario cuando aplique. |
| `IDEMPOTENCY_CONFLICT` | 409 | `CANONICO_P0` | La misma identidad idempotente fue reutilizada con un payload semánticamente diferente. |
| `ERROR_INTERNO` | 500 | `CANONICO_P0` | Error inesperado no cubierto por una causa funcional conocida. |
| `SERVICIO_NO_DISPONIBLE` | 503 | `CANONICO_P0` | El servicio o una dependencia indispensable no puede atender temporalmente la operación. |

## 7.1. Autorización

Las SPEC-003 y SPEC-004 actualmente mencionan conceptualmente:

```text
SIN_AUTORIZACION
```

El módulo ya adoptó el contrato oficial de Seguridad, cuyo código es:

```text
SCOPE_INSUFICIENTE
```

Por tanto:

| Code | Estado | Sustitución |
|---|---|---|
| `SIN_AUTORIZACION` | `DEPRECATED_ALIAS` | `SCOPE_INSUFICIENTE` |

No publicar `SIN_AUTORIZACION` en nuevas APIs ni eventos.

---

# 8. Catálogo / Productos

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `PRODUCTO_NO_ENCONTRADO` | 404 | `DOCUMENTADO` | No existe el producto solicitado o no es visible para el contexto autorizado. |
| `SKU_DUPLICADO` | 409 | `DOCUMENTADO` | El SKU solicitado ya pertenece a otra unidad vendible. |
| `CATEGORIA_INVALIDA` | 422 | `DOCUMENTADO` | La categoría no puede utilizarse para la operación solicitada. |
| `TIPO_PRODUCTO_INVALIDO` | 422 | `DOCUMENTADO` | El tipo de producto informado no puede utilizarse por estado o incompatibilidad con la operación; no representa un recurso de path inexistente. |
| `MARCA_INVALIDA` | 422 | `DOCUMENTADO` | La marca no existe, está inactiva o no puede utilizarse. |
| `DATOS_INCOMPLETOS` | 422 | `DOCUMENTADO` | Faltan datos funcionales requeridos para una transición como activación. |
| `CAMBIO_ESTRUCTURAL_NO_PERMITIDO` | 409 | `DOCUMENTADO` | Se intenta cambiar mediante CRUD ordinario una decisión estructural ya publicada, por ejemplo simple ↔ variantes. |
| `PERFIL_FISICO_INVALIDO` | 422 | `DOCUMENTADO` | Peso o dimensiones contienen valores inválidos. |
| `DATOS_FISICOS_INCOMPLETOS` | 422 | `DOCUMENTADO` | El consumidor requiere un perfil físico utilizable y el SKU no tiene todos los datos requeridos. |

## 8.1. Ejemplo — perfil físico inválido

```json
{
  "type": "/errores/perfil-fisico-invalido",
  "title": "Datos físicos inválidos",
  "status": 422,
  "code": "PERFIL_FISICO_INVALIDO",
  "correlationId": "0c0d092e-6192-47c1-8d18-5ed0e2aa4518",
  "details": {
    "field": "peso",
    "constraint": "greater_than_zero"
  }
}
```

La UI puede mostrar:

```text
Ingresa un peso mayor que 0.
```

pero esa frase no forma parte del contrato de máquina.

---

# 9. Variantes y SKU

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `VARIANTE_NO_ENCONTRADA` | 404 | `DOCUMENTADO` | La variante solicitada no existe. |
| `PRODUCTO_NO_ADMITE_VARIANTES` | 409 | `DOCUMENTADO` | Se intenta crear/gestionar variantes en un producto simple. |
| `COMBINACION_DUPLICADA` | 409 | `DOCUMENTADO` | Ya existe la misma combinación de atributos identificadores para el producto. |
| `SKU_INVALIDO` | 422 | `DOCUMENTADO` | El SKU informado no cumple el formato/semántica permitidos. |
| `ATRIBUTO_IDENTIFICADOR_INVALIDO` | 422 | `DOCUMENTADO` | Un valor identificador no pertenece al esquema válido de la variante. |
| `IMAGEN_INVALIDA` | 422 | `DOCUMENTADO` | La imagen no cumple las reglas de archivo aplicables. |
| `SKU_DUPLICADO` | 409 | `DOCUMENTADO` | Unicidad global de SKU violada. |
| `PERFIL_FISICO_INVALIDO` | 422 | `DOCUMENTADO` | Perfil físico inválido. |
| `DATOS_FISICOS_INCOMPLETOS` | 422 | `DOCUMENTADO` | Perfil físico existente pero no utilizable para una consulta que requiere completitud. |

No crear códigos separados por cada dimensión:

```text
PESO_INVALIDO
LARGO_INVALIDO
ANCHO_INVALIDO
ALTO_INVALIDO
```

El contrato usa:

```text
PERFIL_FISICO_INVALIDO
```

y especifica el campo en `details`.

---

# 10. Inventario

| Code | HTTP / resultado | Estado | Semántica |
|---|---:|---|---|
| `SKU_NO_ENCONTRADO` | 404 | `DOCUMENTADO` | El SKU no existe en Inventario/Catálogo para la operación. |
| `UBICACION_NO_ENCONTRADA` | 404 | `DOCUMENTADO` | La ubicación solicitada no existe o no es válida. |
| `CANTIDAD_INVALIDA` | 422 | `DOCUMENTADO` | Cantidad <= 0 o incompatible con el contrato. |
| `SKU_INACTIVO` | 409 | `DOCUMENTADO` | El SKU existe pero no admite la operación por su estado. |
| `STOCK_INSUFICIENTE` | 409 | `DOCUMENTADO` | La disponibilidad actual no alcanza para reservar la cantidad solicitada. |
| `RESERVA_NO_ENCONTRADA` | 404 | `DOCUMENTADO` | No existe la reserva indicada. |
| `RESERVA_NO_ACTIVA` | 409 | `DOCUMENTADO` | La reserva existe, pero ya está en un estado terminal. |
| `RESERVA_EXPIRADA` | 409 | `DOCUMENTADO` | La reserva venció y ya no puede confirmarse. |
| `VERSION_CONFLICT` | 409 | `DOCUMENTADO` | El saldo cambió desde la versión esperada. |
| `OPERACION_DUPLICADA` | — | `DEPRECATED_ALIAS` | No debe emitirse. Un retry idempotente normal no es un error; si la misma identidad se reutiliza para otra intención, usar `IDEMPOTENCY_CONFLICT`. |

## 10.1. Idempotencia de Inventario

Un reintento con:

```text
mismo Idempotency-Key / operation_id
+
mismo payload semántico
```

debe devolver/reproducir el resultado de la operación original.

No debe responder:

```text
OPERACION_DUPLICADA
```

solo por ser un retry.

Cuando la misma clave se reutiliza para otra intención, utilizar:

```text
IDEMPOTENCY_CONFLICT
```

SPEC-015 v1.1 elimina esta ambigüedad: `OPERACION_DUPLICADA` queda retirado de contratos nuevos.

---

# 11. Pricing

Las reglas existen en SPEC-013; varios nombres se centralizan aquí por primera vez.

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `PRECIO_NO_ENCONTRADO` | 404 | `CANONICO_P0` | No existe precio resoluble para el SKU/contexto solicitado. |
| `PRECIO_INVALIDO` | 422 | `CANONICO_P0` | Precio regular no numérico o <= 0. |
| `OFERTA_INVALIDA` | 422 | `CANONICO_P0` | Oferta no cumple las reglas, por ejemplo >= precio regular. |
| `MOTIVO_CAMBIO_REQUERIDO` | 400 | `CANONICO_P0` | Mutación de precio sin motivo de cambio válido. |
| `VIGENCIA_SUPERPUESTA` | 409 | `CANONICO_P0` | Existe una vigencia solapada para el mismo SKU/tipo/canal/moneda. |
| `ACCION_OFERTA_INVALIDA` | 422 | `CANONICO_P0` | La combinación `CONSERVAR/ESTABLECER/ELIMINAR` y sus importes no es coherente. |
| `SCOPE_PRECIO_INVALIDO` | 422 | `CANONICO_P0` | El scope comercial/canal/moneda informado no es válido. |
| `VERSION_CONFLICT` | 409 | `DOCUMENTADO` | `price_version` obsoleta. |

## 11.1. Nulos en Pricing

No utilizar un error para representar valores legítimamente ausentes.

Ejemplos válidos:

```text
CREACION:
precio_anterior = null

RETIRO_OFERTA:
precio_nuevo = null
```

`null` no equivale a `0`.

## 11.2. Auditoría de precios

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `AUDITORIA_PRECIO_NO_ENCONTRADA` | 404 | `CANONICO_P0` | No existe el registro append-only identificado por `auditId`. |
| `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO` | 422 | `CANONICO_P0` | La consulta es válida, pero el número de registros resultantes excede el máximo del formato solicitado: CSV hasta 100000 y PDF hasta 500. No se crea un trabajo de exportación. |

El límite de registros es una restricción semántica del formato y no el tamaño físico del request; por ello utiliza HTTP `422`, no `413`.

---

# 12. Promociones

Las SPEC actuales definen las reglas funcionales, pero no nombres estables de error. Los siguientes códigos son `CANONICO_P0`.

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `PROMOCION_NO_ENCONTRADA` | 404 | `CANONICO_P0` | No existe la promoción administrativa solicitada. |
| `PROMOCION_INVALIDA` | 422 | `CANONICO_P0` | Fechas, descuento, alcance, prioridad o configuración no son válidos. |
| `PROMOCION_INACTIVA` | 409 | `CANONICO_P0` | Se solicita una mutación/transición incompatible con su estado. |
| `ALCANCE_PROMOCION_INVALIDO` | 422 | `CANONICO_P0` | Productos/SKU del alcance no son válidos. |

No se considera error que una evaluación comercial termine sin beneficios.

Debe representarse como resultado normal, por ejemplo:

```text
beneficios = []
motivo = "Sin beneficios aplicables"
```

y no como `404`/`422`.

---

# 13. Cupones

La validación de un cupón sin consumo es una evaluación de negocio. Un cupón no aplicable puede ser una respuesta normal del endpoint de validación, no necesariamente un error HTTP.

Estos códigos se usan especialmente como **motivos/rechazos de negocio** y en:

```text
promotions.coupon.consumption.rejected
```

| Code | Transporte | Estado | Semántica |
|---|---|---|---|
| `CUPON_NO_ENCONTRADO` | validación / 404 admin | `CANONICO_P0` | Código de cupón inexistente. |
| `CUPON_DUPLICADO` | 409 admin | `CANONICO_P0` | El código normalizado ya está reservado por otro cupón. |
| `CUPON_INACTIVO` | evaluación/result | `CANONICO_P0` | El cupón existe pero no está activo. |
| `CUPON_FUERA_DE_VIGENCIA` | evaluación/result | `CANONICO_P0` | La promoción asociada no está vigente. |
| `MONTO_MINIMO_NO_ALCANZADO` | evaluación/result | `CANONICO_P0` | La cesta no alcanza el mínimo configurado. |
| `CUPON_AGOTADO` | evaluación/result | `CANONICO_P0` | El límite global de usos ya fue alcanzado. |
| `LIMITE_CUPON_CLIENTE_ALCANZADO` | evaluación/result | `CANONICO_P0` | El cliente alcanzó su límite individual. |
| `CUSTOMER_REF_REQUERIDO` | 422 / result | `CANONICO_P0` | Se necesita referencia de cliente para aplicar un límite por cliente. |
| `CUPON_NO_COMBINABLE` | evaluación/result | `CANONICO_P0` | El beneficio no puede combinarse con la selección actual. |
| `LIMITE_CUPON_INVALIDO` | 422 | `CANONICO_P0` | Configuración de límites inválida o inferior a consumo ya registrado. |

Una validación positiva previa no garantiza que el cupón pueda consumirse después. El consumo debe volver a validar capacidad de forma atómica.

---

# 14. Combos

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `COMBO_NO_ENCONTRADO` | 404 | `CANONICO_P0` | No existe el combo solicitado. |
| `COMBO_ANIDADO_NO_PERMITIDO` | 422 | `CANONICO_P0` | Un combo intenta incluir otro combo. |
| `COMBO_COMPONENTES_INSUFICIENTES` | 422 | `CANONICO_P0` | Se intenta configurar menos de dos SKU vendibles distintos. |
| `COMBO_COMPONENTE_DUPLICADO` | 422 | `CANONICO_P0` | El mismo SKU aparece más de una vez como componente. |
| `COMBO_PRECIO_INVALIDO` | 422 | `CANONICO_P0` | El precio del combo no es estrictamente menor que las referencias exigidas. |
| `SKU_NO_ENCONTRADO` | 404/422 según contexto | `DOCUMENTADO` | Un SKU componente no existe. |

Que un combo tenga disponibilidad calculada `0` no implica error HTTP. Es un estado comercial normal.

---

# 15. Recomendaciones — Cross-sell / Upsell

No existen códigos explícitos en SPEC-007. Se centralizan los mínimos necesarios.

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `REGLA_RECOMENDACION_NO_ENCONTRADA` | 404 | `CANONICO_P0` | Regla administrativa inexistente. |
| `REGLA_RECOMENDACION_INVALIDA` | 422 | `CANONICO_P0` | Tipo, prioridad, vigencia o condición inválidos. |
| `PRODUCTO_RECOMENDADO_INVALIDO` | 422 | `CANONICO_P0` | Producto/SKU objetivo no es válido para la regla. |

Una consulta sin recomendaciones válidas devuelve:

```json
{
  "items": []
}
```

No devuelve error.

---

# 16. Taxonomía — Categorías

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `CATEGORIA_NO_ENCONTRADA` | 404 | `CANONICO_P0` | Categoría inexistente. |
| `CATEGORIA_DUPLICADA` | 409 | `CANONICO_P0` | Conflicto de unicidad según la regla de Taxonomía. |
| `PROFUNDIDAD_CATEGORIA_EXCEDIDA` | 422 | `CANONICO_P0` | La reubicación/creación excede `MAX_CATEGORY_DEPTH`. |
| `CICLO_CATEGORIA` | 409 | `CANONICO_P0` | La jerarquía produciría un ciclo. |
| `CATEGORIA_PADRE_INACTIVA` | 409 | `CANONICO_P0` | El padre seleccionado no está activo. |
| `CATEGORIA_CON_SUBCATEGORIAS_ACTIVAS` | 409 | `CANONICO_P0` | Se intenta desactivar una categoría que aún tiene hijas activas. |
| `ENTIDAD_MAESTRA_CON_PRODUCTOS_ACTIVOS` | 409 / result | `CANONICO_P0` | La baja segura obtiene `HAS_ACTIVE_PRODUCTS`. |
| `BAJA_MAESTRA_EN_PROCESO` | 409 | `CANONICO_P0` | Existe una barrera/operación de desactivación aún pendiente. |
| `OPERACION_MAESTRA_NO_ENCONTRADA` | 404 | `CANONICO_P0` | El `operation_id` consultado no corresponde a una operación maestra conocida o recuperable. |

`HAS_ACTIVE_PRODUCTS` es el valor del **resultado interno** de verificación; el código de error externo recomendado es:

```text
ENTIDAD_MAESTRA_CON_PRODUCTOS_ACTIVOS
```

---

# 17. Taxonomía — Marcas

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `MARCA_NO_ENCONTRADA` | 404 | `CANONICO_P0` | Marca inexistente. |
| `MARCA_DUPLICADA` | 409 | `CANONICO_P0` | El nombre normalizado ya pertenece a una marca activa o inactiva. |
| `LOGO_INVALIDO` | 422 | `CANONICO_P0` | MIME/formato de logo no permitido. |
| `LOGO_EXCEDE_LIMITE` | 413 | `CANONICO_P0` | El logo excede el límite de 5 MB definido en SPEC-011. |
| `ENTIDAD_MAESTRA_CON_PRODUCTOS_ACTIVOS` | 409 / result | `CANONICO_P0` | La marca no puede desactivarse mientras existan productos activos. |
| `BAJA_MAESTRA_EN_PROCESO` | 409 | `CANONICO_P0` | Operación de baja segura aún no reconciliada. |

---

# 18. Características y valores LISTA

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `CARACTERISTICA_NO_ENCONTRADA` | 404 | `CANONICO_P0` | Característica inexistente. |
| `TIPO_CARACTERISTICA_INMUTABLE` | 409 | `CANONICO_P0` | Se intenta cambiar `TEXTO/NUMERO/LISTA` de una característica ya creada. |
| `VALOR_LISTA_LIMITE_EXCEDIDO` | 422 | `CANONICO_P0` | Se supera `MAX_ACTIVE_LIST_VALUES`. |
| `TEXTO_ATRIBUTO_EXCEDE_LIMITE` | 422 | `CANONICO_P0` | Valor de texto supera `MAX_TEXT_ATTRIBUTE_LENGTH`. |
| `VALOR_NUMERICO_INVALIDO` | 422 | `CANONICO_P0` | Valor numérico/unidad no cumple la configuración. |
| `VALOR_LISTA_EN_USO` | 409 | `CANONICO_P0` | Un valor requerido/identificador está siendo utilizado por productos/SKU activos. |
| `BAJA_MAESTRA_EN_PROCESO` | 409 | `CANONICO_P0` | El valor se encuentra bajo verificación asíncrona. |

---

# 19. Tipo de producto — Característica

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `TIPO_PRODUCTO_NO_ENCONTRADO` | 404 | `CANONICO_P0` | No existe el tipo de producto solicitado mediante una ruta identificada por `tipoProductoId`. |
| `ASOCIACION_NO_ENCONTRADA` | 404 | `CANONICO_P0` | Asociación inexistente. |
| `ASOCIACION_DUPLICADA` | 409 | `CANONICO_P0` | La característica ya está asociada al tipo. |
| `LIMITE_CARACTERISTICAS_EXCEDIDO` | 422 | `CANONICO_P0` | Se supera `MAX_PRODUCT_TYPE_ATTRIBUTES`. |
| `ASOCIACION_EN_USO` | 409 | `CANONICO_P0` | La desasociación necesita verificación porque participa en productos/variantes activos. |
| `CAMBIO_ESTRUCTURAL_NO_PERMITIDO` | 409 | `DOCUMENTADO` | Un cambio de tipo afectaría identidad publicada y requiere migración. |
| `VERSION_CONFLICT` | 409 | `DOCUMENTADO` | La versión del esquema cambió durante una escritura. |

---

# 20. SEO

| Code | HTTP | Estado | Semántica |
|---|---:|---|---|
| `SLUG_NO_ENCONTRADO` | 404 | `CANONICO_P0` | No existe un slug activo/resolución pública válida. |
| `SLUG_DUPLICADO` | 409 | `CANONICO_P0` | El slug solicitado ya está reservado. Aplica a edición manual y al alta de categoría cuando el `slugConfirmado` dejó de estar disponible entre la resolución previa y la persistencia final. |
| `METADATOS_SEO_INVALIDOS` | 422 | `CANONICO_P0` | Metadatos no cumplen las reglas contractuales. |

Una categoría inactiva no debe exponerse públicamente usando un código que revele innecesariamente su existencia. Para la API pública puede responder:

```text
SLUG_NO_ENCONTRADO
```

### 20.1. Resolución previa durante creación de categoría

`POST /api/v1/seo/categorias/slug/resolver` no devuelve `SLUG_DUPLICADO` por una colisión normal: SEO busca una propuesta disponible y puede aplicar un sufijo incremental visible. La propuesta **no constituye una reserva**.

`POST /api/v1/categorias` recibe `slugConfirmado` y vuelve a validar unicidad inmediatamente antes de persistir. Si el slug fue ocupado en ese intervalo, responde:

```text
HTTP 409
SLUG_DUPLICADO
```

El servidor no genera un nuevo sufijo de forma silenciosa en la confirmación final; el cliente debe volver a resolver y mostrar la nueva propuesta al gestor.

---

# 21. Bulk / Importaciones

Las filas de una importación reutilizan los códigos de los dominios propietarios. El orquestador no debe traducir:

```text
SKU_DUPLICADO
VERSION_CONFLICT
PRECIO_INVALIDO
```

a un genérico:

```text
FILA_ERROR
```

El reporte conserva el código original.

Códigos propios del proceso Bulk:

| Code | HTTP / fila | Estado | Semántica |
|---|---:|---|---|
| `ARCHIVO_INVALIDO` | 400 | `CANONICO_P0` | MIME, extensión, cabeceras o estructura base inválidos. |
| `ARCHIVO_EXCEDE_LIMITE` | 413 | `CANONICO_P0` | Archivo > 10 MB u otro límite contractual vigente. |
| `PLANTILLA_INCOMPATIBLE` | 422 | `CANONICO_P0` | `template_version` o columnas no corresponden al contrato soportado. |
| `CONTENIDO_ACTIVO_NO_PERMITIDO` | 422 | `CANONICO_P0` | Archivo contiene fórmulas/macros/contenido activo prohibido. |
| `LOTE_NO_ENCONTRADO` | 404 | `CANONICO_P0` | `batch_id` o `export_id` inexistente. |
| `VERSION_CONFLICT` | 409 / fila | `DOCUMENTADO` | Versión de Catálogo, Pricing o Inventario obsoleta. |

## 21.1. Estados de trabajo no son códigos de error

No confundir:

```text
QUEUED
PROCESSING
COMPLETED
FAILED
FAILED_GENERAL
```

con `code`.

Son estados de proceso.

Cuando un trabajo termina en `FAILED_GENERAL`, el detalle técnico debe acompañarse de un código estable si existe una causa pública útil; de lo contrario puede utilizarse `ERROR_INTERNO` o `SERVICIO_NO_DISPONIBLE` según corresponda.

---

# 22. Dashboard de stock

`STOCK_BAJO` y `AGOTADO` son **estados de disponibilidad**, no códigos de error.

Correcto:

```json
{
  "estado": "STOCK_BAJO"
}
```

Incorrecto:

```json
{
  "code": "STOCK_BAJO"
}
```

salvo que una operación futura defina explícitamente un error distinto, lo cual no existe actualmente.

---

# 23. Matriz rápida por HTTP

## 400 — Request

```text
VALIDACION
MOTIVO_CAMBIO_REQUERIDO
ARCHIVO_INVALIDO
```

## 401 — Autenticación

```text
TOKEN_INVALIDO
```

## 403 — Autorización

```text
SCOPE_INSUFICIENTE
```

## 404 — Recurso

```text
PRODUCTO_NO_ENCONTRADO
VARIANTE_NO_ENCONTRADA
SKU_NO_ENCONTRADO
UBICACION_NO_ENCONTRADA
RESERVA_NO_ENCONTRADA
PRECIO_NO_ENCONTRADO
PROMOCION_NO_ENCONTRADA
COMBO_NO_ENCONTRADO
CATEGORIA_NO_ENCONTRADA
MARCA_NO_ENCONTRADA
CARACTERISTICA_NO_ENCONTRADA
TIPO_PRODUCTO_NO_ENCONTRADO
ASOCIACION_NO_ENCONTRADA
SLUG_NO_ENCONTRADO
LOTE_NO_ENCONTRADO
OPERACION_MAESTRA_NO_ENCONTRADA
AUDITORIA_PRECIO_NO_ENCONTRADA
```

## 409 — Conflicto

```text
SKU_DUPLICADO
COMBINACION_DUPLICADA
PRODUCTO_NO_ADMITE_VARIANTES
CUPON_DUPLICADO
VERSION_CONFLICT
IDEMPOTENCY_CONFLICT
STOCK_INSUFICIENTE
SKU_INACTIVO
RESERVA_NO_ACTIVA
RESERVA_EXPIRADA
CAMBIO_ESTRUCTURAL_NO_PERMITIDO
VIGENCIA_SUPERPUESTA
CATEGORIA_DUPLICADA
CICLO_CATEGORIA
CATEGORIA_PADRE_INACTIVA
CATEGORIA_CON_SUBCATEGORIAS_ACTIVAS
ENTIDAD_MAESTRA_CON_PRODUCTOS_ACTIVOS
BAJA_MAESTRA_EN_PROCESO
MARCA_DUPLICADA
TIPO_CARACTERISTICA_INMUTABLE
VALOR_LISTA_EN_USO
ASOCIACION_DUPLICADA
ASOCIACION_EN_USO
SLUG_DUPLICADO
```

## 413 — Tamaño

```text
ARCHIVO_EXCEDE_LIMITE
LOGO_EXCEDE_LIMITE
```

## 422 — Semántica

```text
CANTIDAD_INVALIDA
PERFIL_FISICO_INVALIDO
DATOS_FISICOS_INCOMPLETOS
DATOS_INCOMPLETOS
CATEGORIA_INVALIDA
TIPO_PRODUCTO_INVALIDO
MARCA_INVALIDA
SKU_INVALIDO
ATRIBUTO_IDENTIFICADOR_INVALIDO
IMAGEN_INVALIDA
PRECIO_INVALIDO
OFERTA_INVALIDA
ACCION_OFERTA_INVALIDA
SCOPE_PRECIO_INVALIDO
PROMOCION_INVALIDA
ALCANCE_PROMOCION_INVALIDO
CUSTOMER_REF_REQUERIDO
LIMITE_CUPON_INVALIDO
COMBO_ANIDADO_NO_PERMITIDO
COMBO_COMPONENTES_INSUFICIENTES
COMBO_COMPONENTE_DUPLICADO
COMBO_PRECIO_INVALIDO
REGLA_RECOMENDACION_INVALIDA
PRODUCTO_RECOMENDADO_INVALIDO
PROFUNDIDAD_CATEGORIA_EXCEDIDA
LOGO_INVALIDO
VALOR_LISTA_LIMITE_EXCEDIDO
TEXTO_ATRIBUTO_EXCEDE_LIMITE
VALOR_NUMERICO_INVALIDO
LIMITE_CARACTERISTICAS_EXCEDIDO
METADATOS_SEO_INVALIDOS
PLANTILLA_INCOMPATIBLE
CONTENIDO_ACTIVO_NO_PERMITIDO
LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO
```

## 500 / 503

```text
ERROR_INTERNO
SERVICIO_NO_DISPONIBLE
```

---

# 24. `VALIDACION` vs código de dominio

Usar `VALIDACION` cuando el request no puede interpretarse correctamente a nivel de contrato.

Ejemplo:

```json
{
  "code": "VALIDACION",
  "details": {
    "fields": [
      {
        "field": "quantity",
        "message": "Es obligatorio."
      }
    ]
  }
}
```

Usar un código de dominio cuando el request es comprensible pero viola una regla específica.

Ejemplo:

```text
quantity = -2
```

puede convertirse en:

```text
CANTIDAD_INVALIDA
```

si el dominio ya llegó a interpretar la intención.

Esta distinción debe ser consistente por endpoint; no alternar arbitrariamente entre ambos para el mismo caso.

---

# 25. `404` y privacidad

No todos los endpoints deben revelar que un recurso existe pero está inactivo.

Para endpoints públicos o de canal, cuando distinguir:

```text
NO_EXISTE
vs
EXISTE_PERO_NO_ES_VISIBLE
```

facilite enumeración o exponga información que el consumidor no necesita, responder el mismo código de ausencia.

Ejemplo SEO público:

```text
SLUG_NO_ENCONTRADO
```

para un slug que no es publicable.

---

# 26. Rechazos de negocio que no son HTTP error

Los siguientes casos pueden viajar como resultado normal de una evaluación:

```text
CUPON_INACTIVO
CUPON_FUERA_DE_VIGENCIA
MONTO_MINIMO_NO_ALCANZADO
CUPON_AGOTADO
LIMITE_CUPON_CLIENTE_ALCANZADO
CUPON_NO_COMBINABLE
```

Una API como:

```text
POST /cupones/validar
```

puede responder `200` indicando:

```json
{
  "aplicable": false,
  "code": "MONTO_MINIMO_NO_ALCANZADO"
}
```

si así queda definido por el schema de OpenAPI.

No convertir toda decisión comercial negativa en un error de transporte.

---

# 27. Ejemplos

## 27.1. SKU duplicado

```json
{
  "type": "/errores/sku-duplicado",
  "title": "SKU ya registrado",
  "status": 409,
  "detail": "El SKU solicitado ya pertenece a otra unidad vendible.",
  "instance": "/api/v1/productos",
  "code": "SKU_DUPLICADO",
  "correlationId": "d8ec449d-a94e-4d22-a646-02493efce2f0",
  "details": {
    "sku": "BOT-750"
  }
}
```

## 27.2. Version conflict

```json
{
  "type": "/errores/version-conflict",
  "title": "La información cambió",
  "status": 409,
  "detail": "La versión enviada ya no es la vigente.",
  "code": "VERSION_CONFLICT",
  "correlationId": "e172e915-aaaf-46ba-9717-9fc20d3ec149",
  "details": {
    "expectedVersion": 12,
    "currentVersion": 13
  }
}
```

## 27.3. Scope insuficiente

```json
{
  "type": "/errores/scope-insuficiente",
  "title": "Permisos insuficientes",
  "status": 403,
  "code": "SCOPE_INSUFICIENTE",
  "correlationId": "82b76130-f9c0-4d80-bd65-544d40ce7a31"
}
```

No es obligatorio revelar:

```text
scope requerido = ..
```

en la respuesta.

## 27.4. Stock insuficiente

```json
{
  "type": "/errores/stock-insuficiente",
  "title": "Stock insuficiente",
  "status": 409,
  "code": "STOCK_INSUFICIENTE",
  "correlationId": "a7272f69-3154-45f8-80e4-849ffdf42f33",
  "details": {
    "sku": "ZAP-PSX-42-NEG",
    "location_id": "DEFAULT",
    "requested": 3,
    "available": 2
  }
}
```

---

# 28. Reglas de frontend

El frontend debe:

1. ramificar por `code`;
2. conservar `correlationId` cuando muestre una referencia de soporte;
3. mapear códigos a copy operativo;
4. evitar mostrar `detail` crudo si contiene información no pensada para usuario final;
5. mantener errores de campo cerca del control;
6. no traducir un `409` genérico sin revisar `code`.

Ejemplo:

```ts
switch (problem.code) {
  case "SKU_DUPLICADO":
    // mostrar conflicto de SKU
    break;

  case "VERSION_CONFLICT":
    // ofrecer recargar
    break;

  case "SCOPE_INSUFICIENTE":
    // estado de acceso restringido
    break;
}
```

El status HTTP por sí solo no es suficiente.

---

# 29. Reglas de logging y observabilidad

Todo error público debe generar o propagar:

```text
correlationId
code
status
service
operation
```

Cuando corresponda:

```text
operation_id
message_id
batch_id
row_id
sku
product_id
reservation_id
```

Los logs internos pueden contener más contexto que la respuesta pública, pero deben respetar políticas de privacidad.

No registrar:

```text
Authorization
JWT completo
contraseñas
secrets
datos de pago
```

---

# 30. Gobierno del catálogo

Para agregar un nuevo código:
