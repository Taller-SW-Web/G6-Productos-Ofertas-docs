# Catálogo canónico de errores — Productos y Ofertas

**Fuente HTTP:** [`openapi.yaml`](./openapi.yaml)

Los consumidores deben ramificar por `Problem.code`, nunca por `title` o `detail`.

## Formato

```json
{
  "type": "/errores/ejemplo",
  "title": "Descripción legible",
  "status": 409,
  "detail": "Detalle opcional",
  "code": "VERSION_CONFLICT",
  "correlationId": "..."
}
```

## Códigos

| `code` | Semántica |
|---|---|
| `VALIDACION` | Solicitud inválida o incumplimiento de formato/regla de entrada. |
| `TOKEN_INVALIDO` | Token ausente, inválido, expirado o no utilizable. |
| `SCOPE_INSUFICIENTE` | Identidad autenticada sin autorización requerida. |
| `VERSION_CONFLICT` | La versión enviada quedó obsoleta frente al estado persistido. |
| `IDEMPOTENCY_CONFLICT` | La misma identidad idempotente fue reutilizada para otra intención. |
| `ERROR_INTERNO` | Fallo no controlado del servicio. |
| `SERVICIO_NO_DISPONIBLE` | Dependencia o servicio temporalmente no disponible. |
| `OPERACION_MAESTRA_NO_ENCONTRADA` | Operacion maestra no encontrada. |
| `AUDITORIA_PRECIO_NO_ENCONTRADA` | Auditoria precio no encontrada. |
| `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO` | Limite exportacion auditoria excedido. |
| `PRODUCTO_NO_ENCONTRADO` | Producto no encontrado. |
| `SKU_DUPLICADO` | Sku duplicado. |
| `CATEGORIA_INVALIDA` | Categoria invalida. |
| `TIPO_PRODUCTO_INVALIDO` | Tipo producto invalido. |
| `TIPO_PRODUCTO_NO_ENCONTRADO` | Tipo producto no encontrado. |
| `MARCA_INVALIDA` | Marca invalida. |
| `DATOS_INCOMPLETOS` | Datos incompletos. |
| `CAMBIO_ESTRUCTURAL_NO_PERMITIDO` | Cambio estructural no permitido. |
| `PERFIL_FISICO_INVALIDO` | Perfil fisico invalido. |
| `DATOS_FISICOS_INCOMPLETOS` | Datos fisicos incompletos. |
| `VARIANTE_NO_ENCONTRADA` | Variante no encontrada. |
| `PRODUCTO_NO_ADMITE_VARIANTES` | Producto no admite variantes. |
| `COMBINACION_DUPLICADA` | Combinacion duplicada. |
| `SKU_INVALIDO` | Sku invalido. |
| `ATRIBUTO_IDENTIFICADOR_INVALIDO` | Atributo identificador invalido. |
| `IMAGEN_INVALIDA` | Imagen invalida. |
| `SKU_NO_ENCONTRADO` | Sku no encontrado. |
| `UBICACION_NO_ENCONTRADA` | Ubicacion no encontrada. |
| `CANTIDAD_INVALIDA` | Cantidad invalida. |
| `SKU_INACTIVO` | Sku inactivo. |
| `STOCK_INSUFICIENTE` | No existe disponibilidad suficiente para completar la operación. |
| `RESERVA_NO_ENCONTRADA` | Reserva no encontrada. |
| `RESERVA_NO_ACTIVA` | Reserva no activa. |
| `RESERVA_EXPIRADA` | Reserva expirada. |
| `PRECIO_NO_ENCONTRADO` | Precio no encontrado. |
| `PRECIO_INVALIDO` | Precio invalido. |
| `OFERTA_INVALIDA` | Oferta invalida. |
| `MOTIVO_CAMBIO_REQUERIDO` | Motivo cambio requerido. |
| `VIGENCIA_SUPERPUESTA` | Vigencia superpuesta. |
| `ACCION_OFERTA_INVALIDA` | Accion oferta invalida. |
| `SCOPE_PRECIO_INVALIDO` | Scope precio invalido. |
| `PROMOCION_NO_ENCONTRADA` | Promocion no encontrada. |
| `PROMOCION_INVALIDA` | Promocion invalida. |
| `PROMOCION_INACTIVA` | Promocion inactiva. |
| `ALCANCE_PROMOCION_INVALIDO` | Alcance promocion invalido. |
| `CUSTOMER_REF_REQUERIDO` | La regla requiere identificar al cliente y customer_ref es nulo. |
| `LIMITE_CUPON_INVALIDO` | Limite cupon invalido. |
| `CUPON_DUPLICADO` | Cupon duplicado. |
| `COMBO_NO_ENCONTRADO` | Combo no encontrado. |
| `COMBO_ANIDADO_NO_PERMITIDO` | Combo anidado no permitido. |
| `COMBO_COMPONENTES_INSUFICIENTES` | Combo componentes insuficientes. |
| `COMBO_COMPONENTE_DUPLICADO` | Combo componente duplicado. |
| `COMBO_PRECIO_INVALIDO` | Combo precio invalido. |
| `REGLA_RECOMENDACION_NO_ENCONTRADA` | Regla recomendacion no encontrada. |
| `REGLA_RECOMENDACION_INVALIDA` | Regla recomendacion invalida. |
| `PRODUCTO_RECOMENDADO_INVALIDO` | Producto recomendado invalido. |
| `CATEGORIA_NO_ENCONTRADA` | Categoria no encontrada. |
| `CATEGORIA_DUPLICADA` | Categoria duplicada. |
| `PROFUNDIDAD_CATEGORIA_EXCEDIDA` | Profundidad categoria excedida. |
| `CICLO_CATEGORIA` | Ciclo categoria. |
| `CATEGORIA_PADRE_INACTIVA` | Categoria padre inactiva. |
| `CATEGORIA_CON_SUBCATEGORIAS_ACTIVAS` | Categoria con subcategorias activas. |
| `ENTIDAD_MAESTRA_CON_PRODUCTOS_ACTIVOS` | Entidad maestra con productos activos. |
| `BAJA_MAESTRA_EN_PROCESO` | Baja maestra en proceso. |
| `MARCA_NO_ENCONTRADA` | Marca no encontrada. |
| `MARCA_DUPLICADA` | Marca duplicada. |
| `LOGO_INVALIDO` | Logo invalido. |
| `LOGO_EXCEDE_LIMITE` | Logo excede limite. |
| `CARACTERISTICA_NO_ENCONTRADA` | Caracteristica no encontrada. |
| `TIPO_CARACTERISTICA_INMUTABLE` | Tipo caracteristica inmutable. |
| `VALOR_LISTA_LIMITE_EXCEDIDO` | Valor lista limite excedido. |
| `TEXTO_ATRIBUTO_EXCEDE_LIMITE` | Texto atributo excede limite. |
| `VALOR_NUMERICO_INVALIDO` | Valor numerico invalido. |
| `VALOR_LISTA_EN_USO` | Valor lista en uso. |
| `ASOCIACION_NO_ENCONTRADA` | Asociacion no encontrada. |
| `ASOCIACION_DUPLICADA` | Asociacion duplicada. |
| `LIMITE_CARACTERISTICAS_EXCEDIDO` | Limite caracteristicas excedido. |
| `ASOCIACION_EN_USO` | Asociacion en uso. |
| `SLUG_NO_ENCONTRADO` | Slug no encontrado. |
| `SLUG_DUPLICADO` | Slug duplicado. |
| `METADATOS_SEO_INVALIDOS` | Metadatos seo invalidos. |
| `ARCHIVO_INVALIDO` | Archivo invalido. |
| `ARCHIVO_EXCEDE_LIMITE` | Archivo excede limite. |
| `PLANTILLA_INCOMPATIBLE` | Plantilla incompatible. |
| `CONTENIDO_ACTIVO_NO_PERMITIDO` | Contenido activo no permitido. |
| `LOTE_NO_ENCONTRADO` | Lote no encontrado. |
| `CUPON_NO_ENCONTRADO` | Cupon no encontrado. |
| `INCIDENCIA_NO_ENCONTRADA` | No existe la incidencia de inventario solicitada. |
| `INCIDENCIA_NO_ACTIVA` | La incidencia ya no admite la transición solicitada. |
| `RESOLUCION_INCIDENCIA_INVALIDA` | La resolución no cumple sus precondiciones. |
| `REINTEGRO_NO_APLICABLE` | El retorno no cumple las condiciones de reintegro. |
| `TRASLADO_NO_ENCONTRADO` | No existe el traslado solicitado. |
| `TRASLADO_NO_RECIBIBLE` | El traslado ya está cerrado o no admite nuevas recepciones. |
| `CANTIDAD_RECIBIDA_EXCEDE_TRASLADO` | La recepción supera la cantidad aún pendiente. |
| `DISPOSICION_RECEPCION_INVALIDA` | La disposición de recepción no es válida para la operación. |

## Recepción de traslados

Códigos específicos:

```text
TRASLADO_NO_ENCONTRADO
TRASLADO_NO_RECIBIBLE
CANTIDAD_RECIBIDA_EXCEDE_TRASLADO
DISPOSICION_RECEPCION_INVALIDA
```

## Códigos retirados

`SIN_AUTORIZACION` no se utiliza en contratos nuevos. Para una identidad autenticada sin autorización se usa `SCOPE_INSUFICIENTE`.
