# Catálogo canónico de errores — Productos y Ofertas

**Fuente HTTP:** [`openapi.yaml`](./openapi.yaml)
**Versión HTTP de referencia:** `0.5.0`

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
| `OPERACION_MAESTRA_NO_ENCONTRADA` | Operación maestra no encontrada. |
| `AUDITORIA_PRECIO_NO_ENCONTRADA` | Auditoría de precio no encontrada. |
| `LIMITE_EXPORTACION_AUDITORIA_EXCEDIDO` | Límite de exportación de auditoría excedido. |
| `PRODUCTO_NO_ENCONTRADO` | Producto no encontrado. |
| `SKU_DUPLICADO` | SKU duplicado. |
| `CATEGORIA_INVALIDA` | Categoría inválida. |
| `TIPO_PRODUCTO_INVALIDO` | Tipo de producto inválido. |
| `TIPO_PRODUCTO_NO_ENCONTRADO` | Tipo de producto no encontrado. |
| `MARCA_INVALIDA` | Marca inválida. |
| `DATOS_INCOMPLETOS` | Datos incompletos. |
| `CAMBIO_ESTRUCTURAL_NO_PERMITIDO` | Cambio estructural no permitido. |
| `PERFIL_FISICO_INVALIDO` | Perfil físico inválido. |
| `DATOS_FISICOS_INCOMPLETOS` | Datos físicos incompletos. |
| `VARIANTE_NO_ENCONTRADA` | Variante no encontrada. |
| `PRODUCTO_NO_ADMITE_VARIANTES` | Producto no admite variantes. |
| `COMBINACION_DUPLICADA` | Combinación duplicada. |
| `SKU_INVALIDO` | SKU inválido. |
| `ATRIBUTO_IDENTIFICADOR_INVALIDO` | Atributo identificador inválido. |
| `IMAGEN_INVALIDA` | Imagen inválida. |
| `SKU_NO_ENCONTRADO` | SKU no encontrado. |
| `UBICACION_NO_ENCONTRADA` | Ubicación no encontrada. |
| `CANTIDAD_INVALIDA` | Cantidad inválida. |
| `SKU_INACTIVO` | SKU inactivo. |
| `STOCK_INSUFICIENTE` | No existe disponibilidad suficiente para completar la operación. |
| `RESERVA_NO_ENCONTRADA` | Reserva no encontrada. |
| `RESERVA_NO_ACTIVA` | Reserva no activa. |
| `RESERVA_EXPIRADA` | Reserva expirada. |
| `PRECIO_NO_ENCONTRADO` | Precio no encontrado. |
| `PRECIO_INVALIDO` | Precio inválido. |
| `OFERTA_INVALIDA` | Oferta inválida. |
| `MOTIVO_CAMBIO_REQUERIDO` | Motivo cambio requerido. |
| `VIGENCIA_SUPERPUESTA` | Vigencia superpuesta. |
| `ACCION_OFERTA_INVALIDA` | Acción de oferta inválida. |
| `SCOPE_PRECIO_INVALIDO` | Scope precio invalido. |
| `PROMOCION_NO_ENCONTRADA` | Promoción no encontrada. |
| `PROMOCION_INVALIDA` | Promoción inválida. |
| `PROMOCION_INACTIVA` | Promoción inactiva. |
| `ALCANCE_PROMOCION_INVALIDO` | Alcance de promoción inválido. |
| `CUSTOMER_REF_REQUERIDO` | La regla requiere identificar al cliente y customer_ref es nulo. |
| `LIMITE_CUPON_INVALIDO` | Límite de cupón inválido. |
| `CUPON_DUPLICADO` | Cupón duplicado. |
| `COMBO_NO_ENCONTRADO` | Combo no encontrado. |
| `COMBO_ANIDADO_NO_PERMITIDO` | Combo anidado no permitido. |
| `COMBO_COMPONENTES_INSUFICIENTES` | Combo componentes insuficientes. |
| `COMBO_COMPONENTE_DUPLICADO` | Combo componente duplicado. |
| `COMBO_PRECIO_INVALIDO` | Combo precio invalido. |
| `REGLA_RECOMENDACION_NO_ENCONTRADA` | Regla de recomendación no encontrada. |
| `REGLA_RECOMENDACION_INVALIDA` | Regla de recomendación inválida. |
| `PRODUCTO_RECOMENDADO_INVALIDO` | Producto recomendado inválido. |
| `CATEGORIA_NO_ENCONTRADA` | Categoría no encontrada. |
| `CATEGORIA_DUPLICADA` | Categoría duplicada. |
| `PROFUNDIDAD_CATEGORIA_EXCEDIDA` | Profundidad de categoría excedida. |
| `CICLO_CATEGORIA` | Ciclo de categoría. |
| `CATEGORIA_PADRE_INACTIVA` | Categoría padre inactiva. |
| `CATEGORIA_CON_SUBCATEGORIAS_ACTIVAS` | Categoria con subcategorias activas. |
| `ENTIDAD_MAESTRA_CON_PRODUCTOS_ACTIVOS` | Entidad maestra con productos activos. |
| `BAJA_MAESTRA_EN_PROCESO` | Baja maestra en proceso. |
| `MARCA_NO_ENCONTRADA` | Marca no encontrada. |
| `MARCA_DUPLICADA` | Marca duplicada. |
| `LOGO_INVALIDO` | Logo invalido. |
| `LOGO_EXCEDE_LIMITE` | Logo excede limite. |
| `CARACTERISTICA_NO_ENCONTRADA` | Característica no encontrada. |
| `TIPO_CARACTERISTICA_INMUTABLE` | Tipo de característica inmutable. |
| `VALOR_LISTA_LIMITE_EXCEDIDO` | Valor lista limite excedido. |
| `TEXTO_ATRIBUTO_EXCEDE_LIMITE` | Texto atributo excede limite. |
| `VALOR_NUMERICO_INVALIDO` | Valor numerico invalido. |
| `VALOR_LISTA_EN_USO` | Valor lista en uso. |
| `ASOCIACION_NO_ENCONTRADA` | Asociación no encontrada. |
| `ASOCIACION_DUPLICADA` | Asociación duplicada. |
| `LIMITE_CARACTERISTICAS_EXCEDIDO` | Límite de características excedido. |
| `ASOCIACION_EN_USO` | Asociación en uso. |
| `SLUG_NO_ENCONTRADO` | Slug no encontrado. |
| `SLUG_DUPLICADO` | Slug duplicado. |
| `METADATOS_SEO_INVALIDOS` | Metadatos SEO inválidos. |
| `ARCHIVO_INVALIDO` | Archivo inválido. |
| `ARCHIVO_EXCEDE_LIMITE` | Archivo excede el límite. |
| `PLANTILLA_INCOMPATIBLE` | Plantilla incompatible. |
| `CONTENIDO_ACTIVO_NO_PERMITIDO` | Contenido activo no permitido. |
| `LOTE_NO_ENCONTRADO` | Lote no encontrado. |
| `CUPON_NO_ENCONTRADO` | Cupón no encontrado. |
| `INCIDENCIA_NO_ENCONTRADA` | No existe la incidencia de inventario solicitada. |
| `INCIDENCIA_NO_ACTIVA` | La incidencia ya no admite la transición solicitada. |
| `RESOLUCION_INCIDENCIA_INVALIDA` | La resolución no cumple sus precondiciones. |
| `REINTEGRO_NO_APLICABLE` | El retorno no cumple las condiciones de reintegro. |
| `TRASLADO_NO_ENCONTRADO` | No existe el traslado solicitado. |
| `TRASLADO_NO_RECIBIBLE` | El traslado ya está cerrado o no admite nuevas recepciones. |
| `CANTIDAD_RECIBIDA_EXCEDE_TRASLADO` | La recepción supera la cantidad aún pendiente. |
| `DISPOSICION_RECEPCION_INVALIDA` | La disposición de recepción no es válida para la operación. |

| `CODIGO_BARRAS_NO_ENCONTRADO` | El código de barras recibido no puede resolverse a un SKU vendible para la integración autorizada. |

| `RATE_LIMIT_EXCEDIDO` | La identidad o cliente excedió temporalmente la política de solicitudes permitida; la respuesta HTTP es 429 y puede incluir `Retry-After`. |
| `PREPARACION_NO_REINTENTABLE` | La preparación existe pero el estado actual no admite recuperación manual. |

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

---

<!-- HOMOLOGACION-HTTP-0.5.0:START -->
## Cambios HTTP 0.5.0

Los códigos incorporados por HTTP 0.5.0 son `CODIGO_BARRAS_NO_ENCONTRADO`, `RATE_LIMIT_EXCEDIDO` y `PREPARACION_NO_REINTENTABLE`.

`CODIGO_BARRAS_NO_ENCONTRADO` no revela si existió una asociación histórica/inactiva; solo comunica que no hay una resolución comercial válida.

`RATE_LIMIT_EXCEDIDO` se origina en Ingress/API Gateway, no en el dominio, y es distinto de `TOKEN_INVALIDO`, `SCOPE_INSUFICIENTE` e `IDEMPOTENCY_CONFLICT`.

`PREPARACION_NO_REINTENTABLE` indica que la preparación técnica existe pero su estado actual no admite una recuperación manual (p. ej. continúa bajo recuperación técnica ordinaria, ya concluyó con éxito o ya fue admitido un reintento).
<!-- HOMOLOGACION-HTTP-0.5.0:END -->
