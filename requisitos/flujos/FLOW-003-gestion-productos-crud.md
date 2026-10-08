# FLOW-003 — Gestión de productos (CRUD principal)

## 1. Identificación

- **Código:** FLOW-003.
- **Funcionalidad:** Gestión de productos (CRUD principal).
- **Relacionado con:** [SPEC-003](../specs/SPEC-003-gestion-productos-crud.md) / [WF-003](..\..\ux\wireframes\flows\WF-003-gestion-productos-crud.md) / [índice WF-003](..\..\ux\wireframes\prototipos\WF-003-gestion-productos-crud\index.html) / [HU-003](../hu/HU-003-gestion-productos-crud.md).
- **Responsable:** Gabriel Poma Gutierrez.
- **Última actualización:** 2026-10-02.
- **Contratos consultados:** [OpenAPI vigente 0.5.0](..\..\contratos\http\openapi.yaml) y [AsyncAPI 0.4.0](..\..\contratos\eventos\asyncapi.yaml). Se conservan las extensiones vigentes de las fuentes.

## 2. Objetivo del flujo

Representar consulta, creación en `BORRADOR`, preparación asíncrona de precio e inventario, edición, activación, desactivación lógica y reactivación. Solo una confirmación de la dependencia permite considerarla preparada.

## 3. Actores participantes

- **Gestor comercial:** consulta y administra productos, solicita cambios de estado y reintenta preparaciones.
- **Sistema (Catálogo):** valida, persiste y coordina las dependencias mediante RabbitMQ.
- **Pricing e Inventario:** procesan las inicializaciones y emiten sus resultados.

## 4. Diagrama de flujo

### 4.1. Consulta y creación del borrador

```mermaid
flowchart LR
    subgraph G["Gestor comercial"]
        direction TB
        INICIO(("Gestión iniciada"))
        CONSULTAR["Consultar lista o detalle del producto"]
        ACCION{"¿Crear producto?"}
        DATOS["Completar datos mínimos y solicitar guardar<br/>borrador"]
        FIN_CONSULTA((("Consulta completada")))
    end
    subgraph S["Sistema · Catálogo"]
        direction TB
        VALIDAR["Validar datos mínimos, maestros, unicidad de<br/>sku_base y perfil simple proporcionado"]
        VALIDO{"¿Datos válidos?"}
        ERROR["Informar errores sin crear producto"]
        PERSISTIR["Persistir producto en BORRADOR"]
        PRECIO["Iniciar preparación de Pricing en 4.2"]
        SIMPLE{"¿Producto simple?"}
        STOCK["Iniciar preparación de sku_base en 4.3"]
        VARIANTES["Dirigir a FLOW-004; no crear saldo del padre"]
        FIN_ERROR((("Alta rechazada")))
        FIN((("Borrador guardado; preparaciones en curso")))
    end
    INICIO --> CONSULTAR --> ACCION
    ACCION -->|"No"| FIN_CONSULTA
    ACCION -->|"Sí"| DATOS --> VALIDAR --> VALIDO
    VALIDO -->|"No"| ERROR --> FIN_ERROR
    VALIDO -->|"Sí"| PERSISTIR
    PERSISTIR --> PRECIO --> FIN
    PERSISTIR --> SIMPLE
    SIMPLE -->|"Sí"| STOCK --> FIN
    SIMPLE -->|"No"| VARIANTES --> FIN
```

Los datos mínimos son nombre, descripción, categoría, tipo de producto, marca, `sku_base`, `tiene_variantes` y precio base inicial. Guardar borrador no exige imagen, características completas ni datos físicos completos. Si se registra perfil físico simple, se valida `pesoKg > 0`, `largoCm > 0`, `anchoCm > 0`, `altoCm > 0`, usando kg y cm. El padre con variantes no tiene perfil físico ni saldo propios. Las preparaciones son independientes y se inician después de persistir el borrador.

### 4.2. Preparación de Pricing y reintento

```mermaid
flowchart LR
    subgraph S["Sistema · Catálogo"]
        direction TB
        INICIO(("Borrador persistido"))
        PENDING["Registrar preparación de Pricing PENDING"]
        REQUEST["Publicar<br/>pricing.product.initialization.requested<br/>mediante RabbitMQ"]
        RESULTADO{"¿Resultado recibido para la operación?"}
        COMPLETED(("pricing.product.initialization.completed<br/>recibido"))
        REJECTED(("pricing.product.initialization.rejected<br/>recibido"))
        LISTO["Registrar COMPLETED y marcar Pricing<br/>preparado"]
        RECHAZO["Registrar REJECTED y mantener BORRADOR"]
        ESPERA["Mantener PENDING y BORRADOR; informar<br/>preparación sin concluir"]
        CONSERVAR["Conservar operation_id e identidad del<br/>producto; no duplicar precio"]
        FIN_OK((("Pricing preparado; evaluar condiciones en 4.4")))
        FIN_PENDIENTE((("Producto permanece BORRADOR")))
    end
    subgraph P["Pricing"]
        direction TB
        PROCESAR["Procesar inicialización idempotentemente y<br/>emitir resultado por RabbitMQ"]
    end
    subgraph G["Gestor comercial"]
        direction TB
        RETRY{"¿Reintentar dependencia rechazada o sin<br/>concluir?"}
    end
    INICIO --> PENDING --> REQUEST --> PROCESAR --> RESULTADO
    RESULTADO -->|"completed"| COMPLETED --> LISTO --> FIN_OK
    RESULTADO -->|"rejected"| REJECTED --> RECHAZO --> RETRY
    RESULTADO -->|"Sin resultado concluyente"| ESPERA --> RETRY
    RETRY -->|"Sí"| CONSERVAR --> PENDING
    RETRY -->|"No"| FIN_PENDIENTE
```

El comando contiene `product_id`, `sku_base`, `precio_regular`, `moneda`, `channel_id=null` y `motivo_cambio=ALTA_PRODUCTO`. `COMPLETED` acredita el primer precio persistido; Pricing publica `pricing.price.changed` después de su commit. No se inicializa precio base por variante.

### 4.3. Preparación de Inventario del producto simple y reintento

```mermaid
flowchart LR
    subgraph S["Sistema · Catálogo"]
        direction TB
        INICIO(("Borrador simple persistido"))
        PENDING["Registrar preparación de Inventario PENDING"]
        REQUEST["Publicar<br/>inventory.sku.initialization.requested para<br/>sku_base mediante RabbitMQ"]
        RESULTADO{"¿Resultado recibido para la operación?"}
        COMPLETED(("inventory.sku.initialization.completed<br/>recibido"))
        REJECTED(("inventory.sku.initialization.rejected<br/>recibido"))
        LISTO["Registrar COMPLETED y marcar SKU inicializado"]
        RECHAZO["Registrar REJECTED y mantener BORRADOR"]
        ESPERA["Mantener PENDING y BORRADOR; informar<br/>preparación sin concluir"]
        CONSERVAR["Conservar operation_id y sku_base; no<br/>duplicar SKU ni inicialización"]
        FIN_OK((("Inventario preparado; evaluar condiciones en<br/>4.4")))
        FIN_PENDIENTE((("Producto permanece BORRADOR")))
    end
    subgraph I["Inventario"]
        direction TB
        PROCESAR["Procesar inicialización idempotentemente y<br/>emitir resultado por RabbitMQ"]
    end
    subgraph G["Gestor comercial"]
        direction TB
        RETRY{"¿Reintentar dependencia rechazada o sin<br/>concluir?"}
    end
    INICIO --> PENDING --> REQUEST --> PROCESAR --> RESULTADO
    RESULTADO -->|"completed"| COMPLETED --> LISTO --> FIN_OK
    RESULTADO -->|"rejected"| REJECTED --> RECHAZO --> RETRY
    RESULTADO -->|"Sin resultado concluyente"| ESPERA --> RETRY
    RETRY -->|"Sí"| CONSERVAR --> PENDING
    RETRY -->|"No"| FIN_PENDIENTE
```

Para producto simple, `sku=sku_base` y `variant_id=null`. El padre con variantes no ejecuta esta inicialización: cada SKU vendible se prepara desde FLOW-004. Un resultado exitoso de una dependencia no completa la otra; solo se reintenta la pendiente o rechazada, conservando su propia identidad de operación.

### 4.4. Edición, activación y reactivación

```mermaid
flowchart LR
    subgraph G["Gestor comercial"]
        direction TB
        INICIO(("Producto seleccionado"))
        ACCION{"¿Acción solicitada?"}
        EDITAR["Editar datos permitidos del producto"]
        ACTIVAR["Solicitar activación del borrador"]
        REACTIVAR["Solicitar reactivación del producto inactivo"]
    end
    subgraph S["Sistema · Catálogo"]
        direction TB
        VALIDAR["Validar cambios y perfil simple proporcionado<br/>en kg/cm con valores mayores que 0"]
        EDICION{"¿Cambios válidos que conservan naturaleza<br/>comercial y coherencia con variantes,<br/>sin recodificar SKU ni cambiar modelo?"}
        EDIT_ACTIVO{"¿Producto ACTIVO?"}
        EDIT_CONDICIONES{"¿Resultado conserva las condiciones<br/>de activación del producto?"}
        GUARDAR["Guardar cambios sin repetir alta ni<br/>inicializaciones completadas"]
        ESTADO{"¿Estado de origen compatible con la acción?"}
        MINIMOS{"¿Datos mínimos válidos?"}
        MAESTROS{"¿Categoría, tipo y marca válidos?"}
        CARACTERISTICAS{"¿Características obligatorias completas?"}
        IMAGEN{"¿Imagen disponible?"}
        PRECIO{"¿Pricing preparado con COMPLETED?"}
        STOCK{"¿Inventario COMPLETED para sku_base simple<br/>o todas las variantes activas?"}
        MODELO{"¿Usa variantes?"}
        VARIANTES{"¿Existe al menos una variante activa?"}
        FISICO{"¿Perfil simple completo en kg/cm<br/>con los cuatro valores mayores que 0?"}
        PUBLICAR["Persistir producto ACTIVO"]
        BLOQUEAR["Informar condiciones pendientes y conservar<br/>BORRADOR o INACTIVO"]
        RECHAZAR["Informar solicitud inválida y conservar datos<br/>y estado"]
        FIN_EDICION((("Producto editado")))
        FIN_OK((("Producto activado o reactivado")))
        FIN_BLOQUEO((("Cambio no aplicado")))
    end
    INICIO --> ACCION
    ACCION -->|"Editar"| EDITAR --> VALIDAR --> EDICION
    EDICION -->|"Sí"| EDIT_ACTIVO
    EDIT_ACTIVO -->|"No"| GUARDAR
    EDIT_ACTIVO -->|"Sí"| EDIT_CONDICIONES
    EDIT_CONDICIONES -->|"Sí"| GUARDAR --> FIN_EDICION
    EDIT_CONDICIONES -->|"No"| RECHAZAR
    EDICION -->|"No"| RECHAZAR --> FIN_BLOQUEO
    ACCION -->|"Activar"| ACTIVAR --> ESTADO
    ACCION -->|"Reactivar"| REACTIVAR --> ESTADO
    ESTADO -->|"Sí"| MINIMOS
    ESTADO -->|"No"| RECHAZAR
    MINIMOS -->|"Sí"| MAESTROS
    MINIMOS -->|"No"| BLOQUEAR
    MAESTROS -->|"Sí"| CARACTERISTICAS
    MAESTROS -->|"No"| BLOQUEAR
    CARACTERISTICAS -->|"Sí"| IMAGEN
    CARACTERISTICAS -->|"No"| BLOQUEAR
    IMAGEN -->|"Sí"| PRECIO
    IMAGEN -->|"No"| BLOQUEAR
    PRECIO -->|"Sí"| STOCK
    PRECIO -->|"No"| BLOQUEAR
    STOCK -->|"Sí"| MODELO
    STOCK -->|"No"| BLOQUEAR
    MODELO -->|"No"| FISICO
    FISICO -->|"Sí"| PUBLICAR
    FISICO -->|"No"| BLOQUEAR
    MODELO -->|"Sí"| VARIANTES
    VARIANTES -->|"Sí"| PUBLICAR
    VARIANTES -->|"No"| BLOQUEAR
    PUBLICAR --> FIN_OK
    BLOQUEAR --> FIN_BLOQUEO
```

Reactivar usa las mismas comprobaciones de activación y conserva la identidad. `sku_base` no se recodifica por edición ordinaria; `tiene_variantes` no cambia tras publicar la identidad. Preparación completa no activa automáticamente el producto: el gestor solicita el cambio. Un rechazo de una dependencia requerida durante el alta mantiene `BORRADOR`, sin rollback distribuido ni deshacer lo que otra dependencia ya completó; el rechazo de una variante no activa no bloquea por sí solo al padre ni lo inactiva.

La edición conserva la naturaleza comercial del producto y la coherencia con sus variantes en cualquier estado; si representa otro producto, requiere una nueva alta. No crea ni sustituye variantes. Para un producto activo se valida el resultado completo antes de guardar; un incumplimiento rechaza toda la edición y conserva datos y estado anteriores. Para activar/reactivar al padre cuentan todas las variantes activas y debe existir al menos una; los hijos en borrador o inactivos no bloquean ni se ofrecen comercialmente. El perfil físico simple puede estar incompleto en borrador, pero debe completarse antes de activar/reactivar; el padre con variantes no registra peso ni dimensiones. El volumen es derivado, no una entrada independiente.

### 4.5. Desactivación lógica

```mermaid
flowchart LR
    subgraph G["Gestor comercial"]
        direction TB
        INICIO(("Desactivación solicitada"))
        CONFIRMAR{"¿Confirma desactivar?"}
        FIN_CANCELAR((("Desactivación cancelada")))
    end
    subgraph S["Sistema · Catálogo"]
        direction TB
        VALIDAR{"¿Producto admite desactivación?"}
        BAJA["Persistir producto INACTIVO y bloquear<br/>comercialmente sus variantes sin cambiar<br/>sus estados individuales"]
        EVENTO["Publicar catalog.product.deactivated mediante<br/>RabbitMQ"]
        ERROR["Informar estado incompatible sin aplicar baja"]
        FIN_OK((("Producto desactivado")))
        FIN_ERROR((("Desactivación no aplicada")))
    end
    INICIO --> CONFIRMAR
    CONFIRMAR -->|"No"| FIN_CANCELAR
    CONFIRMAR -->|"Sí"| VALIDAR
    VALIDAR -->|"Sí"| BAJA --> EVENTO --> FIN_OK
    VALIDAR -->|"No"| ERROR --> FIN_ERROR
```

RabbitMQ realiza el fan-out de `catalog.product.deactivated` a los consumidores declarados en AsyncAPI 0.4.0 (`promotions-svc`, `combos-svc`, `api-gateway/bff`); Catálogo no realiza llamadas directas a ellos. La baja conserva identidad y bloquea resolución comercial mientras el producto esté inactivo. Estar `ACTIVO` no garantiza visibilidad en todos los canales: también aplica la elegibilidad comercial de SPEC-003.

Reactivar al padre no reactiva hijos inactivos; reactivar una variante tampoco reactiva al padre. Desactivar la última variante activa solo inactiva automáticamente a un padre que estaba `ACTIVO`; un padre en borrador o inactivo conserva su estado, conforme a FLOW-004.

## 5. Reglas de preparación y trazabilidad

| Estado de preparación | Evidencia | Resultado funcional |
|---|---|---|
| `PENDING` | Se publicó `requested`, aún sin resultado concluyente. | Mantener borrador y bloquear activación. |
| `COMPLETED` | Se recibió `completed` de la operación correspondiente. | Marcar esa dependencia preparada y revalidar las demás condiciones. |
| `REJECTED` | Se recibió `rejected` de la operación correspondiente. | Mantener borrador, informar rechazo y permitir reintento idempotente. |

- Estos estados describen cada inicialización, no sustituyen el estado del producto.
- Los reintentos conservan `operation_id`; se deduplican mensajes por `message_id` conforme a AsyncAPI. No duplican producto, precio, SKU ni inicializaciones.
- Los nombres de mensajes y estados técnicos documentan la integración; la interfaz muestra mensajes operativos según WF-003.
- Se conserva la prioridad solicitada: SPEC → documentación WF → índice WF → HU; los nombres y transporte de mensajes se contrastan con AsyncAPI.
