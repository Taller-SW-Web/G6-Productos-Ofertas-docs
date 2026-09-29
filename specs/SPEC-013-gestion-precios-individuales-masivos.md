# SPEC-013 — Especificación: Gestión de precios individuales y masivos

**Responsable:** Leonardo Vera Rodríguez  
**Rama:** vera  
**Trazabilidad:** HU [HU-013](./hu/HU-013-gestion-precios-individuales-masivos.md) | Wireframe [WF-013](./wireframes/flows/WF-013-gestion-precios-individuales-masivos.md)
**Contrato HTTP canónico:** [`./api/openapi.yaml`](./api/openapi.yaml) — `0.3.5-p0`  
**Contrato asíncrono canónico:** [`./asyncapi/asyncapi.yaml`](./asyncapi/asyncapi.yaml) — `0.2.1-p0`  
**Versión documental:** v1.1

## 1. Contexto

En el Marketplace Multicanal de artículos deportivos, los precios pueden variar por campañas comerciales, tipo de cambio, liquidaciones o acuerdos con proveedores. El gestor comercial necesita actualizar y programar precios de forma individual o masiva, consultar el precio oficial en un instante histórico y mantener trazabilidad temporal.

Pricing es propietario del precio regular, de la oferta propia de Pricing, moneda, vigencias, alcance por canal y versión.

Esta capacidad **no administra costos ni márgenes contables**, por lo que no afirma prevenir márgenes negativos.

## 2. Propósito

Permitir al gestor comercial:

- consultar precios vigentes;
- modificar precio regular y oferta;
- programar vigencias futuras;
- consultar precios históricos mediante `as-of`;
- procesar archivos CSV/XLSX;
- operar con concurrencia optimista;
- registrar el motivo de cambio;
- propagar cambios confirmados mediante `pricing.price.changed`.

## 3. Alcance

Incluye:

- precio base a nivel de producto;
- override opcional por SKU de variante;
- producto simple usando el precio de su producto asociado al `sku_base`;
- `precio_regular > 0`;
- `0 < precio_oferta < precio_regular` cuando exista;
- `valid_from`;
- `valid_until` opcional;
- moneda;
- `channel_id` opcional, donde `null` representa precio global;
- consulta histórica por timestamp;
- programación sin intervalos superpuestos;
- importación CSV/XLSX exclusiva de Pricing;
- modo `All-or-Nothing` por defecto;
- `allow_partial=true` como alternativa;
- prevalidación;
- procesamiento asíncrono;
- reporte de errores;
- `price_version`;
- `accion_precio_oferta = CONSERVAR | ESTABLECER | ELIMINAR`;
- evento `pricing.price.changed` posterior al commit.

## 4. Requisitos

### Requisito 1: Actualización de precio individual y motivo obligatorio

El sistema DEBE permitir modificar el precio regular y/o la oferta propia de Pricing de un SKU, exigiendo:

- `motivo_cambio`;
- `price_version` cuando la escritura parte de una lectura previa;
- validaciones comerciales antes de persistir.

La operación debe rechazar:

```text
precio_regular <= 0
precio_oferta <= 0
precio_oferta >= precio_regular
motivo_cambio vacío
price_version obsoleto
```

Una modificación confirmada:

1. persiste en Pricing;
2. incrementa la versión;
3. registra auditoría;
4. publica `pricing.price.changed` después del commit.

Los nombres `PRICING_READ`, `PRICING_WRITE` y `PRICING_BULK` pueden utilizarse como **propuesta interna de capacidades**, pero no se consideran permisos oficiales hasta que Seguridad y Usuarios los publique.

#### Escenario: Actualización exitosa

- **DADO** un SKU con regular S/ 120 y `price_version=8`
- **CUANDO** un gestor autorizado solicita S/ 150 con motivo válido y versión 8
- **ENTONCES** Pricing persiste el cambio, incrementa versión, publica el hecho después del commit y responde HTTP 200.

#### Escenario: Conflicto de versión

- **DADO** que el gestor leyó la versión 8
- **Y** otra operación ya produjo la versión 9
- **CUANDO** intenta guardar usando versión 8
- **ENTONCES** se rechaza con conflicto y no se sobrescribe el valor vigente.

### Requisito 1.1: Resolver precio efectivo por SKU, tiempo y canal

El sistema DEBE resolver el precio vigente de cualquier **SKU vendible** considerando:

- fecha/hora;
- moneda;
- `channel_id` cuando se solicite.

Reglas:

- producto simple → usa el precio del producto asociado a `sku_base`;
- variante con override → usa el precio del SKU;
- variante sin override → hereda el precio vigente del producto padre;
- si existe una vigencia específica para el canal solicitado, se usa conforme a su prioridad;
- si no existe, se usa el precio global (`channel_id=null`);
- si no se indica canal, la consulta resuelve el precio global.

La respuesta identifica como mínimo:

```text
precio_regular
precio_oferta opcional
moneda
channel_id efectivo o null
valid_from
valid_until
price_version
vigencia_id
origen del precio: PRODUCTO | SKU_OVERRIDE
```

`vigencia_id` identifica la vigencia temporal que respalda el resultado, especialmente en consultas históricas.

### Requisito 2: Programación de precios futuros

El sistema DEBE permitir programar un precio con:

- tipo de precio;
- importe;
- moneda;
- `channel_id` opcional;
- `valid_from`;
- `valid_until` opcional;
- `motivo_cambio`.

Para el mismo objetivo, tipo de precio, moneda y canal no se admiten intervalos superpuestos.

Una vigencia futura:

```text
estado = SCHEDULED
```

y no altera el precio actual hasta alcanzar `valid_from`.

Cuando entra en vigor, Pricing actualiza su lectura operativa y publica `pricing.price.changed` después del commit.

### Requisito 3: Consulta histórica oficial — As-Of

El sistema DEBE permitir consultar el precio oficial que un SKU tenía en un instante determinado.

Contrato REST en español:

```http
GET /api/v1/precios/skus/{sku}?at={timestamp}
```

El parámetro de canal es opcional:

```text
canal omitido -> resolución global
canal informado -> scope específico con fallback global
```

La respuesta devuelve el precio vigente para ese instante y su `vigencia_id`.

La consulta es solo lectura y no modifica el histórico.

#### Escenario: Consulta histórica

- **DADO** un SKU cuyo regular fue S/ 80 en agosto y S/ 100 desde septiembre
- **CUANDO** se consulta `GET /api/v1/precios/skus/{sku}?at=2026-08-15T12:00:00Z`
- **ENTONCES** se devuelve S/ 80, moneda, scope efectivo, vigencia y `vigencia_id`.

### Requisito 4: Carga masiva exclusiva de Pricing

Se admite CSV/XLSX con columnas obligatorias:

```text
sku
precio_regular
motivo_cambio
```

y opcionales:

```text
precio_oferta
accion_precio_oferta
channel_id
valid_from
valid_until
price_version
```

Una fila puede fallar por:

- SKU inexistente;
- precio inválido;
- acción de oferta inválida;
- versión obsoleta;
- scope inválido;
- vigencia superpuesta;
- motivo ausente.

### Requisito 4.1: Semántica de la oferta opcional

`accion_precio_oferta` acepta:

```text
CONSERVAR
ESTABLECER
ELIMINAR
```

Reglas:

- acción ausente o vacía = `CONSERVAR`;
- `CONSERVAR` exige `precio_oferta` vacío y mantiene el valor actual;
- `ESTABLECER` exige oferta >0 y menor que el regular final;
- `ELIMINAR` exige `precio_oferta` vacío y retira expresamente la oferta;
- una celda vacía por sí sola **nunca elimina** la oferta;
- si el nuevo regular es incompatible con la oferta que se conservaría, la fila se rechaza.

### Requisito 4.2: Prevalidación y procesamiento asíncrono

El flujo HTTP canónico es:

```text
POST /api/v1/precios/importaciones/prevalidar
-> 200 con resultado de prevalidación

POST /api/v1/precios/importaciones
-> 202 Accepted + batch_id

GET /api/v1/precios/importaciones/{batchId}
-> estado final o en progreso

GET /api/v1/precios/importaciones/{batchId}/reporte
-> reporte CSV cuando corresponda
```

El modo tolerante se expresa únicamente en el **estado final del lote**; la solicitud de admisión sigue siendo asíncrona.

### Requisito 4.3: Atomicidad del lote

#### `allow_partial=false` — predeterminado

La operación es All-or-Nothing **dentro de Pricing**.

Si una fila es inválida, el lote finaliza rechazado y no se aplica ninguna fila.

#### `allow_partial=true`

Pricing aplica las filas válidas y reporta las inválidas.

Esto no promete atomicidad con Catálogo o Inventario.

### Requisito 5: Precio base del producto y override de SKU

El producto posee su precio base.

Una variante puede:

- no tener override → hereda el precio del producto;
- tener override → Pricing resuelve el precio específico del SKU.

El contrato administrativo cubre tanto producto como SKU.

Una actualización de precio no modifica identidad de producto ni SKU.

### Requisito 6: Inicialización de precio y auditoría

Al crear un producto, Catálogo necesita preparar su precio base en Pricing mediante una coordinación idempotente.

La operación conceptual contiene:

- `product_id`;
- `sku_base`;
- `precio_regular`;
- moneda;
- `channel_id=null`;
- `motivo_cambio=ALTA_PRODUCTO`;
- actor;
- correlación.

Pricing registra el primer precio con:

```text
tipo_operacion = CREACION
precio_anterior = null
variacion_porcentual = null
```

y publica `pricing.price.changed` después de persistir.

**Estado contractual:** la necesidad está definida; el nombre/payload definitivo del comando Catálogo → Pricing inicial sigue pendiente de formalización en AsyncAPI.

### Requisito 7: Diferenciar importaciones

La importación de esta SPEC:

```text
solo Pricing
```

La importación general de SPEC-001:

```text
Catálogo + Pricing + Inventario
```

Por tanto:

- la carga exclusiva de Pricing puede garantizar atomicidad local;
- SPEC-001 usa consistencia eventual entre dominios;
- `pricing.price.changed` es un hecho posterior al commit, no un comando de Bulk.

### Requisito 8: Guardrail de variación extraordinaria

El sistema puede calcular el porcentaje de variación respecto del precio vigente y mostrar una advertencia reforzada cuando supera un umbral configurable.

La advertencia:

- no sustituye una validación obligatoria;
- no afirma conocer costo o margen;
- no bloquea por sí sola salvo que una política adicional sea formalizada.

## 5. Requisitos no funcionales

- actualización individual: objetivo de referencia `< 300 ms`;
- consulta vigente/histórica: objetivo de referencia `< 100 ms`;
- 5,000 registros se mantiene como **benchmark de rendimiento**, no como límite de rechazo de filas mientras no exista una regla explícita;
- tamaño máximo del archivo de Pricing: 10 MB conforme a la fuente actual;
- validación de extensión/MIME en backend;
- operaciones protegidas por token emitido por Seguridad;
- `401 -> TOKEN_INVALIDO`;
- `403 -> SCOPE_INSUFICIENTE`;
- permisos granulares de Pricing pendientes de publicación oficial por Seguridad;
- histórico temporal separado de la tabla operativa;
- `pricing.price.changed` mediante Outbox después del commit;
- importes con decimal exacto.

## 6. Fuera de alcance

- Promociones, cupones y combos.
- Checkout/cobro.
- Costos logísticos.
- Costeo y margen contable.
- Descarga de plantilla propia de Pricing si no está definida por la fuente.
- Exportación general de precios.
- Mapeo dinámico de columnas.
- Cancelación de una programación mientras no exista regla aprobada.

## 7. Estado contractual vigente

El contrato HTTP canónico de esta capacidad es OpenAPI `0.3.5`. La semántica definida por esta SPEC ya está reflejada en el contrato vigente:

1. `canal` es opcional en `GET /precios/skus/{sku}`;
2. el alcance global se representa con canal ausente y `channel_id=null`;
3. la respuesta vigente/histórica identifica `vigencia_id` cuando corresponde;
4. las rutas de esta capacidad utilizan el recurso `/precios`;
5. el flujo masivo es asíncrono: prevalidación `200`, admisión `202` y consulta posterior del estado/resultado del lote;
6. el resultado parcial se expresa como estado final del proceso y no mediante una variante síncrona paralela.

Por tanto, estos puntos **ya no son pendientes de OpenAPI**. Cualquier evolución posterior debe modificar primero la regla funcional correspondiente y después actualizar el contrato canónico, evitando mantener variantes documentales paralelas.

Permanecen deliberadamente fuera de este cierre únicamente las dependencias ya identificadas con otros módulos, como la publicación oficial de permisos granulares por Seguridad y la formalización del comando Catálogo → Pricing para la preparación inicial.

## Criterio de completitud

Esta capacidad se considera documentada cuando se mantiene la siguiente coherencia:

- recurso HTTP `/precios`;
- alcance global con canal ausente/`channel_id=null`;
- consulta histórica con identificación de vigencia;
- procesamiento masivo `200` prevalidación → `202` admisión → consulta de estado;
- ausencia de una variante síncrona adicional para el resultado parcial;
- permisos `PRICING_*` tratados como nombres propuestos hasta homologación con Seguridad;
- versionado, vigencias, auditoría y publicación por Outbox preservados.

**Estado:** Cumplido por OpenAPI `0.3.5-p0` y los contratos asociados.
