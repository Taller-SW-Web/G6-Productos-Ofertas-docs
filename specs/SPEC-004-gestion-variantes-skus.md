# SPEC-004 — Especificación: Gestión avanzada de variantes (SKUs)

**Responsable:** Gabriel Poma Gutierrez  
**Rama:** poma  
**Trazabilidad:** HU [HU-004](./hu/HU-004-gestion-variantes-skus.md) | Wireframe [WF-004](./wireframes/flows/WF-004-gestion-variantes-skus.md)  
**Contrato HTTP:** [`./api/openapi.yaml`](./api/openapi.yaml)  
**Contrato de integración:** [`./Contrato_Api.md`](./Contrato_Api.md)  
**Arquitectura:** [`./Arquitectura.md`](./Arquitectura.md)  
**Modelo conceptual:** [`./Modelo_Conceptual.md`](./Modelo_Conceptual.md)  
**Catálogo de errores:** [`./api/catalogo-errores.md`](./api/catalogo-errores.md)

**Versión:** v3.1 — seguridad y códigos de error armonizados

> **Cambios principales de esta versión**
>
> - se mantiene la separación entre `variant_id` interno y SKU comercial;
> - se incorpora el **perfil físico del SKU vendible** como responsabilidad de Catálogo;
> - se definen `pesoKg`, `largoCm`, `anchoCm` y `altoCm`;
> - se fija kg/cm como unidad contractual;
> - se permite editar el perfil físico sin cambiar la identidad de la variante;
> - se formaliza la consulta física en lote para Despacho;
> - se deja explícito que **Despacho es dueño del empaque**, no Productos;
> - se evita duplicar stock, precio o lógica logística dentro de Catálogo;
- la autenticación/autorización HTTP se alinea con el contrato oficial de Seguridad mediante `TOKEN_INVALIDO` y `SCOPE_INSUFICIENTE`.

---

# 1. Contexto

Dentro del catálogo de productos deportivos es común que un mismo producto base tenga múltiples versiones comerciales diferenciadas por características como talla, color u otros atributos.

La capacidad de Gestión de Productos (`SPEC-003`) define:

```text
tiene_variantes = false
```

para productos simples, cuyo `sku_base` funciona como SKU vendible;

y:

```text
tiene_variantes = true
```

para productos cuya venta se realiza mediante variantes.

Cada variante representa una combinación comercial concreta, por ejemplo:

```text
Nike Air Max
Talla 42
Color Negro
SKU NKE-AM-42-BLK
```

El SKU es utilizado como identidad de integración por:

- Pricing;
- Inventario;
- Promociones;
- Combos;
- Ventas/Postventa;
- Despacho.

Catálogo es responsable de la **identidad y descripción del SKU**, pero no de:

- su precio autoritativo;
- su stock;
- sus reservas;
- el empaque;
- el despacho.

---

# 2. Propósito

Permitir crear y administrar variantes de productos con:

- identidad interna estable;
- SKU comercial único;
- combinación de atributos identificadores;
- imagen propia;
- atributos no identificadores;
- estado de ciclo de vida;
- perfil físico del SKU para integración logística.

El objetivo es que cualquier consumidor pueda identificar de forma inequívoca qué unidad vendible está utilizando, sin mezclar responsabilidades de Catálogo con Pricing, Inventario o Despacho.

---

# 3. Alcance

Esta SPEC aplica principalmente a productos con:

```text
tiene_variantes = true
```

Incluye:

1. configuración de características identificadoras;
2. creación de variantes;
3. generación de `variant_id`;
4. SKU comercial informado o autogenerado;
5. imagen propia;
6. edición de atributos no identificadores;
7. activación/reactivación/desactivación;
8. consulta de variantes;
9. perfil físico por SKU;
10. exposición de datos físicos para Despacho;
11. integración con Inventario al inicializar el SKU;
12. integración con Pricing mediante la identidad SKU.

## 3.1. Productos simples

Los productos simples siguen perteneciendo funcionalmente a `SPEC-003`.

Sin embargo, como `sku_base` también es un SKU vendible, el modelo conceptual establece que **todo SKU vendible puede disponer de perfil físico**.

Por tanto:

- esta SPEC define la regla para variantes;
- `SPEC-003` deberá aplicar la misma semántica al `sku_base` de productos simples;
- la API de consulta física de Despacho debe tratar ambos tipos de SKU de forma uniforme.

---

# 4. Identidad de variante

## 4.1. `variant_id`

Cada variante DEBE tener un:

```text
variant_id
```

generado por Catálogo.

Debe ser:

- interno;
- estable;
- inmutable;
- no significativo;
- independiente del SKU.

No debe utilizarse como código comercial visible.

---

## 4.2. SKU comercial

Cada variante DEBE disponer de un:

```text
sku
```

comercial único a nivel del catálogo.

Puede ser:

- informado por el gestor/importación;
- generado automáticamente por Catálogo.

Una vez publicada la identidad comercial, el SKU no puede cambiarse mediante edición ordinaria.

Una recodificación requiere un proceso explícito de migración.

---

# 5. Configuración de características identificadoras

Para un producto con variantes, antes de crear la primera variante se selecciona un conjunto no vacío de características identificadoras.

Reglas:

- solo características `LISTA`;
- activas;
- permitidas por `tipo_producto_id`;
- sin duplicados;
- una vez creada la primera variante, la selección queda inmutable.

Cada variante debe indicar exactamente un `valor_id` para cada característica identificadora.

Ejemplo:

```text
Características identificadoras:
- Talla
- Color

Variante:
- Talla = 42
- Color = Negro
```

Una combinación no puede repetirse dentro del mismo producto aunque la variante anterior esté inactiva.

---

# 6. Requisito 1 — Crear variante

El sistema DEBE permitir crear una variante para un producto con:

```text
tiene_variantes = true
```

## Datos mínimos conceptuales

- producto padre;
- atributos identificadores;
- imagen propia;
- SKU comercial opcional;
- atributos no identificadores opcionales.

## Resultado

La variante:

- recibe `variant_id`;
- recibe o conserva un SKU único;
- se crea inicialmente en `BORRADOR`;
- queda asociada al producto padre.

---

## Escenario — Creación exitosa

**DADO** un producto con variantes y configuración identificadora válida

**CUANDO** el gestor registra una combinación no utilizada

**ENTONCES** Catálogo:

1. genera `variant_id`;
2. valida o genera SKU;
3. registra atributos;
4. registra imagen;
5. crea la variante en `BORRADOR`.

---

## Escenario — Combinación duplicada

**DADO** una variante existente con:

```text
Talla 42 + Negro
```

**CUANDO** se intenta crear otra variante del mismo producto con la misma combinación

**ENTONCES** se rechaza la operación.

---

# 7. Requisito 2 — SKU proporcionado o autogenerado

## SKU proporcionado

Si se informa un SKU:

- debe cumplir formato;
- debe ser globalmente único;
- no debe pertenecer a otro producto o variante.

## SKU omitido

Si no se informa:

- Catálogo genera uno;
- comprueba unicidad;
- devuelve el valor definitivo.

## Colisión

Una colisión:

- no crea la variante;
- no expone una identidad incompleta;
- devuelve un error recuperable.

---

# 8. Requisito 3 — Imagen propia

Cada variante debe poder asociar una imagen propia.

La imagen:

- representa la combinación específica;
- no sustituye la imagen general del producto;
- puede actualizarse sin cambiar identidad.

Un archivo inválido:

- se rechaza;
- no elimina la imagen vigente.

---

# 9. Requisito 4 — Perfil físico del SKU

Catálogo es owner del **perfil físico intrínseco** del SKU.

Para una variante, el perfil físico se identifica por su SKU comercial.

Campos contractuales:

```text
pesoKg
largoCm
anchoCm
altoCm
actualizadoEn
```

La representación HTTP agrupa las dimensiones como:

```json
{
  "pesoKg": 1.4,
  "dimensionesCm": {
    "largo": 35,
    "ancho": 22,
    "alto": 13
  }
}
```

---

# 10. Requisito 4.1 — Unidades

Las unidades contractuales son:

```text
peso -> kilogramos
dimensiones -> centímetros
```

No se admiten unidades ambiguas.

El consumidor no debe inferir si un valor está en gramos, metros, pulgadas u otra unidad.

---

# 11. Requisito 4.2 — Validación del perfil físico

Los valores informados deben cumplir:

```text
pesoKg > 0
largoCm > 0
anchoCm > 0
altoCm > 0
```

No se aceptan:

- valores negativos;
- cero;
- texto no numérico;
- dimensiones sin unidad conocida.

La precisión decimal deberá conservarse de forma suficiente para productos pequeños.

Ejemplos válidos:

```text
pesoKg = 0.25
altoCm = 3
```

---

# 12. Requisito 4.3 — Semántica de las dimensiones

Las dimensiones representan las dimensiones físicas del SKU tal como Catálogo las registra para integración.

No representan:

- caja de despacho;
- bolsa;
- pallet;
- agrupación de varios productos;
- volumen final del envío.

Productos y Ofertas NO define:

```text
tipoEmpaque
cantidadPaquetes
dimensionesPaqueteFinal
volumenLogisticoFinal
```

Estos conceptos pertenecen a **Despacho y Entrega**.

---

# 13. Requisito 4.4 — Perfil físico e identidad

Modificar:

```text
pesoKg
largoCm
anchoCm
altoCm
```

NO cambia:

- `variant_id`;
- SKU;
- atributos identificadores;
- combinación de variante.

El perfil físico es información editable de la variante y no forma parte de su identidad comercial.

---

# 14. Requisito 4.5 — Edición del perfil físico

El gestor autorizado puede actualizar el perfil físico.

## Escenario — Actualización válida

**DADO** una variante existente

**CUANDO** el gestor modifica peso o dimensiones con valores válidos

**ENTONCES**:

- se guarda el nuevo perfil;
- se conserva `variant_id`;
- se conserva SKU;
- se actualiza `actualizadoEn`;
- futuras consultas de Despacho reciben los nuevos valores.

## Escenario — Valor inválido

**DADO** una variante existente

**CUANDO** se informa:

```text
pesoKg = -1
```

o una dimensión `<= 0`

**ENTONCES** se rechaza la actualización y se conserva el perfil anterior.

---

# 15. Requisito 4.6 — Completitud del perfil físico

Una variante puede existir en `BORRADOR` mientras se completa su información.

Sin embargo, cuando otro módulo solicite datos físicos, Catálogo solo puede entregar como perfil utilizable aquel que contenga:

```text
pesoKg
largoCm
anchoCm
altoCm
```

válidos.

La ausencia o incompletitud debe manejarse explícitamente; no se deben inventar valores por defecto.

La regla de activación general de la variante no se amplía automáticamente con nuevos bloqueos no definidos en esta SPEC.

Si en una iteración posterior se decide que el perfil físico será requisito obligatorio de activación, dicha decisión deberá reflejarse explícitamente en SPEC/HU/WF.

---

# 16. Requisito 5 — Consulta física en lote para Despacho

Catálogo debe exponer los datos físicos de varios SKU en una sola consulta.

Contrato HTTP canónico:

```http
POST /api/v1/productos/datos-fisicos/consulta
```

Consumidor previsto:

```text
modulo-despacho
```

Scope propuesto:

```text
productos:fisicos:leer
```

Estado contractual actual:

```text
provisional
```

---

# 17. Requisito 5.1 — Request en lote

La consulta recibe:

```json
{
  "skus": [
    "POL-NEG-M",
    "ZAP-RUN-42"
  ]
}
```

El contrato actual admite hasta:

```text
100 SKU
```

por solicitud.

El límite técnico exacto pertenece a OpenAPI.

---

# 18. Requisito 5.2 — Respuesta física

Respuesta conceptual:

```json
{
  "productos": [
    {
      "sku": "ZAP-RUN-42",
      "estado": "ACTIVO",
      "pesoKg": 1.4,
      "dimensionesCm": {
        "largo": 35,
        "ancho": 22,
        "alto": 13
      },
      "actualizadoEn": "2026-09-28T12:00:00Z"
    }
  ],
  "noEncontrados": []
}
```

La forma exacta pertenece a `api/openapi.yaml`.

---

# 19. Requisito 5.3 — Despacho no recibe ownership

La consulta física NO transfiere ownership.

Despacho puede utilizar peso y dimensiones para:

- decidir empaque;
- agrupar unidades;
- calcular volumen;
- estimar capacidad.

Catálogo continúa siendo owner de los datos físicos propios del SKU.

---

# 20. Requisito 5.4 — Despacho no consulta stock mediante esta API

La consulta:

```http
POST /api/v1/productos/datos-fisicos/consulta
```

NO debe devolver:

- `on_hand`;
- `reserved`;
- `available`;
- reservas;
- pedidos.

Disponibilidad pertenece al contrato de Inventario.

---

# 21. Requisito 6 — Actualización ordinaria de variante

El sistema debe permitir editar:

- imagen;
- atributos no identificadores;
- perfil físico.

No debe permitir editar ordinariamente:

- `variant_id`;
- SKU comercial publicado;
- atributos identificadores.

---

# 22. Requisito 7 — Activación

La variante se crea:

```text
BORRADOR
```

y puede pasar a:

```text
ACTIVA
```

cuando cumple las condiciones funcionales ya establecidas:

- SKU válido;
- atributos identificadores válidos;
- imagen válida;
- producto padre válido;
- precio preparado;
- SKU inicializado en Inventario.

Esta versión no añade el perfil físico como bloqueo universal de activación salvo decisión funcional posterior.

---

# 23. Requisito 8 — Reactivación

Una variante:

```text
INACTIVA
```

puede reactivarse si vuelve a cumplir las mismas condiciones de activación.

La reactivación:

- conserva SKU;
- conserva `variant_id`;
- no reactiva automáticamente al producto padre.

---

# 24. Requisito 9 — Desactivación

El gestor puede desactivar una variante.

La baja es lógica.

Efectos:

- no participa en nuevas ventas;
- no participa en nuevos combos;
- conserva identidad e histórico;
- pedidos anteriores mantienen snapshot.

Si era la última variante activa, el producto padre se inactiva conforme a la regla existente.

---

# 25. Requisito 10 — Consulta de variantes

El sistema debe permitir consultar las variantes de un producto.

Información conceptual:

```text
variant_id
sku
atributos identificadores
atributos no identificadores
imagen
estado
perfil físico cuando esté disponible
```

La disponibilidad de stock NO se almacena en la variante.

Puede obtenerse desde Inventario cuando una vista agregada la necesite.

---

# 26. Requisito 11 — Integración con Inventario

Al crear un SKU vendible, Catálogo solicita/informa la inicialización correspondiente en Inventario.

Inventario es owner de:

```text
on_hand
reserved
available
stock_version
```

Catálogo no persiste ni modifica estos valores.

Una variante no debe exponer stock como si fuera un atributo propio.

---

# 27. Requisito 12 — Integración con Pricing

Pricing puede definir un precio específico por SKU.

Si no existe override, puede aplicar fallback al precio del producto padre según SPEC-013.

Catálogo:

- no persiste el precio vigente;
- no calcula vigencias;
- no decide promociones.

---

# 28. Requisito 13 — Carga masiva

Cuando Bulk crea una variante:

- identifica el producto;
- identifica la combinación;
- Catálogo genera `variant_id`;
- valida o genera SKU;
- devuelve correlación de resultado.

La carga masiva no puede:

- recodificar SKU mediante actualización ordinaria;
- cambiar atributos identificadores históricos.

Si el formato Bulk incorpora en el futuro perfil físico, deberá usar los mismos campos y validaciones contractuales de esta SPEC.

No se deben crear reglas físicas alternativas solo para Bulk.

---

# 29. Elegibilidad comercial

Una variante `ACTIVA` solo es comercialmente utilizable cuando su producto padre también se encuentra en estado permitido.

Conceptualmente:

```text
Padre ACTIVO
+
Variante ACTIVA
+
Pricing preparado
+
Inventario inicializado
=
SKU elegible
```

El perfil físico no modifica por sí mismo el ownership o el saldo.

---

# 30. Datos que pertenecen a Catálogo

Catálogo es owner de:

```text
product_id
variant_id
sku_base
sku
atributos
imagen
estado
slug
perfil físico
```

Para el perfil físico:

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
precio_regular
precio_oferta
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

## Ventas

```text
pedido
pago
estado del pedido
reembolso
```

---

# 32. Modelo conceptual del perfil físico

Relación:

```text
SKU VENDIBLE
    |
    | puede tener
    v
PERFIL FÍSICO
```

Cardinalidad conceptual:

```text
SKU 1 -> 0.1 PERFIL FÍSICO
```

En el modelo lógico puede materializarse como:

```text
sku_physical_profiles
```

o estructura equivalente dentro de `catalog`.

No se comparte tabla con Despacho.

---

# 33. Requisitos no funcionales

## 33.1. Rendimiento

- consulta individual de variantes eficiente;
- listado paginable cuando corresponda;
- consulta física de Despacho en lote;
- evitar una llamada HTTP por cada SKU del pedido.

## 33.2. Seguridad

Crear, editar, activar, reactivar y desactivar requiere una identidad autenticada y autorización suficiente conforme al contrato vigente de Seguridad.

Las respuestas HTTP protegidas se normalizan como:

```text
401 -> TOKEN_INVALIDO
403 -> SCOPE_INSUFICIENTE
```

`TOKEN_INVALIDO` aplica cuando la petición no puede autenticarse mediante un token utilizable.

`SCOPE_INSUFICIENTE` aplica cuando la identidad está autenticada pero no posee autorización suficiente para la operación.

El código no obliga a exponer al consumidor el permiso o scope exacto faltante.

La consulta física para Despacho requiere identidad técnica de servicio.

Para:

```text
POST /api/v1/productos/datos-fisicos/consulta
```

el scope propuesto continúa siendo:

```text
productos:fisicos:leer
```

hasta que Seguridad lo registre/homologue definitivamente. Esa provisionalidad no modifica la semántica estable de `401` y `403`.

## 33.3. Auditoría

Registrar:

- creación;
- edición;
- cambio de imagen;
- cambio de perfil físico;
- cambio de estado.

Como mínimo:

```text
actor
fecha/hora
variante
tipo de cambio
```

## 33.4. Disponibilidad

Las lecturas de variantes y la consulta física deben ser suficientemente disponibles para los consumidores del catálogo.

## 33.5. Escalabilidad

La implementación debe soportar:

- crecimiento del número de variantes;
- múltiples consumidores;
- consultas en lote.

---

# 34. Errores y códigos de aplicación

El catálogo canónico pertenece a:

```text
api/catalogo-errores.md
```

Códigos relevantes para esta capacidad:

```text
VALIDACION
TOKEN_INVALIDO
SCOPE_INSUFICIENTE
PRODUCTO_NO_ENCONTRADO
PRODUCTO_NO_ADMITE_VARIANTES
VARIANTE_NO_ENCONTRADA
COMBINACION_DUPLICADA
SKU_DUPLICADO
SKU_INVALIDO
ATRIBUTO_IDENTIFICADOR_INVALIDO
IMAGEN_INVALIDA
PERFIL_FISICO_INVALIDO
DATOS_FISICOS_INCOMPLETOS
VERSION_CONFLICT
ERROR_INTERNO
SERVICIO_NO_DISPONIBLE
```

La representación HTTP exacta pertenece a OpenAPI y utiliza:

```text
application/problem+json
```

Los consumidores deben ramificar por `code`, no por `title` ni `detail`.

El código histórico:

```text
SIN_AUTORIZACION
```

queda retirado de nuevos contratos. Cuando la identidad está autenticada pero no cuenta con autorización suficiente se utiliza:

```text
SCOPE_INSUFICIENTE
```

---

# 35. Escenarios adicionales del perfil físico

## Escenario A — Registrar perfil físico

**DADO** una variante `ZAP-RUN-42`

**CUANDO** el gestor registra:

```text
peso = 1.4 kg
largo = 35 cm
ancho = 22 cm
alto = 13 cm
```

**ENTONCES** Catálogo conserva esos valores asociados al SKU.

---

## Escenario B — Editar perfil sin cambiar SKU

**DADO** una variante existente

**CUANDO** se corrige el peso de:

```text
1.4 kg
```

a:

```text
1.35 kg
```

**ENTONCES**:

- el SKU no cambia;
- `variant_id` no cambia;
- el perfil queda actualizado.

---

## Escenario C — Peso inválido

**DADO** una variante

**CUANDO** se intenta registrar:

```text
peso = 0
```

**ENTONCES** se rechaza el perfil.

---

## Escenario D — Dimensión inválida

**DADO** una variante

**CUANDO** se intenta registrar:

```text
alto = -2 cm
```

**ENTONCES** se rechaza la actualización.

---

## Escenario E — Consulta física de Despacho

**DADO** dos SKU válidos con perfil completo

**CUANDO** `modulo-despacho` realiza la consulta en lote

**ENTONCES** Catálogo devuelve peso y dimensiones de ambos.

---

## Escenario F — SKU no encontrado en consulta física

**DADO** una consulta con:

```text
SKU-VALIDO
SKU-INEXISTENTE
```

**CUANDO** se procesa la solicitud

**ENTONCES** la respuesta distingue los SKU encontrados de los no encontrados sin fallar necesariamente todo el lote.

La representación exacta sigue OpenAPI.

---

## Escenario G — Token no válido

**DADO** una operación protegida sobre variantes

**CUANDO** la petición no contiene un token utilizable según el contrato de Seguridad

**ENTONCES** la API responde:

```text
401
TOKEN_INVALIDO
```

sin crear, editar ni cambiar el estado de la variante.

---

## Escenario H — Identidad sin autorización suficiente

**DADO** una identidad autenticada

**CUANDO** intenta crear, editar, activar, reactivar o desactivar una variante sin autorización suficiente

**ENTONCES** la API responde:

```text
403
SCOPE_INSUFICIENTE
```

sin ejecutar la mutación y sin necesidad de revelar el permiso exacto faltante.

---

# 36. Fuera de alcance

Queda fuera de esta SPEC:

- persistencia de precios;
- gestión de stock;
- reservas;
- consumo de inventario;
- promociones;
- combos;
- checkout;
- pedidos;
- definición del empaque;
- cantidad de paquetes;
- optimización logística;
- cálculo de rutas;
- capacidad de vehículos;
- edición avanzada de imágenes;
- recodificación ordinaria de SKU;
- perfil físico de producto simple como formulario propio, que debe alinearse en SPEC-003.

---

# 37. Dependencias

| Dependencia | Uso |
|---|---|
| SPEC-003 | Producto padre, `sku_base`, `tiene_variantes` |
| SPEC-009 | Características |
| SPEC-010 | Tipo de Producto–Característica |
| SPEC-013 | Pricing |
| SPEC-015 | Inicialización/consulta de Inventario |
| Despacho | Consumo de datos físicos |
| Seguridad | Autenticación/autorización; `401 TOKEN_INVALIDO` y `403 SCOPE_INSUFICIENTE` en operaciones protegidas |
| OpenAPI | Contrato técnico HTTP |

---

# 38. Criterio de completitud

La funcionalidad se considera correctamente implementada cuando:

- [ ] solo productos `tiene_variantes=true` crean variantes mediante esta capacidad;
- [ ] cada variante tiene `variant_id` estable;
- [ ] SKU es único;
- [ ] puede informarse o autogenerarse;
- [ ] la combinación identificadora es única;
- [ ] atributos identificadores son inmutables;
- [ ] imagen propia está soportada;
- [ ] estados BORRADOR/ACTIVA/INACTIVA funcionan;
- [ ] desactivar última variante activa aplica la regla del padre;
- [ ] Catálogo no persiste stock ni precio;
- [ ] se puede registrar y editar perfil físico;
- [ ] `pesoKg`, `largoCm`, `anchoCm` y `altoCm` se validan;
- [ ] kg/cm son las unidades contractuales;
- [ ] modificar perfil físico no cambia SKU ni `variant_id`;
- [ ] la consulta física en lote coincide con `api/openapi.yaml`;
- [ ] Despacho no obtiene ownership de los datos;
- [ ] Productos no modela `tipoEmpaque`;
- [ ] existen pruebas de validación y contrato para la consulta física;
- [ ] los cambios de perfil físico quedan auditados;
- [ ] respuestas protegidas usan `TOKEN_INVALIDO` para 401;
- [ ] respuestas protegidas usan `SCOPE_INSUFICIENTE` para 403;
- [ ] `SIN_AUTORIZACION` no se emite en contratos nuevos;
- [ ] códigos HTTP coinciden con OpenAPI y `api/catalogo-errores.md`.
