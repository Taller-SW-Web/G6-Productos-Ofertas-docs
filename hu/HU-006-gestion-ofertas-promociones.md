# HU-006 — Historia de Usuario: Gestión de ofertas y promociones

**Responsable:** Axel Andree Cueva Alcalá  
**Rama:** cueva  
**Trazabilidad:** Spec [SPEC-006](../specs/SPEC-006-gestion-ofertas-promociones.md) | Flow [WF-006](../wireframes/flows/WF-006-gestion-ofertas-promociones.md)

## Funcionalidad

Gestión de ofertas y promociones — Obligatoria.

## Historia de usuario

**Como** gestor comercial,  
**quiero** configurar ofertas y promociones indicando productos o SKUs participantes, descuento, modalidad, vigencia, estado, prioridad, canales y política de combinación,  
**para** que los canales de venta puedan consultar y evaluar correctamente beneficios comerciales sin modificar el precio maestro de Pricing.

## Reglas de negocio consolidadas

- Una promoción usa descuento por **porcentaje** o por **monto fijo**.
- Porcentaje: `0 < valor <= 100`.
- Monto fijo: `valor > 0`, aplicado una vez al subtotal elegible.
- El descuento no produce importe final negativo.
- Solo participa si está activa, vigente, aplica al alcance y está habilitada para el canal.
- La modalidad es `AUTOMATICA` o `CUPON`.
- Cada promoción define prioridad y política de combinación.
- Por defecto no se permite combinar con otros beneficios.
- Se construyen únicamente combinaciones autorizadas.
- Se selecciona la alternativa válida de menor importe final.
- En empate exacto: no consumir cupón → menor prioridad → identificador estable.
- Un cupón no se consume durante la validación/evaluación.
- Modificar o desactivar una promoción no modifica pedidos ya confirmados.
- Pricing entrega precios; Promociones evalúa beneficios y no sobrescribe esos precios.
- No existe pantalla administrativa «Evaluar compra».

## Criterios de aceptación

| ID | Criterio |
|---|---|
| **CA-01** | Solo un usuario autorizado puede crear, modificar, activar o desactivar promociones. Los permisos granulares los define Seguridad. |
| **CA-02** | Para registrar una promoción se indican nombre, alcance, tipo/valor, inicio, fin, modalidad, estado inicial, prioridad, canales y política de combinación. |
| **CA-03** | El alcance contiene al menos un producto o SKU vendible activo. Inicio < fin; porcentaje `(0,100]`; monto fijo `>0`. |
| **CA-04** | El gestor puede consultar listado/detalle, editar condiciones y activar/desactivar. |
| **CA-05** | Solo se aplica si está activa, vigente, es elegible por alcance y está habilitada para el canal. |
| **CA-06** | El monto fijo se aplica una sola vez al subtotal elegible; ningún descuento deja importe negativo. |
| **CA-07** | Con varias promociones automáticas se evalúan solo combinaciones permitidas y se elige la de menor importe final. |
| **CA-08** | La evaluación devuelve beneficio seleccionado, importe original, descuento, importe resultante y motivo si no aplica beneficio. |
| **CA-09** | Modificar o desactivar no altera pedidos confirmados. |
| **CA-10** | Oferta propia de Pricing, promoción automática y cupón se combinan únicamente cuando la política lo permite; todas las combinaciones deshabilitadas equivalen a una promoción exclusiva. |
| **CA-11** | El alcance puede definirse por producto completo o SKU específico; la coincidencia se deduplica. |
| **CA-12** | La modalidad es obligatoria. Una promoción `CUPON` no se aplica automáticamente sin un código válido asociado. |
| **CA-13** | La modalidad solo se cambia en una promoción inactiva nunca activada, sin cupones asociados ni usos históricos; en otro caso se crea una nueva promoción. |
| **CA-14** | Pricing entrega regular/oferta por SKU; Promociones los usa como insumo sin cambiar el precio maestro. |
| **CA-15** | La evaluación considera el canal solicitante y excluye promociones no habilitadas. Validar no consume cupón. |
| **CA-16** | El backoffice no ofrece una pantalla de simulación de compra; la evaluación es una capacidad API consumida por el flujo real. |
| **CA-17** | Las reglas de importación, programación e histórico de precios pertenecen a SPEC/HU-013 y no forman parte de esta HU. |

## Escenarios

### Escenario 1: Registrar promoción válida

- **DADO** un gestor autorizado y productos/SKUs activos
- **CUANDO** registra una promoción completa y válida
- **ENTONCES** se guarda y aparece en la administración con el estado indicado.

### Escenario 2: Rechazar configuración inválida

- **DADO** un formulario de promoción
- **CUANDO** se ingresa porcentaje >100, monto <=0, fin <= inicio o alcance vacío
- **ENTONCES** se impide guardar y se conservan los datos para corregirlos.

### Escenario 3: Aplicar porcentaje

- **DADO** subtotal elegible S/ 200 y promoción válida del 15 %
- **CUANDO** el canal evalúa
- **ENTONCES** se devuelve descuento S/ 30 e importe S/ 170.

### Escenario 4: Limitar monto fijo

- **DADO** subtotal S/ 30 y descuento fijo S/ 50
- **CUANDO** se evalúa
- **ENTONCES** el descuento se limita a S/ 30 y el importe final es S/ 0.

### Escenario 5: Elegir mejor alternativa

- **DADO** múltiples beneficios con políticas conocidas
- **CUANDO** se evalúan combinaciones permitidas
- **ENTONCES** se selecciona la alternativa válida de menor importe final.

### Escenario 6: Promoción automática y cupón

- **DADO** una promoción automática y un cupón válido
- **CUANDO** el canal evalúa
- **ENTONCES** se combinan solo si está permitido; de lo contrario se elige la alternativa válida correspondiente.

### Escenario 7: Fuera de vigencia

- **DADO** una promoción no iniciada o vencida
- **CUANDO** se evalúa
- **ENTONCES** no se aplica.

### Escenario 8: Desactivar

- **DADO** una promoción activa
- **CUANDO** el gestor la desactiva
- **ENTONCES** deja de participar en nuevas evaluaciones y los pedidos históricos no cambian.

### Escenario 9: Modalidad cupón sin código

- **DADO** una promoción `CUPON`
- **CUANDO** la compra no presenta un código válido
- **ENTONCES** la promoción no se aplica automáticamente.

### Escenario 10: Oferta propia de Pricing como alternativa

- **DADO** regular S/ 200, oferta propia vigente S/ 180 y promoción automática que deja S/ 170
- **CUANDO** la política no permite acumulación
- **ENTONCES** se elige S/ 170 y no se vuelve a descontar sobre S/ 180.

### Escenario 11: Modalidad no editable

- **DADO** una promoción que ya fue activada o tiene cupones/usos históricos
- **CUANDO** el gestor intenta cambiar `AUTOMATICA ↔ CUPON`
- **ENTONCES** el sistema bloquea el cambio y orienta a crear una nueva promoción.

## Interacción con otros módulos

| Módulo | Necesidad | Recibe | Entrega |
|---|---|---|---|
| Marketplace | Consultar/evaluar promociones | Cesta, cantidades, canal y cupón cuando exista | Beneficio seleccionado y desglose |
| Chatbot | Consultar promociones | Productos y cantidades | Descripción/vigencia/resultado |
| Retail | Venta asistida | Cesta y canal | Beneficio seleccionado |
| Ventas/Postventa | Registrar snapshot comercial | Beneficio aceptado por el flujo de venta | Datos de evaluación; consumo de cupón se trata en HU-005 |
| Seguridad | Autorizar administración | Token/claims | 401/403 según contrato |
| Pricing | Proveer precios | regular/oferta, vigencia, scope | Promociones no modifica Pricing |

## Dependencias internas

- Gestión de Productos: identidad/estado de productos y SKU.
- Gestión de Precios: precios regular/oferta vigentes.
- Gestión de Cupones: código y límites del cupón cuando la modalidad lo requiera.

## Delimitación

No pertenecen a esta HU:

- inicialización de precios;
- carga masiva de precios;
- histórico temporal de Pricing;
- SCD de precios;
- límites de archivos de Pricing;
- permisos `PRICING_*` como requisito de Promociones.
