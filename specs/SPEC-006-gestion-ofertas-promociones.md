# SPEC-006 — Especificación: Gestión de ofertas y promociones

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** HU [HU-006](./hu/HU-006-gestion-ofertas-promociones.md) | Wireframe [WF-006](./wireframes/flows/WF-006-gestion-ofertas-promociones.md)

## 1. Contexto

El proyecto consiste en un Marketplace Multicanal para productos deportivos, organizado en módulos integrados mediante APIs. Dentro del Módulo de Productos y Ofertas, una funcionalidad obligatoria es la gestión de ofertas y promociones.

Esta capacidad concentra la lógica para registrar promociones, validar fechas, estado y condiciones, calcular descuentos y resolver conflictos cuando más de un beneficio puede aplicarse a una compra.

## 2. Propósito

Permitir al Gestor Comercial administrar promociones y permitir que los canales de venta consulten y evalúen correctamente los beneficios aplicables a productos y compras.

## 3. Alcance

Incluye:

- registrar, consultar, modificar, activar y desactivar promociones;
- asociar promociones a productos completos o a SKUs vendibles específicos;
- descuentos por porcentaje o monto fijo;
- modalidad obligatoria `AUTOMATICA` o `CUPON`;
- vigencia, estado y alcance;
- `prioridad`;
- canales habilitados;
- política explícita de combinación;
- evaluación de promociones aplicables;
- resolución determinista de múltiples beneficios;
- preservación del beneficio registrado en pedidos ya confirmados.

Esta funcionalidad **no administra** el precio maestro del producto, el histórico de Pricing, cargas masivas de precios, cupones como códigos, combos, stock, pedidos, pagos ni despacho.

## 4. Requisitos

### Requisito 1: Registrar promociones

El sistema DEBE permitir registrar una promoción indicando como mínimo:

- nombre;
- tipo de descuento;
- valor;
- fecha/hora de inicio y fin;
- modalidad `AUTOMATICA` o `CUPON`;
- estado inicial `ACTIVA` o `INACTIVA`;
- alcance: uno o más productos y/o SKUs vendibles;
- `prioridad`;
- `canales_habilitados`;
- política de combinación.

La política de combinación declara expresamente si la promoción puede coexistir con:

- oferta propia de Pricing;
- otra promoción automática;
- cupón.

Por defecto las combinaciones son `false`.

La fecha de inicio DEBE ser anterior a la fecha de fin.

Una lista vacía de canales se interpreta como todos los canales soportados por el contrato vigente.

### Requisito 2: Validar valores de descuento

#### Porcentaje

```text
0 < porcentaje <= 100
```

#### Monto fijo

```text
monto_fijo > 0
```

El monto fijo se aplica **una sola vez sobre el subtotal elegible de la evaluación**, no por unidad.

Ningún descuento puede producir un importe final negativo. Si el descuento supera el subtotal elegible, se limita a dicho subtotal.

### Requisito 3: Modificar promociones

El sistema DEBE permitir modificar la configuración editable de una promoción.

Si una modificación es inválida:

- no se persiste;
- se conserva la última configuración válida;
- se informa la causa al gestor.

Modificar una promoción no reescribe descuentos ya registrados en pedidos confirmados.

### Requisito 4: Activar y desactivar promociones

El sistema DEBE permitir activar o desactivar una promoción sin eliminarla.

Una promoción inactiva:

- no participa en nuevas evaluaciones;
- conserva su configuración e histórico.

Desactivar una promoción no modifica pedidos ya confirmados.

### Requisito 5: Evaluar promociones aplicables

Solo participan promociones que:

- correspondan al producto o SKU evaluado;
- estén activas;
- estén dentro de su vigencia;
- estén habilitadas para el canal solicitante.

La base monetaria de cada SKU se obtiene del precio regular vigente de Pricing.

La oferta propia de Pricing, promociones automáticas y cupones solo se combinan cuando las políticas configuradas lo permiten.

Una ausencia de autorización expresa para combinar se interpreta como incompatibilidad.

### Requisito 6: Resolver múltiples promociones automáticas

Cuando varias promociones `AUTOMATICA` sean válidas:

1. se construyen solo combinaciones permitidas;
2. no se aplica dos veces la misma promoción;
3. las promociones compatibles que actúan sobre las mismas líneas siguen orden determinista por `prioridad` ascendente y luego identificador estable;
4. cada cálculo usa decimal exacto;
5. entre alternativas válidas se selecciona la que produzca el menor importe final para la misma cesta.

Si ninguna combinación múltiple es válida, se conserva la mejor alternativa individual.

### Requisito 7: Resolver promoción automática, cupón y oferta propia de Pricing

Una oferta propia de Pricing, una promoción automática y un cupón pueden coexistir **solo si las políticas de combinación lo permiten**.

El evaluador:

- compara alternativas sobre la misma cesta;
- mantiene intactas las líneas no elegibles;
- evita descontar dos veces la misma base;
- selecciona el menor importe final válido.

En empate exacto:

1. se prefiere la alternativa que no consume cupón;
2. luego la de menor `prioridad`;
3. finalmente el identificador estable.

Un cupón solo consume uso si forma parte del beneficio finalmente seleccionado y su consumo posterior es confirmado por el flujo correspondiente.

### Requisito 7.1: Alcance por producto o SKU

Una promoción puede configurarse:

- a nivel de producto, aplicando a sus SKUs vendibles activos; o
- a nivel de SKU específico.

Si una misma promoción incluye un producto y uno de sus SKU de forma explícita, el evaluador deduplica el alcance y aplica el beneficio una sola vez por unidad elegible.

### Requisito 8: Consultar promociones

El sistema DEBE permitir consultar como mínimo:

- nombre;
- modalidad;
- tipo de descuento;
- valor;
- alcance;
- estado;
- vigencia;
- prioridad;
- canales habilitados;
- política de combinación.

### Requisito 9: Exponer evaluación mediante API

La evaluación debe devolver como mínimo:

- identificador de la promoción seleccionada, si existe;
- importe original;
- descuento aplicado;
- importe resultante;
- motivo cuando no existe un beneficio aplicable.

La evaluación es una capacidad de API/negocio consumida por los canales. **No requiere una pantalla administrativa independiente de “Evaluar compra”.**

### Requisito 10: Cambio de modalidad

La modalidad `AUTOMATICA | CUPON` forma parte de la naturaleza comercial de la promoción.

Solo puede editarse cuando la promoción:

- está inactiva;
- nunca fue activada;
- no tiene cupones asociados;
- no posee usos históricos asociados al flujo de cupón.

En los demás casos, para cambiar de modalidad se crea una nueva promoción.

### Política comercial compartida de precios y descuentos

Pricing es propietario de:

- `precio_regular`;
- `precio_oferta`;
- moneda;
- vigencia;
- scope por canal.

Promociones es propietario de:

- reglas de promoción;
- alcance;
- prioridad;
- canales;
- política de combinación;
- evaluación de beneficios promocionales.

Pricing no evalúa cupones ni promociones. Promociones no modifica el precio maestro de Pricing.

La combinación final con datos del pedido continúa sujeta a los contratos homologados con Ventas/Postventa; esta SPEC no inventa comandos o eventos externos no publicados.

## 5. Requisitos no funcionales

- Seguridad: las operaciones administrativas requieren autenticación y autorización; los códigos granulares de permiso pertenecen a Seguridad y Usuarios.
- Errores HTTP protegidos: `401 TOKEN_INVALIDO` y `403 SCOPE_INSUFICIENTE` conforme al contrato transversal.
- Cálculo monetario: decimal exacto y redondeo definido por la moneda.
- Integración: no existe acceso directo a bases de datos de otros bounded contexts.
- Persistencia: un cambio administrativo rechazado conserva la última configuración válida.
- Observabilidad: las operaciones deben poder correlacionarse con el contexto de solicitud sin exponer identificadores técnicos innecesarios en la interfaz.
- El frontend no es autoridad de las reglas de elegibilidad; el backend las revalida.

## 6. Fuera de alcance

- Administración de códigos, límites y consumo de cupones — SPEC-005.
- Gestión de combos — SPEC-002.
- Precio regular/oferta maestro, programación, importación e histórico de Pricing — SPEC-013.
- Auditoría de precios — SPEC-014.
- Stock y reservas — Inventario.
- Cobro, checkout y ciclo de pedido — Ventas/Postventa y canales.
- Despacho, empaque y tarifas logísticas — Despacho.
- Promociones 2x1 u otras mecánicas no descritas en esta SPEC.

## 7. Contrato HTTP relacionado

El OpenAPI contempla:

```text
GET  /api/v1/promociones
POST /api/v1/promociones
GET  /api/v1/promociones/{promocionId}
PATCH /api/v1/promociones/{promocionId}
POST /api/v1/promociones/{promocionId}/activar
POST /api/v1/promociones/{promocionId}/desactivar

GET  /api/v1/promociones/administracion
POST /api/v1/promociones/evaluar
```

Las rutas administrativas derivadas permanecen marcadas como internas/provisionales hasta congelar el contrato final.

## Criterio de completitud

La capacidad se considera correctamente implementada cuando:

- puede administrar promociones sin mezclar responsabilidades de Pricing;
- valida descuentos, vigencia, alcance y estado;
- soporta modalidad, prioridad, canales y política de combinación;
- evalúa solo combinaciones permitidas;
- conserva pedidos históricos;
- no incorpora una UI administrativa de evaluación;
- no incluye carga masiva, programación o histórico de precios dentro de Promociones.
