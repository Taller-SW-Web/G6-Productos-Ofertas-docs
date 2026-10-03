# Supuestos de trabajo — Hito 2

> **DOCUMENTO INTERNO DE COORDINACIÓN — NO PUBLICAR EN EL REPOSITORIO**
>
> Este archivo **no constituye una fuente de verdad funcional, contractual, arquitectónica ni de datos**.
> Su único objetivo es permitir que el equipo avance con el modelo físico, migraciones, validaciones y presentación del Hito 2 mientras se cierran acuerdos intermodulares.
>
> Si este documento contradice una fuente oficial, **prevalece siempre la fuente oficial**.
>
> Este archivo tampoco debe utilizarse como justificación para introducir en el esquema oficial campos, restricciones o relaciones que no estén respaldados por la documentación vigente.

**Fecha de creación:** 2026-10-02  
**Última auditoría interna:** 2026-10-02  
**Ámbito:** Productos y Ofertas — Hito 2  
**Uso:** coordinación privada del equipo de desarrollo  
**Estado del documento:** temporal / interno  
**Referencia de auditoría de Productos y Ofertas:** `master @ 234c62ec5146baf9c4e088bef30fe33660b28d48`

Repositorios externos contrastados cuando afectan estos supuestos:

- Despacho: `main @ abbdd04e62787cb183c1eac33eeecb7ad065e9d9`
- Chatbot: `main @ 422751472a10e4457aeb08cda37102559d38b0b6`
- Retail: `main @ 7f8a67ae1189fc5fd35ad923da7ce386492f143a`
- Ventas/Postventa: `main @ a4a491f84c9b0c3f467fde01eb6019166f56b065`
- Seguridad: `main @ 15796e06d3ac6c5ee2f72c727b700a1523861fd2`

---

# 1. Regla principal

Este archivo existe para responder únicamente:

> **¿Qué podemos asumir provisionalmente para no detener Hito 2 sin convertir esa suposición en una regla oficial?**

No responde qué debe hacer definitivamente el sistema.

Las fuentes oficiales continúan siendo las definidas por el repositorio, entre ellas:

- reglas funcionales → `specs/SPEC-XXX-*.md`;
- contrato HTTP → `api/openapi.yaml`;
- mensajería → `asyncapi/asyncapi.yaml`;
- ownership e integración → `Contrato_Api.md`;
- arquitectura → `Arquitectura.md`;
- ownership conceptual → `Modelo_Conceptual.md`.

---

# 2. Reglas de uso

1. No publicar este documento en el repositorio oficial.
2. No citar este archivo desde SPEC, HU, OpenAPI, Arquitectura o contratos.
3. No presentar una suposición como acuerdo confirmado con otro módulo.
4. No crear `CHECK`, `UNIQUE`, FK o restricciones rígidas basadas únicamente en una suposición de este archivo.
5. Cuando la fuente oficial ya resuelva un punto, debe marcarse `RESUELTO` aquí y dejar de utilizarse como supuesto.
6. Si una decisión sigue abierta, el modelo físico debe favorecer extensibilidad sobre una interpretación rígida.
7. Nunca crear FK entre bounded contexts o módulos distintos.
8. Identificadores externos se conservan como referencias escalares, no como FK cross-service.
9. Ante duda, implementar únicamente lo que exige la fuente oficial del bounded context.

---

# 3. Estados

- `TEMPORAL`: se utiliza solo para avanzar en Hito 2.
- `EN_VALIDACION`: existe evidencia parcial o una discrepancia intermodular activa.
- `RESUELTO`: ya existe respaldo suficiente en fuentes oficiales; deja de ser un supuesto.
- `DESCARTADO`: no debe seguir utilizándose, ya sea porque era incorrecto, redundante o peligroso para el modelo.

---

# 4. Resultado de la nueva auditoría

| ID | Tema | Estado anterior | Estado actual | Acción |
|---|---|---:|---:|---|
| H2-A-001 | Una ubicación de fulfillment por pedido | TEMPORAL | EN_VALIDACION | Mantener solo como escenario; **no imponerlo en la BD** |
| H2-A-002 | Inventario es owner de Ubicación | TEMPORAL | RESUELTO | Ownership ya oficial |
| H2-A-003 | `Retail.tiendaId` ↔ `location_id` | TEMPORAL | TEMPORAL | Mantener sin FK ni igualdad obligatoria |
| H2-A-004 | PEN como moneda de Hito 2 | TEMPORAL | TEMPORAL | Solo fixtures/demo; no crear `CHECK currency='PEN'` |
| H2-A-005 | Precio final / IGV / 2 decimales | TEMPORAL | TEMPORAL | No codificar semántica tributaria en Pricing |
| H2-A-006 | Código de barras por SKU | TEMPORAL | EN_VALIDACION | Retail lo requiere, Productos aún no lo formaliza |
| H2-A-007 | TTL configurable de reserva | TEMPORAL | RESUELTO | `expires_at` + configuración ya están documentados |
| H2-A-008 | Pickup no condiciona BD Hito 2 | TEMPORAL | EN_VALIDACION | Retail lo contempla; Despacho actual no publica Pickup |
| H2-A-009 | Persistencia de combos para Hito 2 | TEMPORAL | RESUELTO | Scope de `combos-svc` ya definido |
| H2-A-010 | Stock inicial por carga/ajuste | TEMPORAL | RESUELTO | SPEC-001 ya lo formaliza |
| H2-A-011 | No split fulfillment | TEMPORAL | DESCARTADO | Duplicaba H2-A-001 y podía generar una constraint incorrecta |
| H2-A-012 | SKU como identidad vendible de Inventario | TEMPORAL | RESUELTO | SPEC/Contrato/Modelo ya lo exigen |

**Conclusión de la auditoría:** no hace falta agregar nuevas suposiciones de BD.  
La actualización principal consiste en **retirar como supuestos varias reglas que ya son oficiales y evitar que los supuestos restantes se conviertan en restricciones físicas prematuras**.

---

# 5. Supuestos todavía activos

## H2-A-001 — Escenario de una sola ubicación de fulfillment

**Estado:** `EN_VALIDACION`

### Uso permitido en Hito 2

Para fixtures, validaciones y presentación se puede utilizar el escenario simple:

```text
PEDIDO
  ↓
una ubicación de fulfillment
  ↓
varias líneas SKU
```

El contrato actual de Despacho refuerza parcialmente esta simplificación para delivery:

- todos los pedidos se preparan en un único centro de despacho;
- para el alcance inicial, un pedido genera un despacho;
- Pickup no forma parte de su contrato actual.

### Salvaguarda crítica

**NO trasladar este supuesto a una restricción del modelo físico de Inventario.**

La documentación oficial de Productos e Inventario modela las líneas de reserva como:

```text
reservation_line
- sku
- quantity
- location_id
```

Por tanto:

```text
location_id
```

debe permanecer a nivel de línea cuando así lo establece el modelo oficial.

### NO hacer

No diseñar:

```text
reservation.location_id NOT NULL
```

como reemplazo de `reservation_line.location_id` únicamente por este supuesto.

No crear una constraint que obligue a todas las líneas a compartir ubicación salvo que una fuente oficial futura lo determine.

### Motivo

Esto permite presentar un escenario simple en Hito 2 sin cerrar prematuramente split fulfillment.

---

## H2-A-003 — Mapeo entre tienda Retail y ubicación de Inventario

**Estado:** `TEMPORAL`

Retail continúa utilizando identificadores conceptuales como:

```text
TIENDA-MIRAFLORES
```

mientras Productos e Inventario utilizan:

```text
location_id
```

Para Hito 2 se puede asumir una asociación conceptual:

```text
Retail.tiendaId
        ↓
Inventory.location.external_ref
```

### Salvaguardas

- no crear FK hacia una tabla de Retail;
- no asumir que ambos IDs son definitivamente iguales;
- no codificar el formato `TIENDA-*` como una regla irreversible;
- `external_ref` es una posibilidad de implementación, no un contrato externo.

---

## H2-A-004 — PEN para fixtures y demostración

**Estado:** `TEMPORAL`

Para datos de prueba, seed, validaciones y presentación del Hito 2 se utilizará:

```text
PEN
```

Esto coincide con los ejemplos actuales de los consumidores comerciales y evita introducir conversión monetaria en la demostración.

### Salvaguarda crítica

La arquitectura de Productos mantiene `currency` explícita.

Por tanto **no crear** únicamente por este supuesto:

```sql
CHECK (currency = 'PEN')
```

si la fuente oficial de Pricing no exige esa restricción.

La BD debe conservar un campo de moneda compatible con el contrato vigente.

---

## H2-A-005 — Tratamiento monetario para la demostración

**Estado:** `TEMPORAL`

En ejemplos de Hito 2 puede asumirse:

- PEN;
- importes con dos decimales;
- precios mostrados como precio final al consumidor.

Retail documenta precios en soles, IGV incluido y desglose tributario. Sin embargo, Productos y Ofertas aún no define formalmente la semántica tributaria completa de `precio_regular` / `precio_oferta`.

### Salvaguarda crítica

`pricing-svc` debe almacenar la información comercial que le corresponde:

```text
amount
currency
vigencia
version
...
```

sin introducir tablas o columnas fiscales basadas únicamente en esta suposición.

No agregar en Pricing, solo por este documento:

```text
igv
base_imponible
tasa_igv
```

El desglose tributario pertenece al flujo comercial/fiscal que deberá homologarse con Ventas/Retail.

---

## H2-A-006 — Código de barras

**Estado:** `EN_VALIDACION`

### Hallazgo actual

Retail sigue requiriendo explícitamente:

```text
codigoBarras
```

en búsqueda e incidencias.

Sin embargo, las fuentes oficiales actuales de Productos y Ofertas no modelan todavía el código de barras como dato de Catálogo/SKU.

### Regla para Hito 2

**El código de barras no debe bloquear `catalog-svc`.**

Mientras no se formalice en Productos:

- no es obligatorio introducirlo en el modelo físico oficial de Hito 2;
- si se necesita en una rama experimental o fixture, debe tratarse como extensión provisional;
- no debe presentarse como campo contractual de Productos.

### Si se formaliza antes de cerrar Hito 2

La opción mínima sería:

```text
sku
barcode nullable
```

pero la cardinalidad definitiva:

```text
SKU 1 → 0..1 barcode
```

vs.

```text
SKU 1 → 0..N barcodes
```

sigue pendiente.

---

## H2-A-008 — Pickup no introduce persistencia específica en Hito 2

**Estado:** `EN_VALIDACION`

### Situación actual

Retail mantiene especificaciones y contratos propios de Pickup / Click & Collect.

Despacho, en cambio, tiene actualmente un contrato centrado en:

```text
pedido preparado
→ centro de despacho único
→ delivery a domicilio
```

y no publica endpoints de Pickup.

### Regla de trabajo Hito 2

`inventory-svc` no necesita tablas específicas de Pickup para aprobar Hito 2.

El modelo base debe poder evolucionar utilizando:

```text
location
stock_balance
reservation
reservation_line
inventory_movement
transfer
```

### No crear todavía por esta necesidad

```text
pickup_order
pickup_handoff
pickup_store_receipt
```

salvo que un acuerdo intermodular oficial lo exija.

---

# 6. Puntos que ya NO son supuestos

## H2-A-002 — Ownership de Ubicación

**Estado:** `RESUELTO`

`Contrato_Api.md` ya asigna oficialmente:

```text
Stock / Reserva / Kardex / Ubicación
→ Productos y Ofertas — Inventario
```

Por tanto, para Hito 2 no hace falta tratar el ownership de `location` como incierto.

### Lo que sigue siendo decisión de implementación

La forma exacta de una tabla física como:

```text
LOCATION
- id
- code
- name
- type
- external_ref
- active
```

no está fijada por este documento interno.

El responsable de `inventory-svc` debe derivarla de:

- Modelo Conceptual;
- SPEC-015;
- Arquitectura;
- estándares comunes de BD;
- issue #54.

---

## H2-A-007 — TTL de reservas

**Estado:** `RESUELTO`

Las fuentes oficiales ya establecen:

- reservas con `expires_at`;
- expiración por TTL;
- TTL configurable por entorno/canal;
- expiración libera `reserved`, no `blocked`.

Por tanto el modelo físico puede implementar:

```text
expires_at
```

sin definir un valor rígido de minutos.

La cantidad exacta de minutos pertenece a configuración operativa, no al esquema de BD.

---

## H2-A-009 — Persistencia de combos

**Estado:** `RESUELTO`

El alcance actual de Hito 2 para `combos-svc` ya establece persistencia de:

- combo;
- componentes;
- referencias SKU;
- proyecciones locales necesarias;
- Outbox/Inbox cuando corresponda.

Las SPEC también contemplan compra de combo y reserva de componentes, pero esa orquestación **no exige que `combos-svc` sea dueño de pedidos, pagos o reservas**.

Por tanto no deben crearse en el schema `combos` tablas como:

```text
pedido
pago
reserva_inventario
```

solo para implementar checkout.

---

## H2-A-010 — Stock inicial

**Estado:** `RESUELTO`

SPEC-001 y el flujo oficial ya distinguen:

```text
inicialización del SKU
```

de:

```text
aplicación de stock inicial
```

Cuando:

```text
stock_inicial > 0
```

y existe:

```text
default_location_id
```

Bulk utiliza:

```text
inventory.bulk.stock.adjust.requested
```

Por tanto este comportamiento deja de ser una suposición.

---

## H2-A-012 — SKU como identidad vendible en Inventario

**Estado:** `RESUELTO`

El contrato y SPEC-015 ya utilizan formalmente:

```text
sku
quantity
location_id
```

en las líneas de inventario/reserva.

`product_id` no sustituye al SKU en operaciones físicas.

El modelo físico puede apoyarse en esta regla sin etiquetarla como provisional.

---

# 7. Supuesto descartado

## H2-A-011 — “No split fulfillment”

**Estado:** `DESCARTADO`

Se elimina como supuesto independiente porque:

1. duplicaba H2-A-001;
2. podía interpretarse erróneamente como una constraint de BD;
3. el modelo oficial mantiene `location_id` a nivel de línea de reserva.

Para la presentación puede utilizarse un caso simple de una sola ubicación, pero el modelo físico no debe cerrarse artificialmente por ello.

---

# 8. Reglas oficiales que el equipo debe aplicar directamente

Estas reglas **no pertenecen a este documento de supuestos** y deben tratarse como decisiones oficiales:

### Aislamiento entre bounded contexts

```text
NO FK entre schemas de microservicios diferentes
NO acceso SQL directo cross-service
```

### Ownership

```text
catalog      → producto / variante / SKU
taxonomy     → categorías / marcas / características
pricing      → precio
promotions   → promociones / cupones
combos       → combos
inventory    → stock / reservas / Kardex / ubicación
price-audit  → auditoría de precios
bulk         → trabajos masivos
```

### Inventario

```text
saldo autoritativo = (sku, location_id)
```

### Reserva

```text
line:
  sku
  quantity
  location_id
```

### Stock inicial

```text
stock_inicial > 0
+ default_location_id
→ inventory.bulk.stock.adjust.requested
```

### Hito 2 BD

Cada bounded context mantiene su propio schema y sus migraciones reproducibles.

---

# 9. Riesgos externos que NO deben entrar al modelo físico de Hito 2

Siguen abiertos, pero no justifican detener la BD:

1. decisión final de Pickup entre Retail, Ventas y Despacho;
2. quién realiza picking/packing antes de Despacho;
3. compensación si el pago fue aprobado y el consumo de inventario falla;
4. flujo comercial definitivo de venta presencial de Retail;
5. reintegro Postventa por SKU y ubicación;
6. distribución de descuentos en devoluciones parciales;
7. restauración de cupones después de devoluciones;
8. promociones sobre costo de envío;
9. semántica tributaria definitiva compartida;
10. código de barras;
11. múltiples terminales Retail en modo offline;
12. política definitiva de fulfillment multiubicación.

Estos asuntos se resuelven principalmente mediante contratos y orquestación.

No deben provocar que un responsable agregue a su schema tablas pertenecientes a Ventas, Retail o Despacho.

---

# 10. Qué puede avanzar sin esperar

## `catalog-svc`

Puede avanzar con las fuentes oficiales actuales.

No debe esperar por código de barras.

## `taxonomy-svc`

Puede avanzar completamente.

## `pricing-svc`

Puede avanzar manteniendo moneda explícita y tipos monetarios exactos.

Usar PEN en seeds no significa restringir definitivamente la moneda.

## `price-audit-svc`

Puede avanzar completamente.

## `promotions-svc`

Puede avanzar según SPEC/contrato vigente.

No necesita modelar tributación ni costo de despacho.

## `combos-svc`

Puede avanzar con combo, componentes y proyecciones locales.

No debe duplicar Pedido, Pago o Reserva.

## `inventory-svc`

Puede avanzar con:

```text
location
stock_balance
reservation
reservation_line
inventory_operation
kardex
threshold
incident
transfer
reconciliation
outbox/inbox
```

según las fuentes oficiales.

La principal precaución es **no imponer una única `location_id` por reserva únicamente por H2-A-001**.

## `bulk-svc`

Puede avanzar con el flujo oficial de inicialización y ajustes.

---

# 11. Checklist antes de aprobar un modelo físico

Antes de aprobar `physical-model.md` o `migration.sql`, comprobar:

- [ ] No se introdujo una regla proveniente únicamente de este archivo como constraint definitiva.
- [ ] No existen FK cross-service.
- [ ] Los IDs externos son referencias escalares.
- [ ] Inventario conserva `(sku, location_id)` como identidad del saldo.
- [ ] Las líneas de reserva conservan `location_id`.
- [ ] PEN se usa como dato de prueba, no como restricción no documentada.
- [ ] Pricing no absorbió cálculo tributario de Retail/Ventas.
- [ ] Catalog no agregó `barcode` como campo contractual sin formalización.
- [ ] Combos no creó ownership de Pedido/Pago.
- [ ] Pickup no generó persistencia prematura.
- [ ] `expires_at` existe donde corresponde, sin hardcodear un TTL empresarial.
- [ ] Stock inicial sigue el flujo oficial de Bulk/Inventario.
- [ ] El modelo coincide con la fuente de verdad vigente del bounded context.

---

# 12. Procedimiento de revisión

Cuando cambie una fuente oficial:

1. comparar el cambio contra este archivo;
2. si confirma un supuesto → `RESUELTO`;
3. si contradice un supuesto → `DESCARTADO`;
4. revisar únicamente las tablas/migraciones realmente afectadas;
5. actualizar el documento interno;
6. no propagar automáticamente el contenido de este archivo hacia las fuentes oficiales.

---

# 13. Acuerdo interno del equipo

El equipo utiliza este archivo bajo la siguiente regla:

> **Los supuestos permiten avanzar, pero nunca tienen autoridad suficiente para modificar por sí solos el contrato o imponer una restricción irreversible en la base de datos.**

Para Hito 2 se prioriza:

```text
fuente oficial vigente
        ↓
modelo conceptual
        ↓
modelo físico
        ↓
migración SQL
```

y este documento actúa únicamente como apoyo temporal para los puntos todavía abiertos.
